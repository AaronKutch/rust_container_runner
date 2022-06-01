use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};

// TODO serde options

#[derive(Debug, Clone, Hash, PartialEq, Eq, PartialOrd, Ord, Deserialize, Serialize)]
pub struct Container {
    image: String,
    common_env_vars: Vec<String>,
    env_vars: BTreeMap<String, String>,
}

#[derive(Debug, Clone, Hash, PartialEq, Eq, PartialOrd, Ord, Deserialize, Serialize)]
pub struct RunNode {}

#[derive(Debug, Clone, Hash, PartialEq, Eq, PartialOrd, Ord, Deserialize, Serialize)]
pub struct Group {
    images: BTreeMap<String, String>,
    common_env_vars: BTreeMap<String, BTreeMap<String, String>>,
    containers: BTreeMap<String, Container>,
    //run_graph: Vec<RunNode>,
}
