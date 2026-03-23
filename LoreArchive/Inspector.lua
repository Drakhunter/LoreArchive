local addonName, addonTable = ...
local UI = addonTable.UI

-- --- Data Inspector (The "Crazy" Debug Window) ---
UI.Inspector = addonTable.CreateThemedFrame("LoreArchiveInspector", UIParent)
local Inspector = UI.Inspector
Inspector:SetSize(450, 450)
Inspector:SetPoint("CENTER", 150, 50)
Inspector:Hide()
Inspector:SetFrameStrata("TOOLTIP") -- Topmost
table.insert(UISpecialFrames, "LoreArchiveInspector")

Inspector.Title = Inspector:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
Inspector.Title:SetPoint("TOP", 0, -18)
Inspector.Title:SetText("|cFF00FFFFData Inspector|r")

-- Close Button
Inspector.CloseButton = CreateFrame("Button", nil, Inspector, "UIPanelCloseButton")
Inspector.CloseButton:SetPoint("TOPRIGHT", -4, -4)
Inspector.CloseButton:SetScript("OnClick", function() Inspector:Hide() end)

-- Scroll Area for data
local iScroll = CreateFrame("ScrollFrame", nil, Inspector, "UIPanelScrollFrameTemplate")
iScroll:SetPoint("TOPLEFT", 20, -50)
iScroll:SetPoint("BOTTOMRIGHT", -35, 20)

local iContent = CreateFrame("EditBox", nil, iScroll)
iContent:SetMultiLine(true)
iContent:SetFontObject("ChatFontNormal")
iContent:SetWidth(380)
iContent:SetAutoFocus(false)
iContent:SetScript("OnEscapePressed", function() Inspector:Hide() end)
iScroll:SetScrollChild(iContent)
Inspector.EditBox = iContent

-- Attempt to find IDs from Target or Mouseover
local function GetIDFromGUID(guid)
    if not guid then return "Unknown" end
    local type, _, _, _, _, id = strsplit("-", guid)
    if id then return id .. " (" .. type .. ")" end
    return guid
end

function UI.ShowInspector()
    local data = {}
    local title = ItemTextGetItem() or "N/A"
    local creator = ItemTextGetCreator() or "N/A"
    local material = ItemTextGetMaterial() or "N/A"
    local page = ItemTextGetPage() or 0
    local hasNext = ItemTextHasNextPage() and "Yes" or "No"
    local text = ItemTextGetText() or ""

    local targetID = GetIDFromGUID(UnitGUID("target"))
    local mouseoverID = GetIDFromGUID(UnitGUID("mouseover"))
    
    -- If it's an item on cursor
    local _, cursorID = GetCursorInfo()
    cursorID = cursorID and tostring(cursorID) or "None"

    local mapID = C_Map.GetBestMapForUnit("player")
    local zone = "Unknown"
    if mapID then
        local info = C_Map.GetMapInfo(mapID)
        if info then zone = info.name end
    end

    local targetName = UnitName("target") or "None"
    local targetGUID = UnitGUID("target") or "None"

    table.insert(data, "=== LORE OBJECT DATA ===")
    table.insert(data, "Title: " .. title)
    table.insert(data, "ID (Target): " .. (targetID or "N/A"))
    table.insert(data, "ID (Mouseover): " .. (mouseoverID or "N/A"))
    table.insert(data, "ID (Cursor Item): " .. cursorID)
    table.insert(data, "Creator: " .. creator)
    table.insert(data, "Material: " .. material)
    table.insert(data, "Current Page: " .. page)
    table.insert(data, "Has Next Page: " .. hasNext)
    table.insert(data, "Text Length: " .. string.len(text))
    table.insert(data, "")
    table.insert(data, "=== PLAYER CONTEXT ===")
    table.insert(data, "MapID: " .. (mapID or "Unknown"))
    table.insert(data, "Zone: " .. zone)
    table.insert(data, "Target Name: " .. targetName)
    table.insert(data, "Target GUID: " .. targetGUID)
    table.insert(data, "")
    table.insert(data, "=== RAW TEXT (PAGE " .. page .. ") ===")
    table.insert(data, text)

    Inspector.EditBox:SetText(table.concat(data, "\n"))
    Inspector:Show()
end
