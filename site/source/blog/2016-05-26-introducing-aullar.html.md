---
title: Introducing Aullar, the new editing engine
location: Stockholm, Sweden
---

Starting with the 0.4 release, Howl ships with a new, custom-written editing
engine. Code named "Aullar", the new editing engine replaces the previously used
engine [Scintilla] . In this post we'll have a look at the new editing engine
and what it brings to the table, some history and the rationale for introducing
it.

_(As the post became quite long, you might want to skip to the section on
[Aullar](#aullar) if you're primarily interested in reading about the new
things)._

READMORE

## In the beginning...

When Howl was started, its creator had some previous experience with
[Scintilla]. Scintilla is a free source code editing component written in C++
that has been around for a long time, and it's used by a lot of different
projects. It offers a rich set of functionality, including buffer and view
management, support for lexing, folding, completions, indentation guides, and a
lot, lot more. All of those bells and whistles makes it a good candidate for
quickly creating a powerful editor without having to create all the building
blocks yourself. The widespread usage of it also means that there will be a lot
of other users that will help with finding bugs and ensuring the stability of
the component.

So, Howl started out using Scintilla as the editing engine. However, the choice
was not done without certain reservations. As good as Scintilla is, and for all
it offers, it also has some drawbacks. For one, it has a rather cumbersome API.
Scintilla started its life an Windows control component, and it emulated the API
of the existing Window edit controls to make it an easy to use replacement for
those controls. For better or worse (in Howl's case the latter), this then made
the Scintilla API a message passing API in the standard Windows fashion similar
to other Windows controls. Even though later versions of Scintilla have made
efforts to provide a more consistent API the heritage is still very much there.

The need for archaic message passing using structs and a single API entry point
is one thing however, which can be (and was) papered over successfully using a
generated wrapper on Howl's side utilizing the LuaJIT FFI. It was harder to
abstract away other architectural issues with the Scintilla API. An example of
this is the very tight coupling in Scintilla between buffers (documents in
Scintilla lingo) and views. Using Scintilla it's for instance not possible to
create and work against a buffer without using the Scintilla view component,
which effectively ends up being a weird view/buffer hybrid. It should be noted
that this is not due to the any internal limitations within Scintilla, but
appears to solely be an unfortunate effect of the C API. In order for Howl to
provide a good API model on top of Scintilla there were a lot of hoops to jump
through. For instance, to provide stand-alone buffers from the Howl API, a
disconnected background Scintilla instance was employed, with buffers switched
back and forth into that instance as needed. Scintilla also had other
limitations, such as a maximum of 255 different styles available for a Scintilla
component. This too was worked around at the Howl side, but at the cost of
additional complexity.

_As an aside, there was a search for alternatives when Howl was created. The
major contender at the time was the built-in editing component in GTK+, the GTK
TextView. This has a rather clean and nice API, but is by itself not a great
base for a programming editor since it lacks many of the features one would
expect. However, there is also the [GtkSourceView] component which builds on top
of the basic TextView component and adds additional features. For a very brief
time at the beginning Howl was actually switched to use this instead of
Scintilla, but Scintilla quickly returned though, as GtkSourceView proved too
limited._

## The start of Aullar

The decision having been made, Howl proceeded with Scintilla as the core editing
component. There was a fair amount of work needed to make it fit into the way
Howl functioned, including the aforementioned API wrapper and the enabling of
stand-alone buffers in the Howl API, but also a lot of other things that needed
to be bridged between the Howl API and Scintilla, or otherwise worked around on
the Howl side.

All in all, Scintilla performed well, but a lot of things had to be shoe-horned
in. Other things were just not doable at all, as they would require Scintilla
itself to be modified, and had to be left out. And in lots of other areas where
Scintilla actually provided ready-made functionality, Howl still used its own
implementations. For example, Scintilla provides built-in support for lexing of
various programming languages. Howl didn't use this, as it instead employs LPEG
based lexing. Scintilla provides completion popups, but Howl didn't use those as
it has its own popups (which are vastly more aesthetically pleasing). Scintilla
has lots of default key bindings for various editing operations, but Howl used
its own key maps and disabled all Scintilla key mappings. The fact that
Scintilla was written in C++, while not a limitation in itself, meant that there
was a much higher barrier for modfifying it compared to the rest of Howl.

So, things worked, but from a long term perspective it wasn't ideal to be tied
to, and hampered by, Scintilla. The turning point came in the summer of 2014
with some issues for the (even at the time) older Ubuntu 12.04 version. The
[first report](https://github.com/howl-editor/howl/issues/28), resulting in a
full-blown core dump for Howl, was quickly identified as an issue with
Scintilla. This was fixed shortly thereafter in Scintilla, and the issue was
laid to rest. A while later the issue (or a similar variant thereof) resurfaced
for a later Scintilla version, and this time your humble author thought it would
be a good time to take a closer look at Scintilla's internals. However, that
quickly turned into a forage of the underlying GTK/Pango APIs instead. As has
happened to many a poor developer, the author, now armed with some inkling on
what would be required, soon found himself thinking that it _really shouldn't be
that hard_ to just write a tailor-made replacement.

Experienced developers of course recognize that for what is - a self-delusion
brought about by wishful thinking and an overly coarse-grained view of the goal.
Still, it was not the worst example of underestimation. For one, it was
understood that it would be a major undertaking requiring quite some time (even
though the initial estimation was, as one would expect, off by a significant
margin). Secondly, some of the building blocks were already in place since Howl
already had a FFI framework for working with all the needed GLib/GTK/Pango
libraries, so that part was solved already. And thirdly, this new component
needed not be a full replacement for Scintilla, but only something which would
handle Howl's required subset of Scintilla functionality.

So after some conferring between developers, the work on Aullar was started.

## Aullar

The first work for Aullar was committed on July 1st, 2014. This was obviously a
very crude implementation with only the bare basics in place, but it was still
very encouraging as very little time had passed since its original conception
and there was already something to show for it. Development then proceeded at a
steady pace, and directly after the 0.3 release in September 2015 a much more
complete version of Aullar was merged into the master branch.

While the intention at the outset was to provide the bare minimum of Scintilla's
features that would allow Howl to work as it should (but sans Scintilla's
limitations), there will be changes just from doing something anew. Also, there
has been some feature creep over the course of Aullar's development resulting in
new features as well. Below, we'll attempt to highlight some of changes with
Aullar compared to Scintilla.

### Transparency, oh my...

While transparency and gaudy effects in general aren't for everyone, it should
definitely be possible to achive with Howl. This was not possible with
Scintilla, which painted text with a solid background color, but was enabled
from start with the new editing engine. After Aullar was merged into the master
branch, the theming support and UI for Howl was reworked to enable support for
these kind of effects, and then not only for the editor view but for supporting
UI elements. Nearly everything in Howl can now be styled using translucent
effects if one so wishes. The below screenshot using the new Steinom theme shows
off some of the resulting capabilities.

![Transparency support](blog/introducing-aullar/buffer-search-forward.png)

### Variable height styles

Scintilla was limited to single height lines, and it's easy to see why as it
simplifies layout handling greatly. When building Aullar it was decided to build
it from the start with support for varying style heights. Although it's
sparingly used at the moment, this enables all kinds of wonderous things in
future. The below screenshot in the Monokai theme, which is now the default,
shows this in action:

![Varying height](blog/introducing-aullar/aullar-varying-height.png)

### Smarter code blocks

Howl has pretty good support for sub lexing a language within another language
(provided the language in question has a proper Howl language bundle). Visually,
the sub lexed language is shown as a block. With Scintilla, there was no
alternative other than displaying the sub-lexed lines with a full-width
background color. This ends up being effective, but not particularly subtle.
With Aullar, a code block is displayed with just the needed amount of background
color:

![Code blocks](blog/introducing-aullar/aullar-code-blocks.png)

### Better flairs

Named "indicators" in Scintilla, "flairs" are highlighting overlays that are
used for visually marking a certain piece of text. With Scintilla, it was not
possible to actually specify a certain text color to use with an indicator,
which is a surprisingly big issue since it's very limiting in the effects that
can be achieved. The closest one would get would be to specify a solid color
with transparency applied, but it would still end up looking washed out.

Needless to say, this is no longer the case in Howl, where one can now do so,
but still of course specify all kinds of transparency if wanted. Flairs also
ended up being a very important building block, with everything from the cursor
and the current line marker to the selection being implemented as flairs.

![Flairs](blog/introducing-aullar/aullar-flairs.png)

### What the eyes don't see

![Tip](blog/introducing-aullar/tip-of-the-iceberg.png)

While the previous sections highlight some of the visible new things with
Aullar, there was a of course a lot of work that went into the back-end side of
things to make this possible. As mentioned previously Scintilla not only
provided the view component, but also provided buffer management and associated
groundwork. Replacing Scintilla meant implementing all of the support needed for
an advanced editor in Howl itself - including such things as working buffer
management (using gap buffers), efficient coalescing of editing operations,
multiple view handling, undo management, and much more. As this post is long
enough already we won't go into that in any greater detail. However, there are
some non-visual benefits that are worth pointing out. One for example is the
obvious removal of an extra dependency, written in a different language. Not
only is that nice by itself, but it also cuts down on building time and has the
nice effect that the Howl executable was shrunk by 50%. That is of course offset
by needing more bytecode in Howl, but the net effect is still positive. Looking
at runtime memory usage Howl now appears to be leaner than the previous 0.3
release, which is actually surprising considering that we now allow for more
memory use in order to lift previous limitations (e.g. the limit of allowed
styles in an editor is now 65536 instead of the previous 255). With some example
files open the virtual memory used is now down to 75% of what is was, with the
resident memory size also being slightly smaller at 96% of the previous value.
While this could also be due to factors other than Aullar vs Scintilla, it's
nonetheless nice to see that the 0.4 release will be an improvement in this
regard.

## Parting thoughts

Aullar has now been in use in the master branch for over half a year, and with
the imminent 0.4 release it will officially replace Scintilla. Looking back, it
was still a good decision to start out with Scintilla, as it allowed Howl to get
off the ground faster and quickly become a nice and stable editor. A lot of
initial work has been invested in Aullar, but with that in the past it's great
to now have a custom-written engine tailored for Howl, that can be tweaked and
adapted for future needs.

--
[Scintilla]: http://www.scintilla.org
[GtkSourceView]: (https://wiki.gnome.org/Projects/GtkSourceView)
