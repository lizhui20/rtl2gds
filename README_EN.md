# IC Design Virtual Machine Environment and RTL2GDS

A preconfigured Red Hat Enterprise Linux 8.10 VMware environment for digital, analog, and mixed-signal IC design. The repository provides the image download location, import instructions, environment inventory tooling, troubleshooting notes, and a record of the RTL2GDS flow implemented in the VM.

## Reduced-Function Scripts and Usage Notice

The repository includes [rtl2gds_small](rtl2gds_small/README.md), a reduced-function script package containing `be_env` and `pr_env`. It does not include all capabilities demonstrated in the full VM environment below, test designs, generated outputs, EDA software, or PDKs.

**The entire virtual machine environment and scripts are for learning purposes only. Commercial use is prohibited.** Project-owned scripts, configuration, and documentation that the licensors have authority to license are subject to [LICENSE](LICENSE); see [NOTICE.md](NOTICE.md) for a summary. Third-party materials retain their own licenses. The Chinese license text is authoritative.

## Download

Download from [Baidu Netdisk](https://pan.baidu.com/s/1wqB7OsjWHtzFlZPJBeHAaQ?pwd=ekdi) with extraction code `ekdi`.

The shared package currently contains the `RedHat8.10/` VM directory and a Chinese usage guide. The main `RHEL8_ICA-disk1.vmdk` file is about **389 GB (362 GiB)**. Use the Netdisk client for a complete download and reserve at least **500 GiB** of free host storage. The virtual disk is provisioned as 1 TB.

## Start The VM

1. Install a VMware product that can import OVF or open VMX files.
2. Download the complete `RedHat8.10/` directory without renaming or moving individual files.
3. Import `RedHat8.10.ovf`. If import fails, open `RHEL8_ICA.vmx` directly.
4. The source configuration uses 32 GB RAM, 12 vCPUs, a 1 TB virtual disk, and NAT networking.
5. Let VMware generate a unique MAC address for the new instance instead of reusing the fixed value in the shared guide.
6. Start the VM and select its default user. Initial login details are in the bundled Chinese guide; change the password immediately after login.
7. Before use, open a terminal and run `lmg`.

The bundled guide discloses a default password and fixed MAC. The maintainer should rotate the password and republish a sanitized image. Until then, boot only on NAT or an isolated network and do not reuse the guide's MAC value.

## RTL2GDS Flow

The current example is **`io_port` in TSMC 28HPC+ (N28)**. A serial interface controls GPIO and a 4 KiB register buffer. The project covers RTL simulation, synthesis, DFT, place and route, GDS export, and physical verification.

### Final Layout

![Complete io_port layout](docs/images/rtl2gds/io_port_layout_user_2026-11-15.png)

[View original image](docs/images/rtl2gds/io_port_layout_user_2026-11-15.png)

The **838×838 µm** die uses 7-track standard cells and a 9M 4X2Y2R metal stack, with **25 signal IOs, 14 supply/ground IOs and 39 bond pads**. The 4 KiB buffer is built from standard cells; the scan chain contains 32,934 bits.

FC routing and power connectivity checks pass, Formality equivalence passes, and Calibre prefill/postfill LVS comparisons are `CORRECT`. Remaining DRC/ERC items are recorded for waiver; see the [project details](docs/RTL2GDS.md#验证结果).

[Project and commands](docs/RTL2GDS.md) · [Flow screenshots](docs/RTL2GDS_ARCHIVE_2026-09-04.md) · [Earlier SPI project](docs/RTL2GDS_SPI_2026-09.md)

## Verify The Environment

Some legacy VMware filenames mention Red Hat Enterprise Linux 8.9. Verify the guest version instead of relying on the VM display name:

```bash
cat /etc/redhat-release
cat /etc/os-release
```

To collect a reviewable environment inventory:

```bash
git clone https://github.com/lizhui20/rtl2gds.git
cd rtl2gds
bash scripts/collect-environment.sh
```

See the [Chinese quick-start guide](docs/QUICKSTART.md), [environment inventory](docs/ENVIRONMENT.md), and [troubleshooting guide](docs/TROUBLESHOOTING.md) for details.

The current VM has installation trees for Cadence IC 23.1, Spectre 24.1, Liberate 23.1; multiple Synopsys W-2024.09 products including VCS, Verdi, HSPICE, Design Compiler, Formality, Fusion Compiler, PrimeTime, SpyGlass, TestMAX, StarRC, and VC Static; and Siemens Calibre 2025.1. Product paths have been detected; workflow validation is tracked separately.
