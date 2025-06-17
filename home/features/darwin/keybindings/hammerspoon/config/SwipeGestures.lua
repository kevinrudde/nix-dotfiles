Swipe = hs.loadSpoon("Swipe")

local AEROSPACE = "/run/current-system/sw/bin/aerospace"

function aerospaceExec(cmd)
  os.execute("nohup " .. AEROSPACE .. " " .. cmd .. " &", true)
end

-- use four finger swipe to switch workspace
local current_id, threshold
Swipe:start(4, function(direction, distance, id)
  if id == current_id then
      if distance > threshold then
          threshold = math.huge -- only trigger once per swipe

          -- use "natural" scrolling
          if direction == "left" then
            aerospaceExec("workspace --wrap-around prev")
          elseif direction == "right" then
            aerospaceExec("workspace --wrap-around next")
          end
      end
  else
      current_id = id
      threshold = 0.01 -- swipe distance > 20% of trackpad
  end
end)
