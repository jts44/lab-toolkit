# Intune / Autopilot troubleshooting

Quick state check on the PC (read-only):

```powershell
irm https://spieles.us/win/intune/get-device-info.ps1 | iex
```

---

## Timing: most "failures" are just waiting

Cloud records update on different clocks. Before you change anything, confirm the previous change has landed.

- **Hash upload → visible in Autopilot devices:** minutes (use **Sync**, then **Refresh** in the pane)
- **Added to an Entra group → Autopilot profile Assigned:** up to **several hours**
- **Dynamic group membership recalculation:** minutes to hours
- **On-prem AD change (OU move, rename) → reflected in Entra:** next Entra Connect sync cycle (typically ~30 min; longer if the sync is backlogged)
- **Policy or app assignment → applied on the PC:** next check-in (force it with `sync-intune.ps1`), then 15–30 min; Win32 apps longer

Rules of thumb:

- Never reset until **Profile status = Assigned** in the Autopilot devices pane.
- After any group change, wait, then sync. Repeated resets do not speed up the cloud.
- If something still looks wrong after several hours, check the next sections.

---

## Symptoms and fixes

**PC came up as a normal Windows setup, not the organization's sign-in**
- Profile was not assigned when the PC reached OOBE.
- Check Autopilot devices → serial → profile status and group membership → wait for *Assigned* → reset again.

**Device not found in Autopilot devices**
- Hash never uploaded, or uploaded to a different tenant.
- Run `register-autopilot.ps1` (Path A). Search by the BIOS serial, not the hostname.

**"This device is not properly managed" (or similar) logon message**
- Device is missing its building/area group.
- Add it to `Intune.DeviceGroup.<Campus>.<Building>` (nested subgroups also count) → sync → wait 15–20 min.
- Still showing after the group is confirmed and synced: run `clear-logon-notice.ps1`, then reboot.

**Computer GPOs not applying / wrong drive maps or printers**
- AD computer object is still in the Autopilot staging OU.
- Move it to `<Area OU>` in Active Directory Users and Computers → `gpupdate /force` → reboot.
- Confirm with `get-device-info.ps1` (AD location).

**Hybrid join incomplete (`Domain joined: YES`, `Entra joined: NO`)**
- The AD object has not synced to Entra yet, or the OU is outside the Entra Connect sync scope.
- Wait one sync cycle; confirm the target OU is in sync scope; have a user sign in on the domain network, then reboot.
- Check with `dsregcmd /status`.

**Entra join broken after a rename**
- Renamed by unbinding and rebinding AD.
- Rename only through Settings. If already broken, the cleanest fix is usually a reset.

**Apps missing in Company Portal or "not the primary user" error**
- Primary User is wrong or unset.
- Intune → device → Properties → **Change Primary User** (dedicated PC) or **Remove Primary User** (shared/lab PC). The user needs an M365 license.

**Required apps or policies not arriving**
- Device is not in the app group, the device is noncompliant, or there has been no check-in yet.
- Confirm group membership → `sync-intune.ps1` → check Intune → device → Device compliance and Managed apps for errors.
- IME service missing or stopped (`get-device-info.ps1`) blocks Win32 apps and scripts.

**Can't add a device to a group**
- PIM role not active, or the group is outside your administrative unit.
- Activate the role and retry. For shared groups owned by another team, request access through your infrastructure team.

**Hash upload fails or sign-in loops**
- Role not active, a TLS or proxy issue, or an outdated script.
- Activate PIM first; the script forces TLS 1.2 and reinstalls the latest `Get-WindowsAutopilotInfo`. On first run you may need to consent to the app registration permissions. Fallback: `-Offline` and a CSV import.

**OOBE stuck on network or credential errors**
- Wi-Fi authentication restrictions during OOBE.
- Use **Ethernet**.

**Duplicate or stale records after re-imaging**
- Old Intune and Entra objects from the previous install.
- After the new enrollment succeeds, delete the stale Intune device record (older last check-in, same serial). Leave the Autopilot device record, which is what allows future resets.

---

## Useful commands on the PC

```powershell
dsregcmd /status                       # join state, device ID, PRT
gpupdate /force                        # reapply Group Policy
Get-Service IntuneManagementExtension  # Win32 app/script agent
# Collect MDM/Autopilot diagnostics into a .cab for deeper digging:
mdmdiagnosticstool.exe -area "DeviceEnrollment;DeviceProvisioning;Autopilot" -cab C:\Temp\mdmdiag.cab
```
