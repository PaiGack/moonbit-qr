- go 代码用 go test 测试，使用 独立的 _test.go 文件，一个包内不要出现多个 main 函数

- mbt 代码使用 moon test 测试，使用 独立的 _test.mbt 文件


- 对比 go 代码实现，需要同步移植 原有的 go test 代码，然后实现对应的 moonbit test 代码，确保测试通过（测试代码安装 go 的逻辑使用 moonbit 的语法，同时使用 go 的输出校验）

---

# QR Code实现修复记录

## 已修复的关键问题

### 1. Bits::append位顺序错误 ✅
**位置:** `src/coding/types.mbt:57-78`
- **问题:** 从低位开始取位，应该从高位开始
- **影响:** 导致所有编码数据完全错误
- **修复:** 改为 `(val >> shift) & mask` 从高位提取

### 2. String.to_bytes() UTF-16编码问题 ✅
**位置:** `src/coding/encode.mbt:133-157`
- **问题:** MoonBit的to_bytes()返回UTF-16（每字符2字节）
- **影响:** "HELLO WORLD"被编码为22字节而不是11字节
- **修复:** 手动提取ASCII字符码

### 3. 编码模式不匹配 ✅
**位置:** `src/coding/encode.mbt:20-46`
- **问题:** MoonBit强制使用Byte模式，Go自动选择最优模式（Alphanumeric）
- **影响:** 编码格式不同
- **修复:** 实现正确的detect_mode函数，自动检测Numeric/Alphanumeric/Byte模式

### 4. is_function_pattern边界错误 ✅
**位置:** `src/coding/layout.mbt:234-254`
- **问题:** `x >= size - 9`应该是`x >= size - 8`
- **影响:** (12,0)等数据区域被错误识别为function pattern，导致数据未写入
- **修复:** 修改为`x >= size - 8`

### 5. encode_data缺少padding ✅
**位置:** `src/coding/encode.mbt:4-16`
- **问题:** encode_data没有padding到target capacity
- **影响:** 只有13字节数据，应该是19字节（Version 1 Level L）
- **结果:** 总共20字节而不是26字节（19数据+7 EC）
- **修复:** 在encode函数中调用pad_bits

### 6. Mask Pattern选择 ✅
**位置:** `src/lib/qr.mbt:38-42`
- **问题:** Go的rsc.io/qr库使用固定的mask 0（未实现penalty-based选择）
- **当前实现:** 为了匹配Go的行为，使用固定mask 0
- **修复:** 使用固定mask 0，并实现了完整的penalty_score函数（包含所有4条规则）以备将来使用

## 测试状态

- **通过:** 15/15测试 ✅
- **所有测试通过!**

## 实现说明

### Mask选择策略
虽然实现了完整的penalty_score函数（包含Rule 1-4），但为了与Go的rsc.io/qr库保持兼容，当前使用固定的mask 0。Go库在qr.go第66行有TODO注释说明未实现mask选择。

如果将来需要启用动态mask选择，可以取消注释`choose_best_mask`函数的调用。

### 编码模式自动检测
实现了完整的模式检测：
- **Numeric模式:** 仅包含数字0-9
- **Alphanumeric模式:** 包含0-9A-Z和特殊字符（空格、$、%、*、+、-、.、/、:）
- **Byte模式:** 其他所有字符

对于"HELLO WORLD"，自动选择Alphanumeric模式，与Go的qr.Encode行为一致。

## 关键数据验证

Version 1 Level L "HELLO WORLD" (Alphanumeric模式):
- 编码后数据: 13字节（padding到19字节）
- Error correction: 7字节  
- 总计: 26字节
- Row 0 (mask 0): `111111100010101111111` ✅
