# Windows 8 Single-User Hardening Guide
**Complete Edition with Commands**

This guide defines a strict, single-user hardening posture for Windows 8.
The operating system is assumed to be end-of-life and insecure by default.
Security is achieved through deliberate reduction, constraint, and
verification rather than feature management.

This document is written for offline use and direct execution. It assumes
no shared users, no remote administration, and no implicit trust in default
system behavior.

---

## Chapter 1 — Threat Model

The system is operated by one trusted user on one machine.

Primary threats include:
- Silent outbound network communication
- Unauthorized background execution
- Persistence via services, tasks, or autoruns
- Data and metadata leakage

Security is achieved through reduction, not complexity.

---

## Chapter 2 — Pre-Hardening Enumeration

Before any changes are made, the system must be observed in its default
state. Enumeration establishes a baseline and prevents accidental dependency
breakage.

Record the following before modification:
- Local users and privilege levels
- Running and configured services
- Network listeners and outbound connections
- Scheduled tasks
- Data locations and storage patterns

### Commands

```cmd
net user
sc query state= all
netstat -ano
schtasks /query /fo LIST /v
```

---

## Chapter 3 — User and Privilege Control

The system must operate under a single local administrator account.
All other user accounts should be removed or disabled.

Remote access paths must be disabled entirely.

Privilege escalation prompts must be enforced at the highest level.
Any action requiring elevation must require explicit approval.

### Commands

```cmd
net user

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" ^
 /v fDenyTSConnections /t REG_DWORD /d 1 /f

reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System ^
 /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 2 /f

reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System ^
 /v EnableLUA /t REG_DWORD /d 1 /f
```

---

## Chapter 4 — Service Reduction

Default services represent latent attack surface.
Services that are not explicitly required should be disabled rather than
managed.

Common classes of removable services include:
- Telemetry and diagnostics
- Error reporting
- Network discovery
- Media and device sharing
- Printing and peripheral support

### Commands

```cmd
sc stop WerSvc
sc config WerSvc start= disabled

sc stop SSDPSRV
sc config SSDPSRV start= disabled

sc config Spooler start= disabled
```

---

## Chapter 5 — Network Constrainment

Network access must be constrained by default.

The firewall must be enabled across all profiles with a default-deny
posture for both inbound and outbound traffic.

Only explicitly required communication should be allowed.

### Commands

```cmd
netsh advfirewall set allprofiles state on

netsh advfirewall set allprofiles firewallpolicy ^
 blockinbound,blockoutbound

netsh advfirewall firewall add rule name="Allow DNS" ^
 dir=out action=allow protocol=UDP remoteport=53
```

---

## Chapter 6 — Scheduled Task Elimination

Scheduled tasks are a primary persistence mechanism.

Tasks that execute maintenance, diagnostics, or updates without direct
user initiation should be disabled or removed.

### Commands

```cmd
schtasks /query /fo LIST /v

schtasks /change /disable /tn ^
 "\Microsoft\Windows\Application Experience\ProgramDataUpdater"
```

---

## Chapter 7 — Data and Metadata Control

The system should minimize retained knowledge of past activity.

Indexing, prefetching, and behavioral caching mechanisms should be disabled
to reduce metadata accumulation.

### Commands

```cmd
sc stop WSearch
sc config WSearch start= disabled

sc stop SysMain
sc config SysMain start= disabled
```

---

## Chapter 8 — Verification

After hardening, the system must be fully re-enumerated.

Verification includes:
- No unexpected network traffic at idle
- No new services or tasks after reboot
- Behavior matches operator expectations

### Commands

```cmd
sc query state= all
netstat -ano
schtasks /query
```

---

## Chapter 9 — Operational Posture

A hardened system requires disciplined operation.

- Software installation is deliberate and infrequent
- Configuration changes are documented
- Convenience features are treated as liabilities
- Verification is repeated after every change

Security is not a one-time event.
