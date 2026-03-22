import cocotb
import pytest
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb_tools.runner import get_runner


@pytest.fixture
def runner():
    return get_runner("verilator")


@pytest.mark.parametrize("div", [8, 16, 32])
def test_clk_div(runner, div):
    MODULE_NAME = "i2c_clk_div"
    params = {"DIV": div}
    runner.build(
        sources=[f"rtl/{MODULE_NAME}.sv"],
        hdl_toplevel=MODULE_NAME,
        parameters=params,
        waves=True,
    )

    runner.test(
        hdl_toplevel=MODULE_NAME,
        test_module=f"test_{MODULE_NAME}_smoke",
        test_dir="waves",
        test_args=["--trace-file", f"{MODULE_NAME}_{div}.vcd"],
        waves=True,
    )


@cocotb.test()
async def test_reset(dut):
    """rst_n=0, o_scl should be low"""
    dut._log.info("Starting Reset Test")
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst_n.value = 0
    dut.i_en.value = 0
    for _ in range(5):
        await RisingEdge(dut.clk)
        assert dut.o_scl.value == 0, "o_scl should be low when rst_n is 0"
    sample = []
    dut.rst_n.value = 1
    dut.i_en.value = 1
    for _ in range(50):
        await RisingEdge(dut.clk)
        sample.append(int(dut.o_scl.value))
    assert any(sample), "o_scl should toggle when rst_n is 1 and i_en is 1"


@cocotb.test()
async def test_enable(dut):
    """i_en test"""
    dut._log.info("Starting Enable Test")
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst_n.value = 0
    dut.i_en.value = 0
    for _ in range(5):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    for _ in range(20):
        await RisingEdge(dut.clk)
        assert dut.o_scl.value == 0, "o_scl should be low when i_en is 0"
    dut.i_en.value = 1
    sample = []
    for _ in range(50):
        await RisingEdge(dut.clk)
        sample.append(int(dut.o_scl.value))
    assert any(sample), "o_scl should toggle when i_en is 1"


@cocotb.test()
async def test_period_and_duty(dut):
    """cycle = DIV, duty = 50%"""
    dut._log.info("Starting Period and Duty Cycle Test")
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst_n.value = 0
    dut.i_en.value = 0
    div = int(dut.DIV.value)
    cycle = 10
    for _ in range(5):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    dut.i_en.value = 1
    # Skip first period for settling
    for _ in range(div):
        await RisingEdge(dut.clk)
    sample = []
    for _ in range(div * cycle):
        await RisingEdge(dut.clk)
        sample.append(int(dut.o_scl.value))
    high_count = sum(sample)
    low_count = len(sample) - high_count
    assert high_count == low_count, (
        f"High count {high_count} should equal low count {low_count} for 50% duty cycle"
    )
