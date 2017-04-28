---
title: Building and installing Howl on Windows
---

# Using the binary distributions

*TODO*

# Building from source


## Setting up the build environment

First of all, you need [MSYS2](http://www.msys2.org/). Once that's been
installed, open up the MSYS2 shell and run:

```
pacman -S make tar git wget patch
pacman -S mingw32/mingw-w64-i686-gcc mingw32/mingw-w64-i686-pkg-config
pacman -S mingw32/mingw-w64-i686-gtk3 mingw32/mingw-w64-i686-imagemagick
```

You can omit ImageMagick if desired, but then the Howl binary won't have the
icon files embedded inside.

## Building

**Open the MinGW32 shell. If you stay in the normal MSYS Shell, the build
will fail with obscure, downright weird errors.** If you accidentally began
building in the MSYS Shell, make sure you run `make clean` before continuing!

Run:

```
make MAKE_RC=1
```

to build with the icons embedded or plain:

```
make
```

to build without them.

## Using Howl outside MSYS2

The binary file that's built won't be usable outside MSYS2. To make a version
usable within the rest of Windows, run:

```
make windist
```

This will a `windist` directory, containing:

- A copy of Howl with the proper DLLs in place.
- A file `howl.zip`, suitable for portable usage.

If you want an installer, make sure Inno Setup is installed and in your PATH,
and run:

```
make wininst
```
