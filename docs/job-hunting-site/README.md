# Portfolio site

Source for https://spinfosecurity.github.io/

Primary: PowerShell IT Triage Toolkit.  
Also: ICS/OT scanners as scripting + networking + docs.

## Publish (as spinfosecurity)

```bash
WORKDIR="$(mktemp -d)"
git clone --depth 1 https://github.com/spinfosecurity/spinfosecurity.git "$WORKDIR/p"
bash "$WORKDIR/p/docs/job-hunting-site/APPLY.sh"
# then create+merge the PR using the real branch name the script prints
```
