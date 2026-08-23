# Safe use — ICS/OT Nmap assessments

Use **Nmap for ICS/OT Security** only on networks you are authorized to assess.

## Before every scan

- [ ] Written scope: targets, methods, rate limits, contacts  
- [ ] OT / process owner aware and reachable  
- [ ] Abort plan agreed  
- [ ] Findings routed to remediation and segmentation — not exploitation  

## Abort if

- Controllers fault or CPU / network alarms spike  
- I/O or process communications drop  
- Operators report impact  

## Do not

- Scan without permission  
- Publish live target lists or raw scan XML to public repos  
- Run exploit, brute-force, or DoS-oriented scripts against production controllers  

This guide supports **defensive ICS/OT exposure discovery** (Modbus, EtherNet/IP, S7, DNP3, BACnet, IEC 104, and related protocols).

Back to the guide: [README.md](README.md) · Employers: [FOR-EMPLOYERS.md](FOR-EMPLOYERS.md)
