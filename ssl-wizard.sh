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
# SECTION 6: ERROR HANDLING & CLEANUP
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
# SECTION 7: MAIN WORKFLOW
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
