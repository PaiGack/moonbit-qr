# rsc.io/qr 移植到 MoonBit 可行性分析与执行计划

## 一、项目概述

**源项目**: `rsc.io/qr` v0.2.0  
**目标**: 完整移植到 MoonBit  
**源代码位置**: `C:\Users\C2\go\pkg\mod\rsc.io\qr@v0.2.0`  
**总代码量**: 约 2355 行 Go 代码

## 二、项目结构分析

### 2.1 目录结构

```
rsc.io/qr@v0.2.0/
├── qr.go              (117 行) - 主包，公共 API
├── png.go             (401 行) - PNG 编码器
├── png_test.go        (测试)
├── coding/
│   ├── qr.go          (816 行) - QR 编码核心逻辑
│   ├── gen.go         (150 行) - 代码生成工具（构建时）
│   └── qr_test.go     (测试)
├── gf256/
│   ├── gf256.go       (242 行) - 伽罗瓦域 GF(256) 算术
│   ├── gf256_test.go  (测试)
│   └── blog_test.go   (测试)
└── libqrencode/
    └── qrencode.go    (150 行) - C 库包装器（仅测试用）
```

### 2.2 模块依赖关系

```
qr (主包)
 ├─> coding (编码逻辑)
 │    └─> gf256 (数学基础)
 └─> image, color (Go 标准库)

libqrencode (独立，仅用于测试对比，不需要移植)
```

## 三、核心功能模块分析

### 3.1 gf256 包 - 伽罗瓦域运算

**功能**: 实现 GF(256) 有限域算术运算，用于 Reed-Solomon 纠错码

**核心数据结构**:
- `Field`: 包含对数表和指数表
- `RSEncoder`: Reed-Solomon 编码器

**关键算法**:
- 域初始化（多项式运算）
- 加法（XOR）
- 乘法（对数表查找）
- 求逆
- Reed-Solomon 纠错码生成

**移植难度**: ⭐⭐☆☆☆（中低）
- 纯数学算法，无外部依赖
- 需要实现字节数组操作
- 算法逻辑清晰

### 3.2 coding 包 - QR 编码核心

**功能**: QR 码编码的底层实现

**核心组件**:

1. **数据编码** (`Encoding` 接口)
   - `Num`: 数字模式（0-9）
   - `Alpha`: 字母数字模式（0-9A-Z $%*+-./:）
   - `String`: 字节模式（任意数据）

2. **版本管理** (`Version`)
   - 支持版本 1-40
   - 每个版本对应不同的尺寸和容量
   - 内置版本表（`vtab`）包含所有版本参数

3. **布局生成** (`Plan`)
   - 定位图案（Position markers）
   - 对齐图案（Alignment patterns）
   - 时序图案（Timing patterns）
   - 格式信息（Format info）
   - 版本信息（Version info）

4. **掩码应用** (`Mask`)
   - 8 种掩码模式
   - 避免伪图案

**移植难度**: ⭐⭐⭐⭐☆（较高）
- 逻辑复杂，包含大量位操作
- 需要仔细处理像素级布局
- 包含大型常量表（vtab）

### 3.3 qr 包 - 公共 API

**功能**: 提供简洁的用户接口

**核心 API**:
- `Encode(text string, level Level) (*Code, error)`: 生成 QR 码
- `Code` 结构: 表示 QR 码位图
- `Black(x, y int) bool`: 查询像素
- `Image() image.Image`: 转换为 Go 图像

**移植难度**: ⭐⭐☆☆☆（中低）
- API 层较简单
- 主要是调用 coding 包

### 3.4 png 包 - PNG 编码

**功能**: 将 QR 码编码为 PNG 图像

**特点**:
- 自定义 PNG 编码器（优化性能）
- 手动实现 DEFLATE 压缩
- 包含 Adler-32 校验和
- 针对 QR 码的黑白图像优化

**移植难度**: ⭐⭐⭐⭐⭐（高）
- 需要实现完整的 PNG 格式
- 需要实现 DEFLATE 压缩算法
- 二进制格式处理复杂
- **建议**: 可以使用 MoonBit 现有的图像库或简化输出

## 四、MoonBit 适配性分析

### 4.1 语言特性对比

| Go 特性 | MoonBit 对应方案 | 难度 |
|---------|------------------|------|
| 结构体（struct） | Struct | ✅ 直接对应 |
| 方法（method） | Method | ✅ 直接对应 |
| 接口（interface） | Trait | ✅ 使用 trait |
| 切片（slice） | Array/ArrayView | ⚠️ 需要适配 |
| 可变切片操作 | Array 方法 | ⚠️ 需要调整 |
| panic | abort/Result | ⚠️ 改用错误处理 |
| 位操作 | 位运算符 | ✅ 直接对应 |
| 字节数组 | Bytes/Array[Byte] | ✅ 直接对应 |

### 4.2 标准库依赖

| Go 标准库 | MoonBit 方案 | 说明 |
|-----------|--------------|------|
| `errors` | `@moonbitlang/core` | 使用 Result 类型 |
| `fmt` | `@moonbitlang/core` | 字符串格式化 |
| `strconv` | `@moonbitlang/core` | 字符串转换 |
| `strings` | `@moonbitlang/core` | 字符串操作 |
| `image` | **需实现或简化** | 图像抽象 |
| `image/color` | **需实现或简化** | 颜色模型 |
| `bytes` | `@moonbitlang/core` | 字节缓冲区 |
| `hash/crc32` | **需实现** | CRC32 校验 |
| `encoding/binary` | **需实现** | 二进制编码 |

### 4.3 关键技术点

1. **位图操作**
   - Go: `[]byte` 作为位图，按字节存储
   - MoonBit: 使用 `Array[Byte]` 或 `Bytes`

2. **位操作**
   - Go: `&`, `|`, `^`, `<<`, `>>`, `&^`
   - MoonBit: 完全支持相同的位运算符

3. **错误处理**
   - Go: `error` 接口 + 多返回值
   - MoonBit: `Result[T, E]` 类型

4. **数组切片**
   - Go: 灵活的切片操作 `s[start:end]`
   - MoonBit: 需要使用 `slice()` 方法或索引

## 五、建议的项目结构

```
moonbit-qr/
├── moon.mod.json          # 模块配置
├── README.md
├── docs/
│   ├── prd-000.md         # 原始 PRD
│   ├── feasibility-analysis.md  # 本文档
│   └── algorithm.md       # 算法说明
├── src/
│   ├── gf256/
│   │   ├── moon.pkg.json
│   │   ├── gf256.mbt
│   │   └── gf256_test.mbt
│   ├── coding/
│   │   ├── moon.pkg.json
│   │   ├── types.mbt
│   │   ├── encoding.mbt
│   │   ├── plan.mbt
│   │   ├── tables.mbt
│   │   ├── encode.mbt
│   │   └── coding_test.mbt
│   ├── lib/
│   │   ├── moon.pkg.json
│   │   ├── qr.mbt         # 主 API
│   │   ├── output.mbt     # 输出格式
│   │   └── qr_test.mbt
│   ├── cmd/
│   │   ├── main
│   │   │   ├── main.mbt
│   │   │   └── moon.pkg.json
```


## 六、成功标准

### 6.1 质量标准
- 与 Go 版本结果一致（运行 {workspace}/baseline/compare.sh 逐位对比 go 和 moon 的输出 go_output.txt.tmp moonbit_output.txt.tmp 是否一致）
- 单元测试覆盖率 > 80%
- 通过所有标准测试用例
- 无内存泄漏或错误

### 6.2 文档标准
- 完整的 API 文档
- 至少 3 个使用示例
- 清晰的 README
