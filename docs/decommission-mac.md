---
title: "Retire or resell a Mac"
description: "Order of steps to remove management software and erase a Mac for resale or surplus."
audience: staff
order: 10
---

# Runbook: Mac decommission for resale or surplus

## Before touching the Mac
1. Release the serial number in Apple School/Business Manager.
2. Unmanage and delete the computer record in Jamf Pro.
3. If Jamf Conditional Access was used: retire the Microsoft Entra ID / Intune device record.
4. Confirm the user's data is backed up or no longer needed.

## On the Mac
1. `sudo zsh remove-beyondtrust.sh`: restores normal admin/sudo behavior
2. `sudo zsh remove-jamf.sh`: framework, apps, Jamf Connect, Conditional Access ([details](remove-jamf-mac.md))
3. Restart (`sudo shutdown -r now`): clears per-user agents still in memory
4. `sudo zsh verify.sh`: expect `No / No` for enrollment and `none` everywhere else
5. Sign out of Apple ID / iCloud; disable Find My (clears Activation Lock).
6. Erase:
   - Apple silicon or T2: System Settings → General → Transfer or Reset → Erase All Content and Settings
   - Intel without T2: Recovery → Disk Utility erase → Reinstall macOS

## After erase
- At Setup Assistant, confirm **no Remote Management screen** appears. If it does, the ABM/ASM release has not propagated or was missed.
