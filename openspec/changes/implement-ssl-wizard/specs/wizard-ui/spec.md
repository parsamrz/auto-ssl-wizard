## ADDED Requirements

### Requirement: Display challenge type selection menu
The script SHALL present all available ACME challenge methods with clear descriptions.

#### Scenario: Challenge menu displayed
- **WHEN** user is about to request a certificate
- **THEN** system displays:
  ```
  Select validation challenge method:
  [1] DNS TXT Record Challenge (Manual)
      → For all certificate types (single, multi, wildcard)
      → You manually add DNS TXT record
      → Best for: Wildcard certs, manual control
  
  [2] HTTP-01 Challenge (Requires Port 80)
      → For single/multi-domain certificates only
      → Requires port 80 to be available
      → Best for: Single domain certs, automated flows
  
  [3] ACME DNS API (Advanced)
      → For automation with DNS provider integration
      → Requires API credentials (not yet configured)
      → Best for: Repeated issuances
  
  Enter choice [1-3]:
  ```

#### Scenario: Challenge-specific instructions displayed
- **WHEN** user selects a challenge type
- **THEN** system displays detailed instructions for that method

### Requirement: Display complete DNS record data structure
The script SHALL show formatted DNS record details required for validation.

#### Scenario: DNS TXT record structure box
- **WHEN** DNS TXT challenge is selected
- **THEN** system displays formatted box:
  ```
  ╔════════════════════════════════════════════════════════╗
  ║         DNS TXT Record Required (CRITICAL)             ║
  ╠════════════════════════════════════════════════════════╣
  ║ Record Type:   TXT                                     ║
  ║ Name/Host:     _acme-challenge.example.com            ║
  ║ Value:         aB3xYz9kL2mNoPqRsT1uVwXyZaBcDeF4gHiJk  ║
  ║ TTL:           300 (or minimum for your provider)      ║
  ║ Full Entry:    _acme-challenge.example.com TXT "..."   ║
  ╠════════════════════════════════════════════════════════╣
  ║ 📋 Copy to clipboard? (y/n)                            ║
  ╚════════════════════════════════════════════════════════╝
  ```

#### Scenario: Current A record status display
- **WHEN** HTTP-01 challenge is selected
- **THEN** system displays:
  ```
  Current DNS A Record Status:
  ┌──────────────────────────────────┐
  │ Domain:     example.com          │
  │ Expected:   203.0.113.42         │
  │ Current:    203.0.113.42  ✓      │
  │ Status:     MATCHES - Ready!     │
  └──────────────────────────────────┘
  ```

### Requirement: Display DNS entry checklist
The script SHALL provide step-by-step guidance for DNS record entry.

#### Scenario: DNS entry checklist displayed
- **WHEN** manual DNS challenge is initiated
- **THEN** system shows:
  ```
  DNS Entry Checklist:
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [ ] Step 1: Log into your DNS provider
  [ ] Step 2: Navigate to DNS Records section
  [ ] Step 3: Create new TXT record
  [ ] Step 4: Set Name: _acme-challenge.example.com
  [ ] Step 5: Set Value: <token>
  [ ] Step 6: Set TTL: 300 seconds
  [ ] Step 7: Save changes
  [ ] Step 8: Wait 30-60 seconds for propagation
  [ ] Step 9: Press Enter when ready
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ```

### Requirement: Display provider-specific DNS instructions
The script SHALL show tailored instructions for different DNS providers.

#### Scenario: Provider selection menu
- **WHEN** DNS challenge begins
- **THEN** system offers:
  ```
  Which DNS provider are you using?
  [1] Cloudflare
  [2] Amazon Route 53 (AWS)
  [3] DigitalOcean
  [4] Namecheap
  [5] GoDaddy
  [6] Other / Manual Entry
  Enter choice [1-6]:
  ```

#### Scenario: Cloudflare instructions displayed
- **WHEN** user selects Cloudflare
- **THEN** system displays:
  ```
  Cloudflare DNS Instructions:
  ────────────────────────────────────────────
  1. Go to https://dash.cloudflare.com/
  2. Select domain: example.com
  3. Click "DNS" in sidebar
  4. Click "+ Add Record"
  5. Type: TXT
  6. Name: _acme-challenge
  7. Content: <token_value>
  8. TTL: Auto or 300
  9. Proxy: ☐ Proxied  ☑ DNS only (MUST BE DNS ONLY)
  10. Click "Save"
  
  ⏱ Allow 1-5 minutes for propagation
  🔍 Verify: dig _acme-challenge.example.com TXT
  ────────────────────────────────────────────
  ```

### Requirement: Display real-time DNS validation progress
The script SHALL show polling progress during DNS validation.

#### Scenario: DNS polling progress displayed
- **WHEN** real-time DNS validation is in progress
- **THEN** system displays:
  ```
  Checking DNS propagation...
  [████████░░░░░░░░] Attempt 5/36 (50s elapsed)
  
  Expected: aB3xYz9kL2mNoPqRsT1uVwXyZaBcDeF4gHiJk
  Current:  Not found (checking again in 5s...)
  ```

#### Scenario: DNS validation successful
- **WHEN** DNS record is found and matches
- **THEN** system displays:
  ```
  ✓ DNS Record Verified!
  
  Record found: _acme-challenge.example.com
  Value matches: aB3xYz9kL2mNoPqRsT1uVwXyZaBcDeF4gHiJk
  Propagation time: 47 seconds
  
  Proceeding with certificate validation...
  ```

#### Scenario: DNS validation timeout with options
- **WHEN** DNS polling times out
- **THEN** system displays:
  ```
  ⏱ DNS validation timeout (3 minutes)
  
  The DNS record was not detected. This could mean:
  - DNS changes haven't propagated yet (common)
  - Record value is incorrect
  - DNS provider is caching old records
  
  Options:
  [1] Continue waiting (wait another 2 minutes)
  [2] Skip to manual verification (you run dig)
  [3] Abort and retry later
  
  Enter choice [1-3]:
  ```
The script SHALL use ANSI color codes to provide visual feedback on operations.

#### Scenario: Success message in green
- **WHEN** an operation completes successfully (e.g., DNS verified, port cleared)
- **THEN** system displays message in green (ANSI code \033[32m) with prefix "✓" or "SUCCESS"

#### Scenario: Warning message in yellow
- **WHEN** a condition warrants user attention (e.g., DNS mismatch, rate limit approaching)
- **THEN** system displays message in yellow (ANSI code \033[33m) with prefix "⚠" or "WARNING"

#### Scenario: Error message in red
- **WHEN** an operation fails or requires immediate action (e.g., Certbot failure, port occupied)
- **THEN** system displays message in red (ANSI code \033[31m) with prefix "✗" or "ERROR"

#### Scenario: Neutral information in default color
- **WHEN** system displays general information (prompts, summaries, logs)
- **THEN** system uses default terminal color for readability

### Requirement: Display clear menu prompts for user choices
The script SHALL present numbered or lettered options for user selection.

#### Scenario: Certificate type selection menu
- **WHEN** user is prompted to choose certificate type
- **THEN** system displays:
  ```
  Select certificate type:
  [1] Single Domain (example.com)
  [2] Multi-Domain (example.com, www.example.com)
  [3] Wildcard (*.example.com)
  Enter choice [1-3]:
  ```

#### Scenario: Invalid selection handling
- **WHEN** user enters invalid choice
- **THEN** system displays "Invalid selection. Please enter [1-3]:" and re-prompts

### Requirement: Format system diagnostic summary
The script SHALL present a structured summary of system status at startup.

#### Scenario: Diagnostic summary displayed
- **WHEN** script starts
- **THEN** system displays formatted table or section:
  ```
  ========== SSL Wizard - System Diagnostics ==========
  Public IP:       203.0.113.42
  OS:              Ubuntu 24.04 LTS
  Kernel:          6.1.0-20-generic
  Port 80:         ✓ Available
  Port 443:        ✓ Available
  Certbot:         ✓ Installed (v2.6.0)
  DNS Tool:        ✓ dig available
  ==================================================
  ```

### Requirement: Display real-time operation progress
The script SHALL show progress indicators during long-running operations.

#### Scenario: Dependency installation progress
- **WHEN** Certbot is being installed
- **THEN** system displays: "Installing Certbot... [████████░░] 80%" or similar progress bar

#### Scenario: DNS check progress
- **WHEN** DNS validation is running
- **THEN** system displays: "Checking DNS for example.com..." with spinner or dots indicator

#### Scenario: Certificate issuance progress
- **WHEN** Certbot is processing certificate request
- **THEN** system displays: "Requesting certificate from Let's Encrypt... (this may take 30-60 seconds)"

### Requirement: Accept yes/no user confirmations
The script SHALL parse yes/no responses with flexible input handling.

#### Scenario: User confirms with lowercase 'y'
- **WHEN** system prompts "Proceed with certificate issuance? (y/n):" and user enters 'y'
- **THEN** system interprets as yes and proceeds

#### Scenario: User confirms with uppercase 'Y'
- **WHEN** user enters 'Y' or 'yes' or 'YES'
- **THEN** system treats all variants as affirmative

#### Scenario: User denies with 'n' or 'no'
- **WHEN** user enters 'n', 'N', 'no', or 'NO'
- **THEN** system interprets as negative and handles accordingly

#### Scenario: Invalid confirmation input
- **WHEN** user enters value other than yes/no
- **THEN** system displays "Please enter 'y' or 'n':" and re-prompts

### Requirement: Display help and usage information
The script SHALL provide accessible help for users running without arguments.

#### Scenario: Help displayed on --help or no args
- **WHEN** user runs `./ssl-wizard.sh --help` or `./ssl-wizard.sh` without args
- **THEN** system displays usage information including:
  - Brief description of purpose
  - Command-line options (if any)
  - Examples of common workflows
  - Contact/documentation link

### Requirement: Log all user interactions
The script SHALL record all user inputs and prompts for troubleshooting.

#### Scenario: User interaction logged
- **WHEN** user makes a choice or enters input
- **THEN** log file records: timestamp, prompt text, user input, and action taken

### Requirement: Display final success message
The script SHALL show a clear completion summary upon successful certificate issuance.

#### Scenario: Success message displayed
- **WHEN** certificate issuance and file organization complete
- **THEN** system displays:
  ```
  ✓ Certificate issuance completed successfully!
  
  Certificate files saved to: ./certs-out/example.com/
  - Certificate:  ./certs-out/example.com/live/cert.pem
  - Private Key:  ./certs-out/example.com/live/privkey.pem
  - Full Chain:   ./certs-out/example.com/live/fullchain.pem
  - Log File:     ./certs-out/example.com/logs/issuance.log
  
  Next steps: Copy these files to your web server configuration.
  ```

### Requirement: Display error exit message
The script SHALL provide clear information when exiting due to error.

#### Scenario: Error exit message displayed
- **WHEN** script exits due to error
- **THEN** system displays:
  ```
  ✗ Certificate issuance failed!
  
  Error: <specific error message>
  Log file: ./certs-out/<domain>/logs/issuance.log
  
  For troubleshooting: Review log file or re-run the wizard.
  ```
