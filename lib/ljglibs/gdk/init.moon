-- Copyright 2013-2023 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

core = require 'ljglibs.core'

def = {
  constants: {
    prefix: 'GDK_'

    -- GdkEventType;
    'NOTHING',
    'DELETE',
    'DESTROY',
    'EXPOSE',
    'MOTION_NOTIFY',
    'BUTTON_PRESS',
    '2BUTTON_PRESS',
    'DOUBLE_BUTTON_PRESS',
    '3BUTTON_PRESS',
    'TRIPLE_BUTTON_PRESS',
    'BUTTON_RELEASE',
    'KEY_PRESS',
    'KEY_RELEASE',
    'ENTER_NOTIFY',
    'LEAVE_NOTIFY',
    'FOCUS_CHANGE',
    'CONFIGURE',
    'MAP',
    'UNMAP',
    'PROPERTY_NOTIFY',
    'SELECTION_CLEAR',
    'SELECTION_REQUEST',
    'SELECTION_NOTIFY',
    'PROXIMITY_IN',
    'PROXIMITY_OUT',
    'DRAG_ENTER',
    'DRAG_LEAVE',
    'DRAG_MOTION',
    'DRAG_STATUS',
    'DROP_START',
    'DROP_FINISHED',
    'CLIENT_EVENT',
    'VISIBILITY_NOTIFY',
    'SCROLL',
    'WINDOW_STATE',
    'SETTING',
    'OWNER_CHANGE',
    'GRAB_BROKEN',
    'DAMAGE',
    'TOUCH_BEGIN',
    'TOUCH_UPDATE',
    'TOUCH_END',
    'TOUCH_CANCEL',
    'EVENT_LAST',

    -- GdkEventMask;
    'EXPOSURE_MASK',
    'POINTER_MOTION_MASK',
    'POINTER_MOTION_HINT_MASK',
    'BUTTON_MOTION_MASK',
    'BUTTON1_MOTION_MASK',
    'BUTTON2_MOTION_MASK',
    'BUTTON3_MOTION_MASK',
    'BUTTON_PRESS_MASK',
    'BUTTON_RELEASE_MASK',
    'KEY_PRESS_MASK',
    'KEY_RELEASE_MASK',
    'ENTER_NOTIFY_MASK',
    'LEAVE_NOTIFY_MASK',
    'FOCUS_CHANGE_MASK',
    'STRUCTURE_MASK',
    'PROPERTY_CHANGE_MASK',
    'VISIBILITY_NOTIFY_MASK',
    'PROXIMITY_OUT_MASK',
    'SUBSTRUCTURE_MASK',
    'SCROLL_MASK',
    'TOUCH_MASK',
    'SMOOTH_SCROLL_MASK',
    'ALL_EVENTS_MASK',

    -- GdkModifierType
    'SHIFT_MASK',
    'LOCK_MASK',
    'CONTROL_MASK',
    'ALT_MASK',
    'SUPER_MASK',
    'HYPER_MASK',
    'META_MASK',
    'BUTTON1_MASK',
    'BUTTON2_MASK',
    'BUTTON3_MASK',
    'BUTTON4_MASK',
    'BUTTON5_MASK',

    -- GdkScrollDirection;
    'SCROLL_UP',
    'SCROLL_DOWN',
    'SCROLL_LEFT',
    'SCROLL_RIGHT',
    'SCROLL_SMOOTH'

    -- GdkCursor
    'X_CURSOR',
    'ARROW',
    'BASED_ARROW_DOWN',
    'BASED_ARROW_UP',
    'BOAT',
    'BOGOSITY',
    'BOTTOM_LEFT_CORNER',
    'BOTTOM_RIGHT_CORNER',
    'BOTTOM_SIDE',
    'BOTTOM_TEE',
    'BOX_SPIRAL',
    'CENTER_PTR',
    'CIRCLE',
    'CLOCK',
    'COFFEE_MUG',
    'CROSS',
    'CROSS_REVERSE',
    'CROSSHAIR',
    'DIAMOND_CROSS',
    'DOT',
    'DOTBOX',
    'DOUBLE_ARROW',
    'DRAFT_LARGE',
    'DRAFT_SMALL',
    'DRAPED_BOX',
    'EXCHANGE',
    'FLEUR',
    'GOBBLER',
    'GUMBY',
    'HAND1',
    'HAND2',
    'HEART',
    'ICON',
    'IRON_CROSS',
    'LEFT_PTR',
    'LEFT_SIDE',
    'LEFT_TEE',
    'LEFTBUTTON',
    'LL_ANGLE',
    'LR_ANGLE',
    'MAN',
    'MIDDLEBUTTON',
    'MOUSE',
    'PENCIL',
    'PIRATE',
    'PLUS',
    'QUESTION_ARROW',
    'RIGHT_PTR',
    'RIGHT_SIDE',
    'RIGHT_TEE',
    'RIGHTBUTTON',
    'RTL_LOGO',
    'SAILBOAT',
    'SB_DOWN_ARROW',
    'SB_H_DOUBLE_ARROW',
    'SB_LEFT_ARROW',
    'SB_RIGHT_ARROW',
    'SB_UP_ARROW',
    'SB_V_DOUBLE_ARROW',
    'SHUTTLE',
    'SIZING',
    'SPIDER',
    'SPRAYCAN',
    'STAR',
    'TARGET',
    'TCROSS',
    'TOP_LEFT_ARROW',
    'TOP_LEFT_CORNER',
    'TOP_RIGHT_CORNER',
    'TOP_SIDE',
    'TOP_TEE',
    'TREK',
    'UL_ANGLE',
    'UMBRELLA',
    'UR_ANGLE',
    'WATCH',
    'XTERM',
    'LAST_CURSOR',
    'BLANK_CURSOR',
    'CURSOR_IS_PIXMAP'

    -- GdkInterpType
    'INTERP_NEAREST'
    'INTERP_TILES'
    'INTERP_BILINEAR'
    'INTERP_HYPER'
   }
}

def.KEY_Return = 0xff0d

core.auto_loading 'gdk', def
