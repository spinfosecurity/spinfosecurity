# Reviewing this repo for a role

If you are hiring for **OT/ICS security**, **security automation**, or defensive assessment work with a scripting bent, this page is a five-minute map.

**Repo:** [github.com/spinfosecurity/nmap-ot-howto](https://github.com/spinfosecurity/nmap-ot-howto)  
**Portfolio:** [spinfosecurity.github.io](https://spinfosecurity.github.io)  
**Companion scanners:** [ICS OT Protector](https://github.com/spinfosecurity/ics-ot-protector)

---

## What this repository demonstrates

A professional, **authorized-use** methodology for Nmap on industrial networks:

| Signal | Where to look |
|--------|----------------|
| OT-safe defaults (timing, rate limits, no `-A`) | [README §4–5](README.md#4-pre-scan-checklist) |
| Protocol literacy (Modbus, ENIP, S7, DNP3, BACnet, IEC 104) | [README §6–7](README.md#6-protocol-commands) |
| End-to-end engagement narrative | [README §2 walkthrough](README.md#2-first-engagement-walkthrough) |
| Analyst-style reporting | [README §8](README.md#8-report-findings) |
| Operations judgment (abort, troubleshooting) | [SAFE-USE.md](SAFE-USE.md) · [README §10](README.md#10-troubleshooting) |
| Tooling judgment (Nmap vs sector scanners) | [README §11](README.md#11-nmap-vs-ics-ot-protector) |

Posture is explicit: **discovery and exposure → remediation**, not exploit development.

---

## Suggested resume / portfolio bullets

Edit to match the conversation — these describe what the public repo shows:

- Authored an open-source **ICS/OT Nmap howto** covering safe timing, industrial port catalogs, and identity-oriented NSE for Modbus, EtherNet/IP, S7, BACnet, and related protocols.
- Documented an **authorized engagement workflow** (scope → slow discovery → protocol identity → remediation notes) suitable for fragile OT environments.
- Positioned Nmap alongside [ICS OT Protector](https://github.com/spinfosecurity/ics-ot-protector) sector scanners so assessors know when to use each tool.
- Kept public materials free of exploit payloads, credential attacks, and DoS recipes against controllers.

---

## Roles this maps to

OT/ICS security · SCADA / critical infrastructure defense · security automation · defensive network assessment · roles that need protocol familiarity (Modbus, DNP3, BACnet, EtherNet/IP) without offensive tooling in the portfolio.

---

## Read next

1. [README.md](README.md) — full setup and usage guide  
2. [SAFE-USE.md](SAFE-USE.md) — authorization and abort criteria  
3. [ICS OT Protector](https://github.com/spinfosecurity/ics-ot-protector) — sector scanners + employer guide  
