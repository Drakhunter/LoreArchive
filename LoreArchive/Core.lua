local addonName, addonTable = ...
_G[addonName] = addonTable

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        if not LoreArchiveDB then
            LoreArchiveDB = {
                books = {}, -- List of lore books
            }
        elseif LoreArchiveDB.fragments then
            -- Migration: Move fragments to books
            LoreArchiveDB.books = LoreArchiveDB.books or {}
            for _, fragment in ipairs(LoreArchiveDB.fragments) do
                table.insert(LoreArchiveDB.books, fragment)
            end
            LoreArchiveDB.fragments = nil
        end
        addonTable.db = LoreArchiveDB
        print("|cFF00FFFF[Lore Archive]|r loaded. Type |cFFFFFF00/lore|r to view your collection.")
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
