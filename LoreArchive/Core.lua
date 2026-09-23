local addonName, addonTable = ...
_G[addonName] = addonTable
addonTable.UI = {}
addonTable.Inspector = {}
addonTable.ThemedFrames = {}

-- Safe Backdrop Template helper
local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil

-- Sound Helper with safe fallback across client versions
function addonTable.PlaySound(soundName, fallbackID)
    if SOUNDKIT and SOUNDKIT[soundName] then
        pcall(PlaySound, SOUNDKIT[soundName])
    elseif fallbackID then
        pcall(PlaySound, fallbackID)
    end
end

-- Theme Definitions for inner panels
addonTable.Themes = {
    parchment = {
        name = "Classic Parchment",
        panelBg = { 0.16, 0.13, 0.09, 0.90 },
        panelBorder = { 0.75, 0.60, 0.30, 0.9 },
        cardBg = { 0.12, 0.10, 0.07, 0.8 },
        cardBorder = { 0.50, 0.40, 0.20, 0.6 },
    },
    dark = {
        name = "Night Scholar",
        panelBg = { 0.05, 0.06, 0.08, 0.92 },
        panelBorder = { 0.40, 0.45, 0.55, 0.8 },
        cardBg = { 0.03, 0.04, 0.06, 0.8 },
        cardBorder = { 0.30, 0.35, 0.45, 0.6 },
    }
}

-- Apply Theme across all registered frames
function addonTable.ApplyTheme(themeKey)
    local theme = addonTable.Themes[themeKey] or addonTable.Themes.parchment
    if LoreArchiveDB then
        LoreArchiveDB.theme = themeKey
    end

    for _, entry in ipairs(addonTable.ThemedFrames) do
        local frame = entry.frame
        if frame and frame.SetBackdropColor and frame.SetBackdropBorderColor then
            if entry.isPanel then
                frame:SetBackdropColor(unpack(theme.panelBg))
                frame:SetBackdropBorderColor(unpack(theme.panelBorder))
            end
        end
    end

    if addonTable.UI and addonTable.UI.OnThemeChanged then
        addonTable.UI.OnThemeChanged(themeKey)
    end
end

-- Shared UI Helpers: Unified Frame creation
function addonTable.CreateThemedFrame(name, parent, isPanel)
    local frame
    if isPanel then
        -- Child Panels: NOT movable, NOT draggable, permanently anchored to parent
        frame = CreateFrame("Frame", name, parent, BACKDROP_TEMPLATE)
        if BackdropTemplateMixin and not frame.SetBackdrop then
            Mixin(frame, BackdropTemplateMixin)
        end
        frame:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })

        local currentThemeKey = (LoreArchiveDB and LoreArchiveDB.theme) or "parchment"
        local theme = addonTable.Themes[currentThemeKey] or addonTable.Themes.parchment
        frame:SetBackdropColor(unpack(theme.panelBg))
        frame:SetBackdropBorderColor(unpack(theme.panelBorder))

        frame:SetMovable(false)
        frame:EnableMouse(false)

        table.insert(addonTable.ThemedFrames, { frame = frame, isPanel = true })
        return frame
    else
        -- Main Top-Level Windows: Uses Blizzard's authentic native frame template!
        frame = CreateFrame("Frame", name, parent or UIParent, "BasicFrameTemplateWithInset")
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

        table.insert(addonTable.ThemedFrames, { frame = frame, isPanel = false })
        return frame
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        if not LoreArchiveDB then
            LoreArchiveDB = {
                books = {},
                debugMode = false,
                theme = "parchment",
                fontSize = "medium",
            }
        elseif LoreArchiveDB.fragments then
            LoreArchiveDB.books = LoreArchiveDB.books or {}
            for _, fragment in ipairs(LoreArchiveDB.fragments) do
                table.insert(LoreArchiveDB.books, fragment)
            end
            LoreArchiveDB.fragments = nil
        end

        if LoreArchiveDB.debugMode == nil then
            LoreArchiveDB.debugMode = false
        end
        if LoreArchiveDB.theme == nil then
            LoreArchiveDB.theme = "parchment"
        end
        if LoreArchiveDB.fontSize == nil then
            LoreArchiveDB.fontSize = "medium"
        end

        addonTable.db = LoreArchiveDB

        -- Re-apply saved theme on login once DB is ready
        addonTable.ApplyTheme(LoreArchiveDB.theme)

        -- Automatically update UI with recorded data
        if addonTable.UI and addonTable.UI.UpdateList then
            addonTable.UI.UpdateList()
        end

        print("|cFF00FFFF[Lore Archive]|r loaded. Type |cFFFFFF00/lore|r to open your Athenaeum.")
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
