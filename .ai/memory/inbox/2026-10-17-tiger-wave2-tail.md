# Wave-1 tail bundle (Decision 6) — 2026-10-17

`nftables/nftables.conf` curatively rebuilt: the pasted live ruleset
dump is now authored nftables, unified with the existing authored
tables. Intent preserved rule-by-rule against the dump: same tables
(inet my_filter, inet nat, ip6 nat, ip nat, ip filter, ip6 filter,
inet monero), chains, hooks and policies. Translations:
`xt match "addrtype"` (LOCAL) -> `fib daddr type local`;
`xt target "MASQUERADE"` -> `masquerade`; DOCKER-CT's
`xt match "conntrack"` -> `ct state established,related`; live counter
values dropped (`counter` only — counts are runtime state). Duplicated
rules from the paste (my_filter input block, forward pairs,
masquerade lines) written once. Gate: `unshare -rn nft -c` clean; the
wave-1 strict xfail flipped to a real pass (suite 10 passed).
REPO-SIDE ONLY — nothing was applied to any live firewall.
