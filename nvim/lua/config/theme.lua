-- テーマ切り替え。状態は ~/.local/state/theme/{current,slots.json} で
-- wezterm 側 (wezterm/wezterm.lua) と共有する。id・スロット名・role タグの
-- 命名/優先順位は wezterm 側と揃えること。

local M = {}

local state_dir = (os.getenv("HOME") or vim.fn.expand("~")) .. "/.local/state/theme"
local current_file = state_dir .. "/current"
local slots_file = state_dir .. "/slots.json"

-- snacks.nvim のデフォルトヘッダー (lua/snacks/dashboard.lua の defaults.preset.header と同じ)。
-- mochipop 系以外に戻したときの復元用。
local DEFAULT_DASHBOARD_HEADER = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]]

local MOCHIPOP_DASHBOARD_HEADER = [[
⋆｡°✩⋆｡°✩⋆｡°✩⋆｡°✩⋆｡°✩⋆｡°✩⋆｡°✩⋆
     m  o  c  h  i  p  o  p
⋆｡°✩⋆｡°✩⋆｡°✩⋆｡°✩⋆｡°✩⋆｡°✩⋆｡°✩⋆]]

-- bufferline の見た目のうち区切り形状(separator_style/indicator)だけがテーマ依存。
-- それ以外は共通のベースとして保持し、テーマ切替のたびに setup() し直す。
local BUFFERLINE_BASE_OPTIONS = {
  numbers = "ordinal",
  diagnostics = "nvim_lsp",
  diagnostics_indicator = function(count, level)
    local icon = level:match("error") and " " or " "
    return " " .. icon .. count
  end,
  show_buffer_close_icons = true,
  show_close_icon = false,
  offsets = {
    {
      filetype = "neo-tree",
      text = "File Explorer",
      text_align = "left",
      separator = true,
    },
  },
}

-- config/theme.lua の shape (tri/round/underline) から
-- wezterm 側のタブ形状と揃えた bufferline / snacks 通知の見た目を決める。
local SHAPE_BUFFERLINE = {
  tri = { separator_style = "slant", indicator = { style = "icon" } },
  round = { separator_style = "thick", indicator = { style = "icon" } },
  underline = { separator_style = "thin", indicator = { style = "underline" } },
}

local THEMES = {
  tokyonight = {
    tags = { "dark", "classic" },
    shape = "tri",
    apply = function()
      require("tokyonight").setup({
        transparent = true,
        styles = {
          sidebars = "transparent",
          floats = "transparent",
        },
      })
      vim.cmd.colorscheme("tokyonight")
    end,
  },
  mocha = {
    tags = { "dark", "kawaii", "classic" },
    shape = "round",
    apply = function()
      require("catppuccin").setup({ flavour = "mocha", transparent_background = true })
      vim.cmd.colorscheme("catppuccin")
    end,
  },
  latte = {
    tags = { "light", "kawaii", "classic" },
    shape = "round",
    apply = function()
      require("catppuccin").setup({ flavour = "latte", transparent_background = true })
      vim.cmd.colorscheme("catppuccin")
    end,
  },
  rosepine = {
    tags = { "dark", "elegant", "classic" },
    shape = "underline",
    apply = function()
      require("rose-pine").setup({ variant = "main", styles = { transparency = true } })
      vim.cmd.colorscheme("rose-pine")
    end,
  },
  dawn = {
    tags = { "light", "elegant", "classic" },
    shape = "underline",
    apply = function()
      require("rose-pine").setup({ variant = "dawn", styles = { transparency = true } })
      vim.cmd.colorscheme("rose-pine")
    end,
  },
  mochi = {
    tags = { "dark", "kawaii", "buzz", "original" },
    shape = "round",
    smear_color = "#d9a4ff",
    dashboard_header = MOCHIPOP_DASHBOARD_HEADER,
    apply = function()
      require("mini.base16").setup({
        use_cterm = true,
        palette = {
          base00 = "#221a2c", base01 = "#2c2138", base02 = "#362a44", base03 = "#9686a8",
          base04 = "#b8a4c4", base05 = "#f5e8f7", base06 = "#fbf3fc", base07 = "#fff9ff",
          base08 = "#ff6f9f", base09 = "#ffab7a", base0A = "#ffd889", base0B = "#8de8b8",
          base0C = "#7fe3ea", base0D = "#8fc4ff", base0E = "#d9a4ff", base0F = "#c98f6a",
        },
      })
    end,
  },
  sakura = {
    tags = { "light", "kawaii", "buzz", "original" },
    shape = "round",
    smear_color = "#832eb8",
    dashboard_header = MOCHIPOP_DASHBOARD_HEADER,
    apply = function()
      require("mini.base16").setup({
        use_cterm = true,
        palette = {
          base00 = "#fff5fa", base01 = "#ffe9f3", base02 = "#ffd9ec", base03 = "#81567a",
          base04 = "#7a4f72", base05 = "#4a2b45", base06 = "#2e1a2b", base07 = "#200f1e",
          base08 = "#c3225c", base09 = "#ae4f19", base0A = "#985c16", base0B = "#1e764c",
          base0C = "#197676", base0D = "#2a68c6", base0E = "#832eb8", base0F = "#8a5a3a",
        },
      })
    end,
  },
}

local ALL_TAGS = {}
for _, t in pairs(THEMES) do
  for _, tag in ipairs(t.tags) do
    ALL_TAGS[tag] = true
  end
end

local last_applied = nil

local function ensure_dir()
  vim.fn.mkdir(state_dir, "p")
end

local function read_current()
  local f = io.open(current_file, "r")
  if not f then
    return nil
  end
  local content = f:read("*l")
  f:close()
  if not content then
    return nil
  end
  content = content:gsub("%s+$", "")
  return content ~= "" and content or nil
end

local function write_current(id)
  ensure_dir()
  local f = io.open(current_file, "w")
  if f then
    f:write(id)
    f:close()
  end
end

local function write_slots(slots)
  ensure_dir()
  local f = io.open(slots_file, "w")
  if f then
    f:write(vim.json.encode(slots))
    f:close()
  end
end

local function read_slots()
  local f = io.open(slots_file, "r")
  if not f then
    local default = { main = "tokyonight" }
    write_slots(default)
    return default
  end
  local content = f:read("*a")
  f:close()
  local ok, decoded = pcall(vim.json.decode, content)
  if ok and type(decoded) == "table" then
    return decoded
  end
  return { main = "tokyonight" }
end

local smear_setup_done = false

local function set_smear(color)
  local ok, sc = pcall(require, "smear_cursor")
  if not ok then
    return
  end
  if not smear_setup_done then
    sc.setup({ enabled = false })
    smear_setup_done = true
  end
  if color then
    sc.cursor_color = color
    sc.enabled = true
  else
    sc.enabled = false
  end
end

local function set_dashboard(header)
  local ok, snacks = pcall(require, "snacks")
  if not ok or not snacks.config or not snacks.config.dashboard then
    return
  end
  local dash_cfg = snacks.config.dashboard
  dash_cfg.preset = dash_cfg.preset or {}
  dash_cfg.preset.header = header or DEFAULT_DASHBOARD_HEADER
end

local function set_bufferline(shape)
  local ok, bufferline = pcall(require, "bufferline")
  if not ok then
    return
  end
  local shape_opts = SHAPE_BUFFERLINE[shape] or SHAPE_BUFFERLINE.tri
  bufferline.setup({
    options = vim.tbl_deep_extend("force", {}, BUFFERLINE_BASE_OPTIONS, shape_opts),
  })
end

function M.apply(id)
  local theme = THEMES[id]
  if not theme then
    vim.notify('Theme: unknown theme id "' .. id .. '"', vim.log.levels.ERROR)
    return
  end
  theme.apply()
  set_smear(theme.smear_color)
  set_dashboard(theme.dashboard_header)
  set_bufferline(theme.shape)
  last_applied = id
  write_current(id)
end

function M.pick(ids)
  ids = ids or vim.tbl_keys(THEMES)
  table.sort(ids)
  local ok_fzf, fzf = pcall(require, "fzf-lua")
  if not ok_fzf then
    vim.ui.select(ids, { prompt = "Theme:" }, function(choice)
      if choice then
        M.apply(choice)
      end
    end)
    return
  end
  local items = {}
  for _, id in ipairs(ids) do
    table.insert(items, string.format("%-12s %s", id, table.concat(THEMES[id].tags, ",")))
  end
  fzf.fzf_exec(items, {
    prompt = "Theme> ",
    actions = {
      ["default"] = function(selected)
        local chosen = selected[1] and selected[1]:match("^(%S+)")
        if chosen then
          M.apply(chosen)
        end
      end,
    },
  })
end

function M.switch(raw)
  raw = (raw or ""):gsub("^%s+", ""):gsub("%s+$", "")

  local slot, id = raw:match("^([%w_%-]+)=([%w_%-]+)$")
  if slot then
    if THEMES[slot] then
      vim.notify('Theme: slot name "' .. slot .. '" collides with a theme id', vim.log.levels.ERROR)
      return
    end
    if ALL_TAGS[slot] then
      vim.notify('Theme: slot name "' .. slot .. '" collides with a role tag', vim.log.levels.ERROR)
      return
    end
    if not THEMES[id] then
      vim.notify('Theme: unknown theme id "' .. id .. '"', vim.log.levels.ERROR)
      return
    end
    local slots = read_slots()
    slots[slot] = id
    write_slots(slots)
    M.apply(id)
    vim.notify('Theme: registered "' .. slot .. '" -> ' .. id, vim.log.levels.INFO)
    return
  end

  if raw == "" then
    M.pick()
    return
  end

  if THEMES[raw] then
    M.apply(raw)
    return
  end

  local slots = read_slots()
  if slots[raw] then
    if not THEMES[slots[raw]] then
      vim.notify('Theme: slot "' .. raw .. '" points to unknown id "' .. slots[raw] .. '"', vim.log.levels.ERROR)
      return
    end
    M.apply(slots[raw])
    return
  end

  if ALL_TAGS[raw] then
    local matches = {}
    for tid, t in pairs(THEMES) do
      if vim.tbl_contains(t.tags, raw) then
        table.insert(matches, tid)
      end
    end
    table.sort(matches)
    if #matches == 1 then
      M.apply(matches[1])
    else
      M.pick(matches)
    end
    return
  end

  vim.notify('Theme: unknown theme/slot/role "' .. raw .. '"', vim.log.levels.ERROR)
end

function M.setup()
  ensure_dir()

  local id = read_current() or "tokyonight"
  if not THEMES[id] then
    id = "tokyonight"
  end
  M.apply(id)

  vim.api.nvim_create_user_command("Theme", function(opts)
    M.switch(opts.args)
  end, {
    nargs = "?",
    complete = function(arg_lead)
      local candidates = {}
      for tid, _ in pairs(THEMES) do
        table.insert(candidates, tid)
      end
      for tag, _ in pairs(ALL_TAGS) do
        table.insert(candidates, tag)
      end
      for slot, _ in pairs(read_slots()) do
        table.insert(candidates, slot)
      end
      table.sort(candidates)
      if not arg_lead or arg_lead == "" then
        return candidates
      end
      local out = {}
      for _, c in ipairs(candidates) do
        if c:sub(1, #arg_lead) == arg_lead then
          table.insert(out, c)
        end
      end
      return out
    end,
  })

  vim.keymap.set("n", "<leader>ut", function()
    M.pick()
  end, { desc = "Switch theme" })

  vim.api.nvim_create_autocmd("FocusGained", {
    callback = function()
      local disk_id = read_current()
      if disk_id and disk_id ~= last_applied and THEMES[disk_id] then
        THEMES[disk_id].apply()
        last_applied = disk_id
      end
    end,
  })
end

return M
