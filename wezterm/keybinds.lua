local wezterm = require("wezterm")
local act = wezterm.action

return {
  keys = {
    { key = "d", mods = "CMD", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { key = "d", mods = "CMD|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
    { key = "w", mods = "CMD|OPT", action = act.CloseCurrentPane({ confirm = false }) },

    { key = "h", mods = "CMD|OPT", action = act.ActivatePaneDirection("Left") },
    { key = "j", mods = "CMD|OPT", action = act.ActivatePaneDirection("Down") },
    { key = "k", mods = "CMD|OPT", action = act.ActivatePaneDirection("Up") },
    { key = "l", mods = "CMD|OPT", action = act.ActivatePaneDirection("Right") },
    {
      key = "s",
      mods = "CMD|OPT",
      action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }),
    },
    { key = "z", mods = "CMD|OPT", action = act.TogglePaneZoomState },

    { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
    { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
    { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
    { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
    {
      key = "s",
      mods = "LEADER",
      action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }),
    },
    { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

    { key = "w", mods = "CMD|SHIFT", action = act.ShowLauncherArgs({ flags = "WORKSPACES" }) },
    {
      key = "c",
      mods = "CMD|OPT",
      action = act.PromptInputLine({
        description = "Workspace name",
        action = wezterm.action_callback(function(window, pane, line)
          if line then
            window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
          end
        end),
      }),
    },
    {
      key = "r",
      mods = "CMD|OPT",
      action = act.PromptInputLine({
        description = "Rename workspace",
        action = wezterm.action_callback(function(window, pane, line)
          if line then
            wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
          end
        end),
      }),
    },
  },

  key_tables = {
    resize_pane = {
      { key = "h", action = act.AdjustPaneSize({ "Left", 2 }) },
      { key = "j", action = act.AdjustPaneSize({ "Down", 2 }) },
      { key = "k", action = act.AdjustPaneSize({ "Up", 2 }) },
      { key = "l", action = act.AdjustPaneSize({ "Right", 2 }) },
      { key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 2 }) },
      { key = "DownArrow", action = act.AdjustPaneSize({ "Down", 2 }) },
      { key = "UpArrow", action = act.AdjustPaneSize({ "Up", 2 }) },
      { key = "RightArrow", action = act.AdjustPaneSize({ "Right", 2 }) },
      { key = "Escape", action = "PopKeyTable" },
      { key = "Enter", action = "PopKeyTable" },
    },
  },
}
