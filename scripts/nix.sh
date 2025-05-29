#!/usr/bin/env bash
# /qompassai/network/scripts/nix.sh
# ------------------------------------
# Copyright (C) 2025 Qompass AI, All rights reserved

set -euo pipefail

echo "🚀 Installing and Testing Qompass AI Network Security Tools"
echo "=========================================================="

CURRENT_USER=$(whoami)
USER_HOME=$(eval echo "~$CURRENT_USER")
SYSTEM_CORES=$(nproc 2>/dev/null || echo "4")
MAX_JOBS=$((SYSTEM_CORES > 8 ? 8 : SYSTEM_CORES))

echo "🔧 Setting up for user: $CURRENT_USER"
echo "🖥️  System cores: $SYSTEM_CORES, Max jobs: $MAX_JOBS"

if command -v nix &> /dev/null; then
    echo "✅ Nix is already installed: $(nix --version)"
else
    echo "📦 Installing Nix package manager..."
    sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon

    echo "🔄 Sourcing Nix environment..."
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi
fi

mkdir -p "$USER_HOME/.config/nix"

if [ -f "$USER_HOME/.config/nix/nix.conf" ]; then
    BACKUP_FILE="$USER_HOME/.config/nix/nix.conf.backup.$(date +%Y%m%d-%H%M%S)"
    cp "$USER_HOME/.config/nix/nix.conf" "$BACKUP_FILE"
    echo "💾 Backed up existing config to: $BACKUP_FILE"
fi

echo "📝 Creating Nix configuration..."
cat > "$USER_HOME/.config/nix/nix.conf" << EOF
# ~/.config/nix/nix.conf
# Auto-generated for $CURRENT_USER on $(date)

auto-optimise-store = true
experimental-features = nix-command flakes
fallback = true
flake-registry = https://github.com/NixOS/flake-registry/raw/master/flake-registry.json
gc-keep-outputs = true
http-connections = 25
keep-derivations = true
keep-env-derivations = true
keep-outputs = true
max-jobs = $MAX_JOBS
min-free = 1073741824
require-sigs = true
sandbox = true
stalled-download-timeout = 300
substituters = https://cache.nixos.org https://nix-community.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
trusted-substituters = https://cache.nixos.org
trusted-users = root $CURRENT_USER
use-xdg-base-directories = true
warn-dirty = false
netrc-file = $USER_HOME/.config/nix/netrc
extra-trusted-public-keys = cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM= cache.flakehub.com-4:Asi8qIv291s0aYLyH6IOnr5Kf6+OF14WVjkE6t3xMio= cache.flakehub.com-5:zB96CRlL7tiPtzA9/WKyPkp3A2vqxqgdgyTVNGShPDU= cache.flakehub.com-6:W4EGFwAGgBj3he7c5fNh9NkOXw0PUVaxygCVKeuvaqU= cache.flakehub.com-7:mvxJ2DZVHn/kRxlIaxYNMuDG1OvMckZu32um1TadOR8= cache.flakehub.com-8:moO+OVS0mnTjBTcOUh2kYLQEd59ExzyoW1QgQ8XAARQ= cache.flakehub.com-9:wChaSeTI6TeCuV/Sg2513ZIM9i0qJaYsF+lZCXg0J6o= cache.flakehub.com-10:2GqeNlIp6AKp4EF2MVbE1kBOp9iBSyo0UPR9KoR0o1Y=
extra-substituters = https://cache.flakehub.com/
EOF

chmod 644 "$USER_HOME/.config/nix/nix.conf"

touch "$USER_HOME/.config/nix/netrc"
chmod 600 "$USER_HOME/.config/nix/netrc"

echo "✅ Nix configuration created successfully!"

if [ ! -f "flake.nix" ]; then
    echo "❌ Error: flake.nix not found in current directory"
    echo "💡 Please run this script from the qompassai/network directory"
    exit 1
fi

echo "🔧 Entering Nix development environment and testing tools..."

nix develop --command bash -c "
    echo '🔒 Network Security Environment Ready!'
    echo ''

    echo '🔨 Testing hash utilities:'
    if [ -f 'README.md' ]; then
        hash-utils blake3 README.md
    else
        echo 'test content' > test.txt
        hash-utils blake3 test.txt
        rm test.txt
    fi
    echo ''

    echo '🔐 Testing encryption:'
    echo 'secret message' | rage -e -p > encrypted.age
    echo 'Encrypted file created: encrypted.age'

    echo '🔓 Testing decryption:'
    rage -d encrypted.age
    rm encrypted.age
    echo ''

    echo '📚 Available tools:'
    rage --version
    openssl version
    echo ''

    echo '✅ All tests completed successfully!'
    echo 'You can now use: nix develop'
"

echo ""
echo "🎉 Setup complete! To use the tools again, run:"
echo "   cd /path/to/qompassai/network"
echo "   nix develop"
echo ""
echo "📋 Configuration summary:"
echo "   User: $CURRENT_USER"
echo "   Config: $USER_HOME/.config/nix/nix.conf"
echo "   Max jobs: $MAX_JOBS (based on $SYSTEM_CORES cores)"

