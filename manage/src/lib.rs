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
        test,
    };

    pub mod err {
        pub use crate::error::*;
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
        match run("..") {
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
    pub fn run(path: impl AsRef<Path>) -> Res<()> {
        let path = path.as_ref();

        log::info!("testing book...");
        test::book(path)?;

        log::info!("testing `.out` code snippets");
        let mut src_path = path.to_path_buf();
        src_path.push("src");
        test::code_out(src_path)?;

        log::info!("everything okay");
        Ok(())
    }

    /// Tests the book itself.
    pub fn book(path: impl AsRef<Path>) -> Res<()> {
        use std::process::Command;

        let status = Command::new("mdbook")
            .arg("test")
            .arg("--")
            .arg(path.as_ref())
            .status()
            .chain_err(|| "failed to run `mdbook test`")?;
        if !status.success() {
            bail!("`mdbook` returned with an error")
        }
        Ok(())
    }

    macro_rules! dir_read_err {
        { $dir:expr } => {
            || format!("while reading directory `{}`", $dir)
        };
    }

    /// Tests the code snippets that have a `.out` file.
    pub fn code_out(path: impl AsRef<Path>) -> Res<()> {
        code_out_in(path)
    }
    fn code_out_in(src: impl AsRef<Path>) -> Res<()> {
        const CODE_DIR: &str = "code";
        let src = src.as_ref().to_path_buf();
        log::debug!("code_out_in({})", src.display());

        if !(src.exists() && src.is_dir()) {
            bail!("expected directory path, got `{}`", src.display())
        }

        // Is there a `code` folder?
        {
            let mut code_dir = src.clone();
            code_dir.push(CODE_DIR);
            if code_dir.exists() && code_dir.is_dir() {
                code_out_check(&code_dir).chain_err(|| {
                    format!("while checking code snippets in `{}`", code_dir.display())
                })?
            }
        }

        'sub_dirs: for entry_res in src.read_dir().chain_err(dir_read_err!(src.display()))? {
            let entry = entry_res.chain_err(dir_read_err!(src.display()))?;
            let entry_path = entry.path();
            if !entry_path.is_dir() {
                continue 'sub_dirs;
            }

            log::debug!("code_out_in: looking at `{}`", entry_path.display());

            // `code` directory, check what's inside
            if entry_path
                .file_name()
                .map(|name| name == CODE_DIR)
                .unwrap_or(false)
            {
                code_out_check(&entry_path).chain_err(|| {
                    format!("while checking code snippets in `{}`", entry_path.display())
                })?
            }

            // just a sub-directory, go down
            code_out_in(entry_path)?
        }

        Ok(())
    }
    fn code_out_check(path: impl AsRef<Path>) -> Res<()> {
        const OUT_SUFF: &str = "out";
        let path = path.as_ref();
        log::debug!("code_out_check({})", path.display());

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
            if ext == "smt2" {
                code_out_check_smt2(&out_path, &snippet_path)?;
            } else {
                bail!(
                    "unknown extension `{}` for code snippet `{}` with out file `{}`",
                    ext,
                    snippet_path.display(),
                    out_path.display()
                )
            }

            log::info!(
                "`{}` is okay w.r.t. `{}`",
                snippet_path.display(),
                out_path.display()
            );
        }

        Ok(())
    }

    fn code_out_check_smt2(out_path: impl AsRef<Path>, snippet_path: impl AsRef<Path>) -> Res<()> {
        let (out_path, snippet_path) = (out_path.as_ref(), snippet_path.as_ref());
        let cmd = || {
            let mut cmd = std::process::Command::new("z3");
            cmd.arg(snippet_path);
            cmd
        };
        let output = cmd()
            .output()
            .chain_err(|| format!("running z3 on `{}`", snippet_path.display()))?;
        let stdout = String::from_utf8_lossy(&output.stdout);
        let expected = {
            use std::{fs::OpenOptions, io::BufReader};
            let mut file = BufReader::new(
                OpenOptions::new()
                    .read(true)
                    .open(out_path)
                    .chain_err(|| format!("while read-opening `{}`", out_path.display()))?,
            );
            let mut buf = String::new();
            file.read_to_string(&mut buf)
                .chain_err(|| format!("while reading `{}`", out_path.display()))?;
            buf
        };

        if stdout != expected {
            let _ = cmd().status();
            return Err(err::Error::from(format!(
                "unexpected output for `z3 {}`",
                snippet_path.display()
            ))
            .chain_err(|| format!("expected output:\n{}", expected)));
        }

        Ok(())
    }
}
