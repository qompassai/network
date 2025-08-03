#!/usr/bin/env sh
# /qompassai/network/wireguard/quickstart.sh
# Qompass AI  WireGuard Quick Start
# Copyright (C) 2025 Qompass AI, All rights reserved
####################################################
set -eu
XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"
mkdir -p "$XDG_BIN_HOME"
case ":$PATH:" in
*":$XDG_BIN_HOME:"*) : ;;
*) export PATH="$XDG_BIN_HOME:$PATH" ;;
esac
install_wireguard_userlocal() {
	echo "⚠️  'wg' not found. Attempting user-local install of wireguard-go..."
	os="$(uname -s)"
	arch="$(uname -m)"
	case "$arch" in
	x86_64 | amd64) arch="amd64" ;;
	aarch64 | arm64) arch="arm64" ;;
	*)
		echo "Unsupported arch: $arch. Please install wireguard-tools manually."
		exit 1
		;;
	esac
	case "$os" in
	Linux)
		url="https://github.com/WireGuard/wireguard-go/releases/latest/download/wireguard-go-linux-$arch"
		;;
	Darwin)
		url="https://github.com/WireGuard/wireguard-go/releases/latest/download/wireguard-go-darwin-$arch"
		;;
	*)
		echo "Unsupported OS: $os. Please install wireguard-tools manually."
		exit 1
		;;
	esac
	dest="$XDG_BIN_HOME/wg"
	if [ ! -x "$dest" ]; then
		echo "Downloading $url to $dest ..."
		curl -fsSL "$url" -o "$dest" || wget -O "$dest" "$url"
		chmod +x "$dest"
		echo "'wg' installed locally at: $dest"
	fi
}
command -v wg >/dev/null 2>&1 || install_wireguard_userlocal
if ! command -v wg >/dev/null 2>&1; then
	echo "❌ 'wg' (WireGuard) could not be found or installed."
	echo "Please install it manually for your platform (see https://www.wireguard.com/install/)."
	exit 1
fi
KEYDIR=${1:-./wg-keys}
DEFAULT_HOSTNAMES="caffe doppio pensare primo ristretto"
HOSTNAMES=""
MENU_TMP="/tmp/wg_menu.$USER.$$"
trap 'rm -f "$MENU_TMP"' EXIT
HOST_ARRAY=$(echo "$DEFAULT_HOSTNAMES" | tr ' ' '\n' | nl -w1 -s' ')
i=0
printf '%s\n' "$HOST_ARRAY" | while read -r idx name; do
	printf "%s\t%s\n" "$idx" "$name"
done >"$MENU_TMP"
show_menu() {
	printf '╭────────────────────────────────────────────╮\n'
	printf '│   Qompass AI · WireGuard Quick‑Start       │\n'
	printf '╰────────────────────────────────────────────╯\n'
	printf '    © 2025 Qompass AI. All rights reserved   \n\n'
	printf "Available hosts for key generation:\n\n"
	awk -F '\t' '{printf " %s) %s\n", $1, $2}' "$MENU_TMP"
	printf " a) all   (generate keys for all hosts)\n"
	printf " q) quit\n\n"
	printf "Choose host(s) [1]: "
}
while :; do
	show_menu
	read -r choice
	case "$choice" in
	"" | 1)
		HOSTNAMES=$(awk -F '\t' '$1==1{print $2}' "$MENU_TMP")
		break
		;;
	[2-9])
		HOSTNAMES=$(awk -F '\t' -v c="$choice" '$1==c{print $2}' "$MENU_TMP")
		break
		;;
	a | A)
		HOSTNAMES="$DEFAULT_HOSTNAMES"
		break
		;;
	q | Q)
		echo "Aborted."
		exit 0
		;;
	*)
		echo "Invalid selection. Try again."
		sleep 1
		;;
	esac
done
[ -z "$HOSTNAMES" ] && {
	echo "No hostnames given."
	exit 1
}
mkdir -p "$KEYDIR"
chmod 700 "$KEYDIR"
printf "\n"
for HOST in $HOSTNAMES; do
	WG_PRIV="$KEYDIR/$HOST.privatekey"
	WG_PUB="$KEYDIR/$HOST.publickey"
	PSK="$KEYDIR/$HOST.presharedkey"
	umask 077
	[ -f "$WG_PRIV" ] || wg genkey >"$WG_PRIV"
	wg pubkey <"$WG_PRIV" >"$WG_PUB"
	[ -f "$PSK" ] || wg genpsk >"$PSK"
	chmod 600 "$WG_PRIV" "$PSK"
	chmod 644 "$WG_PUB"
	echo "✅ Keys for $HOST: $WG_PRIV $WG_PUB $PSK"
done
echo
echo "== WireGuard config snippets (per host) =="
for HOST in $HOSTNAMES; do
	WG_PRIV="$KEYDIR/$HOST.privatekey"
	WG_PUB="$KEYDIR/$HOST.publickey"
	PSK="$KEYDIR/$HOST.presharedkey"
	echo
	echo "---- $HOST ----"
	echo "[Interface]"
	echo "PrivateKey = $(cat "$WG_PRIV")"
	echo "# PublicKey (share with peers): $(cat "$WG_PUB")"
	echo "..."
	echo "[Peer example]"
	echo "PublicKey = <peer-public-key>"
	echo "PresharedKey = $(cat "$PSK")"
	echo "AllowedIPs = ..."
done
echo
echo "All keys stored in: $KEYDIR"
echo
exit 0
