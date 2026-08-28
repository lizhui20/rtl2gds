# 快速开始

## 1. 宿主机准备

当前镜像由 VMware 文件组成，并提供 OVF 描述文件。建议准备：

| 项目 | 建议值 |
| --- | --- |
| 虚拟化软件 | 支持 OVF/VMX 的 VMware Workstation、Player 或 Fusion |
| 可用磁盘 | 至少 500 GiB；后续项目数据需要额外空间 |
| 内存 | 镜像原始配置 32 GB；宿主机建议高于此值 |
| CPU | 镜像原始配置 12 vCPU；宿主机需启用 Intel VT-x 或 AMD-V |
| 网络 | NAT |

在 BIOS/UEFI 中启用硬件虚拟化。Windows 宿主机若同时启用 Hyper-V、VBS 或其他虚拟化平台，VMware 性能可能受影响。

## 2. 下载与完整性检查

1. 打开[百度网盘分享](https://pan.baidu.com/s/1-8x7LnedM-ATdbUHXocRAw?pwd=hs1t)，提取码为 `hs1t`。
2. 使用百度网盘客户端下载完整的 `RedHat8.10/` 目录和 `虚拟机使用方法.docx`。
3. 确认 `RHEL8_ICA-disk1.vmdk` 下载完成，显示大小约 389 GB（362 GiB）。
4. 保持 OVF、VMX、VMDK、NVRAM 和清单文件位于同一目录，不要单独改名。

当前仓库尚未发布由维护者签名的 SHA-256 清单。校验清单发布前，不应信任第三方转载的镜像。

## 3. 导入虚拟机

### 方式 A：导入 OVF

在 VMware 中选择 **Open a Virtual Machine** 或 **Import**，打开 `RedHat8.10.ovf`，选择存储位置后等待导入完成。

### 方式 B：直接打开 VMX

若 OVF 导入失败，选择 **Open a Virtual Machine** 并打开 `RHEL8_ICA.vmx`。VMware 询问虚拟机是移动还是复制时，优先选择 **I moved it**，以保留已有虚拟硬件标识。

## 4. 核对虚拟硬件

在虚拟机关机状态下打开设置，核对：

- 内存：32 GB
- 处理器：12 vCPU
- 虚拟磁盘：1 TB
- 网络模式：NAT
- 网卡 MAC：由 VMware 为每个实例唯一生成

MAC 地址设置路径通常为 **Virtual Machine Settings > Network Adapter > Advanced**。原始分享指南披露了一个固定 MAC，但仓库不复述该值；建议让 VMware 为每个实例生成唯一地址。

## 5. 首次启动

1. 启动虚拟机并选择默认用户。
2. 按网盘附带 `虚拟机使用方法.docx` 中的初始信息登录；不要在公开 Issue 中转发密码。
3. 在桌面空白处右键，可通过 **Display Settings** 调整分辨率。
4. 打开终端，执行：

   ```bash
   lmg
   ```

5. 保持该终端运行，再打开一个新终端。
6. 根据工作流分别启动 Virtuoso、VCS、Design Compiler、Fusion Compiler、Calibre 等工具。

登录后立即用 `passwd` 修改公开默认密码。若需要联网，先确认系统中不存在维护者的 SSH 私钥、访问令牌、浏览器会话或个人文件。

## 6. 版本与资源核验

```bash
cat /etc/redhat-release
uname -r
lscpu | sed -n '1,20p'
free -h
df -h
bash -lic 'alias lmg >/dev/null && echo lmg-ready'
```

最后一条命令输出 `lmg-ready` 即表示启动命令已经加载。也可运行仓库中的 `scripts/collect-environment.sh` 生成脱敏环境报告。若系统版本不是 8.10，或 `lmg` 不存在，请按[故障排查](TROUBLESHOOTING.md)收集信息并提交 Issue。
