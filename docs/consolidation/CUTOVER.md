# Post-cutover remaining steps

## Verified complete

- [x] Monorepo renamed to https://github.com/spinfosecurity/ics-ot-protector
- [x] `BAS-Guardian`, `Energy-Grid-Protector`, `Rail-OT-Protector` archived with README pointers
- [x] EGP v1.1.0 (PROFINET / OPC UA + dedupe) present on monorepo main
- [x] Portfolio README updated to `ics-ot-protector` links (this repo)

## Still needed (run locally as `spinfosecurity`)

This Cloud Agent cannot push to `ics-ot-protector` or `spinfosecurity.github.io`.
On a machine where `gh auth status` shows **spinfosecurity**, run:

```bash
# From a clone of this portfolio branch, or download the script:
bash docs/consolidation/apply-github-io-update.sh
```

That script will:

1. Update the monorepo GitHub description to the unified portfolio wording
2. Replace `spinfosecurity.github.io` homepage with the monorepo-first layout
3. Add `/projects/ics-ot-protector/`
4. Turn old project pages into redirects
5. Refresh `sitemap.xml`

Do **not** touch sundaystack.
