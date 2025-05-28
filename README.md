# I2C-master
This project implements a I2C Master controller written in Verilog. It supports multi-byte write operations with proper START, STOP, and ACK handling. The core is controlled via a finite state machine (FSM) and designed for FPGA deployment and simulation environments.
The module is fully valified and simulation with M24LC04B EEPROM 

# Features
- Fully synchronous FSM-based I2C master
- Supports standard I2C protocol timing and acknowledgment
- Handles burst write with internal `length` counter
- SDA open-drain simulation with bidirectional handling
- Separate modules for clean testbench structure

# Folder Structure
i2c_master_fsm/
- src/ # Verilog source files (i2c_master.v)
- tb/ # Testbench files
- sim/ # Simulation outputs (e.g., .vcd, .fst)
- doc/ # Block diagrams, timing diagrams
- run.tcl # Script to compile and simulate
- README.md
