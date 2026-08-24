-- macOS-style lid handling for the built-in panel.
--
-- The suspend half of this is logind's, not Hyprland's -- see
-- systems/<host>/rootfs/etc/systemd/logind.conf.d/10-lid.conf. Closing the lid
-- undocked suspends, and hypridle's before_sleep_cmd locks on the way down, so
-- the lid opens onto a password prompt. Docked, logind stays out of the way and
-- the session keeps running.
--
-- That docked case is what this module covers: clamshell only feels right if
-- the shut panel actually leaves the layout, otherwise Hyprland happily parks a
-- workspace on a screen nobody can see.
--
-- Hosts opt in from their hosts/<host>.lua by handing over the very same spec
-- they passed to hl.monitor(), which is also what gets replayed on lid-open --
-- a monitor rule can only be undone by restating it in full.
--
--   local internal = { output = "eDP-1", mode = "preferred", ... }
--   hl.monitor(internal)
--   require("conf.lid").setup(internal)

local M = {}

---@param spec HL.MonitorSpec the internal panel, exactly as passed to hl.monitor()
function M.setup(spec)
  local internal = spec.output

  -- Disabling the only enabled output would leave Hyprland with nothing to
  -- draw on, and it is not always a lid-open event that brings the session
  -- back -- a power-button wake with the lid still shut would otherwise strand
  -- it there. Undocked closes suspend anyway, so gating on a second monitor
  -- costs nothing and mirrors how logind decides it is docked.
  local function docked()
    for _, monitor in ipairs(hl.get_monitors()) do
      if monitor.name ~= internal then
        return true
      end
    end

    return false
  end

  hl.bind("switch:on:Lid Switch", function()
    if docked() then
      hl.monitor({ output = internal, disabled = true })
    end
  end, { locked = true, desc = "Lid closed: drop the built-in panel" })

  hl.bind("switch:off:Lid Switch", function()
    hl.monitor(spec)
  end, { locked = true, desc = "Lid opened: restore the built-in panel" })
end

return M
