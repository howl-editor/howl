---
title: Installation
---

# Installing Howl

Howl is developed on Linux, but it should build on other \*NIX platforms as well
such as the \*BSD family, although this hasn't been verified yet (there's also
nothing the author is aware of that should prevent it from being ported to OSX
or Window, should any brave soul like to try).

You can install Howl by building it from source, either from a release or by
cloning the repository from Github.

### Latest release

The latest release is Howl 0.1, available for download from
[http://download.howl.io/release/howl-0.1.tgz](http://download.howl.io/release/howl-0.1.tgz)

__MD5 checksum__: c8128a9d1510c91ae27603787b17010a

__SHA1 checksum__: 16cfdd89d537ca22881c1646832270165dd05d17

### Build requirements

Howl requires the following build dependencies:

- `wget`: For auto-downloading build dependencies (only needed when building
from a code checkout, as the release tarball contains pre-downloaded
dependencies).

- `GTK+`: Version >= 3, with development files.

  As an example, on Debian-based based systems you would need the `libgtk-3-dev` package.

- `C/C++ compiler`: Howl has a very small C core itself, but it embedds dependencies built both
  in C and C++.

This list is not guaranteed to be complete, so please let me know if there's anything missing
(or if this works well for you I love to hear that as well).

### Building

Download and unpack a Howl release, or get the source from
[Github](https://github.com/nilnor/howl), either by cloning the repository or by
download a Zip-file of the desired branch/tag.. Compile Howl by issuing `make`
from the `src` directory. When building directly from a source checkout, in-app
dependencies will automatically be downloaded for you using `wget`. Once it's
built, you can if you want run it directly as is from the `src` directory, like
so: `$ ./howl`. To install it properly however, so that it integrates into your
desktop, you'll want to run the `make install` command.

*Example session:*

```
[nilnor@cohen:~/tmp]% git clone https://github.com/nilnor/howl.git
Cloning into 'howl'...
remote: Counting objects: 7924, done.
[..]
Checking connectivity... done
[nilnor@cohen:~/tmp]%
[nilnor@cohen:~/tmp]% cd howl/src/
[nilnor@cohen:~/tmp/howl/src]% make -j 4
[snipped download and compiling]
make  49.44s user 4.21s system 81% cpu 1:05.74 total
[nilnor@cohen:~/tmp/howl/src]% sudo make install
[sudo] password for nilnor:
Installing to /usr/local..
All done.
```

Howl installs to `/usr/local` by default, but you can specify a different location to install to
by specifying `PREFIX` to make, like so:

```shell
make PREFIX=~/.local
make PREFIX=~/.local install
```

*NB: If you install to a non-standard location, your desktop environment might
not pick up on the fact that Howl is installed, and the application icon will
look ugly as the result.*

### Tracking the latest from Github

If you want to track the latest version of Howl, clone the repository from
Github and build as per the above instructions. To update just pull the latest
additions, and issue make again from the src directory. Don't forget to make
again, as this would cause stale code to be loaded.
