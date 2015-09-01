---
title: Installation
---

# Installing Howl

Howl is developed on Linux, but it should build on other \*NIX platforms as well
such as the \*BSD family, although this hasn't been verified yet (there's also
nothing the author is aware of that should prevent it from being ported to OSX
or Window, should any brave soul like to try).

You can install Howl by building it from source, either from a release or by
cloning the repository from Github. If you're on ArchLinux you can install the
Arch package available from the AUR (after verifying the version).

## Latest release

The latest release of Howl is 0.3. It was released at 2015-09-02, and is
available for download from:

[https://github.com/howl-editor/howl/releases/download/0.3/howl-0.3.tgz](https://github.com/howl-editor/howl/releases/download/0.3/howl-0.3.tgz)

_MD5_: 30014d5a9d6adda87c8f0048afc25893

_SHA1_: 102f47badbcfd43c0c1f1d3921d70ba11767b0e4

__Release notes:__
[Howl 0.3 Released](/blog/2015/09/02/howl-0-dot-3-released.html)

## Building Howl from source

### Build requirements

Howl requires the following build dependencies:

- `wget`: For auto-downloading build dependencies (only needed when building
from a code checkout, as the release tarball contains pre-downloaded
dependencies).

- `GTK+`: Version >= 3, with development files.

  As an example, on Debian-based based systems you would need the `libgtk-3-dev` package.

- `C/C++ compiler`: Howl has a very small C core itself, but it embedds dependencies built both
  in C and C++.

### Building

Download and unpack a Howl release, or get the source from
[Github](https://github.com/howl-editor/howl), either by cloning the repository or by
download a Zip-file of the desired branch/tag.. Compile Howl by issuing `make`
from the `src` directory. When building directly from a source checkout, in-app
dependencies will automatically be downloaded for you using `wget`. Once it's
built, you can if you want run it directly as is from the `src` directory, like
so: `$ ./howl`. To install it properly however, so that it integrates into your
desktop, you'll want to run the `make install` command.

*Example session:*

```
[nilnor@cohen:~/tmp]% git clone https://github.com/howl-editor/howl.git
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

## Distribution packages

### ArchLinux

![ArchLinux](logos/archlinux-logo.png)

Courtesy of [Bartłomiej Piotrowski](http://bpiotrowski.pl), Howl is available as
a package in the [Arch User Repository](https://aur.archlinux.org/) (AUR). You
can install it using your AUR
[helper](https://wiki.archlinux.org/index.php/AUR_Helpers) of choice, or by
doing a manual install from AUR. As an example, using the `packer` helper you
can install Howl by issuing:

```shell
$ sudo packer -S howl-editor
```

## Older releases

### Howl 0.2.1, released 2014-04-29.

[Download](http://download.howl.io/release/howl-0.2.1.tgz)

_MD5_: 8caf43a8631041677a4bc4df9c6c0f18

_SHA1_: 79a582e4b31012073e2dc15678814d5c46596fa9

### Howl 0.2, released 2014-04-29.

[Download](http://download.howl.io/release/howl-0.2.tgz)

_MD5_: 616598045baa8633f67af0a21c3afacf

_SHA1_: cbcebc01b1fe4762895e914d989c17457058f2ff

---

### Howl 0.1.1, released 2014-03-15.

[Download](http://download.howl.io/release/howl-0.1.1.tgz)

_MD5_: b7fe35018a7016e66b93920a67444b0d

_SHA1_: 9542dd53c25045e33732f7210b0c68ebff156d41

---

### Howl 0.1, released 2014-03-15.

[Download](http://download.howl.io/release/howl-0.1.tgz)

_MD5_: c8128a9d1510c91ae27603787b17010a

_SHA1_: 16cfdd89d537ca22881c1646832270165dd05d17
