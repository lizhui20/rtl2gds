# IC Design Virtual Machine Environment and RTL2GDS

A preconfigured Red Hat Enterprise Linux 8.10 VMware environment for digital, analog, and mixed-signal IC design. The repository provides the image download location, import instructions, environment inventory tooling, troubleshooting notes, and a record of the RTL2GDS flow implemented in the VM.

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

An RTL2GDS flow has been implemented in this VM and demonstrated with the `smic18mmrf` process. The `spi_slave` example covers logic implementation, DFT/ATPG, place and route, formal verification, parasitic extraction, PrimeTime static timing analysis, RedHawk static IR-drop analysis, Calibre DRC/antenna/LVS, post-layout ATPG, and GDS inspection. The captures show **99.91% stuck-at fault test coverage**, **230 passing formal compare points with no failures**, and no negative-slack endpoints in the eight PrimeTime endpoint groups shown.

The record also preserves open review items instead of describing the run as universally signoff-clean: ATPG reports an `N23` warning, Calibre DRC shows three warnings that require classification or waiver, and the lowest visible RedHawk power node is about 0.7929 V and must be judged against the project's IR-drop limit.

The record also presents the schematic and layout of a **14-bit, 10 MS/s TI SAR ADC** implemented with `smic18mmrf`; the design completed post-layout simulation and the Cadence signoff flow.

[View the latest complete RTL2GDS flow record online](docs/RTL2GDS.md) · [Download the initial DOCX archive](docs/RTL2GDS.docx)

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
