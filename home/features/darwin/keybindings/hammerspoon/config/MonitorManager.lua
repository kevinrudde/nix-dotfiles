-- MonitorManager.lua
-- Automatically manages AeroSpace layouts based on connected monitors

local MonitorManager = {}

-- AeroSpace binary path
local AEROSPACE = "/run/current-system/sw/bin/aerospace"

-- Monitor name to detect (adjust if needed)
local LG_HDR_4K_NAME = "LG HDR 4K"

-- Workspaces assigned to LG HDR 4K
local LG_WORKSPACES = {"6", "7", "8"}

-- Execute aerospace command
local function aerospaceExec(cmd)
    hs.task.new(AEROSPACE, function(exitCode, stdOut, stdErr)
        if exitCode ~= 0 then
            hs.console.printStyledtext("AeroSpace command failed: " .. cmd .. "\nError: " .. stdErr)
        end
    end, {cmd}):start()
end

-- Check if LG HDR 4K monitor is connected
local function isLGHDR4KConnected()
    local screens = hs.screen.allScreens()
    for _, screen in ipairs(screens) do
        local name = screen:name()
        if name and string.find(name, LG_HDR_4K_NAME) then
            return true
        end
    end
    return false
end

-- Apply layouts based on monitor configuration
local function applyLayouts()
    local lgConnected = isLGHDR4KConnected()
    
    -- Get current workspace to return to it later
    local currentWorkspace = nil
    hs.task.new(AEROSPACE, function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
            currentWorkspace = stdOut:gsub("%s+$", "") -- trim whitespace
        end
    end, {"list-workspaces", "--focused"}):start()
    
    if lgConnected then
        hs.console.printStyledtext("LG HDR 4K detected - Setting horizontal layouts for workspaces 6, 7, 8")
        -- Set horizontal layout for LG HDR 4K workspaces (for portrait display)
        for i, workspace in ipairs(LG_WORKSPACES) do
            hs.timer.doAfter(i * 0.2, function()  -- Stagger the commands
                aerospaceExec("workspace " .. workspace)
                hs.timer.doAfter(0.1, function()
                    aerospaceExec("layout tiles horizontal")
                    hs.console.printStyledtext("Applied horizontal layout to workspace " .. workspace)
                end)
            end)
        end
    else
        hs.console.printStyledtext("LG HDR 4K not detected - Setting vertical layouts for workspaces 6, 7, 8")
        -- Set vertical layout for laptop screen when LG is not connected
        for i, workspace in ipairs(LG_WORKSPACES) do
            hs.timer.doAfter(i * 0.2, function()  -- Stagger the commands
                aerospaceExec("workspace " .. workspace)
                hs.timer.doAfter(0.1, function()
                    aerospaceExec("layout tiles vertical")
                    hs.console.printStyledtext("Applied vertical layout to workspace " .. workspace)
                end)
            end)
        end
    end
    
    -- Return to original workspace after all layouts are applied
    hs.timer.doAfter(1.5, function()
        if currentWorkspace then
            aerospaceExec("workspace " .. currentWorkspace)
            hs.console.printStyledtext("Returned to workspace " .. currentWorkspace)
        end
    end)
end

-- Monitor change callback
local function onScreenChange()
    hs.timer.doAfter(1, function()  -- Delay to let system settle
        applyLayouts()
    end)
end

-- Start monitoring
function MonitorManager.start()
    -- Apply layouts on startup
    hs.timer.doAfter(2, function()  -- Initial delay for system startup
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
    applyLayouts()
end

return MonitorManager 