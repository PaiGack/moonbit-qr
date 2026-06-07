# MoonBit QR 码生成器

从 Go 库 [rsc.io/qr](https://pkg.go.dev/rsc.io/qr)（Russ Cox 的 QR 码生成器）完整移植到 MoonBit。支持版本 1-40、完整 Reed-Solomon 纠错，输出与 Go 参考实现**逐字节一致**。

## ✨ 特性

- ✅ **纯 MoonBit 实现** — 无外部依赖
- ✅ **GF(256) 有限域算术** — 完整 Reed-Solomon 纠错
- ✅ **三种数据模式** — 数字、字母数字、字节（UTF-8）
- ✅ **四种纠错级别** — L (7%)、M (15%)、Q (25%)、H (30%)
- ✅ **全部 QR 版本** — 1-40（21×21 到 177×177 像素）
- ✅ **自动版本选择** — 挑选最小可容纳版本
- ✅ **ASCII 输出** — 终端直接显示，黑块 `██`、白块 `  `

## 🚀 快速开始

### 运行示例

```bash
moon run src/cmd/main
```

会生成三个示例 QR 码（HELLO WORLD、12345678、https://moonbitlang.com）并以 ASCII 形式输出。

### 在代码中使用

```moonbit
// 使用便捷函数
let qr_low    = @lib.encode_low("你好,MoonBit!")    // 7%  冗余
let qr_medium = @lib.encode_medium("你好,MoonBit!")  // 15% 冗余
let qr_high   = @lib.encode_high("你好,MoonBit!")    // 25% 冗余

// 或直接调用 encode() 指定级别
let qr = @lib.encode("你好,MoonBit!", L)

// 以 ASCII 形式输出
println(qr.to_string())

// 访问像素数据
let is_black = qr.is_black(x, y)
let n        = qr.size
```

## 📦 项目结构

```
moonbit-qr/
├── moon.mod                       # 模块元信息
├── docs/
│   ├── prd-000.md                 # 原始 PRD
│   └── prd-000-feasibility-analysis.md
├── baseline/
│   ├── compare.sh                 # 输出对比脚本
│   └── go_rscio_qr/main.go        # Go 参考实现（用于验证）
└── src/
    ├── gf256/                     # 伽罗瓦域 GF(256) 算术
    │   ├── gf256.mbt              #   Field、Add、Mul、Exp、Log、Inv、RSEncoder
    │   └── gf256_test.mbt         #   3 个测试
    ├── coding/                    # QR 编码核心
    │   ├── bits.mbt               #   MSB-first 位缓冲区
    │   ├── bits_test.mbt          #   2 个测试
    │   ├── encoding.mbt           #   Num / Alpha / String 三种模式
    │   ├── pixel.mbt              #   Pixel、PixelRole、Mask
    │   ├── plan.mbt               #   Plan: vplan、fplan、lplan、mplan
    │   └── vtab.mbt               #   版本表（v1-v40）
    ├── lib/                       # 公共 API
    │   ├── qr.mbt                 #   QRCode、encode_low/medium/high
    │   └── qr_test.mbt            #   4 个测试
    └── cmd/
        └── main/                  # 命令行 demo
            ├── main.mbt
            └── moon.pkg
```

## 🧪 测试

```bash
moon test                          # 运行所有测试
moon test src/gf256                # 仅 GF(256) 测试
moon test src/coding               # 仅 coding 包测试
moon test src/lib                  # 仅 lib 包测试
```

当前结果：**9/9 测试全部通过** ✅

## 🔬 与 Go 实现的对比验证

仓库内含 Go 参考实现在 `baseline/go_rscio_qr/`，可验证 MoonBit 输出与 Go 完全一致：

```bash
cd baseline
go run go_rscio_qr/main.go > go_output.txt.tmp
cd ..
moon run src/cmd/main > baseline/moonbit_output.txt.tmp
diff baseline/moonbit_output.txt.tmp baseline/go_output.txt.tmp
```

三个示例 QR 码（HELLO WORLD、12345678、https://moonbitlang.com）的输出**逐字节一致**。✅

## 📚 公共 API

### `enum LibLevel`
- `L` — 7% 冗余
- `M` — 15% 冗余
- `Q` — 25% 冗余
- `H` — 30% 冗余

### `struct QRCode`
QR 码位图。

- `size : Int` — 每边像素数
- `modules : Array[Array[Int]]` — 二维数组，1 表示黑、0 表示白

方法：
- `QRCode::size()` — 每边像素数
- `QRCode::is_black(x, y)` — 查询像素
- `QRCode::to_string()` — ASCII 字符串

### 函数
- `encode(text : String, level : LibLevel) -> QRCode` — 主入口
- `encode_low(text : String) -> QRCode` — 级别 L
- `encode_medium(text : String) -> QRCode` — 级别 M
- `encode_high(text : String) -> QRCode` — 级别 Q

## 🔗 参考

- **原始 Go 项目**：[rsc.io/qr](https://pkg.go.dev/rsc.io/qr)（BSD-3-Clause）
- **QR 码规范**：ISO/IEC 18004
- **MoonBit 语言**：[moonbitlang.com](https://www.moonbitlang.com/)

## 📄 许可证

Apache-2.0。Go 参考代码保留其 BSD-3-Clause 许可证（Go Authors）。
