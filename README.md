# ICS/OT Advisories

### Current CISA industrial control advisories in one place—for people who maintain the equipment

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Source: CISA CSAF](https://img.shields.io/badge/Source-CISA%20CSAF%20OT-0c6f74.svg)](https://github.com/cisagov/CSAF)
[![Refresh: Weekly](https://img.shields.io/badge/Refresh-Weekly-lightgrey.svg)](.github/workflows/update-advisories.yml)
[![Live site](https://img.shields.io/badge/Live-spinfosecurity.github.io%2Fics--ot--advisories-0c6f74?style=flat-square)](https://spinfosecurity.github.io/ics-ot-advisories/)
[![Portfolio](https://img.shields.io/badge/Portfolio-spinfosecurity.github.io-0c6f74?style=flat-square)](https://spinfosecurity.github.io)

**Live:** [spinfosecurity.github.io/ics-ot-advisories](https://spinfosecurity.github.io/ics-ot-advisories/)  
**Hiring managers:** [5-minute review](FOR-EMPLOYERS.md) · **Flagship scanners:** [ICS OT Protector](https://github.com/spinfosecurity/ics-ot-protector)  
**Subscribe:** [RSS](https://spinfosecurity.github.io/ics-ot-advisories/feed.xml) · [JSON](https://spinfosecurity.github.io/ics-ot-advisories/advisories.json)

A simple, open-source place to read **CISA ICS Advisories (ICSA)** and **ICS Medical Advisories (ICSMA)**—so plant engineers, OT defenders, and integrators can answer: *does today’s notice touch equipment I maintain?*

| | |
|:--|:--|
| **Audience** | OT/ICS maintainers, critical-infrastructure defenders, security automation roles |
| **Outputs** | Searchable web page · RSS feed · JSON snapshot |
| **Source of truth** | Official [CISA CSAF OT](https://github.com/cisagov/CSAF) feed (TLP:WHITE) |
| **Not included** | Exploit details beyond public CISA text · vendor paywalled intel · unofficial scrapes of blocked RSS |

> Always verify affected products and versions on the **official CISA advisory** before patching or isolating systems. See [ATTRIBUTION.md](ATTRIBUTION.md).

---

## Why this exists

CISA publishes excellent ICS/OT advisories, but staying current across ICSA and ICSMA notices is noisy if you only have a browser tab and a vendor list in your head. This repository:

1. Reads the **authoritative CSAF machine feed** (CISA’s public RSS often returns HTTP 403 to automation)
2. Normalizes vendor, product, severity, CVSS, and canonical links
3. Publishes a **maintainer-first triage page**, plus **RSS** and **JSON**
4. Refreshes on a **weekly, rate-limited** schedule so GitHub and upstream mirrors stay happy

Keywords this project covers: **CISA ICS advisories**, **ICSMA**, **OT security**, **SCADA advisories**, **industrial control vulnerabilities**, **CSAF**, **CVSS triage**, **critical infrastructure**, and **security automation**.

---

## Live surfaces

| Surface | URL |
|---------|-----|
| Triage page | https://spinfosecurity.github.io/ics-ot-advisories/ |
| RSS | https://spinfosecurity.github.io/ics-ot-advisories/feed.xml |
| JSON | https://spinfosecurity.github.io/ics-ot-advisories/advisories.json |
| Source | https://github.com/spinfosecurity/ics-ot-advisories |

---

## Quick start (local)

```bash
git clone https://github.com/spinfosecurity/ics-ot-advisories.git
cd ics-ot-advisories
python3 tools/aggregate.py --limit 120
python3 -m http.server -d site 8765
# open http://127.0.0.1:8765/
```

Requires Python 3.10+ (stdlib only).

---

## How maintainers use the page

1. Search vendor or product family  
2. Filter Critical / High first  
3. Open the CISA write-up for versions and fixes  
4. Optionally subscribe to RSS for the ticket queue  

---

## Repository layout

```
site/                 # GitHub Pages site (generated HTML + static assets)
tools/aggregate.py    # CSAF → JSON / RSS / HTML
.github/workflows/    # weekly refresh + Pages deploy
FOR-EMPLOYERS.md      # hiring-manager map
ATTRIBUTION.md        # source credit and limits
docs/                 # practitioner notes
```

---

## Automation posture

- **Weekly** scheduled refresh (not daily)  
- Low concurrency and a small delay between fetches  
- Commits only when advisory content changes  
- Manual `workflow_dispatch` available when you need an on-demand rebuild  

Details: [`.github/workflows/update-advisories.yml`](.github/workflows/update-advisories.yml)

---

## Related work

- [ICS OT Protector](https://github.com/spinfosecurity/ics-ot-protector) — defensive OT/SCADA exposure scanners  
- [Nmap OT howto](https://github.com/spinfosecurity/nmap-ot-howto) — authorized ICS/OT discovery with Nmap  
- Portfolio: [spinfosecurity.github.io](https://spinfosecurity.github.io)

---

## License

MIT — see [LICENSE](LICENSE). Advisory text and CSAF documents remain subject to CISA’s terms; this project aggregates and links, it does not claim ownership of upstream content.
