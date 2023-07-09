local _, MRT_NL = ...

local sendChannel
local function UpdateSendChannel()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        sendChannel = "INSTANCE_CHAT"
    elseif IsInRaid() then
        sendChannel = "RAID"
    else
        sendChannel = "PARTY"
    end
end

local isWaitForSending
function MRT_NL:SendChatMessage(lines)
    if isWaitForSending then return end
    isWaitForSending = true

    UpdateSendChannel()

    -- remove color codes
    lines = string.gsub(lines, "\124\124c%w%w%w%w%w%w%w%w", "")
    lines = string.gsub(lines, "\124\124r", "")

    -- convert to string[]
    lines = strsplittable("\n", lines)

    -- {spell:xxx} -> link
    for i = 1, #lines do
        lines[i] = string.gsub(lines[i], "%{spell:%d+%}", function(text)
            local id = tonumber(strmatch(text, "%d+"))
            local link = GetSpellLink(id)
            if link then
                return link
            else
                return ""
            end
        end)
    end

    -- test
    -- texplore(lines)
    -- C_Timer.After(1, function()
    --     isWaitForSending = false
    --     MRT_NL_Send:SetEnabled(true)
    -- end)

    for i = 1, #lines + 1 do
        local delay = i * 200 / 1000

        if lines[i] then
            C_Timer.After(delay, function()
                SendChatMessage(lines[i], sendChannel)
            end)
        else
            C_Timer.After(delay, function()
                isWaitForSending = false
                MRT_NL_Send:SetEnabled(true)
            end)
        end
    end
end