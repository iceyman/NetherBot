# NetherBot v2.1 — NPCBot Control Panel

A modern, tabbed in-game control panel for the **NPCBots** mod
([trickerer/Trinity-Bots](https://github.com/trickerer/Trinity-Bots)) on
**TrinityCore / AzerothCore 3.3.5**. Click buttons instead of typing `.npcbot`
commands.

Original addon by **NetherstormX**. UI rework, bug-fixes, GM-mode gating and the
`createnew` builder by **Iceymidgit**.

---

## What's new in v2.1

- **Tabbed dark UI** (Control · Behavior · Manage · Create) — the old single
  cluttered window is gone.
- **GM Mode toggle** — players see only what they can use; admins flip a switch
  to reveal the power tools.
- **`.npcbot createnew` builder** — a form that assembles the custom-bot command
  for you.
- **Lots more commands wired up** — behaviour toggles, set faction/spec,
  attack-distance, list spawned/free, kill/suicide/eject.
- **Bug-fixes** (see bottom) and **saved settings** (position, scale, last tab,
  GM mode).

---

## Installation

1. Copy `netherbot.lua` and `NetherBot.toc` into your existing
   `World of Warcraft\Interface\AddOns\NetherBot` folder, **overwriting** the old
   files. Keep your `locale\` subfolder (it holds translations).
2. If you do **not** already have NetherBot, drop the whole `NetherBot` folder
   into `Interface\AddOns\`. The `locale\` translation files are optional —
   English works without them.
3. At the character screen, make sure **NetherBot** is enabled under AddOns.
4. In game, type `/reload` (or relog).

## Opening / closing

| Command | Action |
|---|---|
| `/netherbot` or `/nb` | Show the panel |
| `/netherbot hide` or `/nb hide` | Hide the panel and all its sub-windows |

You can also drag the window anywhere, resize it with the **−/+** buttons in the
header, and close it with **X**. Position, scale, last-used tab and GM Mode are
all remembered between sessions.

---

## The tabs

### Control (everyone)
Day-to-day bot control.

- **Follow / Stand / Stop / Slack** — `command follow`, `command standstill`,
  `command stopfully`, `command follow only`.
- **Unhide / Hide / Recall / Unbind** — `unhide`, `hide`, `recall teleport`,
  `command unbind`.
- **Follow Distance** — Low (30) / Medium (50) / High (85); the active one stays
  highlighted.
- **Raid Frames** — toggles a movable raid health/mana display for your bots.
- **Revive Bots** — `revive` (note: revive is a GM command on most servers).

### Behavior (everyone)
Fine-tuning and troubleshooting.

- **Toggles** — Walk, No Gossip, No Cast, No Long (cast), Rebind, Recall Spawns.
- **Attack Distance** — Short / Long, or type an exact value (0–50) and press
  Enter.
- **Troubleshooting** — Eject (out of vehicles), Kill, Suicide (both confirm
  first; they force stuck bots to die so they respawn clean).

### Manage (GM only)
Admin actions. Hidden until GM Mode is on.

- **Add / Remove / Move / Recall / Bot-Info / Delete** — target a bot or enter an
  ID when prompted.
- **Lookup / Spawn** — opens a class list (`lookup <class>`) and a spawn-by-ID box
  (`spawn <id>`).
- **List Spawned / Free** — `list spawned`, `list spawned free`.
- **Set Faction** — Alliance / Horde / Hostile / Friendly (`set faction a|h|m|f`)
  on the selected bot.
- **Set Spec** — type 1–30 and Apply (`set spec <n>`).
- **Redemption** icon — secure button to cast Redemption on a target.

### Create (GM only)
Builds the `.npcbot createnew` command for custom bots.

- Enter a **Name** and **Class** (required). For special classes (12–19) that's
  all you need.
- For normal classes, fill **Race, Gender, Skin, Face, Hair, Color, Features,
  Sound**.
- **Ranges** prints the valid appearance numbers for every race to chat.
- **Create Bot** assembles and sends the full command (spaces in the name are
  auto-converted to underscores) and echoes it to your chat frame.

---

## GM Mode — how it works (and its limits)

The 3.3.5 game client cannot reliably tell whether your account is a GM, so GM
Mode is an **honour-system toggle**, not a security feature. With it **off**,
only Control and Behavior are shown — a tidy view for a normal player. With it
**on**, Manage and Create appear.

This is purely about decluttering the interface. The commands themselves are
still enforced **server-side** by RBAC / permissions, so a non-GM who flips the
switch and clicks "Delete" or "Create Bot" simply gets nothing — the server
refuses. Your server is the real gatekeeper.

---

## Bug-fixes vs. the original

- `recall teleport` — the original sent a misspelled `recal teleport`.
- **Spawn** now uses the `SAY` chat channel (the original used `GUILD`, which
  failed if you weren't in a guild).
- Removed **duplicate global frame names** (three buttons all shared
  `NetherbotShow3Button`).
- The window **position** is now saved (the original only saved scale).

---

## Requirements

- WoW client **3.3.5a** (interface 30300).
- A TrinityCore or AzerothCore 3.3.5 server with the **NPCBots** mod installed.
- For the GM tabs to actually do anything, your account needs the matching
  command permissions on the server.
