`rtl2gds_small` 是 RTL2GDS 的功能削减版，包含 `be_env` 和 `pr_env`，不代表完整虚拟机环境中展示的全部流程与能力。

虚拟机环境及脚本仅供学习使用，禁止商用。使用声明见 [NOTICE.md](NOTICE.md)；EDA 软件及 PDK 等第三方内容仍受各自许可约束。

环境路径通过以下变量配置：

| 变量 | 默认值或用途 |
| --- | --- |
| `PDK_ROOT` | 当前用户的 `$HOME/PDK` |
| `BE_ROOT` | `pr_env` 同级的 `be_env` |
| `TO_SOC` | BE 查找设计 filelist 和 SDC 的搜索根目录；递归搜索其下的 `<design>.f` 和 `<design>.sdc` |
| `DESIGN_SRC_ROOT` | PR 设计配置搜索目录，默认 `pr_env` 同级的 `DESIGN` |
| `FC_AUTO_EXIT` | 设为 `1` 时批处理运行并退出 EDA 工具 |
| `LC_TOOL` | BE 的 LC 可执行文件绝对路径，可通过环境变量或 make 参数覆盖；`SYNOPSYS_LC_ROOT` 随此路径推导 |
| `ROOT_PATH` | Makefile 工作目录；PR 辅助脚本直接运行时从脚本位置推导 |
| `DEBUG_PATH` | 默认 `be_env` 根目录，额外脚本在其 `scripts` 子目录中查找 |
| `TRACK_SETUP_FILE` | 可选的布线轨道设置脚本；工艺启用该步骤时需配置，现有两种工艺均跳过 |
| `VC_PATH` | `be_env/scripts/vc`，可在其 `blackbox` 子目录放置黑盒脚本 |
| `FM_UNDRIVEN_SIGNALS` | 可选，覆盖等价检查的未驱动信号处理方式；默认 `synthesis` |

PDK 软链接由 `be_env` 的 `make run_prepare_inputs b=<design>` 和 `pr_env` 的
`make link b=<design>` 生成；发布目录不包含指向个人目录的预生成软链接。
EDA 工具路径集中在各自 Makefile 中配置；直接运行辅助 Shell 脚本时，可设置对应工具变量，或将工具加入 PATH。工艺库文件名、工具接口和工具安装路径中的
厂商标识属于功能依赖，仍予保留。

脚本保留范围覆盖两个 Makefile 的全部入口及其依赖，包括 Lint/CDC/RDC、综合、
DFT/ATPG、等价检查、时序分析、布局布线、ECO、签核和 GUI，以及两种可选工艺。

脚本使用按用途命名的小写文件名，单词以下划线分隔。主要入口如下，日常运行仍通过 `gmake <target> b=<design>` 调用：

| 文件 | 用途 |
| --- | --- |
| `be_env/scripts/fc_syn/synthesis_main.tcl` | 逻辑综合入口 |
| `be_env/scripts/pt/timing_main.tcl` | BE 时序分析与模型提取 |
| `be_env/scripts/utilities/input_lists.tcl` | RTL filelist 解析 |
| `pr_env/scripts/utilities/stage_execute.sh` | 布局布线阶段调度 |
| `pr_env/scripts/pnr/layout_context.tcl` | 物理实现公共配置 |
| `pr_env/scripts/signoff/timing_analysis.tcl` | 布局后时序分析 |

运行前需配置 `TO_SOC`，指向存放设计 filelist 的目录或其上级目录，使用绝对路径。`b=your_top` 时，`run_prepare_inputs` 会在该目录及其子目录中按文件名查找 `your_top.f`，并链接到 `be_env/your_top/inputs/your_top.f`。设计的 SDC 也从同一搜索根目录查找；已有有效 SDC 时保留现有输入。

例如，设计源目录可以这样组织：

```text
/path/to/design_sources/
├── filelist/
│   └── your_top.f
├── rtl/
│   └── your_top.v
└── sdc/
    └── your_top.sdc
```

对应设置为 `export TO_SOC=/path/to/design_sources`。这里配置的是搜索目录，不是 `.f` 文件本身；RTL 文件由 `your_top.f` 中的条目指定，不会自动遍历 `rtl/`。例如 filelist 中可写 `/path/to/design_sources/rtl/your_top.v`，建议使用绝对路径。搜索范围内应只保留一份同名 filelist 和 SDC；找到多个同名文件时，脚本会告警，不会自动选择其中一份。

批处理主流程示例（先配置两个环境的 `scripts/pdk/process_select.tcl` 和工具路径）：

```bash
export PDK_ROOT=/path/to/pdk
export TO_SOC=/path/to/design_sources
export DESIGN_SRC_ROOT="$TO_SOC"
export FC_AUTO_EXIT=1
design=your_top
gmake -C be_env run_fc_syn b="$design"
gmake -C be_env run_fm b="$design"
gmake -C be_env run_fm_dft run_atpg b="$design"
gmake -C pr_env pnr_all b="$design"
gmake -C pr_env signoff_all b="$design"
```

将 `your_top` 替换为顶层模块名。`run_fm_dft` 包含扫描链插入。
Lint、CDC、RDC、GCA 和时序模型分别使用 BE 的 `run_vc_lint`、`run_vc_cdc`、
`run_vc_rdc`、`run_gca`、`run_pt` 入口，需要相应工具及许可证。
BE 的 FC 寄生文件由 PDK 配置中的 `PDK_FC_PARASITIC_FILE` 指定；`run_prepare_inputs` 创建对应的 `tech` 软链接，FC 检查并读取该链接。N28 使用 `cworst_T.nxtgrd`（运行目录链接名为 `tsmcn28_9lm_cworst.nxtgrd`），SMIC18 保留其已有的 typical TLUPlus 配置。
BE 综合可选读取 `inputs/<design>.def.gz` 或 `inputs/<design>.def`；未提供时使用当前 PDK 的自动 floorplan 配置。
`run_pt` 执行 PrimeTime 和 Library Compiler，生成 `.lib` 与 `.db`。
需要 NDM 时，再单独运行 `gmake -C be_env run_gen_ndm b="$design"`，读取已有 DB 生成 NDM。
BE 默认使用原来的 LC W-2024.09-SP3。本机该版本存在写库后退出崩溃，
流程仅在本次写库完成、DB 非空、写库阶段日志无错误且退出码为 139 时接受该次写库结果；
会明确提示并保留完整崩溃日志。运行前删除旧 DB，避免误用上次结果。
其他安装环境可用
`gmake -C be_env run_pt b="$design" LC_TOOL=/path/to/lc/bin/lc_shell`
指定 LC 版本。其他退出异常和读写库错误仍会使 `run_pt` 失败；NDM 检查错误使 `run_gen_ndm` 失败。
PR 默认 `SIGNOFF_REQUIRE_CLEAN=1`，时序路径或电气约束存在违例时签核失败。
N28 DRC 默认使用 block 模式及脚本中现有的提示/库内结果分类，不等同于原始结果为零。
设计的 `<design>.pr_user_setting.tcl` 可配置 `FLOORPLAN_CORE_OFFSET` 和
`PG_RING_OFFSET`，默认分别为 `{2 2}`、`{0.4 0.4}`；缩小 core 留边时需同时保证电源环位于设计边界内。

精简版不提供按 SRAM 型号和目录命名自动推导宏单元库的功能，也不读取 `_model.f`。使用宏单元时需在工艺/设计配置中显式提供相应库视图。
