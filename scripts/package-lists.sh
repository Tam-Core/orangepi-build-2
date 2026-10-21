#!/usr/bin/env bash
# Exact whitespace-delimited package names, never regular expressions.
exclude_packages() {
    awk -v excluded="$2" 'BEGIN {
        n = split(excluded, names, /[[:space:]]+/)
        for (i = 1; i <= n; i++) removed[names[i]] = 1
    } {
        for (i = 1; i <= NF; i++) if (!($i in removed)) {
            printf "%s%s", separator, $i
            separator = " "
        }
    } END { print "" }' <<< "$1"
}
