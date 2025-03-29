TOPLEVEL_LANG = verilog
SIM = icarus

# List all Verilog source files explicitly
VERILOG_SOURCES = verilog/clock_divider.v \
                  verilog/empty.v \
                  verilog/fifo_mem.v \
                  verilog/full.v \
                  verilog/sync_r2w.v \
                  verilog/sync_w2r.v \
                  verilog/top.v  # Ensure this contains `tt_um_Kavya`

TOPLEVEL = tt_um_Kavya  # Change this if your module has a different name
MODULE = testbench

SIM_ARGS = -g2005-sv
include $(shell cocotb-config --makefiles)/Makefile.sim
