//! Book manager.

manage_api::prelude!();

fn main() {
    const VERB_KEY: &str = "VERB";
    let matches = clap::App::new("manager")
        .arg(clap::Arg::with_name(VERB_KEY).short("v").multiple(true))
        .get_matches();
    let log_level = match matches.occurrences_of(VERB_KEY) {
        0 => log::LevelFilter::Info,
        1 => log::LevelFilter::Debug,
        _ => log::LevelFilter::Trace,
    };

    simple_logger::SimpleLogger::new()
        .with_level(log_level)
        .init()
        .expect("failed to initialize logger");

    match test::run(".") {
        Ok(()) => std::process::exit(0),
        Err(e) => {
            eprintln!("|===| Error(s):");
            e.pretty_eprint("| ");
            eprintln!("|===|");
            std::process::exit(2);
        }
    }
}
