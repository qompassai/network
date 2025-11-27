# /qompassai/network/scripts/config.sh
# ---------------------------------------
# Copyright (C) 2025 Qompass AI, All rights reserved

echo "[main]
dns=none" | sudo tee /etc/NetworkManager/conf.d/90-dns-none.conf
echo "[Resolve]
DNS=127.0.0.1
DNSStubListener=no" | sudo tee /etc/systemd/resolved.conf
echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf
