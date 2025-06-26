-- MonitorManager.lua
-- Simple layout management for multi-monitor setups

local MonitorManager = {}

-- Configuration constants
-- Adjust these values to change workspace behavior
local TOTAL_WORKSPACES = 9                          -- Total number of workspaces (1 to N)
local HOME_OFFICE_VERTICAL_WORKSPACES = {6, 7}      -- Workspaces to use vertical layout on LG monitor

-- AeroSpace binary path
local AEROSPACE = "/run/current-system/sw/bin/aerospace"

-- Monitor detection
local LG_HDR_4K_NAME = "LG HDR 4K"

-- Check if LG HDR 4K monitor is connected
local function isLGConnected()
    for _, screen in pairs(hs.screen.allScreens()) do
        local name = screen:name()
        if name and string.find(name, LG_HDR_4K_NAME) then
            return true
        end
    end
    return false
end

-- Check if workspace should use vertical layout (home office setup)
local function isVerticalWorkspace(workspace)
    for _, ws in ipairs(HOME_OFFICE_VERTICAL_WORKSPACES) do
        if ws == workspace then
            return true
        end
    end
    return false
end

-- Get desired layout for workspace based on monitor setup
local function getDesiredLayout(workspace, lgConnected)
    if lgConnected then
        -- Home-Office setup with LG monitor
        if isVerticalWorkspace(workspace) then
            return "tiles vertical"  -- stacking on LG portrait
        else
            return "tiles horizontal"  -- side-by-side (other workspaces)
        end
    else
        -- Office setup without LG monitor
        return "tiles horizontal"  -- all workspaces side-by-side
    end
end

-- Generate workspace array based on total workspaces
local function generateWorkspaceArray()
    local workspaces = {}
    for i = 1, TOTAL_WORKSPACES do
        table.insert(workspaces, i)
    end
    return workspaces
end

-- Apply layout to all workspaces
local function applyLayouts()
    local lgConnected = isLGConnected()
    local workspaces = generateWorkspaceArray()
    
    -- Get current workspace to restore focus later
    hs.task.new(AEROSPACE, function(exitCode, stdout, stderr)
        local originalWorkspace = nil
        if exitCode == 0 and stdout then
            originalWorkspace = tonumber(stdout:match("%d+"))
        end
        
        -- Apply layouts sequentially with longer delays
        local function applyNext(index)
            if index > #workspaces then
                -- Restore original workspace focus after a delay
                if originalWorkspace then
                    hs.timer.doAfter(0.5, function()
                        hs.task.new(AEROSPACE, function() end, {"workspace", tostring(originalWorkspace)}):start()
                    end)
                end
                return
            end
            
            local ws = workspaces[index]
            local layout = getDesiredLayout(ws, lgConnected)
            
            -- Focus workspace first
            hs.task.new(AEROSPACE, function()
                -- Wait longer for workspace to fully focus
                hs.timer.doAfter(0.5, function()
                    -- Apply layout to the now-focused workspace
                    hs.task.new(AEROSPACE, function()
                        -- Wait longer for layout to fully apply before next workspace
                        hs.timer.doAfter(0.4, function()
                            applyNext(index + 1)
                        end)
                    end, {"layout", layout}):start()
                end)
            end, {"workspace", tostring(ws)}):start()
        end
        
        applyNext(1)
    end, {"list-workspaces", "--focused"}):start()
end

-- Monitor change detection
local screenWatcher = nil
local lastScreenCount = 0
local isApplying = false  -- Prevent concurrent applications

local function onScreenChange()
    if isApplying then return end  -- Skip if already applying layouts
    
    local currentScreenCount = #hs.screen.allScreens()
    
    -- Only apply layouts if screen count changed
    if currentScreenCount ~= lastScreenCount then
        lastScreenCount = currentScreenCount
        
        -- Apply layouts after longer delay for system to stabilize
        hs.timer.doAfter(3, function()
            if not isApplying then
                isApplying = true
                applyLayouts()
                -- Reset flag after layouts are done (estimate: workspaces * 0.9s each + buffer)
                hs.timer.doAfter(TOTAL_WORKSPACES + 1, function()
                    isApplying = false
                end)
            end
        end)
    end
end

-- Public API
function MonitorManager.start()
    MonitorManager.stop()
    
    lastScreenCount = #hs.screen.allScreens()
    screenWatcher = hs.screen.watcher.new(onScreenChange)
    screenWatcher:start()
    
    -- Apply initial layouts with longer delay
    hs.timer.doAfter(2, function()
        isApplying = true
        applyLayouts()
        hs.timer.doAfter(TOTAL_WORKSPACES, function()
            isApplying = false
        end)
    end)
end

function MonitorManager.stop()
    if screenWatcher then
        screenWatcher:stop()
        screenWatcher = nil
    end
    isApplying = false
end

function MonitorManager.fix()
    if isApplying then 
        print("MonitorManager: Already applying layouts, skipping...")
        return 
    end
    isApplying = true
    applyLayouts()
    hs.timer.doAfter(TOTAL_WORKSPACES, function()
        isApplying = false
    end)
end

function MonitorManager.debug()
    local lgConnected = isLGConnected()
    
    print("=== MonitorManager Configuration ===")
    print(string.format("Total Workspaces: %d", TOTAL_WORKSPACES))
    print(string.format("Vertical Workspaces: %s", table.concat(HOME_OFFICE_VERTICAL_WORKSPACES, ", ")))
    print(string.format("Screens: %d, LG Connected: %s, Applying: %s", 
        #hs.screen.allScreens(), tostring(lgConnected), tostring(isApplying)))
    
    print("\n=== Available Screens ===")
    for i, screen in pairs(hs.screen.allScreens()) do
        print(string.format("Screen %d: %s", i, screen:name() or "Unknown"))
    end
    
    print("\n=== Workspace Layout Preview ===")
    for i = 1, TOTAL_WORKSPACES do
        local layout = getDesiredLayout(i, lgConnected)
        print(string.format("Workspace %d: %s", i, layout))
    end
end

return MonitorManager 