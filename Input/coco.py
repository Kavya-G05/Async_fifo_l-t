import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import random

@cocotb.test()
async def test_fifo(dut):
    """Test Asynchronous FIFO in tt_um_Kavya"""

    # Start clock
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())

    # Reset
    dut.rst_n.value = 0
    dut.wr_rq.value = 0
    dut.rd_rq.value = 0
    dut.wdata.value = 0
    await Timer(50, units="ns")
    dut.rst_n.value = 1
    await Timer(50, units="ns")

    # Write some data into FIFO
    for i in range(8):  
        while dut.full.value == 1:
            await RisingEdge(dut.clk_in)  # Wait if full
        dut.wr_rq.value = 1
        dut.wdata.value = i
        await RisingEdge(dut.clk_in)
        dut.wr_rq.value = 0
        await Timer(10, units="ns")

    # Read data from FIFO
    for _ in range(8):
        while dut.empty.value == 1:
            await RisingEdge(dut.clk_in)  # Wait if empty
        dut.rd_rq.value = 1
        await RisingEdge(dut.clk_in)
        cocotb.log.info(f"Read Data: {dut.rdata.value}")
        dut.rd_rq.value = 0
        await Timer(10, units="ns")

    cocotb.log.info("FIFO test completed successfully.")
