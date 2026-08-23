# Optional: bump Node 20 actions on ics-ot-advisories

The Pages deploy warning is from Node.js 20-targeted Actions.
Use `docs/ics-ot-advisories-pages.yml` as `.github/workflows/pages.yml`.

For `update-advisories.yml`, change:

```yaml
uses: actions/checkout@v4
```

to:

```yaml
uses: actions/checkout@v5
```
