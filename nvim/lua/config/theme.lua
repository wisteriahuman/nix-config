-- テーマ切り替え。状態は ~/.local/state/theme/{current,slots.json} で
-- wezterm 側 (wezterm/wezterm.lua) と共有する。id・スロット名・role タグの
-- 命名/優先順位は wezterm 側と揃えること。

local M = {}

local state_dir = (os.getenv("HOME") or vim.fn.expand("~")) .. "/.local/state/theme"
local current_file = state_dir .. "/current"
local slots_file = state_dir .. "/slots.json"

local THEMES = {
  tokyonight = {
    tags = { "dark", "classic" },
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
    apply = function()
      require("catppuccin").setup({ flavour = "mocha", transparent_background = true })
      vim.cmd.colorscheme("catppuccin")
    end,
  },
  latte = {
    tags = { "light", "kawaii", "classic" },
    apply = function()
      require("catppuccin").setup({ flavour = "latte", transparent_background = true })
      vim.cmd.colorscheme("catppuccin")
    end,
  },
  rosepine = {
    tags = { "dark", "elegant", "classic" },
    apply = function()
      require("rose-pine").setup({ variant = "main", styles = { transparency = true } })
      vim.cmd.colorscheme("rose-pine")
    end,
  },
  dawn = {
    tags = { "light", "elegant", "classic" },
    apply = function()
      require("rose-pine").setup({ variant = "dawn", styles = { transparency = true } })
      vim.cmd.colorscheme("rose-pine")
    end,
  },
  mochi = {
    tags = { "dark", "kawaii", "buzz", "original" },
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
    apply = function()
      require("mini.base16").setup({
        use_cterm = true,
        palette = {
          base00 = "#fff5fa", base01 = "#ffe9f3", base02 = "#ffd9ec", base03 = "#9c6f92",
          base04 = "#7a4f72", base05 = "#4a2b45", base06 = "#2e1a2b", base07 = "#200f1e",
          base08 = "#e0507a", base09 = "#e0793d", base0A = "#e0a23d", base0B = "#3fb88f",
          base0C = "#2fb0c4", base0D = "#4f8fe0", base0E = "#b968e0", base0F = "#b07a4f",
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

function M.apply(id)
  local theme = THEMES[id]
  if not theme then
    vim.notify('Theme: unknown theme id "' .. id .. '"', vim.log.levels.ERROR)
    return
  end
  theme.apply()
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
