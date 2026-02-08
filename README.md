# Secure Immich Server
A self-hosted personal photo cloud built using **Immich**. 

The system is designed with a **zero public exposure** model. The system runs on a repurposed gaming laptop from 2019, and is accessible **only over a VPN connection**, with all services bound to localhost and protected by a
default-deny firewall.

Although this project prioritizes **security over convenience**, it's still fairly simple to use once set up correctly.

## Why did I make it?

Just like everyone else, I also have a large personal photo library, which I stored on clod. I wanted to move away from these
third-party cloud storages because:

- I started having some privacy concerns about trusting third party services with my personal data.
- These services started increasing their subscription prices, which made me uncomfortable.


I did stop using cloud storage solutions, and started saving my media on hard drives, but it came with new challenges.
- I had to maintain multiple copies of data,to prevent losing it in case of hard drive failure/corruption.
- Manually decrypting data, copying it, and then encrypting it again made the process of backing up very time consuming and tedious.
- I also faced issues like data duplication and accidental loss due to my own negligence.

The goal was to build a **private and centralized media backup system** that I fully
control, both technically and operationally.



## High-Level Security Goals

- **No public HTTP, HTTPS, or SSH exposure**
- **Minimum (preferably zero) dependency on third party services**
- **VPN-only access** using WireGuard
- Services **bound to localhost** wherever possible
- Explicit and minimal firewall rules (default deny)
- Encryption at rest for photo data
- Manual and deliberate update strategy



## Architecture Overview

**Host:**  
- Dedicated old gaming laptop (repurposed as a server)
- Runs Ubuntu LTS
- Always plugged in.
- Battery charge level locked at 60%, which acts as a built-in UPS

**Core components:**
- Immich (Docker Compose)
- Nginx reverse proxy
- WireGuard VPN
- UFW firewall
- LUKS-encrypted data partition

**Access flow:**
```
Client (phone)
  │   
  ▼   
 VPN  (wireguard)
  │   
  ▼   
Nginx (listening only on VPN IP)
  │   
  ▼   
Immich (bound to localhost)
```

No service is reachable without first authenticating to the VPN.


## Key Design Decisions

### VPN-Only Access
- WireGuard is the **only exposed service** on the public interface
- Split-tunnel configuration: only selected app traffic will route via VPN
- SSH and web access are reachable **only over wireguard**

### Reverse Proxy
- Nginx listens only on the WireGuard interface
- Forwards traffic to Immich bound on `127.0.0.1`
- TLS enabled using self-signed certificates.

### Container Isolation
- Immich deployed using Docker Compose
- Uses a docker bridge network (`immich_default`)
- Only Immich server port is published, and **only to localhost**
- No containers use host networking

### Firewall Strategy
- UFW with default deny for inbound, outbound, and routed traffic
- Explicit allow rules only for:
  - WireGuard
  - SSH over wireguard
  - Required container egress
- Firewall assumes the host is **hostile-by-default**

### Encryption at Rest
- Photo data stored on a LUKS-encrypted partition
- Partition is manually unlocked during server startup
- Protects data in case of physical theft or disk removal

### Startup & Shutdown Control
- Immich does **not** start automatically on boot
- Manual startup script:
  - Unlocks encrypted partition
  - Mounts storage
  - Starts Immich via Docker Compose
- Shutdown script:
  - Checks for active Immich jobs
  - Gracefully stops containers
  - Unmounts and re-encrypts the partition

### Power Loss Handling
- Laptop battery capped at 60% and always plugged in
- Acts as a built-in UPS
- Battery monitoring script triggers safe shutdown when battery is in discharging state and battery percentage drops below 30%.



## Monitoring & Operations

- Battery percentage checked every 5 minutes via cron
- Logs stored locally for operational awareness
- Updates are performed **manually** by the user to reduce supply-chain risk.



## Threat Model Summary

### In scope
- Unauthorized remote access
- Accidental service exposure
- Data exposure from lost or stolen powered-off hardware
- Misconfiguration leading to unintended access

### Out of scope
- Kernel-level zero-day exploits
- Compromised upstream Docker images
- Malicious upstream Immich updates


## Repository Structure

```
docs/ → Architecture, security model, and operational docs
scripts/ → Startup, shutdown, and monitoring scripts
diagrams/ → Architecture and network flow diagrams
security/ → Threat model and attack surface analysis
```

## Status

- Actively used as a personal photo cloud
- Stable for day-to-day usage
- Continuously reviewed for improvements



## Future Improvements

- External UPS
- RAID-based redundancy
- Key-based SSH authentication
- Certificate trust distribution instead of manual TLS warnings
- Formalized backup rotation

