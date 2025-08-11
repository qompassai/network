#!/usr/bin/env bash
# ~/distcctest.sh
# Copyright (C) 2025 Qompass AI, All rights reserved
####################################################
set -euo pipefail
SUBNET="151.123.1"
PORT=1234
USER="distccuser"
declare -A HOST_ALIASES=(
    [151.123.1.101]="uno"
    [151.123.1.102]="dos"
    [151.123.1.103]="tres"
    [151.123.1.104]="quatro"
)
found_hosts=()
for i in {1..254}; do
    ip="${SUBNET}.${i}"
    if timeout 1 bash -c "echo > /dev/tcp/${ip}/${PORT}" 2>/dev/null; then
        echo -n "✅ Found SSH on $ip... "
        if ssh -p $PORT -o ConnectTimeout=2 "${USER}@${ip}" 'zig version' &>/dev/null; then
            echo "Zig OK"
            found_hosts+=("${ip}")
        else
            echo "❌ Zig not found"
        fi
    fi
done
if [ ${#found_hosts[@]} -eq 0 ]; then
    echo "❌ No distcc-capable Zig hosts found."
    exit 1
fi
DISTCC_HOSTS=""
for ip in "${found_hosts[@]}"; do
    DISTCC_HOSTS+="${ip}/4,lzo "
done
DISTCC_HOSTS+="localhost"
export DISTCC_HOSTS
echo "🔧 DISTCC_HOSTS = $DISTCC_HOSTS"
echo "📝 Updating /etc/hosts with known aliases..."
for ip in "${found_hosts[@]}"; do
    alias="${HOST_ALIASES[$ip]}"
    if [[ -n "$alias" ]] && ! grep -qE "\s${alias}$" /etc/hosts; then
        echo "$ip  $alias"
        echo "$ip  $alias" | sudo tee -a /etc/hosts >/dev/null
    fi
done
echo "✅ Done."
