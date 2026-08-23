# Nmap OT Howto

**How to set up Nmap and use it for authorized ICS/OT exposure discovery.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Nmap](https://img.shields.io/badge/Nmap-7.80%2B-blue.svg)](https://nmap.org/)
[![Posture](https://img.shields.io/badge/Posture-Defensive%20discovery-0c6f74.svg)](SAFE-USE.md)
[![No exploits](https://img.shields.io/badge/Exploits-None-lightgrey.svg)](SAFE-USE.md)
[![Portfolio](https://img.shields.io/badge/Portfolio-spinfosecurity.github.io-0c6f74?style=flat-square)](https://spinfosecurity.github.io)

A short human guide: install Nmap, pick safe options for operational technology, discover common ICS protocols, and turn open ports into hardening work.

> **Authorized networks only.** Get written approval and an OT change window before you scan. Aggressive IT-style scanning can disrupt PLCs, RTUs, and HMIs. This project ships **no exploit payloads**.

**Companion:** [ICS OT Protector](https://github.com/spinfosecurity/ics-ot-protector) — sector scanners with port catalogs and CISA-oriented remediation notes.

---

## What you will do

1. **Install** Nmap on your assessment workstation  
2. **Confirm** scope, timing limits, and an abort contact with the OT owner  
3. **Discover** hosts and common ICS ports slowly  
4. **Identify** protocols with discovery-oriented NSE scripts  
5. **Report** exposure for segmentation and remediation — not exploitation  

---

## 1. Set up Nmap

### Linux (Debian / Ubuntu)

```bash
sudo apt update
sudo apt install -y nmap
nmap --version
```

### Linux (RHEL / Fedora / CentOS)

```bash
sudo dnf install -y nmap    # or: sudo yum install -y nmap
nmap --version
```

### macOS

```bash
brew install nmap
nmap --version
```

### Windows

1. Download the official installer from [nmap.org/download](https://nmap.org/download.html)  
2. Run the installer (includes Npcap when selected)  
3. Open **Nmap - Zenmap GUI** or `nmap` from “Nmap Command Prompt”  
4. Confirm: `nmap --version`

### Confirm NSE scripts you will use

```bash
nmap --script-help 'modbus-discover,enip-info,bacnet-info,s7-info,omron-info,fox-info,iec-identify'
```

If a script name is missing, upgrade Nmap. Script availability varies by version.

---

## 2. Before you scan (required)

Do not skip this on live OT.

| Check | Why |
|-------|-----|
| Written authorization (CIDRs, excludes, max rate) | Legal / policy boundary |
| Change window + OT owner on call | Process impact is possible |
| Abort criteria | Stop if faults, lost I/O, or operator alarms appear |
| Prefer passive data first | Inventories, firewall logs, SPAN often reduce active probing |

Full checklist: [SAFE-USE.md](SAFE-USE.md).

**OT-safe defaults vs IT habits**

| Use on OT | Avoid until proven safe |
|-----------|-------------------------|
| `-sT -Pn -T1` (or `-T2`) | `-T4` / `-T5` |
| `--scan-delay 200ms` | `-A` (bundles OS detect, scripts, traceroute) |
| `--max-rate 20`–`30` | Full `-p-` sweeps |
| Narrow ICS port lists | Unreviewed `vuln` NSE against controllers |

---

## 3. How to use it — step by step

Replace `<target>` with an authorized host or CIDR from your scope document.

### Step A — Host discovery

```bash
nmap -sn -T2 --max-retries 1 <target>
```

ICMP is often filtered on OT networks. If this returns nothing, skip to a slow TCP port pass with `-Pn` (treat hosts as online).

### Step B — Common ICS/OT ports

```bash
nmap -sT -Pn -T1 --scan-delay 200ms --max-rate 30 \
  -p 102,502,2404,20000,44818,47808,1911,4911,2222,2455,9600 \
  -oA ot-ports \
  <target>
```

`-oA ot-ports` writes `ot-ports.nmap`, `.gnmap`, and `.xml` for your engagement package (keep them out of public git).

### Step C — Identify the protocol (NSE)

Run **one protocol at a time** against hosts that showed the matching open port:

```bash
# Modbus/TCP — Nmap marks this script intrusive; go slow
nmap -sT -Pn -T1 --scan-delay 200ms -p 502 \
  --script modbus-discover <target>

# EtherNet/IP
nmap -sT -Pn -T1 --scan-delay 200ms -p 44818 \
  --script enip-info <target>

# Siemens S7
nmap -sT -Pn -T1 --scan-delay 200ms -p 102 \
  --script s7-info <target>

# OMRON FINS
nmap -sT -Pn -T1 --scan-delay 200ms -p 9600 \
  --script omron-info <target>

# Niagara Fox
nmap -sT -Pn -T1 --scan-delay 200ms -p 1911,4911 \
  --script fox-info <target>

# IEC 60870-5-104 — also marked intrusive; go slow
nmap -sT -Pn -T1 --scan-delay 200ms -p 2404 \
  --script iec-identify <target>

# BACnet/IP (usually UDP)
nmap -sU -Pn -T1 --scan-delay 200ms -p 47808 \
  --script bacnet-info <target>

# DNP3 — many builds have no identity NSE; treat open 20000 as exposure
nmap -sT -Pn -T1 --scan-delay 200ms -p 20000 <target>
```

**Rule of thumb:** if an NSE description sounds like privilege gain, brute force, or DoS, do not use it on production controllers. Stick to identity / discovery and document findings for hardening.

---

## 4. Port reference

| Port | Typical use |
|------|-------------|
| 102 | Siemens S7comm |
| 502 | Modbus/TCP |
| 2404 | IEC 60870-5-104 |
| 20000 | DNP3 |
| 44818 | EtherNet/IP / CIP |
| 47808 | BACnet/IP (often UDP) |
| 1911, 4911 | Niagara Fox |
| 2222 | EtherNet/IP (alternate) |
| 2455 | WAGO / related automation |
| 9600 | OMRON FINS |

An open port means **reachability**, not “exploit now.” Confirm whether that path should exist between zones (Purdue / IEC 62443).

---

## 5. What to do with results

For each open service, write down:

1. **Asset** — IP, role, zone  
2. **Exposure** — who can reach it (engineering VLAN, enterprise, internet?)  
3. **Expected?** — allowlisted conduit vs accidental flat network  
4. **Action** — firewall allowlist, jump host, disable unused service, vendor patch path, monitoring  

### Minimal report block

```text
Engagement: <name>   Window: <dates>   Auth: <ticket>
Scope: <CIDRs>
Method: Nmap -sT -T1, ports <list>, scripts <list>
Findings:
  - <ip:port> <protocol> zone=<z> expected=<y/n> action=<...>
Incidents during scan: <none | describe>
```

Map product families to public guidance (e.g. CISA ICS advisories). Prefer segmentation and access control over chasing proof-of-concept exploits on live process networks.

---

## 6. Scope of this guide

| In scope | Out of scope |
|----------|--------------|
| Install and configure Nmap for OT-aware discovery | Exploit development |
| Safe timing and rate limits | DoS testing against controllers |
| Identity-oriented NSE | Credential attacks |
| Exposure → remediation reporting | Scanning without permission |

---

## Related

- [ICS OT Protector](https://github.com/spinfosecurity/ics-ot-protector)  
- [SpinfoSecurity portfolio](https://spinfosecurity.github.io)  
- [Nmap download](https://nmap.org/download.html) · [NSE docs](https://nmap.org/nsedoc/)  

---

## License

MIT — see [LICENSE](LICENSE).
