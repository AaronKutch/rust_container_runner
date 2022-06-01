use std::{fs::OpenOptions, io::Read, path::PathBuf};

#[derive(clap::Parser)]
struct Args {
    #[clap(long)]
    group: String,
    #[clap(long, default_value = "./")]
    dir: String,
}

pub fn assert_exists(path: &PathBuf) {
    if !path.exists() {
        panic!("path {:?} does not exist", path);
    }
}

pub fn assert_is_file(path: &PathBuf) {
    assert_exists(path);
    if !path.is_file() {
        panic!("path {:?} is not a file", path);
    }
}

// looks for `neon.ron` in the `groups` folder
// cargo r --bin run -- --group neon.ron
#[tokio::main]
async fn main() {
    let args = <Args as clap::Parser>::parse();

    // check the directory for expected folders we will be using
    let base_dir = PathBuf::from(&args.dir);
    assert_exists(&base_dir);
    let group_dir = base_dir.join("groups");
    assert_exists(&group_dir);
    let group_path = group_dir.join(&args.group);
    assert_is_file(&group_path);
    let logs_dir = base_dir.join("logs");
    assert_exists(&logs_dir);
    let scripts_dir = base_dir.join("scripts");
    assert_exists(&scripts_dir);

    print!("opening group file {:?}, ", group_path);
    let mut file = OpenOptions::new().read(true).open(&group_path).unwrap();
    let mut file_s = String::new();
    file.read_to_string(&mut file_s).unwrap();
    println!("groups file length is {}, parsing.", file_s.len());
    let s: Group = ron::from_str(&file_s).unwrap();
    //dbg!(s);

    //let processes = vec![];
    // .try_wait(), .kill(), .stdout, .stderr
    //let process = Command::new("ls").args(["-l", "-a"]).spawn().unwrap();
    //dbg!(process.wait_with_output());
}
