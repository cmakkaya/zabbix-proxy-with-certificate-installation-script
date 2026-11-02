# zabbix-proxy-with-certificate-installation-script

This script installs Zabbix Proxy 7.4 (or a different version) on Ubuntu with a MySQL backend and certificate-based TLS encryption.

Automates the installation and configuration of Zabbix Proxy 7.4 on Ubuntu 24.04 LTS (AMD64) with a MySQL backend and certificate-based TLS encryption. The script handles Zabbix repository setup, package installation, MySQL database and schema creation, proxy configuration, PFX certificate extraction, CA certificate chain generation and verification, certificate deployment, and service startup. It also includes pre-installation checks, author integrity protection, automatic configuration backups, and post-installation verification instructions. After completing the automated steps, it guides the administrator through the remaining Zabbix frontend proxy and encryption configuration.

## Configuration – Customize Before Running

Before executing the script, edit the following variables in the FIXED VARIABLES section according to your environment:

### PFX Certificate Configuration

```sh
PFX_SOURCE_DIR="/home/administrator"
PFX_FILE="${PFX_SOURCE_DIR}/<your-file-name>.pfx"
PFX_PASSWORD="your-password"
```

### MySQL Database Configuration
```sh
DB_NAME="your-db-name"
DB_USER="your-user"
DB_PASSWORD="your-password"
```
Replace the placeholder values with your own certificate filename, PFX password, database name, database username, and database password.

### Here are some additional values users should check in their own environment.

```sh
Variable	                  Default                             value	Action
PFX_SOURCE_DIR	            /home/administrator	                Change if the PFX file is stored elsewhere.
PFX_FILE	                 <your-file-name>.pfx	              Set your own PFX filename.
PFX_PASSWORD	              your-password	                      Enter your PFX password.
DB_NAME	                    your-db-name	                      Set your database name.
DB_USER	                    your-user	                          Set your database username.
DB_PASSWORD	                your-password	                      Set a secure database password.
DB_ROOT_USER	              root	                              Change if your MySQL administrative account uses a different username.
WORK_DIR	                  /home/administrator	                Change this if you want to use a different working directory.
PROXY_VERSION	              7.4	                                Change if installing another Zabbix Proxy version.
ZABBIX_REPO_DEB	            Zabbix 7.4 repository package	      Must match the selected Zabbix version and Ubuntu release.
ZABBIX_REPO_URL	            Zabbix 7.4 repository URL	          Must match the selected repository package.
```

### Values ​​requested from the user while the script is running:

These are not predefined among the variables; they are entered interactively while the script is running:

```sh
- Zabbix Server IP Address: The IP address of the Zabbix Server. 
- Proxy Hostname: The proxy hostname you will define on the Zabbix frontend.
```

### Notes:

```sh
Upload your PFX certificate to the configured PFX_SOURCE_DIR before running the script.

Make sure the PFX password is correct.

Ensure the server has internet access to download Zabbix packages and CA certificates.

Run the script with root privileges.

The script currently downloads DigiCert Global Root G2 and GeoTrust TLS RSA CA G1 certificates. These must match your certificate's actual issuer chain. If you use a different certificate authority, update the certificate-chain section accordingly.

Complete the remaining Proxy and TLS encryption configuration manually through the Zabbix frontend.
```
