# Talking points (Google Meet / interview)

Use this as your cheat sheet. Plain language only.

---

### Why-Broken.ps1
**What I’d say:**  
“Most tickets aren’t mysterious. The laptop clock is wrong, DNS is lying, the disk is full, there’s no gateway, or HTTPS is blocked. This script checks those in order, ranks the failures, and tells me the first fix — so I don’t open a ticket until I’m stuck.”

**If they ask how:**  
“It samples time from an HTTPS Date header, resolves a known site and checks for private IPs, checks free space on C:, looks for a default gateway, and tries HTTPS out.”

---

### Dns-Truth.ps1
**What I’d say:**  
“Windows DNS isn’t always honest — hotel Wi-Fi and some middleboxes return fake answers. I ask the same name two ways: through Windows, and through Cloudflare DNS over HTTPS. If Windows hands back a private IP, or a random fake name suddenly resolves, we found a hijack or captive portal.”

**If they ask why DoH:**  
“It’s an independent path. If the local resolver and Cloudflare disagree in a dangerous way, I trust the independent one.”

---

### Auth-Clock.ps1
**What I’d say:**  
“People swear their password is right. Often the PC clock drifted. Kerberos and a lot of SSO break when skew is over a couple minutes. This compares local time to a few public sites’ Date headers. If it’s bad, `-Fix` asks Windows Time to resync.”

**If they ask the threshold:**  
“Under 30 seconds is fine. Over 120 seconds and auth gets flaky — that’s when I fix before resetting passwords.”

---

### Reach-Matrix.ps1
**What I’d say:**  
“User says Slack is broken. Is it Slack, or can they not reach anything? I load a short list of critical hosts and ports and test TCP in one shot. All open → not a path problem. All blocked → network. One blocked → that service or its ACL.”

**If they ask about the list:**  
“`targets.conf` — GitHub, IdP, chat, whatever matters for that company. Example file ships with the repo.”

---

### Stack-Reset.ps1
**What I’d say:**  
“Rebooting hides the problem. I measure ping and HTTPS, clear the DNS cache, renew DHCP, measure again, and show the before/after. If it’s healthy, we’re done. If not, I escalate with proof — not ‘I rebooted it.’”

---

### Escalate-Smart.ps1
**What I’d say:**  
“Senior engineers don’t want a zip of logs. This runs the probes, writes a one-page markdown brief: who’s hurt, the top hypothesis, what I already tried, and one concrete ask. Paste it into the ticket.”

---

## 60-second demo arc

1. “Here’s Why-Broken — ranked cause, not a dump.”  
2. “Auth-Clock — wrong password is often wrong time.”  
3. “Reach-Matrix — path vs app.”  
4. “Escalate-Smart — how I brief L3.”
