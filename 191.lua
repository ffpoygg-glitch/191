local HttpService = game:GetService("HttpService")
local Market = game:GetService("MarketplaceService")

local WEBHOOK_URL = "https://discord.com/api/webhooks/1500330325597753495/imtWnho70s3MU1jqPiztMfBeI6aZBIx4dP7qNwHx6pZMEPPiNlNubWPjSOb6kgliXepg"
local MIN_DURATION = 10 -- กรองเสียงสั้น (วินาที)
local SentIDs = {}

local function SendToDiscord(sound)
    local soundId = sound.SoundId
    local cleanId = soundId:match("%d+")
    
    -- ถ้าไม่มี ID หรือเคยส่ง ID นี้ไปแล้ว ให้ข้าม
    if not cleanId or SentIDs[cleanId] then return end

    -- รอให้ข้อมูล TimeLength โหลด (สำคัญสำหรับการเช็คความยาวเพลง)
    if sound.TimeLength <= 0 then
        task.wait(1) 
    end

    if sound.TimeLength < MIN_DURATION then return end

    SentIDs[cleanId] = true

    -- ดึงข้อมูลชื่อเพลงและเจ้าของ
    local success, info = pcall(function()
        return Market:GetProductInfo(cleanId)
    end)
    
    local name = success and info.Name or "Unknown"
    local creator = success and info.Creator.Name or "Unknown"
    local minutes = math.floor(sound.TimeLength / 60)
    local seconds = math.floor(sound.TimeLength % 60)
    local durationText = string.format("%02d:%02d", minutes, seconds)

    -- จัดหน้าตา Embed ให้เหมือนรูป Audio Manager ที่คุณต้องการ
    local data = {
        ["embeds"] = {{
            ["title"] = "🔊 Detected from RELICSxyz Boombox",
            ["description"] = "**" .. name .. "** by " .. creator,
            ["color"] = 7419130, -- สีม่วง
            ["fields"] = {
                {["name"] = "🆔 Audio ID", ["value"] = "```" .. cleanId .. "```", ["inline"] = true},
                {["name"] = "⏳ Duration", ["value"] = "```" .. durationText .. "```", ["inline"] = true},
                {["name"] = "📂 Source", ["value"] = "```" .. sound.Parent.Name .. "```", ["inline"] = true},
                {["name"] = "🔗 Links", ["value"] = "[View on Roblox](https://www.roblox.com/library/" .. cleanId .. ")", ["inline"] = false}
            },
            ["footer"] = {["text"] = "Honlykuki Audio Logger v3"},
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    
    pcall(function()
        local req = (syn and syn.request) or (http and http.request) or http_request or request
        req({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
end

-- ฟังก์ชันดักจับเฉพาะตัว AudioPlayer
local function HookAudioPlayer(obj)
    if obj.Name == "AudioPlayer" and obj:IsA("Sound") then
        -- ตรวจสอบเมื่อ ID เปลี่ยน (กรณีเปลี่ยนเพลงในเครื่องเล่นเดิม)
        obj:GetPropertyChangedSignal("SoundId"):Connect(function()
            if obj.SoundId ~= "" then
                task.wait(0.5)
                SendToDiscord(obj)
            end
        end)

        -- ตรวจสอบเมื่อเริ่มเล่น
        obj:GetPropertyChangedSignal("Playing"):Connect(function()
            if obj.Playing and obj.SoundId ~= "" then
                SendToDiscord(obj)
            end
        end)

        -- ถ้ากำลังเล่นอยู่แล้วตอนรันสคริปต์
        if obj.Playing and obj.SoundId ~= "" then
            SendToDiscord(obj)
        end
    end
end

-- สแกนหา AudioPlayer ทั้งหมดใน Workspace (ตามรูป Dex)
for _, v in pairs(game:GetDescendants()) do
    HookAudioPlayer(v)
end

-- ดักจับเมื่อมีคนใหม่ใส่ Boombox (มี AudioPlayer ใหม่เพิ่มเข้ามา)
game.DescendantAdded:Connect(HookAudioPlayer)

print("🎯 เจาะจงดักจับ AudioPlayer จาก RELICSxyz เรียบร้อยแล้ว!")

