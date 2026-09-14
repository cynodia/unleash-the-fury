# unleash-the-fury

Disable the RGB LEDs on Kingston Fury RAM sticks under Linux.

## What it does

The `fury-rgb-off` script:

- auto-detects a matching `SMBus I801` adapter string when there is exactly one match
- checks DDR5 SPD device nodes (`0x50`-`0x57`) exposed via `/sys/bus/i2c/devices`
- maps detected Fury RGB controller addresses (`0x60`-`0x67`)
- writes the values needed to switch the LEDs to black/off

The current auto-detection logic is Intel-I801-oriented. If your system uses a different SMBus controller, set `BUS` manually.

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

If your system exposes multiple matching `SMBus I801` adapters, the script will stop and ask you to set `BUS` manually instead of guessing.

The script prints each detected DIMM/RGB address pair and then disables RGB on each matching stick.

## Safety note

This script writes directly to SMBus/I²C device registers after matching sysfs-exposed SPD/RGB device addresses on the selected bus. Use it only if you understand the risks and have confirmed the detected bus is correct for your system.
