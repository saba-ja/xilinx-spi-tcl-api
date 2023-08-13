A TCL API for controlling Xilinx SPI IP.
The tcl procs were written based on SPI register map [axi-quad-spi-reg-map](./axi-quad-spi-reg-map.csv) from Xilinx PG153 AXI Quad SPI Product Guide.

To run the loopback test create a firmware with AXI JTAG, VIP, and QUAD SPI IP is needed.
Set the SPI IP to 0x4000_0000 (if using different address make sure to update the address in the loopback.tcl) then source ./loopback.tcl from the root directory of this repo.
