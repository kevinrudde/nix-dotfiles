local M = {}

M.internal_monitor = "eDP-1"
M.primary_workspaces = { 1, 2, 3, 4, 5, 6 }

-- Workspaces that live on the side screen rather than the one in front of the
-- keyboard. They keep their keybind on a desk that has no second external --
-- there is simply nothing to send them to, so they fall back to the primary
-- screen like any other workspace.
M.secondary_workspaces = { 7 }

-- Hosts that sit in front of more than one external screen list them here,
-- most primary first, as a prefix of the EDID description (the `description`
-- field of `hyprctl monitors all -j`). Left empty, connection order decides
-- which screen carries workspaces 1-6 -- and the order two cables happen to
-- come up in is not a promise, so the small side monitor is as likely to win
-- it as the big one in front of you.
M.external_monitors = {}

function M.workspace(workspace)
  if workspace == 0 then
    return "name:0"
  end

  return tostring(workspace)
end

function M.has_monitor(monitor)
  return monitor ~= nil and hl.get_monitor(monitor) ~= nil
end

function M.active_monitor_name()
  local monitor = hl.get_active_monitor()

  if monitor ~= nil then
    return monitor.name
  end

  return nil
end

-- The desk monitor has no stable connector name: the same screen arrives as
-- DP-1 at one desk and DP-4 at the other, depending on which port the cable
-- lands in. A name pinned here reads as "no external monitor" at every desk
-- but one, and every primary workspace then piles onto the laptop panel.
--
-- So do not name it -- ask Hyprland. Anything that is not the built-in panel
-- is an external screen; M.external_monitors picks between them when a desk
-- has several, and connection order settles anything it does not mention.
--
-- Returns names, most primary first: the screens M.external_monitors lists, in
-- the order it lists them, then anything it does not mention.
function M.external_monitor_names()
  local attached = {}

  for _, monitor in ipairs(hl.get_monitors()) do
    if monitor.name ~= M.internal_monitor then
      table.insert(attached, monitor)
    end
  end

  local ordered = {}
  local claimed = {}

  for _, wanted in ipairs(M.external_monitors) do
    for index, monitor in ipairs(attached) do
      if not claimed[index] and monitor.description:sub(1, #wanted) == wanted then
        claimed[index] = true
        table.insert(ordered, monitor.name)
      end
    end
  end

  for index, monitor in ipairs(attached) do
    if not claimed[index] then
      table.insert(ordered, monitor.name)
    end
  end

  return ordered
end

function M.external_monitor()
  return M.external_monitor_names()[1]
end

-- nil whenever the desk has at most one external screen, which is what makes
-- the secondary workspaces fall back onto the primary one.
function M.secondary_monitor()
  return M.external_monitor_names()[2]
end

function M.internal_monitor_or_fallback()
  if M.has_monitor(M.internal_monitor) then
    return M.internal_monitor
  end

  return M.external_monitor() or M.active_monitor_name()
end

function M.primary_monitor()
  return M.external_monitor() or M.internal_monitor_or_fallback()
end

function M.is_secondary_workspace(workspace)
  for _, candidate in ipairs(M.secondary_workspaces) do
    if candidate == workspace then
      return true
    end
  end

  return false
end

function M.monitor_for_workspace(workspace)
  if workspace == 0 then
    return M.internal_monitor_or_fallback()
  end

  if M.is_secondary_workspace(workspace) then
    return M.secondary_monitor() or M.primary_monitor()
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

  for _, workspace in ipairs(M.secondary_workspaces) do
    M.move_workspace_to_target(workspace)
  end
end

function M.configure_workspace_rules()
  local internal_monitor = M.internal_monitor_or_fallback()
  local external_monitor = M.external_monitor()
  local primary_monitor = external_monitor or internal_monitor

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

      if external_monitor ~= nil and workspace == 1 then
        rule.default = true
      end

      hl.workspace_rule(rule)
    end
  end

  -- Only while a second screen is actually there. Pinned to the primary
  -- instead, a persistent rule would leave a 7th always-present workspace
  -- sitting on the main screen at every desk that has no side monitor; without
  -- a rule the keybind still opens it on demand and it disappears when empty.
  local secondary_monitor = M.secondary_monitor()

  if secondary_monitor ~= nil then
    for _, workspace in ipairs(M.secondary_workspaces) do
      hl.workspace_rule({
        workspace = M.workspace(workspace),
        monitor = secondary_monitor,
        persistent = true,
      })
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
