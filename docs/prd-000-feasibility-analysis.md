# rsc.io/qr 移植到 MoonBit 可行性分析与执行计划

## 一、项目概述

**源项目**: `rsc.io/qr` v0.2.0  
**目标**: 完整移植到 MoonBit  
**源代码位置**: `C:\Users\C2\go\pkg\mod\rsc.io\qr@v0.2.0`  
**总代码量**: 约 2355 行 Go 代码  
**授权协议**: BSD-3-Clause (Go Authors)

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

## 五、可行性评估

### 5.1 技术可行性：✅ 高度可行

**优势**:
1. **算法纯粹**: 主要是数学和位操作，无复杂 I/O
2. **无 unsafe**: 原代码基本无 unsafe 操作（除 libqrencode）
3. **无并发**: 无 goroutine、channel 等并发原语
4. **无 CGO**: 核心代码不依赖 C（libqrencode 仅测试用）
5. **逻辑清晰**: 代码结构良好，职责分明

**挑战**:
1. **PNG 编码复杂**: 需要实现 DEFLATE 或寻找替代方案
2. **大型常量表**: 需要手动移植版本参数表
3. **位操作密集**: 需要仔细验证位运算逻辑
4. **测试数据**: 需要准备完整的测试用例

### 5.2 工作量估算

| 模块 | 预估工作量 | 优先级 |
|------|-----------|--------|
| gf256 包 | 2-3 天 | P0（基础） |
| coding 包（核心编码） | 5-7 天 | P0（核心） |
| qr 包（API 层） | 1-2 天 | P0（必需） |
| PNG 简化输出 | 2-3 天 | P1（可选） |
| 完整 PNG 编码 | 5-8 天 | P2（优化） |
| 测试套件 | 3-5 天 | P0（必需） |
| 文档与示例 | 2 天 | P1（重要） |

**总计**: 20-30 工作日（完整实现）  
**MVP 版本**: 10-15 工作日（核心功能 + 简单输出）

## 六、执行计划

### 阶段 0: 准备工作（1 天）

**任务**:
- [ ] 创建 MoonBit 项目结构
- [ ] 设置 `moon.mod.json` 和包配置
- [ ] 准备测试数据和参考 QR 码
- [ ] 确定输出格式（先文本/数组，后 PNG）

**交付物**:
- 项目骨架
- 测试数据集

### 阶段 1: gf256 包实现（2-3 天）

**任务**:
- [ ] 实现 `Field` 结构和初始化
- [ ] 实现域运算：Add, Mul, Inv, Exp, Log
- [ ] 实现 `RSEncoder` 和 `ECC` 方法
- [ ] 移植单元测试
- [ ] 验证与 Go 版本结果一致

**交付物**:
- `src/gf256/gf256.mbt`
- `src/gf256/gf256_test.mbt`
- 通过所有单元测试

**关键验证**:
```moonbit
// 测试示例
let f = Field::new(0x11d, 2)
assert!(f.mul(3, 7) == f.exp(f.log(3) + f.log(7)))
```

### 阶段 2: coding 包 - 基础结构（2 天）

**任务**:
- [ ] 定义类型：Version, Level, Pixel, PixelRole
- [ ] 实现 `Bits` 结构（位缓冲区）
- [ ] 实现编码接口：Num, Alpha, String
- [ ] 移植版本表 `vtab`
- [ ] 单元测试编码器

**交付物**:
- `src/coding/types.mbt`
- `src/coding/encoding.mbt`
- `src/coding/tables.mbt`
- 编码器测试通过

### 阶段 3: coding 包 - 布局生成（3 天）

**任务**:
- [ ] 实现 `grid()` 和像素网格
- [ ] 实现 `vplan()` - 版本布局
- [ ] 实现 `posBox()`, `alignBox()` - 图案绘制
- [ ] 实现 `fplan()` - 格式信息
- [ ] 实现 `lplan()` - 纠错分配
- [ ] 实现 `mplan()` - 掩码应用

**交付物**:
- `src/coding/plan.mbt`
- 布局测试通过

### 阶段 4: coding 包 - 编码流程（2 天）

**任务**:
- [ ] 实现 `NewPlan()`
- [ ] 实现 `Bits::Pad()` 和 `AddCheckBytes()`
- [ ] 实现 `Plan::Encode()`
- [ ] 集成测试

**交付物**:
- `src/coding/encode.mbt`
- 完整编码流程测试

### 阶段 5: qr 包 - 公共 API（2 天）

**任务**:
- [ ] 实现 `Code` 结构
- [ ] 实现 `Encode()` 函数
- [ ] 实现 `Black()` 方法
- [ ] 实现简单的文本输出（ASCII art）
- [ ] 端到端测试

**交付物**:
- `src/qr.mbt`
- `src/qr_test.mbt`
- 可生成 QR 码的 CLI 工具

**里程碑**: 🎯 **MVP 完成** - 可生成正确的 QR 码位图

### 阶段 6: 输出格式（3-5 天，可选）

**方案 A: 简化输出（3 天）**
- [ ] 实现 SVG 输出（XML 格式，简单）
- [ ] 实现文本输出（ASCII/Unicode）
- [ ] 实现原始位图输出（二进制）

**方案 B: 完整 PNG（5 天）**
- [ ] 实现 PNG 文件结构
- [ ] 实现 CRC32 校验
- [ ] 实现简化的 DEFLATE（或调用库）
- [ ] 实现 Adler-32 校验

**推荐**: 先实现方案 A（SVG 最实用），需要时再做方案 B

### 阶段 7: 测试与验证（3 天）

**任务**:
- [ ] 准备标准测试用例（参考 Go 版本）
- [ ] 对比测试：与 Go 版本逐字节对比
- [ ] 边界测试：各版本、纠错级别组合
- [ ] 模糊测试：随机输入
- [ ] 性能测试与优化

**交付物**:
- 完整测试套件
- 测试报告
- 性能对比

### 阶段 8: 文档与示例（2 天）

**任务**:
- [ ] API 文档（MoonDoc）
- [ ] 使用示例
- [ ] README（中英文）
- [ ] 技术文档（算法说明）

**交付物**:
- `README.md`
- `docs/api.md`
- `examples/` 目录

## 七、风险与应对

### 7.1 技术风险

| 风险 | 影响 | 概率 | 应对措施 |
|------|------|------|----------|
| MoonBit 位操作差异 | 高 | 低 | 早期验证，编写测试对比 |
| 大数组性能问题 | 中 | 中 | 性能测试，必要时优化 |
| PNG 编码过于复杂 | 中 | 高 | 优先 SVG，PNG 为可选 |
| 浮点精度问题 | 低 | 低 | 纯整数算法，无浮点 |

### 7.2 资源风险

| 风险 | 应对 |
|------|------|
| 缺少 MoonBit 图像库 | 自实现简化版或纯文本输出 |
| 缺少 DEFLATE 库 | 使用未压缩 PNG 或 SVG |
| 测试数据不足 | 从 Go 版本生成参考数据 |

## 八、成功标准

### 8.1 功能标准
- ✅ 支持 QR 码版本 1-40
- ✅ 支持 4 个纠错级别（L/M/Q/H）
- ✅ 支持 3 种编码模式（Numeric/Alpha/Byte）
- ✅ 生成正确的 QR 码（可被扫描器识别）
- ✅ 至少一种输出格式（文本/SVG/PNG）

### 8.2 质量标准
- ✅ 与 Go 版本结果一致（逐位对比）
- ✅ 单元测试覆盖率 > 80%
- ✅ 通过所有标准测试用例
- ✅ 无内存泄漏或错误

### 8.3 文档标准
- ✅ 完整的 API 文档
- ✅ 至少 3 个使用示例
- ✅ 清晰的 README

## 九、建议的项目结构

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
│   └── bin/
│       ├── moon.pkg.json
│       └── main.mbt       # CLI 工具
├── examples/
│   └── basic.mbt
└── test/
    └── testdata/          # 测试数据
```

## 十、结论

**总体评估**: ✅ **高度可行**

这个项目具有很高的可行性：
1. **技术栈匹配**: Go 和 MoonBit 语言特性相近，核心算法可直接移植
2. **依赖简单**: 无复杂外部依赖，主要是纯算法
3. **结构清晰**: 原代码组织良好，便于理解和移植
4. **价值明确**: QR 码是常用功能，移植后有实用价值

**关键成功因素**:
1. 按阶段渐进实施，先 MVP 后优化
2. 充分的测试验证，确保正确性
3. 灵活选择输出格式，避免过早优化
4. 保持与原项目的算法一致性

**开始建议**:
1. 从 gf256 包开始（基础且独立）
2. 并行准备测试数据集
3. 优先文本/SVG 输出，PNG 为后续目标
4. 边实现边测试，确保每个模块正确

**预期时间线**: 2-4 周完成核心功能，4-6 周完成所有功能和文档。
