# unleash-the-fury
Disable RGB LEDS on Fury RAM sticks in Linux

## Run on every startup with systemd

From the repository root, use `./setup-systemd-service.sh` to install a oneshot systemd service that runs your existing LED-disabling command at boot:

```bash
sudo ./setup-systemd-service.sh '<command to disable the LEDs>'
```

The script:

- writes the command to `/usr/local/bin/unleash-the-fury-command`
- installs and enables `unleash-the-fury.service`
- starts the service immediately on first install and restarts it on later updates

Useful commands after installation:

```bash
systemctl is-enabled unleash-the-fury.service
journalctl -u unleash-the-fury.service
```
