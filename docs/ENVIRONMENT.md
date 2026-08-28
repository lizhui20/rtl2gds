# 环境与工具清单

## 已确认信息

| 项目 | 当前公开信息 | 核验方式 |
| --- | --- | --- |
| 虚拟化格式 | VMware VMX + OVF + VMDK | 网盘目录文件列表 |
| 虚拟机目录 | `RedHat8.10/` | 网盘目录 |
| 核心磁盘 | `RHEL8_ICA-disk1.vmdk`，约 389 GB / 362 GiB | 网盘文件大小 |
| 配置磁盘容量 | 1 TB | 原始使用说明截图 |
| 内存 | 32 GB | 原始使用说明截图 |
| CPU | 12 vCPU | 原始使用说明截图 |
| 网络 | NAT | 原始使用说明截图 |
| 网络标识 | 原始指南披露了固定 MAC；仓库不复述该值 | 发布前改为每个实例唯一生成 |
| 使用前命令 | `lmg` | 原始使用说明与交互式 shell 别名 |

## 已检测的 EDA 安装

以下信息来自当前虚拟机的安装目录和 `PATH`。表格记录已检测到的产品路径，功能状态需要结合实际设计流程继续验证。

| 工作流 | 产品 | 检测到的发行版本 |
| --- | --- | --- |
| 模拟设计与版图 | Cadence Virtuoso IC | 23.1 |
| SPICE 仿真 | Cadence Spectre | 24.1 |
| 单元表征 | Cadence Liberate | 23.1 |
| RTL 仿真与调试 | Synopsys VCS、Verdi | W-2024.09-SP1 |
| SPICE 仿真 | Synopsys HSPICE | W-2024.09-SP1 |
| 综合与库管理 | Synopsys Design Compiler、Library Compiler | W-2024.09-SP3 |
| 数字实现 | Synopsys Fusion Compiler | W-2024.09-SP3 |
| 等价性与静态验证 | Synopsys Formality、VC Static、SpyGlass | W-2024.09-SP3 / SP2 / SP1 |
| 时序、功耗与提取 | Synopsys PrimeTime、PrimePower RTL、StarRC | W-2024.09；另有 StarRC U-2022.12-SP5-2 |
| DFT | Synopsys TestMAX | W-2024.09-SP1 |
| 物理验证 | Siemens EDA Calibre | 2025.1_16.10 |

当前还检测到 Synopsys RTL Architect、WaveView、CoreTools 和 SCL 2025.03。PDK、库和模型将在完成整理与测试后补充。

## 采集脱敏报告

在虚拟机内执行：

```bash
bash scripts/collect-environment.sh
```

默认输出到当前目录的 `environment-report.txt`。脚本采集：

- 操作系统、内核、CPU、内存和文件系统信息
- VMware 虚拟化标识
- 已知厂商产品的发行目录，以及常见数字、模拟、混合信号 EDA 命令是否位于 `PATH`

发布报告前人工检查以下内容：

- 用户名、主机名、内网地址和挂载路径是否敏感
- `PATH` 是否包含个人目录、客户名或项目代号
- RPM 包名是否泄露不应公开的软件安装信息
- 输出中是否存在序列号、令牌或密钥

工具路径存在不代表端到端流程已经验证。版本清单与实测状态应分别维护。
