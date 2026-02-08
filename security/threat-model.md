# Threat Model

This document describes the threat model for the self-hosted Immich deployment.
It defines what is protected, from whom, and which threats are explicitly
accepted as out of scope.

The goal is  to reduce risk through intentional design choices.



## Assets Being Protected

Primary assets:
- Personal photo and video library
- Metadata derived from photos (faces, locations, timestamps)
- User authentication data
- Encrypted storage keys

Secondary assets:
- Host system integrity
- Network topology information
- Service availability



## Security Goals

- Prevent unauthorized remote access
- Minimize exposed attack surface
- Protect data at rest in case of physical theft
- Make accidental exposure difficult



## Threat Actors Considered

### 1. Opportunistic Internet Attackers

**Threat Description:**
An attacker scan the internet to find open ports and running services to try and exploit them.

Examples:
- Port scanners
- Automated exploit bots
- Credential stuffing tools


**Status:**
- Well mitigated

**Mitigation:**
- No public-facing services
- Only WireGuard port exposed (and changed the default port)
- Default-deny firewall posture
- Silent packet drops for unauthorized traffic

### 2. Authenticated but Malicious Remote Attackers

**Threat Description:**
An attacker gains access to the WireGuard tunnel using valid credentials and
attempts to access internal services or pivot further.

Examples:
- Stolen VPN credentials
- Compromised client device with valid VPN access


**Status**
- This risk is acknowledged and accepted for a personal deployment.

**Mitigation:**
- Periodic rotation  and regeneration of WireGuard peer keys
- No automatic peer enrollment; all clients are manually registered
- VPN access required before any service is reachable
- Immich requires separate application-level authentication
- Services bind only to localhost or the WireGuard interface
- No routing from the VPN to the home LAN
- Minimal services exposed even after VPN authentication

**Residual Risk:**
- An attacker with valid VPN credentials gains visibility into VPN-exposed services
- Lateral movement is intentionally limited but not fully eliminated


### 3. Local Network Attackers

**Threat Description:**
An attacker gains access to the local network attempts to access server's internal services.

Examples:
- Compromised device on home Wi-Fi
- Guest devices


**Status:**
- Well mitigated


**Mitigation:**
- No services bound to LAN interface
- No trust placed in local network
- Access requires WireGuard authentication


### 4. Physical Theft

**Threat Description:**
An attacker breaks in and gains access to the physical location of the server and attempts to steal the device.

Examples:
- Laptop stolen while shut down
- Disk removed from system

**Status:**
- Well mitigated

**Mitigation:**
- LUKS-encrypted data partition, automatically unmounted on server shutdown.
- Encryption key not stored on disk
- Manual unlock required


### 5. Physical Access

**Threat Description:**
An attacker breaks in and attempts to gain access to the physical device on which the server is running.

Example:
- Attacker with physical access while services are running.


**Status:**
- Considered out of scope

**Rationale:**
- Server operates in a private residence, and uses Ubuntu's standard security measures.
- Risk accepted due to low likelihood

### 6. Upstream or Supply Chain Compromise

**Threat Description:**
An attacker compromises or poisons upstream software sources, such as operating
system packages, Docker images, or application releases, resulting in malicious
code being introduced during installation or updates.

Examples:
- Supply-chain compromise of Docker images
- Malicious or vulnerable Immich releases
- Vulnerabilities in Ubuntu base packages or bundled utilities

**Status:**
- Well mitigated

**Mitigation:**
- The server runs a minimal Ubuntu LTS installation and only required components were installed.
- Docker images are sourced from official repositories only
- Updates are performed manually and deliberately.
- Before updating, changes are reviewed through:
  - Community feedback
  - Release notes
  - Reported security issues affecting Ubuntu, Nginx, WireGuard, and Immich

**Residual Risk:**
- A targeted or sophisticated supply-chain attack may still bypass these controls
- This risk is acknowledged and accepted for a personal deployment


## Explicitly Out-of-Scope Threats

The following threats are acknowledged but not actively defended against:

- Kernel-level 0-day exploits
- Nation-state level attackers
- Hardware firmware backdoors
- Side-channel attacks

Mitigations for these threats would exceed the risk profile and goals of a
personal deployment.



## Trust Assumptions

- WireGuard cryptography is trusted
- Ubuntu LTS receives timely security patches
- Docker provides reasonable isolation
- Immich upstream is generally non-malicious
- Home physical security is adequate


## Attack Surface Summary
```
| Component        | Exposure Level |
|------------------|----------------|
| WireGuard        | Minimal        |
| Nginx            | VPN-only       |
| Immich           | Localhost-only |
| Databases        | Docker-internal|
| SSH              | VPN-only       |

No component except wireguard is exposed directly to the public internet.
```

## Defense-in-Depth Strategy

Security controls are layered:

1. Network isolation (VPN-only access)
2. Firewall enforcement (default deny)
3. Service binding restrictions
4. Container isolation
5. Encrypted storage at rest
6. Manual operational control

Failure of a single layer does not immediately expose data.



## Known Weaknesses

- Manual acceptance of self-signed TLS certificates
- No intrusion detection system
- No hardware-backed secure enclave
- Single-host deployment (no redundancy for services)

These are accepted trade-offs for simplicity and control.


## Risk Acceptance Statement

This system is designed for a personal, privacy-focused use case.

Security decisions prioritize:
- Reducing accidental exposure
- Making remote compromise difficult
- Protecting data at rest