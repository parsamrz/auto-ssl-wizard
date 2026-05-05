## ADDED Requirements

### Requirement: Issue single-domain certificate
The script SHALL use Certbot to issue an SSL certificate for a single domain via standalone mode.

#### Scenario: Successful single domain issuance
- **WHEN** user selects "Single Domain" and provides "example.com"
- **THEN** system runs `certbot certonly --standalone --domain example.com` and receives certificate files

#### Scenario: Single domain issuance fails
- **WHEN** Certbot returns a non-zero exit code during issuance
- **THEN** system captures the error message, logs it, and displays "Certificate issuance failed: <error>" to user

### Requirement: Issue multi-domain certificate
The script SHALL issue a certificate covering multiple domains in a single request.

#### Scenario: Successful multi-domain issuance
- **WHEN** user provides "example.com,www.example.com"
- **THEN** system runs `certbot certonly --standalone --domain example.com --domain www.example.com` and receives single certificate covering both domains

#### Scenario: Multi-domain with one invalid domain
- **WHEN** one of the provided domains fails DNS validation before issuance
- **THEN** system offers option to issue cert for remaining domains or abort

### Requirement: Issue wildcard certificate via manual DNS challenge
The script SHALL support wildcard certificate issuance by prompting user for manual DNS TXT record entry.

#### Scenario: Wildcard issuance initiated
- **WHEN** user selects "Wildcard Certificate" and provides "example.com"
- **THEN** system runs `certbot certonly --manual --preferred-challenges dns --domain *.example.com` and pauses for DNS configuration

#### Scenario: System displays required TXT record
- **WHEN** Certbot requires DNS challenge
- **THEN** system displays: "Add this TXT record to your DNS provider: _acme-challenge.example.com = <random_token>" with clear instructions

#### Scenario: User confirms DNS record is set
- **WHEN** user has added the TXT record and presses Enter to continue
- **THEN** system resumes Certbot DNS validation and completes certificate issuance

#### Scenario: DNS validation fails for wildcard
- **WHEN** Certbot cannot validate the DNS TXT record
- **THEN** system displays error message with troubleshooting tips and allows retry

### Requirement: Allow user to select challenge type
The script SHALL present all available ACME challenges and let user select the preferred method.

#### Scenario: Challenge type menu displayed
- **WHEN** user is about to request a certificate
- **THEN** system displays interactive challenge type selection menu:
  ```
  Select validation challenge method:
  [1] DNS TXT Record Challenge (Manual) - For wildcard & all domain types
  [2] HTTP-01 Challenge (Port 80) - For single/multi-domain only
  [3] ACME DNS API (if configured) - Advanced option for automation
  Enter choice [1-3]:
  ```

#### Scenario: User selects DNS TXT challenge
- **WHEN** user chooses [1] DNS TXT Record Challenge
- **THEN** system displays detailed instructions and displays the exact record structure needed

#### Scenario: User selects HTTP-01 challenge
- **WHEN** user chooses [2] HTTP-01 Challenge
- **THEN** system verifies Port 80 is available, displays current DNS A record status, and proceeds with standalone mode

#### Scenario: Challenge selection updates Certbot flags
- **WHEN** challenge type is selected
- **THEN** system adjusts Certbot command: `--manual --preferred-challenges dns` for TXT, or standard `--standalone` for HTTP-01

### Requirement: Display complete DNS record data structure
The script SHALL show the exact DNS record format and values required for validation.

#### Scenario: Full DNS TXT record structure displayed
- **WHEN** DNS TXT challenge is initiated
- **THEN** system displays complete record format:
  ```
  ╔════════════════════════════════════════════════════╗
  ║ DNS TXT Record Required                             ║
  ╠════════════════════════════════════════════════════╣
  ║ Type:       TXT                                    ║
  ║ Name/Host:  _acme-challenge.example.com           ║
  ║ Value:      <base64_encoded_token>                ║
  ║ TTL:        300 (or minimum supported by provider) ║
  ║ Full:       _acme-challenge.example.com TXT "..."  ║
  ╚════════════════════════════════════════════════════╝
  ```

#### Scenario: Current A record status displayed
- **WHEN** HTTP-01 challenge is selected
- **THEN** system displays current DNS A record status:
  ```
  Current DNS A Record Status:
  Domain:      example.com
  Expected:    <server_public_ip>
  Current:     <resolved_from_dns> 
  Status:      ✓ Matches (or ✗ Mismatch - update DNS before continuing)
  ```

#### Scenario: Wildcard DNS structure for multiple subdomains
- **WHEN** user requests *.example.com certificate
- **THEN** system displays wildcard-specific record:
  ```
  DNS Record for Wildcard:
  Name:   _acme-challenge.example.com  (NOT _acme-challenge.*.example.com)
  Type:   TXT
  Value:  <challenge_token>
  Note:   Single record covers *.example.com
  ```

### Requirement: Handle Let's Encrypt rate limits
The script SHALL warn users about rate limiting and prevent accidental duplicate requests.

#### Scenario: Rate limit warning
- **WHEN** user attempts to issue a certificate for a domain that was issued recently
- **THEN** system displays: "⚠ You may have issued a cert for this domain recently. Let's Encrypt limits: 50 certs/domain per 3 hours. Continue? (y/n)"

#### Scenario: User acknowledges rate limit risk
- **WHEN** user selects "y" at the rate limit warning
- **THEN** system logs the acknowledgment and proceeds with issuance

#### Scenario: Rate limit hit (168-hour lockout)
- **WHEN** Certbot receives a rate limit error from Let's Encrypt
- **THEN** system displays "Rate limit exceeded. Try again in 168 hours." and logs the timestamp

### Requirement: Accept user email for certificate registration
The script SHALL prompt for an email address for Certbot registration (notifications, account recovery).

#### Scenario: User provides email
- **WHEN** system prompts for "Email address for certificate notifications"
- **THEN** user provides valid email and system passes to Certbot via `--email <email>`

#### Scenario: User skips email
- **WHEN** user skips email entry or provides empty input
- **THEN** system allows continuation without email (Certbot will handle default behavior)

### Requirement: Accept Terms of Service
The script SHALL obtain user consent to Let's Encrypt Terms of Service before issuance.

#### Scenario: User agrees to TOS
- **WHEN** system displays "Do you agree to Let's Encrypt Terms of Service? (y/n)"
- **THEN** user confirms with "y" and system proceeds with certificate request using `--agree-tos` flag

#### Scenario: User declines TOS
- **WHEN** user selects "n"
- **THEN** system exits with message "Cannot proceed without agreeing to Terms of Service"
