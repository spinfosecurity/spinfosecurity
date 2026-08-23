# Job-hunting site redesign

Truthful OT/ICS portfolio updates for https://spinfosecurity.github.io/

## Changes

- **Brand-first hero** with SpinfoSecurity as the primary signal
- **Light industrial UI** (steel/teal), readable type, motion with reduced-motion support
- **SEO:** stronger titles/descriptions, keywords, Person + WebSite + SoftwareApplication JSON-LD, Open Graph/Twitter
- **Job hunting:** open-to-roles framing, proof-of-work, skills table, role-fit section without inflating titles
- **Accuracy:** TCP reachability / exposure candidates; removes CSV claim; clear is/is-not
- **ICS/OT Advisories:** `/advisories/` triage page + RSS/JSON from CISA CSAF (weekly refresh; see `tools/advisories/`)

## Publish (local as spinfosecurity)

```bash
WORKDIR="$(mktemp -d)"
git clone --depth 1 -b cursor/job-hunting-site-ux-a4c2 \
  https://github.com/spinfosecurity/spinfosecurity.git "$WORKDIR/p" \
  || git clone --depth 1 https://github.com/spinfosecurity/spinfosecurity.git "$WORKDIR/p"
bash "$WORKDIR/p/docs/job-hunting-site/APPLY.sh"
# then create+merge the PR the script prints
```
