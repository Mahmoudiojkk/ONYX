local BRPlayerCharacterBase = {
  ServerRPC = {},
  ClientRPC = {},
  MulticastRPC = {},
  LuaEventContainer = {}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = {
  Reliable = true,
  Params = {}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Object
  }
}
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Int
  }
}
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Int
  }
}
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Bool
  }
}
local ENetRole = import("ENetRole")
local EPawnState = import("EPawnState")
local ECharacterHideMovementAcive = import("ECharacterHideMovementAcive")
local ESpecialMovementType = import("ESpecialMovementType")
local ESpiderSwingMoveState = import("ESpiderSwingMoveState")
local ESurviveWeaponPropSlot = import("ESurviveWeaponPropSlot")
local EParachuteState = import("EParachuteState")
local EMovementMode = import("EMovementMode")
local EStateType = import("EStateType")
local ESTEPoseState = import("ESTEPoseState")
local EGameModeType = import("EGameModeType")
local STExtraGameStateBase = import("STExtraGameStateBase")
local UKismetSystemLibrary = import("KismetSystemLibrary")
local USTExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
local MatchModeIds = require("GameLua.Mod.BaseMod.GamePlay.Config.MatchModeIdsConfig")

local LocUtilModule = require("client.common.LocUtil")
local SettingPageDefineModule = require("client.logic.NewSetting.SettingPageDefine")
local SettingCatalogModule = require("client.logic.NewSetting.SettingCatalog")
local AliasMapModule = require("client.slua.umg.NewSetting.Item.AliasMap")

-- ====================================================================
-- COMBAT BLOCK
-- ====================================================================
_G.LexusConfig = _G.LexusConfig or {}
_G.LexusConfig.FakeHWID          = _G.LexusConfig.FakeHWID          or false
_G.LexusConfig.IpadView          = _G.LexusConfig.IpadView          or false
_G.LexusConfig.WeaponGlow        = _G.LexusConfig.WeaponGlow        or false
_G.LexusConfig.NoRecoilEnabled   = _G.LexusConfig.NoRecoilEnabled   or false
_G.LexusConfig.RecoilReduction   = _G.LexusConfig.RecoilReduction   or 100
_G.LexusConfig.AutoHead          = _G.LexusConfig.AutoHead          or false
_G.LexusConfig.WeaponAimbot      = _G.LexusConfig.WeaponAimbot      or false

_G.LexusState = _G.LexusState or {}
_G.LexusState.CustomTextData = _G.LexusState.CustomTextData or {}
_G.LexusState.CustomTextData.IpadViewFOV         = _G.LexusState.CustomTextData.IpadViewFOV         or 120
_G.LexusState.CustomTextData.WeaponGlowColor     = _G.LexusState.CustomTextData.WeaponGlowColor     or 5
_G.LexusState.CustomTextData.WeaponGlowThickness = _G.LexusState.CustomTextData.WeaponGlowThickness or 3

local function _Valid(o)
    if not o then return false end
    if slua and slua.isValid then
        local ok, v = pcall(slua.isValid, o)
        return ok and v
    end
    return true
end

local function _GetGDP()
    local ok, m = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if ok then return m end
    return nil
end

local function _GetLC()
    return import("LinearColor") or _G.FLinearColor
end

_G.InitFakeHWID = function()
    pcall(function()
        local SystemLib = import("KismetSystemLibrary")
        if SystemLib and not _G.FakeHWID_Hooked then
            _G.Original_GetDeviceId = SystemLib.GetDeviceId
            SystemLib.GetDeviceId = function(...)
                if _G.LexusConfig.FakeHWID then
                    if not _G.FakeHWID_String then
                        local chars = "0123456789ABCDEF"
                        local hwid = ""
                        for i = 1, 32 do
                            local idx = math.random(1, #chars)
                            hwid = hwid .. chars:sub(idx, idx)
                            if i == 8 or i == 12 or i == 16 or i == 20 then hwid = hwid .. "-" end
                        end
                        _G.FakeHWID_String = hwid
                    end
                    return _G.FakeHWID_String
                end
                if _G.Original_GetDeviceId then return _G.Original_GetDeviceId(...) end
                return "UNKNOWN"
            end
            _G.FakeHWID_Hooked = true
        end
    end)
end

_G.ApplyIpadView = function(localPlayer)
    if not _Valid(localPlayer) then return end
    pcall(function()
        local cam = localPlayer.ThirdPersonCameraComponent
        if not _Valid(cam) then return end
        local target = _G.LexusConfig.IpadView and (_G.LexusState.CustomTextData.IpadViewFOV or 120) or 90
        if cam.FieldOfView ~= target then cam.FieldOfView = target end
    end)
end

_G.ApplyWeaponGlow = function(PlayerCharacter)
    pcall(function()
        local WM = PlayerCharacter:GetWeaponManager()
        if not _Valid(WM) then return end
        local LC = _GetLC()
        local enabled = _G.LexusConfig.WeaponGlow
        local intensity = 80.0
        local thick = _G.LexusState.CustomTextData.WeaponGlowThickness or 3
        local mode = _G.LexusState.CustomTextData.WeaponGlowColor or 5
        local r, g, b = 1.0, 1.0, 0.0
        if mode == 1 then r, g, b = 1.0, 0.0, 0.0
        elseif mode == 2 then r, g, b = 0.0, 1.0, 0.0
        elseif mode == 3 then r, g, b = 0.0, 0.0, 1.0
        elseif mode == 4 then r, g, b = 1.0, 1.0, 0.0
        elseif mode == 5 then
            local t = os.clock() * 2.0
            r = (math.sin(t) + 1) / 2
            g = (math.sin(t + 2) + 1) / 2
            b = (math.sin(t + 4) + 1) / 2
        end
        local color = LC and LC(r * intensity, g * intensity, b * intensity, 1.0)
                      or { R = r * 255 * intensity, G = g * 255 * intensity, B = b * 255 * intensity, A = 255 }
        for slot = 1, 3 do
            local W = WM:GetInventoryWeaponByPropSlot(slot)
            if _Valid(W) then
                local okC, meshClass = pcall(function() return import("/Script/Engine.MeshComponent") end)
                if okC then
                    local okG, comps = pcall(function() return W:GetComponentsByClass(meshClass) end)
                    if okG and comps then
                        local n = type(comps.Num) == "function" and comps:Num() or #comps
                        for i = 1, n do
                            local comp = type(comps.Get) == "function" and comps:Get(i - 1) or comps[i]
                            if _Valid(comp) then
                                if enabled then
                                    pcall(function()
                                        comp.UseScopeDistanceCulling = false
                                        comp.PrimitiveShadingStrategy = 1
                                        comp.ShadingRate = 6
                                        if comp.SetDrawIdeaOutline then
                                            comp:SetDrawIdeaOutline(true)
                                            if comp.OverrideIdeaOutlineColor then comp:OverrideIdeaOutlineColor(true, color) end
                                            if comp.OverrideIdeaOutlineThickness then comp:OverrideIdeaOutlineThickness(true, thick) end
                                        end
                                    end)
                                else
                                    pcall(function()
                                        if comp.SetDrawIdeaOutline then comp:SetDrawIdeaOutline(false) end
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

_G._recoilCache = _G._recoilCache or setmetatable({}, { __mode = "k" })
_G._RECOIL_FIELDS = { "RecoilKick","RecoilKickADS","AnimationKick","GameDeviationFactor","RecoilModifierStand","RecoilModifierCrouch","RecoilModifierProne","CameraShakeScale","AimCameraShakeScale","ShootCameraShakeScale","FireCameraShakeScale","GameDeviationAccuracy","ShotGunHorizontalSpread","ShotGunVerticalSpread","DeviationMultiplier" }
_G._RECOIL_TARGET = { RecoilKick=0.01,RecoilKickADS=0.01,AnimationKick=0.01,GameDeviationFactor=0.01,RecoilModifierStand=0.01,RecoilModifierCrouch=0.01,RecoilModifierProne=0.01,CameraShakeScale=0.01,AimCameraShakeScale=0.01,ShootCameraShakeScale=0.01,FireCameraShakeScale=0.01,GameDeviationAccuracy=0.01,ShotGunHorizontalSpread=0.01,ShotGunVerticalSpread=0.01,DeviationMultiplier=0.01 }
_G._RECOIL_INFO = { "VerticalRecoilMin","VerticalRecoilMax","RecoilSpeedVertical","RecoilSpeedHorizontal","VerticalRecoveryMax" }
_G._RECOIL_INFO_TARGET = { VerticalRecoilMin=0.01,VerticalRecoilMax=0.01,RecoilSpeedVertical=0.01,RecoilSpeedHorizontal=0.01,VerticalRecoveryMax=0.01 }

_G.ApplyNoRecoil = function()
    pcall(function()
        local GD = _GetGDP()
        if not GD or not GD.GetPlayerController then return end
        local pc = GD.GetPlayerController()
        if not _Valid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not _Valid(char) then return end
        local wm = char.WeaponManagerComponent
        if not _Valid(wm) then return end
        local weapon = wm.CurrentWeaponReplicated
        if not _Valid(weapon) then return end
        local ent = weapon.ShootWeaponEntityComp
        if not _Valid(ent) then return end

        if not _G.LexusConfig.NoRecoilEnabled then
            if _G._recoilCache[ent] then
                local saved = _G._recoilCache[ent]
                for k, v in pairs(saved) do
                    if k == "RecoilInfo" then
                        if ent.RecoilInfo then for rk, rv in pairs(v) do ent.RecoilInfo[rk] = rv end end
                    elseif k == "ShootCameraShakeScale" then
                        if ent.ShootCameraShake then ent.ShootCameraShake.Scale = v end
                    else ent[k] = v end
                end
                _G._recoilCache[ent] = nil
            end
            return
        end

        if not _G._recoilCache[ent] then
            local saved = { RecoilInfo = {} }
            for _, f in ipairs(_G._RECOIL_FIELDS) do if ent[f] ~= nil then saved[f] = ent[f] end end
            if ent.RecoilInfo then
                for _, f in ipairs(_G._RECOIL_INFO) do if ent.RecoilInfo[f] ~= nil then saved.RecoilInfo[f] = ent.RecoilInfo[f] end end
            end
            if ent.ShootCameraShake then saved.ShootCameraShakeScale = ent.ShootCameraShake.Scale end
            _G._recoilCache[ent] = saved
        end

        local orig = _G._recoilCache[ent]
        local s = (_G.LexusConfig.RecoilReduction or 100) / 100
        if s > 1 then s = 1 end

        for _, f in ipairs(_G._RECOIL_FIELDS) do
            if ent[f] ~= nil and orig[f] ~= nil and _G._RECOIL_TARGET[f] then
                ent[f] = orig[f] + (_G._RECOIL_TARGET[f] - orig[f]) * s
            end
        end
        if ent.RecoilInfo then
            for _, f in ipairs(_G._RECOIL_INFO) do
                if ent.RecoilInfo[f] ~= nil and orig.RecoilInfo[f] ~= nil and _G._RECOIL_INFO_TARGET[f] then
                    ent.RecoilInfo[f] = orig.RecoilInfo[f] + (_G._RECOIL_INFO_TARGET[f] - orig.RecoilInfo[f]) * s
                end
            end
        end
        if ent.ShootCameraShake then
            local os0 = orig.ShootCameraShakeScale or 1.0
            ent.ShootCameraShake.Scale = os0 + (0.01 - os0) * s
        end
    end)
end

_G.ApplyAutoHead = function()
    pcall(function()
        local GD = _GetGDP()
        if not GD or not GD.GetPlayerController then return end
        local pc = GD.GetPlayerController()
        if not _Valid(pc) then return end
        local lc = pc:GetPlayerCharacterSafety()
        if not _Valid(lc) then return end
        local ll = nil
        pcall(function() ll = lc:K2_GetActorLocation() end)
        if not ll then return end
        local myTeam = lc.TeamID

        local scoped = false
        pcall(function()
            local cam = lc.ThirdPersonCameraComponent
            if _Valid(cam) and cam.FieldOfView then scoped = cam.FieldOfView < 60 end
        end)
        local maxD = scoped and 500 or 250

        local best, bestD = nil, 999999
        local chars = GD.GetAllPlayerCharacters and GD.GetAllPlayerCharacters() or {}
        for _, en in pairs(chars) do
            if _Valid(en) and en ~= lc and en.TeamID ~= myTeam then
                local dead = false
                pcall(function()
                    if type(en.IsDead) == "function" then dead = en:IsDead()
                    elseif en.bIsDead ~= nil then dead = en.bIsDead end
                end)
                if not dead then
                    local el = nil
                    pcall(function() el = en:K2_GetActorLocation() end)
                    if el then
                        local dx, dy, dz = (el.X or 0)-(ll.X or 0), (el.Y or 0)-(ll.Y or 0), (el.Z or 0)-(ll.Z or 0)
                        local d = math.sqrt(dx*dx + dy*dy + dz*dz)
                        if d < bestD then bestD = d ; best = en end
                    end
                end
            end
        end
        if not best or bestD > maxD then return end

        local tl = nil
        pcall(function()
            local mesh = best.Mesh
            if _Valid(mesh) and type(mesh.GetSocketLocation) == "function" then
                if scoped then tl = mesh:GetSocketLocation("head")
                else
                    tl = mesh:GetSocketLocation("spine_02")
                    if not tl then tl = best:K2_GetActorLocation() end
                    if tl then tl.Z = tl.Z + 100 end
                end
            end
        end)
        if not tl then
            pcall(function() tl = best:K2_GetActorLocation() end)
            if tl then tl.Z = tl.Z + (scoped and 180 or 100) end
        end
        if not tl then return end

        local myCam = lc.ThirdPersonCameraComponent
        if not _Valid(myCam) then return end
        local cl = nil
        pcall(function() cl = myCam:K2_GetComponentLocation() end)
        if not cl then return end

        local dx, dy, dz = (tl.X or 0)-(cl.X or 0), (tl.Y or 0)-(cl.Y or 0), (tl.Z or 0)-(cl.Z or 0)
        local len = math.sqrt(dx*dx + dy*dy + dz*dz)
        if len <= 0 then return end

        local rot = nil
        pcall(function()
            local FRotator = import("Rotator")
            local pitch = math.deg(math.asin(dz / len))
            local yaw = math.deg(math.atan2(dy, dx))
            if scoped then
                rot = FRotator and FRotator(-pitch, yaw, 0) or {Pitch = -pitch, Yaw = yaw, Roll = 0}
            else
                local cur = pc:GetControlRotation()
                if cur then
                    local cp, cy = cur.Pitch or 0, cur.Yaw or 0
                    local b = 0.35
                    local np = cp + (-pitch - cp) * b
                    local ny = cy + (yaw - cy) * b
                    rot = FRotator and FRotator(np, ny, 0) or {Pitch = np, Yaw = ny, Roll = 0}
                else
                    rot = FRotator and FRotator(-pitch, yaw, 0) or {Pitch = -pitch, Yaw = yaw, Roll = 0}
                end
            end
        end)
        if rot then pcall(function() pc:SetControlRotation(rot) end) end
    end)
end

_G.ApplyWeaponAimbot = function()
    pcall(function()
        local GD = _GetGDP()
        if not GD or not GD.GetPlayerController then return end
        local pc = GD.GetPlayerController()
        if not _Valid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not _Valid(char) then return end
        local wm = char.WeaponManagerComponent
        if not _Valid(wm) then return end
        local w = wm.CurrentWeaponReplicated
        if not _Valid(w) then return end
        local ent = w.ShootWeaponEntityComp
        if _Valid(ent) and ent.AutoAimingConfig then
            for _, r in ipairs({"OuterRange", "InnerRange"}) do
                local c = ent.AutoAimingConfig[r]
                if c then
                    c.Speed = 10 ; c.RangeRate = 2 ; c.SpeedRate = 4
                    c.RangeRateSight = 2 ; c.SpeedRateSight = 4
                    c.CrouchRate = 2 ; c.ProneRate = 2 ; c.DyingRate = 2
                end
            end
            ent.AutoAimingConfig = ent.AutoAimingConfig
        end
        local aimComp = char.BP_AutoAimingComponent_C or char.BP_AutoAimingComponent
        if _Valid(aimComp) and aimComp.Bones then
            aimComp.Bones = {"head", "head", "head"}
        end
    end)
end

_G.ApplyAutoAimCompOverride = function()
    pcall(function()
        local GD = _GetGDP()
        if not GD then return end
        local pc = GD.GetPlayerController and GD.GetPlayerController()
        if not _Valid(pc) then return end
        local lp = pc:GetPlayerCharacterSafety()
        if not _Valid(lp) then return end
        local comp = lp.AutoAimComp
        if not _Valid(comp) then return end
        if not _G.LexusState.OrigAutoAimCompCached then
            _G.LexusState.OrigAutoAimCompCached = {
                bOnlyHitHead = comp.bOnlyHitHead,
                HeadBoneName = comp.HeadBoneName,
                Bones        = comp.Bones,
                ChestBoneName= comp.ChestBoneName,
                PelvisBoneName=comp.PelvisBoneName,
            }
        end
        if _G.LexusConfig.AutoHead then
            comp.bOnlyHitHead = true
            comp.HeadBoneName = "Head"
            pcall(function() comp.Bones = {"Head"} end)
            comp.ChestBoneName = "Head"
            comp.PelvisBoneName = "Head"
        else
            local o = _G.LexusState.OrigAutoAimCompCached
            comp.bOnlyHitHead = o.bOnlyHitHead
            comp.HeadBoneName = o.HeadBoneName
            pcall(function() comp.Bones = o.Bones or {"Spine_01", "Pelvis", "Head"} end)
            comp.ChestBoneName = o.ChestBoneName
            comp.PelvisBoneName = o.PelvisBoneName
        end
    end)
end

_G.DriveCombat = function(localPlayer)
    if _G.LexusConfig.IpadView and localPlayer then pcall(_G.ApplyIpadView, localPlayer) end
    if _G.LexusConfig.FakeHWID then pcall(_G.InitFakeHWID) end
    if _G.LexusConfig.WeaponGlow and localPlayer then pcall(_G.ApplyWeaponGlow, localPlayer) end
    if _G.LexusConfig.NoRecoilEnabled then pcall(_G.ApplyNoRecoil) end
    if _G.LexusConfig.AutoHead then
        pcall(_G.ApplyAutoHead)
        pcall(_G.ApplyAutoAimCompOverride)
    end
    if _G.LexusConfig.WeaponAimbot then pcall(_G.ApplyWeaponAimbot) end
end

_G.BuildStackCombat = function(AliasMap, T)
    return {
        { Key = "ModMenu_FakeHWID", UI = AliasMap.Switcher, Text = T("ايدي جهاز وهمي (حماية من الباند)"), GetFunc = function() return _G.LexusConfig.FakeHWID end, SetFunc = function(c,v) _G.LexusConfig.FakeHWID = v return true end },
        { Key = "ModMenu_Ipad_Ex", UI = AliasMap.TitleSwitcher, Text = T("وضع الآيباد (IPAD VIEW)"), ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.IpadView end, SetFunc = function(c,v) _G.LexusConfig.IpadView = v return true end },
        { Key = "ModMenu_Ipad_FOV", UI = AliasMap.Slider, Text = T("   زاوية الرؤية (FOV)"), ExpandHandle = "ModMenu_Ipad_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return (_G.LexusState.CustomTextData.IpadViewFOV or 120) - 90 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.IpadViewFOV = 90 + v return true end },
        { Key = "ModMenu_WeaponGlow_Ex", UI = AliasMap.TitleSwitcher, Text = T("توهج السلاح (HDR)"), ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.WeaponGlow end, SetFunc = function(c,v) _G.LexusConfig.WeaponGlow = v return true end },
        { Key = "ModMenu_WeaponGlowColor", UI = AliasMap.Slider, Text = T("   اللون (1:أحمر 2:أخضر 3:أزرق 4:أصفر 5:متغير)"), ExpandHandle = "ModMenu_WeaponGlow_Ex", MinValue = 1, MaxValue = 5, GetFunc = function() return _G.LexusState.CustomTextData.WeaponGlowColor or 5 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.WeaponGlowColor = v return true end },
        { Key = "ModMenu_WeaponGlowThick", UI = AliasMap.Slider, Text = T("   سماكة التوهج"), ExpandHandle = "ModMenu_WeaponGlow_Ex", MinValue = 1, MaxValue = 15, GetFunc = function() return _G.LexusState.CustomTextData.WeaponGlowThickness or 3 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.WeaponGlowThickness = v return true end },
        { Key = "ModMenu_NoRecoil", UI = AliasMap.TitleSwitcher, Text = T("بدون ارتداد (NO RECOIL)"), ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.NoRecoilEnabled end, SetFunc = function(c,v) _G.LexusConfig.NoRecoilEnabled = v return true end },
        { Key = "ModMenu_RecoilReduction", UI = AliasMap.Slider, Text = T("   تخفيض الارتداد"), ExpandHandle = "ModMenu_NoRecoil", MinValue = 0, MaxValue = 100, GetFunc = function() return _G.LexusConfig.RecoilReduction or 100 end, SetFunc = function(c,v) _G.LexusConfig.RecoilReduction = v return true end },
        { Key = "ModMenu_AutoHead", UI = AliasMap.TitleSwitcher, Text = T("تصويب تلقائي للرأس (AIMBOT)"), ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.AutoHead end, SetFunc = function(c,v) _G.LexusConfig.AutoHead = v return true end },
        { Key = "ModMenu_WeaponAimbot", UI = AliasMap.TitleSwitcher, Text = T("تصويب تلقائي للسلاح"), ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.WeaponAimbot end, SetFunc = function(c,v) _G.LexusConfig.WeaponAimbot = v return true end },
    }
end

-- ====================================================================
-- ESP BLOCK
-- ====================================================================
_G.LexusConfig.Esp9_Count    = _G.LexusConfig.Esp9_Count    or false
_G.LexusConfig.Esp9_Line     = _G.LexusConfig.Esp9_Line     or false
_G.LexusConfig.ColorBodyNew  = _G.LexusConfig.ColorBodyNew  or false

local _espValid = function(o)
    if not o then return false end
    if slua and slua.isValid then
        local ok, v = pcall(slua.isValid, o)
        return ok and v
    end
    return true
end

local function _espGetGDP()
    local ok, m = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if ok then return m end
end

local function _espGetPC()
    local gd = _espGetGDP()
    if not gd then return nil end
    local ok, pc = pcall(function() return gd.GetPlayerController and gd.GetPlayerController() end)
    if ok and _espValid(pc) then return pc end
end

local function _espGetMyChar()
    local gd = _espGetGDP()
    if not gd then return nil end
    local ok, c = pcall(function() return gd.GetLocalCharacter and gd.GetLocalCharacter() end)
    if ok and _espValid(c) then return c end
    local pc = _espGetPC()
    if _espValid(pc) then
        local ok2, p = pcall(function() return pc.GetPawn and pc:GetPawn() end)
        if ok2 and _espValid(p) then return p end
    end
end

local function _espIsBot(c)
    if not _espValid(c) then return false end
    local ok, v = pcall(function()
        if c.bIsAI == true or c.IsAI == true then return true end
        if c.bIsBot == true then return true end
        local ps = c.PlayerState or (c.GetPlayerState and c:GetPlayerState())
        if _espValid(ps) and (ps.bIsABot or ps.bIsBot) then return true end
    end)
    return ok and v or false
end

local function _espIsAlive(c)
    if not _espValid(c) then return false end
    local ok, v = pcall(function()
        if c.IsDead then return not c:IsDead() end
        if c.Health then return c.Health > 0 end
        if c.bIsDead ~= nil then return not c.bIsDead end
    end)
    return ok and v ~= false
end

_G.CountPlayersAndBots = function()
    local myChar = _espGetMyChar()
    local myTeam = myChar and (myChar.GetTeamID and myChar:GetTeamID() or myChar.TeamID)
    local myKey = nil
    pcall(function()
        local pc = _espGetPC()
        if _espValid(pc) then
            if pc.GetPlayerKey then myKey = pc:GetPlayerKey()
            elseif pc.PlayerKey then myKey = pc.PlayerKey end
        end
    end)

    local players, bots = 0, 0
    local gd = _espGetGDP()
    local allChars = {}
    pcall(function()
        if gd and gd.GetAllPlayerCharacters then allChars = gd.GetAllPlayerCharacters() or {}
        elseif gd and gd.GameCharacters then for _, c in pairs(gd.GameCharacters) do table.insert(allChars, c) end end
    end)
    if not next(allChars) then
        pcall(function()
            local pawns = Game:GetAllPlayerPawns()
            if pawns then for _, p in pairs(pawns) do table.insert(allChars, p) end end
        end)
    end

    for _, c in ipairs(allChars) do
        if _espValid(c) and _espIsAlive(c) then
            local isMe = false
            pcall(function()
                local pc = _espGetPC()
                if _espValid(pc) and pc.GetPawn and pc:GetPawn() == c then isMe = true end
                if myChar and c == myChar then isMe = true end
            end)
            local cKey = nil
            pcall(function()
                if c.PlayerKey then cKey = c.PlayerKey
                elseif c.GetPlayerKey then cKey = c:GetPlayerKey() end
            end)
            if myKey and cKey and tostring(myKey) == tostring(cKey) then isMe = true end

            local sameTeam = false
            if myTeam ~= nil then
                local cTeam = nil
                pcall(function()
                    if c.GetTeamID then cTeam = c:GetTeamID()
                    elseif c.TeamID then cTeam = c.TeamID end
                end)
                if cTeam ~= nil and cTeam == myTeam then sameTeam = true end
            end

            if not isMe and not sameTeam then
                if _espIsBot(c) then bots = bots + 1 else players = players + 1 end
            end
        end
    end
    return players, bots
end

_G._ConsoleNewWallReady = _G._ConsoleNewWallReady or false

_G.ApplyWallhackChams = function(enemy, markData)
    if not _espValid(enemy) then return end
    markData = markData or {}
    pcall(function()
        if not _G._ConsoleNewWallReady then
            local KSL = import("KismetSystemLibrary")
            local world = slua.getWorld()
            if KSL and world then
                KSL.ExecuteConsoleCommand(world, "r.EnableDrawDyeingColor 1")
                KSL.ExecuteConsoleCommand(world, "r.CustomDepth 3")
                KSL.ExecuteConsoleCommand(world, "r.IdeaOutline.Enable 1")
                KSL.ExecuteConsoleCommand(world, "r.Highlight.Enable 1")
                _G._ConsoleNewWallReady = true
            end
        end

        local meshes = {}
        if _espValid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
        pcall(function()
            local SMC = import("SkeletalMeshComponent")
            if SMC and enemy.GetComponentsByClass then
                local list = enemy:GetComponentsByClass(SMC)
                if list then
                    local n = type(list.Num) == "function" and list:Num() or #list
                    for i = 1, n do
                        local comp = type(list.Get) == "function" and list:Get(i - 1) or list[i]
                        if _espValid(comp) and comp ~= enemy.Mesh then table.insert(meshes, comp) end
                    end
                end
            end
        end)
        local wpn = nil
        pcall(function() wpn = enemy:GetCurrentWeapon() end)
        if _espValid(wpn) and _espValid(wpn.Mesh) then table.insert(meshes, wpn.Mesh) end

        local LC = import("LinearColor") or _G.FLinearColor
        local isBot = _espIsBot(enemy)
        local visColor = isBot and (LC and LC(49, 48, 0, 100) or {R=49,G=48,B=0,A=100})
                          or  (LC and LC(0, 100, 0, 1)   or {R=0,G=100,B=0,A=1})
        local occColor = isBot and (LC and LC(9, 1.5, 45, 100) or {R=9,G=1.5,B=45,A=100})
                          or  (LC and LC(100, 0, 0, 1)   or {R=100,G=0,B=0,A=1})

        for _, mesh in ipairs(meshes) do
            if _espValid(mesh) then
                pcall(function()
                    if type(mesh.SetDrawDyeing) == "function" then
                        mesh:SetDrawDyeing(true)
                        mesh:SetDrawDyeingMode(1)
                        mesh:SetVisibleDyeingColor(visColor)
                        mesh:SetOccludedDyeingColor(occColor)
                        mesh:SetDyeingColorFadeDistance(99999.0)
                        mesh:SetDyeingColorMinMaxDistance(0.0, 99999.0)
                        mesh:SetDrawHighlight(true)
                        mesh:OverrideHighlightColor(visColor)
                        mesh:SetHighlightCanBeOccluded(false)
                        mesh:SetDrawIdeaOutline(true)
                        mesh:SetIdeaOutlineNew(true)
                        mesh:SetIdeaOutlineOcclusionHighlight(true)
                        mesh:OverrideIdeaOutlineColor(visColor)
                        mesh:SetIdeaOutlineOcclusionColor(occColor)
                        mesh:OverrideIdeaOutlineThickness(20.0)
                        mesh:SetIdeaOverrideOutlineAndOcclusion(true)
                        mesh:SetRenderCustomDepth(true)
                        mesh:SetCustomDepthStencilValue(255)
                    end
                end)
            end
        end
        markData.ColorNewApplied = true
    end)
end

_G.RemoveWallhackChams = function(enemy, markData)
    if not _espValid(enemy) then return end
    markData = markData or {}
    pcall(function()
        local meshes = {}
        if _espValid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
        pcall(function()
            local SMC = import("SkeletalMeshComponent")
            if SMC and enemy.GetComponentsByClass then
                local list = enemy:GetComponentsByClass(SMC)
                if list then
                    local n = type(list.Num) == "function" and list:Num() or #list
                    for i = 1, n do
                        local comp = type(list.Get) == "function" and list:Get(i - 1) or list[i]
                        if _espValid(comp) and comp ~= enemy.Mesh then table.insert(meshes, comp) end
                    end
                end
            end
        end)
        for _, mesh in ipairs(meshes) do
            if _espValid(mesh) then
                pcall(function()
                    if type(mesh.SetDrawDyeing) == "function" then
                        mesh:SetDrawDyeing(false)
                        mesh:SetDrawHighlight(false)
                        mesh:SetDrawIdeaOutline(false)
                        mesh:SetRenderCustomDepth(false)
                    end
                end)
            end
        end
        markData.ColorNewApplied = false
    end)
end

_G.DriveESPWallhack = function()
    local gd = _espGetGDP()
    if not gd or not gd.GetAllPlayerCharacters then return end
    local pc = _espGetPC()
    if not _espValid(pc) then return end
    local myChar = pc:GetPlayerCharacterSafety()
    if not _espValid(myChar) then return end
    local myTeam = myChar.TeamID

    _G.LexusState = _G.LexusState or {}
    _G.LexusState.EnemyMarks = _G.LexusState.EnemyMarks or {}
    _G.LexusConfig = _G.LexusConfig or {}

    for _, enemy in pairs(gd.GetAllPlayerCharacters()) do
        if _espValid(enemy) and enemy ~= myChar and enemy.TeamID ~= myTeam then
            local eKey = tostring(enemy.PlayerKey or enemy:GetUniqueID() or enemy)
            local mark = _G.LexusState.EnemyMarks[eKey] or {}
            _G.LexusState.EnemyMarks[eKey] = mark
            if _G.LexusConfig.ColorBodyNew then
                _G.ApplyWallhackChams(enemy, mark)
            else
                if mark.ColorNewApplied then _G.RemoveWallhackChams(enemy, mark) end
            end
        end
    end
end

-- ====================================================================
-- SKIN SYSTEM
-- ====================================================================
_G.WeaponSkinMap    = _G.WeaponSkinMap    or {}
_G.VehicleSkinMap   = _G.VehicleSkinMap   or {}
_G.OutfitMap        = _G.OutfitMap        or {}
_G.skinIdCache      = _G.skinIdCache      or {}
_G.skinIdCache2     = _G.skinIdCache2     or {}
_G.skinAttachCache  = _G.skinAttachCache  or {}
_G.g_parts          = _G.g_parts          or {}
_G.CustSlotType     = { ClothesEquipemtSlot=5, BackpackEquipemtSlot=8, HelmetEquipemtSlot=9, ParachuteEquipemtSlot=11, GlideEquipemtSlot=15 }

_G.VIP_Attachments = _G.VIP_Attachments or {
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

_G.BaseAttachToIndex = _G.BaseAttachToIndex or {
    [201010]=1, [201005]=1, [201004]=1, [201009]=2, [201003]=2, [201002]=2,
    [201011]=3, [201007]=3, [201006]=3, [204012]=4, [204005]=4, [204008]=4,
    [204011]=5, [204004]=5, [204007]=5, [204013]=6, [204006]=6, [204009]=6,
    [203001]=7, [203002]=8, [203003]=9, [203014]=10, [203004]=11, [203015]=12, [203005]=13,
    [202002]=14, [202001]=15, [202004]=16, [202005]=17, [202007]=18, [202006]=19,
    [205002]=20, [205003]=20, [205001]=20, [203018]=21, [204014]=22
}

_G.VipAttachToIndex = _G.VipAttachToIndex or {}
if not next(_G.VipAttachToIndex) then
    for skinId, attachList in pairs(_G.VIP_Attachments) do
        for index, attachId in ipairs(attachList) do
            if attachId > 0 then
                _G.VipAttachToIndex[attachId] = index
            end
        end
    end
end

_G.OutfitSkins = _G.OutfitSkins or {
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

_G.skinIdMappings = _G.skinIdMappings or {
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

_G.VehicleSkins = _G.VehicleSkins or {
    [1961001] = { 1961151,1961152,1961153,1961147,1961148,1961149,1961144,1961145,1961137,1961138,1961139,1961066,1961067,1961065,1961062,1961063,1961064,1961054,1961055,1961056,1961057,1961051,1961052,1961053,1961048,1961049,1961050,1961044,1961045,1961046,1961047,1961041,1961042,1961043,1961038,1961039,1961040,1961033,1961034,1961035,1961029,1961030,1961031,1961032,1961007,1961010,1961012,1961013,1961014,1961015,1961140,1961141,1961142,1961143,1991023,1991024 },
    [1903001] = { 1903228,1903220,1903221,1903223,1903218,1903219,1903213,1903212,1903202,1908094,1908095,1903193,1903192,1903191,19030790,19030791,19030800,19030801,1903074,1903075,1903076,1903071,1903072,1903073,1903216,1903217,1991001,1991002,1991003,1991004,1903088,1903089,1903090,1903023 },
    [1915004] = { 1915021, 1915022, 1915008, 1915009, 1914011 },
    [1908001] = { 1908108,1908109,19080951,19081080,1908084,1908085,1908075,1908077,1908078,1908070,1908069,1908066,1908086,1908088,1908089,1908018 },
    [1907002] = { 1907058, 1907054, 1907059, 1907053, 1907063, 1907072, 1907040, 1907041, 1907027, 1907047, 1907021}
}

_G.muzzles = _G.muzzles or {
    id_flash_hider = { 201010, 201005, 201004 },
    id_compensator = { 201009, 201003, 201002 },
    id_suppressor  = { 201011, 201006, 201007 }
}
_G.foregrips = _G.foregrips or {
    id_Angledforegrip = 202001,
    id_thumb_grip     = 202006,
    id_vertical_grip  = 202002,
    id_light_grip     = 202004,
    id_half_grip      = 202005,
    id_ergonomic_grip = 202051,
    id_laser_sight    = 202007
}
_G.magazines = _G.magazines or {
    id_expanded_mag       = { 204011, 204007, 204004 },
    id_quick_mag          = { 204012, 204008, 204005 },
    id_expanded_quick_mag = { 204013, 204009, 204006 }
}
_G.scopes = _G.scopes or {
    id_reddot = 203001,
    id_holo   = 203002,
    id_2x     = 203003,
    id_3x     = 203014,
    id_4x     = 203004,
    id_6x     = 203015,
    id_8x     = 203005
}
_G.stock = _G.stock or {
    id_microStock = 205001,
    id_tactical   = 205002,
    id_bulletloop = 204014,
    id_CheekPad   = 205003
}

local ATTACH_NAME_MAP = {
    ["Red Dot Sight"] = "RedDot", ["Holographic Sight"] = "Holo",
    ["2x Scope"] = "Scope2x", ["3x Scope"] = "Scope3x", ["4x Scope"] = "Scope4x",
    ["6x Scope"] = "Scope6x", ["8x Scope"] = "Scope8x", ["Canted Sight"] = "CantedSight",
    ["Flash Hider"] = "FlashHider", ["Compensator"] = "Compensator", ["Suppressor"] = "Suppressor",
    ["Extended Mag"] = "ExtMag", ["Quickdraw Mag"] = "QuickMag", ["Extended Quickdraw Mag"] = "ExtQuickMag",
    ["Angled Foregrip"] = "AngledGrip", ["Vertical Foregrip"] = "VerticalGrip", ["Thumb Grip"] = "ThumbGrip",
    ["Half Grip"] = "HalfGrip", ["Light Grip"] = "LightGrip", ["Laser Sight"] = "LaserSight",
    ["Tactical Stock"] = "TactStock", ["Stock"] = "MicroStock", ["Cheek Pad"] = "CheekPad",
}

local _SKIN_ATTACH_PATH = "/storage/emulated/0/Android/data/com.pubg.imobile/files/attachments.txt"
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
                    curSkin = num; result[curSkin] = result[curSkin] or {}
                elseif num and curSkin then
                    local attachName = line:match("^%d+%s*|%s*%x+%s*|%s*(.-)%s*$")
                    if not attachName then attachName = line:match("^%d+%s*|%s*(.-)%s*$") end
                    if attachName and attachName ~= "" then
                        local key = ATTACH_NAME_MAP[attachName]
                        if key then result[curSkin][key] = num end
                    end
                end
            elseif line:find("^#%-%-%-%-") and line:find("skin") then curSkin = nil end
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

_G.download_item = function(id)
    if not id then return end
    pcall(function()
        local PM = require("client.slua.logic.download.puffer.puffer_manager")
        local PC = require("client.slua.logic.download.puffer_const")
        if PM.GetState(PC.ENUM_DownloadType.ODPTD, {id}) ~= PC.ENUM_DownloadState.Done then
            PM.Download(PC.ENUM_DownloadType.ODPTD, {id})
        end
    end)
end

_G.ItemUpgradeSystem = nil
pcall(function()
    local MM  = require("client.module_framework.ModuleManager")
    local IUS = MM.GetModule(MM.CommonModuleConfig.ItemUpgradeManager)
    if IUS then
        IUS:DefineAndResetData(); IUS:OnInitialize()
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
    local function is_in(t) for _, id in ipairs(_G.muzzles[t]) do if current_id == id then return true end end return false end
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
    local function is_in(t) for _, id in ipairs(_G.magazines[t]) do if current_id == id then return true end end return false end
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
                    if not _G.skinIdCache[SkinID] then _G.download_item(SkinID); _G.skinIdCache[SkinID] = true end
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
        if slotData and slotData.SlotID == _G.CustSlotType.GlideEquipemtSlot then hasGliderSlot = true; break end
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

_G.ApplyVehicleSkins = function(PlayerCharacter)
    pcall(function()
        local Vehicle = PlayerCharacter:GetCurrentVehicle()
        if not slua.isValid(Vehicle) then _G.LastVehicleEntity = nil; return end
        if _G.LastVehicleEntity == Vehicle and _G.CurrentEquipVehicleID ~= nil then return end
        local VehicleAvatar = Vehicle.VehicleAvatar or Vehicle.VehicleAvatarComponent_BP or Vehicle:GetAvatarComponent()
        if not slua.isValid(VehicleAvatar) then return end
        local defId = tostring(VehicleAvatar:GetDefaultAvatarID() or Vehicle.VehicleID or "")
        local currentId = tostring(Vehicle:GetAvatarId() or "")
        local applySkinId = 0
        for baseMapId, targetSkin in pairs(_G.VehicleSkinMap) do
            if defId:find(tostring(baseMapId)) or currentId:find(tostring(baseMapId)) then applySkinId = targetSkin; break end
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

local function _nop() return true end
local function _retFalse() return false end
local function _retTrue() return true end

_G.InitializeSkinBypass = function()
    pcall(function()
        local ptlog = package.loaded["client.slua.logic.download.report.puffer_tlog"]
        if ptlog then ptlog.ReportEvent = _nop; ptlog.ReportDownloadResult = _nop; ptlog.ReportODPTDError = _nop; ptlog.ReportSkinError = _nop end
        local AvatarUtils = package.loaded["AvatarUtils"]
        if AvatarUtils then AvatarUtils.CheckIsWeaponInBlackList = _retFalse; AvatarUtils.IsValidAvatar = _retTrue; AvatarUtils.CheckAvatarIntegrity = _retTrue; AvatarUtils.ReportInvalidAvatar = _nop end
        local sub = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("FileCheckSubsystem")
        if sub then sub.StartCheck = _nop; sub.ReportAbnormalFile = _nop; sub.StopCheck = _nop end
        local eqEx = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
        if eqEx then eqEx.Report = _nop; eqEx.SendException = _nop end
    end)
end

_G.InitializeSkinModSystem = function()
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

_G.ForceRefreshSkinMaps = function()
    pcall(function()
        if not _G.LexusState or not _G.LexusState.CustomTextData then return end
        local cData = _G.LexusState.CustomTextData
        if _G.OutfitSkins then
            if cData.SkinSuit and _G.OutfitSkins.Suit[cData.SkinSuit] then _G.OutfitMap.Suit = _G.OutfitSkins.Suit[cData.SkinSuit] end
            if cData.SkinBag and _G.OutfitSkins.Bag[cData.SkinBag] then _G.OutfitMap.Bag = _G.OutfitSkins.Bag[cData.SkinBag] end
            if cData.SkinHelmet and _G.OutfitSkins.Helmet[cData.SkinHelmet] then _G.OutfitMap.Helmet = _G.OutfitSkins.Helmet[cData.SkinHelmet] end
        end
        if _G.skinIdMappings then
            local map = {
                SkinM416=101004, SkinAKM=101001, SkinSCAR=101003, SkinM762=101008,
                SkinAUG=101006, SkinUMP=102002, SkinUZI=102001, SkinGroza=101005,
                SkinS12K=104003, SkinDBS=104004, SkinASM=101101, SkinQBZ=101007,
                SkinHoney=101012, SkinM16A4=101002, SkinACE32=101102,
                SkinKar98k=103001, SkinM24=103002, SkinAWM=103003
            }
            for k, wpn in pairs(map) do
                local idx = cData[k]
                if idx and _G.skinIdMappings[wpn] and _G.skinIdMappings[wpn][idx] then
                    _G.WeaponSkinMap[wpn] = _G.skinIdMappings[wpn][idx]
                end
            end
        end
        if _G.VehicleSkins then
            local vmap = { SkinDacia=1903001, SkinUAZ=1908001, SkinCoupe=1961001, SkinBuggy=1907002, SkinMirado=1915004 }
            for k, veh in pairs(vmap) do
                local idx = cData[k]
                if idx and _G.VehicleSkins[veh] and _G.VehicleSkins[veh][idx] then
                    _G.VehicleSkinMap[veh] = _G.VehicleSkins[veh][idx]
                end
            end
        end
    end)
end

-- ====================================================================
-- RAAD ESP LINES
-- ====================================================================
_G.RAAD_LINES = {}
local RL = _G.RAAD_LINES

local FVector2D_RL    = _G.FVector2D or import("Vector2D")
local FLinearColor_RL = _G.FLinearColor or import("LinearColor")
local SlateBP_RL      = nil
local WidgetLayout_RL = nil
pcall(function() SlateBP_RL = import("SlateBlueprintLibrary") end)
pcall(function() WidgetLayout_RL = import("WidgetLayoutLibrary") end)

local function RL_Valid(obj)
  if obj == nil then return false end
  if not slua or not slua.isValid then return false end
  local ok, v = pcall(slua.isValid, obj)
  return ok and v == true
end

local function RL_V2(x, y)
  if FVector2D_RL then return FVector2D_RL(x, y) end
  return { X = x, Y = y }
end

local function RL_KC(r, g, b, a)
  if FLinearColor_RL then return FLinearColor_RL(r, g, b, a) end
  return { R = r, G = g, B = b, A = a }
end

local function RL_RND(v)
  if v ~= v then return 0 end
  return math.floor(v + 0.5)
end

RL.CFG = {
  MaxMeters      = 100,
  Thickness      = 1.8,
  OriginY        = 0,
  ScreenMargin   = 220,
  VisInterval    = 0.15,
  VisBudget      = 3,
  DeadZone       = 0.5,
  MaxTracked     = 12,
}

RL.COLOR_VISIBLE   = RL_KC(0.5776, 0.0, 0.0, 1.0)
RL.COLOR_INVISIBLE = RL_KC(0.12,   1.0, 0.25, 1.0)

RL.Canvas      = nil
RL.Lines       = {}
RL.VisCache    = {}
RL.Known       = {}
RL.ScaleX      = 1.0
RL.ScaleY      = 1.0
RL.OffsetX     = 0.0
RL.OffsetY     = 0.0
RL.LastTransform = -999
RL.bActive     = false

local function RL_GetCanvas()
  if RL_Valid(RL.Canvas) then return RL.Canvas end
  local root = nil
  pcall(function()
    local T = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
    if T and T.GetMainControlBaseUI then root = T.GetMainControlBaseUI() end
  end)
  if not RL_Valid(root) then return nil end
  local cv = nil
  pcall(function()
    if RL_Valid(root.CanvasPanel_0) then cv = root.CanvasPanel_0
    elseif RL_Valid(root.CanvasPanel_42) then cv = root.CanvasPanel_42 end
  end)
  if RL_Valid(cv) then RL.Canvas = cv return cv end
  return nil
end

local function RL_UpdateTransform(pc)
  local cv = RL_GetCanvas()
  if not RL_Valid(cv) then return false end
  local ok = false
  pcall(function()
    if SlateBP_RL and SlateBP_RL.AbsoluteToLocal then
      local geo = cv:GetCachedGeometry()
      if geo then
        local p0 = SlateBP_RL.AbsoluteToLocal(geo, RL_V2(0, 0))
        local p1 = SlateBP_RL.AbsoluteToLocal(geo, RL_V2(100, 100))
        if p0 and p1 and p1.X ~= p0.X and p1.Y ~= p0.Y then
          RL.ScaleX = (p1.X - p0.X) / 100.0
          RL.ScaleY = (p1.Y - p0.Y) / 100.0
          RL.OffsetX = p0.X
          RL.OffsetY = p0.Y
          ok = true
        end
      end
    end
  end)
  if not ok then
    local s = 1.0
    pcall(function()
      if WidgetLayout_RL and WidgetLayout_RL.GetViewportScale then
        local v = WidgetLayout_RL.GetViewportScale(pc)
        if tonumber(v) and v > 0 then s = v end
      end
    end)
    RL.ScaleX = 1.0 / s
    RL.ScaleY = 1.0 / s
    RL.OffsetX, RL.OffsetY = 0, 0
  end
  return true
end

local _pix_RL = nil
local _loc_RL = { X = 0, Y = 0, Z = 0 }

local function RL_Project(pc, x, y, z)
  if not pc then return nil end
  if not _pix_RL then _pix_RL = RL_V2(0, 0) end
  _loc_RL.X, _loc_RL.Y, _loc_RL.Z = x, y, z
  local ok, res = pcall(function()
    return pc:ProjectWorldLocationToScreen(_loc_RL, _pix_RL, true)
  end)
  if not ok then return nil end
  local px, py = _pix_RL.X, _pix_RL.Y
  local good = (res == true or res == 1) or (px ~= 0 or py ~= 0)
  if not good then return nil end
  return px * (RL.ScaleX or 1.0) + (RL.OffsetX or 0.0),
         py * (RL.ScaleY or 1.0) + (RL.OffsetY or 0.0),
         px, py
end

local function RL_ScreenCenterX(pc, viewW)
  local cx = nil
  pcall(function()
    local mgr = import("GameplayStatics").GetPlayerCameraManager(pc, 0)
    if mgr and mgr.GetCameraLocation and mgr.GetCameraRotation then
      local loc, rot = mgr:GetCameraLocation(), mgr:GetCameraRotation()
      if loc and rot then
        local yaw, pitch = math.rad(rot.Yaw), math.rad(rot.Pitch)
        local cp = math.cos(pitch)
        local D = 10000
        local sx = RL_Project(pc,
          loc.X + cp * math.cos(yaw) * D,
          loc.Y + cp * math.sin(yaw) * D,
          loc.Z + math.sin(pitch) * D)
        if sx and tonumber(sx) then cx = sx end
      end
    end
  end)
  if not cx then
    cx = (viewW * 0.5) * (RL.ScaleX or 1.0) + (RL.OffsetX or 0.0)
  end
  return RL_RND(cx)
end

local function RL_NewLine(color, z)
  local cv = RL_GetCanvas()
  if not RL_Valid(cv) then return nil end
  local border = nil
  pcall(function() border = CGame:NewObjectFromPath("/Script/UMG.Border", cv) end)
  if not RL_Valid(border) then return nil end
  pcall(function()
    border:SetBrushColor(color)
    border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    border:SetRenderTransformPivot(RL_V2(0.0, 0.5))
  end)
  local slot = nil
  pcall(function() slot = cv:AddChildToCanvas(border) end)
  if not slot then
    pcall(function() border:RemoveFromParent() end)
    return nil
  end
  pcall(function() slot:SetAutoSize(false) slot:SetZOrder(z or 30) end)
  return { Widget = border, Slot = slot }
end

local function RL_EnsureLine(key)
  local d = RL.Lines[key]
  if d and RL_Valid(d.Widget) then return d end
  d = RL_NewLine(RL.COLOR_VISIBLE, 30)
  if d then d.colorKey = "vis" end
  RL.Lines[key] = d
  RL.Known[key] = true
  return d
end

local function RL_DrawLine(d, x1, y1, x2, y2, thickness)
  if not d or not d.Slot or not RL_Valid(d.Widget) then return false end
  if x1 ~= x1 or y1 ~= y1 or x2 ~= x2 or y2 ~= y2 then return false end
  x1, y1, x2, y2 = RL_RND(x1), RL_RND(y1), RL_RND(x2), RL_RND(y2)
  local dz = RL.CFG.DeadZone
  if d.lx1 and d.th == thickness then
    if math.abs(d.lx1 - x1) < dz and math.abs(d.ly1 - y1) < dz
    and math.abs(d.lx2 - x2) < dz and math.abs(d.ly2 - y2) < dz then
      return true
    end
  end
  local dx, dy = x2 - x1, y2 - y1
  local len = math.sqrt(dx * dx + dy * dy)
  if len < 1 then
    pcall(function() d.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
    d.hidden = true
    return false
  end
  local angle = (math.atan2 and math.atan2(dy, dx) or math.atan(dy, dx)) * 180 / math.pi
  angle = math.floor(angle * 10 + 0.5) / 10
  local ok = pcall(function()
    if d.hidden then
      d.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
      d.hidden = false
    end
    d.Slot:SetPosition(RL_V2(x1, y1 - thickness * 0.5))
    d.Slot:SetSize(RL_V2(len, thickness))
    d.Widget:SetRenderAngle(angle)
  end)
  if ok then
    d.lx1, d.ly1, d.lx2, d.ly2, d.th = x1, y1, x2, y2, thickness
  end
  return true
end

local function RL_SetColor(d, color, key)
  if not d or d.colorKey == key then return end
  if not RL_Valid(d.Widget) then return end
  pcall(function() d.Widget:SetBrushColor(color) end)
  d.colorKey = key
end

local function RL_HideLine(d)
  if d and not d.hidden and RL_Valid(d.Widget) then
    pcall(function() d.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
    d.hidden = true
    d.lx1, d.ly1, d.lx2, d.ly2 = nil, nil, nil, nil
  end
end

local KLib_RL   = nil
local HitRes_RL = nil
local StartPos_RL = { X = 0, Y = 0, Z = 0 }
local EndPos_RL   = { X = 0, Y = 0, Z = 0 }
pcall(function()
  KLib_RL = import("KismetSystemLibrary")
  local HR = import("HitResult")
  if HR then HitRes_RL = HR() else HitRes_RL = {} end
end)

local BONES_RL = { "head", "spine_03", "pelvis" }

local function RL_GetBoneXYZ(c, bone)
  local x, y, z
  if type(c.GetBonePos) == "function" then
    local p = c:GetBonePos(bone, { X = 0, Y = 0, Z = 0 })
    if p then x, y, z = p.X, p.Y, p.Z end
  end
  if (x == nil or (x == 0 and y == 0 and z == 0)) and type(c.GetSocketLocation) == "function" then
    local p = c:GetSocketLocation(bone)
    if p then x, y, z = p.X, p.Y, p.Z end
  end
  return x, y, z
end

local _visLeft_RL = 0

local function RL_IsVisible(key, pc, c, now)
  local cached = RL.VisCache[key]
  if cached then
    local age = now - cached.t
    if age >= 0 and age < RL.CFG.VisInterval then return cached.b end
    if _visLeft_RL <= 0 and age < 0.6 then return cached.b end
  end
  _visLeft_RL = _visLeft_RL - 1
  local bVis = false
  local cx, cy, cz = nil, nil, nil
  pcall(function()
    local GPs = import("GameplayStatics")
    local mgr = GPs.GetPlayerCameraManager(pc, 0)
    if mgr and mgr.GetCameraLocation then
      local l = mgr:GetCameraLocation()
      cx, cy, cz = l.X, l.Y, l.Z
    end
  end)
  if cx and KLib_RL and KLib_RL.LineTraceSingle and RL_Valid(c) then
    for i = 1, #BONES_RL do
      local bx, by, bz = RL_GetBoneXYZ(c, BONES_RL[i])
      if bx and (bx ~= 0 or by ~= 0 or bz ~= 0) then
        local dx, dy, dz = bx - cx, by - cy, bz - cz
        local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
        if dist >= 50 then
          StartPos_RL.X = cx + (dx / dist) * 60
          StartPos_RL.Y = cy + (dy / dist) * 60
          StartPos_RL.Z = cz + (dz / dist) * 60
          EndPos_RL.X, EndPos_RL.Y, EndPos_RL.Z = bx, by, bz
          local ok, hit = pcall(function()
            return KLib_RL.LineTraceSingle(pc, StartPos_RL, EndPos_RL, 0, false, nil, 0, HitRes_RL, true)
          end)
          if ok then
            if not hit then bVis = true break end
            local ha = HitRes_RL and (type(HitRes_RL.GetActor) == "function" and HitRes_RL:GetActor() or HitRes_RL.Actor)
            if ha == c then bVis = true break end
          end
        end
      end
    end
  else
    bVis = true
  end
  if cached then cached.b, cached.t = bVis, now
  else RL.VisCache[key] = { b = bVis, t = now } end
  return bVis
end

function RL.Update()
  if not RL.bActive then return end
  local now = os.clock()

  local pc = nil
  pcall(function()
    local GDP = require("GameLua.GameCore.Data.GameplayData")
    if GDP and GDP.GetPlayerController then pc = GDP.GetPlayerController() end
  end)
  if not RL_Valid(pc) then return end
  local cv = RL_GetCanvas()
  if not RL_Valid(cv) then return end

  if now - RL.LastTransform >= 0.6 then
    RL_UpdateTransform(pc)
    RL.LastTransform = now
  end

  local vw, vh = 1920, 1080
  pcall(function()
    local v = RL_V2(0, 0)
    pc:GetViewportSize(v)
    if v and tonumber(v.X) and v.X > 200 then vw, vh = v.X, v.Y end
  end)

  local ox = RL_ScreenCenterX(pc, vw)
  local oy = RL.CFG.OriginY

  local player = nil
  pcall(function()
    local GDP = require("GameLua.GameCore.Data.GameplayData")
    if GDP and GDP.GetPlayerCharacter then player = GDP.GetPlayerCharacter() end
  end)
  if not RL_Valid(player) then return end

  local myTeam = nil
  pcall(function()
    if type(player.GetTeamID) == "function" then myTeam = player:GetTeamID()
    else myTeam = player.TeamID end
  end)

  local pawns = nil
  pcall(function() pawns = Game:GetAllPlayerPawns() end)
  if not pawns then return end

  _visLeft_RL = RL.CFG.VisBudget
  local activeKeys = {}

  for _, c in pairs(pawns) do
    if RL_Valid(c) and c ~= player then
      pcall(function()
        local team = nil
        if type(c.GetTeamID) == "function" then team = c:GetTeamID() else team = c.TeamID end
        if team ~= myTeam and (team == nil or myTeam == nil or tostring(team) ~= tostring(myTeam)) then
          local alive = true
          pcall(function()
            if type(c.IsAlive) == "function" then alive = c:IsAlive()
            else alive = (c.Health or 1) > 0 end
          end)

          if alive then
            local key = nil
            pcall(function()
              if type(c.GetPlayerKey) == "function" then key = tostring(c:GetPlayerKey())
              elseif c.PlayerKey then key = tostring(c.PlayerKey) end
            end)
            if not key then key = tostring(c) end
            activeKeys[key] = true

            local dist = 999999
            pcall(function()
              local a = c:K2_GetActorLocation()
              local b = player:K2_GetActorLocation()
              local dx, dy, dz = a.X - b.X, a.Y - b.Y, a.Z - b.Z
              dist = math.sqrt(dx * dx + dy * dy + dz * dz)
            end)

            if dist / 100 <= RL.CFG.MaxMeters then
              local hx, hy, hz = nil, nil, nil
              pcall(function()
                local cap = c.CapsuleComponent or c:GetCapsuleComponent()
                if RL_Valid(cap) then
                  local l = cap:GetComponentLocation()
                  local h = cap:GetScaledCapsuleHalfHeight()
                  hx, hy, hz = l.X, l.Y, l.Z + h
                end
              end)

              if hx then
                local sx, sy = RL_Project(pc, hx, hy, hz)
                if sx then
                  local okScreen = (sx > -RL.CFG.ScreenMargin and sx < vw + RL.CFG.ScreenMargin
                                and sy > -RL.CFG.ScreenMargin and sy < vh + RL.CFG.ScreenMargin)
                  if okScreen then
                    local line = RL_EnsureLine(key)
                    if line then
                      local bVis = RL_IsVisible(key, pc, c, now)
                      if bVis then RL_SetColor(line, RL.COLOR_VISIBLE, "vis")
                      else RL_SetColor(line, RL.COLOR_INVISIBLE, "inv") end
                      RL_DrawLine(line, ox, oy, sx, sy, RL.CFG.Thickness)
                    end
                  else
                    RL_HideLine(RL.Lines[key])
                  end
                end
              end
            else
              RL_HideLine(RL.Lines[key])
            end
          else
            RL_HideLine(RL.Lines[key])
          end
        end
      end)
    end
  end

  for k, d in pairs(RL.Lines) do
    if not activeKeys[k] then RL_HideLine(d) end
  end
end

function RL.Start()
  if RL.bActive then return end
  RL.bActive = true
  local tk = nil
  pcall(function() tk = require("common.time_ticker") end)
  if tk and tk.AddTimerOnce then
    local function tick()
      if not RL.bActive then return end
      if _G.LexusConfig and _G.LexusConfig.Esp9_Line then
        pcall(RL.Update)
      end
      tk.AddTimerOnce(0.033, tick)
    end
    tk.AddTimerOnce(0.1, tick)
  end
end

function RL.Stop()
  RL.bActive = false
  for k, d in pairs(RL.Lines) do
    if d and RL_Valid(d.Widget) then
      pcall(function()
        d.Widget:RemoveFromParent()
        d.Widget:ConditionalBeginDestroy()
      end)
    end
  end
  RL.Lines = {}
  RL.VisCache = {}
  RL.Known = {}
end

function RL.SetThickness(t)  RL.CFG.Thickness = tonumber(t) or 1.8 end
function RL.SetMaxMeters(m)  RL.CFG.MaxMeters = tonumber(m) or 100 end
function RL.SetVisibleColor(r, g, b)   RL.COLOR_VISIBLE = RL_KC(r, g, b, 1) end
function RL.SetInvisibleColor(r, g, b) RL.COLOR_INVISIBLE = RL_KC(r, g, b, 1) end

_G.PMM_LINES = RL

-- ====================================================================
-- MOD MENU
-- ====================================================================
local FakeTextMap = {
  [999000] = "منيو مهدي مود",
  [999001] = "كشف - ESP",
  [999003] = "مميزات - SDK",
  [999004] = "سكنات مود",
}

local function EnsureLexusGlobals()
  _G.LexusState = _G.LexusState or {}
  _G.LexusState.CustomTextData = _G.LexusState.CustomTextData or {
    IpadViewFOV = 120, WeaponGlowThickness = 3, WeaponGlowColor = 5
  }
  _G.LexusConfig = _G.LexusConfig or {}
end

local function HookLocUtilText()
  local LocUtil = LocUtilModule or _G.LocUtil
  if not LocUtil then return end
  _G.LocUtil = LocUtil
  if LocUtil._IsModMenuHooked_V2 then return end
  local hookFuncs = { "GetLocalizeResStr", "GetText", "GetTextByID", "GetLocalText", "GetLocalizeStr" }
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

local function BuildESPStack(AliasMap)
  return {
    { Key = "ModMenu_ESP9_Count", UI = AliasMap.Switcher, Text = "عداد اللاعبين والبوتات", GetFunc = function() return _G.LexusConfig.Esp9_Count end, SetFunc = function(c,v)
        _G.LexusConfig.Esp9_Count = v
        if v and _G.CountPlayersAndBots then
          local p, b = _G.CountPlayersAndBots()
          _G.LexusState.LastCount = { players = p, bots = b }
        else
          _G.LexusState.LastCount = nil
        end
        return true
      end },
    { Key = "ModMenu_ColorBodyNew", UI = AliasMap.Switcher, Text = "كاشف الوول هاك (تلوين الأجسام)", GetFunc = function() return _G.LexusConfig.ColorBodyNew end, SetFunc = function(c,v)
        _G.LexusConfig.ColorBodyNew = v
        if not v and _G.LexusState.EnemyMarks then
          for _, mark in pairs(_G.LexusState.EnemyMarks) do
            if mark.ColorNewApplied then mark.ColorNewApplied = false end
          end
        end
        return true
      end },
    { Key = "ModMenu_ESP9_Line", UI = AliasMap.Switcher, Text = "خطوط ESP (خط من الشاشة للعدو)", GetFunc = function() return _G.LexusConfig.Esp9_Line end, SetFunc = function(c,v)
        _G.LexusConfig.Esp9_Line = v
        if v then
          if _G.PMM_LINES and _G.PMM_LINES.Start then _G.PMM_LINES.Start() end
        else
          if _G.PMM_LINES and _G.PMM_LINES.Stop then _G.PMM_LINES.Stop() end
        end
        return true
      end },
  }
end

local function BuildSkinStack(AliasMap)
  return {
    { Key = "ModMenu_ModSkin", UI = AliasMap.TitleSwitcher, Text = "تفعيل السكنات", ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.ModSkin end, SetFunc = function(c,v) _G.LexusConfig.ModSkin = v if v and _G.ForceRefreshSkinMaps then _G.ForceRefreshSkinMaps() end return true end },
    { Key = "ModMenu_Skin_Suit", UI = AliasMap.Slider, Text = "   سكن البدلة", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 80, GetFunc = function() return _G.LexusState.CustomTextData.SkinSuit or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinSuit = v if _G.OutfitSkins and _G.OutfitSkins.Suit[v] then _G.OutfitMap.Suit = _G.OutfitSkins.Suit[v] end return true end },
    { Key = "ModMenu_Skin_Bag", UI = AliasMap.Slider, Text = "   سكن الحقيبة", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 15, GetFunc = function() return _G.LexusState.CustomTextData.SkinBag or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinBag = v if _G.OutfitSkins and _G.OutfitSkins.Bag[v] then _G.OutfitMap.Bag = _G.OutfitSkins.Bag[v] end return true end },
    { Key = "ModMenu_Skin_Helmet", UI = AliasMap.Slider, Text = "   سكن الخوذة", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 11, GetFunc = function() return _G.LexusState.CustomTextData.SkinHelmet or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinHelmet = v if _G.OutfitSkins and _G.OutfitSkins.Helmet[v] then _G.OutfitMap.Helmet = _G.OutfitSkins.Helmet[v] end return true end },
    { Key = "ModMenu_Skin_M416", UI = AliasMap.Slider, Text = "   سكن M416", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 8, GetFunc = function() return _G.LexusState.CustomTextData.SkinM416 or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinM416 = v if _G.skinIdMappings[101004] and _G.skinIdMappings[101004][v] then _G.WeaponSkinMap[101004] = _G.skinIdMappings[101004][v] end return true end },
    { Key = "ModMenu_Skin_AKM", UI = AliasMap.Slider, Text = "   سكن AKM", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 8, GetFunc = function() return _G.LexusState.CustomTextData.SkinAKM or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinAKM = v if _G.skinIdMappings[101001] and _G.skinIdMappings[101001][v] then _G.WeaponSkinMap[101001] = _G.skinIdMappings[101001][v] end return true end },
    { Key = "ModMenu_Skin_SCAR", UI = AliasMap.Slider, Text = "   سكن SCAR", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 8, GetFunc = function() return _G.LexusState.CustomTextData.SkinSCAR or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinSCAR = v if _G.skinIdMappings[101003] and _G.skinIdMappings[101003][v] then _G.WeaponSkinMap[101003] = _G.skinIdMappings[101003][v] end return true end },
    { Key = "ModMenu_Skin_M762", UI = AliasMap.Slider, Text = "   سكن M762", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 8, GetFunc = function() return _G.LexusState.CustomTextData.SkinM762 or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinM762 = v if _G.skinIdMappings[101008] and _G.skinIdMappings[101008][v] then _G.WeaponSkinMap[101008] = _G.skinIdMappings[101008][v] end return true end },
    { Key = "ModMenu_Skin_AUG", UI = AliasMap.Slider, Text = "   سكن AUG", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 7, GetFunc = function() return _G.LexusState.CustomTextData.SkinAUG or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinAUG = v if _G.skinIdMappings[101006] and _G.skinIdMappings[101006][v] then _G.WeaponSkinMap[101006] = _G.skinIdMappings[101006][v] end return true end },
    { Key = "ModMenu_Skin_UMP", UI = AliasMap.Slider, Text = "   سكن UMP", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 5, GetFunc = function() return _G.LexusState.CustomTextData.SkinUMP or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinUMP = v if _G.skinIdMappings[102002] and _G.skinIdMappings[102002][v] then _G.WeaponSkinMap[102002] = _G.skinIdMappings[102002][v] end return true end },
    { Key = "ModMenu_Skin_UZI", UI = AliasMap.Slider, Text = "   سكن UZI", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.LexusState.CustomTextData.SkinUZI or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinUZI = v if _G.skinIdMappings[102001] and _G.skinIdMappings[102001][v] then _G.WeaponSkinMap[102001] = _G.skinIdMappings[102001][v] end return true end },
    { Key = "ModMenu_Skin_Groza", UI = AliasMap.Slider, Text = "   سكن Groza", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.LexusState.CustomTextData.SkinGroza or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinGroza = v if _G.skinIdMappings[101005] and _G.skinIdMappings[101005][v] then _G.WeaponSkinMap[101005] = _G.skinIdMappings[101005][v] end return true end },
    { Key = "ModMenu_Skin_S12K", UI = AliasMap.Slider, Text = "   سكن S12K", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.LexusState.CustomTextData.SkinS12K or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinS12K = v if _G.skinIdMappings[104003] and _G.skinIdMappings[104003][v] then _G.WeaponSkinMap[104003] = _G.skinIdMappings[104003][v] end return true end },
    { Key = "ModMenu_Skin_DBS", UI = AliasMap.Slider, Text = "   سكن DBS", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 3, GetFunc = function() return _G.LexusState.CustomTextData.SkinDBS or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinDBS = v if _G.skinIdMappings[104004] and _G.skinIdMappings[104004][v] then _G.WeaponSkinMap[104004] = _G.skinIdMappings[104004][v] end return true end },
    { Key = "ModMenu_Skin_ASM", UI = AliasMap.Slider, Text = "   سكن ASM", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.LexusState.CustomTextData.SkinASM or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinASM = v if _G.skinIdMappings[101101] and _G.skinIdMappings[101101][v] then _G.WeaponSkinMap[101101] = _G.skinIdMappings[101101][v] end return true end },
    { Key = "ModMenu_Skin_QBZ", UI = AliasMap.Slider, Text = "   سكن QBZ", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.LexusState.CustomTextData.SkinQBZ or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinQBZ = v if _G.skinIdMappings[101007] and _G.skinIdMappings[101007][v] then _G.WeaponSkinMap[101007] = _G.skinIdMappings[101007][v] end return true end },
    { Key = "ModMenu_Skin_Honey", UI = AliasMap.Slider, Text = "   سكن Honey Badger", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.LexusState.CustomTextData.SkinHoney or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinHoney = v if _G.skinIdMappings[101012] and _G.skinIdMappings[101012][v] then _G.WeaponSkinMap[101012] = _G.skinIdMappings[101012][v] end return true end },
    { Key = "ModMenu_Skin_M16A4", UI = AliasMap.Slider, Text = "   سكن M16A4", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.LexusState.CustomTextData.SkinM16A4 or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinM16A4 = v if _G.skinIdMappings[101002] and _G.skinIdMappings[101002][v] then _G.WeaponSkinMap[101002] = _G.skinIdMappings[101002][v] end return true end },
    { Key = "ModMenu_Skin_ACE32", UI = AliasMap.Slider, Text = "   سكن ACE32", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.LexusState.CustomTextData.SkinACE32 or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinACE32 = v if _G.skinIdMappings[101102] and _G.skinIdMappings[101102][v] then _G.WeaponSkinMap[101102] = _G.skinIdMappings[101102][v] end return true end },
    { Key = "ModMenu_Skin_Kar98k", UI = AliasMap.Slider, Text = "   سكن Kar98k", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.LexusState.CustomTextData.SkinKar98k or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinKar98k = v if _G.skinIdMappings[103001] and _G.skinIdMappings[103001][v] then _G.WeaponSkinMap[103001] = _G.skinIdMappings[103001][v] end return true end },
    { Key = "ModMenu_Skin_M24", UI = AliasMap.Slider, Text = "   سكن M24", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.LexusState.CustomTextData.SkinM24 or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinM24 = v if _G.skinIdMappings[103002] and _G.skinIdMappings[103002][v] then _G.WeaponSkinMap[103002] = _G.skinIdMappings[103002][v] end return true end },
    { Key = "ModMenu_Skin_AWM", UI = AliasMap.Slider, Text = "   سكن AWM", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.LexusState.CustomTextData.SkinAWM or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinAWM = v if _G.skinIdMappings[103003] and _G.skinIdMappings[103003][v] then _G.WeaponSkinMap[103003] = _G.skinIdMappings[103003][v] end return true end },
    { Key = "ModMenu_Skin_Dacia", UI = AliasMap.Slider, Text = "   سكن داسيا", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 34, GetFunc = function() return _G.LexusState.CustomTextData.SkinDacia or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinDacia = v if _G.VehicleSkins[1903001] and _G.VehicleSkins[1903001][v] then _G.VehicleSkinMap[1903001] = _G.VehicleSkins[1903001][v] end return true end },
    { Key = "ModMenu_Skin_UAZ", UI = AliasMap.Slider, Text = "   سكن UAZ", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 16, GetFunc = function() return _G.LexusState.CustomTextData.SkinUAZ or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinUAZ = v if _G.VehicleSkins[1908001] and _G.VehicleSkins[1908001][v] then _G.VehicleSkinMap[1908001] = _G.VehicleSkins[1908001][v] end return true end },
    { Key = "ModMenu_Skin_Coupe", UI = AliasMap.Slider, Text = "   سكن الكوبيه", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 55, GetFunc = function() return _G.LexusState.CustomTextData.SkinCoupe or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinCoupe = v if _G.VehicleSkins[1961001] and _G.VehicleSkins[1961001][v] then _G.VehicleSkinMap[1961001] = _G.VehicleSkins[1961001][v] end return true end },
    { Key = "ModMenu_Skin_Buggy", UI = AliasMap.Slider, Text = "   سكن الباجي", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 11, GetFunc = function() return _G.LexusState.CustomTextData.SkinBuggy or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinBuggy = v if _G.VehicleSkins[1907002] and _G.VehicleSkins[1907002][v] then _G.VehicleSkinMap[1907002] = _G.VehicleSkins[1907002][v] end return true end },
    { Key = "ModMenu_Skin_Mirado", UI = AliasMap.Slider, Text = "   سكن ميرادو", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 5, GetFunc = function() return _G.LexusState.CustomTextData.SkinMirado or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinMirado = v if _G.VehicleSkins[1915004] and _G.VehicleSkins[1915004][v] then _G.VehicleSkinMap[1915004] = _G.VehicleSkins[1915004][v] end return true end },
    { Key = "ModMenu_SkinDeadBox", UI = AliasMap.TitleSwitcher, Text = "سكن صندوق الموت", ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.SkinDeadBox end, SetFunc = function(c,v) _G.LexusConfig.SkinDeadBox = v return true end },
    { Key = "ModMenu_SkinAttachment", UI = AliasMap.TitleSwitcher, Text = "سكن الإضافات", ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.SkinAttachment end, SetFunc = function(c,v) _G.LexusConfig.SkinAttachment = v return true end },
  }
end

local function HookUIManagerShowUI()
  local UIManager = _G.UIManager
  if not UIManager or UIManager._IsModMenuHooked then return end
  local old_ShowUI = UIManager.ShowUI
  UIManager.ShowUI = function(config, ...)
    local args = { ... }
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
          if not hasModMenu then table.insert(catalog, 1, SettingPageDefineModule.ModMenu) end
        end
      end
    end
    local table_unpack = table.unpack or unpack
    return old_ShowUI(config, table_unpack(args, 1, n))
  end
  UIManager._IsModMenuHooked = true
end

function BRPlayerCharacterBase:InitModMenuTab()
  if _G.ModMenuInitialized then return end
  _G.ModMenuInitialized = true
  EnsureLexusGlobals()
  HookLocUtilText()

  local SettingPageDefine = SettingPageDefineModule
  local SettingCatalog = SettingCatalogModule
  local AliasMap = AliasMapModule

  if not SettingPageDefine.ModMenu then
    SettingPageDefine.ModMenu = {
      Key = "ModMenu",
      Text = 999000,
      UIKey = "Setting_Page_Privacy",
      Category = {
        { Key = "Cat_ESP",    Text = 999001, Stack = BuildESPStack(AliasMap) },
        { Key = "Cat_Combat", Text = 999003, Stack = _G.BuildStackCombat(AliasMap, function(t) return t end) },
        { Key = "Cat_Skin",   Text = 999004, Stack = BuildSkinStack(AliasMap) },
      }
    }
    table.insert(SettingCatalog, 1, SettingPageDefine.ModMenu)
  end

  HookUIManagerShowUI()

  if _G.InitializeSkinBypass then _G.InitializeSkinBypass() end
  if _G.InitializeSkinModSystem then _G.InitializeSkinModSystem() end
  if _G.ForceRefreshSkinMaps then _G.ForceRefreshSkinMaps() end
  if _G.InitFakeHWID then _G.InitFakeHWID() end
  if _G.LexusConfig.Esp9_Line and _G.PMM_LINES and _G.PMM_LINES.Start then
    _G.PMM_LINES.Start()
  end
  print(bWriteLog and "BRPlayerCharacterBase:InitModMenuTab done")
end

function BRPlayerCharacterBase:_TryInitModMenu()
  if _G.ModMenuInitialized then return end
  local ok, err = pcall(self.InitModMenuTab, self)
  if not ok then print(bWriteLog and "BRPlayerCharacterBase:_TryInitModMenu failed: " .. tostring(err)) end
end

function BRPlayerCharacterBase:_TryApplySkinsOnce()
  if not _G.LexusConfig or not _G.LexusConfig.ModSkin then return end
  local ok, err = pcall(function()
    if _G.ApplyWeaponSkins then _G.ApplyWeaponSkins(self) end
    if _G.equip_character_avatar then _G.equip_character_avatar(self) end
    if _G.ApplyVehicleSkins then _G.ApplyVehicleSkins(self) end
    if _G.HandlePetLogic then _G.HandlePetLogic() end
  end)
  if not ok then print(bWriteLog and "BRPlayerCharacterBase:_TryApplySkinsOnce failed: " .. tostring(err)) end
end

function BRPlayerCharacterBase:_TickCombat()
  local ok, err = pcall(function()
    if _G.DriveCombat then _G.DriveCombat(self) end
    if _G.DriveESPWallhack then _G.DriveESPWallhack() end
    if _G.LexusConfig and _G.LexusConfig.Esp9_Count and _G.CountPlayersAndBots then
      local p, b = _G.CountPlayersAndBots()
      _G.LexusState.LastCount = { players = p, bots = b }
    end
  end)
  if not ok then print(bWriteLog and "BRPlayerCharacterBase:_TickCombat failed: " .. tostring(err)) end
end

-- ====================================================================
-- ORIGINAL LIFECYCLE
-- ====================================================================
function BRPlayerCharacterBase:ctor()
end

function BRPlayerCharacterBase:_PostConstruct()
  BRPlayerCharacterBase.__super._PostConstruct(self)
  self:InitAddSpecialMoveInfo()
  self.bCanNearDeathGiveup = true
  print(bWriteLog and "BRPlayerCharacterBase:_PostConstruct bCanNearDeathGiveup true")
end

function BRPlayerCharacterBase:ReceiveBeginPlay()
  BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
  self:AddControlEvent(self, "MovementModeChangedDelegate", self.HandleOnMovementModeChangedNew, self)
  self:_TryInitModMenu()
  self:_TryApplySkinsOnce()
  self:AddGameTimer(0.2, true, function()
    if not slua.isValid(self.Object) then return end
    self:_TickCombat()
  end)
  if self:HasAuthority() and self:CheckAddCheckFallingDistanceComponent() then
    local CheckFallingDistanceComponent_C = import("CheckFallingDistanceComponent")
    if slua.isValid(CheckFallingDistanceComponent_C) and not slua.isValid(self:GetComponentByClass(CheckFallingDistanceComponent_C)) then
      print(bWriteLog and "BRPlayerCharacterBase:ReceiveBeginPlay Add CheckFallingDistanceComponent")
      Game:AddComponent(CheckFallingDistanceComponent_C, self, "CheckFallingDistanceComponent")
    end
  end
  if slua.isValid(self.STCharacterMovement) then
    self.STCharacterMovement.bPositiveBlowUp = true
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy then
    self:AddControlEvent(self, "OnPawnStateDisabled", self.OnPawnStateChange, self)
    self:AddControlEvent(self, "OnPawnStateEnabled", self.OnPawnStateChange, self)
    self:AddControlEventConditionOnly(self, "OnAttrChangeEventDelegate", {
      AttrName = { "bCanSelfRescue" }
    }, self.CharacterAttrChangeEvent, self)
  end
  if Client then
    printf(bWriteLog and "BRPlayerCharacterBase:ReceiveBeginPlay, PlayerKey:%u ", self.PlayerKey)
    GameplayData.AddCharacter(self.Object)
  else
    self:AddCommonEventWithConditions(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, {
      [1] = "FinishedState"
    }, self.HandleFinishedState, self)
    self:AddControlEvent(self, "OnPawnRespawnDelegate", self.OnRespawnRehideCheck, self)
  end
end

function BRPlayerCharacterBase:CharacterAttrChangeEvent(uPawn, AttrName, AttrVal)
  BRPlayerCharacterBase.__super.CharacterAttrChangeEvent(self, uPawn, AttrName, AttrVal)
  if self.Object ~= uPawn then return end
  if self.Role == ENetRole.ROLE_AutonomousProxy and AttrName == "bCanSelfRescue" then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then uPlayerController:BroadcastUIMessage("UIMsg_CanSelfRescue", 0, "", "") end
  end
end

function BRPlayerCharacterBase:OnPawnStateChange(PawnState)
  if PawnState == EPawnState.SwitchPP then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then uPlayerController:BroadcastUIMessage("UIMsg_FPPModeChange", 0, "", "") end
  end
end

function BRPlayerCharacterBase:HandleFinishedState()
  if slua.isValid(self.STCharacterMovement) and self.STCharacterMovement.SetDynamicSimpleQueryConfigDisable then
    local EDynamicSimpleQueryConfigDisableMask = import("EDynamicSimpleQueryConfigDisableMask")
    self.STCharacterMovement:SetDynamicSimpleQueryConfigDisable(EDynamicSimpleQueryConfigDisableMask.Bit0, true)
  end
end

function BRPlayerCharacterBase:OnRespawnRehideCheck()
  if not self:GetEnsure() then return end
  self:AddGameTimer(0.5, false, function()
    if not slua.isValid(self.Object) then return end
    if self:HasState(EPawnState.InPlane) then
      self:SetCharacterHideInGame(true, true, true, 1, ECharacterHideMovementAcive.Normal)
    end
  end)
end

function BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent()
  if CGameMode and CGameMode.GameModeType and CGameState and CGameState.GameModeID then
    local GameModeType = CGameMode.GameModeType
    local GameModeID = tonumber(CGameState.GameModeID)
    local bModeTypeSatisfy = GameModeType == EGameModeType.ETypicalGameMode or GameModeType == EGameModeType.EFourInOneGameMode or GameModeType == EGameModeType.EHeavyWeaponGameMode
    local bModeIDSatisfy = not MatchModeIds[GameModeID]
    return bModeTypeSatisfy and bModeIDSatisfy
  end
  return false
end

function BRPlayerCharacterBase:LuaHandleParachuteStateChanged(LastParachuteState, NewParachuteState)
  BRPlayerCharacterBase.__super.LuaHandleParachuteStateChanged(self, LastParachuteState, NewParachuteState)
  if not Client then
    local uCurrentPlayerControl = self:GetPlayerControllerSafety()
    if slua.isValid(uCurrentPlayerControl) and uCurrentPlayerControl.CheckParachuteOpenFeature then
      if NewParachuteState == EParachuteState.PS_Opening then
        if uCurrentPlayerControl.CheckParachuteOpenFeature.SatrtCheckShowParachuteCloseUI then
          uCurrentPlayerControl.CheckParachuteOpenFeature:SatrtCheckShowParachuteCloseUI()
        end
      elseif NewParachuteState == EParachuteState.PS_None then
        if uCurrentPlayerControl.CheckParachuteOpenFeature.RecoverParachuteOpenParam then uCurrentPlayerControl.CheckParachuteOpenFeature:RecoverParachuteOpenParam() end
        if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState() end
      end
    end
  end
end

function BRPlayerCharacterBase:OnLanded()
  if self.HandleOnLanded then self:HandleOnLanded(-1) end
  if not Client then
    local uCurrentPlayerControl = self:GetPlayerControllerSafety()
    if slua.isValid(uCurrentPlayerControl) and uCurrentPlayerControl.CheckParachuteOpenFeature then
      if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState() end
      if uCurrentPlayerControl.CheckParachuteOpenFeature.ResetCheckShowUI then uCurrentPlayerControl.CheckParachuteOpenFeature:ResetCheckShowUI() end
    end
  end
end

function BRPlayerCharacterBase:ReceiveEndPlay(EndPlayReason)
  BRPlayerCharacterBase.__super.ReceiveEndPlay(self, EndPlayReason)
  if Client then GameplayData.RemoveCharacter(self.Object) end
end

function BRPlayerCharacterBase:IsWarGameMode()
  local uGameState = GameplayData:GetGameState()
  if slua.isValid(uGameState) and Game:IsClassOf(uGameState, STExtraGameStateBase) then
    return uGameState.GameModeType == EGameModeType.EWarGameMode
  else
    return false
  end
end

function BRPlayerCharacterBase:BPOnRecycled()
  if Client then self:ResetMeshRelativeLocationAndRotation() end
end

function BRPlayerCharacterBase:BPOnRespawned()
  if Client then self:ResetMeshRelativeLocationAndRotation() end
end

function BRPlayerCharacterBase:ReceiveOnRecycle()
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
    GameplayData.RemoveCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:ReceiveOnSpawn()
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
    GameplayData.AddCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:ResetMeshRelativeLocationAndRotation()
  if Game:IsValid(self.Object) and Game:IsValid(self.Mesh) then
    local uDefaultMeshRot = FRotator(0, -90, 0)
    local uDefaultMeshRelativeLoc = FVector(0, 0, 0)
    if self.Mesh.K2_SetRelativeRotation then self.Mesh:K2_SetRelativeRotation(uDefaultMeshRot, false, nil, false) end
    self:CacheInitialMeshOffset(uDefaultMeshRelativeLoc, uDefaultMeshRot)
  end
end

function BRPlayerCharacterBase:HandleOnMovementModeChangedNew()
  if Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Swimming and self:CheckBaseIsMoveable() then
    self.CharacterMovement:SetBase(nil, "", true)
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy and Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Walking and UIManager.UI_Config_InGame.ParachuteOpenUI then
    UIManager.CloseUI(UIManager.UI_Config_InGame.ParachuteOpenUI)
  end
end

function BRPlayerCharacterBase:BPOnMissPlayerDamageRecord()
end

function BRPlayerCharacterBase:PreAttachedToVehicle()
  local IsDS = UKismetSystemLibrary.IsDedicatedServer(self)
  if not IsDS then return end
  local MainPlayerController = self:GetPlayerControllerSafety()
  if not slua.isValid(MainPlayerController) then return end
  local CharacterAvatarComp2_BP = self.CharacterAvatarComp2_BP
  if not slua.isValid(CharacterAvatarComp2_BP) then return end
  local CommerAvatarDataUtil = require("GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil")
  local changedVehicleId = CommerAvatarDataUtil:ChangeVehicleSkinByClothes(MainPlayerController, CharacterAvatarComp2_BP)
  local ESTExtraVehicleShapeType = import("ESTExtraVehicleShapeType")
  if changedVehicleId then
    local UAvatarUtils = import("AvatarUtils")
    if UAvatarUtils.GetVehicleShapeBySkinID(changedVehicleId) == ESTExtraVehicleShapeType.VST_Horse then
      local uCurPlayerState = self:GetPlayerStateSafety()
      if slua.isValid(uCurPlayerState) then uCurPlayerState:AddGeneralCount(468, 1, false) end
    end
  end
end

function BRPlayerCharacterBase:ParachuteJump()
  local uPlayerController = self:GetControllerSafety()
  if slua.isValid(uPlayerController) then
    if not self:GetEnsure() then
      if uPlayerController:GetCurrentStateType() ~= EStateType.State_ParachuteJump and uPlayerController:GetCurrentStateType() ~= EStateType.State_ParachuteOpen then
        self:SwitchPoseState(ESTEPoseState.Stand, true, true, true, false)
        uPlayerController:ReInitParachuteItem()
        uPlayerController:ServerChangeStatePC(EStateType.State_ParachuteJump)
      end
    else
      EventSystem:postEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_AI_CALL_PARACHUTE_JUMP, self.Object)
    end
  end
end

function BRPlayerCharacterBase:OnMovementBaseChangedEvent(uCharacter, uNewMovementBase, uOldMovementBase)
  if uCharacter ~= self.Object then return end
  local MedievalCrane = self:GetMedievalCraneFromBase(uNewMovementBase)
  if MedievalCrane and MedievalCrane.AddCharacter then
    MedievalCrane:AddCharacter(self.Object)
  else
    MedievalCrane = self:GetMedievalCraneFromBase(uOldMovementBase)
    if MedievalCrane and MedievalCrane.RemoveCharacter then MedievalCrane:RemoveCharacter(self.Object) end
  end
end

function BRPlayerCharacterBase:GetMedievalCraneFromBase(Base)
  if not slua.isValid(Base) or not Base.GetOwner then return end
  local Lifter = Base:GetOwner()
  if not slua.isValid(Lifter) then return end
  if not Lifter.AddCharacter then return end
  return Lifter
end

function BRPlayerCharacterBase:CheckForbidFlaregun()
  local uPlayerState = self:GetPlayerStateSafety()
  if not slua.isValid(uPlayerState) then return false end
  if uPlayerState.CanUseFlaregun == false and self:IsLocallyControlled() then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then uPlayerController:DisplayGameTipWithMsgID(48532) end
  end
  return not uPlayerState.CanUseFlaregun
end

function BRPlayerCharacterBase:ServerRPC_NearDeathGiveupRescue()
  self:HandleNearDeathGiveupRescue()
end

function BRPlayerCharacterBase:HandleNearDeathGiveupRescue()
  local uNearDeathComp = self.NearDeatchComponent
  if self:IsNearDeath() and slua.isValid(uNearDeathComp) and self.bCanNearDeathGiveup == true then
    local uPlayerState = self:GetPlayerStateSafety()
    if slua.isValid(uPlayerState) then uPlayerState:AddGeneralCount(1613, 1, false) end
    uNearDeathComp:TriggerGotoDieExplictly(self.Object)
  end
end

function BRPlayerCharacterBase:RPC_Server_GmPlayAction(actionId)
  if USTExtraBlueprintFunctionLibrary.IsDevelopment() then
    self:MulticastRPC_GmPlayAction(actionId)
  end
end

function BRPlayerCharacterBase:MulticastRPC_GmPlayAction(actionId)
  if not Client then return end
  local uPlayEmoteComp = self:GetPlayEmoteComponent()
  if not slua.isValid(uPlayEmoteComp) then return end
  local LogFilter = require("common.log_filter")
  LogFilter.SetLogTreeEnable(true)
  local animCfg = CDataTable.GetTableData("EmoteBPTable", actionId)
  if not animCfg then return end
  local handlePath = animCfg.Path
  local EmoteHandleAsset = slua.loadObject(handlePath)
  local assetsArray = slua.Array(UEnums.EPropertyClass.Struct, import("/Script/CoreUObject.SoftObjectPath"))
  local handle = EmoteHandleAsset()
  uPlayEmoteComp:OnLoadEmoteAssetBegin(handle, actionId, assetsArray, "")
  local tb = FuncUtil.LuaArrayToTable(assetsArray)
  local asset_util = require("common.asset_util")
  local function loadLater()
    uPlayEmoteComp:OnLoadEmoteAssetEnd(handle, actionId, 0)
  end
  asset_util.GetAssetsArrayAsyncParallel(tb, loadLater)
end

function BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall(bServerSyncShouldCheckPassWall)
  if slua.isValid(self.ParachuteComponent) then
    self.ParachuteComponent.bServerSyncShouldCheckPassWall = bServerSyncShouldCheckPassWall
  end
end

function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState()
  self.Super:OnPlayerEnterCarryBoxState()
  if self.CarryDeadBoxFeature then self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState() end
end

function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  self.Super:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  if self.CarryDeadBoxFeature then self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(bInIsInterrupt) end
end

function BRPlayerCharacterBase:ServerRPC_CarryDeadBox(uInDeadBox)
  if slua.isValid(uInDeadBox) and Game:IsClassOf(uInDeadBox, import("/Script/ShadowTrackerExtra.PlayerTombBox")) and self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:CarryDeadBox(uInDeadBox)
  end
end

function BRPlayerCharacterBase:SetAreaID(AreaID)
  self:SetAttrValue("AreaID", AreaID, -1)
end

function BRPlayerCharacterBase:GetAreaID()
  return math.floor(self:GetAttrValue("AreaID") + 0.5)
end

function BRPlayerCharacterBase:CannotChangeIntoPetSpectator()
  return self.bCannotChangeIntoPetSpectator
end

function BRPlayerCharacterBase:DoModChangeToBT()
  if self:HasState(EPawnState.SpecialSuit) then
    self:TriggerEntrySkillWithID(4301101, true)
  end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteOpening()
  self.Super:SwitchCameraToParachuteOpening()
  if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
    self.ParachuteFormation:OverlayFormationCameraParams()
  end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteFalling()
  self.Super:SwitchCameraToParachuteFalling()
  if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
    self.ParachuteFormation:OverlayFormationCameraParams()
  end
end

function BRPlayerCharacterBase:SwitchCameraToNormal()
  self.Super:SwitchCameraToNormal()
  if self.ParachuteFormation and self.ParachuteFormation.OnLandingClearFormationCamera then
    self.ParachuteFormation:OnLandingClearFormationCamera()
  end
end

function BRPlayerCharacterBase:SwitchWeaponCheck(Slot, IgnoreState)
  if self:HasState(EPawnState.AttachToOther) then
    local Weapon = self:GetWeaponBySlot(Slot)
    if slua.isValid(Weapon) then
      local WeaponID = Weapon:GetWeaponID()
      local AttachToOtherConfig = GamePlayTools.GetCurrentConfig("AttachToOtherConfig")
      if AttachToOtherConfig and AttachToOtherConfig.CheckIsWeaponInBlackList and AttachToOtherConfig.CheckIsWeaponInBlackList(WeaponID) then
        local uPlayerController = self:GetPlayerControllerSafety()
        if Client and slua.isValid(uPlayerController) and uPlayerController.Role == ENetRole.ROLE_AutonomousProxy then
          uPlayerController:DisplayGameTipWithMsgID(47306)
        end
        return false
      end
    end
  end
  if self:HasState(EPawnState.WebSwing) and Slot ~= ESurviveWeaponPropSlot.SWPS_None and slua.isValid(self.STCharacterMovement) then
    local SpiderSwingObj = self.STCharacterMovement:GetSpecialMoveObjBySpecialMoveType(ESpecialMovementType.SPECIAL_MOVE_SpiderSwing)
    if slua.isValid(SpiderSwingObj) then
      local nCurState = SpiderSwingObj:GetCurMoveState()
      if nCurState == ESpiderSwingMoveState.Launching or nCurState == ESpiderSwingMoveState.Swinging then
        return false
      end
    end
  end
  return self.Super:SwitchWeaponCheck(Slot, IgnoreState)
end

local VICTORY_DANCE_FX_MAP = { [12219601] = 22010089 }
local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
local isFitVersion = PublishRegionMacros.IsFITVersion()

local function ResolveEmoteResID(ItemID)
  local FxID = VICTORY_DANCE_FX_MAP[ItemID]
  if not FxID or FxID == ItemID then return ItemID end
  local model_util = require("client.common.model_util")
  local FxBPID = model_util.GetBPID(FxID)
  local ResID = ItemID
  if FxBPID and 0 < FxBPID and model_util.IsBattleItemHandleExist("Emote", FxBPID, false, false) then
    ResID = FxID
  end
  if isFitVersion and ResID == 12219601 then return 12222069 end
  return ResID
end

function BRPlayerCharacterBase:GetEmoteHandlePath(ItemID)
  local ResID = ResolveEmoteResID(ItemID)
  if self.Super then return self.Super:GetEmoteHandlePath(ResID) end
  local model_util = require("client.common.model_util")
  local BPID = model_util.GetBPID(ResID)
  if not BPID or BPID <= 0 then return "" end
  return model_util.GetPath("Emote", BPID, false, false) or ""
end

function BRPlayerCharacterBase:GetEmoteHandle(ItemID)
  local ResID = ResolveEmoteResID(ItemID)
  if self.Super then return self.Super:GetEmoteHandle(ResID) end
  local model_util = require("client.common.model_util")
  local BPID = model_util.GetBPID(ResID)
  if not BPID or BPID <= 0 then return nil end
  local HandleClass = model_util.GetClass("Emote", BPID, false, false)
  if not HandleClass then return nil end
  local Handle = HandleClass()
  if not slua.isValid(Handle) then return nil end
  return Handle
end

local class = require("class")
local CCharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CBRPlayerCharacterBase = class(CCharacterBase, nil, BRPlayerCharacterBase)
return require("combine_class").DeclareFeature(CBRPlayerCharacterBase, {
  { SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature" },
  { CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature" },
  { SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature" },
  { TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature" },
  { LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature" },
  { FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature" },
  { CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature" },
  { BuildAircraftVehicleFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature" },
  { UnifiedBuildVehicleFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.UnifiedBuildVehicleFeature" },
  { CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature" },
  { ParachuteFormation = "GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature" },
  { ParachuteSprint = "GameLua.Mod.BaseMod.GamePlay.Feature.Parachute.ParachuteSprintFeature" },
  { GeneralShowSpotFeature = "GameLua.Mod.BRMod.Gameplay.Feature.PlayerCharacterGeneralShowSpotFeature" },
  { FPPAnimMonitor = "GameLua.Mod.BaseMod.GamePlay.Feature.Player.FPPAnimMonitorFeature" }
}, "BRPlayerCharacterBase")