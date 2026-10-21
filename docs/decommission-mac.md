# Runbook: Mac decommission for resale or surplus

## Before touching the Mac
1. Release the serial number in Apple School/Business Manager.
2. Delete the computer record in Jamf Pro.
3. Confirm the user's data is backed up or no longer needed.

## On the Mac
1. `sudo zsh remove-beyondtrust.sh`: restores normal admin/sudo behavior
2. `sudo zsh remove-jamf.sh`
3. `sudo zsh verify.sh`: expect "none" for every section
4. Sign out of Apple ID / iCloud; disable Find My (clears Activation Lock).
5. Erase:
   - Apple silicon or T2: System Settings → General → Transfer or Reset → Erase All Content and Settings
   - Intel without T2: Recovery → Disk Utility erase → Reinstall macOS

## After erase
- At Setup Assistant, confirm **no Remote Management screen** appears. If it does, the ABM/ASM release has not propagated or was missed.
