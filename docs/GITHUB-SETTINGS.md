# One-time GitHub settings (run as spinfosecurity)

Cloud agents cannot change repository settings or close PRs on `spinfosecurity.github.io` (API 403). Run this locally:

```bash
# Close stale github.io PR
gh pr close 1 --repo spinfosecurity/spinfosecurity.github.io \
  --comment "Stale ICS sync — site already leads with IT Triage Toolkit."

# Hub repo description + homepage + topics
gh repo edit spinfosecurity/spinfosecurity \
  --description "PowerShell IT triage toolkit for Windows endpoints, plus defensive network reachability tooling." \
  --homepage "https://spinfosecurity.github.io" \
  --add-topic powershell \
  --add-topic it-support \
  --add-topic networking \
  --add-topic windows \
  --add-topic troubleshooting \
  --add-topic automation \
  --add-topic portfolio \
  --add-topic cybersecurity

# Optional: drop OT-first topics if you want a cleaner IT Services signal
# gh repo edit spinfosecurity/spinfosecurity --remove-topic ics-security --remove-topic ot-security
```

Verify:

```bash
gh repo view spinfosecurity/spinfosecurity --json description,homepageUrl,repositoryTopics
```
