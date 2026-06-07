// QR code plan and layout, ported from rsc.io/qr/coding/qr.go

///|
/// GF(256) field for QR code Reed-Solomon error correction.
pub let field : @gf256.Field = @gf256.Field::new(0x11d, 2)

///|
/// QRError is raised for QR code construction errors.
pub suberror QRError {
  QRError(String)
}

///|
/// Create a QRError from a string (public constructor for cross-package use).
pub fn QRError::new(msg : String) -> QRError {
  QRError::QRError(msg)
}

///|
/// QRCode represents the bitmap of a QR code.
pub struct QRCode {
  bitmap : Array[Byte]
  size : Int
  stride : Int
}

///|
/// A Plan describes how to construct a QR code with a specific version, level, and mask.
pub struct Plan {
  version : Version
  mut level : Level
  mut mask : Mask
  mut data_bytes : Int // number of data bytes
  mut check_bytes : Int // number of error correcting (checksum) bytes
  mut blocks : Int // number of data blocks
  mut pixel : Array[Array[Pixel]] // pixel map
}

///|
/// Create a new QR code plan.
pub fn Plan::new(
  version : Version,
  level : Level,
  mask : Mask,
) -> Plan raise QRError {
  if version < min_version || version > max_version {
    raise QRError("invalid QR version")
  }
  let p : Plan = {
    version,
    level,
    mask,
    data_bytes: 0,
    check_bytes: 0,
    blocks: 0,
    pixel: Array::new(),
  }
  vplan(p)
  p.level = level
  fplan(p, level, mask)
  lplan(p, level)
  mplan(p, mask)
  p
}

///|
/// Return the size (pixels per side) of the QR code.
pub fn Plan::size(self : Plan) -> Int {
  self.pixel.length()
}

///|
/// Encode the given text encodings into a QR code bitmap.
pub fn Plan::encode(
  self : Plan,
  encs : Array[Encoding],
) -> QRCode raise QRError {
  let b = Bits::new()
  for i = 0; i < encs.length(); i = i + 1 {
    let t = encs[i]
    if !t.check() {
      raise QRError("invalid text for encoding")
    }
    t.encode(b, self.version)
  }
  if b.bits() > self.data_bytes * 8 {
    raise QRError(
      "cannot encode " +
      b.bits().to_string() +
      " bits into " +
      (self.data_bytes * 8).to_string() +
      "-bit code",
    )
  }
  add_check_bytes(b, self.version, self.level)
  let bytes = b.bytes()
  let siz = self.pixel.length()
  let stride = (siz + 7) & -8
  let bitmap : Array[Byte] = Array::make(stride * siz, b'\x00')
  // Build the code by going through the plan's pixel map.
  for y = 0; y < siz; y = y + 1 {
    let row = self.pixel[y]
    let base = y * stride
    for x = 0; x < siz; x = x + 1 {
      let mut pix = row[x]
      let role = pixel_role(pix)
      if role == Data || role == Check {
        let o = pixel_offset(pix)
        if (bytes[o / 8].to_int() & (1 << (7 - o % 8))) != 0 {
          pix = pix ^ black
        }
      }
      if (pix & black) != 0 {
        bitmap[base + x / 8] = bitmap[base + x / 8] |
          (1 << (7 - x % 8)).to_byte()
      }
    }
  }
  { bitmap, size: siz, stride }
}

///|
/// QRCode::black returns true if the pixel at (x, y) is black.
pub fn QRCode::black(self : QRCode, x : Int, y : Int) -> Bool {
  x >= 0 &&
  x < self.size &&
  y >= 0 &&
  y < self.size &&
  (self.bitmap[y * self.stride + x / 8].to_int() & (1 << (7 - x % 8))) != 0
}

// ===== Internal plan construction =====

///|
/// vplan creates a Plan for the given version, with timing, position boxes,
/// alignment boxes, version pattern, and the lonely black pixel.
fn vplan(p : Plan) -> Unit {
  let v = p.version
  let siz = 17 + v * 4
  let m = grid(siz)
  p.pixel = m
  // Timing markers (overwritten by boxes).
  let ti = 6
  for i = 0; i < siz; i = i + 1 {
    let mut pix = Timing.to_pixel()
    if (i & 1) == 0 {
      pix = pix | black
    }
    m[i][ti] = pix
    m[ti][i] = pix
  }
  // Position boxes (finder patterns).
  pos_box(m, 0, 0)
  pos_box(m, siz - 7, 0)
  pos_box(m, 0, siz - 7)
  // Alignment boxes.
  let info = vtab[v]
  let mut x = 4
  while x + 5 < siz {
    let mut y = 4
    while y + 5 < siz {
      // don't overwrite timing markers
      let conflict = (x < 7 && y < 7) ||
        (x < 7 && y + 5 >= siz - 7) ||
        (x + 5 >= siz - 7 && y < 7)
      if !conflict {
        align_box(m, x, y)
      }
      if y == 4 {
        y = info.apos
      } else {
        y = y + info.astride
      }
    }
    if x == 4 {
      x = info.apos
    } else {
      x = x + info.astride
    }
  }
  // Version pattern (v >= 7).
  let pat = vtab[v].pattern
  if pat != 0 {
    let mut vv = pat
    for xi = 0; xi < 6; xi = xi + 1 {
      for yi = 0; yi < 3; yi = yi + 1 {
        let mut pix = PVersion.to_pixel()
        if (vv & 1) != 0 {
          pix = pix | black
        }
        m[siz - 11 + yi][xi] = pix
        m[xi][siz - 11 + yi] = pix
        vv = vv >> 1
      }
    }
  }
  // One lonely black pixel.
  m[siz - 8][8] = Unused.to_pixel() | black
}

///|
/// fplan adds the format pixels for the given level and mask.
fn fplan(p : Plan, l : Level, m : Mask) -> Unit {
  // Format pixels.
  let mut fb = (l.to_int() ^ 1) << 13 // level: L=01, M=00, Q=11, H=10
  fb = fb | (m.to_int() << 10) // mask
  let format_poly = 0x537
  let mut rem = fb
  for i = 14; i >= 10; i = i - 1 {
    if (rem & (1 << i)) != 0 {
      rem = rem ^ (format_poly << (i - 10))
    }
  }
  fb = fb | rem
  let inv = 0x5412
  let siz = p.pixel.length()
  for i = 0; i < 15; i = i + 1 {
    let mut pix = Format.to_pixel() + offset_pixel(i)
    if ((fb >> i) & 1) == 1 {
      pix = pix | black
    }
    if ((inv >> i) & 1) == 1 {
      pix = pix ^ (invert | black)
    }
    // top left
    if i < 6 {
      p.pixel[i][8] = pix
    } else if i < 8 {
      p.pixel[i + 1][8] = pix
    } else if i < 9 {
      p.pixel[8][7] = pix
    } else {
      p.pixel[8][14 - i] = pix
    }
    // bottom right
    if i < 8 {
      p.pixel[8][siz - 1 - i] = pix
    } else {
      p.pixel[siz - 1 - (14 - i)][8] = pix
    }
  }
}

///|
/// lplan edits a version-only Plan to add information about the error correction
/// levels (data + check bytes, arranged in a bit sequence for placement).
fn lplan(p : Plan, l : Level) -> Unit {
  let v = p.version
  let vt = vtab[v]
  let lev = vt.level[l.to_int()]
  let nblock = lev.nblock
  let ne = lev.check
  let nde = (vt.bytes - ne * nblock) / nblock
  let extra = (vt.bytes - ne * nblock) % nblock
  let data_bits = (nde * nblock + extra) * 8
  let check_bits = ne * nblock * 8
  p.data_bytes = vt.bytes - ne * nblock
  p.check_bytes = ne * nblock
  p.blocks = nblock
  // Make data + check pixels.
  let data : Array[Pixel] = Array::make(data_bits, 0)
  for i = 0; i < data_bits; i = i + 1 {
    data[i] = Data.to_pixel() | offset_pixel(i)
  }
  let check : Array[Pixel] = Array::make(check_bits, 0)
  for i = 0; i < check_bits; i = i + 1 {
    check[i] = Check.to_pixel() | offset_pixel(i + data_bits)
  }
  // Split into blocks.
  let data_list : Array[Array[Pixel]] = Array::make(nblock, Array::new())
  let check_list : Array[Array[Pixel]] = Array::make(nblock, Array::new())
  let mut data_idx = 0
  let mut check_idx = 0
  for i = 0; i < nblock; i = i + 1 {
    let mut nd = nde
    if i >= nblock - extra {
      nd = nd + 1
    }
    let data_block : Array[Pixel] = Array::make(nd * 8, 0)
    for j = 0; j < nd * 8; j = j + 1 {
      data_block[j] = data[data_idx + j]
    }
    data_idx = data_idx + nd * 8
    let check_block : Array[Pixel] = Array::make(ne * 8, 0)
    for j = 0; j < ne * 8; j = j + 1 {
      check_block[j] = check[check_idx + j]
    }
    check_idx = check_idx + ne * 8
    data_list[i] = data_block
    check_list[i] = check_block
  }
  if data_idx != data.length() || check_idx != check.length() {
    abort("data/check math")
  }
  // Build up bit sequence, taking first byte of each block, then second byte, etc.
  let bits : Array[Pixel] = Array::make(data_bits + check_bits, 0)
  let mut dst = 0
  for i = 0; i < nde + 1; i = i + 1 {
    for bi = 0; bi < nblock; bi = bi + 1 {
      let b = data_list[bi]
      if i * 8 < b.length() {
        for j = 0; j < 8; j = j + 1 {
          bits[dst + j] = b[i * 8 + j]
        }
        dst = dst + 8
      }
    }
  }
  for i = 0; i < ne; i = i + 1 {
    for bi = 0; bi < nblock; bi = bi + 1 {
      let b = check_list[bi]
      if i * 8 < b.length() {
        for j = 0; j < 8; j = j + 1 {
          bits[dst + j] = b[i * 8 + j]
        }
        dst = dst + 8
      }
    }
  }
  if dst != bits.length() {
    abort("dst math")
  }
  // Sweep up pair of columns, then down, assigning to right then left pixel.
  let siz = p.pixel.length()
  let rem : Array[Pixel] = Array::make(7, 0)
  for i = 0; i < 7; i = i + 1 {
    rem[i] = Extra.to_pixel()
  }
  let src : Array[Pixel] = Array::make(bits.length() + 7, 0)
  for i = 0; i < bits.length(); i = i + 1 {
    src[i] = bits[i]
  }
  for i = 0; i < 7; i = i + 1 {
    src[bits.length() + i] = rem[i]
  }
  let mut src_idx = 0
  let mut xx = siz
  while xx > 0 {
    for y = siz - 1; y >= 0; y = y - 1 {
      if pixel_role(p.pixel[y][xx - 1]) == None {
        p.pixel[y][xx - 1] = src[src_idx]
        src_idx = src_idx + 1
      }
      if pixel_role(p.pixel[y][xx - 2]) == None {
        p.pixel[y][xx - 2] = src[src_idx]
        src_idx = src_idx + 1
      }
    }
    xx = xx - 2
    if xx == 7 {
      xx = xx - 1
    }
    for y = 0; y < siz; y = y + 1 {
      if pixel_role(p.pixel[y][xx - 1]) == None {
        p.pixel[y][xx - 1] = src[src_idx]
        src_idx = src_idx + 1
      }
      if pixel_role(p.pixel[y][xx - 2]) == None {
        p.pixel[y][xx - 2] = src[src_idx]
        src_idx = src_idx + 1
      }
    }
    xx = xx - 2
  }
}

///|
/// mplan edits a version+level-only Plan to add the mask.
fn mplan(p : Plan, m : Mask) -> Unit {
  p.mask = m
  let siz = p.pixel.length()
  for y = 0; y < siz; y = y + 1 {
    let row = p.pixel[y]
    for x = 0; x < siz; x = x + 1 {
      let pix = row[x]
      let r = pixel_role(pix)
      if (r == Data || r == Check || r == Extra) && m.invert(y, x) {
        row[x] = pix ^ (black | invert)
      }
    }
  }
}

///|
/// add_check_bytes pads the bit stream and appends Reed-Solomon check bytes.
fn add_check_bytes(b : Bits, v : Version, l : Level) -> Unit {
  let nd = version_data_bytes(v, l)
  if b.bits() < nd * 8 {
    b.pad(nd * 8 - b.bits())
  }
  if b.bits() != nd * 8 {
    abort("qr: too much data")
  }
  let mut dat = b.bytes()
  let vt = vtab[v]
  let lev = vt.level[l.to_int()]
  let mut db = nd / lev.nblock
  let extra = nd % lev.nblock
  let chk : Array[Byte] = Array::make(lev.check, b'\x00')
  let rs = @gf256.RSEncoder::new(field, lev.check)
  for i = 0; i < lev.nblock; i = i + 1 {
    if i == lev.nblock - extra {
      db = db + 1
    }
    // Take db bytes from dat
    let dat_block : Array[Byte] = Array::make(db, b'\x00')
    for j = 0; j < db; j = j + 1 {
      dat_block[j] = dat[j]
    }
    let computed = rs.ecc(dat_block)
    for j = 0; j < lev.check; j = j + 1 {
      chk[j] = computed[j]
    }
    b.append(chk)
    // Drop the first db bytes from dat.
    let new_dat : Array[Byte] = Array::make(dat.length() - db, b'\x00')
    for j = db; j < dat.length(); j = j + 1 {
      new_dat[j - db] = dat[j]
    }
    dat = new_dat
  }
  if b.bytes().length() != vt.bytes {
    abort("qr: internal error")
  }
}

///|
/// grid creates a 2D pixel array of size siz x siz.
fn grid(siz : Int) -> Array[Array[Pixel]] {
  let m : Array[Array[Pixel]] = Array::make(siz, Array::new())
  for i = 0; i < siz; i = i + 1 {
    let row : Array[Pixel] = Array::make(siz, 0)
    m[i] = row
  }
  m
}

///|
/// pos_box draws a position (large) box at upper left x, y.
fn pos_box(m : Array[Array[Pixel]], x : Int, y : Int) -> Unit {
  let pos = Position.to_pixel()
  // box
  for dy = 0; dy < 7; dy = dy + 1 {
    for dx = 0; dx < 7; dx = dx + 1 {
      let mut p = pos
      if dx == 0 ||
        dx == 6 ||
        dy == 0 ||
        dy == 6 ||
        (dx >= 2 && dx <= 4 && dy >= 2 && dy <= 4) {
        p = p | black
      }
      m[y + dy][x + dx] = p
    }
  }
  // white border
  for dy = -1; dy < 8; dy = dy + 1 {
    if y + dy >= 0 && y + dy < m.length() {
      if x > 0 {
        m[y + dy][x - 1] = pos
      }
      if x + 7 < m.length() {
        m[y + dy][x + 7] = pos
      }
    }
  }
  for dx = -1; dx < 8; dx = dx + 1 {
    if x + dx >= 0 && x + dx < m.length() {
      if y > 0 {
        m[y - 1][x + dx] = pos
      }
      if y + 7 < m.length() {
        m[y + 7][x + dx] = pos
      }
    }
  }
}

///|
/// align_box draws an alignment (small) box at upper left x, y.
fn align_box(m : Array[Array[Pixel]], x : Int, y : Int) -> Unit {
  let align = Alignment.to_pixel()
  for dy = 0; dy < 5; dy = dy + 1 {
    for dx = 0; dx < 5; dx = dx + 1 {
      let mut p = align
      if dx == 0 || dx == 4 || dy == 0 || dy == 4 || (dx == 2 && dy == 2) {
        p = p | black
      }
      m[y + dy][x + dx] = p
    }
  }
}
