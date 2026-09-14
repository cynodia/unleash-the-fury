# unleash-the-fury

Disable the RGB LEDs on Kingston Fury RAM sticks under Linux.

## What it does

The `fury-rgb-off` script:

- auto-detects the Intel I801 SMBus when possible
- scans DDR5 SPD addresses (`0x50`-`0x57`)
- maps detected Fury RGB controller addresses (`0x60`-`0x67`)
- writes the values needed to switch the LEDs to black/off

## Requirements

- Linux
- `i2c-tools` (`i2cdetect` and `i2cset`)
- permission to access the I²C bus (typically root)

## Usage

```bash
chmod +x ./fury-rgb-off
sudo ./fury-rgb-off
```

If auto-detection does not find the correct SMBus, set it manually:

```bash
sudo BUS=4 ./fury-rgb-off
```

The script prints each detected DIMM/RGB address pair and then disables RGB on each matching stick.

## Safety note

This script writes directly to SMBus/I²C device registers. Use it only if you understand the risks and have confirmed the detected bus is correct for your system.
