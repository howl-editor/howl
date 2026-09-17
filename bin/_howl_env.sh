# Copyright 2026 The Howl Developers
# License: MIT (see LICENSE.md at the top-level directory of the distribution)
#
# Shared preamble for the scripts in bin/. Sets ROOT and HOWL. Source it, don't run it:
#
#   . "$(dirname "$0")/_howl_env.sh"
#
# It deliberately does not change directory, so relative paths given on the command line
# keep resolving against the caller's working directory. Scripts that walk the tree
# themselves (lint-all, run-all-specs, howl-compile-stale) cd to "$ROOT" on their own.

ROOT=$(cd "$(dirname "$0")/.." && pwd)

HOWL=
for howl in "$ROOT/bin/howl" "$ROOT/src/howl"; do
  if [ -e "$howl" ]; then
    HOWL=$howl
    break
  fi
done

if [ -z "$HOWL" ]; then
  echo "Could not locate howl executable - run 'make -C src' first" >&2
  exit 1
fi
