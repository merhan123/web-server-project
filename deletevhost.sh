#!/bin/bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh" || exit 1
require_root
[[ $# -ge 1 && $# -le 2 ]] || fail "Usage: $0 DOMAIN [--delete-content]"
domain=$1
validate_domain
[[ ${2:-} == '' || ${2:-} == --delete-content || ${2:-} == dellhostdir ]] || fail 'Unknown deletion option.'
conf="$vhostsdir/ssl.$domain.conf"
suspended="$vhostsdir/ssl.$domain.sus"
[[ ! -e $conf || ! -e $suspended ]] || fail 'Both active and suspended configurations exist; resolve this manually.'
[[ -e $conf ]] || conf=$suspended
[[ -f $conf && ! -L $conf ]] || fail 'Virtual host not found or is a symlink.'
hostdir="$apachedir/$domain"
[[ ! -L $hostdir ]] || fail 'Document root is a symlink; remove it manually.'
backup=$(mktemp "$vhostsdir/.cleanup.XXXXXX")
mv -- "$conf" "$backup"
if ! reload_config; then
    mv -- "$backup" "$conf"
    reload_config || true
    fail 'Apache rejected the change; original configuration restored.'
fi
rm -f -- "$backup" "$certdir/$domain.crt" "$certdir/$domain.key"
if [[ ${2:-} == --delete-content || ${2:-} == dellhostdir ]]; then
    rm -rf -- "$hostdir"
fi
printf 'Removed virtual host %s. Logs and hosts-file entries are retained for manual review.\n' "$domain"
