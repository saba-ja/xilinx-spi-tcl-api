source ./jtag_cmds.tcl -notrace

# The followin is based on Xilinx PG153 product guide

# Software Reset Register Description 
# (Core Base Address + 0x40)
# The only allowed operation on this register 
# is a write of 0x0000000a, which resets the 
# AXI Quad SPI core.
proc spi_srr_software_reset {base_addr} {
    set srr_reg 0x40
    set value 0x0000000a
    set addr [expr {$base_addr + $srr_reg}]
    axi_write $addr $value
    puts "SPI reset. Reg 0x[format %08x $addr] value 0x[format %08x $value]"
}


# Write to the LOOP bit in the SPI Control Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Boolean value (0 or 1) to set the LOOP bit.
#
# Description:
#   This procedure allows you to write to the LOOP bit of the SPI Control Register.
#   The LOOP bit enables local loopback operation in standard SPI master mode.
#   When set to 1, the transmitter output is internally connected to the receiver input.
#   The receiver and transmitter operate normally, except that received data 
#   from a remote slave is ignored.
#
proc spi_cr_loop_write {base_addr value} {
    set spicr_addr [expr {$base_addr + 0x60}]
    set spicr_value [axi_read $spicr_addr] ;

    if {$value == 1} {
        set new_spicr_value [expr {$spicr_value | 0x1}]
    } else {
        set new_spicr_value [expr {$spicr_value & ~0x1}]
    }
    
    axi_write $spicr_addr $new_spicr_value
}

# Read the LOOP bit from the SPI Control Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the LOOP bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the LOOP bit from the SPI Control Register.
#   The LOOP bit indicates whether the SPI core is operating in normal mode (0) or loopback mode (1).
#
proc spi_cr_loop_read {base_addr} {
    set spicr_addr [expr {$base_addr + 0x60}]
    set spicr_value [axi_read $spicr_addr]
    
    set loop_bit [expr {$spicr_value & 0x1}]
    return $loop_bit
}

# Write to the SPE (SPI system enable) bit in the SPI Control Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Boolean value (0 or 1) to set the SPE bit.
#
# Description:
#   This procedure allows you to write to the SPE bit of the SPI Control Register.
#   The SPE bit controls the SPI system's enable state.
#   When set to 1, the SPI system is enabled, and the master outputs are active.
#
proc spi_enable {base_addr value} {
    spi_cr_spe_write $base_addr $value
}

proc spi_cr_spe_write {base_addr value} {
    set spicr_addr [expr {$base_addr + 0x60}]
    set spicr_value [axi_read $spicr_addr]
    
    if {$value == 1} {
        set new_spicr_value [expr {$spicr_value | 0x2}]
    } else {
        set new_spicr_value [expr {$spicr_value & ~0x2}]
    }
    
    axi_write $spicr_addr $new_spicr_value
}

# Read the SPE bit from the SPI Control Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the SPE bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the SPE bit from the SPI Control Register.
#   The SPE bit indicates whether the SPI system is enabled (1) or disabled (0).
#
proc spi_is_enabled {base_addr} {
    set is_en [spi_cr_spe_read $base_addr]
    return $is_en
}
proc spi_cr_spe_read {base_addr} {
    set spicr_addr [expr {$base_addr + 0x60}]
    set spicr_value [axi_read $spicr_addr]
    
    set spe_bit [expr {($spicr_value >> 1) & 0x1}]
    return $spe_bit
}

# Write to the Master bit in the SPI Control Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Boolean value (0 or 1) to set the Master bit.
#
# Description:
#   This procedure allows you to write to the Master bit of the SPI Control Register.
#   The Master bit configures the SPI device as a master (1) or a slave (0).
#   In dual/quad SPI mode, only the master mode of the core is allowed.
#
proc spi_cr_master_write {base_addr value} {
    set spicr_addr [expr {$base_addr + 0x60}]
    set spicr_value [axi_read $spicr_addr]
    
    if {$value == 1} {
        set new_spicr_value [expr {$spicr_value | 0x4}]
    } else {
        set new_spicr_value [expr {$spicr_value & ~0x4}]
    }
    
    axi_write $spicr_addr $new_spicr_value
}

# Read the Master bit from the SPI Control Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the Master bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the Master bit from the SPI Control Register.
#   The Master bit indicates whether the SPI device is configured as a master (1) or a slave (0).
#
proc spi_cr_master_read {base_addr} {
    set spicr_addr [expr {$base_addr + 0x60}]
    set spicr_value [axi_read $spicr_addr]
    
    set master_bit [expr {($spicr_value >> 2) & 0x1}]
    return $master_bit
}

# Write to the CPOL bit in the SPI Control Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Boolean value (0 or 1) to set the CPOL bit.
#
# Description:
#   This procedure allows you to write to the CPOL bit of the SPI Control Register.
#   The CPOL bit defines the clock polarity.
#   When set to 0, the clock is active-high, and SCK idles low.
#   When set to 1, the clock is active-low, and SCK idles high.
#
proc spi_cr_cpol_write {base_addr value} {
    set spicr_addr [expr {$base_addr + 0x60}]
    set spicr_value [axi_read $spicr_addr]
    
    if {$value == 1} {
        set new_spicr_value [expr {$spicr_value | (1 << 3)}]
    } else {
        set new_spicr_value [expr {$spicr_value & ~(1 << 3)}]
    }
    
    axi_write $spicr_addr $new_spicr_value
}

# Read the CPOL bit from the SPI Control Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the CPOL bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the CPOL bit from the SPI Control Register.
#   The CPOL bit indicates whether the clock polarity is active-high (0) or active-low (1).
#
proc spi_cr_cpol_read {base_addr} {
    set spicr_addr [expr {$base_addr + 0x60}]
    set spicr_value [axi_read $spicr_addr]
    
    set cpol_bit [expr {($spicr_value >> 3) & 1}]
    return $cpol_bit
}

# Write to the CPHA bit in the SPI Control Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Boolean value (0 or 1) to set the CPHA bit.
#
# Description:
#   This procedure allows you to write to the CPHA bit of the SPI Control Register.
#   The CPHA bit selects one of two fundamentally different transfer formats.
#   When set to 0, the data is captured on the leading edge (rising edge) of the clock.
#   When set to 1, the data is captured on the trailing edge (falling edge) of the clock.
#
proc spi_cr_cpha_write {base_addr value} {
    set spicr_addr [expr {$base_addr + 0x60}]
    set spicr_value [axi_read $spicr_addr]
    
    if {$value == 1} {
        set new_spicr_value [expr {$spicr_value | (1 << 4)}]
    } else {
        set new_spicr_value [expr {$spicr_value & ~(1 << 4)}]
    }
    
    axi_write $spicr_addr $new_spicr_value
}

# Read the CPHA bit from the SPI Control Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the CPHA bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the CPHA bit from the SPI Control Register.
#   The CPHA bit indicates the clock phase, where 0 corresponds to leading edge (rising edge) capture
#   and 1 corresponds to trailing edge (falling edge) capture.
#
proc spi_cr_cpha_read {base_addr} {
    set spicr_addr [expr {$base_addr + 0x60}]
    set spicr_value [axi_read $spicr_addr]
    
    set cpha_bit [expr {($spicr_value >> 4) & 1}]
    return $cpha_bit
}

# Write to the TX_FIFO_Reset bit in the SPI Control Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Boolean value (0 or 1) to set the TX_FIFO_Reset bit.
#
# Description:
#   This procedure allows you to write to the TX_FIFO_Reset bit of the SPI Control Register.
#   The TX_FIFO_Reset bit is used to force a reset of the transmit FIFO to the empty condition.
#   One AXI clock cycle after reset, this bit is again set to 0.
#   When set to 1, the transmit FIFO pointer is reset.
#
proc spi_cr_tx_fifo_reset_write {base_addr value} {
    set spicr_addr [expr {$base_addr + 0x60}]
    set spicr_value [axi_read $spicr_addr]
    
    if {$value == 1} {
        set new_spicr_value [expr {$spicr_value | (1 << 5)}]
    } else {
        set new_spicr_value [expr {$spicr_value & ~(1 << 5)}]
    }
    
    axi_write $spicr_addr $new_spicr_value
}

# Read the TX_FIFO_Reset bit from the SPI Control Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the TX_FIFO_Reset bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the TX_FIFO_Reset bit from the SPI Control Register.
#   The TX_FIFO_Reset bit indicates whether the transmit FIFO reset is active (1) or not (0).
#
proc spi_cr_tx_fifo_reset_read {base_addr} {
    set spicr_addr [expr {$base_addr + 0x60}]
    set spicr_value [axi_read $spicr_addr]
    
    set tx_fifo_reset_bit [expr {($spicr_value >> 5) & 1}]
    return $tx_fifo_reset_bit
}

# Write to the RX_FIFO_Reset bit in the SPI Control Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Boolean value (0 or 1) to set the RX_FIFO_Reset bit.
#
# Description:
#   This procedure allows you to write to the RX_FIFO_Reset bit of the SPI Control Register.
#   The RX_FIFO_Reset bit is used to force a reset of the receive FIFO to the empty condition.
#   One AXI clock cycle after reset, this bit is again set to 0.
#   When set to 1, the receive FIFO pointer is reset.
#
proc spi_cr_rx_fifo_reset_write {base_addr value} {
    set spicr_addr [expr {$base_addr + 0x60}]
    set spicr_value [axi_read $spicr_addr]
    
    if {$value == 1} {
        set new_spicr_value [expr {$spicr_value | (1 << 6)}]
    } else {
        set new_spicr_value [expr {$spicr_value & ~(1 << 6)}]
    }
    
    axi_write $spicr_addr $new_spicr_value
}

# Read the RX_FIFO_Reset bit from the SPI Control Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the RX_FIFO_Reset bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the RX_FIFO_Reset bit from the SPI Control Register.
#   The RX_FIFO_Reset bit indicates whether the receive FIFO reset is active (1) or not (0).
#
proc spi_cr_rx_fifo_reset_read {base_addr} {
    set spicr_addr [expr {$base_addr + 0x60}]
    set spicr_value [axi_read $spicr_addr]
    
    set rx_fifo_reset_bit [expr {($spicr_value >> 6) & 1}]
    return $rx_fifo_reset_bit
}

# Write to the Manual_Slave_Select_Assertion_Enable bit in the SPI Control Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Boolean value (0 or 1) to set the Manual_Slave_Select_Assertion_Enable bit.
#
# Description:
#   This procedure allows you to write to the Manual_Slave_Select_Assertion_Enable bit of the SPI Control Register.
#   The Manual_Slave_Select_Assertion_Enable bit forces the data in the slave select register to be asserted on the slave select output.
#   This happens anytime the device is configured as a master and the device is enabled (SPE asserted).
#   This bit has no effect on slave operation.
#
proc spi_cr_manual_slave_select_assertion_enable_write {base_addr value} {
    set spicr_addr [expr {$base_addr + 0x60}]
    set spicr_value [axi_read $spicr_addr]
    
    if {$value == 1} {
        set new_spicr_value [expr {$spicr_value | (1 << 7)}]
    } else {
        set new_spicr_value [expr {$spicr_value & ~(1 << 7)}]
    }
    
    axi_write $spicr_addr $new_spicr_value
}

# Read the Manual_Slave_Select_Assertion_Enable bit from the SPI Control Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the Manual_Slave_Select_Assertion_Enable bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the Manual_Slave_Select_Assertion_Enable bit from the SPI Control Register.
#   The Manual_Slave_Select_Assertion_Enable bit determines whether the slave select output follows data in the slave select register.
#
proc spi_cr_manual_slave_select_assertion_enable_read {base_addr} {
    set spicr_addr [expr {$base_addr + 0x60}]
    set spicr_value [axi_read $spicr_addr]
    
    set manual_slave_select_assertion_enable_bit [expr {($spicr_value >> 7) & 1}]
    return $manual_slave_select_assertion_enable_bit
}

# Write to the Master_Transaction_Inhibit bit in the SPI Control Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Boolean value (0 or 1) to set the Master_Transaction_Inhibit bit.
#
# Description:
#   This procedure allows you to write to the Master_Transaction_Inhibit bit of the SPI Control Register.
#   The Master_Transaction_Inhibit bit inhibits master transactions. This bit has no effect on slave operation.
#   When set to 1, master transactions are disabled, and this immediately inhibits the transaction.
#
proc spi_cr_master_transaction_inhibit_write {base_addr value} {
    set spicr_addr [expr {$base_addr + 0x60}]
    set spicr_value [axi_read $spicr_addr]
    
    if {$value == 1} {
        set new_spicr_value [expr {$spicr_value | (1 << 8)}]
    } else {
        set new_spicr_value [expr {$spicr_value & ~(1 << 8)}]
    }
    
    axi_write $spicr_addr $new_spicr_value
}

# Read the Master_Transaction_Inhibit bit from the SPI Control Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the Master_Transaction_Inhibit bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the Master_Transaction_Inhibit bit from the SPI Control Register.
#   The Master_Transaction_Inhibit bit indicates whether master transactions are enabled (0) or disabled (1).
#
proc spi_cr_master_transaction_inhibit_read {base_addr} {
    set spicr_addr [expr {$base_addr + 0x60}]
    set spicr_value [axi_read $spicr_addr]
    
    set master_transaction_inhibit_bit [expr {($spicr_value >> 8) & 1}]
    return $master_transaction_inhibit_bit
}

# Write to the LSB_First bit in the SPI Control Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Boolean value (0 or 1) to set the LSB_First bit.
#
# Description:
#   This procedure allows you to write to the LSB_First bit of the SPI Control Register.
#   The LSB_First bit selects the LSB first data transfer format.
#   When set to 1, the transfer format becomes LSB first; when set to 0, it's MSB first.
#
proc spi_cr_lsb_first_write {base_addr value} {
    set spicr_addr [expr {$base_addr + 0x60}]
    set spicr_value [axi_read $spicr_addr]
    
    if {$value == 1} {
        set new_spicr_value [expr {$spicr_value | (1 << 9)}]
    } else {
        set new_spicr_value [expr {$spicr_value & ~(1 << 9)}]
    }
    
    axi_write $spicr_addr $new_spicr_value
}

# Read the LSB_First bit from the SPI Control Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the LSB_First bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the LSB_First bit from the SPI Control Register.
#   The LSB_First bit indicates whether the data transfer format is LSB first (1) or MSB first (0).
#
proc spi_cr_lsb_first_read {base_addr} {
    set spicr_addr [expr {$base_addr + 0x60}]
    set spicr_value [axi_read $spicr_addr]
    
    set lsb_first_bit [expr {($spicr_value >> 9) & 1}]
    return $lsb_first_bit
}

# Read the RX_Empty bit from the SPI Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the RX_Empty bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the RX_Empty bit from the SPI Status Register.
#   The RX_Empty bit is set high when the receive FIFO is empty (or when the receive register has been read in standard SPI mode).
#   The occupancy of the FIFO is decremented with each FIFO read operation.
#   Note that in dual/quad SPI mode, the FIFO is always present in the core.
#
proc spi_sr_rx_empty_read {base_addr} {
    set spisr_addr [expr {$base_addr + 0x64}]
    set spisr_value [axi_read $spisr_addr]
    
    set rx_empty_bit [expr {$spisr_value & 1}]
    return $rx_empty_bit
}

# Read the RX_Full bit from the SPI Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the RX_Full bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the RX_Full bit from the SPI Status Register.
#   The RX_Full bit is set high when the receive FIFO is full (or when an SPI transfer has completed in standard SPI mode).
#   The occupancy of the FIFO is incremented with the completion of each SPI transaction.
#   Note that in dual/quad SPI mode, the FIFO is always present in the core.
#
proc spi_sr_rx_full_read {base_addr} {
    set spisr_addr [expr {$base_addr + 0x64}]
    set spisr_value [axi_read $spisr_addr]
    
    set rx_full_bit [expr {($spisr_value >> 1) & 1}]
    return $rx_full_bit
}

# Read the TX_Empty bit from the SPI Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the TX_Empty bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the TX_Empty bit from the SPI Status Register.
#   The TX_Empty bit is set high when the transmit FIFO is empty.
#   While this bit is high, the last byte of the data that is to be transmitted would still be in the pipeline.
#   The occupancy of the FIFO is decremented with the completion of each SPI transfer.
#   Note that in dual/quad SPI mode, the FIFO is always present in the core.
#
proc spi_sr_tx_empty_read {base_addr} {
    set spisr_addr [expr {$base_addr + 0x64}]
    set spisr_value [axi_read $spisr_addr]
    
    set tx_empty_bit [expr {($spisr_value >> 2) & 1}]
    return $tx_empty_bit
}

# Read the TX_Full bit from the SPI Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the TX_Full bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the TX_Full bit from the SPI Status Register.
#   The TX_Full bit is set high when the transmit FIFO is full (or when an AXI write to the transmit register has been made in standard SPI mode).
#   Note that in dual/quad SPI mode, the FIFO is always present in the core.
#
proc spi_sr_tx_full_read {base_addr} {
    set spisr_addr [expr {$base_addr + 0x64}]
    set spisr_value [axi_read $spisr_addr]
    
    set tx_full_bit [expr {($spisr_value >> 3) & 1}]
    return $tx_full_bit
}

# Read the MODF (Mode-fault error flag) bit from the SPI Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the MODF bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the MODF (Mode-fault error flag) bit from the SPI Status Register.
#   The MODF bit is set if the SS (Slave Select) signal goes active while the SPI device is configured as a master.
#   MODF is automatically cleared by reading the SPISR.
#   A Low-to-High MODF transition generates a single-cycle strobe interrupt.
#
proc spi_sr_modf_read {base_addr} {
    set spisr_addr [expr {$base_addr + 0x64}]
    set spisr_value [axi_read $spisr_addr]
    
    set modf_bit [expr {($spisr_value >> 4) & 1}]
    return $modf_bit
}

# Read the Slave_Mode_Select bit from the SPI Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the Slave_Mode_Select bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the Slave_Mode_Select bit from the SPI Status Register.
#   The Slave_Mode_Select flag is asserted when the core is configured in slave mode.
#   Slave_Mode_Select is activated as soon as the master SPI core asserts the chip select pin for the core.
#   1 - Default in standard mode.
#   0 - Asserted when core configured in slave mode and selected by external SPI master.
#
proc spi_sr_slave_mode_select_read {base_addr} {
    set spisr_addr [expr {$base_addr + 0x64}]
    set spisr_value [axi_read $spisr_addr]
    
    set slave_mode_select_bit [expr {($spisr_value >> 5) & 1}]
    return $slave_mode_select_bit
}

# Read the CPOL_CPHA_Error flag from the SPI Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the CPOL_CPHA_Error flag (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the CPOL_CPHA_Error flag from the SPI Status Register.
#   The CPOL_CPHA_Error flag is set to 1 when CPOL and CPHA are set to 01 or 10.
#   This is only applicable when the core is configured in dual or quad mode with the legacy or enhanced AXI4 interface.
#
proc spi_sr_cpol_cpha_error_read {base_addr} {
    set spisr_addr [expr {$base_addr + 0x64}]
    set spisr_value [axi_read $spisr_addr]
    
    set cpol_cpha_error_flag [expr {($spisr_value >> 6) & 1}]
    return $cpol_cpha_error_flag
}

# Read the Slave_mode_error flag from the SPI Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the Slave_mode_error flag (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the Slave_mode_error flag from the SPI Status Register.
#   The Slave_mode_error flag is set to 1 when the core is configured with dual or quad SPI mode and the master is set to 0 in the control register (SPICR).
#   This is only applicable when the core is configured in dual or quad mode with the legacy or enhanced AXI4 interface.
#
proc spi_sr_slave_mode_error_read {base_addr} {
    set spisr_addr [expr {$base_addr + 0x64}]
    set spisr_value [axi_read $spisr_addr]
    
    set slave_mode_error_flag [expr {($spisr_value >> 7) & 1}]
    return $slave_mode_error_flag
}

# Read the MSB_Error flag from the SPI Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the MSB_Error flag (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the MSB_Error flag from the SPI Status Register.
#   The MSB_Error flag is set to 1 when the core is configured to transfer the SPI transactions in either dual or quad SPI mode and LSB first bit is set in the control register (SPICR).
#   This is only applicable when the core is configured in dual or quad mode with the legacy or enhanced AXI4 interface.
#
proc spi_sr_msb_error_read {base_addr} {
    set spisr_addr [expr {$base_addr + 0x64}]
    set spisr_value [axi_read $spisr_addr]
    
    set msb_error_flag [expr {($spisr_value >> 8) & 1}]
    return $msb_error_flag
}

# Read the Loopback_Error flag from the SPI Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the Loopback_Error flag (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the Loopback_Error flag from the SPI Status Register.
#   The Loopback_Error flag is set to 1 when the SPI command, address, and data bits are set to be transferred in other than standard SPI protocol mode and the Loopback_Error bit is set in control register (SPICR).
#   Note: Loopback is only allowed when the core is configured in standard mode. Other modes setting of the bit causes an error.
#   This is only applicable when the core is configured in dual or quad mode with the legacy or enhanced AXI4 interface.
#
proc spi_sr_loopback_error_read {base_addr} {
    set spisr_addr [expr {$base_addr + 0x64}]
    set spisr_value [axi_read $spisr_addr]
    
    set loopback_error_flag [expr {($spisr_value >> 9) & 1}]
    return $loopback_error_flag
}

# Read the Command_Error flag from the SPI Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the Command_Error flag (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the Command_Error flag from the SPI Status Register.
#   The Command_Error flag is set to 1 when the core is configured in dual/quad SPI mode and the first entry in the SPI DTR FIFO (after reset) do not match with the supported command list for the particular memory.
#   This is only applicable when the core is configured in dual or quad mode with the legacy or enhanced AXI4 interface.
#
proc spi_sr_command_error_read {base_addr} {
    set spisr_addr [expr {$base_addr + 0x64}]
    set spisr_value [axi_read $spisr_addr]
    
    set command_error_flag [expr {($spisr_value >> 10) & 1}]
    return $command_error_flag
}

# Write to the Selected_Slave field in the SPI Slave Select Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: One-hot encoded value representing the selected slave.
#
# Description:
#   This procedure allows you to write to the Selected_Slave field in the SPI Slave Select Register.
#   The slaves are numbered right to left starting at zero with the LSB.
#   The slave numbers correspond to the indexes of the signal SS (Slave Select).
#   Each bit in the value represents the selection of a slave, where a set bit (1) indicates the selected slave.
#
proc spi_ssr_selected_slave_write {base_addr value} {
    set ssr_addr [expr {$base_addr + 0x70}]
    axi_write $ssr_addr $value
}

# Read the Selected_Slave field from the SPI Slave Select Register
# 
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the Selected_Slave field.
#
# Description:
#   This procedure allows you to read the value of the Selected_Slave field from the SPI Slave Select Register.
#   The Selected_Slave field is a one-hot encoded value representing the selected slave.
#   The slave numbers correspond to the indexes of the signal SS (Slave Select).
#   Each bit in the value represents the selection of a slave, where a set bit (1) indicates the selected slave.
#
proc spi_ssr_selected_slave_read {base_addr} {
    set ssr_addr [expr {$base_addr + 0x70}]
    set ssr_value [axi_read $ssr_addr]
    return $ssr_value
}

# Read the Occupancy_Value field from the SPI Transmit FIFO Occupancy Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The occupancy value of the SPI Transmit FIFO.
#
# Description:
#   This procedure allows you to read the occupancy value of the SPI Transmit FIFO from the SPI Transmit FIFO Occupancy Register.
#   The binary value plus 1 yields the occupancy.
#   The bit width is log(FIFO Depth).
#
proc spi_txfifo_occupancy_read {base_addr} {
    set txfifo_or_addr [expr {$base_addr + 0x74}]
    set txfifo_or_value [axi_read $txfifo_or_addr]
    
    set occupancy_value [expr {($txfifo_or_value & 0xFFFFFFFF)}]
    return $occupancy_value
}

# Read the Occupancy_Value field from the SPI Receive FIFO Occupancy Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The occupancy value of the SPI Receive FIFO.
#
# Description:
#   This procedure allows you to read the occupancy value of the SPI Receive FIFO from the SPI Receive FIFO Occupancy Register.
#   The binary value plus 1 yields the occupancy.
#   The bit width is log(FIFO Depth).
#
proc spi_rxfifo_occupancy_read {base_addr} {
    set rxfifo_or_addr [expr {$base_addr + 0x78}]
    set rxfifo_or_value [axi_read $rxfifo_or_addr]
    
    set occupancy_value [expr {($rxfifo_or_value & 0xFFFFFFFF)}]
    return $occupancy_value
}

# Write to the GIE (Global Interrupt Enable) bit in the Device Global Interrupt Enable Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the GIE bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the GIE (Global Interrupt Enable) bit in the Device Global Interrupt Enable Register.
#   When the GIE bit is set to 1, it allows passing all individually enabled interrupts to the interrupt controller.
#   When the GIE bit is set to 0, it disables passing interrupts to the interrupt controller.
#
proc spi_dgier_gie_write {base_addr value} {
    set dgier_addr [expr {$base_addr + 0x1C}]
    axi_write $dgier_addr $value
}

# Read the GIE (Global Interrupt Enable) bit from the Device Global Interrupt Enable Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the GIE (Global Interrupt Enable) bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the GIE (Global Interrupt Enable) bit from the Device Global Interrupt Enable Register.
#   When the GIE bit is set to 1, it allows passing all individually enabled interrupts to the interrupt controller.
#   When the GIE bit is set to 0, it disables passing interrupts to the interrupt controller.
#
proc spi_dgier_gie_read {base_addr} {
    set dgier_addr [expr {$base_addr + 0x1C}]
    set dgier_value [axi_read $dgier_addr]
    
    set gie_bit [expr {($dgier_value >> 31) & 1}]
    return $gie_bit
}


# Write to the MODF (Mode-fault error) bit in the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Description:
#   This procedure allows you to write to the MODF (Mode-fault error) bit in the IP Interrupt Status Register.
#   When the MODF bit is set to 1, it generates an interrupt if the SS signal goes active while the SPI device is configured as a master.
#   This bit is set immediately on SS going active. This register is TOW
#   TOW = Toggle On Write. Writing a 1 to a bit position within the register causes the corresponding bit position in the register to toggle.
proc spi_ipisr_modf_write {base_addr value} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr] ;# Read the current value first
    set ipisr_value [expr {($ipisr_value & ~(1 << 0)) | ($value << 0)}] ;# Clear and set the MODF bit
    axi_write $ipisr_addr $ipisr_value ;# Write the modified value back
}

# Read the MODF (Mode-fault error) bit from the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the MODF (Mode-fault error) bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the MODF (Mode-fault error) bit from the IP Interrupt Status Register.
#   When the MODF bit is set to 1, it indicates that the SS signal went active while the SPI device was configured as a master.
#
proc spi_ipisr_modf_read {base_addr} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr]
    
    set modf_bit [expr {($ipisr_value >> 0) & 1}]
    return $modf_bit
}

# Write to the Slave_MODF (Slave mode-fault error) bit in the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Description:
#   This procedure allows you to write to the Slave_MODF (Slave mode-fault error) bit in the IP Interrupt Status Register.
#   When the Slave_MODF bit is set to 1, it generates an interrupt if the SS signal goes active while the SPI device is configured as a slave, but is not enabled.
#   This bit is set immediately on SS going active and continually set if SS is active and the device is not enabled.
#   This register is TOW
#   TOW = Toggle On Write. Writing a 1 to a bit position within the register causes the corresponding bit position in the register to toggle.
proc spi_ipisr_slave_modf_write {base_addr value } {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr] ;# Read the current value first
    set ipisr_value [expr {($ipisr_value & ~(1 << 1)) | ($value << 1)}] ;# Clear and set the Slave_MODF bit
    axi_write $ipisr_addr $ipisr_value ;# Write the modified value back
}

# Read the Slave_MODF (Slave mode-fault error) bit from the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the Slave_MODF (Slave mode-fault error) bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the Slave_MODF (Slave mode-fault error) bit from the IP Interrupt Status Register.
#   When the Slave_MODF bit is set to 1, it indicates that the SS signal went active while the SPI device was configured as a slave, but was not enabled.
#
proc spi_ipisr_slave_modf_read {base_addr} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr]
    
    set slave_modf_bit [expr {($ipisr_value >> 1) & 1}]
    return $slave_modf_bit
}

# Write to the DTR_Empty (Data transmit register/FIFO empty) bit in the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Description:
#   This procedure allows you to write to the DTR_Empty (Data transmit register/FIFO empty) bit in the IP Interrupt Status Register.
#   When the DTR_Empty bit is set to 1, it indicates that the last byte of data has been transferred out to the external flash memory.
#   In the context of the M68HC11 reference manual, when configured without FIFOs, this interrupt is equivalent in information content to the complement of the SPI transfer complete flag (SPIF) interrupt bit.
#   In master mode, if this bit is set to 1, no more SPI transfers are permitted.
#   This register is TOW (Toggle On Write). Writing a 1 to a bit position within the register causes the corresponding bit position in the register to toggle.
#
proc spi_ipisr_dtr_empty_write {base_addr value} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr] ;# Read the current value first
    set ipisr_value [expr {($ipisr_value & ~(1 << 2)) | ($value << 2)}] ;# Clear and set the DTR_Empty bit
    axi_write $ipisr_addr $ipisr_value ;# Write the modified value back
}

# Read the DTR_Empty (Data transmit register/FIFO empty) bit from the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the DTR_Empty (Data transmit register/FIFO empty) bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the DTR_Empty (Data transmit register/FIFO empty) bit from the IP Interrupt Status Register.
#   When the DTR_Empty bit is set to 1, it indicates that the last byte of data has been transferred out to the external flash memory.
#
proc spi_ipisr_dtr_empty_read {base_addr} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr]
    
    set dtr_empty_bit [expr {($ipisr_value >> 2) & 1}]
    return $dtr_empty_bit
}

# Write to the DTR_Underrun bit in the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the DTR_Underrun bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the DTR_Underrun bit in the IP Interrupt Status Register.
#   When the DTR_Underrun bit is set to 1, it indicates that a SPI element transfer has ended with a data transmit register/FIFO underrun.
#   This can occur when data is requested from an empty transmit register/FIFO by the SPI core logic to perform a SPI transfer.
#   This condition can only occur when the SPI device is configured as a slave in standard SPI configuration and is enabled by the SPE bit.
#   All zeros are loaded in the shift register and transmitted by the slave in an underrun condition.
#   This register is TOW (Toggle On Write). Writing a 1 to a bit position within the register causes the corresponding bit position in the register to toggle.
#
proc spi_ipisr_dtr_underrun_write {base_addr value} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr] ;# Read the current value first
    set ipisr_value [expr {($ipisr_value & ~(1 << 3)) | ($value << 3)}] ;# Clear and set the DTR_Underrun bit
    axi_write $ipisr_addr $ipisr_value ;# Write the modified value back
}

# Read the DTR_Underrun bit from the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the DTR_Underrun bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the DTR_Underrun bit from the IP Interrupt Status Register.
#   When the DTR_Underrun bit is set to 1, it indicates that a SPI element transfer has ended with a data transmit register/FIFO underrun.
#
proc spi_ipisr_dtr_underrun_read {base_addr} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr]
    
    set dtr_underrun_bit [expr {($ipisr_value >> 3) & 1}]
    return $dtr_underrun_bit
}

# Write to the DRR_Full bit in the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the DRR_Full bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the DRR_Full bit in the IP Interrupt Status Register.
#   When the DRR_Full bit is set to 1, it indicates that the data receive register/FIFO is full.
#   Without FIFOs, this bit is set at the end of a SPI element transfer by a one-clock period strobe to the interrupt register.
#   With FIFOs, this bit is set at the end of the SPI element transfer when the receive FIFO has been completely filled by a one-clock period strobe to the interrupt register.
#   This register is TOW (Toggle On Write). Writing a 1 to a bit position within the register causes the corresponding bit position in the register to toggle.
#
proc spi_ipisr_drr_full_write {base_addr value} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr] ;# Read the current value first
    set ipisr_value [expr {($ipisr_value & ~(1 << 4)) | ($value << 4)}] ;# Clear and set the DRR_Full bit
    axi_write $ipisr_addr $ipisr_value ;# Write the modified value back
}

# Read the DRR_Full bit from the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the DRR_Full bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the DRR_Full bit from the IP Interrupt Status Register.
#   When the DRR_Full bit is set to 1, it indicates that the data receive register/FIFO is full.
#
proc spi_ipisr_drr_full_read {base_addr} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr]
    
    set drr_full_bit [expr {($ipisr_value >> 4) & 1}]
    return $drr_full_bit
}

# Write to the DRR_Overrun bit in the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the DRR_Overrun bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the DRR_Overrun bit in the IP Interrupt Status Register.
#   When the DRR_Overrun bit is set to 1, it indicates that an attempt to write data to a full receive register or FIFO was made by the SPI core logic to complete a SPI transfer.
#   This can occur when the SPI device is in either master or slave mode (in standard SPI mode) or if the IP is configured in SPI master mode (dual or quad SPI mode).
#   This register is TOW (Toggle On Write). Writing a 1 to a bit position within the register causes the corresponding bit position in the register to toggle.
proc spi_ipisr_drr_overrun_write {base_addr value} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr] ;# Read the current value first
    set ipisr_value [expr {($ipisr_value & ~(1 << 5)) | ($value << 5)}] ;# Clear and set the DRR_Overrun bit
    axi_write $ipisr_addr $ipisr_value ;# Write the modified value back
}

# Read the DRR_Overrun bit from the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the DRR_Overrun bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the DRR_Overrun bit from the IP Interrupt Status Register.
#   When the DRR_Overrun bit is set to 1, it indicates that an attempt to write data to a full receive register or FIFO was made by the SPI core logic to complete a SPI transfer.
#
proc spi_ipisr_drr_overrun_read {base_addr} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr]
    
    set drr_overrun_bit [expr {($ipisr_value >> 5) & 1}]
    return $drr_overrun_bit
}

# Write to the TXFIFO_Half_Empty bit in the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the TXFIFO_Half_Empty bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the TXFIFO_Half_Empty bit in the IP Interrupt Status Register.
#   In standard SPI configuration, TXFIFO_Half_Empty is the transmit FIFO half-empty interrupt.
#   In dual or quad SPI configuration, based on the FIFO depth, this bit is set at half-empty condition.
#   This interrupt exists only if the AXI Quad SPI core is configured with FIFOs (In standard, dual or quad SPI mode).
#   This register is TOW (Toggle On Write). Writing a 1 to a bit position within the register causes the corresponding bit position in the register to toggle.
#
proc spi_ipisr_txfifo_half_empty_write {base_addr value} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr] ;# Read the current value first
    set ipisr_value [expr {($ipisr_value & ~(1 << 6)) | ($value << 6)}] ;# Clear and set the TXFIFO_Half_Empty bit
    axi_write $ipisr_addr $ipisr_value ;# Write the modified value back
}

# Read the TXFIFO_Half_Empty bit from the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the TXFIFO_Half_Empty bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the TXFIFO_Half_Empty bit from the IP Interrupt Status Register.
#   In standard SPI configuration, TXFIFO_Half_Empty is the transmit FIFO half-empty interrupt.
#   In dual or quad SPI configuration, based on the FIFO depth, this bit is set at half-empty condition.
#   This interrupt exists only if the AXI Quad SPI core is configured with FIFOs (In standard, dual or quad SPI mode).
#
proc spi_ipisr_txfifo_half_empty_read {base_addr} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr]
    
    set txfifo_half_empty_bit [expr {($ipisr_value >> 6) & 1}]
    return $txfifo_half_empty_bit
}

# Write to the Slave_Select_Mode bit in the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the Slave_Select_Mode bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the Slave_Select_Mode bit in the IP Interrupt Status Register.
#   The assertion of this bit is applicable only when the core is configured in slave mode in standard SPI configuration.
#   This bit is set when the other SPI master core selects the core by asserting the slave select line.
#   This bit is set by a one-clock period strobe to the interrupt register.
#   Note: This bit is applicable only in standard SPI slave mode.
#   This register is TOW (Toggle On Write). Writing a 1 to a bit position within the register causes the corresponding bit position in the register to toggle.
#
proc spi_ipisr_slave_select_mode_write {base_addr value} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr] ;# Read the current value first
    set ipisr_value [expr {($ipisr_value & ~(1 << 7)) | ($value << 7)}] ;# Clear and set the Slave_Select_Mode bit
    axi_write $ipisr_addr $ipisr_value ;# Write the modified value back
}

# Read the Slave_Select_Mode bit from the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the Slave_Select_Mode bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the Slave_Select_Mode bit from the IP Interrupt Status Register.
#   The assertion of this bit is applicable only when the core is configured in slave mode in standard SPI configuration.
#   This bit is set when the other SPI master core selects the core by asserting the slave select line.
#   This bit is set by a one-clock period strobe to the interrupt register.
#   Note: This bit is applicable only in standard SPI slave mode.
#
proc spi_ipisr_slave_select_mode_read {base_addr} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr]
    
    set slave_select_mode_bit [expr {($ipisr_value >> 7) & 1}]
    return $slave_select_mode_bit
}

# Write to the DRR_Not_Empty bit in the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the DRR_Not_Empty bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the DRR_Not_Empty bit in the IP Interrupt Status Register.
#   The assertion of this bit is applicable only in the case where FIFO Depth is 16 or 256 and the core is configured in slave mode and standard SPI mode.
#   This bit is set when the DRR FIFO receives the first data value during the SPI transaction.
#   This bit is set by a one-clock period strobe to the interrupt register when the core receives the first data beat.
#   Note: The assertion of this bit is applicable only when the FIFO Depth parameter is 16 or 256 and the core is configured in slave mode in standard SPI mode.
#   When FIFO Depth is set to 0, this bit always returns 0. This bit has no significance in dual/quad mode.
#
proc spi_ipisr_drr_not_empty_write {base_addr value} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr] ;# Read the current value first
    set ipisr_value [expr {($ipisr_value & ~(1 << 8)) | ($value << 8)}] ;# Clear and set the DRR_Not_Empty bit
    axi_write $ipisr_addr $ipisr_value ;# Write the modified value back
}

# Read the DRR_Not_Empty bit from the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the DRR_Not_Empty bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the DRR_Not_Empty bit from the IP Interrupt Status Register.
#   The assertion of this bit is applicable only in the case where FIFO Depth is 16 or 256 and the core is configured in slave mode and standard SPI mode.
#   This bit is set when the DRR FIFO receives the first data value during the SPI transaction.
#
proc spi_ipisr_drr_not_empty_read {base_addr} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr]
    
    set drr_not_empty_bit [expr {($ipisr_value >> 8) & 1}]
    return $drr_not_empty_bit
}

# Write to the CPOL_CPHA_Error bit in the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the CPOL_CPHA_Error bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the CPOL_CPHA_Error bit in the IP Interrupt Status Register.
#   The CPOL_CPHA_Error flag is asserted when:
#   - The core is configured in either dual or quad SPI mode, and
#   - The CPOL - CPHA control register bits are set to 01 or 10.
#
proc spi_ipisr_cpol_cpha_error_write {base_addr value} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr] ;# Read the current value first
    set ipisr_value [expr {($ipisr_value & ~(1 << 9)) | ($value << 9)}] ;# Clear and set the CPOL_CPHA_Error bit
    axi_write $ipisr_addr $ipisr_value ;# Write the modified value back
}

# Read the CPOL_CPHA_Error bit from the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the CPOL_CPHA_Error bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the CPOL_CPHA_Error bit from the IP Interrupt Status Register.
#   The CPOL_CPHA_Error flag is asserted when the core is configured in either dual or quad SPI mode, and the CPOL - CPHA control register bits are set to 01 or 10.
#
proc spi_ipisr_cpol_cpha_error_read {base_addr} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr]
    
    set cpol_cpha_error_bit [expr {($ipisr_value >> 9) & 1}]
    return $cpol_cpha_error_bit
}

# Write to the Slave_Mode_Error bit in the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the Slave_Mode_Error bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the Slave_Mode_Error bit in the IP Interrupt Status Register.
#   The Slave_Mode_Error flag is asserted when:
#   - The core is configured in either dual or quad SPI mode, and
#   - The core is configured in master = 0 in control register (SPICR(2)).
#
proc spi_ipisr_slave_mode_error_write {base_addr value} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr] ;# Read the current value first
    set ipisr_value [expr {($ipisr_value & ~(1 << 10)) | ($value << 10)}] ;# Clear and set the Slave_Mode_Error bit
    axi_write $ipisr_addr $ipisr_value ;# Write the modified value back
}

# Read the Slave_Mode_Error bit from the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the Slave_Mode_Error bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the Slave_Mode_Error bit from the IP Interrupt Status Register.
#   The Slave_Mode_Error flag is asserted when the core is configured in either dual or quad SPI mode, and the core is configured in master = 0 in control register (SPICR(2)).
#
proc spi_ipisr_slave_mode_error_read {base_addr} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr]
    
    set slave_mode_error_bit [expr {($ipisr_value >> 10) & 1}]
    return $slave_mode_error_bit
}

# Write to the MSB_Error bit in the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the MSB_Error bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the MSB_Error bit in the IP Interrupt Status Register.
#   The MSB_Error flag is asserted when:
#   - The core is configured in either dual or quad SPI mode, and
#   - The LSB First bit in the control register (SPICR) is set to 1.
#
proc spi_ipisr_msb_error_write {base_addr value} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr] ;# Read the current value first
    set ipisr_value [expr {($ipisr_value & ~(1 << 11)) | ($value << 11)}] ;# Clear and set the MSB_Error bit
    axi_write $ipisr_addr $ipisr_value ;# Write the modified value back
}

# Read the MSB_Error bit from the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the MSB_Error bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the MSB_Error bit from the IP Interrupt Status Register.
#   The MSB_Error flag is asserted when the core is configured in either dual or quad SPI mode, and the LSB First bit in the control register (SPICR) is set to 1.
#
proc spi_ipisr_msb_error_read {base_addr} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr]
    
    set msb_error_bit [expr {($ipisr_value >> 11) & 1}]
    return $msb_error_bit
}

# Write to the Loopback_Error bit in the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the Loopback_Error bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the Loopback_Error bit in the IP Interrupt Status Register.
#   The Loopback_Error flag is asserted when:
#   - The core is configured in dual or quad SPI transfer mode, and
#   - The LOOP bit is set in control register (SPICR(0)).
#
proc spi_ipisr_loopback_error_write {base_addr value} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr] ;# Read the current value first
    set ipisr_value [expr {($ipisr_value & ~(1 << 12)) | ($value << 12)}] ;# Clear and set the Loopback_Error bit
    axi_write $ipisr_addr $ipisr_value ;# Write the modified value back
}

# Read the Loopback_Error bit from the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the Loopback_Error bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the Loopback_Error bit from the IP Interrupt Status Register.
#   The Loopback_Error flag is asserted when the core is configured in dual or quad SPI transfer mode, and the LOOP bit is set in control register (SPICR(0)).
#
proc spi_ipisr_loopback_error_read {base_addr} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr]
    
    set loopback_error_bit [expr {($ipisr_value >> 12) & 1}]
    return $loopback_error_bit
}

# Write to the Command_Error bit in the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the Command_Error bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the Command_Error bit in the IP Interrupt Status Register.
#   The Command_Error flag is asserted when:
#   - The core is configured in dual/quad SPI mode, and
#   - The first entry in the SPI DTR FIFO (after reset) does not match with the supported command list for particular memory.
#   When the SPI command in DTR FIFO does not match with the internal supported command list, the core completes the SPI transactions in standard SPI format.
#   This bit is set to show this behavior of the core.
#
proc spi_ipisr_command_error_write {base_addr value} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr] ;# Read the current value first
    set ipisr_value [expr {($ipisr_value & ~(1 << 13)) | ($value << 13)}] ;# Clear and set the Command_Error bit
    axi_write $ipisr_addr $ipisr_value ;# Write the modified value back
}

# Read the Command_Error bit from the IP Interrupt Status Register
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the Command_Error bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the Command_Error bit from the IP Interrupt Status Register.
#   The Command_Error flag is asserted when the core is configured in dual/quad SPI mode, and the first entry in the SPI DTR FIFO (after reset) does not match with the supported command list for particular memory.
#   When the SPI command in DTR FIFO does not match with the internal supported command list, the core completes the SPI transactions in standard SPI format.
#
proc spi_ipisr_command_error_read {base_addr} {
    set ipisr_addr [expr {$base_addr + 0x20}]
    set ipisr_value [axi_read $ipisr_addr]
    
    set command_error_bit [expr {($ipisr_value >> 13) & 1}]
    return $command_error_bit
}

# Write to the MODF bit in the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the MODF bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the MODF bit in the IPIER (IP Interrupt Enable Register).
#   The MODF flag is used to enable or disable the mode-fault error interrupt.
#
proc spi_ipier_modf_write {base_addr value} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr] ;# Read the current value first
    set ipier_value [expr {($ipier_value & ~(1 << 0)) | ($value << 0)}] ;# Clear and set the MODF bit
    axi_write $ipier_addr $ipier_value ;# Write the modified value back
}

# Read the MODF bit from the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the MODF bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the MODF bit from the IPIER (IP Interrupt Enable Register).
#   The MODF flag is used to enable or disable the mode-fault error interrupt.
#
proc spi_ipier_modf_read {base_addr} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr]
    
    set modf_bit [expr ($ipier_value >> 0) & 1]
    return $modf_bit
}

# Write to the Slave_MODF bit in the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the Slave_MODF bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the Slave_MODF bit in the IPIER (IP Interrupt Enable Register).
#   The Slave_MODF flag is used to enable or disable the slave mode-fault error interrupt.
#
proc spi_ipier_slave_modf_write {base_addr value} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr] ;# Read the current value first
    set ipier_value [expr {($ipier_value & ~(1 << 1)) | ($value << 1)}] ;# Clear and set the Slave_MODF bit
    axi_write $ipier_addr $ipier_value ;# Write the modified value back
}

# Read the Slave_MODF bit from the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the Slave_MODF bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the Slave_MODF bit from the IPIER (IP Interrupt Enable Register).
#   The Slave_MODF flag is used to enable or disable the slave mode-fault error interrupt.
#
proc spi_ipier_slave_modf_read {base_addr} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr]
    
    set slave_modf_bit [expr ($ipier_value >> 1) & 1]
    return $slave_modf_bit
}

# Write to the DTR_Empty bit in the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the DTR_Empty bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the DTR_Empty bit in the IPIER (IP Interrupt Enable Register).
#   The DTR_Empty flag is used to enable or disable the data transmit register/FIFO empty interrupt.
#
proc spi_ipier_dtr_empty_write {base_addr value} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr] ;# Read the current value first
    set ipier_value [expr {($ipier_value & ~(1 << 2)) | ($value << 2)}] ;# Clear and set the DTR_Empty bit
    axi_write $ipier_addr $ipier_value ;# Write the modified value back
}

# Read the DTR_Empty bit from the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the DTR_Empty bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the DTR_Empty bit from the IPIER (IP Interrupt Enable Register).
#   The DTR_Empty flag is used to enable or disable the data transmit register/FIFO empty interrupt.
#
proc spi_ipier_dtr_empty_read {base_addr} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr]
    
    set dtr_empty_bit [expr ($ipier_value >> 2) & 1]
    return $dtr_empty_bit
}

# Write to the DTR_Underrun bit in the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the DTR_Underrun bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the DTR_Underrun bit in the IPIER (IP Interrupt Enable Register).
#   The DTR_Underrun flag is used to enable or disable the data transmit FIFO underrun interrupt.
#
proc spi_ipier_dtr_underrun_write {base_addr value} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr] ;# Read the current value first
    set ipier_value [expr {($ipier_value & ~(1 << 3)) | ($value << 3)}] ;# Clear and set the DTR_Underrun bit
    axi_write $ipier_addr $ipier_value ;# Write the modified value back
}

# Read the DTR_Underrun bit from the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the DTR_Underrun bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the DTR_Underrun bit from the IPIER (IP Interrupt Enable Register).
#   The DTR_Underrun flag is used to enable or disable the data transmit FIFO underrun interrupt.
#
proc spi_ipier_dtr_underrun_read {base_addr} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr]
    
    set dtr_underrun_bit [expr ($ipier_value >> 3) & 1]
    return $dtr_underrun_bit
}

# Write to the DRR_Full bit in the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the DRR_Full bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the DRR_Full bit in the IPIER (IP Interrupt Enable Register).
#   The DRR_Full flag is used to enable or disable the data receive register/FIFO full interrupt.
#
proc spi_ipier_drr_full_write {base_addr value} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr] ;# Read the current value first
    set ipier_value [expr {($ipier_value & ~(1 << 4)) | ($value << 4)}] ;# Clear and set the DRR_Full bit
    axi_write $ipier_addr $ipier_value ;# Write the modified value back
}

# Read the DRR_Full bit from the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the DRR_Full bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the DRR_Full bit from the IPIER (IP Interrupt Enable Register).
#   The DRR_Full flag is used to enable or disable the data receive register/FIFO full interrupt.
#
proc spi_ipier_drr_full_read {base_addr} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr]
    
    set drr_full_bit [expr ($ipier_value >> 4) & 1]
    return $drr_full_bit
}

# Write to the DRR_Overrun bit in the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the DRR_Overrun bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the DRR_Overrun bit in the IPIER (IP Interrupt Enable Register).
#   The DRR_Overrun flag is used to enable or disable the receive FIFO overrun interrupt.
#
proc spi_ipier_drr_overrun_write {base_addr value} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr] ;# Read the current value first
    set ipier_value [expr {($ipier_value & ~(1 << 5)) | ($value << 5)}] ;# Clear and set the DRR_Overrun bit
    axi_write $ipier_addr $ipier_value ;# Write the modified value back
}

# Read the DRR_Overrun bit from the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the DRR_Overrun bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the DRR_Overrun bit from the IPIER (IP Interrupt Enable Register).
#   The DRR_Overrun flag is used to enable or disable the receive FIFO overrun interrupt.
#
proc spi_ipier_drr_overrun_read {base_addr} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr]
    
    set drr_overrun_bit [expr ($ipier_value >> 5) & 1]
    return $drr_overrun_bit
}


# Write to the TX_FIFO_Half_Empty bit in the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the TX_FIFO_Half_Empty bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the TX_FIFO_Half_Empty bit in the IPIER (IP Interrupt Enable Register).
#   The TX_FIFO_Half_Empty flag is used to enable or disable the transmit FIFO half-empty interrupt.
#   This bit is meaningful only if the AXI Quad SPI core is configured with FIFOs.
#
proc spi_ipier_tx_fifo_half_empty_write {base_addr value} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr] ;# Read the current value first
    set ipier_value [expr {($ipier_value & ~(1 << 6)) | ($value << 6)}] ;# Clear and set the TX_FIFO_Half_Empty bit
    axi_write $ipier_addr $ipier_value ;# Write the modified value back
}

# Read the TX_FIFO_Half_Empty bit from the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the TX_FIFO_Half_Empty bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the TX_FIFO_Half_Empty bit from the IPIER (IP Interrupt Enable Register).
#   The TX_FIFO_Half_Empty flag is used to enable or disable the transmit FIFO half-empty interrupt.
#   This bit is meaningful only if the AXI Quad SPI core is configured with FIFOs.
#
proc spi_ipier_tx_fifo_half_empty_read {base_addr} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr]
    
    set tx_fifo_half_empty_bit [expr ($ipier_value >> 6) & 1]
    return $tx_fifo_half_empty_bit
}

# Write to the Slave_Select_Mode bit in the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the Slave_Select_Mode bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the Slave_Select_Mode bit in the IPIER (IP Interrupt Enable Register).
#   The Slave_Select_Mode flag is used to enable or disable the Slave_Select_Mode interrupt.
#   This bit is applicable only when the core is configured in slave mode by selecting the active-Low status on spisel.
#   In master mode, setting this bit has no effect.
#
proc spi_ipier_slave_select_mode_write {base_addr value} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr] ;# Read the current value first
    set ipier_value [expr {($ipier_value & ~(1 << 7)) | ($value << 7)}] ;# Clear and set the Slave_Select_Mode bit
    axi_write $ipier_addr $ipier_value ;# Write the modified value back
}

# Read the Slave_Select_Mode bit from the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the Slave_Select_Mode bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the Slave_Select_Mode bit from the IPIER (IP Interrupt Enable Register).
#   The Slave_Select_Mode flag is used to enable or disable the Slave_Select_Mode interrupt.
#   This bit is applicable only when the core is configured in slave mode by selecting the active-Low status on spisel.
#   In master mode, setting this bit has no effect.
#
proc spi_ipier_slave_select_mode_read {base_addr} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr]
    
    set slave_select_mode_bit [expr ($ipier_value >> 7) & 1]
    return $slave_select_mode_bit
}

# Write to the DRR_Not_Empty bit in the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the DRR_Not_Empty bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the DRR_Not_Empty bit in the IPIER (IP Interrupt Enable Register).
#   The DRR_Not_Empty flag is used to enable or disable the DRR_Not_Empty interrupt.
#   This bit is applicable only when FIFO Depth is set to 1 and the core is configured in slave mode of standard SPI mode.
#   If FIFO Depth is set to 0, the setting of this bit has no effect. This is allowed only in standard SPI configuration.
#   This bit has no significance in dual or quad mode.
#
proc spi_ipier_drr_not_empty_write {base_addr value} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr] ;# Read the current value first
    set ipier_value [expr {($ipier_value & ~(1 << 8)) | ($value << 8)}] ;# Clear and set the DRR_Not_Empty bit
    axi_write $ipier_addr $ipier_value ;# Write the modified value back
}

# Read the DRR_Not_Empty bit from the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the DRR_Not_Empty bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the DRR_Not_Empty bit from the IPIER (IP Interrupt Enable Register).
#   The DRR_Not_Empty flag is used to enable or disable the DRR_Not_Empty interrupt.
#   This bit is applicable only when FIFO Depth is set to 1 and the core is configured in slave mode of standard SPI mode.
#   If FIFO Depth is set to 0, the setting of this bit has no effect. This is allowed only in standard SPI configuration.
#   This bit has no significance in dual or quad mode.
#
proc spi_ipier_drr_not_empty_read {base_addr} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr]
    
    set drr_not_empty_bit [expr ($ipier_value >> 8) & 1]
    return $drr_not_empty_bit
}

# Write to the CPOL_CPHA_Error bit in the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the CPOL_CPHA_Error bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the CPOL_CPHA_Error bit in the IPIER (IP Interrupt Enable Register).
#   The CPOL_CPHA_Error flag is used to enable or disable the CPOL_CPHA error interrupt.
#   This bit is applicable only when the core is configured in dual or quad SPI mode.
#
proc spi_ipier_cpol_cpha_error_write {base_addr value} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr] ;# Read the current value first
    set ipier_value [expr {($ipier_value & ~(1 << 9)) | ($value << 9)}] ;# Clear and set the CPOL_CPHA_Error bit
    axi_write $ipier_addr $ipier_value ;# Write the modified value back
}

# Read the CPOL_CPHA_Error bit from the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the CPOL_CPHA_Error bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the CPOL_CPHA_Error bit from the IPIER (IP Interrupt Enable Register).
#   The CPOL_CPHA_Error flag is used to enable or disable the CPOL_CPHA error interrupt.
#   This bit is applicable only when the core is configured in dual or quad SPI mode.
#
proc spi_ipier_cpol_cpha_error_read {base_addr} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr]
    
    set cpol_cpha_error_bit [expr ($ipier_value >> 9) & 1]
    return $cpol_cpha_error_bit
}

# Write to the Slave_Mode_Error bit in the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the Slave_Mode_Error bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the Slave_Mode_Error bit in the IPIER (IP Interrupt Enable Register).
#   The Slave_Mode_Error flag is used to enable or disable the Slave_Mode_Error interrupt.
#   This bit is applicable only when the core is configured in dual or quad SPI mode.
#
proc spi_ipier_slave_mode_error_write {base_addr value} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr] ;# Read the current value first
    set ipier_value [expr {($ipier_value & ~(1 << 10)) | ($value << 10)}] ;# Clear and set the Slave_Mode_Error bit
    axi_write $ipier_addr $ipier_value ;# Write the modified value back
}

# Read the Slave_Mode_Error bit from the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the Slave_Mode_Error bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the Slave_Mode_Error bit from the IPIER (IP Interrupt Enable Register).
#   The Slave_Mode_Error flag is used to enable or disable the Slave_Mode_Error interrupt.
#   This bit is applicable only when the core is configured in dual or quad SPI mode.
#
proc spi_ipier_slave_mode_error_read {base_addr} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr]
    
    set slave_mode_error_bit [expr ($ipier_value >> 10) & 1]
    return $slave_mode_error_bit
}

# Write to the MSB_Error bit in the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the MSB_Error bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the MSB_Error bit in the IPIER (IP Interrupt Enable Register).
#   The MSB_Error flag is used to enable or disable the MSB_Error interrupt.
#   This bit is applicable only when the core is configured in dual or quad SPI mode.
#
proc spi_ipier_msb_error_write {base_addr value} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr] ;# Read the current value first
    set ipier_value [expr {($ipier_value & ~(1 << 11)) | ($value << 11)}] ;# Clear and set the MSB_Error bit
    axi_write $ipier_addr $ipier_value ;# Write the modified value back
}

# Read the MSB_Error bit from the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the MSB_Error bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the MSB_Error bit from the IPIER (IP Interrupt Enable Register).
#   The MSB_Error flag is used to enable or disable the MSB_Error interrupt.
#   This bit is applicable only when the core is configured in dual or quad SPI mode.
#
proc spi_ipier_msb_error_read {base_addr} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr]
    
    set msb_error_bit [expr ($ipier_value >> 11) & 1]
    return $msb_error_bit
}

# Write to the Loopback_Error bit in the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the Loopback_Error bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the Loopback_Error bit in the IPIER (IP Interrupt Enable Register).
#   The Loopback_Error flag is used to enable or disable the Loopback_Error interrupt.
#   This bit is applicable only when the core is configured in dual or quad SPI mode.
#
proc spi_ipier_loopback_error_write {base_addr value} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr] ;# Read the current value first
    set ipier_value [expr {($ipier_value & ~(1 << 12)) | ($value << 12)}] ;# Clear and set the Loopback_Error bit
    axi_write $ipier_addr $ipier_value ;# Write the modified value back
}

# Read the Loopback_Error bit from the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the Loopback_Error bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the Loopback_Error bit from the IPIER (IP Interrupt Enable Register).
#   The Loopback_Error flag is used to enable or disable the Loopback_Error interrupt.
#   This bit is applicable only when the core is configured in dual or quad SPI mode.
#
proc spi_ipier_loopback_error_read {base_addr} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr]
    
    set loopback_error_bit [expr ($ipier_value >> 12) & 1]
    return $loopback_error_bit
}

# Write to the Command_Error bit in the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   value: Value to set for the Command_Error bit (0 or 1).
#
# Description:
#   This procedure allows you to write to the Command_Error bit in the IPIER (IP Interrupt Enable Register).
#   The Command_Error flag is used to enable or disable the Command_Error interrupt.
#   This bit is applicable only when the core is configured in dual or quad SPI mode.
#
proc spi_ipier_command_error_write {base_addr value} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr] ;# Read the current value first
    set ipier_value [expr {($ipier_value & ~(1 << 13)) | ($value << 13)}] ;# Clear and set the Command_Error bit
    axi_write $ipier_addr $ipier_value ;# Write the modified value back
}

# Read the Command_Error bit from the IPIER (IP Interrupt Enable Register)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The value of the Command_Error bit (0 or 1).
#
# Description:
#   This procedure allows you to read the value of the Command_Error bit from the IPIER (IP Interrupt Enable Register).
#   The Command_Error flag is used to enable or disable the Command_Error interrupt.
#   This bit is applicable only when the core is configured in dual or quad SPI mode.
#
proc spi_ipier_command_error_read {base_addr} {
    set ipier_addr [expr {$base_addr + 0x28}]
    set ipier_value [axi_read $ipier_addr]
    
    set command_error_bit [expr ($ipier_value >> 13) & 1]
    return $command_error_bit
}

# Write data to the SPI Data Transmit Register (SPI_DTR)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#   data: Data to be written to the SPI_DTR register.
#
# Description:
#   This procedure allows you to write data to the SPI Data Transmit Register (SPI_DTR).
#   The data provided will be transmitted over the SPI bus.
#
proc spi_dtr_write {base_addr data} {
    set spi_dtr_addr [expr {$base_addr + 0x68}]
    axi_write $spi_dtr_addr $data ;# Write the data to the SPI_DTR register
}

# Read data from the SPI Data Receive Register (SPI_DRR)
#
# Arguments:
#   base_addr: Base address of the SPI core.
#
# Returns:
#   The data read from the SPI_DRR register.
#
# Description:
#   This procedure allows you to read data from the SPI Data Receive Register (SPI_DRR).
#   The data received over the SPI bus can be obtained using this function.
#
proc spi_drr_read {base_addr} {
    set spi_drr_addr [expr {$base_addr + 0x6C}]
    set received_data [axi_read $spi_drr_addr] ;# Read the data from the SPI_DRR register
    return $received_data
}
