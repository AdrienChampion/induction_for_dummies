# Induction For Dummies

Induction as a formal program verification technique for the uninitiated.

## Building

> This book relies mostly on [`mdbook`] and [`mdbook-linkcheck`].

[Install Rust] if you haven't already, make sure it's not outdated, and retrieve the dependencies.

```bash
# Update Rust toolchain.
> rustup update
# Install/update `mdbook` and `mdbook-linkcheck`.
> make update_deps
```

Use the [`manager`](#Manager) to run the tests if you want, but be aware that this requires the
binaries for [Z3] and mikino to be in your path. You can download its latest release [here][Z3
releases].

```bash
> make test
# or
> cargo run
```


## Manager

The manager is written in Rust, its code is in the `manage` directory. It is responsible for
testing the whole book. This relies mostly on [`mdbook`] and [`mdbook-linkcheck`], but the manager
also tests all files appearing in a `code` directory inside `src` (recursively).

Such a file `file.ext` is expected to either

- be a Rust file (`ext` is `rs`), meaning they are tested by [`mdbook`] if reachable, or
- have an associated `file.ext.out` *output* file.

The output file contains the output of running a certain command on `file.ext`, which depends on
`ext`. For instance, `file.smt2` should have a `file.smt2.out` companion file containing the output
of `z3 file.smt2`.


[Install Rust]: https://www.rust-lang.org/tools/install
(Rust installation homepage)
[`mdbook`]: https://github.com/rust-lang/mdBook
(mdbook on github)
[`mdbook-linkcheck`]: https://github.com/Michael-F-Bryan/mdbook-linkcheck
(mdbook-linkcheck on github)
[Z3]: https://github.com/Z3Prover/z3
(Z3 on github)
[Z3 releases]: https://github.com/Z3Prover/z3/releases
(Z3 releases on github)
