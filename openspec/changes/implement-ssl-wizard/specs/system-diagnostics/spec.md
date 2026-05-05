## ADDED Requirements

### Requirement: Display server IP address
The script SHALL retrieve and display the server's public IPv4 address at startup.

#### Scenario: Successful IP detection
- **WHEN** the script starts
- **THEN** the system retrieves the public IP (via `curl ifconfig.me` or equivalent) and displays it in the initial summary

#### Scenario: IP detection fails gracefully
- **WHEN** the public IP cannot be retrieved (network unavailable)
- **THEN** the system displays a warning message and continues with "IP: unknown" without blocking execution

### Requirement: Display OS version information
The script SHALL detect and display the Ubuntu/Debian OS version and kernel version.

#### Scenario: Successful OS detection
- **WHEN** the script starts on Ubuntu 22.04 or 24.04
- **THEN** the system displays "OS: Ubuntu 24.04 LTS" or similar in the initial summary

#### Scenario: Unsupported OS detection
- **WHEN** the script runs on a non-Debian/Ubuntu system
- **THEN** the system displays an error message and exits with a helpful recommendation

### Requirement: Check port 80 and 443 availability
The script SHALL verify whether ports 80 and 443 are available (not in use by other processes).

#### Scenario: Ports available
- **WHEN** the script performs port availability check
- **THEN** the system reports "Port 80: Available" and "Port 443: Available" in green

#### Scenario: Port 80 occupied
- **WHEN** a process is bound to port 80
- **THEN** the system reports "Port 80: Occupied by <process_name> (PID: <pid>)" in yellow/red

#### Scenario: Port 443 occupied
- **WHEN** a process is bound to port 443
- **THEN** the system reports "Port 443: Occupied by <process_name> (PID: <pid>)" in yellow/red and informs user this may affect certificate storage but not issuance

### Requirement: Display summary at startup
The script SHALL present a summary of system diagnostics before prompting for domain input.

#### Scenario: Summary format
- **WHEN** diagnostics collection completes
- **THEN** the system displays a formatted table or section containing: Public IP, OS version, Kernel version, Port 80 status, Port 443 status, and Certbot presence
