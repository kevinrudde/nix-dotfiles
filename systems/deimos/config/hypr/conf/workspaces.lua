local M = {}

M.internal_monitor = "eDP-1"
M.external_monitor = "DP-1"
M.primary_workspaces = { 1, 2, 3, 4, 5, 6 }

function M.workspace(workspace)
  if workspace == 0 then
    return "name:0"
  end

  return tostring(workspace)
end

function M.has_monitor(monitor)
  return hl.get_monitor(monitor) ~= nil
end

function M.active_monitor_name()
  local monitor = hl.get_active_monitor()

  if monitor ~= nil then
    return monitor.name
  end

  return nil
end

function M.internal_monitor_or_fallback()
  if M.has_monitor(M.internal_monitor) then
    return M.internal_monitor
  end

  if M.has_monitor(M.external_monitor) then
    return M.external_monitor
  end

  return M.active_monitor_name()
end

function M.primary_monitor()
  if M.has_monitor(M.external_monitor) then
    return M.external_monitor
  end

  return M.internal_monitor_or_fallback()
end

function M.monitor_for_workspace(workspace)
  if workspace == 0 then
    return M.internal_monitor_or_fallback()
  end

  return M.primary_monitor()
end

function M.move_workspace_to_target(workspace)
  local monitor = M.monitor_for_workspace(workspace)

  if monitor ~= nil then
    hl.dispatch(hl.dsp.workspace.move({
      workspace = M.workspace(workspace),
      monitor = monitor,
    }))
  end

  return monitor
end

function M.focus(workspace)
  return function()
    local monitor = M.move_workspace_to_target(workspace)

    if monitor ~= nil then
      hl.dispatch(hl.dsp.focus({ monitor = monitor }))
    end

    hl.dispatch(hl.dsp.focus({ workspace = M.workspace(workspace) }))
  end
end

function M.move_window(workspace)
  return function()
    M.move_workspace_to_target(workspace)
    hl.dispatch(hl.dsp.window.move({
      workspace = M.workspace(workspace),
      follow = true,
    }))
  end
end

function M.apply_workspace_monitor_assignments()
  M.move_workspace_to_target(0)

  for _, workspace in ipairs(M.primary_workspaces) do
    M.move_workspace_to_target(workspace)
  end
end

function M.configure_workspace_rules()
  local internal_monitor = M.internal_monitor_or_fallback()
  local primary_monitor = M.primary_monitor()

  if internal_monitor ~= nil then
    hl.workspace_rule({
      workspace = M.workspace(0),
      monitor = internal_monitor,
      persistent = true,
      default = true,
    })
  end

  if primary_monitor ~= nil then
    for _, workspace in ipairs(M.primary_workspaces) do
      local rule = {
        workspace = M.workspace(workspace),
        monitor = primary_monitor,
        persistent = true,
      }

      if primary_monitor == M.external_monitor and workspace == 1 then
        rule.default = true
      end

      hl.workspace_rule(rule)
    end
  end
end

function M.apply_workspace_layout()
  M.configure_workspace_rules()
  M.apply_workspace_monitor_assignments()
end

function M.configure_rules()
  M.configure_workspace_rules()

  if not M.events_registered then
    hl.on("hyprland.start", M.apply_workspace_layout)
    hl.on("config.reloaded", M.apply_workspace_layout)
    hl.on("monitor.added", M.apply_workspace_layout)
    hl.on("monitor.removed", M.apply_workspace_layout)

    M.events_registered = true
  end
end

return M
