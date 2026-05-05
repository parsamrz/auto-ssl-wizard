## ADDED Requirements

### Requirement: Create organized output directory structure
The script SHALL organize certificate files in a predictable folder hierarchy at the script's root.

#### Scenario: Directory structure created
- **WHEN** certificate issuance completes successfully
- **THEN** system creates `./certs-out/<domain>/` directory and subdirectories: `archive/`, `live/`, `logs/`

#### Scenario: Existing directory handling
- **WHEN** output directory for a domain already exists
- **THEN** system displays warning "Directory ./certs-out/<domain>/ already exists. Overwrite? (y/n)"

#### Scenario: User confirms overwrite
- **WHEN** user selects "y" at the overwrite prompt
- **THEN** system backs up existing files with timestamp suffix and creates new directory structure

### Requirement: Copy certificate files from Certbot
The script SHALL retrieve certificate, private key, and chain files from Certbot's output and copy them to the organized structure.

#### Scenario: Files copied successfully
- **WHEN** certificate issuance completes
- **THEN** system copies:
  - `cert.pem` (certificate)
  - `privkey.pem` (private key)
  - `chain.pem` (certificate chain)
  - `fullchain.pem` (certificate + chain combined)
  to `./certs-out/<domain>/live/`

#### Scenario: Copy operation fails
- **WHEN** system cannot read or write certificate files
- **THEN** system displays error message with source and destination paths and offers to retry or abort

### Requirement: Set proper file permissions
The script SHALL enforce restrictive permissions on certificate files for security.

#### Scenario: Private key permissions set correctly
- **WHEN** privkey.pem is copied to output directory
- **THEN** system sets permissions to 600 (read/write for owner only) via `chmod 600`

#### Scenario: Certificate permissions set
- **WHEN** cert.pem, chain.pem, and fullchain.pem are copied
- **THEN** system sets permissions to 644 (read-only for all, writable by owner)

#### Scenario: Permission check fails
- **WHEN** chmod operation fails (e.g., due to filesystem or permissions)
- **THEN** system logs warning and continues (file integrity is still intact)

### Requirement: Create archive of original Certbot files
The script SHALL preserve original certificate files from Certbot in an archive subdirectory.

#### Scenario: Archive created
- **WHEN** files are organized
- **THEN** system copies originals from `/etc/letsencrypt/live/<domain>/` to `./certs-out/<domain>/archive/` for reference

#### Scenario: Archive already exists
- **WHEN** archive directory exists
- **THEN** system appends timestamp to archived files or creates versioned subdirectories

### Requirement: Save operation logs
The script SHALL write detailed logs of file operations to a log file.

#### Scenario: Log file created
- **WHEN** certificate issuance and file organization completes
- **THEN** system creates `./certs-out/<domain>/logs/issuance.log` containing:
  - Timestamp of issuance
  - Domains covered
  - Certbot command used
  - File copy operations and results
  - Permission changes
  - Any errors or warnings

#### Scenario: Log file appended on repeat issuance
- **WHEN** issuance is repeated for the same domain
- **THEN** system appends to existing log file with new timestamp and operation details

### Requirement: Provide file summary to user
The script SHALL display the location and details of all generated certificate files at completion.

#### Scenario: Summary displayed
- **WHEN** file organization completes
- **THEN** system displays summary showing:
  - Certificate path: `./certs-out/<domain>/live/cert.pem`
  - Private key path: `./certs-out/<domain>/live/privkey.pem`
  - Full chain path: `./certs-out/<domain>/live/fullchain.pem`
  - Log file location: `./certs-out/<domain>/logs/issuance.log`

#### Scenario: Summary includes readiness checks
- **WHEN** summary is displayed
- **THEN** system indicates files are "Ready to use" and provides next steps (e.g., copy to web server)
