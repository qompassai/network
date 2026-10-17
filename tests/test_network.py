"""Validation gate for the qompassai/network repository.

The repo's built features are its network configuration artifacts:
a Nix flake (dev shell, packages, a NixOS hardening module),
nftables rulesets, NetworkManager configuration, and shell
installers. These tests validate the real artifacts with the real
tools (nix, nft, bash, configparser) — validation cases — and
prove the structural checks reject corrupted input — adversarial
cases.

nftables/nftables.conf was rebuilt on 2026-10-17 (Decision 6): the
pasted live ruleset dump (xtables-compat expressions, live counters)
was translated into authored nftables with identical tables, chains,
policies and rule intent, so test_nftables_conf_loads is a real pass.

Run: python3 -m pytest tests/ -q
"""

from __future__ import annotations

import configparser
import re
import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
SUBPROCESS_TIMEOUT_S = 60
FLAKE_TIMEOUT_S = 600
MAX_OUTPUT_BYTES = 200_000

SHELL_SCRIPTS = [
    'scripts/config.sh',
    'scripts/nix.sh',
    'nmcli/quickstart.sh',
    'wireguard/quickstart.sh',
    'etc/NetworkManager/99-unbound-check',
    'doh/doh-client-disabled',
]


def _run(
    argv: list[str], *, timeout_s: int = SUBPROCESS_TIMEOUT_S
) -> subprocess.CompletedProcess:
    """Run one bounded, argv-form subprocess and return its result."""
    result = subprocess.run(
        argv,
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        timeout=timeout_s,
        check=False,
    )
    assert len(result.stdout) + len(result.stderr) <= MAX_OUTPUT_BYTES
    return result


def _nft_check(relative_path: str) -> subprocess.CompletedProcess:
    # nft -c still wants netlink cache access for its check phase;
    # a user+net namespace gives it a private netlink to check
    # against, so the verdict is the file's, not the host's.
    return _run(['unshare', '-rn', 'nft', '-c', '-f', relative_path])


def _nm_problems(text: str) -> list[str]:
    """Structural contract for the NetworkManager config."""
    parser = configparser.ConfigParser()
    try:
        parser.read_string(text)
    except configparser.Error as err:
        return [f'unparsable: {err}']
    problems: list[str] = []
    if parser.get('main', 'dns', fallback='') != 'unbound':
        problems.append("[main] dns is not 'unbound'")
    if 'keyfile' not in parser.get('main', 'plugins', fallback=''):
        problems.append('[main] plugins does not include keyfile')
    if parser.get('device', 'wifi.backend', fallback='') != 'iwd':
        problems.append("[device] wifi.backend is not 'iwd'")
    return problems


def _nft_structure_problems(text: str) -> list[str]:
    """Structural contract for an nftables ruleset (no kernel check)."""
    problems: list[str] = []
    if text.count('{') != text.count('}'):
        problems.append('unbalanced braces')
    tables = re.findall(r'^table\s+(\w+)\s+(\w+)\s*\{', text, re.MULTILINE)
    if not tables:
        problems.append('no table declarations found')
    return problems


# --- Validation ---


def test_flake_evaluates() -> None:
    """The flake's devShell, packages and NixOS module evaluate.

    Uses the path: flake reference on purpose: the git+file
    reference fails on primo because nix's libgit2 cannot read
    this working tree's .jj-managed git extensions.
    """
    result = _run(
        ['nix', 'flake', 'check', '--no-build', 'path:.'],
        timeout_s=FLAKE_TIMEOUT_S,
    )
    assert result.returncode == 0, result.stderr[-2000:]


def test_monero_ruleset_loads() -> None:
    result = _nft_check('nftables/monero.nft')
    assert result.returncode == 0, result.stderr


def test_shell_scripts_parse() -> None:
    for script in SHELL_SCRIPTS:
        result = _run(['bash', '-n', script])
        assert result.returncode == 0, f'{script}: {result.stderr}'


def test_networkmanager_config_matches_contract() -> None:
    text = (REPO_ROOT / 'etc/NetworkManager/NetworkManager.conf').read_text(
        encoding='utf-8'
    )
    assert _nm_problems(text) == []


def test_nftables_conf_structure() -> None:
    text = (REPO_ROOT / 'nftables/nftables.conf').read_text(encoding='utf-8')
    assert _nft_structure_problems(text) == []
    # the authored filter table must default-drop inbound traffic
    assert 'type filter hook input priority filter; policy drop;' in text


# --- Rebuilt ruleset (Decision 6, 2026-10-17) ---


def test_nftables_conf_loads() -> None:
    result = _nft_check('nftables/nftables.conf')
    assert result.returncode == 0, result.stderr


# --- Adversarial ---


def test_nm_problems_reject_wrong_dns() -> None:
    text = (REPO_ROOT / 'etc/NetworkManager/NetworkManager.conf').read_text(
        encoding='utf-8'
    )
    assert _nm_problems(text.replace('dns=unbound', 'dns=default')) != []


def test_nm_problems_reject_garbage() -> None:
    assert _nm_problems('this is not an ini file {{{') != []


def test_nft_structure_rejects_unbalanced_braces() -> None:
    assert _nft_structure_problems('table inet x {\n chain y {\n') != []


def test_nft_structure_rejects_tableless_text() -> None:
    assert _nft_structure_problems('just some words, no rules\n') != []
