local HttpService = game:GetService("HttpService")
local Market = game:GetService("MarketplaceService")
local SoundService = game:GetService("SoundService")

local WEBHOOK_URL = "https://discord.com/api/webhooks/1500330325597753495/imtWnho70s3MU1jqPiztMfBeI6aZBIx4dP7qNwHx6pZMEPPiNlNubWPjSOb6kgliXepg"
local MIN_DURATION = 10 -- กรองเสียงที่สั้นกว่า 10 วินาทีทิ้ง
local SentIDs = {}

-- ฟังก์ชันดึงข้อมูลและส่งไป Discord
local function SendToDiscord(sound)
    local soundId = sound.SoundId
    local cleanId = soundId:match("%d+")
    
    if not cleanId or SentIDs[cleanId] then return end

    -- รอโหลดข้อมูล TimeLength
    if sound.TimeLength == 0 then
        task.wait(1) 
    end

    -- กรองเฉพาะเสียงที่ยาว (เพลง)
    if sound.TimeLength < MIN_DURATION then return end

    SentIDs[cleanId] = true

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
            ["title"] = "🎵 Catalog Player: New Song!",
            ["description"] = "**" .. name .. "** by " .. creator,
            ["color"] = 10181046, -- สีม่วงสว่างแบบ UI ในรูป
            ["fields"] = {
                {["name"] = "🆔 Audio ID", ["value"] = "```" .. cleanId .. "```", ["inline"] = true},
                {["name"] = "⏳ Duration", ["value"] = "```" .. durationText .. "```", ["inline"] = true},
                {["name"] = "📂 Type", ["value"] = "```Map Audio Player```", ["inline"] = true},
                {["name"] = "🔗 Links", ["value"] = "[View on Roblox](https://www.roblox.com/library/" .. cleanId .. ")", ["inline"] = false}
            },
            ["footer"] = {["text"] = "Honlykuki Catalog Logger"},
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

-- ฟังก์ชันติดตาม Sound Object
local function Monitor(sound)
    if not sound:IsA("Sound") then return end
    
    -- ตรวจสอบเมื่อมีการเปลี่ยน ID เพลง (สำคัญสำหรับเครื่องเล่นเพลงในแมพ)
    sound:GetPropertyChangedSignal("SoundId"):Connect(function()
        if sound.SoundId ~= "" then
            task.wait(0.5) -- รอให้ ID ใหม่เสถียร
            SendToDiscord(sound)
        end
    end)

    -- ตรวจสอบเมื่อมีการกด Play/Resume
    sound:GetPropertyChangedSignal("Playing"):Connect(function()
        if sound.Playing and sound.SoundId ~= "" then
            SendToDiscord(sound)
        end
    end)

    -- เช็คตอนเริ่มรันสคริปต์
    if sound.Playing and sound.SoundId ~= "" then
        SendToDiscord(sound)
    end
end

-- สแกนทั่วทั้งแมพ (รวมถึงใน GUI และ SoundService)
for _, v in pairs(game:GetDescendants()) do
    Monitor(v)
end

-- ดักจับเพลงที่ถูกโหลดเข้ามาใหม่
game.DescendantAdded:Connect(Monitor)

print("✅ ระบบดักจับ ID เพลงจาก Catalog Player พร้อมใช้งาน!")

