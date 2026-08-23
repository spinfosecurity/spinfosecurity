# Attribution & limits

## Upstream source

This project aggregates **public** Industrial Control Systems advisories published by the
U.S. Cybersecurity and Infrastructure Security Agency (CISA) in **CSAF** form:

- Feed index: [cisagov/CSAF — OT TLP:WHITE](https://github.com/cisagov/CSAF/tree/develop/csaf_files/OT/white)
- ROLIE feed JSON: `cisa-csaf-ot-feed-tlp-white.json`

CISA remains the authoritative publisher. Every rendered item links to the corresponding
CISA web advisory when available.

## Why not CISA’s public RSS URLs?

Endpoints such as `https://www.cisa.gov/cybersecurity-advisories/ics-advisories.xml` frequently
return **HTTP 403** to automated clients. CSAF on GitHub is the reliable machine-readable path
CISA provides for the same OT advisory corpus.

## What this is / is not

| Is | Is not |
|----|--------|
| A convenience triage UI + RSS/JSON over public CSAF | A replacement for CISA or vendor bulletins |
| Open-source defensive automation portfolio work | A vulnerability database claiming completeness |
| Weekly refreshed snapshot of recent advisories | Real-time alerting with SLA guarantees |

## Refresh policy

Scheduled aggregation runs **weekly** with low concurrency and a short delay between
outbound fetches. Manual runs are available via GitHub Actions `workflow_dispatch`.

## License of this repository

MIT for the aggregator code and site chrome. Upstream CSAF/advisory content remains subject
to CISA’s terms; we do not claim ownership of those documents.
