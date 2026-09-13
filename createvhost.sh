#!/bin/bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
require_root
[[ $# == 2 ]] || fail "Usage: $0 DOMAIN IPV4_ADDRESS"
domain=$1
listen_ip=$2
validate_domain
[[ $listen_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail 'Provide a local IPv4 address.'
found=false
for ip in $(hostname -I); do
    [[ $ip != "$listen_ip" ]] || found=true
done
$found || fail 'That exact IP address is not assigned to this host.'
conf="$vhostsdir/ssl.$domain.conf"
hostdir="$apachedir/$domain"
key="$certdir/$domain.key"
cert="$certdir/$domain.crt"
for path in "$conf" "$vhostsdir/ssl.$domain.sus" "$key" "$cert"; do
    [[ ! -e $path && ! -L $path ]] || fail "Already exists: $path"
done
[[ ! -e $hostdir && ! -L $hostdir ]] || fail 'Document root already exists; refusing to overwrite it.'
mkdir -p -- "$vhostsdir" "$certdir"
created_dir=false
created_assets=false
rollback() {
    local code=$?
    if (( code != 0 )); then
        if $created_assets; then rm -f -- "$conf" "$key" "$cert"; fi
        if $created_dir; then rm -f -- "$hostdir/index.html"; rmdir -- "$hostdir" || true; fi
        printf 'Creation failed; new lab files rolled back.\n' >&2
    fi
}
trap rollback EXIT
mkdir -- "$hostdir"
created_dir=true
chmod 755 -- "$hostdir"
printf '<!doctype html><title>%s</title><h1>Welcome to %s</h1>\n' "$domain" "$domain" > "$hostdir/index.html"
created_assets=true
(umask 077; openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "$key" -out "$cert" -subj "/CN=$domain" -addext "subjectAltName=DNS:$domain")
chmod 644 -- "$cert"
cat > "$conf" <<EOF
<VirtualHost $listen_ip:443>
    SSLEngine on
    SSLCertificateFile "$cert"
    SSLCertificateKeyFile "$key"
    ServerName $domain
    DocumentRoot "$hostdir"
    ErrorLog /var/log/httpd/$domain-error.log
    CustomLog /var/log/httpd/$domain-access.log combined
</VirtualHost>
<Directory "$hostdir">
    Options -Indexes +FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>
EOF
if ! reload_config; then
    rm -f -- "$conf"
    reload_config || true
    fail 'Apache rejected the new configuration.'
fi
trap - EXIT
printf 'Created https://%s. Configure DNS or your client hosts file to resolve it to %s.\n' "$domain" "$listen_ip"
