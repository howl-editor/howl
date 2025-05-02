{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DefaultSignatures #-}

{-
  This example file was taken from the 'animate' library by Joe Vargas
  Original repository: https://github.com/jxv/animate

  BSD 3-Clause License

  Copyright (c) 2017, Joe Vargas
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.

  * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

  * Neither the name of the copyright holder nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-}

module Animate
  ( Color
  , FrameIndex
  , Frame(..)
  , Animations(..)
  , Loop(..)
  , Position(..)
  , FrameStep(..)
  , KeyName(..)
  , SpriteClip(..)
  , SpriteSheet(..)
  , SpriteSheetInfo(..)
  , animations
  , framesByAnimation
  , initPosition
  , initPositionLoops
  , initPositionWithLoop
  , stepFrame
  , stepPosition
  , isAnimationComplete
  , positionHasLooped
  , currentFrame
  , currentLocation
  , nextKey
  , prevKey
  , readSpriteSheetInfoJSON
  , readSpriteSheetInfoYAML
  , readSpriteSheetJSON
  , readSpriteSheetYAML
  ) where

import qualified Data.Vector as V (Vector, (!), length, fromList)
import qualified Data.Map as Map
import qualified Data.ByteString.Lazy as BL
import qualified Data.Yaml as Y
import Control.Applicative ((<|>))
import Control.Monad (mzero)
import Data.Aeson (FromJSON(..), ToJSON(..), (.:), eitherDecode, object, (.=), Value(..))
import Data.Map (Map)
import Data.Word (Word8)
import Data.Text (Text, pack)
import GHC.Generics (Generic)


-- | Alias for RGB (8bit, 8bit, 8bit)
type Color = (Word8, Word8, Word8)

type FrameIndex = Int

data Frame loc delay = Frame
  { fLocation :: loc -- ^ User defined reference to the location of a sprite. For example, a sprite sheet clip.
  , fDelay :: delay -- ^ Minimium amount of units for the frame to last.
  } deriving (Show, Eq, Generic)

-- | Type safe animation set. Use a sum type with an `Enum` and `Bounded` instance for the animation, @a@.
newtype Animations key loc delay = Animations { unAnimations :: V.Vector (V.Vector (Frame loc delay)) }
  deriving (Show, Eq)

-- class (Ord key, Bounded key, Enum key) => Key key

-- | Animation Keyframe. `keyName` is used for JSON parsing.
class KeyName key where
  keyName :: key -> Text
  default keyName :: Show key => key -> Text
  keyName = pack . dropTickPrefix . show
    where
      dropTickPrefix :: String -> String
      dropTickPrefix = drop 1 . dropWhile (/= '\'')

-- | Describe the boxed area of the 2d sprite inside a sprite sheet
data SpriteClip key = SpriteClip
  { scX :: Int
  , scY :: Int
  , scW :: Int
  , scH :: Int
  , scOffset :: Maybe (Int, Int)
  } deriving (Show, Eq, Generic)

instance ToJSON (SpriteClip key) where
  toJSON SpriteClip{scX,scY,scW,scH,scOffset} = case scOffset of
    Nothing -> toJSON (scX, scY, scW, scH)
    Just (ofsX, ofsY) -> toJSON (scX, scY, scW, scH, ofsX, ofsY)

instance FromJSON (SpriteClip key) where
  parseJSON v =
    (do
      (x,y,w,h) <- parseJSON v
      return SpriteClip { scX = x, scY = y, scW = w, scH = h, scOffset = Nothing })
    <|>
    (do
      (x,y,w,h,ofsX,ofsY) <- parseJSON v
      return SpriteClip { scX = x, scY = y, scW = w, scH = h, scOffset = Just (ofsX, ofsY) })

-- | Generalized sprite sheet data structure
data SpriteSheet key img delay = SpriteSheet
  { ssAnimations :: Animations key (SpriteClip key) delay
  , ssImage :: img
  } deriving (Generic)

-- | One way to represent sprite sheet information.
--   JSON loading is included.
data SpriteSheetInfo key delay = SpriteSheetInfo
  { ssiImage :: FilePath
  , ssiAlpha :: Maybe Color
  , ssiClips :: [SpriteClip key]
  , ssiAnimations :: Map Text [(FrameIndex, delay)]
  } deriving (Show, Eq, Generic)

instance ToJSON delay => ToJSON (SpriteSheetInfo key delay) where
  toJSON SpriteSheetInfo{ssiImage,ssiAlpha,ssiClips,ssiAnimations} = object
    [ "image" .= ssiImage
    , "alpha" .= ssiAlpha
    , "clips" .= ssiClips
    , "animations" .= ssiAnimations
    ]

instance FromJSON delay => FromJSON (SpriteSheetInfo key delay) where
  parseJSON (Object o) = do
    image <- o .: "image"
    alpha <- o .: "alpha"
    clips <- o .: "clips"
    anis <- o .: "animations"
    return SpriteSheetInfo { ssiImage = image, ssiAlpha = alpha, ssiClips = clips, ssiAnimations = anis }
  parseJSON _ = mzero

-- | Generate animations given each constructor
animations :: (Enum key, Bounded key) => (key -> [Frame loc delay]) -> Animations key loc delay
animations getFrames = Animations $ V.fromList $ map (V.fromList . getFrames) [minBound..maxBound]

-- | Lookup the frames of an animation
framesByAnimation :: Enum key => Animations key loc delay -> key -> V.Vector (Frame loc delay)
framesByAnimation (Animations as) k = as V.! fromEnum k

data Loop
  = Loop'Always -- ^ Never stop looping. Animation can never be completed.
  | Loop'Count Int -- ^ Count down loops to below zero. 0 = no loop. 1 = one loop. 2 = two loops. etc.
  deriving (Show, Eq, Generic)

-- | State for progression through an animation
--
-- > example = Position minBound 0 0 Loop'Always
data Position key delay = Position
  { pKey :: key -- ^ Index for the animation.
  , pFrameIndex :: FrameIndex -- ^ Index wihin the animation. WARNING: Modifying to below zero or equal-to-or-greater-than-the-frame-count will throw out of bounds errors.
  , pCounter :: delay -- ^ Accumulated units to end of the frame. Will continue to compound if animation is completed.
  , pLoop :: Loop -- ^ How to loop through an animation. Loop'Count is a count down.
  } deriving (Show, Eq, Generic)

-- | New `Position` with its animation key to loop forever
initPosition :: (Num delay) => key -> Position key delay
initPosition key = initPositionWithLoop key Loop'Always

-- | New `Position` with its animation key with a limited loop
initPositionLoops :: (Num delay) => key -> Int -> Position key delay
initPositionLoops key count = initPositionWithLoop key (Loop'Count count)

-- | New `Position`
initPositionWithLoop :: (Num delay) => key -> Loop -> Position key delay
initPositionWithLoop key loop = Position
  { pKey = key
  , pFrameIndex = 0
  , pCounter = 0
  , pLoop = loop
  }

-- | You can ignore. An intermediate type for `stepPosition` to judge how to increment the current frame.
data FrameStep delay
  = FrameStep'Counter delay -- ^ New counter to compare against the frame's delay.
  | FrameStep'Delta delay -- ^ How much delta to carry over into the next frame.
  deriving (Show, Eq, Generic)

-- | Intermediate function for how a frame should be step through.
stepFrame :: (Num delay, Ord delay) => Frame loc delay -> Position key delay -> delay -> FrameStep delay
stepFrame Frame{fDelay} Position{pCounter} delta =
  if pCounter + delta >= fDelay
    then FrameStep'Delta $ pCounter + delta - fDelay
    else FrameStep'Counter $ pCounter + delta

-- | Step through the animation resulting a new position.
stepPosition :: (Enum key, Num delay, Ord delay) => Animations key loc delay -> Position key delay -> delay -> Position key delay
stepPosition as p d =
  case frameStep of
    FrameStep'Counter counter -> p{pCounter = counter }
    FrameStep'Delta delta -> stepPosition as p' delta
  where
    frameStep = stepFrame f p d
    fs = unAnimations as V.! fromEnum (pKey p)
    f = fs V.! pFrameIndex p
    p'= case pLoop p of
      Loop'Always -> p{pFrameIndex = (pFrameIndex p + 1) `mod` V.length fs, pCounter = 0}
      Loop'Count n -> let
        index = (pFrameIndex p + 1) `mod` V.length fs
        n' = if index == 0 then n - 1 else n
        in p
          { pFrameIndex = if n' < 0 then pFrameIndex p else index
          , pCounter = 0
          , pLoop = Loop'Count n' }

-- | Use the position to find the current frame of the animation.
currentFrame :: (Enum key, Num delay) => Animations key loc delay -> Position key delay -> Frame loc delay
currentFrame anis Position{pKey,pFrameIndex} = (framesByAnimation anis pKey) V.! pFrameIndex

-- | Use the position to find the current location, lik a sprite sheet clip, of the animation.
currentLocation :: (Enum key, Num delay) => Animations key loc delay -> Position key delay -> loc
currentLocation anis p = fLocation (currentFrame anis p)

-- | The animation has finished all its frames. Useful for signalling into switching to another animation.
--   With a Loop'Always, the animation will never be completed.
isAnimationComplete :: (Enum key, Num delay, Ord delay) => Animations key loc delay -> Position key delay -> Bool
isAnimationComplete as p = case pLoop p of
  Loop'Always -> False
  Loop'Count n -> n < 0 && pFrameIndex p == lastIndex && pCounter p >= fDelay lastFrame
  where
    frames = framesByAnimation as (pKey p)
    lastIndex = V.length frames - 1
    lastFrame = frames V.! lastIndex

-- | Cycle through the next animation key.
nextKey :: (Bounded key, Enum key, Eq key) => key -> key
nextKey key = if key == maxBound then minBound else succ key

-- | Cycle through the previous animation key.
prevKey :: (Bounded key, Enum key, Eq key) => key -> key
prevKey key = if key == minBound then maxBound else pred key

-- | Simple function diff'ing the position for loop change.
positionHasLooped
  :: Position key delay -- ^ Previous
  -> Position key delay -- ^ Next
  -> Bool
positionHasLooped Position{ pLoop = Loop'Count c } Position{ pLoop = Loop'Count c' } = c > c'
positionHasLooped Position{ pLoop = Loop'Always } _ = False
positionHasLooped _ Position{ pLoop = Loop'Always } = False

-- | Quick function for loading `SpriteSheetInfo`.
--   Check the example.
readSpriteSheetInfoJSON
  :: FromJSON delay
  => FilePath -- ^ Path of the sprite sheet info JSON file
  -> IO (SpriteSheetInfo key delay)
readSpriteSheetInfoJSON = readSpriteSheetInfo eitherDecode

readSpriteSheetInfoYAML
  :: FromJSON delay
  => FilePath -- ^ Path of the sprite sheet info JSON file
  -> IO (SpriteSheetInfo key delay)
readSpriteSheetInfoYAML = readSpriteSheetInfo eitherDecodeYAML

eitherDecodeYAML :: FromJSON a => BL.ByteString -> Either String a
eitherDecodeYAML = Y.decodeEither . BL.toStrict

readSpriteSheetInfo
  :: FromJSON delay
  => (BL.ByteString -> Either String (SpriteSheetInfo key delay))
  -> FilePath -- ^ Path of the sprite sheet info JSON file
  -> IO (SpriteSheetInfo key delay)
readSpriteSheetInfo decoder path = do
  metaBytes <- BL.readFile path
  case decoder metaBytes of
    Left _err -> error $ "Cannot parse Sprite Sheet Info \"" ++ path ++ "\""
    Right ssi -> return ssi

-- | Quick function for loading `SpriteSheetInfo`, then using it to load its image for a `SpriteSheet`.
--   Check the example.
readSpriteSheetJSON
  :: (KeyName key, Ord key, Bounded key, Enum key, FromJSON delay)
  => (FilePath -> Maybe Color -> IO img) -- ^ Inject an image loading function
  -> FilePath -- ^ Path of the sprite sheet info JSON file
  -> IO (SpriteSheet key img delay)
readSpriteSheetJSON = readSpriteSheet eitherDecode

readSpriteSheetYAML
  :: (KeyName key, Ord key, Bounded key, Enum key, FromJSON delay)
  => (FilePath -> Maybe Color -> IO img) -- ^ Inject an image loading function
  -> FilePath -- ^ Path of the sprite sheet info JSON file
  -> IO (SpriteSheet key img delay)
readSpriteSheetYAML = readSpriteSheet eitherDecodeYAML

readSpriteSheet
  :: (KeyName key, Ord key, Bounded key, Enum key, FromJSON delay)
  => (BL.ByteString -> Either String (SpriteSheetInfo key delay))
  -> (FilePath -> Maybe Color -> IO img)
  -> FilePath
  -> IO (SpriteSheet key img delay)
readSpriteSheet decoder loadImage infoPath = do
  SpriteSheetInfo{ssiImage, ssiClips, ssiAnimations, ssiAlpha} <- readSpriteSheetInfo decoder infoPath
  i <- loadImage ssiImage ssiAlpha
  let frame key = (key, map (\a -> Frame (ssiClips !! fst a) (snd a)) (ssiAnimations Map.! keyName key))
  let animationMap = Map.fromList $ map frame [minBound..maxBound]
  return $ SpriteSheet (animations $ (Map.!) animationMap) i
