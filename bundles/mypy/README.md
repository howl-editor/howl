# Mypy bundle

## What is it?

This is a bundle that lets you use the mypy type checker in your Python code.
To use it, just set `inspectors_on_idle` and `inspectors_on_save` to `mypy` for
your Python files, or put this in your `init.moon`:

```moonscript
howl.mode.configure 'python',
  inspectors_on_idle: 'mypy'
  inspectors_on_save: 'mypy'
```

## License

Copyright 2017 The Howl Developers
License: MIT (see LICENSE.md at the top-level directory of the distribution)
