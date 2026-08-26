# Job-hunting site redesign

Truthful portfolio updates for https://spinfosecurity.github.io/

## Changes

- **Brand-first hero** with SpinfoSecurity as the primary signal
- **IT-services-aware framing:** scripting, network troubleshooting, documentation, and security hygiene—without inventing helpdesk job history
- **Light industrial UI** (steel/teal), readable type, motion with reduced-motion support
- **SEO:** stronger titles/descriptions, keywords, Person + WebSite + SoftwareApplication JSON-LD, Open Graph/Twitter
- **Job hunting:** open-to-roles framing (IT operations / technical support / security-aware automation), proof-of-work, skills table without inflating titles
- **Accuracy:** TCP reachability / exposure candidates; clear is/is-not
- **ICS/OT Advisories:** dedicated SEO repo + site at [ics-ot-advisories](https://github.com/spinfosecurity/ics-ot-advisories) ([live](https://spinfosecurity.github.io/ics-ot-advisories/)); portfolio `/advisories/` redirects there

## Publish (local as spinfosecurity)

```bash
WORKDIR="$(mktemp -d)"
git clone --depth 1 https://github.com/spinfosecurity/spinfosecurity.git "$WORKDIR/p"
bash "$WORKDIR/p/docs/job-hunting-site/APPLY.sh"
# then create+merge the PR the script prints
```
