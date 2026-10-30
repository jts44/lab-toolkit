# Removing Jamf completely from macOS

- **Applies to:** Jamf Pro, Jamf Connect, Jamf Conditional Access (legacy), Microsoft Entra ID / Intune
- **Scripts:** `mac/decommission/remove-jamf.sh` 🔴 · `mac/decommission/verify.sh` 🟢
- **Scope:** Institution-owned Macs that are **authorized** for removal from Jamf. Do not remove management components from an actively managed computer.

---

## Quick path

```bash
curl -fsSLO https://spieles.us/mac/decommission/remove-jamf.sh
sudo zsh remove-jamf.sh --dry-run      # preview
sudo zsh remove-jamf.sh                # remove
sudo shutdown -r now                   # restart
curl -fsSL https://spieles.us/mac/decommission/verify.sh | sudo zsh
```

`remove-jamf.sh` is safe to re-run. If Conditional Access prompts appear after an earlier `jamf removeFramework`, run it again and restart.

---

## What has to go

Jamf leaves up to three layers on a Mac. `jamf removeFramework` handles only the first.

1. **Jamf Pro management:** MDM enrollment profile, Jamf framework (`/usr/local/jamf`, `jamf` binary, launch daemons).
2. **Jamf apps and background services:** Self Service, Jamf Connect, JamfAgent, launch agents, preferences.
3. **Jamf Conditional Access (jamfAAD):** legacy Microsoft Entra ID / Intune device registration. Runs as a per-user launch agent and can keep showing registration prompts after the framework is gone.

Components you may find (not every Mac has all of them):

- `/Library/Application Support/JAMF/Jamf.app`: container app that bundles the two below
  - `…/Contents/MacOS/Jamf Conditional Access.app`: Microsoft device registration
  - `…/JamfAgent.app`: compliance reporting
- `/Library/LaunchAgents/com.jamf.management.jamfAAD.agent.plist`: Conditional Access agent
- `/Library/LaunchAgents/com.jamf.management.jamfAAD.clean.agent.plist`: Conditional Access cleanup agent
- `/Library/Preferences/com.jamfsoftware.management.jamfAAD.plist`: Conditional Access settings
- `/Applications/Self Service.app` (or `Self Service+.app`): policy and software portal
- `/Applications/Jamf Connect.app` + `/usr/local/bin/authchanger`: login window and identity

---

## 1. Remove management (server side first)

If the Mac still checks in with Jamf Pro:

1. Open the computer record in Jamf Pro.
2. **Management → Remove MDM Profile** (if offered), then **Unmanage**.
3. Confirm the commands completed, then delete the computer record.

Options vary by Jamf Pro version and enrollment method.

**ADE (Automated Device Enrollment):** if the serial is still assigned to an MDM server in Apple School/Business Manager, the Mac re-enrolls at Setup Assistant after an erase. Release or reassign it there; local cleanup cannot fix this.

---

## 2. Remove local components

`remove-jamf.sh` performs these steps in order:

1. `authchanger -reset` (Jamf Connect only). Resets the login window first so it is not left pointing at deleted plugins.
2. `jamf removeFramework`: Jamf's own uninstaller. Removes the framework, but **not** necessarily the MDM profile, separately installed apps, or Conditional Access.
3. Unloads launchd jobs:
   - Daemons from the `system` domain
   - Agents from **each logged-in user's** `gui/<uid>` domain, by label
4. Stops remaining processes: Conditional Access, Self Service, JamfAgent.
5. Deletes apps, `/Library/Application Support/JAMF`, preferences (`com.jamfsoftware.*`, `com.jamf.*`), and logs.
6. Deletes per-user Jamf preferences and caches.
7. Forgets Jamf package receipts.

**Why Conditional Access lingers.** Its agents run inside the user's login session, not the system domain. Deleting the plist does not stop a job that is already loaded, and `launchctl bootout system …` does not reach it. The job keeps running, and the notifications continue, until it is booted out of `gui/<uid>` or the Mac restarts.

Manual equivalent for the current user:

```bash
for label in com.jamf.management.jamfAAD.agent com.jamf.management.jamfAAD.clean.agent; do
  launchctl bootout "gui/$(id -u)/$label" 2>/dev/null
  sudo rm -f "/Library/LaunchAgents/$label.plist"
done
sudo rm -rf "/Library/Application Support/JAMF"
sudo rm -f /Library/Preferences/com.jamfsoftware.management.jamfAAD.plist
sudo shutdown -r now
```

---

## 3. Microsoft Entra ID / Intune (if Conditional Access was used)

Local cleanup does not remove the cloud-side device record. If prompts persist after cleanup and a restart:

1. Find the device in **Microsoft Entra ID → Devices** and check for a matching **Intune** record.
2. Retire or delete the obsolete records through IT's normal device-retirement process.
3. Check whether Company Portal was installed as part of the integration.
4. Inspect keychain items (e.g., Workplace Join / `com.jamf.management.jamfAAD`) only if registration problems persist.

**Caution:** Do not remove Microsoft authentication credentials, Company Portal, or registration files if the Mac still uses Microsoft 365 or is migrating to Intune. For resale, an erase clears all local Microsoft state anyway; only the cloud record needs retiring.

---

## 4. Check background items

**System Settings → General → Login Items & Extensions:** look for remaining Jamf entries under *Allow in the Background*.

Disabling a background item does not uninstall it. If an entry remains after the script and a restart, find its plist with:

```bash
sudo find /Library/LaunchAgents /Library/LaunchDaemons ~/Library/LaunchAgents -maxdepth 1 -iname '*jamf*'
```

---

## 5. Verify (after restart)

```bash
sudo zsh verify.sh
```

Expected:

- `profiles status -type enrollment` → `Enrolled via DEP: No` and `MDM enrollment: No`
- Every other section → `none`
- **System Settings → General → Device Management** shows no profiles

Spot checks:

```bash
ps aux | grep -i '[j]amf'                          # running processes
launchctl print gui/$(id -u) | grep -i jamf        # loaded user agents
find /Applications -maxdepth 2 -iname '*jamf*'     # leftover apps
```

---

## Troubleshooting

- **Conditional Access prompts continue:** re-run `remove-jamf.sh`, restart, then check Entra ID / Intune (section 3).
- **`jamf: command not found`:** the framework is already gone; the script continues with manual cleanup.
- **`sudo` blocked or "admin rights required" dialogs:** remove BeyondTrust EPM first (`remove-beyondtrust.sh`).
- **Login window broken after removing Jamf Connect:** the login-window reset (step 2.1) was skipped. For a resale Mac, erase from Recovery; otherwise follow Jamf's Jamf Connect uninstall documentation.
- **Remote Management screen after erase:** the serial is still assigned in ABM/ASM.
