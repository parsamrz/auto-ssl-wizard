#!/bin/bash
# ssl-wizard.sh - Automated SSL/TLS certificate management and renewal wizard
# This script provides comprehensive SSL certificate provisioning, management,
# and maintenance with robust error handling and detailed diagnostics.

set -euo pipefail

#############################################################################
# SECTION 1: PROJECT SETUP & CONFIGURATION
#############################################################################

# Configuration variables
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"
readonly VERSION="1.0.0"
readonly OUTPUT_DIR="${SCRIPT_DIR}/output"
readonly TEMP_DIR="${SCRIPT_DIR}/.tmp"
readonly STATE_DIR="${OUTPUT_DIR}/.state"

# Timeout values (in seconds)
readonly DNS_CHECK_TIMEOUT=10
readonly HTTP_CHECK_TIMEOUT=5
readonly CERT_CHECK_TIMEOUT=10

# Network configuration
readonly PUBLIC_IP_SOURCES=(
  "https://api.ipify.org"
  "https://ifconfig.me"
  "https://icanhazip.com"
  "https://checkip.amazonaws.com"
)
readonly DNS_SERVERS=("8.8.8.8" "1.1.1.1" "9.9.9.9")

# ANSI Color Constants
readonly COLOR_RESET='\033[0m'
readonly COLOR_BOLD='\033[1m'
readonly COLOR_DIM='\033[2m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_MAGENTA='\033[0;35m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_WHITE='\033[0;37m'
readonly COLOR_LIGHT_GRAY='\033[0;90m'
readonly COLOR_LIGHT_RED='\033[0;91m'
readonly COLOR_LIGHT_GREEN='\033[0;92m'
readonly COLOR_LIGHT_YELLOW='\033[0;93m'
readonly COLOR_LIGHT_BLUE='\033[0;94m'
readonly COLOR_LIGHT_MAGENTA='\033[0;95m'
readonly COLOR_LIGHT_CYAN='\033[0;96m'

# Global state variables
DOMAIN=""
LOG_FILE=""
DEBUG_MODE="${DEBUG_MODE:-false}"
QUIET_MODE="${QUIET_MODE:-false}"

#############################################################################
# SECTION 2: LOGGING INFRASTRUCTURE
#############################################################################

# Initialize logging directory structure
init_logging() {
  local domain="$1"
  local log_dir="${OUTPUT_DIR}/${domain}/logs"

  mkdir -p "$log_dir"
  LOG_FILE="${log_dir}/issuance.log"

  # Write initialization header
  {
    echo "================================================================================"
    echo "SSL Wizard Execution Log - $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Domain: $domain"
    echo "Script Version: $VERSION"
    echo "================================================================================"
    echo ""
  } >> "$LOG_FILE"
}

# Log info message with timestamp
log_info() {
  local message="$1"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  if [[ "$QUIET_MODE" != "true" ]]; then
    echo -e "${COLOR_BLUE}[${timestamp}]${COLOR_RESET} ${COLOR_GREEN}ℹ${COLOR_RESET} ${message}"
  fi

  if [[ -n "$LOG_FILE" ]]; then
    echo "[${timestamp}] [INFO] ${message}" >> "$LOG_FILE"
  fi
}

# Log warning message with timestamp
log_warn() {
  local message="$1"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  if [[ "$QUIET_MODE" != "true" ]]; then
    echo -e "${COLOR_BLUE}[${timestamp}]${COLOR_RESET} ${COLOR_YELLOW}⚠${COLOR_RESET} ${message}"
  fi

  if [[ -n "$LOG_FILE" ]]; then
    echo "[${timestamp}] [WARN] ${message}" >> "$LOG_FILE"
  fi
}

# Log error message with timestamp
log_error() {
  local message="$1"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  if [[ "$QUIET_MODE" != "true" ]]; then
    echo -e "${COLOR_BLUE}[${timestamp}]${COLOR_RESET} ${COLOR_RED}✘${COLOR_RESET} ${message}" >&2
  fi

  if [[ -n "$LOG_FILE" ]]; then
    echo "[${timestamp}] [ERROR] ${message}" >> "$LOG_FILE"
  fi
}

# Log debug message (only if DEBUG_MODE is true)
log_debug() {
  local message="$1"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  if [[ "$DEBUG_MODE" == "true" ]]; then
    if [[ "$QUIET_MODE" != "true" ]]; then
      echo -e "${COLOR_BLUE}[${timestamp}]${COLOR_RESET} ${COLOR_LIGHT_GRAY}◆ ${message}${COLOR_RESET}"
    fi
  fi

  if [[ -n "$LOG_FILE" ]]; then
    echo "[${timestamp}] [DEBUG] ${message}" >> "$LOG_FILE"
  fi
}

#############################################################################
# SECTION 3: UTILITY FUNCTIONS
#############################################################################

# Display formatted section header
section_header() {
  local title="$1"
  local width=80
  local title_len=${#title}
  local padding=$(( (width - title_len - 4) / 2 ))

  echo ""
  echo -e "${COLOR_BOLD}${COLOR_CYAN}$(printf '─%.0s' $(seq 1 $width))${COLOR_RESET}"
  echo -e "${COLOR_BOLD}${COLOR_CYAN}$(printf '─%.0s' $(seq 1 $padding)) ${title} $(printf '─%.0s' $(seq 1 $padding))${COLOR_RESET}"
  echo -e "${COLOR_BOLD}${COLOR_CYAN}$(printf '─%.0s' $(seq 1 $width))${COLOR_RESET}"
}

# Display formatted info box
info_box() {
  local title="$1"
  local content="$2"

  echo -e ""
  echo -e "${COLOR_BOLD}${COLOR_BLUE}┌─ ${title}${COLOR_RESET}"
  echo -e "${COLOR_BLUE}│${COLOR_RESET}"
  while IFS= read -r line; do
    echo -e "${COLOR_BLUE}│${COLOR_RESET}  ${line}"
  done <<< "$content"
  echo -e "${COLOR_BLUE}│${COLOR_RESET}"
  echo -e "${COLOR_BLUE}└─${COLOR_RESET}"
}

# Display formatted error box
error_box() {
  local title="$1"
  local content="$2"

  echo -e ""
  echo -e "${COLOR_BOLD}${COLOR_RED}╔═ ${title}${COLOR_RESET}"
  echo -e "${COLOR_RED}║${COLOR_RESET}"
  while IFS= read -r line; do
    echo -e "${COLOR_RED}║${COLOR_RESET}  ${line}"
  done <<< "$content"
  echo -e "${COLOR_RED}║${COLOR_RESET}"
  echo -e "${COLOR_RED}╚═${COLOR_RESET}"
}

# Prompt user for yes/no response
prompt_yes_no() {
  local question="$1"
  local default="${2:-y}"
  local response

  if [[ "$QUIET_MODE" == "true" ]]; then
    # In quiet mode, use default
    log_debug "Quiet mode: using default '$default' for prompt"
    [[ "$default" == "y" || "$default" == "yes" ]]
    return $?
  fi

  while true; do
    echo -n -e "${COLOR_CYAN}${question}${COLOR_RESET} ${COLOR_BOLD}[${default}]:${COLOR_RESET} "
    read -r response
    response="${response:-$default}"

    case "${response,,}" in
      y|yes)
        return 0
        ;;
      n|no)
        return 1
        ;;
      *)
        echo "Please answer 'y' or 'n'."
        ;;
    esac
  done
}

#############################################################################
# SECTION 4: SYSTEM DIAGNOSTICS (Tasks 2.1-2.6)
#############################################################################

# Get public IP address with multiple fallback sources
get_public_ip() {
  local ip

  log_debug "Attempting to retrieve public IP address..."

  for source in "${PUBLIC_IP_SOURCES[@]}"; do
    log_debug "Trying source: $source"

    if ip=$(curl -s --max-time "$HTTP_CHECK_TIMEOUT" "$source" 2>/dev/null); then
      if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_info "Public IP obtained: $ip"
        echo "$ip"
        return 0
      fi
    fi
  done

  log_warn "Could not retrieve public IP address"
  echo "UNKNOWN"
  return 1
}

# Detect OS version and distribution
detect_os_version() {
  local os_info
  local os_name="Unknown"
  local os_version="Unknown"

  log_debug "Detecting OS version..."

  # Try /etc/os-release first (modern systems)
  if [[ -f /etc/os-release ]]; then
    os_name=$(grep '^NAME=' /etc/os-release | cut -d'"' -f2)
    os_version=$(grep '^VERSION_ID=' /etc/os-release | cut -d'"' -f2)
    log_debug "OS detected via /etc/os-release: $os_name $os_version"
  # Fallback to uname
  elif command -v uname &> /dev/null; then
    os_name=$(uname -s)
    os_version=$(uname -r)
    log_debug "OS detected via uname: $os_name $os_version"
  fi

  os_info="${os_name} ${os_version}"
  echo "$os_info"
}

# Check if system is Ubuntu
is_ubuntu() {
  log_debug "Checking if system is Ubuntu..."

  if [[ -f /etc/os-release ]]; then
    if grep -qi "ubuntu" /etc/os-release; then
      log_info "Ubuntu distribution detected"
      return 0
    fi
  fi

  log_warn "Ubuntu distribution not detected"
  return 1
}

# Check if a specific port is available
check_port_available() {
  local port="$1"

  log_debug "Checking port $port availability..."

  # Try ss first (newer systems)
  if command -v ss &> /dev/null; then
    if ! ss -tlnp 2>/dev/null | grep -q ":$port "; then
      log_info "Port $port is available"
      return 0
    fi
  # Fallback to netstat
  elif command -v netstat &> /dev/null; then
    if ! netstat -tln 2>/dev/null | grep -q ":$port "; then
      log_info "Port $port is available"
      return 0
    fi
  else
    log_warn "Neither ss nor netstat available for port checking"
    return 1
  fi

  log_warn "Port $port is in use"
  return 1
}

# Get process using a specific port
get_process_on_port() {
  local port="$1"
  local process_info="UNKNOWN"

  log_debug "Identifying process on port $port..."

  # Try ss first
  if command -v ss &> /dev/null; then
    process_info=$(ss -tlnp 2>/dev/null | grep ":$port " | grep -oP 'pid=\K[0-9]+' || echo "UNKNOWN")
  # Fallback to netstat
  elif command -v netstat &> /dev/null; then
    process_info=$(netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $NF}' || echo "UNKNOWN")
  fi

  echo "$process_info"
  log_debug "Process on port $port: $process_info"
}

# Run comprehensive system diagnostics
run_diagnostics() {
  section_header "System Diagnostics"

  log_info "Starting system diagnostics..."

  # Get OS information
  local os_info
  os_info=$(detect_os_version)
  info_box "Operating System" "$os_info"

  # Get public IP
  local public_ip
  public_ip=$(get_public_ip)
  info_box "Public IP Address" "$public_ip"

  # Check for Ubuntu
  if is_ubuntu; then
    info_box "Distribution Check" "✓ Ubuntu distribution detected"
  else
    info_box "Distribution Check" "✗ Non-Ubuntu distribution detected (some features may not be available)"
  fi

  # Check key ports
  log_info "Checking critical ports..."
  local ports_info="Port 80 (HTTP): $(check_port_available 80 && echo '✓ Available' || echo '✗ In use')\n"
  ports_info="${ports_info}Port 443 (HTTPS): $(check_port_available 443 && echo '✓ Available' || echo '✗ In use')"
  info_box "Port Status" "$ports_info"

  # Check DNS resolution
  log_info "Checking DNS resolution..."
  local dns_info="Nameservers: ${DNS_SERVERS[*]}"
  info_box "DNS Configuration" "$dns_info"

  log_info "System diagnostics completed"
}

#############################################################################
# SECTION 5: DEPENDENCY MANAGEMENT (Tasks 3.1-3.6)
#############################################################################

# Check if certbot is installed
is_certbot_installed() {
  log_debug "Checking if certbot is installed..."

  if command -v certbot &> /dev/null; then
    log_info "certbot is installed"
    return 0
  fi

  log_debug "certbot not found in PATH"
  return 1
}

# Get certbot version
get_certbot_version() {
  local version="UNKNOWN"

  if is_certbot_installed; then
    version=$(certbot --version 2>/dev/null | awk '{print $NF}' || echo "UNKNOWN")
    log_debug "certbot version: $version"
  else
    log_debug "Cannot determine certbot version - not installed"
  fi

  echo "$version"
}

# Install certbot via snap
install_certbot_snap() {
  log_info "Installing certbot via snap..."

  if ! command -v snap &> /dev/null; then
    log_warn "snap not available on this system"
    return 1
  fi

  if snap install certbot --classic 2>&1 | tee -a "$LOG_FILE"; then
    log_info "certbot successfully installed via snap"

    # Create symlink for easier access
    if [[ ! -L /usr/bin/certbot ]]; then
      if ln -s /snap/bin/certbot /usr/bin/certbot 2>/dev/null; then
        log_info "Created symlink for certbot at /usr/bin/certbot"
      fi
    fi
    return 0
  else
    log_error "Failed to install certbot via snap"
    return 1
  fi
}

# Install certbot via apt (fallback method)
install_certbot_apt() {
  log_info "Installing certbot via apt..."

  if ! command -v apt-get &> /dev/null; then
    log_error "apt-get not available - cannot install certbot"
    return 1
  fi

  if apt-get update 2>&1 | tee -a "$LOG_FILE" && apt-get install -y certbot 2>&1 | tee -a "$LOG_FILE"; then
    log_info "certbot successfully installed via apt"
    return 0
  else
    log_error "Failed to install certbot via apt"
    return 1
  fi
}

# Ensure certbot is installed, auto-install if needed
ensure_certbot() {
  log_info "Ensuring certbot is installed..."

  if is_certbot_installed; then
    local version
    version=$(get_certbot_version)
    info_box "certbot Status" "✓ Installed\nVersion: $version"
    return 0
  fi

  log_warn "certbot not found - attempting installation..."

  # Try snap first (preferred method)
  if install_certbot_snap; then
    return 0
  fi

  # Fallback to apt
  if install_certbot_apt; then
    return 0
  fi

  log_error "Could not install certbot using any available method"
  return 1
}

# Check all required dependencies
check_dependencies() {
  section_header "Dependency Check"

  log_info "Checking required dependencies..."

  local deps_missing=false
  local deps_status=""

  # Check certbot
  if is_certbot_installed; then
    local version
    version=$(get_certbot_version)
    deps_status="${deps_status}✓ certbot (v${version})\n"
  else
    deps_status="${deps_status}✗ certbot\n"
    deps_missing=true
  fi

  # Check dig (DNS lookup)
  if command -v dig &> /dev/null; then
    deps_status="${deps_status}✓ dig (DNS utilities)\n"
  else
    deps_status="${deps_status}✗ dig (DNS utilities)\n"
    deps_missing=true
  fi

  # Check ss or netstat
  if command -v ss &> /dev/null; then
    deps_status="${deps_status}✓ ss (network diagnostics)\n"
  elif command -v netstat &> /dev/null; then
    deps_status="${deps_status}✓ netstat (network diagnostics)\n"
  else
    deps_status="${deps_status}✗ ss/netstat (network diagnostics)\n"
    deps_missing=true
  fi

  # Check curl
  if command -v curl &> /dev/null; then
    deps_status="${deps_status}✓ curl (HTTP client)"
  else
    deps_status="${deps_status}✗ curl (HTTP client)"
    deps_missing=true
  fi

  info_box "Dependency Status" "$deps_status"

  if [[ "$deps_missing" == "true" ]]; then
    log_warn "Some dependencies are missing"

    if prompt_yes_no "Would you like to install missing dependencies?" "y"; then
      ensure_certbot
    else
      log_warn "Skipping dependency installation"
      return 1
    fi
  else
    log_info "All required dependencies are satisfied"
    return 0
  fi
}

#############################################################################
# SECTION 6: DNS VALIDATION (Tasks 4.1-4.7)
#############################################################################

# Task 4.1: Parse comma-separated domain input
parse_domains() {
  local input="$1"
  local -a domains
  
  log_debug "Parsing domain input: $input"
  
  # Split by comma and trim whitespace
  while IFS=',' read -ra domain_array; do
    for domain in "${domain_array[@]}"; do
      domain=$(echo "$domain" | xargs)  # Trim whitespace
      if [[ -n "$domain" ]]; then
        domains+=("$domain")
      fi
    done
  done <<< "$input"
  
  # Return as space-separated string for bash arrays
  echo "${domains[@]:-}"
}

# Task 4.2: A record lookup using dig (primary) or nslookup (fallback)
get_a_record() {
  local domain="$1"
  local result=""
  
  log_debug "Looking up A record for: $domain"
  
  # Try dig first
  if command -v dig &> /dev/null; then
    result=$(dig +short A "$domain" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -1)
    if [[ -n "$result" ]]; then
      log_debug "A record for $domain: $result (via dig)"
      echo "$result"
      return 0
    fi
  fi
  
  # Fallback to nslookup
  if command -v nslookup &> /dev/null; then
    result=$(nslookup "$domain" 2>/dev/null | grep -A1 "Name:" | tail -1 | awk '{print $NF}' 2>/dev/null || echo "")
    if [[ -n "$result" && $result =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      log_debug "A record for $domain: $result (via nslookup)"
      echo "$result"
      return 0
    fi
  fi
  
  log_warn "Could not retrieve A record for $domain"
  return 1
}

# Task 4.3: NS record lookup and display
get_ns_records() {
  local domain="$1"
  local result=""
  
  log_debug "Looking up NS records for: $domain"
  
  # Try dig first
  if command -v dig &> /dev/null; then
    result=$(dig +short NS "$domain" 2>/dev/null)
    if [[ -n "$result" ]]; then
      log_debug "NS records for $domain retrieved (via dig)"
      echo "$result"
      return 0
    fi
  fi
  
  # Fallback to nslookup
  if command -v nslookup &> /dev/null; then
    result=$(nslookup -type=NS "$domain" 2>/dev/null | grep "nameserver" | awk '{print $NF}')
    if [[ -n "$result" ]]; then
      log_debug "NS records for $domain retrieved (via nslookup)"
      echo "$result"
      return 0
    fi
  fi
  
  log_warn "Could not retrieve NS records for $domain"
  return 1
}

# Task 4.4: DNS-to-server-IP matching logic with clear mismatch reporting
validate_dns_match() {
  local domain="$1"
  local expected_ip="$2"
  
  log_debug "Validating DNS match for $domain (expected: $expected_ip)"
  
  local actual_ip
  actual_ip=$(get_a_record "$domain")
  
  if [[ -z "$actual_ip" ]]; then
    log_warn "DNS lookup failed for $domain"
    return 2  # DNS lookup failed
  fi
  
  if [[ "$actual_ip" == "$expected_ip" ]]; then
    log_info "DNS validation passed for $domain: $actual_ip"
    return 0  # Match
  else
    log_warn "DNS mismatch for $domain - Expected: $expected_ip, Actual: $actual_ip"
    return 1  # Mismatch
  fi
}

# Task 4.5: User prompt for DNS mismatch override with warning
prompt_dns_override() {
  local domain="$1"
  local expected_ip="$2"
  local actual_ip="$3"
  
  log_debug "Prompting user for DNS mismatch override"
  
  error_box "DNS Mismatch Warning" "Domain: $domain\nExpected IP: $expected_ip\nActual IP: $actual_ip\n\nThe domain is not currently pointing to your server.\nIf you continue, HTTPS validation may fail."
  
  if prompt_yes_no "Do you want to proceed anyway?" "n"; then
    log_info "User confirmed DNS mismatch override for $domain"
    return 0
  else
    log_info "User declined DNS mismatch override for $domain"
    return 1
  fi
}

# Task 4.6: Validation loop for multiple domains with error handling per domain
validate_domains() {
  local domains_input="$1"
  local expected_ip="$2"
  local -a valid_domains=()
  local -a failed_domains=()
  
  section_header "DNS Validation"
  
  log_info "Starting DNS validation for domains: $domains_input"
  
  # Parse domains
  local domains_array
  read -ra domains_array <<< "$(parse_domains "$domains_input")"
  
  if [[ ${#domains_array[@]} -eq 0 ]]; then
    log_error "No valid domains provided"
    return 1
  fi
  
  log_info "Validating ${#domains_array[@]} domain(s)"
  
  # Validate each domain
  for domain in "${domains_array[@]}"; do
    log_info "Validating domain: $domain"
    
    if validate_dns_match "$domain" "$expected_ip"; then
      valid_domains+=("$domain")
      info_box "✓ DNS Valid" "$domain resolves to $expected_ip"
    else
      local actual_ip
      actual_ip=$(get_a_record "$domain") || actual_ip="UNKNOWN"
      
      # Try to get override
      if prompt_dns_override "$domain" "$expected_ip" "$actual_ip"; then
        valid_domains+=("$domain")
      else
        failed_domains+=("$domain")
      fi
    fi
  done
  
  # Report results
  if [[ ${#valid_domains[@]} -eq 0 ]]; then
    log_error "No valid domains remaining after validation"
    error_box "Validation Failed" "All domains failed DNS validation."
    return 1
  fi
  
  local summary="Valid: ${#valid_domains[@]} domain(s)\n"
  if [[ ${#failed_domains[@]} -gt 0 ]]; then
    summary="${summary}Failed: ${#failed_domains[@]} domain(s)"
  fi
  info_box "DNS Validation Complete" "$summary"
  
  # Export results as space-separated string
  echo "${valid_domains[@]}"
  return 0
}

#############################################################################
# SECTION 7: PORT CONFLICT RESOLUTION (Tasks 5.1-5.7)
#############################################################################

# Task 5.1: Identify process(es) on port 80
find_processes_on_port() {
  local port="$1"
  local -a processes=()
  
  log_debug "Finding processes on port $port"
  
  # Try ss first (newer systems)
  if command -v ss &> /dev/null; then
    while IFS= read -r line; do
      local pid
      pid=$(echo "$line" | grep -oP 'pid=\K[0-9]+' | head -1)
      if [[ -n "$pid" ]]; then
        processes+=("$pid")
      fi
    done < <(ss -tlnp 2>/dev/null | grep ":$port " || true)
  
  # Fallback to netstat
  elif command -v netstat &> /dev/null; then
    while IFS= read -r line; do
      local pid
      pid=$(echo "$line" | awk '{print $NF}' | cut -d/ -f1)
      if [[ "$pid" =~ ^[0-9]+$ ]]; then
        processes+=("$pid")
      fi
    done < <(netstat -tlnp 2>/dev/null | grep ":$port " || true)
  fi
  
  if [[ ${#processes[@]} -gt 0 ]]; then
    # Output unique PIDs
    printf '%s\n' "${processes[@]}" | sort -u
    return 0
  else
    log_debug "No processes found on port $port"
    return 1
  fi
}

# Task 5.2: User confirmation prompt for process termination
confirm_process_termination() {
  local -a pids=("$@")
  local process_info=""
  
  log_debug "Confirming process termination for PIDs: ${pids[*]}"
  
  for pid in "${pids[@]}"; do
    local cmd
    cmd=$(ps -p "$pid" -o comm= 2>/dev/null || echo "UNKNOWN")
    process_info="${process_info}PID: $pid - Command: $cmd\n"
  done
  
  error_box "Port 80 Occupied" "The following process(es) are using port 80:\n\n${process_info}\nTo continue, these processes must be terminated."
  
  if prompt_yes_no "Do you want to terminate these processes?" "n"; then
    log_info "User confirmed process termination"
    return 0
  else
    log_info "User declined process termination"
    return 1
  fi
}

# Task 5.3: Graceful process termination (SIGTERM) with 5-second timeout
terminate_process_graceful() {
  local pid="$1"
  local timeout=5
  local elapsed=0
  
  log_info "Attempting graceful termination of PID $pid (SIGTERM)"
  
  # Send SIGTERM
  if ! kill -TERM "$pid" 2>/dev/null; then
    log_warn "Failed to send SIGTERM to PID $pid (process may have already exited)"
    return 1
  fi
  
  # Wait for process to exit
  while [[ $elapsed -lt $timeout ]]; do
    if ! kill -0 "$pid" 2>/dev/null; then
      log_info "Process $pid terminated gracefully"
      return 0
    fi
    sleep 1
    ((elapsed++))
  done
  
  log_warn "Graceful termination of PID $pid timed out after ${timeout}s"
  return 1
}

# Task 5.4: Force kill (SIGKILL) as fallback if graceful fails
terminate_process_force() {
  local pid="$1"
  
  log_info "Attempting force termination of PID $pid (SIGKILL)"
  
  if ! kill -KILL "$pid" 2>/dev/null; then
    log_error "Failed to send SIGKILL to PID $pid"
    return 1
  fi
  
  # Wait a moment for process to be killed
  sleep 1
  
  if ! kill -0 "$pid" 2>/dev/null; then
    log_info "Process $pid force terminated"
    return 0
  else
    log_error "Process $pid still exists after SIGKILL"
    return 1
  fi
}

# Task 5.5: Port verification after termination attempt
verify_port_available() {
  local port="$1"
  
  log_debug "Verifying port $port is available"
  
  # Try ss first
  if command -v ss &> /dev/null; then
    if ! ss -tlnp 2>/dev/null | grep -q ":$port "; then
      log_info "Port $port is now available"
      return 0
    fi
  # Fallback to netstat
  elif command -v netstat &> /dev/null; then
    if ! netstat -tln 2>/dev/null | grep -q ":$port "; then
      log_info "Port $port is now available"
      return 0
    fi
  fi
  
  log_warn "Port $port is still in use"
  return 1
}

# Task 5.6-5.7: Complete port conflict resolution with error handling
resolve_port_conflict() {
  local port="${1:-80}"
  
  section_header "Port Conflict Resolution"
  
  log_info "Checking for conflicts on port $port"
  
  # Find processes using the port
  if ! check_port_available "$port"; then
    local pids
    mapfile -t pids < <(find_processes_on_port "$port")
    
    if [[ ${#pids[@]} -eq 0 ]]; then
      log_error "Port $port is in use but no processes could be identified"
      error_box "Port Check Error" "Port $port appears to be in use but no process could be found.\nThis may indicate a firewall rule or kernel issue."
      return 1
    fi
    
    # Ask for confirmation
    if ! confirm_process_termination "${pids[@]}"; then
      log_error "User declined port conflict resolution"
      return 1
    fi
    
    # Try to terminate processes
    local all_terminated=true
    for pid in "${pids[@]}"; do
      if ! terminate_process_graceful "$pid"; then
        # Try force kill as fallback
        if ! terminate_process_force "$pid"; then
          all_terminated=false
        fi
      fi
    done
    
    # Verify port is now available
    sleep 1
    if ! verify_port_available "$port"; then
      log_error "Failed to free port $port"
      error_box "Port Resolution Failed" "Could not terminate all processes using port $port.\n\nYou may need to manually kill these processes or restart your system."
      return 1
    fi
    
    info_box "✓ Port Freed" "Port $port is now available for certificate validation"
    log_info "Port $port successfully freed"
  else
    log_info "Port $port is available"
    info_box "✓ Port Available" "Port $port is available for certificate validation"
  fi
  
  return 0
}

#############################################################################
# SECTION 8: DNS POLLING & CACHE CLEARING (Tasks 5a.1-5c.5)
#############################################################################

# Task 5b.1: DNS cache detection function to identify system cache service
detect_dns_cache_method() {
  log_debug "Detecting DNS cache service on system"
  
  # Check for systemd-resolved
  if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
    log_info "Detected systemd-resolved as DNS cache service"
    echo "systemd-resolved"
    return 0
  fi
  
  # Check for nscd
  if systemctl is-active --quiet nscd 2>/dev/null; then
    log_info "Detected nscd as DNS cache service"
    echo "nscd"
    return 0
  fi
  
  # Check if nscd daemon is running
  if pgrep -x "nscd" > /dev/null 2>&1; then
    log_info "Detected nscd daemon"
    echo "nscd"
    return 0
  fi
  
  log_debug "No standard DNS cache service detected"
  echo "none"
  return 0
}

# Task 5b.2: Implement resolvectl flush-caches for systemd-resolved systems
flush_dns_cache_resolvectl() {
  log_debug "Attempting DNS cache flush via resolvectl"
  
  if ! command -v resolvectl &> /dev/null; then
    log_debug "resolvectl not available"
    return 1
  fi
  
  if resolvectl flush-caches 2>/dev/null; then
    log_info "DNS cache flushed via resolvectl"
    return 0
  else
    log_debug "resolvectl flush-caches failed"
    return 1
  fi
}

# Task 5b.3: Implement systemctl restart systemd-resolved as fallback
flush_dns_cache_systemctl() {
  log_debug "Attempting DNS cache flush via systemctl restart systemd-resolved"
  
  if ! systemctl is-active --quiet systemd-resolved 2>/dev/null; then
    log_debug "systemd-resolved not active"
    return 1
  fi
  
  if systemctl restart systemd-resolved 2>/dev/null; then
    log_info "DNS cache flushed via systemctl restart systemd-resolved"
    sleep 1  # Wait for service to restart
    return 0
  else
    log_debug "systemctl restart systemd-resolved failed"
    return 1
  fi
}

# Task 5b.4: Implement nscd -i hosts for nscd cache daemon
flush_dns_cache_nscd() {
  log_debug "Attempting DNS cache flush via nscd -i hosts"
  
  if ! command -v nscd &> /dev/null; then
    log_debug "nscd command not available"
    return 1
  fi
  
  if nscd -i hosts 2>/dev/null; then
    log_info "DNS cache flushed via nscd -i hosts"
    return 0
  else
    log_debug "nscd -i hosts failed"
    return 1
  fi
}

# Task 5b.5: Implement service nscd restart as nscd fallback
flush_dns_cache_nscd_restart() {
  log_debug "Attempting DNS cache flush via service nscd restart"
  
  if ! systemctl is-active --quiet nscd 2>/dev/null && ! pgrep -x "nscd" > /dev/null 2>&1; then
    log_debug "nscd service not running"
    return 1
  fi
  
  if systemctl restart nscd 2>/dev/null || service nscd restart 2>/dev/null; then
    log_info "DNS cache flushed via nscd restart"
    sleep 1
    return 0
  else
    log_debug "nscd restart failed"
    return 1
  fi
}

# Task 5b.6: Create fallback chain function (try methods in order, continue if all fail)
flush_dns_cache() {
  log_debug "Starting DNS cache flush sequence"
  
  # Try methods in order
  if flush_dns_cache_resolvectl; then
    echo "resolvectl"
    return 0
  fi
  
  if flush_dns_cache_systemctl; then
    echo "systemctl"
    return 0
  fi
  
  if flush_dns_cache_nscd; then
    echo "nscd"
    return 0
  fi
  
  if flush_dns_cache_nscd_restart; then
    echo "nscd-restart"
    return 0
  fi
  
  log_warn "DNS cache flush failed using all available methods"
  echo "none"
  return 1
}

# Task 5a.1-5a.2: DNS polling function that queries every 5 seconds
poll_dns_record() {
  local domain="$1"
  local expected_value="$2"
  local record_type="${3:-A}"
  local max_attempts="${4:-36}"  # 3 minutes with 5-second intervals
  local attempt=0
  local start_time
  start_time=$(date +%s)
  
  log_info "Starting DNS polling for $domain ($record_type record) - max $max_attempts attempts"
  
  section_header "DNS Propagation Monitoring"
  
  while [[ $attempt -lt $max_attempts ]]; do
    ((attempt++))
    
    # Flush DNS cache before query
    local cache_method
    cache_method=$(flush_dns_cache)
    local cache_status="[CACHE: ${cache_method:-NONE}]"
    
    # Query DNS
    local actual_value
    if [[ "$record_type" == "A" ]]; then
      actual_value=$(get_a_record "$domain" 2>/dev/null || echo "")
    else
      # For TXT and other records
      if command -v dig &> /dev/null; then
        actual_value=$(dig +short "$record_type" "$domain" 2>/dev/null | head -1)
      fi
    fi
    
    # Calculate elapsed time
    local current_time
    current_time=$(date +%s)
    local elapsed=$((current_time - start_time))
    local elapsed_min=$((elapsed / 60))
    local elapsed_sec=$((elapsed % 60))
    
    # Display progress
    if [[ -n "$actual_value" ]]; then
      if [[ "$actual_value" == "$expected_value" ]] || [[ -z "$expected_value" ]]; then
        # Match found
        local prop_time
        if [[ $elapsed -lt 60 ]]; then
          prop_time="${elapsed}s"
        else
          prop_time="${elapsed_min}m${elapsed_sec}s"
        fi
        
        info_box "✓ DNS Propagated" "Domain: $domain\nRecord Type: $record_type\nValue: $actual_value\nPropagation Time: $prop_time\n$cache_status"
        log_info "DNS record detected for $domain after ${prop_time}: $actual_value $cache_status"
        return 0
      fi
    fi
    
    # Display progress
    echo -ne "\rAttempt $attempt/$max_attempts (${elapsed_min}m${elapsed_sec}s) - Querying $domain... $cache_status"
    log_debug "Poll attempt $attempt: $domain not yet propagated (cache: $cache_method)"
    
    if [[ $attempt -lt $max_attempts ]]; then
      sleep 5
    fi
  done
  
  echo ""
  log_error "DNS polling timed out after $((max_attempts * 5)) seconds"
  error_box "DNS Propagation Timeout" "The DNS record for $domain was not detected within 3 minutes.\n\nPlease verify your DNS records are correctly set and try again."
  return 1
}

# Task 5a.3-5a.8: Progress display and logging (integrated into poll_dns_record above)

# Task 5a.5: Multiple DNS server checking
check_dns_on_multiple_servers() {
  local domain="$1"
  local record_type="${2:-A}"
  local -a results=()
  
  log_info "Checking $domain on multiple DNS servers"
  
  for dns_server in "${DNS_SERVERS[@]}"; do
    log_debug "Querying $domain on nameserver $dns_server"
    
    local result
    if command -v dig &> /dev/null; then
      result=$(dig +short "$record_type" "$domain" @"$dns_server" 2>/dev/null || echo "FAILED")
    else
      result="UNKNOWN"
    fi
    
    results+=("$dns_server: $result")
    log_info "$dns_server: $result"
  done
  
  # Display results
  local display=""
  for r in "${results[@]}"; do
    display="${display}${r}\n"
  done
  
  info_box "DNS Resolution Across Multiple Servers" "Domain: $domain\nRecord Type: $record_type\n\n${display}"
}

# Task 5a.7: Manual DNS check option
manual_dns_check() {
  local domain="$1"
  local record_type="${2:-A}"
  
  log_info "Offering manual DNS check option"
  
  section_header "Manual DNS Verification"
  
  info_box "Manual DNS Check Required" "Please run the following command on your local machine to verify the DNS record:\n\ndig +short $record_type $domain\n\nor\n\nnslookup -type=$record_type $domain\n\nEnter the result when prompted."
  
  read -p "Enter the DNS record value: " user_entry
  
  if [[ -n "$user_entry" ]]; then
    log_info "User provided manual DNS check result: $user_entry"
    echo "$user_entry"
    return 0
  else
    log_warn "No value provided for manual DNS check"
    return 1
  fi
}

#############################################################################
# SECTION 10: ERROR HANDLING & CLEANUP
#############################################################################

# Error trap handler
on_error() {
  local line_num="$1"
  local error_code="$2"

  log_error "Script error on line $line_num (exit code: $error_code)"

  if [[ "$error_code" -ne 130 ]]; then  # 130 is Ctrl+C
    error_box "Execution Error" "An error occurred on line $line_num with exit code $error_code.\n\nPlease review the logs at:\n$LOG_FILE"
  fi

  cleanup
  exit "$error_code"
}

# Cleanup function for temporary files
cleanup() {
  log_debug "Cleaning up temporary files..."

  if [[ -d "$TEMP_DIR" ]] && [[ -n "$TEMP_DIR" ]]; then
    if rm -rf "$TEMP_DIR" 2>/dev/null; then
      log_debug "Temporary directory cleaned up: $TEMP_DIR"
    fi
  fi

  log_info "Cleanup completed"
}

# Set error and exit traps
set_traps() {
  trap 'on_error ${LINENO} $?' ERR
  trap cleanup EXIT INT TERM
}

#############################################################################
# SECTION 11: MAIN WORKFLOW
#############################################################################

# Display banner
show_banner() {
  cat << "EOF"

     _____ _____ _     _    _ _   ______            _
    / ____|  __ \| |   | |  | (_) |___  /           | |
   | (___ | |  | | |   | |  | |_ _ __) / ___ _ __ __| |
    \___ \| |  | | |   | |  | | | |_ \ / _ \ '__/ _` |
    ____) | |__| | |___| |__| | | |___) |  __/ | | (_| |
   |_____/|_____/|______|\____/|_|_____/ \___|_|  \__,_| By Parsamrz

   Automated SSL/TLS Certificate Management Wizard
   Version 1.0.0 - https://github.com/parsamrz/auto-ssl-wizard
   ─────────────────────────────────────────────────

EOF
}

# Main entry point
main() {
  show_banner

  # Parse command line arguments
  DOMAIN="${1:-}"

  # Check if domain was provided
  if [[ -z "$DOMAIN" ]]; then
    log_error "Domain name is required"
    echo ""
    echo "Usage: $SCRIPT_NAME <domain>"
    echo ""
    echo "Example: $SCRIPT_NAME example.com"
    echo ""
    exit 1
  fi

  log_info "Starting SSL Wizard for domain: $DOMAIN"
  init_logging "$DOMAIN"

  # Set error traps
  set_traps

  log_info "Creating working directories..."
  mkdir -p "$OUTPUT_DIR/$DOMAIN"/{certs,keys,configs}
  mkdir -p "$TEMP_DIR"

  # Execute main workflow
  run_diagnostics
  check_dependencies

  # Placeholder for future features
  log_info "Main workflow milestone completed successfully"

  info_box "Next Steps" "The SSL Wizard is ready for certificate provisioning.\n\nFuture features will include:\n• DNS validation setup\n• Certificate issuance\n• Automatic renewal configuration"

  log_info "SSL Wizard execution completed"
  section_header "Execution Complete"
}

# Run main function with all arguments
main "$@"
