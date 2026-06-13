-- =============================================================================
--  NetherBot  -  NPCBot control panel for TrinityCore 3.3.5
--  Modern dark UI, tabbed (v2.1).  Original addon by NetherstormX.
--  UI rework, bugfixes & feature expansion from Iceymidgit.
--
--  Tabs:  Control  |  Behavior  |  Manage  |  Create
--  Adds:  .npcbot createnew builder, behaviour toggles (walk/nocast/nolongcast/
--         nogossip/rebind), set faction & spec, attack-distance, recall spawns,
--         kill/suicide/vehicle-eject, list spawned/free.
--  Fixes: recall-teleport typo; spawn now uses SAY; unique frame names; window
--         position + active tab are saved between sessions.
-- =============================================================================

NetherBot.InitLocale()
local i18n = NetherBot.I18n
NetherbotDB = NetherbotDB or {}

-- ----------------------------------------------------------------------------
--  THEME
-- ----------------------------------------------------------------------------
local FONT  = "Fonts\\FRIZQT__.TTF"
local SOLID = "Interface\\Buttons\\WHITE8X8"
local ICON  = "Interface\\Icons\\"
local COL = {
  panelBg     = { 0.075, 0.067, 0.110, 0.97 },
  panelBorder = { 0.42,  0.30,  0.78,  1.00 },
  header      = { 0.13,  0.10,  0.20,  1.00 },
  body        = { 0.10,  0.09,  0.15,  0.96 },
  accent      = { 0.62,  0.48,  1.00,  1.00 },
  accentDim   = { 0.32,  0.24,  0.52,  1.00 },
  btn         = { 0.16,  0.14,  0.22,  1.00 },
  btnHover    = { 0.26,  0.21,  0.38,  1.00 },
  btnBorder   = { 0.30,  0.26,  0.42,  1.00 },
  text        = { 0.91,  0.89,  0.96,  1.00 },
  textMuted   = { 0.55,  0.52,  0.62,  1.00 },
  green       = { 0.46,  0.82,  0.45,  1.00 },
  red         = { 0.90,  0.38,  0.32,  1.00 },
}

-- ----------------------------------------------------------------------------
--  HELPERS
-- ----------------------------------------------------------------------------
local function ApplyBackdrop(f, bg, border, edge)
  f:SetBackdrop({ bgFile = SOLID, edgeFile = SOLID, edgeSize = edge or 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 } })
  f:SetBackdropColor(unpack(bg))
  f:SetBackdropBorderColor(unpack(border))
end

local function MakeFS(parent, size, color, flags)
  local fs = parent:CreateFontString(nil, "OVERLAY")
  fs:SetFont(FONT, size or 12, flags or "")
  fs:SetTextColor(unpack(color or COL.text))
  return fs
end

local function SectionLabel(parent, text)
  local fs = MakeFS(parent, 10, COL.textMuted)
  fs:SetText(string.upper(text))
  return fs
end

local function Say(cmd) SendChatMessage(cmd, "SAY") end

local function Tip(frame, title, body)
  frame:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(title, COL.accent[1], COL.accent[2], COL.accent[3])
    if body then GameTooltip:AddLine(body, 0.8, 0.8, 0.85, true) end
    GameTooltip:Show()
  end)
  frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

local function TextButton(parent, w, h, label, onClick, textColor)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(w, h)
  ApplyBackdrop(b, COL.btn, COL.btnBorder)
  local fs = MakeFS(b, 11, textColor or COL.text)
  fs:SetPoint("CENTER"); fs:SetText(label)
  b.label = fs
  b:SetScript("OnEnter", function(self)
    self:SetBackdropColor(unpack(COL.btnHover)); self:SetBackdropBorderColor(unpack(COL.accent))
  end)
  b:SetScript("OnLeave", function(self)
    self:SetBackdropColor(unpack(COL.btn)); self:SetBackdropBorderColor(unpack(COL.btnBorder))
  end)
  if onClick then b:SetScript("OnClick", onClick) end
  return b
end

local function IconButton(parent, size, icon, caption, tip, onClick)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(size, size)
  ApplyBackdrop(b, COL.btn, COL.btnBorder)
  local tex = b:CreateTexture(nil, "ARTWORK")
  tex:SetPoint("TOPLEFT", 3, -3); tex:SetPoint("BOTTOMRIGHT", -3, -3)
  tex:SetTexture(icon); tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  local cap = MakeFS(b, 9, COL.textMuted)
  cap:SetPoint("TOP", b, "BOTTOM", 0, -2); cap:SetText(caption)
  b.caption = cap
  b:SetScript("OnEnter", function(self)
    self:SetBackdropBorderColor(unpack(COL.accent)); cap:SetTextColor(unpack(COL.accent))
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(caption, COL.accent[1], COL.accent[2], COL.accent[3])
    if tip then GameTooltip:AddLine(tip, 0.8, 0.8, 0.85, true) end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function(self)
    self:SetBackdropBorderColor(unpack(COL.btnBorder)); cap:SetTextColor(unpack(COL.textMuted))
    GameTooltip:Hide()
  end)
  if onClick then b:SetScript("OnClick", onClick) end
  return b
end

local function EditBox(parent, w, h)
  local e = CreateFrame("EditBox", nil, parent)
  e:SetSize(w, h); e:SetAutoFocus(false)
  e:SetFont(FONT, 12, ""); e:SetTextColor(unpack(COL.text))
  e:SetTextInsets(6, 6, 0, 0)
  ApplyBackdrop(e, COL.body, COL.btnBorder)
  e:SetScript("OnEscapePressed", e.ClearFocus)
  e:SetScript("OnEnterPressed", e.ClearFocus)
  e:SetScript("OnEditFocusGained", function(self) self:SetBackdropBorderColor(unpack(COL.accent)) end)
  e:SetScript("OnEditFocusLost", function(self) self:SetBackdropBorderColor(unpack(COL.btnBorder)) end)
  return e
end

local function Confirm(key, text, onYes)
  StaticPopupDialogs[key] = {
    text = text, button1 = "Yes", button2 = "No",
    timeout = 0, whileDead = true, hideOnEscape = true, OnAccept = onYes,
  }
  StaticPopup_Show(key)
end

local function PromptID(key, runWithTarget, runWithID)
  if UnitName("target") then
    runWithTarget()
  else
    StaticPopupDialogs[key] = {
      text = i18n("Enter NPCBOT ID:"), button1 = "OK", button2 = "Cancel",
      hasEditBox = true, timeout = 0, whileDead = true, hideOnEscape = true,
      OnAccept = function(self)
        local id = self.editBox:GetText(); if id and id ~= "" then runWithID(id) end
      end,
    }
    StaticPopup_Show(key)
  end
end

-- ----------------------------------------------------------------------------
--  MAIN FRAME + HEADER + TABS
-- ----------------------------------------------------------------------------
local frame = CreateFrame("Frame", "NetherbotFrame", UIParent)
frame:SetSize(330, 446)
frame:SetClampedToScreen(true)
ApplyBackdrop(frame, COL.panelBg, COL.panelBorder)
frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local p, _, rp, x, y = self:GetPoint()
  NetherbotDB.point = { p = p, rp = rp, x = x, y = y }
end)

local header = CreateFrame("Frame", nil, frame)
header:SetPoint("TOPLEFT", 1, -1); header:SetPoint("TOPRIGHT", -1, -1); header:SetHeight(30)
ApplyBackdrop(header, COL.header, COL.header)
local accentBar = header:CreateTexture(nil, "OVERLAY")
accentBar:SetTexture(SOLID); accentBar:SetVertexColor(unpack(COL.accent))
accentBar:SetPoint("BOTTOMLEFT"); accentBar:SetPoint("BOTTOMRIGHT"); accentBar:SetHeight(2)
local title = MakeFS(header, 14, COL.text)
title:SetPoint("LEFT", 10, 0); title:SetText("|cffae8bffNether|r|cffe8e4f0Bot|r")

local closeBtn = TextButton(header, 22, 20, "X", function() frame:Hide() end, COL.red)
closeBtn:SetPoint("RIGHT", -6, 0)
local scaleDown = TextButton(header, 20, 20, "-", function()
  local s = math.max(0.6, frame:GetScale() - 0.1); frame:SetScale(s); NetherbotDB.scale = s
end, COL.accent)
scaleDown:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)
local scaleUp = TextButton(header, 20, 20, "+", function()
  local s = math.min(2.0, frame:GetScale() + 0.1); frame:SetScale(s); NetherbotDB.scale = s
end, COL.accent)
scaleUp:SetPoint("RIGHT", scaleDown, "LEFT", -2, 0)

local TAB_NAMES = { "Control", "Behavior", "Manage", "Create" }
local GM_TABS = { [3] = true, [4] = true }   -- Manage + Create are GM-only
local tabs, panels = {}, {}
local SetActiveDistance   -- fwd decl
local LayoutTabs          -- fwd decl
local UpdateGMToggle      -- fwd decl
local function SelectTab(idx)
  if GM_TABS[idx] and not NetherbotDB.gmMode then idx = 1 end
  for i, p in ipairs(panels) do if i == idx then p:Show() else p:Hide() end end
  for i, t in ipairs(tabs) do
    if i == idx then
      t:SetBackdropColor(unpack(COL.accentDim)); t:SetBackdropBorderColor(unpack(COL.accent))
      t.label:SetTextColor(unpack(COL.text))
    else
      t:SetBackdropColor(unpack(COL.btn)); t:SetBackdropBorderColor(unpack(COL.btnBorder))
      t.label:SetTextColor(unpack(COL.textMuted))
    end
  end
  NetherbotDB.tab = idx
end

local tabW = 78
for i, name in ipairs(TAB_NAMES) do
  local t = TextButton(frame, tabW, 22, i18n(name), function() SelectTab(i) end, COL.textMuted)
  t:SetScript("OnLeave", function(self)
    if NetherbotDB.tab == i then self:SetBackdropColor(unpack(COL.accentDim)); self:SetBackdropBorderColor(unpack(COL.accent))
    else self:SetBackdropColor(unpack(COL.btn)); self:SetBackdropBorderColor(unpack(COL.btnBorder)) end
  end)
  tabs[i] = t
end

-- show/hide + relayout tabs depending on GM Mode
LayoutTabs = function()
  local prev
  for i, t in ipairs(tabs) do
    if (not GM_TABS[i]) or NetherbotDB.gmMode then
      t:Show(); t:ClearAllPoints()
      if not prev then t:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 2, -4)
      else t:SetPoint("LEFT", prev, "RIGHT", 1, 0) end
      prev = t
    else
      t:Hide()
    end
  end
end

-- GM Mode toggle in the header (reveals the admin tabs)
local gmToggle = TextButton(header, 42, 20, "GM", nil, COL.textMuted)
gmToggle:SetPoint("RIGHT", scaleUp, "LEFT", -8, 0)
UpdateGMToggle = function()
  if NetherbotDB.gmMode then
    gmToggle.label:SetText("GM |cff7bff7bON|r"); gmToggle:SetBackdropBorderColor(unpack(COL.accent))
  else
    gmToggle.label:SetText("GM"); gmToggle:SetBackdropBorderColor(unpack(COL.btnBorder))
  end
end
gmToggle:SetScript("OnLeave", function(self)
  self:SetBackdropColor(unpack(COL.btn))
  if NetherbotDB.gmMode then self:SetBackdropBorderColor(unpack(COL.accent))
  else self:SetBackdropBorderColor(unpack(COL.btnBorder)) end
end)
gmToggle:SetScript("OnClick", function()
  NetherbotDB.gmMode = not NetherbotDB.gmMode
  UpdateGMToggle(); LayoutTabs()
  if not NetherbotDB.gmMode and GM_TABS[NetherbotDB.tab] then SelectTab(1) end
end)
Tip(gmToggle, i18n("GM Mode"), "Reveals the admin tabs (Manage, Create). Those commands need GM access on your account.")

local function MakePanel()
  local p = CreateFrame("Frame", nil, frame)
  p:SetPoint("TOPLEFT", tabs[1], "BOTTOMLEFT", -2, -4)
  p:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
  ApplyBackdrop(p, COL.body, COL.btnBorder)
  return p
end
for i = 1, #TAB_NAMES do panels[i] = MakePanel() end
local pControl, pBehavior, pManage, pCreate = panels[1], panels[2], panels[3], panels[4]

-- ============================================================================
--  TAB 1: CONTROL
-- ============================================================================
local function rowOfIcons(parent, anchor, yoff, defs)
  local size, gap, startx, prev = 52, 8, 12, nil
  for idx, d in ipairs(defs) do
    local b = IconButton(parent, size, d.icon, i18n(d.cap), d.tip, d.fn)
    if idx == 1 then b:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", startx, yoff)
    else b:SetPoint("LEFT", prev, "RIGHT", gap, 0) end
    prev = b
  end
  return prev
end

local cmdLabel = SectionLabel(pControl, i18n("Commands"))
cmdLabel:SetPoint("TOPLEFT", 12, -10)
rowOfIcons(pControl, cmdLabel, -6, {
  { icon = ICON.."Ability_Tracking",        cap = "Follow", tip = "All bots follow you.",                      fn = function() Say(".npcbot command follow") end },
  { icon = ICON.."Spell_Nature_TimeStop",   cap = "Stand",  tip = "Bots hold their current position.",         fn = function() Say(".npcbot command standstill") end },
  { icon = ICON.."Spell_ChargeNegative",    cap = "Stop",   tip = "Full stop - freeze and ignore everything.", fn = function() Say(".npcbot command stopfully") end },
  { icon = ICON.."Spell_Nature_Sleep",      cap = "Slack",  tip = "Follow only - do nothing but follow.",      fn = function() Say(".npcbot command follow only") end },
})

local visLabel = SectionLabel(pControl, i18n("Visibility"))
visLabel:SetPoint("TOPLEFT", cmdLabel, "BOTTOMLEFT", 0, -66)
rowOfIcons(pControl, visLabel, -6, {
  { icon = ICON.."Ability_Hunter_BeastCall", cap = "Unhide", tip = "Bring bots back into the world.",     fn = function() Say(".npcbot unhide") end },
  { icon = ICON.."Ability_Stealth",          cap = "Hide",   tip = "Send bots out of the world.",         fn = function() Say(".npcbot hide") end },
  { icon = ICON.."Spell_Arcane_Blink",       cap = "Recall", tip = "Teleport all bots to you.",           fn = function() Say(".npcbot recall teleport") end },
  { icon = ICON.."INV_Misc_Key_14",          cap = "Unbind", tip = "Temporarily release selected bot.",   fn = function() Say(".npcbot command unbind") end },
})

local distLabel = SectionLabel(pControl, i18n("Follow Distance"))
distLabel:SetPoint("TOPLEFT", visLabel, "BOTTOMLEFT", 0, -66)
local distButtons = {}
SetActiveDistance = function(which)
  for k, b in pairs(distButtons) do
    if k == which then b:SetBackdropColor(unpack(COL.accentDim)); b:SetBackdropBorderColor(unpack(COL.accent)); b.label:SetTextColor(unpack(COL.text))
    else b:SetBackdropColor(unpack(COL.btn)); b:SetBackdropBorderColor(unpack(COL.btnBorder)); b.label:SetTextColor(unpack(COL.textMuted)) end
  end
  NetherbotDB.distance = which
end
local distDefs = { { "low", "Low", 30 }, { "med", "Medium", 50 }, { "high", "High", 85 } }
local dprev
for idx, d in ipairs(distDefs) do
  local b = TextButton(pControl, 96, 24, i18n(d[2]), nil, COL.textMuted)
  if idx == 1 then b:SetPoint("TOPLEFT", distLabel, "BOTTOMLEFT", 0, -6)
  else b:SetPoint("LEFT", dprev, "RIGHT", 6, 0) end
  b:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(COL.accent)) end)
  b:SetScript("OnLeave", function(self)
    if NetherbotDB.distance == d[1] then self:SetBackdropBorderColor(unpack(COL.accent))
    else self:SetBackdropBorderColor(unpack(COL.btnBorder)) end
  end)
  b:SetScript("OnClick", function() Say(".npcbot distance " .. d[3]); SetActiveDistance(d[1]) end)
  distButtons[d[1]] = b; dprev = b
end

local raidButton = TextButton(pControl, 148, 28, i18n("Raid Frames"), nil, COL.text)
raidButton:SetPoint("TOPLEFT", distLabel, "BOTTOMLEFT", 0, -44)
local reviveButton = TextButton(pControl, 148, 28, i18n("Revive Bots"), function() Say(".npcbot revive") end, COL.green)
reviveButton:SetPoint("LEFT", raidButton, "RIGHT", 6, 0)

-- ============================================================================
--  TAB 2: BEHAVIOR
-- ============================================================================
local behLabel = SectionLabel(pBehavior, i18n("Toggles"))
behLabel:SetPoint("TOPLEFT", 12, -10)
local toggleDefs = {
  { "Walk",          ".npcbot command walk",       "Toggle walk/run movement." },
  { "No Gossip",     ".npcbot command nogossip",   "Toggle the right-click gossip menu." },
  { "No Cast",       ".npcbot command nocast",     "Toggle ALL spellcasting." },
  { "No Long",       ".npcbot command nolongcast", "Toggle spells with a cast time." },
  { "Rebind",        ".npcbot command rebind",     "Call unbound bots back." },
  { "Recall Spawns", ".npcbot recall spawns",      "Send inactive bots to spawn points." },
}
local brow
for idx, d in ipairs(toggleDefs) do
  local b = TextButton(pBehavior, 148, 26, i18n(d[1]), function() Say(d[2]) end, COL.text)
  Tip(b, i18n(d[1]), d[3])
  local col = (idx - 1) % 2
  if col == 0 then
    if idx == 1 then b:SetPoint("TOPLEFT", behLabel, "BOTTOMLEFT", 0, -6)
    else b:SetPoint("TOPLEFT", brow, "BOTTOMLEFT", 0, -6) end
    brow = b
  else
    b:SetPoint("LEFT", brow, "RIGHT", 6, 0)
  end
end

local atkLabel = SectionLabel(pBehavior, i18n("Attack Distance"))
atkLabel:SetPoint("TOPLEFT", brow, "BOTTOMLEFT", 0, -14)
local atkShort = TextButton(pBehavior, 96, 24, i18n("Short"), function() Say(".npcbot distance attack short") end)
atkShort:SetPoint("TOPLEFT", atkLabel, "BOTTOMLEFT", 0, -6)
local atkLong = TextButton(pBehavior, 96, 24, i18n("Long"), function() Say(".npcbot distance attack long") end)
atkLong:SetPoint("LEFT", atkShort, "RIGHT", 6, 0)
local atkInput = EditBox(pBehavior, 48, 24)
atkInput:SetPoint("LEFT", atkLong, "RIGHT", 6, 0)
atkInput:SetScript("OnEnterPressed", function(self)
  local v = self:GetText(); if v and v ~= "" then Say(".npcbot distance attack " .. v) end; self:ClearFocus()
end)
Tip(atkInput, i18n("Exact"), "Type a number (0-50) and press Enter.")

local trbLabel = SectionLabel(pBehavior, i18n("Troubleshooting"))
trbLabel:SetPoint("TOPLEFT", atkLabel, "BOTTOMLEFT", 0, -42)
local bEject = TextButton(pBehavior, 96, 26, i18n("Eject"), function() Say(".npcbot vehicle eject") end)
bEject:SetPoint("TOPLEFT", trbLabel, "BOTTOMLEFT", 0, -6)
Tip(bEject, i18n("Eject"), "Kick bots out of vehicles.")
local bKill = TextButton(pBehavior, 96, 26, i18n("Kill"), function()
  Confirm("NB_KILL", i18n("Force selected bot(s) to die?"), function() Say(".npcbot kill") end)
end, COL.red)
bKill:SetPoint("LEFT", bEject, "RIGHT", 6, 0)
Tip(bKill, i18n("Kill"), "Force-kill bots (fixes stuck bots).")
local bSuicide = TextButton(pBehavior, 96, 26, i18n("Suicide"), function()
  Confirm("NB_SUICIDE", i18n("Force ALL your bots to die?"), function() Say(".npcbot suicide") end)
end, COL.red)
bSuicide:SetPoint("LEFT", bKill, "RIGHT", 6, 0)
Tip(bSuicide, i18n("Suicide"), "Force-kill ALL your bots.")

-- ============================================================================
--  TAB 3: MANAGE
-- ============================================================================
local mgLabel = SectionLabel(pManage, i18n("Bot Management"))
mgLabel:SetPoint("TOPLEFT", 12, -10)
local function ManageBtn(label, w, onClick, color) return TextButton(pManage, w, 24, i18n(label), onClick, color) end

local bAdd = ManageBtn("Add", 96, function()
  PromptID("NB_ADD", function() Say(".npcbot add") end, function(id) Say(".npcbot add " .. id) end)
end, COL.green)
bAdd:SetPoint("TOPLEFT", mgLabel, "BOTTOMLEFT", 0, -6)
local bRemove = ManageBtn("Remove", 96, function()
  PromptID("NB_REMOVE", function() Say(".npcbot remove") end, function(id) Say(".npcbot remove " .. id) end)
end, COL.red)
bRemove:SetPoint("LEFT", bAdd, "RIGHT", 6, 0)
local bMove = ManageBtn("Move", 96, function() Say(".npcbot move") end)
bMove:SetPoint("LEFT", bRemove, "RIGHT", 6, 0)

local bRecall = ManageBtn("Recall", 96, function() Say(".npcbot recall") end)
bRecall:SetPoint("TOPLEFT", bAdd, "BOTTOMLEFT", 0, -6)
local bInfo = ManageBtn("Bot-Info", 96, function() Say(".npcbot info") end)
bInfo:SetPoint("LEFT", bRecall, "RIGHT", 6, 0)
local bDelete = ManageBtn("Delete", 96, function()
  Confirm("NB_DELETE_C", i18n("Are you sure you want to delete?"), function()
    PromptID("NB_DELETE", function() Say(".npcbot delete") end, function(id) Say(".npcbot delete " .. id) end)
  end)
end, COL.red)
bDelete:SetPoint("LEFT", bInfo, "RIGHT", 6, 0)

local bLookup = ManageBtn("Lookup / Spawn", 148, nil, COL.accent)
bLookup:SetPoint("TOPLEFT", bRecall, "BOTTOMLEFT", 0, -6)
local bListSpawned = ManageBtn("List Spawned", 70, function() Say(".npcbot list spawned") end)
bListSpawned:SetPoint("LEFT", bLookup, "RIGHT", 6, 0)
local bListFree = ManageBtn("Free", 72, function() Say(".npcbot list spawned free") end)
bListFree:SetPoint("LEFT", bListSpawned, "RIGHT", 6, 0)

local facLabel = SectionLabel(pManage, i18n("Set Faction (selected bot)"))
facLabel:SetPoint("TOPLEFT", bLookup, "BOTTOMLEFT", 0, -16)
local facDefs = { { "Alliance", "a", COL.accent }, { "Horde", "h", COL.red }, { "Hostile", "m", COL.red }, { "Friendly", "f", COL.green } }
local fprev
for idx, d in ipairs(facDefs) do
  local b = TextButton(pManage, 70, 24, i18n(d[1]), function() Say(".npcbot set faction " .. d[2]) end, d[3])
  if idx == 1 then b:SetPoint("TOPLEFT", facLabel, "BOTTOMLEFT", 0, -6)
  else b:SetPoint("LEFT", fprev, "RIGHT", 6, 0) end
  fprev = b
end

local specLabel = SectionLabel(pManage, i18n("Set Spec (1-30, selected bot)"))
specLabel:SetPoint("TOPLEFT", facLabel, "BOTTOMLEFT", 0, -42)
local specInput = EditBox(pManage, 60, 24)
specInput:SetPoint("TOPLEFT", specLabel, "BOTTOMLEFT", 0, -6)
specInput:SetNumeric(true)
local specGo = TextButton(pManage, 90, 24, i18n("Apply Spec"), function()
  local v = specInput:GetText(); if v and v ~= "" then Say(".npcbot set spec " .. v); specInput:SetText(""); specInput:ClearFocus() end
end, COL.accent)
specGo:SetPoint("LEFT", specInput, "RIGHT", 6, 0)

local reviveSpell = CreateFrame("Button", "NetherbotReviveSpell", pManage, "SecureActionButtonTemplate")
reviveSpell:SetSize(30, 30); reviveSpell:SetPoint("BOTTOMRIGHT", -10, 10)
ApplyBackdrop(reviveSpell, COL.btn, COL.btnBorder)
local reviveIcon = reviveSpell:CreateTexture(nil, "ARTWORK")
reviveIcon:SetPoint("TOPLEFT", 3, -3); reviveIcon:SetPoint("BOTTOMRIGHT", -3, -3)
reviveIcon:SetTexture(select(3, GetSpellInfo(7328))); reviveIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
reviveSpell:SetAttribute("type", "spell"); reviveSpell:SetAttribute("spell", 7328)
reviveSpell:SetScript("OnEnter", function(self)
  self:SetBackdropBorderColor(unpack(COL.accent))
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(i18n("Cast Redemption"), COL.accent[1], COL.accent[2], COL.accent[3]); GameTooltip:Show()
end)
reviveSpell:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(COL.btnBorder)); GameTooltip:Hide() end)

-- ============================================================================
--  TAB 4: CREATE  (.npcbot createnew builder)
-- ============================================================================
local crLabel = SectionLabel(pCreate, i18n("Create Custom Bot"))
crLabel:SetPoint("TOPLEFT", 12, -10)
local crHint = MakeFS(pCreate, 9, COL.textMuted)
crHint:SetPoint("TOPLEFT", crLabel, "BOTTOMLEFT", 0, -4)
crHint:SetWidth(300); crHint:SetJustifyH("LEFT")
crHint:SetText(i18n("Name + Class required. Special classes (12-19) ignore the rest. Use Ranges for valid appearance values."))

local nameLbl = MakeFS(pCreate, 9, COL.textMuted); nameLbl:SetText(i18n("Name"))
nameLbl:SetPoint("TOPLEFT", crHint, "BOTTOMLEFT", 0, -12)
local nameBox = EditBox(pCreate, 200, 22)
nameBox:SetPoint("TOPLEFT", nameLbl, "BOTTOMLEFT", 0, -3)

local gridDefs = {
  { "Class", "class" }, { "Race", "race" }, { "Gender", "gender" },
  { "Skin", "skin" }, { "Face", "face" }, { "Hair", "hairstyle" },
  { "Color", "haircolor" }, { "Features", "features" }, { "Sound", "sound" },
}
local fieldBoxes = {}
local colW, gridGapX, gridGapY = 90, 6, 8
for idx, d in ipairs(gridDefs) do
  local lbl = MakeFS(pCreate, 9, COL.textMuted); lbl:SetText(i18n(d[1]))
  local box = EditBox(pCreate, colW, 22); box:SetNumeric(true)
  local col = (idx - 1) % 3
  local rowi = math.floor((idx - 1) / 3)
  lbl:SetPoint("TOPLEFT", nameBox, "BOTTOMLEFT", col * (colW + gridGapX), -10 - rowi * (22 + 14 + gridGapY))
  box:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -3)
  fieldBoxes[d[2]] = box
end

local rangesBtn = TextButton(pCreate, 90, 26, i18n("Ranges"), function() Say(".npcbot createnew ranges") end, COL.accent)
rangesBtn:SetPoint("TOPLEFT", fieldBoxes["haircolor"], "BOTTOMLEFT", 0, -16)
Tip(rangesBtn, i18n("Ranges"), "Print valid appearance values for all races to chat.")

local createBtn = TextButton(pCreate, 196, 26, i18n("Create Bot"), function()
  local name = nameBox:GetText() or ""
  name = name:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", "_")
  local class = fieldBoxes["class"]:GetText() or ""
  if name == "" or class == "" then
    print("|cffae8bffNetherBot:|r " .. i18n("Name and Class are required."))
    return
  end
  local order = { "class", "race", "gender", "skin", "face", "hairstyle", "haircolor", "features", "sound" }
  local cmd = ".npcbot createnew " .. name
  for _, key in ipairs(order) do
    local v = fieldBoxes[key]:GetText() or ""
    if v == "" then break end
    cmd = cmd .. " " .. v
  end
  Say(cmd)
  print("|cffae8bffNetherBot:|r " .. cmd)
end, COL.green)
createBtn:SetPoint("LEFT", rangesBtn, "RIGHT", 6, 0)

-- ----------------------------------------------------------------------------
--  LOOKUP / SPAWN POPUP
-- ----------------------------------------------------------------------------
local lookupFrame = CreateFrame("Frame", "NetherbotLookupFrame", UIParent)
lookupFrame:SetSize(220, 430); lookupFrame:SetPoint("CENTER", 260, 0)
ApplyBackdrop(lookupFrame, COL.panelBg, COL.panelBorder)
lookupFrame:SetMovable(true); lookupFrame:EnableMouse(true); lookupFrame:RegisterForDrag("LeftButton")
lookupFrame:SetScript("OnDragStart", lookupFrame.StartMoving)
lookupFrame:SetScript("OnDragStop", lookupFrame.StopMovingOrSizing)
lookupFrame:Hide()
local lkHeader = CreateFrame("Frame", nil, lookupFrame)
lkHeader:SetPoint("TOPLEFT", 1, -1); lkHeader:SetPoint("TOPRIGHT", -1, -1); lkHeader:SetHeight(26)
ApplyBackdrop(lkHeader, COL.header, COL.header)
local lkTitle = MakeFS(lkHeader, 12, COL.accent); lkTitle:SetPoint("LEFT", 10, 0); lkTitle:SetText(i18n("Lookup Class"))
local lkClose = TextButton(lkHeader, 22, 20, "X", function() lookupFrame:Hide() end, COL.red)
lkClose:SetPoint("RIGHT", -6, 0)
bLookup:SetScript("OnClick", function() if lookupFrame:IsShown() then lookupFrame:Hide() else lookupFrame:Show() end end)

local classTable = {
  { "Warrior", 1 }, { "Paladin", 2 }, { "Hunter", 3 }, { "Rogue", 4 }, { "Priest", 5 },
  { "Death Knight", 6 }, { "Shaman", 7 }, { "Mage", 8 }, { "Warlock", 9 }, { "Druid", 11 },
  { "Blademaster", 12 }, { "Sphynx", 13 }, { "Archmage", 14 }, { "Dreadlord", 15 },
  { "Spellbreaker", 16 }, { "DarkRanger", 17 }, { "Necromancer", 18 }, { "SeaWitch", 19 },
}
local lkScroll = CreateFrame("ScrollFrame", "NetherbotLookupScroll", lookupFrame, "UIPanelScrollFrameTemplate")
lkScroll:SetPoint("TOPLEFT", lkHeader, "BOTTOMLEFT", 6, -6)
lkScroll:SetPoint("BOTTOMRIGHT", lookupFrame, "BOTTOMRIGHT", -28, 78)
local lkList = CreateFrame("Frame", nil, lkScroll); lkList:SetSize(170, #classTable * 26); lkScroll:SetScrollChild(lkList)
local cprev
for idx, c in ipairs(classTable) do
  local b = TextButton(lkList, 168, 22, i18n(c[1]) .. "  (" .. c[2] .. ")", function() Say(".npcbot lookup " .. c[2]) end)
  if idx == 1 then b:SetPoint("TOPLEFT", 2, -2) else b:SetPoint("TOPLEFT", cprev, "BOTTOMLEFT", 0, -4) end
  cprev = b
end
local spawnLabel = SectionLabel(lookupFrame, i18n("Spawn Bot by ID"))
spawnLabel:SetPoint("BOTTOMLEFT", 12, 52)
local spawnInput = EditBox(lookupFrame, 95, 24); spawnInput:SetPoint("BOTTOMLEFT", 14, 14); spawnInput:SetNumeric(true)
local spawnGo = TextButton(lookupFrame, 80, 24, i18n("Spawn"), function()
  local id = spawnInput:GetText()
  if id and id ~= "" then Say(".npcbot spawn " .. id); spawnInput:SetText(""); spawnInput:ClearFocus()
  else print("|cffae8bffNetherBot:|r " .. i18n("Please enter an ID.")) end
end, COL.green)
spawnGo:SetPoint("BOTTOMRIGHT", -14, 14)

-- ----------------------------------------------------------------------------
--  RAID FRAMES
-- ----------------------------------------------------------------------------
local TeamFrame = CreateFrame("Frame", "NetherbotTeamFrame", UIParent)
TeamFrame:SetSize(350, 600); TeamFrame:SetPoint("CENTER")
TeamFrame:SetMovable(true); TeamFrame:EnableMouse(true); TeamFrame:RegisterForDrag("LeftButton")
TeamFrame:SetScript("OnDragStart", TeamFrame.StartMoving); TeamFrame:SetScript("OnDragStop", TeamFrame.StopMovingOrSizing)
TeamFrame:Hide()
local memberFrames, healthBars, manaBars, nameTexts, groupFrames = {}, {}, {}, {}, {}
local function InitRaid()
  if not RAID_CLASS_COLORS then return end
  for i = 1, #memberFrames do memberFrames[i]:Hide() end
  memberFrames, healthBars, manaBars, nameTexts = {}, {}, {}, {}
  local num = GetNumRaidMembers()
  for i = 1, num do
    local group = math.ceil(i / 5)
    local position = i - ((group - 1) * 5)
    local column = (group - 1) % 2
    local row = math.floor((group - 1) / 2)
    if position == 1 then
      local gf = CreateFrame("Frame", nil, TeamFrame); gf:SetSize(150, 20)
      gf:SetPoint("TOPLEFT", TeamFrame, "TOP", 175 * (column - 1) + 12, 6 - row * 230)
      local gt = MakeFS(gf, 11, COL.accent); gt:SetPoint("LEFT"); gt:SetText(i18n("Group") .. " " .. group)
      groupFrames[group] = gf
    end
    local mf = CreateFrame("Button", nil, TeamFrame, "SecureUnitButtonTemplate"); mf:SetSize(150, 40)
    mf:SetPoint("TOPLEFT", TeamFrame, "TOPLEFT", 10 + 175 * column, -10 - ((row * 230) + (position - 1) * 44))
    mf:SetAttribute("unit", "raid" .. i); mf:RegisterForClicks("AnyUp"); SecureUnitButton_OnLoad(mf, "raid" .. i)
    ApplyBackdrop(mf, COL.body, COL.btnBorder)
    local _, charClass = UnitClass("raid" .. i)
    local cc = RAID_CLASS_COLORS[charClass] or { r = 1, g = 1, b = 1 }
    mf:SetBackdropBorderColor(cc.r, cc.g, cc.b, 0.85)
    local nameText = MakeFS(mf, 11, COL.text); nameText:SetPoint("TOPLEFT", 6, -4)
    nameText:SetText((UnitName("raid" .. i))); nameText:SetTextColor(cc.r, cc.g, cc.b)
    local hb = CreateFrame("StatusBar", nil, mf); hb:SetStatusBarTexture(SOLID); hb:SetStatusBarColor(unpack(COL.green))
    hb:SetPoint("TOPLEFT", 6, -18); hb:SetSize(138, 9)
    hb:SetMinMaxValues(0, UnitHealthMax("raid" .. i)); hb:SetValue(UnitHealth("raid" .. i))
    local hbbg = hb:CreateTexture(nil, "BACKGROUND"); hbbg:SetTexture(SOLID); hbbg:SetVertexColor(0.1, 0.1, 0.12, 0.9); hbbg:SetAllPoints()
    local mb = CreateFrame("StatusBar", nil, mf); mb:SetStatusBarTexture(SOLID); mb:SetStatusBarColor(0.30, 0.45, 0.95)
    mb:SetPoint("TOPLEFT", 6, -29); mb:SetSize(138, 6)
    mb:SetMinMaxValues(0, UnitPowerMax("raid" .. i)); mb:SetValue(UnitPower("raid" .. i))
    local mbbg = mb:CreateTexture(nil, "BACKGROUND"); mbbg:SetTexture(SOLID); mbbg:SetVertexColor(0.1, 0.1, 0.12, 0.9); mbbg:SetAllPoints()
    memberFrames[i] = mf; healthBars[i] = hb; manaBars[i] = mb; nameTexts[i] = nameText
  end
end
local function UpdateBars(_, _, unit)
  for i = 1, #healthBars do
    if unit == "raid" .. i then
      healthBars[i]:SetMinMaxValues(0, UnitHealthMax(unit)); healthBars[i]:SetValue(UnitHealth(unit))
      manaBars[i]:SetMinMaxValues(0, UnitPowerMax(unit)); manaBars[i]:SetValue(UnitPower(unit))
    end
  end
end
TeamFrame:RegisterEvent("UNIT_HEALTH"); TeamFrame:RegisterEvent("UNIT_POWER_UPDATE")
TeamFrame:RegisterEvent("RAID_ROSTER_UPDATE"); TeamFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
TeamFrame:SetScript("OnEvent", function(self, event, ...)
  if event == "PLAYER_ENTERING_WORLD" or event == "RAID_ROSTER_UPDATE" then InitRaid() else UpdateBars(self, event, ...) end
end)
raidButton:SetScript("OnClick", function() if TeamFrame:IsShown() then TeamFrame:Hide() else InitRaid(); TeamFrame:Show() end end)

-- ----------------------------------------------------------------------------
--  LOAD + SLASH
-- ----------------------------------------------------------------------------
local loader = CreateFrame("Frame"); loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, _, name)
  if name == "NetherBot" then
    if NetherbotDB.scale then frame:SetScale(NetherbotDB.scale) end
    if NetherbotDB.point then
      frame:ClearAllPoints()
      frame:SetPoint(NetherbotDB.point.p, UIParent, NetherbotDB.point.rp, NetherbotDB.point.x, NetherbotDB.point.y)
    else
      frame:SetPoint("CENTER")
    end
    if NetherbotDB.distance then SetActiveDistance(NetherbotDB.distance) end
    UpdateGMToggle(); LayoutTabs()
    SelectTab(NetherbotDB.tab or 1)
  end
end)

SLASH_NETHERBOT1 = "/netherbot"
SLASH_NETHERBOT2 = "/nb"
SlashCmdList["NETHERBOT"] = function(msg)
  msg = string.lower(msg or "")
  if msg == "hide" then frame:Hide(); lookupFrame:Hide(); TeamFrame:Hide()
  else frame:Show() end
end

UpdateGMToggle()
LayoutTabs()
SelectTab(NetherbotDB.tab or 1)
