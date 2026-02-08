# System Architecture

This document describes the technical architecture of the self-hosted Immich
photo cloud, including network flow, service isolation, and access boundaries.

The architecture is designed to minimize attack surface while maintaining
usability for personal devices.


## Physical Host

- Repurposed consumer laptop
- Ubuntu LTS
- Always-on operation
- Built-in battery used as a basic UPS
- Encrypted storage for photo data

The laptop is treated as a **dedicated server**, not a general-purpose machine.



## Network Model

### Public Interface

- Only a single UDP port is exposed:
  - WireGuard VPN
- No public HTTP, HTTPS, or SSH ports
- No port forwarding beyond WireGuard

The public interface is assumed to be hostile.



### VPN Layer (WireGuard)

- WireGuard provides the sole access path into the system
- Split-tunnel configuration:
  - Only selected application traffic routes through the VPN
  - No full-tunnel routing (`0.0.0.0/0` is not used)

Once connected:
- The client can reach the server’s VPN IP
- SSH and web services are accessible only over wireguard

WireGuard acts as the **primary authentication and network boundary**.



## Internal Network Flow
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
        │   
        ▼  
Docker bridge network


No service is reachable without first authenticating to the VPN.

```

## Reverse Proxy Layer (Nginx)

- Listens only on the WireGuard interface
- Does not bind to the public interface
- Terminates TLS using self-signed certificates
- Forwards traffic to Immich on localhost

Even though the VPN tunnel already encrypts data during transit and the VPN and Immich server are on the same physical device, TLS is used just for good measure


## Application Layer (Immich)

- Deployed via Docker Compose
- Containers include:
  - Immich server
  - PostgreSQL
  - Redis
  - Machine learning service

### Port Exposure

- Immich server port published only to `127.0.0.1`
- No container ports are published to the public interface
- Databases are not exposed outside the Docker network



## Firewall Model

- Default deny for inbound traffic
- Default deny for forwarded traffic
- Explicit allow rules only for:
  - WireGuard
  - SSH over VPN
  - Required internal communication

The firewall assumes:
> “Anything not explicitly allowed is unsafe.”



## Storage Architecture

- Photo data stored on a LUKS-encrypted partition
- Partition remains locked by default
- Manually unlocked during controlled startup
- Unmounted and re-locked during shutdown

This protects data if:
- The device is stolen
- The disk is removed
- The system is powered off



## Startup & Shutdown Flow

### Startup
1. Encrypted partition unlocked
2. Storage mounted
3. Docker services started
4. Immich becomes available over VPN

### Shutdown
1. Check for active Immich processes
2. Gracefully stop containers
3. Unmount encrypted storage
4. Re-lock partition

Both Startup and Shutdown flows are automated using scripts, but they have to be triggered manually. The startup script requires the user to enter the decryption key to unlock the partition.



## Power Loss Considerations

- Battery charge capped at 60%
- Battery level monitored periodically
- Graceful shutdown triggered below a defined threshold

This reduces risk of data corruption and ensures safe shutdown of all services and the physical device itself.


## Design Philosophy

This architecture follows:
- Explicit control over automation of tasks
- Security is prioritized over convenience
- Every exposed service is intentional.
