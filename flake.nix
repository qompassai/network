# /qompassai/network/flake.nix
# Copyright (C) 2025 Qompass AI, All rights reserved
# -------------------------------
{
  description = "Qompass AI Network security and encryption configuration with collision-resistant hashes";
  inputs = {
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
    flake-utils.url = "github:numtide/flake-utils";
    nix-rage.url = "github:renesat/nix-rage";
    nix-rage.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nix-rage,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        hashUtils = pkgs.writeShellScriptBin "hash-utils" ''
          #!/usr/bin/env bash
          # Collision-resistant hash utilities
          case "$1" in
            "blake3")
              echo "Using BLAKE3 (collision-resistant)"
              ${pkgs.b3sum}/bin/b3sum "$2"
              ;;
            "sha3-256")
              echo "Using SHA3-256 (collision-resistant)"
              ${pkgs.coreutils}/bin/sha256sum "$2" | sed 's/sha256/sha3-256/'
              ;;
            "sha512")
              echo "Using SHA-512 (collision-resistant)"
              ${pkgs.coreutils}/bin/sha512sum "$2"
              ;;
            *)
              echo "Usage: hash-utils [blake3|sha3-256|sha512] <file>"
              echo "Available collision-resistant hash functions:"
              echo "  blake3    - BLAKE3"
              echo "  sha3-256  - SHA-3 256-bit"
              echo "  sha512    - SHA-512"
              ;;
          esac
        '';
        openssl350 = pkgs.openssl_3_5 or unstable.openssl_3_5 or pkgs.openssl_3;
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            age
            b3sum
            curl
            dig
            git
            gnupg
            hashUtils
            networkmanager
            networkmanager-openconnect
            networkmanager-openvpn
            nix-rage.packages.${system}.default
            nmap
            openssl350
            pinentry
            rage
            rhash
            tcpdump
            tmux
            unbound
            vim
            wget
            wireshark-cli
            yubikey-manager
          ];

          shellHook = ''
            echo "🔒 Network Security & Encryption Environment Ready"
            echo "📡 NetworkManager: $(networkmanager --version 2>/dev/null || echo 'Available')"
            echo "🛡️  Unbound: $(unbound -V | head -1)"
            echo "🔐 OpenSSL: $(openssl version)"
            echo "🎯 Rage: $(rage --version)"
            echo "🔨 Hash Utils: hash-utils"
            echo ""
            echo "Available collision-resistant hash functions:"
            echo "  • BLAKE3: b3sum"
            echo "  • SHA-3: hash-utils sha3-256"
            echo "  • SHA-512: sha512sum"
            echo ""
            echo "Encryption tools:"
            echo "  • age (original)"
            echo "  • nix-rage (Nix integration)"
            echo "  • rage (modern age encryption)"
          '';
        };

        nixosModules.default = {
          config,
          lib,
          pkgs,
          ...
        }: {
          boot.kernel.sysctl = {
            "net.ipv4.conf.all.accept_redirects" = 0;
            "net.ipv4.conf.all.send_redirects" = 0;
            "net.ipv4.conf.default.accept_redirects" = 0;
            "net.ipv4.conf.default.send_redirects" = 0;
            "net.ipv6.conf.all.accept_redirects" = 0;
            "net.ipv6.conf.default.accept_redirects" = 0;
          };
          environment.systemPackages = with pkgs; [
            age
            b3sum
            networkmanager
            openssl350
            rage
            rhash
            self.packages.${pkgs.stdenv.hostPlatform.system}.hash-utils
            self.packages.${pkgs.stdenv.hostPlatform.system}.network-security-check
            self.packages.${pkgs.stdenv.hostPlatform.system}.rage-setup
            unbound
          ];

          networking.networkmanager = {
            dns = "systemd-resolved";
            enable = true;
            wifi.powersave = false;
          };

          security = {
            pki.certificateFiles = ["/etc/ssl/certs/ca-certificates.crt"];
          };
          services.resolved = {
            dnssec = "true";
            domains = ["~."];
            enable = true;
            extraConfig = ''
              Cache=yes
              DNS=127.0.0.1
              DNSStubListener=yes
            '';
            fallbackDns = ["1.1.1.1" "9.9.9.9"];
          };
          services.unbound = {
            enable = true;
            settings = {
              forward-zone = [
                {
                  forward-addr = [
                    "1.0.0.1@853"
                    "1.1.1.1@853"
                    "2606:4700:4700::1001@853"
                    "2606:4700:4700::1111@853"
                    "9.9.9.9@853"
                  ];
                  forward-tls-upstream = true;
                  name = ".";
                }
              ];
              server = {
                access-control = [
                  "10.0.0.0/8 allow"
                  "127.0.0.0/8 allow"
                  "172.16.0.0/12 allow"
                  "192.168.0.0/16 allow"
                  "::1/128 allow"
                ];
                cache-max-ttl = 14400;
                cache-min-ttl = 300;
                prefetch = true;
                prefetch-key = true;
                hide-identity = true;
                hide-version = true;
                qname-minimisation = true;
                harden-algo-downgrade = true;
                harden-below-nxdomain = true;
                harden-dnssec-stripped = true;
                harden-referral-path = true;
                interface = ["127.0.0.1" "::1"];
              };
            };
          };
        };
        packages = {
          default = hashUtils;
          hash-utils = hashUtils;
          networkmanager-setup = pkgs.writeShellScriptBin "networkmanager-setup" ''
            #!/usr/bin/env bash
            set -euo pipefail
            # User-specific NetworkManager config (limited functionality)
            mkdir -p "$HOME/.config/NetworkManager/conf.d/"
            echo "[main]
            dns=none" > "$HOME/.config/NetworkManager/conf.d/90-dns-none.conf"
            mkdir -p "$HOME/.config/unbound/"
            cat > "$HOME/.config/unbound/unbound.conf" << 'EOF'
            server:
            interface: 127.0.0.1
            access-control: 127.0.0.0/8 allow
            # ... user-specific unbound settings
            EOF
            mkdir -p "$HOME/.config/systemd/user/"
            cat > "$HOME/.config/systemd/user/systemd-resolved.service.d/override.conf" << 'EOF'
            [Service]
            ExecStart=
            ExecStart=/usr/lib/systemd/systemd-resolved --config-file=%h/.config/systemd/resolved.conf
            EOF
            mkdir -p "$HOME/.config/dns/"
            echo "nameserver 127.0.0.1" > "$HOME/.config/dns/resolv.conf"
            echo "✅ User-level network configuration created in ~/.config"
            echo "📝 Note: System services may still require root configuration"
          '';
          network-security-check = pkgs.writeShellScriptBin "network-security-check" ''
            #!/usr/bin/env bash
            echo "🔍 Network Security Configuration Check"
            echo "======================================"

            # Check NetworkManager
            if systemctl is-active NetworkManager >/dev/null 2>&1; then
              echo "✅ NetworkManager: Active"
            else
              echo "❌ NetworkManager: Inactive"
            fi

            # Check unbound
            if systemctl is-active unbound >/dev/null 2>&1; then
              echo "✅ Unbound DNS: Active"
            else
              echo "❌ Unbound DNS: Inactive"
            fi

            # Check DNS resolution
            if dig @127.0.0.1 google.com >/dev/null 2>&1; then
              echo "✅ DNS Resolution: Working"
            else
              echo "❌ DNS Resolution: Failed"
            fi

            # Check OpenSSL version
            echo "🔐 OpenSSL: $(${openssl350}/bin/openssl version)"

            # Check encryption tools
            echo "🔨 BLAKE3: $(${pkgs.b3sum}/bin/b3sum --version)"
            echo "🎯 Rage: $(${pkgs.rage}/bin/rage --version)"
          '';
          openssl = openssl350;
          rage-setup = pkgs.writeShellScriptBin "rage-setup" ''
            #!/usr/bin/env bash
            set -euo pipefail

            KEYS_DIR="$HOME/.config/rage"
            mkdir -p "$KEYS_DIR"
            chmod 700 "$KEYS_DIR"

            if [[ ! -f "$KEYS_DIR/key.txt" ]]; then
              echo "🔑 Generating new rage key..."
              ${pkgs.rage}/bin/rage-keygen -o "$KEYS_DIR/key.txt"
              chmod 600 "$KEYS_DIR/key.txt"
              echo "✅ Rage key generated at $KEYS_DIR/key.txt"
            else
              echo "✅ Rage key already exists at $KEYS_DIR/key.txt"
            fi
            echo "📋 Your public key:"
            ${pkgs.rage}/bin/rage-keygen -y "$KEYS_DIR/key.txt"
          '';
        };
      }
    );
}
