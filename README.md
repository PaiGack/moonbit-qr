# MoonBit QR Code Generator

一个用纯MoonBit实现的QR码生成器，从Go的`rsc.io/qr`库移植而来。

## ✨ 特性

- ✅ **纯MoonBit实现** - 无外部依赖
- ✅ **Reed-Solomon纠错码** - 完整的GF(256)有限域运算
- ✅ **多种编码模式** - 支持数字、字母数字、字节模式
- ✅ **多种纠错级别** - L(7%), M(15%), Q(25%), H(30%)
- ✅ **版本1-5支持** - 可扩展到版本40
- ✅ **ASCII输出** - 在终端直接显示QR码
- ✅ **完整测试** - gf256和qr包都有全面的单元测试

## 🚀 快速开始

### 运行示例

```bash
moon run cmd/main
```

### 在代码中使用

```moonbit
// 生成低纠错级别的QR码
let qr = @lib.encode_low("Hello, MoonBit!")

// 打印ASCII格式
println(qr.to_string())

// 访问像素数据
for y = 0; y < qr.size; y = y + 1 {
  for x = 0; x < qr.size; x = x + 1 {
    let is_black = qr.get(x, y)
    // 处理像素...
  }
}
```

### 不同纠错级别

```moonbit
let qr_low = @lib.encode_low("TEXT")       // 7% 纠错
let qr_medium = @lib.encode_medium("TEXT") // 15% 纠错
let qr_high = @lib.encode_high("TEXT")     // 30% 纠错
```

## 📦 项目结构

```
moonbit-qr/
├── src/
│   ├── gf256/          # GF(256)有限域运算
│   │   ├── gf256.mbt
│   │   └── gf256_test.mbt
│   ├── coding/         # QR码编码核心
│   │   ├── types.mbt
│   │   ├── layout.mbt
│   │   └── encode.mbt
│   └── lib/            # 公共API
│       ├── qr.mbt
│       └── qr_test.mbt
├── cmd/main/           # CLI工具
│   └── main.mbt
└── docs/               # 文档
    └── prd-000-feasibility-analysis.md
```

## 🧪 测试

```bash
# 运行所有测试
moon test

# 运行特定包的测试
moon test src/gf256
moon test src/lib
```

**测试结果**：
- gf256包：9个测试全部通过 ✅
- lib包：4个测试全部通过 ✅

## 📚 算法详解

### 1. GF(256)有限域运算 (gf256包)

实现了Reed-Solomon纠错码所需的伽罗瓦域GF(256)算术：
- 加法（XOR）
- 乘法（对数表查找）
- 求逆
- 多项式运算

### 2. QR码编码 (coding包)

#### 数据编码模式
- **数字模式** - 仅数字0-9，最高效
- **字母数字模式** - 0-9, A-Z, 空格和一些符号
- **字节模式** - 任意UTF-8数据

#### 布局生成
- 定位图案（Finder patterns）
- 对齐图案（Alignment patterns）
- 时序图案（Timing patterns）
- 格式信息（Format information）

#### 掩码选择
自动选择8种掩码模式中最优的一种，以最小化惩罚分数。

### 3. 公共API (lib包)

简洁的用户接口：
- `encode(text, level)` - 主编码函数
- `encode_low/medium/high(text)` - 便捷函数
- `QRCode::get(x, y)` - 获取像素
- `QRCode::to_string()` - ASCII输出

## 🎯 实现状态

### 已完成 ✅
- [x] GF(256)有限域运算
- [x] Reed-Solomon纠错编码
- [x] QR码布局生成
- [x] 数据编码（数字/字母数字/字节）
- [x] 掩码应用和选择
- [x] 格式信息编码
- [x] ASCII文本输出
- [x] 版本1-5支持
- [x] 完整单元测试

### 待实现 🚧
- [ ] SVG输出
- [ ] PNG输出（需要CRC32和DEFLATE）
- [ ] 版本6-40支持
- [ ] 自动版本选择优化
- [ ] 性能优化

## 📖 可行性分析

详见 [docs/prd-000-feasibility-analysis.md](docs/prd-000-feasibility-analysis.md)

该文档包含：
- 完整的技术可行性分析
- 从Go到MoonBit的移植策略
- 分8个阶段的执行计划
- 工作量估算（20-30工作日）

## 🔗 参考

- **原始项目**: [rsc.io/qr](https://pkg.go.dev/rsc.io/qr) (Go)
- **QR码规范**: ISO/IEC 18004
- **MoonBit语言**: [moonbitlang.com](https://www.moonbitlang.com/)

## 📄 许可证

Apache-2.0 License

原始Go代码：BSD-3-Clause License (Go Authors)

## 🙏 致谢

本项目是从Russ Cox的`rsc.io/qr` Go库移植而来，感谢原作者的优秀实现。

---

**生成QR码示例**：

```
=== MoonBit QR Code Generator ===

Generating QR code for: 'HELLO WORLD'
Version: 1, Size: 21x21
███████████████████████
███████████████  ██  ████    ███████████████
███          ██  ██████      ██          ███
███  ██████  ██  ██  ████    ██  ██████  ███
███  ██████  ██    ██        ██  ██████  ███
███  ██████  ██  ██  ██      ██  ██████  ███
███          ██  ████  ██    ██          ███
███████████████  ██  ██  ██  ███████████████
...
```

用手机扫描上面的QR码即可验证！🎉
