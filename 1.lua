-- ============================================================
-- BLACK ESP + SKIN MOD — Merged (PUBG Mobile Lua)
-- Merged from: 1.lua + No Lag Full Skin.lua
-- ESP unchanged. Skin mod integrated into ModMenu tab.
-- BRPlayerCharacterBase features untouched.
-- ============================================================

-- ========== Imports (ESP) ==========
local SlateBlueprintLibrary = nil
local WidgetLayoutLibrary = nil
local FVector2D = nil
local FVector = nil
local FLinearColor = nil
local FSlateColor = nil

pcall(function()
    SlateBlueprintLibrary = import("SlateBlueprintLibrary") or import("/Script/UMG.SlateBlueprintLibrary")
    WidgetLayoutLibrary = import("WidgetLayoutLibrary") or import("/Script/UMG.WidgetLayoutLibrary")
    FVector2D = import("Vector2D")
    FVector = import("Vector")
    FLinearColor = import("LinearColor")
    FSlateColor = import("SlateColor") or import("/Script/SlateCore.SlateColor")
end)

local function IsValid(obj)
    if not obj then return false end
    if slua and slua.isValid then return slua.isValid(obj) end
    return true
end

local TempProjVec2D = FVector2D and FVector2D(0, 0) or nil
local ColorWhite  = FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or nil
local ColorRed    = FLinearColor and FLinearColor(1.0, 0.15, 0.15, 1.0) or nil
local ColorGreen  = FLinearColor and FLinearColor(0.0, 1.0, 0.05, 1.0) or nil
local ColorYellow = FLinearColor and FLinearColor(1.0, 0.95, 0.0, 1.0) or nil
local ColorBlue   = FLinearColor and FLinearColor(0.18, 0.62, 1.0, 1.0) or nil

local SlateColorRed   = (FSlateColor and ColorRed)   and FSlateColor(ColorRed)   or ColorRed
local SlateColorGreen = (FSlateColor and ColorGreen) and FSlateColor(ColorGreen) or ColorGreen

-- ========== Config (ESP) ==========
_G.LexusConfig = _G.LexusConfig or {}
local _defaults = {
    BoxESP          = false,
    BoxESP_Lines    = true,
    BoxESP_Counter  = true,
    BoxESP_Health   = true,
    BoxESP_Name     = true,
    BoxESP_Distance = true,
    BoxESP_Weapon   = true,
    BoxESP_Flag     = true,
    BoxESP_State    = true,
}
for k, v in pairs(_defaults) do
    if _G.LexusConfig[k] == nil then _G.LexusConfig[k] = v end
end

-- ========== Enemy Counter Badges (ESP) ==========
local ENEMY_COUNTER_PLAYER_URLS = {}
local ENEMY_COUNTER_BOT_URLS    = {}
local EnemyCounterTextureCache  = {}
local BADGE_WIDTH  = 48
local BADGE_HEIGHT = 22

local function FileExists(path)
    if not path or path == "" then return false end
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

local function GetPossibleLocalPaths(filename)
    return {
        "/storage/emulated/0/Android/data/com.tencent.ig/files/" .. filename,
        "/storage/emulated/0/Android/data/com.pubg.krmobile/files/" .. filename,
        "/storage/emulated/0/Android/data/com.vng.pubgmobile/files/" .. filename,
        "/storage/emulated/0/Android/data/com.rekoo.pubgm/files/" .. filename,
        "/storage/emulated/0/Android/data/com.tencent.tmgp.pubgmhd/files/" .. filename,
        filename
    }
end

local function LoadBadgeTexture(imgWidget, urls, filename, typeKey, counterData)
    if not imgWidget or not IsValid(imgWidget) then return end
    if EnemyCounterTextureCache[typeKey] and IsValid(EnemyCounterTextureCache[typeKey]) then
        pcall(function()
            imgWidget:SetBrushFromTexture(EnemyCounterTextureCache[typeKey], false)
            imgWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        if counterData then
            if typeKey == "Player" then counterData.PlayerLoaded = true end
            if typeKey == "Bot"    then counterData.BotLoaded    = true end
        end
        return
    end

    local function applyTex(tex)
        if tex and IsValid(tex) and IsValid(imgWidget) then
            EnemyCounterTextureCache[typeKey] = tex
            if counterData then
                if typeKey == "Player" then counterData.PlayerLoaded = true end
                if typeKey == "Bot"    then counterData.BotLoaded    = true end
            end
            pcall(function()
                imgWidget:SetBrushFromTexture(tex, false)
                imgWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
            return true
        end
        return false
    end

    for _, localPath in ipairs(GetPossibleLocalPaths(filename)) do
        if FileExists(localPath) then
            local tex = nil
            pcall(function()
                local asset_util = package.loaded["common.asset_util"] or require("common.asset_util")
                if asset_util and asset_util.GetAssetSync then tex = asset_util.GetAssetSync(localPath) end
            end)
            if not tex then
                pcall(function() if CGame and CGame.LoadObject then tex = CGame:LoadObject(localPath) end end)
            end
            if tex and applyTex(tex) then return end
        end
    end

    local function tryDownloadUrl(i)
        if i > #urls then return end
        local url = urls[i]
        local done = false
        pcall(function()
            local AsyncTaskDownloadImage = import("AsyncTaskDownloadImage") or import("/Script/UMG.AsyncTaskDownloadImage")
            if AsyncTaskDownloadImage and AsyncTaskDownloadImage.DownloadImage then
                local task = AsyncTaskDownloadImage.DownloadImage(url)
                if task and task.OnSuccess then
                    task.OnSuccess:Add(function(tex)
                        if not done and tex then done = true; applyTex(tex) end
                    end)
                    if task.OnFail then
                        task.OnFail:Add(function() if not done then tryDownloadUrl(i + 1) end end)
                    end
                end
            end
        end)
        if not done then
            pcall(function()
                local mm = _G.ModuleManager or package.loaded["GameLua.GameCore.Module.ModuleManager"]
                if not mm then pcall(function() mm = require("GameLua.GameCore.Module.ModuleManager") end) end
                local imgMgr = nil
                if mm and mm.GetModule and mm.CommonModuleConfig then
                    imgMgr = mm.GetModule(mm.CommonModuleConfig.image_download_mgr)
                end
                if not imgMgr then pcall(function() imgMgr = require("client.slua.logic.image_download.image_download_mgr") end) end
                if imgMgr and imgMgr.DownloadImageByHttpWrapper then
                    imgMgr:DownloadImageByHttpWrapper(url, function(tex)
                        if not done and tex then done = true; applyTex(tex) end
                    end, function() if not done then tryDownloadUrl(i + 1) end end)
                end
            end)
        end
    end
    tryDownloadUrl(1)
end

-- ========== BoxESP Master (ESP — unchanged) ==========
local BoxESP = {
    bActive = true,
    bShowLines = true,
    bShowCounter = true,
    ESPCanvas = nil,
    BoxWidgets = {},
    LineWidgets = {},

    CounterData = {
        ImgPlayer = nil, SlotPlayer = nil,
        ImgBot = nil, SlotBot = nil,
        TxtPlayer = nil, SlotTxtPlayer = nil,
        TxtBot = nil, SlotTxtBot = nil,
        LastPlayerCount = -1, LastBotCount = -1,
        PlayerLoaded = false, BotLoaded = false,
        LastDownloadRetry = 0, bCreated = false
    },

    HealthColor   = { R = 0.0, G = 1.0, B = 0.0, A = 1.0 },
    HealthBgColor = { R = 0.0, G = 0.0, B = 0.0, A = 0.85 },
    HealthBarWidth    = 2.0,
    CornerColor       = { R = 1.0, G = 1.0, B = 1.0, A = 1.0 },
    CornerThickness   = 1.0,
    CornerLengthRatio = 0.28,
    SnapLineThickness = 1.0,
    SnapLineOriginY   = 72,

    _CanvasScaleX = 1.0, _CanvasScaleY = 1.0,
    _CanvasOffsetX = 0.0, _CanvasOffsetY = 0.0,
    _LastCanvas = nil, _LastTransformTime = 0,
    _LastHeavyUpdateTime = 0, _LastVisCheckTime = 0,
    _VisCheckCache = {}
}

function BoxESP.GetMainCanvas()
    if BoxESP.ESPCanvas and IsValid(BoxESP.ESPCanvas) then return BoxESP.ESPCanvas end
    local InGameUITools = package.loaded["GameLua.Mod.BaseMod.Common.UI.InGameUITools"]
    if not InGameUITools then
        pcall(function() InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools") end)
    end
    if not InGameUITools then return nil end
    local MainUI = InGameUITools.GetMainControlBaseUI and InGameUITools.GetMainControlBaseUI() or nil
    if not IsValid(MainUI) then return nil end
    local ParentCanvas = nil
    if MainUI.CanvasPanel_0 and IsValid(MainUI.CanvasPanel_0) then
        ParentCanvas = MainUI.CanvasPanel_0
    elseif MainUI.CanvasPanel_42 and IsValid(MainUI.CanvasPanel_42) then
        ParentCanvas = MainUI.CanvasPanel_42
    end
    if ParentCanvas then
        BoxESP.ESPCanvas = ParentCanvas
        BoxESP._LastCanvas = ParentCanvas
    end
    return ParentCanvas
end

function BoxESP.CreateESPWidget(ParentCanvas)
    if not FLinearColor or not FVector2D then return nil end

    local CornerContainer = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", ParentCanvas)
    if not IsValid(CornerContainer) then return nil end
    local CornerMainSlot = ParentCanvas:AddChildToCanvas(CornerContainer)
    if not CornerMainSlot then return nil end
    CornerMainSlot:SetAutoSize(false)
    CornerMainSlot:SetZOrder(995)
    CornerMainSlot:SetAlignment(FVector2D(0.5, 0.5))

    local whiteColor = FLinearColor(BoxESP.CornerColor.R, BoxESP.CornerColor.G, BoxESP.CornerColor.B, BoxESP.CornerColor.A)

    local function CreateBorderLine()
        local border = CGame:NewObjectFromPath("/Script/UMG.Border", CornerContainer)
        if border and IsValid(border) then
            border:SetBrushColor(whiteColor)
            border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            local slot = CornerContainer:AddChildToCanvas(border)
            if slot then slot:SetAutoSize(false) end
            return { widget = border, slot = slot }
        end
        return nil
    end

    local CornerLines = {
        TopLeft_H = CreateBorderLine(),     TopLeft_V = CreateBorderLine(),
        TopRight_H = CreateBorderLine(),    TopRight_V = CreateBorderLine(),
        BottomLeft_H = CreateBorderLine(),  BottomLeft_V = CreateBorderLine(),
        BottomRight_H = CreateBorderLine(), BottomRight_V = CreateBorderLine()
    }

    local BgImage = CGame:NewObjectFromPath("/Script/UMG.Image", ParentCanvas)
    if not IsValid(BgImage) then return nil end
    BgImage:SetColorAndOpacity(FLinearColor(BoxESP.HealthBgColor.R, BoxESP.HealthBgColor.G, BoxESP.HealthBgColor.B, BoxESP.HealthBgColor.A))
    BgImage:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    local BgSlot = ParentCanvas:AddChildToCanvas(BgImage)
    if not BgSlot then return nil end
    BgSlot:SetAutoSize(false); BgSlot:SetZOrder(998); BgSlot:SetAlignment(FVector2D(0.5, 1.0))

    local HealthImage = CGame:NewObjectFromPath("/Script/UMG.Image", ParentCanvas)
    if not IsValid(HealthImage) then return nil end
    HealthImage:SetColorAndOpacity(FLinearColor(BoxESP.HealthColor.R, BoxESP.HealthColor.G, BoxESP.HealthColor.B, BoxESP.HealthColor.A))
    HealthImage:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    local HealthSlot = ParentCanvas:AddChildToCanvas(HealthImage)
    if not HealthSlot then return nil end
    HealthSlot:SetAutoSize(false); HealthSlot:SetZOrder(999); HealthSlot:SetAlignment(FVector2D(0.5, 1.0))

    local function CreateStyledTextBlock(defaultColor, fontSize, alignment)
        local txt = CGame:NewObjectFromPath("/Script/UMG.TextBlock", ParentCanvas)
        local slot = nil
        if txt and IsValid(txt) then
            txt:SetText("")
            local intSize = math.floor(fontSize or 10)
            if txt.Font then
                local f = txt.Font
                f.Size = intSize
                if f.OutlineSettings then
                    f.OutlineSettings.OutlineSize = 1
                    f.OutlineSettings.OutlineColor = FLinearColor(0.0, 0.0, 0.0, 1.0)
                end
                if txt.SetFont then txt:SetFont(f) else txt.Font = f end
            end
            if txt.SetFontSize then txt:SetFontSize(intSize) end
            txt:SetJustification(1)
            if txt.SetHorizontalAlignment then txt:SetHorizontalAlignment(1) end
            if txt.SetVerticalAlignment   then txt:SetVerticalAlignment(1) end
            if txt.SetAutoWrapText        then txt:SetAutoWrapText(false) end
            if FSlateColor then txt:SetColorAndOpacity(FSlateColor(defaultColor))
            else txt:SetColorAndOpacity(defaultColor) end
            if txt.SetShadowOffset then txt:SetShadowOffset(FVector2D(0.0, 0.0)) end
            if txt.SetShadowColorAndOpacity then txt:SetShadowColorAndOpacity(FLinearColor(0.0, 0.0, 0.0, 0.0)) end
            txt:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            slot = ParentCanvas:AddChildToCanvas(txt)
            if slot then
                slot:SetAutoSize(true); slot:SetZOrder(1000)
                slot:SetAlignment(alignment or FVector2D(0.5, 0.0))
            end
        end
        return txt, slot
    end

    local WeaponWidget, WeaponSlot = CreateStyledTextBlock(ColorYellow, 10, FVector2D(0.5, 1.0))
    local NameWidget,   NameSlot   = CreateStyledTextBlock(ColorBlue,   10, FVector2D(0.5, 0.0))
    local DistWidget,   DistSlot   = CreateStyledTextBlock(ColorWhite,  10, FVector2D(0.5, 0.0))
    local StateWidget,  StateSlot  = CreateStyledTextBlock(ColorGreen,  10, FVector2D(0.5, 0.0))

    local FlagImage = CGame:NewObjectFromPath("/Script/UMG.Image", ParentCanvas)
    local FlagSlot  = nil
    if FlagImage and IsValid(FlagImage) then
        FlagImage:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        FlagSlot = ParentCanvas:AddChildToCanvas(FlagImage)
        if FlagSlot then
            FlagSlot:SetAutoSize(false)
            FlagSlot:SetSize(FVector2D(14, 16))
            FlagSlot:SetZOrder(1000)
            FlagSlot:SetAlignment(FVector2D(0.5, 1.0))
        end
    end

    return {
        CornerContainer = CornerContainer, CornerSlot = CornerMainSlot, Corners = CornerLines,
        BgWidget = BgImage, BgSlot = BgSlot,
        HealthWidget = HealthImage, HealthSlot = HealthSlot,
        WeaponWidget = WeaponWidget, WeaponSlot = WeaponSlot,
        FlagWidget = FlagImage, FlagSlot = FlagSlot,
        NameWidget = NameWidget, NameSlot = NameSlot,
        DistWidget = DistWidget, DistSlot = DistSlot,
        StateWidget = StateWidget, StateSlot = StateSlot,
        _cachedWeapon = "", _cachedNation = nil, _cachedName = "",
        _cachedDist = "", _cachedState = "",
        _lastScanTime = 0, lastW = 0, lastH = 0, bVisible = true
    }
end

function BoxESP.UpdateCornerDimensions(boxData, width, height)
    if boxData.lastW and boxData.lastH then
        if math.abs(width - boxData.lastW) < 1.5 and math.abs(height - boxData.lastH) < 1.5 then return end
    end
    boxData.lastW = width; boxData.lastH = height
    local t = BoxESP.CornerThickness
    local cLen = math.max(7, math.min(width, height) * BoxESP.CornerLengthRatio)
    local C = boxData.Corners
    boxData.CornerSlot:SetSize(FVector2D(width, height))
    if C.TopLeft_H and C.TopLeft_H.slot         then C.TopLeft_H.slot:SetPosition(FVector2D(0, 0));               C.TopLeft_H.slot:SetSize(FVector2D(cLen, t)) end
    if C.TopLeft_V and C.TopLeft_V.slot         then C.TopLeft_V.slot:SetPosition(FVector2D(0, 0));               C.TopLeft_V.slot:SetSize(FVector2D(t, cLen)) end
    if C.TopRight_H and C.TopRight_H.slot       then C.TopRight_H.slot:SetPosition(FVector2D(width - cLen, 0));    C.TopRight_H.slot:SetSize(FVector2D(cLen, t)) end
    if C.TopRight_V and C.TopRight_V.slot       then C.TopRight_V.slot:SetPosition(FVector2D(width - t, 0));       C.TopRight_V.slot:SetSize(FVector2D(t, cLen)) end
    if C.BottomLeft_H and C.BottomLeft_H.slot   then C.BottomLeft_H.slot:SetPosition(FVector2D(0, height - t));    C.BottomLeft_H.slot:SetSize(FVector2D(cLen, t)) end
    if C.BottomLeft_V and C.BottomLeft_V.slot   then C.BottomLeft_V.slot:SetPosition(FVector2D(0, height - cLen)); C.BottomLeft_V.slot:SetSize(FVector2D(t, cLen)) end
    if C.BottomRight_H and C.BottomRight_H.slot then C.BottomRight_H.slot:SetPosition(FVector2D(width - cLen, height - t)); C.BottomRight_H.slot:SetSize(FVector2D(cLen, t)) end
    if C.BottomRight_V and C.BottomRight_V.slot then C.BottomRight_V.slot:SetPosition(FVector2D(width - t, height - cLen)); C.BottomRight_V.slot:SetSize(FVector2D(t, cLen)) end
end

function BoxESP.UpdateCanvasTransform(PC)
    if not BoxESP.ESPCanvas or not IsValid(BoxESP.ESPCanvas) then return end
    local success = false
    if SlateBlueprintLibrary and SlateBlueprintLibrary.AbsoluteToLocal then
        local cg = BoxESP.ESPCanvas:GetCachedGeometry()
        if cg then
            local pt0 = SlateBlueprintLibrary.AbsoluteToLocal(cg, FVector2D(0, 0))
            local pt1 = SlateBlueprintLibrary.AbsoluteToLocal(cg, FVector2D(100, 100))
            if pt0 and pt1 then
                BoxESP._CanvasScaleX  = (pt1.X - pt0.X) / 100
                BoxESP._CanvasScaleY  = (pt1.Y - pt0.Y) / 100
                BoxESP._CanvasOffsetX = pt0.X
                BoxESP._CanvasOffsetY = pt0.Y
                success = true
            end
        end
    end
    if not success and WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportScale then
        local scale = WidgetLayoutLibrary.GetViewportScale(PC) or 1.0
        BoxESP._CanvasScaleX  = 1.0 / scale
        BoxESP._CanvasScaleY  = 1.0 / scale
        BoxESP._CanvasOffsetX = 0
        BoxESP._CanvasOffsetY = 0
    end
end

function BoxESP.ProjectWorldToCanvasLocal(PC, WorldLoc)
    if not IsValid(PC) or not WorldLoc or not TempProjVec2D then return false, 0, 0 end
    local res = PC:ProjectWorldLocationToScreen(WorldLoc, TempProjVec2D, true)
    if (res == true or res == 1) and (TempProjVec2D.X ~= 0 or TempProjVec2D.Y ~= 0) then
        local fx = TempProjVec2D.X * BoxESP._CanvasScaleX + BoxESP._CanvasOffsetX
        local fy = TempProjVec2D.Y * BoxESP._CanvasScaleY + BoxESP._CanvasOffsetY
        return true, fx, fy
    end
    return false, 0, 0
end

function BoxESP.GetSnapLineStartPos(PC, ParentCanvas)
    local sw, sh, scale = 0, 0, 1.0
    pcall(function()
        if PC and PC.GetViewportSize then
            local vs = FVector2D(0, 0)
            PC:GetViewportSize(vs)
            if vs and vs.X and vs.X > 200 then sw = vs.X; sh = vs.Y end
        end
    end)
    if sw <= 200 then
        pcall(function()
            if WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportSize then
                local vs = WidgetLayoutLibrary.GetViewportSize(PC)
                if vs and vs.X and vs.X > 200 then sw = vs.X; sh = vs.Y end
            end
        end)
    end
    pcall(function()
        if WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportScale then
            local s = WidgetLayoutLibrary.GetViewportScale(PC)
            if s and type(s) == "number" and s > 0 then scale = s end
        end
    end)
    if sw <= 200 then sw = 1920 * scale; sh = 1080 * scale end
    local cx = sw / 2.0
    local cy = BoxESP.SnapLineOriginY * scale
    return cx * BoxESP._CanvasScaleX + BoxESP._CanvasOffsetX,
           cy * BoxESP._CanvasScaleY + BoxESP._CanvasOffsetY
end

function BoxESP.CreateSnapLine(ParentCanvas)
    if not IsValid(ParentCanvas) then return nil end
    local border = CGame:NewObjectFromPath("/Script/UMG.Border", ParentCanvas)
    if not IsValid(border) then return nil end
    border:SetBrushColor(ColorWhite)
    border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    border.RenderTransformPivot = FVector2D(0.0, 0.5)
    border:SetRenderTransformPivot(FVector2D(0.0, 0.5))
    local slot = ParentCanvas:AddChildToCanvas(border)
    if slot then slot:SetAutoSize(false); slot:SetZOrder(990) end
    return { Widget = border, Slot = slot, bVisible = true }
end

function BoxESP.UpdateSnapLine(KeyStr, toX, toY, fromX, fromY, CustomColor, ParentCanvas)
    local lineData = BoxESP.LineWidgets[KeyStr]
    if not lineData or not IsValid(lineData.Widget) then
        lineData = BoxESP.CreateSnapLine(ParentCanvas)
        if not lineData or not lineData.Widget or not lineData.Slot then return end
        BoxESP.LineWidgets[KeyStr] = lineData
    end
    if not lineData.bVisible then
        lineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        lineData.bVisible = true
    end
    if CustomColor then pcall(function() lineData.Widget:SetBrushColor(CustomColor) end) end
    local dx, dy = toX - fromX, toY - fromY
    local length = math.sqrt(dx * dx + dy * dy)
    local angle  = (math.atan2 and math.atan2(dy, dx) or math.atan(dy, dx)) * (180.0 / math.pi)
    local t = BoxESP.SnapLineThickness or 1.0
    if not lineData._CachedPosVec then
        lineData._CachedPosVec  = FVector2D(fromX, fromY - t * 0.5)
        lineData._CachedSizeVec = FVector2D(length, t)
    else
        lineData._CachedPosVec.X  = fromX
        lineData._CachedPosVec.Y  = fromY - t * 0.5
        lineData._CachedSizeVec.X = length
        lineData._CachedSizeVec.Y = t
    end
    pcall(function()
        lineData.Slot:SetPosition(lineData._CachedPosVec)
        lineData.Slot:SetSize(lineData._CachedSizeVec)
        lineData.Widget:SetRenderAngle(angle)
    end)
end

function BoxESP.HideSnapLine(KeyStr)
    local ld = BoxESP.LineWidgets[KeyStr]
    if ld and ld.Widget and IsValid(ld.Widget) and ld.bVisible then
        ld.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        ld.bVisible = false
    end
end

function BoxESP.CreateEnemyCounter(ParentCanvas, centerX, topY)
    local CD = BoxESP.CounterData
    if CD.ImgPlayer and IsValid(CD.ImgPlayer) and CD.ImgBot and IsValid(CD.ImgBot) then return true end
    local imgPlayer = CGame:NewObjectFromPath("/Script/UMG.Image", ParentCanvas)
    local slotPlayer = nil
    if imgPlayer and IsValid(imgPlayer) then
        imgPlayer:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        slotPlayer = ParentCanvas:AddChildToCanvas(imgPlayer)
        if slotPlayer then
            slotPlayer:SetAutoSize(false); slotPlayer:SetSize(FVector2D(BADGE_WIDTH, BADGE_HEIGHT))
            slotPlayer:SetPosition(FVector2D(centerX - BADGE_WIDTH, topY)); slotPlayer:SetZOrder(1005)
        end
    end
    local imgBot = CGame:NewObjectFromPath("/Script/UMG.Image", ParentCanvas)
    local slotBot = nil
    if imgBot and IsValid(imgBot) then
        imgBot:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        slotBot = ParentCanvas:AddChildToCanvas(imgBot)
        if slotBot then
            slotBot:SetAutoSize(false); slotBot:SetSize(FVector2D(BADGE_WIDTH, BADGE_HEIGHT))
            slotBot:SetPosition(FVector2D(centerX, topY)); slotBot:SetZOrder(1005)
        end
    end
    local function MakeCounterText(px, py)
        local txt = CGame:NewObjectFromPath("/Script/UMG.TextBlock", ParentCanvas)
        local sl = nil
        if txt and IsValid(txt) then
            txt:SetText("0")
            if txt.Font then
                local f = txt.Font; f.Size = 10
                if f.OutlineSettings then
                    f.OutlineSettings.OutlineSize = 0.0
                    f.OutlineSettings.OutlineColor = FLinearColor(0, 0, 0, 0)
                end
                txt.Font = f
            end
            if txt.SetFontSize then txt:SetFontSize(10) end
            txt:SetJustification(1)
            pcall(function() txt:SetAutoWrapText(false) end)
            if FSlateColor then txt:SetColorAndOpacity(FSlateColor(ColorWhite))
            else txt:SetColorAndOpacity(ColorWhite) end
            txt:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            sl = ParentCanvas:AddChildToCanvas(txt)
            if sl then
                sl:SetAutoSize(true); sl:SetAlignment(FVector2D(0.5, 0.5))
                sl:SetPosition(FVector2D(px, py)); sl:SetZOrder(1010)
            end
        end
        return txt, sl
    end
    local txtPlayer, slotTxtPlayer = MakeCounterText(centerX - (BADGE_WIDTH * 0.25), topY + (BADGE_HEIGHT * 0.5))
    local txtBot,    slotTxtBot    = MakeCounterText(centerX + (BADGE_WIDTH * 0.65), topY + (BADGE_HEIGHT * 0.5))
    LoadBadgeTexture(imgPlayer, ENEMY_COUNTER_PLAYER_URLS, "ic_danger_enemy.png", "Player", CD)
    LoadBadgeTexture(imgBot,    ENEMY_COUNTER_BOT_URLS,    "ic_clear_boot.png",   "Bot",    CD)
    CD.ImgPlayer = imgPlayer; CD.SlotPlayer = slotPlayer
    CD.ImgBot = imgBot; CD.SlotBot = slotBot
    CD.TxtPlayer = txtPlayer; CD.SlotTxtPlayer = slotTxtPlayer
    CD.TxtBot = txtBot; CD.SlotTxtBot = slotTxtBot
    CD.bCreated = true
    return true
end

function BoxESP.UpdateEnemyCounterDisplay(realCount, botCount, ParentCanvas, centerX, topY)
    local CD = BoxESP.CounterData
    if not BoxESP.bShowCounter then
        local col = UEnums.ESlateVisibility.Collapsed
        if CD.ImgPlayer and IsValid(CD.ImgPlayer) then CD.ImgPlayer:SetWidgetVisibility(col) end
        if CD.ImgBot    and IsValid(CD.ImgBot)    then CD.ImgBot:SetWidgetVisibility(col) end
        if CD.TxtPlayer and IsValid(CD.TxtPlayer) then CD.TxtPlayer:SetWidgetVisibility(col) end
        if CD.TxtBot    and IsValid(CD.TxtBot)    then CD.TxtBot:SetWidgetVisibility(col) end
        return
    end
    if not BoxESP.CreateEnemyCounter(ParentCanvas, centerX, topY) then return end
    local now = os.clock()
    if (not CD.PlayerLoaded or not CD.BotLoaded) and (now - CD.LastDownloadRetry > 2.0) then
        CD.LastDownloadRetry = now
        if not CD.PlayerLoaded and CD.ImgPlayer then LoadBadgeTexture(CD.ImgPlayer, ENEMY_COUNTER_PLAYER_URLS, "ic_danger_enemy.png", "Player", CD) end
        if not CD.BotLoaded    and CD.ImgBot    then LoadBadgeTexture(CD.ImgBot,    ENEMY_COUNTER_BOT_URLS,    "ic_clear_boot.png",   "Bot",    CD) end
    end
    pcall(function()
        if CD.SlotPlayer then CD.SlotPlayer:SetSize(FVector2D(BADGE_WIDTH, BADGE_HEIGHT)); CD.SlotPlayer:SetPosition(FVector2D(centerX - BADGE_WIDTH, topY)) end
        if CD.SlotBot    then CD.SlotBot:SetSize(FVector2D(BADGE_WIDTH, BADGE_HEIGHT));    CD.SlotBot:SetPosition(FVector2D(centerX, topY)) end
        if CD.SlotTxtPlayer then CD.SlotTxtPlayer:SetPosition(FVector2D(centerX - (BADGE_WIDTH * 0.25), topY + (BADGE_HEIGHT * 0.5))) end
        if CD.SlotTxtBot    then CD.SlotTxtBot:SetPosition(FVector2D(centerX + (BADGE_WIDTH * 0.65), topY + (BADGE_HEIGHT * 0.5))) end
        if CD.LastPlayerCount ~= realCount then
            if CD.TxtPlayer and IsValid(CD.TxtPlayer) then CD.TxtPlayer:SetText(tostring(realCount)) end
            CD.LastPlayerCount = realCount
        end
        if CD.LastBotCount ~= botCount then
            if CD.TxtBot and IsValid(CD.TxtBot) then CD.TxtBot:SetText(tostring(botCount)) end
            CD.LastBotCount = botCount
        end
        local vis = UEnums.ESlateVisibility.SelfHitTestInvisible
        if CD.ImgPlayer and IsValid(CD.ImgPlayer) then CD.ImgPlayer:SetWidgetVisibility(vis) end
        if CD.ImgBot    and IsValid(CD.ImgBot)    then CD.ImgBot:SetWidgetVisibility(vis) end
        if CD.TxtPlayer and IsValid(CD.TxtPlayer) then CD.TxtPlayer:SetWidgetVisibility(vis) end
        if CD.TxtBot    and IsValid(CD.TxtBot)    then CD.TxtBot:SetWidgetVisibility(vis) end
    end)
end

function BoxESP.HideWidget(boxData)
    if not boxData or not boxData.bVisible then return end
    boxData.bVisible = false
    local col = UEnums.ESlateVisibility.Collapsed
    if boxData.CornerContainer then boxData.CornerContainer:SetWidgetVisibility(col) end
    if boxData.BgWidget        then boxData.BgWidget:SetWidgetVisibility(col) end
    if boxData.HealthWidget    then boxData.HealthWidget:SetWidgetVisibility(col) end
    if boxData.WeaponWidget    then boxData.WeaponWidget:SetWidgetVisibility(col) end
    if boxData.FlagWidget      then boxData.FlagWidget:SetWidgetVisibility(col) end
    if boxData.NameWidget      then boxData.NameWidget:SetWidgetVisibility(col) end
    if boxData.DistWidget      then boxData.DistWidget:SetWidgetVisibility(col) end
    if boxData.StateWidget     then boxData.StateWidget:SetWidgetVisibility(col) end
end

function BoxESP.ShowWidget(boxData)
    if not boxData or boxData.bVisible then return end
    boxData.bVisible = true
    local vis = UEnums.ESlateVisibility.SelfHitTestInvisible
    if boxData.CornerContainer then boxData.CornerContainer:SetWidgetVisibility(vis) end
    if boxData.BgWidget        then boxData.BgWidget:SetWidgetVisibility(vis) end
    if boxData.HealthWidget    then boxData.HealthWidget:SetWidgetVisibility(vis) end
    if boxData.WeaponWidget    then boxData.WeaponWidget:SetWidgetVisibility(vis) end
    if boxData.FlagWidget      then boxData.FlagWidget:SetWidgetVisibility(vis) end
    if boxData.NameWidget      then boxData.NameWidget:SetWidgetVisibility(vis) end
    if boxData.DistWidget      then boxData.DistWidget:SetWidgetVisibility(vis) end
    if boxData.StateWidget     then boxData.StateWidget:SetWidgetVisibility(vis) end
end

function BoxESP.UpdateESP()
    if not BoxESP.bActive then return end

    local Cfg = _G.LexusConfig or {}

    if not Cfg.BoxESP then
        for _, bd in pairs(BoxESP.BoxWidgets) do BoxESP.HideWidget(bd) end
        for k, _ in pairs(BoxESP.LineWidgets) do BoxESP.HideSnapLine(k) end
        local CD = BoxESP.CounterData
        local col = UEnums.ESlateVisibility.Collapsed
        if CD.ImgPlayer and IsValid(CD.ImgPlayer) then CD.ImgPlayer:SetWidgetVisibility(col) end
        if CD.ImgBot    and IsValid(CD.ImgBot)    then CD.ImgBot:SetWidgetVisibility(col) end
        if CD.TxtPlayer and IsValid(CD.TxtPlayer) then CD.TxtPlayer:SetWidgetVisibility(col) end
        if CD.TxtBot    and IsValid(CD.TxtBot)    then CD.TxtBot:SetWidgetVisibility(col) end
        return
    end

    BoxESP.bShowLines   = Cfg.BoxESP_Lines   ~= false
    BoxESP.bShowCounter = Cfg.BoxESP_Counter ~= false

    local ParentCanvas = BoxESP.GetMainCanvas()
    if not ParentCanvas then return end

    local GameplayData = package.loaded["GameLua.GameCore.Data.GameplayData"] or _G.GameplayData
    if not GameplayData then return end

    local LocalPlayer = GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
    if not IsValid(LocalPlayer) then return end

    local PC = GameplayData.GetPlayerController and GameplayData.GetPlayerController()
    if not IsValid(PC) then return end

    local curTime = os.clock and os.clock() or 0
    if BoxESP._LastCanvas ~= ParentCanvas or (curTime - BoxESP._LastTransformTime > 1.0) then
        BoxESP.UpdateCanvasTransform(PC)
        BoxESP._LastCanvas = ParentCanvas
        BoxESP._LastTransformTime = curTime
    end

    local bRunHeavyTasks = (curTime - BoxESP._LastHeavyUpdateTime > 0.15)
    if bRunHeavyTasks then BoxESP._LastHeavyUpdateTime = curTime end

    local bUpdateVisCheck = (curTime - BoxESP._LastVisCheckTime > 0.12)
    if bUpdateVisCheck then BoxESP._LastVisCheckTime = curTime end

    local fromX, fromY = BoxESP.GetSnapLineStartPos(PC, ParentCanvas)

    local TeamID = LocalPlayer.TeamID or (LocalPlayer.GetTeamID and LocalPlayer:GetTeamID()) or 0
    local AllPawns = (Game and Game.GetAllPlayerPawns and Game:GetAllPlayerPawns()) or {}
    local SeenKeys = {}
    local RealPlayerCount = 0
    local BotCount = 0

    for Key, Pawn in pairs(AllPawns) do
        if IsValid(Pawn) and Pawn ~= LocalPlayer then
            local pawnTeam = Pawn.TeamID or (Pawn.GetTeamID and Pawn:GetTeamID()) or -1
            local isAlive = (Pawn.Health and Pawn.Health > 0) or (Pawn.IsAlive and Pawn:IsAlive())

            if isAlive and pawnTeam ~= TeamID then
                local KeyStr = tostring(Key)
                SeenKeys[KeyStr] = true

                local ping = (Pawn.PlayerState and Pawn.PlayerState.Ping) or Pawn.Ping or (Pawn.GetPing and Pawn:GetPing()) or -1
                ping = tonumber(ping) or -1
                local isBot = (ping >= 0 and ping <= 3) or Pawn.bIsAI or Pawn.bIsAIBot or Pawn.bIsABot or (Game and Game.IsAI and Game:IsAI(Pawn))

                if isBot then BotCount = BotCount + 1 else RealPlayerCount = RealPlayerCount + 1 end

                local Loc = Pawn.K2_GetActorLocation and Pawn:K2_GetActorLocation()
                if not Loc and Pawn.RootComponent then
                    Loc = Pawn.RootComponent:K2_GetComponentLocation()
                end

                if Loc then
                    local topWorldPos, bottomWorldPos = nil, nil
                    local mesh = Pawn.Mesh or (Pawn.GetMesh and Pawn:GetMesh()) or Pawn.CharacterMesh0
                    if mesh and mesh.GetSocketLocation then
                        local hLoc = mesh:GetSocketLocation("Head") or mesh:GetSocketLocation("head")
                        if hLoc and (hLoc.X ~= 0 or hLoc.Y ~= 0 or hLoc.Z ~= 0) then
                            topWorldPos = FVector(hLoc.X, hLoc.Y, hLoc.Z + 15)
                        end
                        local rLoc = mesh:GetSocketLocation("root") or mesh:GetSocketLocation("Root")
                        if rLoc and (rLoc.X ~= 0 or rLoc.Y ~= 0 or rLoc.Z ~= 0) then
                            bottomWorldPos = rLoc
                        end
                    end

                    local isProne, isCrouch = false, false
                    if Pawn.bIsProning or Pawn.bIsProne or (Pawn.IsProne and Pawn:IsProne()) or Pawn.PoseState == 2 or Pawn.PoseState == "Prone" then
                        isProne = true
                    elseif Pawn.bIsCrouched or (Pawn.IsCrouched and Pawn:IsCrouched()) or Pawn.PoseState == 1 or Pawn.PoseState == "Crouch" then
                        isCrouch = true
                    end

                    if not topWorldPos or not bottomWorldPos then
                        local topOffset    = isProne and 18 or (isCrouch and 50 or 88)
                        local bottomOffset = isProne and -22 or (isCrouch and -68 or -90)
                        topWorldPos    = topWorldPos    or FVector(Loc.X, Loc.Y, Loc.Z + topOffset)
                        bottomWorldPos = bottomWorldPos or FVector(Loc.X, Loc.Y, Loc.Z + bottomOffset)
                    end

                    local bTopOk, topX, topY          = BoxESP.ProjectWorldToCanvasLocal(PC, topWorldPos)
                    local bBottomOk, bottomX, bottomY = BoxESP.ProjectWorldToCanvasLocal(PC, bottomWorldPos)

                    local boxData = BoxESP.BoxWidgets[KeyStr]
                    if not boxData then
                        boxData = BoxESP.CreateESPWidget(ParentCanvas)
                        if boxData then BoxESP.BoxWidgets[KeyStr] = boxData end
                    end

                    if boxData and IsValid(boxData.CornerContainer) then
                        if bTopOk and bBottomOk then
                            local boxHeight = math.max(28, math.abs(bottomY - topY))
                            local boxWidth  = math.max(15, boxHeight * (isProne and 1.1 or (isCrouch and 0.7 or 0.55)))

                            local centerX = (topX + bottomX) * 0.5
                            local centerY = (topY + bottomY) * 0.5
                            local boxTopY    = centerY - (boxHeight * 0.5)
                            local boxBottomY = centerY + (boxHeight * 0.5)

                            BoxESP.UpdateCornerDimensions(boxData, boxWidth, boxHeight)
                            boxData.CornerSlot:SetPosition(FVector2D(centerX, centerY))
                            BoxESP.ShowWidget(boxData)

                            if Cfg.BoxESP_Health ~= false then
                                local healthBarWidth = BoxESP.HealthBarWidth or 2.0
                                local healthCenterX  = centerX - (boxWidth * 0.5) - 2.5 - (healthBarWidth * 0.5)
                                local health    = Pawn.Health or (Pawn.GetHealth and Pawn:GetHealth()) or 100
                                local healthMax = Pawn.HealthMax or (Pawn.GetHealthMax and Pawn:GetHealthMax()) or 100
                                if healthMax <= 0 then healthMax = 100 end
                                local healthPercent = math.max(0, math.min(1, health / healthMax))
                                local currentHealthHeight = boxHeight * healthPercent

                                boxData.BgSlot:SetSize(FVector2D(healthBarWidth, boxHeight))
                                boxData.BgSlot:SetPosition(FVector2D(healthCenterX, boxBottomY))
                                boxData.HealthSlot:SetSize(FVector2D(healthBarWidth, currentHealthHeight))
                                boxData.HealthSlot:SetPosition(FVector2D(healthCenterX, boxBottomY))
                                boxData.BgWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                                boxData.HealthWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                            else
                                boxData.BgWidget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                                boxData.HealthWidget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                            end

                            if Cfg.BoxESP_Weapon ~= false then
                                if bRunHeavyTasks or boxData._cachedWeapon == "" then
                                    local wep = (Pawn.GetCurrentWeapon and Pawn:GetCurrentWeapon())
                                        or (Pawn.GetCurrentShootWeapon and Pawn:GetCurrentShootWeapon())
                                        or (Pawn.WeaponManagerComponent and Pawn.WeaponManagerComponent.CurrentWeaponReplicated)
                                    local weaponName = "Fist"
                                    if wep and IsValid(wep) then
                                        local wn = (type(wep.GetWeaponName) == "function" and wep:GetWeaponName()) or wep.WeaponName
                                        if wn and wn ~= "" then
                                            weaponName = tostring(wn):gsub("^BP_", ""):gsub("_C$", ""):gsub("_Wrapper$", "")
                                        end
                                    end
                                    if boxData._cachedWeapon ~= weaponName then
                                        boxData.WeaponWidget:SetText(weaponName)
                                        boxData._cachedWeapon = weaponName
                                    end
                                end
                                boxData.WeaponSlot:SetPosition(FVector2D(centerX, boxTopY - 3.5))
                                boxData.WeaponWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                            else
                                boxData.WeaponWidget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                            end

                            if Cfg.BoxESP_Flag ~= false then
                                if bRunHeavyTasks or not boxData._cachedNation then
                                    local playerNation = (Pawn.PlayerState and Pawn.PlayerState.Nation) or Pawn.Nation or ""
                                    playerNation = tostring(playerNation or "")
                                    if playerNation == "" or playerNation == "nil" or playerNation == "0" then playerNation = "G1" end

                                    if boxData._cachedNation ~= playerNation then
                                        local cfg = (CDataTable and CDataTable.GetTableData) and CDataTable.GetTableData("RegionConfig", playerNation)
                                        if not cfg or not cfg.res_path or cfg.res_path == "" then
                                            cfg = (CDataTable and CDataTable.GetTableData) and CDataTable.GetTableData("RegionConfig", "G1")
                                        end
                                        local flagPath = (cfg and cfg.res_path) or "/Game/UMG/Texture/Atlas/NationalflagUI/Frames/T_icon_flag_iland_png.T_icon_flag_iland_png"

                                        if boxData.FlagWidget and IsValid(boxData.FlagWidget) then
                                            local bSet = false
                                            if boxData.FlagWidget.SetBrushResourceFromPathSync then
                                                boxData.FlagWidget:SetBrushResourceFromPathSync(flagPath, false); bSet = true
                                            end
                                            if not bSet and boxData.FlagWidget.SetBrushFromPathAsync then
                                                boxData.FlagWidget:SetBrushFromPathAsync(flagPath, false); bSet = true
                                            end
                                            if not bSet then
                                                local util = package.loaded["client.slua_ui_framework.util"]
                                                if not util then pcall(function() util = require("client.slua_ui_framework.util") end) end
                                                if util and util.SetTexture then
                                                    util.SetTexture(boxData.FlagWidget, flagPath, { sync = true }); bSet = true
                                                end
                                            end
                                            if not bSet then
                                                local asset_util = package.loaded["common.asset_util"]
                                                if not asset_util then pcall(function() asset_util = require("common.asset_util") end) end
                                                local flagTex = (asset_util and asset_util.GetAssetSync and asset_util.GetAssetSync(flagPath))
                                                             or (CGame and CGame.LoadObject and CGame:LoadObject(flagPath))
                                                if flagTex and boxData.FlagWidget.SetBrushFromTexture then
                                                    boxData.FlagWidget:SetBrushFromTexture(flagTex, false); bSet = true
                                                end
                                            end
                                        end
                                        boxData._cachedNation = playerNation
                                    end
                                end
                                if boxData.FlagSlot then boxData.FlagSlot:SetPosition(FVector2D(centerX, boxTopY - 22.0)) end
                                boxData.FlagWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                            else
                                boxData.FlagWidget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                            end

                            if Cfg.BoxESP_Name ~= false then
                                if bRunHeavyTasks or boxData._cachedName == "" then
                                    local playerName = isBot and "Bot" or (Pawn.PlayerName or Pawn.PlayerNamePublic or (Pawn.GetPlayerName and Pawn:GetPlayerName()) or "Player")
                                    playerName = tostring(playerName)
                                    if boxData._cachedName ~= playerName then
                                        boxData.NameWidget:SetText(playerName)
                                        boxData._cachedName = playerName
                                    end
                                end
                                boxData.NameSlot:SetPosition(FVector2D(centerX, boxBottomY + 4.0))
                                boxData.NameWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                            else
                                boxData.NameWidget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                            end

                            if Cfg.BoxESP_Distance ~= false then
                                local distVal = math.floor(LocalPlayer:GetDistanceTo(Pawn) / 100.0)
                                local distStr = tostring(distVal) .. "m"
                                if boxData._cachedDist ~= distStr then
                                    boxData.DistWidget:SetText(distStr)
                                    boxData._cachedDist = distStr
                                end
                                boxData.DistSlot:SetPosition(FVector2D(centerX, boxBottomY + 20.5))
                                boxData.DistWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                            else
                                boxData.DistWidget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                            end

                            if bUpdateVisCheck or BoxESP._VisCheckCache[KeyStr] == nil then
                                BoxESP._VisCheckCache[KeyStr] = (PC and PC.LineOfSightTo and PC:LineOfSightTo(Pawn)) or false
                            end
                            local isVisible = BoxESP._VisCheckCache[KeyStr]

                            if Cfg.BoxESP_State ~= false then
                                if bRunHeavyTasks or boxData._cachedState == "" then
                                    local isKnocked = (Pawn.HealthStatus == 1 or Pawn.bIsKnocked or (Pawn.IsKnocked and Pawn:IsKnocked()))
                                    local stateStr = "Open"
                                    local slateCol = SlateColorGreen
                                    if isKnocked then
                                        stateStr = "Knocked"; slateCol = SlateColorRed
                                    elseif not isVisible then
                                        stateStr = "Cover";   slateCol = SlateColorRed
                                    end
                                    if boxData._cachedState ~= stateStr then
                                        boxData.StateWidget:SetText(stateStr)
                                        boxData.StateWidget:SetColorAndOpacity(slateCol)
                                        boxData._cachedState = stateStr
                                    end
                                end
                                boxData.StateSlot:SetPosition(FVector2D(centerX, boxBottomY + 37.0))
                                boxData.StateWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                            else
                                boxData.StateWidget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                            end

                            if BoxESP.bShowLines then
                                local lineColor = isVisible and ColorGreen or ColorRed
                                BoxESP.UpdateSnapLine(KeyStr, centerX, boxTopY, fromX, fromY, lineColor, ParentCanvas)
                            else
                                BoxESP.HideSnapLine(KeyStr)
                            end
                        else
                            BoxESP.HideWidget(boxData)
                            BoxESP.HideSnapLine(KeyStr)
                        end
                    end
                end
            end
        end
    end

    for KeyStr, boxData in pairs(BoxESP.BoxWidgets) do
        if not SeenKeys[KeyStr] then BoxESP.HideWidget(boxData) end
    end
    for KeyStr, _ in pairs(BoxESP.LineWidgets) do
        if not SeenKeys[KeyStr] then
            BoxESP.HideSnapLine(KeyStr)
            BoxESP._VisCheckCache[KeyStr] = nil
        end
    end

    local counterTopY = fromY - BADGE_HEIGHT - 2
    if counterTopY < 10 then counterTopY = 48 end
    BoxESP.UpdateEnemyCounterDisplay(RealPlayerCount, BotCount, ParentCanvas, fromX, counterTopY)
end

-- ============================================================
-- ========== SKIN MOD SECTION (from No Lag Full Skin) ==========
-- ============================================================

local _slua = rawget(_G, "slua")
local function Valid(obj)
    if not obj then return false end
    if _slua and _slua.isValid then
        local ok, v = pcall(_slua.isValid, obj)
        if not ok or not v then return false end
    end
    return true
end

_G.SumeyyeState = _G.SumeyyeState or {
    LoopToken = 0, NativeESPReady = false, MenuStep = 0, GraphicsUnlocked = false,
    TrackedMarks = {}, EnemyMarks = {}, CustomTextData = nil,
    PrevGraphicsState = {}, LastMagicConfigHash = "",
}

_G.SumeyyeConfig = _G.SumeyyeConfig or {
    ModEmote = false, ModSkin = false, SkinDeadBox = false, SkinAttachment = false,
    KillMessage = false, KillCountUI = false, SkinOpenLink = false,
}
_G.SumeyyeConfig.ModSkin = true

_G.SumeyyeHax = _G.SumeyyeHax or { BlackSky = true }

-- ========== FOV (multi-path) ==========
local FOV_PATHS = {
    "/storage/emulated/0/Android/data/com.tencent.igfit/files/BeysaIPad.ini",
    "/storage/emulated/0/Android/data/com.tencent.ig/files/BeysaIPad.ini",
    "/storage/emulated/0/Android/data/com.vng.pubgmobile/files/BeysaIPad.ini",
}
local FOV_INI_PATH = FOV_PATHS[1]
local FOV_TPP = 115
local FOV_FPP = 103

local function ReadFOVConfig()
    local path = nil
    for _, p in ipairs(FOV_PATHS) do
        if FileExists(p) then path = p; break end
    end
    if not path then
        path = FOV_PATHS[1]
        local f = io.open(path, "w")
        if f then f:write("[FOV]\nTPP=125\nFPP=103\n"); f:close() end
        return
    end
    FOV_INI_PATH = path
    local file = io.open(path, "r")
    if not file then return end
    local new_TPP, new_FPP = FOV_TPP, FOV_FPP
    for line in file:lines() do
        local key, val = line:match("^%s*(%w+)%s*=%s*(%d+)%s*$")
        if key and val then
            val = tonumber(val)
            if key == "TPP" and val >= 80 and val <= 180 then new_TPP = val
            elseif key == "FPP" and val >= 80 and val <= 180 then new_FPP = val end
        end
    end
    file:close()
    FOV_TPP = new_TPP
    FOV_FPP = new_FPP
end

local function ApplyFOVToCameras(playerChar)
    if not slua.isValid(playerChar) then return end
    local tppCam = playerChar.ThirdPersonCameraComponent
    local fppCam = playerChar.FirstPersonCameraComponent
    local isAiming = playerChar.bIsWeaponAiming or false
    if not isAiming then
        if slua.isValid(tppCam) and FOV_TPP > 80 then
            tppCam:SetFieldOfView(FOV_TPP)
            tppCam.FieldOfView = FOV_TPP
        end
        if slua.isValid(fppCam) and FOV_FPP > 80 then
            fppCam:SetFieldOfView(FOV_FPP)
            fppCam.FieldOfView = FOV_FPP
        end
    end
end

-- ========== Attachments (from skin mod) ==========
_G.VIP_Attachments = {
    [1101004236]={1010042307,1010042306,1010042308,1010042304,1010042300,1010042305,1010042299,1010042298,1010042297,1010042296,1010042295,1010042294,0,1010042314,1010042309,1010042316,1010042317,1010042318,1010042310,1010042315,1010042319,0},
    [1101001116]={1010011106,1010011107,1010011108,0,1010011109,1010011112,1010011105,1010011104,1010011103,0,1010011102,0,0,0,0,0,0,0,0,0,0,0},
    [1101001128]={1010011232,1010011233,1010011234,1010011228,1010011227,1010011229,1010011226,1010011225,1010011224,1010011223,1010011222,0,0,0,0,0,0,0,0,0,0,0},
    [1101001154]={1010011487,1010011488,1010011489,1010011493,1010011490,1010011494,1010011486,1010011485,1010011484,1010011483,1010011482,1010011497,0,0,0,0,0,0,0,0,1010011498,0},
    [1101001174]={1010011667,1010011668,1010011669,1010011673,1010011670,1010011674,1010011666,1010011665,1010011664,1010011663,1010011662,0,0,0,0,0,0,0,0,0,0,0},
    [1101001213]={1010012067,1010012068,1010012069,1010012072,1010012070,1010012073,1010012066,1010012065,1010012064,1010012063,1010012062,0,0,0,0,0,0,0,0,1010012074,0},
    [1101001231]={1010012267,1010012268,1010012269,1010012273,1010012272,1010012274,1010012266,1010012265,1010012264,1010012263,1010012262,1010012075,0,0,0,0,0,0,0,0,1010012275,0},
    [1101001242]={1010012357,1010012358,1010012359,1010012363,1010012362,1010012364,1010012356,1010012355,1010012354,1010012353,1010012352,1010012276,0,0,0,0,0,0,0,0,1010012365,0},
    [1101001249]={1010012437,1010012438,1010012439,1010012443,1010012442,1010012444,1010012436,1010012435,1010012434,1010012433,1010012432,1010012366,0,0,0,0,0,0,0,0,1010012445,0},
    [1101001256]={1010012588,1010012589,1010012590,1010012593,1010012592,1010012594,1010012587,1010012586,1010012585,1010012584,1010012583,1010012582,0,0,0,0,0,0,0,0,1010012595,0},
    [1101001265]={1010012698,1010012699,1010012700,1010012703,1010012702,1010012704,1010012697,1010012696,1010012695,1010012694,1010012693,1010012692,0,0,0,0,0,0,0,0,1010012705,0},
    [1101001276]={1010012698,1010012699,1010012700,1010012703,1010012702,1010012704,1010012697,1010012696,1010012695,1010012694,1010012693,1010012692,0,0,0,0,0,0,0,0,1010012705,0},
    [1101002029]={1010020249,1010020250,1010020255,1010020247,1010020246,1010020248,1010020240,1010020239,1010020238,1010020237,1010020236,1010020235,0,0,0,0,0,0,0,1010020257,1010020256,1010020258},
    [1101002056]={1010020519,0,0,1010020517,1010020516,1010020518,1010020500,1010020509,1010020508,1010020507,1010020506,1010020505,0,0,0,0,0,0,0,0,0,0},
    [1101002081]={1010020768,1010020769,1010020770,1010020766,1010020760,1010020767,1010020759,1010020758,1010020757,1010020756,1010020755,1010020776,0,0,0,0,0,0,0,1010020775,1010020777,1010020778},
    [1101003070]={1010030654,1010030653,1010030655,1010030649,1010030648,1010030650,1010030647,1010030646,1010030645,1010030644,1010030643,1010030642,0,1010030658,1010030656,1010030660,1010030662,1010030659,1010030657,0,1010030663,0},
    [1101003080]={1010030754,1010030753,1010030755,1010030749,1010030748,1010030750,1010030747,1010030746,1010030745,1010030744,1010030743,1010030742,0,1010030758,1010030756,1010030760,1010030762,1010030759,1010030757,0,1010030763,0},
    [1101003099]={1010030943,1010030944,1010030945,1010030939,1010030938,1010030942,1010030937,1010030936,1010030935,1010030934,1010030933,1010030932,0,1010030947,1010030946,1010030948,1010030949,1010030953,1010030952,0,1010030955,0},
    [1101003119]={1010031139,1010031140,1010031142,1010031138,1010031137,1010031146,1010031136,1010031135,1010031134,1010031133,1010031132,0,0,1010031144,1010031143,0,0,0,1010031145,0,0,0},
    [1101003146]={1010031229,1010031230,1010031237,1010031228,1010031227,1010031242,1010031226,1010031225,1010031224,1010031223,1010031222,0,0,1010031239,1010031238,0,0,0,1010031240,0,0,0},
    [1101003167]={1010031609,1010031610,1010031613,1010031608,1010031607,1010031617,1010031606,1010031605,1010031604,1010031603,1010031602,1010031618,0,1010031615,1010031614,1010031620,1010031622,1010031619,1010031616,0,1010031623,0},
    [1101003181]={1010031765,1010031764,1010031766,1010031759,1010031758,1010031763,1010031757,1010031756,1010031755,1010031754,1010031753,1010031752,0,1010031769,1010031767,1010031773,1010031774,1010031772,1010031768,0,1010031775,0},
    [1101003195]={1010031912,1010031911,1010031913,1010031908,1010031907,1010031909,1010031906,1010031905,1010031904,1010031903,1010031902,1010031901,0,1010031916,1010031914,1010031918,1010031919,1010031917,1010031915,0,1010031921,0},
    [1101003208]={1010032034,1010032033,1010032045,1010032029,1010032028,1010032032,1010032027,1010032026,1010032025,1010032024,1010032023,1010032022,0,1010032038,1010032036,1010032042,1010032043,1010032039,1010032037,0,1010032044,0},
    [1101004046]={1010040474,1010040475,1010040476,1010040472,1010040471,1010040473,1010040470,1010040469,1010040468,1010040467,1010040466,1010040481,0,1010040479,1010040477,1010040482,1010040483,1010040484,1010040478,1010040480,1010040485,0},
    [1101004062]={1010040578,1010040577,1010040579,1010040575,1010040570,1010040576,1010040569,1010040568,1010040567,1010040566,1010040565,1010040564,0,1010040585,1010040580,1010040587,1010040588,1010040589,1010040584,1010040586,1010040590,1010040594},
    [1101004098]={1010040924,1010040926,1010040925,0,1010040937,1010040938,1010040935,1010040934,1010040929,1010040928,1010040927,0,0,1010040939,1010040945,0,0,0,1010040944,1010040936,0,0},
    [1101004138]={1010041136,1010041137,1010041138,1010041134,1010041129,1010041135,1010041128,1010041127,1010041126,1010041125,1010041124,0,0,1010041145,1010041139,0,0,0,1010041144,1010041146,0,0},
    [1101004163]={1010041570,1010041574,1010041575,1010041568,1010041567,1010041569,1010041566,1010041565,1010041564,1010041560,1010041554,0,0,1010041578,1010041576,0,0,0,1010041577,1010041579,0,0},
    [1101004201]={1010041956,1010041957,1010041958,1010041950,1010041949,1010041955,1010041948,1010041947,1010041946,1010041945,1010041944,1010041967,0,1010041965,1010041959,0,0,0,1010041960,1010041966,0,0},
    [1101004209]={1010042038,1010042037,1010042039,1010042035,1010042034,1010042036,1010042029,1010042028,1010042027,1010042026,1010042025,1010042024,0,1010042046,1010042044,1010042048,1010042049,1010042054,1010042045,1010042047,1010042055,0},
    [1101004218]={1010042128,1010042127,1010042129,1010042125,1010042124,1010042126,1010042119,1010042118,1010042117,1010042116,1010042115,1010042114,0,1010042136,1010042134,1010042138,1010042139,1010042144,1010042135,1010042137,1010042145,0},
    [1101004226]={1010042238,1010042237,1010042239,1010042235,1010042234,1010042236,1010042233,1010042232,1010042231,1010042219,1010042218,1010042217,0,1010042243,1010042241,1010042245,1010042246,1010042247,1010042242,1010042244,1010042248,0},
    [1101004246]={1010042406,1010042407,1010042408,1010042404,1010042400,1010042405,1010042399,1010042398,1010042397,1010042396,1010042395,1010042394,0,1010042414,1010042409,1010042416,1010042417,1010042418,1010042410,1010042415,1010042419,1010042420},
    [1101005038]={0,0,1010050327,1010050329,1010050328,1010050330,1010050326,1010050325,1010050324,1010050323,1010050322,1010050334,0,0,0,0,0,0,0,0,0,0},
    [1101005052]={0,0,1010050467,1010050469,1010050468,1010050470,1010050466,1010050465,1010050464,1010050463,1010050462,1010050473,0,0,0,0,0,0,0,0,0,0},
    [1101005098]={0,0,1010050928,1010050930,1010050929,1010050932,1010050927,1010050926,1010050925,1010050924,1010050923,1010050922,0,0,0,0,0,0,0,0,0,0},
    [1101006062]={1010060573,1010060572,1010060574,1010060564,1010060563,1010060571,1010060562,1010060561,1010060554,1010060553,1010060552,1010060551,0,1010060583,1010060581,1010060591,1010060592,1010060584,1010060582,0,1010060593,0},
    [1101006075]={1010060702,1010060701,1010060703,1010060698,1010060697,1010060699,1010060696,1010060695,1010060694,1010060693,1010060692,1010060691,0,1010060706,1010060704,1010060708,1010060709,1010060707,1010060705,0,1010060711,0},
    [1101006085]={1010060796,1010060795,1010060797,1010060793,1010060789,1010060794,1010060788,1010060787,1010060786,1010060785,1010060784,1010060783,0,1010060800,1010060798,1010060804,1010060805,1010060803,1010060799,0,1010060806,0},
    [1101007046]={1010070410,1010070413,1010070414,1010070408,1010070407,1010070409,1010070406,1010070405,1010070404,1010070403,1010070402,1010070418,0,1010070417,1010070415,1010070420,1010070422,1010070419,1010070416,0,1010070423,0},
    [1101007062]={1010070579,1010070578,1010070581,1010070576,1010070575,1010070577,1010070574,1010070573,1010070572,1010070571,1010070569,1010070568,0,1010070584,1010070582,1010070585,1010070586,1010070587,1010070583,0,1010070588,0},
    [1101007071]={1010070663,1010070662,1010070664,1010070659,1010070658,1010070660,1010070657,1010070656,1010070655,1010070654,1010070653,1010070652,0,1010070667,1010070665,1010070668,1010070669,1010070670,1010070666,0,1010070672,0},
    [1101008051]={1010080463,1010080464,1010080465,1010080459,1010080458,1010080462,1010080457,1010080456,1010080455,1010080454,1010080453,1010080452,0,1010080467,1010080466,1010080468,1010080469,1010080473,1010080472,0,1010080475,0},
    [1101008061]={1010080563,1010080564,1010080565,1010080559,1010080558,1010080562,1010080557,1010080556,1010080555,1010080554,1010080553,0,0,1010080567,1010080566,0,0,0,1010080572,0,0,0},
    [1101008070]={1010080609,1010080612,1010080613,1010080608,1010080607,1010080617,1010080606,1010080605,1010080604,1010080603,1010080602,0,0,1010080615,1010080614,0,0,0,1010080616,0,0,0},
    [1101008081]={1010080740,1010080743,1010080745,1010080738,1010080737,1010080739,1010080736,1010080735,1010080734,1010080733,1010080732,1010080748,0,1010080747,1010080746,1010080750,1010080752,1010080749,1010080744,0,1010080753,0},
    [1101008104]={1010080980,1010080982,1010080984,1010080978,1010080977,1010080979,1010080976,1010080975,1010080974,1010080973,1010080972,1010080992,0,1010080986,1010080985,1010080989,1010080987,1010080993,1010080983,0,1010080988,0},
    [1101008116]={1010081110,1010081112,1010081114,1010081108,1010081107,1010081109,1010081106,1010081105,1010081104,1010081103,1010081102,0,0,1010081116,1010081115,0,0,0,1010081113,0,0,0},
    [1101008126]={1010081210,1010081225,1010081226,1010081208,1010081207,1010081209,1010081206,1010081205,1010081204,1010081203,1010081202,1010081218,0,1010081217,1010081216,1010081219,1010081220,1010081222,1010081214,1010081228,1010081227,1010081229},
    [1101008136]={1010081314,1010081315,1010081316,1010081312,1010081308,1010081313,1010081307,1010081306,1010081305,1010081304,1010081303,1010081302,0,1010081318,1010081317,1010081322,1010081323,1010081325,1010081324,0,1010081326,0},
    [1101008146]={1010081401,1010081402,1010081403,1010081398,1010081397,1010081399,1010081396,1010081395,1010081394,1010081393,1010081392,1010081391,0,1010081405,1010081404,1010081406,1010081407,1010081409,1010081408,0,1010081411,0},
    [1101008154]={1010081531,1010081532,1010081533,1010081528,1010081527,1010081529,1010081526,1010081525,1010081524,1010081523,1010081522,1010081521,0,1010081541,1010081534,1010081542,1010081543,1010081545,1010081544,0,1010081546,0},
    [1101008163]={1010081582,1010081583,1010081584,1010081579,1010081578,1010081580,1010081577,1010081576,1010081575,1010081574,1010081573,1010081572,0,1010081586,1010081585,1010081587,1010081588,1010081590,1010081589,0,1010081592,0},
    [1101012033]={1010120284,1010120285,1010120286,1010120280,1010120279,1010120283,1010120278,1010120277,1010120276,1010120275,1010120274,1010120273,0,0,0,0,0,0,0,0,1010120287,0},
    [1101100012]={1011000066,1011000067,1011000068,0,0,0,1011000058,1011000057,1011000056,1011000055,1011000054,1011000053,0,0,0,0,0,0,0,0,1011000073,0},
    [1101102007]={1011010025,1011010024,1011010026,1011010020,1011010019,1011010023,1011010018,1011010017,1011010016,1011010015,1011010014,1011010013,0,0,0,0,0,0,0,0,1011010027,0},
    [1101102017]={1011020027,1011020028,1011020029,1011020025,1011020024,1011020026,1011020019,1011020018,1011020017,1011020016,1011020015,1011020014,0,1011020036,1011020034,1011020038,1011020039,1011020044,1011020035,1011020037,1011020045,1011020047},
    [1101102025]={1011020127,1011020128,1011020129,1011020125,1011020124,1011020126,1011020119,1011020118,1011020117,1011020116,1011020115,1011020114,0,1011020136,1011020134,1011020138,1011020139,1011020144,1011020135,1011020137,1011020145,0},
    [1101102041]={1011020214,1011020215,1011020216,1011020212,1011020211,1011020213,1011020209,1011020208,1011020207,1011020206,1011020205,1011020204,0,1011020219,1011020217,1011020222,1011020223,1011020224,1011020218,1011020221,1011020225,1011020229},
    [1101102049]={1011020356,1011020357,1011020358,1011020354,1011020350,1011020355,1011020349,1011020348,1011020347,1011020346,1011020345,1011020344,0,1011020364,1011020359,1011020366,1011020367,1011020368,1011020360,1011020365,1011020369,1011020370},
    [1101101007]={1011020436,1011020437,1011020438,1011020434,1011020430,1011020435,1011020429,1011020428,1011020427,1011020426,1011020425,1011020424,0,1011020444,1011020439,1011020446,1011020447,1011020448,1011020440,1011020445,1011020449,1011020450},
    [1102001120]={1020011137,1020011138,1020011139,1020011135,1020011134,1020011136,1020011133,1020011132,0,0,0,0,0,0,0,0,0,0,0,1020011142,0,0},
    [1102001130]={1020011247,1020011248,1020011249,1020011245,1020011244,1020011246,1020011243,1020011242,0,0,0,0,0,0,0,0,0,0,0,1020011250,0,0},
    [1102002043]={1020020372,1020020374,1020020373,1020020383,1020020380,1020020384,1020020379,1020020378,1020020377,1020020376,1020020375,1020020388,0,1020020385,1020020387,0,0,0,1020020386,0,0,0},
    [1102002061]={1020020552,1020020554,1020020553,1020020563,1020020562,1020020564,1020020559,1020020558,1020020557,1020020556,1020020555,1020020578,0,1020020565,1020020567,1020020573,1020020574,1020020572,1020020566,0,1020020569,0},
    [1102002136]={1020021314,1020021313,1020021315,1020021309,1020021308,1020021312,1020021307,1020021306,1020021305,1020021304,1020021303,1020021302,0,1020021318,1020021316,1020021323,1020021324,1020021322,1020021317,0,1020021325,0},
    [1102002424]={1020024193,1020024192,1020024194,1020024189,1020024188,1020024190,1020024187,1020024186,1020024185,1020024184,1020024183,1020024182,0,1020024197,1020024195,1020024199,1020024200,1020024198,1020024196,0,1020024202,0},
    [1102003080]={1020030755,1020030756,1020030758,0,1020030749,1020030754,1020030748,1020030747,1020030746,1020030745,1020030744,1020030764,0,1020030760,0,1020030759,1020030757,0,0,1020030765,0,0},
    [1102003100]={1020030956,1020030957,1020030958,1020030954,1020030950,1020030955,1020030949,1020030948,1020030947,1020030946,1020030945,1020030944,0,1020030964,0,1020030960,1020030959,1020030965,0,1020030967,1020030966,1020030968},
    [1102005064]={1020050588,1020050589,1020050590,0,0,0,1020050587,1020050586,1020050585,1020050584,1020050583,1020050582,0,0,0,0,0,0,0,0,1020050592,0},
    [1103001101]={1030010954,1030010955,1030010956,0,0,0,0,0,0,0,1030010953,1030010952,1030010951,0,0,0,0,0,0,1030010957,0,1030010958},
    [1103001146]={1030011344,1030011345,1030011346,0,0,0,0,0,0,0,1030011343,1030011342,1030011341,0,0,0,0,0,0,1030011347,0,1030011348},
    [1103001154]={1030011484,1030011485,1030011486,0,0,0,0,0,0,0,1030011483,1030011482,1030011481,0,0,0,0,0,0,1030011487,0,1030011488},
    [1103001179]={1030011738,1030011739,1030011741,0,0,0,1030011737,1030011736,1030011735,1030011734,1030011733,1030011732,1030011731,0,0,0,0,0,0,1030011742,1030011743,1030011744},
    [1103001191]={1030011858,1030011859,1030011861,0,0,0,1030011857,1030011856,1030011855,1030011854,1030011853,1030011852,1030011851,0,0,0,0,0,0,1030011862,1030011863,1030011864},
    [1103001202]={1030011948,1030011949,1030011950,0,0,0,1030011947,1030011946,1030011945,1030011944,1030011943,1030011942,1030011941,0,0,0,0,0,0,1030011951,1030011952,1030011953},
    [1103002030]={1030020245,1030020246,1030020247,1030020252,1030020249,1030020253,1030020258,1030020257,1030020256,1030020255,1030020244,1030020243,1030020242,0,0,0,0,0,0,1030020248,0,0},
    [1103002059]={1030020544,1030020545,1030020546,1030020542,1030020539,1030020543,1030020538,1030020537,1030020536,1030020535,1030020534,1030020533,1030020532,0,0,0,0,0,0,1030020547,1030020548,0},
    [1103002087]={1030020824,1030020825,1030020826,0,0,0,1030020818,1030020817,1030020816,1030020815,1030020814,1030020813,1030020812,0,0,0,0,0,0,1030020827,1030020828,0},
    [1103002106]={1030021009,1030021010,1030021012,1030021015,1030021014,1030021016,1030021008,1030021007,1030021006,1030021005,1030021004,1030021003,1030021002,0,0,0,0,0,0,1030021013,1030021017,0},
    [1103002113]={1030021079,1030021080,1030021082,1030021085,1030021084,1030021086,1030021078,1030021077,1030021076,1030021075,1030021074,1030021073,1030021072,0,0,0,0,0,0,1030021083,1030021087,0},
    [1103003022]={1030030165,1030030166,1030030167,1030030172,1030030169,1030030173,0,0,0,0,1030030164,1030030163,1030030162,0,0,0,0,0,0,0,0,0},
    [1103003030]={1030030256,1030030257,1030030258,1030030254,1030030253,1030030255,1030030248,1030030247,1030030246,1030030245,1030030244,1030030243,1030030242,0,0,0,0,0,0,1030030259,1030030249,0},
    [1103003042]={1030030374,1030030375,1030030376,1030030372,1030030369,1030030373,0,0,0,0,1030030364,1030030363,1030030362,0,0,0,0,0,0,1030030377,0,0},
    [1103003051]={1030030458,1030030459,1030030460,1030030456,1030030455,1030030457,0,0,0,0,1030030454,1030030453,1030030452,0,0,0,0,0,0,1030030463,0,0},
    [1103003062]={1030030568,1030030569,1030030570,1030030566,1030030565,1030030567,0,0,0,0,1030030564,1030030563,1030030562,0,0,0,0,0,0,1030030572,0,0},
    [1103003079]={1030030744,1030030745,1030030746,1030030742,1030030740,1030030743,1030030738,1030030737,1030030736,1030030735,1030030734,1030030733,1030030732,0,0,0,0,0,0,1030030747,1030030739,0},
    [1103003087]={1030030825,1030030826,1030030827,1030030823,1030030824,1030030824,1030030818,1030030817,1030030816,1030030815,1030030814,1030030813,1030030812,0,0,0,0,0,0,1030030828,1030030819,0},
    [1103004037]={1030040315,1030040316,1030040317,1030040325,1030040324,1030040323,0,0,0,0,1030040314,1030040313,1030040312,1030040327,1030040326,0,0,0,1030040328,1030040329,0,0},
    [1103006030]={1030060245,1030060246,1030060247,0,1030060253,1030060252,0,0,0,0,1030060244,1030060243,1030060242,0,0,0,0,0,0,0,0,0},
    [1103007028]={1030070233,1030070234,1030070235,1030070226,1030070225,1030070227,1030070218,1030070217,1030070216,1030070215,1030070214,1030070213,1030070212,0,0,0,0,0,0,1030070236,1030070219,0},
    [1103012010]={0,0,0,0,0,0,1030120038,1030120037,1030120036,1030120035,1030120034,1030120033,1030120032,0,0,0,0,0,0,0,0,0},
    [1103012019]={0,0,0,0,0,0,1030120138,1030120137,1030120136,1030120135,1030120134,1030120133,1030120132,0,0,0,0,0,0,0,0,0},
    [1103012031]={0,0,0,0,0,0,1030120258,1030120257,1030120256,1030120255,1030120254,1030120253,1030120252,0,0,0,0,0,0,0,0,0},
    [1103012039]={0,0,0,0,0,0,1030120339,1030120338,1030120337,1030120336,1030120335,1030120334,1030120333,0,0,0,0,0,0,0,0,0},
    [1103102007]={1031020026,1031020027,1031020028,1031020024,1031020023,1031020025,1031020019,1031020018,1031020017,1031020016,1031020015,1031020014,1031020013,0,0,0,0,0,0,1031020029,0,0},
    [1105001034]={0,0,0,0,1050010287,1050010289,1050010286,1050010285,1050010284,1050010283,1050010282,0,0,0,0,0,0,0,0,1050010292,0,0},
    [1105001048]={0,0,0,1050010429,1050010428,1050010434,1050010427,1050010426,1050010425,1050010424,1050010423,0,0,0,0,0,0,0,0,1050010435,0,1050010436},
    [1105001069]={0,0,0,1050010639,1050010638,1050010640,1050010637,1050010636,1050010635,1050010634,1050010633,1050010645,0,0,0,0,0,0,0,1050010643,1050010646,1050010644},
    [1105002091]={0,0,0,0,0,0,1050020847,1050020846,1050020845,1050020844,1050020843,1050020842,0,0,0,0,0,0,0,0,0,1050020848},
    [1105010019]={0,0,0,0,0,0,1050100144,1050100143,1050100142,1050100141,1050100139,1050100138,0,0,0,0,0,0,0,0,0,0}
}

_G.BaseAttachToIndex = {
    [201010]=1, [201005]=1, [201004]=1, [201009]=2, [201003]=2, [201002]=2,
    [201011]=3, [201007]=3, [201006]=3, [204012]=4, [204005]=4, [204008]=4,
    [204011]=5, [204004]=5, [204007]=5, [204013]=6, [204006]=6, [204009]=6,
    [203001]=7, [203002]=8, [203003]=9, [203014]=10, [203004]=11, [203015]=12, [203005]=13,
    [202002]=14, [202001]=15, [202004]=16, [202005]=17, [202007]=18, [202006]=19,
    [205002]=20, [205003]=20, [205001]=20, [203018]=21, [204014]=22
}

_G.VipAttachToIndex = {}
for skinId, attachList in pairs(_G.VIP_Attachments) do
    for index, attachId in ipairs(attachList) do
        if attachId > 0 then
            _G.VipAttachToIndex[attachId] = index
        end
    end
end

local _SKIN_BASE_PATH    = "/storage/emulated/0/Android/data/com.tencent.igfit/files/"
local _SKIN_ATTACH_PATH  = _SKIN_BASE_PATH .. "attachments.txt"
_G.g_parts = _G.g_parts or {}
_G.skinAttachCache = _G.skinAttachCache or {}

local ATTACH_NAME_MAP = {
    ["Red Dot Sight"]          = "RedDot",
    ["Holographic Sight"]      = "Holo",
    ["2x Scope"]               = "Scope2x",
    ["3x Scope"]               = "Scope3x",
    ["4x Scope"]               = "Scope4x",
    ["6x Scope"]               = "Scope6x",
    ["8x Scope"]               = "Scope8x",
    ["Canted Sight"]           = "CantedSight",
    ["Flash Hider"]            = "FlashHider",
    ["Compensator"]            = "Compensator",
    ["Suppressor"]             = "Suppressor",
    ["Extended Mag"]           = "ExtMag",
    ["Quickdraw Mag"]          = "QuickMag",
    ["Extended Quickdraw Mag"] = "ExtQuickMag",
    ["Angled Foregrip"]        = "AngledGrip",
    ["Vertical Foregrip"]      = "VerticalGrip",
    ["Thumb Grip"]             = "ThumbGrip",
    ["Half Grip"]              = "HalfGrip",
    ["Light Grip"]             = "LightGrip",
    ["Laser Sight"]            = "LaserSight",
    ["Tactical Stock"]         = "TactStock",
    ["Stock"]                  = "MicroStock",
    ["Cheek Pad"]              = "CheekPad",
}

local _attachFileCache = nil

local function _parseAttachmentsFile()
    local result = {}
    pcall(function()
        local f = io.open(_SKIN_ATTACH_PATH, "r")
        if not f then return end
        local content = f:read("*all")
        f:close()
        local curSkin = nil
        for line in content:gmatch("[^\r\n]+") do
            local firstNum = line:match("^(%d+)%s*|")
            if firstNum then
                local num = tonumber(firstNum)
                if num and num > 1100000000 then
                    curSkin = num
                    result[curSkin] = result[curSkin] or {}
                elseif num and curSkin then
                    local attachName = line:match("^%d+%s*|%s*%x+%s*|%s*(.-)%s*$")
                    if not attachName then attachName = line:match("^%d+%s*|%s*(.-)%s*$") end
                    if attachName and attachName ~= "" then
                        local key = ATTACH_NAME_MAP[attachName]
                        if key then result[curSkin][key] = num end
                    end
                end
            elseif line:find("^#%-%-%-%-") and line:find("skin") then
                curSkin = nil
            end
        end
    end)
    return result
end

_G.GetAttachForSkin = function(skinId, key)
    if not skinId or skinId == 0 or not key then return nil end
    if not _attachFileCache then _attachFileCache = _parseAttachmentsFile() end
    local t = _attachFileCache[skinId]
    if not t then return nil end
    local v = t[key]
    return (v and v > 0) and v or nil
end

_G.GetAttachFileCache = function()
    if not _attachFileCache then _attachFileCache = _parseAttachmentsFile() end
    return _attachFileCache
end

_G.muzzles = {
    id_flash_hider = { 201010, 201005, 201004 },
    id_compensator = { 201009, 201003, 201002 },
    id_suppressor  = { 201011, 201006, 201007 }
}
_G.foregrips = {
    id_Angledforegrip = 202001,
    id_thumb_grip     = 202006,
    id_vertical_grip  = 202002,
    id_light_grip     = 202004,
    id_half_grip      = 202005,
    id_ergonomic_grip = 202051,
    id_laser_sight    = 202007
}
_G.magazines = {
    id_expanded_mag       = { 204011, 204007, 204004 },
    id_quick_mag          = { 204012, 204008, 204005 },
    id_expanded_quick_mag = { 204013, 204009, 204006 }
}
_G.scopes = {
    id_reddot = 203001,
    id_holo   = 203002,
    id_2x     = 203003,
    id_3x     = 203014,
    id_4x     = 203004,
    id_6x     = 203015,
    id_8x     = 203005
}
_G.stock = {
    id_microStock = 205001,
    id_tactical   = 205002,
    id_bulletloop = 204014,
    id_CheekPad   = 205003
}

_G.ItemUpgradeSystem = nil
pcall(function()
    local MM  = require("client.module_framework.ModuleManager")
    local IUS = MM.GetModule(MM.CommonModuleConfig.ItemUpgradeManager)
    if IUS then
        IUS:DefineAndResetData()
        IUS:OnInitialize()
        _G.ItemUpgradeSystem = IUS
    end
end)

_G.get_group_id = function(itemId)
    if not _G.ItemUpgradeSystem or not itemId then return nil end
    local cfg = _G.ItemUpgradeSystem:GetUpgradeCfg(itemId)
    return cfg and cfg.GroupID or nil
end

_G.InitParts = function(groupId, itemId)
    if not itemId then return _G.g_parts end
    if _G.g_parts[itemId] and next(_G.g_parts[itemId]) then return _G.g_parts end
    _G.g_parts[itemId] = {}
    if not _G.ItemUpgradeSystem then return _G.g_parts end
    if _G.ItemUpgradeSystem:IsWeaponIsRefit(itemId) then
        groupId = _G.ItemUpgradeSystem:GetNormalGroupID(groupId or _G.get_group_id(itemId))
    else
        groupId = groupId or _G.get_group_id(itemId)
    end
    if not groupId then return _G.g_parts end
    local cfg = rawGetTableByFilter("ItemUpgradeUnLockConfig", "GroupID", groupId)
    if cfg then
        for _, info in pairs(cfg) do
            local partId = info.PartId
            if _G.ItemUpgradeSystem:IsWeaponIsRefit(itemId) then
                local switched = _G.ItemUpgradeSystem:PartIDSwitch(partId, true)
                if switched and switched ~= partId then partId = switched end
            end
            local item = rawGetTableData("Item", partId)
            if item and item.ItemName then
                _G.g_parts[itemId][item.ItemName] = partId
            end
        end
    end
    return _G.g_parts
end

_G.GetRawAttachMap = function(skinid)
    if not skinid or skinid <= 0 then return {} end
    if _G.skinAttachCache[skinid] then return _G.skinAttachCache[skinid] end
    local UAvatarUtils = import("AvatarUtils")
    if not UAvatarUtils then return {} end
    local list = UAvatarUtils.GetWeaponAvatarDefaultAttachmentSkin(skinid, {}, false) or {}
    _G.skinAttachCache[skinid] = list
    return list
end

_G.GetSlotFromSkinID = function(skinid, slot)
    if not skinid or not slot then return 0 end
    local list = _G.GetRawAttachMap(skinid)
    local attachmentTypeMap = {
        [1] = {291004,291102,291001,291006,291005,291002,293003,293004,293009,293007,293005,293006,295001,295002,291007,291003,292002,292003,291011,291008},
        [2] = {205005,205102,205007,205009,205006},
        [3] = {203008,203009,203006,203022,203010}
    }
    local targetIDs = attachmentTypeMap[slot]
    if not targetIDs then return 0 end
    for _, targetID in ipairs(targetIDs) do
        for attachID, attachSkinID in pairs(list) do
            if attachID == targetID then return attachSkinID end
        end
    end
    return 0
end

_G.AutoDetectAttach = function(skinid, base_id)
    if not skinid or not base_id then return 0 end
    local list = _G.GetRawAttachMap(skinid)
    local v = list[base_id]
    return (v and v > 0) and v or 0
end

_G.get_muzzleid = function(current_id, avatarid)
    local initial_id = current_id
    _G.InitParts(_G.get_group_id(avatarid), avatarid)
    local p = _G.g_parts[avatarid]
    local function is_in(t)
        for _, id in ipairs(_G.muzzles[t]) do if current_id == id then return true end end
        return false
    end
    if is_in("id_flash_hider") then
        local auto = _G.AutoDetectAttach(avatarid, current_id)
        current_id = _G.GetAttachForSkin(avatarid, "FlashHider") or (p and p["Flash Hider"]) or (auto > 0 and auto) or current_id
    elseif is_in("id_compensator") then
        local auto = _G.AutoDetectAttach(avatarid, current_id)
        current_id = _G.GetAttachForSkin(avatarid, "Compensator") or (p and p["Compensator"]) or (auto > 0 and auto) or current_id
    elseif is_in("id_suppressor") then
        local auto = _G.AutoDetectAttach(avatarid, current_id)
        current_id = _G.GetAttachForSkin(avatarid, "Suppressor") or (p and p["Suppressor"]) or (auto > 0 and auto) or current_id
    end
    return current_id, (initial_id ~= current_id)
end

_G.get_forgripid = function(current_id, avatarid)
    local initial_id = current_id
    _G.InitParts(_G.get_group_id(avatarid), avatarid)
    local p = _G.g_parts[avatarid]
    local auto = _G.AutoDetectAttach(avatarid, current_id)
    if current_id == _G.foregrips.id_Angledforegrip then
        current_id = _G.GetAttachForSkin(avatarid, "AngledGrip") or (p and p["Angled Foregrip"]) or (auto > 0 and auto) or current_id
    elseif current_id == _G.foregrips.id_thumb_grip then
        current_id = _G.GetAttachForSkin(avatarid, "ThumbGrip") or (p and p["Thumb Grip"]) or (auto > 0 and auto) or current_id
    elseif current_id == _G.foregrips.id_vertical_grip then
        current_id = _G.GetAttachForSkin(avatarid, "VerticalGrip") or (p and p["Vertical Foregrip"]) or (auto > 0 and auto) or current_id
    elseif current_id == _G.foregrips.id_light_grip then
        current_id = _G.GetAttachForSkin(avatarid, "LightGrip") or (p and p["Light Grip"]) or (auto > 0 and auto) or current_id
    elseif current_id == _G.foregrips.id_half_grip then
        current_id = _G.GetAttachForSkin(avatarid, "HalfGrip") or (p and p["Half Grip"]) or (auto > 0 and auto) or current_id
    elseif current_id == _G.foregrips.id_ergonomic_grip then
        current_id = (p and p["Ergonomic Grip"]) or (auto > 0 and auto) or current_id
    elseif current_id == _G.foregrips.id_laser_sight then
        current_id = _G.GetAttachForSkin(avatarid, "LaserSight") or (p and p["Laser Sight"]) or (auto > 0 and auto) or current_id
    end
    return current_id, (initial_id ~= current_id)
end

_G.get_magazinesid = function(current_id, avatarid)
    local initial_id = current_id
    _G.InitParts(_G.get_group_id(avatarid), avatarid)
    local p = _G.g_parts[avatarid]
    local function is_in(t)
        for _, id in ipairs(_G.magazines[t]) do if current_id == id then return true end end
        return false
    end
    if is_in("id_expanded_mag") then
        local auto = _G.AutoDetectAttach(avatarid, current_id)
        current_id = _G.GetAttachForSkin(avatarid, "ExtMag") or (p and p["Extended Mag"]) or _G.GetSlotFromSkinID(avatarid, 1) or (auto > 0 and auto) or current_id
    elseif is_in("id_quick_mag") then
        local auto = _G.AutoDetectAttach(avatarid, current_id)
        current_id = _G.GetAttachForSkin(avatarid, "QuickMag") or (p and p["Quickdraw Mag"]) or _G.GetSlotFromSkinID(avatarid, 1) or (auto > 0 and auto) or current_id
    elseif is_in("id_expanded_quick_mag") then
        local auto = _G.AutoDetectAttach(avatarid, current_id)
        current_id = _G.GetAttachForSkin(avatarid, "ExtQuickMag") or (p and p["Extended Quickdraw Mag"]) or _G.GetSlotFromSkinID(avatarid, 1) or (auto > 0 and auto) or current_id
    else
        local fb = _G.GetSlotFromSkinID(avatarid, 1)
        if fb and fb > 0 then current_id = fb end
    end
    return current_id, (initial_id ~= current_id)
end

_G.get_scopeid = function(current_id, avatarid)
    local initial_id = current_id
    _G.InitParts(_G.get_group_id(avatarid), avatarid)
    local p = _G.g_parts[avatarid]
    local auto = _G.AutoDetectAttach(avatarid, current_id)
    if current_id == _G.scopes.id_reddot then
        current_id = _G.GetAttachForSkin(avatarid, "RedDot") or (p and p["Red Dot Sight"]) or _G.GetSlotFromSkinID(avatarid, 3) or (auto > 0 and auto) or current_id
    elseif current_id == _G.scopes.id_holo then
        current_id = _G.GetAttachForSkin(avatarid, "Holo") or (p and p["Holographic Sight"]) or _G.GetSlotFromSkinID(avatarid, 3) or (auto > 0 and auto) or current_id
    elseif current_id == _G.scopes.id_2x then
        current_id = _G.GetAttachForSkin(avatarid, "Scope2x") or (p and p["2x Scope"]) or _G.GetSlotFromSkinID(avatarid, 3) or (auto > 0 and auto) or current_id
    elseif current_id == _G.scopes.id_3x then
        current_id = _G.GetAttachForSkin(avatarid, "Scope3x") or (p and p["3x Scope"]) or _G.GetSlotFromSkinID(avatarid, 3) or (auto > 0 and auto) or current_id
    elseif current_id == _G.scopes.id_4x then
        current_id = _G.GetAttachForSkin(avatarid, "Scope4x") or (p and p["4x Scope"]) or _G.GetSlotFromSkinID(avatarid, 3) or (auto > 0 and auto) or current_id
    elseif current_id == _G.scopes.id_6x then
        current_id = _G.GetAttachForSkin(avatarid, "Scope6x") or (p and p["6x Scope"]) or _G.GetSlotFromSkinID(avatarid, 3) or (auto > 0 and auto) or current_id
    elseif current_id == _G.scopes.id_8x then
        current_id = _G.GetAttachForSkin(avatarid, "Scope8x") or (p and p["8x Scope"]) or _G.GetSlotFromSkinID(avatarid, 3) or (auto > 0 and auto) or current_id
    else
        local fb = _G.GetSlotFromSkinID(avatarid, 3)
        if fb and fb > 0 then current_id = fb end
    end
    return current_id, (initial_id ~= current_id)
end

_G.get_stockid = function(current_id, avatarid)
    local initial_id = current_id
    _G.InitParts(_G.get_group_id(avatarid), avatarid)
    local p = _G.g_parts[avatarid]
    local auto = _G.AutoDetectAttach(avatarid, current_id)
    if current_id == _G.stock.id_microStock then
        current_id = _G.GetAttachForSkin(avatarid, "MicroStock") or (p and p["Stock"]) or _G.GetSlotFromSkinID(avatarid, 2) or (auto > 0 and auto) or current_id
    elseif current_id == _G.stock.id_tactical then
        current_id = _G.GetAttachForSkin(avatarid, "TactStock") or (p and p["Tactical Stock"]) or _G.GetSlotFromSkinID(avatarid, 2) or (auto > 0 and auto) or current_id
    elseif current_id == _G.stock.id_bulletloop then
        current_id = (p and p["Bullet Loop"]) or _G.GetSlotFromSkinID(avatarid, 2) or (auto > 0 and auto) or current_id
    elseif current_id == _G.stock.id_CheekPad then
        current_id = _G.GetAttachForSkin(avatarid, "CheekPad") or (p and p["Cheek Pad"]) or _G.GetSlotFromSkinID(avatarid, 2) or (auto > 0 and auto) or current_id
    else
        local fb = _G.GetSlotFromSkinID(avatarid, 2)
        if fb and fb > 0 then current_id = fb end
    end
    return current_id, (initial_id ~= current_id)
end

_G.apply_attachment = function(CurWeapon, avatarid)
    local array = CurWeapon.synData
    for AttachIdx = 0, 4 do
        local Data = array:Get(AttachIdx)
        local itemid = slua.IndexReference(Data, "defineID").TypeSpecificID
        if itemid and itemid > 0 and itemid < 10000000 then
            local isrefresh = false
            if AttachIdx == 0 then
                Data.defineID.TypeSpecificID, isrefresh = _G.get_muzzleid(slua.IndexReference(Data, "defineID").TypeSpecificID, avatarid)
                array:Set(AttachIdx, Data)
            elseif AttachIdx == 1 then
                Data.defineID.TypeSpecificID, isrefresh = _G.get_forgripid(slua.IndexReference(Data, "defineID").TypeSpecificID, avatarid)
                array:Set(AttachIdx, Data)
            elseif AttachIdx == 2 then
                Data.defineID.TypeSpecificID, isrefresh = _G.get_magazinesid(slua.IndexReference(Data, "defineID").TypeSpecificID, avatarid)
                array:Set(AttachIdx, Data)
            elseif AttachIdx == 3 then
                Data.defineID.TypeSpecificID, isrefresh = _G.get_stockid(slua.IndexReference(Data, "defineID").TypeSpecificID, avatarid)
                array:Set(AttachIdx, Data)
            elseif AttachIdx == 4 then
                Data.defineID.TypeSpecificID, isrefresh = _G.get_scopeid(slua.IndexReference(Data, "defineID").TypeSpecificID, avatarid)
                array:Set(AttachIdx, Data)
            else
                break
            end
            if isrefresh then
                _G.download_item(slua.IndexReference(Data, "defineID").TypeSpecificID)
                CurWeapon:DelayHandleAvatarMeshChanged()
            end
        end
    end
end

_G.WeaponSkinMap = _G.WeaponSkinMap or {}
_G.VehicleSkinMap = _G.VehicleSkinMap or {}
_G.OutfitMap = _G.OutfitMap or {}
_G.skinIdCache = _G.skinIdCache or {}
_G.skinIdCache2 = _G.skinIdCache2 or {}

_G.OutfitSkins = {
    Suit = {1405628,1407920,1407916,1407895,1405760,1407870,1407856,1407812,1407758,1407789,1407682,1407696,1407695,1407632,1407631,1407667,1407618,1407573,1407572,1407559,1407558,1407550,1407523,1407718,1407512,1407471,1407470,1406985,1407353,1407366,1407330,1407487,1410668,1407276,1407275,1407142,1407141,1407140,1406971,1406897,1406891,1407187,1405802,1405192,1405334,1400687,1405340,1405623,1405132,1405436,1405435,1405434,1405433,1405208,1407916,1407917,1407918,1407921,1407921,1407926,1407901,1407902,1407903,1407904,1407822,1407823,1407824,1407825,1407807,1407808,1407845,1407846,1407847,1407848,1407794,1411037,1407795,1411038,1407796,1411039},
    Pants = {1404002,1404050,1404425,1404495,1400650,1404522,1404441,1404152,1404196,1404134,1404137,1404164,1404191,1404466,1400052,404035,1404181,404084,1404516},
    Hair = {40605010,40605011,40605012,1410480,1410085,1410299,1402834,441400152,1400150,1402582,1410289,1402218,1402223,1402283,1400426},
    Bag = {
        {501001, 501002, 501003}, {1501001174, 1501002174, 1501003174}, {1501001220, 1501002220, 1501003220},
        {1501001051, 1501002051, 1501003051}, {1501001443, 1501002443, 1501003443}, {1501001265, 1501002265, 1501003265},
        {1501001321, 1501002321, 1501003321}, {1501001277, 1501002277, 1501003277}, {1501001550, 1501002550, 1501003550},
        {1501001592, 1501002592, 1501003592}, {1501001608, 1501002608, 1501003608}, {1501001024, 1501002024, 1501003024},
        {1501001019, 1501002019, 1501003019}, {1501001179, 1501002179, 1501003179}, {1501001194, 1501002194, 1501003194},
        {1501001346, 1501002346, 1501003346}
    },
    Helmet = {
        {502001, 502002, 502003}, {1502001014, 1502002014, 1502003014}, {1502001349, 1502002349, 1502003349},
        {1502001012, 1502002012, 1502003012}, {1502001009, 1502002009, 1502003009}, {1502001397, 1502002397, 1502003397},
        {1502001390, 1502002390, 1502003390}, {1502001381, 1502002381, 1502003381}, {1502001358, 1502002358, 1502003358},
        {1502001350, 1502002350, 1502003350}, {1502001342, 1502002342, 1502003342}
    },
    Pet = {50000,50001,50002,50003,50004,50005,50006,50021,50022,50038,50039,50040}
}

_G.skinIdMappings = {
    [101004]={101004, 1101004246,1101004226,1101004236,1101004062,1101004078,1101004086,1101004201,1101004218},
    [101001]={101001,1101001276,1101001089,1101001213,1101001172,1101001127,1101001230,1101001241},
    [101003]={101003,1101003227,1103003208,1101003195,1101003187,1101003098,1101003166,1101003218},
    [102002]={102002,1102002136,1102002043,1102002061,1102002424},
    [101008]={101008,1101008146,1101008154,1101008079,1101008126,1101008104,1101008146,1101008061,1101008116},
    [101006]={101006,1101006085,1101006061,1101006074,1101006043,1101006032,1101006084},
    [102001]={102001, 1102001120},
    [101005]={101005, 1101005098},
    [104003]={104003, 1104003037},
    [104004]={104004, 1104004035, 1104004041},
    [101101]={101101, 1101101007},
    [101007]={101007, 1101007071,1101007062,1101007046,1101007078,1101007072},
    [101012]={101012, 1101012033},
    [101002]={101002, 1101002081,1101002056,1101002029,1101002149},
    [101102]={101102, 1101102049,1101102025,1101102017,1101102007,1101102032},
    [103001]={103001, 1103001202,1103001191,1103001179,1103001146,1103001101,1103001079,1103001202},
    [103002]={103002, 1103002113,1103002098,1103002087,1103002060,1103002059,1103002030},
    [103003]={103003, 1103003087,1103003079,1103003069,1103003062,1103003055,1103003051,1103003042,1103003030,1103003022,1103003092},
}

_G.VehicleSkins = {
    [1961001] = { 1961151,1961152,1961153,1961147,1961148,1961149,1961144,1961145,1961137,1961138,1961139,1961066,1961067,1961065,1961062,1961063,1961064,1961054,1961055,1961056,1961057,1961051,1961052,1961053,1961048,1961049,1961050,1961044,1961045,1961046,1961047,1961041,1961042,1961043,1961038,1961039,1961040,1961033,1961034,1961035,1961029,1961030,1961031,1961032,1961007,1961010,1961012,1961013,1961014,1961015,1961140,1961141,1961142,1961143,1991023,1991024 },
    [1903001] = { 1903228,1903220,1903221,1903223,1903218,1903219,1903213,1903212,1903202,1908094,1908095,1903193,1903192,1903191,19030790,19030791,19030800,19030801,1903074,1903075,1903076,1903071,1903072,1903073,1903216,1903217,1991001,1991002,1991003,1991004,1903088,1903089,1903090,1903023 },
    [1915004] = { 1915021, 1915022, 1915008, 1915009, 1914011 },
    [1908001] = { 1908108,1908109,19080951,19081080,1908084,1908085,1908075,1908077,1908078,1908070,1908069,1908066,1908086,1908088,1908089,1908018 },
    [1907002] = { 1907058, 1907054, 1907059, 1907053, 1907063, 1907072, 1907040, 1907041, 1907027, 1907047, 1907021}
}
_G.CustSlotType = { ClothesEquipemtSlot=5, BackpackEquipemtSlot=8, HelmetEquipemtSlot=9, ParachuteEquipemtSlot=11, GlideEquipemtSlot=15 }

local function DownloadGameItem(id)
    local puffer_manager = require('client.slua.logic.download.puffer.puffer_manager')
    local puffer_const = require('client.slua.logic.download.puffer_const')
    if not puffer_manager or not puffer_const then return end
    local state = puffer_manager.GetState(puffer_const.ENUM_DownloadType.ODPTD, {id})
    if state ~= puffer_const.ENUM_DownloadState.Done and state ~= puffer_const.ENUM_DownloadState.Downloading then
        puffer_manager.Download(puffer_const.ENUM_DownloadType.ODPTD, {id})
    end
end

_G.download_item = function(i)
    if not i then return end
    pcall(function()
        local PM = require("client.slua.logic.download.puffer.puffer_manager")
        local PC = require("client.slua.logic.download.puffer_const")
        if PM.GetState(PC.ENUM_DownloadType.ODPAK, {i}) ~= PC.ENUM_DownloadState.Done then
            PM.Download(PC.ENUM_DownloadType.ODPAK, {i})
        end
    end)
    pcall(DownloadGameItem, i)
end

_G.get_skin_id = function(weaponID)
    if not weaponID then return nil end
    local targetSkinId = _G.WeaponSkinMap and _G.WeaponSkinMap[weaponID]
    if targetSkinId and targetSkinId > 0 then
        if not _G.skinIdCache2[targetSkinId] then
            if _G.download_item then pcall(_G.download_item, targetSkinId) end
            _G.skinIdCache2[targetSkinId] = true
        end
        return targetSkinId
    end
    return weaponID
end

_G.equip_character_avatar = function(Character)
    if not Character or not slua.isValid(Character) or not Character.AvatarComponent2 then return end
    local BackpackUtils = import("BackpackUtils")
    local SlotSyncData = Character.AvatarComponent2.NetAvatarData and Character.AvatarComponent2.NetAvatarData.SlotSyncData
    if not SlotSyncData or not slua.isValid(SlotSyncData) or not BackpackUtils then return end

    local function EquipAvatar(ApplyDataIdx, mappedSkin, ApplyEquipSlot, isLevelDependent, levelFunc)
        if not mappedSkin or mappedSkin == 0 then return end
        local slotData = SlotSyncData:Get(ApplyDataIdx)
        if slotData and slotData.SlotID == ApplyEquipSlot then
            local applyItemId = mappedSkin
            if isLevelDependent and type(mappedSkin) == "table" then
                local level = levelFunc(slotData.AdditionalItemID) or 1
                if level < 1 then level = 1 end
                if level > 3 then level = 3 end
                applyItemId = mappedSkin[level] or mappedSkin[1]
            end
            if not applyItemId or applyItemId == 0 or slotData.ItemId == applyItemId then return end
            if not _G.skinIdCache[applyItemId] then
                if _G.download_item then pcall(_G.download_item, applyItemId) end
                _G.skinIdCache[applyItemId] = true
            end
            slotData.ItemId = applyItemId
            SlotSyncData:Set(ApplyDataIdx, slotData)
            Character.AvatarComponent2:OnRep_BodySlotStateChanged()
        end
    end

    local hasGliderSlot = false
    for i = 0, SlotSyncData:Num() - 1 do
        local slotData = SlotSyncData:Get(i)
        if slotData and slotData.SlotID == _G.CustSlotType.GlideEquipemtSlot then
            hasGliderSlot = true
            break
        end
    end
    if not hasGliderSlot then SlotSyncData:Add({ SlotID = _G.CustSlotType.GlideEquipemtSlot, ItemId = 0 }) end

    for i = 0, SlotSyncData:Num() - 1 do
        EquipAvatar(i, _G.OutfitMap.Suit or 0, _G.CustSlotType.ClothesEquipemtSlot, false)
        EquipAvatar(i, _G.OutfitMap.Pants or 0, 6, false)
        EquipAvatar(i, _G.OutfitMap.Hair or 0, 7, false)
        EquipAvatar(i, _G.OutfitMap.Bag, _G.CustSlotType.BackpackEquipemtSlot, true, BackpackUtils.GetEquipmentBagLevel)
        EquipAvatar(i, _G.OutfitMap.Helmet, _G.CustSlotType.HelmetEquipemtSlot, true, BackpackUtils.GetEquipmentHelmetLevel)
        EquipAvatar(i, _G.OutfitMap.Parachute or 0, _G.CustSlotType.ParachuteEquipemtSlot, false)
    end
end

_G.ApplyWeaponSkins = function(PlayerCharacter)
    pcall(function()
        local WeaponManager = PlayerCharacter:GetWeaponManager()
        if not slua.isValid(WeaponManager) then return end

        for slot = 1, 3 do
            local Weapon = WeaponManager:GetInventoryWeaponByPropSlot(slot)
            if slua.isValid(Weapon) and slua.isValid(Weapon.synData) then
                local WeaponID = Weapon:GetWeaponID()
                local SkinID = _G.get_skin_id(WeaponID) or WeaponID
                local isModified = false

                local SkinData = Weapon.synData:Get(7)
                if SkinData and SkinData.defineID and SkinData.defineID.TypeSpecificID ~= SkinID then
                    SkinData.defineID.TypeSpecificID = SkinID
                    Weapon.synData:Set(7, SkinData)
                    if Weapon.SetWeaponAvatarID then pcall(function() Weapon:SetWeaponAvatarID(SkinID) end) end
                    if not _G.skinIdCache[SkinID] then
                        _G.download_item(SkinID)
                        _G.skinIdCache[SkinID] = true
                    end
                    isModified = true
                end

                if SkinID >= 10000000 and _G.VIP_Attachments and _G.VIP_Attachments[SkinID] then
                    for AttachIdx = 0, 5 do
                        local attachData = Weapon.synData:Get(AttachIdx)
                        if attachData then
                            local defineIDRef = slua.IndexReference(attachData, "defineID")
                            if defineIDRef then
                                local attachmentId = defineIDRef.TypeSpecificID
                                if attachmentId and attachmentId > 0 then
                                    local mapIndex = _G.BaseAttachToIndex[attachmentId] or _G.VipAttachToIndex[attachmentId]
                                    if mapIndex and _G.VIP_Attachments[SkinID][mapIndex] and _G.VIP_Attachments[SkinID][mapIndex] > 0 then
                                        local targetAttachId = _G.VIP_Attachments[SkinID][mapIndex]
                                        if targetAttachId ~= attachmentId then
                                            attachData.defineID.TypeSpecificID = targetAttachId
                                            Weapon.synData:Set(AttachIdx, attachData)
                                            if not _G.skinIdCache2[targetAttachId] then
                                                if _G.download_item then pcall(_G.download_item, targetAttachId) end
                                                _G.skinIdCache2[targetAttachId] = true
                                            end
                                            isModified = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                if _G.apply_attachment and SkinID >= 10000000 then
                    pcall(function() _G.apply_attachment(Weapon, SkinID) end)
                end

                if isModified then
                    if Weapon.DelayHandleAvatarMeshChanged then pcall(function() Weapon:DelayHandleAvatarMeshChanged() end) end
                    if Weapon.OnRep_synData then pcall(function() Weapon:OnRep_synData() end) end
                end
            end
        end
    end)
end

_G.ApplyVehicleSkins = function(PlayerCharacter)
    pcall(function()
        local Vehicle = PlayerCharacter:GetCurrentVehicle()
        if not slua.isValid(Vehicle) then
            _G.LastVehicleEntity = nil
            return
        end
        if _G.LastVehicleEntity == Vehicle and _G.CurrentEquipVehicleID ~= nil then return end
        local VehicleAvatar = Vehicle.VehicleAvatar or Vehicle.VehicleAvatarComponent_BP or Vehicle:GetAvatarComponent()
        if not slua.isValid(VehicleAvatar) then return end
        local defId = tostring(VehicleAvatar:GetDefaultAvatarID() or Vehicle.VehicleID or "")
        local currentId = tostring(Vehicle:GetAvatarId() or "")
        local applySkinId = 0
        for baseMapId, targetSkin in pairs(_G.VehicleSkinMap) do
            if defId:find(tostring(baseMapId)) or currentId:find(tostring(baseMapId)) then
                applySkinId = targetSkin
                break
            end
        end
        if applySkinId and applySkinId > 0 then
            _G.skinIdCache = _G.skinIdCache or {}
            if not _G.skinIdCache[applySkinId] then
                if _G.download_item then pcall(_G.download_item, applySkinId) end
                _G.skinIdCache[applySkinId] = true
            end
            VehicleAvatar.curSwitchEffectId = 7303001
            if VehicleAvatar.ChangeItemAvatar then VehicleAvatar:ChangeItemAvatar(applySkinId, true) end
            _G.CurrentEquipVehicleID = applySkinId
            _G.LastVehicleEntity = Vehicle
        end
    end)
end

_G.HandlePetLogic = function()
    pcall(function()
        local petSkin = _G.OutfitMap.Pet
        if not petSkin or petSkin == 0 or petSkin == 50000 or petSkin == _G.LastAppliedPet then return end
        _G.skinIdCache = _G.skinIdCache or {}
        if not _G.skinIdCache[petSkin] then
            if _G.download_item then pcall(_G.download_item, petSkin) end
            _G.skinIdCache[petSkin] = true
        end
        local ModuleManager = require("client.module_framework.ModuleManager")
        if ModuleManager then
            local logic_pet = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_pet)
            if logic_pet then
                if logic_pet.SetCurPetID then logic_pet:SetCurPetID(petSkin) end
                if logic_pet.EquipPet then logic_pet:EquipPet(petSkin) end
            end
        end
        _G.LastAppliedPet = petSkin
    end)
end

_G.ForceRefreshSkinMaps = function()
    pcall(function()
        if not _G.SumeyyeState or not _G.SumeyyeState.CustomTextData then return end
        local cData = _G.SumeyyeState.CustomTextData

        if _G.OutfitSkins then
            if cData.SkinSuit and _G.OutfitSkins.Suit[cData.SkinSuit] then _G.OutfitMap.Suit = _G.OutfitSkins.Suit[cData.SkinSuit] end
            if cData.SkinBag and _G.OutfitSkins.Bag[cData.SkinBag] then _G.OutfitMap.Bag = _G.OutfitSkins.Bag[cData.SkinBag] end
            if cData.SkinHelmet and _G.OutfitSkins.Helmet[cData.SkinHelmet] then _G.OutfitMap.Helmet = _G.OutfitSkins.Helmet[cData.SkinHelmet] end
        end

        if _G.skinIdMappings then
            if cData.SkinM416 and _G.skinIdMappings[101004] and _G.skinIdMappings[101004][cData.SkinM416] then _G.WeaponSkinMap[101004] = _G.skinIdMappings[101004][cData.SkinM416] end
            if cData.SkinAKM and _G.skinIdMappings[101001] and _G.skinIdMappings[101001][cData.SkinAKM] then _G.WeaponSkinMap[101001] = _G.skinIdMappings[101001][cData.SkinAKM] end
            if cData.SkinSCAR and _G.skinIdMappings[101003] and _G.skinIdMappings[101003][cData.SkinSCAR] then _G.WeaponSkinMap[101003] = _G.skinIdMappings[101003][cData.SkinSCAR] end
            if cData.SkinM762 and _G.skinIdMappings[101008] and _G.skinIdMappings[101008][cData.SkinM762] then _G.WeaponSkinMap[101008] = _G.skinIdMappings[101008][cData.SkinM762] end
            if cData.SkinAUG and _G.skinIdMappings[101006] and _G.skinIdMappings[101006][cData.SkinAUG] then _G.WeaponSkinMap[101006] = _G.skinIdMappings[101006][cData.SkinAUG] end
            if cData.SkinUMP and _G.skinIdMappings[102002] and _G.skinIdMappings[102002][cData.SkinUMP] then _G.WeaponSkinMap[102002] = _G.skinIdMappings[102002][cData.SkinUMP] end
            if cData.SkinUZI and _G.skinIdMappings[102001] and _G.skinIdMappings[102001][cData.SkinUZI] then _G.WeaponSkinMap[102001] = _G.skinIdMappings[102001][cData.SkinUZI] end
            if cData.SkinGroza and _G.skinIdMappings[101005] and _G.skinIdMappings[101005][cData.SkinGroza] then _G.WeaponSkinMap[101005] = _G.skinIdMappings[101005][cData.SkinGroza] end
            if cData.SkinS12K and _G.skinIdMappings[104003] and _G.skinIdMappings[104003][cData.SkinS12K] then _G.WeaponSkinMap[104003] = _G.skinIdMappings[104003][cData.SkinS12K] end
            if cData.SkinDBS and _G.skinIdMappings[104004] and _G.skinIdMappings[104004][cData.SkinDBS] then _G.WeaponSkinMap[104004] = _G.skinIdMappings[104004][cData.SkinDBS] end
            if cData.SkinASM and _G.skinIdMappings[101101] and _G.skinIdMappings[101101][cData.SkinASM] then _G.WeaponSkinMap[101101] = _G.skinIdMappings[101101][cData.SkinASM] end
            if cData.SkinQBZ and _G.skinIdMappings[101007] and _G.skinIdMappings[101007][cData.SkinQBZ] then _G.WeaponSkinMap[101007] = _G.skinIdMappings[101007][cData.SkinQBZ] end
            if cData.SkinHoney and _G.skinIdMappings[101012] and _G.skinIdMappings[101012][cData.SkinHoney] then _G.WeaponSkinMap[101012] = _G.skinIdMappings[101012][cData.SkinHoney] end
            if cData.SkinM16A4 and _G.skinIdMappings[101002] and _G.skinIdMappings[101002][cData.SkinM16A4] then _G.WeaponSkinMap[101002] = _G.skinIdMappings[101002][cData.SkinM16A4] end
            if cData.SkinACE32 and _G.skinIdMappings[101102] and _G.skinIdMappings[101102][cData.SkinACE32] then _G.WeaponSkinMap[101102] = _G.skinIdMappings[101102][cData.SkinACE32] end
            if cData.SkinKar98k and _G.skinIdMappings[103001] and _G.skinIdMappings[103001][cData.SkinKar98k] then _G.WeaponSkinMap[103001] = _G.skinIdMappings[103001][cData.SkinKar98k] end
            if cData.SkinM24 and _G.skinIdMappings[103002] and _G.skinIdMappings[103002][cData.SkinM24] then _G.WeaponSkinMap[103002] = _G.skinIdMappings[103002][cData.SkinM24] end
            if cData.SkinAWM and _G.skinIdMappings[103003] and _G.skinIdMappings[103003][cData.SkinAWM] then _G.WeaponSkinMap[103003] = _G.skinIdMappings[103003][cData.SkinAWM] end
        end

        if _G.VehicleSkins then
            if cData.SkinDacia and _G.VehicleSkins[1903001] and _G.VehicleSkins[1903001][cData.SkinDacia] then _G.VehicleSkinMap[1903001] = _G.VehicleSkins[1903001][cData.SkinDacia] end
            if cData.SkinUAZ and _G.VehicleSkins[1908001] and _G.VehicleSkins[1908001][cData.SkinUAZ] then _G.VehicleSkinMap[1908001] = _G.VehicleSkins[1908001][cData.SkinUAZ] end
            if cData.SkinCoupe and _G.VehicleSkins[1961001] and _G.VehicleSkins[1961001][cData.SkinCoupe] then _G.VehicleSkinMap[1961001] = _G.VehicleSkins[1961001][cData.SkinCoupe] end
            if cData.SkinBuggy and _G.VehicleSkins[1907002] and _G.VehicleSkins[1907002][cData.SkinBuggy] then _G.VehicleSkinMap[1907002] = _G.VehicleSkins[1907002][cData.SkinBuggy] end
            if cData.SkinMirado and _G.VehicleSkins[1915004] and _G.VehicleSkins[1915004][cData.SkinMirado] then _G.VehicleSkinMap[1915004] = _G.VehicleSkins[1915004][cData.SkinMirado] end
        end
    end)
end

local cached_GameplayStatics = nil
local cached_PlayerTombBox = nil
local cached_ActorClass = nil
_G.NeedCheckDeadBoxTimer = 100

_G.DeadBox_TemperRequest = function(PlayerController)
    if not _G.SumeyyeConfig.SkinDeadBox then return end
    if _G.NeedCheckDeadBoxTimer <= 0 then return end
    local curTime = os.clock()
    if _G.LastCheckDeadBoxTime and (curTime - _G.LastCheckDeadBoxTime) < 2.0 then return end
    _G.LastCheckDeadBoxTime = curTime
    _G.NeedCheckDeadBoxTimer = _G.NeedCheckDeadBoxTimer - 1

    local PlayerCharacter = PlayerController:GetPlayerCharacterSafety()
    if not slua.isValid(PlayerCharacter) then return end

    if not cached_GameplayStatics then
        cached_GameplayStatics = import("GameplayStatics")
        cached_ActorClass = import("Actor")
        cached_PlayerTombBox = import("PlayerTombBox")
    end
    if not _G.CachedActorArray then
        _G.CachedActorArray = slua.Array(UEnums.EPropertyClass.Object, cached_ActorClass)
    end
    local UI_Util = require("client.common.ui_util")
    local GameInstance = UI_Util and UI_Util.GetGameInstance()
    if not GameInstance or not cached_GameplayStatics then return end
    local deadBoxes = cached_GameplayStatics.GetAllActorsOfClass(GameInstance, cached_PlayerTombBox, _G.CachedActorArray)
    for _, deadBoxActor in pairs(deadBoxes) do
        if slua.isValid(deadBoxActor) and not deadBoxActor.bIsTDSkinApplied then
            local damageCauser = deadBoxActor.DamageCauser
            if damageCauser and damageCauser.PlayerKey == PlayerController.PlayerKey then
                local DeadBoxAvatarComponent = deadBoxActor.DeadBoxAvatarComponent_BP
                if slua.isValid(DeadBoxAvatarComponent) then
                    local currentBoxSkinId = 0
                    if PlayerCharacter.CurrentVehicle and _G.CurrentEquipVehicleID and _G.CurrentEquipVehicleID ~= 0 then
                        currentBoxSkinId = tonumber(tostring(_G.CurrentEquipVehicleID) .. "1") or 0
                    else
                        local currentWeapon = PlayerCharacter:GetCurrentWeapon()
                        if slua.isValid(currentWeapon) and currentWeapon.synData then
                            local weaponSkinData = currentWeapon.synData:Get(7)
                            if weaponSkinData and weaponSkinData.defineID then
                                currentBoxSkinId = weaponSkinData.defineID.TypeSpecificID
                            end
                        end
                    end
                    if currentBoxSkinId ~= 0 then
                        pcall(function()
                            DeadBoxAvatarComponent:ResetItemAvatar()
                            DeadBoxAvatarComponent:PreChangeItemAvatar(currentBoxSkinId)
                            DeadBoxAvatarComponent:SyncChangeItemAvatar(currentBoxSkinId)
                        end)
                    end
                    deadBoxActor.bIsTDSkinApplied = true
                end
            end
        end
    end
end

_G.TDFTDeKillCounts = _G.TDFTDeKillCounts or {}
local CACHED_LinearColor = import("LinearColor")
local CACHED_GoldColor = CACHED_LinearColor and CACHED_LinearColor(1.0, 0.8, 0.0, 1.0) or nil
local CACHED_UI_Manager = nil

_G.ForceEnableKillCounterUI = function()
    pcall(function()
        local KillCounterUISubsystem = package.loaded["GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem"] or require("GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem")
        if KillCounterUISubsystem and KillCounterUISubsystem.__inner_impl and not _G.KCUISystemHacked2 then
            local kcImpl = KillCounterUISubsystem.__inner_impl
            kcImpl.CheckSupportKCUI = function() return true end
            kcImpl.CheckNeedMainKillCounterUI = function(self, PlayerWeapon, PlayerID)
                if slua.isValid(PlayerWeapon) then
                    local WeaponID = PlayerWeapon:GetWeaponID()
                    self:UpdateMainKillCounterUI(true, WeaponID, _G.get_skin_id(WeaponID) or WeaponID)
                else self:UpdateMainKillCounterUI(false) end
            end
            local originalUpdateMainKillCounterUI = kcImpl.UpdateMainKillCounterUI
            kcImpl.UpdateMainKillCounterUI = function(self, bShow, WeaponID, AvatarID)
                if bShow then AvatarID = _G.get_skin_id(WeaponID) or AvatarID end
                if originalUpdateMainKillCounterUI then originalUpdateMainKillCounterUI(self, bShow, WeaponID, AvatarID) end
            end
            _G.KCUISystemHacked2 = true
        end

        local ModuleManager = require("client.module_framework.ModuleManager")
        if ModuleManager and not _G.KCLogicHacked2 then
            local LogicKillCounter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
            if LogicKillCounter then
                LogicKillCounter.CheckSupportKC = function() return true end
                LogicKillCounter.CheckSupportKillCounterAvatar = function() return true end
                LogicKillCounter.CheckHasWeaponKillCounter = function() return true end
                LogicKillCounter.GetBaseKillCounterIdByWeaponId = function() return 2100004 end
                LogicKillCounter.GetEquipedKillCounterId = function() return 2100004 end
                LogicKillCounter.GetMyEquipedKillCounterId = function() return 2100004 end
                LogicKillCounter.GetOneWeaponKillCountInBattle = function(self, uid, weaponId) return _G.TDFTDeKillCounts[weaponId] or 0 end
                LogicKillCounter.GetWeaponKillCountByUid = function(self, uid, weaponId) return _G.TDFTDeKillCounts[weaponId] or 0 end
                _G.KCLogicHacked2 = true
            end
        end

        local killInfoPath = "GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo"
        local KillInfo = package.loaded[killInfoPath] or require(killInfoPath)
        if KillInfo and KillInfo.__inner_impl and not _G.KillInfoCounterHacked then
            local originalFileItem = KillInfo.__inner_impl.FileItem
            KillInfo.__inner_impl.FileItem = function(self, DamageRecordData)
                pcall(function()
                    local LocalPlayer = require("GameLua.GameCore.Data.GameplayData").GetPlayerCharacter()
                    if slua.isValid(LocalPlayer) and DamageRecordData.Causer == LocalPlayer:GetPlayerNameSafety() then
                        local currentWeapon = LocalPlayer:GetCurrentWeapon()
                        if slua.isValid(currentWeapon) then
                            local weaponID = currentWeapon:GetWeaponID()
                            local skinID = _G.get_skin_id(weaponID)
                            if skinID then DamageRecordData.CauserWeaponAvatarID = skinID end
                            if _G.OutfitMap.Suit and _G.OutfitMap.Suit ~= 0 then DamageRecordData.CauserClothAvatarID = _G.OutfitMap.Suit end
                            if CACHED_GoldColor then
                                DamageRecordData.IsUseColor, DamageRecordData.UseColor = true, CACHED_GoldColor
                            end
                            if DamageRecordData.ResultHealthStatus == 2 then
                                _G.TDFTDeKillCounts[weaponID] = (_G.TDFTDeKillCounts[weaponID] or 0) + 1
                                _G.NeedCheckDeadBoxTimer = 50
                                if not CACHED_UI_Manager then CACHED_UI_Manager = require("client.slua_ui_framework.manager") end
                                local uiMainKillCounter = CACHED_UI_Manager.GetUI(CACHED_UI_Manager.UI_Config_InGame.MainKillCounter)
                                if uiMainKillCounter and uiMainKillCounter.UpdateWeaponID then
                                    local mainAvatarID = skinID or currentWeapon:GetWeaponMainAvatarID()
                                    uiMainKillCounter:UpdateWeaponID(weaponID, mainAvatarID)
                                    local kcModule = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
                                    local kcItemID = kcModule:GetEquipedKillCounterId(0, mainAvatarID)
                                    uiMainKillCounter:SetKillCounterItemShowWithNum(kcItemID, _G.TDFTDeKillCounts[weaponID], mainAvatarID)
                                end
                            end
                        end
                    end
                end)
                if originalFileItem then return originalFileItem(self, DamageRecordData) end
            end
            _G.KillInfoCounterHacked = true
        end

        local SwitchWeaponSlotMode2 = package.loaded["GameLua.Mod.BaseMod.Client.MainControlUI.SwitchWeaponSlotMode2"] or require("GameLua.Mod.BaseMod.Client.MainControlUI.SwitchWeaponSlotMode2")
        if SwitchWeaponSlotMode2 and SwitchWeaponSlotMode2.__inner_impl and not _G.SlotBaseHacked then
            SwitchWeaponSlotMode2.__inner_impl.CheckShowKCIcon = function(self)
                if slua.isValid(self.KillCounterImg) then
                    self.KillCounterImg:SetVisibility(import("ESlateVisibility").SelfHitTestInvisible)
                end
            end
            _G.SlotBaseHacked = true
        end
    end)
end

function _G.InitializeSkinModSystem()
    pcall(function()
        local LobbyAvatar = package.loaded["client.logic.avatar.LobbyAvatar"] or require("client.logic.avatar.LobbyAvatar")
        if LobbyAvatar and not _G.LobbyBypassHacked then
            local originalPutonEquipment = LobbyAvatar.PutonEquipment
            LobbyAvatar.PutonEquipment = function(self, itemID, tAvatarCustom, tExtraData)
                local attachIndex = _G.BaseAttachToIndex and _G.BaseAttachToIndex[itemID]
                if attachIndex then
                    local holdingWeaponSkinID = self.GetCurHoldingWeaponSkinID and self:GetCurHoldingWeaponSkinID()
                    if holdingWeaponSkinID and holdingWeaponSkinID >= 10000000 and _G.VIP_Attachments and _G.VIP_Attachments[holdingWeaponSkinID] then
                        local vipAttachID = _G.VIP_Attachments[holdingWeaponSkinID][attachIndex]
                        if vipAttachID and vipAttachID > 0 then
                            if self.HandleDownload then self:HandleDownload(vipAttachID, nil, nil, false) end
                            itemID = vipAttachID
                        end
                    end
                end
                if originalPutonEquipment then return originalPutonEquipment(self, itemID, tAvatarCustom, tExtraData) end
            end

            local originalCharEquipWeaponByResId = LobbyAvatar.CharEquipWeaponByResId
            LobbyAvatar.CharEquipWeaponByResId = function(self, resID, isUse, isAsync, SocketName)
                local retValue = originalCharEquipWeaponByResId and originalCharEquipWeaponByResId(self, resID, isUse, isAsync, SocketName) or nil
                if isUse and self.GetEquipments then
                    local equipments = self:GetEquipments()
                    for _, equip in ipairs(equipments) do
                        if _G.BaseAttachToIndex and _G.BaseAttachToIndex[equip.itemID] then
                            self:PutonEquipment(equip.itemID, equip.CustomInfo, {bIsUse = false})
                        end
                    end
                end
                return retValue
            end
            _G.LobbyBypassHacked = true
        end
    end)

    pcall(function()
        local Common_Items_UIBP = package.loaded["client.slua.component.item.ItemChildren.Common_Items_UIBP"] or require("client.slua.component.item.ItemChildren.Common_Items_UIBP")
        if Common_Items_UIBP and not _G.IconBaloHacked then
            local originalInitView = Common_Items_UIBP.InitView
            Common_Items_UIBP.InitView = function(self, nItemId, nCount, nValidTime, tExtraData)
                tExtraData = tExtraData or {}
                local displayResId = nil
                if _G.get_skin_id then
                    local skinID = _G.get_skin_id(nItemId)
                    if skinID and skinID ~= nItemId then displayResId = skinID end
                end
                local attachIndex = _G.BaseAttachToIndex and _G.BaseAttachToIndex[nItemId]
                if not displayResId and attachIndex then
                    local GameplayData = require("GameLua.GameCore.Data.GameplayData")
                    local LocalPlayer = GameplayData and GameplayData.GetPlayerCharacter()
                    if slua.isValid(LocalPlayer) then
                        local currentWeapon = LocalPlayer:GetCurrentWeapon()
                        if slua.isValid(currentWeapon) then
                            local weaponID = currentWeapon:GetWeaponID()
                            local finalSkinID = _G.get_skin_id(weaponID) or weaponID
                            if finalSkinID >= 10000000 and _G.VIP_Attachments and _G.VIP_Attachments[finalSkinID] then
                                local vipAttachID = _G.VIP_Attachments[finalSkinID][attachIndex]
                                if vipAttachID and vipAttachID > 0 then displayResId = vipAttachID end
                            end
                        end
                    end
                end
                if displayResId then
                    tExtraData.displayResId = displayResId
                    if not _G.skinIdCache2[displayResId] then
                        if _G.download_item then pcall(_G.download_item, displayResId) end
                        _G.skinIdCache2[displayResId] = true
                    end
                end
                if originalInitView then return originalInitView(self, nItemId, nCount, nValidTime, tExtraData) end
            end
            _G.IconBaloHacked = true
        end
    end)
end

-- ========== Skin config save/load ==========
_G.SkinConfigPath = "/storage/emulated/0/Android/data/com.tencent.igfit/files/SkinMenu.ini"

_G.SkinLoadConfig = function()
    pcall(function()
        local f = io.open(_G.SkinConfigPath, "r")
        if not f then return end
        local content = f:read("*a")
        f:close()
        for key, val in content:gmatch("(%w+)=(%d+)") do
            local v = tonumber(val) == 1
            if key == "ModSkin" then _G.SumeyyeConfig.ModSkin = v
            elseif key == "SkinDeadBox" then _G.SumeyyeConfig.SkinDeadBox = v
            elseif key == "SkinAttachment" then _G.SumeyyeConfig.SkinAttachment = v
            elseif key == "KillMessage" then _G.SumeyyeConfig.KillMessage = v
            elseif key == "KillCountUI" then _G.SumeyyeConfig.KillCountUI = v
            elseif key == "ModEmote" then _G.SumeyyeConfig.ModEmote = v
            end
        end
    end)
end

_G.SkinSaveConfig = function()
    pcall(function()
        local f = io.open(_G.SkinConfigPath, "w")
        if not f then return end
        local c = _G.SumeyyeConfig
        f:write("[SkinMenu]\n")
        f:write("ModSkin=" .. (c.ModSkin and 1 or 0) .. "\n")
        f:write("SkinDeadBox=" .. (c.SkinDeadBox and 1 or 0) .. "\n")
        f:write("SkinAttachment=" .. (c.SkinAttachment and 1 or 0) .. "\n")
        f:write("KillMessage=" .. (c.KillMessage and 1 or 0) .. "\n")
        f:write("KillCountUI=" .. (c.KillCountUI and 1 or 0) .. "\n")
        f:write("ModEmote=" .. (c.ModEmote and 1 or 0) .. "\n")
        f:close()
    end)
end

_G.SkinLoadConfig()

-- ========== BlackSky / 165FPS ==========
_G.BlackSky = function()
    local logic_setting_graphics = require("client.slua.logic.setting.logic_setting_graphics")
    if not logic_setting_graphics then return end
    local gi = logic_setting_graphics.GetGameInstance and logic_setting_graphics.GetGameInstance()
    if not gi then
        local GameplayStatics = import("GameplayStatics")
        gi = GameplayStatics.GetGameInstance(nil)
    end
    if not gi then return end
    if _G.SumeyyeHax and _G.SumeyyeHax.BlackSky then
        gi:ExecuteCMD("r.CylinderMaxDrawHeight", "9999")
    else
        gi:ExecuteCMD("r.CylinderMaxDrawHeight", "0")
    end
end

function _G.Enable165FPSLogic()
    pcall(function()
        local graphics = require("client.slua.logic.setting.logic_setting_graphics")
        local fpsComp = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
        local fpsFT = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
        local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
        if graphics then
            local originalSetFPS = graphics.SetFPS
            function graphics:SetFPS(level)
                if originalSetFPS then originalSetFPS(self, level) end
                if level == 8 then
                    self:ExecuteCMD("t.MaxFPS", "165")
                    self:ExecuteCMD("r.FrameRateLimit", "165")
                end
            end
        end
        if fpsComp and fpsComp.__inner_impl then
            local impl = fpsComp.__inner_impl
            function impl.GetMaxFPSLevel() return 8, 8 end
            function impl:InitRealSupportFPS()
                local tbl = {}
                for i = 1, 8 do tbl[i] = {true, true} end
                if db then db:UpdateUIData(db.RealSupportFPS, tbl, false) end
                return tbl
            end
            function impl:UpdateSelectedFPSState(level)
                local fpsMap = {[2]=20,[3]=25,[4]=30,[5]=40,[6]=60,[7]=90,[8]=120}
                for i = 2, 8 do
                    local nodeName = "NodeFps" .. tostring(fpsMap[i] or 120)
                    local node = self.UIRoot[nodeName]
                    if slua.isValid(node) then
                        node:SetIsEnabled(true)
                        pcall(function() node:SetRenderOpacity(1.0) end)
                        local switcher = self.UIRoot["WidgetSwitcher_" .. i]
                        if slua.isValid(switcher) then switcher:SetActiveWidgetIndex(i == level and 0 or 1) end
                    end
                end
            end
        end
        if fpsFT and fpsFT.__inner_impl then
            local impl = fpsFT.__inner_impl
            local MIN_FPS, MAX_FPS, STEP = 90, 165, 5
            local clamp = function(v) return math.max(MIN_FPS, math.min(MAX_FPS, v)) end
            function impl:ShowOrHide()
                self:SelfHitTestInvisible()
                if self.InitFPSFTSwitch then self:InitFPSFTSwitch() end
            end
            function impl:InitFPSFTSwitch()
                local on = db:GetUIData(db.FPSFineTuneSwitch)
                if self.UIRoot.Setting_Switch then self.UIRoot.Setting_Switch:SetSwitcherEnable2(on, true) end
                if self.UIRoot.CanvasPanel_8 then self:SetWidgetVisible(self.UIRoot.CanvasPanel_8, on) end
                if self.UIRoot.WidgetSwitcher_0 then self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(2) end
                if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
            end
            function impl:InitFPSFTValue165()
                local root = self.UIRoot
                local on = db:GetUIData(db.FPSFineTuneSwitch)
                local val = on and (db:GetUIData(db.FPSFineTuneNum) or 165) or 165
                if on then
                    root.Slider_screen3:SetLocked(false)
                    root.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1, 1, 1, 1))
                    root.Slider_screen3:SetSliderHandleColor(FLinearColor(1, 1, 1, 1))
                else
                    root.Slider_screen3:SetLocked(true)
                    root.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1, 0.625, 0.6, 1))
                    root.Slider_screen3:SetSliderHandleColor(FLinearColor(1, 0.625, 0.6, 1))
                end
                local norm = (val - MIN_FPS) / (MAX_FPS - MIN_FPS)
                root.Veihclescreen3:SetText(tostring(val))
                root.Slider_screen3:SetValue(norm)
                root.ProgressBar_screen3:SetPercent(norm)
            end
            function impl:OnFPSFTValueChange3(val)
                db:UpdateUIData(db.FPSFineTuneNum, val)
                if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
                if self:GetParentUI() then self:GetParentUI():SetDirty(true) end
                local gi = db.GetGameInstance and db.GetGameInstance()
                if gi then
                    gi:ExecuteCMD("t.MaxFPS", tostring(val))
                    gi:ExecuteCMD("r.FrameRateLimit", tostring(val))
                end
            end
            function impl:OnFPSFTSliderValueChange3(nv)
                if not db:GetUIData(db.FPSFineTuneSwitch) then return end
                local raw = math.floor(MIN_FPS + (MAX_FPS - MIN_FPS) * nv)
                raw = math.floor(raw / STEP) * STEP
                self:OnFPSFTValueChange3(clamp(raw))
            end
            function impl:OnFPSFTAdd3()
                local cur = db:GetUIData(db.FPSFineTuneNum) or MIN_FPS
                self:OnFPSFTValueChange3(math.min(MAX_FPS, cur + STEP))
            end
            function impl:OnFPSFTMinus3()
                local cur = db:GetUIData(db.FPSFineTuneNum) or MIN_FPS
                self:OnFPSFTValueChange3(math.max(MIN_FPS, cur - STEP))
            end
            impl.OnFPSFTAdd = impl.OnFPSFTAdd3
            impl.OnFPSFTMinus = impl.OnFPSFTMinus3
            impl.OnFPSFTSliderValueChange = impl.OnFPSFTSliderValueChange3
        end
    end)
end

-- ========== Emote mod ==========
pcall(function()
    local QuickExpressionUtils = require("GameLua.Mod.BaseMod.Client.Emote.QuickExpressionUtils")
    local EXTRA_EMOTES = {
        12201301,12216101,12212201,12219207,12209001,12219561,12210001,12219022,12208801,12210801,
        12200701,12219242,12206001,12205401,12205201,12212601,12205601,12219208,12212001,12206801,
        12209801,12211401,12207001,12211801,12207901,12203401,12204001,12201801,12215601,12215532,
        12213201,12215529,12219053,12204601,12215701,12219003,12219004,12219009,12219216,
    }
    local CachedInGameEmotes = nil
    local LastBaseCount = -1
    local LastEmoteSwitchState = nil
    local function GetOptimizedEmoteList(baseList)
        local baseCount = baseList and #baseList or 0
        local isEmoteModEnabled = _G.SumeyyeConfig.ModEmote == true
        if CachedInGameEmotes and LastBaseCount == baseCount and LastEmoteSwitchState == isEmoteModEnabled then
            return CachedInGameEmotes
        end
        local compact = {}
        local seen = {}
        if baseList then
            for _, data in pairs(baseList) do
                if data and data.DefineID and data.DefineID.TypeSpecificID then
                    table.insert(compact, data)
                    seen[data.DefineID.TypeSpecificID] = true
                end
            end
        end
        if isEmoteModEnabled then
            for _, nEmoteID in ipairs(EXTRA_EMOTES) do
                if not seen[nEmoteID] then
                    table.insert(compact, {DefineID = {TypeSpecificID = nEmoteID}, Name = tostring(nEmoteID)})
                    seen[nEmoteID] = true
                end
            end
        end
        CachedInGameEmotes = compact
        LastBaseCount = baseCount
        LastEmoteSwitchState = isEmoteModEnabled
        return CachedInGameEmotes
    end
    if QuickExpressionUtils and not _G.__EMOTE_INGAME_HOOKED then
        _G.__EMOTE_INGAME_HOOKED = true
        _G.__EMOTE_ORIG_GET_LIST = QuickExpressionUtils.GetShowExpressionList
        QuickExpressionUtils.GetShowExpressionList = function()
            local baseList, nWeaponShowEmoteID = _G.__EMOTE_ORIG_GET_LIST()
            return GetOptimizedEmoteList(baseList), nWeaponShowEmoteID
        end
    end
    if not _G.__EMOTE_MENU_EVENT_HOOKED and EventSystem and EventSystem.registEvent then
        _G.__EMOTE_MENU_EVENT_HOOKED = true
        EventSystem:registEvent(EVENTTYPE_INGAME, EVENTID_INGAME_QUICK_EXPRESSION_DECAL_CLICK, function()
            pcall(function()
                if not _G.SumeyyeConfig.ModEmote then return end
                local UIManager = require("client.slua_ui_framework.manager")
                if not UIManager or not UIManager.UI_Config_InGame then return end
                local subPanel = UIManager.GetUI(UIManager.UI_Config_InGame.QuickExpressionDecalSubPanel)
                if subPanel and subPanel.GetQuickExpressionDecalItemByIndex and CachedInGameEmotes then
                    local showCount = 0
                    for _, data in ipairs(CachedInGameEmotes) do
                        local nEmoteID = data.DefineID and data.DefineID.TypeSpecificID
                        if nEmoteID and nEmoteID > 0 then
                            showCount = showCount + 1
                            local item = subPanel:GetQuickExpressionDecalItemByIndex(showCount)
                            if item then
                                if item.UIRoot.WidgetSwitcher_Effect then item.UIRoot.WidgetSwitcher_Effect:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
                                if item.UIRoot.Image_Weapon then item.UIRoot.Image_Weapon:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
                                item:Show()
                                item:RefreshData(nEmoteID, -1)
                            end
                        end
                    end
                    if subPanel.HideRestBlocks then subPanel:HideRestBlocks(showCount) end
                    if subPanel.UIRoot then
                        subPanel.UIRoot.WrapBox_List:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
                        subPanel.UIRoot.VerticalBox_Empty:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                    end
                end
            end)
        end)
    end
end)

-- ========== Skin Tick Loop (independent of BRPlayerCharacterBase) ==========
local _lastSkinApply = 0
_G._skinTickLoopBody = function()
    pcall(function()
        local GD = require("GameLua.GameCore.Data.GameplayData")
        local pc = GD.GetPlayerController()
        if not pc or not slua.isValid(pc) then return end
        local localPlayer = pc:GetPlayerCharacterSafety()
        if not localPlayer or not slua.isValid(localPlayer) then return end
        local now = os.clock()
        if (now - _lastSkinApply) < 1.5 then return end
        _lastSkinApply = now
        if _G.ForceRefreshSkinMaps then pcall(_G.ForceRefreshSkinMaps) end
        if _G.equip_character_avatar then pcall(_G.equip_character_avatar, localPlayer) end
        if _G.ApplyWeaponSkins then pcall(_G.ApplyWeaponSkins, localPlayer) end
        if _G.ApplyVehicleSkins then pcall(_G.ApplyVehicleSkins, localPlayer) end
        if _G.HandlePetLogic then pcall(_G.HandlePetLogic) end
    end)
end

local function skinTickLoop()
    _G._skinTickLoopBody()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(1.5, skinTickLoop)
    end
end

-- ========== Merged ModMenu Init ==========
_G.InitSkinModSystem_FromMenu = function()
    if _G._SkinModBooted then return end
    _G._SkinModBooted = true
    pcall(function()
        if _G.InitializeSkinModSystem then _G.InitializeSkinModSystem() end
    end)
    pcall(skinTickLoop)
    pcall(function()
        if _G.Enable165FPSLogic then _G.Enable165FPSLogic() end
    end)
end

function _G.InitModMenuTab()
    if _G.ModMenuInitialized then return end
    _G.ModMenuInitialized = true

    local function T(vnText, enText) return enText or vnText end

    local LocUtil = _G.LocUtil
    if not LocUtil and package.loaded["client.common.LocUtil"] then
        LocUtil = require("client.common.LocUtil")
    end

    local FakeTextMap = {
        [999000] = T("BLACK ESP"),
        [999001] = T("ESP SETTINGS"),
        [999100] = " BEYSA SKIN MENU",
        [999101] = "Mod Skin (Silah / Karakter / Araç)",
        [999102] = "Sandık Skini",
        [999103] = "Silah Eklenti Skini",
        [999104] = "Kill Message VIP",
        [999105] = "Kill Sayacı",
        [999106] = "Mod Emote",
        [999107] = "Ayarları Kaydet",
        [999108] = "   Suit Skin",
        [999109] = "   Bag Skin",
        [999110] = "   Helmet Skin",
        [999111] = "   M416 Skin",
        [999112] = "   AKM Skin",
        [999113] = "   SCAR Skin",
        [999114] = "   M762 Skin",
        [999115] = "   AUG Skin",
        [999116] = "   UMP Skin",
        [999117] = "   UZI Skin",
        [999118] = "   Groza Skin",
        [999119] = "   S12K Skin",
        [999120] = "   DBS Skin",
        [999121] = "   ASM Gen8 Skin",
        [999122] = "   QBZ Skin",
        [999123] = "   Honey Badger Skin",
        [999124] = "   M16A4 Skin",
        [999125] = "   ACE32 Skin",
        [999126] = "   Kar98k Skin",
        [999127] = "   M24 Skin",
        [999128] = "   AWM Skin",
        [999129] = "   Dacia Skin",
        [999130] = "   UAZ Skin",
        [999131] = "   Coupe Skin",
        [999132] = "   Buggy Skin",
        [999133] = "   Mirado Skin",
        [999134] = T("SKIN SETTINGS"),
    }

    if LocUtil and not LocUtil._IsModMenuHooked_V2 then
        local hookFuncs = {"GetLocalizeResStr", "GetText", "GetTextByID", "GetLocalText", "GetLocalizeStr"}
        for _, funcName in ipairs(hookFuncs) do
            if LocUtil[funcName] then
                local old_func = LocUtil[funcName]
                LocUtil[funcName] = function(id)
                    if FakeTextMap[id] then return FakeTextMap[id] end
                    if type(id) == "string" and not tonumber(id) then return id end
                    if old_func then return old_func(id) end
                    return ""
                end
            end
        end
        LocUtil._IsModMenuHooked_V2 = true
    end

    local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
    local SettingCatalog    = require("client.logic.NewSetting.SettingCatalog")

    if not SettingPageDefine.ModMenu then
        local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")

        local StackESP = {
            { Key = "ModMenu_BoxESP",         UI = AliasMap.TitleSwitcher, Text = T("ESP BOX"),                       ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.BoxESP end,          SetFunc = function(c,v) _G.LexusConfig.BoxESP = v; return true end },
            { Key = "ModMenu_BoxESP_Health",  UI = AliasMap.Switcher,      Text = T("   Health Bar"),                  ExpandHandle = "ModMenu_BoxESP", GetFunc = function() return _G.LexusConfig.BoxESP_Health end,   SetFunc = function(c,v) _G.LexusConfig.BoxESP_Health = v; return true end },
            { Key = "ModMenu_BoxESP_Name",    UI = AliasMap.Switcher,      Text = T("   Player Name"),                 ExpandHandle = "ModMenu_BoxESP", GetFunc = function() return _G.LexusConfig.BoxESP_Name end,     SetFunc = function(c,v) _G.LexusConfig.BoxESP_Name = v; return true end },
            { Key = "ModMenu_BoxESP_Distance",UI = AliasMap.Switcher,      Text = T("   Distance"),                    ExpandHandle = "ModMenu_BoxESP", GetFunc = function() return _G.LexusConfig.BoxESP_Distance end, SetFunc = function(c,v) _G.LexusConfig.BoxESP_Distance = v; return true end },
            { Key = "ModMenu_BoxESP_Weapon",  UI = AliasMap.Switcher,      Text = T("   Weapon Name"),                 ExpandHandle = "ModMenu_BoxESP", GetFunc = function() return _G.LexusConfig.BoxESP_Weapon end,   SetFunc = function(c,v) _G.LexusConfig.BoxESP_Weapon = v; return true end },
            { Key = "ModMenu_BoxESP_Flag",    UI = AliasMap.Switcher,      Text = T("   Country Flag"),                ExpandHandle = "ModMenu_BoxESP", GetFunc = function() return _G.LexusConfig.BoxESP_Flag end,     SetFunc = function(c,v) _G.LexusConfig.BoxESP_Flag = v; return true end },
            { Key = "ModMenu_BoxESP_State",   UI = AliasMap.Switcher,      Text = T("   State (Open/Cover/Knocked)"),  ExpandHandle = "ModMenu_BoxESP", GetFunc = function() return _G.LexusConfig.BoxESP_State end,    SetFunc = function(c,v) _G.LexusConfig.BoxESP_State = v; return true end },
            { Key = "ModMenu_BoxESP_Lines",   UI = AliasMap.Switcher,      Text = T("   Snaplines"),                   ExpandHandle = "ModMenu_BoxESP", GetFunc = function() return _G.LexusConfig.BoxESP_Lines end,    SetFunc = function(c,v) _G.LexusConfig.BoxESP_Lines = v; return true end },
            { Key = "ModMenu_BoxESP_Counter", UI = AliasMap.Switcher,      Text = T("   Player/Bot Counter"),          ExpandHandle = "ModMenu_BoxESP", GetFunc = function() return _G.LexusConfig.BoxESP_Counter end,  SetFunc = function(c,v) _G.LexusConfig.BoxESP_Counter = v; return true end },
        }

        local S = _G.SumeyyeConfig
        local State = _G.SumeyyeState

        local StackSkin = {
            { Key = "SkinMenu_ModSkin", UI = AliasMap.TitleSwitcher, Text = 999101, ExpandIndex = 0,
              GetFunc = function() return S.ModSkin end,
              SetFunc = function(c,v) S.ModSkin = v; if _G.SkinSaveConfig then _G.SkinSaveConfig() end; return true end },
            { Key = "SkinMenu_Suit", UI = AliasMap.Slider, Text = 999108, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 80,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinSuit or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinSuit = v; if _G.OutfitSkins and _G.OutfitSkins.Suit[v] then _G.OutfitMap.Suit = _G.OutfitSkins.Suit[v] end; return true end },
            { Key = "SkinMenu_Bag", UI = AliasMap.Slider, Text = 999109, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 15,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinBag or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinBag = v; if _G.OutfitSkins and _G.OutfitSkins.Bag[v] then _G.OutfitMap.Bag = _G.OutfitSkins.Bag[v] end; return true end },
            { Key = "SkinMenu_Helmet", UI = AliasMap.Slider, Text = 999110, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 11,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinHelmet or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinHelmet = v; if _G.OutfitSkins and _G.OutfitSkins.Helmet[v] then _G.OutfitMap.Helmet = _G.OutfitSkins.Helmet[v] end; return true end },
            { Key = "SkinMenu_M416", UI = AliasMap.Slider, Text = 999111, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 8,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinM416 or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinM416 = v; if _G.skinIdMappings[101004] and _G.skinIdMappings[101004][v] then _G.WeaponSkinMap[101004] = _G.skinIdMappings[101004][v] end; return true end },
            { Key = "SkinMenu_AKM", UI = AliasMap.Slider, Text = 999112, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 8,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinAKM or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinAKM = v; if _G.skinIdMappings[101001] and _G.skinIdMappings[101001][v] then _G.WeaponSkinMap[101001] = _G.skinIdMappings[101001][v] end; return true end },
            { Key = "SkinMenu_SCAR", UI = AliasMap.Slider, Text = 999113, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 8,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinSCAR or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinSCAR = v; if _G.skinIdMappings[101003] and _G.skinIdMappings[101003][v] then _G.WeaponSkinMap[101003] = _G.skinIdMappings[101003][v] end; return true end },
            { Key = "SkinMenu_M762", UI = AliasMap.Slider, Text = 999114, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 8,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinM762 or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinM762 = v; if _G.skinIdMappings[101008] and _G.skinIdMappings[101008][v] then _G.WeaponSkinMap[101008] = _G.skinIdMappings[101008][v] end; return true end },
            { Key = "SkinMenu_AUG", UI = AliasMap.Slider, Text = 999115, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 7,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinAUG or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinAUG = v; if _G.skinIdMappings[101006] and _G.skinIdMappings[101006][v] then _G.WeaponSkinMap[101006] = _G.skinIdMappings[101006][v] end; return true end },
            { Key = "SkinMenu_UMP", UI = AliasMap.Slider, Text = 999116, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 5,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinUMP or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinUMP = v; if _G.skinIdMappings[102002] and _G.skinIdMappings[102002][v] then _G.WeaponSkinMap[102002] = _G.skinIdMappings[102002][v] end; return true end },
            { Key = "SkinMenu_UZI", UI = AliasMap.Slider, Text = 999117, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 2,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinUZI or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinUZI = v; if _G.skinIdMappings[102001] and _G.skinIdMappings[102001][v] then _G.WeaponSkinMap[102001] = _G.skinIdMappings[102001][v] end; return true end },
            { Key = "SkinMenu_Groza", UI = AliasMap.Slider, Text = 999118, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 2,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinGroza or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinGroza = v; if _G.skinIdMappings[101005] and _G.skinIdMappings[101005][v] then _G.WeaponSkinMap[101005] = _G.skinIdMappings[101005][v] end; return true end },
            { Key = "SkinMenu_S12K", UI = AliasMap.Slider, Text = 999119, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 2,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinS12K or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinS12K = v; if _G.skinIdMappings[104003] and _G.skinIdMappings[104003][v] then _G.WeaponSkinMap[104003] = _G.skinIdMappings[104003][v] end; return true end },
            { Key = "SkinMenu_DBS", UI = AliasMap.Slider, Text = 999120, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 3,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinDBS or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinDBS = v; if _G.skinIdMappings[104004] and _G.skinIdMappings[104004][v] then _G.WeaponSkinMap[104004] = _G.skinIdMappings[104004][v] end; return true end },
            { Key = "SkinMenu_ASM", UI = AliasMap.Slider, Text = 999121, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 2,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinASM or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinASM = v; if _G.skinIdMappings[101101] and _G.skinIdMappings[101101][v] then _G.WeaponSkinMap[101101] = _G.skinIdMappings[101101][v] end; return true end },
            { Key = "SkinMenu_QBZ", UI = AliasMap.Slider, Text = 999122, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 2,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinQBZ or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinQBZ = v; if _G.skinIdMappings[101007] and _G.skinIdMappings[101007][v] then _G.WeaponSkinMap[101007] = _G.skinIdMappings[101007][v] end; return true end },
            { Key = "SkinMenu_Honey", UI = AliasMap.Slider, Text = 999123, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 2,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinHoney or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinHoney = v; if _G.skinIdMappings[101012] and _G.skinIdMappings[101012][v] then _G.WeaponSkinMap[101012] = _G.skinIdMappings[101012][v] end; return true end },
            { Key = "SkinMenu_M16A4", UI = AliasMap.Slider, Text = 999124, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 2,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinM16A4 or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinM16A4 = v; if _G.skinIdMappings[101002] and _G.skinIdMappings[101002][v] then _G.WeaponSkinMap[101002] = _G.skinIdMappings[101002][v] end; return true end },
            { Key = "SkinMenu_ACE32", UI = AliasMap.Slider, Text = 999125, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 2,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinACE32 or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinACE32 = v; if _G.skinIdMappings[101102] and _G.skinIdMappings[101102][v] then _G.WeaponSkinMap[101102] = _G.skinIdMappings[101102][v] end; return true end },
            { Key = "SkinMenu_Kar98k", UI = AliasMap.Slider, Text = 999126, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 2,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinKar98k or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinKar98k = v; if _G.skinIdMappings[103001] and _G.skinIdMappings[103001][v] then _G.WeaponSkinMap[103001] = _G.skinIdMappings[103001][v] end; return true end },
            { Key = "SkinMenu_M24", UI = AliasMap.Slider, Text = 999127, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 2,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinM24 or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinM24 = v; if _G.skinIdMappings[103002] and _G.skinIdMappings[103002][v] then _G.WeaponSkinMap[103002] = _G.skinIdMappings[103002][v] end; return true end },
            { Key = "SkinMenu_AWM", UI = AliasMap.Slider, Text = 999128, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 2,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinAWM or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinAWM = v; if _G.skinIdMappings[103003] and _G.skinIdMappings[103003][v] then _G.WeaponSkinMap[103003] = _G.skinIdMappings[103003][v] end; return true end },
            { Key = "SkinMenu_Dacia", UI = AliasMap.Slider, Text = 999129, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 34,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinDacia or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinDacia = v; if _G.VehicleSkins[1903001] and _G.VehicleSkins[1903001][v] then _G.VehicleSkinMap[1903001] = _G.VehicleSkins[1903001][v] end; return true end },
            { Key = "SkinMenu_UAZ", UI = AliasMap.Slider, Text = 999130, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 16,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinUAZ or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinUAZ = v; if _G.VehicleSkins[1908001] and _G.VehicleSkins[1908001][v] then _G.VehicleSkinMap[1908001] = _G.VehicleSkins[1908001][v] end; return true end },
            { Key = "SkinMenu_Coupe", UI = AliasMap.Slider, Text = 999131, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 55,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinCoupe or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinCoupe = v; if _G.VehicleSkins[1961001] and _G.VehicleSkins[1961001][v] then _G.VehicleSkinMap[1961001] = _G.VehicleSkins[1961001][v] end; return true end },
            { Key = "SkinMenu_Buggy", UI = AliasMap.Slider, Text = 999132, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 11,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinBuggy or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinBuggy = v; if _G.VehicleSkins[1907002] and _G.VehicleSkins[1907002][v] then _G.VehicleSkinMap[1907002] = _G.VehicleSkins[1907002][v] end; return true end },
            { Key = "SkinMenu_Mirado", UI = AliasMap.Slider, Text = 999133, ExpandHandle = "SkinMenu_ModSkin", MinValue = 1, MaxValue = 5,
              GetFunc = function() return State.CustomTextData and State.CustomTextData.SkinMirado or 1 end,
              SetFunc = function(c,v) if not State.CustomTextData then State.CustomTextData = {} end State.CustomTextData.SkinMirado = v; if _G.VehicleSkins[1915004] and _G.VehicleSkins[1915004][v] then _G.VehicleSkinMap[1915004] = _G.VehicleSkins[1915004][v] end; return true end },
            { Key = "SkinMenu_SkinDeadBox", UI = AliasMap.Switcher, Text = 999102,
              GetFunc = function() return S.SkinDeadBox end,
              SetFunc = function(c,v) S.SkinDeadBox = v; if _G.SkinSaveConfig then _G.SkinSaveConfig() end; return true end },
            { Key = "SkinMenu_SkinAttachment", UI = AliasMap.Switcher, Text = 999103,
              GetFunc = function() return S.SkinAttachment end,
              SetFunc = function(c,v) S.SkinAttachment = v; if _G.SkinSaveConfig then _G.SkinSaveConfig() end; return true end },
            { Key = "SkinMenu_KillMessage", UI = AliasMap.Switcher, Text = 999104,
              GetFunc = function() return S.KillMessage end,
              SetFunc = function(c,v) S.KillMessage = v; if _G.SkinSaveConfig then _G.SkinSaveConfig() end; return true end },
            { Key = "SkinMenu_KillCountUI", UI = AliasMap.Switcher, Text = 999105,
              GetFunc = function() return S.KillCountUI end,
              SetFunc = function(c,v) S.KillCountUI = v; if _G.SkinSaveConfig then _G.SkinSaveConfig() end; if v and _G.ForceEnableKillCounterUI then pcall(_G.ForceEnableKillCounterUI) end; return true end },
            { Key = "SkinMenu_ModEmote", UI = AliasMap.Switcher, Text = 999106,
              GetFunc = function() return S.ModEmote end,
              SetFunc = function(c,v) S.ModEmote = v; if _G.SkinSaveConfig then _G.SkinSaveConfig() end; return true end },
        }

        SettingPageDefine.ModMenu = {
            Key = "ModMenu",
            Text = 999000,
            UIKey = "Setting_Page_Privacy",
            Category = {
                { Key = "Cat_ESP",  Text = 999001, Stack = StackESP  },
                { Key = "Cat_Skin", Text = 999134, Stack = StackSkin },
            }
        }

        table.insert(SettingCatalog, 1, SettingPageDefine.ModMenu)
    end

    local UIManager = _G.UIManager
    if UIManager and not UIManager._IsModMenuHooked then
        local old_ShowUI = UIManager.ShowUI
        UIManager.ShowUI = function(config, ...)
            local args = {...}
            local n = select('#', ...)
            if config and config.keyName then
                local lowerKeyName = string.lower(config.keyName)
                if string.find(lowerKeyName, "setting_main") and not string.find(lowerKeyName, "custom") then
                    local catalog = args[1]
                    if type(catalog) == "table" and catalog[1] and type(catalog[1]) == "table" and catalog[1].Key then
                        local hasModMenu = false
                        for _, page in ipairs(catalog) do
                            if type(page) == "table" and page.Key == "ModMenu" then hasModMenu = true; break end
                        end
                        if not hasModMenu then table.insert(catalog, 1, SettingPageDefine.ModMenu) end
                    end
                end
            end
            local table_unpack = table.unpack or unpack
            return old_ShowUI(config, table_unpack(args, 1, n))
        end
        UIManager._IsModMenuHooked = true
    end
end

-- ========== Boot ==========
pcall(function()
    local PC = nil
    if slua_GameFrontendHUD and slua_GameFrontendHUD.GetPlayerController then
        PC = slua_GameFrontendHUD:GetPlayerController()
    end
    if IsValid(PC) and PC.AddGameTimer then
        PC:AddGameTimer(0.02, true, BoxESP.UpdateESP)
    end
end)

pcall(function()
    local Ticker = package.loaded["common.time_ticker"] or require("common.time_ticker")
    if Ticker and Ticker.AddTimerLoop then
        Ticker.AddTimerLoop(function()
            BoxESP.UpdateESP()
            return true
        end, 0.02)
    end
end)

_G.BoxESP = BoxESP

pcall(_G.InitModMenuTab)

pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(8.0, function()
            pcall(_G.InitModMenuTab)
        end)
    end
end)

-- ========== BRPlayerCharacterBase (features untouched) ==========
local class = require("class")
local CCharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CombineClass = require("combine_class")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")

local CBRPlayerCharacterBase = class(CCharacterBase, nil, BRPlayerCharacterBase)

function CBRPlayerCharacterBase:ReceiveBeginPlay()
    CCharacterBase.ReceiveBeginPlay(self)
    self:SetActorTickEnabled(true)

    pcall(function()
        if _G.InitializeSkinModSystem then pcall(_G.InitializeSkinModSystem) end
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(3.0, skinTickLoop)
        end
    end)

    if Client then
        self:AddGameTimer(2.0, true, function()
            if not slua.isValid(self.Object) then return end
            local pc = GameplayData.GetPlayerCharacter()
            if not slua.isValid(pc) or pc ~= self.Object then return end
            ReadFOVConfig()
            ApplyFOVToCameras(self.Object)
        end)
        self:AddGameTimer(3.0, false, function()
            _G.InitSkinModSystem_FromMenu()
        end)
    end
end

function CBRPlayerCharacterBase:ReceiveEndPlay(reason)
    CCharacterBase.ReceiveEndPlay(self, reason)
    if Client and GameplayData.RemoveCharacter then
        GameplayData.RemoveCharacter(self.Object)
    end
end

return CombineClass.DeclareFeature(CBRPlayerCharacterBase, {
  { SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature" },
  { CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature" },
  { SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature" },
  { TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature" },
  { LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature" },
  { FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature" },
  { CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature" },
  { BuildSkateFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature" },
  { CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature" },
  { ParachuteFormation = "GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature" },
  { SpiderSenseFootprintFeature = "GameLua.Mod.Library.GamePlay.Feature.SpiderSenseFootprintFeature" },
  { GeneralShowSpotFeature = "GameLua.Mod.BRMod.Gameplay.Feature.PlayerCharacterGeneralShowSpotFeature" }
}, "BRPlayerCharacterBase")