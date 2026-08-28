# 故障排查

## OVF 导入失败

1. 确认 `RedHat8.10.ovf`、`RedHat8.10.mf` 和 `RHEL8_ICA-disk1.vmdk` 位于同一目录。
2. 确认 VMDK 完整下载，大小约为 389 GB（362 GiB）。
3. 检查宿主机是否至少还有 500 GiB 可用空间。
4. 改为直接打开 `RHEL8_ICA.vmx`。

不要随意编辑 OVF、MF 或 VMDK。修改文件会使清单校验失效，并可能损坏虚拟机。

## VMware 提示虚拟机被移动或复制

对于公开分发的副本，选择 **I copied it** 并让 VMware 生成新的虚拟硬件标识。

## 无法启动或性能很差

- 在 BIOS/UEFI 中启用 Intel VT-x 或 AMD-V。
- 检查宿主机是否有足够内存，避免为虚拟机分配超过宿主机可用量的内存。
- 将 VMDK 放在本地 SSD，避免从移动硬盘、网络盘或同步目录直接运行。
- 检查 Windows Hyper-V/VBS 与 VMware 版本的兼容性。
- 不要把 12 vCPU 全部分配到核心数较少的宿主机上。

## 网络不可用

1. 确认 VMware 网络模式为 NAT，且虚拟网卡已连接。
2. 在虚拟机中执行 `ip address` 和 `ip route`。
3. 若 MAC 冲突，确认同一网络中没有第二个镜像实例。
4. 工具启动失败时，记录错误码和工具版本后查看对应日志。

## `lmg: command not found`

```bash
bash -lic 'alias lmg >/dev/null && echo lmg-ready'
```

`lmg` 是交互式 shell 中的别名，非独立可执行文件。重新登录一次以加载 shell 初始化文件，然后在使用 EDA 工具前运行 `lmg`。不要从不可信来源下载同名脚本。

## 系统显示为 RHEL 8.9

```bash
cat /etc/redhat-release
cat /etc/os-release
```

VMware 文件名中的 `Red Hat Enterprise Linux 8.9 64` 可能只是旧显示名称；以上命令才是判断来宾系统版本的依据。如果输出确为 8.9，说明镜像与仓库名称不一致，应由维护者更正说明或重新发布镜像。

## 登录失败

初始登录信息位于网盘附带的 `虚拟机使用方法.docx`。请在图形登录界面选择镜像已有的默认用户，不要反复尝试未知账号，也不要在 Issue 中公开密码。若维护者已经轮换密码，应以最新 Release 或公告为准。

## 提交问题前

请提供：

- 宿主机操作系统与版本
- VMware 产品与版本
- 导入 OVF 还是打开 VMX
- 完整错误文本或脱敏截图
- `cat /etc/redhat-release`、`free -h`、`df -h` 的脱敏输出

请删除用户名、IP 地址、项目路径、客户名称和设计数据。
