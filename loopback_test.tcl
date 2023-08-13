# ------------------------------------------------------------------------------
# Setup
# ------------------------------------------------------------------------------
source ./spi_ctrl.tcl -notrace
set BASE_ADDR 0x40000000 ; # Change to your SPI IP address

# ------------------------------------------------------------------------------
# Software reset
# ------------------------------------------------------------------------------
spi_srr_software_reset $BASE_ADDR
after 1000

# ------------------------------------------------------------------------------
# Reset FIFOs
# ------------------------------------------------------------------------------
spi_cr_tx_fifo_reset_write $BASE_ADDR 0x1
spi_cr_rx_fifo_reset_write $BASE_ADDR 0x1

# ------------------------------------------------------------------------------
# Enable loopback mode
# ------------------------------------------------------------------------------
spi_cr_loop_write $BASE_ADDR 1
puts "Loopback [spi_cr_loop_read $BASE_ADDR]"

# ------------------------------------------------------------------------------
# Set the SPI to master mode
# ------------------------------------------------------------------------------
spi_cr_master_write $BASE_ADDR 1
puts "Master mode [spi_cr_master_read $BASE_ADDR]"

# ------------------------------------------------------------------------------
# Fill the transmit FIFO with data
# ------------------------------------------------------------------------------
set sent_count 0
set sent_value_list {}

while {1} {
    set is_tx_full [spi_sr_tx_full_read $BASE_ADDR]

    if {$is_tx_full != 1} {
        set sent_count [expr $sent_count + 1]
        spi_dtr_write $BASE_ADDR $sent_count
        set hex_count [format "0x%08x" $sent_count]
        lappend sent_value_list $hex_count
    } else {
        puts "Tx is full $is_tx_full"
        break
    }
}

puts "Transfer count $sent_count" 

# ------------------------------------------------------------------------------
# Enable the SPI device
# ------------------------------------------------------------------------------
spi_enable $BASE_ADDR 1
puts "SPI is enabled [spi_is_enabled $BASE_ADDR]"

# ------------------------------------------------------------------------------
# Disable master transaction inhibit
# ------------------------------------------------------------------------------
spi_cr_master_transaction_inhibit_write $BASE_ADDR 0
puts "Master inhibit enable [spi_cr_master_transaction_inhibit_read $BASE_ADDR]"

# ------------------------------------------------------------------------------
# Wait for transmit FIFO to become empty
# ------------------------------------------------------------------------------
while {1} {
    set is_tx_empty [spi_sr_tx_empty_read $BASE_ADDR]
    if {$is_tx_empty == 1} {
        puts "Tx is empty $is_tx_empty"
        break
    }
}

# ------------------------------------------------------------------------------
# Check the status of the receive FIFO
# ------------------------------------------------------------------------------
puts "Rx is full [spi_sr_rx_full_read $BASE_ADDR]"

# ------------------------------------------------------------------------------
# Read from receive FIFO until it's empty
# ------------------------------------------------------------------------------
set received_count 0
set receive_value_list {}

while {1} {
    set is_rx_empty [spi_sr_rx_empty_read $BASE_ADDR]
    if {$is_rx_empty == 1} {
        puts "Rx is empty $is_rx_empty"
        break
    }
    set received_value [spi_drr_read $BASE_ADDR]
    lappend receive_value_list $received_value
    set received_count [expr $received_count + 1]
}

puts "Tx count $sent_count"
puts "Rx count $received_count"

# ------------------------------------------------------------------------------
# Compare sent and received data
# ------------------------------------------------------------------------------
set is_tx_rx_match [expr {$sent_value_list eq $receive_value_list}]

if {$is_tx_rx_match} {
    puts "Sent and received data match"
} else {
    puts "Error: Sent and received data did not match"
}
