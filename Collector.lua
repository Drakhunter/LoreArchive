local addonName, addonTable = ...

local frame = CreateFrame("Frame")
frame:RegisterEvent("ITEM_TEXT_READY")
frame:RegisterEvent("ITEM_TEXT_CLOSED")
-- Depending on exact wow version or event, sometimes lore books trigger different events.
-- ITEM_TEXT_READY is standard for reading readable objects.

local currentLoreTitle = ""
local currentLoreText = ""
local isReadingLore = false

local function GetZoneName(mapID)
    if not mapID then return "Unknown Zone" end
    local mapInfo = C_Map.GetMapInfo(mapID)
    return mapInfo and mapInfo.name or "Unknown Zone"
end

local function GetSourceType(title)
    if not title then return "Unknown" end
    title = title:lower()
    if title:find("scroll") or title:find("schriftrolle") then
        return "Scroll"
    elseif title:find("letter") or title:find("brief") or title:find("note") or title:find("notiz") then
        return "Letter / Note"
    elseif title:find("tablet") or title:find("tafel") or title:find("plaque") or title:find("plakette") then
        return "Tablet / Plaque"
    else
        return "Book" -- Default
    end
end

local function SaveLore(title, text)
    if not title or title == "" or not text or text == "" then return end

    local db = addonTable.db
    if not db then return end

    local existingFragment = false
    -- Check if we already have it
    for _, book in ipairs(db.books) do
        if book.title == title then
            existingFragment = true
            -- If the text we just read is longer, we overwrite.
            if string.len(text) > string.len(book.text) then
                book.text = text
            end
            break
        end
    end

    local mapID = C_Map.GetBestMapForUnit("player")
    local zone = GetZoneName(mapID)
    local source = GetSourceType(title)

    if not existingFragment then
        table.insert(db.books, {
            title = title,
            text = text,
            mapID = mapID,
            zone = zone,
            source = source,
            tags = {}, -- Ready for manual tagging
            date = date("%Y-%m-%d %H:%M:%S")
        })
        print("|cFF00FFFF[Lore Archive]|r Collected new lore: " .. title .. " (" .. zone .. ")")

        -- If UI is open, refresh it
        if addonTable.UI and addonTable.UI.UpdateList then
            addonTable.UI.UpdateList()
        end
    end
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ITEM_TEXT_READY" then
        isReadingLore = true

        -- Sometimes title is empty at first, grab what we can
        local title = ItemTextGetItem() or currentLoreTitle
        if title and title ~= "" then
            currentLoreTitle = title
        end

        local text = ItemTextGetText()
        if text then
            local page = ItemTextGetPage()
            if page == 1 then
                currentLoreText = text
            else
                currentLoreText = currentLoreText .. "\n\n" .. text
            end
        end
    elseif event == "ITEM_TEXT_CLOSED" then
        if isReadingLore then
            -- Fallback if title was never captured
            if currentLoreTitle == "" then
                currentLoreTitle = "Unknown Fragment (" .. date("%Y-%m-%d %H:%M:%S") .. ")"
            end

            SaveLore(currentLoreTitle, currentLoreText)

            -- Reset state
            isReadingLore = false
            currentLoreTitle = ""
            currentLoreText = ""
        end
    end
end)
