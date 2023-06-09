use std::{sync::mpsc, collections::HashMap, time::{Instant, Duration}, io::Write};
use log::warn;
use nes::{joypad::{JoypadButton, Joypad, JoypadEvent}, frame::RenderFrame, nes::{Shutdown, HostPlatform}};

use crate::{io::CloudStream, renderers::{Renderer, self, RenderMode}};

const PRESS_RELEASED_AFTER_MS: u128 = 250;

pub struct CloudHost {
  stream: CloudStream,
  rx: mpsc::Receiver<u8>,
  pressed: HashMap<JoypadButton, Instant>,
  pending: Option<JoypadButton>,
  dead: bool,
  renderer: Box<dyn Renderer>,
  crc: u32,
  time: Instant,
  transmitted: usize,
  tx_b_limit: usize
}

impl CloudHost {
  pub fn new(
    stream: CloudStream, 
    rx: mpsc::Receiver<u8>, 
    mode: RenderMode,
    tx_mb_limit: usize,
  ) -> Self {
    let renderer = renderers::create(mode);
    Self { 
      stream,
      rx, 
      pressed: HashMap::new(),
      pending: None,
      dead: false,
      renderer,
      crc: 0,
      time: Instant::now(),
      transmitted: 0,
      tx_b_limit: tx_mb_limit * 1000 * 1000
    }
  }

  fn release_keys(&mut self, joypad: &mut Joypad) {
    let to_release: Vec<JoypadButton> = self.pressed.keys().copied().collect();

    to_release
      .iter()
      .map(|&b| (JoypadEvent::Release(b), b))
      .for_each(|(ev, b)| {
        // warn!("{:?}", ev);
        joypad.on_event(ev);
        self.pressed.remove(&b);
      });
  }

  fn map_button(&self, key: u8) -> Option<JoypadButton> {
    match key {
      b'b' | b'B' => Some(JoypadButton::B),
      b'n' | b'N' => Some(JoypadButton::A),
      b' ' => Some(JoypadButton::SELECT),
      0x0a => Some(JoypadButton::START),
      b'a' | b'A' => Some(JoypadButton::LEFT),
      b's' | b'S' => Some(JoypadButton::DOWN),
      b'w' | b'W'=> Some(JoypadButton::UP),
      b'd' | b'D' => Some(JoypadButton::RIGHT),
      _ => None
    }
  }
}

impl HostPlatform for CloudHost {
  fn render(&mut self, frame: &RenderFrame) {
    let term_frame = self.renderer.render(frame);
    let frame_crc = crc32fast::hash(&term_frame);
    if self.crc != frame_crc {
      self.dead = self.stream.write_all(&term_frame[..]).is_err();
      self.transmitted += term_frame.len();
      self.crc = frame_crc;
    }

    if self.transmitted >= self.tx_b_limit {
      warn!("tx limit, dead");
      self.dead = true;
    }
  }

  fn poll_events(&mut self, joypad: &mut Joypad) -> Shutdown {
    if let Some(joypad_btn) = self.pending {
        self.pending = None;
        *self.pressed.entry(joypad_btn).or_insert_with(Instant::now) = Instant::now();
        joypad.on_event(JoypadEvent::Press(joypad_btn));
    } else {
        match self.rx.recv_timeout(Duration::from_millis(0)) {
          Ok(key) => {
            let button = self.map_button(key);
            
            if let Some(joypad_btn) = button {
              if self.pressed.contains_key(&joypad_btn) {
                  self.pending = Some(joypad_btn);
                  self.release_keys(joypad);
              } else {
                  self.release_keys(joypad);
                  *self.pressed.entry(joypad_btn).or_insert_with(Instant::now) = Instant::now();
                  joypad.on_event(JoypadEvent::Press(joypad_btn));
              }
            }
          },
          Err(mpsc::RecvTimeoutError::Disconnected) => self.dead = true,
          Err(mpsc::RecvTimeoutError::Timeout) => {}
        }
    }
    self.dead.into()
  }

  fn elapsed_millis(&self) -> usize {
    self.time.elapsed().as_millis() as usize
  }

  fn delay(&self, d: Duration) {
    std::thread::sleep(d);
  }
}
