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

-- Helper: get current layout for a workspace
local function getCurrentLayout(workspaceNum, callback)
    hs.task.new(AEROSPACE, function(exitCode, stdout, stderr)
        if exitCode == 0 then
            -- Example output: "tiles horizontal vertical"
            local layout = stdout:match("layout: ([^\n]+)")
            callback(layout)
        else
            callback(nil)
        end
    end, {"layout", "--workspace", tostring(workspaceNum)}):start()
end

-- Helper: focus a workspace
local function focusWorkspace(workspaceNum, cb)
    hs.task.new(AEROSPACE, function(exitCode, stdout, stderr)
        hs.timer.doAfter(0.2, function() cb() end) -- Give time for focus to settle
    end, {"workspace", tostring(workspaceNum)}):start()
end

-- Determine desired layout for a workspace
local function desiredLayoutFor(ws, lgConnected)
    if lgConnected and ws >= 6 and ws <= 8 then
        return "tiles horizontal vertical" -- side-by-side
    else
        return "tiles vertical horizontal" -- stacking
    end
end

-- Apply layouts to all workspaces 1-0 (1-10)
local function applyAllLayouts()
    local lgConnected = isLGConnected()
    local workspaces = {1,2,3,4,5,6,7,8,9,0}
    -- Remember the currently focused workspace
    hs.task.new(AEROSPACE, function(exitCode, stdout, stderr)
        log("Focused workspace output: " .. tostring(stdout))
        local wsnum = nil
        if stdout then
            wsnum = tonumber(stdout:match("%d+"))
        end
        local originalWorkspace = wsnum

        -- Step 1: Query all workspaces for their current layout
        local toChange = {}
        local checked = 0
        for i, ws in ipairs(workspaces) do
            getCurrentLayout(ws, function(currentLayout)
                local want = desiredLayoutFor(ws, lgConnected)
                if currentLayout ~= want then
                    table.insert(toChange, ws)
                end
                checked = checked + 1
                if checked == #workspaces then
                    -- Step 2: Sequentially focus and apply layout only to those workspaces
                    local idx = 1
                    local function nextChange()
                        if idx > #toChange then
                            -- Restore original workspace focus at the end
                            if originalWorkspace then
                                focusWorkspace(originalWorkspace, function() end)
                            end
                            return
                        end
                        local ws = toChange[idx]
                        idx = idx + 1
                        focusWorkspace(ws, function()
                            local want = desiredLayoutFor(ws, lgConnected)
                            -- Only run layout command on the active workspace, no --workspace argument
                            local layoutCmd = string.format("%s layout %s", AEROSPACE, want)
                            log(string.format("🔧 Setting workspace %d to %s (active only)", ws, want))
                            hs.task.new("/bin/sh", function()
                                hs.timer.doAfter(0.5, nextChange)
                            end, {"-c", layoutCmd}):start()
                        end)
                    end
                    if #toChange > 0 then
                        nextChange()
                    else
                        -- Nothing to change, just restore focus if needed
                        if originalWorkspace then
                            focusWorkspace(originalWorkspace, function() end)
                        end
                    end
                end
            end)
        end
    end, {"list-workspaces", "--focused"}):start()
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