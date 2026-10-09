#!/bin/bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh" || exit 1
shopt -s nullglob
for file in "$vhostsdir"/ssl.*.conf "$vhostsdir"/ssl.*.sus; do
    name=${file##*/}
    name=${name#ssl.}
    printf '%s\n' "${name%.*}"
done
