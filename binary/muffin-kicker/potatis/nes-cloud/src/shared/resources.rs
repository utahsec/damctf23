use std::{fs, path::Path, collections::HashMap, fmt::Debug};
use log::debug;
use serde::Deserialize;

#[derive(Debug, Deserialize, PartialEq, Eq, Hash, Clone, Copy)]
pub enum StrId {
  Welcome,
  AlreadyConnected,
  TooManyPlayers,
  RomSelection,
  InvalidRomSelection,
  InvalidRom,
  RomInserted,
  RenderModeSelection,
  InvalidRenderModeSelection,
  AnyKeyToStart,
}

#[derive(Debug, Deserialize)]
pub struct Resources {
  fps: usize,
  tx_mb_limit: usize,
  strings: HashMap<StrId, String>,
}

impl Resources {
  pub fn load(filepath: &str) -> Resources {
    let f = match fs::File::open(filepath) {
      Ok(f) => f,
      Err(e) => panic!("could not open resource file ({}): {}", filepath, e)
    };

    let res: Resources = serde_yaml::from_reader(f).unwrap();

    res
  }

  pub fn fmt(&self, index: StrId, args: &[&str]) -> Vec<u8> {
    let mut fstr = String::from_utf8(self[index].to_vec()).unwrap();
    for arg in args {
        if !fstr.contains("{}") {
          panic!("fmtwhat: {:?}", index);
        }
      fstr = fstr.replacen("{}", arg, 1)
    }
    fstr.as_bytes().to_vec()
  }

  pub fn load_rom<P: AsRef<Path> + std::fmt::Debug>(&mut self, path: P) -> Vec<u8> {
    debug!("Loading included ROM: {:?}", path);
    std::fs::read(path).expect("failed to load included ROM")
  }

  pub fn fps_conf(&self) -> usize {
    self.fps
  }

  pub fn tx_mb_limit(&self) -> usize {
    self.tx_mb_limit
  }
}

impl std::ops::Index<StrId> for Resources {
  type Output = [u8];

  fn index(&self, index: StrId) -> &[u8] {
    self.strings.get(&index).unwrap().as_bytes()
  }
}

#[cfg(test)]
mod tests {
  use super::{Resources, StrId};

  #[test]
  fn res_fmt() {
    let r = Resources::load("resources.yaml");
    assert_eq!(
      "\nYou have inserted a ROM:\nfoo\nbar\n", 
      String::from_utf8(r.fmt(StrId::RomInserted, &["foo", "bar"])).unwrap()
    );
  }  
}
