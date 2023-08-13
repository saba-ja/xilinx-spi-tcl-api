
# ------------------------------------------------------------------------------
# AXI JTAG read and write
# Original code from D. Hawkins
# Adapted by S. Janamian
# ------------------------------------------------------------------------------

proc axi_write {addr wrdata} {

	set axi_hw [get_hw_axis]

	# Reset the interface
	reset_hw_axi $axi_hw

	# 32-bit aligned address
	set addr [format "0x%.8X" [expr {$addr & ~3}]]

	# Ensure the write data is 32-bits
	set wrdata [format "0x%.8X" $wrdata]

	# Create the write transaction
	create_hw_axi_txn axi_write $axi_hw -type WRITE \
		-address $addr -data $wrdata -len 1 -force -quiet

	# Run the transaction
	run_hw_axi [get_hw_axi_txns axi_write] -quiet

	# Delete the transaction
	delete_hw_axi_txn axi_write
	return
}

proc axi_read {addr} {

	set axi_hw [get_hw_axis]

	# Reset the interface
	reset_hw_axi $axi_hw

	# 32-bit aligned address
	set addr [format "0x%.8X" [expr {$addr & ~3}]]

	# Create the read transaction
	create_hw_axi_txn axi_read $axi_hw -type READ \
		-address $addr -len 1 -force -quiet

	# Run the transaction
	run_hw_axi [get_hw_axi_txns axi_read] -quiet

	# Extract the response data
	set rddata 0x[lindex [report_hw_axi_txn axi_read -t x4] 1]

	# Delete the transaction
	delete_hw_axi_txn axi_read
	return $rddata
}
