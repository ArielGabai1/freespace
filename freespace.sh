#!/bin/bash

set -euo pipefail

Usage() {
    echo "freespace [-r] [-t ###] file [file ...]"
    exit 1
}

RECURSIVE=0
THRESHOLD=48

while getopts ":rt:" opt; do
    case $opt in
        r) RECURSIVE=1 ;;
        t) THRESHOLD="$OPTARG" ;;
        *) Usage ;;
    esac
done

shift $((OPTIND - 1))
[ $# -lt 1 ] && Usage

case "${THRESHOLD:-}" in
    ''|*[!0-9]*) echo "Error: -t expects an integer (hours)"; exit 1 ;;
esac

is_file_compressed() {
    local file="$1"
    [ -f "$file" ] || return 1
    local type
    type=$(file --mime-type -b -- "$file")
    case "$type" in
        application/gzip|application/x-gzip|application/zip|application/x-bzip2|application/x-xz|application/zstd|application/x-7z-compressed)
            return 0 ;;
        *) return 1 ;;
    esac
}

older_file() {
    local file="$1"
    [ -f "$file" ] || return 1
    local mtime
    if mtime=$(stat -c %Y -- "$file" 2>/dev/null); then
        :
    else
        mtime=$(stat -f %m -- "$file")
    fi
    local now
    now=$(date +%s)
    local limit=$(( now - THRESHOLD * 3600 ))
    [ "$mtime" -lt "$limit" ]
}

process_file () {
    local file="$1"
    [ -f "$file" ] || return 1

    case "$(basename "$file")" in
        fc-*)
            if older_file "$file"; then
                rm -f -- "$file"
                return 0
            else
                return 0
            fi
            ;;
    esac

    if is_file_compressed "$file"; then
        local dir base dst
        dir="$(dirname "$file")"
        base="$(basename "$file")"
        dst="$dir/fc-$base"
        mv -- "$file" "$dst"
        touch -- "$dst"
        return 0
    fi

    local dir base out
    dir="$(dirname "$file")"
    base="$(basename "$file")"
    if [[ "$base" == *.gz ]]; then
        out="$dir/fc-$base"
    else
        out="$dir/fc-$base.gz"
    fi
    gzip -c -- "$file" > "$out" && rm -f -- "$file"
    return 0
}

for path in "$@"; do
    if [ -d "$path" ]; then
        if [ "$RECURSIVE" -eq 1 ]; then
            while IFS= read -r -d '' f; do
                process_file "$f"
            done < <(find "$path" -type f -print0)
        else
            while IFS= read -r -d '' f; do
                process_file "$f"
            done < <(find "$path" -maxdepth 1 -type f -print0)
        fi
    else
        process_file "$path"
    fi
done