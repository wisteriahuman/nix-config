-- 長い版のオープニング。空が明け、藤が1本ずつ垂れ、花びらが集まって「NEOVIM」を作り、
-- 風でそれが塵になって崩れ、降りた塵がロゴとメニューになる。最後に猫が飛び降りて歩いてきて座る。
local cat = require("wisteria.cat")
local color = require("wisteria.color")
local sky_art = require("wisteria.sky")

local M = {}

-- 各場面の区間(秒)
local T = {
  sky = { 0, 1.9 },
  rise = { 0.2, 2.6 }, -- 太陽や月が動く
  stars = { 0.9, 3.2 }, -- 星が1つずつ灯る
  meteor = 3.3, -- 流れ星
  vine = { 0.6, 1.5 },
  grow = { 1.1, 3.0 },
  form = { 2.8, 4.6 },
  gust = { 5.2, 7.3 },
  drop = { 7.3, 7.65 },
  walk = { 7.65, 8.55 },
}
M.duration = 9.0

local GROW_TIME = 0.8 -- 房1本が伸びきるまで
local FLY_TIME = 0.75 -- 花びら1枚が目的地へ届くまで
local SETTLE = 0.8 -- 風が通ってから、塵がロゴに降りるまで
local SETTLE_MENU = 1.0 -- 同じく、メニューに降りるまで

-- 最初に出来て、崩れるもの。1文字=1ドット。ここを差し替えれば別の絵や言葉にできる。
local PRELUDE = {
  glyphs = {
    {
      "XX...XX",
      "XXX..XX",
      "XXX..XX",
      "XXXX.XX",
      "XX.X.XX",
      "XX.XXXX",
      "XX..XXX",
      "XX..XXX",
      "XX...XX",
      "XX...XX",
    },
    {
      "XXXXXXX",
      "XXXXXXX",
      "XX.....",
      "XX.....",
      "XXXXXX.",
      "XXXXXX.",
      "XX.....",
      "XX.....",
      "XXXXXXX",
      "XXXXXXX",
    },
    {
      ".XXXXX.",
      "XXXXXXX",
      "XX...XX",
      "XX...XX",
      "XX...XX",
      "XX...XX",
      "XX...XX",
      "XX...XX",
      "XXXXXXX",
      ".XXXXX.",
    },
    {
      "XX...XX",
      "XX...XX",
      "XX...XX",
      "XX...XX",
      "XX...XX",
      "XX...XX",
      ".XX.XX.",
      ".XX.XX.",
      "..XXX..",
      "..XXX..",
    },
    {
      "XXXXXXX",
      "XXXXXXX",
      "..XXX..",
      "..XXX..",
      "..XXX..",
      "..XXX..",
      "..XXX..",
      "..XXX..",
      "XXXXXXX",
      "XXXXXXX",
    },
    {
      "XX...XX",
      "XXX.XXX",
      "XXXXXXX",
      "XXXXXXX",
      "XX.X.XX",
      "XX.X.XX",
      "XX...XX",
      "XX...XX",
      "XX...XX",
      "XX...XX",
    },
  },
  gap = 2,
  -- Neovim の緑から青へ
  from = "#7ccf5a",
  to = "#3fb4f0",
}

local function clamp01(v)
  return math.min(1, math.max(0, v))
end

local function progress(range, t)
  return clamp01((t - range[1]) / (range[2] - range[1]))
end

--- 終わりに向かって減速
local function ease_out(p)
  return 1 - (1 - p) ^ 2
end

--- ゆっくり始まり、ゆっくり終わる
local function ease_in_out(p)
  return p * p * (3 - 2 * p)
end

---@class wisteria.IntroEnv
---@field w integer ドット単位の幅
---@field h integer ドット単位の高さ
---@field parts wisteria.Parts
---@field body? wisteria.Body 太陽か月
---@field stars wisteria.Star[]
---@field clouds wisteria.Cloud[]
---@field bees? wisteria.Bees
---@field bg_at fun(y: integer): string そのドット行の背景色(暗転を掛けたあと)
---@field logo { left: integer, right: integer, top: integer, bottom: integer }
---@field logo_cells { [1]: integer, [2]: integer }[] ロゴの文字があるセル {row, col}
---@field text table<integer, table<integer, boolean>> 文字のあるセル
---@field seat_x integer 猫が座る位置(ドット)
---@field seat_y integer
---@field period wisteria.Period
---@field colors string[] 花びらの色

---@class wisteria.Mote 花びら・塵の1粒
---@field ox number
---@field oy number
---@field tx number
---@field ty number
---@field start number
---@field span number 飛んでいる秒数
---@field phase number
---@field from string 出発時の色
---@field to string 到着時の色

---@class wisteria.Intro
---@field env wisteria.IntroEnv
---@field starts number[] 房ごとの伸び始める時刻
---@field prelude { x: integer, y: integer, color: string, lit: number, gone: number }[] 最初に出来る絵のドット
---@field sparks wisteria.Mote[] 絵を作りに集まる花びら
---@field dust wisteria.Mote[] 崩れた絵から飛ぶ塵
---@field arrive table<integer, number> ロゴのセル(row * w + col)ごとの、灯る時刻
---@field row_lag table<integer, number> メニューの行ごとの、現れる遅れ
---@field gust { y: number, lag: number, phase: number, color: string }[]
---@field meteor? wisteria.Meteor|false
---@field meteor_t? number
---@field bees_scared? boolean
local I = {}
I.__index = I

--- 風の先頭が、その桁(ドット)を通る時刻
local function front_time(env, x)
  return T.gust[1] + (x + 12) / (env.w + 40) * (T.gust[2] - T.gust[1])
end

--- 風の先頭の位置(ドット)。まだ吹いていなければ nil。
local function gust_front(env, t)
  if t < T.gust[1] then
    return nil
  end
  return -12 + progress(T.gust, t) * (env.w + 40)
end

--- 色を4段階で混ぜる(色数を増やしすぎないため)
local function blend(a, b, p)
  return color.mix(a, b, math.floor(p * 3 + 0.5) / 3)
end

---@param env wisteria.IntroEnv
function M.new(env)
  local self = setmetatable({
    env = env,
    starts = {},
    prelude = {},
    sparks = {},
    dust = {},
    arrive = {},
    row_lag = {},
    gust = {},
  }, I)

  -- 房は左から右へ、少しずつずれて伸び始める
  local span = T.grow[2] - T.grow[1] - GROW_TIME
  local sources = {}
  for i, r in ipairs(env.parts.racemes) do
    self.starts[i] = T.grow[1] + (r.x / env.w) * span + math.random() * 0.3
    if r.front and #r.px > 0 then
      sources[#sources + 1] = r
    end
  end

  -- ロゴのセルは、風が通った少し後に灯る
  local by_col, menu_cells = {}, {}
  for _, c in ipairs(env.logo_cells) do
    self.arrive[c[1] * env.w + c[2]] = front_time(env, c[2]) + SETTLE + math.random() * 0.25
    by_col[c[2]] = by_col[c[2]] or {}
    table.insert(by_col[c[2]], c)
  end
  for row, cells in pairs(env.text) do
    self.row_lag[row] = math.random() * 0.3
    if row < env.logo.top or row > env.logo.bottom then
      for col in pairs(cells) do
        menu_cells[#menu_cells + 1] = { row, col }
      end
    end
  end

  -- 最初の絵を、ロゴの場所の中央に置く
  local glyph_w, glyph_h = #PRELUDE.glyphs[1][1], #PRELUDE.glyphs[1]
  local total = #PRELUDE.glyphs * glyph_w + (#PRELUDE.glyphs - 1) * PRELUDE.gap
  local x0 = env.logo.left + math.floor((env.logo.right - env.logo.left + 1 - total) / 2)
  local y0 = env.logo.top * 2 + math.floor(((env.logo.bottom - env.logo.top + 1) * 2 - glyph_h) / 2)
  local window = T.form[2] - T.form[1] - FLY_TIME - 0.3
  for g, glyph in ipairs(PRELUDE.glyphs) do
    for gy, line in ipairs(glyph) do
      for gx = 1, #line do
        if line:sub(gx, gx) ~= "." then
          local x = x0 + (g - 1) * (glyph_w + PRELUDE.gap) + gx - 1
          local y = y0 + gy - 1
          local tone = color.mix(PRELUDE.from, PRELUDE.to, math.floor((x - x0) / total * 7 + 0.5) / 7)
          -- おおよそ左から右へ出来ていくが、ばらつきを持たせる
          local lit = T.form[1] + FLY_TIME + ((x - x0) / total) * window + math.random() * 0.3
          local gone = front_time(env, x)
          self.prelude[#self.prelude + 1] = { x = x, y = y, color = tone, lit = lit, gone = gone }

          -- 集まってくる花びら(手前の房から散る)
          local ox, oy = env.w / 2, 6
          if #sources > 0 then
            local src = sources[math.random(#sources)]
            local p = src.px[math.random(#src.px)]
            ox, oy = p[1], p[2]
          end
          local petal = env.colors[math.random(#env.colors)]
          self.sparks[#self.sparks + 1] = {
            ox = ox,
            oy = oy,
            tx = x,
            ty = y,
            start = lit - FLY_TIME,
            span = FLY_TIME,
            phase = math.random() * 6.28,
            from = petal,
            to = tone,
          }

          -- 崩れたあとの塵。6割は近くのロゴのセルへ、残りはメニューへ降りる。
          local dest, land
          local near = by_col[x + math.random(-2, 2)]
          if near and math.random() < 0.6 then
            dest = near[math.random(#near)]
            land = self.arrive[dest[1] * env.w + dest[2]]
          elseif #menu_cells > 0 then
            for _ = 1, 6 do
              dest = menu_cells[math.random(#menu_cells)]
              if math.abs(dest[2] - x) < 14 then
                break
              end
            end
            land = front_time(env, dest[2]) + SETTLE_MENU + self.row_lag[dest[1]]
          end
          if dest then
            self.dust[#self.dust + 1] = {
              ox = x,
              oy = y,
              tx = dest[2],
              ty = dest[1] * 2 + math.random(0, 1),
              start = gone,
              span = math.max(0.5, land - gone),
              phase = math.random() * 6.28,
              from = tone,
              to = petal,
            }
          end
        end
      end
    end
  end

  -- 風に乗って流れる花びら
  for i = 1, 44 do
    self.gust[i] = {
      y = math.random(4, env.h - 3),
      lag = math.random() * 26,
      phase = math.random() * 6.28,
      color = env.colors[math.random(#env.colors)],
    }
  end
  return self
end

--- 粒を1つ描く。渦を巻きながら目的地へ向かう。push は風に押される強さ。
---@param canvas wisteria.Canvas
---@param m wisteria.Mote
---@param t number
---@param push number
local function draw_mote(canvas, m, t, push)
  local p = (t - m.start) / m.span
  if p <= 0 or p >= 1 then
    return
  end
  local e = ease_in_out(p)
  local swirl = (1 - e) * 7
  local arc = math.sin(p * math.pi)
  local x = m.ox + (m.tx - m.ox) * e + math.sin(p * 7 + m.phase) * swirl + arc * push
  local y = m.oy + (m.ty - m.oy) * e + math.cos(p * 5 + m.phase) * swirl * 0.5 - arc * push * 0.4
  canvas:set(math.floor(x + 0.5), math.floor(y + 0.5), blend(m.from, m.to, p))
end

--- その時刻の絵を canvas に描く。
---@param canvas wisteria.Canvas
---@param t number 経過秒
---@param clock number タイトル画面を開いてからの秒数(雲の位置を、演出のあとと揃えるため)
---@param dt number 前のコマからの秒数
function I:draw(canvas, t, clock, dt)
  local env = self.env

  -- 雲は最初から流れているが、暗闇では見えない。空が明けるにつれて浮かび上がる。
  if #env.clouds > 0 then
    sky_art.draw_clouds(canvas, env.clouds, clock, env.bg_at, math.floor(self:fade(t) ^ 2 * 8 + 0.5) / 8)
  end
  local front = gust_front(env, t)
  -- 風の間、房の先が風下へ流れる
  local blow = front and math.sin(progress(T.gust, t) * math.pi) * 2.2 or 0

  -- 星が1つずつ灯り、流れ星が1つ流れる
  if #env.stars > 0 then
    sky_art.draw_stars(canvas, env.stars, t, progress(T.stars, t))
    if t >= T.meteor then
      self.meteor = self.meteor == nil and sky_art.meteor(env.w, env.h) or self.meteor
      if self.meteor and not sky_art.draw_meteor(canvas, self.meteor, t - (self.meteor_t or t)) then
        self.meteor = false
      end
      self.meteor_t = t
    end
  end
  -- 朝日は昇り、夕日は沈んでくる。月は昇る。
  if env.body and t >= T.rise[1] then
    sky_art.draw_body(canvas, env.body, env.body.def.from * (1 - ease_in_out(progress(T.rise, t))), env.bg_at)
  end

  -- 房: 1本ずつ伸び、伸びている間は先が揺れる
  for i, r in ipairs(env.parts.racemes) do
    local p = clamp01((t - self.starts[i]) / GROW_TIME)
    if p > 0 then
      local shown = r.length * ease_out(p)
      local wobble = (1 - p) * 1.4
      for _, px in ipairs(r.px) do
        local ly = px[2] - 4
        if ly <= shown then
          local depth = ly / r.length
          local dx = math.sin(t * 11 + r.x) * wobble * depth + blow * depth
          canvas:set(px[1] + math.floor(dx + 0.5), px[2], px[3])
        end
      end
    end
  end

  -- つるが左から走り、少し遅れて葉が芽吹く
  local vine_x = ease_in_out(progress(T.vine, t)) * env.w
  for _, px in ipairs(env.parts.vine) do
    if px[1] <= vine_x then
      canvas:set(px[1], px[2], px[3])
    end
  end
  local leaf_x = ease_in_out(progress({ T.vine[1] + 0.25, T.vine[2] + 0.35 }, t)) * env.w
  for _, px in ipairs(env.parts.leaves) do
    if px[1] <= leaf_x then
      canvas:set(px[1], px[2], px[3])
    end
  end

  -- 最初の絵: 花びらが着いたドットから出来ていき、風が通ると消える
  for _, px in ipairs(self.prelude) do
    if t >= px.lit and t < px.gone then
      canvas:set(px.x, px.y, px.color)
    end
  end
  for _, m in ipairs(self.sparks) do
    draw_mote(canvas, m, t, 0)
  end
  -- 崩れた塵は、風に押されながらロゴとメニューへ降りる
  for _, m in ipairs(self.dust) do
    draw_mote(canvas, m, t, 9)
  end

  -- 猫: 藤から飛び降り、ロゴの上を歩いてきて座る
  if t >= T.drop[1] then
    local start_x = env.logo.left + 1
    if t < T.drop[2] then
      local p = progress(T.drop, t)
      cat.draw(canvas, "jump", start_x, math.floor(env.seat_y - (1 - p * p) * 16 + 0.5), env.period)
    elseif t < T.walk[2] then
      local p = progress(T.walk, t)
      local pose = math.floor((t - T.walk[1]) / 0.11) % 2 == 0 and "walk1" or "walk2"
      cat.draw(canvas, pose, math.floor(start_x + (env.seat_x - start_x) * p + 0.5), env.seat_y, env.period)
    else
      cat.draw(canvas, (t - T.walk[2]) % 1.2 > 1.05 and "sit_blink" or "sit", env.seat_x, env.seat_y, env.period)
    end
  end

  -- 蜂は、藤が咲いた頃に画面の外から飛んでくる。風が吹くと驚いて逃げる。
  if env.bees and t >= T.grow[1] + 1.0 then
    if front and not self.bees_scared then
      self.bees_scared = true
      env.bees:scare(0, 0, env.w, env.h)
    end
    env.bees:step(dt)
    env.bees:draw(canvas)
  end

  -- 風に乗る花びら
  if front then
    for _, g in ipairs(self.gust) do
      local x = front - g.lag
      if x >= 0 and x < env.w then
        canvas:set(math.floor(x + 0.5), math.floor(g.y + math.sin(t * 6 + g.phase) * 2.5 + 0.5), g.color)
      end
    end
  end
end

--- 空の明るさ(0 で暗闇、1 でその時刻の空)
function I:fade(t)
  return ease_in_out(progress(T.sky, t))
end

--- そのセルの文字を、まだ隠しておくか。
---@param row integer
---@param col integer
---@param t number
function I:hidden(row, col, t)
  local env = self.env
  local arrive = self.arrive[row * env.w + col]
  if arrive then
    return t < arrive
  end
  local logo = env.logo
  if row >= logo.top and row <= logo.bottom and col >= logo.left and col <= logo.right then
    -- ロゴの中の空白は隠す必要がない
    return false
  end
  -- メニューと一覧は、風が通り過ぎて塵が降りたところから現れる
  return t < front_time(env, col) + SETTLE_MENU + (self.row_lag[row] or 0)
end

return M
