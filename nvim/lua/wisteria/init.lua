-- タイトル画面(snacks dashboard)に藤と猫を重ねて描く。
local Canvas = require("wisteria.canvas")
local cat = require("wisteria.cat")
local color = require("wisteria.color")
local intro = require("wisteria.intro")
local opening = require("wisteria.opening")
local petals = require("wisteria.petals")
local scene = require("wisteria.scene")
local speech = require("wisteria.speech")

local M = {}

local ns = vim.api.nvim_create_namespace("wisteria_art")
local ns_logo = vim.api.nvim_create_namespace("wisteria_logo")
local ns_bg = vim.api.nvim_create_namespace("wisteria_bg")
local ns_bubble = vim.api.nvim_create_namespace("wisteria_bubble")
local ns_cover = vim.api.nvim_create_namespace("wisteria_cover")
local ns_key = vim.api.nvim_create_namespace("wisteria_key")

local TICK = 0.1
local PETAL_COLORS = { "#d9c4ff", "#f3e9ff", "#b79cff" }
local GLOW = "#f1e6ff"
local DARK = "#07050b" -- オープニングの出だしの暗闇

---@class wisteria.State
---@field buf integer
---@field win integer
---@field static wisteria.Canvas 藤だけを描いた、動かない層
---@field text table<integer, table<integer, boolean>> 文字のあるセル
---@field logo? { left: integer, right: integer, top: integer, bottom: integer }
---@field period wisteria.Period
---@field row_bg fun(row: integer): string
---@field petals wisteria.Petals
---@field cat wisteria.CatState
---@field speech wisteria.Speech
---@field opening? wisteria.Opening オープニング演出の途中なら、その進行
---@field intro? wisteria.Intro 長い版のオープニングの中身
---@field intro_env? wisteria.IntroEnv
---@field sky fun(row: integer): string その時刻の空の色(暗転を掛ける前)
---@field fg? integer 文字の色
---@field fade number 空の明るさ(0 で暗闇、1 で通常)
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
  local text, logo, logo_cells = {}, nil, {}
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
          logo_cells[#logo_cells + 1] = { row, col }
        end
      end
      col = col + width
    end
  end
  return text, box, logo, logo_cells
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

local end_opening_guard

local function undress()
  end_opening_guard()
  if saved then
    for name, value in pairs(saved.opts) do
      vim.o[name] = value
    end
    vim.api.nvim_set_hl(0, "MsgArea", saved.msgarea)
    saved = nil
  end
end

-- オープニングの間だけ、カーソルを隠し、キー入力を見張る
local guicursor, smear_was = nil, nil
local function begin_opening_guard()
  if guicursor == nil then
    -- smear-cursor は自前でカーソルを描くので、演出の間は止める
    local ok, smear = pcall(require, "smear_cursor")
    if ok then
      smear_was = smear.enabled
      smear.enabled = false
    end
    guicursor = vim.o.guicursor
    vim.api.nvim_set_hl(0, "WisteriaNoCursor", { blend = 100, nocombine = true })
    vim.o.guicursor = "a:WisteriaNoCursor"
  end
  vim.on_key(function(key, typed)
    local name = vim.fn.keytrans(typed ~= nil and typed or key)
    -- メニューのキーは snacks がそのまま実行する。それ以外も含め、押されたら演出を打ち切る。
    if name ~= "" and not name:find("Mouse") and not name:find("ScrollWheel") and state and state.opening then
      state.opening.skip = true
    end
  end, ns_key)
end

end_opening_guard = function()
  vim.on_key(nil, ns_key)
  if guicursor ~= nil then
    vim.o.guicursor = guicursor
    guicursor = nil
    if smear_was ~= nil then
      require("smear_cursor").enabled = smear_was
      smear_was = nil
    end
  end
end

--- 空の明るさを変える(長い版の出だしで、暗闇から空が明ける)。
local function apply_fade(st, value)
  if st.fade == value then
    return
  end
  st.fade = value
  local function shade(c)
    return tonumber(color.mix(DARK, c, value):sub(2), 16)
  end
  for row = 0, vim.api.nvim_buf_line_count(st.buf) - 1 do
    vim.api.nvim_set_hl(0, "WisteriaBg" .. row, { bg = shade(st.sky(row)) })
  end
  vim.api.nvim_set_hl(0, "SnacksDashboardNormal", { fg = st.fg, bg = shade(st.period.bg) })
  vim.api.nvim_set_hl(0, "MsgArea", { bg = shade(st.sky(st.static.rows)) })
end

--- hidden(row, col) が true のセルの文字を、背景色で覆う。
local function draw_cover_cells(st, hidden)
  local buf, width = st.buf, st.static.cols
  vim.api.nvim_buf_clear_namespace(buf, ns_cover, 0, -1)
  for row in pairs(st.text) do
    local from = nil
    for col = 0, width do
      local hide = col < width and hidden(row, col)
      if hide and not from then
        from = col
      elseif not hide and from then
        vim.api.nvim_buf_set_extmark(buf, ns_cover, row, 0, {
          virt_text = { { string.rep(" ", col - from), "WisteriaBg" .. row } },
          virt_text_win_col = from,
          priority = 100,
        })
        from = nil
      end
    end
  end
end

--- 演出の進み具合に合わせて、まだ見せない文字を背景色で覆う。
local function draw_cover(st, op)
  local buf, width = st.buf, st.static.cols
  vim.api.nvim_buf_clear_namespace(buf, ns_cover, 0, -1)
  local first, last = math.huge, -1
  for row in pairs(st.text) do
    first, last = math.min(first, row), math.max(last, row)
  end
  local menu, logo_p = opening.progress(op, "menu"), opening.progress(op, "logo")
  local function cover(row, from, to)
    if from <= to then
      vim.api.nvim_buf_set_extmark(buf, ns_cover, row, 0, {
        virt_text = { { string.rep(" ", to - from + 1), "WisteriaBg" .. row } },
        virt_text_win_col = from,
        priority = 100,
      })
    end
  end
  for row in pairs(st.text) do
    -- メニューと一覧は、上の行から順に現れる
    local shown = (row - first) / (last - first + 1) < menu
    local logo = st.logo
    if logo and row >= logo.top and row <= logo.bottom then
      -- ロゴは左から灯る。同じ行の右側(一覧)はメニューと一緒に現れる。
      cover(row, logo.left + math.floor(logo_p * (logo.right - logo.left + 1)), logo.right)
      if not shown then
        cover(row, 0, logo.left - 1)
        cover(row, logo.right + 1, width - 1)
      end
    elseif not shown then
      cover(row, 0, width - 1)
    end
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

  local op = st.opening
  if op then
    op.t = op.t + dt
    if op.skip or op.t >= (op.kind == "long" and intro.duration or op.line.duration) then
      st.opening, st.intro, op = nil, nil, nil
      vim.api.nvim_buf_clear_namespace(st.buf, ns_cover, 0, -1)
      apply_fade(st, 1)
      end_opening_guard()
    end
  end
  if op and op.kind == "long" and st.intro_env then
    st.intro = st.intro or intro.new(st.intro_env)
    local scene_now, t = st.intro, op.t
    apply_fade(st, scene_now:fade(t))
    scene_now:draw(canvas, t)
    draw_cover_cells(st, function(row, col)
      return scene_now:hidden(row, col, t)
    end)
    canvas:draw(st.buf, ns, function(row, col)
      -- 見えている文字の上には描かない。まだ隠している文字の上は通ってよい。
      local cells = st.text[row]
      if cells == nil then
        return false
      end
      for c = col - 1, col + 1 do
        if cells[c] and not scene_now:hidden(row, c, t) then
          return true
        end
      end
      return false
    end, st.row_bg)
    return
  end
  if op then
    -- 藤は上から伸びる
    local clip, w = opening.progress(op, "grow") * canvas.h, canvas.w
    for i, c in pairs(st.static.px) do
      if math.floor(i / w) <= clip then
        canvas.px[i] = c
      end
    end
    -- 長い版の出だし: 暗い画面に花びらが1枚落ちる
    if op.line.petal and op.t < op.line.petal[2] then
      local p = op.t / op.line.petal[2]
      canvas:set(math.floor(w / 2 + math.sin(p * 6) * 3), math.floor(p * canvas.h * 0.55), PETAL_COLORS[2])
    end
    -- 猫はロゴの後ろからせり上がる
    local cat_p = opening.progress(op, "cat")
    if st.logo and cat_p > 0 then
      local top = st.logo.top * 2
      cat.draw(
        canvas,
        "sit",
        st.logo.right - 15,
        top - cat.height + math.floor((1 - cat_p) * cat.height + 0.5),
        st.period,
        top - 1
      )
    end
    draw_cover(st, op)
    canvas:draw(st.buf, ns, function(row, col)
      local t = st.text[row]
      return t ~= nil and (t[col] or t[col - 1] or t[col + 1]) or false
    end, st.row_bg)
    return
  end

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
  end, st.row_bg)
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

--- 長い版のオープニングを最初から再生する(タイトル画面の o)。
function M.replay()
  local st = state
  if not st or not st.logo or st.opening then
    return
  end
  vim.api.nvim_buf_clear_namespace(st.buf, ns_bubble, 0, -1)
  st.said, st.bubble = nil, nil
  st.petals = petals.new()
  st.opening, st.intro = opening.new("long"), nil
  begin_opening_guard()
end

--- 右の列(一覧)が始まる桁
local function pane2_col(win)
  return math.floor((vim.api.nvim_win_get_width(win) - TWO_PANE_COLS) / 2) + TWO_PANE_COLS / 2 + 2
end

--- その行の右の列に文字があるか
local function has_right(st, row, pane2)
  for col in pairs(st.text[row] or {}) do
    if col >= pane2 then
      return true
    end
  end
  return false
end

--- 右の列の行へカーソルを置く。行末に置けば、snacks がその列の項目へ合わせる。
--- (snacks は列を文字数で判定するので、左に全角文字がある行では桁を保ったままだと左の列と誤認される)
local function goto_right(st, win, row)
  local line = vim.api.nvim_buf_get_lines(st.buf, row, row + 1, false)[1]
  vim.api.nvim_win_set_cursor(win, { row + 1, math.max(0, #line - 1) })
end

--- 右の一覧へ移る。snacks は「カーソルが1文字右に動いたら右の列へ」という仕組みなので、
--- 右側に何も無い行(キーの文字が行末)では動けない。そのときは一覧のある一番近い行へ飛ぶ。
function M.right()
  local st = state
  local win = vim.api.nvim_get_current_win()
  local cur = vim.api.nvim_win_get_cursor(win)[1] - 1
  if not st or vim.fn.col(".") < vim.fn.col("$") - 1 then
    vim.cmd("normal! l")
    return
  end
  local pane2, best = pane2_col(win), nil
  for row in pairs(st.text) do
    if has_right(st, row, pane2) and (not best or math.abs(row - cur) < math.abs(best - cur)) then
      best = row
    end
  end
  if best then
    goto_right(st, win, best)
  end
end

--- 上下の移動。右の一覧の中では、右の列にとどまったまま隣の行へ移る。
---@param step integer 1 で下、-1 で上
function M.vertical(step)
  local st = state
  local win = vim.api.nvim_get_current_win()
  local pane2 = pane2_col(win)
  if not st or vim.fn.virtcol(".") - 1 < pane2 then
    vim.cmd("normal! " .. (step > 0 and "j" or "k"))
    return
  end
  local row = vim.api.nvim_win_get_cursor(win)[1] - 1 + step
  local count = vim.api.nvim_buf_line_count(st.buf)
  while row >= 0 and row < count do
    if has_right(st, row, pane2) then
      goto_right(st, win, row)
      return
    end
    row = row + step
  end
end

-- 引数なしで起動したときの、最初のタイトル画面かどうか
local boot = vim.fn.argc(-1) == 0

function M.render()
  local buf, win = find_dashboard()
  if not buf then
    return
  end
  local height, width = vim.api.nvim_win_get_height(win), vim.api.nvim_win_get_width(win)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local text, box, logo, logo_cells = scan(lines)
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
  local function sky(row)
    return period.sky_bg(height > 1 and math.min(1, row / (height - 1)) or 0)
  end
  local function row_bg(row)
    local fade = state and state.fade or 1
    return fade < 1 and color.mix(DARK, sky(row), fade) or sky(row)
  end
  vim.api.nvim_buf_clear_namespace(buf, ns_bg, 0, -1)
  for row = 0, #lines - 1 do
    -- 行ごとに色を変えて、空のグラデーションにする
    local name = "WisteriaBg" .. row
    vim.api.nvim_set_hl(0, name, { bg = tonumber(sky(row):sub(2), 16) })
    vim.api.nvim_buf_set_extmark(buf, ns_bg, row, 0, { line_hl_group = name, priority = 1 })
  end

  dress(tonumber(period.sky_bg(1):sub(2), 16), vim.api.nvim_win_get_config(win).relative ~= "")

  if logo then
    paint_logo(buf, lines, logo, period)
  end

  local art = M.band() > 0 and box.right >= 0
  local static = Canvas.new(art and width or 0, art and height or 0)
  local parts
  if art then
    parts = scene.build(width, height * 2, box, period, tonumber(os.date("%Y%m%d")))
    scene.draw(static, parts)
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
    row_bg = row_bg,
    sky = sky,
    fg = normal.fg,
    fade = 1,
    petals = same and state.petals or petals.new(),
    cat = same and state.cat or cat.new_state(),
    speech = same and state.speech or speech.new(period.name),
    opening = same and state.opening or nil,
    t = same and state.t or 0,
  }
  vim.api.nvim_buf_clear_namespace(buf, ns_bubble, 0, -1)
  vim.api.nvim_buf_clear_namespace(buf, ns_cover, 0, -1)
  if art and logo then
    local colors = {}
    for i, c in ipairs(PETAL_COLORS) do
      colors[i] = period.tint and color.mix(c, period.tint, period.amount) or c
    end
    state.intro_env = {
      w = width,
      h = height * 2,
      parts = parts,
      logo = logo,
      logo_cells = logo_cells,
      text = text,
      seat_x = logo.right - 15,
      seat_y = logo.top * 2 - cat.height,
      period = period,
      colors = colors,
    }
  end

  -- 起動時に出るタイトル画面でだけ演出する(戻ってきたときや <leader>h では出さない)
  if art and logo and boot then
    state.opening = opening.new(opening.kind_for_today())
    begin_opening_guard()
  end
  boot = false
  if art and logo then
    vim.keymap.set("n", "o", M.replay, { buffer = buf, nowait = true, desc = "オープニングを再生" })
  end
  vim.keymap.set("n", "l", M.right, { buffer = buf, nowait = true, desc = "右の一覧へ" })
  vim.keymap.set("n", "j", function()
    M.vertical(1)
  end, { buffer = buf, nowait = true, desc = "下の項目へ" })
  vim.keymap.set("n", "k", function()
    M.vertical(-1)
  end, { buffer = buf, nowait = true, desc = "上の項目へ" })
  -- 絵は画面の位置に合わせて描いているので、スクロールさせない
  for _, key in ipairs({ "<ScrollWheelUp>", "<ScrollWheelDown>", "<C-e>", "<C-y>", "<C-d>", "<C-u>", "<C-f>", "<C-b>" }) do
    vim.keymap.set("n", key, "<Nop>", { buffer = buf, nowait = true })
  end
  vim.api.nvim_create_autocmd("WinScrolled", {
    group = vim.api.nvim_create_augroup("wisteria_noscroll", { clear = true }),
    buffer = buf,
    callback = function()
      if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
        vim.api.nvim_win_call(win, function()
          if vim.fn.line("w0") ~= 1 then
            vim.fn.winrestview({ topline = 1 })
          end
        end)
      end
    end,
  })

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
