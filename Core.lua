local addonName, MRT_NL = ...
_G.MRT_NL = MRT_NL

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...)
end)

-------------------------------------------------
-- loaded
-------------------------------------------------
eventFrame:RegisterEvent("ADDON_LOADED")
function eventFrame:ADDON_LOADED(addon)
    if addon == addonName then
        eventFrame:UnregisterEvent("ADDON_LOADED")

        if type(MRT_NL_DB) ~= "table" then MRT_NL_DB = {} end
        if type(MRT_NL_DB.scale) ~= "number" then MRT_NL_DB.scale = 1 end
        if type(MRT_NL_DB.autoload) ~= "table" then
            MRT_NL_DB.autoload = {
                -- {
                --     ["type"] = "zone/eid/ename",
                --     ["value"] = string/number,
                --     ["note"] = noteName,
                -- },
            }
        end
        MRT_NL:Fire("UpdateAutoload")

        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        eventFrame:RegisterEvent("ZONE_CHANGED")
        eventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
        eventFrame:RegisterEvent("ENCOUNTER_START")

        -- button
        local b = MRT_NL.widgets:CreateButton(MRTOptionsFrameNote, "MRT Note Loader", "blue", {120, 20})
        b:SetPoint("TOPRIGHT", 0, -45)
        b:SetScript("OnClick", function()
            MRT_NoteLoader:Show()
        end)
    end
end

-------------------------------------------------
-- callbacks
-------------------------------------------------
MRT_NL.autoload = {
    ["zone"] = {},
    ["eid"] = {},
    ["ename"] = {},
}

MRT_NL:RegisterCallback("UpdateAutoload", "Core_UpdateAutoload", function()
    wipe(MRT_NL.autoload.zone)
    wipe(MRT_NL.autoload.eid)
    wipe(MRT_NL.autoload.ename)

    for _, t in pairs(MRT_NL_DB.autoload) do
        MRT_NL.autoload[t.type][t.value] = t.note
    end
end)

-------------------------------------------------
-- functions
-------------------------------------------------
function MRT_NL:Print(msg)
    print("|cffff9015[MRT Note Loader]|r " .. msg)
end

local function GetNoteIndex(title)
    for i, name in pairs(VMRT.Note.BlackNames) do
        if title == name then
            return i
        end
    end
end

function MRT_NL:LoadNote(title, force)
    local index = GetNoteIndex(title)
    if not index then
        MRT_NL:Print(string.format("note |cffff9015%s|r not found.", title))
        return
    end
    
    -- do not load note during an encounter
    if IsEncounterInProgress() and not force then return end
    
    GMRT.A.Note.frame:Save(index)
    MRT_NL:Print(string.format("note loaded |cffff9015%s|r.", title))
end

-------------------------------------------------
-- zone changed
-------------------------------------------------
function eventFrame:PLAYER_ENTERING_WORLD()
    local isIn, iType = IsInInstance()
    local zone = GetSubZoneText()
    if zone == "" then
        zone = GetRealZoneText()
    end

    if not zone then
        C_Timer.After(1, eventFrame.PLAYER_ENTERING_WORLD)
        return
    end

    MRT_NL:Fire("ZONE_CHANGED", zone)
    if MRT_NL.autoload.zone[zone] then
        MRT_NL:LoadNote(MRT_NL.autoload.zone[zone])
    end
end

eventFrame.ZONE_CHANGED = eventFrame.PLAYER_ENTERING_WORLD
eventFrame.ZONE_CHANGED_INDOORS = eventFrame.PLAYER_ENTERING_WORLD

-------------------------------------------------
-- encounter start
-------------------------------------------------
function eventFrame:ENCOUNTER_START(encounterID, encounterName, difficultyID, groupSize)
    MRT_NL:Fire("ENCOUNTER_START", encounterID, encounterName)
    
    if MRT_NL.autoload.eid[encounterID] then
        MRT_NL:LoadNote(MRT_NL.autoload.eid[encounterID], true)
    end
    if MRT_NL.autoload.ename[encounterName] then
        MRT_NL:LoadNote(MRT_NL.autoload.ename[encounterName], true)
    end
end