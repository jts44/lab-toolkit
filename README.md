# lab-toolkit

Personal command-line toolkit for troubleshooting and maintaining Mac (primary) and Windows lab computers. One URL, no retyping.

> Personal-use repository. Scripts are public; **never commit secrets** (tokens, passwords, server URLs, serial numbers, org identifiers).

---

## Quick start

Hosted at https://spieles.us via GitHub Pages.

**macOS (Terminal)**

```bash
# Inspect, then run (preferred for anything destructive)
curl -fsSLO https://spieles.us/mac/decommission/remove-jamf.sh
less remove-jamf.sh
sudo zsh remove-jamf.sh

# One-liner (read-only/diagnostic scripts only)
curl -fsSL https://spieles.us/mac/system/info.sh | zsh
```

**Windows (PowerShell)**

```powershell
# Inspect, then run
irm https://spieles.us/win/system/info.ps1 -OutFile info.ps1
notepad info.ps1
powershell -ExecutionPolicy Bypass -File .\info.ps1

# One-liner (read-only/diagnostic scripts only)
irm https://spieles.us/win/system/info.ps1 | iex
```

---

## Repository layout

```
lab-toolkit/
├── README.md               # this file
├── INDEX.md                # one-line catalog of every script
├── .gitattributes          # enforces LF for .sh, CRLF for .ps1
├── .nojekyll               # serve files raw on GitHub Pages
├── CNAME                   # short custom domain for GitHub Pages
├── mac/
│   ├── decommission/       # pre-resale/surplus cleanup
│   │   ├── remove-beyondtrust.sh
│   │   ├── remove-jamf.sh
│   │   └── verify.sh
│   ├── mdm/                # enrollment, profiles, Jamf client checks
│   ├── network/            # DNS, Wi-Fi, proxy, connectivity
│   ├── system/             # disk, logs, updates, hardware info
│   ├── users/              # local accounts, AD binding, home folders
│   └── apps/               # app resets, caches, licensing
├── win/
│   ├── network/
│   ├── system/
│   ├── users/
│   └── apps/
├── templates/
│   ├── mac-template.sh     # starting point for new Mac scripts
│   └── win-template.ps1    # starting point for new Windows scripts
└── docs/
    └── decommission-mac.md # runbook: Mac prep for resale/surplus
```

Folders are organized **by platform, then by problem domain**, so URLs read naturally:
`spieles.us/mac/network/flush-dns.sh`

---

## Conventions

**Naming**
- `verb-noun.ext`, lowercase, hyphens: `reset-printing.sh`, `get-battery.ps1`
- Read-only scripts use `get-`, `check-`, `show-`, or `verify`
- Destructive scripts use `remove-`, `reset-`, `clear-`

**Every script includes**
- A header block: purpose, platform/version tested, whether it is destructive, usage
- `--dry-run` / `-WhatIf` support for anything that deletes or modifies
- A confirmation prompt for destructive actions (skip with `-y` / `-Force`)
- A root/admin check where required
- Non-zero exit codes on failure

**Shells**
- macOS: `zsh` (default since 10.15); avoid Bash 3.2-only quirks
- Windows: PowerShell 5.1 compatible (ships with Windows 10/11); avoid PS 7-only syntax unless noted

**Safety tiers** (stated in each script header)
- 🟢 *Read-only*: safe to pipe directly into a shell
- 🟡 *Modifies settings*: reversible; download and review first
- 🔴 *Destructive*: deletes data or software; always download, read, then run

---

## Hosting (GitHub Pages + short domain)

1. Create a **public** GitHub repo named `lab-toolkit`.
2. Settings → Pages → Source: *Deploy from branch* → `main` / root.
3. Add your domain to `CNAME` (one line, e.g. `spieles.us`).
4. At your DNS provider, add the GitHub Pages records:
   - Apex domain: `A` records to GitHub's Pages IPs (see GitHub docs)
   - Or a subdomain: `CNAME` → `<username>.github.io`
5. Enable **Enforce HTTPS** once the certificate is issued.

`.nojekyll` makes Pages serve `.sh` and `.ps1` files exactly as committed.

---

## Adding a script

```bash
cp templates/mac-template.sh mac/network/flush-dns.sh
# edit header + body, test on a lab machine
echo "- mac/network/flush-dns.sh — 🟢 Flush DNS cache and restart mDNSResponder" >> INDEX.md
git add -A && git commit -m "mac/network: add flush-dns" && git push
```

---

## Disclaimer

Written and tested for my own lab environment. Review before running on any machine you do not manage.
