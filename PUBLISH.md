# Create the empty public repo, then run:

#   gh repo create spinfosecurity/ics-ot-advisories --public --source=. --remote=origin --push
#
# Or if the empty repo already exists:
#
#   git init
#   git add -A
#   git commit -m "Initial commit: ICS/OT advisories aggregator"
#   git branch -M main
#   git remote add origin https://github.com/spinfosecurity/ics-ot-advisories.git
#   git push -u origin main
#
# Then enable GitHub Pages: Settings → Pages → Source = GitHub Actions
# (workflow: .github/workflows/pages.yml)
#
# Suggested About description:
#   CISA ICS/OT advisories in one place — searchable triage UI, RSS, and JSON for equipment maintainers.
#
# Suggested homepage URL:
#   https://spinfosecurity.github.io/ics-ot-advisories/
#
# Suggested topics: see TOPICS.md
