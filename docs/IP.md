<!-- /qompassai/network/docs/IP.md -->
<!-- Qompass AI Custom Domain Setup -->
<!-- ---------------------------------------- -->
<!-- Copyright (C) 2025 Qompass AI, All rights reserved -->
## 🌐 Custom Domain Setup

To point your GitHub Pages site to `www.yourdomain.com`, configure your DNS provider with the following records:

| Record Type | Name | Value | Protocol |
|-------------|------|-------------------------|----------|
| A | @ | 185.199.108.153 | IPv4 |
| A | @ | 185.199.109.153 | IPv4 |
| A | @ | 185.199.110.153 | IPv4 |
| A | @ | 185.199.111.153 | IPv4 |
| AAAA | @ | 2606:50c0:8000::153 | IPv6 |
| AAAA | @ | 2606:50c0:8001::153 | IPv6 |
| AAAA | @ | 2606:50c0:8002::153 | IPv6 |
| AAAA | @ | 2606:50c0:8003::153 | IPv6 |

> After setting these records, go to your repository's **Settings → Pages**, configure the custom domain as
`www.yourdomain.com`, and enable **Enforce HTTPS**.
