-- MonitorManager.lua
-- Simple AeroSpace layout management

local MonitorManager = {}

-- AeroSpace binary path
local AEROSPACE = "/run/current-system/sw/bin/aerospace"

-- Monitor name to detect
local LG_HDR_4K_NAME = "LG HDR 4K"

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

-- Simple layout fix function
local function fixWorkspaceLayout(workspace)
    local currentWorkspace = nil
    
    -- Get current workspace
    hs.task.new(AEROSPACE, function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
            currentWorkspace = stdOut:gsub("%s+$", "")
            
            -- Switch to target workspace, flatten, apply layout, return
            hs.task.new(AEROSPACE, nil, {"workspace", workspace}):start()
            hs.timer.doAfter(0.1, function()
                hs.task.new(AEROSPACE, nil, {"flatten-workspace-tree"}):start()
                hs.timer.doAfter(0.1, function()
                    hs.task.new(AEROSPACE, nil, {"layout", "tiles", "horizontal", "vertical"}):start()
                    hs.console.printStyledtext("Fixed layout for workspace " .. workspace)
                    
                    -- Return to original workspace if different
                    if currentWorkspace ~= workspace then
                        hs.timer.doAfter(0.1, function()
                            hs.task.new(AEROSPACE, nil, {"workspace", currentWorkspace}):start()
                        end)
                    end
                end)
            end)
        end
    end, {"list-workspaces", "--focused"}):start()
end

-- Apply all layouts
local function applyAllLayouts()
    local lgConnected = isLGHDR4KConnected()
    
    if lgConnected then
        hs.console.printStyledtext("🏠 HOME: LG HDR 4K detected")
        hs.console.printStyledtext("⚠️  Manual layout management required for external monitor")
    else
        hs.console.printStyledtext("🏢 OFFICE: No LG - fixing laptop workspaces")
        
        -- Fix main workspaces for laptop mode
        fixWorkspaceLayout("1")
        hs.timer.doAfter(0.5, function()
            fixWorkspaceLayout("6")
        end)
        hs.timer.doAfter(1.0, function()
            fixWorkspaceLayout("7")
        end)
        hs.timer.doAfter(1.5, function()
            fixWorkspaceLayout("8")
        end)
    end
end

-- Track previous screen configuration
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
    table.sort(config)
    return table.concat(config, "|")
end

-- Monitor change callback
local function onScreenChange()
    local currentTime = os.time()
    local currentConfig = getScreenConfig()
    
    if currentConfig ~= previousScreenConfig and (currentTime - lastApplyTime) > APPLY_COOLDOWN then
        previousScreenConfig = currentConfig
        lastApplyTime = currentTime
        
        hs.timer.doAfter(2, function()
            hs.console.printStyledtext("🔄 Screen configuration changed")
            applyAllLayouts()
        end)
    end
end

-- Start monitoring
function MonitorManager.start()
    previousScreenConfig = getScreenConfig()
    lastApplyTime = os.time()
    
    -- Watch for screen configuration changes
    MonitorManager.watcher = hs.screen.watcher.new(onScreenChange)
    MonitorManager.watcher:start()
    
    hs.console.printStyledtext("MonitorManager started - manual mode")
end

-- Stop monitoring
function MonitorManager.stop()
    if MonitorManager.watcher then
        MonitorManager.watcher:stop()
        MonitorManager.watcher = nil
    end
end

-- Manual trigger
function MonitorManager.applyLayouts()
    hs.console.printStyledtext("Manual layout fix triggered")
    applyAllLayouts()
end

-- Debug function
function MonitorManager.debugMonitors()
    local screens = hs.screen.allScreens()
    local monitorNames = {}
    for _, screen in ipairs(screens) do
        table.insert(monitorNames, screen:name() or "Unknown")
    end
    hs.console.printStyledtext("Connected monitors: " .. table.concat(monitorNames, ", "))
    hs.console.printStyledtext("LG HDR 4K Connected: " .. tostring(isLGHDR4KConnected()))
end

return MonitorManager 