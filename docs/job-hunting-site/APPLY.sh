#!/usr/bin/env bash
# Publish the job-hunting site redesign to spinfosecurity.github.io
# Requires: gh authenticated as spinfosecurity
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "==> Auth check..."
gh auth status
ACTIVE="$(gh api user --jq .login)"
[[ "$ACTIVE" == "spinfosecurity" ]] || { echo "Switch to spinfosecurity: gh auth switch -u spinfosecurity" >&2; exit 1; }

echo "==> Cloning site..."
git clone --depth 1 https://github.com/spinfosecurity/spinfosecurity.github.io.git "$WORK/site"
cd "$WORK/site"
BRANCH="cursor/job-hunting-site-ux-$(date +%Y%m%d)"
git checkout -b "$BRANCH"

cp "$ROOT/index.html" "$ROOT/styles.css" "$ROOT/404.html" "$ROOT/favicon.svg" "$ROOT/robots.txt" "$ROOT/sitemap.xml" .
cp "$ROOT/.nojekyll" . 2>/dev/null || touch .nojekyll
mkdir -p advisories
cp "$ROOT/advisories/index.html" "$ROOT/advisories/advisories.css" "$ROOT/advisories/advisories.js" \
   "$ROOT/advisories/advisories.json" "$ROOT/advisories/feed.xml" advisories/
mkdir -p projects/ics-ot-protector
cp "$ROOT/projects/ics-ot-protector/index.html" projects/ics-ot-protector/index.html
for slug in water-utility-protector bas-guardian energy-grid-protector rail-ot-protector; do
  mkdir -p "projects/$slug"
  cp "$ROOT/projects/$slug/index.html" "projects/$slug/index.html"
done

git add -A
git commit -m "$(cat <<'MSG'
Add ICS/OT advisories aggregate page and RSS feed

Publish the CISA CSAF-backed advisories triage page, JSON snapshot,
and RSS feed alongside the portfolio site.
MSG
)"
git push -u origin HEAD

echo ""
echo "Pushed $BRANCH"
echo "Create + merge PR:"
echo "  gh pr create --repo spinfosecurity/spinfosecurity.github.io --base main --head $BRANCH --title \"Add ICS/OT advisories page and RSS feed\" --body \"Maintainer-focused CISA ICS/OT advisory aggregate with RSS and JSON.\""
echo "  gh pr merge --repo spinfosecurity/spinfosecurity.github.io --merge --delete-branch"
