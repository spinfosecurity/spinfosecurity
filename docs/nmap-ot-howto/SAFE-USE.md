# Safe use

Use **Nmap OT Howto** only on networks you are authorized to assess.

## Before every scan

- [ ] Written scope: targets, methods, rate limits, contacts  
- [ ] OT / process owner aware and reachable  
- [ ] Abort plan agreed  
- [ ] Findings routed to remediation — not exploitation  

## Abort if

- Controllers fault or CPU / network alarms spike  
- I/O or process communications drop  
- Operators report impact  

## Do not

- Scan without permission  
- Publish live target lists or raw scan XML to public repos  
- Run exploit, brute-force, or DoS-oriented scripts against production controllers  

Back to the guide: [README.md](README.md)
