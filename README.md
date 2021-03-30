# SPI-Communication-Protocol-VHDL
SPI communication protocol using VHDL code

The communication between the Artix-7 FPGA device and the external devices is established
by using SPI protocol. Inside the custom IPs (AXI peripherals) it is instantiated an final SPI
which was designed with the following features.

- Data Transmission speed is configured to 500ns(2 MHz).

- Configurable data length (16 and 24 bits).

- Configurable clock polarity (CPOL) and clock phase (CPHA).

- Full duplex data transmission.
