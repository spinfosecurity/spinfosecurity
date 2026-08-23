#!/usr/bin/env bash
# Apply portfolio site + monorepo description updates after ICS OT cutover.
# Requires: gh authenticated as spinfosecurity with repo write access.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "==> Checking gh auth (expect spinfosecurity)..."
gh auth status
ACTIVE="$(gh api user --jq .login)"
if [[ "$ACTIVE" != "spinfosecurity" ]]; then
  echo "Active account is '$ACTIVE'. Switch with: gh auth switch -u spinfosecurity" >&2
  exit 1
fi

DESC='Unified critical-infrastructure OT/SCADA scanners (water, energy, BAS, rail) in PowerShell and Bash. Authorized defensive exposure discovery only.'
echo "==> Updating ics-ot-protector description..."
gh api -X PATCH repos/spinfosecurity/ics-ot-protector \
  -f description="$DESC" \
  -f homepage='https://spinfosecurity.github.io/projects/ics-ot-protector/' >/dev/null

echo "==> Cloning spinfosecurity.github.io..."
git clone --depth 1 https://github.com/spinfosecurity/spinfosecurity.github.io.git "$WORK/site"
cd "$WORK/site"
BRANCH="cursor/site-monorepo-cutover-$(date +%Y%m%d)"
git checkout -b "$BRANCH"

cp "$ROOT/github-io/index.html" index.html
mkdir -p projects/ics-ot-protector
cp "$ROOT/github-io/projects-ics-ot-protector-index.html" projects/ics-ot-protector/index.html

for slug in water-utility-protector bas-guardian energy-grid-protector rail-ot-protector; do
  mkdir -p "projects/$slug"
  cp "$ROOT/github-io/redirect-${slug}.html" "projects/$slug/index.html"
done

cat > sitemap.xml << 'XML'
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://spinfosecurity.github.io/</loc>
    <changefreq>weekly</changefreq>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://spinfosecurity.github.io/projects/ics-ot-protector/</loc>
    <changefreq>monthly</changefreq>
    <priority>0.9</priority>
  </url>
  <url>
    <loc>https://spinfosecurity.github.io/projects/water-utility-protector/</loc>
    <changefreq>yearly</changefreq>
    <priority>0.3</priority>
  </url>
  <url>
    <loc>https://spinfosecurity.github.io/projects/bas-guardian/</loc>
    <changefreq>yearly</changefreq>
    <priority>0.3</priority>
  </url>
  <url>
    <loc>https://spinfosecurity.github.io/projects/energy-grid-protector/</loc>
    <changefreq>yearly</changefreq>
    <priority>0.3</priority>
  </url>
  <url>
    <loc>https://spinfosecurity.github.io/projects/rail-ot-protector/</loc>
    <changefreq>yearly</changefreq>
    <priority>0.3</priority>
  </url>
</urlset>
XML

git add -A
git commit -m "$(cat <<'MSG'
docs: point portfolio site at ics-ot-protector monorepo

Feature ICS OT Protector as the single project, add a dedicated project
page, and redirect former sector project URLs to the monorepo page.
MSG
)"
git push -u origin HEAD

echo ""
echo "Pushed branch $BRANCH"
echo "Open a PR:"
echo "  gh pr create --repo spinfosecurity/spinfosecurity.github.io --fill"
echo "Or merge locally if you prefer pushing straight to main."
