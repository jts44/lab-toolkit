---
title: How to use this site
description: Opening Terminal or PowerShell, pasting a command, and what to send IT. Start here.
audience: anyone
order: 1
---

# How to use this site

Each script on the home page is a small program that checks or fixes something on a lab computer. You copy one line, paste it into a command window, and read the result.

## 1. Check the badge first

- <span class="badge anyone">Safe for anyone</span> Only looks at the computer and changes nothing. Go ahead.
- <span class="badge admin">Needs admin password</span> Changes a setting. Only run it if you have been given admin access and told to use it.
- <span class="badge staff">IT staff only</span> Removes software or resets the computer. Do not run it. Report the problem to IT staff instead.

## 2. Open the command window

**Mac: Terminal**

1. Press **Command + Space**, type `Terminal`, press **Return**.
2. Commands that start with `sudo` ask for a password. **Nothing appears while you type it.** That is normal. Type it and press **Return**.

**Windows: PowerShell**

1. Click **Start** and type `PowerShell`.
2. For <span class="badge anyone">Safe for anyone</span> scripts, just click **Windows PowerShell**.
3. For <span class="badge admin">Needs admin password</span> scripts, right-click **Windows PowerShell** → **Run as administrator** → enter the admin credentials.

## 3. Copy, paste, run

1. On the home page, click **Copy** next to the command.
2. Paste it into the window: **Command + V** on Mac; **Ctrl + V** or right-click on Windows.
3. Press **Return / Enter** and wait until the prompt comes back.

## 4. Read and report the result

- Each script card says what a good result looks like under **Next**.
- To report a problem, include:
  - the computer name (on the label, or in the script output)
  - the room number
  - a screenshot of the output (Mac: **Command + Shift + 4**; Windows: **Windows + Shift + S**)
  - what you were doing when the problem started

## Rules

- Only run commands copied from this site.
- If a script asks to delete, remove, or reset something and you were not told to do that, answer **N** (no) and stop.
- If you see red error text you don't understand, stop and send a screenshot to IT staff. Don't try a different script to see if it helps.
