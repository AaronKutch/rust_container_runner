use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};

// TODO serde options

#[derive(Debug, Clone, Hash, PartialEq, Eq, PartialOrd, Ord, Deserialize, Serialize)]
pub struct Container {
    pub image: String,
    pub common_env_vars: Vec<String>,
    pub env_vars: BTreeMap<String, String>,
}

#[derive(Debug, Clone, Hash, PartialEq, Eq, PartialOrd, Ord, Deserialize, Serialize)]
pub struct RunNode {}

#[derive(Debug, Clone, Hash, PartialEq, Eq, PartialOrd, Ord, Deserialize, Serialize)]
pub struct Group {
    pub images: BTreeMap<String, String>,
    pub common_env_vars: BTreeMap<String, BTreeMap<String, String>>,
    pub containers: BTreeMap<String, Container>,
    //run_graph: Vec<RunNode>,
}

impl Group {
    /// Verify that this is well formed and there are no keys that have missing
    /// entries
    pub fn verify_well_formed(&self) -> Result<(), String> {
        for (container_name, container) in &self.containers {
            if !self.images.contains_key(&container.image) {
                return Err(format!(
                    "container \"{}\" uses image \"{}\" that does not have an entry in the images \
                     of the group",
                    container_name, container.image
                ))
            }
        }
        Ok(())
    }
}
