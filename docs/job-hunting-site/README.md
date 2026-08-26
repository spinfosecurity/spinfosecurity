# Job-hunting site

Portfolio for https://spinfosecurity.github.io/ — framed for IT services / technical support screens, with public OT/ICS projects as proof of scripting, networking, and docs.

## Visual system

- Aerospace-ops light UI: steel/graphite + teal signal, Space Grotesk + IBM Plex
- Full-bleed hero plane, slim nav, open sections (rules over heavy cards)
- Motion: grid drift, orbit, rise — respects `prefers-reduced-motion`

## Publish (local as spinfosecurity)

```bash
WORKDIR="$(mktemp -d)"
git clone --depth 1 https://github.com/spinfosecurity/spinfosecurity.git "$WORKDIR/p"
bash "$WORKDIR/p/docs/job-hunting-site/APPLY.sh"
# then create+merge the PR using the real branch name the script prints
```
