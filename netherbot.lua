-- =============================================================================
--  NetherBot  -  NPCBot control panel for TrinityCore 3.3.5
--  Modern dark UI redesign (v2.0).  Original addon by NetherstormX.
--  UI rework & bugfixes for Iceymidgit.
--
--  Fixes vs the original:
--    * the recall-teleport command had a misspelled "recall" -> corrected
--    * spawn used the GUILD channel -> now SAY (works without a guild)
--    * duplicate global frame names (NetherbotShow3Button x3) removed
--    * window position is now saved between sessions (was scale only)
-- =============================================================================

NetherBot.InitLocale()
local i18n = NetherBot.I18n

-- Saved variables table (declared in the .toc as NetherbotDB)
NetherbotDB = NetherbotDB or {}

-- ----------------------------------------------------------------------------
--  THEME
-- ----------------------------------------------------------------------------
local FONT = "Fonts\\FRIZQT__.TTF"
local COL = {
  panelBg     = { 0.075, 0.067, 0.110, 0.96 },  -- near-black charcoal
  panelBorder = { 0.42,  0.30,  0.78,  1.00 },  -- violet
  header      = { 0.13,  0.10,  0.20,  1.00 },
  accent      = { 0.62,  0.48,  1.00,  1.00 },  -- bright nether violet
  accentDim   = { 0.42,  0.32,  0.66,  1.00 },
  btn         = { 0.16,  0.14,  0.22,  1.00 },
  btnHover    = { 0.26,  0.21,  0.38,  1.00 },
  btnBorder   = { 0.30,  0.26,  0.42,  1.00 },
  text        = { 0.91,  0.89,  0.96,  1.00 },
  textMuted   = { 0.55,  0.52,  0.62,  1.00 },
  green       = { 0.46,  0.82,  0.45,  1.00 },
  red         = { 0.90,  0.38,  0.32,  1.00 },
  barBg       = { 0.10,  0.09,  0.14,  0.90 },
}

local SOLID = "Interface\\Buttons\\WHITE8X8"

-- ----------------------------------------------------------------------------
--  HELPERS
-- ----------------------------------------------------------------------------
local function ApplyBackdrop(frame, bg, border, edge)
  frame:SetBackdrop({
    bgFile = SOLID, edgeFile = SOLID, edgeSize = edge or 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
  })
  frame:SetBackdropColor(unpack(bg))
  frame:SetBackdropBorderColor(unpack(border))
end

local function MakeFS(parent, size, color, flags)
  local fs = parent:CreateFontString(nil, "OVERLAY")
  fs:SetFont(FONT, size or 12, flags or "")
  fs:SetTextColor(unpack(color or COL.text))
  return fs
end

-- Section label (small muted caps-style heading)
local function SectionLabel(parent, text)
  local fs = MakeFS(parent, 10, COL.textMuted, "")
  fs:SetText(string.upper(text))
  return fs
end

-- Tooltip helper
local function AttachTooltip(frame, title, body)
  frame:SetScript("OnEnter", function(self)
    if frame.OnHoverIn then frame.OnHoverIn(self) end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(title, COL.accent[1], COL.accent[2], COL.accent[3])
    if body then GameTooltip:AddLine(body, 0.8, 0.8, 0.85, true) end
    GameTooltip:Show()
  end)
  frame:SetScript("OnLeave", function(self)
    if frame.OnHoverOut then frame.OnHoverOut(self) end
    GameTooltip:Hide()
  end)
end

-- Flat text button with hover glow
local function TextButton(parent, w, h, label, onClick, textColor)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(w, h)
  ApplyBackdrop(b, COL.btn, COL.btnBorder)
  local fs = MakeFS(b, 12, textColor or COL.text)
  fs:SetPoint("CENTER")
  fs:SetText(label)
  b.label = fs
  b:SetScript("OnEnter", function(self)
    self:SetBackdropColor(unpack(COL.btnHover))
    self:SetBackdropBorderColor(unpack(COL.accent))
  end)
  b:SetScript("OnLeave", function(self)
    self:SetBackdropColor(unpack(COL.btn))
    self:SetBackdropBorderColor(unpack(COL.btnBorder))
  end)
  if onClick then b:SetScript("OnClick", onClick) end
  return b
end

-- Icon button (framed icon + caption underneath + tooltip + hover)
local function IconButton(parent, size, icon, caption, tip, onClick)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(size, size)
  ApplyBackdrop(b, COL.btn, COL.btnBorder)

  local tex = b:CreateTexture(nil, "ARTWORK")
  tex:SetPoint("TOPLEFT", 3, -3)
  tex:SetPoint("BOTTOMRIGHT", -3, -3)
  tex:SetTexture(icon)
  tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)  -- trim default icon border
  b.icon = tex

  local cap = MakeFS(b, 9, COL.textMuted)
  cap:SetPoint("TOP", b, "BOTTOM", 0, -2)
  cap:SetText(caption)
  b.caption = cap

  b.OnHoverIn = function(self)
    self:SetBackdropBorderColor(unpack(COL.accent))
    cap:SetTextColor(unpack(COL.accent))
  end
  b.OnHoverOut = function(self)
    self:SetBackdropBorderColor(unpack(COL.btnBorder))
    cap:SetTextColor(unpack(COL.textMuted))
  end
  AttachTooltip(b, caption, tip)
  if onClick then b:SetScript("OnClick", onClick) end
  return b
end

local function Say(cmd)
  SendChatMessage(cmd, "SAY")
end

-- ----------------------------------------------------------------------------
--  MAIN FRAME
-- ----------------------------------------------------------------------------
local frame = CreateFrame("Frame", "NetherbotFrame", UIParent)
frame:SetSize(290, 286)
frame:SetClampedToScreen(true)
ApplyBackdrop(frame, COL.panelBg, COL.panelBorder)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local p, _, rp, x, y = self:GetPoint()
  NetherbotDB.point = { p = p, rp = rp, x = x, y = y }
end)

-- Header bar
local header = CreateFrame("Frame", nil, frame)
header:SetPoint("TOPLEFT", 1, -1)
header:SetPoint("TOPRIGHT", -1, -1)
header:SetHeight(30)
ApplyBackdrop(header, COL.header, COL.header)

local accentBar = header:CreateTexture(nil, "OVERLAY")
accentBar:SetTexture(SOLID)
accentBar:SetVertexColor(unpack(COL.accent))
accentBar:SetPoint("BOTTOMLEFT", 0, 0)
accentBar:SetPoint("BOTTOMRIGHT", 0, 0)
accentBar:SetHeight(2)

local title = MakeFS(header, 14, COL.text, "")
title:SetPoint("LEFT", header, "LEFT", 10, 0)
title:SetText("|cffae8bffNether|r|cffe8e4f0Bot|r")

-- Close button
local closeBtn = TextButton(header, 22, 20, "X", function() frame:Hide() end, COL.red)
closeBtn:SetPoint("RIGHT", header, "RIGHT", -6, 0)

-- Scale -/+ buttons
local scaleDown = TextButton(header, 20, 20, "-", function()
  local s = math.max(0.5, frame:GetScale() - 0.1)
  frame:SetScale(s); NetherbotDB.scale = s
end, COL.accent)
scaleDown:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)

local scaleUp = TextButton(header, 20, 20, "+", function()
  local s = math.min(2.0, frame:GetScale() + 0.1)
  frame:SetScale(s); NetherbotDB.scale = s
end, COL.accent)
scaleUp:SetPoint("RIGHT", scaleDown, "LEFT", -2, 0)

-- ---- COMMANDS section ----
local cmdLabel = SectionLabel(frame, i18n("Commands"))
cmdLabel:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 12, -10)

local ICON = "Interface\\Icons\\"
local function row4(anchorFrame, yoff, defs)
  local size = 50
  local gap = 8
  local startx = 14
  local prev
  for idx, d in ipairs(defs) do
    local b = IconButton(frame, size, d.icon, i18n(d.cap), d.tip, d.fn)
    if idx == 1 then
      b:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", startx, yoff)
    else
      b:SetPoint("LEFT", prev, "RIGHT", gap, 0)
    end
    prev = b
  end
end

row4(cmdLabel, -6, {
  { icon = ICON.."Ability_Tracking",       cap = "Follow", tip = "All bots follow you.",                      fn = function() Say(".npcbot command follow") end },
  { icon = ICON.."Spell_Nature_TimeStop",  cap = "Stand",  tip = "Bots hold their current position.",         fn = function() Say(".npcbot command standstill") end },
  { icon = ICON.."Spell_ChargeNegative",   cap = "Stop",   tip = "Full stop - bots freeze and ignore all.",   fn = function() Say(".npcbot command stopfully") end },
  { icon = ICON.."Spell_Nature_Sleep",     cap = "Slack",  tip = "Follow only - bots do nothing but follow.", fn = function() Say(".npcbot command follow only") end },
})

-- ---- VISIBILITY section ----
local visLabel = SectionLabel(frame, i18n("Visibility"))
visLabel:SetPoint("TOPLEFT", cmdLabel, "BOTTOMLEFT", 0, -64)

row4(visLabel, -6, {
  { icon = ICON.."Ability_Hunter_BeastCall", cap = "Unhide", tip = "Bring your bots back into the world.",       fn = function() Say(".npcbot unhide") end },
  { icon = ICON.."Ability_Stealth",          cap = "Hide",   tip = "Send bots out of the world temporarily.",    fn = function() Say(".npcbot hide") end },
  { icon = ICON.."Spell_Arcane_Blink",       cap = "Recall", tip = "Teleport all bots directly to you.",         fn = function() Say(".npcbot recall teleport") end },
  { icon = ICON.."INV_Misc_Key_14",          cap = "Unbind", tip = "Temporarily release the selected bot.",      fn = function() Say(".npcbot command unbind") end },
})

-- ---- FOLLOW DISTANCE (segmented control) ----
local distLabel = SectionLabel(frame, i18n("Follow Distance"))
distLabel:SetPoint("TOPLEFT", visLabel, "BOTTOMLEFT", 0, -64)

local distButtons = {}
local function SetActiveDistance(which)
  for k, b in pairs(distButtons) do
    if k == which then
      b:SetBackdropColor(unpack(COL.accentDim))
      b:SetBackdropBorderColor(unpack(COL.accent))
      b.label:SetTextColor(unpack(COL.text))
    else
      b:SetBackdropColor(unpack(COL.btn))
      b:SetBackdropBorderColor(unpack(COL.btnBorder))
      b.label:SetTextColor(unpack(COL.textMuted))
    end
  end
  NetherbotDB.distance = which
end

local distDefs = {
  { key = "low",  cap = "Low",    val = 30 },
  { key = "med",  cap = "Medium", val = 50 },
  { key = "high", cap = "High",   val = 85 },
}
local dprev
for idx, d in ipairs(distDefs) do
  local b = TextButton(frame, 84, 24, i18n(d.cap), nil, COL.textMuted)
  if idx == 1 then
    b:SetPoint("TOPLEFT", distLabel, "BOTTOMLEFT", 0, -6)
  else
    b:SetPoint("LEFT", dprev, "RIGHT", 6, 0)
  end
  -- override hover so the active one stays highlighted
  b:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(COL.accent)) end)
  b:SetScript("OnLeave", function(self)
    if NetherbotDB.distance == d.key then self:SetBackdropBorderColor(unpack(COL.accent))
    else self:SetBackdropBorderColor(unpack(COL.btnBorder)) end
  end)
  b:SetScript("OnClick", function()
    Say(".npcbot distance " .. d.val)
    SetActiveDistance(d.key)
  end)
  distButtons[d.key] = b
  dprev = b
end

-- divider
local divider = frame:CreateTexture(nil, "ARTWORK")
divider:SetTexture(SOLID)
divider:SetVertexColor(COL.btnBorder[1], COL.btnBorder[2], COL.btnBorder[3], 0.8)
divider:SetPoint("TOPLEFT", distLabel, "BOTTOMLEFT", -2, -40)
divider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, 0)
divider:SetHeight(1)

-- ---- FOOTER (Raid | Revive | Admin) ----
local raidButton = TextButton(frame, 84, 26, i18n("Raid"), nil, COL.text)
raidButton:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 2, -10)

local reviveButton = TextButton(frame, 84, 26, i18n("Revive"), function()
  Say(".npcbot revive")
end, COL.green)
reviveButton:SetPoint("LEFT", raidButton, "RIGHT", 6, 0)

local adminButton = TextButton(frame, 84, 26, i18n("Admin"), nil, COL.accent)
adminButton:SetPoint("LEFT", reviveButton, "RIGHT", 6, 0)

-- ----------------------------------------------------------------------------
--  ADMIN FRAME
-- ----------------------------------------------------------------------------
local adminFrame = CreateFrame("Frame", "NetherbotAdminFrame", frame)
adminFrame:SetSize(220, 250)
adminFrame:SetPoint("TOPRIGHT", frame, "TOPLEFT", -8, 0)
ApplyBackdrop(adminFrame, COL.panelBg, COL.panelBorder)
adminFrame:Hide()

local adminHeader = CreateFrame("Frame", nil, adminFrame)
adminHeader:SetPoint("TOPLEFT", 1, -1); adminHeader:SetPoint("TOPRIGHT", -1, -1)
adminHeader:SetHeight(26)
ApplyBackdrop(adminHeader, COL.header, COL.header)
local adminTitle = MakeFS(adminHeader, 12, COL.accent)
adminTitle:SetPoint("LEFT", 10, 0)
adminTitle:SetText(i18n("Admin Tools"))

adminButton:SetScript("OnClick", function()
  if adminFrame:IsShown() then adminFrame:Hide() else adminFrame:Show() end
end)

-- popup helper for ID entry
local function PromptID(name, verb, runWithTarget, runWithID)
  local target = UnitName("target")
  if target then
    runWithTarget(target)
  else
    StaticPopupDialogs[name] = {
      text = i18n("Enter NPCBOT ID:"),
      button1 = "OK", button2 = "Cancel",
      hasEditBox = true, timeout = 0, whileDead = true, hideOnEscape = true,
      OnAccept = function(self)
        local id = self.editBox:GetText()
        if id and id ~= "" then runWithID(id) end
      end,
      EditBoxOnEnterPressed = function(self)
        local id = self:GetParent().editBox:GetText()
        if id and id ~= "" then runWithID(id) end
        self:GetParent():Hide()
      end,
    }
    StaticPopup_Show(name)
  end
end

-- admin grid buttons
local function AdminBtn(label, onClick, color)
  return TextButton(adminFrame, 96, 24, i18n(label), onClick, color or COL.text)
end

local bAdd = AdminBtn("Add", function()
  PromptID("NB_ADD", "add",
    function() Say(".npcbot add") end,
    function(id) Say(".npcbot add " .. id) end)
end, COL.green)
bAdd:SetPoint("TOPLEFT", adminHeader, "BOTTOMLEFT", 8, -10)

local bRemove = AdminBtn("Remove", function()
  PromptID("NB_REMOVE", "remove",
    function() Say(".npcbot remove") end,
    function(id) Say(".npcbot remove " .. id) end)
end, COL.red)
bRemove:SetPoint("LEFT", bAdd, "RIGHT", 8, 0)

local bMove = AdminBtn("Move", function() Say(".npcbot move") end)
bMove:SetPoint("TOPLEFT", bAdd, "BOTTOMLEFT", 0, -8)

local bRecall = AdminBtn("Recall", function() Say(".npcbot recall") end)
bRecall:SetPoint("LEFT", bMove, "RIGHT", 8, 0)

local bInfo = AdminBtn("Bot-Info", function() Say(".npcbot info"); DoEmote("BONK") end)
bInfo:SetPoint("TOPLEFT", bMove, "BOTTOMLEFT", 0, -8)

local bDelete = AdminBtn("Delete", function()
  StaticPopupDialogs["NB_CONFIRM_DELETE"] = {
    text = i18n("Are you sure you want to delete?"),
    button1 = "Yes", button2 = "No",
    timeout = 0, whileDead = true, hideOnEscape = true,
    OnAccept = function()
      PromptID("NB_DELETE", "delete",
        function() Say(".npcbot delete") end,
        function(id) Say(".npcbot delete " .. id) end)
    end,
  }
  StaticPopup_Show("NB_CONFIRM_DELETE")
end, COL.red)
bDelete:SetPoint("LEFT", bInfo, "RIGHT", 8, 0)

-- Revive (secure spell cast) - keep secure button for Redemption
local reviveSpell = CreateFrame("Button", "NetherbotReviveSpell", adminFrame, "SecureActionButtonTemplate")
reviveSpell:SetSize(30, 30)
reviveSpell:SetPoint("BOTTOMLEFT", adminFrame, "BOTTOMLEFT", 10, 12)
ApplyBackdrop(reviveSpell, COL.btn, COL.btnBorder)
local reviveIcon = reviveSpell:CreateTexture(nil, "ARTWORK")
reviveIcon:SetPoint("TOPLEFT", 3, -3); reviveIcon:SetPoint("BOTTOMRIGHT", -3, -3)
reviveIcon:SetTexture(select(3, GetSpellInfo(7328)))  -- Redemption icon
reviveIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
reviveSpell:SetAttribute("type", "spell")
reviveSpell:SetAttribute("spell", 7328)
reviveSpell:SetScript("OnEnter", function(self)
  self:SetBackdropBorderColor(unpack(COL.accent))
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetText(i18n("Revive Bots"), COL.accent[1], COL.accent[2], COL.accent[3])
  GameTooltip:Show()
end)
reviveSpell:SetScript("OnLeave", function(self)
  self:SetBackdropBorderColor(unpack(COL.btnBorder))
  GameTooltip:Hide()
end)

local bLookup = AdminBtn("Lookup", nil, COL.accent)
bLookup:SetSize(110, 26)
bLookup:SetPoint("BOTTOMRIGHT", adminFrame, "BOTTOMRIGHT", -10, 12)

-- ----------------------------------------------------------------------------
--  LOOKUP / SPAWN FRAME
-- ----------------------------------------------------------------------------
local lookupFrame = CreateFrame("Frame", "NetherbotLookupFrame", UIParent)
lookupFrame:SetSize(220, 430)
lookupFrame:SetPoint("CENTER")
ApplyBackdrop(lookupFrame, COL.panelBg, COL.panelBorder)
lookupFrame:SetMovable(true); lookupFrame:EnableMouse(true)
lookupFrame:RegisterForDrag("LeftButton")
lookupFrame:SetScript("OnDragStart", lookupFrame.StartMoving)
lookupFrame:SetScript("OnDragStop", lookupFrame.StopMovingOrSizing)
lookupFrame:Hide()

local lkHeader = CreateFrame("Frame", nil, lookupFrame)
lkHeader:SetPoint("TOPLEFT", 1, -1); lkHeader:SetPoint("TOPRIGHT", -1, -1)
lkHeader:SetHeight(26)
ApplyBackdrop(lkHeader, COL.header, COL.header)
local lkTitle = MakeFS(lkHeader, 12, COL.accent)
lkTitle:SetPoint("LEFT", 10, 0)
lkTitle:SetText(i18n("Select Class"))

local lkClose = TextButton(lkHeader, 22, 20, "X", function() lookupFrame:Hide() end, COL.red)
lkClose:SetPoint("RIGHT", -6, 0)

bLookup:SetScript("OnClick", function()
  if lookupFrame:IsShown() then lookupFrame:Hide() else lookupFrame:Show() end
end)

-- class list (NPCBot lookup IDs)
local classTable = {
  { "Warrior", 1 }, { "Paladin", 2 }, { "Hunter", 3 }, { "Rogue", 4 },
  { "Priest", 5 }, { "Death Knight", 6 }, { "Shaman", 7 }, { "Mage", 8 },
  { "Warlock", 9 }, { "Druid", 11 }, { "Blademaster", 12 }, { "Sphynx", 13 },
  { "Archmage", 14 }, { "Dreadlord", 15 }, { "Spellbreaker", 16 },
  { "DarkRanger", 17 }, { "Necromancer", 18 }, { "SeaWitch", 19 },
}

local lkScroll = CreateFrame("ScrollFrame", "NetherbotLookupScroll", lookupFrame, "UIPanelScrollFrameTemplate")
lkScroll:SetPoint("TOPLEFT", lkHeader, "BOTTOMLEFT", 6, -6)
lkScroll:SetPoint("BOTTOMRIGHT", lookupFrame, "BOTTOMRIGHT", -28, 78)
local lkList = CreateFrame("Frame", nil, lkScroll)
lkList:SetSize(170, #classTable * 26)
lkScroll:SetScrollChild(lkList)

local cprev
for idx, c in ipairs(classTable) do
  local b = TextButton(lkList, 168, 22, i18n(c[1]), function() Say(".npcbot lookup " .. c[2]) end)
  if idx == 1 then b:SetPoint("TOPLEFT", lkList, "TOPLEFT", 2, -2)
  else b:SetPoint("TOPLEFT", cprev, "BOTTOMLEFT", 0, -4) end
  cprev = b
end

-- spawn-by-ID box
local spawnLabel = SectionLabel(lookupFrame, i18n("Spawn Bot by ID"))
spawnLabel:SetPoint("BOTTOMLEFT", lookupFrame, "BOTTOMLEFT", 12, 52)

local spawnInput = CreateFrame("EditBox", "NetherbotSpawnInput", lookupFrame, "InputBoxTemplate")
spawnInput:SetSize(95, 24)
spawnInput:SetPoint("BOTTOMLEFT", lookupFrame, "BOTTOMLEFT", 14, 14)
spawnInput:SetAutoFocus(false)

local spawnGo = TextButton(lookupFrame, 80, 24, i18n("Spawn"), function()
  local id = spawnInput:GetText()
  if id and id ~= "" then
    Say(".npcbot spawn " .. id)   -- was GUILD channel in the original; SAY is correct
    spawnInput:SetText("")
    spawnInput:ClearFocus()
  else
    print("|cffae8bffNetherBot:|r " .. i18n("Please enter an ID."))
  end
end, COL.green)
spawnGo:SetPoint("BOTTOMRIGHT", lookupFrame, "BOTTOMRIGHT", -14, 14)

-- ----------------------------------------------------------------------------
--  RAID FRAMES (restyled)
-- ----------------------------------------------------------------------------
local TeamFrame = CreateFrame("Frame", "NetherbotTeamFrame", UIParent)
TeamFrame:SetSize(350, 600)
TeamFrame:SetPoint("CENTER")
TeamFrame:SetMovable(true); TeamFrame:EnableMouse(true)
TeamFrame:RegisterForDrag("LeftButton")
TeamFrame:SetScript("OnDragStart", TeamFrame.StartMoving)
TeamFrame:SetScript("OnDragStop", TeamFrame.StopMovingOrSizing)
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
      local gf = CreateFrame("Frame", nil, TeamFrame)
      gf:SetSize(150, 20)
      gf:SetPoint("TOPLEFT", TeamFrame, "TOP", 175 * (column - 1) + 12, 6 - row * 230)
      local gt = MakeFS(gf, 11, COL.accent)
      gt:SetPoint("LEFT", 0, 0)
      gt:SetText(i18n("Group") .. " " .. group)
      groupFrames[group] = gf
    end

    local mf = CreateFrame("Button", nil, TeamFrame, "SecureUnitButtonTemplate")
    mf:SetSize(150, 40)
    mf:SetPoint("TOPLEFT", TeamFrame, "TOPLEFT", 10 + 175 * column, -10 - ((row * 230) + (position - 1) * 44))
    mf:SetAttribute("unit", "raid" .. i)
    mf:RegisterForClicks("AnyUp")
    SecureUnitButton_OnLoad(mf, "raid" .. i)
    ApplyBackdrop(mf, COL.barBg, COL.btnBorder)

    local _, charClass = UnitClass("raid" .. i)
    local cc = RAID_CLASS_COLORS[charClass] or { r = 1, g = 1, b = 1 }
    mf:SetBackdropBorderColor(cc.r, cc.g, cc.b, 0.85)

    local nameText = MakeFS(mf, 11, COL.text)
    nameText:SetPoint("TOPLEFT", 6, -4)
    nameText:SetText((UnitName("raid" .. i)))
    nameText:SetTextColor(cc.r, cc.g, cc.b)

    local hb = CreateFrame("StatusBar", nil, mf)
    hb:SetStatusBarTexture(SOLID)
    hb:SetStatusBarColor(unpack(COL.green))
    hb:SetPoint("TOPLEFT", 6, -18)
    hb:SetSize(138, 9)
    hb:SetMinMaxValues(0, UnitHealthMax("raid" .. i))
    hb:SetValue(UnitHealth("raid" .. i))
    local hbbg = hb:CreateTexture(nil, "BACKGROUND")
    hbbg:SetTexture(SOLID); hbbg:SetVertexColor(0.1, 0.1, 0.12, 0.9); hbbg:SetAllPoints()

    local mb = CreateFrame("StatusBar", nil, mf)
    mb:SetStatusBarTexture(SOLID)
    mb:SetStatusBarColor(0.30, 0.45, 0.95)
    mb:SetPoint("TOPLEFT", 6, -29)
    mb:SetSize(138, 6)
    mb:SetMinMaxValues(0, UnitPowerMax("raid" .. i))
    mb:SetValue(UnitPower("raid" .. i))
    local mbbg = mb:CreateTexture(nil, "BACKGROUND")
    mbbg:SetTexture(SOLID); mbbg:SetVertexColor(0.1, 0.1, 0.12, 0.9); mbbg:SetAllPoints()

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

local function OnRaidEvent(self, event, ...)
  if event == "PLAYER_ENTERING_WORLD" or event == "RAID_ROSTER_UPDATE" or event == "ADDON_LOADED" then
    InitRaid()
  else
    UpdateBars(self, event, ...)
  end
end

TeamFrame:RegisterEvent("UNIT_HEALTH")
TeamFrame:RegisterEvent("UNIT_POWER_UPDATE")
TeamFrame:RegisterEvent("RAID_ROSTER_UPDATE")
TeamFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
TeamFrame:SetScript("OnEvent", OnRaidEvent)

raidButton:SetScript("OnClick", function()
  if TeamFrame:IsShown() then TeamFrame:Hide() else InitRaid(); TeamFrame:Show() end
end)

-- ----------------------------------------------------------------------------
--  LOAD: restore saved scale + position
-- ----------------------------------------------------------------------------
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
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
  end
end)

-- ----------------------------------------------------------------------------
--  SLASH COMMAND
-- ----------------------------------------------------------------------------
SLASH_NETHERBOT1 = "/netherbot"
SLASH_NETHERBOT2 = "/nb"
SlashCmdList["NETHERBOT"] = function(msg)
  msg = string.lower(msg or "")
  if msg == "hide" then
    frame:Hide(); adminFrame:Hide(); lookupFrame:Hide(); TeamFrame:Hide()
  else
    frame:Show()
  end
end
