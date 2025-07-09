-- ============================================================================
-- MonitorManager.lua - WORKSPACE STATE MANAGEMENT
-- Handles workspace persistence across monitor changes and sleep/resume events
-- ============================================================================

local MonitorManager = {}

-- ============================================================================
-- AI AGENT DOCUMENTATION - CURRENT IMPLEMENTATION
-- ============================================================================

--[[
===============================================================================
                           IMPLEMENTED FEATURES
===============================================================================

✅ WORKSPACE STATE PERSISTENCE:
- Automatically saves workspace assignments across all monitors
- Detects monitor connect/disconnect events (dock/undock)
- Detects system sleep/resume events
- Restores workspace state after monitor or sleep changes

✅ CURRENT KEYBINDING:
- Alt+T: Layout toggle (handled by AeroSpace directly)
- Command: "exec-and-forget /run/current-system/sw/bin/aerospace layout tiles horizontal vertical"
- Location: modules/darwin/aerospace/default.nix

✅ EVENT HANDLING:
- Monitor changes: hs.screen.watcher for dock/undock detection
- Sleep/resume: hs.caffeinate.watcher for sleep state detection
- State persistence: JSON file storage in ~/.cache/hammerspoon/

✅ ROBUSTNESS FEATURES:
- Error handling for failed AeroSpace commands
- Race condition prevention with operation queuing
- State validation before restoration
- Resource cleanup and timeout handling
- Configurable delays and retry logic

✅ CURRENT IMPLEMENTATION SCOPE:
This MonitorManager handles:
1. Monitor setup change detection
2. System sleep/resume detection  
3. Workspace state capture and restoration
4. Persistent storage across sessions
5. Error recovery and logging

NOT IMPLEMENTED (still available via AeroSpace):
- Layout toggle (Alt+T uses AeroSpace directly)
- Manual layout switching (use AeroSpace modes)
- Per-workspace layout memory (use AeroSpace's built-in state)

===============================================================================
                        WHAT STILL NEEDS REIMPLEMENTATION
===============================================================================

❌ NOT YET IMPLEMENTED:
- Per-workspace layout memory beyond current session
- Automatic layout switching based on monitor configuration
- Custom layout logic beyond AeroSpace's built-in options
- Visual feedback about current layout state
- Manual layout functions (setHorizontal, setVertical, etc.)

If you need these features, see REIMPLEMENTATION GUIDE below.

===============================================================================
                             TECHNICAL DETAILS
===============================================================================

AEROSPACE COMMANDS USED:
- `aerospace list-workspaces --focused` - Get current workspace
- `aerospace list-monitors` - Get monitor information
- `aerospace list-workspaces --monitor X --visible` - Get visible workspace per monitor
- `aerospace workspace X` - Switch to workspace X

STORAGE:
- File: ~/.cache/hammerspoon/workspace-state.json
- Format: { savedState: {monitor: workspace}, currentFocusedWorkspace: number, timestamp: number, monitorCount: number }

EVENT WATCHERS:
- hs.screen.watcher - Monitor connect/disconnect
- hs.caffeinate.watcher - System sleep/resume

TIMING & SAFETY:
- Configurable delays for system stabilization
- Operation queuing to prevent race conditions
- Timeout handling for stuck operations
- State validation before restoration
- Resource cleanup for file operations

===============================================================================
                         AEROSPACE INTEGRATION
===============================================================================

CURRENT KEYBINDINGS (from aerospace/default.nix):
# Main Mode
- Alt+T: Layout toggle
- Alt+1-5: Workspaces 1-5  
- Alt+F1-F4: Workspaces 6-9
- Alt+Shift+P/N: Previous/Next workspace
- Alt+Shift+1-5/F1-F4: Move window to workspace + follow
- Alt+Arrow: Focus window (with wrap-around)
- Alt+Shift+Arrow: Move window
- Alt+Cmd+Arrow: Focus monitor
- Alt+Shift+Cmd+Arrow: Move window to monitor

WORKSPACE TO MONITOR ASSIGNMENTS:
- Workspaces 1-5: "main" monitor
- Workspaces 6-7: "LG HDR 4K" monitor (fallback to main)
- Workspaces 8-9: "built-in" monitor (fallback to main)

===============================================================================
                           REIMPLEMENTATION GUIDE
===============================================================================

TO ADD MANUAL LAYOUT FUNCTIONS:
1. Add layout state tracking
2. Add manual toggle functions
3. Update aerospace keybinding to call Lua instead of direct command

TO ADD PER-WORKSPACE LAYOUT MEMORY:
1. Extend state storage to include layout per workspace
2. Add layout application on workspace switch
3. Integrate with existing state persistence

TO ADD AUTOMATIC LAYOUT SWITCHING:
1. Add monitor detection logic
2. Add layout rules based on monitor setup
3. Integrate with existing monitor change handling

See implementation examples in the STEP sections below.

===============================================================================
--]]

-- ============================================================================
-- CONFIGURATION & STATE
-- ============================================================================

local AEROSPACE = "/run/current-system/sw/bin/aerospace"
local STATE_FILE = os.getenv("HOME") .. "/.cache/hammerspoon/workspace-state.json"
local STATE_DIR = os.getenv("HOME") .. "/.cache/hammerspoon"

-- Configuration constants
local CONFIG = {
    MONITOR_CHANGE_DELAY = 3,      -- Seconds to wait after monitor changes
    SLEEP_RESUME_DELAY = 1,        -- Seconds to wait after sleep resume
    FOCUS_RESTORE_DELAY = 0.3,     -- Seconds to wait before restoring focus
    AEROSPACE_TIMEOUT = 10,        -- Seconds to timeout AeroSpace commands
    MAX_RETRIES = 3,               -- Maximum retries for failed operations
    RETRY_DELAY = 0.5,             -- Seconds between retries
}

-- State storage
local workspaceState = {
    savedState = {},                -- Monitor -> Workspace mapping
    currentFocusedWorkspace = nil   -- Currently focused workspace
}

-- Event watchers and control
local screenWatcher = nil
local caffeineWatcher = nil
local lastScreenCount = 0
local isRestoring = false
local operationQueue = {}
local currentOperation = nil

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function debugLog(message, level)
    level = level or "INFO"
    print(os.date("%Y-%m-%d %H:%M:%S") .. " MonitorManager [" .. level .. "]: " .. message)
end

local function errorLog(message)
    debugLog(message, "ERROR")
end

local function warnLog(message)
    debugLog(message, "WARN")
end

-- Ensure state directory exists
local function ensureStateDirectory()
    local result = hs.execute("mkdir -p " .. STATE_DIR)
    if not result then
        errorLog("Failed to create state directory: " .. STATE_DIR)
        return false
    end
    return true
end

-- Validate workspace number
local function isValidWorkspace(workspace)
    return workspace and type(workspace) == "number" and workspace >= 1 and workspace <= 9
end

-- Safe file operations with cleanup
local function safeFileWrite(filepath, content)
    if not ensureStateDirectory() then
        return false
    end
    
    local file, err = io.open(filepath, "w")
    if not file then
        errorLog("Failed to open file for writing: " .. filepath .. " - " .. (err or "unknown error"))
        return false
    end
    
    local success, writeErr = pcall(function()
        file:write(content)
    end)
    
    file:close()
    
    if not success then
        errorLog("Failed to write file: " .. filepath .. " - " .. (writeErr or "unknown error"))
        return false
    end
    
    return true
end

local function safeFileRead(filepath)
    local file, err = io.open(filepath, "r")
    if not file then
        return nil, err
    end
    
    local content
    local success, readErr = pcall(function()
        content = file:read("*all")
    end)
    
    file:close()
    
    if not success then
        return nil, readErr
    end
    
    return content
end

-- Operation queue management
local function queueOperation(operation)
    table.insert(operationQueue, operation)
    if not currentOperation then
        processNextOperation()
    end
end

local function processNextOperation()
    if #operationQueue == 0 then
        currentOperation = nil
        return
    end
    
    currentOperation = table.remove(operationQueue, 1)
    currentOperation()
end

local function finishOperation()
    currentOperation = nil
    hs.timer.doAfter(0.1, processNextOperation)
end

-- Aerospace command wrapper with timeout and error handling
local function runAerospaceCommand(args, callback, retryCount)
    retryCount = retryCount or 0
    
    local timeoutTimer = hs.timer.doAfter(CONFIG.AEROSPACE_TIMEOUT, function()
        errorLog("AeroSpace command timed out: " .. table.concat(args, " "))
        if callback then callback(false, nil, "timeout") end
    end)
    
    hs.task.new(AEROSPACE, function(exitCode, stdout, stderr)
        timeoutTimer:stop()
        
        if exitCode == 0 then
            if callback then callback(true, stdout, nil) end
        else
            local errorMsg = "AeroSpace command failed (exit " .. exitCode .. "): " .. table.concat(args, " ")
            if stderr and stderr ~= "" then
                errorMsg = errorMsg .. " - " .. stderr
            end
            
            if retryCount < CONFIG.MAX_RETRIES then
                warnLog(errorMsg .. " - retrying (" .. (retryCount + 1) .. "/" .. CONFIG.MAX_RETRIES .. ")")
                hs.timer.doAfter(CONFIG.RETRY_DELAY, function()
                    runAerospaceCommand(args, callback, retryCount + 1)
                end)
            else
                errorLog(errorMsg .. " - max retries exceeded")
                if callback then callback(false, nil, errorMsg) end
            end
        end
    end, args):start()
end

-- ============================================================================
-- WORKSPACE STATE MANAGEMENT
-- ============================================================================

-- Capture current workspace state across all monitors
local function captureWorkspaceState(callback)
    local captureOperation = function()
        workspaceState.savedState = {}
        debugLog("Capturing workspace state...")
        
        -- Get focused workspace first
        runAerospaceCommand({"list-workspaces", "--focused"}, function(success, stdout, error)
            if success and stdout then
                local focusedWs = tonumber(stdout:match("%d+"))
                if isValidWorkspace(focusedWs) then
                    workspaceState.currentFocusedWorkspace = focusedWs
                    debugLog("Focused workspace: " .. focusedWs)
                else
                    warnLog("Invalid focused workspace: " .. (stdout or "nil"))
                end
            else
                errorLog("Failed to get focused workspace: " .. (error or "unknown"))
            end
            
            -- Get monitor information
            runAerospaceCommand({"list-monitors"}, function(success2, stdout2, error2)
                if not success2 then
                    errorLog("Failed to get monitor list: " .. (error2 or "unknown"))
                    finishOperation()
                    if callback then callback() end
                    return
                end
                
                local monitors = {}
                if stdout2 then
                    for line in stdout2:gmatch("[^\r\n]+") do
                        local monitorId, monitorName = line:match("^(%d+)%s+(.+)$")
                        if monitorId and monitorName then
                            monitors[tonumber(monitorId)] = monitorName:gsub("^%s*(.-)%s*$", "%1")
                        end
                    end
                end
                
                local monitorCount = 0
                for _ in pairs(monitors) do
                    monitorCount = monitorCount + 1
                end
                
                if monitorCount == 0 then
                    warnLog("No monitors found")
                    finishOperation()
                    if callback then callback() end
                    return
                end
                
                debugLog("Processing " .. monitorCount .. " monitors")
                local processedCount = 0
                
                for monitorId, monitorName in pairs(monitors) do
                    runAerospaceCommand({"list-workspaces", "--monitor", tostring(monitorId), "--visible"}, 
                        function(success3, stdout3, error3)
                            processedCount = processedCount + 1
                            
                            if success3 and stdout3 then
                                for line in stdout3:gmatch("[^\r\n]+") do
                                    local wsId = line:match("^(%d+)")
                                    if wsId then
                                        local workspace = tonumber(wsId)
                                        if isValidWorkspace(workspace) then
                                            workspaceState.savedState[monitorName] = workspace
                                            debugLog("Monitor '" .. monitorName .. "' -> Workspace " .. workspace)
                                            break
                                        end
                                    end
                                end
                            else
                                warnLog("Failed to get workspaces for monitor " .. monitorName .. ": " .. (error3 or "unknown"))
                            end
                            
                            if processedCount >= monitorCount then
                                finishOperation()
                                if callback then callback() end
                            end
                        end)
                end
            end)
        end)
    end
    
    queueOperation(captureOperation)
end

-- Restore workspace state to monitors
local function restoreWorkspaceState(callback)
    local restoreOperation = function()
        if not workspaceState.savedState or not next(workspaceState.savedState) then
            debugLog("No workspace state to restore")
            finishOperation()
            if callback then callback() end
            return
        end
        
        debugLog("Restoring workspace state...")
        isRestoring = true
        
        -- Validate workspaces before restoring
        local validRestores = {}
        for monitorName, workspace in pairs(workspaceState.savedState) do
            if isValidWorkspace(workspace) then
                validRestores[monitorName] = workspace
            else
                warnLog("Skipping invalid workspace " .. tostring(workspace) .. " for monitor " .. monitorName)
            end
        end
        
        if next(validRestores) == nil then
            warnLog("No valid workspaces to restore")
            isRestoring = false
            finishOperation()
            if callback then callback() end
            return
        end
        
        for monitorName, workspace in pairs(validRestores) do
            debugLog("Restoring workspace " .. workspace .. " to monitor '" .. monitorName .. "'")
            runAerospaceCommand({"workspace", tostring(workspace)}, function(success, stdout, error)
                if not success then
                    errorLog("Failed to restore workspace " .. workspace .. ": " .. (error or "unknown"))
                end
                
                -- Restore the originally focused workspace
                if isValidWorkspace(workspaceState.currentFocusedWorkspace) then
                    hs.timer.doAfter(CONFIG.FOCUS_RESTORE_DELAY, function()
                        debugLog("Restoring focus to workspace " .. workspaceState.currentFocusedWorkspace)
                        runAerospaceCommand({"workspace", tostring(workspaceState.currentFocusedWorkspace)}, 
                            function(success2, stdout2, error2)
                                if not success2 then
                                    errorLog("Failed to restore focus: " .. (error2 or "unknown"))
                                end
                                isRestoring = false
                                finishOperation()
                                if callback then callback() end
                            end)
                    end)
                else
                    isRestoring = false
                    finishOperation()
                    if callback then callback() end
                end
            end)
        end
    end
    
    queueOperation(restoreOperation)
end

-- Save state to disk
local function saveStateToDisk()
    local stateData = {
        savedState = workspaceState.savedState,
        currentFocusedWorkspace = workspaceState.currentFocusedWorkspace,
        timestamp = os.time(),
        monitorCount = #hs.screen.allScreens()
    }
    
    local jsonData = hs.json.encode(stateData)
    if jsonData then
        if safeFileWrite(STATE_FILE, jsonData) then
            debugLog("Workspace state saved to disk")
        else
            errorLog("Failed to save workspace state to disk")
        end
    else
        errorLog("Failed to encode workspace state to JSON")
    end
end

-- Load state from disk
local function loadStateFromDisk()
    local jsonData, readErr = safeFileRead(STATE_FILE)
    if not jsonData then
        if readErr then
            debugLog("No state file found: " .. readErr)
        end
        return false
    end
    
    local stateData = hs.json.decode(jsonData)
    if not stateData then
        errorLog("Failed to decode state file JSON")
        return false
    end
    
    local currentMonitorCount = #hs.screen.allScreens()
    
    if stateData.monitorCount == currentMonitorCount then
        workspaceState.savedState = stateData.savedState or {}
        workspaceState.currentFocusedWorkspace = stateData.currentFocusedWorkspace
        debugLog("Workspace state loaded from disk")
        return true
    else
        debugLog(string.format("State not loaded: monitor count changed (%d -> %d)",
                 stateData.monitorCount or 0, currentMonitorCount))
        return false
    end
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

-- Handle monitor changes (dock/undock)
local function onScreenChange()
    if isRestoring then 
        debugLog("Skipping screen change (currently restoring)")
        return 
    end
    
    local currentScreenCount = #hs.screen.allScreens()
    
    if currentScreenCount ~= lastScreenCount then
        local previousScreenCount = lastScreenCount
        lastScreenCount = currentScreenCount
        
        debugLog(string.format("Monitor change detected: %d -> %d monitors", 
                 previousScreenCount, currentScreenCount))
        
        -- Delay for system stabilization
        hs.timer.doAfter(CONFIG.MONITOR_CHANGE_DELAY, function()
            if currentScreenCount > previousScreenCount then
                -- Monitor connected - try to restore previous state
                local stateLoaded = loadStateFromDisk()
                if stateLoaded then
                    debugLog("Restoring workspace state after monitor connect")
                    restoreWorkspaceState(function()
                        saveStateToDisk()
                    end)
                else
                    debugLog("No valid state to restore after monitor connect")
                end
            else
                -- Monitor disconnected - capture current state for next connect
                debugLog("Capturing workspace state after monitor disconnect")
                captureWorkspaceState(function()
                    saveStateToDisk()
                end)
            end
        end)
    end
end

-- Handle sleep/resume events
local function onCaffeineChange(eventType)
    if eventType == hs.caffeinate.watcher.systemWillSleep then
        debugLog("System going to sleep - capturing workspace state")
        captureWorkspaceState(function()
            saveStateToDisk()
        end)
    elseif eventType == hs.caffeinate.watcher.systemDidWake then
        debugLog("System woke up - restoring workspace state")
        hs.timer.doAfter(CONFIG.SLEEP_RESUME_DELAY, function()
            local stateLoaded = loadStateFromDisk()
            if stateLoaded then
                restoreWorkspaceState(function()
                    debugLog("Workspace state restored after wake")
                end)
            else
                debugLog("No valid state to restore after wake")
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
    
    debugLog("Starting MonitorManager with workspace state persistence")
    
    -- Initialize state
    lastScreenCount = #hs.screen.allScreens()
    
    -- Start watchers
    screenWatcher = hs.screen.watcher.new(onScreenChange)
    screenWatcher:start()
    
    caffeineWatcher = hs.caffeinate.watcher.new(onCaffeineChange)
    caffeineWatcher:start()
    
    -- Try to load previous state on startup
    hs.timer.doAfter(2, function()
        local stateLoaded = loadStateFromDisk()
        if stateLoaded then
            debugLog("Loading workspace state on startup")
            restoreWorkspaceState()
        else
            debugLog("No previous workspace state found")
        end
    end)
    
    debugLog("MonitorManager started - monitoring for dock/undock and sleep/resume")
end

-- Stop the MonitorManager
function MonitorManager.stop()
    if screenWatcher then
        screenWatcher:stop()
        screenWatcher = nil
    end
    
    if caffeineWatcher then
        caffeineWatcher:stop()
        caffeineWatcher = nil
    end
    
    -- Clear operation queue
    operationQueue = {}
    currentOperation = nil
    isRestoring = false
    debugLog("MonitorManager stopped")
end

-- Manual state management
function MonitorManager.saveState()
    debugLog("Manual state save requested")
    captureWorkspaceState(function()
        saveStateToDisk()
        debugLog("Manual state save completed")
    end)
end

function MonitorManager.restoreState()
    debugLog("Manual state restore requested")
    local stateLoaded = loadStateFromDisk()
    if stateLoaded then
        restoreWorkspaceState(function()
            debugLog("Manual state restore completed")
        end)
    else
        debugLog("No valid state to restore")
    end
end

function MonitorManager.clearState()
    workspaceState.savedState = {}
    workspaceState.currentFocusedWorkspace = nil
    os.remove(STATE_FILE)
    operationQueue = {}
    currentOperation = nil
    debugLog("Workspace state cleared")
end

-- Configuration management
function MonitorManager.getConfig()
    return CONFIG
end

function MonitorManager.updateConfig(newConfig)
    for key, value in pairs(newConfig) do
        if CONFIG[key] ~= nil then
            CONFIG[key] = value
            debugLog("Updated config " .. key .. " = " .. tostring(value))
        else
            warnLog("Unknown config key: " .. key)
        end
    end
end

-- Debug information
function MonitorManager.debug()
    debugLog("=== MonitorManager Status ===")
    debugLog(string.format("Monitors: %d, Restoring: %s", #hs.screen.allScreens(), tostring(isRestoring)))
    debugLog(string.format("Screen watcher: %s, Caffeine watcher: %s",
             screenWatcher and "active" or "inactive",
             caffeineWatcher and "active" or "inactive"))
    debugLog(string.format("Operation queue: %d pending, current: %s", 
             #operationQueue, currentOperation and "running" or "none"))
    
    if next(workspaceState.savedState) then
        debugLog("Current workspace state:")
        for monitor, workspace in pairs(workspaceState.savedState) do
            debugLog(string.format("  %s: Workspace %d", monitor, workspace))
        end
        if workspaceState.currentFocusedWorkspace then
            debugLog(string.format("Focused workspace: %d", workspaceState.currentFocusedWorkspace))
        end
    else
        debugLog("No workspace state in memory")
    end
    
    -- Check state file
    local jsonData = safeFileRead(STATE_FILE)
    if jsonData then
        debugLog(string.format("State file exists: %s (%d bytes)", STATE_FILE, #jsonData))
    else
        debugLog("No state file on disk")
    end
    
    -- Show configuration
    debugLog("Configuration:")
    for key, value in pairs(CONFIG) do
        debugLog(string.format("  %s: %s", key, tostring(value)))
    end
end

-- Health check
function MonitorManager.healthCheck()
    debugLog("Running health check...")
    
    -- Test AeroSpace connectivity
    runAerospaceCommand({"list-workspaces", "--focused"}, function(success, stdout, error)
        if success then
            debugLog("AeroSpace connectivity: OK")
            if stdout then
                local workspace = stdout:match("%d+")
                debugLog("Currently focused workspace: " .. (workspace or "unknown"))
            end
        else
            errorLog("AeroSpace connectivity: FAILED - " .. (error or "unknown"))
        end
    end)
    
    -- Test file system access
    if ensureStateDirectory() then
        debugLog("State directory access: OK")
    else
        errorLog("State directory access: FAILED")
    end
    
    -- Test JSON operations
    local testData = {test = "data", number = 42}
    local jsonData = hs.json.encode(testData)
    if jsonData then
        local decoded = hs.json.decode(jsonData)
        if decoded and decoded.test == "data" then
            debugLog("JSON operations: OK")
        else
            errorLog("JSON decode: FAILED")
        end
    else
        errorLog("JSON encode: FAILED")
    end
end

-- ============================================================================
-- REIMPLEMENTATION TEMPLATES (for AI agents)
-- ============================================================================

--[[
STEP 2: ADD MANUAL LAYOUT FUNCTIONS (if needed)
```lua
local currentLayout = "tiles horizontal"

function MonitorManager.toggle()
    local nextLayout = (currentLayout == "tiles horizontal") and "tiles vertical" or "tiles horizontal"
    runAerospaceCommand({"layout", nextLayout}, function(success, stdout, error)
        if success then
            currentLayout = nextLayout
            debugLog("Layout toggled to " .. currentLayout)
        else
            errorLog("Failed to toggle layout: " .. (error or "unknown"))
        end
    end)
end

function MonitorManager.setHorizontal()
    runAerospaceCommand({"layout", "tiles horizontal"}, function(success, stdout, error)
        if success then
            currentLayout = "tiles horizontal"
            debugLog("Layout set to horizontal")
        else
            errorLog("Failed to set horizontal layout: " .. (error or "unknown"))
        end
    end)
end

function MonitorManager.setVertical()
    runAerospaceCommand({"layout", "tiles vertical"}, function(success, stdout, error)
        if success then
            currentLayout = "tiles vertical"
            debugLog("Layout set to vertical")
        else
            errorLog("Failed to set vertical layout: " .. (error or "unknown"))
        end
    end)
end
```

STEP 3: ADD PER-WORKSPACE LAYOUT MEMORY (if needed)
```lua
local workspaceLayouts = {}

local function saveWorkspaceLayout(workspace, layout)
    if isValidWorkspace(workspace) then
        workspaceLayouts[workspace] = layout
        -- Integrate with existing state persistence
        local stateData = {
            savedState = workspaceState.savedState,
            currentFocusedWorkspace = workspaceState.currentFocusedWorkspace,
            workspaceLayouts = workspaceLayouts,
            timestamp = os.time(),
            monitorCount = #hs.screen.allScreens()
        }
        -- Save to disk...
    end
end

local function restoreWorkspaceLayout(workspace)
    local layout = workspaceLayouts[workspace] or "tiles horizontal"
    runAerospaceCommand({"layout", layout}, function(success, stdout, error)
        if success then
            debugLog("Restored layout " .. layout .. " for workspace " .. workspace)
        else
            errorLog("Failed to restore layout for workspace " .. workspace .. ": " .. (error or "unknown"))
        end
    end)
end
```

STEP 4: ADD AUTOMATIC LAYOUT SWITCHING (if needed)
```lua
local function getMonitorSignature()
    local screens = hs.screen.allScreens()
    local signature = {}
    for i, screen in ipairs(screens) do
        table.insert(signature, screen:name() or ("unknown-" .. i))
    end
    table.sort(signature)
    return table.concat(signature, "|")
end

local function applyLayoutsBasedOnMonitor()
    local signature = getMonitorSignature()
    local lgConnected = string.find(signature, "LG HDR 4K") ~= nil
    
    -- Apply different layouts based on monitor setup
    if lgConnected then
        -- Home office setup logic
        for ws = 6, 7 do
            runAerospaceCommand({"workspace", tostring(ws)}, function(success)
                if success then
                    runAerospaceCommand({"layout", "tiles vertical"}, function() end)
                end
            end)
        end
    else
        -- Office setup logic
        for ws = 1, 9 do
            runAerospaceCommand({"workspace", tostring(ws)}, function(success)
                if success then
                    runAerospaceCommand({"layout", "tiles horizontal"}, function() end)
                end
            end)
        end
    end
end
```
--]]

return MonitorManager 