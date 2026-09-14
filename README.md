# unleash-the-fury
Disable RGB LEDS on Fury RAM sticks in Linux

## Run on every startup with systemd

From the repository root, use `./setup-systemd-service.sh` to install a oneshot systemd service that runs your existing LED-disabling command at boot:

```bash
sudo ./setup-systemd-service.sh '<command to disable the LEDs>'
```

The script:

- writes the command to `/etc/unleash-the-fury.command`
- installs a wrapper at `/usr/local/bin/unleash-the-fury-startup`
- installs and enables `unleash-the-fury.service`
- starts the service immediately so you can verify it without rebooting

Useful commands after installation:

```bash
systemctl is-enabled unleash-the-fury.service
journalctl -u unleash-the-fury.service
```
