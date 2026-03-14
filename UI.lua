local addonName, addonTable = ...

-- Helper function to create a basic frame with a backdrop
local function CreateThemedFrame(name, parent)
    local frame = CreateFrame("Frame", name, parent, "BackdropTemplate")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    return frame
end

local UI = {}
addonTable.UI = UI

-- Main Window
UI.MainFrame = CreateThemedFrame("LoreArchiveFrame", UIParent)
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
local groupingModes = {"None", "Zone", "Source", "Tag"}
local currentGroupingIdx = 1
local searchText = ""
local collapsedGroups = {}

UI.SearchBox = CreateFrame("EditBox", nil, ListFrame, "SearchBoxTemplate")
UI.SearchBox:SetSize(220, 20)
UI.SearchBox:SetPoint("TOPLEFT", 15, -12)
UI.SearchBox:SetScript("OnTextChanged", function(self)
    searchText = self:GetText():lower()
    UI.UpdateList()
end)

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
UI.ListScrollFrame:SetPoint("TOPLEFT", 8, -65)
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

UI.ReadScrollFrame = CreateFrame("ScrollFrame", "LoreArchiveReadScrollFrame", ReadFrame, "UIPanelScrollFrameTemplate")
UI.ReadScrollFrame:SetPoint("TOPLEFT", 16, -40)
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
    UI.ReadTitle:SetText(fragment.title or "Unknown Title")
    
    local metadata = ""
    if fragment.zone then
        metadata = metadata .. "|cFF00FF00Zone:|r " .. fragment.zone .. "  "
    end
    if fragment.source then
        metadata = metadata .. "|cFFFFFF00Source:|r " .. fragment.source .. "  "
    end
    if fragment.tags and #fragment.tags > 0 then
        metadata = metadata .. "|cFF00FFFFTags:|r " .. table.concat(fragment.tags, ", ")
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
            if mode == "Zone" then table.insert(keys, book.zone or "Unknown Zone")
            elseif mode == "Source" then table.insert(keys, book.source or "Unknown Source")
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
                    btn = CreateFrame("Button", nil, UI.ListContent)
                    btn:SetSize(210, 24)
                    btn.Text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    btn.Text:SetPoint("LEFT", mode == "None" and 4 or 16, 0)
                    btn.Text:SetPoint("RIGHT", -4, 0)
                    btn.Text:SetJustifyH("LEFT")
                    btn.Text:SetWordWrap(false)
                    btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
                    table.insert(listButtons, btn)
                end
                
                btn:SetPoint("TOPLEFT", 0, -yOffset)
                btn.Text:SetPoint("LEFT", mode == "None" and 4 or 16, 0)
                btn.Text:SetText(book.title)
                btn:Show()
                btn:SetScript("OnClick", function() ShowLoreFragment(book) end)
                
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
