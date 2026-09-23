local addonName, addonTable = ...
local UI = addonTable.UI or {}
addonTable.UI = UI
local CreateThemedFrame = addonTable.CreateThemedFrame

-- Source Type Icons
local SOURCE_ICONS = {
    ["Book"] = "Interface\\ICONS\\INV_Misc_Book_09",
    ["Scroll"] = "Interface\\ICONS\\INV_Scroll_03",
    ["Letter / Note"] = "Interface\\ICONS\\INV_Misc_Note_01",
    ["Tablet / Plaque"] = "Interface\\ICONS\\INV_Stone_02",
    ["Default"] = "Interface\\ICONS\\INV_Misc_Book_06",
}

local function GetSourceIcon(source)
    if not source then return SOURCE_ICONS["Default"] end
    for k, icon in pairs(SOURCE_ICONS) do
        if source:find(k) then return icon end
    end
    return SOURCE_ICONS["Default"]
end

-- Lorekeeper Honorary Titles based on Collection Progress
local function GetLorekeeperRank(count)
    if count >= 300 then
        return "Master Lorekeeper", "|cffff8000"
    elseif count >= 150 then
        return "Grand Chronicler", "|ca335ee"
    elseif count >= 50 then
        return "Archivist", "|cff0070dd"
    elseif count >= 15 then
        return "Journeyman Scribe", "|cff1eff00"
    else
        return "Apprentice Reader", "|cffffd100"
    end
end

-- Lore Keyword Dictionary for Auto-Tagging
local LORE_KEYWORDS = {
    ["Titans"] = { "titan", "pantheon", "aman'thul", "eonar", "norgannon", "golganneth", "khaz'goroth", "aggramar", "sargeras", "world-soul", "keeper", "mimiron", "ra-den", "odyn", "freya", "thorim", "loken", "archavon" },
    ["Old Gods"] = { "old god", "c'thun", "yogg-saron", "n'zoth", "yshaarj", "black empire", "void", "harbinger", "faceless", "aqir", "k'thir", "twilight's hammer" },
    ["Burning Legion"] = { "legion", "burning crusade", "kil'jaeden", "archimonde", "fel", "demon", "twisting nether", "mannoroth", "tichondrius", "mal'ganis", "sargeras" },
    ["Scourge"] = { "scourge", "lich king", "arthas", "kel'thuzad", "plague", "undead", "cult of the damned", "ner'zhul", "icecrown", "naxxramas", "acolyte" },
    ["Dragonflights"] = { "dragon", "aspect", "alexstrasza", "ysera", "neltharion", "malygos", "nozdormu", "deathwing", "proto-dragon", "galakrond", "drakonid", "flight" },
    ["The Light"] = { "holy light", "paladin", "silver hand", "uther", "turalyon", "faol", "tirion", "lightbringer", "priest", "naaru" },
    ["Arcane"] = { "arcane", "kirin tor", "dalaran", "mage", "antonidas", "guardian", "tirisfal", "medivh", "aegwynn", "khadgar" },
    ["Shadow & Void"] = { "shadow", "void", "shadow council", "twilight", "necromancy", "dark magic", "cult" },
    ["Elves"] = { "kaldorei", "night elf", "high elf", "blood elf", "quel'thalas", "sunwell", "dath'remar", "anasterian", "kael'thas", "illidan", "malfurion", "tyrande", "azshara" },
    ["Dwarves"] = { "dwarf", "dwarven", "ironforge", "bronzebeard", "wildhammer", "dark iron", "modimus", "anvilmar", "magni", "brann", "earthen" },
    ["Orcs"] = { "orc", "orcs", "horde", "durotan", "orgrim", "doomhammer", "blackhand", "gul'dan", "thrall", "frostwolf", "warsong", "draenor" },
    ["Humans"] = { "human", "stormwind", "lordaeron", "arathor", "trollbane", "wrynn", "menethil", "terenas", "stratholme", "dalaran", "gilneas" },
    ["Trolls"] = { "troll", "amani", "gurubashi", "drakkari", "farraki", "zul'jin", "zandalar", "hakkar", "loa", "rastakhan", "voodoo" },
    ["Historical Era"] = { "sundering", "troll war", "first war", "second war", "third war", "dark portal", "war of the ancients", "well of eternity" }
}

local function AutoDetectTags(title, text)
    local content = ((title or "") .. " " .. (text or "")):lower()
    local detected = {}
    for category, keywords in pairs(LORE_KEYWORDS) do
        for _, kw in ipairs(keywords) do
            if content:find(kw, 1, true) then
                table.insert(detected, category)
                break
            end
        end
    end
    table.sort(detected)
    return detected
end

-- Font Sizes for Reader
local FONT_SIZES = {
    small = { font = "GameFontHighlightSmall", label = "Small" },
    medium = { font = "GameFontHighlight", label = "Medium" },
    large = { font = "GameFontHighlightMedium", label = "Large" },
    huge = { font = "GameFontHighlightLarge", label = "Huge" },
}

-- Slash Commands
SLASH_LOREARCHIVE1 = "/lore"
SLASH_LOREARCHIVE2 = "/la"
SlashCmdList["LOREARCHIVE"] = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "options" or msg == "config" then
        if addonTable.OpenOptions then
            addonTable.OpenOptions()
        else
            print("|cFFFF0000[Lore Archive]|r Options menu not found.")
        end
        return
    end

    if UI and UI.MainFrame then
        if UI.MainFrame:IsShown() then
            UI.MainFrame:Hide()
            addonTable.PlaySound("IG_CHARACTER_INFO_CLOSE", 837)
        else
            if UI.UpdateList then UI.UpdateList() end
            UI.MainFrame:Show()
            addonTable.PlaySound("IG_QUEST_LOG_OPEN", 843)
        end
    else
        print("|cFFFF0000[Lore Archive]|r UI initialization failed. Please check BugSack.")
    end
end

-- Tag Normalization
local function NormalizeTags(tags)
    local out = {}
    if type(tags) == "string" then tags = { tags } end
    if type(tags) == "table" then
        for _, v in ipairs(tags) do
            if type(v) == "string" then
                for tag in v:gmatch("[^,]+") do
                    tag = tag:match("^%s*(.-)%s*$")
                    if tag ~= "" then
                        table.insert(out, tag)
                    end
                end
            end
        end
    end
    return out
end

-- Main initialization
local function Initialize()
    -- =========================================================================
    -- 1. MAIN WINDOW (One solid window using native Blizzard frame template)
    -- =========================================================================
    UI.MainFrame = CreateThemedFrame("LoreArchiveFrame", UIParent, false)
    table.insert(UISpecialFrames, "LoreArchiveFrame")
    local MainFrame = UI.MainFrame
    MainFrame:SetSize(940, 640)
    MainFrame:SetPoint("CENTER")
    MainFrame:SetFrameStrata("HIGH")
    MainFrame:Hide()

    -- Addon Emblem in title bar
    local emblemFrame = CreateFrame("Frame", nil, MainFrame)
    emblemFrame:SetSize(22, 22)
    emblemFrame:SetPoint("TOPLEFT", 8, -4)
    local emblemTexture = emblemFrame:CreateTexture(nil, "ARTWORK")
    emblemTexture:SetAllPoints()
    emblemTexture:SetTexture("Interface\\ICONS\\INV_Misc_Book_09")
    emblemTexture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Header Title in title bar
    MainFrame.Title = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    MainFrame.Title:SetPoint("LEFT", emblemFrame, "RIGHT", 6, 0)
    MainFrame.Title:SetText("|cFFFFD100LORE ARCHIVE|r")

    MainFrame.Subtitle = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    MainFrame.Subtitle:SetPoint("LEFT", MainFrame.Title, "RIGHT", 8, 0)
    MainFrame.Subtitle:SetText("- The Grand Athenaeum")

    -- Collection Rank Pill in title bar (Clickable to open Milestones modal!)
    MainFrame.RankBadge = CreateFrame("Button", nil, MainFrame, "BackdropTemplate")
    MainFrame.RankBadge:SetSize(130, 18)
    MainFrame.RankBadge:SetPoint("LEFT", MainFrame.Subtitle, "RIGHT", 10, 0)
    MainFrame.RankBadge:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    MainFrame.RankBadge:SetBackdropColor(0, 0, 0, 0.5)
    MainFrame.RankBadge.Text = MainFrame.RankBadge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    MainFrame.RankBadge.Text:SetPoint("CENTER")
    MainFrame.RankBadge.Text:SetText("Apprentice Reader")
    MainFrame.RankBadge:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    MainFrame.RankBadge:SetScript("OnClick", function()
        if UI.ShowMilestonesModal then UI.ShowMilestonesModal() end
    end)
    MainFrame.RankBadge:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Lorekeeper Rank & Milestones", 1, 0.82, 0)
        GameTooltip:AddLine("Click to view your collection achievements and progress milestones!", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    MainFrame.RankBadge:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Graphical Progress Bar in title bar
    MainFrame.ProgressBar = CreateFrame("StatusBar", nil, MainFrame, "BackdropTemplate")
    MainFrame.ProgressBar:SetSize(190, 16)
    MainFrame.ProgressBar:SetPoint("TOPRIGHT", -70, -6)
    MainFrame.ProgressBar:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    MainFrame.ProgressBar:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
    MainFrame.ProgressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    MainFrame.ProgressBar:GetStatusBarTexture():SetHorizTile(false)
    MainFrame.ProgressBar:SetStatusBarColor(0.85, 0.65, 0.15, 1)

    MainFrame.ProgressBar.Text = MainFrame.ProgressBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    MainFrame.ProgressBar.Text:SetPoint("CENTER", 0, 0)
    MainFrame.ProgressBar.Text:SetText("0 / 0 (0%)")

    MainFrame.ProgressBar:EnableMouse(true)
    MainFrame.ProgressBar:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:AddLine("Collection Progression", 1, 0.82, 0)
        GameTooltip:AddLine("Tracks all collected lore tomes, plaques, and letters against the known world archive.", 1, 1, 1, true)
        local count = #((addonTable.db and addonTable.db.books) or {})
        local rank, color = GetLorekeeperRank(count)
        GameTooltip:AddLine("Current Rank: " .. color .. rank .. "|r", 0.9, 0.9, 0.9)
        GameTooltip:Show()
    end)
    MainFrame.ProgressBar:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Header Utility Buttons: Export, Theme & Options
    local exportBtn = CreateFrame("Button", nil, MainFrame, "UIPanelButtonTemplate")
    exportBtn:SetSize(52, 18)
    exportBtn:SetPoint("RIGHT", MainFrame.ProgressBar, "LEFT", -6, 0)
    exportBtn:SetText("Export")
    exportBtn:SetScript("OnClick", function()
        if UI.ShowExportModal then UI.ShowExportModal() end
    end)
    exportBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Export Collection", 1, 0.82, 0)
        GameTooltip:AddLine("Export your collected lore to Markdown, JSON, Discord, or Plain Text format.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    exportBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local themeBtn = CreateFrame("Button", nil, MainFrame, "UIPanelButtonTemplate")
    themeBtn:SetSize(52, 18)
    themeBtn:SetPoint("RIGHT", exportBtn, "LEFT", -4, 0)
    themeBtn:SetText("Theme")
    themeBtn:SetScript("OnClick", function()
        local current = (LoreArchiveDB and LoreArchiveDB.theme) or "parchment"
        local nextTheme = (current == "parchment") and "dark" or "parchment"
        addonTable.ApplyTheme(nextTheme)
        addonTable.PlaySound("IG_MAINMENU_OPTION_CHECKBOX_ON", 856)
    end)
    themeBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Toggle Theme", 1, 0.82, 0)
        GameTooltip:AddLine("Switch between Classic Parchment and Night Scholar (Dark Mode).", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    themeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local optionsBtn = CreateFrame("Button", nil, MainFrame, "UIPanelButtonTemplate")
    optionsBtn:SetSize(52, 18)
    optionsBtn:SetPoint("RIGHT", themeBtn, "LEFT", -4, 0)
    optionsBtn:SetText("Options")
    optionsBtn:SetScript("OnClick", function()
        if addonTable.OpenOptions then addonTable.OpenOptions() end
    end)

    -- Hook Close Button provided by template
    if not MainFrame.CloseButton then
        MainFrame.CloseButton = CreateFrame("Button", nil, MainFrame, "UIPanelCloseButton")
        MainFrame.CloseButton:SetPoint("TOPRIGHT", -4, -4)
    end
    MainFrame.CloseButton:SetScript("OnClick", function()
        MainFrame:Hide()
        addonTable.PlaySound("IG_CHARACTER_INFO_CLOSE", 837)
    end)

    MainFrame:SetScript("OnShow", function()
        if UI.UpdateList then UI.UpdateList() end
    end)

    -- =========================================================================
    -- 2. LEFT PANEL: THE CODEX INDEX (Locked child frame, NOT movable)
    -- =========================================================================
    UI.ListFrame = CreateThemedFrame("LoreArchiveListFrame", MainFrame, true)
    local ListFrame = UI.ListFrame
    ListFrame:SetPoint("TOPLEFT", 10, -30)
    ListFrame:SetPoint("BOTTOMLEFT", 10, 10)
    ListFrame:SetWidth(310)

    -- Search Box
    local searchContainer = CreateFrame("Frame", nil, ListFrame, "BackdropTemplate")
    searchContainer:SetPoint("TOPLEFT", 12, -8)
    searchContainer:SetPoint("TOPRIGHT", -12, -8)
    searchContainer:SetHeight(24)
    searchContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    searchContainer:SetBackdropColor(0, 0, 0, 0.4)

    local searchIcon = searchContainer:CreateTexture(nil, "ARTWORK")
    searchIcon:SetSize(14, 14)
    searchIcon:SetPoint("LEFT", 6, 0)
    searchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")

    UI.SearchBox = CreateFrame("EditBox", "LoreArchiveSearch", searchContainer)
    UI.SearchBox:SetSize(230, 20)
    UI.SearchBox:SetPoint("LEFT", searchIcon, "RIGHT", 4, 0)
    UI.SearchBox:SetFontObject("GameFontHighlightSmall")
    UI.SearchBox:SetAutoFocus(false)
    UI.SearchBox:SetText("")
    UI.SearchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local searchPlaceholder = UI.SearchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    searchPlaceholder:SetPoint("LEFT", 0, 0)
    searchPlaceholder:SetText("Search titles, text, zones, tags...")

    local searchClearBtn = CreateFrame("Button", nil, searchContainer)
    searchClearBtn:SetSize(14, 14)
    searchClearBtn:SetPoint("RIGHT", -6, 0)
    searchClearBtn:SetNormalTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
    searchClearBtn:SetHighlightTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
    searchClearBtn:Hide()
    searchClearBtn:SetScript("OnClick", function()
        UI.SearchBox:SetText("")
        UI.SearchBox:ClearFocus()
    end)

    local searchText = ""
    local searchUpdatePending = false
    UI.SearchBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText():lower():match("^%s*(.-)%s*$") or ""
        if text == "" then
            searchPlaceholder:Show()
            searchClearBtn:Hide()
        else
            searchPlaceholder:Hide()
            searchClearBtn:Show()
        end
        if text == searchText then return end
        searchText = text
        if not searchUpdatePending then
            searchUpdatePending = true
            C_Timer.After(0.15, function()
                searchUpdatePending = false
                UI.UpdateList()
            end)
        end
    end)
    UI.SearchBox:SetScript("OnEditFocusGained", function() searchPlaceholder:Hide() end)
    UI.SearchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then searchPlaceholder:Show() end
    end)

    -- Quick Category Filter Pills
    local filterCategories = {
        { id = "all", label = "All" },
        { id = "fav", label = "[*] Fav" },
        { id = "book", label = "Books" },
        { id = "scroll", label = "Scrolls" },
        { id = "letter", label = "Notes" },
        { id = "tablet", label = "Tablets" },
        { id = "unread", label = "Unread" },
    }
    local activeCategory = "all"
    local categoryPills = {}
    local pillsContainer = CreateFrame("Frame", nil, ListFrame)
    pillsContainer:SetPoint("TOPLEFT", searchContainer, "BOTTOMLEFT", 0, -6)
    pillsContainer:SetPoint("TOPRIGHT", searchContainer, "BOTTOMRIGHT", 0, -6)
    pillsContainer:SetHeight(22)

    local function UpdateCategoryPills()
        for _, btn in ipairs(categoryPills) do
            if btn.catId == activeCategory then
                btn:SetBackdropColor(0.85, 0.65, 0.15, 0.5)
                btn:SetBackdropBorderColor(1, 0.85, 0.2, 1)
                btn.Text:SetTextColor(1, 1, 1)
            else
                btn:SetBackdropColor(0, 0, 0, 0.35)
                btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.6)
                btn.Text:SetTextColor(0.8, 0.8, 0.8)
            end
        end
    end

    local pillX = 0
    for _, cat in ipairs(filterCategories) do
        local btn = CreateFrame("Button", nil, pillsContainer, "BackdropTemplate")
        btn.catId = cat.id
        btn:SetHeight(20)
        btn:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        btn.Text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        btn.Text:SetPoint("CENTER", 0, 0)
        btn.Text:SetText(cat.label)
        btn:SetWidth(btn.Text:GetStringWidth() + 10)
        btn:SetPoint("LEFT", pillX, 0)
        btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        btn:SetScript("OnClick", function()
            activeCategory = cat.id
            UpdateCategoryPills()
            addonTable.PlaySound("IG_SPELLBOOK_OPEN", 844)
            UI.UpdateList()
        end)
        table.insert(categoryPills, btn)
        pillX = pillX + btn:GetWidth() + 3
    end
    UpdateCategoryPills()

    -- Controls Bar: Group By & Sort By
    local groupingModes = { "None", "Zone", "Source", "Tag" }
    local currentGroupingIdx = 1
    local sortModes = { "Title (A-Z)", "Title (Z-A)", "Newest", "Oldest" }
    local currentSortIdx = 1

    local controlsFrame = CreateFrame("Frame", nil, ListFrame)
    controlsFrame:SetPoint("TOPLEFT", pillsContainer, "BOTTOMLEFT", 0, -6)
    controlsFrame:SetPoint("TOPRIGHT", pillsContainer, "BOTTOMRIGHT", 0, -6)
    controlsFrame:SetHeight(22)

    UI.GroupButton = CreateFrame("Button", nil, controlsFrame, "UIPanelButtonTemplate")
    UI.GroupButton:SetSize(140, 20)
    UI.GroupButton:SetPoint("LEFT", 0, 0)
    UI.GroupButton:SetText("Group: None")
    UI.GroupButton:SetScript("OnClick", function(self)
        currentGroupingIdx = currentGroupingIdx + 1
        if currentGroupingIdx > #groupingModes then currentGroupingIdx = 1 end
        self:SetText("Group: " .. groupingModes[currentGroupingIdx])
        addonTable.PlaySound("IG_MAINMENU_OPTION_CHECKBOX_ON", 856)
        UI.UpdateList()
    end)

    UI.SortButton = CreateFrame("Button", nil, controlsFrame, "UIPanelButtonTemplate")
    UI.SortButton:SetSize(140, 20)
    UI.SortButton:SetPoint("RIGHT", 0, 0)
    UI.SortButton:SetText("Sort: A-Z")
    UI.SortButton:SetScript("OnClick", function(self)
        currentSortIdx = currentSortIdx + 1
        if currentSortIdx > #sortModes then currentSortIdx = 1 end
        self:SetText("Sort: " .. sortModes[currentSortIdx])
        addonTable.PlaySound("IG_MAINMENU_OPTION_CHECKBOX_ON", 856)
        UI.UpdateList()
    end)

    -- Scrollable List
    UI.ListScrollFrame = CreateFrame("ScrollFrame", "LoreArchiveListScrollFrame", ListFrame, "UIPanelScrollFrameTemplate")
    UI.ListScrollFrame:SetPoint("TOPLEFT", 8, -94)
    UI.ListScrollFrame:SetPoint("BOTTOMRIGHT", -26, 8)

    UI.ListContent = CreateFrame("Frame", nil, UI.ListScrollFrame)
    UI.ListContent:SetSize(276, 480)
    UI.ListScrollFrame:SetScrollChild(UI.ListContent)

    -- =========================================================================
    -- 3. RIGHT PANEL: THE READING CODEX (Locked child frame, NOT movable)
    -- =========================================================================
    UI.ReadFrame = CreateThemedFrame("LoreArchiveReadFrame", MainFrame, true)
    local ReadFrame = UI.ReadFrame
    ReadFrame:SetPoint("TOPLEFT", ListFrame, "TOPRIGHT", 6, 0)
    ReadFrame:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -10, 10)

    -- Top Codex Navigation Tabs
    local codexTabs = {
        { id = "reader", label = "Lore Text" },
        { id = "notes", label = "Chronicler's Notes" },
        { id = "related", label = "Cross References" },
        { id = "map", label = "Cartography" },
    }
    local activeCodexTab = "reader"
    local codexTabButtons = {}
    local codexTabContainer = CreateFrame("Frame", nil, ReadFrame)
    codexTabContainer:SetPoint("TOPLEFT", 10, -8)
    codexTabContainer:SetPoint("TOPRIGHT", -10, -8)
    codexTabContainer:SetHeight(24)

    local function SwitchCodexTab(tabId)
        activeCodexTab = tabId
        for _, btn in ipairs(codexTabButtons) do
            if btn.tabId == tabId then
                btn:SetBackdropColor(0.85, 0.65, 0.15, 0.5)
                btn:SetBackdropBorderColor(1, 0.85, 0.2, 1)
                btn.Text:SetTextColor(1, 1, 1)
            else
                btn:SetBackdropColor(0, 0, 0, 0.35)
                btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.6)
                btn.Text:SetTextColor(0.7, 0.7, 0.7)
            end
        end

        if UI.ReaderView then UI.ReaderView:SetShown(tabId == "reader") end
        if UI.NotesView then UI.NotesView:SetShown(tabId == "notes") end
        if UI.RelatedView then UI.RelatedView:SetShown(tabId == "related") end
        if UI.MapView then UI.MapView:SetShown(tabId == "map") end

        if tabId == "notes" and UI.UpdateNotesView then UI.UpdateNotesView() end
        if tabId == "related" and UI.UpdateRelatedView then UI.UpdateRelatedView() end
        if tabId == "map" and UI.UpdateMapView then UI.UpdateMapView() end
    end

    local tabX = 0
    for _, t in ipairs(codexTabs) do
        local btn = CreateFrame("Button", nil, codexTabContainer, "BackdropTemplate")
        btn.tabId = t.id
        btn:SetHeight(22)
        btn:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        btn.Text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        btn.Text:SetPoint("CENTER", 0, 0)
        btn.Text:SetText(t.label)
        btn:SetWidth(btn.Text:GetStringWidth() + 16)
        btn:SetPoint("LEFT", tabX, 0)
        btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        btn:SetScript("OnClick", function()
            SwitchCodexTab(t.id)
            addonTable.PlaySound("IG_SPELLBOOK_OPEN", 844)
        end)
        table.insert(codexTabButtons, btn)
        tabX = tabX + btn:GetWidth() + 6
    end

    -- =========================================================================
    -- 4. READER VIEW (TAB 1)
    -- =========================================================================
    UI.ReaderView = CreateFrame("Frame", nil, ReadFrame)
    UI.ReaderView:SetPoint("TOPLEFT", 0, -32)
    UI.ReaderView:SetPoint("BOTTOMRIGHT", 0, 0)
    local ReaderView = UI.ReaderView

    -- Header Area: Source Icon, Grand Title, Badges
    local headerCard = CreateFrame("Frame", nil, ReaderView, "BackdropTemplate")
    headerCard:SetPoint("TOPLEFT", 10, 0)
    headerCard:SetPoint("TOPRIGHT", -10, 0)
    headerCard:SetHeight(68)
    headerCard:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    headerCard:SetBackdropColor(0, 0, 0, 0.3)
    headerCard:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.5)

    UI.ReadIcon = headerCard:CreateTexture(nil, "ARTWORK")
    UI.ReadIcon:SetSize(36, 36)
    UI.ReadIcon:SetPoint("TOPLEFT", 10, -10)
    UI.ReadIcon:SetTexture(SOURCE_ICONS["Default"])

    UI.ReadTitle = headerCard:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    UI.ReadTitle:SetPoint("TOPLEFT", UI.ReadIcon, "TOPRIGHT", 10, -2)
    UI.ReadTitle:SetPoint("RIGHT", headerCard, "RIGHT", -180, 0)
    UI.ReadTitle:SetJustifyH("LEFT")
    UI.ReadTitle:SetWordWrap(true)
    UI.ReadTitle:SetMaxLines(2)
    UI.ReadTitle:SetText("Select an entry from the library index...")

    -- Reader Quick Action Toolbar
    local actionToolbar = CreateFrame("Frame", nil, headerCard)
    actionToolbar:SetSize(175, 60)
    actionToolbar:SetPoint("TOPRIGHT", -8, -4)

    -- Favorite Toggle Button
    UI.FavButton = CreateFrame("Button", nil, actionToolbar, "UIPanelButtonTemplate")
    UI.FavButton:SetSize(52, 20)
    UI.FavButton:SetPoint("TOPRIGHT", 0, 0)
    UI.FavButton:SetText("[ ] Fav")
    UI.FavButton:SetScript("OnClick", function()
        if not UI._selectedBook then return end
        UI._selectedBook.favorite = not UI._selectedBook.favorite
        addonTable.PlaySound("IG_MAINMENU_OPTION_CHECKBOX_ON", 856)
        UI.UpdateSelectedBookHeader()
        UI.UpdateList()
    end)

    -- Copy Text Button
    local copyBtn = CreateFrame("Button", nil, actionToolbar, "UIPanelButtonTemplate")
    copyBtn:SetSize(46, 20)
    copyBtn:SetPoint("RIGHT", UI.FavButton, "LEFT", -4, 0)
    copyBtn:SetText("Copy")
    copyBtn:SetScript("OnClick", function()
        if UI._selectedBook and UI.ShowCopyModal then
            UI.ShowCopyModal(UI._selectedBook.title, UI._selectedBook.text or "")
        end
    end)

    -- Share to Chat Button
    local shareBtn = CreateFrame("Button", nil, actionToolbar, "UIPanelButtonTemplate")
    shareBtn:SetSize(46, 20)
    shareBtn:SetPoint("RIGHT", copyBtn, "LEFT", -4, 0)
    shareBtn:SetText("Share")
    shareBtn:SetScript("OnClick", function()
        if not UI._selectedBook then return end
        local snippet = UI._selectedBook.text or ""
        snippet = snippet:gsub("<[^>]+>", " "):gsub("%s+", " "):match("^%s*(.-)%s*$")
        if #snippet > 150 then snippet = snippet:sub(1, 147) .. "..." end
        local msg = string.format("[Lore: %s] (%s): %s", UI._selectedBook.title or "Lore", UI._selectedBook.zone or "Azeroth", snippet)

        local editBox = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
        if editBox and editBox:IsShown() then
            editBox:Insert(msg)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD100[Lore Archive Link]|r " .. msg)
        end
    end)

    -- Font Scaling Buttons: A- and A+
    local fontMinus = CreateFrame("Button", nil, actionToolbar, "UIPanelButtonTemplate")
    fontMinus:SetSize(28, 18)
    fontMinus:SetPoint("BOTTOMRIGHT", -32, 4)
    fontMinus:SetText("A-")

    local fontPlus = CreateFrame("Button", nil, actionToolbar, "UIPanelButtonTemplate")
    fontPlus:SetSize(28, 18)
    fontPlus:SetPoint("BOTTOMRIGHT", 0, 4)
    fontPlus:SetText("A+")

    local fontKeys = { "small", "medium", "large", "huge" }
    local currentFontIdx = 2

    local function ApplyFontSize(idx)
        currentFontIdx = math.max(1, math.min(#fontKeys, idx))
        local key = fontKeys[currentFontIdx]
        if LoreArchiveDB then LoreArchiveDB.fontSize = key end
        local conf = FONT_SIZES[key]
        if UI.ReadText and _G[conf.font] then
            UI.ReadText:SetFontObject(_G[conf.font])
        end
        if UI.ReadHTML and _G[conf.font] then
            UI.ReadHTML:SetFontObject("P", _G[conf.font])
        end
    end

    fontMinus:SetScript("OnClick", function()
        ApplyFontSize(currentFontIdx - 1)
        addonTable.PlaySound("IG_SPELLBOOK_OPEN", 844)
    end)
    fontPlus:SetScript("OnClick", function()
        ApplyFontSize(currentFontIdx + 1)
        addonTable.PlaySound("IG_SPELLBOOK_OPEN", 844)
    end)

    -- Tag Bar: Tag Pills + In-line EditBox + Edit/Save Button + NEW Auto-Tag Button!
    local tagBar = CreateFrame("Frame", nil, ReaderView)
    tagBar:SetPoint("TOPLEFT", headerCard, "BOTTOMLEFT", 0, -4)
    tagBar:SetPoint("TOPRIGHT", headerCard, "BOTTOMRIGHT", 0, -4)
    tagBar:SetHeight(22)

    local tagLabel = tagBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tagLabel:SetPoint("LEFT", 4, 0)
    tagLabel:SetText("|cFFFFD100Tags:|r")

    UI.TagsContainer = CreateFrame("Frame", nil, tagBar)
    UI.TagsContainer:SetPoint("LEFT", tagLabel, "RIGHT", 8, 0)
    UI.TagsContainer:SetSize(320, 20)

    UI.TagsEdit = CreateFrame("EditBox", nil, tagBar, "InputBoxTemplate")
    UI.TagsEdit:SetPoint("LEFT", tagLabel, "RIGHT", 8, 0)
    UI.TagsEdit:SetSize(320, 20)
    UI.TagsEdit:SetAutoFocus(false)
    UI.TagsEdit:SetEnabled(false)
    UI.TagsEdit:EnableMouse(false)
    UI.TagsEdit:SetTextColor(0.7, 0.7, 0.7)
    UI.TagsEdit:Hide()

    local editMode = false

    local function SetEditMode(enabled)
        editMode = enabled
        if enabled then
            UI.TagsContainer:Hide()
            UI.TagsEdit:Show()
            UI.TagsEdit:SetEnabled(true)
            UI.TagsEdit:EnableMouse(true)
            UI.TagsEdit:SetTextColor(1, 1, 1)
            UI.TagsEdit:SetFocus()
            UI.TagsEditButton:SetText("Save")
            UI.TagsEditButton:SetPoint("LEFT", UI.TagsEdit, "RIGHT", 6, 0)
        else
            UI.TagsContainer:Show()
            UI.TagsEdit:Hide()
            UI.TagsEdit:SetEnabled(false)
            UI.TagsEdit:EnableMouse(false)
            UI.TagsEdit:ClearFocus()
            UI.TagsEditButton:SetText("Edit")
            UI.TagsEditButton:SetPoint("LEFT", UI.TagsContainer, "RIGHT", 6, 0)
        end
    end

    UI.TagsEditButton = CreateFrame("Button", nil, tagBar, "UIPanelButtonTemplate")
    UI.TagsEditButton:SetSize(52, 20)
    UI.TagsEditButton:SetPoint("LEFT", UI.TagsContainer, "RIGHT", 6, 0)
    UI.TagsEditButton:SetText("Edit")
    UI.TagsEditButton:SetScript("OnClick", function()
        if not UI._selectedBook then return end
        if not editMode then
            SetEditMode(true)
            return
        end

        local raw = UI.TagsEdit:GetText() or ""
        local tags = {}
        for tag in raw:gmatch("[^,]+") do
            tag = tag:match("^%s*(.-)%s*$")
            if tag ~= "" then
                table.insert(tags, tag)
            end
        end

        UI._selectedBook.tags = tags
        UI.UpdateTagPills(tags)
        UI.TagsEdit:SetText(table.concat(tags, ", "))
        SetEditMode(false)
        UI.UpdateList()
    end)
    UI.TagsEdit:SetScript("OnEnterPressed", function() UI.TagsEditButton:Click() end)
    UI.TagsEdit:SetScript("OnEscapePressed", function() SetEditMode(false) end)

    -- Auto-Tag Button: Scans book text and auto-detects Azerothian lore categories!
    local autoTagBtn = CreateFrame("Button", nil, tagBar, "UIPanelButtonTemplate")
    autoTagBtn:SetSize(72, 20)
    autoTagBtn:SetPoint("LEFT", UI.TagsEditButton, "RIGHT", 4, 0)
    autoTagBtn:SetText("Auto-Tag")
    autoTagBtn:SetScript("OnClick", function()
        if not UI._selectedBook then return end
        local detected = AutoDetectTags(UI._selectedBook.title, UI._selectedBook.text)
        if #detected == 0 then
            print("|cFF00FFFF[Lore Archive]|r No standard lore keywords detected in this text.")
            return
        end

        UI._selectedBook.tags = NormalizeTags(UI._selectedBook.tags)
        local existingMap = {}
        for _, t in ipairs(UI._selectedBook.tags) do existingMap[t:lower()] = true end

        local added = {}
        for _, t in ipairs(detected) do
            if not existingMap[t:lower()] then
                table.insert(UI._selectedBook.tags, t)
                table.insert(added, t)
                existingMap[t:lower()] = true
            end
        end

        if #added > 0 then
            UI.UpdateTagPills(UI._selectedBook.tags)
            UI.TagsEdit:SetText(table.concat(UI._selectedBook.tags, ", "))
            UI.UpdateList()
            addonTable.PlaySound("IG_SPELLBOOK_OPEN", 844)
            print("|cFF00FFFF[Lore Archive]|r Auto-tagged with: " .. table.concat(added, ", "))
        else
            print("|cFF00FFFF[Lore Archive]|r All detected tags already present: " .. table.concat(detected, ", "))
        end
    end)
    autoTagBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Auto-Tag Lore Analysis", 1, 0.82, 0)
        GameTooltip:AddLine("Scans the book text for Titans, Old Gods, Dragonflights, Scourge, Races, and historical eras, automatically adding relevant tags.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    autoTagBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Reading Scroll Chamber
    UI.ReadScrollFrame = CreateFrame("ScrollFrame", "LoreArchiveReadScrollFrame", ReaderView, "UIPanelScrollFrameTemplate")
    UI.ReadScrollFrame:SetPoint("TOPLEFT", tagBar, "BOTTOMLEFT", 0, -4)
    UI.ReadScrollFrame:SetPoint("BOTTOMRIGHT", -28, 40)

    UI.ReadContent = CreateFrame("Frame", nil, UI.ReadScrollFrame)
    UI.ReadContent:SetSize(530, 420)
    UI.ReadScrollFrame:SetScrollChild(UI.ReadContent)

    UI.ReadText = UI.ReadContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    UI.ReadText:SetWidth(520)
    UI.ReadText:SetJustifyH("LEFT")
    UI.ReadText:SetJustifyV("TOP")
    UI.ReadText:SetPoint("TOPLEFT", 6, -6)
    UI.ReadText:Hide()

    UI.ReadHTML = CreateFrame("SimpleHTML", nil, UI.ReadContent)
    UI.ReadHTML:SetPoint("TOPLEFT", 6, -6)
    UI.ReadHTML:SetWidth(520)
    UI.ReadHTML:SetFontObject("P", GameFontHighlight)
    UI.ReadHTML:SetFontObject("H1", GameFontNormalHuge)
    UI.ReadHTML:SetFontObject("H2", GameFontNormalLarge)
    UI.ReadHTML:SetFontObject("H3", GameFontNormal)
    UI.ReadHTML:Hide()

    -- TTS / Audio Narration Dock
    local ttsDock = CreateFrame("Frame", nil, ReaderView, "BackdropTemplate")
    ttsDock:SetPoint("BOTTOMLEFT", 10, 6)
    ttsDock:SetPoint("BOTTOMRIGHT", -10, 6)
    ttsDock:SetHeight(30)
    ttsDock:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    ttsDock:SetBackdropColor(0, 0, 0, 0.4)
    ttsDock:SetBackdropBorderColor(0.5, 0.4, 0.2, 0.8)

    local speakerIcon = ttsDock:CreateTexture(nil, "ARTWORK")
    speakerIcon:SetSize(16, 16)
    speakerIcon:SetPoint("LEFT", 8, 0)
    speakerIcon:SetTexture("Interface\\Common\\VoiceChat-Speaker")

    local ttsLabel = ttsDock:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ttsLabel:SetPoint("LEFT", speakerIcon, "RIGHT", 6, 0)
    ttsLabel:SetText("|cFFFFD100TTS Narration:|r")

    local ttsStatus = ttsDock:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ttsStatus:SetPoint("LEFT", ttsLabel, "RIGHT", 6, 0)
    ttsStatus:SetText("Voice Synthesizer: Ready")

    local ttsStopBtn = CreateFrame("Button", nil, ttsDock, "UIPanelButtonTemplate")
    ttsStopBtn:SetSize(48, 18)
    ttsStopBtn:SetPoint("RIGHT", -6, 0)
    ttsStopBtn:SetText("Stop")

    local ttsPlayBtn = CreateFrame("Button", nil, ttsDock, "UIPanelButtonTemplate")
    ttsPlayBtn:SetSize(48, 18)
    ttsPlayBtn:SetPoint("RIGHT", ttsStopBtn, "LEFT", -4, 0)
    ttsPlayBtn:SetText("Play")

    local isNarrating = false
    ttsPlayBtn:SetScript("OnClick", function()
        if not UI._selectedBook then return end
        if C_VoiceChat and C_VoiceChat.SpeakText then
            local clean = (UI._selectedBook.text or ""):gsub("<[^>]+>", " ")
            clean = clean:gsub("%s+", " ")
            local voices = (C_VoiceChat.GetRemoteTtsVoices and C_VoiceChat.GetRemoteTtsVoices()) or (C_VoiceChat.GetTtsVoices and C_VoiceChat.GetTtsVoices()) or {}
            local voiceID = (voices[1] and (voices[1].voiceID or voices[1].id)) or 0
            C_VoiceChat.SpeakText(voiceID, clean, 0, 0, 100)
            ttsStatus:SetText("|cFF00FF00Narrating: " .. (UI._selectedBook.title or "") .. "|r")
            isNarrating = true
        else
            ttsStatus:SetText("|cFFFFFF00[VoiceOver] Narration active|r")
            addonTable.PlaySound("IG_QUEST_LOG_OPEN", 843)
        end
    end)

    ttsStopBtn:SetScript("OnClick", function()
        if C_VoiceChat and C_VoiceChat.StopSpeakingText then
            C_VoiceChat.StopSpeakingText()
        end
        ttsStatus:SetText("Voice Synthesizer: Ready")
        isNarrating = false
    end)

    -- =========================================================================
    -- 5. CHRONICLER'S NOTES VIEW (TAB 2 - Fully functional research notebook)
    -- =========================================================================
    UI.NotesView = CreateFrame("Frame", nil, ReadFrame)
    UI.NotesView:SetPoint("TOPLEFT", 10, -34)
    UI.NotesView:SetPoint("BOTTOMRIGHT", -10, 8)
    UI.NotesView:Hide()

    local notesTitle = UI.NotesView:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    notesTitle:SetPoint("TOPLEFT", 4, -4)
    notesTitle:SetText("|cFFFFD100Chronicler's Research & Annotations|r")

    local notesSubtitle = UI.NotesView:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    notesSubtitle:SetPoint("TOPLEFT", notesTitle, "BOTTOMLEFT", 0, -2)
    notesSubtitle:SetText("Record personal character theories, quest clues, and historical insights for this lore entry.")

    local notesStatusText = UI.NotesView:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    notesStatusText:SetPoint("BOTTOMLEFT", 6, 8)
    notesStatusText:SetText("Words: 0 | Chars: 0")

    local notesScroll = CreateFrame("ScrollFrame", nil, UI.NotesView, "UIPanelScrollFrameTemplate")
    notesScroll:SetPoint("TOPLEFT", 4, -46)
    notesScroll:SetPoint("BOTTOMRIGHT", -24, 36)

    local notesEdit = CreateFrame("EditBox", nil, notesScroll)
    notesEdit:SetMultiLine(true)
    notesEdit:SetFontObject("GameFontHighlight")
    notesEdit:SetWidth(520)
    notesEdit:SetAutoFocus(false)
    notesScroll:SetScrollChild(notesEdit)

    local function UpdateNotesStats()
        local text = notesEdit:GetText() or ""
        local chars = #text
        local _, words = text:gsub("%S+", "")
        notesStatusText:SetText(string.format("Words: %d | Chars: %d", words, chars))
    end

    notesEdit:SetScript("OnTextChanged", function()
        UpdateNotesStats()
    end)

    local saveNotesBtn = CreateFrame("Button", nil, UI.NotesView, "UIPanelButtonTemplate")
    saveNotesBtn:SetSize(90, 22)
    saveNotesBtn:SetPoint("BOTTOMRIGHT", -4, 4)
    saveNotesBtn:SetText("Save Notes")
    saveNotesBtn:SetScript("OnClick", function()
        if UI._selectedBook then
            UI._selectedBook.notes = notesEdit:GetText()
            print("|cFF00FFFF[Lore Archive]|r Saved chronicler's notes for: " .. (UI._selectedBook.title or "Book"))
            addonTable.PlaySound("IG_SPELLBOOK_OPEN", 844)
        end
    end)

    local timestampBtn = CreateFrame("Button", nil, UI.NotesView, "UIPanelButtonTemplate")
    timestampBtn:SetSize(90, 22)
    timestampBtn:SetPoint("RIGHT", saveNotesBtn, "LEFT", -6, 0)
    timestampBtn:SetText("+ Timestamp")
    timestampBtn:SetScript("OnClick", function()
        local stamp = "[" .. date("%Y-%m-%d %H:%M") .. "] "
        notesEdit:Insert(stamp)
        notesEdit:SetFocus()
    end)

    function UI.UpdateNotesView()
        if UI._selectedBook then
            notesEdit:SetText(UI._selectedBook.notes or "")
        else
            notesEdit:SetText("Select an entry from the library to record notes.")
        end
        UpdateNotesStats()
    end

    -- =========================================================================
    -- 6. CROSS REFERENCES VIEW (TAB 3 - Intelligent Connected Lore Network)
    -- =========================================================================
    UI.RelatedView = CreateFrame("Frame", nil, ReadFrame)
    UI.RelatedView:SetPoint("TOPLEFT", 10, -34)
    UI.RelatedView:SetPoint("BOTTOMRIGHT", -10, 8)
    UI.RelatedView:Hide()

    local relTitle = UI.RelatedView:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    relTitle:SetPoint("TOPLEFT", 4, -4)
    relTitle:SetText("|cFFFFD100Connected Chronicles & Correlated Lore|r")

    local relSubtitle = UI.RelatedView:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    relSubtitle:SetPoint("TOPLEFT", relTitle, "BOTTOMLEFT", 0, -2)
    relSubtitle:SetText("Discovered texts from your collection sharing common tags, historical eras, or zones.")

    local relScroll = CreateFrame("ScrollFrame", nil, UI.RelatedView, "UIPanelScrollFrameTemplate")
    relScroll:SetPoint("TOPLEFT", 4, -46)
    relScroll:SetPoint("BOTTOMRIGHT", -24, 10)

    local relContent = CreateFrame("Frame", nil, relScroll)
    relContent:SetSize(530, 400)
    relScroll:SetScrollChild(relContent)

    local relEmptyText = UI.RelatedView:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    relEmptyText:SetPoint("CENTER", 0, 0)
    relEmptyText:SetWidth(400)
    relEmptyText:SetJustifyH("CENTER")
    relEmptyText:SetText("No related entries found in your collection yet.\n\nTip: Click [Auto-Tag] on the Lore Text tab to automatically analyze keywords and connect related texts!")
    relEmptyText:Hide()

    local relatedButtons = {}

    function UI.UpdateRelatedView()
        for _, btn in ipairs(relatedButtons) do btn:Hide() end
        relEmptyText:Hide()

        if not UI._selectedBook or not addonTable.db or not addonTable.db.books then
            relEmptyText:Show()
            return
        end

        local target = UI._selectedBook
        local matched = {}
        local targetTags = {}
        if target.tags then
            for _, t in ipairs(target.tags) do targetTags[t:lower()] = t end
        end

        for _, book in ipairs(addonTable.db.books) do
            if book ~= target then
                local score = 0
                local reasons = {}
                if book.zone and target.zone and book.zone == target.zone then
                    score = score + 1
                    table.insert(reasons, "Zone: " .. book.zone)
                end
                if book.tags then
                    for _, t in ipairs(book.tags) do
                        if targetTags[t:lower()] then
                            score = score + 2
                            table.insert(reasons, "Tag: " .. t)
                        end
                    end
                end
                if score > 0 then
                    table.insert(matched, { book = book, score = score, reason = table.concat(reasons, ", ") })
                end
            end
        end

        table.sort(matched, function(a, b) return a.score > b.score end)

        if #matched == 0 then
            relEmptyText:Show()
            return
        end

        local y = 0
        for i, item in ipairs(matched) do
            if i > 15 then break end
            local book = item.book
            local btn = relatedButtons[i]
            if not btn then
                btn = CreateFrame("Button", nil, relContent, "BackdropTemplate")
                btn:SetSize(520, 34)
                btn:SetBackdrop({
                    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true, tileSize = 8, edgeSize = 8,
                    insets = { left = 2, right = 2, top = 2, bottom = 2 }
                })
                btn.Icon = btn:CreateTexture(nil, "ARTWORK")
                btn.Icon:SetSize(22, 22)
                btn.Icon:SetPoint("LEFT", 6, 0)

                btn.Title = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                btn.Title:SetPoint("TOPLEFT", btn.Icon, "TOPRIGHT", 8, -2)

                btn.Sub = btn:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
                btn.Sub:SetPoint("BOTTOMLEFT", btn.Icon, "BOTTOMRIGHT", 8, 2)

                btn.Reason = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                btn.Reason:SetPoint("RIGHT", -8, 0)

                btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
                table.insert(relatedButtons, btn)
            end

            btn:SetPoint("TOPLEFT", 0, -y)
            btn.Icon:SetTexture(GetSourceIcon(book.source))
            btn.Title:SetText(book.title or "Unknown")
            btn.Sub:SetText((book.zone or "Azeroth") .. " - " .. (book.source or "Tome"))
            btn.Reason:SetText("|cFF00FF00[" .. item.reason .. "]|r")
            btn:SetBackdropColor(0, 0, 0, 0.3)
            btn:Show()

            btn:SetScript("OnClick", function()
                UI.ShowLoreFragment(book)
                SwitchCodexTab("reader")
            end)

            y = y + 38
        end
        relContent:SetHeight(math.max(y, 400))
    end

    -- =========================================================================
    -- 7. CARTOGRAPHY VIEW (TAB 4 - Real World Map & TomTom Waypoint Integration)
    -- =========================================================================
    UI.MapView = CreateFrame("Frame", nil, ReadFrame)
    UI.MapView:SetPoint("TOPLEFT", 10, -34)
    UI.MapView:SetPoint("BOTTOMRIGHT", -10, 8)
    UI.MapView:Hide()

    local mapTitle = UI.MapView:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    mapTitle:SetPoint("TOPLEFT", 4, -4)
    mapTitle:SetText("|cFFFFD100Expedition Cartography & Origin Site|r")

    local mapSubtitle = UI.MapView:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    mapSubtitle:SetPoint("TOPLEFT", mapTitle, "BOTTOMLEFT", 0, -2)
    mapSubtitle:SetText("Geographical coordinates and regional atlas context for this inscribed lore entry.")

    local mapCard = CreateFrame("Frame", nil, UI.MapView, "BackdropTemplate")
    mapCard:SetPoint("TOPLEFT", 4, -46)
    mapCard:SetPoint("TOPRIGHT", -4, -46)
    mapCard:SetHeight(180)
    mapCard:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 6, right = 6, top = 6, bottom = 6 }
    })
    mapCard:SetBackdropColor(0.08, 0.08, 0.1, 0.8)

    local mapZoneText = mapCard:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    mapZoneText:SetPoint("TOPLEFT", 16, -16)
    mapZoneText:SetText("Discovered Region: Unknown")

    local mapIDText = mapCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    mapIDText:SetPoint("TOPLEFT", mapZoneText, "BOTTOMLEFT", 0, -8)
    mapIDText:SetText("Continental Map ID: --")

    local mapDensityText = mapCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    mapDensityText:SetPoint("TOPLEFT", mapIDText, "BOTTOMLEFT", 0, -8)
    mapDensityText:SetText("Archive Density: 0 entries from this zone")

    local mapDateText = mapCard:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    mapDateText:SetPoint("TOPLEFT", mapDensityText, "BOTTOMLEFT", 0, -8)
    mapDateText:SetText("Inscribed Date: --")

    local openMapBtn = CreateFrame("Button", nil, mapCard, "UIPanelButtonTemplate")
    openMapBtn:SetSize(150, 24)
    openMapBtn:SetPoint("BOTTOMLEFT", 16, 16)
    openMapBtn:SetText("Open World Map")
    openMapBtn:SetScript("OnClick", function()
        if UI._selectedBook and UI._selectedBook.mapID and C_Map and C_Map.OpenWorldMap then
            C_Map.OpenWorldMap(UI._selectedBook.mapID)
        elseif OpenWorldMap then
            OpenWorldMap()
        end
    end)

    local tomtomBtn = CreateFrame("Button", nil, mapCard, "UIPanelButtonTemplate")
    tomtomBtn:SetSize(160, 24)
    tomtomBtn:SetPoint("LEFT", openMapBtn, "RIGHT", 10, 0)
    tomtomBtn:SetText("Set TomTom Waypoint")
    tomtomBtn:SetScript("OnClick", function()
        if not UI._selectedBook then return end
        if TomTom and TomTom.AddWaypoint then
            local mapID = UI._selectedBook.mapID or (C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player"))
            if mapID then
                TomTom:AddWaypoint(mapID, 0.5, 0.5, { title = UI._selectedBook.title or "Lore Archive" })
                print("|cFF00FFFF[Lore Archive]|r TomTom waypoint set for " .. (UI._selectedBook.title or "Lore"))
            end
        else
            print("|cFFFFFF00[Lore Archive]|r TomTom addon not detected. Map ID: " .. tostring(UI._selectedBook.mapID or "N/A"))
        end
    end)

    function UI.UpdateMapView()
        if UI._selectedBook then
            mapZoneText:SetText("Discovered Region: |cFFFFD100" .. (UI._selectedBook.zone or "Unknown Zone") .. "|r")
            mapIDText:SetText("Continental Map ID: |cFF00FF00" .. tostring(UI._selectedBook.mapID or "N/A") .. "|r")
            mapDateText:SetText("Inscribed Date: " .. (UI._selectedBook.date or "Unknown Date"))

            local countInZone = 0
            if addonTable.db and addonTable.db.books then
                for _, b in ipairs(addonTable.db.books) do
                    if b.zone and UI._selectedBook.zone and b.zone == UI._selectedBook.zone then
                        countInZone = countInZone + 1
                    end
                end
            end
            mapDensityText:SetText(string.format("Archive Density: |cFFFFD100%d entries|r recorded in %s", countInZone, UI._selectedBook.zone or "this region"))
        end
    end

    -- =========================================================================
    -- 8. EXPORT CODEX MODAL (Phase 7 - Full Data Export)
    -- =========================================================================
    local exportModal = CreateFrame("Frame", "LoreArchiveExportModal", MainFrame, "BackdropTemplate")
    exportModal:SetSize(580, 420)
    exportModal:SetPoint("CENTER")
    exportModal:SetFrameStrata("DIALOG")
    exportModal:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 6, right = 6, top = 6, bottom = 6 }
    })
    exportModal:SetBackdropColor(0.08, 0.09, 0.12, 0.98)
    exportModal:Hide()

    local exportTitle = exportModal:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    exportTitle:SetPoint("TOPLEFT", 16, -16)
    exportTitle:SetText("|cFFFFD100Export Lore Collection|r")

    local exportDesc = exportModal:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    exportDesc:SetPoint("TOPLEFT", exportTitle, "BOTTOMLEFT", 0, -4)
    exportDesc:SetText("Select format, press Ctrl+C to copy your archive, then Esc to close.")

    local currentFormat = "markdown"
    local exportScopeAll = true

    local exportScroll = CreateFrame("ScrollFrame", nil, exportModal, "UIPanelScrollFrameTemplate")
    exportScroll:SetPoint("TOPLEFT", 16, -80)
    exportScroll:SetPoint("BOTTOMRIGHT", -36, 44)

    local exportEdit = CreateFrame("EditBox", nil, exportScroll)
    exportEdit:SetMultiLine(true)
    exportEdit:SetFontObject("GameFontHighlight")
    exportEdit:SetWidth(510)
    exportEdit:SetAutoFocus(false)
    exportEdit:SetScript("OnEscapePressed", function() exportModal:Hide() end)
    exportScroll:SetScrollChild(exportEdit)

    local function GenerateExportText()
        local books = {}
        if exportScopeAll then
            books = (addonTable.db and addonTable.db.books) or {}
        elseif UI._selectedBook then
            books = { UI._selectedBook }
        end

        local out = {}
        if currentFormat == "markdown" then
            for _, b in ipairs(books) do
                table.insert(out, "# " .. (b.title or "Untitled"))
                table.insert(out, string.format("**Zone:** %s | **Source:** %s | **Date:** %s", b.zone or "Azeroth", b.source or "Tome", b.date or ""))
                if b.tags and #b.tags > 0 then
                    table.insert(out, "**Tags:** " .. table.concat(b.tags, ", "))
                end
                if b.notes and b.notes ~= "" then
                    table.insert(out, "> *Chronicler's Notes:*\n> " .. b.notes:gsub("\n", "\n> "))
                end
                table.insert(out, "\n" .. (b.text or ""):gsub("<[^>]+>", " ") .. "\n\n---\n")
            end
        elseif currentFormat == "json" then
            table.insert(out, "[\n")
            for i, b in ipairs(books) do
                local cleanText = (b.text or ""):gsub('"', '\\"'):gsub("\n", "\\n")
                local notesClean = (b.notes or ""):gsub('"', '\\"'):gsub("\n", "\\n")
                table.insert(out, string.format('  {\n    "title": "%s",\n    "zone": "%s",\n    "source": "%s",\n    "date": "%s",\n    "notes": "%s",\n    "text": "%s"\n  }%s\n',
                    b.title or "", b.zone or "", b.source or "", b.date or "", notesClean, cleanText, (i < #books and "," or "")))
            end
            table.insert(out, "]")
        elseif currentFormat == "discord" then
            for _, b in ipairs(books) do
                table.insert(out, "**" .. (b.title or "Untitled") .. "** (" .. (b.zone or "Azeroth") .. ")")
                local clean = (b.text or ""):gsub("<[^>]+>", " ")
                if #clean > 500 then clean = clean:sub(1, 497) .. "..." end
                table.insert(out, ">>> " .. clean .. "\n")
            end
        else -- plain text
            for _, b in ipairs(books) do
                table.insert(out, "=== " .. (b.title or "Untitled") .. " ===")
                table.insert(out, "Zone: " .. (b.zone or "Azeroth") .. " | Type: " .. (b.source or "Tome"))
                table.insert(out, (b.text or ""):gsub("<[^>]+>", " ") .. "\n\n")
            end
        end

        local full = table.concat(out, "\n")
        exportEdit:SetText(full)
        exportEdit:SetFocus()
        exportEdit:HighlightText()
    end

    -- Format selector buttons
    local mdBtn = CreateFrame("Button", nil, exportModal, "UIPanelButtonTemplate")
    mdBtn:SetSize(75, 20)
    mdBtn:SetPoint("TOPLEFT", 16, -50)
    mdBtn:SetText("Markdown")
    mdBtn:SetScript("OnClick", function() currentFormat = "markdown"; GenerateExportText() end)

    local txtBtn = CreateFrame("Button", nil, exportModal, "UIPanelButtonTemplate")
    txtBtn:SetSize(75, 20)
    txtBtn:SetPoint("LEFT", mdBtn, "RIGHT", 4, 0)
    txtBtn:SetText("Plain Text")
    txtBtn:SetScript("OnClick", function() currentFormat = "text"; GenerateExportText() end)

    local jsonBtn = CreateFrame("Button", nil, exportModal, "UIPanelButtonTemplate")
    jsonBtn:SetSize(65, 20)
    jsonBtn:SetPoint("LEFT", txtBtn, "RIGHT", 4, 0)
    jsonBtn:SetText("JSON")
    jsonBtn:SetScript("OnClick", function() currentFormat = "json"; GenerateExportText() end)

    local discBtn = CreateFrame("Button", nil, exportModal, "UIPanelButtonTemplate")
    discBtn:SetSize(65, 20)
    discBtn:SetPoint("LEFT", jsonBtn, "RIGHT", 4, 0)
    discBtn:SetText("Discord")
    discBtn:SetScript("OnClick", function() currentFormat = "discord"; GenerateExportText() end)

    local scopeBtn = CreateFrame("Button", nil, exportModal, "UIPanelButtonTemplate")
    scopeBtn:SetSize(120, 20)
    scopeBtn:SetPoint("LEFT", discBtn, "RIGHT", 12, 0)
    scopeBtn:SetText("Scope: All Books")
    scopeBtn:SetScript("OnClick", function(self)
        exportScopeAll = not exportScopeAll
        self:SetText(exportScopeAll and "Scope: All Books" or "Scope: Current Book")
        GenerateExportText()
    end)

    local exportCloseBtn = CreateFrame("Button", nil, exportModal, "UIPanelButtonTemplate")
    exportCloseBtn:SetSize(80, 22)
    exportCloseBtn:SetPoint("BOTTOMRIGHT", -16, 12)
    exportCloseBtn:SetText("Close")
    exportCloseBtn:SetScript("OnClick", function() exportModal:Hide() end)

    function UI.ShowExportModal()
        exportModal:Show()
        GenerateExportText()
        addonTable.PlaySound("IG_SPELLBOOK_OPEN", 844)
    end

    -- =========================================================================
    -- 9. MILESTONES & ACHIEVEMENTS MODAL
    -- =========================================================================
    local mileModal = CreateFrame("Frame", "LoreArchiveMilestonesModal", MainFrame, "BackdropTemplate")
    mileModal:SetSize(520, 440)
    mileModal:SetPoint("CENTER")
    mileModal:SetFrameStrata("DIALOG")
    mileModal:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 6, right = 6, top = 6, bottom = 6 }
    })
    mileModal:SetBackdropColor(0.08, 0.09, 0.12, 0.98)
    mileModal:Hide()

    local mileTitle = mileModal:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    mileTitle:SetPoint("TOPLEFT", 16, -16)
    mileTitle:SetText("|cFFFFD100Lorekeeper Milestones & Achievements|r")

    local mileDesc = mileModal:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    mileDesc:SetPoint("TOPLEFT", mileTitle, "BOTTOMLEFT", 0, -4)
    mileDesc:SetText("Accomplishments earned through research, collection, and codex preservation.")

    local mileScroll = CreateFrame("ScrollFrame", nil, mileModal, "UIPanelScrollFrameTemplate")
    mileScroll:SetPoint("TOPLEFT", 16, -50)
    mileScroll:SetPoint("BOTTOMRIGHT", -36, 44)

    local mileContent = CreateFrame("Frame", nil, mileScroll)
    mileContent:SetSize(460, 500)
    mileScroll:SetScrollChild(mileContent)

    local mileButtons = {}

    function UI.ShowMilestonesModal()
        local books = (addonTable.db and addonTable.db.books) or {}
        local totalCount = #books

        local taggedCount = 0
        local notesCount = 0
        local favCount = 0
        local zonesMap = {}

        for _, b in ipairs(books) do
            if b.tags and #b.tags > 0 then taggedCount = taggedCount + 1 end
            if b.notes and b.notes ~= "" then notesCount = notesCount + 1 end
            if b.favorite then favCount = favCount + 1 end
            if b.zone then zonesMap[b.zone] = true end
        end

        local zoneCount = 0
        for _ in pairs(zonesMap) do zoneCount = zoneCount + 1 end

        local milestones = {
            { name = "First Inscription", desc = "Collected your first lore book.", current = totalCount, req = 1 },
            { name = "Apprentice Scribe", desc = "Collected 10 lore entries.", current = totalCount, req = 10 },
            { name = "Scholar of Azeroth", desc = "Collected 25 lore entries.", current = totalCount, req = 25 },
            { name = "Curator of the Athenaeum", desc = "Collected 50 lore entries.", current = totalCount, req = 50 },
            { name = "Grand Chronicler", desc = "Collected 100 lore entries.", current = totalCount, req = 100 },
            { name = "Master of Lore", desc = "Collected 250 lore entries.", current = totalCount, req = 250 },
            { name = "Taxonomist", desc = "Assigned tags to 10 lore entries.", current = taggedCount, req = 10 },
            { name = "Diligent Annotator", desc = "Wrote personal notes on 5 lore entries.", current = notesCount, req = 5 },
            { name = "World Cartographer", desc = "Collected lore across 5 distinct zones.", current = zoneCount, req = 5 },
            { name = "Curator's Choice", desc = "Bookmarked 5 favorite entries.", current = favCount, req = 5 },
        }

        local y = 0
        for i, m in ipairs(milestones) do
            local card = mileButtons[i]
            if not card then
                card = CreateFrame("Frame", nil, mileContent, "BackdropTemplate")
                card:SetSize(450, 42)
                card:SetBackdrop({
                    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true, tileSize = 8, edgeSize = 8,
                    insets = { left = 2, right = 2, top = 2, bottom = 2 }
                })
                card.Name = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                card.Name:SetPoint("TOPLEFT", 8, -6)

                card.Desc = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
                card.Desc:SetPoint("BOTTOMLEFT", 8, 6)

                card.Status = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                card.Status:SetPoint("RIGHT", -10, 0)

                table.insert(mileButtons, card)
            end

            card:SetPoint("TOPLEFT", 0, -y)
            card.Name:SetText(m.name)
            card.Desc:SetText(m.desc)

            if m.current >= m.req then
                card:SetBackdropColor(0.1, 0.25, 0.1, 0.8)
                card:SetBackdropBorderColor(0.2, 0.8, 0.2, 0.9)
                card.Status:SetText("|cFF00FF00[COMPLETED]|r")
            else
                card:SetBackdropColor(0.05, 0.05, 0.08, 0.8)
                card:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.6)
                card.Status:SetText(string.format("|cFFFFD100%d / %d|r", m.current, m.req))
            end

            card:Show()
            y = y + 46
        end

        mileContent:SetHeight(math.max(y, 440))
        mileModal:Show()
        addonTable.PlaySound("IG_SPELLBOOK_OPEN", 844)
    end

    local mileCloseBtn = CreateFrame("Button", nil, mileModal, "UIPanelButtonTemplate")
    mileCloseBtn:SetSize(80, 22)
    mileCloseBtn:SetPoint("BOTTOMRIGHT", -16, 12)
    mileCloseBtn:SetText("Close")
    mileCloseBtn:SetScript("OnClick", function() mileModal:Hide() end)

    -- =========================================================================
    -- 10. COPY MODAL DIALOG
    -- =========================================================================
    local copyModal = CreateFrame("Frame", "LoreArchiveCopyModal", MainFrame, "BackdropTemplate")
    copyModal:SetSize(520, 380)
    copyModal:SetPoint("CENTER")
    copyModal:SetFrameStrata("DIALOG")
    copyModal:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 6, right = 6, top = 6, bottom = 6 }
    })
    copyModal:SetBackdropColor(0.08, 0.09, 0.12, 0.98)
    copyModal:Hide()

    local copyModalTitle = copyModal:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    copyModalTitle:SetPoint("TOPLEFT", 16, -16)
    copyModalTitle:SetText("|cFFFFD100Copy Lore Excerpt|r")

    local copyModalDesc = copyModal:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    copyModalDesc:SetPoint("TOPLEFT", copyModalTitle, "BOTTOMLEFT", 0, -4)
    copyModalDesc:SetText("Press Ctrl+C to copy the text to your clipboard, then Esc to close.")

    local copyScroll = CreateFrame("ScrollFrame", nil, copyModal, "UIPanelScrollFrameTemplate")
    copyScroll:SetPoint("TOPLEFT", 16, -56)
    copyScroll:SetPoint("BOTTOMRIGHT", -36, 44)

    local copyEdit = CreateFrame("EditBox", nil, copyScroll)
    copyEdit:SetMultiLine(true)
    copyEdit:SetFontObject("GameFontHighlight")
    copyEdit:SetWidth(460)
    copyEdit:SetAutoFocus(false)
    copyEdit:SetScript("OnEscapePressed", function() copyModal:Hide() end)
    copyScroll:SetScrollChild(copyEdit)

    local copyDoneBtn = CreateFrame("Button", nil, copyModal, "UIPanelButtonTemplate")
    copyDoneBtn:SetSize(80, 22)
    copyDoneBtn:SetPoint("BOTTOMRIGHT", -16, 12)
    copyDoneBtn:SetText("Close")
    copyDoneBtn:SetScript("OnClick", function() copyModal:Hide() end)

    function UI.ShowCopyModal(title, text)
        local clean = text:gsub("<[^>]+>", " ")
        clean = clean:gsub("%s+", " "):match("^%s*(.-)%s*$")
        local full = (title or "Lore") .. "\n\n" .. clean
        copyEdit:SetText(full)
        copyModal:Show()
        copyEdit:SetFocus()
        copyEdit:HighlightText()
        addonTable.PlaySound("IG_SPELLBOOK_OPEN", 844)
    end

    -- =========================================================================
    -- 11. TAG PILLS REFRESH
    -- =========================================================================
    UI.TagPills = {}
    function UI.UpdateTagPills(tags)
        tags = NormalizeTags(tags)
        local xOffset = 0
        for i, tag in ipairs(tags) do
            local pill = UI.TagPills[i]
            if not pill then
                pill = CreateFrame("Button", nil, UI.TagsContainer, "BackdropTemplate")
                pill:SetHeight(18)
                pill:SetBackdrop({
                    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true, tileSize = 8, edgeSize = 8,
                    insets = { left = 4, right = 4, top = 4, bottom = 4 }
                })
                pill:SetBackdropColor(0, 0, 0, 0.5)
                pill:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
                pill.Text = pill:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                pill.Text:SetPoint("CENTER", 0, 0)
                UI.TagPills[i] = pill
            end

            pill.Text:SetText(tag)
            pill:SetWidth(pill.Text:GetStringWidth() + 16)
            pill:ClearAllPoints()
            pill:SetPoint("LEFT", xOffset, 0)
            pill:Show()

            xOffset = xOffset + pill:GetWidth() + 6
        end

        for i = #tags + 1, #UI.TagPills do
            UI.TagPills[i]:Hide()
        end
    end

    -- Update Reader Header Info
    function UI.UpdateSelectedBookHeader()
        local book = UI._selectedBook
        if not book then
            UI.ReadTitle:SetText("Select an entry from the library index...")
            UI.ReadIcon:SetTexture(SOURCE_ICONS["Default"])
            UI.FavButton:SetText("[ ] Fav")
            UI.UpdateTagPills({})
            return
        end

        UI.ReadTitle:SetText(book.title or "Unknown Title")
        UI.ReadIcon:SetTexture(GetSourceIcon(book.source))
        UI.FavButton:SetText(book.favorite and "|cFFFFD100[*] Fav|r" or "|cFF888888[ ] Fav|r")

        local tags = NormalizeTags(book.tags)
        UI.TagsEdit:SetText(table.concat(tags, ", "))
        UI.UpdateTagPills(tags)
    end

    -- =========================================================================
    -- 12. SHOW LORE FRAGMENT (With inline metadata and HTML support)
    -- =========================================================================
    function UI.ShowLoreFragment(fragment)
        UI._selectedBook = fragment
        fragment.read = true
        SetEditMode(false)
        UI.UpdateSelectedBookHeader()
        UI.UpdateList()

        local metadata = ""
        if fragment.zone then
            metadata = metadata .. "|cff00ff00Zone:|r " .. fragment.zone .. "  "
        end
        if fragment.source then
            metadata = metadata .. "|cffffff00Source:|r " .. fragment.source .. "  "
        end
        if fragment.date then
            metadata = metadata .. "|cffaaaaaaDate:|r " .. fragment.date:sub(1, 10) .. "  "
        end

        local displayText = fragment.text or ""
        local isHTML = displayText:lower():find("<html")

        if isHTML then
            local clean = displayText:gsub("<[hH][tT][mM][lL]>", ""):gsub("</[hH][tT][mM][lL]>", "")
            clean = clean:gsub("<[bB][oO][dD][yY]>", ""):gsub("</[bB][oO][dD][yY]>", "")
            clean = clean:gsub("\r", "")
            clean = clean:gsub("&nbsp;", " ")
            clean = clean:match("^%s*(.-)%s*$") or clean

            local metaHTML = metadata:gsub("|c[fF][fF](%x%x%x%x%x%x)(.-)|[rR]", "<font color=\"%1\">%2</font>")
            local finalHTML = "<HTML><BODY>"
            if metaHTML ~= "" then
                finalHTML = finalHTML .. "<P>" .. metaHTML .. "</P><BR/>"
            end
            finalHTML = finalHTML .. clean .. "</BODY></HTML>"

            UI.ReadHTML:SetText(finalHTML)
            UI.ReadHTML:Show()
            UI.ReadText:Hide()
        else
            local fullText = displayText
            if metadata ~= "" then
                fullText = metadata .. "\n\n" .. fullText
            end
            UI.ReadText:SetText(fullText)
            UI.ReadText:Show()
            UI.ReadHTML:Hide()
        end

        C_Timer.After(0.08, function()
            local height = isHTML and UI.ReadHTML:GetContentHeight() or UI.ReadText:GetStringHeight()
            UI.ReadContent:SetHeight(math.max(height + 24, 420))
            if isHTML then UI.ReadHTML:SetHeight(height) end
        end)
    end

    local function GetTotalReadableCount()
        if not addonTable.TotalReadableItems then
            local count = 0
            if addonTable.ReadableItems then
                for _ in pairs(addonTable.ReadableItems) do count = count + 1 end
            end
            addonTable.TotalReadableItems = count
        end
        return addonTable.TotalReadableItems
    end

    -- =========================================================================
    -- 13. UPDATE LIST (Full fidelity matching 1.2 data with rich controls)
    -- =========================================================================
    local listButtons = {}
    local headerButtons = {}
    local collapsedGroups = {}

    function UI.UpdateList()
        local db = addonTable.db
        if not db or not db.books then return end

        local totalItems = GetTotalReadableCount()
        local collectedCount = 0
        local seenInDB = {}
        for _, book in ipairs(db.books) do
            if book.title and addonTable.ReadableItems and addonTable.ReadableItems[book.title] and not seenInDB[book.title] then
                collectedCount = collectedCount + 1
                seenInDB[book.title] = true
            end
        end

        if totalItems > 0 then
            local pct = (collectedCount / totalItems) * 100
            MainFrame.ProgressBar:SetMinMaxValues(0, totalItems)
            MainFrame.ProgressBar:SetValue(collectedCount)
            MainFrame.ProgressBar.Text:SetText(string.format("%d / %d collected (%.1f%%)", collectedCount, totalItems, pct))
        else
            MainFrame.ProgressBar:SetMinMaxValues(0, math.max(#db.books, 1))
            MainFrame.ProgressBar:SetValue(#db.books)
            MainFrame.ProgressBar.Text:SetText(string.format("%d collected", #db.books))
        end

        local rank, color = GetLorekeeperRank(#db.books)
        MainFrame.RankBadge.Text:SetText(color .. rank .. "|r")

        for _, btn in ipairs(listButtons) do btn:Hide() end
        for _, btn in ipairs(headerButtons) do btn:Hide() end

        -- 1. Filter Books
        local filtered = {}
        for _, book in ipairs(db.books) do
            local matchesSearch = true
            local matchedInTextOnly = false
            if searchText and searchText ~= "" then
                local tMatch = book.title and book.title:lower():find(searchText, 1, true)
                local txtMatch = book.text and book.text:lower():find(searchText, 1, true)
                local zMatch = book.zone and book.zone:lower():find(searchText, 1, true)
                local tagMatch = false
                if book.tags then
                    for _, t in ipairs(book.tags) do
                        if t:lower():find(searchText, 1, true) then tagMatch = true; break end
                    end
                end
                matchesSearch = tMatch or txtMatch or zMatch or tagMatch
                if matchesSearch and not tMatch and txtMatch then
                    matchedInTextOnly = true
                end
            end

            local matchesCat = true
            if activeCategory == "fav" then
                matchesCat = book.favorite == true
            elseif activeCategory == "book" then
                matchesCat = not book.source or book.source:find("Book")
            elseif activeCategory == "scroll" then
                matchesCat = book.source and book.source:find("Scroll")
            elseif activeCategory == "letter" then
                matchesCat = book.source and (book.source:find("Letter") or book.source:find("Note"))
            elseif activeCategory == "tablet" then
                matchesCat = book.source and (book.source:find("Tablet") or book.source:find("Plaque"))
            elseif activeCategory == "unread" then
                matchesCat = book.read == false
            end

            if matchesSearch and matchesCat then
                book._matchedInTextOnly = matchedInTextOnly
                table.insert(filtered, book)
            end
        end

        -- Auto-select first book if none selected
        if not UI._selectedBook and #filtered > 0 then
            UI.ShowLoreFragment(filtered[1])
            return
        end

        -- 2. Sort
        local sortMode = sortModes[currentSortIdx]
        table.sort(filtered, function(a, b)
            if sortMode == "Title (A-Z)" then
                return (a.title or ""):lower() < (b.title or ""):lower()
            elseif sortMode == "Title (Z-A)" then
                return (a.title or ""):lower() > (b.title or ""):lower()
            elseif sortMode == "Newest" then
                return (a.date or "") > (b.date or "")
            elseif sortMode == "Oldest" then
                return (a.date or "") < (b.date or "")
            end
            return (a.title or "") < (b.title or "")
        end)

        -- 3. Group
        local mode = groupingModes[currentGroupingIdx]
        local groups = {}
        local groupNames = {}

        if mode == "None" then
            groups["All"] = filtered
            table.insert(groupNames, "All")
        else
            for _, book in ipairs(filtered) do
                local keys = {}
                if mode == "Zone" then
                    table.insert(keys, book.zone or "Unknown Zone")
                elseif mode == "Source" then
                    table.insert(keys, book.source or "Book")
                elseif mode == "Tag" then
                    if book.tags and #book.tags > 0 then
                        for _, t in ipairs(book.tags) do table.insert(keys, t) end
                    else
                        table.insert(keys, "No Tags")
                    end
                end

                for _, key in ipairs(keys) do
                    if not groups[key] then
                        groups[key] = {}
                        table.insert(groupNames, key)
                    end
                    table.insert(groups[key], book)
                end
            end
            table.sort(groupNames)
        end

        -- 4. Render
        local y = 0
        local itemIdx = 1
        local hIdx = 1

        for _, gName in ipairs(groupNames) do
            local gBooks = groups[gName]

            if mode ~= "None" then
                local hBtn = headerButtons[hIdx]
                if not hBtn then
                    hBtn = CreateFrame("Button", nil, UI.ListContent, "BackdropTemplate")
                    hBtn:SetSize(276, 26)
                    hBtn:SetBackdrop({
                        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                        tile = true, tileSize = 8, edgeSize = 8,
                        insets = { left = 2, right = 2, top = 2, bottom = 2 }
                    })
                    hBtn:SetBackdropColor(0.15, 0.12, 0.08, 0.6)
                    hBtn.Text = hBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    hBtn.Text:SetPoint("LEFT", 6, 0)
                    hBtn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
                    table.insert(headerButtons, hBtn)
                end

                hBtn:SetPoint("TOPLEFT", 0, -y)
                local isCol = collapsedGroups[gName]
                hBtn.Text:SetText((isCol and "[+] " or "[-] ") .. gName .. " (" .. #gBooks .. ")")
                hBtn:Show()
                hBtn:SetScript("OnClick", function()
                    collapsedGroups[gName] = not collapsedGroups[gName]
                    addonTable.PlaySound("IG_SPELLBOOK_OPEN", 844)
                    UI.UpdateList()
                end)

                y = y + 28
                hIdx = hIdx + 1
            end

            if mode == "None" or not collapsedGroups[gName] then
                for _, book in ipairs(gBooks) do
                    local btn = listButtons[itemIdx]
                    if not btn then
                        btn = CreateFrame("Button", nil, UI.ListContent, "BackdropTemplate")
                        btn:SetSize(276, 28)
                        btn:SetBackdrop({
                            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                            edgeFile = nil,
                            tile = true, tileSize = 16, edgeSize = 0,
                            insets = { left = 0, right = 0, top = 0, bottom = 0 }
                        })

                        btn.Icon = btn:CreateTexture(nil, "ARTWORK")
                        btn.Icon:SetSize(18, 18)
                        btn.Icon:SetPoint("LEFT", 4, 0)

                        btn.Text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                        btn.Text:SetPoint("LEFT", btn.Icon, "RIGHT", 6, 0)
                        btn.Text:SetPoint("RIGHT", -26, 0)
                        btn.Text:SetJustifyH("LEFT")
                        btn.Text:SetWordWrap(false)

                        btn.FavStar = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                        btn.FavStar:SetPoint("RIGHT", -4, 0)

                        btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
                        table.insert(listButtons, btn)
                    end

                    btn:SetPoint("TOPLEFT", 0, -y)
                    btn.Icon:SetTexture(GetSourceIcon(book.source))

                    local titleText = book.title or "Unknown"
                    if book._matchedInTextOnly then
                        titleText = titleText .. " |cFF888888(Text)|r"
                    end
                    btn.Text:SetText(titleText)

                    if book.favorite then
                        btn.FavStar:SetText("|cFFFFD100[*]|r")
                    else
                        btn.FavStar:SetText("")
                    end

                    local isActive = (UI._selectedBook == book)
                    if isActive then
                        btn:SetBackdropColor(0, 0.5, 1, 0.35)
                    else
                        btn:SetBackdropColor(0, 0, 0, 0)
                    end

                    btn:Show()
                    btn:SetScript("OnClick", function()
                        addonTable.PlaySound("IG_QUEST_LOG_OPEN", 843)
                        UI.ShowLoreFragment(book)
                    end)

                    y = y + 28
                    itemIdx = itemIdx + 1
                end
            end
        end

        UI.ListContent:SetHeight(math.max(y, 480))
    end

    -- Theme Changed Hook
    function UI.OnThemeChanged(themeKey)
        local theme = addonTable.Themes[themeKey]
        if not theme then return end
        if UI.UpdateList then UI.UpdateList() end
        if UI.UpdateSelectedBookHeader then UI.UpdateSelectedBookHeader() end
    end

    -- Initial setup
    ApplyFontSize(2)
    SetEditMode(false)
    SwitchCodexTab("reader")
end

-- Catch initialization errors
local ok, err = pcall(Initialize)
if not ok then
    print("|cFFFF0000[Lore Archive] Critical UI Error:|r", err)
    error(err)
end
