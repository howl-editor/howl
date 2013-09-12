# Clojure mode

## What is it?

This is a Clojure mode for the Howl editor. It builds upon Lisp mode, and adds basic support for nrepl.
Once installed you have two new commands for use with Clojure projects:

- `nrepl-connect`: Allows you to connect to an existing nrepl instance
- `nrepl-eval`: Allows you to eval typed-in expressions in the currently connected nrepl

Once an nrepl instance is connected, it will automatically be used for additional completions.

## Requirements

At this point you're required to have the `luasocket` Lua library installed on your system, outside of the Howl editor. You can install that by using Luarocks. Should that not be installed, `nrepl-connect` will raise an error alerting you to the fact.

## License

Please see LICENSE.md.