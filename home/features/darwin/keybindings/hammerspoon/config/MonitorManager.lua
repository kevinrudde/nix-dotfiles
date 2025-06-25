-- MonitorManager.lua
-- AeroSpace layout management for multi-monitor setups
-- Handles LG HDR 4K portrait display with proper screen detection

local MonitorManager = {}

-- AeroSpace binary path
local AEROSPACE = "/run/current-system/sw/bin/aerospace"

-- Monitor name to detect
local LG_HDR_4K_NAME = "LG HDR 4K"

-- Debug function to log with timestamp
local function log(message)
    local timestamp = os.date("%H:%M:%S")
    hs.console.printStyledtext(string.format("[%s] %s", timestamp, message))
end

-- Check if LG HDR 4K monitor is connected using proper screen detection
local function isLGConnected()
    -- Use screenPositions for better detection
    local screenPositions = hs.screen.screenPositions()
    
    for screen, position in pairs(screenPositions) do
        local name = screen:name()
        if name and string.find(name, LG_HDR_4K_NAME) then
            log(string.format("🖥️  LG HDR 4K found: %s at position {x=%d, y=%d}", 
                name, position.x, position.y))
            return true
        end
    end
    
    return false
end

-- Get current workspace and monitor information
local function getCurrentWorkspaceInfo(callback)
    hs.task.new(AEROSPACE, function(exitCode, stdout, stderr)
        if exitCode == 0 then
            local workspace = stdout:gsub("%s+", "")
            local workspaceNum = tonumber(workspace)
            
            -- Also get monitor info
            hs.task.new(AEROSPACE, function(exitCode2, stdout2, stderr2)
                local monitorInfo = {}
                if exitCode2 == 0 then
                    for line in stdout2:gmatch("[^\r\n]+") do
                        -- Parse monitor list output
                        if line:match("Monitor") then
                            table.insert(monitorInfo, line)
                        end
                    end
                end
                
                callback(workspaceNum, monitorInfo)
            end, {"list-monitors"}):start()
        else
            callback(nil, {})
        end
    end, {"list-workspaces", "--focused"}):start()
end

-- Apply layout based on workspace and monitor configuration
local function applyLayoutToWorkspace(workspaceNum, isLGConnected)
    if not workspaceNum then 
        log("❌ Cannot apply layout: invalid workspace")
        return 
    end
    
    -- Determine if this workspace should use stacking (portrait) layout
    local shouldStack = isLGConnected and (workspaceNum >= 6 and workspaceNum <= 8)
    
    -- AeroSpace layout parameters
    -- For side-by-side: "tiles horizontal vertical"
    -- For stacking: "tiles vertical horizontal"
    local primary = shouldStack and "vertical" or "horizontal"
    local secondary = shouldStack and "horizontal" or "vertical"
    
    -- Create the layout command
    local layoutCmd = string.format("%s layout --workspace %d tiles %s %s", 
        AEROSPACE, workspaceNum, primary, secondary)
    
    log(string.format("🔧 Applying to workspace %d: %s %s", 
        workspaceNum, primary, secondary))
    
    hs.task.new("/bin/sh", function(exitCode, stdout, stderr)
        local status = exitCode == 0 and "✅" or "❌"
        local layoutType = shouldStack and "STACKING" or "SIDE-BY-SIDE"
        local reason = isLGConnected and 
            (shouldStack and "(LG portrait mode)" or "(regular layout)") or 
            "(no LG detected)"
        
        log(string.format("%s Workspace %d: %s %s", 
            status, workspaceNum, layoutType, reason))
            
        if exitCode ~= 0 and stderr and stderr ~= "" then
            log(string.format("❌ Layout error: %s", stderr))
        end
    end, {"-c", layoutCmd}):start()
end

-- Apply layouts to all relevant workspaces
local function applyAllLayouts()
    getCurrentWorkspaceInfo(function(currentWorkspace, monitorInfo)
        local lgConnected = isLGConnected()
        
        log(string.format("🔄 Layout update - LG connected: %s, Current workspace: %s", 
            tostring(lgConnected), tostring(currentWorkspace or "unknown")))
        
        if #monitorInfo > 0 then
            log("📺 Monitors detected by AeroSpace:")
            for _, info in ipairs(monitorInfo) do
                log("   " .. info)
            end
        end
        
        -- Apply layout to current workspace first
        if currentWorkspace then
            applyLayoutToWorkspace(currentWorkspace, lgConnected)
        end
        
        -- If LG is connected, also ensure workspaces 6-8 have correct layout
        -- If LG is disconnected, ensure workspaces 6-8 revert to side-by-side
        if lgConnected or (currentWorkspace and currentWorkspace >= 6 and currentWorkspace <= 8) then
            for ws = 6, 8 do
                if ws ~= currentWorkspace then
                    hs.timer.doAfter(0.5 * (ws - 5), function()
                        applyLayoutToWorkspace(ws, lgConnected)
                    end)
                end
            end
        end
    end)
end

-- Monitor change detection with improved logic
local screenWatcher = nil
local lastChangeTime = 0
local CHANGE_COOLDOWN = 3
local lastScreenCount = 0
local lastLGState = false

-- Get simplified screen configuration
local function getScreenConfig()
    local screens = hs.screen.allScreens()
    local count = #screens
    local lgConnected = isLGConnected()
    
    return count, lgConnected
end

local function onScreenChange()
    local now = os.time()
    if (now - lastChangeTime) < CHANGE_COOLDOWN then return end
    
    local currentScreenCount, currentLGState = getScreenConfig()
    
    -- Only trigger if there's a meaningful change
    if currentScreenCount ~= lastScreenCount or currentLGState ~= lastLGState then
        lastScreenCount = currentScreenCount
        lastLGState = currentLGState
        lastChangeTime = now
        
        log(string.format("🔄 Screen change detected: %d screens, LG: %s", 
            currentScreenCount, tostring(currentLGState)))
        
        -- Apply layouts after a brief delay to let the system settle
        hs.timer.doAfter(2, function()
            log("🔧 Applying layouts after screen change...")
            applyAllLayouts()
        end)
    end
end

-- Public API
function MonitorManager.start()
    -- Stop any existing watcher
    MonitorManager.stop()
    
    -- Initialize state tracking
    lastScreenCount, lastLGState = getScreenConfig()
    
    -- Create and start screen watcher
    screenWatcher = hs.screen.watcher.new(onScreenChange)
    screenWatcher:start()
    
    log("🚀 MonitorManager started")
    log(string.format("📺 Initial state: %d screens, LG: %s", 
        lastScreenCount, tostring(lastLGState)))
    
    -- Apply initial layout
    hs.timer.doAfter(1, function()
        log("🔧 Applying initial layouts...")
        applyAllLayouts()
    end)
end

function MonitorManager.stop()
    if screenWatcher then
        screenWatcher:stop()
        screenWatcher = nil
        log("🛑 MonitorManager stopped")
    else
        log("ℹ️  MonitorManager was not running")
    end
end

-- Manual layout fix
function MonitorManager.fix()
    log("🔧 Manual layout fix requested")
    applyAllLayouts()
end

-- Debug information
function MonitorManager.debug()
    log("🔍 MonitorManager Debug Info:")
    
    -- Screen information using proper Hammerspoon APIs
    local screenPositions = hs.screen.screenPositions()
    local count = 0
    
    for screen, position in pairs(screenPositions) do
        count = count + 1
        local name = screen:name() or "Unknown"
        local frame = screen:frame()
        log(string.format("   Screen %d: %s at {x=%d, y=%d} size=%dx%d", 
            count, name, position.x, position.y, frame.w, frame.h))
    end
    
    log(string.format("📊 Total screens: %d", count))
    log(string.format("🖥️  LG HDR 4K connected: %s", tostring(isLGConnected())))
    
    -- Current workspace info
    getCurrentWorkspaceInfo(function(workspace, monitorInfo)
        if workspace then
            local lgConnected = isLGConnected()
            local shouldStack = lgConnected and (workspace >= 6 and workspace <= 8)
            log(string.format("📍 Current workspace: %d", workspace))
            log(string.format("🎯 Expected layout: %s", 
                shouldStack and "STACKING (vertical)" or "SIDE-BY-SIDE (horizontal)"))
        end
        
        if #monitorInfo > 0 then
            log("🖥️  AeroSpace monitor info:")
            for _, info in ipairs(monitorInfo) do
                log("   " .. info)
            end
        end
    end)
end

-- Check system configuration
function MonitorManager.checkConfig()
    log("🔍 System Configuration Check:")
    
    -- Check if "Displays have separate Spaces" is enabled
    hs.task.new("/usr/bin/defaults", function(exitCode, stdout, stderr)
        if exitCode == 0 then
            local value = stdout:gsub("%s+", "")
            local enabled = (value == "0" or value == "false")
            
            if enabled then
                log("✅ 'Displays have separate Spaces' is DISABLED (recommended for AeroSpace)")
            else
                log("⚠️  'Displays have separate Spaces' is ENABLED")
                log("   Consider disabling for better AeroSpace stability:")
                log("   defaults write com.apple.spaces spans-displays -bool true && killall SystemUIServer")
            end
        else
            log("❓ Could not check 'Displays have separate Spaces' setting")
        end
    end, {"read", "com.apple.spaces", "spans-displays"}):start()
    
    -- Check AeroSpace binary
    hs.task.new("/bin/sh", function(exitCode, stdout, stderr)
        if exitCode == 0 then
            log("✅ AeroSpace binary found: " .. AEROSPACE)
        else
            log("❌ AeroSpace binary not found at: " .. AEROSPACE)
        end
    end, {"-c", "test -x " .. AEROSPACE}):start()
end

return MonitorManager 