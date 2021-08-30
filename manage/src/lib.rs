//! Book manager.

mod error;

#[macro_export]
macro_rules! prelude {
    {} => { use $crate::prelude::*; }
}

/// Crate's prelude.
pub mod prelude {
    pub use std::path::Path;

    pub use error_chain::bail;
    pub use log;

    pub use crate::{
        prelude::err::{Res, ResExt},
        test, Conf,
    };

    pub mod err {
        pub use crate::error::*;
    }
}

prelude!();

/// Test configuration.
#[derive(Clone, Debug)]
pub struct Conf<'s> {
    check_smt2: Option<(bool, &'s str)>,
    check_mikino: Option<(bool, &'s str)>,
}
impl Default for Conf<'static> {
    fn default() -> Self {
        Self {
            check_smt2: Some((true, "z3")),
            check_mikino: Some((true, "mikino")),
        }
    }
}
impl<'s> Conf<'s> {
    /// Constructor.
    pub fn new() -> Self {
        Self {
            check_smt2: None,
            check_mikino: None,
        }
    }

    pub fn set_smt2(mut self, check: bool, command: &'s str) -> Self {
        self.check_smt2 = Some((check, command));
        self
    }
    pub fn set_mikino(mut self, check: bool, command: &'s str) -> Self {
        self.check_mikino = Some((check, command));
        self
    }

    fn get_smt2(&self) -> Res<(bool, &'s str)> {
        self.check_smt2.ok_or_else(|| {
            format!("[internal] no information provided for SMT file checking").into()
        })
    }
    fn get_mikino(&self) -> Res<(bool, &'s str)> {
        self.check_mikino.ok_or_else(|| {
            format!("[internal] no information provided for mikino file checking").into()
        })
    }

    /// Runs the actual checks.
    pub fn check(&self, path: impl AsRef<Path>) -> Res<()> {
        test::run(self, path)
    }
}

/// Test functions.
pub mod test {
    use std::io::Read;

    prelude!();

    #[test]
    fn test_all() -> () {
        simple_logger::SimpleLogger::new()
            .with_level(log::LevelFilter::Trace)
            .init()
            .expect("failed to initialize logger");
        let out = std::process::Command::new("pwd").output().unwrap();
        println!("pwd: {}", String::from_utf8_lossy(&out.stdout));
        let conf = Conf::default();
        match run(&conf, "..") {
            Ok(()) => (),
            Err(e) => {
                eprintln!("|===| Error(s):");
                e.pretty_eprint("| ");
                eprintln!("|===|");
                panic!("test failed")
            }
        }
    }

    /// Runs all the tests.
    pub fn run(conf: &Conf, path: impl AsRef<Path>) -> Res<()> {
        let path = path.as_ref();

        log::info!("testing book...");
        test::book(path)?;

        log::info!("testing code snippets");
        let mut src_path = path.to_path_buf();
        src_path.push("src");
        test::code_out(conf, src_path)?;

        log::info!("everything okay");
        Ok(())
    }

    /// Tests the book itself.
    pub fn book(path: impl AsRef<Path>) -> Res<()> {
        use std::process::Command;

        log::info!("building with `mdbook`");
        let status = Command::new("mdbook")
            .arg("build")
            .arg("--")
            .arg(path.as_ref())
            .status()
            .chain_err(|| "failed to run `mdbook test`")?;
        if !status.success() {
            bail!("`mdbook build` returned with an error")
        }

        log::info!("testing with `mdbook`");
        let status = Command::new("mdbook")
            .arg("test")
            .arg("--")
            .arg(path.as_ref())
            .status()
            .chain_err(|| "failed to run `mdbook test`")?;
        if !status.success() {
            bail!("`mdbook test` returned with an error")
        }
        Ok(())
    }

    macro_rules! dir_read_err {
        { $dir:expr } => {
            || format!("while reading directory `{}`", $dir)
        };
    }

    /// Tests the code snippets that have a `.out` file.
    pub fn code_out(conf: &Conf, path: impl AsRef<Path>) -> Res<()> {
        code_out_in(conf, path)
    }
    /// Searches for `code` directories in `src`, recursively.
    fn code_out_in(conf: &Conf, src: impl AsRef<Path>) -> Res<()> {
        const CODE_DIR: &str = "code";
        let src = src.as_ref().to_path_buf();
        log::trace!("code_out_in({})", src.display());

        if !(src.exists() && src.is_dir()) {
            bail!("expected directory path, got `{}`", src.display())
        }

        'sub_dirs: for entry_res in src.read_dir().chain_err(dir_read_err!(src.display()))? {
            let entry = entry_res.chain_err(dir_read_err!(src.display()))?;
            let entry_path = entry.path();
            if !entry_path.is_dir() {
                continue 'sub_dirs;
            }

            log::trace!("code_out_in: looking at `{}`", entry_path.display());

            // `code` directory, check what's inside
            if entry_path
                .file_name()
                .map(|name| name == CODE_DIR)
                .unwrap_or(false)
            {
                code_out_check(conf, &entry_path).chain_err(|| {
                    format!("while checking code snippets in `{}`", entry_path.display())
                })?
            }

            // just a sub-directory, go down
            code_out_in(conf, entry_path)?
        }

        Ok(())
    }
    /// Tests a `code` directory at `path`.
    ///
    /// Scans the files in `path`, looking for *output* files with a `<name>.out` extension. Such
    /// files must have an associated file `<name>`. The output file contains the output of
    /// whatever tool corresponds to file `<name>`'s extension.
    ///
    /// For instance, `<name>.smt2` file's corresponding tool is Z3 and the output file contains
    /// the output of `z3 <name>.smt2`.
    fn code_out_check(conf: &Conf, path: impl AsRef<Path>) -> Res<()> {
        const OUT_SUFF: &str = "out";
        let path = path.as_ref();
        log::trace!("code_out_check({})", path.display());

        'out_files: for entry_res in path.read_dir().chain_err(dir_read_err!(path.display()))? {
            let entry = entry_res.chain_err(dir_read_err!(path.display()))?;
            let entry_path = entry.path();
            if entry_path.is_dir() {
                continue 'out_files;
            }
            log::trace!("working on `{}`", entry_path.display());

            let is_out_file = entry_path
                .extension()
                .map(|ext| {
                    log::trace!("ext: `{}`", ext.to_string_lossy());
                    ext == OUT_SUFF
                })
                .unwrap_or(false);

            if !is_out_file {
                log::trace!("not an `out` file");
                warn_if_not_tested(path, entry_path)?;
                continue 'out_files;
            }

            let out_path = entry_path;
            let snippet_path = {
                let mut path = out_path.clone();
                let stem = path
                    .file_stem()
                    .ok_or_else(|| {
                        format!("could not retrieve file stem for `{}`", path.display())
                    })?
                    .to_owned();
                let okay = path.pop();
                if !okay {
                    bail!("problem popping last part of path `{}`", path.display());
                }
                path.push(stem);
                path
            };

            log::trace!(
                "out: {}, snippet: {}",
                out_path.display(),
                snippet_path.display()
            );

            let ext = snippet_path
                .extension()
                .ok_or_else(|| {
                    format!(
                        "could not retrieve extension for `{}`",
                        snippet_path.display()
                    )
                })?
                .to_string_lossy();

            let err = || {
                format!(
                    "while checking `{}` with out file `{}`",
                    snippet_path.display(),
                    out_path.display()
                )
            };

            let actually_okay = if ext == "smt2" {
                code_out_check_smt2(conf, &out_path, &snippet_path).chain_err(err)?
            } else if ext == "mkn" {
                code_out_check_mkn(conf, &out_path, &snippet_path).chain_err(err)?
            } else {
                bail!(
                    "unknown extension `{}` for code snippet `{}` with out file `{}`",
                    ext,
                    snippet_path.display(),
                    out_path.display()
                )
            };

            if actually_okay {
                log::debug!(
                    "`{}` is okay w.r.t. `{}`",
                    snippet_path.display(),
                    out_path.display()
                );
            }
        }

        Ok(())
    }

    /// Checks a non-output file, issues a warning if there is a problem.
    ///
    /// A non-output file `name.ext` must be such that either
    ///
    /// - `ext` is `rs`: Rust files are checked by `mdbook` itself, or
    /// - there exists a `name.ext.out` file, which will be handled by regular testing.
    ///
    /// Otherwise we have non-Rust file with no output file, meaning the file is not tested against
    /// anything. We assume the author forgot the output file and issue a warning.
    fn warn_if_not_tested(parent: impl AsRef<Path>, snippet_path: impl AsRef<Path>) -> Res<()> {
        let (parent, snippet) = (parent.as_ref(), snippet_path.as_ref());

        // Rust files are tested by `mdbook`, no need for output file.
        if snippet.extension().map(|ext| ext == "rs").unwrap_or(false) {
            return Ok(());
        }

        // Not a Rust file, construct expected output file path and check it exists.
        let file_name = snippet
            .file_name()
            .ok_or_else(|| format!("failed to retrieve filename from `{}`", snippet.display()))?;
        let out_file = {
            let mut parent = parent.to_path_buf();
            parent.push(format!("{}.out", file_name.to_string_lossy()));
            parent
        };
        if !out_file.exists() {
            log::warn!(
                "file `{}` has no output file, no way to test it",
                snippet.display()
            );
        }
        if out_file.is_dir() {
            log::warn!(
                "file `{}` has no output 'file', `{}` exists but is a directory",
                snippet.display(),
                out_file.display()
            );
        }

        Ok(())
    }

    /// Compares the output of a command to the content of a file.
    fn cmd_output_same_as_file_content(
        cmd: &mut std::process::Command,
        path: impl AsRef<Path>,
    ) -> Res<()> {
        let path = path.as_ref();
        let output = cmd
            .output()
            .chain_err(|| format!("running command {:?}", cmd))?;
        let stdout = String::from_utf8_lossy(&output.stdout);
        let expected = {
            use std::{fs::OpenOptions, io::BufReader};
            let mut file = BufReader::new(
                OpenOptions::new()
                    .read(true)
                    .open(path)
                    .chain_err(|| format!("while read-opening `{}`", path.display()))?,
            );
            let mut buf = String::new();
            file.read_to_string(&mut buf)
                .chain_err(|| format!("while reading `{}`", path.display()))?;
            buf
        };
        if stdout != expected {
            bail!("unexpected output for `{:?}`", cmd)
        } else {
            Ok(())
        }
    }

    /// Checks a single `.smt2` file `snippet_path` against its output file `out_path`.
    fn code_out_check_smt2(
        conf: &Conf,
        out_path: impl AsRef<Path>,
        snippet_path: impl AsRef<Path>,
    ) -> Res<bool> {
        let (out_path, snippet_path) = (out_path.as_ref(), snippet_path.as_ref());
        let (check_smt2, z3_cmd) = conf.get_smt2()?;
        if !check_smt2 {
            log::warn!(
                "SMT2 checking deactivated, skipping `{}` (`{}`)",
                snippet_path.display(),
                out_path.display()
            );
            return Ok(false);
        }
        let mut cmd = std::process::Command::new(z3_cmd);
        cmd.arg(snippet_path);
        let () = cmd_output_same_as_file_content(&mut cmd, out_path)?;

        Ok(true)
    }

    /// Checks a single `.mkn` file `snippet_path` against its output file `out_path`.
    fn code_out_check_mkn(
        conf: &Conf,
        out_path: impl AsRef<Path>,
        snippet_path: impl AsRef<Path>,
    ) -> Res<bool> {
        let (out_path, snippet_path) = (out_path.as_ref(), snippet_path.as_ref());
        let (check_mikino, mikino_cmd) = conf.get_mikino()?;
        if !check_mikino {
            log::warn!(
                "mikino checking deactivated, skipping `{}` (`{}`)",
                snippet_path.display(),
                out_path.display()
            );
            return Ok(false);
        }

        let (_, z3_cmd) = conf.get_smt2()?;
        let mut cmd = retrieve_mkn_cmd(mikino_cmd, z3_cmd, snippet_path, "//")?;
        cmd_output_same_as_file_content(&mut cmd, out_path)?;

        Ok(true)
    }

    fn retrieve_mkn_cmd(
        mikino_cmd: &str,
        z3_cmd: &str,
        path: impl AsRef<Path>,
        pref: &str,
    ) -> Res<std::process::Command> {
        let path = path.as_ref();
        // Mikino files are expected to start with a special line specifying the command to run.
        let cmd_line = first_line_of(path)?
            .ok_or_else(|| "first line of `mkn` files must specify a `mikino` command")?;
        const CMD_PREF: &str = " CMD: ";
        if !cmd_line.starts_with(pref) || !cmd_line[pref.len()..].starts_with(CMD_PREF) {
            bail!(
                "first line of `mkn` files should start with `{}{}` to specify the mikino command",
                pref,
                CMD_PREF,
            )
        }

        let start = pref.len() + CMD_PREF.len();
        let cmd_line = &cmd_line[start..];
        let mut elems = cmd_line.split_whitespace();

        match elems.next() {
            Some("mikino") => (),
            Some(tkn) => bail!(
                "unexpected token `{}` on first line, expected `mikino`",
                tkn,
            ),
            None => bail!("expected `mikino` command on first line"),
        }

        let mut cmd = std::process::Command::new(mikino_cmd);
        cmd.args(&["--z3_cmd", z3_cmd]);

        for arg in elems {
            if arg == "<file>" {
                cmd.arg(path);
            } else {
                cmd.arg(arg);
            }
        }

        Ok(cmd)
    }

    /// Retrieves the first line of a file.
    ///
    /// Some code snippets are expected to specify, on their first line, the command used to run
    /// them. Mikino files, for example.
    fn first_line_of(path: impl AsRef<Path>) -> Res<Option<String>> {
        use std::{
            fs::OpenOptions,
            io::{BufRead, BufReader},
        };

        let path = path.as_ref();
        let mut reader = BufReader::new(
            OpenOptions::new()
                .read(true)
                .open(path)
                .chain_err(|| format!("while read-opening file `{}`", path.display()))?,
        );

        let mut line = String::with_capacity(31);
        let bytes_read = reader
            .read_line(&mut line)
            .chain_err(|| format!("while reading for line of file `{}`", path.display()))?;

        if bytes_read == 0 {
            Ok(None)
        } else {
            line.shrink_to_fit();
            Ok(Some(line))
        }
    }
}
