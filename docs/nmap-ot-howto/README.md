# Nmap for ICS/OT — Authorized Exposure Discovery

**Audience:** defenders, OT engineers, and assessors working on **authorized** networks.  
**Goal:** discover reachable ICS/OT services and map exposure for remediation — not exploit devices.

> This guide is defensive. Use it only with written authorization, an approved change window, and an OT-aware rollback plan. Aggressive IT-style scanning can disrupt PLCs, RTUs, HMIs, and legacy protocol stacks.

Companion tooling: [ICS OT Protector](https://github.com/spinfosecurity/ics-ot-protector) (TCP reachability catalogs + CISA-oriented notes; no exploit payloads).

---

## 1. Why OT scanning is different

| IT habit | OT reality |
|----------|------------|
| Fast timing (`-T4`/`-T5`) | Controllers may drop sessions or fault under burst traffic |
| Version detection / `-A` | Extra probes can crash fragile stacks |
| “Find CVEs then exploit” | Priority is **inventory + exposure + compensating controls** |
| Scan anytime | Needs process owner buy-in, window, and monitoring |

Treat Nmap as a **careful discovery instrument**, not a vulnerability cannon.

---

## 2. Before you scan (non-negotiable)

1. **Authorization** — signed scope: CIDRs, VLANs, excluded hosts, max rate, contacts.
2. **Change record** — window, observer on the process side, abort criteria.
3. **Baseline** — know what “healthy” looks like (alarms, CPU, comms counters).
4. **Start in lab** — Conpot, PLC simulators, or a mirrored OT VLAN before production.
5. **Prefer passive first** — SPAN/TAP, firewall logs, asset inventories, vendor tools where available.

If you cannot meet those, do not scan production OT.

---

## 3. Safe default posture

Use slow timing, narrow ports, and no aggressive scripts until a lab run is clean.

```bash
# Host discovery only (ICMP may be filtered — confirm with owners)
nmap -sn -T2 --max-retries 1 <authorized-cidr>

# Conservative TCP connect scan of common ICS ports (see table below)
nmap -sT -Pn -T1 --scan-delay 200ms --max-rate 30 \
  -p 102,502,20000,44818,47808,1911,4911,2222,2455,9600 \
  <authorized-targets>
```

**Defaults to avoid on live OT until proven safe in lab:**

- `-T4` / `-T5`
- `-A` (OS + version + script + traceroute bundle)
- Broad `-p-` / large UDP sweeps
- Unreviewed NSE “vuln” categories against controllers

`--defeat-rst-ratelimit` and very high `--min-rate` values also belong in lab, not on a running plant network.

---

## 4. Common ICS/OT TCP ports (discovery catalog)

| Port | Protocol / use (typical) |
|------|---------------------------|
| 102 | Siemens S7comm |
| 502 | Modbus/TCP |
| 20000 | DNP3 |
| 44818 | EtherNet/IP / CIP |
| 47808 | BACnet/IP |
| 1911, 4911 | Niagara Fox |
| 2222 | EtherNet/IP (alternate) |
| 2455 | WAGO / related automation |
| 9600 | OMRON FINS |

Use this as an **exposure checklist**, not a claim that every open port is vulnerable. Confirm with owners what should be reachable from which zone (Purdue levels / IEC 62443 zones & conduits).

---

## 5. Protocol-aware discovery (NSE) — identify, don’t attack

Nmap ships scripts that **identify** common ICS services. Prefer scripts whose purpose is discovery/info over exploit-oriented ones.

```bash
# Example: Modbus device identification on an authorized target
nmap -sT -Pn -T1 --scan-delay 200ms -p 502 \
  --script modbus-discover \
  <authorized-host>

# Example: EtherNet/IP identity
nmap -sT -Pn -T1 --scan-delay 200ms -p 44818 \
  --script enip-info \
  <authorized-host>

# Example: BACnet device info
nmap -sT -Pn -T1 --scan-delay 200ms -p 47808 \
  --script bacnet-info \
  <authorized-host>
```

Other discovery-oriented scripts worth knowing (verify names with `nmap --script-help=<name>` on your Nmap version): `s7-info`, `omron-info`, `proconos-info`, `codesys-v2-discover`.

**Rule of thumb:** if a script description sounds like privilege gain, DoS, or auth bypass, leave it out of production OT assessments. Stick to identity/discovery and document findings for hardening.

List available ICS-related scripts:

```bash
nmap --script-help 'modbus* or enip* or bacnet* or s7* or dnp*'
```

---

## 6. Turning scans into defensive outcomes

For each reachable service, record:

1. **Asset** — hostname/IP, vendor/model if identified, zone
2. **Exposure** — who can reach it (engineering workstation VLAN? corporate? internet?)
3. **Expected?** — allowlisted conduit vs accidental flat network
4. **Action** — firewall rule, jump host, vendor patch path, network segmentation, monitoring

Map follow-ups to public guidance (e.g. CISA ICS advisories for the product family) rather than chasing proof-of-concept exploits.

Example remediation themes:

- Move engineering protocols off Level 3+ / enterprise networks
- Require jump hosts / MFA for interactive access
- Disable unused services; restrict source IPs on PLCs/firewalls
- Monitor for unexpected scanners and new listeners

---

## 7. Minimal reporting template

```text
Engagement: <name>    Window: <dates>    Authorization: <ticket>
Scope: <CIDRs / hosts>
Method: Nmap -sT -T1, ports <list>, scripts <list>
Findings:
  - <ip:port> <protocol> zone=<z> expected=<y/n> action=<...>
Incidents during scan: <none | describe>
Recommendations: <segmentation / allowlists / monitoring>
```

Keep raw Nmap XML (`-oX`) with the engagement package; redact or withhold from public repos.

---

## 8. Lab practice (recommended before any live OT)

Safe places to build muscle memory:

- [Conpot](https://github.com/mushorg/conpot) — ICS honeypot / protocol simulation
- Vendor or open PLC simulators in an isolated lab VLAN
- Your own mirrored OT segment with explicit permission

Never point practice scans at someone else’s infrastructure.

---

## 9. Suggested “quick repo” layout

If you split this into its own GitHub repo later:

```text
nmap-ot-howto/
  README.md              # this guide
  LICENSE                # MIT (or your org default)
  SAFE-USE.md            # authorization + abort criteria (optional extract)
  examples/
    lab-modbus.sh        # slow, lab-only examples
  .gitignore             # ignore *.xml scan output, *.gnmap, target lists
```

Keep **scan outputs and live target lists out of git**. Publish only sanitized examples.

---

## 10. Scope of this guide

**In scope:** authorized discovery, safe timing, common ports, identity NSE, remediation-oriented reporting.  
**Out of scope:** exploit development, DoS testing against controllers, bypassing access controls, or scanning without permission.

For broader sector port catalogs and remediation-oriented scanners, see [ICS OT Protector](https://github.com/spinfosecurity/ics-ot-protector).
