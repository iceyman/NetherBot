# Changelog

## v2.1
- **GM Mode toggle** in the header: hides the admin tabs (Manage, Create) for
  regular players; flip it on to reveal them. Saved between sessions.
- **Create tab**: a `.npcbot createnew` builder (name + class + appearance +
  sound) with a Ranges helper. Auto-underscores names; special classes need only
  name + class.
- **Behavior tab**: walk / nogossip / nocast / nolongcast / rebind / recall
  spawns toggles, attack-distance short/long/exact, and kill / suicide / vehicle
  eject troubleshooting.
- **Manage tab**: add / remove / move / recall / info / delete, lookup & spawn,
  list spawned/free, set faction (A/H/M/F), set spec (1-30).
- Window position, scale, last tab and GM mode are now all persisted.

## v2.0
- Full modern dark "nether" UI rework (tabbed), replacing the original single
  window.
- Bug-fixes: corrected the `recall teleport` command typo; spawn now uses the
  SAY channel instead of GUILD; removed duplicate global frame names; window
  position is now saved.

## v1.1 (original, by NetherstormX)
- Original single-window addon with one-click NPCBot commands, raid frames and
  locale support.
