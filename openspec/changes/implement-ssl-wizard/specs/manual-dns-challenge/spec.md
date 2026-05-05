## ADDED Requirements

### Requirement: Initiate manual DNS challenge mode
The script SHALL invoke Certbot in manual DNS challenge mode for wildcard certificates.

#### Scenario: Manual challenge mode started
- **WHEN** user selects wildcard certificate option
- **THEN** system executes `certbot certonly --manual --preferred-challenges dns --domain *.example.com` and pauses for user action

#### Scenario: Challenge mode fails to start
- **WHEN** Certbot exits with error during DNS challenge initialization
- **THEN** system displays error message and prompts user to retry or switch to different certificate type

### Requirement: Display DNS challenge token
The script SHALL clearly present the TXT record value that must be added to DNS.

#### Scenario: Challenge token displayed
- **WHEN** Certbot generates the DNS challenge
- **THEN** system displays a formatted message:
  ```
  Add this TXT record to your DNS provider:
  _acme-challenge.example.com = <random_base64_token>
  ```

#### Scenario: Token copied to clipboard (optional)
- **WHEN** token is generated and system supports clipboard (`xclip`, `xsel`)
- **THEN** system offers "Copy to clipboard? (y/n)" and copies token if user confirms

### Requirement: Pause and wait for user DNS configuration
The script SHALL pause execution and wait for user confirmation before resuming DNS validation.

#### Scenario: Pause for DNS record entry
- **WHEN** challenge token is displayed
- **THEN** system displays: "Press Enter after adding the TXT record and waiting 30 seconds for propagation" and waits for user input

#### Scenario: User confirms record is set
- **WHEN** user presses Enter
- **THEN** system resumes Certbot validation process

#### Scenario: Optional delay before validation
- **WHEN** user presses Enter
- **THEN** system optionally prompts: "Waiting for DNS propagation... (usually 1-5 minutes)" and can apply a user-configurable delay

### Requirement: Handle DNS validation timeout
The script SHALL handle cases where DNS validation cannot confirm the TXT record within a reasonable time.

#### Scenario: DNS validation succeeds
- **WHEN** Certbot detects the TXT record in DNS within timeout window
- **THEN** certificate issuance proceeds and TXT record can be removed

#### Scenario: DNS validation fails due to timeout
- **WHEN** Certbot cannot find the TXT record after timeout
- **THEN** system displays: "DNS validation timeout. TXT record may not have propagated. Retry? (y/n)"

#### Scenario: User retries DNS validation
- **WHEN** user selects "y" at the retry prompt
- **THEN** system returns to pause state and waits for user to confirm DNS is ready

### Requirement: Provide DNS troubleshooting guidance
The script SHALL offer helpful troubleshooting information if DNS validation fails.

#### Scenario: Troubleshooting guidance displayed
- **WHEN** DNS validation fails
- **THEN** system displays suggestions:
  - "Verify TXT record is exactly as shown above (including underscore)"
  - "Use `dig _acme-challenge.example.com TXT` to check DNS propagation"
  - "DNS changes can take 1-10 minutes to propagate globally"
  - "Retry after waiting longer, or abort and use standard domain certificate instead"

#### Scenario: User runs provided dig command
- **WHEN** user checks DNS manually using provided command
- **THEN** system offers to resume validation when user confirms record is visible

### Requirement: Implement real-time DNS record validation
The script SHALL continuously check DNS records in real-time to verify user has correctly entered the challenge token.

#### Scenario: Real-time DNS check initiated
- **WHEN** user confirms DNS record is set
- **THEN** system begins polling DNS for the TXT record at `_acme-challenge.<domain>` every 5 seconds

#### Scenario: DNS record detected successfully
- **WHEN** DNS query finds the required TXT record with matching token value
- **THEN** system displays "✓ DNS record verified! Proceeding with validation..." and continues with Certbot

#### Scenario: DNS record not yet propagated
- **WHEN** DNS record is not found in initial queries
- **THEN** system displays "⏳ Checking DNS propagation... (Attempt X/Y)" with countdown timer

#### Scenario: DNS record has wrong value
- **WHEN** DNS query finds a TXT record at the location but with incorrect value
- **THEN** system displays "✗ DNS record found but value is incorrect. Expected: <token>, Found: <wrong_value>"

#### Scenario: Real-time validation timeout
- **WHEN** DNS polling reaches maximum attempts (e.g., 30 attempts over 2-3 minutes)
- **THEN** system displays "DNS validation timeout. Allow more propagation time? (y/n)" and offers retry or manual verification

#### Scenario: User chooses manual verification
- **WHEN** user selects manual DNS check during polling
- **THEN** system displays `dig _acme-challenge.example.com TXT` command and waits for user to confirm record is visible

### Requirement: Display DNS verification checklist
The script SHALL provide a step-by-step checklist for DNS record entry with validation status.

#### Scenario: DNS entry checklist displayed
- **WHEN** DNS challenge is initiated
- **THEN** system displays:
  ```
  DNS Entry Checklist:
  [ ] 1. Log into your DNS provider
  [ ] 2. Add TXT record to _acme-challenge.example.com
  [ ] 3. Set value to: <token>
  [ ] 4. Set TTL to 300 or minimum
  [ ] 5. Save changes
  [ ] 6. Press Enter when ready (system will verify automatically)
  ```

#### Scenario: Checklist updates as steps complete
- **WHEN** user completes each step
- **THEN** system allows marking steps complete (optional) or proceeds with real-time validation

### Requirement: Support multiple DNS provider instructions
The script SHALL display provider-specific DNS entry instructions.

#### Scenario: Provider selection offered
- **WHEN** DNS challenge starts
- **THEN** system offers: "Which DNS provider are you using?" with options like:
  - Cloudflare
  - Route53 (AWS)
  - DigitalOcean
  - Namecheap
  - GoDaddy
  - Other/Manual

#### Scenario: Provider-specific instructions displayed
- **WHEN** user selects a provider (e.g., Cloudflare)
- **THEN** system displays Cloudflare-specific instructions:
  ```
  Cloudflare DNS Instructions:
  1. Go to https://dash.cloudflare.com/
  2. Select your domain
  3. Go to DNS Records
  4. Click "Add Record"
  5. Type: TXT
  6. Name: _acme-challenge.example.com
  7. Content (Value): <token>
  8. TTL: 1 minute (300 seconds)
  9. Proxy status: DNS only (gray cloud)
  10. Click "Save"
  ```

### Requirement: Clear OS DNS cache before each check
The script SHALL flush the system DNS cache before polling for TXT record to ensure fresh lookups.

#### Scenario: Cache cleared before TXT record polling
- **WHEN** real-time DNS polling for TXT records begins
- **THEN** system clears OS DNS cache before each 5-second polling attempt
- This ensures newly-added TXT records are detected immediately

#### Scenario: Cache flush methods attempted in order
- **WHEN** cache clearing is needed
- **THEN** system tries methods in order of preference:
  1. `resolvectl flush-caches` (systemd-resolved, modern)
  2. `systemctl restart systemd-resolved` (systemd-resolved fallback)
  3. `nscd -i hosts` (nscd daemon)
  4. `service nscd restart` (nscd service fallback)
  5. Continue without flushing if all unavailable

#### Scenario: Cache clear logged in detail
- **WHEN** each polling cycle occurs
- **THEN** log records:
  ```
  [14:22:03] Polling attempt 1/36
  [14:22:03] DNS Cache: Flushed via resolvectl
  [14:22:03] TXT Query: _acme-challenge.example.com [FRESH]
  [14:22:03] Result: Not found (checking in 5s)
  [14:22:08] Polling attempt 2/36
  [14:22:08] DNS Cache: Flushed via resolvectl
  [14:22:08] TXT Query: _acme-challenge.example.com [FRESH]
  [14:22:08] Result: Found! Value matches token
  ```

#### Scenario: Propagation timing uses cached data awareness
- **WHEN** DNS record is detected after cache clearing
- **THEN** system displays:
  ```
  ✓ TXT Record Detected!
  Time to detect: 47 seconds (after DNS cache clearing)
  Token: aB3xYz9kL2mNoPqRsT1uVwXyZaBcDeF4gHiJk
  Status: Fresh (verified with cache flush)
  ```

### Requirement: Log DNS challenge details
The script SHALL record all DNS challenge attempts, confirmations, and results in the log file.

#### Scenario: Challenge logged with full details
- **WHEN** manual DNS challenge occurs
- **THEN** log file contains:
  - Challenge token value
  - Timestamp of challenge initiation
  - User confirmation timestamp
  - Real-time validation attempts and results
  - DNS propagation time (if successful)
  - Any retry attempts and their outcomes
  - Final validation result (success/failure)
