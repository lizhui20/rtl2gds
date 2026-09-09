DFT 流程包含扫描链插入和 ATPG 两个步骤。

| 步骤 | 工具 | 脚本 | 主要输出 |
| --- | --- | --- | --- |
| 扫描链插入 | DFT Compiler (`dcnxt_shell`) | `scan_insert.tcl` | `<DESIGN>.scan.v`、`<DESIGN>.spf`、`<DESIGN>.scandef` |
| ATPG | TestMAX (`tmax`) | `pattern_generate.tcl` | 测试向量和覆盖率报告 |

运行前准备综合输出 `results/<DESIGN>.mapped.v`，并在
`scripts/pdk/process_select.tcl` 选择工艺。逻辑库、单元 Verilog 模型及库搜索路径
由工艺配置提供；时钟、复位、扫描端口和链数在
`scripts/utilities/design_defaults.tcl` 或设计的用户配置中设置。
`scan_options.tcl` 汇总 DFT 配置。

在 `be_env` 目录执行：

```sh
gmake run_dft_insert b=<DESIGN>
gmake run_atpg b=<DESIGN>
```

也可执行 `gmake run_testmax_dft b=<DESIGN>`，依次完成两个步骤。
结果、报告和日志分别位于 `<DESIGN>/results`、`<DESIGN>/reports/dft`
和 `<DESIGN>/logs`。
