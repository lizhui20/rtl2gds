# RTL2GDS 各阶段截图

当前 `io_port` 版图和早期项目的工具界面。项目参数与运行方法见 [RTL2GDS](RTL2GDS.md)。除版图外，其余截图为早期流程记录。

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

![io_port 完整版图](images/rtl2gds/io_port_layout_user_2026-11-15.png)

[查看原图](images/rtl2gds/io_port_layout_user_2026-11-15.png)

838×838 µm，25 个信号 IO、14 个电源/地 IO、39 个 bond pad。

## IO pad / bond pad 视图

![同一最终 GDS 的焊盘及开口层视图](images/rtl2gds/io_port_full_pads_3200_2026-11-14.png)

单独显示焊盘金属和开口，便于查看四边 pad 的分布。

## PrimeTime 分析界面

![PrimeTime 报告生成](images/rtl2gds/image5.png)

![PrimeTime endpoint 汇总](images/rtl2gds/pt_gui.png)

## RedHawk IR 视图

![RedHawk 结果与节点列表](images/rtl2gds/redhawk_gui.png)

## Calibre RVE

![Calibre DRC 结果界面](images/rtl2gds/drc_rve.png)

![Calibre LVS 比较结果](images/rtl2gds/image10.png)

更多内容：[SPI 项目记录](RTL2GDS_SPI_2026-09.md) · [早期 DOCX](RTL2GDS.docx)。
