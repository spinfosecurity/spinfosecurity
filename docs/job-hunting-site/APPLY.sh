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
mkdir -p projects/ics-ot-protector projects/nmap-ot-howto
cp "$ROOT/projects/ics-ot-protector/index.html" projects/ics-ot-protector/index.html
cp "$ROOT/projects/nmap-ot-howto/index.html" projects/nmap-ot-howto/index.html
for slug in water-utility-protector bas-guardian energy-grid-protector rail-ot-protector; do
  mkdir -p "projects/$slug"
  cp "$ROOT/projects/$slug/index.html" "projects/$slug/index.html"
done

git add -A
git commit -m "$(cat <<'MSG'
Improve job-hunting portfolio UX, SEO, and truthful messaging

Light industrial visual system, SpinfoSecurity-first hero, clearer
proof-of-work and skills sections, and accurate TCP-reachability claims.
MSG
)"
git push -u origin HEAD

echo ""
echo "Pushed $BRANCH"
echo "Create + merge PR:"
echo "  gh pr create --repo spinfosecurity/spinfosecurity.github.io --base main --head $BRANCH --title \"Improve job-hunting portfolio UX and SEO\" --body \"Truthful OT/ICS messaging, stronger SEO, clearer UI/UX.\""
echo "  gh pr merge --repo spinfosecurity/spinfosecurity.github.io --merge --delete-branch"
