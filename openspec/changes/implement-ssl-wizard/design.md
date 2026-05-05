## Context

The manual SSL certificate issuance process requires DevOps engineers to execute multiple fragmented steps: checking system prerequisites, verifying DNS configuration, managing port conflicts, and running Certbot commands. This wizard consolidates these into a single interactive script on Ubuntu/Debian systems. The script must work reliably across clean system instances and provide clear feedback at each step, with comprehensive logging for troubleshooting failed attempts.

## Goals / Non-Goals

**Goals:**
- Provide a single-command interactive wizard for SSL certificate issuance
- Automate all pre-flight checks (dependencies, DNS, ports) without manual intervention
- Support single-domain, multi-domain, and wildcard certificate types
- Organize certificate output in a predictable, portable folder structure
- Handle error cases gracefully with clear messaging and step-by-step recovery
- Maintain comprehensive logs of every step for debugging

**Non-Goals:**
- Automatic web server configuration (Nginx/Apache)
- Cron-based auto-renewal management
- Support for non-Debian/Ubuntu distributions
- Cloud-provider DNS API integrations (manual TXT entry for wildcards only)
- Automatic process restart after certificate issuance

## Decisions

### 1. **Single Bash Script Architecture**
**Decision**: Implement as one self-contained `ssl-wizard.sh` file rather than modular scripts.
**Rationale**: Simplifies deployment (one command), easier to copy/share, reduces dependency on folder structure. DevOps workflow expects a single executable.
**Alternatives Considered**: Modular Bash library → adds complexity; Go/Python binary → increases deployment friction; Docker container → requires additional setup.

### 2. **Standalone Mode + Manual DNS Challenge**
**Decision**: Use Certbot's standalone mode for standard domains; manual DNS challenge mode for wildcards.
**Rationale**: Standalone mode avoids web server configuration; manual challenge works on any infrastructure. Temporary port occupancy is acceptable during issuance.
**Alternatives Considered**: DNS API integrations → cloud-specific, out of scope; webroot plugin → requires active web server; CNAME validation → not supported by Let's Encrypt.

### 3. **Local Certificate Storage at Script Root**
**Decision**: Save certificates to `./certs-out/<domain>/{cert.pem, privkey.pem, chain.pem, fullchain.pem}` relative to script location.
**Rationale**: Portable, no permission conflicts with `/etc/letsencrypt/`, easy backup/transport. User retains full control of files.
**Alternatives Considered**: Copy to `/etc/letsencrypt/` → requires root, permission issues; user home directory → less discoverable; absolute paths → reduces portability.

### 4. **Interactive CLI with Color-Coded Output**
**Decision**: Use ANSI color codes (Green, Yellow, Red) and clear prompts for user guidance.
**Rationale**: Reduces errors from missed warnings; provides immediate visual feedback; improves UX.
**Alternatives Considered**: Silent execution with only errors → unclear progress; JSON output → not user-friendly for manual operation.

### 5. **Process Termination via PID (No Force Kill)**
**Decision**: Prompt user to confirm before terminating processes on Port 80; use `kill -9` only if graceful kill fails.
**Rationale**: Safer approach; preserves data in running services; gives user control.
**Alternatives Considered**: Auto-kill with force flag → risky for production; skip port check → allows failures; manual user stop → adds friction.

### 6. **DNS Verification via dig/nslookup**
**Decision**: Use `dig` for NS record check and A record verification; fall back to `nslookup` if `dig` unavailable.
**Rationale**: Standard Linux tooling; `dig` provides detailed DNS info; fallback ensures compatibility.
**Alternatives Considered**: `host` command → less detailed; `getent hosts` → doesn't verify authoritative nameservers; API calls → external dependency.

### 7. **Rate Limit Awareness**
**Decision**: Log warnings about Let's Encrypt rate limits (50 certs/domain per 3 hours); allow user to proceed at own risk.
**Rationale**: Informs user of consequences; respects Let's Encrypt policies; prevents accidental lockouts.
**Alternatives Considered**: Auto-retry logic → could cause longer lockouts; hard block → too restrictive for testing.

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| **Port 80 Conflict During Issuance** | Prompt user to kill conflicting process; log PID for reference; allow retry. |
| **DNS Propagation Delay on Wildcard** | Manual DNS challenge allows user to control timing; clear instructions for TXT record entry. |
| **Let's Encrypt Rate Limiting** | Display warning; log domain requests; inform user of 168-hour lockout consequence. |
| **Partial Failure (e.g., cert issued but copy fails)** | Comprehensive logging; verify file existence; offer manual recovery instructions. |
| **Ubuntu-Only Support** | Explicitly documented in help; graceful detection and error message for unsupported distros. |
| **Snap vs. Apt Certbot** | Try snap first (modern), fall back to apt; allow user choice if both available. |
| **Private Key Permissions** | Always set to 600; log permission checks; validate before marking success. |

## Migration Plan

**Deployment:**
1. Copy `ssl-wizard.sh` to target server
2. Run with: `bash ssl-wizard.sh` or `./ssl-wizard.sh` (if executable)
3. Follow interactive prompts
4. Collect certificates from `./certs-out/<domain>/`

**Rollback**: No state changes or system modifications beyond temporary port occupation during standalone mode. Script is idempotent.

## Open Questions

- Should the script attempt to auto-restart Nginx/Apache after successful issuance? (Currently out of scope)
- Should we support EAB (External Account Binding) for other ACME providers, or focus solely on Let's Encrypt?
- Should the script retain a record of issued certificates for duplicate-prevention checks?
- How should the script behave if multiple domains are provided but one DNS check fails? (Fail-fast or skip-and-continue?)
