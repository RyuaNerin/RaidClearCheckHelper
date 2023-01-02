-- Ignore some luacheck warnings about global vars, just use a ton of them in WoW Lua
-- luacheck: no global
-- luacheck: no self
local _, RaidClearCheckHelper = ...

RaidClearCheckHelper = LibStub("AceAddon-3.0"):NewAddon(RaidClearCheckHelper, "RaidClearCheckHelper", "AceConsole-3.0", "AceEvent-3.0")
LibRealmInfo = LibStub("LibRealmInfo")

-- Set up DataBroker for minimap button

RaidClearCheckHelperLDB = LibStub("LibDataBroker-1.1"):NewDataObject("RaidClearCheckHelper", {
    type = "data source",
    text = "레이드 클자 체크 도우미",
    label = "RaidClearCheckHelper",
    icon = "Interface\\AddOns\\RaidClearCheckHelper\\logo",
    OnClick = function()
      if RaidClearCheckHelperFrame and RaidClearCheckHelperFrame:IsShown() then
        RaidClearCheckHelperFrame:Hide()
      else
        RaidClearCheckHelper:PrintPartyList()
      end
    end,
    OnTooltipShow = function(tt)
        tt:AddLine("레이드 클자 체크 도우미")
        tt:AddLine(" ")
        tt:AddLine("공대원 전체 목록을 복사하려면 클릭하세요.")
        tt:AddLine("아이콘을 '/rcch minimap' 명령어를 통해 아이콘을 켜고 끌 수 있습니다.")
    end
})

LibDBIcon = LibStub("LibDBIcon-1.0")

local RaidClearCheckHelperFrame = nil

function RaidClearCheckHelper:OnInitialize()
  -- init databroker
  self.db = LibStub("AceDB-3.0"):New("RaidClearCheckHelperDB", {
    profile = {
      minimap = {
        hide = false,
      },
      frame = {
        point = "CENTER",
        relativeFrame = nil,
        relativePoint = "CENTER",
        ofsx = 0,
        ofsy = 0,
        width = 750,
        height = 400,
      },
    },
  });
  LibDBIcon:Register("RaidClearCheckHelper", RaidClearCheckHelperLDB, self.db.profile.minimap)
  RaidClearCheckHelper:UpdateMinimapButton()

  RaidClearCheckHelper:RegisterChatCommand('rcch', 'HandleChatCommand')
end

function RaidClearCheckHelper:OnEnable()

end

function RaidClearCheckHelper:OnDisable()

end

function RaidClearCheckHelper:UpdateMinimapButton()
  if (self.db.profile.minimap.hide) then
    LibDBIcon:Hide("RaidClearCheckHelper")
  else
    LibDBIcon:Show("RaidClearCheckHelper")
  end
end

function RaidClearCheckHelper:HandleChatCommand(input)
  local args = {strsplit(' ', input)}

  for _, arg in ipairs(args) do
    if arg == 'minimap' then
      self.db.profile.minimap.hide = not self.db.profile.minimap.hide
      RaidClearCheckHelper:UpdateMinimapButton()
      return
    end
  end

  self:PrintPartyList()
end

function RaidClearCheckHelper:PrintPartyList()
  local players = {} ---@type table<string, boolean>

  local function append(k)
    local playerName, playerRealm = UnitName(k)
    playerRealm = playerRealm or GetRealmName()

    if playerName and playerRealm then
      players[format("%s-%s", playerName, playerRealm)] = true
    end
  end

  if IsInRaid() then
    for i = 1, 40 do
      append("raid"..i)
    end
  elseif IsInGroup() then
    for i = 1, 4 do
      append("party"..i)
    end
  end

  append("player")

  local text = ""
  for k, v in pairs(players) do
    if text ~= "" then
      text = text .. ","
    end
    text = text .. k
  end

  local f = RaidClearCheckHelper:GetMainFrame(text)
  f:Show()
end

function RaidClearCheckHelper:GetMainFrame(text)
  -- Frame code largely adapted from https://www.wowinterface.com/forums/showpost.php?p=323901&postcount=2
  if not RaidClearCheckHelperFrame then
    -- Main Frame
    local frameConfig = self.db.profile.frame
    local f = CreateFrame("Frame", "RaidClearCheckHelperFrame", UIParent, "DialogBoxFrame")
    f:ClearAllPoints()
    -- load position from local DB
    f:SetPoint(
      frameConfig.point,
      frameConfig.relativeFrame,
      frameConfig.relativePoint,
      frameConfig.ofsx,
      frameConfig.ofsy
    )
    f:SetSize(frameConfig.width, frameConfig.height)
    f:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight",
      edgeSize = 16,
      insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:SetScript("OnMouseDown", function(self, button) -- luacheck: ignore
      if button == "LeftButton" then
        self:StartMoving()
      end
    end)
    f:SetScript("OnMouseUp", function(self, _) -- luacheck: ignore
      self:StopMovingOrSizing()
      -- save position between sessions
      local point, relativeFrame, relativeTo, ofsx, ofsy = self:GetPoint()
      frameConfig.point = point
      frameConfig.relativeFrame = relativeFrame
      frameConfig.relativePoint = relativeTo
      frameConfig.ofsx = ofsx
      frameConfig.ofsy = ofsy
    end)

    -- scroll frame
    local sf = CreateFrame("ScrollFrame", "RaidClearCheckHelperScrollFrame", f, "UIPanelScrollFrameTemplate")
    sf:SetPoint("LEFT", 16, 0)
    sf:SetPoint("RIGHT", -32, 0)
    sf:SetPoint("TOP", 0, -32)
    sf:SetPoint("BOTTOM", RaidClearCheckHelperFrameButton, "TOP", 0, 0)

    -- edit box
    local eb = CreateFrame("EditBox", "RaidClearCheckHelperEditBox", RaidClearCheckHelperScrollFrame)
    eb:SetSize(sf:GetSize())
    eb:SetMultiLine(true)
    eb:SetAutoFocus(true)
    eb:SetFontObject("ChatFontNormal")
    eb:SetScript("OnEscapePressed", function() f:Hide() end)
    sf:SetScrollChild(eb)

    -- resizing
    f:SetResizable(true)
    if f.SetMinResize then
      -- older function from shadowlands and before
      -- Can remove when Dragonflight is in full swing
      f:SetMinResize(150, 100)
    else
      -- new func for dragonflight
      f:SetResizeBounds(150, 100, nil, nil)
    end
    local rb = CreateFrame("Button", "SimcResizeButton", f)
    rb:SetPoint("BOTTOMRIGHT", -6, 7)
    rb:SetSize(16, 16)

    rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    rb:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    rb:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    rb:SetScript("OnMouseDown", function(self, button) -- luacheck: ignore
        if button == "LeftButton" then
            f:StartSizing("BOTTOMRIGHT")
            self:GetHighlightTexture():Hide() -- more noticeable
        end
    end)
    rb:SetScript("OnMouseUp", function(self, _) -- luacheck: ignore
        f:StopMovingOrSizing()
        self:GetHighlightTexture():Show()
        eb:SetWidth(sf:GetWidth())

        -- save size between sessions
        frameConfig.width = f:GetWidth()
        frameConfig.height = f:GetHeight()
    end)

    RaidClearCheckHelperFrame = f
  end
  RaidClearCheckHelperEditBox:SetText(text)
  RaidClearCheckHelperEditBox:HighlightText()
  return RaidClearCheckHelperFrame
end