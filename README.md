# Weather Station

This repository contains the implementation of a wireless communication system for a weather station, primarily designed using digital hardware with **radio frequency (RF) modules** and RS-232 protocol. The project is divided into two main modules — **EMISOR** (Transmitter) and **RECEPTOR** (Receiver) — both written in VHDL for deployment on FPGA boards, such as the Nexys2.

## Overview

- **EMISOR (Transmitter):**  
  Responsible for sending meteorological data using UART at 9600 baud rate, packed in ASCII format via a radio frequency module.  
  Main code: [`EMISOR/EMISOR.vhd`](EMISOR/EMISOR.vhd)

- **RECEPTOR (Receiver):**  
  Receives wirelessly-transmitted data via the RF module and displays it, for example, on LEDs using the Nexys2 board.  
  Main code: [`RECEPTOR/RECEPTOR.vhd`](RECEPTOR/RECEPTOR.vhd)

## Features

- Wireless data transmission using RF modules.
- UART communication with standard baud rate configuration (9600).
- Visualization of received data on LEDs for easy monitoring/debugging.
- Modular architecture: distinct transmitter and receiver implementations.
- All digital processing is implemented in VHDL for programmable hardware.

## Repository Structure

```
Weather-Station/
├── EMISOR/
│   ├── EMISOR.vhd
│   └── output_files/
├── RECEPTOR/
│   ├── RECEPTOR.vhd
│   └── output_files/
```

## Getting Started

1. **Requirements:**
   - Compatible FPGA board (e.g., Nexys2)
   - USB or JTAG cable for programming
   - Radio frequency modules for wireless communication
   - Quartus Prime for synthesis and project management

2. **FPGA Programming:**
   - Compile the `.vhd` files using Quartus Prime.
   - Load the generated `.sof` file onto your FPGA board.

3. **Physical Connections:**
   - EMISOR: Connect the RF module to transmit data from the hardware.
   - RECEPTOR: Connect the RF module to receive data and output to LEDs for visualization.

4. **Testing Communication:**
   - You can use any external device or simulator capable of sending ASCII data via RF for testing transmission.

## Credits

Repository created by [dtrejo0611](https://github.com/dtrejo0611).

---

> Example inspired by digital circuits and serial communication lab projects.
