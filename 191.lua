local HttpService = game:GetService("HttpService")
local WebhookURL = "https://discord.com/api/webhooks/1500330325597753495/imtWnho70s3MU1jqPiztMfBeI6aZBIx4dP7qNwHx6pZMEPPiNlNubWPjSOb6kgliXepg"

-- ฟังก์ชันส่งข้อมูลไป Discord
local function sendToDiscord(name, id, method)
    local data = {
        ["embeds"] = {{
            ["title"] = "🎯 ตรวจพบไฟล์เสียงใหม่! (อัตโนมัติ)",
            ["description"] = "🎵 **ชื่อไฟล์:** " .. name .. "\n🆔 **ID เพลง:** `" .. id .. "`\n🔍 **ประเภทการดัก:** " .. method,
            ["color"] = 7419530, -- สีม่วงเข้ม
            ["footer"] = {["text"] = "Honlykuki Ultimate System • " .. os.date("%X")}
        }}
    }
    pcall(function()
        HttpService:PostAsync(WebhookURL, HttpService:JSONEncode(data))
    end)
end

-- ฟังก์ชันหลักในการจ้องดัก Sound
local function setupMonitor(v)
    if v:IsA("Sound") then
        -- 1. ดักจับทันทีที่เจอ (สำหรับเพลงที่ไม่เข้ารหัส หรือมี ID ค้างไว้แล้ว)
        local initialId = string.match(v.SoundId, "%d+")
        if initialId and initialId ~= "" then
            sendToDiscord(v.Name, initialId, "ตรวจพบในโฟลเดอร์ (Scan)")
        end

        -- 2. ดักจับเมื่อมีการเปลี่ยน ID (แก้ทางพวก Encode/Script เปลี่ยนเพลง)
        v:GetPropertyChangedSignal("SoundId"):Connect(function()
            local newId = string.match(v.SoundId, "%d+")
            if newId then
                sendToDiscord(v.Name, newId, "ดักจับจากการถอดรหัส (Anti-Encode)")
            end
        end)
    end
end

-- สแกนหาทุกอย่างที่มีอยู่ในเกมตอนนี้
for _, descendant in pairs(game:GetDescendants()) do
    setupMonitor(descendant)
end

-- ระบบอัตโนมัติ: ดักจับของที่เพิ่งถูกสร้างใหม่ (รถใหม่, เครื่องเสียงใหม่)
game.DescendantAdded:Connect(function(descendant)
    setupMonitor(descendant)
end)

print("🚀 [Honlykuki System] ทำงานเต็มระบบ: ดักจับอัตโนมัติ 100% (Normal + Encoded)")

