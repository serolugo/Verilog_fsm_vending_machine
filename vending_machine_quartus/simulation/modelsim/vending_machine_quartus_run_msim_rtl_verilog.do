transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/DOCUMENTOS/2.-Escuela/5.\ TEC/FPGA/GITHUB/Verilog_fsm_vending_machine/vending_machine_quartus {C:/DOCUMENTOS/2.-Escuela/5. TEC/FPGA/GITHUB/Verilog_fsm_vending_machine/vending_machine_quartus/top_vending_machine.v}
vlog -vlog01compat -work work +incdir+C:/DOCUMENTOS/2.-Escuela/5.\ TEC/FPGA/GITHUB/Verilog_fsm_vending_machine/vending_machine_quartus {C:/DOCUMENTOS/2.-Escuela/5. TEC/FPGA/GITHUB/Verilog_fsm_vending_machine/vending_machine_quartus/fsm.v}
vlog -vlog01compat -work work +incdir+C:/DOCUMENTOS/2.-Escuela/5.\ TEC/FPGA/GITHUB/Verilog_fsm_vending_machine/vending_machine_quartus {C:/DOCUMENTOS/2.-Escuela/5. TEC/FPGA/GITHUB/Verilog_fsm_vending_machine/vending_machine_quartus/bcd_to_7seg.v}

vlog -sv -work work +incdir+C:/DOCUMENTOS/2.-Escuela/5.\ TEC/FPGA/GITHUB/Verilog_fsm_vending_machine/vending_machine_quartus {C:/DOCUMENTOS/2.-Escuela/5. TEC/FPGA/GITHUB/Verilog_fsm_vending_machine/vending_machine_quartus/tb_vending_machine.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  tb_vending_machine

add wave *
view structure
view signals
run -all
