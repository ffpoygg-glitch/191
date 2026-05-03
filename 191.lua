local HttpService = game:GetService("HttpService")
local Market = game:GetService("MarketplaceService")

local WEBHOOK_URL = "https://discord.com/api/webhooks/1500330325597753495/imtWnho70s3MU1jqPiztMfBeI6aZBIx4dP7qNwHx6pZMEPPiNlNubWPjSOb6kgliXepg"
local MIN_DURATION = 10 -- ตั้งค่า: เสียงต้องยาวเกิน 10 วินาทีถึงจะส่ง (กันเสียงเดิน/เสียงปืน)
local SentIDs = {}

local function SendToDiscord(sound)
    local soundId = sound.SoundId
    local cleanId = soundId:match("%d+")
    
    if not cleanId or SentIDs[cleanId] then return end

    -- รอให้ข้อมูลความยาวเสียงโหลด (สำคัญมาก)
    if sound.TimeLength == 0 then
        repeat task.wait(0.5) until sound.TimeLength > 0 or not sound.Parent
    end

    -- ตรวจสอบความยาวเสียง ถ้าสั้นกว่าที่กำหนดให้ข้ามไป
    if sound.TimeLength < MIN_DURATION then 
        return 
    end

    SentIDs[cleanId] = true

    -- ดึงข้อมูลจาก Marketplace
    local success, info = pcall(function()
        return Market:GetProductInfo(cleanId)
    end)
    
    local name = success and info.Name or sound.Name
    local creator = success and info.Creator.Name or "Unknown"
    local minutes = math.floor(sound.TimeLength / 60)
    local seconds = math.floor(sound.TimeLength % 60)
    local durationText = string.format("%02d:%02d", minutes, seconds)

    local data = {
        ["embeds"] = {{
            ["title"] = "🎵 New Music Detected!",
            ["description"] = "**" .. name .. "** by " .. creator,
            ["color"] = 7419130,
            ["fields"] = {
                {
                    ["name"] = "🆔 Audio ID",
                    ["value"] = "```" .. cleanId .. "```",
                    ["inline"] = true
                },
                {
                    ["name"] = "⏳ Duration",
                    ["value"] = "```" .. durationText .. "```",
                    ["inline"] = true
                },
                {
                    ["name"] = "📂 Type",
                    ["value"] = "```Music/Song```",
                    ["inline"] = true
                },
                {
                    ["name"] = "🔗 Links",
                    ["value"] = "[View on Roblox](https://www.roblox.com/library/" .. cleanId .. ")",
                    ["inline"] = false
                }
            },
            ["footer"] = { ["text"] = "Honlykuki Audio Filter" },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    
    local finalData = HttpService:JSONEncode(data)
    pcall(function()
        local req = (syn and syn.request) or (http and http.request) or http_request or request
        req({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = finalData
        })
    end)
end

local function HandleSound(sound)
    if not sound:IsA("Sound") then return end
    
    -- ดักจับตอนกดเล่น
    sound:GetPropertyChangedSignal("Playing"):Connect(function()
        if sound.Playing and sound.SoundId ~= "" then
            SendToDiscord(sound)
        end
    end)

    -- ตรวจสอบเผื่อเล่นอยู่แล้ว
    if sound.Playing and sound.SoundId ~= "" then
        SendToDiscord(sound)
    end
end

for _, v in pairs(game:GetDescendants()) do HandleSound(v) end
game.DescendantAdded:Connect(HandleSound)

