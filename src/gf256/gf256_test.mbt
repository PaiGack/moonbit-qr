// Test file for gf256 package

test "Field creation and basic properties" {
  let f = Field::new(0x11d, 2)

  // Test zero and one
  assert_eq!(f.zero(), 0)
  assert_eq!(f.one(), 1)

  // Test that exp and log tables are inverses
  for i = 1; i < 256; i = i + 1 {
    let b = i
    let e = f.log_func(b)
    let result = f.exp_func(e)
    assert_eq!(result, b)
  }
}

test "Field addition (XOR)" {
  let f = Field::new(0x11d, 2)

  // Addition is XOR in GF(256)
  assert_eq!(f.add(0, 0), 0)
  assert_eq!(f.add(0, 1), 1)
  assert_eq!(f.add(1, 1), 0)
  assert_eq!(f.add(3, 5), 6)  // 0b011 XOR 0b101 = 0b110
  assert_eq!(f.add(255, 255), 0)

  // Commutative
  assert_eq!(f.add(7, 13), f.add(13, 7))

  // Associative
  assert_eq!(f.add(f.add(3, 5), 7), f.add(3, f.add(5, 7)))

  // Identity
  assert_eq!(f.add(42, 0), 42)
}

test "Field multiplication" {
  let f = Field::new(0x11d, 2)

  // Multiplication by zero
  assert_eq!(f.mul(0, 5), 0)
  assert_eq!(f.mul(5, 0), 0)

  // Multiplication by one
  assert_eq!(f.mul(1, 7), 7)
  assert_eq!(f.mul(7, 1), 7)

  // Commutative
  assert_eq!(f.mul(3, 7), f.mul(7, 3))

  // Associative
  assert_eq!(f.mul(f.mul(3, 5), 7), f.mul(3, f.mul(5, 7)))

  // Distributive over addition
  let a = 3
  let b = 5
  let c = 7
  assert_eq!(f.mul(a, f.add(b, c)), f.add(f.mul(a, b), f.mul(a, c)))
}

test "Field inverse" {
  let f = Field::new(0x11d, 2)

  // Test that x * inv(x) = 1 for all non-zero x
  for i = 1; i < 256; i = i + 1 {
    let x = i
    let inv_x = f.inv(x)
    assert_eq!(f.mul(x, inv_x), 1)
  }
}

test "Field exp and log relationship" {
  let f = Field::new(0x11d, 2)

  // log(x * y) = log(x) + log(y)
  let x = 3
  let y = 7
  let product = f.mul(x, y)
  assert_eq!(f.log_func(product), (f.log_func(x) + f.log_func(y)) % 255)

  // exp(log(x)) = x for x != 0
  for i = 1; i < 256; i = i + 1 {
    let x = i
    assert_eq!(f.exp_func(f.log_func(x)), x)
  }
}

test "RSEncoder creation" {
  let f = Field::new(0x11d, 2)
  let rs = RSEncoder::new(f, 10)

  // Generator polynomial should have degree num_errors
  assert_eq!(rs.gen.length(), 11)  // degree 10 polynomial has 11 coefficients

  // Leading coefficient should be non-zero
  assert_true!(rs.gen[0] != 0)
}

test "RSEncoder ECC generation" {
  let rs = qr_rs(7)  // 7 error correction bytes

  // Test with known data
  let data = [1, 2, 3, 4, 5]
  let ecc = rs.ecc(data)

  // Should generate exactly 7 ECC bytes
  assert_eq!(ecc.length(), 7)

  // ECC should be deterministic
  let ecc2 = rs.ecc(data)
  assert_eq!(ecc.length(), ecc2.length())
  for i = 0; i < ecc.length(); i = i + 1 {
    assert_eq!(ecc[i], ecc2[i])
  }
}

test "RSEncoder with zero data" {
  let rs = qr_rs(5)

  let data = [0, 0, 0, 0]
  let ecc = rs.ecc(data)

  // ECC of all zeros should be all zeros
  assert_eq!(ecc.length(), 5)
  for i = 0; i < ecc.length(); i = i + 1 {
    assert_eq!(ecc[i], 0)
  }
}

test "RSEncoder property: ECC is linear" {
  let rs = qr_rs(5)
  let f = qr_field

  // ECC(a + b) = ECC(a) + ECC(b)
  let data1 = [1, 2, 3]
  let data2 = [4, 5, 6]
  let data_sum = [f.add(1, 4), f.add(2, 5), f.add(3, 6)]

  let ecc1 = rs.ecc(data1)
  let ecc2 = rs.ecc(data2)
  let ecc_sum = rs.ecc(data_sum)

  for i = 0; i < ecc1.length(); i = i + 1 {
    assert_eq!(f.add(ecc1[i], ecc2[i]), ecc_sum[i])
  }
}
