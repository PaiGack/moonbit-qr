// Package gf256 implements arithmetic over GF(256).
// GF(256) is the Galois Field with 256 elements, used for Reed-Solomon error correction.

// Field represents a Galois Field GF(256) with a given polynomial.
struct Field {
  log : FixedArray[Int]  // log table: log[0] is unused, log[i] = log_α(i)
  exp : FixedArray[Int]  // exp table: exp[i] = α^i
}

// new creates a new Field with the given polynomial and generator.
// poly: the primitive polynomial (e.g., 0x11d for QR codes)
// gen: the generator element (usually 2)
pub fn Field::new(poly : Int, gen : Int) -> Field {
  let log = FixedArray::make(256, 0)
  let exp = FixedArray::make(512, 0)  // doubled for convenience

  // Generate exp and log tables
  let mut x = 1
  for i = 0; i < 255; i = i + 1 {
    exp[i] = x
    exp[i + 255] = x  // duplicate for wrap-around
    log[x] = i

    // Multiply by generator
    x = x * gen
    if x >= 256 {
      x = x.lxor(poly)  // reduce by polynomial
    }
  }

  { log, exp }
}

// zero returns the zero element
pub fn Field::zero(_self : Field) -> Int {
  0
}

// one returns the multiplicative identity
pub fn Field::one(_self : Field) -> Int {
  1
}

// add returns the sum of x and y in GF(256)
// Addition in GF(256) is XOR
pub fn Field::add(_self : Field, x : Int, y : Int) -> Int {
  x.lxor(y)
}

// mul returns the product of x and y in GF(256)
pub fn Field::mul(self : Field, x : Int, y : Int) -> Int {
  if x == 0 || y == 0 {
    return 0
  }
  // log(x*y) = log(x) + log(y)
  let log_x = self.log[x]
  let log_y = self.log[y]
  self.exp[log_x + log_y]
}

// inv returns the multiplicative inverse of x in GF(256)
pub fn Field::inv(self : Field, x : Int) -> Int {
  if x == 0 {
    abort("gf256: inverse of zero")
  }
  // log(1/x) = -log(x) = 255 - log(x)
  let log_x = self.log[x]
  self.exp[255 - log_x]
}

// exp_func returns α^e where α is the generator
pub fn Field::exp_func(self : Field, e : Int) -> Int {
  self.exp[e % 255]
}

// log_func returns log_α(x)
pub fn Field::log_func(self : Field, x : Int) -> Int {
  if x == 0 {
    abort("gf256: log of zero")
  }
  self.log[x]
}

// RSEncoder implements Reed-Solomon encoding over GF(256)
pub struct RSEncoder {
  field : Field
  gen : Array[Int]  // generator polynomial coefficients
}

// new_rs creates a Reed-Solomon encoder for 'num_errors' error correction symbols
pub fn RSEncoder::new(field : Field, num_errors : Int) -> RSEncoder {
  // Generate the generator polynomial: g(x) = (x - α^0)(x - α^1)...(x - α^(num_errors-1))
  let gen = Array::new(capacity=num_errors + 1)
  gen.push(1)  // g(x) starts as 1

  for i = 0; i < num_errors; i = i + 1 {
    // Multiply g(x) by (x - α^i)
    gen.push(0)
    let mut j = gen.length() - 1
    while j > 0 {
      let c = gen[j]
      if c != 0 {
        gen[j] = field.add(gen[j - 1], field.mul(c, field.exp_func(i)))
      } else {
        gen[j] = gen[j - 1]
      }
      j = j - 1
    }
    gen[0] = field.mul(gen[0], field.exp_func(i))
  }

  { field, gen }
}

// ecc computes the error correction code for data
pub fn RSEncoder::ecc(self : RSEncoder, data : Array[Int]) -> Array[Int] {
  let num_ecc = self.gen.length() - 1
  let ecc = Array::make(num_ecc, 0)

  // Polynomial division
  for i = 0; i < data.length(); i = i + 1 {
    let fb = ecc[0].lxor(data[i])
    for j = 0; j < num_ecc - 1; j = j + 1 {
      ecc[j] = ecc[j + 1].lxor(if fb == 0 { 0 } else {
        self.field.mul(self.gen[j + 1], fb)
      })
    }
    ecc[num_ecc - 1] = if fb == 0 { 0 } else {
      self.field.mul(self.gen[num_ecc], fb)
    }
  }

  ecc
}

// QR code uses poly=0x11d (x^8 + x^4 + x^3 + x^2 + 1) with generator 2
pub let qr_field : Field = Field::new(0x11d, 2)

// qr_rs creates a Reed-Solomon encoder for QR codes
pub fn qr_rs(num_errors : Int) -> RSEncoder {
  RSEncoder::new(qr_field, num_errors)
}
