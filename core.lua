local _, RaidClearCheckHelper = ...

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Const
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

---@enum Difficulty
Difficulty = {
  None   = 0,
  Normal = 3,
  Heroic = 4,
  Mystic = 5,
}

---@type table<Difficulty, string>
Difficulty2String = {
  [Difficulty.None  ] = "알 수 없음",
  [Difficulty.Normal] = "일반",
  [Difficulty.Heroic] = "영웅",
  [Difficulty.Mystic] = "신화",
}

---@type table<number, Difficulty>
DifficultyIDTable = {
  [14] = Difficulty.Normal,
  [15] = Difficulty.Heroic,
  [16] = Difficulty.Mystic,
}

---@class Player
---@field name  string
---@field realm string

---@class Core
---@field frame      Frame?
---@field difficulty Frame?
---@field players    Frame?
---@field editbox    EditBox?
---@field checkbox   CheckButton?
---@field curPlayers table<string, Player>

---@type Core
local core = {
  frame = nil,
  difficulty = nil,
  players = nil,
  editbox = nil,
  checkbox = nil,
  curPlayers = {},
}

---@class RaidClearCheckHelperConfigProfileMinimap
---@field hide boolean

---@class RaidClearCheckHelperConfigProfileFrame
---@field point         FramePoint
---@field relativePoint FramePoint
---@field relativeFrame Frame?
---@field x             number
---@field y             number
---@field width         number
---@field height        number
---@field checked       boolean

---@class RaidClearCheckHelperConfig
---@field minimap RaidClearCheckHelperConfigProfileMinimap
---@field frame   RaidClearCheckHelperConfigProfileFrame

---@type RaidClearCheckHelperConfig
local defaultConfig = {
  minimap = {
    hide = false,
  },
  frame = {
    point         = "CENTER",
    relativePoint = "CENTER",
    relativeFrame = nil,
    x             = 0,
    y             = 0,
    width         = 500,
    height        = 300,
    checked       = true,
  },
}

---@type table<string, string>
local realmToNumber = {
    --- 아즈샤라가 제일 많아서 맨 위로
    ["아즈샤라"    ] =  '0',
    ["가로나"      ] =  '1',
    ["굴단"        ] =  '2',
    ["노르간논"    ] =  '3',
    ["달라란"      ] =  '4',
    ["데스윙"      ] =  '5',
    ["듀로탄"      ] =  '6',
    ["라그나로스"  ] =  '7',
    ["렉사르"      ] =  '8',
    ["말퓨리온"    ] =  '9',
    ["불타는군단"  ] = '10',
    ["세나리우스"  ] = '11',
    ["스톰레이지"  ] = '12',
    ---["아즈샤라"    ] = ' 13',
    ["알렉스트라자"] = '14',
    ["에이그윈"    ] = '15',
    ["엘룬"        ] = '16',
    ["와일드해머"  ] = '17',
    ["윈드러너"    ] = '18',
    ["이오나"      ] = '19',
    ["줄진"        ] = '20',
    ["카르가스"    ] = '21',
    ["하이잘"      ] = '22',
    ["헬스크림"    ] = '23',
}

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- ACE Initialize
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

LibDBIcon = LibStub("LibDBIcon-1.0")

---@class RaidClearCheckHelper
---@field db { profile: RaidClearCheckHelperConfig } | AceDBObject-3.0

---@type RaidClearCheckHelper | AceAddon | AceConsole-3.0 | AceEvent-3.0
RaidClearCheckHelper = LibStub("AceAddon-3.0"):NewAddon(RaidClearCheckHelper, "RaidClearCheckHelper", "AceConsole-3.0", "AceEvent-3.0")

local RaidClearCheckHelperLDB = LibStub("LibDataBroker-1.1"):NewDataObject("RaidClearCheckHelper", {
  type = "data source",
  text = "레이드 클자 체크 도우미",
  label = "RaidClearCheckHelper",
  icon = "Interface\\AddOns\\RaidClearCheckHelper\\logo",
  OnClick = function()
      core:Toggle()
  end,
  OnTooltipShow = function(tooltip) ---@param tooltip GameTooltip
      tooltip:AddLine("레이드 클자 체크 도우미")
      tooltip:AddLine(" ")
      tooltip:AddLine("'/rcch minimap' 명령어를 통해 아이콘을 켜고 끌 수 있습니다.")
  end
})

---@diagnostic disable-next-line: duplicate-set-field
function RaidClearCheckHelper:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("RaidClearCheckHelperDB", {
    profile = defaultConfig
  });

  LibDBIcon:Register(
    "RaidClearCheckHelper",
    RaidClearCheckHelperLDB --[[@as LibDBIcon.dataObject]],
    self.db.profile.minimap --[[@as LibDBIcon.button.DB]]
  )
  RaidClearCheckHelper:UpdateMinimapButton()

  RaidClearCheckHelper:RegisterChatCommand(
    'rcch',
    function(input)
      local args = {strsplit(' ', input)}
    
      for _, arg in ipairs(args) do
        if arg == 'minimap' then
          self.db.profile.minimap.hide = not self.db.profile.minimap.hide
          RaidClearCheckHelper:UpdateMinimapButton()
          return
        end
      end
    
      core:Show()
    end
    )
  RaidClearCheckHelper:RegisterEvent("GROUP_ROSTER_UPDATE", 'HandleGroupRosterUpdate')
end

function RaidClearCheckHelper:UpdateMinimapButton()
  if (self.db.profile.minimap.hide) then
    LibDBIcon:Hide("RaidClearCheckHelper")
  else
    LibDBIcon:Show("RaidClearCheckHelper")
  end
end

function RaidClearCheckHelper:HandleGroupRosterUpdate()
  if core.frame and core.frame:IsShown() then
    core:UpdatePlayers()
    core:RefreshText()
  end
end

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Frame
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

function core:RefreshText()
    local difficulty = DifficultyIDTable[GetRaidDifficultyID()] or Difficulty.None
    local players = 0

    local parts = {}

    if self.checkbox:GetChecked() then
      table.insert(parts, "https://wow-check.ryuar.in/?")

      if difficulty ~= Difficulty.None then
        table.insert(parts, "d=")
        table.insert(parts, difficulty)
        table.insert(parts, "&")
      end

      table.insert(parts, "q=")
      for k, v in pairs(self.curPlayers) do
        table.insert(parts, v.name)
        table.insert(parts, realmToNumber[v.realm])
        players = players + 1
      end
    else
      for k, v in pairs(self.curPlayers) do
        if text ~= "" then
          table.insert(parts, text, ",")
        end
        table.insert(parts, text, k)
        players = players + 1
      end
    end

    local text = table.concat(parts)

    self.difficulty:SetText("현재 인스턴스 난이도 : " .. Difficulty2String[difficulty])

    self.players:SetText(format("현재 인원 수 : %d", players))

    self.editbox:SetText(text)
    self.editbox:HighlightText()
end

function core:initFrame()
  if core.frame then
    return
  end

  local mainFrame  = CreateFrame("Frame",       "RaidClearCheckHelperFrame",       UIParent,  "DialogBoxFrame")
  local difficulty = mainFrame:CreateFontString("RaidClearCheckHelperDifficulty",  "OVERLAY", "GameFontNormal")
  local players    = mainFrame:CreateFontString("RaidClearCheckHelperPlayers",     "OVERLAY", "GameFontNormal")
  local checkBox   = CreateFrame("CheckButton", "RaidClearCheckHelperCheckBox",    mainFrame, "UICheckButtonTemplate")
  local scroll     = CreateFrame("ScrollFrame", "RaidClearCheckHelperScrollFrame", mainFrame, "UIPanelScrollFrameTemplate")
  local editbox    = CreateFrame("EditBox",     "RaidClearCheckHelperEditBox",     mainFrame)
  local copyright  = mainFrame:CreateFontString("RaidClearCheckHelperCopyright",   "OVERLAY", "GameFontNormal")
  local resize     = CreateFrame("Button",      "RaidClearCheckHelperButton",      mainFrame)
  local close, _   = mainFrame:GetChildren()

  -- mainFrame
  do
    mainFrame:ClearAllPoints()
    -- load position from local DB
    mainFrame:SetPoint(
      RaidClearCheckHelper.db.profile.frame.point,
      RaidClearCheckHelper.db.profile.frame.relativeFrame,
      RaidClearCheckHelper.db.profile.frame.relativePoint,
      RaidClearCheckHelper.db.profile.frame.x,
      RaidClearCheckHelper.db.profile.frame.y
    )
    mainFrame:SetSize(RaidClearCheckHelper.db.profile.frame.width, RaidClearCheckHelper.db.profile.frame.height)
    mainFrame:SetToplevel(true)
    mainFrame:SetFrameStrata("DIALOG")

    mainFrame:SetMovable(true)
    mainFrame:SetClampedToScreen(true)
    mainFrame:SetResizable(true)
    ---@diagnostic disable-next-line: undefined-field
    mainFrame:SetResizeBounds(300, 200, nil, nil)

    ---@diagnostic disable-next-line: undefined-field
    mainFrame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight",
      edgeSize = 16,
      insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })

    mainFrame:SetScript("OnMouseDown", function(self2, button)
      if button == "LeftButton" then
        self2:StartMoving()
      end
    end)
    mainFrame:SetScript("OnMouseUp", function(self2, _)
      self2:StopMovingOrSizing()

      local point, relativeFrame, relativeTo, ofsx, ofsy = self2:GetPoint()
      RaidClearCheckHelper.db.profile.frame.point = point
      RaidClearCheckHelper.db.profile.frame.relativeFrame = relativeFrame
      RaidClearCheckHelper.db.profile.frame.relativePoint = relativeTo
      RaidClearCheckHelper.db.profile.frame.ofsx = ofsx
      RaidClearCheckHelper.db.profile.frame.ofsy = ofsy
    end)
    mainFrame:SetScript("OnShow", function()
      core:RefreshText()
    end)
  end

  -- difficulty
  do
    difficulty:SetPoint("TOP", 16, -16)
    difficulty:SetPoint("LEFT", 16, 0)
    difficulty:SetPoint("RIGHT", -32, 0)
  end

  -- players
  do
    players:SetPoint("TOP", difficulty, "BOTTOM", 0, -10)
    players:SetPoint("LEFT", 16, 0)
    players:SetPoint("RIGHT", -32, 0)
  end

  -- checkBox
  do
    checkBox:SetChecked(RaidClearCheckHelper.db.profile.frame.checked)
    checkBox:SetPoint("TOP", players, "BOTTOM", 0, 0)
    checkBox:SetPoint("LEFT", 16, 0)

    ---@diagnostic disable-next-line: undefined-field
    checkBox.Text:SetText("주소 형태로 복사 (크롬 주소창에 바로 붙여넣기 하세요)")

    checkBox:SetScript("OnClick", function()
      RaidClearCheckHelper.db.profile.frame.checked = checkBox:GetChecked() --[[@as boolean]]
      core:RefreshText()
    end)
  end

  -- scroll
  do
    scroll:SetPoint("TOP", checkBox, "BOTTOM", 0, -10)
    scroll:SetPoint("LEFT", 16, 0)
    scroll:SetPoint("RIGHT", -32, 0)
    scroll:SetPoint("BOTTOM", copyright, "TOP", 0, 8)
    scroll:SetScrollChild(editbox)
  end

  -- editbox
  do
    editbox:SetSize(scroll:GetSize())
    editbox:SetMultiLine(true)
    editbox:SetAutoFocus(true)
    editbox:SetFontObject("ChatFontNormal")

    editbox:SetScript("OnEscapePressed", core.Hide)
  end

  -- copyright
  do
    copyright:SetText("만든이 : 류아네린\n(RyuaNerin, 경력직자택경비원-아즈샤라, 곌벴꼲똴꼍놂뚫뀄-아즈샤라)")
    copyright:SetPoint("LEFT", 16, 0)
    copyright:SetPoint("RIGHT", -32, 0)
    copyright:SetPoint("BOTTOM", close, "TOP", 0, 8)
  end

  -- resize
  do
    resize:SetPoint("BOTTOMRIGHT", -6, 7)
    resize:SetSize(16, 16)

    resize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resize:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resize:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    resize:SetScript("OnMouseDown", function(self, button)
      if button == "LeftButton" then
        mainFrame:StartSizing("BOTTOMRIGHT")
        self:GetHighlightTexture():Hide()
      end
    end)
    resize:SetScript("OnMouseUp", function(self, _)
      mainFrame:StopMovingOrSizing()
      self:GetHighlightTexture():Show()

      editbox:SetSize(scroll:GetSize())

      RaidClearCheckHelper.db.profile.frame.width = mainFrame:GetWidth()
      RaidClearCheckHelper.db.profile.frame.height = mainFrame:GetHeight()
    end)
  end

  ---@diagnostic disable: assign-type-mismatch
  core.frame = mainFrame
  core.difficulty = difficulty
  core.players = players
  core.checkbox = checkBox
  core.editbox = editbox
  ---@diagnostic enable: assign-type-mismatch
end

function core:UpdatePlayers()
  local players = {} ---@type table<string, Player>

  local function append(k)
    local playerName, playerRealm = UnitName(k)
    playerRealm = playerRealm or GetRealmName()

    if playerName and playerRealm then
      players[format("%s-%s", playerName, playerRealm)] = { name = playerName, realm = playerRealm }
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

  core.curPlayers = players
end

function core:Hide()
  core.frame:Hide()
end

function core:Show()
  core:UpdatePlayers()
  core:initFrame()
  core.frame:Show()
end

function core:Toggle()
  if core.frame and core.frame:IsShown() then
    core:Hide()
  else
    core:Show()
  end
end

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- Compartment
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

AddonCompartmentFrame:RegisterAddon({
  text = "레이드 클자 체크 도우미",
  icon = "Interface\\AddOns\\RaidClearCheckHelper\\logo",
  notCheckable = true,
  func = core.Show,
})
