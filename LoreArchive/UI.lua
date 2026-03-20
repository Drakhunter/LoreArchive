local addonName, addonTable = ...

-- Helper function to create a basic frame with a backdrop
local function CreateThemedFrame(name, parent)
    local frame = CreateFrame("Frame", name, parent, "BackdropTemplate")
    frame:SetBackdrop({
        bgFile = "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 512,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    return frame
end

local UI = {}
addonTable.UI = UI

-- Main Window
UI.MainFrame = CreateThemedFrame("LoreArchiveFrame", UIParent)
tinsert(UISpecialFrames, "LoreArchiveFrame")
local MainFrame = UI.MainFrame
MainFrame:SetSize(800, 600)
MainFrame:SetPoint("CENTER")
MainFrame:SetMovable(true)
MainFrame:EnableMouse(true)
MainFrame:RegisterForDrag("LeftButton")
MainFrame:SetScript("OnDragStart", MainFrame.StartMoving)
MainFrame:SetScript("OnDragStop", MainFrame.StopMovingOrSizing)
MainFrame:Hide()

-- Title
MainFrame.Title = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
MainFrame.Title:SetPoint("TOP", 0, -16)
MainFrame.Title:SetText("Lore Archive")

-- Close Button
MainFrame.CloseButton = CreateFrame("Button", nil, MainFrame, "UIPanelCloseButton")
MainFrame.CloseButton:SetPoint("TOPRIGHT", -4, -4)
MainFrame.CloseButton:SetScript("OnClick", function() MainFrame:Hide() end)

-- Left Panel: List of Books
UI.ListFrame = CreateThemedFrame(nil, MainFrame)
local ListFrame = UI.ListFrame
ListFrame:SetSize(250, 520)
ListFrame:SetPoint("TOPLEFT", 16, -40)

-- Filter & Search Section
local groupingModes = { "None", "Zone", "Source", "Tag" }
local currentGroupingIdx = 1
local searchText = ""
local collapsedGroups = {}
local editMode = false

local function NormalizeTags(tags)
    local out = {}

    if type(tags) == "string" then
        tags = { tags }
    end

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

local function UpdateTagPills(tags)
    tags = NormalizeTags(tags)
    UI.TagPills = UI.TagPills or {}

    local xOffset = 0
    for i, tag in ipairs(tags) do
        local pill = UI.TagPills[i]
        if not pill then
            pill = CreateFrame("Button", nil, UI.TagsContainer, "BackdropTemplate")
            pill:SetHeight(18)
            pill:SetBackdrop({
                bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true,
                tileSize = 8,
                edgeSize = 8,
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

local function SetEditMode(enabled)
    editMode = enabled

    if UI.TagsContainer then
        if enabled then
            UI.TagsContainer:Hide()
        else
            UI.TagsContainer:Show()
        end
    end

    if UI.TagsEdit then
        UI.TagsEdit:SetEnabled(enabled)
        UI.TagsEdit:EnableMouse(enabled)
        if enabled then
            UI.TagsEdit:Show()
            UI.TagsEdit:SetTextColor(1, 1, 1)
            UI.TagsEdit:SetFocus()
        else
            UI.TagsEdit:Hide()
            UI.TagsEdit:SetTextColor(0.7, 0.7, 0.7)
            UI.TagsEdit:ClearFocus()
        end
    end

    if UI.TagsEditButton then
        if enabled then
            UI.TagsEditButton:SetSize(80, 20)
            UI.TagsEditButton:SetText("Save")
            UI.TagsEditButton:SetAlpha(1)
            UI.TagsEditButton:SetPoint("LEFT", UI.TagsEdit, "RIGHT", 10, 0)
        else
            UI.TagsEditButton:SetSize(80, 20)
            UI.TagsEditButton:SetText("Edit")
            UI.TagsEditButton:SetAlpha(0.6)
            UI.TagsEditButton:SetPoint("LEFT", UI.TagsContainer, "RIGHT", 6, 0)
        end
    end
end

UI.SearchBox = CreateFrame("EditBox", "LoreArchiveSearch", ListFrame, "InputBoxTemplate")
UI.SearchBox:SetSize(220, 20)
UI.SearchBox:SetPoint("TOPLEFT", 15, -12)
UI.SearchBox:SetAutoFocus(false)
UI.SearchBox:SetText("")
UI.SearchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
UI.SearchBox:SetScript("OnTextChanged", function(self)
    searchText = self:GetText():lower()
    UI.UpdateList()
end)
local SearchLabel = UI.SearchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
SearchLabel:SetPoint("LEFT", UI.SearchBox, "LEFT", 5, 0)
SearchLabel:SetText("Search...")
UI.SearchBox:SetScript("OnEditFocusGained", function() SearchLabel:Hide() end)
UI.SearchBox:SetScript("OnEditFocusLost", function(self)
    if self:GetText() == "" then SearchLabel:Show() else SearchLabel:Hide() end
end)
UI.ListFrame.searchBox = UI.SearchBox

UI.GroupButton = CreateFrame("Button", nil, ListFrame, "UIPanelButtonTemplate")
UI.GroupButton:SetSize(220, 22)
UI.GroupButton:SetPoint("TOPLEFT", 15, -35)
UI.GroupButton:SetText("Group By: None")
UI.GroupButton:SetScript("OnClick", function(self)
    currentGroupingIdx = currentGroupingIdx + 1
    if currentGroupingIdx > #groupingModes then currentGroupingIdx = 1 end
    local mode = groupingModes[currentGroupingIdx]
    self:SetText("Group By: " .. mode)
    UI.UpdateList()
end)

UI.ListScrollFrame = CreateFrame("ScrollFrame", "LoreArchiveListScrollFrame", ListFrame, "UIPanelScrollFrameTemplate")
UI.ListScrollFrame:SetPoint("TOPLEFT", 12, -65)
UI.ListScrollFrame:SetPoint("BOTTOMRIGHT", -30, 8)

UI.ListContent = CreateFrame("Frame", nil, UI.ListScrollFrame)
UI.ListContent:SetSize(210, 500)
UI.ListScrollFrame:SetScrollChild(UI.ListContent)

-- Right Panel: Reading Area
UI.ReadFrame = CreateThemedFrame(nil, MainFrame)
local ReadFrame = UI.ReadFrame
ReadFrame:SetSize(500, 520)
ReadFrame:SetPoint("TOPRIGHT", -16, -40)

UI.ReadTitle = ReadFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
UI.ReadTitle:SetPoint("TOP", 0, -16)
UI.ReadTitle:SetText("Select a book from the index...")

UI.TagsLabel = ReadFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
UI.TagsLabel:SetPoint("TOPLEFT", 16, -40)
UI.TagsLabel:SetText("Tags:")

UI.TagsContainer = CreateFrame("Frame", nil, ReadFrame)
UI.TagsContainer:SetSize(360, 20)
UI.TagsContainer:SetPoint("TOPLEFT", 16, -60)

UI.TagsEdit = CreateFrame("EditBox", nil, ReadFrame, "InputBoxTemplate")
UI.TagsEdit:SetSize(360, 20)
UI.TagsEdit:SetPoint("TOPLEFT", 16, -60)
UI.TagsEdit:SetAutoFocus(false)
UI.TagsEdit:SetEnabled(false)
UI.TagsEdit:EnableMouse(false)
UI.TagsEdit:SetTextColor(0.7, 0.7, 0.7)
UI.TagsEdit:SetScript("OnEnterPressed", function()
    if UI.TagsEditButton and editMode then
        UI.TagsEditButton:Click()
    end
end)

UI.TagsEditButton = CreateFrame("Button", nil, ReadFrame, "UIPanelButtonTemplate")
UI.TagsEditButton:SetSize(80, 20)
UI.TagsEditButton:SetPoint("LEFT", UI.TagsEdit, "RIGHT", 10, 0)
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

    -- Immediately refresh the tag pills so the UI updates without needing to re-open the note
    UpdateTagPills(tags)
    UI.TagsEdit:SetText(table.concat(tags, ", "))

    SetEditMode(false)
    ShowLoreFragment(UI._selectedBook)
    UI.UpdateList()
end)

-- Ensure we start in view mode with the edit bar hidden
SetEditMode(false)

UI.ReadScrollFrame = CreateFrame("ScrollFrame", "LoreArchiveReadScrollFrame", ReadFrame, "UIPanelScrollFrameTemplate")
UI.ReadScrollFrame:SetPoint("TOPLEFT", 16, -90)
UI.ReadScrollFrame:SetPoint("BOTTOMRIGHT", -30, 16)

UI.ReadContent = CreateFrame("Frame", nil, UI.ReadScrollFrame)
UI.ReadContent:SetSize(450, 460)
UI.ReadScrollFrame:SetScrollChild(UI.ReadContent)

UI.ReadText = UI.ReadContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
UI.ReadText:SetWidth(430)
UI.ReadText:SetJustifyH("LEFT")
UI.ReadText:SetJustifyV("TOP")
UI.ReadText:SetPoint("TOPLEFT", 0, 0)
UI.ReadText:SetText("")

local listButtons = {}
local headerButtons = {}

local function ShowLoreFragment(fragment)
    UI._selectedBook = fragment
    UI.UpdateList()

    SetEditMode(false)
    UI.ReadTitle:SetText(fragment.title or "Unknown Title")

    local tags = NormalizeTags(fragment.tags)
    UI.TagsEdit:SetText(table.concat(tags, ", "))
    UpdateTagPills(tags)

    local metadata = ""
    if fragment.zone then
        metadata = metadata .. "|cFF00FF00Zone:|r " .. fragment.zone .. "  "
    end
    if fragment.source then
        metadata = metadata .. "|cFFFFFF00Source:|r " .. fragment.source .. "  "
    end

    local displayText = fragment.text or ""
    if metadata ~= "" then
        displayText = metadata .. "\n\n" .. displayText
    end

    UI.ReadText:SetText(displayText)

    -- Resize content frame based on text height
    C_Timer.After(0.1, function()
        local height = UI.ReadText:GetStringHeight()
        UI.ReadContent:SetHeight(math.max(height + 20, 460))
    end)
end

function UI.UpdateList()
    local db = addonTable.db
    if not db or not db.books then return end

    -- Hide all buttons
    for _, btn in ipairs(listButtons) do btn:Hide() end
    for _, btn in ipairs(headerButtons) do btn:Hide() end

    local mode = groupingModes[currentGroupingIdx]
    local filteredBooks = {}

    -- 1. Filter and Collect
    for _, book in ipairs(db.books) do
        local titleMatch = not searchText or searchText == "" or (book.title and book.title:lower():find(searchText))
        local textMatch = not searchText or searchText == "" or (book.text and book.text:lower():find(searchText))
        if titleMatch or textMatch then
            table.insert(filteredBooks, book)
        end
    end

    -- 2. Group
    local groups = {}
    local groupNames = {}

    if mode == "None" then
        groups["All"] = filteredBooks
        table.insert(groupNames, "All")
    else
        for _, book in ipairs(filteredBooks) do
            local keys = {}
            if mode == "Zone" then
                table.insert(keys, book.zone or "Unknown Zone")
            elseif mode == "Source" then
                table.insert(keys, book.source or "Unknown Source")
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

    -- 3. Render
    local yOffset = 0
    local bookIdx = 1
    local headerIdx = 1

    for _, groupName in ipairs(groupNames) do
        local groupBooks = groups[groupName]

        -- Header (if grouping is on)
        if mode ~= "None" then
            local hBtn = headerButtons[headerIdx]
            if not hBtn then
                hBtn = CreateFrame("Button", nil, UI.ListContent)
                hBtn:SetSize(210, 26)
                hBtn.Text = hBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                hBtn.Text:SetPoint("LEFT", 4, 0)
                hBtn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
                table.insert(headerButtons, hBtn)
            end

            hBtn:SetPoint("TOPLEFT", 0, -yOffset)
            local isCollapsed = collapsedGroups[groupName]
            hBtn.Text:SetText((isCollapsed and "[+] " or "[-] ") .. groupName .. " (" .. #groupBooks .. ")")
            hBtn:Show()
            hBtn:SetScript("OnClick", function()
                collapsedGroups[groupName] = not collapsedGroups[groupName]
                UI.UpdateList()
            end)

            yOffset = yOffset + 26
            headerIdx = headerIdx + 1
        end

        -- Books
        if mode == "None" or not collapsedGroups[groupName] then
            for _, book in ipairs(groupBooks) do
                local btn = listButtons[bookIdx]
                if not btn then
                    btn = CreateFrame("Button", nil, UI.ListContent, "BackdropTemplate")
                    btn:SetSize(210, 24)
                    btn:SetBackdrop({
                        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                        edgeFile = nil,
                        tile = true,
                        tileSize = 16,
                        edgeSize = 0,
                        insets = { left = 0, right = 0, top = 0, bottom = 0 }
                    })
                    btn.Text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    btn.Text:SetPoint("LEFT", mode == "None" and 6 or 16, 0)
                    btn.Text:SetPoint("RIGHT", -4, 0)
                    btn.Text:SetJustifyH("LEFT")
                    btn.Text:SetWordWrap(false)
                    btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
                    table.insert(listButtons, btn)
                end

                btn:SetPoint("TOPLEFT", 0, -yOffset)
                btn.Text:SetPoint("LEFT", mode == "None" and 6 or 16, 0)
                btn.Text:SetText(book.title)
                btn:Show()
                btn:SetScript("OnClick", function() ShowLoreFragment(book) end)
                local isActive = (UI._selectedBook == book)
                if isActive then
                    btn:SetBackdropColor(0, 0.5, 1, 0.35) -- active
                else
                    btn:SetBackdropColor(0, 0, 0, 0) -- normal
                end

                yOffset = yOffset + 24
                bookIdx = bookIdx + 1
            end
        end
    end

    UI.ListContent:SetHeight(math.max(yOffset, 500))
end

-- Slash Commands
SLASH_LOREARCHIVE1 = "/lore"
SLASH_LOREARCHIVE2 = "/la"
SlashCmdList["LOREARCHIVE"] = function(msg)
    if MainFrame:IsShown() then
        MainFrame:Hide()
    else
        UI.UpdateList()
        MainFrame:Show()
    end
end
