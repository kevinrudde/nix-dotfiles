-- MonitorManager.lua
-- Automatically manages AeroSpace layouts based on connected monitors

local MonitorManager = {}

-- AeroSpace binary path
local AEROSPACE = "/run/current-system/sw/bin/aerospace"

-- Monitor name to detect (adjust if needed)
local LG_HDR_4K_NAME = "LG HDR 4K"

-- Workspaces assigned to LG HDR 4K
local LG_WORKSPACES = {"6", "7", "8"}

-- Execute aerospace command with proper argument handling
local function aerospaceExec(cmdArray)
    hs.task.new(AEROSPACE, function(exitCode, stdOut, stdErr)
        if exitCode ~= 0 then
            -- Only show errors that aren't expected/normal
            local cmdStr = table.concat(cmdArray, " ")
            if stdErr ~= "" and 
               not string.find(stdErr, "No window is focused") and
               not string.find(stdErr, "The window is non%-tiling") then
                hs.console.printStyledtext("AeroSpace command failed: " .. cmdStr .. "\nError: " .. stdErr)
            end
        end
    end, cmdArray):start()
end

-- List connected monitors for logging
local function logConnectedMonitors()
    local screens = hs.screen.allScreens()
    local monitorNames = {}
    for _, screen in ipairs(screens) do
        local name = screen:name() or "Unknown"
        table.insert(monitorNames, name)
    end
    hs.console.printStyledtext("Connected monitors: " .. table.concat(monitorNames, ", "))
end

-- Check if LG HDR 4K monitor is connected
local function isLGHDR4KConnected()
    local screens = hs.screen.allScreens()
    
    for _, screen in ipairs(screens) do
        local name = screen:name()
        if name and (name == LG_HDR_4K_NAME or string.match(name, "^LG HDR 4K")) then
            return true
        end
    end
    return false
end

-- Apply layouts based on monitor configuration
local function applyLayouts()
    logConnectedMonitors()
    local lgConnected = isLGHDR4KConnected()
    
    -- Get current workspace to return to it later
    local currentWorkspace = nil
    hs.task.new(AEROSPACE, function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
            currentWorkspace = stdOut:gsub("%s+$", "") -- trim whitespace
        end
    end, {"list-workspaces", "--focused"}):start()
    
    if lgConnected then
        hs.console.printStyledtext("🏠 HOME SETUP: LG HDR 4K detected - Setting HORIZONTAL layouts for workspaces 6, 7, 8")
        -- Set horizontal layout for LG HDR 4K workspaces (for portrait display)
        for i, workspace in ipairs(LG_WORKSPACES) do
            hs.timer.doAfter(i * 0.2, function()  -- Stagger the commands
                aerospaceExec({"workspace", workspace})
                hs.timer.doAfter(0.1, function()
                    aerospaceExec({"layout", "tiles", "horizontal", "vertical"})
                    hs.console.printStyledtext("Applied HORIZONTAL layout to workspace " .. workspace)
                end)
            end)
        end
    else
        hs.console.printStyledtext("🏢 OFFICE SETUP: LG HDR 4K not detected - Setting VERTICAL layouts for workspaces 6, 7, 8")
        -- Set vertical layout for office setup when LG is not connected
        for i, workspace in ipairs(LG_WORKSPACES) do
            hs.timer.doAfter(i * 0.2, function()  -- Stagger the commands
                aerospaceExec({"workspace", workspace})
                hs.timer.doAfter(0.1, function()
                    aerospaceExec({"layout", "tiles", "vertical", "horizontal"})
                    hs.console.printStyledtext("Applied VERTICAL layout to workspace " .. workspace)
                end)
            end)
        end
    end
    
    -- Return to original workspace after all layouts are applied
    hs.timer.doAfter(1.5, function()
        if currentWorkspace then
            aerospaceExec({"workspace", currentWorkspace})
            hs.console.printStyledtext("Returned to workspace " .. currentWorkspace)
        end
    end)
end

-- Track previous screen configuration to avoid false triggers
local previousScreenConfig = nil
local lastApplyTime = 0
local APPLY_COOLDOWN = 5 -- seconds

-- Get current screen configuration signature
local function getScreenConfig()
    local screens = hs.screen.allScreens()
    local config = {}
    for _, screen in ipairs(screens) do
        local name = screen:name() or "Unknown"
        local frame = screen:frame()
        table.insert(config, name .. ":" .. frame.w .. "x" .. frame.h)
    end
    table.sort(config) -- Sort to ensure consistent comparison
    return table.concat(config, "|")
end

-- Monitor change callback with debouncing
local function onScreenChange()
    local currentTime = os.time()
    local currentConfig = getScreenConfig()
    
    -- Only apply if configuration actually changed and cooldown period has passed
    if currentConfig ~= previousScreenConfig and (currentTime - lastApplyTime) > APPLY_COOLDOWN then
        previousScreenConfig = currentConfig
        lastApplyTime = currentTime
        
        hs.timer.doAfter(2, function()  -- Delay to let system settle
            hs.console.printStyledtext("🔄 Screen hardware configuration changed - reapplying layouts...")
            applyLayouts()
        end)
    end
end

-- Start monitoring
function MonitorManager.start()
    -- Initialize screen configuration tracking
    previousScreenConfig = getScreenConfig()
    lastApplyTime = os.time()
    
    -- Apply layouts on startup
    hs.timer.doAfter(2, function()  -- Initial delay for system startup
        hs.console.printStyledtext("MonitorManager: Applying initial layouts...")
        applyLayouts()
    end)
    
    -- Watch for screen configuration changes
    MonitorManager.watcher = hs.screen.watcher.new(onScreenChange)
    MonitorManager.watcher:start()
    
    hs.console.printStyledtext("MonitorManager started - watching for display changes")
end

-- Stop monitoring
function MonitorManager.stop()
    if MonitorManager.watcher then
        MonitorManager.watcher:stop()
        MonitorManager.watcher = nil
    end
end

-- Manual trigger (for testing or manual execution)
function MonitorManager.applyLayouts()
    hs.console.printStyledtext("Manual applyLayouts() triggered")
    applyLayouts()
end

-- Debug function (for manual troubleshooting if needed)
function MonitorManager.debugMonitors()
    logConnectedMonitors()
    local lgConnected = isLGHDR4KConnected()
    hs.console.printStyledtext("LG HDR 4K Connected: " .. tostring(lgConnected))
end

return MonitorManager 