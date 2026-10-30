---
title: "Re-image an existing Windows PC (Autopilot)"
description: "Upload the hardware hash, fix the groups, wait for the profile, then reset."
audience: staff
order: 20
---

# Path A: Re-image an existing PC with Autopilot (hash upload + reset)

**Use when:** the PC is not listed under Intune → Devices → Enrollment → Windows Autopilot → Devices (older hardware, reused machine, never registered).

**Scripts:** `win/intune/register-autopilot.ps1` 🟡 · `win/intune/get-device-info.ps1` 🟢

> Names below are placeholders. Substitute your team's conventions (kept in the internal KB):
> `Intune.DeviceGroup.Autopilot.<Profile>` · `Intune.DeviceGroup.<Campus>.<Building>` · `Intune.AppGroup.<App>` · AD OU `<Area OU>`

---

## Checklist

1. **Record the device** in the asset system and register its Ethernet/Wi-Fi MAC addresses for network access, if your network requires it.
2. **Activate your admin role** (PIM) before touching Entra or Intune. You need Intune enrollment rights for the upload and Groups rights for step 4.
3. **Upload the hash.** In an elevated PowerShell on the PC:
   ```powershell
   irm https://spieles.us/win/intune/register-autopilot.ps1 -OutFile register-autopilot.ps1
   powershell -ExecutionPolicy Bypass -File .\register-autopilot.ps1
   ```
   - Sign in with your admin account when prompted; approve NuGet/PSGallery prompts.
   - No network login or no Windows yet? Use OOBE: **Shift+F10** → `powershell` → same commands.
   - No internet on the PC? Add `-Offline`, carry `C:\HWID\AutopilotHWID.csv` out, and import it in Intune (Autopilot devices → **Import**).
4. **Add the device to groups** (Entra admin center → Groups → *group* → Members → Add members). Search by **serial number**: Autopilot creates an Entra device object named after the serial.
   - Autopilot/profile group: `Intune.DeviceGroup.Autopilot.<Profile>`
   - Building/area group: `Intune.DeviceGroup.<Campus>.<Building>` (prevents the "not properly managed" logon message)
   - Any app groups the room needs
5. **Wait for assignment.** Intune → Autopilot devices → find the serial → **Profile status = Assigned**.
   - Hash appears in minutes; group membership and profile assignment can take **several hours**.
   - Do not reset before it shows *Assigned*, or the PC comes up as a plain Windows install and you will have to reset again.
6. **Reset the PC.** Either:
   - On the PC: Settings → System → Recovery → **Reset this PC → Remove everything**, or
   - In Intune: device → **Wipe** (if your tenant requires a second admin to approve, request it). Wipe works for several PCs at once.
7. **Provision.** Use **Ethernet** (Wi-Fi auth often fails during OOBE). Let OOBE start, sign in with the end user's or your admin account, and click **Continue** past non-fatal errors. If you reach the desktop, fix the remaining items afterward; do not reset again.
8. **Finish:** go to [Finish steps (both paths)](#finish-steps-both-paths).

---

## Finish steps (both paths)

- **Rename** to your naming standard through **Settings → System → About → Rename this PC**. Never unbind and rebind AD to rename; that can break the Entra join.
- **Move the computer object in Active Directory** (hybrid-joined PCs) from the Autopilot staging OU to `<Area OU>`, then on the PC:
  ```powershell
  gpupdate /force
  ```
  Reboot so computer GPOs apply. Make sure the target OU is inside the Entra Connect sync scope or the hybrid join will drop.
- **Set the Primary User** in Intune → Devices → *device* → Properties. For lab or shared PCs, **remove** the Primary User instead (Shared PC mode). The user needs an M365 license to be assigned.
- **Run updates** (Windows Update and Dell Command | Update).
- **Verify:**
  ```powershell
  irm https://spieles.us/win/intune/get-device-info.ps1 | iex
  ```
  Expect: Join type = Hybrid or Entra joined · Intune enrolled = Yes · Autopilot profile = Yes · AD location = `<Area OU>` · IME service = Running.
- If you use co-management, confirm the Configuration Manager client is installed (Control Panel → Configuration Manager → Co-management = Enabled).

Problems? See [win-intune-troubleshooting.md](win-intune-troubleshooting.md).

Sources:
- Microsoft Learn: Manually register devices with Windows Autopilot: https://learn.microsoft.com/en-us/autopilot/add-devices
