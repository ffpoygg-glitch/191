-- [[ MUSIC ID LOGGER - ภายใต้เทพ ]] --

local Webhook_URL = "https://discord.com/api/webhooks/1500123072550666291/jEp7S6CKoR6fw_wqrCp-1COua0gPqRKx1u66yVpAAT8GAOqLcCuj3Vv1ONULgd_GTl8a"

local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local LoggedIDs = {}

-- ฟังก์ชันดึงชื่อเพลง
local function GetSafeName(id)
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(id)
    end)
    if success and info then
        return info.Name
    end
    return "ไม่พบชื่อเพลง"
end

-- ฟังก์ชันส่งไป Discord
local function SendToDiscord(songId)
    local songName = GetSafeName(songId)
    local data = {
        ["content"] = "🎧 **ระบบดักไอดีเพลงทำงาน!**",
        ["embeds"] = {{
            ["title"] = "พบไอดีเพลงใหม่ในเซิร์ฟเวอร์",
            ["description"] = "ID นี้ถูกคัดลอกมาจากตัวละครหรือแมพที่คุณอยู่",
            ["color"] = 16711935, -- สีชมพูอมม่วง
            ["fields"] = {
                {["name"] = "ชื่อเพลง", ["value"] = "```" .. songName .. "```", ["inline"] = false},
                {["name"] = "Audio ID", ["value"] = "```" .. tostring(songId) .. "```", ["inline"] = true},
                {["name"] = "ลิงก์", ["value"] = "[คลิกเพื่อฟัง](https://www.roblox.com/library/" .. songId .. ")", ["inline"] = true}
            },
            ["footer"] = {["text"] = "Music Logger By Gemini | Status: Active"}
        }}
    }
    
    local success, err = pcall(function()
        (request or http_request)({
            Url = Webhook_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
end

-- ระบบ Scan
print("--- Music Logger Loaded ---")
task.spawn(function()
    while task.wait(3) do -- สแกนทุก 3 วินาที
        for _, sound in pairs(game:GetDescendants()) do
            if sound:IsA("Sound") and sound.IsPlaying then
                local rawId = tostring(sound.SoundId)
                local id = rawId:match("%d+")
                
                if id and not LoggedIDs[id] then
                    LoggedIDs[id] = true
                    SendToDiscord(id)
                end
            end
        end
    end
end)

