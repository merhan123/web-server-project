#!/bin/bash
# Shared validation for the RHEL-style Apache lab scripts.
set -euo pipefail
vhostsdir=/etc/httpd/conf.d/vhosts
certdir=/etc/httpd/conf.d/certificate
apachedir=/var/www

fail() { printf '%s\n' "$*" >&2; exit 1; }
require_root() { [[ $(id -u) == 0 ]] || fail 'Run this command with sudo.'; }
validate_domain() {
    local label
    [[ ${#domain} -le 253 && $domain =~ ^[A-Za-z0-9.-]+$ ]] || fail 'Invalid domain.'
    [[ $domain != .* && $domain != *. && $domain != *..* ]] || fail 'Invalid domain.'
    local -a labels
    IFS=. read -ra labels <<< "$domain"
    for label in "${labels[@]}"; do
        [[ ${#label} -le 63 && $label =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$ ]] || fail 'Invalid domain label.'
    done
}
reload_config() { apachectl configtest && systemctl reload httpd; }
