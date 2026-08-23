# ICS OT Protector cutover checklist

Keep **separate**:
- `spinfosecurity/spinfosecurity` (this portfolio README)
- `spinfosecurity/spinfosecurity.github.io` (public site)
- sundaystack (private; out of scope)

## Goal

One tooling repo: `spinfosecurity/ics-ot-protector`  
Archive: `BAS-Guardian`, `Energy-Grid-Protector`, `Rail-OT-Protector`

## 1. Apply EGP v1.1.0 merge to the monorepo

```bash
git clone https://github.com/spinfosecurity/water-utility-protector.git
cd water-utility-protector
git checkout -b cursor/merge-egp-v1.1-a4c2
git am path/to/0001-feat-energy-grid-merge-standalone-EGP-v1.1.0-into-mo.patch
# or: git apply path/to/....patch && git commit
git push -u origin HEAD
```

Patch file in this folder:
`0001-feat-energy-grid-merge-standalone-EGP-v1.1.0-into-mo.patch`

What it merges from standalone Energy-Grid-Protector v1.1.0:
- PROFINET RT/RTA (34962, 34963) and OPC UA (4840) in sector YAML/JSON
- TcpClient `Dispose()` in PowerShell `Test-TcpPort`
- host:port finding deduplication in PowerShell and Bash
- version bump to EGP 1.1.0

## 2. Archive legacy repos + rename monorepo

Requires org-admin `gh` auth on `spinfosecurity`:

```bash
cd water-utility-protector   # after merge is on main
./scripts/admin/archive-legacy-repos.sh
```

This:
1. Pushes archive READMEs to the three legacy repos
2. Archives those repos
3. Renames `water-utility-protector` → `ics-ot-protector`

## 3. Update portfolio site

Draft HTML lives in `github-io/` in this folder. Apply against
`spinfosecurity/spinfosecurity.github.io` after the rename (or keep
`water-utility-protector` links until rename completes).

## 4. Update this README

After rename, change featured links from
`water-utility-protector` → `ics-ot-protector`.
