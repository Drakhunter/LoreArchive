local addonName, addonTable = ...
_G[addonName] = addonTable
addonTable.UI = {}
addonTable.Inspector = {}

-- Shared UI Helpers
function addonTable.CreateThemedFrame(name, parent)
    local frame = CreateFrame("Frame", name, parent, "BackdropTemplate")
    frame:SetBackdrop({
        bgFile = "Interface\\ACHIEVEMENTFRAME\\UI-GuildAchievement-Parchment",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 512,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    -- Make all themed windows moveable by default
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    return frame
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        if not LoreArchiveDB then
            LoreArchiveDB = {
                books = {}, -- List of lore books
                debugMode = false, -- Default to off
            }
        elseif LoreArchiveDB.fragments then
            -- Migration: Move fragments to books
            LoreArchiveDB.books = LoreArchiveDB.books or {}
            for _, fragment in ipairs(LoreArchiveDB.fragments) do
                table.insert(LoreArchiveDB.books, fragment)
            end
            LoreArchiveDB.fragments = nil
        end
        
        -- Ensure debugMode exists for returning users
        if LoreArchiveDB.debugMode == nil then
            LoreArchiveDB.debugMode = false
        end

        addonTable.db = LoreArchiveDB
        print("|cFF00FFFF[Lore Archive]|r loaded. Type |cFFFFFF00/lore|r to view your collection.")
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
