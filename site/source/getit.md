---
title: Installation
---

# Installing Howl

Howl is developed on Linux, but it builds on other \*NIX platforms as well such
as FreeBSD and OpenBSD (with other \*BSDs presumably requiring only little
work). It should be possible to port to OSX or Windows, should any brave soul be
willing to put in the work.

You can install Howl by building it from source, either from a release or by
cloning the repository from Github.

## Latest release

The latest release of Howl is 0.5.2. It was released at 2017-10-06, and is
available for download from:

[https://github.com/howl-editor/howl/releases/download/0.5.2/howl-0.5.2.tgz](https://github.com/howl-editor/howl/releases/download/0.5.2/howl-0.5.2.tgz)

_MD5_: 63b604888656212d94f2e98cc5bc2207

_SHA1_: 947742c70c141308f92426c79d8adf87fa078196

__Release notes:__
[Howl 0.5 Released](/blog/2017/06/30/howl-0-5-released.html)

## Building Howl from source

### Build requirements

Howl requires the following build dependencies:

- `wget`: For auto-downloading build dependencies (only needed when building
from a code checkout, as the release tarball contains pre-downloaded
dependencies).

- `GTK+`: Version >= 3, with development files.

  For example:

  * On Debian-based based systems you would need the `libgtk-3-dev` package.
  * For Fedora you would need the `gtk3-devel` package.

- `C compiler`: Howl has a very small C core itself, and it embedds a few
dependencies built in C.

### Building

Download and unpack a Howl release, or get the source from
[Github](https://github.com/howl-editor/howl), either by cloning the repository
or by download a Zip-file of the desired branch/tag.. Compile Howl by issuing
`make` from the `src` directory (`gmake` for \*BSD). When building directly from
a source checkout, in-app dependencies will automatically be downloaded for you
using `wget`. Once it's built, you can if you want run it directly as is from
the `src` directory, like so: `$ ./howl`. To install it properly however, so
that it integrates into your desktop, you'll want to run the `make install`
command.

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

We developers use Howl every day for our daily development, and we try our best
to keep the master branch stable and suitable for production usage at all times.
If you want to follow along with the latest updates for Howl, simply clone the
repository from Github and build as per the above instructions. To update just
pull the latest additions, and issue make again from the src directory. _Don't
forget to make again though_, as this would cause stale byte code to be loaded
and confusion to arise.

## Older releases

### Howl 0.5.1 released 2017-07-06

_MD5_: 0529b657f441acbc2e334a3dcd2d49d9

_SHA1_: 1e48e4b2e50b6e587007a3de641349b57f4fbd1e

[Download](https://github.com/howl-editor/howl/releases/download/0.5.1/howl-0.5.1.tgz)

### Howl 0.5 released 2017-06-30

_MD5_: 5d254146f174455156cabcbdf1f3c95c

_SHA1_: 5fb65ebd9e916ca8a63f42f3dce11c6245aeeec5

[Download](https://github.com/howl-editor/howl/releases/download/0.5/howl-0.5.tgz)

### Howl 0.4.1 released 2016-10-14

_MD5_: 9ef463f4d8b31e8954e70e507fbb1858

_SHA1_: 1434af03c5bc9f10d64ef93ca0ae68ccc7092fee

[Download](https://github.com/howl-editor/howl/releases/download/0.4.1/howl-0.4.1.tgz)

### Howl 0.4, released 2016-05-31

[Download](https://github.com/howl-editor/howl/releases/download/0.4/howl-0.4.tgz)

_MD5_: aa4761e657b2cedbae0f2f843731a17f

_SHA1_: 557fea5af8e6768ea6408ab2d11db63c0ae5fdf4

### Howl 0.3, released 2015-09-02.

[Download](https://github.com/howl-editor/howl/releases/download/0.3/howl-0.3.tgz)

_MD5_: 30014d5a9d6adda87c8f0048afc25893

_SHA1_: 102f47badbcfd43c0c1f1d3921d70ba11767b0e4

[Release notes](/blog/2015/09/01/howl-0-dot-3-released.html)

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
