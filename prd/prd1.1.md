# 1. Overview
- **Summary:** This project involves the development of a professional Bash-based wizard for Ubuntu servers designed to automate the manual issuance of Let's Encrypt SSL certificates. The script guides the user through system diagnostics, dependency resolution, DNS validation, and the final certificate acquisition process using Certbot.
- **Problem Statement:** Manually issuing SSL certificates often involves repetitive pre-checks (DNS pointing, port availability, dependency management) that are prone to human error, leading to failed challenges or service conflicts.
- **Goal:** To provide a reliable, "one-command" interactive wizard that ensures a server is fully prepared before requesting a certificate, resulting in a successful issuance and organized file storage every time.

# 2. Scope & Out of Scope
- **In Scope:**
    - Interactive CLI Wizard (Step-by-step UI).
    - Automated system summary (OS version, IP, Port 80/443 status).
    - Dependency check and auto-installation (Certbot, etc.).
    - DNS record verification (NS and A record checks for provided domains).
    - Conflict management (detecting and killing processes occupying Port 80).
    - Certificate issuance for Single, Multi-domain, and Wildcard types.
    - Structured file output (Certs, Keys, CA Bundles, and Logs) saved to the script's root directory.
- **Out of Scope:**
    - Automatic web server configuration (Nginx/Apache config modification).
    - Cron-based auto-renewal setup (this script focuses on manual/initial issuance).
    - Support for non-Debian/Ubuntu distributions.
    - Cloud-specific DNS API integrations (manual TXT entry for wildcards is the focus).

# 3. User Personas & Use Cases
- **Persona:** DevOps Engineer / System Administrator. A technical user who needs to quickly provision certificates for new environments or manual deployments without manually running fragmented Certbot commands.

### UC-1: Standard Domain Issuance
- **UC-ID:** UC-1
- **Title:** Issue SSL for Root and WWW
- **Description:** User wants to secure `example.com` and `[www.example.com](https://www.example.com)`.
- **Pre-conditions:** Server is running Ubuntu; user has sudo privileges.
- **Post-conditions:** Certificate files are saved in the local folder structure.
- **Main Flow:**
    1. User runs the script.
    2. Script displays System IP and OS summary.
    3. User enters domain names.
    4. Script verifies Port 80 is clear; kills conflicting `nginx` or `apache2` if found.
    5. Script checks if DNS points to current server IP.
    6. Script executes Certbot standalone mode.
    7. Script copies files to `./certs/[example.com/](https://example.com/)`.
- **Alternate / Error Flows:** 
    - **DNS Mismatch:** If DNS points elsewhere, the script warns the user and asks to proceed or abort.
    - **Port Conflict:** If a process refuses to die, the script logs the error and exits gracefully.

### UC-2: Wildcard Certificate Issuance
- **UC-ID:** UC-2
- **Title:** Issue Wildcard SSL via DNS Challenge
- **Description:** User requests `*.example.com`.
- **Pre-conditions:** User has access to DNS provider to add TXT records.
- **Post-conditions:** Wildcard cert is issued and validated.
- **Main Flow:**
    1. User selects "Wildcard" option.
    2. Script initiates `certbot --manual --preferred-challenges dns`.
    3. Script pauses and displays the required TXT record.
    4. User confirms record is set.
    5. Script finishes issuance and saves logs.

# 4. Functional Requirements
- **FR-1:** The script must display the server's Public IP and Current NS for the entered domain.
- **FR-2:** The script must check for `certbot` and install it via `snap` or `apt` if missing.
- **FR-3:** The script must verify if Port 80 is occupied and prompt to kill the specific PID before starting the standalone server.
- **FR-4:** The script must support comma-separated domain inputs.
- **FR-5:** The script must create a directory structure: `./output/<domain_name>/{archive, live, logs}`.
- **FR-6:** The script must aggregate the certificate and CA bundle into a single `fullchain.pem` equivalent if required by the user.

# 5. Non-Functional Requirements
- **Performance:** DNS lookups and dependency checks must complete in under 10 seconds.
- **Security:** Certificate private keys must be saved with restrictive permissions (`600`).
- **Reliability & Monitoring:** Every step must be logged to a local `.log` file within the script's root for troubleshooting.
- **UX & Accessibility:** Use clear color coding (Green for success, Red for errors, Yellow for warnings) in the Bash terminal.

# 6. Integration & API Hints
- **Certbot CLI:** The script acts as a wrapper around the Certbot binary.
- **External Tools:** Uses `dig` or `nslookup` for DNS verification and `netstat` or `ss` for port checking.
- **Folder Structure:**
  ```text
  /script-root
  ├── ssl-wizard.sh
  └── certs-out/
      └── domain.com/
          ├── cert.pem
          ├── privkey.pem
          ├── chain.pem
          └── fullchain.pem
  ```

# 7. Analytics & Success Metrics
- **Success Rate:** Percentage of script executions that result in a successfully saved certificate.
- **Time-to-Issue:** Average time taken from script launch to file availability.
- **Error Frequency:** Tracking whether "DNS Mismatch" or "Port Conflict" is the primary cause of failure.

# 8. Risks & Open Questions
- **Risk:** Let’s Encrypt Rate Limits. Repeatedly running the script for the same domain during testing may trigger a 168-hour lockout.
- **Risk:** DNS Propagation. For wildcard TXT records, propagation speed varies, which may cause the manual challenge to fail if the user continues too quickly.
- **Open Question:** Should the script automatically attempt to restart the killed processes (like Nginx) after the certificate is issued?
- **Open Question:** Do we need to support EAB (External Account Binding) for other ACME providers, or is Let's Encrypt the sole target?

# 9. Acceptance Criteria
- [ ] Script runs on a clean Ubuntu 22.04/24.04 LTS instance.
- [ ] Script successfully identifies and kills a "dummy" process on Port 80.
- [ ] DNS check correctly identifies when a domain does *not* point to the local server IP.
- [ ] Certificate, Private Key, and Chain files are correctly copied from `/etc/letsencrypt/` to the local script folder.
- [ ] Wildcard flow correctly pauses for DNS TXT entry.
- [ ] Final terminal output shows a summary of the file paths for the new certificates.
```