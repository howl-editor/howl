---
title: File selection improvements
location: Stockholm, Sweden
---

In this post we examine some performance enhancements that just landed in Howl's
master branch, greatly improving the performance of the recursive file selection
commands (_tl;dr: by a factor of between 30x and 32x_). These will be a part of
the next 0.6 release. We also mention some other new stuff such as the new
activities module.

READMORE

## Background

The issue of performance when opening files was first brought up in the [Gitter
channel](https://gitter.im/howl-editor/howl) back in August, where a user
wondered if anyone had any experience with using Howl for larger projects. The
user had issues with doing recursive file listings in a somewhat larger
directory, containing around 13K entries. There were basically two issues
reported:

- The file listing itself was too slow.

- When doing a recursive file listing (Tip: you can do this by pressing `ctrl_s`
from the ordinary `open` dialog), there was a timeout of 3 seconds, after which
the dialog opened with only partial (< 13K) results.

The reason for the timeout was basically sound - as the code loading the file
entries was run uninterruptibly the entire UI would freeze and and hang until
completion without providing any feedback to the user. Without any timeout it
would mean that Howl would seemingly hang without any possibility of cancelling.
However, it unfortunately meant that users were left without any way of loading
all entries from larger directories.

At the time there was some loose discussion about possible solutions, such as
switching to an async file listing API, using a faster, more low-level API for
listing the actual files, and doing some kind of profiling first of all. Nothing
was done at the time though.

## Falling down the rabbit hole

One of the main things your author is interested in adding for the next release
(0.6) is nicely integrated project searching using external tools such as ag,
rg, ack, etc. You can of course use any of the aforementioned tools with Howl
already today, by simply runnning them from within the project root (and the
resulting buffer actually has some navigation support built-in using `enter`).
The new integration is imagined to work differently however - the command would
run in a modal fashion and the results be presented to the user in an ordinary
selection list for quick navigation.

As a project search can potentially take quite a lot of time this presents a
similar problem to the recursive file listing above, as the command should first
run while the user waits with the results being presented afterwards. In
contrast to the file listing code at the time, running a command already uses
asynchronous APIs under the hood, so the application wouldn't seemingly hang.
However, that only helps with one part of the problem and results in other
issues. When run directly from a key binding such a command would now appear not
to run at all, and at some later time a selection list would popup unannounced.
If run from the command line it would leave the user with a blinking command
line prompt.

Thus the [activities](/doc/api/activities.html) module was born. The activities
provides support for running potentially longer operations that, while typically
still asynchronous, appear blocking to the user. Activities are user visible
when running for too long, and can be cancellable if supported. At the time
though (and still today), the new search itself wasn't anywhere near ready, but
there were other candidates for using the new module. Unsurprisingly, the
recursive file listing was one such example, where use of the module could also
help solve a known and irritating issue. Thus some time was spent in converting
the
[File.find](/doc/api/io/file.html#find) to be asynchronous in supported
contexts, and converting the recursive file listing code to use the new
activities module. And voila! Below you can see this in effect, as we switch to
a recursive file listing in a very large directory.

![activity](/images/blog/file-performance/howl-activity.png)

## Performance

Having the activites support in place was great, and it fixed one of the
original issues with large directories - users could now list a directory no
matter how large, provided they were willing to wait sufficiently (and provided
RAM allowed it). That still left the other issue of performance, as users would
unfortunately have to be willing to wait a rather long time for larger
directories to load. When all you want to do is open a file, performance quickly
becomes an issue. In a way, using an activity only highlighted how slow this
could be as it was now possible to wait for the loading to complete. This led to
the next part of the work; identifying the issues with and improving the
underlying performance of the file commands. Before going into any more details,
we should note that there are two primary ways of recursively listing a
directory from within Howl:

- A recursive file listing, as seen above

- A project file listing (using the `project-open` command)

In the latter case the file entries can either be loaded from a VC, such as git,
or using a direct scan like the recursive file listing. In the case of Git, it's
faster to get a list of project entries from Git itself than to scan the
directory ourselves.

### The baseline

So, how slow is slow? If we look at the 0.5 release, performing the two types of
project listings discussed above for a directory with 30K entries spread out in
sub directories, we get the below numbers:

| What             | Directory size | Time    |
-------------------|----------------|----------
| Direct file scan | ~30K entries   | ~22.6 s |
| Git loading      | ~30K entries   | ~9.2 s  |

A directory with 30K entries was chosen for benchmarking, which hopefully should
more than account for most projects typically worked with. As a reference, a
[report from
2012](http://royal.pingdom.com/2012/04/16/linux-kernel-development-numbers/)
suggests that the 2.6.11 Linux kernel consisted of 17090 different files.

  As can be seen above loading directory entries from Git rather than scanning
it ourselves is a lot faster, but both operations are slow enough as to be
unusable.

### Removing some avoidable stat calls

Fetching information about a file from the file system, such as file type, etc.
is generally a very expensive operation, and something you'll want to keep to a
minimum if you're looking at performance. None of Howl's code for file listings
had been optimized with this in mind, so the first thing major thing changed was
to allow creating instances of [File] with a predetermined type, thus avoiding
any extra lookups later for the cases where the file type is already known. This
happen to be the case both for recursive file scans and when loading entries
from git (in git's case we don't actually have the full type information, but
just knowing whether it's a directory or not is sufficient in this instance).
This gives a nice performance boost:

| What             | Directory size | Time    |
-------------------|----------------|----------
| Direct file scan | ~30K entries   | ~15.5 s |
| Git loading      | ~30K entries   | ~2.8 s  |

### Optimizing the selection preparation step

It turns out that it's not only the actual directory reading that accounts for
the time it takes to present the user with a file selection list. Instead, the
process can be seen as having three steps:

- Load a list of possible files (from VC or recursive directory scan)

- Create a new data set suitable for displaying and matching

- Create a matcher object used for filtering and getting entries to show

We have so far only looked at the first step. As part of the optimization
efforts the third part, the matcher, was also optimized for a smaller speedup.
However, it's now time to have a look at the second part. This part hadn't been
optimized at all, and it created styled list entries by constructing
[howl markup](doc/api/ui/markup/howl.html) for each entry. The markup parsing is
not typically a performance issue, but it quickly adds up in this case. We avoid
this by creating
[StyledText](/doc/api/ui/styled_text.html) instances directly:

| What             | Directory size | Time    |
-------------------|----------------|----------
| Direct file scan | ~30K entries   | ~14.8 s |
| Git loading      | ~30K entries   | ~1.5 s  |

This gives us another boost, but not so marked as the first, and really only
noticeable for the Git case.

### Getting rid of abstractions

Abstractions, such as Howls [File], are great and allows code to be written in a
clear and straightforward fashion. You do however pay a price for using them -
the simplicity offered often comes at the expense of performance. In the
original discussion it was mentioned that an external command line file selector
had no performance issues for the directory in question. This is not surprising
since a small, focused, utility more easily can afford to do away with all kinds
of abstractions and focus on a sole task (the Unix philosophy anyone?).

Howl, however, is not primarily a file selection program, but we can still gain
a lot of performance by cutting away some abstraction. Even after optimizing the
File class, the results are still abysmal for the direct file scans, and there's
not that much more to be done for the File class without crippling it for other
uses. As an experiment, and in order to get some idea of posssible performance
targets, a simple recursive test listing script was written using only the glib
primitives, which provided some promising results.

As our final step then, we forego use of [File] instances altogether for this
particular use case, and instead we work simply on relative string paths both
for project and recursive listings, changing the commands and the supporting
code. This makes the code in question slightly less useful and more of a special
case, but to good effect:

| What             | Directory size | Time    |
-------------------|----------------|----------
| Direct file scan | ~30K entries   | ~0.7 s  |
| Git loading      | ~30K entries   | ~0.3 s  |

## Wrap up and finishing notes..

In conclusion, recursive file listings were sped up by a factor of between _30x_
and _32x_. If you're working on large projects this should be very welcome! If
you're anything like the author, you might not have reflected much on the
performance previously, but will still find things a lot snappier now compared
to before.

As far as optimizations go, here is where we stop now. There are potentially
more optimizations that could be done, but the low hanging fruits have been
picked.

We didn't talk much on what happens once all directory entries are loaded, but
this part to had to be changed in order to cope with the larger data sets.
Howl's matcher is now more efficient, which benefits all, and it also supports
larger data sets by returning partial matches when the number of matching
results would be larger than 1000.

Finally, this post touched on one of the rabbit holes the author went down into
on the way to integrated project searching. Another related addition was that of
breadcrumbs (back and forth navigation), so make sure to [check that
out](/doc/manual/files.html#navigating-buffers) as well if you're following
master, and provide any feedback you might have.

Happy howling!

[File]: /doc/api/io/file.html
