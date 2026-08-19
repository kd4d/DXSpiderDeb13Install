# DXSpiderDeb13Install

Docker-based installation scripts and configuration templates for running [DXSpider](https://github.com/EA3CV/dx-spider) on a **Debian 13** VPS.

This repository packages a two-phase host setup (`root` then `sysop`) that installs Docker, builds a DXSpider container from the upstream `mojo` branch, and exposes cluster telnet and a web console.

## What This Repo Provides

| File | Purpose |
|------|---------|
| `setup_root.sh` | Run once as `root` — installs Docker and creates the `sysop` user |
| `setup_sysop.sh` | Run as `sysop` — stages config, builds image, starts container |
| `Dockerfile` | Container image: Debian Bookworm, DXSpider, ttyd web console |
| `docker-compose.yml` | Service definition and volume mounts |
| `DXVars.pm` | Station variables (callsign, location, listeners) — **customize before deploy** |
| `Listeners.pm` | Optional listener overrides |
| `issue` / `motd` | Login banner and message of the day |
| `Docs/InstallationGuide.md` | Full step-by-step installation instructions |

## Quick Start

1. **Customize** `Dockerfile`, `DXVars.pm`, `issue`, and `motd` — replace all `????` placeholders.
2. **Upload** the six deploy files to `/tmp` on your VPS (see [Installation Guide](Docs/InstallationGuide.md)).
3. **As root:** `chmod +x /tmp/*.sh && /tmp/setup_root.sh`
4. **Log out**, then **log in as `sysop`** and run `/tmp/setup_sysop.sh`.
5. **Verify:** `docker ps`, then `telnet <server-ip> 7300` or open `http://<server-ip>:8080`.

Detailed instructions, SFTP examples, skimmer/RBN setup, and troubleshooting are in **[Docs/InstallationGuide.md](Docs/InstallationGuide.md)**.

## Services and Ports

| Port | Service |
|------|---------|
| 7300 | DXSpider user telnet (cluster login) |
| 8001 | DXSpider node port (cluster interconnect) |
| 8080 | Web console (ttyd + Perl console) |

Adjust port mappings in `docker-compose.yml` if your environment requires different external ports.

## Configuration Notes

- **`DXVars.pm`** — Set your callsign, name, QTH, locator, email, and listener definitions. Lines containing `????` must be changed before deployment.
- **`Dockerfile`** — Set the web console password and callsign in the `ttyd` entrypoint line.
- **`issue` / `motd`** — Customize login banners; copy to `~/dxspider-prod/local_data/` after first deploy (see installation guide).
- **Runtime data** — `local/`, `local_data/`, `connect/`, and `local_cmd/` are created on the server and mounted into the container; they are excluded from git via `.gitignore`.

## Server Directory Layout

After installation on the VPS:

```text
~/dxspider-prod/
├── Dockerfile
├── docker-compose.yml
├── local/           ← DXVars.pm, Listeners.pm
├── local_data/      ← dxusers.db, issue, motd
├── connect/         ← skimmer/node connection scripts
└── local_cmd/
```

## Useful DXSpider Commands

After logging in (telnet or web console):

```text
help apropos          # find commands by keyword
sh/dx                 # show DX spots
sh/user               # list connected users
set/skimmer           # enable skimmer/RBN spots
unset/skimmer         # disable skimmer spots
links                 # show active node connections
```

See `motd` in this repo for more examples, and the [DXSpider User Manual](https://wiki.dxcluster.org/wiki/DXSpider_User_Manual) for full documentation.

## Requirements

- Debian 13 VPS (tested on `6.12.x+deb13-amd64`)
- Root access for initial setup
- Outbound internet (Docker install, git clone of dx-spider)

## License and Upstream

DXSpider itself is maintained upstream at [EA3CV/dx-spider](https://github.com/EA3CV/dx-spider). Configuration templates such as `DXVars.pm` retain their original copyright notices from the DXSpider project.

Install and deployment scripts in this repository are provided as-is for amateur radio sysops deploying a personal DX cluster node.
