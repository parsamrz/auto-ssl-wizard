## ADDED Requirements

### Requirement: Verify DNS A record points to server
The script SHALL check that the provided domain's A record resolves to the server's public IP address.

#### Scenario: DNS matches server IP
- **WHEN** user provides a domain and DNS validation runs
- **THEN** the system queries the A record for that domain and confirms it matches the server's public IP, displaying "DNS: ✓ Correct" in green

#### Scenario: DNS points to different IP
- **WHEN** user provides a domain with A record pointing to a different IP
- **THEN** the system displays "DNS: ✗ Points to <different_ip> instead of <server_ip>" in red and prompts user to update DNS or abort

#### Scenario: DNS record not found
- **WHEN** the domain has no A record
- **THEN** the system displays "DNS: ✗ No A record found for <domain>" in red and prompts user to create the record

### Requirement: Check authoritative nameservers
The script SHALL retrieve and display the authoritative nameservers for the provided domain.

#### Scenario: Nameservers retrieved
- **WHEN** DNS validation runs
- **THEN** the system queries NS records and displays "Nameservers: ns1.example.com, ns2.example.com" in the diagnostics summary

#### Scenario: Nameserver lookup fails
- **WHEN** NS record lookup fails (DNS server unreachable)
- **THEN** the system logs the error, displays a warning, and continues without blocking

### Requirement: Support comma-separated domain input
The script SHALL accept multiple domains in a single input and validate each one.

#### Scenario: Multiple domains provided
- **WHEN** user inputs "example.com,www.example.com"
- **THEN** the system parses the list and validates DNS for both domains sequentially

#### Scenario: DNS check fails for one domain in list
- **WHEN** user provides multiple domains and one fails DNS validation
- **WHEN** the system displays the error and offers options: "Retry", "Skip this domain", or "Abort"

### Requirement: Allow user override for DNS mismatches
The script SHALL permit users to proceed despite DNS mismatches when explicitly confirmed.

#### Scenario: User confirms mismatch warning
- **WHEN** DNS does not match and user is prompted to proceed
- **THEN** the system displays a clear warning: "⚠ Domain DNS does not match. Continue anyway? (y/n)" and logs the user's choice

#### Scenario: User aborts due to DNS mismatch
- **WHEN** user selects abort at the DNS warning prompt
- **THEN** the system exits gracefully with message "Aborted by user due to DNS mismatch"

### Requirement: Real-time DNS validation with polling
The script SHALL continuously verify DNS records during validation with automatic polling.

#### Scenario: Real-time A record validation
- **WHEN** DNS validation begins for a domain
- **THEN** system queries A record every 5 seconds and displays progress:
  ```
  Validating DNS for example.com...
  [████████░░] Attempt 3/10 - Expected: 203.0.113.42
  Current: 203.0.113.42 ✓ Match found!
  ```

#### Scenario: Propagation time displayed
- **WHEN** DNS record becomes available after initial queries fail
- **THEN** system displays "DNS record propagated in X seconds"

#### Scenario: Validation with timeout and manual check option
- **WHEN** DNS validation reaches timeout threshold
- **THEN** system displays: "DNS not yet propagated. Provide manual check? (y/n)"
- If yes, user runs `dig example.com A` and reports result

### Requirement: Display DNS record structure during validation
The script SHALL show the expected vs. actual DNS values during validation.

#### Scenario: DNS mismatch details displayed
- **WHEN** DNS validation fails
- **THEN** system displays detailed comparison:
  ```
  DNS Validation Failed:
  
  Expected Record:
  Domain:  example.com
  Type:    A
  Value:   203.0.113.42
  
  Actual Record:
  Domain:  example.com
  Type:    A
  Value:   198.51.100.55
  
  Action: Update DNS or select override
  ```

#### Scenario: Multiple DNS servers checked
- **WHEN** user opts for thorough validation
- **THEN** system queries multiple public DNS servers (8.8.8.8, 1.1.1.1) and reports consistency

### Requirement: Clear OS DNS cache before each check
The script SHALL flush the system DNS cache before each DNS query to ensure fresh lookups and avoid stale cached records.

#### Scenario: DNS cache cleared before validation
- **WHEN** DNS validation begins
- **THEN** system clears the OS DNS cache using appropriate mechanism for the system:
  - systemd-resolved: `systemctl restart systemd-resolved`
  - nscd: `nscd -i hosts` or `service nscd restart`
  - resolvectl: `resolvectl flush-caches`
  - Logs: "DNS cache flushed successfully"

#### Scenario: Cache clearing succeeds
- **WHEN** cache flush command completes successfully
- **THEN** subsequent DNS queries are guaranteed to be fresh from authoritative nameservers
- Log entry: `[INFO] 14:22:03 DNS cache cleared | Method: systemd-resolved | Status: Success`

#### Scenario: Cache clearing fails gracefully
- **WHEN** cache flush attempt fails (no DNS cache service running)
- **THEN** system logs warning and continues with DNS query anyway
- Display: "⚠ DNS cache flush unavailable (using regular query)" in yellow

#### Scenario: DNS cache cleared between polling attempts
- **WHEN** real-time DNS polling is running (every 5 seconds)
- **THEN** system clears DNS cache before each polling query to get fresh results
- All polling attempts show fresh data (not OS-cached stale records)

#### Scenario: Cache clear status logged
- **WHEN** each DNS validation cycle occurs
- **THEN** log file records:
  - Cache flush method attempted
  - Success/failure status
  - Timestamp
  - Result (cache cleared or unavailable)
  Example log:
  ```
  [14:22:03] DNS Cache Flush: Method=systemd-resolved, Status=Success
  [14:22:03] DNS Query for example.com: 203.0.113.42 (FRESH - not cached)
  [14:22:08] DNS Cache Flush: Method=systemd-resolved, Status=Success
  [14:22:08] DNS Query for example.com: 203.0.113.42 (FRESH - verified)
  ```

#### Scenario: Multiple cache clearing methods attempted
- **WHEN** primary cache flush method is unavailable
- **THEN** system attempts fallback methods:
  1. Try: `systemctl restart systemd-resolved`
  2. Try: `resolvectl flush-caches`
  3. Try: `nscd -i hosts`
  4. Try: `service nscd restart`
  5. If all fail: Log warning and continue without flushing
