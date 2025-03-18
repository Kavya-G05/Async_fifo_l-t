# Constraints File (constraints.sdc)

# Create clocks for write and read domains
create_clock -name w_clk -period 20 [get_ports w_clk]
create_clock -name r_clk -period 33.33 [get_ports r_clk]

# Set input delays
set_input_delay -clock w_clk 1 [get_ports wdata]
set_input_delay -clock w_clk 1 [get_ports wr_rq]
set_input_delay -clock r_clk 1 [get_ports rd_rq]

# Set output delays
set_output_delay -clock r_clk 2 [get_ports rdata]

# Set false paths between asynchronous clocks
set_false_path -from [get_clocks w_clk] -to [get_clocks r_clk]
set_false_path -from [get_clocks r_clk] -to [get_clocks w_clk]

# Area constraints (optional)
set_max_area 0  ; # No area constraints, optimize as needed
