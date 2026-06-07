- go 代码用 go test 测试，使用 独立的 _test.go 文件，一个包内不要出现多个 main 函数

- mbt 代码使用 moon test 测试，使用 独立的 _test.mbt 文件


- 对比 go 代码实现，需要同步移植 原有的 go test 代码，然后实现对应的 moonbit test 代码，确保测试通过（测试代码安装 go 的逻辑使用 moonbit 的语法，同时使用 go 的输出校验）

