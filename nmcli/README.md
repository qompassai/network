<!-- ~/.GH/Qompass/Network/nmcli/README.md -->
<!-- ------------------------------------- -->
<!-- Copyright (C) 2025 Qompass AI, All rights reserved -->

<h2> Tools involved </h2>

- bash
- nmcli
- networkmanager
- unbound
- rfkill


* Getting access to public wifi


```bash
sudo systemctl enable --now NetworkManager
nmcli radio wifi on
```


```bash
nmcli device wifi list
```

```
sudo nmcli device wifi connect "YOUR_SSID" password "YOUR_PASSWORD" ifname wlan0
```
