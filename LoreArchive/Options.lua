local addonName, addonTable = ...

-- Setup the frame as a styled window (in case registration fails and we show it manually)
local f = addonTable.CreateThemedFrame("LoreArchiveOptionsPanel", UIParent)
f.name = "Lore Archive"
f:SetSize(420, 450)
f:SetPoint("CENTER")
f:SetFrameStrata("DIALOG")
f:Hide()
table.insert(UISpecialFrames, "LoreArchiveOptionsPanel")

-- Close Button for manual mode
f.CloseButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
f.CloseButton:SetPoint("TOPRIGHT", -4, -4)
f.CloseButton:SetScript("OnClick", function() f:Hide() end)

local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Lore Archive Options")

local desc = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
desc:SetText("Configure settings for your Lore collection.")

-- Debug Mode Checkbox
local debugCheck = CreateFrame("CheckButton", "LoreArchiveDebugCheck", f, "InterfaceOptionsCheckButtonTemplate")
debugCheck:SetPoint("TOPLEFT", 16, -60)
local checkText = _G[debugCheck:GetName() .. "Text"] or debugCheck.Text
if not checkText then
    checkText = debugCheck:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    checkText:SetPoint("LEFT", debugCheck, "RIGHT", 4, 0)
    debugCheck.Text = checkText
end
checkText:SetText("Enable Data Inspector (Debug)")
debugCheck.tooltipText = "When enabled, opening a lore object will also show a technical Data Inspector window with IDs and raw text."

debugCheck:SetScript("OnShow", function(self)
    self:SetChecked(LoreArchiveDB and LoreArchiveDB.debugMode)
end)

debugCheck:SetScript("OnClick", function(self)
    local checked = self:GetChecked()
    if LoreArchiveDB then
        LoreArchiveDB.debugMode = checked
    end
    print("|cFF00FFFF[Lore Archive]|r Debug Mode is now " .. (checked and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"))
end)

-- Dynamic AddOn version retrieval
local addonVersion = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version"))
    or (GetAddOnMetadata and GetAddOnMetadata(addonName, "Version"))
    or "1.2.0"

-- Help text
local helpText = f:CreateFontString(nil, "OVERLAY", "GameFontDisable")
helpText:SetPoint("BOTTOMLEFT", 16, 16)
helpText:SetText("Lore Archive v" .. addonVersion .. " - All features active.")

-- Register with the WoW Options Interface
local function RegisterOptions()
    if Settings then
        -- Check for the specific API used by BugSack and modern Anniversary builds
        if Settings.RegisterVerticalLayoutCategory then
            local category, layout = Settings.RegisterVerticalLayoutCategory(f.name)
            if Settings.RegisterAddOnCategory then
                Settings.RegisterAddOnCategory(category)
            end
            addonTable.OptionsCategory = category
            return
        end

        -- Broad scan for modern API candidates
        local candidates = {
            "RegisterCanvasLayoutCategory",
            "RegisterCanvasLayout",
            "RegisterAddOnCanvasLayout",
            "RegisterLayout", 
            "RegisterCanvasCategory"
        }
        
        for _, name in ipairs(candidates) do
            if Settings[name] then
                local category, layout = Settings[name](f, f.name)
                if Settings.RegisterAddOnCategory then
                    Settings.RegisterAddOnCategory(category)
                end
                addonTable.OptionsCategory = category
                return
            end
        end

        local foundFunc = nil
        for k, v in pairs(Settings) do
            if type(v) == "function" and k:find("^Register") and (k:find("Layout") or k:find("Category")) then
                foundFunc = v
                break
            end
        end

        if foundFunc then
            local category, layout = foundFunc(f, f.name)
            if Settings.RegisterAddOnCategory then
                Settings.RegisterAddOnCategory(category)
            end
            addonTable.OptionsCategory = category
            return
        end
        
        -- Last ditch modern attempt
        if Settings.RegisterAddOnCategory then
            local ok, category = pcall(Settings.RegisterAddOnCategory, f, f.name)
            if ok and category then
                addonTable.OptionsCategory = category
                return
            end
        end
    end

    -- Try Legacy API
    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(f)
    else
        -- Fallback: Use simple frame management if nothing else works
        print("|cFFFFFF00[Lore Archive]|r Standalone options active.")
    end
end

local ok, err = pcall(RegisterOptions)
if not ok then
    print("|cFFFF0000[Lore Archive] Options Error:|r", err)
end

function addonTable.OpenOptions()
    -- Always toggle our standalone window for now to ensure the user can see it
    if f:IsShown() then
        f:Hide()
    else
        f:Show()
        f:Raise()
    end
end
