use std::{fs::File, io::{Read, BufWriter}};
use nes::frame::{RenderFrame, PixelFormat, PixelFormatRGB888, self};

use crate::ansi::{Ansi, self};

const UPPER_BLOCK: &str = "\u{2580}";

#[derive(Debug, Clone, Copy)]
pub enum RenderMode { 
    Muffin
}

#[derive(PartialEq, Eq, Debug, Clone, Copy)]
pub(crate) struct Rgb(u8, u8, u8);

impl ansi_colours::AsRGB for Rgb {
  fn as_u32(&self) -> u32 {
    let mut i = (self.0 as u32) << 16;
    i |= (self.1 as u32) << 8;
    i |= self.2 as u32;
    i
  }
}

pub trait Renderer {
  fn render(&mut self, frame: &RenderFrame) -> Vec<u8>;
  // fn tx_speed(&self) -> usize;
}

pub fn create(mode: RenderMode) -> Box<dyn Renderer> {
  match mode {
    RenderMode::Muffin => Box::new(MuffinRenderer::new()),
  }
}

struct MuffinRenderer {
  buf: String
}

impl MuffinRenderer {
  fn new() -> Self {
    Self { buf: String::with_capacity(50000) }
  }
}

impl Renderer for MuffinRenderer {
  fn render(&mut self, frame: &RenderFrame) -> Vec<u8> {
    self.buf.clear();
    self.buf.push_str(crate::ansi::CURSOR_HOME);

    for (n, &t) in frame.nametable().iter().enumerate() {
        let x = (n % frame::NAMETABLE_WIDTH) as u8;
        let y = n / frame::NAMETABLE_WIDTH;

        let c = if x == frame.sprite0_x / 8 && y == (frame.sprite0_y as usize + 1) / 8 {
            '>'
        }
        else { match t {
            0 => ' ',
            c @ 1..=0x7F => c as char,
            0x81 => '⎸',
            0x82 => '⎹',
            0x83 => '║',
            0x84 => '‾',
            0x85 => '⎾',
            0x86 => '⏋',
            0x87 => '⨅',

            _ => '?'
        }};

        self.buf.push(c);
        if n % frame::NAMETABLE_WIDTH == 0 {
            self.buf.push('\n');
        }
    }

    self.buf.as_bytes().to_vec()
  }
}
