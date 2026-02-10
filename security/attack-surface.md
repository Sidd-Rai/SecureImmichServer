# Attack Surface Analysis

This document identifies and analyzes the exposed attack surfaces of the
self-hosted Immich deployment.

The purpose is to clearly enumerate what is reachable, under what conditions,
and what assumptions are made about each exposed component.



## Overview

The system follows a **deny-by-default** philosophy.
No application services are directly exposed to the public internet.

All access paths are controlled and documented.



## Network-Level Attack Surface

### 1. Public Internet

**Exposed:**
- WireGuard UDP port.
- The default Wireguard UDP port is 51820 which was changed in the configs to improve security.

**Not Exposed:**
- SSH
- HTTP/HTTPS
- Nginx
- Immich
- Docker services

**Notes:**
- Unauthorized packets are silently dropped
- No service banners or application responses are visible externally
- Attack surface is limited to **WireGuard’s protocol implementation**



### 2. WireGuard VPN Interface

**Exposed (VPN-authenticated only):**
- SSH service
- Nginx reverse proxy
- Immich application (via Nginx)

**Not Exposed:**
- Home LAN devices
- Non-essential system services
- Docker internal networks

**Controls:**
- Split tunnel configuration
- Manually registered peers only
- No automatic client enrollment
- No routing from VPN to LAN



## Host-Level Attack Surface

### 3. SSH Access

**Exposure:**
- Accessible only via WireGuard interface

**Authentication:**
- key-based authentication
- Root login disabled

**Risk Considerations:**
- Relies on WireGuard as the primary access control



### 4. Nginx Reverse Proxy

**Exposure:**
- Listens only on WireGuard IP
- Not reachable from LAN or public interfaces

**Function:**
- Proxies requests to Immich on localhost

**TLS Model:**
- Self-signed certificates
- Manual trust acceptance on client devices



## Application-Level Attack Surface

### 5. Immich Application

**Exposure:**
- Bound to `127.0.0.1` only
- Accessible exclusively through Nginx

**Authentication:**
- Separate application-level credentials required

**Data Access:**
- Photo storage mounted from encrypted partition
- No direct file system exposure



### 6. Docker Runtime & Networks

**Docker Networks:**
- Custom bridge network (`immich_default`)
- Containers isolated from host network

**Port Publishing:**
- Immich server published to `127.0.0.1` only
- Databases and internal services not exposed to host or network

**Risk Considerations:**
- Container escape remains a theoretical risk



## Storage Attack Surface

### 7. Encrypted Storage

**At Rest:**
- LUKS-encrypted partition
- Encryption key not stored on disk

**At Runtime:**
- Partition mounted only after manual unlock
- Unmounted and re-encrypted during shutdown

**Limitations:**
- Data is accessible while the server is running, assuming someone has access to the server's credentials



## Operational Attack Surface

### 8. Startup & Shutdown Scripts

**Exposure:**
- Scripts are executed locally by the operator
- Not network-accessible

**Risk Considerations:**
- Script misuse could impact availability



### 9. Power Loss Handling

**Mitigation:**
- Battery-backed operation
- Automatic shutdown before critical battery levels

**Residual Risk:**
- Sudden hardware failure during write operations



## Summary
```
| Surface           | Exposure Scope        | Risk Level    |
|-------------------|-----------------------|---------------|
| WireGuard         | Public (UDP only)     | Low           |
| SSH               | VPN-only              | Low           |
| Nginx             | VPN-only              | Low           |
| Immich            | Localhost via proxy   | Low           |
| Docker internals  | Local only            | Low           |
| Encrypted storage | Runtime only          | Medium        |
```

## Design Intent

The system intentionally trades:
- Convenience for reduced exposure
- Automation for explicit operator control
- Feature richness for auditability

