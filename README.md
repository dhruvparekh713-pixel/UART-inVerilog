# UART Transceiver (Verilog)

A parameterizable UART implemented in Verilog for full-duplex 8-bit serial communication. Includes a baud-rate generator, a transmitter, and a receiver with oversampling.

## Modules

| File | Description |
|------|-------------|
| `buadRateGen.v` | Divides a 50 MHz clock to configurable baud rates (9600–115200) and generates the timing tick for the TX and RX. |
| `uartTransmitter.v` | Transmitter FSM (IDLE → START → DATA → STOP). Serializes an 8-bit byte out LSB-first, framed with a start and stop bit. |
| `uartReciever.v` | Receiver FSM with [16×] oversampling. Detects the start bit, samples each data bit near its center, and reassembles the byte. |

## Frame Format

Standard 8-N-1 (8 data bits, no parity, 1 stop bit). The line idles high; a falling edge marks the start bit, followed by 8 data bits (LSB first) and a stop bit.

```
Idle  Start   D0 D1 D2 D3 D4 D5 D6 D7   Stop  Idle
 1  |   0   |     data (LSB first)    |   1   |  1
```

## Baud Rate

```
divisor = f_clk / (baud_rate × oversample_factor)
```

At 50 MHz, 115200 baud, 16× oversampling: divisor ≈ 27.

## Status

Behavioral design complete (baud generator, TX FSM, RX FSM). Testbenches in progress.

## Author

**Dhruv Parekh** — B.S. Electrical and Computer Engineering, Carnegie Mellon University
[github.com/dhruvparekh713-pixel](https://github.com/dhruvparekh713-pixel)
