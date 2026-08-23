# ICS/OT advisory aggregator

Builds a maintainer-focused advisories page + RSS feed from the official
**CISA CSAF OT** feed on GitHub (`cisagov/CSAF`).

CISA’s public RSS URLs often return HTTP 403 to automated clients. CSAF is the
reliable machine-readable source.

## Generate locally

```bash
python3 tools/advisories/aggregate.py
```

Outputs (under `docs/job-hunting-site/advisories/`):

| File | Purpose |
|------|---------|
| `index.html` | Human triage page |
| `feed.xml` | RSS subscribe |
| `advisories.json` | Machine-readable snapshot |
| `advisories.css` / `advisories.js` | Page assets |

## Schedule

`.github/workflows/update-advisories.yml` runs **once per week** (Monday),
regenerates outputs, and commits only when the advisory set changes. Manual runs
use **workflow_dispatch**. The aggregator also rate-limits outbound fetches so we
do not hammer GitHub’s raw content CDN.
