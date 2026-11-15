# RTL2GDS 各阶段截图

这组截图展示综合、DFT、布局布线、形式验证、时序分析和物理验证的工具界面。本页已用最新 `io_port` 带 IO pad 的 N28 版图替换旧 SMIC18 展示；其余工具界面保留为历史截图，不表示新项目通过相同检查。最新状态见 [RTL2GDS 全流程](RTL2GDS.md)。

## 综合 QoR

![Fusion Compiler 综合 QoR](images/rtl2gds/image1.png)

## DFT / ATPG

![TestMAX ATPG 结果界面](images/rtl2gds/image2.png)

## 前端交付物

![综合、DFT 与 ATPG 产物](images/rtl2gds/image3.png)

## 布局布线交付物

![布局布线产物](images/rtl2gds/image6.png)

## Formality 等价验证

![Formality 等价检查](images/rtl2gds/image4.png)

## 签核产物

![签核结果目录](images/rtl2gds/image7.png)

## 最新 GDS 视图：io_port / TSMC N28（2026-11-14）

![io_port 最终签核 GDS 完整层视图，含 dummy fill](images/rtl2gds/io_port_postfill_overview_2026-11-14.png)

838×838 µm，25 个信号 IO、14 个电源/地 IO、39 个 bond pad。图像由 Calibre DESIGNrev 从签核输入 `results/signoff/io_port.pnr.dummy.gds` 原生导出，显示全部图层及 dummy fill。

## IO pad / bond pad 视图

![同一最终 GDS 的焊盘及开口层视图](images/rtl2gds/io_port_postfill_pads_2026-11-14.png)

该图选择 AP、CB、CB2W 和 M7 标签层，展示焊盘位置；完整层图及当前验证状态见 [项目记录](RTL2GDS.md)。

## PrimeTime 分析界面

![PrimeTime 报告生成](images/rtl2gds/image5.png)

![PrimeTime endpoint 汇总](images/rtl2gds/pt_gui.png)

## RedHawk IR 视图

![RedHawk 结果与节点列表](images/rtl2gds/redhawk_gui.png)

## Calibre RVE

![Calibre DRC 结果界面](images/rtl2gds/drc_rve.png)

![Calibre LVS 比较结果](images/rtl2gds/image10.png)

本页其余阶段截图整理于 2026-09-04。历史 SPI 十二场景、ATPG 和 IR 数值见 [SPI 记录](RTL2GDS_SPI_2026-09.md)；原始图文保留在 [DOCX 历史存档](RTL2GDS.docx)，不作为当前项目状态依据。
