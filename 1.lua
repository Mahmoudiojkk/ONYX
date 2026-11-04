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

-- ==============================================================================
--  [MOD MENU + ESP SNAP LINES BOOTSTRAP]  --  TAB واحد فقط: Snap Lines
-- ==============================================================================
local function _BootstrapModMenu()
  if _G.__ModMenuBootstrapDone then return end
  _G.__ModMenuBootstrapDone = true

  -- ==============================
  --  RAAD_LINES (inline)
  -- ==============================
  do
    _G.RAAD_LINES = {}
    local L = _G.RAAD_LINES
    local FVector2D     = _G.FVector2D or import("Vector2D")
    local FLinearColor  = _G.FLinearColor or import("LinearColor")
    local SlateBP       = nil
    local WidgetLayout  = nil
    pcall(function() SlateBP = import("SlateBlueprintLibrary") end)
    pcall(function() WidgetLayout = import("WidgetLayoutLibrary") end)

    local function ESPValid(obj)
      if obj == nil then return false end
      if not slua or not slua.isValid then return false end
      local ok, v = pcall(slua.isValid, obj)
      return ok and v == true
    end
    local function V2(x, y)
      if FVector2D then return FVector2D(x, y) end
      return { X = x, Y = y }
    end
    local function KC(r, g, b, a)
      if FLinearColor then return FLinearColor(r, g, b, a) end
      return { R = r, G = g, B = b, A = a }
    end
    local function RND(v)
      if v ~= v then return 0 end
      return math.floor(v + 0.5)
    end

    L.CFG = {
      MaxMeters    = 100,
      Thickness    = 1.8,
      OriginY      = 0,
      ScreenMargin = 220,
      VisInterval  = 0.15,
      VisBudget    = 3,
      DeadZone     = 0.5,
      MaxTracked   = 12,
    }
    L.COLOR_VISIBLE   = KC(0.5776, 0.0, 0.0, 1.0)
    L.COLOR_INVISIBLE = KC(0.12,   1.0, 0.25, 1.0)

    L.Canvas = nil
    L.Lines  = {}
    L.VisCache = {}
    L.Known    = {}
    L.ScaleX, L.ScaleY = 1.0, 1.0
    L.OffsetX, L.OffsetY = 0.0, 0.0
    L.LastTransform = -999
    L.bActive = false

    local function GetCanvas()
      if ESPValid(L.Canvas) then return L.Canvas end
      local root = nil
      pcall(function()
        local T = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
        if T and T.GetMainControlBaseUI then root = T.GetMainControlBaseUI() end
      end)
      if not ESPValid(root) then return nil end
      local cv = nil
      pcall(function()
        if ESPValid(root.CanvasPanel_0) then cv = root.CanvasPanel_0
        elseif ESPValid(root.CanvasPanel_42) then cv = root.CanvasPanel_42 end
      end)
      if ESPValid(cv) then L.Canvas = cv return cv end
      return nil
    end

    local function UpdateTransform(pc)
      local cv = GetCanvas()
      if not ESPValid(cv) then return false end
      local ok = false
      pcall(function()
        if SlateBP and SlateBP.AbsoluteToLocal then
          local geo = cv:GetCachedGeometry()
          if geo then
            local p0 = SlateBP.AbsoluteToLocal(geo, V2(0, 0))
            local p1 = SlateBP.AbsoluteToLocal(geo, V2(100, 100))
            if p0 and p1 and p1.X ~= p0.X and p1.Y ~= p0.Y then
              L.ScaleX = (p1.X - p0.X) / 100.0
              L.ScaleY = (p1.Y - p0.Y) / 100.0
              L.OffsetX = p0.X
              L.OffsetY = p0.Y
              ok = true
            end
          end
        end
      end)
      if not ok then
        local s = 1.0
        pcall(function()
          if WidgetLayout and WidgetLayout.GetViewportScale then
            local v = WidgetLayout.GetViewportScale(pc)
            if tonumber(v) and v > 0 then s = v end
          end
        end)
        L.ScaleX = 1.0 / s
        L.ScaleY = 1.0 / s
        L.OffsetX, L.OffsetY = 0, 0
      end
      return true
    end

    local _pix = nil
    local _loc = { X = 0, Y = 0, Z = 0 }
    local function Project(pc, x, y, z)
      if not pc then return nil end
      if not _pix then _pix = V2(0, 0) end
      _loc.X, _loc.Y, _loc.Z = x, y, z
      local ok, res = pcall(function()
        return pc:ProjectWorldLocationToScreen(_loc, _pix, true)
      end)
      if not ok then return nil end
      local px, py = _pix.X, _pix.Y
      local good = (res == true or res == 1) or (px ~= 0 or py ~= 0)
      if not good then return nil end
      return px * (L.ScaleX or 1.0) + (L.OffsetX or 0.0),
             py * (L.ScaleY or 1.0) + (L.OffsetY or 0.0),
             px, py
    end

    local function ScreenCenterX(pc, viewW)
      local cx = nil
      pcall(function()
        local mgr = import("GameplayStatics").GetPlayerCameraManager(pc, 0)
        if mgr and mgr.GetCameraLocation and mgr.GetCameraRotation then
          local loc, rot = mgr:GetCameraLocation(), mgr:GetCameraRotation()
          if loc and rot then
            local yaw, pitch = math.rad(rot.Yaw), math.rad(rot.Pitch)
            local cp = math.cos(pitch)
            local D = 10000
            local sx = Project(pc,
              loc.X + cp * math.cos(yaw) * D,
              loc.Y + cp * math.sin(yaw) * D,
              loc.Z + math.sin(pitch) * D)
            if sx and tonumber(sx) then cx = sx end
          end
        end
      end)
      if not cx then
        cx = (viewW * 0.5) * (L.ScaleX or 1.0) + (L.OffsetX or 0.0)
      end
      return RND(cx)
    end

    local function NewLine(color, z)
      local cv = GetCanvas()
      if not ESPValid(cv) then return nil end
      local border = nil
      pcall(function() border = CGame:NewObjectFromPath("/Script/UMG.Border", cv) end)
      if not ESPValid(border) then return nil end
      pcall(function()
        border:SetBrushColor(color)
        border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        border:SetRenderTransformPivot(V2(0.0, 0.5))
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

    local function EnsureLine(key)
      local d = L.Lines[key]
      if d and ESPValid(d.Widget) then return d end
      d = NewLine(L.COLOR_VISIBLE, 30)
      if d then d.colorKey = "vis" end
      L.Lines[key] = d
      L.Known[key] = true
      return d
    end

    local function DrawLine(d, x1, y1, x2, y2, thickness)
      if not d or not d.Slot or not ESPValid(d.Widget) then return false end
      if x1 ~= x1 or y1 ~= y1 or x2 ~= x2 or y2 ~= y2 then return false end
      x1, y1, x2, y2 = RND(x1), RND(y1), RND(x2), RND(y2)
      local dz = L.CFG.DeadZone
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
        d.Slot:SetPosition(V2(x1, y1 - thickness * 0.5))
        d.Slot:SetSize(V2(len, thickness))
        d.Widget:SetRenderAngle(angle)
      end)
      if ok then
        d.lx1, d.ly1, d.lx2, d.ly2, d.th = x1, y1, x2, y2, thickness
      end
      return true
    end

    local function SetColor(d, color, key)
      if not d or d.colorKey == key then return end
      if not ESPValid(d.Widget) then return end
      pcall(function() d.Widget:SetBrushColor(color) end)
      d.colorKey = key
    end

    local function HideLine(d)
      if d and not d.hidden and ESPValid(d.Widget) then
        pcall(function() d.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
        d.hidden = true
        d.lx1, d.ly1, d.lx2, d.ly2 = nil, nil, nil, nil
      end
    end

    local KLib, HitRes = nil, nil
    local StartPos = { X = 0, Y = 0, Z = 0 }
    local EndPos   = { X = 0, Y = 0, Z = 0 }
    pcall(function()
      KLib = import("KismetSystemLibrary")
      local HR = import("HitResult")
      if HR then HitRes = HR() else HitRes = {} end
    end)

    local BONES = { "head", "spine_03", "pelvis" }
    local function GetBoneXYZ(c, bone)
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

    local _visLeft = 0
    local function IsVisible(key, pc, c, now)
      local cached = L.VisCache[key]
      if cached then
        local age = now - cached.t
        if age >= 0 and age < L.CFG.VisInterval then return cached.b end
        if _visLeft <= 0 and age < 0.6 then return cached.b end
      end
      _visLeft = _visLeft - 1
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
      if cx and KLib and KLib.LineTraceSingle and ESPValid(c) then
        for i = 1, #BONES do
          local bx, by, bz = GetBoneXYZ(c, BONES[i])
          if bx and (bx ~= 0 or by ~= 0 or bz ~= 0) then
            local dx, dy, dz = bx - cx, by - cy, bz - cz
            local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
            if dist >= 50 then
              StartPos.X = cx + (dx / dist) * 60
              StartPos.Y = cy + (dy / dist) * 60
              StartPos.Z = cz + (dz / dist) * 60
              EndPos.X, EndPos.Y, EndPos.Z = bx, by, bz
              local ok, hit = pcall(function()
                return KLib.LineTraceSingle(pc, StartPos, EndPos, 0, false, nil, 0, HitRes, true)
              end)
              if ok then
                if not hit then bVis = true break end
                local ha = HitRes and (type(HitRes.GetActor) == "function" and HitRes:GetActor() or HitRes.Actor)
                if ha == c then bVis = true break end
              end
            end
          end
        end
      else
        bVis = true
      end
      if cached then cached.b, cached.t = bVis, now
      else L.VisCache[key] = { b = bVis, t = now } end
      return bVis
    end

    function L.Update()
      if not L.bActive then return end
      local now = os.clock()
      local pc = nil
      pcall(function()
        local GDP = require("GameLua.GameCore.Data.GameplayData")
        if GDP and GDP.GetPlayerController then pc = GDP.GetPlayerController() end
      end)
      if not ESPValid(pc) then return end
      local cv = GetCanvas()
      if not ESPValid(cv) then return end
      if now - L.LastTransform >= 0.6 then
        UpdateTransform(pc)
        L.LastTransform = now
      end
      local vw, vh = 1920, 1080
      pcall(function()
        local v = V2(0, 0)
        pc:GetViewportSize(v)
        if v and tonumber(v.X) and v.X > 200 then vw, vh = v.X, v.Y end
      end)
      local ox = ScreenCenterX(pc, vw)
      local oy = L.CFG.OriginY
      local player = nil
      pcall(function()
        local GDP = require("GameLua.GameCore.Data.GameplayData")
        if GDP and GDP.GetPlayerCharacter then player = GDP.GetPlayerCharacter() end
      end)
      if not ESPValid(player) then return end
      local myTeam = nil
      pcall(function()
        if type(player.GetTeamID) == "function" then myTeam = player:GetTeamID()
        else myTeam = player.TeamID end
      end)
      local pawns = nil
      pcall(function() pawns = Game:GetAllPlayerPawns() end)
      if not pawns then return end
      _visLeft = L.CFG.VisBudget
      local activeKeys = {}
      for _, c in pairs(pawns) do
        if ESPValid(c) and c ~= player then
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
                if dist / 100 <= L.CFG.MaxMeters then
                  local hx, hy, hz = nil, nil, nil
                  pcall(function()
                    local cap = c.CapsuleComponent or c:GetCapsuleComponent()
                    if ESPValid(cap) then
                      local l = cap:GetComponentLocation()
                      local h = cap:GetScaledCapsuleHalfHeight()
                      hx, hy, hz = l.X, l.Y, l.Z + h
                    end
                  end)
                  if hx then
                    local sx, sy = Project(pc, hx, hy, hz)
                    if sx then
                      local okScreen = (sx > -L.CFG.ScreenMargin and sx < vw + L.CFG.ScreenMargin
                                    and sy > -L.CFG.ScreenMargin and sy < vh + L.CFG.ScreenMargin)
                      if okScreen then
                        local line = EnsureLine(key)
                        if line then
                          local bVis = IsVisible(key, pc, c, now)
                          if bVis then SetColor(line, L.COLOR_VISIBLE, "vis")
                          else SetColor(line, L.COLOR_INVISIBLE, "inv") end
                          DrawLine(line, ox, oy, sx, sy, L.CFG.Thickness)
                        end
                      else
                        HideLine(L.Lines[key])
                      end
                    end
                  end
                else
                  HideLine(L.Lines[key])
                end
              else
                HideLine(L.Lines[key])
              end
            end
          end)
        end
      end
      for k, d in pairs(L.Lines) do
        if not activeKeys[k] then HideLine(d) end
      end
    end

    function L.Start()
      if L.bActive then return end
      L.bActive = true
      local tk = nil
      pcall(function() tk = require("common.time_ticker") end)
      if tk and tk.AddTimerOnce then
        local function tick()
          if not L.bActive then return end
          pcall(L.Update)
          tk.AddTimerOnce(0.033, tick)
        end
        tk.AddTimerOnce(0.1, tick)
      end
      print("[RAAD @Masssryy] ESP Lines STARTED ✓")
    end

    function L.Stop()
      L.bActive = false
      for k, d in pairs(L.Lines) do
        if d and ESPValid(d.Widget) then
          pcall(function()
            d.Widget:RemoveFromParent()
            d.Widget:ConditionalBeginDestroy()
          end)
        end
      end
      L.Lines = {}
      L.VisCache = {}
      L.Known = {}
      print("[RAAD @Masssryy] ESP Lines STOPPED")
    end

    function L.SetThickness(t)  L.CFG.Thickness = tonumber(t) or 1.8 end
    function L.SetMaxMeters(m)  L.CFG.MaxMeters = tonumber(m) or 100 end
    function L.SetVisibleColor(r, g, b)   L.COLOR_VISIBLE = KC(r, g, b, 1) end
    function L.SetInvisibleColor(r, g, b) L.COLOR_INVISIBLE = KC(r, g, b, 1) end

    _G.PMM_LINES = L
  end

  -- ==============================
  --  MOD MENU INIT  (TAB واحد فقط)
  -- ==============================
  function _G.InitModMenuTab()
      if _G.ModMenuInitialized then return end
      _G.ModMenuInitialized = true

      local function T(vnText, enText)
          return enText or vnText
      end

      _G.LexusState.CustomTextData = _G.LexusState.CustomTextData or {
          SnapLineThickness = 2, SnapLineMaxMeters = 100,
          SnapLineColorVisible = 1, SnapLineColorInvisible = 2
      }

      local SNAP_COLORS = {
          [1] = { 0.5776, 0.0,    0.0    },
          [2] = { 0.12,   1.0,    0.25   },
          [3] = { 0.20,   0.55,   1.0    },
          [4] = { 1.0,    0.85,   0.15   },
          [5] = { 1.0,    0.30,   0.90   },
      }

      local LocUtil = _G.LocUtil
      if not LocUtil and package.loaded["client.common.LocUtil"] then
          LocUtil = require("client.common.LocUtil")
      end

      local FakeTextMap = {
          [999000] = T("DAVID KING"),
          [999001] = T("SNAP LINES"),
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
      local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")

      if not SettingPageDefine.ModMenu then
          local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")

          -- ============================
          --  تاب واحد فقط: Snap Lines
          -- ============================
          local StackSnapLines = {
              { Key = "ModMenu_SnapLines_Ex", UI = AliasMap.TitleSwitcher, Text = T("ESP SNAP LINES (RAAD)"), ExpandIndex = 0,
                GetFunc = function() return _G.LexusConfig.SnapLines end,
                SetFunc = function(c, v)
                    _G.LexusConfig.SnapLines = v
                    if v then
                        if _G.RAAD_LINES and _G.RAAD_LINES.Start then pcall(_G.RAAD_LINES.Start) end
                    else
                        if _G.RAAD_LINES and _G.RAAD_LINES.Stop then pcall(_G.RAAD_LINES.Stop) end
                    end
                    return true
                end },
              { Key = "ModMenu_SnapLines_Thick", UI = AliasMap.Slider, Text = T("   Line Thickness"), ExpandHandle = "ModMenu_SnapLines_Ex",
                MinValue = 1, MaxValue = 6,
                GetFunc = function() return _G.LexusState.CustomTextData.SnapLineThickness or 2 end,
                SetFunc = function(c, v)
                    _G.LexusState.CustomTextData.SnapLineThickness = v
                    if _G.RAAD_LINES and _G.RAAD_LINES.SetThickness then pcall(_G.RAAD_LINES.SetThickness, v) end
                    return true
                end },
              { Key = "ModMenu_SnapLines_Meters", UI = AliasMap.Slider, Text = T("   Max Distance (m)"), ExpandHandle = "ModMenu_SnapLines_Ex",
                MinValue = 25, MaxValue = 300,
                GetFunc = function() return _G.LexusState.CustomTextData.SnapLineMaxMeters or 100 end,
                SetFunc = function(c, v)
                    _G.LexusState.CustomTextData.SnapLineMaxMeters = v
                    if _G.RAAD_LINES and _G.RAAD_LINES.SetMaxMeters then pcall(_G.RAAD_LINES.SetMaxMeters, v) end
                    return true
                end },
              { Key = "ModMenu_SnapLines_ColVis", UI = AliasMap.Slider, Text = T("   Visible Color (1-5)"), ExpandHandle = "ModMenu_SnapLines_Ex",
                MinValue = 1, MaxValue = 5,
                GetFunc = function() return _G.LexusState.CustomTextData.SnapLineColorVisible or 1 end,
                SetFunc = function(c, v)
                    _G.LexusState.CustomTextData.SnapLineColorVisible = v
                    local col = SNAP_COLORS[v] or SNAP_COLORS[1]
                    if _G.RAAD_LINES and _G.RAAD_LINES.SetVisibleColor then
                        pcall(_G.RAAD_LINES.SetVisibleColor, col[1], col[2], col[3])
                    end
                    return true
                end },
              { Key = "ModMenu_SnapLines_ColInv", UI = AliasMap.Slider, Text = T("   Hidden Color (1-5)"), ExpandHandle = "ModMenu_SnapLines_Ex",
                MinValue = 1, MaxValue = 5,
                GetFunc = function() return _G.LexusState.CustomTextData.SnapLineColorInvisible or 2 end,
                SetFunc = function(c, v)
                    _G.LexusState.CustomTextData.SnapLineColorInvisible = v
                    local col = SNAP_COLORS[v] or SNAP_COLORS[2]
                    if _G.RAAD_LINES and _G.RAAD_LINES.SetInvisibleColor then
                        pcall(_G.RAAD_LINES.SetInvisibleColor, col[1], col[2], col[3])
                    end
                    return true
                end },
          }

          -- فلتر أمان: أي عنصر مفيهوش Get/SetFunc يتشال
          local function _hasFuncs(item)
              return type(item) == "table"
                  and type(item.GetFunc) == "function"
                  and type(item.SetFunc) == "function"
          end
          local _clean = {}
          for _, item in ipairs(StackSnapLines) do
              if _hasFuncs(item) then _clean[#_clean + 1] = item end
          end
          StackSnapLines = _clean

          SettingPageDefine.ModMenu = {
              Key = "ModMenu",
              Text = 999000,
              UIKey = "Setting_Page_Privacy",
              Category = {
                  { Key = "Cat_SnapLines", Text = 999001, Stack = StackSnapLines },
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
                              if type(page) == "table" and page.Key == "ModMenu" then
                                  hasModMenu = true
                                  break
                              end
                          end
                          if not hasModMenu then
                              table.insert(catalog, 1, SettingPageDefine.ModMenu)
                          end
                      end
                  end
              end
              local table_unpack = table.unpack or unpack
              return old_ShowUI(config, table_unpack(args, 1, n))
          end
          UIManager._IsModMenuHooked = true
      end
  end

  -- Globals defaults
  _G.LexusConfig = _G.LexusConfig or {
      SnapLines = false,
  }
  _G.LexusState = _G.LexusState or { CustomTextData = {}, DirtyConfig = false }
  _G.OutfitMap = _G.OutfitMap or {}
  _G.WeaponSkinMap = _G.WeaponSkinMap or {}
  _G.VehicleSkinMap = _G.VehicleSkinMap or {}
  _G.OutfitSkins = _G.OutfitSkins or { Suit = {}, Bag = {}, Helmet = {} }
  _G.skinIdMappings = _G.skinIdMappings or {}
  _G.VehicleSkins = _G.VehicleSkins or {}
end
-- ==============================================================================
--  [END BOOTSTRAP]
-- ==============================================================================


function BRPlayerCharacterBase:ctor()
end

function BRPlayerCharacterBase:_PostConstruct()
  BRPlayerCharacterBase.__super._PostConstruct(self)
  pcall(_BootstrapModMenu)
  pcall(_G.InitModMenuTab)
  self:InitAddSpecialMoveInfo()
  self.bCanNearDeathGiveup = true
  print(bWriteLog and "BRPlayerCharacterBase:_PostConstruct bCanNearDeathGiveup true")
end

function BRPlayerCharacterBase:ReceiveBeginPlay()
  BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
  pcall(_G.InitModMenuTab)
  self:AddControlEvent(self, "MovementModeChangedDelegate", self.HandleOnMovementModeChangedNew, self)
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
      AttrName = {
        "bCanSelfRescue"
      }
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
  if self.Object ~= uPawn then
    return
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy and AttrName == "bCanSelfRescue" then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:BroadcastUIMessage("UIMsg_CanSelfRescue", 0, "", "")
    end
  end
end

function BRPlayerCharacterBase:OnPawnStateChange(PawnState)
  print("BRPlayerCharacterBase:OnPawnStateChange:", PawnState)
  if PawnState == EPawnState.SwitchPP then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:BroadcastUIMessage("UIMsg_FPPModeChange", 0, "", "")
    end
  end
end

function BRPlayerCharacterBase:HandleFinishedState()
  print(bWriteLog and "BRPlayerCharacterBase:HandleFinishedState", self.STCharacterMovement)
  if slua.isValid(self.STCharacterMovement) and self.STCharacterMovement.SetDynamicSimpleQueryConfigDisable then
    local EDynamicSimpleQueryConfigDisableMask = import("EDynamicSimpleQueryConfigDisableMask")
    self.STCharacterMovement:SetDynamicSimpleQueryConfigDisable(EDynamicSimpleQueryConfigDisableMask.Bit0, true)
  end
end

function BRPlayerCharacterBase:OnRespawnRehideCheck()
  if not self:GetEnsure() then
    return
  end
  self:AddGameTimer(0.5, false, function()
    if not slua.isValid(self.Object) then
      return
    end
    if self:HasState(EPawnState.InPlane) then
      self:SetCharacterHideInGame(true, true, true, 1, ECharacterHideMovementAcive.Normal)
      print(bWriteLog and "BRPlayerCharacterBase:OnRespawnRehideCheck re-hide AI on plane, PlayerKey:", self.PlayerKey)
    end
  end)
end

function BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent()
  if CGameMode and CGameMode.GameModeType and CGameState and CGameState.GameModeID then
    local GameModeType = CGameMode.GameModeType
    local GameModeID = tonumber(CGameState.GameModeID)
    local bModeTypeSatisfy = GameModeType == EGameModeType.ETypicalGameMode or GameModeType == EGameModeType.EFourInOneGameMode or GameModeType == EGameModeType.EHeavyWeaponGameMode
    local bModeIDSatisfy = not MatchModeIds[GameModeID]
    print(bWriteLog and bWriteLog and "BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent:", GameModeType, GameModeID, bModeTypeSatisfy, bModeIDSatisfy)
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
        if uCurrentPlayerControl.CheckParachuteOpenFeature.RecoverParachuteOpenParam then
          uCurrentPlayerControl.CheckParachuteOpenFeature:RecoverParachuteOpenParam()
        end
        if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then
          uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState()
        end
      end
    end
  end
end

function BRPlayerCharacterBase:OnLanded()
  printf("BRPlayerCharacterBase:OnLanded PlayerKey:%d", self.PlayerKey)
  if self.HandleOnLanded then
    self:HandleOnLanded(-1)
  end
  if not Client then
    local uCurrentPlayerControl = self:GetPlayerControllerSafety()
    if slua.isValid(uCurrentPlayerControl) and uCurrentPlayerControl.CheckParachuteOpenFeature then
      if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then
        uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState()
      end
      if uCurrentPlayerControl.CheckParachuteOpenFeature.ResetCheckShowUI then
        uCurrentPlayerControl.CheckParachuteOpenFeature:ResetCheckShowUI()
      end
    end
  end
end

function BRPlayerCharacterBase:ReceiveEndPlay(EndPlayReason)
  BRPlayerCharacterBase.__super.ReceiveEndPlay(self, EndPlayReason)
  if Client then
    GameplayData.RemoveCharacter(self.Object)
  end
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
  print(bWriteLog and string.format("%s BPOnRecycled()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
  end
end

function BRPlayerCharacterBase:BPOnRespawned()
  print(bWriteLog and string.format("%s BPOnRespawned()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
  end
end

function BRPlayerCharacterBase:ReceiveOnRecycle()
  print(bWriteLog and string.format("%s IReusable:ReceiveOnRecycle()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
    GameplayData.RemoveCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:ReceiveOnSpawn()
  print(bWriteLog and string.format("%s IReusable:ReceiveOnSpawn()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
    GameplayData.AddCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:ResetMeshRelativeLocationAndRotation()
  if Game:IsValid(self.Object) and Game:IsValid(self.Mesh) then
    local uDefaultMeshRot = FRotator(0, -90, 0)
    local uDefaultMeshRelativeLoc = FVector(0, 0, 0)
    if self.Mesh.K2_SetRelativeRotation then
      self.Mesh:K2_SetRelativeRotation(uDefaultMeshRot, false, nil, false)
    end
    self:CacheInitialMeshOffset(uDefaultMeshRelativeLoc, uDefaultMeshRot)
    local vRelativeRot = self.Mesh.RelativeRotation
    local vBaseRotationOffset = self.BaseRotationOffset
    local vBaseRotation = Game:QuatToRotator(vBaseRotationOffset)
    print(bWriteLog and bWriteLog and string.format("%s ResetMeshRelativeLocationAndRotation() Mesh.RelativeRotation: %s %s %s   Pawn.BaseRotationOffset:%s %s %s ", Game:GetPlainName(self.Object), tostring(vRelativeRot.Pitch), tostring(vRelativeRot.Yaw), tostring(vRelativeRot.Roll), tostring(vBaseRotation.Pitch), tostring(vBaseRotation.Yaw), tostring(vBaseRotation.Roll)))
  end
end

function BRPlayerCharacterBase:HandleOnMovementModeChangedNew()
  print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged11")
  if Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Swimming and self:CheckBaseIsMoveable() then
    print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged22")
    self.CharacterMovement:SetBase(nil, "", true)
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy and Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Walking and UIManager.UI_Config_InGame.ParachuteOpenUI then
    print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChangedNew CloseUI")
    UIManager.CloseUI(UIManager.UI_Config_InGame.ParachuteOpenUI)
  end
end

function BRPlayerCharacterBase:BPOnMissPlayerDamageRecord()
end

function BRPlayerCharacterBase:PreAttachedToVehicle()
  local IsDS = UKismetSystemLibrary.IsDedicatedServer(self)
  if not IsDS then
    return
  end
  local MainPlayerController = self:GetPlayerControllerSafety()
  if not slua.isValid(MainPlayerController) then
    return
  end
  local CharacterAvatarComp2_BP = self.CharacterAvatarComp2_BP
  if not slua.isValid(CharacterAvatarComp2_BP) then
    return
  end
  local CommerAvatarDataUtil = require("GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil")
  local changedVehicleId = CommerAvatarDataUtil:ChangeVehicleSkinByClothes(MainPlayerController, CharacterAvatarComp2_BP)
  local ESTExtraVehicleShapeType = import("ESTExtraVehicleShapeType")
  if changedVehicleId then
    local UAvatarUtils = import("AvatarUtils")
    if UAvatarUtils.GetVehicleShapeBySkinID(changedVehicleId) == ESTExtraVehicleShapeType.VST_Horse then
      local uCurPlayerState = self:GetPlayerStateSafety()
      if slua.isValid(uCurPlayerState) then
        print(bWriteLog and "  BRPlayerCharacterBase:PreAttachedToVehicle. changedVehicleId: " .. tostring(changedVehicleId))
        uCurPlayerState:AddGeneralCount(468, 1, false)
      end
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
      print(bWriteLog and "BRPlayerCharacterBase:ParachuteJump over")
    else
      EventSystem:postEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_AI_CALL_PARACHUTE_JUMP, self.Object)
      print(bWriteLog and "BRPlayerCharacterBase:ParachuteJump AI JUMP over, Loc=", tostring(self:K2_GetActorLocation():ToString()))
    end
  end
end

function BRPlayerCharacterBase:OnMovementBaseChangedEvent(uCharacter, uNewMovementBase, uOldMovementBase)
  if uCharacter ~= self.Object then
    return
  end
  print(bWriteLog and string.format("BRPlayerCharacterBase:OnMovementBaseChangedEvent %s, Base: %s -> %s", uCharacter, uOldMovementBase, uNewMovementBase))
  local MedievalCrane = self:GetMedievalCraneFromBase(uNewMovementBase)
  if MedievalCrane and MedievalCrane.AddCharacter then
    MedievalCrane:AddCharacter(self.Object)
  else
    MedievalCrane = self:GetMedievalCraneFromBase(uOldMovementBase)
    if MedievalCrane and MedievalCrane.RemoveCharacter then
      MedievalCrane:RemoveCharacter(self.Object)
    end
  end
end

function BRPlayerCharacterBase:GetMedievalCraneFromBase(Base)
  if not slua.isValid(Base) or not Base.GetOwner then
    return
  end
  local Lifter = Base:GetOwner()
  if not slua.isValid(Lifter) then
    return
  end
  if not Lifter.AddCharacter then
    return
  end
  return Lifter
end

function BRPlayerCharacterBase:CheckForbidFlaregun()
  local uPlayerState = self:GetPlayerStateSafety()
  if not slua.isValid(uPlayerState) then
    return false
  end
  if uPlayerState.CanUseFlaregun == false and self:IsLocallyControlled() then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:DisplayGameTipWithMsgID(48532)
    end
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
    if slua.isValid(uPlayerState) then
      uPlayerState:AddGeneralCount(1613, 1, false)
    end
    uNearDeathComp:TriggerGotoDieExplictly(self.Object)
  end
end

function BRPlayerCharacterBase:RPC_Server_GmPlayAction(actionId)
  log(bWriteLog and "  BRPlayerCharacterBase:RPC_Server_GmPlayAction.  actionId: " .. tostring(actionId))
  if USTExtraBlueprintFunctionLibrary.IsDevelopment() then
    log(bWriteLog and "  BRPlayerCharacterBase:RPC_Server_GmPlayAction. IsDevelopment actionId: " .. tostring(actionId))
    self:MulticastRPC_GmPlayAction(actionId)
  end
end

function BRPlayerCharacterBase:MulticastRPC_GmPlayAction(actionId)
  if not Client then
    return
  end
  log(bWriteLog and "  BRPlayerCharacterBase:MulticastRPC_GmPlayAction.  actionId: " .. tostring(actionId))
  local uPlayEmoteComp = self:GetPlayEmoteComponent()
  if not slua.isValid(uPlayEmoteComp) then
    return
  end
  local LogFilter = require("common.log_filter")
  LogFilter.SetLogTreeEnable(true)
  local animCfg = CDataTable.GetTableData("EmoteBPTable", actionId)
  if not animCfg then
    return
  end
  local handlePath = animCfg.Path
  local EmoteHandleAsset = slua.loadObject(handlePath)
  local assetsArray = slua.Array(UEnums.EPropertyClass.Struct, import("/Script/CoreUObject.SoftObjectPath"))
  local handle = EmoteHandleAsset()
  uPlayEmoteComp:OnLoadEmoteAssetBegin(handle, actionId, assetsArray, "")
  log(bWriteLog and "  BRPlayerCharacterBase:MulticastRPC_GmPlayAction. assetsArray:Num(): " .. tostring(assetsArray:Num()))
  local tb = FuncUtil.LuaArrayToTable(assetsArray)
  local asset_util = require("common.asset_util")
  
  local function loadLater()
    uPlayEmoteComp:OnLoadEmoteAssetEnd(handle, actionId, 0)
  end
  
  asset_util.GetAssetsArrayAsyncParallel(tb, loadLater)
end

function BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall(bServerSyncShouldCheckPassWall)
  print(bWriteLog and "BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall " .. tostring(bServerSyncShouldCheckPassWall))
  if slua.isValid(self.ParachuteComponent) then
    self.ParachuteComponent.bServerSyncShouldCheckPassWall = bServerSyncShouldCheckPassWall
  end
end

function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState()
  self.Super:OnPlayerEnterCarryBoxState()
  local CharName = self:GetPlayerNameSafety()
  print(bWriteLog and string.format("DeadBoxLog BRPlayerCharacterBase:OnPlayerEnterCarryBoxState Role:%s PlayerKey:%s Name:%s", tostring(self.Role), tostring(self.PlayerKey), tostring(CharName)))
  if self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState()
  end
end

function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  self.Super:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  local CharName = self:GetPlayerNameSafety()
  print(bWriteLog and string.format("DeadBoxLog BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState Role:%s PlayerKey:%s Name:%s bInIsInterrupt:%s", tostring(self.Role), tostring(self.PlayerKey), tostring(CharName), tostring(bInIsInterrupt)))
  if self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  end
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
  print(bWriteLog and "BRPlayerCharacterBase:CannotChangeIntoPetSpectator")
  return self.bCannotChangeIntoPetSpectator
end

function BRPlayerCharacterBase:DoModChangeToBT()
  print(bWriteLog and string.format("BRPlayerCharacterBase:DoModChangeToBT, PlayerKey=%s", tostring(self.PlayerKey)))
  if self:HasState(EPawnState.SpecialSuit) then
    self:TriggerEntrySkillWithID(4301101, true)
    print(bWriteLog and string.format("BRPlayerCharacterBase:DoModChangeToBT, PlayerKey=%s, HasState(EPawnState.SpecialSuit)", tostring(self.PlayerKey)))
  end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteOpening()
  print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteOpening")
  self.Super:SwitchCameraToParachuteOpening()
  if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
    self.ParachuteFormation:OverlayFormationCameraParams()
    print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteOpening - Formation camera overlaid")
  end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteFalling()
  print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteFalling")
  self.Super:SwitchCameraToParachuteFalling()
  if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
    self.ParachuteFormation:OverlayFormationCameraParams()
    print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteFalling - Formation camera overlaid")
  end
end

function BRPlayerCharacterBase:SwitchCameraToNormal()
  print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToNormal")
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
        print(bWriteLog and "BRPlayerCharacterBase:SwitchWeaponCheck not allow switch weapon in AttachToOther, WeaponID: " .. tostring(WeaponID))
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
        print(bWriteLog and "BRPlayerCharacterBase:SwitchWeaponCheck blocked by SpiderSwing state: " .. tostring(nCurState))
        return false
      end
    end
  end
  return self.Super:SwitchWeaponCheck(Slot, IgnoreState)
end

local VICTORY_DANCE_FX_MAP = {
  [12219601] = 22010089
}
local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
local isFitVersion = PublishRegionMacros.IsFITVersion()

local function ResolveEmoteResID(ItemID)
  local FxID = VICTORY_DANCE_FX_MAP[ItemID]
  if not FxID or FxID == ItemID then
    return ItemID
  end
  local model_util = require("client.common.model_util")
  local FxBPID = model_util.GetBPID(FxID)
  local ResID = ItemID
  if FxBPID and 0 < FxBPID and model_util.IsBattleItemHandleExist("Emote", FxBPID, false, false) then
    ResID = FxID
  end
  print(bWriteLog and string.format("BRPlayerCharacterBase 11 ResolveEmoteResID ItemID:%s, FxID:%s, FxBPID:%s, ResID:%s", tostring(ItemID), tostring(FxID), tostring(FxBPID), tostring(ResID)))
  if isFitVersion and ResID == 12219601 then
    print(bWriteLog and "BRPlayerCharacterBase ResolveEmoteResID 12219601 to 12222069")
    return 12222069
  end
  return ResID
end

function BRPlayerCharacterBase:GetEmoteHandlePath(ItemID)
  local ResID = ResolveEmoteResID(ItemID)
  if self.Super then
    return self.Super:GetEmoteHandlePath(ResID)
  end
  local model_util = require("client.common.model_util")
  local BPID = model_util.GetBPID(ResID)
  if not BPID or BPID <= 0 then
    return ""
  end
  return model_util.GetPath("Emote", BPID, false, false) or ""
end

function BRPlayerCharacterBase:GetEmoteHandle(ItemID)
  local ResID = ResolveEmoteResID(ItemID)
  if self.Super then
    return self.Super:GetEmoteHandle(ResID)
  end
  local model_util = require("client.common.model_util")
  local BPID = model_util.GetBPID(ResID)
  if not BPID or BPID <= 0 then
    return nil
  end
  local HandleClass = model_util.GetClass("Emote", BPID, false, false)
  if not HandleClass then
    return nil
  end
  local Handle = HandleClass()
  if not slua.isValid(Handle) then
    return nil
  end
  return Handle
end

local class = require("class")
local CCharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CBRPlayerCharacterBase = class(CCharacterBase, nil, BRPlayerCharacterBase)
return require("combine_class").DeclareFeature(CBRPlayerCharacterBase, {
  {
    SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature"
  },
  {
    CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature"
  },
  {
    SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature"
  },
  {
    TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature"
  },
  {
    LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature"
  },
  {
    FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature"
  },
  {
    CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature"
  },
  {
    BuildAircraftVehicleFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature"
  },
  {
    UnifiedBuildVehicleFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.UnifiedBuildVehicleFeature"
  },
  {
    CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature"
  },
  {
    ParachuteFormation = "GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature"
  },
  {
    ParachuteSprint = "GameLua.Mod.BaseMod.GamePlay.Feature.Parachute.ParachuteSprintFeature"
  },
  {
    GeneralShowSpotFeature = "GameLua.Mod.BRMod.Gameplay.Feature.PlayerCharacterGeneralShowSpotFeature"
  },
  {
    FPPAnimMonitor = "GameLua.Mod.BaseMod.GamePlay.Feature.Player.FPPAnimMonitorFeature"
  }
}, "BRPlayerCharacterBase")