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
**位置:** `src/coding/encode.mbt:19-23`
- **问题:** MoonBit使用Alphanumeric模式，Go使用Byte模式
- **影响:** 编码格式完全不同
- **修复:** 强制使用Byte模式以匹配Go

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

## 剩余问题

### 1. Mask Pattern选择不正确 ❌
**状态:** 未修复
- **问题:** penalty_score计算不正确，导致选择了错误的mask
- **当前情况:**
  - Go选择mask并生成row 0: `111111100010101111111`
  - MoonBit当前选择的mask生成row 0: `111111101111101111111`
  - 如果强制使用mask 3，可以通过所有测试
- **下一步:** 需要修复penalty_score的四个评分规则实现

## 测试状态

- **通过:** 16/17测试
- **失败:** 1个测试（row 0 after full encode: HELLO WORLD）
- **原因:** mask选择错误

## 临时解决方案

可以临时在`src/lib/qr.mbt:38`强制使用mask 3：
```moonbit
let best_mask = 3  // 临时：强制使用mask 3
```

这样可以通过所有测试，但不是正确的解决方案。

## Go基准输出

```
=== Go QR Code Generator (Reference) ===
Generating QR code for: 'HELLO WORLD'
Size: 21x21
Row 0: 111111100010101111111
```

## 关键数据验证

Version 1 Level L "HELLO WORLD":
- 编码后数据: 19字节
- Error correction: 7字节  
- 总计: 26字节
- byte[17] = 0xEC = 11101100 (bit 6 = 1) ✅
