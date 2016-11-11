---
title: Howl 0.4.1 released!
location: Stockholm, Sweden
---

We are very happy to announce the release of [Howl](http://howl.io/) 0.4.1
(download available [here](/getit.html)). This is a minor maintenance release,
and as such it contains mainly compatibility fixes for a few bigger issues:

- Support for theming changes in newer Gtk versions

Newer versions of Gtk+ 3 introduced changes with regards to custom theming,
resulting in the following error when trying to start Howl:

```
(howl:2048): Gtk-WARNING **: Theme parsing error: <data>:11:31: Using Pango
syntax for the font: style property is deprecated; please use CSS syntax
```

- Fix Howl UI layout for some version/combination of WM/compositor, etc.

As seen on ElementaryOS, there was a problem that manifested itself as a very
wide margin outside of the actual Howl window. Issue
[200](https://github.com/howl-editor/howl/issues/200) has more information.

- FreeBSD build fixes

Thanks to [maxc01](https://github.com/maxc01) Howl now builds cleanly out of the
box on FreeBSD without the need for any patches (still requires `gmake` though).

- Themable scrollbars

Scrollbars can now be themed as well (requires newer versions of Gtk). While
this may not sound like a show stopper in itself, the lack of styling became a
real problem when the default scrollbar color blended in to well with a theme,
in effect making it invisible.
