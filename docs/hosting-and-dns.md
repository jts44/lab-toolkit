# Hosting lab-toolkit on spieles.us

How this repo is published, how to add scripts, and the DNS basics for future projects.

---

## 1. How it works

```
GitHub repo (jts44/lab-toolkit, public, branch main)
        │  push
        ▼
GitHub Pages (builds in ~1 min)
        │  serves files as-is (.nojekyll)
        ▼
spieles.us  ← DNS A records point here
```

- Repo path = URL path: `mac/network/flush-dns.sh` → `https://spieles.us/mac/network/flush-dns.sh`
- `CNAME` file (repo root) tells GitHub which domain this site answers to. Do not delete it.
- Repo must stay **public** (Pages on private repos requires GitHub Pro).

---

## 2. Everyday workflow

**Add or edit a script**
```bash
cd ~/Documents/GitHub/lab-toolkit
cp templates/mac-template.sh mac/network/flush-dns.sh   # new script
# edit, test locally with --dry-run
git add -A && git commit -m "mac/network: add flush-dns" && git push
```
- Live in ~1 minute. Check progress: repo → **Actions** → "pages build and deployment".
- Add a line to `INDEX.md` for every new script.

**Use a script on a lab Mac**
```bash
curl -fsSLO https://spieles.us/mac/decommission/remove-jamf.sh   # download
less remove-jamf.sh                                              # read
sudo zsh remove-jamf.sh --dry-run                                # preview
sudo zsh remove-jamf.sh                                          # run
```
- 🟢 read-only only: `curl -fsSL https://spieles.us/<path> | zsh`

**Use a script on a lab PC (PowerShell)**
```powershell
irm https://spieles.us/win/system/info.ps1 -OutFile info.ps1
powershell -ExecutionPolicy Bypass -File .\info.ps1
```

**Stale file after a push?** GitHub's CDN caches ~10 min. Force a fresh copy:
`curl -fsSLO "https://spieles.us/<path>?v=$(date +%s)"`

---

## 3. Current configuration (reference)

- **GitHub account:** Settings → Pages → `spieles.us` **Verified** (TXT record `_github-pages-challenge-jts44`)
- **Repo:** Settings → Pages → Source `main` / root · Custom domain `spieles.us` · Enforce HTTPS ✔
- **DNS at registrar (`spieles.us`):**
  - `A @` → `185.199.108.153`, `185.199.109.153`, `185.199.110.153`, `185.199.111.153`
  - `AAAA @` → `2606:50c0:8000::153` … `2606:50c0:8003::153` (optional)
  - `CNAME www` → `jts44.github.io` (optional)
  - `TXT _github-pages-challenge-jts44` → verification code (keep)

---

## 4. DNS in five minutes

DNS maps names to destinations. Each **record** has a **name** (host), a **type**, a **value**, and a **TTL**.

**Names**
- `@` = the apex (root) domain itself: `spieles.us`
- Anything else is a **subdomain**: `www`, `tools`, `wiki` → `tools.spieles.us`
- Subdomains are free and unlimited: one domain can host many projects.

**Record types you will actually use**
- **A**: name → IPv4 address. `@ → 185.199.108.153`
- **AAAA**: name → IPv6 address. Same idea, newer protocol.
- **CNAME**: name → *another name* ("go ask over there"). `tools → jts44.github.io`
  - Not allowed on the apex (`@`); use A records there, or ALIAS/ANAME if your registrar offers it.
  - A name with a CNAME can have no other records.
- **TXT**: free-form text; used to prove ownership (GitHub, Google, Microsoft) and for email security (SPF, DMARC).
- **MX**: where email for the domain is delivered. Only matters if you use email on the domain.
- **NS**: which company's servers hold the domain's records (your registrar or e.g. Cloudflare). Records only take effect at the NS provider.

**TTL and propagation**
- TTL = how long (seconds) resolvers cache an answer. 3600 = 1 hour.
- Changes appear when caches expire: usually minutes, up to 24 h.
- Tip: lower TTL to 300 a day before making changes; raise it afterwards.

**Checking from Terminal**
```bash
dig +short spieles.us                 # A records
dig +short AAAA spieles.us            # IPv6
dig +short tools.spieles.us           # CNAME chain
dig +short TXT _github-pages-challenge-jts44.spieles.us
dig +short NS spieles.us              # who hosts the DNS
dig @1.1.1.1 +short spieles.us        # ask a specific resolver (bypass local cache)
```
On Windows: `Resolve-DnsName spieles.us`.

---

## 5. Pattern for future Git projects

Give each project its own subdomain instead of a new domain.

1. Create the repo (public), add a `CNAME` file containing e.g. `wiki.spieles.us`.
2. Repo → Settings → Pages → source `main` / root → custom domain `wiki.spieles.us`.
3. Registrar → add `CNAME wiki → jts44.github.io` (never include the repo name).
4. `dig +short wiki.spieles.us` → wait for **DNS check successful** → **Enforce HTTPS**.

Already verified at the domain level, so subdomains need no new TXT record.

**Safety rules**
- Never create a wildcard record (`*.spieles.us`): enables subdomain takeover.
- When you retire a site, **delete its DNS record the same day**. A record pointing at a disabled Pages site can be claimed by someone else.
- Keep secrets out of public repos; Pages publishes everything in the branch.

---

## 6. Troubleshooting

- **404 on spieles.us:** Pages source not set, deploy failed (Actions tab), or wrong path/case (URLs are case-sensitive).
- **Custom domain field keeps clearing:** `CNAME` file missing or edited.
- **Certificate error / HTTPS box greyed out:** DNS not yet correct, or cert still issuing (≤24 h). Still stuck: remove domain, save, re-add.
- **Works on one machine, not another:** cached DNS. `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder` (Mac) · `ipconfig /flushdns` (Windows).

Sources:
- GitHub Docs: Managing a custom domain for your GitHub Pages site: https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site
- GitHub Docs: What is GitHub Pages?: https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages
