# DXSpider Debian 13 Installation Guide

This guide walks through deploying [DXSpider](https://github.com/EA3CV/dx-spider) on a Debian 13 VPS using Docker. The install uses two setup scripts: one run as `root`, then one run as `sysop`.

## Prerequisites

- A Debian 13 (or compatible) VPS with root SSH access
- SFTP/SCP client (Windows OpenSSH, PuTTY, WinSCP, etc.)
- Your amateur radio callsign and station details

## Overview

| Phase | User | Script | Purpose |
|-------|------|--------|---------|
| 1 | `root` | `setup_root.sh` | Install Docker, create `sysop` user |
| 2 | `sysop` | `setup_sysop.sh` | Stage config files, build and start container |

After deployment:

| Service | Port | Description |
|---------|------|-------------|
| Cluster Telnet | 7300 | User login (telnet/SSH client) |
| Node port | 8001 | Cluster node connections (optional) |
| Web console | 8080 | Browser-based DXSpider console (ttyd) |

---

## Step 0: Determine Server IP Address

Log in to the server and run:

```bash
ip a
```

Look for the primary interface (often `eth0` or `enp0s*`) and note the `inet` address, for example:

```
inet 203.0.113.10/24 brd 203.0.113.255 scope global eth0
```

Use this address wherever `<server-ip>` appears below.

---

## Step 1: Customize and Upload Files

### Files to customize

Edit these repository files **before** uploading. Search for `????` placeholders and replace them with your values:

| File | What to change |
|------|----------------|
| `Dockerfile` | Web console password and login callsign in the `ttyd` line |
| `DXVars.pm` | Callsign, name, location, email, and listener ports |
| `docker-compose.yml` | Published ports if needed |
| `Listeners.pm` | Listener addresses and ports (if used separately from `DXVars.pm`) |
| `issue` | Pre-login banner text |
| `motd` | Post-login message of the day |

#### Dockerfile

Change the web console credentials and console callsign:

```dockerfile
exec ttyd -p 8080 -W -c "sysop:YOUR_WEB_PASSWORD" perl -I/spider/local -I/spider/perl /spider/perl/console.pl YOUR-CALLSIGN
```

#### DXVars.pm

```perl
$mycall    = "W3LPL";
$myname    = "Your Name";
$myalias   = "W3LPL-9";      # Web console / alias callsign
$mylatitude  = 39.3;
$mylongitude = -77.0;
$mylocator = "FM19LG";
$myqth     = "Glenwood, MD";
$myemail   = "you@example.com";
```

### Upload to `/tmp`

Upload these six files to `/tmp` on the server as `root`:

- `setup_root.sh`
- `setup_sysop.sh`
- `Dockerfile`
- `docker-compose.yml`
- `DXVars.pm`
- `Listeners.pm`

#### Example: SFTP from Windows

```text
sftp root@<server-ip>
cd /tmp
put Dockerfile
put DXVars.pm
put docker-compose.yml
put Listeners.pm
mput setup*.sh
ls
```

Confirm all six files are present in `/tmp` before continuing.

---

## Step 2: Execute Root Setup

SSH in as `root`:

```bash
ssh root@<server-ip>
cd /tmp
chmod +x *.sh
./setup_root.sh
```

The script will:

1. Update the system and install prerequisites
2. Add the official Docker repository and install Docker
3. Create the `sysop` user (UID 1000) and prompt for a password
4. Add `sysop` to the `sudo` and `docker` groups

When finished, you should see:

```text
Root setup complete!
Please log out completely and log back in as 'sysop'
then execute setup_sysop.sh
```

---

## Step 3: Log Out

Exit the root session completely so group membership takes effect:

```bash
exit
```

---

## Step 4: Log In as sysop and Deploy

SSH back in as `sysop`:

```bash
ssh sysop@<server-ip>
cd /tmp
echo $UID    # should print 1000
./setup_sysop.sh
```

The script verifies the four config files are in `/tmp`, copies them into `~/dxspider-prod/`, then runs `docker compose build` and `docker compose up -d`.

Expected completion message:

```text
DXSpider container deployment complete!
Web console running on port 8080.
Cluster Telnet running on port 7300.
```

### Verify the container

```bash
docker ps
```

You should see the `dxspider` container with ports `7300` and `8080` published.

### Test Telnet locally

```bash
telnet localhost 7300
```

Log in with your callsign. Example session:

```text
login: KD4D
Hello KD4D, this is W3LPL in Glenwood,MD
running DXSpider V1.57 build 686
...
KD4D de W3LPL 30-Jul-2026 1649Z dxspider >
sh/user
exit
```

### Test from your workstation

```text
telnet <server-ip> 7300
```

### Test the web console

Open in a browser:

```text
http://<server-ip>:8080
```

Use the credentials from your customized `Dockerfile` (`sysop:YOUR_WEB_PASSWORD`) and the callsign from the `ttyd` line.

The `sh/node` command should work once the user database is initialized.

---

## Post-Install Configuration

### Copy banner files

Copy `issue` and `motd` into the persistent data directory **as user `sysop`**:

```bash
cp /tmp/issue ~/dxspider-prod/local_data/issue
cp /tmp/motd  ~/dxspider-prod/local_data/motd
```

Restart the container if needed:

```bash
cd ~/dxspider-prod
docker compose restart
```

### Configure Reverse Beacon Network (Skimmer) connections

From the DXSpider console (web or telnet), register skimmer nodes:

```text
set/node sk0mmr
set/node sk1mmr
set/rbn sk0mmr sk1mmr
```

Create connection scripts in `~/dxspider-prod/connect/`:

**`~/dxspider-prod/connect/sk0mmr`** (CW):

```text
timeout 60
connect telnet telnet.reversebeacon.net 7000
'call:' 'YOUR-CALL-RBNCW'
```

**`~/dxspider-prod/connect/sk1mmr`** (FT8/FT4):

```text
timeout 60
connect telnet telnet.reversebeacon.net 7001
'call:' 'YOUR-CALL-RBNFT'
```

Make them executable:

```bash
chmod +x ~/dxspider-prod/connect/sk*
```

Test manually from the console before relying on automatic connections:

```text
connect sk0mmr
connect sk1mmr
links
```

---

## Directory Layout (on server)

After `setup_sysop.sh` completes:

```text
~/dxspider-prod/
├── Dockerfile
├── docker-compose.yml
├── local/
│   ├── DXVars.pm
│   └── Listeners.pm
├── local_data/          # persistent DB, issue, motd
├── connect/             # skimmer / node connection scripts
└── local_cmd/           # optional local commands
```

---

## Troubleshooting

| Symptom | Check |
|---------|-------|
| Cannot connect on port 7300 | `docker ps`, firewall rules, `docker compose logs` |
| Web console login fails | Password and callsign in `Dockerfile` `ttyd` line |
| `setup_sysop.sh` waits for files | All four config files must be in `/tmp` |
| Permission errors | Ensure `sysop` UID is 1000 (`echo $UID`) |

View container logs:

```bash
cd ~/dxspider-prod
docker compose logs -f
```

---

## References

- [DXSpider User Manual](https://wiki.dxcluster.org/wiki/DXSpider_User_Manual)
- [DXSpider Filtering Manual](https://wiki.dxcluster.org/wiki/DXSpider_Filtering_Manual)
- [EA3CV dx-spider (mojo branch)](https://github.com/EA3CV/dx-spider)
