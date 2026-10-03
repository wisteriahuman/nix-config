local color = require("wisteria.color")
local rng = require("wisteria.rng")

local M = {}

local FLOWER = { "#6f55c0", "#9478e6", "#b79cff", "#d9c4ff", "#f3e9ff" }
local LEAF = { "#3f8a66", "#62b98a", "#8fd9a8" }
local VINE = "#7a5a4c"

---@class wisteria.Period
---@field name string
---@field shade? string 背景を寄せる色
---@field shade_amount number
---@field tint? string 花や葉に重ねる色
---@field amount number tint の強さ(0..1)
---@field sky? { [1]: string, [2]: string, [3]: number } 空のグラデーション(上端の色, 下端の色, 強さ)
---@field bg? string 実際の背景色(resolve で決まる)
---@field sky_bg? fun(t: number): string 画面の上端(0)から下端(1)までの背景色

---@type table<string, wisteria.Period>
M.periods = {
  morning = {
    name = "morning",
    shade = "#7a6088",
    shade_amount = 0.10,
    tint = "#ffd9c9",
    amount = 0.18,
    sky = { "#1d1a3a", "#6b3f58", 0.8 },
  },
  day = { name = "day", shade_amount = 0, amount = 0 },
  evening = {
    name = "evening",
    shade = "#7a2a1e",
    shade_amount = 0.13,
    tint = "#ff9a6e",
    amount = 0.28,
    sky = { "#2a1836", "#7a3520", 0.85 },
  },
  night = {
    name = "night",
    shade = "#0a0a22",
    shade_amount = 0.35,
    tint = "#5a6fd0",
    amount = 0.30,
    sky = { "#0f0d22", "#1d1c44", 0.8 },
  },
  midnight = { name = "midnight", shade = "#040410", shade_amount = 0.55, tint = "#2a2350", amount = 0.50 },
}

--- テーマの背景色から、その時刻の背景色を決める。
---@param period wisteria.Period
---@param normal_bg string
---@return wisteria.Period
function M.resolve(period, normal_bg)
  local out = vim.deepcopy(period)
  out.bg = period.shade and color.mix(normal_bg, period.shade, period.shade_amount) or normal_bg
  local sky, flat = period.sky, out.bg
  out.sky_bg = function(t)
    if not sky then
      return flat
    end
    -- 下端に近づくほど急に色づく(地平線の近くだけ焼ける)
    return color.mix(normal_bg, color.mix(sky[1], sky[2], t ^ 1.6), sky[3])
  end
  return out
end

---@param hour integer 0..23
---@return wisteria.Period
function M.period(hour)
  if hour < 5 then
    return M.periods.midnight
  elseif hour < 10 then
    return M.periods.morning
  elseif hour < 16 then
    return M.periods.day
  elseif hour < 19 then
    return M.periods.evening
  end
  return M.periods.night
end

local function tinted(list, period)
  if not period.tint then
    return list
  end
  local out = {}
  for i, c in ipairs(list) do
    out[i] = color.mix(c, period.tint, period.amount)
  end
  return out
end

--- 房の太さ(半幅)。付け根で急に太り、先へ向かって細くなる。
local function half_width(t, w)
  if t < 0.18 then
    return 0.8 + (w - 0.8) * (t / 0.18)
  end
  return w * (1 - (t - 0.18) / 0.82) ^ 0.8
end

local function raceme(canvas, r, x0, length, flower, fill)
  local w = 2.0 + r:next() * 1.5
  local phase = r:next() * 6.28
  for y = 0, length - 1 do
    local t = y / length
    local hw = half_width(t, w)
    local cx = x0 + math.floor(math.sin(t * 2.2 + phase) * 0.7 + 0.5)
    for dx = -math.ceil(hw), math.ceil(hw) do
      if math.abs(dx) <= hw + (r:next() - 0.5) * 0.6 and r:next() < fill then
        -- 付け根は開いた花で明るく、先はつぼみで濃い。左から光が当たる。
        local shade = 4 - math.floor(t * 3.2) + (dx < 0 and 1 or 0) + r:int(-1, 0)
        canvas:set(cx + dx, 4 + y, flower[math.max(1, math.min(#flower, shade))])
      end
    end
  end
end

---@class wisteria.Layout
---@field left integer 文字のある範囲の左端(セル)
---@field right integer 右端(セル)
---@field top integer 上端(セル)

---@param canvas wisteria.Canvas
---@param layout wisteria.Layout
---@param period wisteria.Period
---@param seed integer
function M.wisteria(canvas, layout, period, seed)
  local r = rng.new(seed)
  local flower, leaf = tinted(FLOWER, period), tinted(LEAF, period)
  local vine = period.tint and color.mix(VINE, period.tint, period.amount) or VINE

  -- 房(葉とつるより先に描いて、付け根を葉で隠す)。
  -- 奥の層を暗く密に、手前の層を明るくまばらに重ねて奥行きを出す。
  local center = (layout.left + layout.right) / 2
  local half = math.max(1, (layout.right - layout.left) / 2)
  local back = {}
  for i, c in ipairs(flower) do
    back[i] = color.mix(c, period.bg, 0.5)
  end
  for _, layer in ipairs({
    { palette = back, gap = { 4, 6 }, scale = 0.8, fill = 0.97 },
    { palette = flower, gap = { 6, 10 }, scale = 1, fill = 0.9 },
  }) do
    local x = r:int(1, 4)
    while x < canvas.w - 1 do
      local limit
      if x >= layout.left - 3 and x <= layout.right + 3 then
        -- 文字の上では、ロゴの手前で止める。中央ほど短くしてアーチにする。
        local arch = 0.62 + 0.38 * math.min(1, math.abs(x - center) / half)
        limit = (layout.top * 2 - 6) * arch
      else
        limit = canvas.h * 0.7
      end
      local length = math.floor(limit * layer.scale * (0.55 + r:next() * 0.45))
      if length >= 5 then
        raceme(canvas, r, x, length, layer.palette, layer.fill)
      end
      x = x + r:int(layer.gap[1], layer.gap[2])
    end
  end

  -- つる
  for vx = 0, canvas.w - 1 do
    canvas:set(vx, 2 + math.floor(math.sin(vx / 9) * 1.2 + 0.5), vine)
  end

  -- 葉
  for lx = 0, canvas.w - 1 do
    local n = r:int(1, 4)
    for ly = 0, n do
      if r:next() < 0.8 then
        canvas:set(lx, ly, leaf[r:int(1, #leaf)])
      end
    end
  end
end

return M
