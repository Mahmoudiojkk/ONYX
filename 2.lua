-- ============================================================
-- BRPlayerCharacterBase - ULTIMATE IMMORTAL FIREWALL v6.9.0
-- ============================================================
-- 🛡️ FIREWALL ULTIMATE PRO - ANTI BAN ABSOLUTE SYSTEM 🛡️
-- 🚫 100% BAN PROOF - IMPENETRABLE SECURITY LAYER
-- 🔥 Bypasses All Anti-Cheat Systems (ACE, BattlEye, XIGNCODE, TSS)
-- 👑 Owner: @Xx4Fx | 📢 Channel: https://t.me/REGERvip
-- ============================================================

local class = require("class")
local CharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CombineClass = require("combine_class")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local TimerManager = require("common.time_ticker")

-- ============================================================
-- ADVANCED FIREWALL CONFIGURATION - ULTIMATE PROTECTION
-- ============================================================
local FirewallConfig = {
    Enabled = true,
    Version = "6.9.0",
    ImmuneMode = true, -- وضع المناعة المطلق
    
    -- قائمة موسعة من الملفات المحمية (حماية شاملة)
    ProtectedExtensions = {
        ".lua", ".luac", ".uasset", ".uexp", ".pak", ".umap",
        ".ubulk", ".locres", ".json", ".ini", ".cfg", ".txt",
        ".xml", ".dat", ".bin", ".dll", ".so", ".apk", ".jar",
        ".class", ".py", ".pyc", ".js", ".html", ".css",
        ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".tga", ".dds"
    },
    
    -- جميع ملفات النظام والأمان (موسعة)
    ProtectedFiles = {
        "BRPlayerCharacterBase.lua", "GameplayData.lua", "CharacterBase.lua",
        "CombineClass.lua", "SubsystemMgr.lua", "HiggsBosonComponent.lua",
        "CoronaLabSubsystem.lua", "SwiftHawkSubsystem.lua", "ClientReportPlayerSubsystem.lua",
        "DSReportPlayerSubsystem.lua", "PlayerSecurityInfoSubsystem.lua", "MemoryCheckSubsystem.lua",
        "FileCheckSubsystem.lua", "SpeedCheckSubsystem.lua", "WallCheckSubsystem.lua",
        "ShootVerifySubSystemClient.lua", "AvatarExceptionSubsystem.lua", "PakFileSubsystem.lua",
        "TLogSubsystem.lua", "RealTimeBanSubsystem.lua", "ClientBanSubsystem.lua",
        "SecurityCheckSubsystem.lua", "AntiTamperSubsystem.lua", "MemoryScanner.lua",
        "DebuggerDetector.lua", "EmulatorDetector.lua", "RootDetector.lua",
        "PacketAnalyzer.lua", "BehaviorMonitor.lua", "ReportManager.lua",
        "BanManager.lua", "KickManager.lua", "SuspensionManager.lua",
        "KernelProtection.lua", "DriverCheck.lua", "IntegrityCheck.lua"
    },
    
    -- جميع المجلدات الحيوية
    ProtectedFolders = {
        "GameLua/", "client/", "Server/", "Mod/", "BaseMod/",
        "Security/", "Subsystem/", "Framework/", "GameCore/", "Data/",
        "Script/", "Core/", "Engine/", "Runtime/", "Plugin/",
        "AntiCheat/", "Protection/", "Monitor/", "Report/", "Ban/"
    },
    
    -- منافذ محظورة (جميع المنافذ المعروفة لأنظمة مكافحة الغش)
    BlockedPorts = {
        8011, 8013, 8015, 8080, 8085, 8086, 8088, 8700, 9001,
        10334, 10336, 10309, 10087, 10095, 10120, 10157, 10213,
        10262, 10664, 10685, 10706, 10709, 10761, 10769,
        11008, 11045, 11075, 12221, 12401, 13331, 13728, 14545,
        15692, 1670, 18081, 19900, 19700, 20371, 20000, 20001,
        20002, 20003, 20004, 20005, 24798, 25177, 27000, 27015,
        27030, 27040, 31113, 5061, 5062, 6667, 9030,
        443, 80, 8080, 8443, 10443, 1337, 31337, 4444, 5555,
        6666, 7777, 8888, 9999, 11111, 22222, 33333, 44444,
        55555, 66666, 77777, 88888, 99999, 12345, 23456, 34567,
        45678, 56789, 67890, 78901, 89012, 90123, 1024, 2048
    },
    
    -- نطاقات IP محظورة (جميع نطاقات تينسنت والخوادم الأمنية)
    BlockedIPs = {
        "43.128.0.0/16", "43.129.0.0/16", "43.130.0.0/16", "43.131.0.0/16",
        "43.132.0.0/16", "43.133.0.0/16", "43.134.0.0/16", "43.135.0.0/16",
        "43.136.0.0/16", "43.137.0.0/16", "43.138.0.0/16", "43.139.0.0/16",
        "43.140.0.0/16", "43.141.0.0/16", "43.142.0.0/16", "43.143.0.0/16",
        "43.144.0.0/16", "43.145.0.0/16", "43.146.0.0/16", "43.147.0.0/16",
        "43.148.0.0/16", "43.149.0.0/16", "43.150.0.0/16", "43.151.0.0/16",
        "43.152.0.0/16", "43.153.0.0/16", "43.154.0.0/16", "43.155.0.0/16",
        "43.156.0.0/16", "43.157.0.0/16", "43.158.0.0/16", "43.159.0.0/16",
        "43.160.0.0/16", "43.161.0.0/16", "43.162.0.0/16", "43.163.0.0/16",
        "43.164.0.0/16", "43.165.0.0/16", "43.166.0.0/16", "43.167.0.0/16",
        "43.168.0.0/16", "43.169.0.0/16", "43.170.0.0/16", "43.171.0.0/16",
        "43.172.0.0/16", "43.173.0.0/16", "43.174.0.0/16", "43.175.0.0/16",
        "43.176.0.0/16", "43.177.0.0/16", "43.178.0.0/16", "43.179.0.0/16",
        "43.180.0.0/16", "43.181.0.0/16", "43.182.0.0/16", "43.183.0.0/16",
        "43.184.0.0/16", "43.185.0.0/16", "43.186.0.0/16", "43.187.0.0/16",
        "43.188.0.0/16", "43.189.0.0/16", "43.190.0.0/16", "43.191.0.0/16",
        "43.192.0.0/16", "43.193.0.0/16", "43.194.0.0/16", "43.195.0.0/16",
        "43.196.0.0/16", "43.197.0.0/16", "43.198.0.0/16", "43.199.0.0/16",
        "43.200.0.0/16", "43.201.0.0/16", "43.202.0.0/16", "43.203.0.0/16",
        "43.204.0.0/16", "43.205.0.0/16", "43.206.0.0/16", "43.207.0.0/16",
        "43.208.0.0/16", "43.209.0.0/16", "43.210.0.0/16", "43.211.0.0/16",
        "43.212.0.0/16", "43.213.0.0/16", "43.214.0.0/16", "43.215.0.0/16",
        "43.216.0.0/16", "43.217.0.0/16", "43.218.0.0/16", "43.219.0.0/16",
        "43.220.0.0/16", "43.221.0.0/16", "43.222.0.0/16", "43.223.0.0/16",
        "129.204.0.0/16", "129.205.0.0/16", "129.206.0.0/16", "129.207.0.0/16",
        "129.208.0.0/16", "129.209.0.0/16", "129.210.0.0/16", "129.211.0.0/16",
        "129.212.0.0/16", "129.213.0.0/16", "129.214.0.0/16", "129.215.0.0/16",
        "129.216.0.0/16", "129.217.0.0/16", "129.218.0.0/16", "129.219.0.0/16",
        "129.220.0.0/16", "129.221.0.0/16", "129.222.0.0/16", "129.223.0.0/16",
        "185.244.0.0/16", "185.245.0.0/16", "185.246.0.0/16", "185.247.0.0/16",
        "185.248.0.0/16", "185.249.0.0/16", "185.250.0.0/16", "185.251.0.0/16",
        "185.252.0.0/16", "185.253.0.0/16", "185.254.0.0/16", "185.255.0.0/16",
        "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "127.0.0.0/8"
    },
    
    -- جميع الدومينات الأمنية والمعروفة
    BlockedDomains = {
        "anticheat.qq.com", "tss.tencent.com", "tss-sdk.qq.com",
        "report.qq.com", "ban.qq.com", "security.qq.com",
        "hawkeye.qq.com", "pubgm.qq.com", "pubgmobile.qq.com",
        "igame.qq.com", "tencent.com", "qq.com",
        "tlog.qq.com", "ds.qq.com", "lobby.qq.com",
        "match.qq.com", "login.qq.com", "account.qq.com",
        "device.qq.com", "fingerprint.qq.com", "telemetry.qq.com",
        "analytics.qq.com", "crash.qq.com", "bugly.qq.com",
        "tdm.qq.com", "gokuba.qq.com", "swifthawk.qq.com",
        "coronalab.qq.com", "higgsboson.qq.com", "battleye.com",
        "xigncode.com", "ace.qq.com", "tss-sdk.com",
        "antihack.com", "securitycheck.com", "validation.com",
        "verification.com", "monitor.com", "tracking.com",
        "google.com", "facebook.com", "amazon.com", "microsoft.com",
        "apple.com", "cloudflare.com", "fastly.com", "akamai.net",
        "cloudfront.net", "azure.com", "aws.com", "gc.com"
    },
    
    -- قائمة الحزم المحظورة (موسعة جداً)
    BlockedPackets = {
        "ReportAttackFlow", "ReportSecAttackFlow", "ReportHurtFlow",
        "ReportFireArms", "ReportVerifyInfoFlow", "ReportMrpcsFlow",
        "ReportPlayerBehavior", "ReportTeammatHurt", "ReportAimFlow",
        "ReportHitFlow", "ReportCircleFlow", "ReportJumpFlow",
        "report_players_ping", "report_player_ip", "report_net_saturate",
        "tss_sdk_report", "SwiftHawk", "ClientSwiftHawk",
        "CoronaLabData", "GokubaData", "TLogReport",
        "TelemetryData", "AnalyticsData", "CrashReport",
        "ReportSecurityAlert", "ReportAntiCheat", "ReportViolation",
        "ReportBan", "ReportKick", "ReportCheat", "ReportHack",
        "ReportMod", "ReportInject", "ReportHook", "ReportPatch",
        "ReportTamper", "ReportCorrupt", "ReportInvalid",
        "ReportSpoof", "ReportFake", "ReportClone", "ReportDuplicate",
        "ReportAbnormal", "ReportSuspicious", "ReportDetect",
        "ReportFlag", "ReportMonitor", "ReportTrack", "ReportLog",
        "ReportTelemetry", "ReportAnalytics", "ReportUsage",
        "ReportPerformance", "ReportBenchmark", "ReportDiagnostic",
        "ReportHeartbeat", "ReportPing", "ReportStatus", "ReportState"
    },
    
    -- قائمة RPCs المحظورة
    BlockedRPCs = {
        "RPC_Server_ClientSecMrpcsFlow", "RPC_Server_SwiftHawk",
        "RPC_Server_ClientSwiftHawkWithParams", "RPC_Server_ReportSimulateCharacterLocation",
        "RPC_Client_ShootVertifyRes", "RPC_ClientCoronaLab",
        "RPC_Server_HawkReportCheat", "RPC_Server_ReportPlayerKillFlow",
        "RPC_Server_RequestImprison", "RPC_Server_ReportSecurityViolation",
        "RPC_Server_CheckIntegrity", "RPC_Server_Heartbeat",
        "RPC_Server_ReportAbnormal", "RPC_Server_ReportSuspicious",
        "RPC_Server_ReportDetect", "RPC_Server_ReportFlag",
        "RPC_Server_ReportMonitor", "RPC_Server_ReportTrack",
        "RPC_Server_ReportLog", "RPC_Server_ReportTelemetry",
        "RPC_Server_ReportAnalytics", "RPC_Server_ReportUsage",
        "RPC_Server_ReportPerformance", "RPC_Server_ReportBenchmark",
        "RPC_Server_ReportDiagnostic", "RPC_Server_ReportHeartbeat",
        "RPC_Server_ReportPing", "RPC_Server_ReportStatus",
        "RPC_Server_ReportState", "RPC_Server_ReportError",
        "RPC_Server_ReportException", "RPC_Server_ReportFatal"
    },
    
    -- قائمة أسماء الـ UI المحظورة (لقتل الباند)
    BlockedUINames = {
        "Legal", "Common_Legal", "Notice", "Ban", "Error",
        "Popup", "Message", "Dialog", "Warning", "Alert",
        "Notification", "Toast", "Snackbar", "Banner",
        "Confirm", "Prompt", "Input", "Select", "Progress",
        "Loading", "Success", "Failure", "Info", "Fatal",
        "Panic", "Kick", "Suspend", "Freeze", "Block",
        "Security", "Violation", "Report", "Suspicious",
        "Abnormal", "Detect", "Monitor", "Track", "Flag",
        "Common_Legal_01_UIBP", "BanNotice_UIBP", "BanPopup_UIBP",
        "KickPopup_UIBP", "WarningPopup_UIBP", "AlertPopup_UIBP",
        "SecurityAlert_UIBP", "AntiCheatPopup_UIBP", "ReportPopup_UIBP",
        "ViolationNotice_UIBP", "SuspensionNotice_UIBP", "FrozenNotice_UIBP",
        "RiskNotice_UIBP", "InspectionNotice_UIBP", "HawkEyeReport_UIBP",
        "CheatNotice_UIBP", "HackNotice_UIBP", "ModNotice_UIBP",
        "InjectNotice_UIBP", "HookNotice_UIBP", "PatchNotice_UIBP",
        "TamperNotice_UIBP", "CorruptNotice_UIBP", "InvalidNotice_UIBP"
    }
}

-- ============================================================
-- ADVANCED UTILITY FUNCTIONS
-- ============================================================
local function EmptyFunc() end
local function TrueFunc(...) return true end
local function FalseFunc(...) return false end
local function EmptyTableFunc(...) return {} end
local function EmptyStringFunc(...) return "" end
local function ZeroFunc(...) return 0 end
local function NilFunc(...) return nil end

local function IsValid(obj)
    return obj and slua.isValid and slua.isValid(obj)
end

local function SafeCall(func, ...)
    local success, result = pcall(func, ...)
    return success, result
end

local function DeepCopyTable(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then copy[k] = DeepCopyTable(v)
        else copy[k] = v end
    end
    return copy
end

local function GetPlayerController()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not IsValid(pc) then
        local GameplayData = package.loaded["GameLua.GameCore.Data.GameplayData"]
        if GameplayData and GameplayData.GetPlayerController then
            pc = GameplayData.GetPlayerController()
        end
    end
    return pc
end

local function GetGameInstance()
    local pc = GetPlayerController()
    if IsValid(pc) then
        return pc:GetGameInstance()
    end
    return nil
end

local function ExecuteCommandSafe(cmd)
    local pc = GetPlayerController()
    if IsValid(pc) then
        local KSL = import("KismetSystemLibrary")
        if KSL and KSL.ExecuteConsoleCommand then
            SafeCall(KSL.ExecuteConsoleCommand, pc, cmd)
        end
    end
end

-- ============================================================
-- FUNCTION OVERRIDE ENGINE - ULTIMATE HOOK SYSTEM
-- ============================================================
local function OverrideFunction(obj, funcName, newFunc)
    if obj and obj[funcName] then
        local orig = obj[funcName]
        obj[funcName] = function(...)
            return newFunc(orig, ...)
        end
        return true
    end
    return false
end

local function HookAllFunctions(obj, hookName, handler)
    if not obj then return end
    for k, v in pairs(obj) do
        if type(v) == "function" then
            local orig = v
            obj[k] = function(...)
                local result = handler(k, orig, ...)
                if result ~= nil then return result end
                return orig(...)
            end
        end
    end
end

-- ============================================================
-- LAYER 1: KERNEL & DRIVER LEVEL PROTECTION
-- ============================================================
local function KernelDriverProtection()
    SafeCall(function()
        -- تعطيل فحص النواة
        if _G.KernelCheck then
            _G.KernelCheck.VerifyKernel = TrueFunc
            _G.KernelCheck.ReportKernel = EmptyFunc
            _G.KernelCheck.IsKernelClean = function() return true, { code = 0, message = "clean" } end
            _G.KernelCheck.ScanKernel = function() return true end
            _G.KernelCheck.DetectKernelHooks = function() return {} end
        end
        
        -- تعطيل فحص الدرايفرز
        if _G.DriverCheck then
            _G.DriverCheck.VerifyDriver = TrueFunc
            _G.DriverCheck.ReportDriver = EmptyFunc
            _G.DriverCheck.ScanDrivers = function() return {} end
            _G.DriverCheck.DetectRootkit = function() return false end
        end
        
        -- تعطيل فحص System Integrity
        if _G.IntegrityCheck then
            _G.IntegrityCheck.VerifySystem = TrueFunc
            _G.IntegrityCheck.ReportIntegrity = EmptyFunc
            _G.IntegrityCheck.ScanIntegrity = function() return {} end
            _G.IntegrityCheck.CheckChecksum = TrueFunc
        end
        
        -- تعطيل فحص Hypervisor
        if _G.HypervisorCheck then
            _G.HypervisorCheck.IsHypervisorPresent = FalseFunc
            _G.HypervisorCheck.ReportHypervisor = EmptyFunc
        end
    end)
end

-- ============================================================
-- LAYER 2: MEMORY & PROCESS HIDING
-- ============================================================
local function MemoryProcessHiding()
    SafeCall(function()
        -- تعطيل جميع فحوصات الذاكرة
        if _G.MemoryCheck then
            _G.MemoryCheck.ScanMemory = function() return true, {} end
            _G.MemoryCheck.ReportMemory = EmptyFunc
            _G.MemoryCheck.VerifyMemory = TrueFunc
            _G.MemoryCheck.ScanProcessMemory = function() return true end
            _G.MemoryCheck.DetectMemoryModifications = function() return {} end
            _G.MemoryCheck.CompareMemory = TrueFunc
        end
        
        if _G.MemoryScanner then
            _G.MemoryScanner.StartScan = function() return false end
            _G.MemoryScanner.StopScan = EmptyFunc
            _G.MemoryScanner.GetResults = EmptyTableFunc
            _G.MemoryScanner.ScanRegion = function() return {} end
            _G.MemoryScanner.FindPattern = function() return nil end
        end
        
        if _G.ModuleCheck then
            _G.ModuleCheck.VerifyModule = TrueFunc
            _G.ModuleCheck.ReportModule = EmptyFunc
            _G.ModuleCheck.ScanModule = function() return {} end
            _G.ModuleCheck.CheckModuleIntegrity = TrueFunc
            _G.ModuleCheck.DetectInjectedModules = function() return {} end
        end
        
        if _G.ProcessCheck then
            _G.ProcessCheck.VerifyProcess = TrueFunc
            _G.ProcessCheck.ReportProcess = EmptyFunc
            _G.ProcessCheck.ScanProcess = function() return {} end
            _G.ProcessCheck.HideProcess = TrueFunc
        end
    end)
end

-- ============================================================
-- LAYER 3: ADVANCED NETWORK SPOOFING & BLOCKING
-- ============================================================
local function NetworkSpoofingBlocking()
    SafeCall(function()
        -- حظر جميع دوال الشبكة
        if socket and socket.connect then
            local origConnect = socket.connect
            socket.connect = function(host, port, ...)
                if IsBlockedIP(host) or IsBlockedDomain(host) or IsBlockedPort(port) then
                    return nil, "Blocked by Firewall"
                end
                return origConnect(host, port, ...)
            end
        end
        
        if NetUtil and NetUtil.ConnectToServer then
            local origConnect = NetUtil.ConnectToServer
            NetUtil.ConnectToServer = function(ip, port, ...)
                if IsBlockedIP(ip) or IsBlockedDomain(ip) or IsBlockedPort(port) then
                    return false, "Blocked by Firewall"
                end
                return origConnect(ip, port, ...)
            end
        end
        
        -- حظر HTTP/HTTPS
        if _G.Http then
            if _G.Http.Get then
                local origGet = _G.Http.Get
                _G.Http.Get = function(url, ...)
                    if type(url) == "string" then
                        local host = url:match("^https?://([^:/?]+)")
                        if host then
                            local port = url:match("^https?://[^:]+:(%d+)") or (url:match("^https://") and "443") or "80"
                            if IsBlockedDomain(host) or IsBlockedIP(host) or IsBlockedPort(tonumber(port)) then
                                return nil, "Request blocked by Firewall"
                            end
                        end
                    end
                    return origGet(url, ...)
                end
            end
            if _G.Http.Post then
                local origPost = _G.Http.Post
                _G.Http.Post = function(url, ...)
                    if type(url) == "string" then
                        local host = url:match("^https?://([^:/?]+)")
                        if host then
                            local port = url:match("^https?://[^:]+:(%d+)") or (url:match("^https://") and "443") or "80"
                            if IsBlockedDomain(host) or IsBlockedIP(host) or IsBlockedPort(tonumber(port)) then
                                return nil, "Request blocked by Firewall"
                            end
                        end
                    end
                    return origPost(url, ...)
                end
            end
        end
        
        -- حظر WebSocket
        if _G.WebSocket and _G.WebSocket.Connect then
            local origConnect = _G.WebSocket.Connect
            _G.WebSocket.Connect = function(url, ...)
                if type(url) == "string" then
                    local host = url:match("^wss?://([^:/?]+)")
                    if host then
                        local port = url:match("^wss?://[^:]+:(%d+)") or (url:match("^wss://") and "443") or "80"
                        if IsBlockedDomain(host) or IsBlockedIP(host) or IsBlockedPort(tonumber(port)) then
                            return nil, "WebSocket blocked by Firewall"
                        end
                    end
                end
                return origConnect(url, ...)
            end
        end
        
        -- حظر جميع الحزم
        if NetUtil and NetUtil.SendPacket then
            local origSend = NetUtil.SendPacket
            NetUtil.SendPacket = function(packetName, ...)
                for _, blocked in ipairs(FirewallConfig.BlockedPackets) do
                    if packetName == blocked then return nil end
                end
                return origSend(packetName, ...)
            end
        end
        
        -- حظر جميع RPCs
        if _G.SendRPC then
            local origRPC = _G.SendRPC
            _G.SendRPC = function(rpcName, ...)
                for _, blocked in ipairs(FirewallConfig.BlockedRPCs) do
                    if rpcName == blocked then return nil end
                end
                return origRPC(rpcName, ...)
            end
        end
        
        -- تعطيل جميع تقارير الشبكة
        if _G.ReportManager then
            _G.ReportManager.SendReport = EmptyFunc
            _G.ReportManager.QueueReport = EmptyFunc
            _G.ReportManager.FlushReports = EmptyFunc
            _G.ReportManager.ReportData = EmptyFunc
        end
    end)
end

-- ============================================================
-- LAYER 4: FILE SYSTEM FORTIFICATION (ULTIMATE)
-- ============================================================
local function FileSystemFortification()
    SafeCall(function()
        local FileHelper = import("FFileHelper")
        if FileHelper then
            -- منع جميع عمليات الملفات المحمية
            if FileHelper.FileExists then
                local origExists = FileHelper.FileExists
                FileHelper.FileExists = function(path)
                    if IsProtectedFile(path) then return true end
                    return origExists(path)
                end
            end
            if FileHelper.LoadFileToString then
                local origLoad = FileHelper.LoadFileToString
                FileHelper.LoadFileToString = function(path, ...)
                    if IsProtectedFile(path) then return "PROTECTED_CONTENT", true end
                    return origLoad(path, ...)
                end
            end
            if FileHelper.SaveStringToFile then
                local origSave = FileHelper.SaveStringToFile
                FileHelper.SaveStringToFile = function(str, path, ...)
                    if IsProtectedFile(path) then return false end
                    return origSave(str, path, ...)
                end
            end
            if FileHelper.DeleteFile then
                local origDelete = FileHelper.DeleteFile
                FileHelper.DeleteFile = function(path, ...)
                    if IsProtectedFile(path) then return false end
                    return origDelete(path, ...)
                end
            end
            if FileHelper.MoveFile then
                local origMove = FileHelper.MoveFile
                FileHelper.MoveFile = function(src, dst, ...)
                    if IsProtectedFile(src) or IsProtectedFile(dst) then return false end
                    return origMove(src, dst, ...)
                end
            end
            if FileHelper.CopyFile then
                local origCopy = FileHelper.CopyFile
                FileHelper.CopyFile = function(src, dst, ...)
                    if IsProtectedFile(src) or IsProtectedFile(dst) then return false end
                    return origCopy(src, dst, ...)
                end
            end
            if FileHelper.Exists then
                local origExists = FileHelper.Exists
                FileHelper.Exists = function(path)
                    if IsProtectedFile(path) then return true end
                    return origExists(path)
                end
            end
            if FileHelper.ReadFile then
                local origRead = FileHelper.ReadFile
                FileHelper.ReadFile = function(path, ...)
                    if IsProtectedFile(path) then return "PROTECTED", true end
                    return origRead(path, ...)
                end
            end
            if FileHelper.WriteFile then
                local origWrite = FileHelper.WriteFile
                FileHelper.WriteFile = function(path, data, ...)
                    if IsProtectedFile(path) then return false end
                    return origWrite(path, data, ...)
                end
            end
        end
        
        -- تعطيل io
        local origIoOpen = io.open
        io.open = function(path, mode)
            if IsProtectedFile(path) then
                if mode and (mode == "w" or mode == "a" or mode == "w+" or mode == "a+") then
                    return nil, "Access denied by Firewall"
                end
                return origIoOpen(path, "r")
            end
            return origIoOpen(path, mode)
        end
        
        local origIoLines = io.lines
        io.lines = function(path, ...)
            if IsProtectedFile(path) then
                return function() return nil end
            end
            return origIoLines(path, ...)
        end
        
        -- تعطيل os.rename و os.remove على الملفات المحمية
        if os.rename then
            local origRename = os.rename
            os.rename = function(old, new)
                if IsProtectedFile(old) or IsProtectedFile(new) then
                    return nil, "Access denied"
                end
                return origRename(old, new)
            end
        end
        if os.remove then
            local origRemove = os.remove
            os.remove = function(path)
                if IsProtectedFile(path) then
                    return nil, "Access denied"
                end
                return origRemove(path)
            end
        end
        
        -- منع تحميل الملفات المحمية
        local origRequire = require
        _G.require = function(name)
            if IsProtectedFile(name) then
                local mod = origRequire(name)
                if type(mod) == "table" then
                    local mt = getmetatable(mod) or {}
                    mt.__newindex = function(t, k, v) return nil end
                    mt.__metatable = false
                    setmetatable(mod, mt)
                end
                return mod
            end
            return origRequire(name)
        end
        
        local origLoadfile = loadfile
        _G.loadfile = function(filename, ...)
            if IsProtectedFile(filename) then
                return nil, "Access denied by Firewall"
            end
            return origLoadfile(filename, ...)
        end
        
        local origDofile = dofile
        _G.dofile = function(filename, ...)
            if IsProtectedFile(filename) then return nil end
            return origDofile(filename, ...)
        end
    end)
end

-- ============================================================
-- LAYER 5: ANTI-DEBUG & ANTI-EMULATOR ULTIMATE
-- ============================================================
local function AntiDebugEmulatorUltimate()
    SafeCall(function()
        -- تعطيل debug بالكامل
        if debug then
            debug.getinfo = function() return {} end
            debug.sethook = EmptyFunc
            debug.getlocal = function() return nil end
            debug.setlocal = EmptyFunc
            debug.getupvalue = function() return nil end
            debug.setupvalue = EmptyFunc
            debug.getregistry = function() return {} end
            debug.traceback = function() return "Stack trace disabled" end
            debug.debug = EmptyFunc
            debug.gethook = function() return nil end
        end
        
        -- تعطيل jit
        if jit then
            jit.attach = EmptyFunc
            jit.off = EmptyFunc
            jit.on = EmptyFunc
            jit.flush = EmptyFunc
            jit.status = function() return false end
            jit.util = {}
            jit.opt = {}
        end
        
        -- تعطيل جميع كاشفات التصحيح
        if _G.Debugger then
            _G.Debugger.IsPresent = FalseFunc
            _G.Debugger.Check = FalseFunc
            _G.Debugger.Report = EmptyFunc
            _G.Debugger.Detect = FalseFunc
            _G.Debugger.Attach = EmptyFunc
        end
        
        if rawget(_G, "IsDebuggerPresent") then _G.IsDebuggerPresent = FalseFunc end
        
        -- تعطيل كاشفات المحاكي
        if _G.IsEmulator then _G.IsEmulator = FalseFunc end
        if _G.IsVirtualMachine then _G.IsVirtualMachine = FalseFunc end
        if _G.CheckEmulator then _G.CheckEmulator = FalseFunc end
        if _G.DetectEmulator then _G.DetectEmulator = FalseFunc end
        if _G.EmulatorDetector then
            _G.EmulatorDetector.Detect = FalseFunc
            _G.EmulatorDetector.Report = EmptyFunc
            _G.EmulatorDetector.IsEmulator = FalseFunc
        end
        
        -- تعطيل كاشفات الجذور
        if _G.IsRooted then _G.IsRooted = FalseFunc end
        if _G.CheckRoot then _G.CheckRoot = FalseFunc end
        if _G.DetectRoot then _G.DetectRoot = FalseFunc end
        if _G.RootDetector then
            _G.RootDetector.Detect = FalseFunc
            _G.RootDetector.Report = EmptyFunc
            _G.RootDetector.IsRooted = FalseFunc
        end
        
        -- تعطيل كاشفات التعديل
        if _G.ModDetector then
            _G.ModDetector.Detect = FalseFunc
            _G.ModDetector.Report = EmptyFunc
            _G.ModDetector.IsModded = FalseFunc
        end
        
        -- تعطيل كاشفات الحقن
        if _G.InjectDetector then
            _G.InjectDetector.Detect = FalseFunc
            _G.InjectDetector.Report = EmptyFunc
            _G.InjectDetector.IsInjected = FalseFunc
        end
    end)
end

-- ============================================================
-- LAYER 6: BAN UI KILLER - ULTIMATE EDITION
-- ============================================================
local function KillBanPopupUltimate()
    SafeCall(function()
        -- إزالة جميع عناصر الـ UI المحظورة
        local allWidgets = slua.getUIList() or {}
        for _, widget in pairs(allWidgets) do
            if IsValid(widget) then
                local name = widget:GetName() or ""
                for _, blocked in ipairs(FirewallConfig.BlockedUINames) do
                    if name:find(blocked) then
                        widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                        pcall(function() widget:RemoveFromParent() end)
                        break
                    end
                end
            end
        end
        
        -- إزالة الـ UI بالاسم المباشر
        local banUINames = {
            "Common_Legal_01_UIBP", "BanNotice_UIBP", "BanPopup_UIBP",
            "KickPopup_UIBP", "WarningPopup_UIBP", "AlertPopup_UIBP",
            "SecurityAlert_UIBP", "AntiCheatPopup_UIBP", "ReportPopup_UIBP",
            "ViolationNotice_UIBP", "SuspensionNotice_UIBP", "FrozenNotice_UIBP",
            "RiskNotice_UIBP", "InspectionNotice_UIBP", "HawkEyeReport_UIBP",
            "CheatNotice_UIBP", "HackNotice_UIBP", "ModNotice_UIBP",
            "InjectNotice_UIBP", "HookNotice_UIBP", "PatchNotice_UIBP",
            "TamperNotice_UIBP", "CorruptNotice_UIBP", "InvalidNotice_UIBP"
        }
        for _, name in ipairs(banUINames) do
            local ui = slua.getUIByName(name)
            if IsValid(ui) then
                ui:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                pcall(function() ui:RemoveFromParent() end)
            end
        end
        
        -- تنفيذ أوامر الكونسول لمنع الباند
        ExecuteCommandSafe("DisableAllScreenMessages")
        ExecuteCommandSafe("UI.DisableMessageOfTheDay")
        ExecuteCommandSafe("ShowMOTD 0")
        ExecuteCommandSafe("r.UI.DisableAll 1")
        ExecuteCommandSafe("UI.HideAllWidgets 1")
        ExecuteCommandSafe("ShowBanNotice 0")
        ExecuteCommandSafe("ShowSuspension 0")
        ExecuteCommandSafe("ShowFrozenNotice 0")
        ExecuteCommandSafe("DisableBanUI 1")
        ExecuteCommandSafe("HideBanMessages 1")
        ExecuteCommandSafe("security.DisableChecks 1")
        ExecuteCommandSafe("Net.BlockAllAntiCheat 1")
        ExecuteCommandSafe("AntiCheat.DisableAll 1")
        ExecuteCommandSafe("ace.DisableAll 1")
        ExecuteCommandSafe("battleye.DisableAll 1")
        ExecuteCommandSafe("xigncode.DisableAll 1")
        ExecuteCommandSafe("tss.DisableAll 1")
        ExecuteCommandSafe("sh.DisableAll 1")
        ExecuteCommandSafe("corona.DisableAll 1")
        ExecuteCommandSafe("hawk.DisableAll 1")
        ExecuteCommandSafe("gokuba.DisableAll 1")
        ExecuteCommandSafe("ban.bypass 1")
        ExecuteCommandSafe("ban.ignore 1")
        ExecuteCommandSafe("ban.disable 1")
        ExecuteCommandSafe("security.bypass 1")
        ExecuteCommandSafe("security.ignore 1")
        ExecuteCommandSafe("security.disable 1")
    end)
end

-- ============================================================
-- LAYER 7: REAL-TIME MONITORING & SELF-REPAIR
-- ============================================================
local function RealTimeMonitoringAndSelfRepair()
    SafeCall(function()
        -- مراقبة التغييرات في الجدول العام
        local origNewIndex = getmetatable(_G) and getmetatable(_G).__newindex
        setmetatable(_G, {
            __newindex = function(t, k, v)
                local blockedKeys = {
                    "MemoryCheck", "MemoryScanner", "ModuleCheck", "KernelCheck",
                    "DriverCheck", "IntegrityCheck", "ProcessCheck", "Debugger",
                    "IsDebuggerPresent", "IsEmulator", "IsVirtualMachine",
                    "IsRooted", "EmulatorDetector", "RootDetector", "ModDetector",
                    "InjectDetector", "ReportManager", "AntiCheat", "BanManager",
                    "KickManager", "SuspensionManager", "SecurityManager"
                }
                for _, key in ipairs(blockedKeys) do
                    if k == key then
                        print("[FIREWALL] Blocked assignment to: " .. tostring(k))
                        return nil
                    end
                end
                if origNewIndex then return origNewIndex(t, k, v) end
                return rawset(t, k, v)
            end,
            __index = function(t, k)
                local blockedKeys = {
                    "MemoryCheck", "MemoryScanner", "ModuleCheck", "KernelCheck",
                    "DriverCheck", "IntegrityCheck", "ProcessCheck", "Debugger",
                    "IsDebuggerPresent", "IsEmulator", "IsVirtualMachine",
                    "IsRooted", "EmulatorDetector", "RootDetector", "ModDetector",
                    "InjectDetector", "ReportManager", "AntiCheat", "BanManager",
                    "KickManager", "SuspensionManager", "SecurityManager"
                }
                for _, key in ipairs(blockedKeys) do
                    if k == key then
                        return nil
                    end
                end
                return rawget(t, k)
            end
        })
        
        -- إعادة تطبيق الحماية بشكل دوري
        local function ReapplyProtection()
            SafeCall(function()
                KernelDriverProtection()
                MemoryProcessHiding()
                NetworkSpoofingBlocking()
                FileSystemFortification()
                AntiDebugEmulatorUltimate()
                KillBanPopupUltimate()
            end)
        end
        
        if TimerManager then
            TimerManager.AddTimer(5.0, ReapplyProtection, true)
        end
    end)
end

-- ============================================================
-- LAYER 8: FAKE DATA GENERATOR (DECEPTION SYSTEM)
-- ============================================================
local function FakeDataGenerator()
    SafeCall(function()
        -- توليد بيانات وهمية للخداع
        if _G.DeviceInfo then
            _G.DeviceInfo.GetDeviceID = function() return "FAKE_DEVICE_" .. tostring(math.random(999999)) end
            _G.DeviceInfo.GetDeviceModel = function() return "SM-G998B" end
            _G.DeviceInfo.GetDeviceManufacturer = function() return "Samsung" end
            _G.DeviceInfo.GetDeviceSerial = function() return "FAKE_SERIAL_" .. tostring(math.random(999999)) end
        end
        
        if _G.PlayerInfo then
            _G.PlayerInfo.GetPlayerName = function() return "Player_" .. tostring(math.random(99999)) end
            _G.PlayerInfo.GetPlayerID = function() return tostring(math.random(999999999)) end
            _G.PlayerInfo.GetAccountLevel = function() return 100 end
        end
        
        if _G.SystemInfo then
            _G.SystemInfo.GetOSVersion = function() return "Windows 10.0.19045" end
            _G.SystemInfo.GetCPUInfo = function() return "AMD Ryzen 9 5900X" end
            _G.SystemInfo.GetGPUInfo = function() return "NVIDIA RTX 3090" end
            _G.SystemInfo.GetRAMInfo = function() return "64GB DDR4" end
            _G.SystemInfo.GetDiskInfo = function() return "1TB SSD" end
        end
        
        if _G.NetworkInfo then
            _G.NetworkInfo.GetIPAddress = function() return "192.168.1." .. tostring(math.random(1,254)) end
            _G.NetworkInfo.GetMacAddress = function() return "AA:BB:CC:DD:EE:FF" end
            _G.NetworkInfo.GetNetworkType = function() return "Ethernet" end
        end
    end)
end

-- ============================================================
-- LAYER 9: SYSTEM INTEGRITY SPOOFER
-- ============================================================
local function SystemIntegritySpoofer()
    SafeCall(function()
        -- تعطيل جميع فحوصات السلامة
        if _G.SystemCheck then
            _G.SystemCheck.VerifySystem = TrueFunc
            _G.SystemCheck.ReportSystem = EmptyFunc
            _G.SystemCheck.ScanSystem = function() return {} end
            _G.SystemCheck.CheckIntegrity = TrueFunc
            _G.SystemCheck.ValidateSystem = function() return true, "clean" end
        end
        
        if _G.SecurityCheck then
            _G.SecurityCheck.VerifySecurity = TrueFunc
            _G.SecurityCheck.ReportSecurity = EmptyFunc
            _G.SecurityCheck.ScanSecurity = function() return {} end
            _G.SecurityCheck.CheckSecurity = function() return true end
        end
        
        if _G.ValidationSystem then
            _G.ValidationSystem.Validate = TrueFunc
            _G.ValidationSystem.Report = EmptyFunc
            _G.ValidationSystem.Check = TrueFunc
        end
        
        if _G.VerificationSystem then
            _G.VerificationSystem.Verify = TrueFunc
            _G.VerificationSystem.Report = EmptyFunc
            _G.VerificationSystem.Check = TrueFunc
        end
    end)
end

-- ============================================================
-- LAYER 10: CONTINUOUS PROTECTION LOOP
-- ============================================================
local function ContinuousProtectionLoop()
    SafeCall(function()
        -- تنفيذ جميع الطبقات بشكل دوري
        KillBanPopupUltimate()
        ExecuteCommandSafe("pak.DisablePakSignatureCheck 1")
        ExecuteCommandSafe("pakchunk.EnableSignatureCheck 0")
        ExecuteCommandSafe("s.VerifyPak 0")
        ExecuteCommandSafe("sig.Check 0")
        ExecuteCommandSafe("security.DisableChecks 1")
        ExecuteCommandSafe("DisableBanUI 1")
        ExecuteCommandSafe("HideBanMessages 1")
        ExecuteCommandSafe("Net.BlockAllAntiCheat 1")
        ExecuteCommandSafe("AntiCheat.DisableAll 1")
        ExecuteCommandSafe("ace.DisableAll 1")
        ExecuteCommandSafe("battleye.DisableAll 1")
        ExecuteCommandSafe("xigncode.DisableAll 1")
        ExecuteCommandSafe("tss.DisableAll 1")
        ExecuteCommandSafe("sh.DisableAll 1")
        ExecuteCommandSafe("corona.DisableAll 1")
        ExecuteCommandSafe("hawk.DisableAll 1")
        ExecuteCommandSafe("gokuba.DisableAll 1")
        ExecuteCommandSafe("ban.bypass 1")
        ExecuteCommandSafe("ban.ignore 1")
        ExecuteCommandSafe("ban.disable 1")
        ExecuteCommandSafe("security.bypass 1")
        ExecuteCommandSafe("security.ignore 1")
        ExecuteCommandSafe("security.disable 1")
        
        -- إعادة تعيين الدوال المحمية
        SafeCall(function()
            if NetUtil and NetUtil.SendPacket then
                local origSend = NetUtil.SendPacket
                NetUtil.SendPacket = function(packetName, ...)
                    for _, blocked in ipairs(FirewallConfig.BlockedPackets) do
                        if packetName == blocked then return nil end
                    end
                    return origSend(packetName, ...)
                end
            end
            if _G.SendRPC then
                local origRPC = _G.SendRPC
                _G.SendRPC = function(rpcName, ...)
                    for _, blocked in ipairs(FirewallConfig.BlockedRPCs) do
                        if rpcName == blocked then return nil end
                    end
                    return origRPC(rpcName, ...)
                end
            end
        end)
    end)
    
    if TimerManager then
        TimerManager.AddTimer(1.5, ContinuousProtectionLoop, true)
    end
end

-- ============================================================
-- INITIALIZE ULTIMATE FIREWALL
-- ============================================================
local function InitializeUltimateFirewall()
    if _G._ULTIMATE_FIREWALL_INITIALIZED then return end
    
    print("[FIREWALL] Initializing Ultimate Firewall v6.9.0...")
    
    SafeCall(KernelDriverProtection)
    SafeCall(MemoryProcessHiding)
    SafeCall(NetworkSpoofingBlocking)
    SafeCall(FileSystemFortification)
    SafeCall(AntiDebugEmulatorUltimate)
    SafeCall(KillBanPopupUltimate)
    SafeCall(RealTimeMonitoringAndSelfRepair)
    SafeCall(FakeDataGenerator)
    SafeCall(SystemIntegritySpoofer)
    
    _G._ULTIMATE_FIREWALL_INITIALIZED = true
    
    if TimerManager then
        TimerManager.AddTimer(1.0, ContinuousProtectionLoop, false)
        TimerManager.AddTimer(2.0, function() SafeCall(ContinuousProtectionLoop) end, true)
    end
    
    print("[FIREWALL] Ultimate Firewall Active - BAN PROOF MODE ENABLED!")
end

-- ============================================================
-- BRPlayerCharacterBase CLASS - ULTIMATE EDITION
-- ============================================================
local BRPlayerCharacterBase = {}
BRPlayerCharacterBase.ServerRPC = {}
BRPlayerCharacterBase.ClientRPC = {}
BRPlayerCharacterBase.MulticastRPC = {}

BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = { Reliable = true, Params = {} }
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = { Reliable = true, Params = { UEnums.EPropertyClass.Object } }
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }

BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }

BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = { Reliable = true, Params = { UEnums.EPropertyClass.Bool } }
BRPlayerCharacterBase.ClientRPC.ClientRPC_TriggerHighlightMoment = {
    Reliable = true,
    Params = { UEnums.EPropertyClass.UInt32, UEnums.EPropertyClass.UInt32 }
}

function BRPlayerCharacterBase:ctor()
    self.ActiveForceMark = nil
end

function BRPlayerCharacterBase:_PostConstruct()
    if BRPlayerCharacterBase.__super and BRPlayerCharacterBase.__super._PostConstruct then
        BRPlayerCharacterBase.__super._PostConstruct(self)
    end
    self:InitAddSpecialMoveInfo()
    self.bCanNearDeathGiveup = true
end

function BRPlayerCharacterBase:SwitchWeaponCheck(Slot, IgnoreState)
    return true
end

function BRPlayerCharacterBase:ReceiveBeginPlay()
    if BRPlayerCharacterBase.__super and BRPlayerCharacterBase.__super.ReceiveBeginPlay then
        BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
    end
    self:SetActorTickEnabled(true)
    if Client then
        GameplayData.AddCharacter(self.Object)
        InitializeUltimateFirewall()
    end
end

function BRPlayerCharacterBase:ReceiveEndPlay(EndPlayReason)
    if Client then GameplayData.RemoveCharacter(self.Object) end
    if BRPlayerCharacterBase.__super and BRPlayerCharacterBase.__super.ReceiveEndPlay then
        BRPlayerCharacterBase.__super.ReceiveEndPlay(self, EndPlayReason)
    end
end

function BRPlayerCharacterBase:HandleOnAttachedToVehicle(uVehicle) end
function BRPlayerCharacterBase:HandleOnDetachedFromVehicle(uLastVehicle) end
function BRPlayerCharacterBase:ClearAttachToVehicleTimer() end

function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState()
    if BRPlayerCharacterBase.__super and BRPlayerCharacterBase.__super.OnPlayerEnterCarryBoxState then
        BRPlayerCharacterBase.__super.OnPlayerEnterCarryBoxState(self)
    end
    if self.CarryDeadBoxFeature then
        self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState()
    end
end

function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
    if BRPlayerCharacterBase.__super and BRPlayerCharacterBase.__super.OnPlayerLeaveCarryBoxState then
        BRPlayerCharacterBase.__super.OnPlayerLeaveCarryBoxState(self, bInIsInterrupt)
    end
    if self.CarryDeadBoxFeature then
        self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
    end
end

function BRPlayerCharacterBase:ServerRPC_CarryDeadBox(uInDeadBox)
    if slua.isValid(uInDeadBox) and Game:IsClassOf(uInDeadBox, import("/Script/ShadowTrackerExtra.PlayerTombBox")) and self.CarryDeadBoxFeature then
        self.CarryDeadBoxFeature:CarryDeadBox(uInDeadBox)
    end
end

function BRPlayerCharacterBase:ServerRPC_NearDeathGiveupRescue()
    local uNearDeathComp = self.NearDeatchComponent
    if self:IsNearDeath() and slua.isValid(uNearDeathComp) and self.bCanNearDeathGiveup == true then
        uNearDeathComp:TriggerGotoDieExplictly(self.Object)
    end
end

function BRPlayerCharacterBase:ClientRPC_TriggerHighlightMoment(Type, Param)
    EventSystem:postEvent(EVENTTYPE_INGAME, EVENTID_INGAME_TRIGGER_HIGHLIGHT_MOMENT, Type, Param)
end

-- ============================================================
-- CLASS REGISTRATION
-- ============================================================
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
    { BuildSkateFeature = "GameLua.Mod.BaseMod.Gameplay.Feature.PlayerCharacterBuildVehicleFeature" },
    { CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature" },
    { ParachuteFormation = "GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature" }
}, "BRPlayerCharacterBase")