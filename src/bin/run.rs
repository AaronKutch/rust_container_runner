use std::{
    collections::BTreeMap,
    fs::{self, OpenOptions},
    io::Read,
    path::PathBuf,
    process::Command,
};

use common::Group;

#[derive(clap::Parser)]
struct Args {
    #[clap(long)]
    group: String,
    #[clap(long, default_value = "./")]
    dir: String,
    #[clap(long, default_value = "testnet")]
    network: String,
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

pub fn kill_containers(active_container_ids: &mut BTreeMap<String, String>) {
    for (name, id) in active_container_ids {
        let rm_output = Command::new("docker")
            .args(["rm", "-f", id])
            .output()
            .unwrap();
        if rm_output.status.success() {
            println!("stopped container {}", name);
        } else {
            println!("tried to stop container {} and got {:?}", name, rm_output);
        }
    }
}

// looks for `neon.ron` in the `groups` folder
// cargo r --bin run -- --group neon.ron
fn main() {
    let args = <Args as clap::Parser>::parse();

    // check the directory for expected folders we will be using
    let base_dir = PathBuf::from(&args.dir);
    assert_exists(&base_dir);
    let base_dir = fs::canonicalize(base_dir).unwrap();
    println!("using base directory {:?}", base_dir);
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
    let group: Group = ron::from_str(&file_s).unwrap();
    group.verify_well_formed().unwrap();

    // create docker network
    let net_rm_output = Command::new("docker")
        .args(["network", "rm", &args.network])
        .output()
        .unwrap();
    assert!(net_rm_output.status.success());
    let net_create_output = Command::new("docker")
        .args(["network", "create", "--internal", &args.network])
        .output()
        .unwrap();
    assert!(net_create_output.status.success());

    let mut active_container_ids: BTreeMap<String, String> = BTreeMap::new();
    for (container_name, container) in &group.containers {
        let mut args = vec![
            "create",
            "--network",
            &args.network,
            "--hostname",
            &container_name,
            "--name",
            &container_name,
        ];
        let create_output = Command::new("docker").args(args).output().unwrap();
        let id;
        if create_output.status.success() {
            if let Ok(s) = String::from_utf8(create_output.stdout.clone()) {
                id = Ok(s);
            } else {
                id = Err(format!(
                    "failed to parse stdout as utf8: {:?}",
                    create_output
                ));
            }
        } else {
            id = Err(format!("docker create command failed: {:?}", create_output));
        }
        match id {
            Ok(id) => {
                active_container_ids.insert(container_name.clone(), id);
            }
            Err(e) => {
                kill_containers(&mut active_container_ids);
                panic!("container \"{}\": {}", container_name, e);
            }
        }
    }

    //let processes = vec![];
    // .try_wait(), .kill(), .stdout, .stderr
    //let process = Command::new("ls").args(["-l", "-a"]).spawn().unwrap();
    //dbg!(process.wait_with_output());
    kill_containers(&mut active_container_ids);
}
