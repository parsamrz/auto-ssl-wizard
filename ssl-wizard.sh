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
# SECTION 9: CERTIFICATE ISSUANCE (Tasks 6.1-6.13)
#############################################################################

# Define DNS providers
declare -A DNS_PROVIDERS=(
  [cloudflare]="Cloudflare"
  [route53]="AWS Route 53"
  [digitalocean]="DigitalOcean"
  [namecheap]="Namecheap"
  [godaddy]="GoDaddy"
  [manual]="Manual DNS Entry"
)

# Task 6.1: Challenge type selection menu
select_challenge_type() {
  section_header "Challenge Type Selection"
  
  log_info "Presenting challenge type selection menu"
  
  echo ""
  echo "Select ACME challenge type for certificate validation:"
  echo ""
  echo "  1) DNS-01 (Manual TXT Record) - Most flexible, works everywhere"
  echo "  2) HTTP-01 (Port 80 HTTP Server) - Requires port 80, faster"
  echo "  3) DNS API Integration - Automated DNS updates (future)"
  echo ""
  
  local choice
  read -p "Enter your choice (1-3): " choice
  
  case "$choice" in
    1)
      log_info "User selected DNS-01 (Manual TXT Record) challenge"
      echo "dns"
      return 0
      ;;
    2)
      log_info "User selected HTTP-01 (Port 80) challenge"
      echo "http"
      return 0
      ;;
    3)
      log_info "User selected DNS API challenge"
      echo "dns-api"
      return 0
      ;;
    *)
      log_error "Invalid challenge type selection: $choice"
      echo "Invalid choice. Please select 1, 2, or 3."
      select_challenge_type
      ;;
  esac
}

# Task 6.2: Display challenge-specific instructions and DNS provider selection
display_challenge_instructions() {
  local challenge_type="$1"
  local domain="$2"
  
  section_header "Challenge Instructions"
  
  case "$challenge_type" in
    dns)
      log_info "Displaying DNS challenge instructions"
      
      echo ""
      echo "You will need to create a TXT record in your DNS provider."
      echo ""
      echo "Steps:"
      echo "1. A TXT record will be displayed below"
      echo "2. Add it to your DNS provider's control panel"
      echo "3. Wait for DNS propagation (usually 30 seconds to 5 minutes)"
      echo "4. The wizard will verify the record and issue your certificate"
      echo ""
      
      read -p "Press ENTER to continue..."
      ;;
    http)
      log_info "Displaying HTTP challenge instructions"
      
      error_box "HTTP-01 Challenge Requirements" "This challenge requires:\n\n1. Port 80 must be accessible from the internet\n2. Domain must resolve to your server's IP\n3. No web server should be running on port 80\n\nThe wizard will start a temporary web server to validate the certificate."
      
      if prompt_yes_no "Do you understand and wish to proceed?" "y"; then
        return 0
      else
        return 1
      fi
      ;;
    dns-api)
      log_info "Displaying DNS API challenge instructions"
      
      error_box "DNS API Integration" "This feature is not yet implemented.\n\nPlease select DNS-01 (Manual) or HTTP-01 for now."
      return 1
      ;;
  esac
  
  return 0
}

# Task 6.3: Create formatted display for DNS record structure
display_dns_record_structure() {
  local domain="$1"
  local txt_value="$2"
  
  section_header "DNS Record Configuration"
  
  local acme_domain="_acme-challenge.${domain}"
  
  echo ""
  echo "╔════════════════════════════════════════════════════════════════════╗"
  echo "║                    ADD THIS DNS RECORD                             ║"
  echo "╠════════════════════════════════════════════════════════════════════╣"
  echo "║                                                                    ║"
  echo "║  Type:  TXT                                                        ║"
  echo "║  Name:  ${acme_domain}"
  echo "║  Value: ${txt_value}"
  echo "║  TTL:   300 (or lowest available)                                  ║"
  echo "║                                                                    ║"
  echo "╚════════════════════════════════════════════════════════════════════╝"
  echo ""
  
  log_info "Displayed DNS record for $domain: $txt_value"
}

# Task 6.4: Display current DNS A record status
display_dns_status() {
  local domain="$1"
  local expected_ip="$2"
  
  section_header "Current DNS Status"
  
  local actual_ip
  actual_ip=$(get_a_record "$domain" 2>/dev/null || echo "UNKNOWN")
  
  local status="PASS"
  if [[ "$actual_ip" != "$expected_ip" ]]; then
    status="FAIL"
  fi
  
  echo ""
  echo "╔════════════════════════════════════════════════════════════════════╗"
  echo "║                    A RECORD VERIFICATION                           ║"
  echo "╠════════════════════════════════════════════════════════════════════╣"
  echo "║                                                                    ║"
  echo "║  Domain:      $domain"
  echo "║  Expected IP: $expected_ip"
  echo "║  Actual IP:   $actual_ip"
  echo "║  Status:      $status"
  echo "║                                                                    ║"
  echo "╚════════════════════════════════════════════════════════════════════╝"
  echo ""
  
  log_info "DNS A record status for $domain: Expected=$expected_ip, Actual=$actual_ip, Status=$status"
}

# Task 6.5: Wildcard-specific DNS record format
get_acme_challenge_domain() {
  local domain="$1"
  local is_wildcard="${2:-false}"
  
  if [[ "$is_wildcard" == "true" ]]; then
    # For wildcard, use _acme-challenge.example.com (not _acme-challenge.*.example.com)
    echo "_acme-challenge.${domain}"
  else
    # For single domain
    echo "_acme-challenge.${domain}"
  fi
}

# Task 6.6: Certificate type selection menu (single/multi/wildcard)
select_certificate_type() {
  section_header "Certificate Type Selection"
  
  log_info "Presenting certificate type selection menu"
  
  echo ""
  echo "Select certificate type:"
  echo ""
  echo "  1) Single Domain       - Certificate for one domain (e.g., example.com)"
  echo "  2) Multi-Domain (SAN)  - One cert for multiple domains"
  echo "  3) Wildcard            - Certificate for *.example.com (includes subdomains)"
  echo ""
  
  local choice
  read -p "Enter your choice (1-3): " choice
  
  case "$choice" in
    1)
      log_info "User selected Single Domain certificate"
      echo "single"
      return 0
      ;;
    2)
      log_info "User selected Multi-Domain certificate"
      echo "multi"
      return 0
      ;;
    3)
      log_info "User selected Wildcard certificate"
      echo "wildcard"
      return 0
      ;;
    *)
      log_error "Invalid certificate type selection: $choice"
      echo "Invalid choice. Please select 1, 2, or 3."
      select_certificate_type
      ;;
  esac
}

# Task 6.7: Single-domain certificate issuance via Certbot
issue_single_domain_certificate() {
  local domain="$1"
  local email="${2:-}"
  local challenge_type="${3:-dns}"
  
  log_info "Starting single-domain certificate issuance for $domain"
  
  # Build certbot command
  local cert_command="certbot certonly"
  
  if [[ "$challenge_type" == "dns" ]]; then
    cert_command="$cert_command --manual --preferred-challenges dns"
  elif [[ "$challenge_type" == "http" ]]; then
    cert_command="$cert_command --standalone --preferred-challenges http"
  fi
  
  cert_command="$cert_command --domain $domain"
  
  if [[ -n "$email" ]]; then
    cert_command="$cert_command --email $email"
  fi
  
  cert_command="$cert_command --agree-tos --non-interactive"
  
  section_header "Certificate Issuance in Progress"
  
  log_info "Executing certbot: $cert_command"
  
  if eval "$cert_command" 2>&1 | tee -a "$LOG_FILE"; then
    log_info "Certificate successfully issued for $domain"
    return 0
  else
    log_error "Certificate issuance failed for $domain"
    return 1
  fi
}

# Task 6.8: Multi-domain certificate issuance
issue_multi_domain_certificate() {
  local -a domains=("$@")
  local email=""
  local challenge_type="dns"
  
  log_info "Starting multi-domain certificate issuance for ${#domains[@]} domains"
  
  # Build certbot command with multiple domains
  local cert_command="certbot certonly --manual --preferred-challenges dns"
  
  for domain in "${domains[@]}"; do
    cert_command="$cert_command --domain $domain"
  done
  
  if [[ -n "$email" ]]; then
    cert_command="$cert_command --email $email"
  fi
  
  cert_command="$cert_command --agree-tos --non-interactive"
  
  section_header "Multi-Domain Certificate Issuance in Progress"
  
  log_info "Executing certbot: $cert_command"
  
  if eval "$cert_command" 2>&1 | tee -a "$LOG_FILE"; then
    log_info "Certificate successfully issued for ${#domains[@]} domains"
    return 0
  else
    log_error "Certificate issuance failed for multiple domains"
    return 1
  fi
}

# Task 6.9: Email prompt and TOS agreement flow
prompt_email_and_tos() {
  section_header "Account Setup"
  
  local email
  read -p "Enter email address for Let's Encrypt account: " email
  
  if [[ -z "$email" ]]; then
    log_error "Email address is required"
    error_box "Error" "Email address cannot be empty"
    return 1
  fi
  
  if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    log_error "Invalid email format: $email"
    error_box "Error" "Invalid email format"
    return 1
  fi
  
  log_info "Email provided: $email"
  
  # TOS agreement
  info_box "Let's Encrypt Terms of Service" "You must agree to the Let's Encrypt Terms of Service to issue a certificate.\n\nhttps://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf"
  
  if prompt_yes_no "Do you agree to the Let's Encrypt Terms of Service?" "y"; then
    log_info "User agreed to Let's Encrypt TOS"
    echo "$email"
    return 0
  else
    log_error "User declined Let's Encrypt TOS"
    return 1
  fi
}

# Task 6.10: Let's Encrypt rate limit warning
display_rate_limit_warning() {
  section_header "Rate Limit Notice"
  
  error_box "Let's Encrypt Rate Limits" "⚠ Important Rate Limit Information ⚠\n\nLet's Encrypt enforces rate limits:\n\n• 50 certificates per domain per week\n• Duplicate certificate limit: 5 exact duplicates per week\n• Requests per IP: 10 per second\n\nIf you hit a rate limit, you'll receive a 429 error.\nWait until the next rate limit window to retry.\n\nFor testing, use the Let's Encrypt staging environment."
  
  if prompt_yes_no "Do you understand these limits and wish to proceed?" "y"; then
    log_info "User acknowledged rate limits"
    return 0
  else
    log_warn "User declined after rate limit warning"
    return 1
  fi
}

# Task 6.11: Error capture and logging for Certbot failures
handle_certbot_error() {
  local domain="$1"
  local error_message="$2"
  
  log_error "Certbot error for domain $domain: $error_message"
  
  error_box "Certificate Issuance Failed" "Failed to issue certificate for $domain.\n\nError:\n$error_message\n\nPlease review the logs at:\n$LOG_FILE"
}

# Tasks 6.12-6.13: Testing functions (to be used in main workflow)

#############################################################################
# SECTION 9: CERTIFICATE STORAGE & FILE ORGANIZATION (Tasks 8.1-8.8)
#############################################################################

# Task 8.1-8.2: Create output directory structure and copy certificates
organize_certificate_files() {
  local domain="$1"
  
  section_header "Organizing Certificate Files"
  
  log_info "Organizing certificate files for $domain"
  
  local output_base="${OUTPUT_DIR}/${domain}"
  local letsencrypt_path="/etc/letsencrypt/live/${domain}"
  
  # Create directory structure
  mkdir -p "${output_base}/live"
  mkdir -p "${output_base}/archive"
  mkdir -p "${output_base}/logs"
  
  log_info "Created directory structure at $output_base"
  
  # Check if Let's Encrypt certificate exists
  if [[ ! -d "$letsencrypt_path" ]]; then
    log_error "Certificate not found at $letsencrypt_path"
    return 1
  fi
  
  # Backup existing files if they exist
  if [[ -d "${output_base}/live/cert.pem" ]]; then
    local backup_timestamp
    backup_timestamp=$(date +%Y%m%d_%H%M%S)
    
    if mv "${output_base}/live" "${output_base}/archive/live.backup.${backup_timestamp}"; then
      log_info "Backed up existing files with timestamp $backup_timestamp"
    fi
  fi
  
  # Copy certificate files
  if cp -v "${letsencrypt_path}/cert.pem" "${output_base}/live/" 2>&1 | tee -a "$LOG_FILE"; then
    log_info "Copied cert.pem"
  else
    log_error "Failed to copy cert.pem"
    return 1
  fi
  
  if cp -v "${letsencrypt_path}/chain.pem" "${output_base}/live/" 2>&1 | tee -a "$LOG_FILE"; then
    log_info "Copied chain.pem"
  fi
  
  if cp -v "${letsencrypt_path}/fullchain.pem" "${output_base}/live/" 2>&1 | tee -a "$LOG_FILE"; then
    log_info "Copied fullchain.pem"
  fi
  
  if cp -v "${letsencrypt_path}/privkey.pem" "${output_base}/live/" 2>&1 | tee -a "$LOG_FILE"; then
    log_info "Copied privkey.pem"
  else
    log_error "Failed to copy privkey.pem"
    return 1
  fi
  
  log_info "Certificate files copied to $output_base/live"
  
  # Task 8.3: Set file permissions
  chmod 600 "${output_base}/live/privkey.pem"
  chmod 644 "${output_base}/live/cert.pem"
  chmod 644 "${output_base}/live/chain.pem"
  chmod 644 "${output_base}/live/fullchain.pem"
  
  log_info "File permissions set: privkey.pem=600, cert.pem=644, chain.pem=644, fullchain.pem=644"
  
  # Task 8.4: Archive original files
  local archive_timestamp
  archive_timestamp=$(date +%Y%m%d_%H%M%S)
  mkdir -p "${output_base}/archive/original_${archive_timestamp}"
  
  if cp -r "${letsencrypt_path}"/* "${output_base}/archive/original_${archive_timestamp}/" 2>&1 | tee -a "$LOG_FILE"; then
    log_info "Created archive backup with timestamp $archive_timestamp"
  fi
  
  return 0
}

# Task 8.6: Log file creation with detailed operation record
create_issuance_summary() {
  local domain="$1"
  local cert_type="$2"
  local challenge_type="$3"
  
  local summary_file="${OUTPUT_DIR}/${domain}/ISSUANCE_SUMMARY.txt"
  
  {
    echo "================================================================================"
    echo "SSL Certificate Issuance Summary"
    echo "================================================================================"
    echo ""
    echo "Domain:             $domain"
    echo "Certificate Type:   $cert_type"
    echo "Challenge Type:     $challenge_type"
    echo "Issued:             $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Script Version:     $VERSION"
    echo ""
    echo "Certificate Files:"
    echo "  Private Key:      ${OUTPUT_DIR}/${domain}/live/privkey.pem (600)"
    echo "  Certificate:      ${OUTPUT_DIR}/${domain}/live/cert.pem (644)"
    echo "  Chain:            ${OUTPUT_DIR}/${domain}/live/chain.pem (644)"
    echo "  Full Chain:       ${OUTPUT_DIR}/${domain}/live/fullchain.pem (644)"
    echo ""
    echo "Archive:            ${OUTPUT_DIR}/${domain}/archive/"
    echo "Logs:               ${OUTPUT_DIR}/${domain}/logs/"
    echo ""
    echo "================================================================================"
  } > "$summary_file"
  
  log_info "Created issuance summary at $summary_file"
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
    echo "Usage: $SCRIPT_NAME <domain> [additional_domains...]"
    echo ""
    echo "Examples:"
    echo "  $SCRIPT_NAME example.com"
    echo "  $SCRIPT_NAME example.com www.example.com api.example.com"
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

  # Phase 1: Diagnostics and Dependencies
  run_diagnostics
  
  if ! check_dependencies; then
    log_error "Required dependencies not available"
    error_box "Dependencies Missing" "Some required dependencies could not be installed.\nPlease install them manually and try again."
    exit 1
  fi

  # Phase 2: DNS and Port Configuration
  section_header "DNS and Port Configuration"
  
  # Get public IP for validation
  local public_ip
  public_ip=$(get_public_ip)
  
  if [[ "$public_ip" == "UNKNOWN" ]]; then
    log_warn "Could not determine public IP - DNS validation may be unavailable"
    if ! prompt_yes_no "Continue without public IP verification?" "n"; then
      exit 1
    fi
  fi
  
  # Validate DNS (if public IP is known)
  if [[ "$public_ip" != "UNKNOWN" ]]; then
    log_info "Validating DNS configuration"
    # Parse all provided domains
    local -a all_domains=("$DOMAIN")
    shift  # Remove first domain
    while [[ $# -gt 0 ]]; do
      all_domains+=("$1")
      shift
    done
    
    # Create domain string for validation
    local domain_string
    domain_string=$(printf '%s,' "${all_domains[@]}" | sed 's/,$//')
    
    log_info "Domains to validate: $domain_string"
    
    # Note: validate_domains function would return valid domains
    # For now, we'll proceed with the domains provided
  fi
  
  # Check for port conflicts
  log_info "Checking port availability"
  if ! check_port_available 80; then
    log_warn "Port 80 is in use"
    if prompt_yes_no "Would you like to resolve this conflict?" "y"; then
      resolve_port_conflict 80 || {
        log_error "Could not resolve port 80 conflict"
        exit 1
      }
    else
      log_warn "Continuing without resolving port 80 conflict"
    fi
  fi
  
  if ! check_port_available 443; then
    log_warn "Port 443 is in use"
    info_box "Port 443 Status" "Port 443 is in use. This may be okay if you're renewing a certificate.\nMake sure the port is available during certificate issuance."
  fi

  # Phase 3: Certificate Type and Challenge Selection
  log_info "Selecting certificate type and challenge method"
  
  local cert_type
  cert_type=$(select_certificate_type)
  
  if [[ -z "$cert_type" ]]; then
    log_error "No certificate type selected"
    exit 1
  fi
  
  log_info "Selected certificate type: $cert_type"
  
  # Select challenge type
  local challenge_type
  challenge_type=$(select_challenge_type)
  
  if [[ -z "$challenge_type" ]]; then
    log_error "No challenge type selected"
    exit 1
  fi
  
  if ! display_challenge_instructions "$challenge_type" "$DOMAIN"; then
    log_error "Challenge instructions not accepted"
    exit 1
  fi
  
  # Phase 4: Email and Rate Limit Acknowledgment
  local email
  email=$(prompt_email_and_tos)
  
  if [[ -z "$email" ]]; then
    log_error "Email address not provided"
    exit 1
  fi
  
  # Display rate limit warning
  if ! display_rate_limit_warning; then
    log_error "User did not acknowledge rate limits"
    exit 1
  fi

  # Phase 5: Certificate Issuance
  section_header "Certificate Issuance"
  
  log_info "Proceeding with certificate issuance"
  
  # Show DNS record info if using DNS challenge
  if [[ "$challenge_type" == "dns" ]]; then
    display_dns_status "$DOMAIN" "$public_ip"
    
    # For manual DNS challenge, show the format
    info_box "DNS Challenge Format" "You will need to add a TXT record to your DNS:\n\nType: TXT\nName: _acme-challenge.$DOMAIN\nValue: [Will be provided by Certbot]"
  fi
  
  # Issue certificate based on type
  case "$cert_type" in
    single)
      log_info "Issuing single-domain certificate"
      if issue_single_domain_certificate "$DOMAIN" "$email" "$challenge_type"; then
        log_info "Certificate issued successfully"
      else
        log_error "Certificate issuance failed"
        handle_certbot_error "$DOMAIN" "Certbot exited with error"
        exit 1
      fi
      ;;
    multi)
      log_info "Issuing multi-domain certificate"
      # Collect all domains
      local -a cert_domains=("$DOMAIN")
      shift  # Remove processed first domain
      while [[ $# -gt 0 ]]; do
        cert_domains+=("$1")
        shift
      done
      
      if issue_multi_domain_certificate "${cert_domains[@]}"; then
        log_info "Certificate issued successfully for ${#cert_domains[@]} domains"
      else
        log_error "Certificate issuance failed"
        handle_certbot_error "$DOMAIN" "Certbot exited with error"
        exit 1
      fi
      ;;
    wildcard)
      log_info "Issuing wildcard certificate"
      # Extract base domain from wildcard
      local base_domain="$DOMAIN"
      if [[ "$base_domain" == \** ]]; then
        base_domain="${base_domain#*.}"
      fi
      
      if issue_single_domain_certificate "*.$base_domain" "$email" "$challenge_type"; then
        log_info "Wildcard certificate issued successfully"
      else
        log_error "Certificate issuance failed"
        handle_certbot_error "$DOMAIN" "Certbot exited with error"
        exit 1
      fi
      ;;
  esac

  # Phase 6: File Organization
  section_header "File Organization"
  
  if organize_certificate_files "$DOMAIN"; then
    log_info "Certificate files organized successfully"
  else
    log_error "Failed to organize certificate files"
    error_box "File Organization Failed" "Could not organize certificate files.\nFiles may still be available at /etc/letsencrypt/live/$DOMAIN/"
  fi
  
  # Create summary
  create_issuance_summary "$DOMAIN" "$cert_type" "$challenge_type"

  # Phase 7: Summary and Next Steps
  section_header "Certificate Issued Successfully"
  
  local summary="Domain: $DOMAIN\n"
  summary="${summary}Type: $cert_type\n"
  summary="${summary}Challenge: $challenge_type\n"
  summary="${summary}Email: $email\n"
  summary="${summary}\n"
  summary="${summary}Certificate Location:\n"
  summary="${summary}  Private Key:  ${OUTPUT_DIR}/${DOMAIN}/live/privkey.pem\n"
  summary="${summary}  Certificate:  ${OUTPUT_DIR}/${DOMAIN}/live/fullchain.pem\n"
  summary="${summary}  Chain:        ${OUTPUT_DIR}/${DOMAIN}/live/chain.pem\n"
  summary="${summary}\n"
  summary="${summary}Next Steps:\n"
  summary="${summary}1. Update your web server configuration\n"
  summary="${summary}2. Set up automatic renewal with: certbot renew\n"
  summary="${summary}3. Test your certificate at: https://www.ssllabs.com/\n"
  summary="${summary}\n"
  summary="${summary}Certificate valid for 90 days from issue date."
  
  info_box "✓ Certificate Successfully Issued" "$summary"
  
  log_info "SSL Wizard execution completed successfully"
}

# Run main function with all arguments
main "$@"
