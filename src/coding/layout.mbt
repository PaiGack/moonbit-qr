// QR code layout generation and planning

// Pixel values
let pixel_off : Int = 0    // white pixel
let pixel_on : Int = 1     // black pixel

// newPlan creates a Plan for a given version and level
pub fn new_plan(version : Int, level : Level) -> Plan {
  let size = version_size(version)
  let (data_bytes, check_per_block, blocks) = version_info(version, level)

  // Create pixel grid
  let pixel = Array::new(capacity=size)
  for _i = 0; _i < size; _i = _i + 1 {
    let row = Array::make(size, 0)
    pixel.push(row)
  }

  {
    version,
    level,
    data_bytes,
    check_bytes: check_per_block * blocks,
    blocks,
    pixel,
    data_cache: Array::new(),
    num_pixels: size * size,
  }
}

// addFinderPattern adds a finder pattern (position detection) at top-left corner offset by (x, y)
fn add_finder_pattern(p : Plan, x : Int, y : Int) -> Unit {
  // 7x7 finder pattern
  for dy = 0; dy < 7; dy = dy + 1 {
    for dx = 0; dx < 7; dx = dx + 1 {
      let py = y + dy
      let px = x + dx
      if py >= 0 && py < p.pixel.length() && px >= 0 && px < p.pixel[0].length() {
        if dy == 0 || dy == 6 || dx == 0 || dx == 6 {
          p.pixel[py][px] = pixel_on
        } else if dy == 1 || dy == 5 || dx == 1 || dx == 5 {
          p.pixel[py][px] = pixel_off
        } else {
          p.pixel[py][px] = pixel_on
        }
      }
    }
  }
}

// addSeparator adds white separator around finder pattern
fn add_separator(p : Plan, x : Int, y : Int, width : Int, height : Int) -> Unit {
  for dy = 0; dy < height; dy = dy + 1 {
    for dx = 0; dx < width; dx = dx + 1 {
      let py = y + dy
      let px = x + dx
      if py >= 0 && py < p.pixel.length() && px >= 0 && px < p.pixel[0].length() {
        p.pixel[py][px] = pixel_off
      }
    }
  }
}

// addAlignmentPattern adds an alignment pattern centered at (x, y)
fn add_alignment_pattern(p : Plan, x : Int, y : Int) -> Unit {
  for dy = -2; dy <= 2; dy = dy + 1 {
    for dx = -2; dx <= 2; dx = dx + 1 {
      let py = y + dy
      let px = x + dx
      if py >= 0 && py < p.pixel.length() && px >= 0 && px < p.pixel[0].length() {
        if dy == -2 || dy == 2 || dx == -2 || dx == 2 {
          p.pixel[py][px] = pixel_on
        } else if dx == 0 && dy == 0 {
          p.pixel[py][px] = pixel_on
        } else {
          p.pixel[py][px] = pixel_off
        }
      }
    }
  }
}

// initGrid initializes the QR code grid with all fixed patterns
pub fn init_grid(p : Plan) -> Unit {
  let size = p.pixel.length()

  add_finder_pattern(p, 0, 0)
  add_finder_pattern(p, size - 7, 0)
  add_finder_pattern(p, 0, size - 7)

  add_separator(p, 7, 0, 1, 8)
  add_separator(p, 0, 7, 8, 1)
  add_separator(p, size - 8, 0, 1, 8)
  add_separator(p, size - 8, 7, 8, 1)
  add_separator(p, 7, size - 8, 1, 8)
  add_separator(p, 0, size - 8, 8, 1)

  for i = 8; i < size - 8; i = i + 1 {
    p.pixel[6][i] = if i % 2 == 0 { pixel_on } else { pixel_off }
    p.pixel[i][6] = if i % 2 == 0 { pixel_on } else { pixel_off }
  }

  p.pixel[size - 8][8] = pixel_on

  if p.version >= 2 {
    let positions = get_alignment_positions(p.version)
    for i = 0; i < positions.length(); i = i + 1 {
      for j = 0; j < positions.length(); j = j + 1 {
        let x = positions[i]
        let y = positions[j]

        if (x <= 10 && y <= 10) ||
           (x <= 10 && y >= size - 11) ||
           (x >= size - 11 && y <= 10) {
          continue
        }

        add_alignment_pattern(p, x, y)
      }
    }
  }
}

fn get_alignment_positions(version : Int) -> Array[Int] {
  if version == 1 {
    []
  } else if version == 2 {
    [18]
  } else if version == 3 {
    [22]
  } else if version == 4 {
    [26]
  } else if version == 5 {
    [30]
  } else if version == 6 {
    [34]
  } else if version == 7 {
    [6, 22, 38]
  } else {
    []
  }
}

fn encode_format(level : Level, mask : Int) -> Int {
  // Note: Go uses level^1 encoding: L=01, M=00, Q=11, H=10
  let level_bits = match level {
    L => 0b01
    M => 0b00
    Q => 0b11
    H => 0b10
  }

  let data = (level_bits << 3) | (mask & 0x07)

  let mut d = data << 10
  let gen = 0b10100110111

  for _i = 0; _i < 5; _i = _i + 1 {
    let check_bit = 14 - _i
    let has_bit = (d & (1 << check_bit)) != 0
    if has_bit {
      let shift = 4 - _i
      d = d ^ (gen << shift)
    }
  }

  let format = (data << 10) | d
  format ^ 0b101010000010010
}

pub fn write_format(p : Plan, mask : Int) -> Unit {
  let format = encode_format(p.level, mask)
  let size = p.pixel.length()

  // Format information is 15 bits, mapped to specific positions
  // See ISO/IEC 18004 and rsc.io/qr implementation
  for i = 0; i < 15; i = i + 1 {
    let bit = if (format & (1 << i)) != 0 { pixel_on } else { pixel_off }

    // Top-left format info (along row 8 and column 8, skipping timing at row/col 6)
    if i < 6 {
      // bits 0-5: column 8, rows 0-5
      p.pixel[i][8] = bit
    } else if i < 8 {
      // bits 6-7: column 8, rows 7-8 (skip row 6 = timing)
      p.pixel[i + 1][8] = bit
    } else if i < 9 {
      // bit 8: row 8, column 7 (column 6 is timing, column 8 is dark module)
      p.pixel[8][7] = bit
    } else {
      // bits 9-14: row 8, columns 5,4,3,2,1,0
      p.pixel[8][14 - i] = bit
    }

    // Bottom-left and top-right format info (mirror copy)
    if i < 8 {
      // bits 0-7: row 8, columns size-1 down to size-8
      p.pixel[8][size - 1 - i] = bit
    } else {
      // bits 8-14: column 8, rows size-7 down to size-1 (reverse of top)
      p.pixel[size - 1 - (14 - i)][8] = bit
    }
  }
}

pub fn apply_mask(p : Plan, mask : Int) -> Unit {
  let size = p.pixel.length()

  for y = 0; y < size; y = y + 1 {
    for x = 0; x < size; x = x + 1 {
      if is_function_pattern(p, x, y) {
        continue
      }

      let invert = match mask {
        0 => (y + x) % 2 == 0
        1 => y % 2 == 0
        2 => x % 3 == 0
        3 => (y + x) % 3 == 0
        4 => (y / 2 + x / 3) % 2 == 0
        5 => (y * x) % 2 + (y * x) % 3 == 0
        6 => ((y * x) % 2 + (y * x) % 3) % 2 == 0
        7 => ((y + x) % 2 + (y * x) % 3) % 2 == 0
        _ => false
      }

      if invert {
        p.pixel[y][x] = if p.pixel[y][x] == pixel_on { pixel_off } else { pixel_on }
      }
    }
  }
}

fn is_function_pattern(p : Plan, x : Int, y : Int) -> Bool {
  let size = p.pixel.length()

  // Finder patterns (7x7) + separators (1 pixel) + format area
  // Top-left: (0,0) to (8,8)
  // Top-right: (size-8,0) to (size-1,8)
  // Bottom-left: (0,size-8) to (8,size-1)
  if (x <= 8 && y <= 8) || (x >= size - 8 && y <= 8) || (x <= 8 && y >= size - 8) {
    return true
  }

  // Timing patterns (row 6 and column 6)
  if x == 6 || y == 6 {
    return true
  }

  // Dark module at (8, size-8)
  if x == 8 && y == size - 8 {
    return true
  }

  // Format information strips
  // Column 8: rows 0-8 and rows size-8 to size-1
  // Row 8: columns 0-8 and columns size-8 to size-1
  if (x == 8 && (y < 9 || y >= size - 8)) || (y == 8 && (x < 9 || x >= size - 8)) {
    return true
  }

  false
}

pub fn copy_plan_pixels(p : Plan) -> Array[Array[Int]] {
  let size = p.pixel.length()
  let pixel_copy = Array::new(capacity=size)

  for y = 0; y < size; y = y + 1 {
    let row = Array::new(capacity=size)
    for x = 0; x < size; x = x + 1 {
      row.push(p.pixel[y][x])
    }
    pixel_copy.push(row)
  }

  pixel_copy
}
