local wezterm = require("wezterm")
local keybinds = require("keybinds")

wezterm.on("update-right-status", function(window)
  local name = window:active_key_table()
  window:set_right_status(name and ("TABLE: " .. name) or "")
end)

local SOLID_LEFT_ARROW = wezterm.nerdfonts.ple_lower_right_triangle
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.ple_upper_left_triangle

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local background = "#5c6d74"
  local foreground = "#FFFFFF"
  local edge_background = "none"

  if tab.is_active then
    background = "#9ece6a"
    foreground = "#1a1b26"
  elseif hover then
    background = "#73daca"
    foreground = "#1a1b26"
  end

  local edge_foreground = background
  local title = " " .. tab.tab_index + 1 .. ": " .. wezterm.truncate_right(tab.active_pane.title, max_width - 6) .. " "

  return {
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = SOLID_LEFT_ARROW },
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = title },
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = SOLID_RIGHT_ARROW },
  }
end)

wezterm.on("gui-startup", function()
  local _, _, window = wezterm.mux.spawn_window({})
  window:gui_window():maximize()
end)

local config = wezterm.config_builder()

config.automatically_reload_config = true
config.font = wezterm.font_with_fallback({
  "JetBrains Mono",
  "Hiragino Sans",
  "Symbols Nerd Font Mono",
  "Noto Color Emoji",
})
config.font_size = 12.0
config.color_scheme = "Tokyo Night"
config.use_ime = true

config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 10,
}
config.window_background_opacity = 0.75
config.macos_window_background_blur = 20
config.window_decorations = "RESIZE"

config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 2000 }
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = true
config.show_tabs_in_tab_bar = true
config.show_new_tab_button_in_tab_bar = false
config.window_frame = {
  inactive_titlebar_bg = "none",
  active_titlebar_bg = "none",
}
config.window_background_gradient = {
  colors = { "#000000" },
}
config.colors = {
  tab_bar = {
    inactive_tab_edge = "none",
  },
}

config.keys = keybinds.keys
config.key_tables = keybinds.key_tables

config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate = 500
config.scrollback_lines = 10000

return config
