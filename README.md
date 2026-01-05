# SystemVerilog UART Transceiver on Artix-7

This repository contains the RTL design and verification environment for a full-duplex UART transceiver. The project was implemented on a **Digilent Cmod A7-35T (Xilinx Artix-7)** FPGA and verified using both simulation and on-hardware logic analysis.

The system functions as a **hardware loopback**, receiving data from a host Linux PC via USB-UART, processing it in the FPGA, and transmitting it back to verify data integrity.

## Hardware Verification
I validated the design by tapping into internal status signals using a logic analyzer and **PulseView**.

![Logic Analyzer Capture](docs/logic_analyzer_capture.png)
*Figure 1: PulseView capture showing the full transaction. `rx_in` (top) receives a byte, triggering `data_ready`, which immediately initiates the `tx_out` (middle) echo.*

![Terminal Output](docs/gtkterm_echo_test.png)
*Figure 2: Successful loopback test using GTKTerm on Ubuntu (9600 baud).*

---

## Design Implementation Details

This is not a basic UART; the design focuses on robustness and clock domain safety.

### 1. Receiver Robustness (RX)
*   **Metastability Protection:** The asynchronous `rx_in` signal passes through a **2-stage Flip-Flop Synchronizer** before entering the main logic. This prevents metastability issues caused by the signal crossing into the FPGA clock domain.
*   **Noise Rejection:** I implemented **16x Oversampling**. Instead of sampling on the edge, the logic counts clock cycles to sample the data bit exactly in the middle of the period. This makes the receiver resistant to signal noise or slight baud rate mismatches.

### 2. Verification Strategy
*   **Golden Model Testbench:** The Transmitter testbench (`tb_uart_tx.sv`) compares the DUT output against a parallel "Golden Model" task on every clock cycle. It automatically flags mismatches, rather than relying on manual waveform inspection.
*   **Error Injection:** The Receiver testbench (`tb_uart_rx.sv`) simulates framing errors to ensure the FSM recovers correctly.

---

## File Structure

*   `rtl/` - SystemVerilog source files (`uart_rx`, `uart_tx`, `uart_echo` top level).
*   `sim/` - Self-checking testbenches.
*   `constraints/` - XDC file for the Cmod A7-35T (Clock and Pin mappings).
*   `docs/` - Verification screenshots.

---

## How to Run

### Simulation
Open the files in Vivado (or any SystemVerilog simulator like Verilator/ModelSim).
*   Run `tb_uart_tx` to verify timing accuracy against the golden model.
*   Run `tb_uart_rx` to verify serial-to-parallel conversion.

### Hardware Setup
1.  Create a project in Vivado targeting the **XC7A35T-1CPG236C**.
2.  Import the `rtl` and `constraints` files.
3.  Generate Bitstream and program the Cmod A7.
4.  Connect the Cmod A7 USB to a PC.
5.  Open a serial terminal (e.g., **GTKTerm** on Linux or PuTTY on Windows).
    *   **Baud:** 9600
    *   **Data:** 8 bit
    *   **Parity:** None
    *   **Stopbits:** 1
6.  Typing characters in the terminal will send them to the FPGA, which will echo them back instantly.

---

## Tools Used

*   **HDL:** SystemVerilog
*   **FPGA:** Xilinx Artix-7 (Cmod A7)
*   **IDE:** Xilinx Vivado
*   **Debug:** Sigrok PulseView (Logic Analyzer), GTKTerm
