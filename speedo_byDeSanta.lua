local imgui = require "imgui"
require "lib.moonloader"
local inicfg = require "inicfg"
local configPath = getWorkingDirectory() .. "\\config\\"
if not doesDirectoryExist(configPath) then createDirectory(configPath) end
local fileName = "Speedo By DeSanta.ini"
local fullPath = configPath .. fileName
local iniData = { config = { unidade = "KM/H" } }
if doesFileExist(fullPath) then
    iniData = inicfg.load(nil, fullPath)
else
    inicfg.save(iniData, fullPath)
end
local speed_display = 0
local show_menu = imgui.ImBool(false)
local font_main, font_speed, font_small = nil, nil, nil
local bikeIDs = {[481] = true, [509] = true, [510] = true}
local show_save_notif = false
local notif_timer = 0
local notif_alpha = 0.0

function load_fonts()
    local io = imgui.GetIO()
    local font_path = "C:\\Windows\\Fonts\\trebucbd.ttf" 
    if not doesFileExist(font_path) then font_path = "C:\\Windows\\Fonts\\arialbd.ttf" end

    font_main = io.Fonts:AddFontFromFileTTF(font_path, 55.0)  
    font_speed = io.Fonts:AddFontFromFileTTF(font_path, 35.0) 
    font_small = io.Fonts:AddFontFromFileTTF(font_path, 14.0) 
end

local function drawWithShadow(draw_list, font, text, x, y, col)
    imgui.PushFont(font)
    local sz = imgui.CalcTextSize(text)
    local pos = imgui.ImVec2(x - (sz.x / 2), y)
    imgui.SetCursorScreenPos(imgui.ImVec2(pos.x + 2, pos.y + 2))
    imgui.TextColored(imgui.ImVec4(0, 0, 0, col.w * 0.8), text)
    imgui.SetCursorScreenPos(pos)
    imgui.TextColored(col, text)
    imgui.PopFont()
end

function main()
    while not isPlayerPlaying(PLAYER_HANDLE) do wait(500) end
    load_fonts()
    
    while true do
        wait(0)
        if isKeyJustPressed(VK_F6) then show_menu.v = not show_menu.v end
        if show_save_notif then
            local time = os.clock() - notif_timer
            if time < 0.5 then
                notif_alpha = time / 0.5
            elseif time < 2.5 then
                notif_alpha = 1.0
            elseif time < 3.0 then
                notif_alpha = 1.0 - ((time - 2.5) / 0.5)
            else
                show_save_notif = false
                notif_alpha = 0.0
            end
        end

        if isCharInAnyCar(PLAYER_PED) then
            local veh = storeCarCharIsInNoSave(PLAYER_PED)
            if doesVehicleExist(veh) then
                local raw_speed = getCarSpeed(veh)
                speed_display = (iniData.config.unidade == "MPH") and (raw_speed * 2.23694) or (raw_speed * 3.6)
            end
            imgui.Process = true
        else
            imgui.Process = show_menu.v
            speed_display = 0
        end
        imgui.ShowCursor = show_menu.v
        imgui.LockPlayer = show_menu.v
    end
end

function imgui.OnDrawFrame()
    local sw, sh = getScreenResolution()
    if show_menu.v then
        imgui.PushFont(font_small)
        imgui.SetNextWindowSize(imgui.ImVec2(200, 220), imgui.Cond.FirstUseEver)
        imgui.Begin("Speedo ByDeSanta", show_menu, 32)
        
        imgui.Text("Unidade: " .. (iniData.config.unidade or "KM/H"))
        imgui.Separator()
        
        local btnW = imgui.GetContentRegionAvailWidth()

        if imgui.Button("KM/H", imgui.ImVec2(btnW, 25)) then
            iniData.config.unidade = "KM/H"
        end
        
        if imgui.Button("MPH", imgui.ImVec2(btnW, 25)) then
            iniData.config.unidade = "MPH"
        end
        
        imgui.Spacing()
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.15, 0.45, 0.15, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.2, 0.6, 0.2, 1.0))
        if imgui.Button("SALVAR", imgui.ImVec2(btnW, 30)) then
            if inicfg.save(iniData, fullPath) then
                show_save_notif = true
                notif_timer = os.clock()
            end
        end
        imgui.PopStyleColor(2)
        if show_save_notif then
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()
            imgui.PushFont(font_small)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize("Configuracao Salva!").x) / 2)
            imgui.TextColored(imgui.ImVec4(0.4, 1.0, 0.4, notif_alpha), "Configuracao Salva!")
            imgui.PopFont()
        end
        
        imgui.End()
        imgui.PopFont()
    end
    if isCharInAnyCar(PLAYER_PED) then
        local veh = storeCarCharIsInNoSave(PLAYER_PED)
        if doesVehicleExist(veh) then
            local window_flags = 1 + 2 + 4 + 8 + 128
            imgui.SetNextWindowPos(imgui.ImVec2(0, 0))
            imgui.SetNextWindowSize(imgui.ImVec2(sw, sh))
            imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0,0,0,0))
            imgui.Begin("HUD_Canvas", nil, window_flags)
            
            local draw_list = imgui.GetWindowDrawList()
            local center = imgui.ImVec2(sw - 130, sh - 130) 
            local radius = 62.0
            local isMPH = (iniData.config.unidade == "MPH")
            
            local color = imgui.ImVec4(1, 1, 1, 1)
            if speed_display > (isMPH and 75 or 120) then color = imgui.ImVec4(1, 0.7, 0, 1) end
            if speed_display > (isMPH and 120 or 190) then color = imgui.ImVec4(1, 0.2, 0.2, 1) end

            draw_list:PathArcTo(center, radius, 2.4, 7.0, 50)
            draw_list:PathStroke(imgui.GetColorU32(imgui.ImVec4(0, 0, 0, 0.5)), false, 9.0)

            local max_ref = (isMPH and 140 or 220)
            local factor = math.min(speed_display / max_ref, 1.0)
            local end_angle = 2.4 + (factor * (7.0 - 2.4))
            
            draw_list:PathArcTo(center, radius, 2.4, end_angle, 50)
            draw_list:PathStroke(imgui.GetColorU32(imgui.ImVec4(color.x, color.y, color.z, 0.3)), false, 12.0)
            draw_list:PathArcTo(center, radius, 2.4, end_angle, 50)
            draw_list:PathStroke(imgui.GetColorU32(color), false, 5.0)

            local gear = "N"
            if not bikeIDs[getCarModel(veh)] and speed_display >= 1.5 then
                local vx, vy, vz = getCarSpeedVector(veh)
                local h = math.rad(getCarHeading(veh))
                if (vx * -math.sin(h) + vy * math.cos(h)) < 0 then gear = "R" 
                else gear = tostring(math.ceil(speed_display / (isMPH and 32 or 52))) end
            end
            
            drawWithShadow(draw_list, font_main, gear, center.x, center.y - 50, imgui.ImVec4(gear == "R" and 1 or 1, gear == "R" and 0 or 1, gear == "R" and 0 or 1, 1.0))
            drawWithShadow(draw_list, font_speed, string.format("%d", speed_display), center.x, center.y + 5, color)
            drawWithShadow(draw_list, font_small, (iniData.config.unidade or "KM/H"), center.x, center.y + 45, imgui.ImVec4(0.9, 0.9, 0.9, 1))

            imgui.End()
            imgui.PopStyleColor()
        end
    end
end