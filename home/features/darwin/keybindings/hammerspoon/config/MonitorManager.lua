-- ============================================================================
-- MonitorManager.lua
-- Intelligent layout management for multi-monitor setups with state persistence
-- ============================================================================

local MonitorManager = {}

-- ============================================================================
-- CONFIGURATION & CONSTANTS
-- ============================================================================

-- Workspace Configuration
-- Adjust these values to change workspace behavior
local TOTAL_WORKSPACES = 9                          -- Total number of workspaces (1 to N)
local HOME_OFFICE_VERTICAL_WORKSPACES = {6, 7}      -- Workspaces to use vertical layout on LG monitor

-- External Dependencies
local AEROSPACE = "/run/current-system/sw/bin/aerospace"  -- AeroSpace binary path
local LG_HDR_4K_NAME = "LG HDR 4K"                      -- Monitor name for detection

-- State Storage
local workspaceState = {
    savedState = {},                    -- Monitor -> Workspace mapping
    currentFocusedWorkspace = nil       -- Currently focused workspace
}

-- Runtime State
local screenWatcher = nil
local lastScreenCount = 0
local isApplying = false  -- Prevent concurrent applications

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Generate workspace array based on total workspaces
local function generateWorkspaceArray()
    local workspaces = {}
    for i = 1, TOTAL_WORKSPACES do
        table.insert(workspaces, i)
    end
    return workspaces
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

-- ============================================================================
-- MONITOR DETECTION & MANAGEMENT
-- ============================================================================

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

-- ============================================================================
-- WORKSPACE STATE PERSISTENCE
-- ============================================================================

-- Capture current workspace state across all monitors
local function captureWorkspaceState(callback)
    workspaceState.savedState = {}
    
    -- Get focused workspace first
    hs.task.new(AEROSPACE, function(exitCode, stdout, stderr)
        if exitCode == 0 and stdout then
            workspaceState.currentFocusedWorkspace = tonumber(stdout:match("%d+"))
        end
        
        -- Get all monitors and their workspaces
        hs.task.new(AEROSPACE, function(exitCode2, stdout2, stderr2)
            if exitCode2 == 0 and stdout2 then
                -- Parse monitor information
                local monitors = {}
                for line in stdout2:gmatch("[^\r\n]+") do
                    local monitorId, monitorName = line:match("^(%d+)%s+(.+)$")
                    if monitorId and monitorName then
                        monitors[tonumber(monitorId)] = monitorName:gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
                    end
                end
                
                -- For each monitor, find which workspace is visible
                local monitorCount = 0
                local processedCount = 0
                
                for monitorId, monitorName in pairs(monitors) do
                    monitorCount = monitorCount + 1
                end
                
                if monitorCount == 0 then
                    if callback then callback() end
                    return
                end
                
                for monitorId, monitorName in pairs(monitors) do
                    hs.task.new(AEROSPACE, function(exitCode3, stdout3, stderr3)
                        processedCount = processedCount + 1
                        
                        if exitCode3 == 0 and stdout3 then
                            -- Find visible workspace on this monitor
                            for line in stdout3:gmatch("[^\r\n]+") do
                                local wsId = line:match("^(%d+)")
                                if wsId then
                                    local workspace = tonumber(wsId)
                                    if workspace then
                                        workspaceState.savedState[monitorName] = workspace
                                        break -- Only first (visible) workspace per monitor
                                    end
                                end
                            end
                        end
                        
                        -- Call callback when all monitors processed
                        if processedCount >= monitorCount and callback then
                            callback()
                        end
                    end, {"list-workspaces", "--monitor", tostring(monitorId), "--visible"}):start()
                end
            else
                if callback then callback() end
            end
        end, {"list-monitors"}):start()
    end, {"list-workspaces", "--focused"}):start()
end

-- Restore workspace state to monitors
local function restoreWorkspaceState(callback)
    if not workspaceState.savedState or not next(workspaceState.savedState) then
        if callback then callback() end
        return
    end
    
    print("Restoring workspace state:", hs.inspect(workspaceState.savedState))
    
    local restoreCount = 0
    local totalRestores = 0
    
    -- Count total restores needed
    for monitorName, workspace in pairs(workspaceState.savedState) do
        totalRestores = totalRestores + 1
    end
    
    if totalRestores == 0 then
        if callback then callback() end
        return
    end
    
    -- Restore each workspace to its monitor
    for monitorName, workspace in pairs(workspaceState.savedState) do
        -- Focus the workspace (this will show it on the appropriate monitor)
        hs.task.new(AEROSPACE, function()
            restoreCount = restoreCount + 1
            if restoreCount >= totalRestores then
                -- Finally, restore the originally focused workspace
                if workspaceState.currentFocusedWorkspace then
                    hs.timer.doAfter(0.3, function()
                        hs.task.new(AEROSPACE, function()
                            if callback then callback() end
                        end, {"workspace", tostring(workspaceState.currentFocusedWorkspace)}):start()
                    end)
                else
                    if callback then callback() end
                end
            end
        end, {"workspace", tostring(workspace)}):start()
    end
end

-- Save workspace state to persistent storage
local function saveWorkspaceStateToDisk()
    local stateFile = os.getenv("HOME") .. "/.cache/hammerspoon/workspace-state.json"
    local dir = os.getenv("HOME") .. "/.cache/hammerspoon"
    
    -- Ensure directory exists
    hs.execute("mkdir -p " .. dir)
    
    local stateData = {
        savedState = workspaceState.savedState,
        currentFocusedWorkspace = workspaceState.currentFocusedWorkspace,
        timestamp = os.time(),
        monitorCount = #hs.screen.allScreens()
    }
    
    local jsonData = hs.json.encode(stateData)
    if jsonData then
        local file = io.open(stateFile, "w")
        if file then
            file:write(jsonData)
            file:close()
            print("Workspace state saved to disk")
        end
    end
end

-- Load workspace state from persistent storage
local function loadWorkspaceStateFromDisk()
    local stateFile = os.getenv("HOME") .. "/.cache/hammerspoon/workspace-state.json"
    local file = io.open(stateFile, "r")
    
    if not file then
        return false
    end
    
    local jsonData = file:read("*all")
    file:close()
    
    if not jsonData then
        return false
    end
    
    local stateData = hs.json.decode(jsonData)
    if not stateData then
        return false
    end
    
    -- Check if monitor count matches (workspace preferences don't expire)
    local currentMonitorCount = #hs.screen.allScreens()
    
    if stateData.monitorCount == currentMonitorCount then
        workspaceState.savedState = stateData.savedState or {}
        workspaceState.currentFocusedWorkspace = stateData.currentFocusedWorkspace
        print("Workspace state loaded from disk")
        return true
    else
        print("Workspace state not loaded: monitor count changed (%d -> %d)", 
              stateData.monitorCount or 0, currentMonitorCount)
        return false
    end
end

-- ============================================================================
-- LAYOUT MANAGEMENT
-- ============================================================================

-- Apply layout to all workspaces with state preservation
local function applyLayouts(skipStateCapture)
    local lgConnected = isLGConnected()
    local workspaces = generateWorkspaceArray()
    
    -- Capture current state before applying layouts (unless skipped)
    local function proceedWithLayouts()
        -- Apply layouts sequentially with longer delays
        local function applyNext(index)
            if index > #workspaces then
                -- After all layouts applied, restore workspace state
                hs.timer.doAfter(0.5, function()
                    restoreWorkspaceState(function()
                        saveWorkspaceStateToDisk()
                    end)
                end)
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
    end
    
    if skipStateCapture then
        proceedWithLayouts()
    else
        captureWorkspaceState(proceedWithLayouts)
    end
end

-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

-- Handle monitor changes (docking/undocking)
local function onScreenChange()
    if isApplying then return end  -- Skip if already applying layouts
    
    local currentScreenCount = #hs.screen.allScreens()
    
    -- Only apply layouts if screen count changed
    if currentScreenCount ~= lastScreenCount then
        local previousScreenCount = lastScreenCount
        lastScreenCount = currentScreenCount
        
        print(string.format("Screen count changed: %d -> %d", previousScreenCount, currentScreenCount))
        
        -- Apply layouts after longer delay for system to stabilize
        hs.timer.doAfter(3, function()
            if not isApplying then
                isApplying = true
                
                -- For monitor changes, try to load previous state first
                local stateLoaded = false
                if currentScreenCount > previousScreenCount then
                    -- Monitor connected - try to restore previous state
                    stateLoaded = loadWorkspaceStateFromDisk()
                    if stateLoaded then
                        -- Apply layouts but don't capture current state (we want to restore)
                        applyLayouts(true)
                    end
                end
                
                if not stateLoaded then
                    -- Normal layout application with state capture
                    applyLayouts(false)
                end
                
                -- Reset flag after layouts are done (estimate: workspaces * 0.9s each + buffer)
                hs.timer.doAfter(TOTAL_WORKSPACES + 2, function()
                    isApplying = false
                end)
            end
        end)
    end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

-- Start the MonitorManager
function MonitorManager.start()
    MonitorManager.stop()
    
    lastScreenCount = #hs.screen.allScreens()
    screenWatcher = hs.screen.watcher.new(onScreenChange)
    screenWatcher:start()
    
    -- Apply initial layouts with longer delay
    hs.timer.doAfter(2, function()
        isApplying = true
        
        -- Try to load previous workspace state on startup
        local stateLoaded = loadWorkspaceStateFromDisk()
        if stateLoaded then
            print("Starting MonitorManager with restored workspace state")
            applyLayouts(true)  -- Don't capture state, we want to restore
        else
            print("Starting MonitorManager with fresh layout application")
            applyLayouts(false) -- Normal startup, capture state
        end
        
        hs.timer.doAfter(TOTAL_WORKSPACES + 1, function()
            isApplying = false
        end)
    end)
end

-- Stop the MonitorManager
function MonitorManager.stop()
    if screenWatcher then
        screenWatcher:stop()
        screenWatcher = nil
    end
    isApplying = false
end

-- Manually fix layouts (triggered by alt-m)
function MonitorManager.fix()
    if isApplying then 
        print("MonitorManager: Already applying layouts, skipping...")
        return 
    end
    isApplying = true
    applyLayouts(false) -- Capture state when manually fixing
    hs.timer.doAfter(TOTAL_WORKSPACES + 1, function()
        isApplying = false
    end)
end

-- Manual workspace state management
function MonitorManager.saveState()
    captureWorkspaceState(function()
        saveWorkspaceStateToDisk()
        print("Workspace state captured and saved")
    end)
end

function MonitorManager.restoreState()
    local stateLoaded = loadWorkspaceStateFromDisk()
    if stateLoaded then
        restoreWorkspaceState(function()
            print("Workspace state restored")
        end)
    else
        print("No valid workspace state found to restore")
    end
end

function MonitorManager.clearState()
    workspaceState.savedState = {}
    workspaceState.currentFocusedWorkspace = nil
    local stateFile = os.getenv("HOME") .. "/.cache/hammerspoon/workspace-state.json"
    os.remove(stateFile)
    print("Workspace state cleared")
end

-- Debug and diagnostic information
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
    
    print("\n=== Workspace State ===")
    if next(workspaceState.savedState) then
        print("Saved workspace state:")
        for monitor, workspace in pairs(workspaceState.savedState) do
            print(string.format("  %s: Workspace %d", monitor, workspace))
        end
        if workspaceState.currentFocusedWorkspace then
            print(string.format("Focused workspace: %d", workspaceState.currentFocusedWorkspace))
        end
    else
        print("No workspace state saved")
    end
    
    -- Check disk state
    local stateFile = os.getenv("HOME") .. "/.cache/hammerspoon/workspace-state.json"
    local file = io.open(stateFile, "r")
    if file then
        file:close()
        print(string.format("State file exists: %s", stateFile))
    else
        print("No state file on disk")
    end
end

-- ============================================================================
-- MODULE EXPORT
-- ============================================================================

return MonitorManager 