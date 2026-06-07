// Galois Field GF(256) arithmetic, ported from rsc.io/qr/gf256/gf256.go

///|
/// A Field represents an instance of GF(256) defined by a specific polynomial.
struct Field {
  log : FixedArray[Byte] // size 256, log[0] is unused
  exp : FixedArray[Byte] // size 510
}

///|
/// nbit returns the number of significant bits in p.
fn nbit(p : Int) -> Int {
  let mut n = 0
  let mut v = p
  while v > 0 {
    n = n + 1
    v = v >> 1
  }
  n
}

///|
/// polyDiv divides the polynomial p by q and returns the remainder.
fn poly_div(p_in : Int, q : Int) -> Int {
  let mut p = p_in
  let np = nbit(p)
  let nq = nbit(q)
  let mut np_cur = np
  while np_cur >= nq {
    if ((p >> (np_cur - 1)) & 1) != 0 {
      p = p ^ (q << (np_cur - nq))
    }
    np_cur = np_cur - 1
  }
  p
}

///|
/// mul returns the product x*y mod poly, a GF(256) multiplication.
fn gf_mul(x_in : Int, y_in : Int, poly : Int) -> Int {
  let mut x = x_in
  let mut y = y_in
  let mut z = 0
  while x > 0 {
    if (x & 1) != 0 {
      z = z ^ y
    }
    x = x >> 1
    y = y << 1
    if (y & 0x100) != 0 {
      y = y ^ poly
    }
  }
  z
}

///|
/// reducible reports whether p is reducible.
fn reducible(p : Int) -> Bool {
  let np = nbit(p)
  // Multiplying n-bit * n-bit produces (2n-1)-bit,
  // so if p is reducible, one of its factors must be
  // of np/2+1 bits or fewer.
  for q = 2; q < 1 << (np / 2 + 1); q = q + 1 {
    if poly_div(p, q) == 0 {
      return true
    }
  }
  false
}

///|
/// NewField returns a new field corresponding to the polynomial poly
/// and generator alpha.  The Reed-Solomon encoding in QR codes uses
/// polynomial 0x11d with generator 2.
pub fn Field::new(poly : Int, alpha : Int) -> Field {
  if poly < 0x100 || poly >= 0x200 || reducible(poly) {
    abort("gf256: invalid polynomial")
  }
  let log = FixedArray::make(256, b'\x00')
  let exp = FixedArray::make(510, b'\x00')
  let mut x = 1
  for i = 0; i < 255; i = i + 1 {
    if x == 1 && i != 0 {
      abort("gf256: invalid generator")
    }
    exp[i] = x.to_byte()
    exp[i + 255] = x.to_byte()
    log[x] = i.to_byte()
    x = gf_mul(x, alpha, poly)
  }
  log[0] = b'\xff' // 255
  // sanity check
  for i = 0; i < 255; i = i + 1 {
    if log[exp[i].to_int()] != i.to_byte() {
      abort("bad log")
    }
    if log[exp[i + 255].to_int()] != i.to_byte() {
      abort("bad log")
    }
  }
  for i = 1; i < 256; i = i + 1 {
    if exp[log[i].to_int()] != i.to_byte() {
      abort("bad log")
    }
  }
  { log, exp }
}

///|
/// Add returns the sum of x and y in the field.
pub fn Field::add(_self : Field, x : Byte, y : Byte) -> Byte {
  x ^ y
}

///|
/// Exp returns the base-alpha exponential of e in the field.
/// If e < 0, Exp returns 0.
pub fn Field::exp(self : Field, e : Int) -> Byte {
  if e < 0 {
    return b'\x00'
  }
  self.exp[e % 255]
}

///|
/// Log returns the base-alpha logarithm of x in the field.
/// If x == 0, Log returns -1.
pub fn Field::log(self : Field, x : Byte) -> Int {
  if x == b'\x00' {
    return -1
  }
  self.log[x.to_int()].to_int()
}

///|
/// Inv returns the multiplicative inverse of x in the field.
/// If x == 0, Inv returns 0.
pub fn Field::inv(self : Field, x : Byte) -> Byte {
  if x == b'\x00' {
    return b'\x00'
  }
  self.exp[255 - self.log[x.to_int()].to_int()]
}

///|
/// Mul returns the product of x and y in the field.
pub fn Field::mul(self : Field, x : Byte, y : Byte) -> Byte {
  if x == b'\x00' || y == b'\x00' {
    return b'\x00'
  }
  let li = self.log[x.to_int()].to_int()
  let lj = self.log[y.to_int()].to_int()
  self.exp[li + lj]
}

///|
/// gen returns the generator polynomial and its log-form
/// for e error correction bytes.
fn Field::gen(self : Field, e : Int) -> (Array[Byte], Array[Byte]) {
  // p = 1
  let p : Array[Byte] = Array::make(e + 1, b'\x00')
  p[e] = b'\x01'
  for i = 0; i < e; i = i + 1 {
    // p *= (x + Exp(i))
    // p[j] = p[j]*Exp(i) + p[j+1].
    let c = self.exp(i)
    for j = 0; j < e; j = j + 1 {
      p[j] = self.mul(p[j], c) ^ p[j + 1]
    }
    p[e] = self.mul(p[e], c)
  }
  // lp = log p.
  let lp : Array[Byte] = Array::make(e + 1, b'\x00')
  for i = 0; i < e + 1; i = i + 1 {
    let c = p[i]
    if c == b'\x00' {
      lp[i] = b'\xff' // 255
    } else {
      lp[i] = self.log(c).to_byte()
    }
  }
  (p, lp)
}

///|
/// An RSEncoder implements Reed-Solomon encoding
/// over a given field using a given number of error correction bytes.
pub struct RSEncoder {
  f : Field
  c : Int
  gen : Array[Byte]
  lgen : Array[Byte]
}

///|
/// NewRSEncoder returns a new Reed-Solomon encoder
/// over the given field and number of error correction bytes.
pub fn RSEncoder::new(f : Field, c : Int) -> RSEncoder {
  let (gen, lgen) = f.gen(c)
  { f, c, gen, lgen }
}

///|
/// ECC writes a freshly-allocated check slice containing the error correcting code bytes
/// for data using the given Reed-Solomon parameters.
pub fn RSEncoder::ecc(self : RSEncoder, data : Array[Byte]) -> Array[Byte] {
  let c = self.c
  if c == 0 {
    return Array::make(0, b'\x00')
  }
  // The check bytes are the remainder after dividing
  // data padded with c zeros by the generator polynomial.
  let n = data.length() + c
  let p : Array[Byte] = Array::make(n, b'\x00')
  for i = 0; i < data.length(); i = i + 1 {
    p[i] = data[i]
  }
  // p[data.length():] is already 0.

  // Divide p by gen, leaving the remainder in p[data.length():].
  // p[0] is the most significant term in p, and
  // gen[0] is the most significant term in the generator,
  // which is always 1.
  // To avoid repeated work, we store various values as
  // lv, not v, where lv = log[v].
  let f = self.f
  let lgen = self.lgen[1:]
  for i = 0; i < data.length(); i = i + 1 {
    let ci = p[i]
    if ci == b'\x00' {
      continue
    }
    let start = f.log[ci.to_int()].to_int()
    for j = 0; j < lgen.length(); j = j + 1 {
      let lg = lgen[j]
      if lg != b'\xff' {
        // lgen uses 255 for log 0
        p[i + 1 + j] = p[i + 1 + j] ^ f.exp[start + lg.to_int()]
      }
    }
  }
  let check : Array[Byte] = Array::make(c, b'\x00')
  for i = 0; i < c; i = i + 1 {
    check[i] = p[data.length() + i]
  }
  check
}
