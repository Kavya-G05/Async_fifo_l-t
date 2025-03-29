import os
import cocotb_test.simulator

def test_fifo():
    cocotb_test.simulator.run(
        simulator="icarus",
        verilog_sources=[
            "verilog/clock_divider.v",
            "verilog/empty.v",
            "verilog/fifo_mem.v",
            "verilog/full.v",
            "verilog/sync_r2w.v",
            "verilog/sync_w2r.v",
            "verilog/top.v"
        ],
        toplevel="tt_um_Kavya",
        module="testbench"
    )

if __name__ == "__main__":
    test_fifo()
