# Operational Model

This document describes how the server is operated on a day-to-day basis.
It focuses on startup, shutdown, updates, failure handling, and operator
assumptions.

The system favors explicit operator control over automation.


## Operational Philosophy

- The server is designed to be always-on by default
- Sensitive services do not start automatically on boot
- Human presence is required to unlock encrypted storage
- Security is prioritized over convenience

This reduces accidental exposure and limits the impact of unattended failures.


## Boot Behavior

On system boot:
- WireGuard service starts automatically
- Nginx starts automatically
- Immich and related containers **do not start** automatically

At this stage:
- Encrypted storage remains locked
- Application data is inaccessible
- The server exposes no application functionality



## Service Startup Sequence

Service startup is performed manually by the operator.

**Order:**
1. Establish VPN connection to the server
2. Authenticate via SSH **over WireGuard**
3. Run the startup script. The script will:
```
    a Ask the user to enter user password and disk encryption passphrase.
    b. Mount the encrypted partition.
    c. Start Immich using Docker Compose.

```
4. After successful startup, immich will be available on the ip address:port that you configured.
 

**Guarantees:**
- Application data is never mounted unattended
- Services cannot start without explicit authorization


## Normal Operation

During normal operation:
- Immich runs inside Docker containers
- Nginx proxies requests from the WireGuard interface
- Photo storage remains mounted and accessible
- Firewall rules remain static

The system is expected to operate unattended once started.


## Safe Shutdown Procedure

A controlled shutdown procedure is used to protect data integrity.

**Order:**
1. Establish VPN connection to the server
2. Authenticate via SSH **over WireGuard**
3. Run the shutdown script. The script will:
```
    a. Ask the user to enter user password.
    b. Check for active Immich jobs (uploads, processing)
    c. If jobs are active, shutdown is cancelled, otherwise it will continue.
    d. Stop Immich containers.
    e. Unmount encrypted partition.
    f. Re-encrypt storage.

```

This ensures data is not left mounted unnecessarily.

## Power Loss Handling

The server runs on a laptop with a functioning battery, which is always plugged in. The charge level of the battery is set to stop at 60%. This slows down battery degradation.

**Strategy:**

1. Battery level is monitored periodically
2. If battery drops below a defined threshold (currently set to 30%):
3. Immich containers are stopped immediately
4. Encrypted partition is unmounted and re-encrypted
5. System is shut down gracefully

**Design intent:**
- Avoid abrupt power loss during disk writes
- Preserve encrypted-at-rest guarantees



## Update Strategy

Updates are performed manually.

**Rationale:**
- Avoid unintended breaking changes
- Observe community feedback before upgrading
- Maintain operator awareness of system state

**Components updated manually:**
- Ubuntu packages
- Docker images
- Immich releases
- Nginx and WireGuard configurations

No unattended upgrades are enabled.



## Monitoring & Logging

**Battery Monitoring:**
- Battery percentage logged at regular intervals
- Used solely to trigger safe shutdown logic

**Logs:**
- Battery logs stored locally
- No external logging or telemetry



## Failure Scenarios & Recovery

### Unexpected Shutdown
- Storage may remain encrypted
- Manual inspection required before restart
- Immich can be restarted after verification

### Power outage
- Laptop battery will keep the server running for sometime.
- If battery levels go below 30%, safe shutdown is performed

## Operational Assumptions

- Operator availability when starting the server
- Physical security of the deployment environment
- Reliable local network and power under normal conditions

## Limitations

- Single-host deployment
- No automated failover
- No hardware UPS (battery used as mitigation)
- During power outages, the server may remain unreachable even if server is on battery power, as the network would also be down in such scenarios. 
