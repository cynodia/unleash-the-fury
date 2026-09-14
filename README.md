# unleash-the-fury

Disable the RGB LEDs on Kingston Fury RAM sticks under Linux.

## Quick install

The installer downloads the latest `fury-rgb-off` script, asks whether you want to run a one-time test first, and then installs/enables the systemd service.

```bash
curl -fsSL https://raw.githubusercontent.com/cynodia/unleash-the-fury/main/install-systemd-service.sh | sudo bash
```

```bash
wget -qO- https://raw.githubusercontent.com/cynodia/unleash-the-fury/main/install-systemd-service.sh | sudo bash
```

If your system needs a manual SMBus selection, pass `BUS` into the installer so the same value is used for both the test run and the installed service:

```bash
curl -fsSL https://raw.githubusercontent.com/cynodia/unleash-the-fury/main/install-systemd-service.sh | sudo env BUS=4 bash -s
```

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

## Run on every startup with systemd

For the simplest path, use the quick-install command above.

If you already have a local checkout and want to install the service manually from the repository root, use `./setup-systemd-service.sh` to install a oneshot systemd service that runs your existing LED-disabling command or script at boot:

```bash
sudo ./setup-systemd-service.sh /path/to/disable-leds [args...]
```

The repository also includes `./install-systemd-service.sh` if you want the local installer that downloads `fury-rgb-off`, offers a one-time test run, and then installs the service.

The manual setup script:

- writes the command path and arguments to `/usr/local/bin/unleash-the-fury-command`
- installs and enables `unleash-the-fury.service`
- starts the service immediately on first install and restarts it on later updates

Useful commands after installation:

```bash
systemctl is-enabled unleash-the-fury.service
journalctl -u unleash-the-fury.service
```

## Safety note

This script writes directly to SMBus/I²C device registers after matching sysfs-exposed SPD/RGB device addresses on the selected bus. Use it only if you understand the risks and have confirmed the detected bus is correct for your system.
