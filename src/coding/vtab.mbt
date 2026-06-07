// QR code version table, ported from rsc.io/qr/coding/qr.go (vtab)
// Generated from qrencode-3.1.1/qrspec.c.

///|
/// LevelInfo describes the number of blocks and check bytes per level.
pub struct LevelInfo {
  nblock : Int
  check : Int
} derive(Eq)

///|
/// VersionInfo describes metadata for a specific QR version.
pub struct VersionInfo {
  apos : Int // alignment pattern offset (or 100 if none)
  astride : Int // alignment pattern stride (or 100)
  bytes : Int // total bytes in code
  pattern : Int // version pattern (or 0 for v<=6)
  level : Array[LevelInfo] // size 4: L, M, Q, H
} derive(Eq)

///|
/// Make a LevelInfo.
fn make_level(nblock : Int, check : Int) -> LevelInfo {
  { nblock, check }
}

///|
/// Build a VersionInfo.
fn make_version(
  apos : Int,
  astride : Int,
  bytes : Int,
  pattern : Int,
  levels : Array[LevelInfo],
) -> VersionInfo {
  { apos, astride, bytes, pattern, level: levels }
}

///|
/// The version table (vtab) for QR versions 1-40.
/// Index 0 is a placeholder; the actual entries start at index 1.
pub let vtab : Array[VersionInfo] = [
  // index 0: placeholder
  make_version(0, 0, 0, 0, [
    make_level(0, 0),
    make_level(0, 0),
    make_level(0, 0),
    make_level(0, 0),
  ]),
  // 1
  make_version(100, 100, 26, 0x0, [
    make_level(1, 7),
    make_level(1, 10),
    make_level(1, 13),
    make_level(1, 17),
  ]),
  // 2
  make_version(16, 100, 44, 0x0, [
    make_level(1, 10),
    make_level(1, 16),
    make_level(1, 22),
    make_level(1, 28),
  ]),
  // 3
  make_version(20, 100, 70, 0x0, [
    make_level(1, 15),
    make_level(1, 26),
    make_level(2, 18),
    make_level(2, 22),
  ]),
  // 4
  make_version(24, 100, 100, 0x0, [
    make_level(1, 20),
    make_level(2, 18),
    make_level(2, 26),
    make_level(4, 16),
  ]),
  // 5
  make_version(28, 100, 134, 0x0, [
    make_level(1, 26),
    make_level(2, 24),
    make_level(4, 18),
    make_level(4, 22),
  ]),
  // 6
  make_version(32, 100, 172, 0x0, [
    make_level(2, 18),
    make_level(4, 16),
    make_level(4, 24),
    make_level(4, 28),
  ]),
  // 7
  make_version(20, 16, 196, 0x7c94, [
    make_level(2, 20),
    make_level(4, 18),
    make_level(6, 18),
    make_level(5, 26),
  ]),
  // 8
  make_version(22, 18, 242, 0x85bc, [
    make_level(2, 24),
    make_level(4, 22),
    make_level(6, 22),
    make_level(6, 26),
  ]),
  // 9
  make_version(24, 20, 292, 0x9a99, [
    make_level(2, 30),
    make_level(5, 22),
    make_level(8, 20),
    make_level(8, 24),
  ]),
  // 10
  make_version(26, 22, 346, 0xa4d3, [
    make_level(4, 18),
    make_level(5, 26),
    make_level(8, 24),
    make_level(8, 28),
  ]),
  // 11
  make_version(28, 24, 404, 0xbbf6, [
    make_level(4, 20),
    make_level(5, 30),
    make_level(8, 28),
    make_level(11, 24),
  ]),
  // 12
  make_version(30, 26, 466, 0xc762, [
    make_level(4, 24),
    make_level(8, 22),
    make_level(10, 26),
    make_level(11, 28),
  ]),
  // 13
  make_version(32, 28, 532, 0xd847, [
    make_level(4, 26),
    make_level(9, 22),
    make_level(12, 24),
    make_level(16, 22),
  ]),
  // 14
  make_version(24, 20, 581, 0xe60d, [
    make_level(4, 30),
    make_level(9, 24),
    make_level(16, 20),
    make_level(16, 24),
  ]),
  // 15
  make_version(24, 22, 655, 0xf928, [
    make_level(6, 22),
    make_level(10, 24),
    make_level(12, 30),
    make_level(18, 24),
  ]),
  // 16
  make_version(24, 24, 733, 0x10b78, [
    make_level(6, 24),
    make_level(10, 28),
    make_level(17, 24),
    make_level(16, 30),
  ]),
  // 17
  make_version(28, 24, 815, 0x1145d, [
    make_level(6, 28),
    make_level(11, 28),
    make_level(16, 28),
    make_level(19, 28),
  ]),
  // 18
  make_version(28, 26, 901, 0x12a17, [
    make_level(6, 30),
    make_level(13, 26),
    make_level(18, 28),
    make_level(21, 28),
  ]),
  // 19
  make_version(28, 28, 991, 0x13532, [
    make_level(7, 28),
    make_level(14, 26),
    make_level(21, 26),
    make_level(25, 26),
  ]),
  // 20
  make_version(32, 28, 1085, 0x149a6, [
    make_level(8, 28),
    make_level(16, 26),
    make_level(20, 30),
    make_level(25, 28),
  ]),
  // 21
  make_version(26, 22, 1156, 0x15683, [
    make_level(8, 28),
    make_level(17, 26),
    make_level(23, 28),
    make_level(25, 30),
  ]),
  // 22
  make_version(24, 24, 1258, 0x168c9, [
    make_level(9, 28),
    make_level(17, 28),
    make_level(23, 30),
    make_level(34, 24),
  ]),
  // 23
  make_version(28, 24, 1364, 0x177ec, [
    make_level(9, 30),
    make_level(18, 28),
    make_level(25, 30),
    make_level(30, 30),
  ]),
  // 24
  make_version(26, 26, 1474, 0x18ec4, [
    make_level(10, 30),
    make_level(20, 28),
    make_level(27, 30),
    make_level(32, 30),
  ]),
  // 25
  make_version(30, 26, 1588, 0x191e1, [
    make_level(12, 26),
    make_level(21, 28),
    make_level(29, 30),
    make_level(35, 30),
  ]),
  // 26
  make_version(28, 28, 1706, 0x1afab, [
    make_level(12, 28),
    make_level(23, 28),
    make_level(34, 28),
    make_level(37, 30),
  ]),
  // 27
  make_version(32, 28, 1828, 0x1b08e, [
    make_level(12, 30),
    make_level(25, 28),
    make_level(34, 30),
    make_level(40, 30),
  ]),
  // 28
  make_version(24, 24, 1921, 0x1cc1a, [
    make_level(13, 30),
    make_level(26, 28),
    make_level(35, 30),
    make_level(42, 30),
  ]),
  // 29
  make_version(28, 24, 2051, 0x1d33f, [
    make_level(14, 30),
    make_level(28, 28),
    make_level(38, 30),
    make_level(45, 30),
  ]),
  // 30
  make_version(24, 26, 2185, 0x1ed75, [
    make_level(15, 30),
    make_level(29, 28),
    make_level(40, 30),
    make_level(48, 30),
  ]),
  // 31
  make_version(28, 26, 2323, 0x1f250, [
    make_level(16, 30),
    make_level(31, 28),
    make_level(43, 30),
    make_level(51, 30),
  ]),
  // 32
  make_version(32, 26, 2465, 0x209d5, [
    make_level(17, 30),
    make_level(33, 28),
    make_level(45, 30),
    make_level(54, 30),
  ]),
  // 33
  make_version(28, 28, 2611, 0x216f0, [
    make_level(18, 30),
    make_level(35, 28),
    make_level(48, 30),
    make_level(57, 30),
  ]),
  // 34
  make_version(32, 28, 2761, 0x228ba, [
    make_level(19, 30),
    make_level(37, 28),
    make_level(51, 30),
    make_level(60, 30),
  ]),
  // 35
  make_version(28, 24, 2876, 0x2379f, [
    make_level(19, 30),
    make_level(38, 28),
    make_level(53, 30),
    make_level(63, 30),
  ]),
  // 36
  make_version(22, 26, 3034, 0x24b0b, [
    make_level(20, 30),
    make_level(40, 28),
    make_level(56, 30),
    make_level(66, 30),
  ]),
  // 37
  make_version(26, 26, 3196, 0x2542e, [
    make_level(21, 30),
    make_level(43, 28),
    make_level(59, 30),
    make_level(70, 30),
  ]),
  // 38
  make_version(30, 26, 3362, 0x26a64, [
    make_level(22, 30),
    make_level(45, 28),
    make_level(62, 30),
    make_level(74, 30),
  ]),
  // 39
  make_version(24, 28, 3532, 0x27541, [
    make_level(24, 30),
    make_level(47, 28),
    make_level(65, 30),
    make_level(77, 30),
  ]),
  // 40
  make_version(28, 28, 3706, 0x28c69, [
    make_level(25, 30),
    make_level(49, 28),
    make_level(68, 30),
    make_level(81, 30),
  ]),
]

///|
/// Return the number of data bytes that can be stored in a QR code with
/// the given version and level.
pub fn version_data_bytes(v : Version, l : Level) -> Int {
  let vt = vtab[v]
  let lev = vt.level[l.to_int()]
  vt.bytes - lev.nblock * lev.check
}
