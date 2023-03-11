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
        if type(MRT_NL_DB.postAction) ~= "string" then MRT_NL_DB.postAction = "hide" end
        if type(MRT_NL_DB.autoload) ~= "table" then
            MRT_NL_DB.autoload = {
                -- {
                --     ["type"] = "zone/eid/ename",
                --     ["value"] = string/number,
                --     ["note"] = noteName(string)/noteIndex(number),
                -- },
            }
        end
        MRT_NL:Fire("UpdateAutoload")

        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        eventFrame:RegisterEvent("ZONE_CHANGED")
        eventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
        eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        eventFrame:RegisterEvent("ENCOUNTER_START")
        eventFrame:RegisterEvent("ENCOUNTER_END")

        -- button
        local b = MRT_NL.widgets:CreateButton(MRTOptionsFrameNote, "MRT Note Loader", "blue", {140, 20})
        b:SetPoint("TOPLEFT", 80, 7)
        b:SetScript("OnClick", function()
            MRT_NoteLoader:Show()
        end)

        -- NL_DEFAULT
        if VMRT.Note.BlackNames[1] ~= "Note Loader Default" then
            tinsert(VMRT.Note.BlackNames, 1, "Note Loader Default")
            tinsert(VMRT.Note.Black, 1, "")
        end

        -- restore MRT Note alpha
        hooksecurefunc(GMRT.A.Note.frame, "UpdateText", function()
            GMRT.A.Note.frame:SetAlpha(VMRT.Note.Alpha and (VMRT.Note.Alpha / 100) or 1)
            if not VMRT.Note.Fix then
                GMRT.A.Note.frame:EnableMouse(true)
            end
        end)
    end
end

-------------------------------------------------
-- callbacks
-------------------------------------------------
MRT_NL.autoload = {
    ["zone"] = {},
    ["zone_p"] = {},
    ["eid"] = {},
    ["eid_p"] = {},
    ["ename"] = {},
    ["ename_p"] = {},
}

MRT_NL:RegisterCallback("UpdateAutoload", "Core_UpdateAutoload", function()
    wipe(MRT_NL.autoload.zone)
    wipe(MRT_NL.autoload.zone_p)
    wipe(MRT_NL.autoload.eid)
    wipe(MRT_NL.autoload.eid_p)
    wipe(MRT_NL.autoload.ename)
    wipe(MRT_NL.autoload.ename_p)

    for _, t in pairs(MRT_NL_DB.autoload) do
        if t.isPersonal then
            MRT_NL.autoload[t.type.."_p"][t.value] = t.note
        else
            MRT_NL.autoload[t.type][t.value] = t.note
        end
    end
end)

-------------------------------------------------
-- functions
-------------------------------------------------
function MRT_NL:Print(msg)
    print("|cffff9015[MRT Note Loader]|r " .. msg)
end

local function GetNoteIndex(title)
    if type(title) == "string" then
        for i, name in pairs(VMRT.Note.BlackNames) do
            if title == name then
                return i
            end
        end
    elseif type(title) == "number" and VMRT.Note.Black[title] then
        return title
    end
end

local isEncounterInProgress = false
local zoneFound = false
local showByThisAddon = false

function MRT_NL:LoadNote(title, isPersonal, force)
    --! do not load if current note is loaded by ENCOUNTER_START 
    if isEncounterInProgress and not force then return end
    
    local index = GetNoteIndex(title)
    if not index then
        MRT_NL:Print(string.format("note |cffff9015%s|r not found.", title))
        return
    end
    
    if not VMRT.Note.enabled then
        GMRT.A.Note:Enable()
    end

    if isPersonal then
        VMRT.Note.SelfText = VMRT.Note.Black[index]
        GMRT.A.Note.frame:UpdateText()
        MRT_NL:Print(string.format("personal note loaded |cffff9015%s|r.", title))
    else
        GMRT.A.Note.frame:Save(index)
        MRT_NL:Print(string.format("note loaded |cffff9015%s|r.", title))
    end

    showByThisAddon = true
end

-------------------------------------------------
-- after encounter / zone changed
-------------------------------------------------
local function HideOrLoad()
    showByThisAddon = false
    if MRT_NL_DB.postAction == "hide" then
        GMRT.A.Note.frame:SetAlpha(0)
        GMRT.A.Note.frame:EnableMouse(false)

    elseif MRT_NL_DB.postAction == "load" or MRT_NL_DB.postAction == "loadAndClear" then
        if VMRT.Note.BlackNames[1] == "Note Loader Default" then
            GMRT.A.Note.frame:Save(1)
        end
        
        if MRT_NL_DB.postAction == "loadAndClear" then
            VMRT.Note.SelfText = ""
            GMRT.A.Note.frame:UpdateText()
        end

    else
        -- do nothing
    end
end

-------------------------------------------------
-- zone changed
-------------------------------------------------
function eventFrame:ZONE_CHANGED()
    -- local isIn, iType = IsInInstance()
    local zone = GetSubZoneText()
    if zone == "" then
        zone = GetRealZoneText()
    end

    if not zone then
        C_Timer.After(1, eventFrame.ZONE_CHANGED)
        return
    end

    MRT_NL:Fire("ZONE_CHANGED", zone)

    zoneFound = false

    if MRT_NL.autoload.zone[zone] then
        MRT_NL:LoadNote(MRT_NL.autoload.zone[zone])
        zoneFound = true
    end
    if MRT_NL.autoload.zone_p[zone] then
        MRT_NL:LoadNote(MRT_NL.autoload.zone_p[zone], true)
        zoneFound = true
    end

    if showByThisAddon and not isEncounterInProgress and not zoneFound then
        HideOrLoad()
    end
end

eventFrame.ZONE_CHANGED_INDOORS = eventFrame.ZONE_CHANGED
eventFrame.ZONE_CHANGED_NEW_AREA = eventFrame.ZONE_CHANGED

function eventFrame:PLAYER_ENTERING_WORLD(isLogin, isReload)
    eventFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
    if isReload then
        eventFrame:ZONE_CHANGED()
    end
end

-------------------------------------------------
-- encounter start
-------------------------------------------------
function eventFrame:ENCOUNTER_START(encounterID, encounterName, difficultyID, groupSize)
    MRT_NL:Fire("ENCOUNTER_START", encounterID, encounterName)
    
    if MRT_NL.autoload.eid[encounterID] then
        isEncounterInProgress = true
        MRT_NL:LoadNote(MRT_NL.autoload.eid[encounterID], false, true)
    end
    if MRT_NL.autoload.eid_p[encounterID] then
        isEncounterInProgress = true
        MRT_NL:LoadNote(MRT_NL.autoload.eid_p[encounterID], true, true)
    end
    if MRT_NL.autoload.ename[encounterName] then
        isEncounterInProgress = true
        MRT_NL:LoadNote(MRT_NL.autoload.ename[encounterName], false, true)
    end
    if MRT_NL.autoload.ename_p[encounterName] then
        isEncounterInProgress = true
        MRT_NL:LoadNote(MRT_NL.autoload.ename_p[encounterName], true, true)
    end

    if isEncounterInProgress then
        -- call MRT's ENCOUNTER_START
        GMRT.A.Note.main:ENCOUNTER_START(encounterID, encounterName, difficultyID, groupSize)
    end
end

function eventFrame:ENCOUNTER_END()
    isEncounterInProgress = false
    if showByThisAddon then
        if zoneFound then -- reload note for this zone
            eventFrame:ZONE_CHANGED()
        else
            HideOrLoad()
        end
    end
end