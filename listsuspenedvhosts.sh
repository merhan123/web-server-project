#!/bin/bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
shopt -s nullglob
for file in "$vhostsdir"/ssl.*.sus; do
    name=${file##*/}
    name=${name#ssl.}
    printf '%s\n' "${name%.*}"
done
