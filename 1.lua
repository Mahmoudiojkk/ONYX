if not _G.AK_GetVal then
  _G.AK_SETTINGS = _G.AK_SETTINGS or {
    ESP_FULL_INFO = 1,
    ESP_BOX       = 1,
    ESP_HEALTH    = 1,
    ESP_NAME      = 1,
    ESP_DISTANCE  = 1,
    ESP_TEAMID    = 0,
    ESP_LINE      = 1,
    ESP_WEAPON    = 0,
    ESP_HEALTH_POS = 1,
  }
  function _G.AK_GetVal(key)
    return _G.AK_SETTINGS and _G.AK_SETTINGS[key] or 0
  end
end

if not _G.AK_CheckIsBot then
  function _G.AK_CheckIsBot(Character)
    local isNormalBot, isMLBot = false, false
    pcall(function()
      if Game and Game.IsAI and Game:IsAI(Character) then
        isNormalBot = true
      end
      if Character and Character.IsMLBot then
        isMLBot = Character:IsMLBot() and true or false
      end
    end)
    return isNormalBot, isMLBot
  end
end

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

-- ============================================================
-- ESP MODULE (inlined, driven by this character's lifecycle)
-- ============================================================
local ESP = {}
ESP.bActive = false
ESP.ESPCanvas = nil
ESP.ESPWidgets = {}
ESP.ESPWidgetPtrs = {}
ESP.SnapLineWidgets = {}
ESP.BoxWidgets = {}
ESP.HealthWidgets = {}
ESP.CustomTextWidgets = {}
ESP.WidgetComps = {}
ESP.MarkMap = {}
ESP.PlayerInfo = {}
ESP._FrameCount = 0
ESP._MasterTimerHandle = nil
ESP._LastPC = nil
ESP._cachedViewportW = 1920
ESP._cachedViewportH = 1080
ESP._CanvasScaleX = 1.0
ESP._CanvasScaleY = 1.0
ESP._CanvasOffsetX = 0.0
ESP._CanvasOffsetY = 0.0
ESP._OBHeadWidgetClass = nil
ESP._OBHeadWidgetLoadFailed = false
ESP._bAllPathsFailed = false
ESP._WorkingWidgetPath = nil
ESP._FailedWidgetPaths = {}
ESP._bScreenMarkConfigSetup = false
ESP._NavInstIDCounter = 1000

ESP.bIncludeMe = false
ESP.bIncludeAI = true
ESP.bUseScreenESP = true
ESP.bUseSnapLines = false
ESP.bShowDistance = true
ESP.bUseServerMarks = false
ESP.bUseQuickSign = false
ESP.bUseNavigator = false
ESP.bUseWidgetComponent = false
ESP.MarkTypeID = 1007
ESP.nHeavyScanFrameInterval = 15
ESP.nDistanceUpdateFrameInterval = 5
ESP.SnapLineThickness = 1
ESP.SnapLineOriginY = 50
ESP.SnapLineOriginX = 0
ESP.SnapLineColor = nil
ESP.SnapLineOpacity = 0.7
ESP.WidgetCompUIPath = "/Game/BluePrints/ControlInput/NewbieItem/NewbieTips_ConsumeTips.NewbieTips_ConsumeTips"
ESP.WidgetCompBoneName = "head"
ESP.WidgetCompOffset = FVector(0, 0, 80)
ESP.WidgetCompDrawSize = FVector2D(300, 50)
ESP.HPWidgetSwitcherTypeIndex = 0
ESP.HPWidgetSwitcherType2Index = 0
ESP.ESPWorldOffsetZ = 0
ESP.ESPScreenOffsetY = 0
ESP.ESPAnchorOffsetX = 0
ESP.ESPAnchorOffsetY = 0

local function AK_IsValid(obj)
  if obj == nil then return false end
  if slua and slua.isValid then return slua.isValid(obj) end
  return obj ~= nil
end

local function AK_GetVal(key)
  if _G.AK_GetVal then
    return _G.AK_GetVal(key)
  end
  return 0
end

local function AK_GetMapAddedFlag()
  if ESP.MapAddedFlag ~= nil then return ESP.MapAddedFlag end
  if UEnums and UEnums.EAddMarkFlag and UEnums.EAddMarkFlag.EAMF_Both then
    return UEnums.EAddMarkFlag.EAMF_Both
  end
  return 3
end

local function AK_CheckIsBot(Character)
  local isNormalBot, isMLBot = false, false
  if _G.AK_CheckIsBot then
    isNormalBot, isMLBot = _G.AK_CheckIsBot(Character)
  end
  return isNormalBot, isMLBot
end

function ESP.GetGameplayData()
  if ESP._CachedGameplayData then return ESP._CachedGameplayData end
  local ok, GDP = pcall(function()
    return require("GameLua.GameCore.Data.GameplayData")
  end)
  if ok and GDP then
    ESP._CachedGameplayData = GDP
    return GDP
  end
  return nil
end

function ESP.GetMyPlayerController()
  local PC = ESP._CachedPC
  if PC and AK_IsValid(PC) then return PC end
  local GDP = ESP.GetGameplayData()
  if not GDP then return nil end
  pcall(function() PC = GDP.GetPlayerController and GDP.GetPlayerController() end)
  if PC and AK_IsValid(PC) then
    ESP._CachedPC = PC
    return PC
  end
  return nil
end

function ESP.GetCGameState()
  if CGameState and AK_IsValid(CGameState) then return CGameState end
  if ESP._CachedCGameState and AK_IsValid(ESP._CachedCGameState) then
    return ESP._CachedCGameState
  end
  local ok, GS = pcall(function()
    return require("GameLua.GameCore.Data.CGameState")
  end)
  if ok and GS then
    ESP._CachedCGameState = GS
    return GS
  end
  return nil
end

function ESP.GetAllCharacters()
  local AllChars = {}
  pcall(function()
    local Pawns = Game:GetAllPlayerPawns()
    if Pawns then
      for _, Pawn in pairs(Pawns) do
        if Pawn and slua.isValid(Pawn) then
          local pKey = nil
          if Pawn.GetPlayerKey then pKey = Pawn:GetPlayerKey() end
          if not pKey and Pawn.PlayerKey then pKey = Pawn.PlayerKey end
          if not pKey and Pawn.PlayerState and Pawn.PlayerState.PlayerKey then
            pKey = Pawn.PlayerState.PlayerKey
          end
          if pKey then AllChars[pKey] = Pawn end
        end
      end
    end
  end)
  if not next(AllChars) then
    local GS = ESP.GetCGameState()
    if GS and GS.GetAllCharacters then
      pcall(function() AllChars = GS:GetAllCharacters() end)
    end
  end
  return AllChars
end

function ESP.GetMyPlayerKey()
  local PC = ESP.GetMyPlayerController()
  if not AK_IsValid(PC) then return nil end
  local MyKey = nil
  pcall(function()
    if PC.GetPlayerKey then MyKey = PC:GetPlayerKey()
    elseif PC.PlayerState and PC.PlayerState.PlayerKey then
      MyKey = PC.PlayerState.PlayerKey
    end
  end)
  return MyKey
end

function ESP.IsMe(Character, PlayerKey, MyKey)
  local bIsMe = false
  pcall(function()
    local GDP = ESP.GetGameplayData()
    if GDP and GDP.GetLocalCharacter then
      local MyChar = GDP.GetLocalCharacter()
      if MyChar and Character == MyChar then bIsMe = true; return end
    end
    local PC = ESP.GetMyPlayerController()
    if PC and PC.GetPawn then
      local Pawn = PC:GetPawn()
      if Pawn and Character == Pawn then bIsMe = true; return end
    end
  end)
  if not bIsMe and MyKey ~= nil and PlayerKey ~= nil then
    bIsMe = (tostring(PlayerKey) == tostring(MyKey))
  end
  return bIsMe
end

function ESP.GetCharacterLocation(Character)
  if not AK_IsValid(Character) then return nil end
  local Loc = nil
  pcall(function()
    if Character.K2_GetActorLocation then
      Loc = Character:K2_GetActorLocation()
    end
  end)
  if not Loc then
    pcall(function()
      if Game and Game.GetActorLocation then
        Loc = Game:GetActorLocation(Character)
      end
    end)
  end
  return Loc
end

function ESP.CalcDistance(Loc1, Loc2)
  if not Loc1 or not Loc2 then return nil end
  local Dist = nil
  pcall(function()
    if FVector and FVector.Dist2D then
      Dist = FVector.Dist2D(Loc1, Loc2)
    end
  end)
  if not Dist then
    pcall(function()
      local DX = (Loc1.X or 0) - (Loc2.X or 0)
      local DY = (Loc1.Y or 0) - (Loc2.Y or 0)
      Dist = math.sqrt(DX * DX + DY * DY)
    end)
  end
  return Dist
end

function ESP.GetDistanceString(MyLoc, TargetLoc)
  if not ESP.bShowDistance then return "" end
  if not MyLoc or not TargetLoc then return "" end
  local Dist = ESP.CalcDistance(MyLoc, TargetLoc)
  if not Dist then return "" end
  local Meters = Dist / 100
  if Meters < 1000 then
    return tostring(math.floor(Meters)) .. "m"
  else
    local kmFloor = math.floor((Meters / 1000) * 10) / 10
    return tostring(kmFloor) .. "km"
  end
end

function ESP.GetMyLocation()
  local GDP = ESP.GetGameplayData()
  if not GDP then return nil end
  local MyChar = nil
  pcall(function() MyChar = GDP.GetLocalCharacter and GDP.GetLocalCharacter() end)
  if not AK_IsValid(MyChar) then
    local PC = ESP.GetMyPlayerController()
    if AK_IsValid(PC) and PC.GetPawn then
      pcall(function()
        local Pawn = PC:GetPawn()
        if AK_IsValid(Pawn) and Pawn.K2_GetActorLocation then
          return Pawn:K2_GetActorLocation()
        end
      end)
    end
    return nil
  end
  return ESP.GetCharacterLocation(MyChar)
end

function ESP.GetPlayerName(Character)
  if not AK_IsValid(Character) then return "Unknown" end
  local Name = nil
  pcall(function()
    if Character.GetPlayerNameSafety then
      Name = Character:GetPlayerNameSafety()
    end
  end)
  if not Name then
    pcall(function()
      local PS = nil
      if Character.GetPlayerStateSafety then
        PS = Character:GetPlayerStateSafety()
      elseif Character.GetPlayerState then
        PS = Character:GetPlayerState()
      end
      if AK_IsValid(PS) and PS.GetPlayerName then
        Name = PS:GetPlayerName()
      end
    end)
  end
  return Name or "Unknown"
end

function ESP.IsAI(Character)
  local bAI = false
  pcall(function()
    if Game and Game.IsAI then bAI = Game:IsAI(Character) end
  end)
  return bAI
end

function ESP.IsAlive(Character)
  local bAlive = true
  pcall(function()
    if Character.IsAlive then bAlive = Character:IsAlive() end
  end)
  return bAlive
end

function ESP.GetTeamID(Character)
  if not AK_IsValid(Character) then return nil end
  local TeamID = nil
  pcall(function()
    if Character.GetTeamID then TeamID = Character:GetTeamID() end
  end)
  if not TeamID then
    pcall(function()
      local PS = nil
      if Character.GetPlayerStateSafety then
        PS = Character:GetPlayerStateSafety()
      elseif Character.GetPlayerState then
        PS = Character:GetPlayerState()
      end
      if AK_IsValid(PS) and PS.GetTeamID then TeamID = PS:GetTeamID()
      elseif AK_IsValid(PS) and PS.TeamID then TeamID = PS.TeamID end
    end)
  end
  if not TeamID then
    pcall(function()
      if Character.TeamID then TeamID = Character.TeamID end
    end)
  end
  return TeamID
end

function ESP.GetTeamColor(TeamID)
  if TeamID == nil then return nil end
  local TeamColors = {
    [1] = FLinearColor(1.0, 0.2, 0.2, 1.0),
    [2] = FLinearColor(0.2, 0.4, 1.0, 1.0),
    [3] = FLinearColor(0.2, 0.9, 0.3, 1.0),
    [4] = FLinearColor(1.0, 0.9, 0.2, 1.0),
    [5] = FLinearColor(0.8, 0.3, 1.0, 1.0),
    [6] = FLinearColor(0.2, 0.9, 0.9, 1.0),
    [7] = FLinearColor(1.0, 0.5, 0.2, 1.0),
    [8] = FLinearColor(1.0, 0.4, 0.7, 1.0),
  }
  local color = TeamColors[TeamID]
  if color then return color end
  if TeamID == 1 then return FLinearColor(1.0, 0.2, 0.2, 1.0)
  else return FLinearColor(0.2, 0.4, 1.0, 1.0) end
end

function ESP.GetCharacterMesh(Character)
  if not AK_IsValid(Character) then return nil end
  local Mesh = nil
  pcall(function()
    if Character.Mesh and Game:IsValid(Character.Mesh) then
      Mesh = Character.Mesh
    end
  end)
  if not Mesh then
    pcall(function()
      local SkeletalMeshCompClass = import("/Script/Engine.SkeletalMeshComponent")
      Mesh = Character:GetComponentByClass(SkeletalMeshCompClass)
    end)
  end
  return Mesh
end

function ESP.ApplyWorldOffset(Loc, OffsetZ)
  if not Loc then return nil end
  if not OffsetZ or OffsetZ == 0 then return Loc end
  local ok = pcall(function() Loc.Z = Loc.Z + OffsetZ end)
  if ok then return Loc end
  local result = nil
  pcall(function()
    local X = Loc.X or 0
    local Y = Loc.Y or 0
    local Z = (Loc.Z or 0) + OffsetZ
    if FVector then result = FVector(X, Y, Z) end
  end)
  return result or Loc
end

function ESP.GetESPLocation(Character)
  if not AK_IsValid(Character) then return nil end
  local BoneLoc = ESP.GetCharacterLocation(Character)
  if BoneLoc then
    local heightOffset = 65
    pcall(function()
      if Character.bIsCrouched then heightOffset = 40 end
      if Character.IsProne and Character:IsProne() then heightOffset = 15 end
    end)
    BoneLoc = ESP.ApplyWorldOffset(BoneLoc, heightOffset + (ESP.ESPWorldOffsetZ or 0))
  end
  return BoneLoc
end

-- ============================================================
-- Canvas / Projection helpers
-- ============================================================
function ESP.InitESPCanvas()
  if ESP.ESPCanvas and Game:IsValid(ESP.ESPCanvas) then
    return true
  end
  local InGameUITools = nil
  pcall(function() InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools") end)
  if not InGameUITools then return false end
  local MainControlBaseUI = nil
  pcall(function() MainControlBaseUI = InGameUITools.GetMainControlBaseUI() end)
  if not MainControlBaseUI or not Game:IsValid(MainControlBaseUI) then return false end
  local ParentCanvas = nil
  pcall(function()
    if MainControlBaseUI.CanvasPanel_0 and Game:IsValid(MainControlBaseUI.CanvasPanel_0) then
      ParentCanvas = MainControlBaseUI.CanvasPanel_0
    elseif MainControlBaseUI.CanvasPanel_42 and Game:IsValid(MainControlBaseUI.CanvasPanel_42) then
      ParentCanvas = MainControlBaseUI.CanvasPanel_42
    end
  end)
  if not ParentCanvas then return false end
  ESP.ESPCanvas = ParentCanvas
  return true
end

function ESP.UpdateCanvasTransform(PC)
  if not ESP.ESPCanvas or not Game:IsValid(ESP.ESPCanvas) then return end
  local SlateBlueprintLibrary = import("SlateBlueprintLibrary") or import("/Script/UMG.SlateBlueprintLibrary")
  local WidgetLayoutLibrary = import("WidgetLayoutLibrary") or import("/Script/UMG.WidgetLayoutLibrary")
  local success = false
  pcall(function()
    if SlateBlueprintLibrary and SlateBlueprintLibrary.AbsoluteToLocal then
      local cg = ESP.ESPCanvas:GetCachedGeometry()
      if cg then
        local pt0 = SlateBlueprintLibrary.AbsoluteToLocal(cg, FVector2D(0, 0))
        local pt1 = SlateBlueprintLibrary.AbsoluteToLocal(cg, FVector2D(100, 100))
        if pt0 and pt1 then
          ESP._CanvasScaleX = (pt1.X - pt0.X) / 100
          ESP._CanvasScaleY = (pt1.Y - pt0.Y) / 100
          ESP._CanvasOffsetX = pt0.X
          ESP._CanvasOffsetY = pt0.Y
          success = true
        end
      end
    end
  end)
  if not success then
    pcall(function()
      if WidgetLayoutLibrary and WidgetLayoutLibrary.ScreenToWidgetLocal then
        local cg = ESP.ESPCanvas:GetCachedGeometry()
        if cg then
          local pt0 = FVector2D(0, 0)
          local pt1 = FVector2D(0, 0)
          WidgetLayoutLibrary.ScreenToWidgetLocal(PC, cg, FVector2D(0, 0), pt0)
          WidgetLayoutLibrary.ScreenToWidgetLocal(PC, cg, FVector2D(100, 100), pt1)
          ESP._CanvasScaleX = (pt1.X - pt0.X) / 100
          ESP._CanvasScaleY = (pt1.Y - pt0.Y) / 100
          ESP._CanvasOffsetX = pt0.X
          ESP._CanvasOffsetY = pt0.Y
          success = true
        end
      end
    end)
  end
  if not success then
    local scale = 1.0
    if WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportScale then
      scale = WidgetLayoutLibrary.GetViewportScale(PC) or 1.0
    end
    ESP._CanvasScaleX = 1.0 / scale
    ESP._CanvasScaleY = 1.0 / scale
    ESP._CanvasOffsetX = 0
    ESP._CanvasOffsetY = 0
  end
end

function ESP.ScreenPixelToCanvasLocal(PC, ScreenPixelPos)
  if not ScreenPixelPos then return FVector2D(0, 0) end
  local scaleX = ESP._CanvasScaleX or 1.0
  local scaleY = ESP._CanvasScaleY or 1.0
  local offsetX = ESP._CanvasOffsetX or 0
  local offsetY = ESP._CanvasOffsetY or 0
  return FVector2D(ScreenPixelPos.X * scaleX + offsetX, ScreenPixelPos.Y * scaleY + offsetY)
end

function ESP.ProjectWorldToCanvasLocal(PC, WorldLoc)
  if not AK_IsValid(PC) or not WorldLoc then return false, FVector2D(0, 0) end
  local ScreenPixelPos = FVector2D(0, 0)
  local bOK = false
  pcall(function()
    local res = PC:ProjectWorldLocationToScreen(WorldLoc, ScreenPixelPos, true)
    if res == true or res == 1 or (ScreenPixelPos and (ScreenPixelPos.X ~= 0 or ScreenPixelPos.Y ~= 0)) then
      bOK = true
    end
  end)
  if not bOK or not ScreenPixelPos or (ScreenPixelPos.X == 0 and ScreenPixelPos.Y == 0) then
    return false, FVector2D(0, 0)
  end
  local CanvasLocalPos = ESP.ScreenPixelToCanvasLocal(PC, ScreenPixelPos)
  return true, CanvasLocalPos
end

-- ============================================================
-- Widget creation helpers
-- ============================================================
function ESP.CreateBoxLine()
  if not ESP.ESPCanvas or not Game:IsValid(ESP.ESPCanvas) then return nil end
  local Border = nil
  pcall(function() Border = CGame:NewObjectFromPath("/Script/UMG.Border", ESP.ESPCanvas) end)
  if not Border or not slua.isValid(Border) then return nil end
  pcall(function() Border:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
  pcall(function() Border:SetRenderTransformPivot(FVector2D(0.0, 0.0)) end)
  local Slot = nil
  pcall(function()
    Slot = ESP.ESPCanvas:AddChildToCanvas(Border)
    if Slot then
      Slot:SetAutoSize(false)
      Slot:SetZOrder(1)
    end
  end)
  return { Widget = Border, Slot = Slot, _vis = 2 }
end

function ESP.CreateTextLine()
  if not ESP.ESPCanvas or not Game:IsValid(ESP.ESPCanvas) then return nil end
  local TxtWidget = nil
  pcall(function() TxtWidget = CGame:NewObjectFromPath("/Script/UMG.TextBlock", ESP.ESPCanvas) end)
  if not TxtWidget or not slua.isValid(TxtWidget) then return nil end
  pcall(function() TxtWidget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
  pcall(function() TxtWidget:SetRenderTransformPivot(FVector2D(0.5, 0.5)) end)
  pcall(function() TxtWidget:SetJustification(1) end)
  local Slot = nil
  pcall(function()
    Slot = ESP.ESPCanvas:AddChildToCanvas(TxtWidget)
    if Slot then
      Slot:SetAutoSize(true)
      Slot:SetAlignment(FVector2D(0.5, 0.5))
      Slot:SetZOrder(3)
    end
  end)
  return { Widget = TxtWidget, Slot = Slot, _vis = 2 }
end

function ESP.CreateESPWidget()
  if not ESP.ESPCanvas or not Game:IsValid(ESP.ESPCanvas) then return nil end
  if ESP._OBHeadWidgetLoadFailed then return nil end
  if not ESP._OBHeadWidgetClass then
    pcall(function()
      local Path = "/Game/BluePrints/UI/OBUI/Item/OB_PlayerHeadHPItem_UIBP.OB_PlayerHeadHPItem_UIBP"
      local uClass = slua.loadClass(Path)
      if uClass then ESP._OBHeadWidgetClass = uClass end
    end)
    if not ESP._OBHeadWidgetClass then
      ESP._OBHeadWidgetLoadFailed = true
      return nil
    end
  else
    local bValid = false
    pcall(function() bValid = slua.isValid(ESP._OBHeadWidgetClass) end)
    if not bValid then
      ESP._OBHeadWidgetLoadFailed = true
      ESP._OBHeadWidgetClass = nil
      return nil
    end
  end
  local Widget = nil
  pcall(function()
    local STExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
    local PC = ESP.GetMyPlayerController()
    local OuterObj = AK_IsValid(PC) and PC.Object or ESP.ESPCanvas
    Widget = STExtraBlueprintFunctionLibrary.CreateWidgetByClass(ESP._OBHeadWidgetClass, OuterObj)
  end)
  if not Widget then return nil end
  pcall(function() Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
  pcall(function() Widget:SetRenderOpacity(1.0) end)
  Widget._vis = 0
  local NameText = nil
  pcall(function()
    NameText = Widget.TextBlock_TeamName
    if NameText and slua.isValid(NameText) then
      pcall(function() NameText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
    end
    if Widget.TextBlock_PlayerName and slua.isValid(Widget.TextBlock_PlayerName) then
      pcall(function() Widget.TextBlock_PlayerName:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
    end
    local WS_Type = Widget.WidgetSwitcher_Type
    local WS_Type2 = Widget.WidgetSwitcher_Type2
    if WS_Type and slua.isValid(WS_Type) then
      pcall(function() WS_Type:SetActiveWidgetIndex(ESP.HPWidgetSwitcherTypeIndex) end)
    end
    if WS_Type2 and slua.isValid(WS_Type2) then
      pcall(function() WS_Type2:SetActiveWidgetIndex(ESP.HPWidgetSwitcherType2Index) end)
    end
  end)
  return {
    Container = Widget,
    NameText = NameText,
    HasChildren = (NameText ~= nil)
  }
end

-- ============================================================
-- Box / Health / Text updates
-- ============================================================
function ESP.Update2DBox(KeyStr, topPos, bottomPos, color, isVisible)
  ESP.BoxWidgets = ESP.BoxWidgets or {}
  local box = ESP.BoxWidgets[KeyStr]
  if not isVisible then
    if box then
      for i = 1, 4 do
        local line = box[i]
        if line and line.Widget and slua.isValid(line.Widget) and line._vis ~= 2 then
          pcall(function() line.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
          line._vis = 2
        end
      end
    end
    return
  end
  if not box then
    box = { ESP.CreateBoxLine(), ESP.CreateBoxLine(), ESP.CreateBoxLine(), ESP.CreateBoxLine() }
    ESP.BoxWidgets[KeyStr] = box
  end
  local height = bottomPos.Y - topPos.Y
  local width = height * 0.55
  local centerX = bottomPos.X
  local tX = centerX - (width / 2)
  local tY = topPos.Y
  local bX = centerX - (width / 2)
  local bY = bottomPos.Y
  local thick = 1.3
  local lines = {
    { x = tX, y = tY, w = width, h = thick },
    { x = bX, y = bY, w = width, h = thick },
    { x = tX, y = tY, w = thick, h = height },
    { x = tX + width, y = tY, w = thick, h = height + thick }
  }
  for i = 1, 4 do
    local line = box[i]
    if line and line.Widget and line.Slot then
      if line._vis ~= 0 then
        pcall(function() line.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
        line._vis = 0
      end
      pcall(function() line.Widget:SetBrushColor(color) end)
      local nx, ny = lines[i].x, lines[i].y
      local nw, nh = lines[i].w, lines[i].h
      if not line._CachedPos or math.abs(line._CachedPos.X - nx) > 0.5 or math.abs(line._CachedPos.Y - ny) > 0.5 or
         not line._CachedSize or math.abs(line._CachedSize.X - nw) > 0.5 or math.abs(line._CachedSize.Y - nh) > 0.5 then
        line._CachedPos = line._CachedPos or FVector2D(nx, ny)
        line._CachedSize = line._CachedSize or FVector2D(nw, nh)
        line._CachedPos.X, line._CachedPos.Y = nx, ny
        line._CachedSize.X, line._CachedSize.Y = nw, nh
        pcall(function()
          line.Slot:SetPosition(line._CachedPos)
          line.Slot:SetSize(line._CachedSize)
        end)
      end
    end
  end
end

function ESP.Update2DHealthBar(KeyStr, topPos, bottomPos, pct, isVisible)
  ESP.HealthWidgets = ESP.HealthWidgets or {}
  local hpBox = ESP.HealthWidgets[KeyStr]
  if not isVisible then
    if hpBox then
      if hpBox.bg and hpBox.bg.Widget and slua.isValid(hpBox.bg.Widget) and hpBox.bg._vis ~= 2 then
        pcall(function() hpBox.bg.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end); hpBox.bg._vis = 2
      end
      if hpBox.fg and hpBox.fg.Widget and slua.isValid(hpBox.fg.Widget) and hpBox.fg._vis ~= 2 then
        pcall(function() hpBox.fg.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end); hpBox.fg._vis = 2
      end
    end
    return
  end
  if not hpBox then
    hpBox = { bg = ESP.CreateBoxLine(), fg = ESP.CreateBoxLine() }
    ESP.HealthWidgets[KeyStr] = hpBox
  end
  local barTopY = topPos.Y - 14
  local barBottomY = bottomPos.Y + 14
  local barHeight = barBottomY - barTopY
  local boxHeight = bottomPos.Y - topPos.Y
  local boxWidth = boxHeight * 0.55
  local barWidth = 4.0
  local padding = 5.0
  local centerX = bottomPos.X
  local mode = AK_GetVal("ESP_HEALTH_POS") or 1
  local bgX, bgY, bgW, bgH, fgX, fgY, fgW, fgH
  if mode == 2 then
    bgX = centerX + (boxWidth / 2) + padding; bgY = barTopY; bgW = barWidth; bgH = barHeight
    fgX = bgX; fgH = barHeight * pct; fgY = barBottomY - fgH; fgW = barWidth
  elseif mode == 3 then
    bgX = centerX - (barHeight / 2); bgY = topPos.Y - 11; bgW = barHeight; bgH = barWidth
    fgX = bgX; fgY = bgY; fgW = barHeight * pct; fgH = barWidth
  elseif mode == 4 then
    bgX = centerX - (barHeight / 2); bgY = bottomPos.Y + 7; bgW = barHeight; bgH = barWidth
    fgX = bgX; fgY = bgY; fgW = barHeight * pct; fgH = barWidth
  else
    bgX = centerX - (boxWidth / 2) - padding - barWidth; bgY = barTopY; bgW = barWidth; bgH = barHeight
    fgX = bgX; fgH = barHeight * pct; fgY = barBottomY - fgH; fgW = barWidth
  end
  local hpColor = FLinearColor(0, 1, 0, 1)
  if pct < 0.25 then hpColor = FLinearColor(1, 0, 0, 1)
  elseif pct < 0.60 then hpColor = FLinearColor(1, 1, 0, 1) end
  local bgColor = FLinearColor(0, 0, 0, 0.7)
  local drawLine = function(lineData, x, y, w, h, col)
    if lineData and lineData.Widget and lineData.Slot then
      if lineData._vis ~= 0 then
        pcall(function() lineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
        lineData._vis = 0
      end
      pcall(function() lineData.Widget:SetBrushColor(col) end)
      if not lineData._CachedPos or math.abs(lineData._CachedPos.X - x) > 0.01 or math.abs(lineData._CachedPos.Y - y) > 0.01 or
         not lineData._CachedSize or math.abs(lineData._CachedSize.X - w) > 0.01 or math.abs(lineData._CachedSize.Y - h) > 0.01 then
        lineData._CachedPos = lineData._CachedPos or FVector2D(x, y)
        lineData._CachedSize = lineData._CachedSize or FVector2D(w, h)
        lineData._CachedPos.X, lineData._CachedPos.Y = x, y
        lineData._CachedSize.X, lineData._CachedSize.Y = w, h
        pcall(function()
          lineData.Slot:SetPosition(lineData._CachedPos)
          lineData.Slot:SetSize(lineData._CachedSize)
        end)
      end
    end
  end
  drawLine(hpBox.bg, bgX, bgY, bgW, bgH, bgColor)
  drawLine(hpBox.fg, fgX, fgY, fgW, fgH, hpColor)
end

function ESP.Update2DTextData(KeyStr, topPos, bottomPos, nameStr, distStr, teamIDStr, isVisible, espColor)
  ESP.CustomTextWidgets = ESP.CustomTextWidgets or {}
  local tBox = ESP.CustomTextWidgets[KeyStr]
  if not isVisible then
    if tBox then
      if tBox.nameTxt and tBox.nameTxt.Widget and slua.isValid(tBox.nameTxt.Widget) and tBox.nameTxt._vis ~= 2 then
        pcall(function() tBox.nameTxt.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end); tBox.nameTxt._vis = 2
      end
      if tBox.distTxt and tBox.distTxt.Widget and slua.isValid(tBox.distTxt.Widget) and tBox.distTxt._vis ~= 2 then
        pcall(function() tBox.distTxt.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end); tBox.distTxt._vis = 2
      end
      if tBox.botTxt and tBox.botTxt.Widget and slua.isValid(tBox.botTxt.Widget) and tBox.botTxt._vis ~= 2 then
        pcall(function() tBox.botTxt.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end); tBox.botTxt._vis = 2
      end
    end
    return
  end
  if not tBox then
    tBox = { nameTxt = ESP.CreateTextLine(), distTxt = ESP.CreateTextLine(), botTxt = ESP.CreateTextLine() }
    ESP.CustomTextWidgets[KeyStr] = tBox
  end
  if not tBox.nameTxt then tBox.nameTxt = ESP.CreateTextLine() end
  if not tBox.distTxt then tBox.distTxt = ESP.CreateTextLine() end
  local centerX = bottomPos.X
  local applyText = function(lineData, x, y, textStr, col, fontSize)
    if lineData and lineData.Widget and lineData.Slot then
      if lineData._vis ~= 0 then
        pcall(function() lineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
        lineData._vis = 0
      end
      if lineData._lastTxt ~= textStr then
        pcall(function() lineData.Widget:SetText(textStr) end)
        lineData._lastTxt = textStr
      end
      pcall(function()
        local FSlateColor = import("SlateColor") or import("/Script/SlateCore.SlateColor")
        if FSlateColor then lineData.Widget:SetColorAndOpacity(FSlateColor(col))
        else lineData.Widget:SetColorAndOpacity(col) end
      end)
      if not lineData._fontInit then
        pcall(function()
          if lineData.Widget.Font then
            local font = lineData.Widget.Font
            font.Size = fontSize
            font.OutlineSettings.OutlineSize = 1
            font.OutlineSettings.OutlineColor = FLinearColor(0,0,0,1)
            lineData.Widget:SetFont(font)
          end
        end)
        lineData._fontInit = true
      end
      if not lineData._CachedPos or math.abs(lineData._CachedPos.X - x) > 0.01 or math.abs(lineData._CachedPos.Y - y) > 0.01 then
        lineData._CachedPos = lineData._CachedPos or FVector2D(x, y)
        lineData._CachedPos.X, lineData._CachedPos.Y = x, y
        pcall(function() lineData.Slot:SetPosition(lineData._CachedPos) end)
      end
    end
  end
  local hpMode = AK_GetVal("ESP_HEALTH_POS") or 1
  local isShowHp = AK_GetVal("ESP_HEALTH") == 1
  local yOffsetName = -26
  local yOffsetDist = -14
  local yOffsetTeam = 14
  if isShowHp then
    if hpMode == 3 then
      yOffsetName = -35; yOffsetDist = -23
    elseif hpMode == 4 then
      yOffsetTeam = 23
    end
  end
  if nameStr ~= "" then
    applyText(tBox.nameTxt, centerX, topPos.Y + yOffsetName, nameStr, FLinearColor(1, 1, 1, 1), 10)
  elseif tBox.nameTxt and tBox.nameTxt.Widget and slua.isValid(tBox.nameTxt.Widget) and tBox.nameTxt._vis ~= 2 then
    pcall(function() tBox.nameTxt.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end); tBox.nameTxt._vis = 2
  end
  if distStr ~= "" then
    applyText(tBox.distTxt, centerX, topPos.Y + yOffsetDist, "[" .. distStr .. "]", FLinearColor(0, 1, 0, 1), 10)
  elseif tBox.distTxt and tBox.distTxt.Widget and slua.isValid(tBox.distTxt.Widget) and tBox.distTxt._vis ~= 2 then
    pcall(function() tBox.distTxt.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end); tBox.distTxt._vis = 2
  end
  if teamIDStr and teamIDStr ~= "" then
    local txtColor = espColor
    local numID = tonumber(teamIDStr)
    if numID then
      local specificColor = ESP.GetTeamColor(numID)
      if specificColor then txtColor = specificColor end
    end
    applyText(tBox.botTxt, centerX, bottomPos.Y + yOffsetTeam, tostring(teamIDStr), txtColor, 10)
  elseif tBox.botTxt and tBox.botTxt.Widget and slua.isValid(tBox.botTxt.Widget) and tBox.botTxt._vis ~= 2 then
    pcall(function() tBox.botTxt.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end); tBox.botTxt._vis = 2
  end
end

function ESP.Remove2DBox(KeyStr)
  local box = ESP.BoxWidgets[KeyStr]
  if box then
    for i = 1, 4 do
      if box[i] and box[i].Widget and slua.isValid(box[i].Widget) then
        pcall(function()
          box[i].Widget:RemoveFromParent()
          box[i].Widget:ConditionalBeginDestroy()
        end)
      end
    end
    ESP.BoxWidgets[KeyStr] = nil
  end
  local hpBox = ESP.HealthWidgets[KeyStr]
  if hpBox then
    if hpBox.bg and slua.isValid(hpBox.bg.Widget) then pcall(function() hpBox.bg.Widget:RemoveFromParent(); hpBox.bg.Widget:ConditionalBeginDestroy() end) end
    if hpBox.fg and slua.isValid(hpBox.fg.Widget) then pcall(function() hpBox.fg.Widget:RemoveFromParent(); hpBox.fg.Widget:ConditionalBeginDestroy() end) end
    ESP.HealthWidgets[KeyStr] = nil
  end
  local tBox = ESP.CustomTextWidgets[KeyStr]
  if tBox then
    for _, k in ipairs({"nameTxt", "distTxt", "botTxt"}) do
      local t = tBox[k]
      if t and t.Widget and slua.isValid(t.Widget) then
        pcall(function() t.Widget:RemoveFromParent(); t.Widget:ConditionalBeginDestroy() end)
      end
    end
    ESP.CustomTextWidgets[KeyStr] = nil
  end
end

function ESP.RemoveESPWidget(Widget)
  if not Widget then return end
  local Container = Widget.Container or Widget
  pcall(function()
    local ptr = tostring(Container)
    ESP.ESPWidgetPtrs[ptr] = nil
    Container:RemoveFromParent()
    Container:ConditionalBeginDestroy()
  end)
end

-- ============================================================
-- Snap lines
-- ============================================================
function ESP.CreateSnapLine()
  if not ESP.ESPCanvas or not Game:IsValid(ESP.ESPCanvas) then return nil end
  local Border = nil
  pcall(function() Border = CGame:NewObjectFromPath("/Script/UMG.Border", ESP.ESPCanvas) end)
  if not Border or not slua.isValid(Border) then return nil end
  local color = ESP.SnapLineColor or FLinearColor(1.0, 1.0, 1.0, ESP.SnapLineOpacity or 0.7)
  pcall(function() Border:SetBrushColor(color) end)
  pcall(function() Border:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
  pcall(function() Border:SetRenderTransformPivot(FVector2D(0.0, 0.5)) end)
  local Slot = nil
  pcall(function()
    Slot = ESP.ESPCanvas:AddChildToCanvas(Border)
    if Slot then
      Slot:SetAutoSize(false)
      Slot:SetZOrder(1)
    end
  end)
  return { Widget = Border, Slot = Slot, _vis = 2 }
end

function ESP.GetSnapLineStartPos(PC)
  local screenPixelW, screenPixelH = 0, 0
  local scale = 1.0
  local WidgetLayoutLibrary = import("WidgetLayoutLibrary") or import("/Script/UMG.WidgetLayoutLibrary")
  pcall(function()
    if PC and PC.GetViewportSize then
      local vs = FVector2D(0, 0)
      PC:GetViewportSize(vs)
      if vs and vs.X and vs.X > 200 then
        screenPixelW = vs.X; screenPixelH = vs.Y
      end
    end
  end)
  if screenPixelW <= 200 then
    pcall(function()
      if WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportSize then
        local vs = WidgetLayoutLibrary.GetViewportSize(PC)
        if vs and vs.X and vs.X > 200 then
          screenPixelW = vs.X; screenPixelH = vs.Y
        end
      end
    end)
  end
  pcall(function()
    if WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportScale then
      local s = WidgetLayoutLibrary.GetViewportScale(PC)
      if s and type(s) == "number" and s > 0 then scale = s end
    end
  end)
  if screenPixelW <= 200 then
    screenPixelW = (ESP._cachedViewportW or 1920) * scale
    screenPixelH = (ESP._cachedViewportH or 1080) * scale
  end
  if not ESP._CachedTopCenterPixel then ESP._CachedTopCenterPixel = FVector2D(0, 0) end
  ESP._CachedTopCenterPixel.X = screenPixelW / 2.0
  ESP._CachedTopCenterPixel.Y = (ESP.SnapLineOriginY or 50) * scale
  local fromCanvasPos = ESP.ScreenPixelToCanvasLocal(PC, ESP._CachedTopCenterPixel)
  local fromX = fromCanvasPos.X + (ESP.SnapLineOriginOffsetX or 0)
  local fromY = fromCanvasPos.Y
  return fromX, fromY
end

function ESP.UpdateSnapLine(KeyStr, CanvasPos, bOnScreen, fromX, fromY, color)
  if not ESP.bUseSnapLines then return end
  if not ESP.ESPCanvas or not Game:IsValid(ESP.ESPCanvas) then return end
  local LineData = ESP.SnapLineWidgets[KeyStr]
  if not bOnScreen or not CanvasPos then
    if LineData and LineData.Widget and slua.isValid(LineData.Widget) and LineData._vis ~= 2 then
      pcall(function() LineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
      LineData._vis = 2
    end
    return
  end
  if not LineData then
    LineData = ESP.CreateSnapLine()
    if not LineData or not LineData.Widget or not LineData.Slot then return end
    ESP.SnapLineWidgets[KeyStr] = LineData
  end
  local Widget = LineData.Widget
  local Slot = LineData.Slot
  if LineData._vis ~= 0 then
    pcall(function() Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
    LineData._vis = 0
  end
  if color then pcall(function() Widget:SetBrushColor(color) end) end
  local toX = CanvasPos.X + (ESP.SnapLineHeadOffsetX or 0)
  local toY = CanvasPos.Y + (ESP.SnapLineHeadOffsetY or 0)
  local dx = toX - fromX
  local dy = toY - fromY
  local length = math.sqrt(dx * dx + dy * dy)
  local thickness = ESP.SnapLineThickness or 1.5
  local angle_rad = 0
  if math.atan2 then angle_rad = math.atan2(dy, dx) else angle_rad = math.atan(dy, dx) end
  local angle = angle_rad * (180.0 / math.pi)
  if not LineData._CachedPosVec then
    LineData._CachedPosVec = FVector2D(fromX, fromY - thickness / 2.0)
    LineData._CachedSizeVec = FVector2D(length, thickness)
  else
    LineData._CachedPosVec.X = fromX
    LineData._CachedPosVec.Y = fromY - thickness / 2.0
    LineData._CachedSizeVec.X = length
    LineData._CachedSizeVec.Y = thickness
  end
  pcall(function()
    Slot:SetPosition(LineData._CachedPosVec)
    Slot:SetSize(LineData._CachedSizeVec)
  end)
  pcall(function() Widget:SetRenderAngle(angle) end)
end

function ESP.RemoveSnapLine(KeyStr)
  local LineData = ESP.SnapLineWidgets[KeyStr]
  if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
    pcall(function()
      LineData.Widget:RemoveFromParent()
      LineData.Widget:ConditionalBeginDestroy()
    end)
    ESP.SnapLineWidgets[KeyStr] = nil
  end
end

-- ============================================================
-- Position update
-- ============================================================
function ESP.UpdateESPPositionWithPC(Widget, WorldLoc, PC, CanvasPos)
  if not Widget or not AK_IsValid(PC) then return false end
  local Container = Widget.Container or Widget
  local bOnScreen = true
  if not CanvasPos then
    if not WorldLoc then return false end
    bOnScreen, CanvasPos = ESP.ProjectWorldToCanvasLocal(PC, WorldLoc)
  end
  if not bOnScreen then
    if Container._vis ~= 2 then
      pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
      Container._vis = 2
    end
    return false
  end
  pcall(function()
    if ESP.ESPCanvas and Game:IsValid(ESP.ESPCanvas) then
      local ptr = tostring(Container)
      local Slot = ESP.ESPWidgetPtrs[ptr]
      if not Slot or not slua.isValid(Slot) or type(Slot) == "boolean" then
        local addedSlot = ESP.ESPCanvas:AddChildToCanvas(Container)
        if addedSlot and slua.isValid(addedSlot) then
          Slot = addedSlot
          ESP.ESPWidgetPtrs[ptr] = addedSlot
          if type(Widget) == "table" then Widget.Slot = addedSlot end
          pcall(function() Slot:SetAutoSize(true) end)
          pcall(function() Slot:SetAlignment(FVector2D(0.5, 1.0)) end)
          pcall(function() Slot:SetZOrder(20) end)
        end
      end
      if Container._vis ~= 0 then
        Container:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        Container._vis = 0
      end
      if not Widget._OffsetResetDone then
        pcall(function() Container:SetRenderTranslation(FVector2D(0.0, 0.0)) end)
        pcall(function() Container:SetRenderTransformPivot(FVector2D(0.5, 1.0)) end)
        Widget._OffsetResetDone = true
      end
      if Slot and slua.isValid(Slot) and Slot ~= ESP.ESPCanvas then
        local finalX = CanvasPos.X + (ESP.ESPAnchorOffsetX or 0)
        local finalY = CanvasPos.Y + (ESP.ESPAnchorOffsetY or 0)
        if type(Widget) == "table" then
          if not Widget._CachedPosVec or math.abs(Widget._CachedPosVec.X - finalX) > 0.5 or math.abs(Widget._CachedPosVec.Y - finalY) > 0.5 then
            Widget._CachedPosVec = Widget._CachedPosVec or FVector2D(finalX, finalY)
            Widget._CachedPosVec.X = finalX
            Widget._CachedPosVec.Y = finalY
            pcall(function() Slot:SetPosition(Widget._CachedPosVec) end)
          end
        else
          pcall(function() Slot:SetPosition(FVector2D(finalX, finalY)) end)
        end
      end
    end
  end)
  return true
end

-- ============================================================
-- Main update loop
-- ============================================================
function ESP.UpdateESPLight()
  if AK_GetVal("ESP_FULL_INFO") ~= 1 then return end
  if not ESP.bUseScreenESP then return end
  if not ESP.ESPCanvas or not Game:IsValid(ESP.ESPCanvas) then return end
  local PC = ESP.GetMyPlayerController()
  if not AK_IsValid(PC) then return end
  ESP.UpdateCanvasTransform(PC)
  ESP.bUseSnapLines = (AK_GetVal("ESP_LINE") == 1)
  local fromX, fromY = 0, 0
  if ESP.bUseSnapLines then fromX, fromY = ESP.GetSnapLineStartPos(PC) end
  local MyLoc = ESP.GetMyLocation()
  for KeyStr, ESPData in pairs(ESP.ESPWidgets) do
    local Widget = ESPData.Widget
    local Character = ESPData.Character
    local Container = Widget and (Widget.Container or Widget)
    local bWidgetValid = false
    pcall(function() bWidgetValid = Container and slua.isValid(Container) end)
    if Widget and bWidgetValid and Character and AK_IsValid(Character) then
      local bIsAlive = ESP.IsAlive(Character)
      if not bIsAlive then
        if Container._vis ~= 2 then
          pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
          Container._vis = 2
        end
        ESP.RemoveSnapLine(KeyStr)
        ESP.Update2DBox(KeyStr, nil, nil, nil, false)
      else
        local rootLoc = ESP.GetCharacterLocation(Character)
        local topLoc = ESP.GetESPLocation(Character)
        if rootLoc and topLoc then
          local dist2D = 0
          if MyLoc then dist2D = ESP.CalcDistance(MyLoc, rootLoc) / 100.0 end
          rootLoc.Z = rootLoc.Z - 90
          topLoc.Z = topLoc.Z + 15
          local bOnBot, botPos = ESP.ProjectWorldToCanvasLocal(PC, rootLoc)
          local bOnTop, topPos = ESP.ProjectWorldToCanvasLocal(PC, topLoc)
          local isVisible = (bOnBot or bOnTop)
          if isVisible then
            local estHeight = 18000 / math.max(dist2D, 1)
            if estHeight > 3000 then estHeight = 3000 elseif estHeight < 15 then estHeight = 15 end
            if bOnBot and not bOnTop then
              topPos = FVector2D(botPos.X, botPos.Y - estHeight)
            elseif bOnTop and not bOnBot then
              botPos = FVector2D(topPos.X, topPos.Y + estHeight)
            end
            if botPos.Y < topPos.Y then
              local tempY = botPos.Y
              botPos.Y = topPos.Y
              topPos.Y = tempY
            end
            local height = botPos.Y - topPos.Y
            if height > 3000 then botPos.Y = topPos.Y + 3000 end
            if dist2D > 650 then isVisible = false end
          end
          if isVisible then
            if Container._vis ~= 0 then
              pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
              Container._vis = 0
            end
            ESP.UpdateESPPositionWithPC(Widget, topLoc, PC, topPos)
            if not ESPData.bCleanedUpUMG then
              local hideNames = {"TextBlock_TeamID", "TextBlock_PlayerTeamID", "Text_TeamID", "TextBlock_Team", "Image_TeamBG", "Image_TeamLogoBG", "TeamBgBorder", "Image_RingBG", "Image_TeamBG_2", "SizeBox_HP"}
              for _, name in ipairs(hideNames) do
                local w = Container[name]
                if w and slua.isValid(w) then pcall(function() w:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end) end
              end
              if Widget.NameText and slua.isValid(Widget.NameText) then pcall(function() Widget.NameText:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end) end
              ESPData.bCleanedUpUMG = true
            end
            local bShowBox      = (AK_GetVal("ESP_BOX") == 1)
            local bShowHealth   = (AK_GetVal("ESP_HEALTH") == 1)
            local bShowName     = (AK_GetVal("ESP_NAME") == 1)
            local bShowDistance = (AK_GetVal("ESP_DISTANCE") == 1)
            local bShowTeam     = (AK_GetVal("ESP_TEAMID") == 1)
            local bShowLine     = (AK_GetVal("ESP_LINE") == 1)
            local isNormalBot, isMLBot = AK_CheckIsBot(Character)
            local isBot = isNormalBot or isMLBot
            local espColor = isBot and FLinearColor(1, 1, 1, 1) or FLinearColor(1, 0, 0, 1)
            if bShowLine then
              ESP.UpdateSnapLine(KeyStr, topPos, isVisible, fromX, fromY, espColor)
            else
              ESP.RemoveSnapLine(KeyStr)
            end
            ESP.Update2DBox(KeyStr, topPos, botPos, espColor, isVisible and bShowBox)
            local HP, MaxHP = 100, 100
            pcall(function()
              HP = type(Character.GetHealth) == "function" and Character:GetHealth() or Character.Health or 0
              MaxHP = type(Character.GetHealthMax) == "function" and Character:GetHealthMax() or Character.MaxHealth or 100
            end)
            local pct = (HP > 0 and MaxHP > 0) and (HP / MaxHP) or 0
            if pct > 1 then pct = 1 elseif pct < 0 then pct = 0 end
            ESP.Update2DHealthBar(KeyStr, topPos, botPos, pct, isVisible and bShowHealth)
            local distStr   = bShowDistance and (ESPData.LastDistStr or "") or ""
            local nameStr   = bShowName and (ESPData.Name or "Unknown") or ""
            local teamIDStr = bShowTeam and (ESPData.TeamID and tostring(ESPData.TeamID) or "") or ""
            ESP.Update2DTextData(KeyStr, topPos, botPos, nameStr, distStr, teamIDStr, isVisible, espColor)
          else
            if Container._vis ~= 2 then
              pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
              Container._vis = 2
            end
            ESP.RemoveSnapLine(KeyStr)
            ESP.Update2DBox(KeyStr, nil, nil, nil, false)
            ESP.Update2DHealthBar(KeyStr, nil, nil, 0, false)
            ESP.Update2DTextData(KeyStr, nil, nil, "", "", "", false, nil)
          end
        else
          if Container._vis ~= 2 then
            pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
            Container._vis = 2
          end
          ESP.RemoveSnapLine(KeyStr)
          ESP.Update2DBox(KeyStr, nil, nil, nil, false)
          ESP.Update2DHealthBar(KeyStr, nil, nil, 0, false)
          ESP.Update2DTextData(KeyStr, nil, nil, "", "", "", false, nil)
        end
      end
    end
  end
end

function ESP.UpdateESPDistances()
  if AK_GetVal("ESP_DISTANCE") ~= 1 then return end
  if not ESP.bUseScreenESP then return end
  local MyLoc = ESP.GetMyLocation()
  if not MyLoc then return end
  local PC = ESP.GetMyPlayerController()
  if not AK_IsValid(PC) then return end
  ESP.UpdateCanvasTransform(PC)
  for KeyStr, ESPData in pairs(ESP.ESPWidgets) do
    local Character = ESPData.Character
    local Widget = ESPData.Widget
    local Container = Widget and (Widget.Container or Widget)
    local bWidgetValid = false
    pcall(function() bWidgetValid = Container and slua.isValid(Container) end)
    if Character and AK_IsValid(Character) and Widget and bWidgetValid then
      local Loc = ESP.GetESPLocation(Character)
      if Loc then
        local Dist = ESP.CalcDistance(MyLoc, Loc)
        ESPData.LastDistance = Dist
        if ESP.bShowDistance then
          local DistStr = ""
          local Meters = 0
          if Dist then
            Meters = Dist / 100
            if Meters < 1000 then DistStr = tostring(math.floor(Meters)) .. "m"
            else
              local kmFloor = math.floor((Meters / 1000) * 10) / 10
              DistStr = tostring(kmFloor) .. "km"
            end
          end
          ESPData.LastDistStr = DistStr
        end
      end
    end
  end
end

function ESP.UpdateESP(AllPlayers, MyLoc)
  if not ESP.bUseScreenESP then return end
  if not ESP.InitESPCanvas() then return end
  if ESP._OBHeadWidgetLoadFailed then return end
  local PC = ESP.GetMyPlayerController()
  if AK_IsValid(PC) then ESP.UpdateCanvasTransform(PC) end
  ESP.bUseSnapLines = (AK_GetVal("ESP_LINE") == 1)
  local fromX, fromY = 0, 0
  if ESP.bUseSnapLines and AK_IsValid(PC) then
    fromX, fromY = ESP.GetSnapLineStartPos(PC)
  end
  local MyKey = ESP.GetMyPlayerKey()
  local SeenKeys = {}
  local MyChar = nil
  pcall(function()
    local GDP = ESP.GetGameplayData()
    if GDP and GDP.GetLocalCharacter then MyChar = GDP.GetLocalCharacter()
    elseif PC and PC.GetPawn then MyChar = PC:GetPawn() end
  end)
  local MyTeamID = ESP.GetTeamID(MyChar)
  for PlayerKey, Character in pairs(AllPlayers) do
    if AK_IsValid(Character) then
      local bIsMe = ESP.IsMe(Character, PlayerKey, MyKey)
      local bIsAI = ESP.IsAI(Character)
      local KeyStr = tostring(PlayerKey)
      local isNormalBot, isMLBot = AK_CheckIsBot(Character)
      local Name = "BOT"
      if not (isNormalBot or isMLBot) then
        Name = ESP.GetPlayerName(Character)
      end
      local Loc = ESP.GetESPLocation(Character)
      local DistStr = ""
      if AK_GetVal("ESP_DISTANCE") == 1 then ESP.bShowDistance = true else ESP.bShowDistance = false end
      if MyLoc and Loc and ESP.bShowDistance then
        DistStr = ESP.GetDistanceString(MyLoc, Loc)
      end
      local bSkip = false
      if bIsMe and not ESP.bIncludeMe then bSkip = true end
      if bIsAI and not ESP.bIncludeAI then bSkip = true end
      local TeamID = ESP.GetTeamID(Character)
      if MyTeamID ~= nil and TeamID == MyTeamID and not bIsMe then bSkip = true end
      local bIsAlive = ESP.IsAlive(Character)
      if not bSkip and Loc then
        SeenKeys[KeyStr] = true
        local ESPData = ESP.ESPWidgets[KeyStr]
        local Text = ""
        if AK_GetVal("ESP_TEAMID") == 1 and TeamID then
          Text = tostring(TeamID) .. "  " .. Name
        else
          Text = Name
        end
        if DistStr and DistStr ~= "" then Text = Text .. "  [" .. DistStr .. "]" end
        if not ESPData then
          local Widget = ESP.CreateESPWidget()
          if Widget then
            ESP.ESPWidgets[KeyStr] = {
              Widget = Widget,
              Character = Character,
              Name = Name,
              LastDistStr = DistStr,
              TeamID = TeamID,
            }
            if not bIsAlive then
              local Container = Widget.Container or Widget
              pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
              Container._vis = 2
            end
          end
        else
          ESPData.Character = Character
          ESPData.Name = Name
          ESPData.LastDistStr = DistStr
          if not bIsAlive then
            local Container = ESPData.Widget.Container or ESPData.Widget
            if Container._vis ~= 2 then
              pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
              Container._vis = 2
            end
          end
        end
      end
    end
  end
  for KeyStr, Data in pairs(ESP.ESPWidgets) do
    if not SeenKeys[KeyStr] then
      ESP.RemoveESPWidget(Data.Widget)
      ESP.ESPWidgets[KeyStr] = nil
      ESP.RemoveSnapLine(KeyStr)
      ESP.Remove2DBox(KeyStr)
    end
  end
end

function ESP.ScanAndUpdate()
  if AK_GetVal("ESP_FULL_INFO") ~= 1 then
    ESP.ClearAllESP()
    return 0
  end
  local AllChars = ESP.GetAllCharacters()
  if not AllChars then return 0 end
  local MyLoc = ESP.GetMyLocation()
  if ESP.bUseScreenESP then
    ESP.UpdateESP(AllChars, MyLoc)
  end
  return 0
end

function ESP.ClearAllESP()
  for KeyStr, Data in pairs(ESP.ESPWidgets) do
    ESP.RemoveESPWidget(Data.Widget)
  end
  ESP.ESPWidgets = {}
  ESP.ESPWidgetPtrs = {}
  for k, _ in pairs(ESP.SnapLineWidgets) do ESP.RemoveSnapLine(k) end
  ESP.SnapLineWidgets = {}
  for k, _ in pairs(ESP.BoxWidgets or {}) do ESP.Remove2DBox(k) end
  ESP.BoxWidgets = {}
  ESP.HealthWidgets = {}
  ESP.CustomTextWidgets = {}
  ESP.ESPCanvas = nil
  ESP._OBHeadWidgetClass = nil
  ESP._OBHeadWidgetLoadFailed = false
  ESP._cachedViewportW = 1920
  ESP._cachedViewportH = 1080
end

function ESP.OnTick()
  if not ESP.bActive then return end
  pcall(function()
    local currentPC = ESP.GetMyPlayerController()
    if ESP._LastPC ~= currentPC then
      ESP.ClearAllESP()
      ESP._LastPC = currentPC
      ESP.ESPCanvas = nil
    end
    ESP._FrameCount = ESP._FrameCount + 1
    local frame = ESP._FrameCount
    if frame % ESP.nHeavyScanFrameInterval == 0 then
      local AllChars = ESP.GetAllCharacters()
      if AllChars then
        local MyLoc = ESP.GetMyLocation()
        ESP.UpdateESP(AllChars, MyLoc)
      end
    end
    if frame % ESP.nDistanceUpdateFrameInterval == 0 then
      ESP.UpdateESPDistances()
    end
    ESP.UpdateESPLight()
  end)
end

function ESP.Start()
  if ESP.bActive then return end
  ESP.bActive = true
  ESP._FrameCount = 0
  if not ESP._TickRegistered then
    ESP._TickRegistered = true
    local ok = pcall(function()
      local ticker = package.loaded["common.time_ticker"] or require("common.time_ticker")
      if ticker and ticker.AddTimerLoop then
        ESP._MasterTimerHandle = ticker.AddTimerLoop(0, function()
          if not ESP.bActive then return end
          ESP._FrameCount = ESP._FrameCount + 1
          local frameCount = ESP._FrameCount
          pcall(function() ESP.UpdateESPLight() end)
          if frameCount % 6 == 0 then
            if ESP.bUseScreenESP and ESP.bShowDistance then
              pcall(function() ESP.UpdateESPDistances() end)
            end
          end
          if frameCount >= 30 then
            local currentPC = ESP.GetMyPlayerController()
            if currentPC and ESP._LastPC ~= currentPC then
              ESP.ClearAllESP()
              ESP._LastPC = currentPC
              ESP.ESPCanvas = nil
            end
            pcall(function() ESP.ScanAndUpdate() end)
            ESP._FrameCount = 0
          end
        end, -1, 0.016)
      end
    end)
  end
end

function ESP.Stop()
  ESP.bActive = false
  ESP._FrameCount = 0
  if ESP._MasterTimerHandle then
    pcall(function()
      local ticker = package.loaded["common.time_ticker"] or require("common.time_ticker")
      if ticker and ticker.RemoveTimer then ticker.RemoveTimer(ESP._MasterTimerHandle) end
    end)
    ESP._MasterTimerHandle = nil
  end
  ESP.ClearAllESP()
end

_G.AK_ESP_Internal = ESP

-- ============================================================
-- END ESP MODULE
-- ============================================================

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
    -- ESP: start on local client
    if self:IsLocallyControlled() then
      pcall(function() ESP.Start() end)
    end
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
  if not self:GetEnsure() then return end
  self:AddGameTimer(0.5, false, function()
    if not slua.isValid(self.Object) then return end
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
    -- ESP: stop when local controlled character ends
    if self:IsLocallyControlled() then
      pcall(function() ESP.Stop() end)
    end
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
    if self:IsLocallyControlled() then
      pcall(function() ESP.Stop() end)
    end
  end
end

function BRPlayerCharacterBase:BPOnRespawned()
  print(bWriteLog and string.format("%s BPOnRespawned()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
    if self:IsLocallyControlled() then
      pcall(function() ESP.Start() end)
    end
  end
end

function BRPlayerCharacterBase:ReceiveOnRecycle()
  print(bWriteLog and string.format("%s IReusable:ReceiveOnRecycle()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
    GameplayData.RemoveCharacter(self.Object)
    if self:IsLocallyControlled() then
      pcall(function() ESP.Stop() end)
    end
  end
end

function BRPlayerCharacterBase:ReceiveOnSpawn()
  print(bWriteLog and string.format("%s IReusable:ReceiveOnSpawn()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
    GameplayData.AddCharacter(self.Object)
    if self:IsLocallyControlled() then
      pcall(function() ESP.Start() end)
    end
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
  if uCharacter ~= self.Object then return end
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
  if not Client then return end
  log(bWriteLog and "  BRPlayerCharacterBase:MulticastRPC_GmPlayAction.  actionId: " .. tostring(actionId))
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
  if not FxID or FxID == ItemID then return ItemID end
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
  if not BPID or BPID <= 0 then return "" end
  return model_util.GetPath("Emote", BPID, false, false) or ""
end

function BRPlayerCharacterBase:GetEmoteHandle(ItemID)
  local ResID = ResolveEmoteResID(ItemID)
  if self.Super then
    return self.Super:GetEmoteHandle(ResID)
  end
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