# Safe use — Nmap on ICS/OT

Use the [howto](./README.md) only when all of the following are true:

1. You have **written authorization** covering targets, methods, and timing.
2. An **OT process owner** is aware and reachable during the window.
3. You have tested the same Nmap options in a **lab** first.
4. You have an **abort plan** (stop scan, restore comms path, escalate).
5. Findings go to **remediation / segmentation**, not exploitation.

Abort immediately if controllers show rising faults, lost I/O, or unexpected CPU/network alarms.

Scan artifacts (`*.xml`, `*.gnmap`, `*.nmap`, target lists) stay out of public repositories.
