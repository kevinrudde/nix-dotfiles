local SwipeGestures = require('SwipeGestures')
local MonitorManager = require('MonitorManager')

ipc = require("hs.ipc")
ipc.cliInstall()

-- Start MonitorManager for automatic layout switching
MonitorManager.start()

-- Make MonitorManager globally accessible for AeroSpace shortcuts
_G.MonitorManager = MonitorManager
