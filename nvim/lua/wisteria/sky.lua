-- 空に浮かぶもの。朝と夕方は太陽、夜と深夜は月と星。藤の後ろに描く。
local color = require("wisteria.color")
local rng = require("wisteria.rng")

local M = {}

---@class wisteria.BodyDef
---@field kind "sun"|"moon"
---@field radius number
---@field sink number 中心が地平線(画面の下端)からどれだけ下にあるか。負なら浮いている。
---@field core string[] 中心から縁への色
---@field glow string 周りの光の色
---@field halo { [1]: number, [2]: number }[] 光の輪 {縁からの距離, 濃さ}
---@field stripes? integer[] 太陽を横切る雲の筋(中心からの高さ)
---@field bite? { [1]: number, [2]: number, [3]: number } 月の欠け {横ずれ, 縦ずれ, 半径}
---@field from number オープニングでの出発位置(最終位置からの縦のずれ。正なら下から昇る)

---@type table<string, wisteria.BodyDef>
local BODIES = {
  morning = {
    kind = "sun",
    radius = 11,
    sink = 0,
    core = { "#fff6cf", "#ffeaa6", "#ffd98c", "#ffc878" },
    glow = "#ffb08a",
    halo = { { 2, 0.5 }, { 5, 0.26 }, { 9, 0.12 } },
    from = 16,
  },
  evening = {
    kind = "sun",
    radius = 14,
    sink = 0,
    core = { "#ffe08a", "#ffc061", "#ff9a4d", "#ff7442" },
    glow = "#ff5a3c",
    halo = { { 2, 0.5 }, { 5, 0.28 }, { 10, 0.13 } },
    from = -24,
  },
  night = {
    kind = "moon",
    radius = 8,
    sink = -15,
    core = { "#fffbe6", "#f6efcf" },
    glow = "#b9b6f0",
    halo = { { 2, 0.3 }, { 5, 0.13 } },
    bite = { 4, -2, 7.4 },
    from = 18,
  },
  midnight = {
    kind = "moon",
    radius = 8,
    sink = -15,
    core = { "#f3eed8", "#e2dbbd" },
    glow = "#8f8cc8",
    halo = { { 2, 0.24 }, { 4, 0.1 } },
    bite = { 3, -1.5, 7.6 },
    from = 18,
  },
}

local STAR_COUNT = { night = 46, midnight = 70 }
local STAR_LEVELS = { "#6f6890", "#b9b0c8", "#fff6d8" }

---@class wisteria.Body
---@field def wisteria.BodyDef
---@field cx integer
---@field cy integer

--- その時刻の太陽か月。無い時刻(昼)は nil。画面の右下(一覧の下の空いている所)に置く。
---@param w integer ドット単位の幅
---@param h integer ドット単位の高さ
---@param period wisteria.Period
---@return wisteria.Body?
function M.body(w, h, period)
  local def = BODIES[period.name]
  if not def then
    return nil
  end
  return { def = def, cx = math.floor(w * 0.76), cy = h - 1 + def.sink }
end

--- 太陽か月を描く。丸みは色の帯で、光は背景に溶ける輪で出す。
---@param canvas wisteria.Canvas
---@param body wisteria.Body
---@param offset number 縦のずれ(オープニングで昇る・沈むのに使う)
---@param bg_at fun(y: integer): string そのドット行の背景色
function M.draw_body(canvas, body, offset, bg_at)
  local def = body.def
  local cx, cy = body.cx, body.cy + math.floor(offset + 0.5)
  local reach = math.ceil(def.radius + def.halo[#def.halo][1])
  for dy = -reach, reach do
    local y = cy + dy
    if y >= 6 and y < canvas.h then
      local bg = bg_at(y)
      for dx = -reach, reach do
        -- 少し足すと、円の上下左右に1ドットだけ飛び出すのを防げる
        local d = math.sqrt(dx * dx + dy * dy) + 0.4
        local c
        if d <= def.radius then
          c = def.core[math.min(#def.core, math.floor(d / def.radius * #def.core) + 1)]
          if def.bite then
            -- ずらした円の内側は影。真っ暗にせず、うっすら見せると月らしくなる。
            local bx, by = dx - def.bite[1], dy - def.bite[2]
            if math.sqrt(bx * bx + by * by) <= def.bite[3] then
              c = color.mix(bg, def.core[#def.core], 0.14)
            end
          end
          if def.stripes then
            for _, s in ipairs(def.stripes) do
              if -dy == s then
                c = color.mix(bg, def.glow, 0.35)
              end
            end
          end
        else
          for _, ring in ipairs(def.halo) do
            if d <= def.radius + ring[1] then
              c = color.mix(bg, def.glow, ring[2])
              break
            end
          end
        end
        if c then
          canvas:set(cx + dx, y, c)
        end
      end
    end
  end
end

---@class wisteria.Star
---@field x integer
---@field y integer
---@field phase number
---@field speed number
---@field born number オープニングで灯る順(0..1)

---@return wisteria.Star[]
function M.stars(w, h, period, seed)
  local stars, r = {}, rng.new(seed + 29)
  for i = 1, STAR_COUNT[period.name] or 0 do
    stars[i] = {
      x = r:int(0, w - 1),
      y = r:int(6, h - 2),
      phase = r:next() * 6.28,
      speed = 0.6 + r:next() * 1.8,
      born = r:next(),
    }
  end
  return stars
end

--- 星を描く。それぞれの速さで明滅する。
---@param canvas wisteria.Canvas
---@param stars wisteria.Star[]
---@param t number
---@param shown? number 0..1。オープニングで、ここまでの順番の星だけ灯す。
function M.draw_stars(canvas, stars, t, shown)
  for _, s in ipairs(stars) do
    if not shown or s.born <= shown then
      local level = math.floor((math.sin(t * s.speed + s.phase) + 1) / 2 * 3.99)
      -- 灯った瞬間は一番明るく光る
      if shown and shown - s.born < 0.06 then
        level = 3
      end
      if level > 0 then
        canvas:set(s.x, s.y, STAR_LEVELS[level])
      end
    end
  end
end

---@class wisteria.Meteor
---@field x number
---@field y number
---@field vx number
---@field vy number
---@field life number 残り秒数

--- 流れ星を1つ作る。左上から右下へ流れる。
---@param w integer
---@param h integer
---@return wisteria.Meteor
function M.meteor(w, h)
  return {
    x = math.random(4, math.floor(w * 0.55)),
    y = math.random(8, math.floor(h * 0.3)),
    vx = 62,
    vy = 20,
    life = 0.9,
  }
end

--- 流れ星を進めて描く。消えたら false を返す。
---@param canvas wisteria.Canvas
---@param m wisteria.Meteor
---@param dt number
---@return boolean alive
function M.draw_meteor(canvas, m, dt)
  m.x, m.y, m.life = m.x + m.vx * dt, m.y + m.vy * dt, m.life - dt
  if m.life <= 0 or m.x >= canvas.w then
    return false
  end
  -- 頭が明るく、尾は後ろへ暗くなる
  for i = 0, 7 do
    local level = i == 0 and 3 or (i < 4 and 2 or 1)
    canvas:set(math.floor(m.x - i * 1.6 + 0.5), math.floor(m.y - i * 0.52 + 0.5), STAR_LEVELS[level])
  end
  return true
end

return M
