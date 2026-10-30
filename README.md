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
├── index.html              # spieles.us home page (cards built from _data/scripts.yml)
├── INDEX.md                # one-line catalog, generated from _data/scripts.yml
├── _config.yml             # Jekyll/GitHub Pages settings, badge labels
├── _data/scripts.yml       # script catalog: titles + plain-language descriptions
├── _layouts/default.html   # page template for every rendered page
├── assets/                 # style.css, site.js (copy buttons, filter)
├── .gitattributes          # enforces LF for .sh, CRLF for .ps1
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
│   ├── intune/             # Autopilot registration, sync, device info
│   ├── network/
│   ├── system/
│   ├── users/
│   └── apps/
├── templates/
│   ├── mac-template.sh     # starting point for new Mac scripts
│   └── win-template.ps1    # starting point for new Windows scripts
└── docs/
    ├── how-to-use.md       # start here: for students and new staff
    ├── decommission-mac.md # runbook: Mac prep for resale/surplus
    ├── remove-jamf-mac.md  # full Jamf removal incl. Conditional Access
    ├── win-autopilot-reimage.md     # Path A: hash upload + reset
    ├── win-autopilot-new-device.md  # Path B: pre-registered new PC
    ├── win-intune-troubleshooting.md
    └── hosting-and-dns.md  # how this repo is hosted + DNS primer
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

**Audience badges** (set per script in `_data/scripts.yml`)
- `anyone`: read-only, changes nothing; safe for students and to pipe straight into a shell
- `admin`: changes settings, needs admin rights; download and review first
- `staff`: removes software or resets; IT staff only; always download, read, then run

---

## Hosting (GitHub Pages + short domain)

1. Create a **public** GitHub repo named `lab-toolkit`.
2. Settings → Pages → Source: *Deploy from branch* → `main` / root.
3. Add your domain to `CNAME` (one line, e.g. `spieles.us`).
4. At your DNS provider, add the GitHub Pages records:
   - Apex domain: `A` records to GitHub's Pages IPs (see GitHub docs)
   - Or a subdomain: `CNAME` → `<username>.github.io`
5. Enable **Enforce HTTPS** once the certificate is issued.

GitHub Pages runs Jekyll: Markdown files render as HTML pages, and scripts (no front matter) are served exactly as committed.

---

## Adding a script

```bash
cp templates/mac-template.sh mac/network/flush-dns.sh
# edit header + body, test on a lab machine
# then add an entry to _data/scripts.yml (title, audience, when, what, cmd)
git add -A && git commit -m "mac/network: add flush-dns" && git push
```

---

## Disclaimer

Written and tested for my own lab environment. Review before running on any machine you do not manage.
