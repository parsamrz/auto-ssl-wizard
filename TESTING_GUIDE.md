# SSL Wizard Critical Fixes - Testing Guide

This guide provides step-by-step instructions for testing all critical bug fixes.

## Prerequisites

- Linux/Ubuntu system (WSL works)
- Certbot installed
- Access to a domain you own
- DNS provider access
- Root/sudo access

## Quick Start Tests

### Test 1: Domain Input Prompt (Non-Blocking)

**Purpose:** Verify the interactive domain prompt works correctly

**Steps:**
```bash
cd /path/to/auto-ssl-wizard
bash ssl-wizard.sh
# When prompted for domain, enter: example.com
```

**Expected Output:**
- Script shows banner
- Displays section header "Domain Input"
- Prompts: "Enter domain(s) (comma-separated for multiple):"
- Accepts input and validates format
- Shows "✓ Domains Accepted" message

**Validation Points:**
- ✓ Script waits for user input (not using command-line arg)
- ✓ Single domain accepted
- ✓ Validation message shown with domain count
- ✓ Script continues to next phase

---

### Test 2: Multi-Domain Input (Non-Blocking)

**Purpose:** Verify comma-separated domain input works

**Steps:**
```bash
cd /path/to/auto-ssl-wizard
bash ssl-wizard.sh
# When prompted, enter: example.com,www.example.com,api.example.com
```

**Expected Output:**
- Script accepts comma-separated input
- Shows "✓ Domains Accepted" with count: 3 domains
- Lists all domains in acceptance message

**Validation Points:**
- ✓ Multiple domains parsed correctly
- ✓ Whitespace trimmed from each domain
- ✓ Domain count accurate
- ✓ All domains displayed to user

---

### Test 3: Invalid Domain Input (Non-Blocking)

**Purpose:** Verify invalid domain format is rejected

**Steps:**
```bash
cd /path/to/auto-ssl-wizard
bash ssl-wizard.sh
# When prompted, enter: "not a domain!", press Enter
```

**Expected Output:**
- Script rejects invalid format
- Shows error box: "Invalid Domain"
- Displays: "Domain format is invalid: not a domain!"
- Shows valid format examples
- Script exits gracefully

**Validation Points:**
- ✓ Invalid formats rejected
- ✓ Error message is clear
- ✓ Examples provided
- ✓ No partial processing

---

### Test 4: Empty Domain Input (Non-Blocking)

**Purpose:** Verify empty input is handled

**Steps:**
```bash
cd /path/to/auto-ssl-wizard
bash ssl-wizard.sh
# When prompted, press Enter without typing anything
```

**Expected Output:**
- Script rejects empty input
- Shows error: "Domain input cannot be empty"
- Script exits gracefully

**Validation Points:**
- ✓ Empty input rejected
- ✓ User-friendly error message
- ✓ No crash or undefined behavior

---

### Test 5: Certificate Validation - Files Exist (Blocking)

**Purpose:** Verify certificate files validation works for valid certificates

**Prerequisites:**
- Already have a valid certificate issued for a domain
- Certbot certificate exists at `/etc/letsencrypt/live/example.com/`

**Steps:**
```bash
# Manually run validation function in test context
bash -c 'source ssl-wizard.sh; validate_certificate_files "example.com"'
```

**Expected Output:**
- Shows section "Certificate File Validation"
- Lists each file: privkey.pem, fullchain.pem, chain.pem, cert.pem
- Shows file sizes for each
- Shows "Certificate content is valid (openssl x509 check passed)"
- Shows "All validations PASSED"

**Validation Points:**
- ✓ All files detected
- ✓ File sizes shown
- ✓ OpenSSL validation succeeds
- ✓ Permission check shown
- ✓ Success status returned

---

### Test 6: Certificate Validation - Files Missing (Blocking)

**Purpose:** Verify certificate validation detects missing files

**Steps:**
```bash
# Try validating a domain that doesn't have a certificate
bash -c 'source ssl-wizard.sh; validate_certificate_files "nonexistent-domain-12345.com"'
```

**Expected Output:**
- Shows section "Certificate File Validation"
- Shows error: "Certificate directory not found"
- Error box with: "Certificate Validation Failed"
- Lists specific files missing
- Shows checked location

**Validation Points:**
- ✓ Missing directory detected
- ✓ Clear error message
- ✓ User knows exactly what's wrong
- ✓ Checked location shown
- ✓ Function returns failure

---

### Test 7: Domain Verification in Certificate (Blocking)

**Purpose:** Verify domains are correctly identified in certificate

**Prerequisites:**
- Valid certificate for a domain exists
- Example: certificate for "example.com"

**Steps:**
```bash
# Test with matching domain
bash -c 'source ssl-wizard.sh; verify_domains_in_cert "example.com" "example.com"'
```

**Expected Output:**
- Shows section "Domain Verification in Certificate"
- Extracts and displays CN and SANs
- Shows: "✓ Domain found in certificate: example.com"
- Shows "All requested domains verified in certificate"
- Success info box with verified domain count

**Validation Points:**
- ✓ Certificate CN extracted correctly
- ✓ Certificate SANs extracted correctly
- ✓ Matching domain recognized
- ✓ User shown per-domain status
- ✓ Success message clear and accurate

---

### Test 8: Domain Verification - Missing Domains (Blocking)

**Purpose:** Verify missing domains are detected in certificate

**Prerequisites:**
- Certificate exists for "example.com"
- But NOT for "www.example.com"

**Steps:**
```bash
# Test with domain not in certificate
bash -c 'source ssl-wizard.sh; verify_domains_in_cert "example.com" "www.example.com" "api.example.com"'
```

**Expected Output:**
- Shows section "Domain Verification in Certificate"
- Shows "✘ Domain NOT found in certificate: www.example.com"
- Shows "✘ Domain NOT found in certificate: api.example.com"
- Error box: "Domain Verification Failed"
- Lists missing domains
- Shows what certificate actually contains

**Validation Points:**
- ✓ Missing domains detected
- ✓ Clear indication which are missing
- ✓ Error message informative
- ✓ What certificate contains shown
- ✓ Function returns failure

---

### Test 9: Full Issuance Validation (Integrated)

**Purpose:** Verify comprehensive validation during full certificate flow

**Prerequisites:**
- Domain registered and DNS configured
- Port 80/443 accessible
- Certbot environment ready

**Steps:**
```bash
bash ssl-wizard.sh
# Input: your-test-domain.com
# Select: Single Domain
# Select: DNS-01
# Enter email
# Acknowledge rate limits
# Complete DNS challenge
# Watch validation phase
```

**Expected Output (After Certbot Completes):**
```
─────────────────────────────────────────
         Certificate Validation
─────────────────────────────────────────

[timestamp] ℹ Starting post-issuance validation

Certificate File Validation section showing:
✓ File exists and readable: privkey.pem (size: XXXX bytes)
✓ File exists and readable: fullchain.pem (size: XXXX bytes)
✓ File exists and readable: chain.pem (size: XXXX bytes)
✓ File exists and readable: cert.pem (size: XXXX bytes)
✓ Certificate content is valid (openssl x509 check passed)
✓ All validations PASSED

Domain Verification in Certificate section showing:
✓ Domain found in certificate: your-test-domain.com
✓ All requested domains verified in certificate

File Organization section showing:
✓ Files organized successfully

✓ Certificate Successfully Issued & Verified section showing:
✓ Domain verified in certificate
✓ File paths with permissions
✓ Verification status
```

**Validation Points:**
- ✓ Validation runs immediately after certbot
- ✓ Files validated before success shown
- ✓ Domains verified in certificate
- ✓ File organization only after validation
- ✓ Success message shows verification status
- ✓ No false positives

---

### Test 10: Failure Handling - Certificate Not Issued

**Purpose:** Verify failure message when certificate isn't actually issued

**Steps:**
```bash
# Mock scenario: Try issuing with DNS challenge without actually setting DNS
bash ssl-wizard.sh
# Input: test-domain-no-dns.com
# Select: Single Domain
# Select: DNS-01
# Deliberately do NOT add DNS record
# Certbot will fail after timeout
```

**Expected Output:**
- Certbot fails and logs error
- Script DOES NOT show success
- Script enters validation phase
- Validation detects files don't exist
- Error box shown: "Certificate Validation Failed"
- Troubleshooting suggestions displayed:
  - Check DNS records
  - Check rate limits
  - Review Certbot logs at /var/log/letsencrypt/
  - Check firewall/ports

**Validation Points:**
- ✓ No false success message
- ✓ User informed of actual failure
- ✓ Clear troubleshooting steps
- ✓ Log file path shown
- ✓ Script exits with error code

---

## Automated Testing (Optional)

Create a test script to verify functions:

```bash
#!/bin/bash

# Test 1: Validate function exists
echo "Test 1: Checking function definitions..."
grep -q "prompt_for_domains()" ssl-wizard.sh && echo "✓ prompt_for_domains found" || echo "✗ Missing"
grep -q "validate_certificate_files()" ssl-wizard.sh && echo "✓ validate_certificate_files found" || echo "✗ Missing"
grep -q "verify_domains_in_cert()" ssl-wizard.sh && echo "✓ verify_domains_in_cert found" || echo "✗ Missing"
grep -q "validate_certificate_issuance()" ssl-wizard.sh && echo "✓ validate_certificate_issuance found" || echo "✗ Missing"

# Test 2: Syntax check
echo -e "\nTest 2: Syntax check..."
bash -n ssl-wizard.sh && echo "✓ No syntax errors" || echo "✗ Syntax errors found"

# Test 3: Check for critical error handling
echo -e "\nTest 3: Checking error handling..."
grep -q "validate_certificate_issuance" ssl-wizard.sh && echo "✓ Validation called in main" || echo "✗ Missing"
grep -q "Certificate Validation Failed" ssl-wizard.sh && echo "✓ Error message present" || echo "✗ Missing"

# Test 4: Check DOMAINS_ARRAY usage
echo -e "\nTest 4: Checking DOMAINS_ARRAY..."
grep -q "DOMAINS_ARRAY=()" ssl-wizard.sh && echo "✓ DOMAINS_ARRAY initialized" || echo "✗ Missing"
grep -q "DOMAINS_ARRAY" ssl-wizard.sh && [[ $(grep -c "DOMAINS_ARRAY" ssl-wizard.sh) -gt 5 ]] && echo "✓ DOMAINS_ARRAY used multiple times" || echo "✗ Limited usage"

echo -e "\nAll checks completed!"
```

---

## Validation Checklist

- [ ] Domain prompt interactive (not command-line arg)
- [ ] Single domain accepted
- [ ] Multi-domain comma-separated accepted
- [ ] Invalid domains rejected
- [ ] Empty input rejected
- [ ] Files validated before success
- [ ] Domain verification in certificate
- [ ] Missing files cause error
- [ ] Missing domains cause error
- [ ] No false success messages
- [ ] Troubleshooting info provided
- [ ] All functions syntactically correct
- [ ] Error codes returned properly
- [ ] Logs capture all validation steps
- [ ] Output messages clear and helpful

---

## Troubleshooting Test Issues

### Script hangs at domain prompt
- May be due to terminal buffering
- Try: `echo "example.com" | bash ssl-wizard.sh`
- Check: Is script waiting for input correctly?

### Certificate validation fails unexpectedly
- Verify certificate exists: `ls -la /etc/letsencrypt/live/`
- Check certificate: `openssl x509 -in /etc/letsencrypt/live/DOMAIN/cert.pem -text -noout`
- Check permissions: Files must be readable by the user

### Domain verification shows missing domains
- This might be correct if certificate wasn't issued for those domains
- Check certificate SAN: `openssl x509 -in cert.pem -text -noout | grep -A1 "Subject Alternative Name"`
- Check CN: `openssl x509 -in cert.pem -noout -subject`

### Tests cause elevation needed
- Some operations require sudo (copying to /etc/letsencrypt/)
- Run tests with: `sudo bash ssl-wizard.sh`
- Check sudoers for certbot: `sudo -l | grep certbot`

---

## Success Criteria

All critical bug fixes are working when:

1. **Domain Input** ✓
   - Script prompts for domain interactively
   - Accepts single and multiple domains
   - Validates format before proceeding

2. **Certificate Validation** ✓
   - Files verified to exist after certbot
   - File sizes checked (> 0 bytes)
   - OpenSSL validation passes
   - Permissions verified

3. **Domain Verification** ✓
   - Certificate CN and SAN extracted
   - Each requested domain verified
   - Status reported per domain
   - Error if any domain missing

4. **Error Handling** ✓
   - Clear error messages shown
   - Troubleshooting steps provided
   - Script exits gracefully on failure
   - No false success messages

5. **False Success Prevention** ✓
   - Success message ONLY after ALL validations
   - File organization ONLY if validation passes
   - Detailed verification status in output
   - Confidence in certificate issuance

---

## Next Steps

After validating these fixes work:

1. Deploy to production
2. Update user documentation
3. Consider additional improvements:
   - Pre-issuance DNS validation
   - Rate limit checking
   - Automatic retry logic
   - Email notifications
   - Renewal automation
