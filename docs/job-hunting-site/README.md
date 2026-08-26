# Job-hunting site

Portfolio for https://spinfosecurity.github.io/ — framed for **IT Services Technician** screens.

Primary proof: PowerShell IT Triage Toolkit.  
Secondary proof: ICS/OT scanners as scripting + networking + docs.

## Publish (local as spinfosecurity)

```bash
WORKDIR="$(mktemp -d)"
git clone --depth 1 https://github.com/spinfosecurity/spinfosecurity.git "$WORKDIR/p"
bash "$WORKDIR/p/docs/job-hunting-site/APPLY.sh"
# then create+merge the PR using the real branch name the script prints
```
