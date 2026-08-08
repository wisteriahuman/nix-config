local wezterm = require("wezterm")
local act = wezterm.action

-- テーマ切り替え。状態は ~/.local/state/theme/{current,slots.json} で
-- nvim 側 (nvim/lua/config/theme.lua) と共有する。id・スロット名・role タグの
-- 命名/優先順位は nvim 側と揃えること。

local HOME = os.getenv("HOME")
local STATE_DIR = HOME .. "/.local/state/theme"
local CURRENT_FILE = STATE_DIR .. "/current"
local SLOTS_FILE = STATE_DIR .. "/slots.json"

local THEMES = {
  tokyonight = {
    tags = { "dark", "classic" },
    scheme = "Tokyo Night",
    bg = "#1a1b26",
    tab_bg = "#292e42", tab_fg2 = "#c0caf5",
    tab_accent = "#9ece6a", tab_hover = "#73daca", tab_fg = "#1a1b26",
  },
  mocha = {
    tags = { "dark", "kawaii", "classic" },
    scheme = "Catppuccin Mocha",
    bg = "#1e1e2e",
    tab_bg = "#313244", tab_fg2 = "#cdd6f4",
    tab_accent = "#a6e3a1", tab_hover = "#94e2d5", tab_fg = "#1e1e2e",
  },
  latte = {
    tags = { "light", "kawaii", "classic" },
    scheme = "Catppuccin Latte",
    bg = "#eff1f5",
    tab_bg = "#ccd0da", tab_fg2 = "#4c4f69",
    tab_accent = "#40a02b", tab_hover = "#179299", tab_fg = "#eff1f5",
  },
  rosepine = {
    tags = { "dark", "elegant", "classic" },
    scheme = "rose-pine",
    bg = "#191724",
    tab_bg = "#26233a", tab_fg2 = "#e0def4",
    tab_accent = "#31748f", tab_hover = "#9ccfd8", tab_fg = "#191724",
  },
  dawn = {
    tags = { "light", "elegant", "classic" },
    scheme = "rose-pine-dawn",
    bg = "#faf4ed",
    tab_bg = "#f2e9e1", tab_fg2 = "#575279",
    tab_accent = "#286983", tab_hover = "#56949f", tab_fg = "#faf4ed",
  },
  mochi = {
    tags = { "dark", "kawaii", "buzz", "original" },
    bg = "#221a2c",
    tab_bg = "#2c2138", tab_fg2 = "#f5e8f7",
    tab_accent = "#d9a4ff", tab_hover = "#8fc4ff", tab_fg = "#221a2c",
    colors = {
      foreground = "#f5e8f7",
      background = "#221a2c",
      cursor_bg = "#d9a4ff",
      cursor_fg = "#221a2c",
      cursor_border = "#d9a4ff",
      selection_bg = "#362a44",
      selection_fg = "#f5e8f7",
      ansi = { "#221a2c", "#ff6f9f", "#8de8b8", "#ffd889", "#8fc4ff", "#d9a4ff", "#7fe3ea", "#f5e8f7" },
      brights = { "#9686a8", "#ff85ac", "#a0f0cb", "#ffe3a8", "#a8d4ff", "#e6c0ff", "#a0edf2", "#fbf3fc" },
    },
  },
  sakura = {
    tags = { "light", "kawaii", "buzz", "original" },
    bg = "#fff5fa",
    tab_bg = "#ffe9f3", tab_fg2 = "#4a2b45",
    tab_accent = "#b968e0", tab_hover = "#4f8fe0", tab_fg = "#fff5fa",
    colors = {
      foreground = "#4a2b45",
      background = "#fff5fa",
      cursor_bg = "#b968e0",
      cursor_fg = "#fff5fa",
      cursor_border = "#b968e0",
      selection_bg = "#ffd9ec",
      selection_fg = "#4a2b45",
      ansi = { "#fff5fa", "#e0507a", "#3fb88f", "#e0a23d", "#4f8fe0", "#b968e0", "#2fb0c4", "#4a2b45" },
      brights = { "#9c6f92", "#ea6f92", "#5fd0a8", "#f0bc5a", "#78adf5", "#d190ef", "#5fd0dc", "#2e1a2b" },
    },
  },
}

local function ensure_dir()
  os.execute('mkdir -p "' .. STATE_DIR .. '"')
end

local function write_current(id)
  ensure_dir()
  local f = io.open(CURRENT_FILE, "w")
  if f then
    f:write(id)
    f:close()
  end
end

local function read_current()
  local f = io.open(CURRENT_FILE, "r")
  if not f then
    write_current("tokyonight")
    return "tokyonight"
  end
  local content = f:read("*l")
  f:close()
  if not content or content == "" then
    return "tokyonight"
  end
  return (content:gsub("%s+$", ""))
end

local function write_slots(slots)
  ensure_dir()
  local f = io.open(SLOTS_FILE, "w")
  if f then
    f:write(wezterm.json_encode(slots))
    f:close()
  end
end

local function read_slots()
  local f = io.open(SLOTS_FILE, "r")
  if not f then
    local default = { main = "tokyonight" }
    write_slots(default)
    return default
  end
  local content = f:read("*a")
  f:close()
  local ok, decoded = pcall(wezterm.json_parse, content)
  if ok and type(decoded) == "table" then
    return decoded
  end
  return { main = "tokyonight" }
end

local function all_tags()
  local tags = {}
  for _, t in pairs(THEMES) do
    for _, tag in ipairs(t.tags) do
      tags[tag] = true
    end
  end
  return tags
end

local function picker_action(ids)
  ids = ids or (function()
    local all = {}
    for id, _ in pairs(THEMES) do
      table.insert(all, id)
    end
    table.sort(all)
    return all
  end)()
  local choices = {}
  for _, id in ipairs(ids) do
    table.insert(choices, { id = id, label = id .. "  " .. table.concat(THEMES[id].tags, ",") })
  end
  return act.InputSelector({
    title = "Theme",
    choices = choices,
    action = wezterm.action_callback(function(win, _pane, id)
      if id then
        write_current(id)
        win:toast_notification("theme", "-> " .. id, nil, 2000)
        win:reload_configuration()
      end
    end),
  })
end

local function switch(window, pane, raw)
  raw = (raw or ""):gsub("^%s+", ""):gsub("%s+$", "")

  if raw == "" then
    window:perform_action(picker_action(), pane)
    return
  end

  local slot, id = raw:match("^([%w_%-]+)=([%w_%-]+)$")
  if slot then
    if THEMES[slot] then
      window:toast_notification("theme", 'slot "' .. slot .. '" collides with a theme id', nil, 4000)
      return
    end
    if all_tags()[slot] then
      window:toast_notification("theme", 'slot "' .. slot .. '" collides with a role tag', nil, 4000)
      return
    end
    if not THEMES[id] then
      window:toast_notification("theme", 'unknown theme id "' .. id .. '"', nil, 4000)
      return
    end
    local slots = read_slots()
    slots[slot] = id
    write_slots(slots)
    write_current(id)
    window:toast_notification("theme", 'registered "' .. slot .. '" -> ' .. id, nil, 3000)
    window:reload_configuration()
    return
  end

  if THEMES[raw] then
    write_current(raw)
    window:toast_notification("theme", "-> " .. raw, nil, 2000)
    window:reload_configuration()
    return
  end

  local slots = read_slots()
  if slots[raw] then
    if THEMES[slots[raw]] then
      write_current(slots[raw])
      window:toast_notification("theme", raw .. " -> " .. slots[raw], nil, 2000)
      window:reload_configuration()
    else
      window:toast_notification("theme", 'slot "' .. raw .. '" points to unknown id "' .. slots[raw] .. '"', nil, 4000)
    end
    return
  end

  if all_tags()[raw] then
    local matches = {}
    for tid, t in pairs(THEMES) do
      for _, tg in ipairs(t.tags) do
        if tg == raw then
          table.insert(matches, tid)
          break
        end
      end
    end
    table.sort(matches)
    if #matches == 1 then
      write_current(matches[1])
      window:toast_notification("theme", "-> " .. matches[1], nil, 2000)
      window:reload_configuration()
    else
      window:perform_action(picker_action(matches), pane)
    end
    return
  end

  window:toast_notification("theme", 'unknown theme/slot/role "' .. raw .. '"', nil, 4000)
end

local current_id = read_current()
if not THEMES[current_id] then
  current_id = "tokyonight"
end
local current_theme = THEMES[current_id]

wezterm.add_to_config_reload_watch_list(CURRENT_FILE)

local theme = {
  THEMES = THEMES,
  current_id = current_id,
  current_theme = current_theme,
  switch = switch,
  picker_action = picker_action,
}

local keybinds = require("keybinds").build(theme)

wezterm.on("update-right-status", function(window)
  local name = window:active_key_table()
  window:set_right_status(name and ("TABLE: " .. name) or "")
end)

local SOLID_LEFT_ARROW = wezterm.nerdfonts.ple_lower_right_triangle
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.ple_upper_left_triangle

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local background = current_theme.tab_bg
  local foreground = current_theme.tab_fg2

  if tab.is_active then
    background = current_theme.tab_accent
    foreground = current_theme.tab_fg
  elseif hover then
    background = current_theme.tab_hover
    foreground = current_theme.tab_fg
  end

  local edge_background = "none"
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
config.use_ime = true

if current_theme.scheme then
  config.color_scheme = current_theme.scheme
  config.colors = { tab_bar = { inactive_tab_edge = "none" } }
elseif current_theme.colors then
  config.colors = current_theme.colors
  config.colors.tab_bar = { inactive_tab_edge = "none" }
end

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
  colors = { current_theme.bg },
}

config.keys = keybinds.keys
config.key_tables = keybinds.key_tables

config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate = 500
config.scrollback_lines = 10000

return config
