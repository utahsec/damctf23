#![feature(iter_array_chunks)]

use std::{error::Error, net::TcpStream, io::{Write, Read}, os::unix::prelude::FromRawFd, ops::Sub, path::PathBuf, fmt::{Display}, time::Duration, sync::mpsc::{Sender, Receiver}, ptr::read};
use log::{info, warn, debug, error};
use nes::{cartridge::{Cartridge, Header, HeapRom, error::CartridgeError}, nes::Nes};
use renderers::RenderMode;

use crate::{io::CloudStream, host::CloudHost};

use libcloud::{self, logging, resources::{StrId, Resources}, ServerMode, utils::{ReadByte, strhash}};

mod renderers;
mod io;
mod ansi;
mod host;

const FD_STDOUT: i32 = 1;

#[derive(Debug)]
enum RomSelection {
  Invalid(char),
  Included(PathBuf),
  Cart(Cartridge<HeapRom>, md5::Digest)
}

#[derive(Debug)]
struct InstanceError<S : AsRef<str>>(S);

impl<S : AsRef<str>> Display for InstanceError<S> {
  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
    write!(f, "{}", self.0.as_ref())
  }
}

impl<S : AsRef<str> + std::fmt::Debug> std::error::Error for InstanceError<S> {}

fn read_rom(r: &mut impl Read) -> Result<RomSelection, Box<dyn Error>> {
  let mut rest_of_magic = [0u8; 3];
  r.read_exact(&mut rest_of_magic)?;

  if rest_of_magic != nes::cartridge::MAGIC[1..] {
    return Err(Box::new(CartridgeError::InvalidCartridge("magic")))
  }

  let mut header_buf = [0u8; 16];
  r.read_exact(&mut header_buf)?;

  let mut full_header = nes::cartridge::MAGIC.to_vec();
  full_header.append(&mut header_buf.to_vec());
  let header = Header::parse(&full_header)?;

  let mut rom_buf = vec![0; header.total_size_excluding_header() - 4];
  r.read_exact(&mut rom_buf)?;

  let mut full_cart = full_header;
  full_cart.append(&mut rom_buf);

  let hash = md5::compute(&full_cart);
  let cart = Cartridge::blow_dust_vec(full_cart)?;
  Ok(RomSelection::Cart(cart, hash))
}

fn recv_thread(mut stream: CloudStream, tx: Sender<u8>) {
  info!("Starting recv thread.");

  let mut buf = [0u8; 1];
  while stream.read_exact(&mut buf).is_ok() {
    debug!("got input: {} ({:#04x})", buf[0] as char, buf[0]);
    tx.send(buf[0]).unwrap();
  }

  warn!("Recv thread died")
}

fn emulation_thread(
  stream: CloudStream, 
  rx: Receiver<u8>, 
  cart: Cartridge<HeapRom>, 
  mode: RenderMode,
  res: &Resources,
) {
  let fps = res.fps_conf();
  info!("Starting emulation. FPS: {}, limit: {}", fps, res.tx_mb_limit());

  let host = CloudHost::new(stream, rx, mode, res.tx_mb_limit());
  let mut nes = Nes::insert(cart, host);
  nes.fps_max(fps);

  while nes.powered_on() {
    nes.tick();
  }

  warn!("NES powered off")
}

fn main() -> Result<(), Box<dyn Error>> {
  logging::init(std::env::var("LOG_TO_FILE")
    .map_or(false, |s| s.parse().unwrap_or(false)))?;

  let oghook = std::panic::take_hook();
  std::panic::set_hook(Box::new(move |info| {
    oghook(info);
    error!("EMU INSTANCE PANIC: {}", info);
    std::process::exit(1);
  }));

  let fd = std::env::var("FD");
  let rom: String = std::env::var("ROM").expect("no ROM specified");
  info!("Instance started. FD: {:?}, ROM: {:?}", fd, rom);

  let mut res = Resources::load("resources.yaml");

  let mut stream: CloudStream = match fd?.parse() {
    Ok(FD_STDOUT) => CloudStream::Offline,
    Ok(socketfd) => unsafe { CloudStream::Online(TcpStream::from_raw_fd(socketfd)) },
    Err(e) => panic!("invalid FD: {}", e)
  };
  
  // Say hello
  let players = std::env::var("PLAYERS").unwrap_or_else(|_| "0".into());
  stream.write_all(&res.fmt(StrId::Welcome, &[&players]))?;

      let cart = match Cartridge::blow_dust_vec(res.load_rom(&rom)) {
        Ok(cart) => cart,
        Err(e) => panic!("Failed to load included ROM: {}", e),
      };

  let mode = RenderMode::Muffin;

  let rom_name = &rom[(rom.rfind('/').unwrap() + 1)..];
  stream.write_all(&res.fmt(StrId::AnyKeyToStart, &[rom_name]))?;
  if stream.read_byte()? == 0x0a {
    // Read again for non-icanon ppl (0x0a from last input)
    stream.read_byte()?;
  }

  let (tx, rx) = std::sync::mpsc::channel::<u8>();
  std::thread::scope(|scope| {
    let s = stream.clone();
    scope.spawn(|| { recv_thread(s, tx) });
    scope.spawn(|| { emulation_thread(stream, rx, cart, mode, &res) });

    if std::env::var("PANIC").is_ok() {
      std::thread::sleep(Duration::from_millis(1000));
      panic!("intentional")
    }
  });

  info!("Instance died.");

  Ok(())
}

