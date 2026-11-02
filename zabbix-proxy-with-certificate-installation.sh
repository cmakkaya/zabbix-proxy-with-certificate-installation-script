#!/bin/bash
# ==============================================================
#  Zabbix Proxy v7.4 Installation Script
#  Ubuntu 24.04 LTS | AMD64 | MySQL | Certificate TLS
#
#  Ref: https://www.zabbix.com/documentation/7.4/en/manual/
#       installation/install_from_packages/ubuntu
#
#  This script was prepared by DevOps Engineer Cumhur M. Akkaya.
#  For suggestions and feedback, please reach out via:
#  https://www.linkedin.com/in/cumhurakkaya/
#  https://cmakkaya.medium.com/
#  https://github.com/cmakkaya
# ==============================================================

# -------------------------------------------------------
# INTEGRITY PROTECTION
# The author block (lines 9-13) is protected by a SHA256 hash.
# DO NOT modify the author information block above.
# Changing it will cause the script to refuse execution.
# -------------------------------------------------------
AUTHOR_BLOCK_HASH="166004d84dd9cd4b69e465225c5e462f6ae423dfbcf4adccc071f0a09134cac9"
AUTHOR_BLOCK_LINES="9,13"

check_integrity() {
    local SCRIPT_PATH
    SCRIPT_PATH="$(realpath "$0")"
    local ACTUAL_HASH
    ACTUAL_HASH=$(sed -n "${AUTHOR_BLOCK_LINES}p" "${SCRIPT_PATH}" | sha256sum | awk '{print $1}')

    if [[ "${ACTUAL_HASH}" != "${AUTHOR_BLOCK_HASH}" ]]; then
        echo ""
        echo "============================================================"
        echo "  INTEGRITY CHECK FAILED"
        echo "============================================================"
        echo ""
        echo "  The author information block of this script has been"
        echo "  modified or removed. This script cannot be executed."
        echo ""
        echo "  This script was prepared by DevOps Engineer Cumhur M. Akkaya."
        echo "  Unauthorized modification of the authorship information"
        echo "  is not permitted."
        echo ""
        echo "  Contact : https://www.linkedin.com/in/cumhurakkaya/"
        echo "            https://cmakkaya.medium.com/"
        echo "            https://github.com/cmakkaya"
        echo ""
        echo "============================================================"
        exit 1
    fi
}

# -------------------------------------------------------
# TO INSTALL A DIFFERENT VERSION OF ZABBIX PROXY
# -------------------------------------------------------
# If you want to install a different version, update both
# PROXY_VERSION and ZABBIX_REPO_DEB lines below under
# the "FIXED VARIABLES" section.
# Example:
#   PROXY_VERSION="7.0.10"
#   ZABBIX_REPO_DEB="zabbix-release_latest_7.0+ubuntu24.04_all.deb"
#   ZABBIX_REPO_URL="https://repo.zabbix.com/zabbix/7.0/release/ubuntu/pool/main/z/zabbix-release/${ZABBIX_REPO_DEB}"
#
# Check the latest releases at:
#   https://repo.zabbix.com/zabbix/7.4/release/ubuntu/pool/main/z/zabbix-release/

# -------------------------------------------------------
# FIXED VARIABLES - Edit here if needed:
# -------------------------------------------------------
PROXY_VERSION="7.4"
ZABBIX_REPO_DEB="zabbix-release_latest_7.4+ubuntu24.04_all.deb"
ZABBIX_REPO_URL="https://repo.zabbix.com/zabbix/7.4/release/ubuntu/pool/main/z/zabbix-release/${ZABBIX_REPO_DEB}"

PFX_SOURCE_DIR="/home/administrator"
PFX_FILE="${PFX_SOURCE_DIR}/<your-file-name>.pfx"
PFX_PASSWORD="your-password"

WORK_DIR="/home/administrator"
ZABBIX_CONF_DIR="/etc/zabbix"
ZABBIX_PROXY_CONF="${ZABBIX_CONF_DIR}/zabbix_proxy.conf"

DB_NAME="your-db-name"
DB_USER="your-user"
DB_PASSWORD="your-password"
DB_ROOT_USER="root"

CERT_DEST_DIR="${ZABBIX_CONF_DIR}"

# -------------------------------------------------------
# COLOR DEFINITIONS
# -------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# -------------------------------------------------------
# HELPER FUNCTIONS
# -------------------------------------------------------
print_banner() {
    clear
    echo ""
    echo -e "${YELLOW}============================================================${NC}"
    echo -e "${YELLOW}  Welcome to the Zabbix Proxy v${PROXY_VERSION} Installation Script.${NC}"
    echo -e "${YELLOW}  Prepared for Ubuntu 24.04 LTS | AMD64 | MySQL | TLS Cert.${NC}"
    echo ""
    echo -e "${GRAY}  Ref: https://www.zabbix.com/documentation/7.4/en/manual/${NC}"
    echo -e "${GRAY}       installation/install_from_packages/ubuntu${NC}"
    echo ""
    echo -e "${CYAN}  This script was prepared by DevOps Engineer Cumhur M. Akkaya.${NC}"
    echo -e "${CYAN}  For suggestions, please contact via:${NC}"
    echo -e "${CYAN}  https://www.linkedin.com/in/cumhurakkaya/${NC}"
    echo -e "${CYAN}  https://cmakkaya.medium.com/${NC}"
    echo -e "${CYAN}  https://github.com/cmakkaya${NC}"
    echo -e "${YELLOW}============================================================${NC}"
    echo ""
}

print_step() {
    echo ""
    echo -e "${YELLOW}--------------------------------------------------------------${NC}"
    echo -e "${BOLD}${GREEN} STEP $1: $2${NC}"
    echo -e "${YELLOW}--------------------------------------------------------------${NC}"
}

print_ok() {
    echo -e "  ${GREEN}[OK]${NC} $1"
}

print_info() {
    echo -e "  ${CYAN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "  ${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "  ${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root. Please run: sudo -s"
        exit 1
    fi
}

press_enter_to_exit() {
    echo ""
    echo -e "${YELLOW}============================================================${NC}"
    echo -e "${CYAN}  Installation completed. Press [ENTER] to close the script.${NC}"
    echo -e "${YELLOW}============================================================${NC}"
    read -r
}

# -------------------------------------------------------
# PRE-FLIGHT CHECK
# -------------------------------------------------------
pre_flight_check() {
    print_banner

    echo -e "${BOLD}============================================================${NC}"
    echo -e "${BOLD}  PRE-FLIGHT CHECKLIST${NC}"
    echo -e "${BOLD}============================================================${NC}"
    echo ""
    echo -e "${CYAN}  Before proceeding, please confirm the following:${NC}"
    echo ""
    echo -e "  ${YELLOW}[?]${NC} Have you uploaded the file"
    echo -e "      ${BOLD}star_ngncloud_052026.pfx${NC}"
    echo -e "      to the directory ${BOLD}/home/administrator/${NC} on this server?"
    echo ""
    echo -e "      You can upload it from your laptop using:"
    echo -e "      ${GRAY}scp C:\\star_ngncloud_052026.pfx administrator@<SERVER_IP>:/home/administrator/${NC}"
    echo ""
    echo -e "  Type ${GREEN}yes${NC} to continue or ${RED}no${NC} to abort: "
    read -r CONFIRM

    if [[ "$CONFIRM" != "yes" && "$CONFIRM" != "YES" ]]; then
        echo ""
        print_error "Aborted by user. Please upload the PFX file first and re-run this script."
        echo ""
        press_enter_to_exit
        exit 1
    fi

    echo ""
    print_info "Checking if PFX file exists at ${PFX_FILE} ..."
    if ! ls -la "${PFX_FILE}" > /dev/null 2>&1; then
        echo ""
        print_error "File not found: ${PFX_FILE}"
        print_error "Please upload star_ngncloud_052026.pfx to /home/administrator/ and re-run this script."
        echo ""
        press_enter_to_exit
        exit 1
    fi
    print_ok "PFX file found: ${PFX_FILE}"
    ls -la "${PFX_FILE}"
}

# -------------------------------------------------------
# STEP 1: Install Zabbix Repository
# -------------------------------------------------------
step1_install_repo() {
    print_step "1" "Installing Zabbix ${PROXY_VERSION} Repository"

    cd /tmp || exit 1
    print_info "Downloading Zabbix repository package..."
    wget -q "${ZABBIX_REPO_URL}" -O "${ZABBIX_REPO_DEB}"
    if [[ $? -ne 0 ]]; then
        print_error "Failed to download Zabbix repository package."
        exit 1
    fi
    print_ok "Repository package downloaded."

    dpkg -i "${ZABBIX_REPO_DEB}"
    print_ok "Repository package installed."

    apt update -y
    print_ok "Package lists updated."
}

# -------------------------------------------------------
# STEP 2: Install Zabbix Proxy and MySQL
# -------------------------------------------------------
step2_install_proxy() {
    print_step "2" "Installing Zabbix Proxy (MySQL backend)"

    apt install -y zabbix-proxy-mysql zabbix-sql-scripts mysql-server
    if [[ $? -ne 0 ]]; then
        print_error "Installation failed. Check apt output above."
        exit 1
    fi
    print_ok "Zabbix Proxy and MySQL installed successfully."
}

# -------------------------------------------------------
# STEP 3: Create Database
# -------------------------------------------------------
step3_create_database() {
    print_step "3" "Creating MySQL Database for Zabbix Proxy"

    print_info "Creating database: ${DB_NAME}"
    print_info "Creating DB user: ${DB_USER}"

    mysql -u${DB_ROOT_USER} <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
SET GLOBAL log_bin_trust_function_creators = 1;
FLUSH PRIVILEGES;
EOF

    if [[ $? -ne 0 ]]; then
        print_error "Database creation failed."
        exit 1
    fi
    print_ok "Database and user created."

    print_info "Importing Zabbix proxy schema (this may take a moment)..."
    cat /usr/share/zabbix/sql-scripts/mysql/proxy.sql | \
        mysql --default-character-set=utf8mb4 -u${DB_USER} -p${DB_PASSWORD} ${DB_NAME}

    if [[ $? -ne 0 ]]; then
        print_error "Schema import failed."
        exit 1
    fi
    print_ok "Schema imported successfully."

    print_info "Disabling log_bin_trust_function_creators..."
    mysql -u${DB_ROOT_USER} -e "SET GLOBAL log_bin_trust_function_creators = 0;"
    print_ok "Done."
}

# -------------------------------------------------------
# STEP 4: Configure zabbix_proxy.conf
# -------------------------------------------------------
step4_configure_proxy() {
    print_step "4" "Configuring zabbix_proxy.conf"

    echo ""
    echo -e "  ${CYAN}Please enter the Zabbix Server IP address (e.g. 172.17.160.70):${NC}"
    read -r ZABBIX_SERVER_IP

    echo ""
    echo -e "  ${CYAN}Please enter the Proxy Hostname (e.g. ngn-zabbixproxy):${NC}"
    read -r PROXY_HOSTNAME

    if [[ -z "$ZABBIX_SERVER_IP" || -z "$PROXY_HOSTNAME" ]]; then
        print_error "Server IP and Hostname cannot be empty."
        exit 1
    fi

    print_info "Writing configuration to ${ZABBIX_PROXY_CONF} ..."

    # Backup original config
    cp "${ZABBIX_PROXY_CONF}" "${ZABBIX_PROXY_CONF}.bak.$(date +%Y%m%d%H%M%S)"
    print_ok "Original config backed up."

    # Apply settings using sed
    sed -i "s|^Server=.*|Server=${ZABBIX_SERVER_IP}|" "${ZABBIX_PROXY_CONF}"
    sed -i "s|^Hostname=.*|Hostname=${PROXY_HOSTNAME}|" "${ZABBIX_PROXY_CONF}"
    sed -i "s|^DBName=.*|DBName=${DB_NAME}|" "${ZABBIX_PROXY_CONF}"
    sed -i "s|^DBUser=.*|DBUser=${DB_USER}|" "${ZABBIX_PROXY_CONF}"
    # Remove any existing DBPassword line (commented or not) and append a clean one
    sed -i '/^[[:space:]]*#\?[[:space:]]*DBPassword=/d' "${ZABBIX_PROXY_CONF}"
    echo "DBPassword=${DB_PASSWORD}" >> "${ZABBIX_PROXY_CONF}"

    # Add TLS settings if not present
    grep -q "^TLSConnect" "${ZABBIX_PROXY_CONF}" || echo "TLSConnect=cert" >> "${ZABBIX_PROXY_CONF}"
    grep -q "^TLSAccept" "${ZABBIX_PROXY_CONF}" || echo "TLSAccept=cert" >> "${ZABBIX_PROXY_CONF}"
    grep -q "^TLSCertFile" "${ZABBIX_PROXY_CONF}" || echo "TLSCertFile=${CERT_DEST_DIR}/zabbix.crt" >> "${ZABBIX_PROXY_CONF}"
    grep -q "^TLSKeyFile" "${ZABBIX_PROXY_CONF}" || echo "TLSKeyFile=${CERT_DEST_DIR}/zabbix.key" >> "${ZABBIX_PROXY_CONF}"
    grep -q "^TLSCAFile" "${ZABBIX_PROXY_CONF}" || echo "TLSCAFile=${CERT_DEST_DIR}/ca.crt" >> "${ZABBIX_PROXY_CONF}"

    # Capture values for final info summary
    CONFIGURED_PROXY_HOSTNAME="${PROXY_HOSTNAME}"
    CONFIGURED_SERVER_IP="${ZABBIX_SERVER_IP}"
    # Detect this VM's primary IP address
    VM_IP=$(hostname -I | awk '{print $1}')
    export CONFIGURED_PROXY_HOSTNAME CONFIGURED_SERVER_IP VM_IP

    print_ok "Configuration written successfully."
}

# -------------------------------------------------------
# STEP 5: Convert PFX Certificate
# -------------------------------------------------------
step5_convert_certificates() {
    print_step "5" "Converting PFX Certificate"

    cd "${WORK_DIR}" || exit 1
    export SIFRENIZ="${PFX_PASSWORD}"

    print_info "Extracting host certificate (zabbix.crt)..."
    openssl pkcs12 -in "${PFX_FILE}" \
        -clcerts -nokeys -out zabbix.crt \
        -passin pass:${SIFRENIZ}
    if [[ $? -ne 0 ]]; then print_error "Failed to extract zabbix.crt"; exit 1; fi
    print_ok "zabbix.crt extracted."

    print_info "Extracting private key (zabbix.key)..."
    openssl pkcs12 -in "${PFX_FILE}" \
        -nocerts -nodes -out zabbix.key \
        -passin pass:${SIFRENIZ}
    if [[ $? -ne 0 ]]; then print_error "Failed to extract zabbix.key"; exit 1; fi
    print_ok "zabbix.key extracted."

    print_info "Verifying extracted files..."
    ls -la zabbix.crt zabbix.key
}

# -------------------------------------------------------
# STEP 6: Build Certificate Chain
# -------------------------------------------------------
step6_build_chain() {
    print_step "6" "Building Certificate Chain (CA Chain)"

    cd "${WORK_DIR}" || exit 1

    print_info "Downloading DigiCert Global Root G2 (DER format)..."
    wget -q -O digicert_root.crt https://cacerts.digicert.com/DigiCertGlobalRootG2.crt
    if [[ $? -ne 0 ]]; then print_error "Failed to download DigiCert root certificate."; exit 1; fi

    print_info "Converting DigiCert root to PEM format..."
    openssl x509 -inform DER -in digicert_root.crt -out digicert_root.pem
    print_ok "digicert_root.pem created."

    print_info "Verifying DigiCert root subject..."
    DIGICERT_SUBJECT=$(openssl x509 -in digicert_root.pem -noout -subject)
    print_info "Subject: ${DIGICERT_SUBJECT}"
    echo "${DIGICERT_SUBJECT}" | grep -q "DigiCert Global Root G2" || \
        print_warn "Unexpected subject for DigiCert root. Please verify manually."

    print_info "Downloading GeoTrust TLS RSA CA G1 intermediate certificate..."
    wget -q -O geotrust_intermediate.crt \
        https://cacerts.digicert.com/GeoTrustTLSRSACAG1.crt
    if [[ $? -ne 0 ]]; then print_error "Failed to download GeoTrust intermediate certificate."; exit 1; fi

    print_info "Converting GeoTrust intermediate to PEM format..."
    openssl x509 -inform DER -in geotrust_intermediate.crt -out geotrust_intermediate.pem
    print_ok "geotrust_intermediate.pem created."

    print_info "Verifying GeoTrust intermediate subject..."
    GEOTRUST_SUBJECT=$(openssl x509 -in geotrust_intermediate.pem -noout -subject)
    print_info "Subject: ${GEOTRUST_SUBJECT}"
    echo "${GEOTRUST_SUBJECT}" | grep -q "GeoTrust" || \
        print_warn "Unexpected subject for GeoTrust intermediate. Please verify manually."

    print_info "Building full certificate chain (ORDER IS CRITICAL)..."
    cat zabbix.crt geotrust_intermediate.pem digicert_root.pem > ca-chain.crt
    print_ok "ca-chain.crt created."

    print_info "Verifying certificate chain..."
    VERIFY_RESULT=$(openssl verify -CAfile ca-chain.crt zabbix.crt 2>&1)
    echo -e "  Verify result: ${VERIFY_RESULT}"
    echo "${VERIFY_RESULT}" | grep -q "OK" || \
        { print_error "Certificate chain verification FAILED. Please check certificates."; exit 1; }
    print_ok "Certificate chain verified successfully."

    print_info "Removing empty/invalid ca.crt if exists..."
    rm -f ca.crt
    print_ok "Cleanup done."
}

# -------------------------------------------------------
# STEP 7: Deploy Certificates to /etc/zabbix/
# -------------------------------------------------------
step7_deploy_certificates() {
    print_step "7" "Deploying Certificates to ${CERT_DEST_DIR}"

    cd "${WORK_DIR}" || exit 1

    print_info "Copying zabbix.crt ..."
    cp zabbix.crt "${CERT_DEST_DIR}/zabbix.crt"

    print_info "Copying zabbix.key ..."
    cp zabbix.key "${CERT_DEST_DIR}/zabbix.key"

    print_info "Copying ca-chain.crt as ca.crt ..."
    cp ca-chain.crt "${CERT_DEST_DIR}/ca.crt"

    print_info "Setting ownership and permissions..."
    chown zabbix:zabbix "${CERT_DEST_DIR}/ca.crt" \
                         "${CERT_DEST_DIR}/zabbix.crt" \
                         "${CERT_DEST_DIR}/zabbix.key"
    chmod 644 "${CERT_DEST_DIR}/ca.crt" "${CERT_DEST_DIR}/zabbix.crt"
    chmod 640 "${CERT_DEST_DIR}/zabbix.key"

    print_ok "Certificates deployed."
    ls -la "${CERT_DEST_DIR}/ca.crt" "${CERT_DEST_DIR}/zabbix.crt" "${CERT_DEST_DIR}/zabbix.key"
}

# -------------------------------------------------------
# STEP 8: Start and Enable Zabbix Proxy Service
# -------------------------------------------------------
step8_start_service() {
    print_step "8" "Starting and Enabling Zabbix Proxy Service"

    systemctl restart zabbix-proxy
    sleep 2
    systemctl enable zabbix-proxy

    STATUS=$(systemctl is-active zabbix-proxy)
    if [[ "$STATUS" == "active" ]]; then
        print_ok "Zabbix Proxy service is running."
    else
        print_error "Zabbix Proxy service failed to start. Check logs below:"
        echo ""
        tail -20 /var/log/zabbix/zabbix_proxy.log
        exit 1
    fi

    echo ""
    print_info "Service status:"
    systemctl status zabbix-proxy --no-pager
    echo ""
    print_info "Last 20 log lines:"
    tail -20 /var/log/zabbix/zabbix_proxy.log
}

# -------------------------------------------------------
# FINAL INFO: UI Configuration Summary
# -------------------------------------------------------
print_final_info() {
    echo ""
    echo -e "${YELLOW}============================================================${NC}"
    echo -e "${BOLD}${GREEN}  INSTALLATION COMPLETE!${NC}"
    echo -e "${YELLOW}============================================================${NC}"
    echo ""
    echo -e "${BOLD}  DATABASE INFORMATION (for reference):${NC}"
    echo -e "  ${CYAN}  DBName     :${NC} ${DB_NAME}"
    echo -e "  ${CYAN}  DBUser     :${NC} ${DB_USER}"
    echo -e "  ${CYAN}  DBPassword :${NC} ${DB_PASSWORD}"
    echo ""
    echo -e "${BOLD}  CERTIFICATE FILES DEPLOYED:${NC}"
    echo -e "  ${CYAN}  TLSCAFile   :${NC} ${CERT_DEST_DIR}/ca.crt"
    echo -e "  ${CYAN}  TLSCertFile :${NC} ${CERT_DEST_DIR}/zabbix.crt"
    echo -e "  ${CYAN}  TLSKeyFile  :${NC} ${CERT_DEST_DIR}/zabbix.key"
    echo ""
    echo -e "${YELLOW}--------------------------------------------------------------${NC}"
    echo -e "${BOLD}  STEP 9 (MANUAL): Update Zabbix UI${NC}"
    echo -e "${YELLOW}--------------------------------------------------------------${NC}"
    echo ""
    echo -e "  ${BOLD}--- 9.1  Proxy Tab ---${NC}"
    echo -e "  Navigate to:"
    echo -e "  ${CYAN}  Administration → Proxies → Add (or select existing) → Proxy${NC}"
    echo ""
    echo -e "  ${BOLD}  Field                   Value${NC}"
    echo -e "  ┌────────────────────────┬──────────────────────────────┐"
    printf  "  │ %-22s │ %-28s │\n" "Proxy name"    "${CONFIGURED_PROXY_HOSTNAME}"
    printf  "  │ %-22s │ %-28s │\n" "Proxy address" "${VM_IP}"
    echo -e "  └────────────────────────┴──────────────────────────────┘"
    echo ""
    echo -e "  ${BOLD}--- 9.2  Encryption Tab ---${NC}"
    echo -e "  Navigate to:"
    echo -e "  ${CYAN}  Administration → Proxies → ${CONFIGURED_PROXY_HOSTNAME} → Encryption${NC}"
    echo ""
    echo -e "  Apply the following settings:"
    echo ""
    echo -e "  ${BOLD}  Field                   Value${NC}"
    echo -e "  ┌────────────────────────┬──────────────┐"
    echo -e "  │ Connections to proxy   │ Certificate  │"
    echo -e "  │ Connections from proxy │ Certificate  │"
    echo -e "  │ Issuer                 │ (leave empty)│"
    echo -e "  │ Subject                │ (leave empty)│"
    echo -e "  └────────────────────────┴──────────────┘"
    echo ""
    echo -e "  Click ${GREEN}[Update]${NC} to save."
    echo ""
    echo -e "${YELLOW}--------------------------------------------------------------${NC}"
    echo -e "${BOLD}  VERIFICATION COMMANDS:${NC}"
    echo -e "${YELLOW}--------------------------------------------------------------${NC}"
    echo ""
    echo -e "  ${GRAY}systemctl status zabbix-proxy${NC}"
    echo -e "  ${GRAY}tail -f /var/log/zabbix/zabbix_proxy.log${NC}"
    echo -e "  ${GRAY}ls -la /etc/zabbix/*.crt /etc/zabbix/*.key${NC}"
    echo ""
    echo -e "${YELLOW}============================================================${NC}"
}

# -------------------------------------------------------
# MAIN - Execution Order
# -------------------------------------------------------
check_integrity
check_root
pre_flight_check
step1_install_repo
step2_install_proxy
step3_create_database
step4_configure_proxy
step5_convert_certificates
step6_build_chain
step7_deploy_certificates
step8_start_service
print_final_info

echo ""
echo -e "${YELLOW}  Press [ENTER] to close the script...${NC}"
read -r
