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

### The six files to upload

Customize the four config files below, then upload **all six** files to `/tmp` on the server as `root`:

| File | Customize before upload? |
|------|--------------------------|
| `Dockerfile` | **Yes** — web console password and callsign |
| `DXVars.pm` | **Yes** — station identity and location |
| `docker-compose.yml` | **Optional** — external port mappings |
| `Listeners.pm` | **Optional** — listener addresses and ports |
| `setup_root.sh` | No |
| `setup_sysop.sh` | No |

Search each file for `????` placeholders and replace them with your values. Comments marked `# Example:` show sample values only — do not leave the `????` strings in place.

### Dockerfile

In the `ttyd` line inside the entrypoint script, replace both placeholders:

| Placeholder | Replace with |
|-------------|--------------|
| `sysop:????????` | Web console username `sysop` and your chosen password (8 characters shown as `????????`) |
| `console.pl ?????` | Your console callsign (5 characters shown as `?????`; often matches `$myalias` in `DXVars.pm`) |

```dockerfile
exec ttyd -p 8080 -W -c "sysop:????????" perl -I/spider/local -I/spider/perl /spider/perl/console.pl ?????
```

Example after customization (your values will differ):

```dockerfile
exec ttyd -p 8080 -W -c "sysop:mySecretPw" perl -I/spider/local -I/spider/perl /spider/perl/console.pl W1ABC
```

### DXVars.pm

Replace every line containing `????` before upload:

```perl
# this really does need to change for your system!!!!
# use CAPITAL LETTERS
$mycall = "????";

# your name
$myname = "?????";

# Your 'normal' callsign (in CAPTTAL LETTERS)
$myalias = "??????";  # Example:  W3LPL-9

# Your latitude (+)ve = North (-)ve = South in degrees and decimal degrees
$mylatitude = ?????;  #  Example:  +39.3

# Your Longtitude (+)ve = East, (-)ve = West in degrees and decimal degrees
$mylongitude = ????; #  Example:  -77.0

# Your locator (USE CAPITAL LETTERS)
$mylocator = "?????";  #  Example:  FM19LG

# Your QTH (roughly)
$myqth = "?????";     #  Example:  Glenwood, MD

# Your e-mail address
$myemail = "????????";
```

| Variable | Placeholder | Notes |
|----------|-------------|-------|
| `$mycall` | `"????"` | Cluster node callsign (CAPITAL LETTERS) |
| `$myname` | `"?????"` | Your name |
| `$myalias` | `"??????"` | Normal / alias callsign (CAPITAL LETTERS); see `# Example:` comment |
| `$mylatitude` | `?????` | Decimal degrees, no quotes; North positive |
| `$mylongitude` | `????` | Decimal degrees, no quotes; East positive |
| `$mylocator` | `"?????"` | Maidenhead locator (CAPITAL LETTERS); see `# Example:` comment |
| `$myqth` | `"?????"` | City or area description; see `# Example:` comment |
| `$myemail` | `"????????"` | Contact e-mail address |

The file also defines cluster listeners at the bottom. Adjust ports or bind addresses if your deployment differs from the defaults:

```perl
@listen = (
    [ '0.0.0.0', 7300, 'dx' ],    # User Handler (interactive login: banners, 'login:' prompt)
    [ '0.0.0.0', 8001, 'node' ],  # Dedicated Node Handler (raw PC protocol, no banners/prompts)
);
```

Optional: set `@my_cc` if your node spans multiple country codes (see comments in the file). Leave blank to derive from `$mycall`.

### docker-compose.yml

No `????` placeholders. Customize only if you need non-default **external** port mappings or IPv6 networking:

| Line | Purpose |
|------|---------|
| `#- "23:7300"` | Map standard telnet port 23 to internal 7300 |
| `#- "7373:7300"` | Alternative user port |
| `- "7300:7300"` | Default user telnet (active) |
| `#- "3607:8001"` | Example incoming ARCluster node port |
| `- "8001:8001"` | Default node port (active) |
| `- "8080:8080"` | Web console (active) |
| `# enable_ipv6: true` | Enable IPv6 on the Docker network (commented by default) |
| `# - subnet: fd00:172:28::/64` | IPv6 subnet (commented by default) |

Uncomment and edit a mapping to change which host port is published. Internal container ports (`7300`, `8001`, `8080`) must stay aligned with `@listen` in `DXVars.pm` and the `Dockerfile` entrypoint.

### Listeners.pm

No `????` placeholders. This file defines which interfaces and ports DXSpider listens on. The shipped template has IPv4/IPv6 listeners enabled:

```perl
@listen = (
# remove the '#' character from the next line to enable the listener!
           ["::", 7300],     # IPV4 and IPV6
           ["::", 8001],     # IPV4 and IPV6  - Cluster Connection Port
```

Customize by:

- Uncommenting the alternative IPv4-only block if you do not want IPv6 (see comments in the file).
- Adding or removing listener entries for additional ports.

**Note:** `DXVars.pm` also defines `@listen` with handler types (`dx`, `node`). Ensure port numbers match between the two files, or consolidate listener configuration in `DXVars.pm` only and keep `Listeners.pm` consistent with your chosen approach.

### setup_root.sh and setup_sysop.sh

No customization required. Upload as-is.

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

Log in with your callsign. Example session (your banner text will reflect your `$mycall` and `$myqth` settings):

```text
login: W1ABC
Hello W1ABC, this is YOURCALL in Your City,ST
running DXSpider V1.57 build 686
...
W1ABC de YOURCALL 30-Jul-2026 1649Z dxspider >
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

Use the web console password you substituted for `????????` and the callsign you substituted for `?????` in the `Dockerfile` `ttyd` line.

The `sh/node` command should work once the user database is initialized.

---

## Post-Install Configuration

### Customize and install banner files

The repo includes `issue` (pre-login banner) and `motd` (post-login message). These are **not** among the six files uploaded in Step 1, but should be edited locally before copying to the server. Replace any site-specific text (callsign, location, node name) with your own.

Copy customized files into the persistent data directory **as user `sysop`**:

```bash
cp /path/to/issue ~/dxspider-prod/local_data/issue
cp /path/to/motd  ~/dxspider-prod/local_data/motd
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
