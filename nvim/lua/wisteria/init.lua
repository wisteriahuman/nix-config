-- タイトル画面(snacks dashboard)に藤と猫を重ねて描く。
local Canvas = require("wisteria.canvas")
local cat = require("wisteria.cat")
local color = require("wisteria.color")
local petals = require("wisteria.petals")
local scene = require("wisteria.scene")
local speech = require("wisteria.speech")

local M = {}

local ns = vim.api.nvim_create_namespace("wisteria_art")
local ns_logo = vim.api.nvim_create_namespace("wisteria_logo")
local ns_bg = vim.api.nvim_create_namespace("wisteria_bg")
local ns_bubble = vim.api.nvim_create_namespace("wisteria_bubble")

local TICK = 0.1
local PETAL_COLORS = { "#d9c4ff", "#f3e9ff", "#b79cff" }
local GLOW = "#f1e6ff"

---@class wisteria.State
---@field buf integer
---@field win integer
---@field static wisteria.Canvas 藤だけを描いた、動かない層
---@field text table<integer, table<integer, boolean>> 文字のあるセル
---@field logo? { left: integer, right: integer, top: integer, bottom: integer }
---@field period wisteria.Period
---@field petals wisteria.Petals
---@field cat wisteria.CatState
---@field speech wisteria.Speech
---@field said? string いま吹き出しに出している一言
---@field bubble? { top: integer, bottom: integer, left: integer, right: integer }
---@field t number
---@field timer? uv.uv_timer_t

---@type wisteria.State?
local state = nil

-- 文字部分(ロゴ+メニュー+起動時間)の行数。上の余白を決めるのに使う。
local CONTENT_ROWS = 18
-- 2列で表示できる最小の幅(snacks.lua の width = 54 が2つ + 間の4桁)
local TWO_PANE_COLS = 112
local BAND_ROWS = 13
local MIN_BAND_ROWS = 6

--- 藤を垂らすために、文字部分の上に空ける行数。
---@return integer
function M.band()
  if vim.o.columns < TWO_PANE_COLS then
    return 0
  end
  -- タブライン・ステータスライン・コマンドラインの3行を除いた高さで考える
  local band = math.min(BAND_ROWS, vim.o.lines - 3 - CONTENT_ROWS - 4)
  return band >= MIN_BAND_ROWS and band or 0
end

--- dashboard の先頭に置く空白。snacks は全体を上下中央に寄せるので、その分を見込んで足す。
function M.spacer()
  local band = M.band()
  local n = band > 0 and math.max(0, 2 * band + CONTENT_ROWS - (vim.o.lines - 3)) or 0
  -- 空の text 自体が1行ぶんあるので、その分を引く
  return { text = "", padding = math.max(0, n - 1) }
end

local function find_dashboard()
  -- <leader>h で重ねて開いたときは、いま居るウィンドウが新しいタイトル画面
  local cur = vim.api.nvim_get_current_win()
  if vim.bo[vim.api.nvim_win_get_buf(cur)].filetype == "snacks_dashboard" then
    return vim.api.nvim_win_get_buf(cur), cur
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "snacks_dashboard" then
      return buf, win
    end
  end
end

local function normal_bg()
  local hl = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  return hl.bg and string.format("#%06x", hl.bg) or "#000000"
end

local LOGO_CHARS = {}
for _, ch in ipairs(vim.fn.split("█╗╔╝╚═║", "\\zs")) do
  LOGO_CHARS[ch] = true
end

--- 文字のあるセルと、ロゴの範囲を調べる。
local function scan(lines)
  local text, logo = {}, nil
  local box = { left = math.huge, right = -1, top = math.huge }
  for i, line in ipairs(lines) do
    local row, col = i - 1, 0
    for _, ch in ipairs(vim.fn.split(line, "\\zs")) do
      local width = vim.api.nvim_strwidth(ch)
      if ch ~= " " then
        text[row] = text[row] or {}
        for c = col, col + width - 1 do
          text[row][c] = true
        end
        box.left, box.right, box.top = math.min(box.left, col), math.max(box.right, col), math.min(box.top, row)
        if LOGO_CHARS[ch] then
          logo = logo or { left = col, right = col, top = row, bottom = row }
          logo.left, logo.right, logo.bottom = math.min(logo.left, col), math.max(logo.right, col), row
        end
      end
      col = col + width
    end
  end
  return text, box, logo
end

local LOGO_TOP, LOGO_BOTTOM = "#f1dcff", "#b68af2"

local function paint_logo(buf, lines, logo, period)
  vim.api.nvim_buf_clear_namespace(buf, ns_logo, 0, -1)
  local rows = logo.bottom - logo.top
  for row = logo.top, logo.bottom do
    local c = color.mix(LOGO_TOP, LOGO_BOTTOM, rows > 0 and (row - logo.top) / rows or 0)
    if period.tint then
      c = color.mix(c, period.tint, period.amount * 0.5)
    end
    local name = "WisteriaLogo" .. (row - logo.top)
    vim.api.nvim_set_hl(0, name, { fg = c, bold = true })
    -- snacks 側の色付け(既定の優先度 4096)より上に重ねる
    -- ロゴの行は空白と1桁幅の文字だけなので、桁数=文字数。行が短いときは行末まで。
    local line = lines[row + 1]
    local from, to = vim.fn.byteidx(line, logo.left), vim.fn.byteidx(line, logo.right + 1)
    vim.api.nvim_buf_set_extmark(buf, ns_logo, row, from >= 0 and from or 0, {
      end_col = to >= 0 and to or #line,
      hl_group = name,
      priority = 5000,
    })
  end
end

local function stop()
  if state and state.timer then
    state.timer:stop()
    state.timer:close()
    state.timer = nil
  end
end

-- タイトル画面の間だけ、最下行(コマンドライン)を空の色に合わせ、桁表示や
-- ステータスライン・タブラインを隠す。自分で変えた項目だけを覚えて、閉じるときに戻す。
local saved = nil
local function dress(bg, floating)
  saved = saved or { opts = {}, msgarea = vim.api.nvim_get_hl(0, { name = "MsgArea" }) }
  local want = { ruler = false }
  if not floating then
    want.laststatus, want.showtabline = 0, 0
  end
  for name, value in pairs(want) do
    if vim.o[name] ~= value then
      if saved.opts[name] == nil then
        saved.opts[name] = vim.o[name]
      end
      vim.o[name] = value
    end
  end
  vim.api.nvim_set_hl(0, "MsgArea", { bg = bg })
end

local function undress()
  if saved then
    for name, value in pairs(saved.opts) do
      vim.o[name] = value
    end
    vim.api.nvim_set_hl(0, "MsgArea", saved.msgarea)
    saved = nil
  end
end

local function in_bubble(row, col)
  local b = state and state.bubble
  return b ~= nil and row >= b.top and row <= b.bottom and col >= b.left and col <= b.right
end

--- 動かない層を、深夜の明滅と突風の揺れを加えながら写す。
local glow_cache = {}
local function copy_static(canvas, st)
  local level = 0
  if st.period.name == "midnight" then
    level = math.floor((math.sin(st.t * 1.4) + 1) / 2 * 3 + 0.5)
  end
  local gust = st.petals:gusting()
  if level == 0 and not gust then
    for i, c in pairs(st.static.px) do
      canvas.px[i] = c
    end
    return
  end
  glow_cache[level] = glow_cache[level] or {}
  local cache, w = glow_cache[level], canvas.w
  for i, c in pairs(st.static.px) do
    if level > 0 then
      cache[c] = cache[c] or color.mix(c, GLOW, level * 0.09)
      c = cache[c]
    end
    if gust then
      local y = math.floor(i / w)
      -- 房の先ほど大きく流れる。葉とつる(上の数ドット)は動かさない。
      canvas:set(i % w + math.floor(math.min(1, math.max(0, (y - 6) / 16)) * 2 + 0.5), y, c)
    else
      canvas.px[i] = c
    end
  end
end

---@param dt number 前のコマからの秒数(0 なら動かさずに描くだけ)
local function frame(dt)
  local st = state
  if not st then
    return
  end
  st.t = st.t + dt
  local width, height = st.static.cols, st.static.rows
  local canvas = Canvas.new(width, height)
  copy_static(canvas, st)

  local pose, cat_x, cat_y
  if st.logo then
    pose = cat.pose(st.cat, st.period, dt)
    cat_x, cat_y = st.logo.right - 15, st.logo.top * 2 - cat.height
    cat.draw(canvas, pose, cat_x, cat_y, st.period)

    local said = st.speech:current(dt)
    if said ~= st.said then
      st.said = said
      st.bubble = speech.draw(st.buf, ns_bubble, said, st.logo.top - 3, cat_x + cat.width + 1, width - 1)
    end
  end

  local colors = {}
  for i, c in ipairs(PETAL_COLORS) do
    colors[i] = st.period.tint and color.mix(c, st.period.tint, st.period.amount) or c
  end
  st.petals:step(dt, petals.motions[st.period.name], {
    w = canvas.w,
    h = canvas.h,
    top = 5,
    colors = colors,
    solid = function(x, y)
      local row = math.floor(y / 2)
      local t = st.text[row]
      return (t ~= nil and t[x] == true) or in_bubble(row, x) or (pose ~= nil and cat.solid(pose, x - cat_x, y - cat_y))
    end,
  })
  st.petals:draw(canvas)

  canvas:draw(st.buf, ns, function(row, col)
    local t = st.text[row]
    return (t ~= nil and (t[col] or t[col - 1] or t[col + 1])) or in_bubble(row, col) or false
  end)
end

local function tick()
  if not state or not vim.api.nvim_buf_is_valid(state.buf) or vim.fn.bufwinid(state.buf) == -1 then
    stop()
    state = nil
    undress()
    return
  end
  local ok, err = pcall(frame, TICK)
  if not ok then
    stop()
    vim.notify("wisteria: " .. tostring(err), vim.log.levels.WARN)
  end
end

local function start()
  if state and not state.timer and state.static.cols > 0 then
    state.timer = assert(vim.uv.new_timer())
    state.timer:start(TICK * 1000, TICK * 1000, vim.schedule_wrap(tick))
  end
end

function M.render()
  local buf, win = find_dashboard()
  if not buf then
    return
  end
  local height, width = vim.api.nvim_win_get_height(win), vim.api.nvim_win_get_width(win)

  -- 画面の下端まで描けるように、空行で埋める
  local count = vim.api.nvim_buf_line_count(buf)
  if count < height then
    vim.bo[buf].modifiable = true
    local pad = {}
    for i = 1, height - count do
      pad[i] = ""
    end
    vim.api.nvim_buf_set_lines(buf, count, count, false, pad)
    vim.bo[buf].modifiable = false
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local text, box, logo = scan(lines)
  -- vim.g.wisteria_hour に 0..23 を入れると、その時刻の見た目を確認できる
  local hour = vim.g.wisteria_hour or tonumber(os.date("%H"))
  local period = scene.resolve(scene.period(hour), normal_bg())

  -- このウィンドウだけ背景を時刻の色にする。行末より右の余白まで確実に塗るため、
  -- ウィンドウの Normal を差し替えるのに加えて、全行に行ハイライトを付ける。
  -- 絵や吹き出しは背景色を持たせず、この行ハイライトの上に重ねる。
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local bg = tonumber(period.bg:sub(2), 16)
  vim.api.nvim_set_hl(0, "SnacksDashboardNormal", { fg = normal.fg, bg = bg })
  vim.api.nvim_set_hl(0, "WisteriaBubble", { fg = color.mix("#b79cff", period.bg, 0.2) })
  vim.api.nvim_set_hl(0, "WisteriaBubbleText", { fg = normal.fg })
  vim.api.nvim_buf_clear_namespace(buf, ns_bg, 0, -1)
  for row = 0, #lines - 1 do
    -- 行ごとに色を変えて、空のグラデーションにする
    local name = "WisteriaBg" .. row
    local sky = period.sky_bg(#lines > 1 and row / (#lines - 1) or 0)
    vim.api.nvim_set_hl(0, name, { bg = tonumber(sky:sub(2), 16) })
    vim.api.nvim_buf_set_extmark(buf, ns_bg, row, 0, { line_hl_group = name, priority = 1 })
  end

  dress(tonumber(period.sky_bg(1):sub(2), 16), vim.api.nvim_win_get_config(win).relative ~= "")

  if logo then
    paint_logo(buf, lines, logo, period)
  end

  local art = M.band() > 0 and box.right >= 0
  local static = Canvas.new(art and width or 0, art and height or 0)
  if art then
    scene.wisteria(static, box, period, tonumber(os.date("%Y%m%d")))
  end

  stop()
  local same = state and state.buf == buf and state.period.name == period.name
  state = {
    buf = buf,
    win = win,
    static = static,
    text = text,
    logo = art and logo or nil,
    period = period,
    petals = same and state.petals or petals.new(),
    cat = same and state.cat or cat.new_state(),
    speech = same and state.speech or speech.new(period.name),
    t = same and state.t or 0,
  }
  vim.api.nvim_buf_clear_namespace(buf, ns_bubble, 0, -1)
  if art then
    frame(0)
    start()
  else
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  end
end

function M.setup()
  math.randomseed(os.time())
  local group = vim.api.nvim_create_augroup("wisteria_title", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "SnacksDashboardUpdatePost",
    callback = function()
      -- 飾りの失敗でタイトル画面を使えなくしない
      local ok, err = pcall(M.render)
      if not ok then
        vim.schedule(function()
          vim.notify("wisteria: " .. tostring(err), vim.log.levels.WARN)
        end)
      end
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "SnacksDashboardClosed",
    callback = function()
      -- 重ねて開いた別のタイトル画面が閉じただけかもしれないので、消えた後に確かめる
      vim.schedule(function()
        if state and not vim.api.nvim_buf_is_valid(state.buf) then
          stop()
          state = nil
          undress()
        end
      end)
    end,
  })
  -- 画面を見ていない間は動かさない
  vim.api.nvim_create_autocmd("FocusLost", { group = group, callback = stop })
  vim.api.nvim_create_autocmd("FocusGained", { group = group, callback = start })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      Canvas.clear_hl_cache()
      vim.schedule(M.render)
    end,
  })
end

return M
