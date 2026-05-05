## ADDED Requirements

### Requirement: Check for Certbot installation
The script SHALL check if Certbot is installed on the system.

#### Scenario: Certbot already installed
- **WHEN** the dependency check runs
- **THEN** the system detects Certbot in PATH and reports "Certbot: Installed (version X.Y.Z)"

#### Scenario: Certbot not installed
- **WHEN** the dependency check runs and Certbot is not found
- **THEN** the system reports "Certbot: Not found - will install" and proceeds to auto-installation

### Requirement: Auto-install Certbot via snap
The script SHALL attempt to install Certbot using snap package manager as the primary method.

#### Scenario: Snap install succeeds
- **WHEN** Certbot is missing and snap is available
- **THEN** the system runs `snap install certbot --classic` and verifies installation completion with exit code 0

#### Scenario: Snap install fails
- **WHEN** snap install fails (snap unavailable or permission denied)
- **THEN** the system logs the error and falls back to apt installation

### Requirement: Auto-install Certbot via apt
The script SHALL fall back to apt package manager if snap installation fails or is unavailable.

#### Scenario: Apt install succeeds
- **WHEN** snap is unavailable and apt is available
- **THEN** the system runs `apt update && apt install certbot -y` and verifies installation

#### Scenario: Apt install fails
- **WHEN** both snap and apt fail
- **THEN** the system exits with error message "Failed to install Certbot" and provides manual installation instructions

### Requirement: Check for DNS tools (dig/nslookup)
The script SHALL verify that DNS lookup tools are available.

#### Scenario: dig is available
- **WHEN** dependency check runs
- **THEN** the system detects `dig` in PATH and uses it for DNS verification

#### Scenario: dig unavailable, nslookup available
- **WHEN** dig is not found but nslookup is available
- **THEN** the system falls back to `nslookup` for DNS queries

#### Scenario: Both DNS tools unavailable
- **WHEN** neither dig nor nslookup is available
- **THEN** the system exits with error message "Required DNS tools not found" and prompts for manual installation

### Requirement: Check for port checking tools (netstat/ss)
The script SHALL verify that port checking utilities are available.

#### Scenario: ss is available
- **WHEN** dependency check runs
- **THEN** the system detects `ss` and uses it for port availability checks

#### Scenario: ss unavailable, netstat available
- **WHEN** ss is not found but netstat is available
- **THEN** the system falls back to `netstat` for port queries

### Requirement: Display dependency status
The script SHALL report the status of all critical dependencies at startup.

#### Scenario: All dependencies met
- **WHEN** all required tools are installed
- **THEN** the system displays "Dependencies: ✓ All required tools available" in green

#### Scenario: Dependencies auto-installed
- **WHEN** auto-installation completes successfully
- **THEN** the system displays "Dependencies: ✓ Certbot installed successfully" and continues execution
