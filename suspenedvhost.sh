#!/bin/bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh" || exit 1
require_root
[[ $# == 1 ]] || fail "Usage: $0 DOMAIN"
domain=$1
validate_domain
source_path="$vhostsdir/ssl.$domain.conf"
target_path="$vhostsdir/ssl.$domain.sus"
[[ -f $source_path && ! -L $source_path ]] || fail 'Source virtual host not found or is a symlink.'
[[ ! -e $target_path && ! -L $target_path ]] || fail 'Target virtual host already exists.'
mv -- "$source_path" "$target_path"
if ! reload_config; then
    mv -- "$target_path" "$source_path"
    reload_config || true
    fail 'Apache rejected the change; original configuration restored.'
fi
printf 'Updated %s successfully.\n' "$domain"
