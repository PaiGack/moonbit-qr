// Public API for QR code generation

// QRCode represents an encoded QR code
pub struct QRCode {
  pub version : Int
  pub level : @coding.Level
  pub size : Int
  pub modules : Array[Array[Int]]  // The actual QR code grid (0=white, 1=black)
}

// encode generates a QR code for the given text with specified error correction level
pub fn encode(text : String, level : @coding.Level) -> QRCode {
  // Choose appropriate version for the text length
  let version = choose_version(text, level)

  // Create plan
  let plan = @coding.new_plan(version, level)

  // Initialize grid with fixed patterns
  @coding.init_grid(plan)

  // Encode data
  let bits = @coding.encode_data(text, version, level)

  // Get capacity info
  let (data_bytes, ec_per_block, blocks) = @coding.version_info(version, level)

  // Pad to target length
  let target_bits = data_bytes * 8
  @coding.pad_bits(bits, target_bits)

  // Add error correction
  let data_with_ec = @coding.add_error_correction(bits.bytes(), ec_per_block, blocks)

  // Write data to grid
  @coding.write_data(plan, data_with_ec)

  // Apply best mask
  let best_mask = choose_best_mask(plan)
  @coding.apply_mask(plan, best_mask)

  // Write format information
  @coding.write_format(plan, best_mask)

  // Return QRCode
  {
    version: plan.version,
    level: plan.level,
    size: plan.pixel.length(),
    modules: plan.pixel,
  }
}

// choose_version selects an appropriate QR code version for the given text
fn choose_version(text : String, level : @coding.Level) -> Int {
  // Try versions 1-5 (we have data for these)
  for v = 1; v <= 5; v = v + 1 {
    let (capacity, _ec, _blocks) = @coding.version_info(v, level)
    // Rough estimate: need mode indicator + count + data
    let needed = text.length() + 2

    if needed <= capacity {
      return v
    }
  }

  // Default to version 5 if nothing fits
  5
}

// choose_best_mask selects the best mask pattern (lowest penalty score)
fn choose_best_mask(plan : @coding.Plan) -> Int {
  let mut best_mask = 0
  let mut best_score = 999999

  // Try all 8 mask patterns
  for mask = 0; mask < 8; mask = mask + 1 {
    // Save original pixels
    let original_pixels = @coding.copy_plan_pixels(plan)

    // Apply mask
    @coding.apply_mask(plan, mask)
    let score = penalty_score(plan)

    // Restore original pixels
    for y = 0; y < plan.pixel.length(); y = y + 1 {
      for x = 0; x < plan.pixel[0].length(); x = x + 1 {
        plan.pixel[y][x] = original_pixels[y][x]
      }
    }

    if score < best_score {
      best_score = score
      best_mask = mask
    }
  }

  best_mask
}

// penalty_score calculates the penalty score for a QR code (lower is better)
fn penalty_score(plan : @coding.Plan) -> Int {
  let mut score = 0
  let size = plan.pixel.length()

  // Rule 1: Adjacent modules in row/column with same color (5+ gets penalty)
  for y = 0; y < size; y = y + 1 {
    let mut run_color = plan.pixel[y][0]
    let mut run_length = 1

    for x = 1; x < size; x = x + 1 {
      if plan.pixel[y][x] == run_color {
        run_length = run_length + 1
      } else {
        if run_length >= 5 {
          score = score + (run_length - 5 + 3)
        }
        run_color = plan.pixel[y][x]
        run_length = 1
      }
    }

    if run_length >= 5 {
      score = score + (run_length - 5 + 3)
    }
  }

  // Column check
  for x = 0; x < size; x = x + 1 {
    let mut run_color = plan.pixel[0][x]
    let mut run_length = 1

    for y = 1; y < size; y = y + 1 {
      if plan.pixel[y][x] == run_color {
        run_length = run_length + 1
      } else {
        if run_length >= 5 {
          score = score + (run_length - 5 + 3)
        }
        run_color = plan.pixel[y][x]
        run_length = 1
      }
    }

    if run_length >= 5 {
      score = score + (run_length - 5 + 3)
    }
  }

  // Rule 2: 2x2 blocks of same color
  for y = 0; y < size - 1; y = y + 1 {
    for x = 0; x < size - 1; x = x + 1 {
      let color = plan.pixel[y][x]
      if plan.pixel[y][x + 1] == color &&
         plan.pixel[y + 1][x] == color &&
         plan.pixel[y + 1][x + 1] == color {
        score = score + 3
      }
    }
  }

  score
}

// get returns the module value at (x, y), true if black
pub fn QRCode::get(self : QRCode, x : Int, y : Int) -> Bool {
  if x < 0 || x >= self.size || y < 0 || y >= self.size {
    return false
  }
  self.modules[y][x] == 1
}

// to_string creates a simple ASCII representation of the QR code
pub fn QRCode::to_string(self : QRCode) -> String {
  let mut result = ""

  // Add top border
  for _i = 0; _i < self.size + 2; _i = _i + 1 {
    result = result + "█"
  }
  result = result + "\n"

  // Add each row
  for y = 0; y < self.size; y = y + 1 {
    result = result + "█"  // Left border

    for x = 0; x < self.size; x = x + 1 {
      result = result + (if self.get(x, y) { "██" } else { "  " })
    }

    result = result + "█\n"  // Right border
  }

  // Add bottom border
  for _i = 0; _i < self.size + 2; _i = _i + 1 {
    result = result + "█"
  }
  result = result + "\n"

  result
}

// Quick encoding functions with default error correction levels
pub fn encode_low(text : String) -> QRCode {
  encode(text, @coding.Level::L)
}

pub fn encode_medium(text : String) -> QRCode {
  encode(text, @coding.Level::M)
}

pub fn encode_high(text : String) -> QRCode {
  encode(text, @coding.Level::H)
}
