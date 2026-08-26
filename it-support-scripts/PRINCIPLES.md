# Principles

Goal: **minimize time until someone is unblocked.**

| Script | Why it exists |
|--------|----------------|
| Why-Broken | Rank causes — don’t dump `ipconfig` into a ticket |
| Dns-Truth | Local DNS can lie; compare to an independent answer |
| Auth-Clock | Many “bad password” cases are clock skew |
| Reach-Matrix | Separate network path failure from application failure |
| Stack-Reset | Change DNS/DHCP, then prove the delta — don’t hide issues under reboot |
| Escalate-Smart | Senior time is scarce — one page, one concrete ask |

## Rules

1. Optimize unblocked people, not ticket cosmetics  
2. End triage with **#1 cause + suggested fix**  
3. Prove changes with before/after checks  
4. Escalate with impact, what you tried, evidence, and one ask  
5. Keep tools simple enough to run and explain during real support work  
