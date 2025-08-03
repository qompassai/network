#!/usr/bin/env sh
# /qompassai/network/nmcli/quickstart.sh
# Qompass AI - NetworkManager (nmcli) Quick Start
# Copyright (C) 2025 Qompass AI, All rights reserved
####################################################
set -eu
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
NMCLI_MENU_TMP="/tmp/nmcli_menu.$USER.$$"
trap 'rm -f "$NMCLI_MENU_TMP"' EXIT
if ! command -v nmcli >/dev/null 2>&1; then
	echo "❌ 'nmcli' (NetworkManager CLI) is not installed or on the PATH."
	echo "→ For most Linux distros, install with: sudo apt install network-manager"
	echo "→ On Fedora: sudo dnf install NetworkManager"
	echo "→ On openSUSE: sudo zypper install NetworkManager"
	echo "→ On Arch: sudo pacman -S networkmanager"
	echo "NetworkManager/nmcli is not user-local installable; please ask your sysadmin or run the above."
	exit 1
fi
NM_WIFI_DEVS=$(nmcli -t -f DEVICE,TYPE,STATE dev | awk -F: '$2=="wifi" && $3!="unavailable"{print $1}')
if [ -z "$NM_WIFI_DEVS" ]; then
	echo "No active Wi-Fi interface detected with nmcli."
	exit 1
fi
nmcli device wifi list | awk 'NR>1{print NR-1"\t"$1"\t"$8"\t"$2}' >"$NMCLI_MENU_TMP"
show_menu() {
	printf '╭────────────────────────────────────────────╮\n'
	printf '│   Qompass AI · NetworkManager Quick‑Start  │\n'
	printf '╰────────────────────────────────────────────╯\n'
	printf '    © 2025 Qompass AI. All rights reserved   \n\n'
	printf "Available Wi-Fi networks:\n\n"
	awk -F '\t' '{printf " %s) %s   [Signal: %s] %s\n", $1, $2, $3, $4}' "$NMCLI_MENU_TMP"
	printf " n) New custom connection\n"
	printf " q) Quit\n\n"
	printf "Choose network to connect [1]: "
}
while :; do
	show_menu
	read -r choice
	if [ -z "$choice" ] || [ "$choice" = "1" ]; then
		SEL=$(awk -F'\t' '$1==1{print $2}' "$NMCLI_MENU_TMP")
		break
	elif [ "$choice" = "n" ]; then
		SEL=""
		break
	elif [ "$choice" = "q" ]; then
		echo "Aborted."
		exit 0
	elif awk -F'\t' -v n="$choice" '$1==n{exit 0} END{exit 1}' "$NMCLI_MENU_TMP"; then
		SEL=$(awk -F'\t' -v n="$choice" '$1==n{print $2}' "$NMCLI_MENU_TMP")
		break
	else
		echo "Invalid selection. Try again."
		sleep 1
	fi
done
if [ "$choice" = "n" ]; then
	printf "Enter SSID: "
	read -r NEW_SSID
	printf "Enter Wi-Fi security type [wpa-psk/wpa2-psk/none]: "
	read -r SECURITY
	if [ "$SECURITY" = "none" ]; then
		PASS_OPT=""
	else
		printf "Enter Wi-Fi password: "
		stty -echo
		read -r PASS
		stty echo
		printf "\n"
		PASS_OPT="password $PASS"
	fi
	DEV=$(echo "$NM_WIFI_DEVS" | head -n1)
	echo
	echo "Connecting to custom access point: $NEW_SSID ..."
	if [ -n "$PASS_OPT" ]; then
		if ! nmcli device wifi connect "$NEW_SSID" $PASS_OPT ifname "$DEV"; then
			echo "❌ Failed to connect. Please check SSID, password, and try again."
			exit 1
		fi
	else
		if ! nmcli device wifi connect "$NEW_SSID" ifname "$DEV"; then
			echo "❌ Failed to connect. Please check SSID and try again."
			exit 1
		fi
	fi
	echo "✅ Connected to $NEW_SSID."
else
	if [ -z "$SEL" ]; then
		echo "No network selected."
		exit 1
	fi
	SECURITY_TYPE=$(nmcli --fields SSID,SECURITY device wifi list | awk -v ssid="$SEL" '$1==ssid{print $2}')
	DEV=$(echo "$NM_WIFI_DEVS" | head -n1)
	echo
	printf "Connecting to '%s' ...\n" "$SEL"
	if echo "$SECURITY_TYPE" | grep -qi 'wpa\|wep'; then
		printf "Wi-Fi password: "
		stty -echo
		read -r PASS
		stty echo
		printf "\n"
		if ! nmcli device wifi connect "$SEL" password "$PASS" ifname "$DEV"; then
			echo "❌ Failed to connect. Please check password and try again."
			exit 1
		fi
	else
		if ! nmcli device wifi connect "$SEL" ifname "$DEV"; then
			echo "❌ Failed to connect."
			exit 1
		fi
	fi
	echo "✅ Connected to $SEL."
fi
echo
echo "Connection complete. Profile is managed by NetworkManager."
echo "Status:"
nmcli connection show --active
echo
exit 0
