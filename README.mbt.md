# PaiGack/moonbitqrcode

从 Go 库 [rsc.io/qr](https://pkg.go.dev/rsc.io/qr) 完整移植到 MoonBit 的 QR 码生成器。
支持版本 1-40、完整 Reed-Solomon 纠错，输出与 Go 参考实现**逐字节一致**。

## 快速开始

运行 demo 查看三个示例 QR 码（HELLO WORLD、12345678、https://moonbitlang.com）：

```bash
moon run src/cmd/main
```

## 特性

- 纯 MoonBit 实现，无外部依赖
- GF(256) 有限域算术，支持 Reed-Solomon 纠错
- 数字、字母数字、字节（UTF-8）三种数据模式
- 四种纠错级别：L (7%)、M (15%)、Q (25%)、H (30%)
- 全部 QR 版本 1-40（21×21 到 177×177 像素）
- 自动版本选择（挑选最小可容纳版本）
- ASCII 终端输出

## API

```mbt nocheck
// 以指定纠错级别生成 QR 码。
let qr = @lib.encode("你好,MoonBit!", @lib.L)

// 使用便捷函数。
let qr_low    = @lib.encode_low("文本")      // 7%  冗余
let qr_medium = @lib.encode_medium("文本")   // 15% 冗余
let qr_high   = @lib.encode_high("文本")     // 25% 冗余

// 访问位图。
let n = qr.size              // 每边像素数
let b = qr.is_black(x, y)    // 像素 (x, y) 是否为黑？

// 以 ASCII 形式输出。
println(qr.to_string())
```

## 测试

9 个单元测试全部通过。运行 `moon test`。

## 验证

与 Go 参考输出**逐字节一致**。详见 `baseline/compare.sh`。

## 许可证

Apache-2.0。Go 参考代码保留其 BSD-3-Clause 许可证（Go Authors）。
