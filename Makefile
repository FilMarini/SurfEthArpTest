# Default target
.DEFAULT_GOAL := all

# Export variables
export MODULE=SurfArpTest
export LIBPYTHON_LOC=$(shell cocotb-config --libpython)
export PYTHONPATH=$(abspath $(PWD)/cocotb-test/cocotb)
export COCOTB_RESOLVE_X=ZEROS

%:
	cd ghdl; make -f ghdl.mk $@
