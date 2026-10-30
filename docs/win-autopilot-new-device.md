---
title: "Set up a new Dell already in Autopilot"
description: "Move a pre-registered PC into the right groups before its first boot."
audience: staff
order: 21
---

# Path B: New Dell already registered in Autopilot (group migration only)

**Use when:** the vendor registered the hardware hash at purchase, so the serial already appears in Intune → Devices → Enrollment → Windows Autopilot → Devices. No script or hash upload needed.

**Scripts (optional):** `win/intune/get-device-info.ps1` 🟢 · `win/intune/sync-intune.ps1` 🟡

> Placeholders: `Intune.DeviceGroup.Autopilot.<Profile>` · `Intune.DeviceGroup.<Campus>.<Building>` · `Intune.AppGroup.<App>` · AD OU `<Area OU>`

---

## Before powering on

Do the group work **before** the first boot. If the PC reaches OOBE first, it provisions with whatever profile and apps it currently has.

1. **Get the service tag** from the box label or BIOS. In BIOS, also note the MAC addresses and make any required changes (e.g., storage mode).
2. **Record the device** in the asset system and register its MAC addresses for network access, if required.
3. **Confirm registration:** Intune → Autopilot devices → search the service tag.
   - Not listed → follow [Path A](win-autopilot-reimage.md) instead (upload the hash yourself, during OOBE if needed).
4. **Activate your admin role** (PIM).
5. **Migrate groups:** Entra admin center → find the device object by **serial number**.
   - Check **Group memberships**. Vendor-registered devices often land only in a default or catch-all Autopilot group.
   - Add: `Intune.DeviceGroup.Autopilot.<Profile>`, `Intune.DeviceGroup.<Campus>.<Building>`, and any `Intune.AppGroup.<App>` groups.
   - Remove: any default group that assigns a conflicting profile. A device can receive only **one** Autopilot profile; overlapping groups make the assignment unpredictable.
6. **Wait for assignment:** Autopilot devices → *serial* → **Profile status = Assigned**, and the profile name matches the group you added. This can take **several hours**; plan the unboxing for the next day if needed.

## Provision

7. Connect **Ethernet**, power on, and let OOBE start (no key presses).
8. Sign in with the end user's or your admin account; click **Continue** past non-fatal errors.
9. Do the [Finish steps](win-autopilot-reimage.md#finish-steps-both-paths): rename, move the AD object, Primary User, updates, verify.

## Already booted with the wrong groups?

- **Apps or policies missing, but the profile was right:** fix the groups, run `sync-intune.ps1`, and wait. No reset needed.
- **Wrong Autopilot profile** (wrong join type, wrong naming, wrong OOBE experience): fix the groups, wait for the new profile to show *Assigned*, then **reset** (Intune Wipe, or Reset this PC → Remove everything).

Problems? See [win-intune-troubleshooting.md](win-intune-troubleshooting.md).
