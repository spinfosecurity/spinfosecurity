# Practitioner notes

## Intended use

Use the live page or RSS feed as a **triage aid** when you maintain ICS/OT or
related medical-device equipment in scope for CISA ICSA/ICSMA notices.

Recommended workflow:

1. Search your vendor / product family on the live page  
2. Open Critical and High items first  
3. Confirm affected versions on the official CISA advisory  
4. Follow your plant change-control process for patches or compensating controls  

## Automation consumers

- RSS: `https://spinfosecurity.github.io/ics-ot-advisories/feed.xml`  
- JSON: `https://spinfosecurity.github.io/ics-ot-advisories/advisories.json`  

JSON fields include `id`, `title`, `published`, `severity`, `cvss`, `vendors`,
`products`, `cves`, and `url` (canonical CISA web page).

## Operational limits

- Snapshot of **recent** advisories (generator `--limit`, default 120), not the full historic corpus  
- Weekly refresh by default  
- Does not replace vendor PSIRT mailings or your internal CMDB matching  

See [ATTRIBUTION.md](../ATTRIBUTION.md).
