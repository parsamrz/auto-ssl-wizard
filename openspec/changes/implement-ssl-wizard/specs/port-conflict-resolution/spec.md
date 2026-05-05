## ADDED Requirements

### Requirement: Detect process occupying Port 80
The script SHALL identify any process bound to port 80 before attempting standalone certificate issuance.

#### Scenario: Port 80 is free
- **WHEN** port availability check runs
- **THEN** the system confirms "Port 80: Available" and proceeds without prompting for termination

#### Scenario: Port 80 occupied by single process
- **WHEN** a process (e.g., nginx, apache2) occupies port 80
- **THEN** the system displays "Port 80 occupied by nginx (PID: 1234)" and prompts user to terminate it

#### Scenario: Port 80 occupied by multiple processes
- **WHEN** multiple processes are bound to port 80
- **THEN** the system displays all processes and their PIDs, allowing user to select which to terminate

### Requirement: Prompt user to terminate conflicting process
The script SHALL ask the user for permission before terminating any process on port 80.

#### Scenario: User confirms termination
- **WHEN** script displays port conflict and user confirms "Terminate nginx? (y/n)"
- **THEN** the system attempts graceful termination and verifies the port is now free

#### Scenario: User declines termination
- **WHEN** user selects "n" at the termination prompt
- **THEN** the system exits with message "Cannot proceed with port 80 occupied"

### Requirement: Attempt graceful process termination
The script SHALL use SIGTERM (kill -15) before attempting SIGKILL (kill -9).

#### Scenario: Graceful termination succeeds
- **WHEN** system sends SIGTERM to the process
- **THEN** the process terminates gracefully and port 80 becomes available within 5 seconds

#### Scenario: Graceful termination fails, force kill succeeds
- **WHEN** SIGTERM does not terminate the process within 5 seconds
- **THEN** the system sends SIGKILL (kill -9) and verifies port 80 is free

#### Scenario: Force kill fails
- **WHEN** even kill -9 fails to terminate the process
- **THEN** the system logs the error, displays "Failed to kill process <pid>", and exits with error code

### Requirement: Verify port is free after termination
The script SHALL confirm that port 80 is available after attempting process termination.

#### Scenario: Port confirmed free
- **WHEN** termination completes
- **THEN** the system re-checks port 80 status and displays "Port 80: ✓ Now available"

#### Scenario: Port still occupied after termination
- **WHEN** port 80 is still occupied after kill attempts
- **THEN** the system displays error and prompts user to manually investigate or abort

### Requirement: Log termination actions
The script SHALL record all port conflict detection and process termination actions in the log file.

#### Scenario: Termination logged
- **WHEN** a process is terminated
- **THEN** the log file contains: timestamp, process name, PID, termination method (SIGTERM/SIGKILL), and result
