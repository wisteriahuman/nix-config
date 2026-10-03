-- 花びらの動き。時刻ごとに落ち方が違い、文字や猫の上に乗る。
local M = {}

---@class wisteria.Motion
---@field count integer 同時に降っている枚数の目安
---@field fall number 落ちる速さ(ドット/秒)
---@field sway number 左右の揺れ幅(ドット)
---@field wind number 横風(ドット/秒)
---@field gust? number 突風のときの横風

---@type table<string, wisteria.Motion>
M.motions = {
  morning = { count = 6, fall = 7, sway = 0, wind = 0 },
  day = { count = 11, fall = 5, sway = 1.6, wind = 0 },
  evening = { count = 16, fall = 6, sway = 0.5, wind = 5, gust = 30 },
  night = { count = 8, fall = 2.2, sway = 2.2, wind = 0.6 },
  midnight = { count = 2, fall = 2, sway = 0.8, wind = 0 },
}

local MAX_RESTING = 14

---@class wisteria.Petal
---@field x number
---@field y number
---@field phase number
---@field color string
---@field lands boolean ものの上に乗るか(乗らない花びらは後ろを通り抜ける)
---@field rest? number 乗っている残り秒数
---@field kx? number 猫に払われた勢い(ドット/秒)
---@field ky? number

---@class wisteria.Petals
---@field list wisteria.Petal[]
---@field t number
---@field gust_at number 次の突風の時刻
---@field gust_until number
local P = {}
P.__index = P

function M.new()
  return setmetatable({ list = {}, t = 0, gust_at = 5, gust_until = 0 }, P)
end

--- いま突風が吹いているか(藤を揺らすのに使う)
function P:gusting()
  return self.t < self.gust_until
end

---@param dt number 経過秒
---@param motion wisteria.Motion
---@param env { w: integer, h: integer, top: integer, colors: string[], solid: fun(x: integer, y: integer): boolean }
function P:step(dt, motion, env)
  self.t = self.t + dt

  local wind = motion.wind
  if motion.gust then
    if self.t > self.gust_at then
      self.gust_until = self.t + 1.6
      self.gust_at = self.t + 7 + math.random() * 6
      -- 突風で、乗っていた花びらも飛ばされる
      for _, p in ipairs(self.list) do
        p.rest = nil
        p.lands = false
      end
    end
    if self:gusting() then
      wind = motion.gust
    end
  end

  local falling, resting = 0, 0
  for _, p in ipairs(self.list) do
    if p.rest then
      resting = resting + 1
    else
      falling = falling + 1
    end
  end
  if falling < motion.count and math.random() < dt * motion.count / 3 then
    self.list[#self.list + 1] = {
      x = math.random(0, env.w - 1),
      y = env.top,
      phase = math.random() * 6.28,
      color = env.colors[math.random(#env.colors)],
      lands = math.random() < 0.7,
    }
  end

  local keep = {}
  for _, p in ipairs(self.list) do
    local alive = true
    if p.rest then
      p.rest = p.rest - dt
      alive = p.rest > 0
    else
      local nx = p.x + (wind + math.cos(self.t * 1.7 + p.phase) * motion.sway + (p.kx or 0)) * dt
      local ny = p.y + (motion.fall + (p.ky or 0)) * dt
      if p.kx then
        -- 払われた勢いは、すぐに弱まる
        local keep_rate = math.max(0, 1 - 2.5 * dt)
        p.kx, p.ky = p.kx * keep_rate, p.ky * keep_rate
      end
      local cx, cy, fx, fy = math.floor(p.x + 0.5), math.floor(p.y + 0.5), math.floor(nx + 0.5), math.floor(ny + 0.5)
      if fy >= env.h - 1 then
        -- 地面に落ちたら、しばらく残って消える
        p.y, p.rest = env.h - 1, 3 + math.random() * 3
      elseif p.lands and fy > cy and env.solid(fx, fy) and not env.solid(cx, cy) then
        if resting < MAX_RESTING then
          p.rest = 4 + math.random() * 5
          resting = resting + 1
        else
          p.lands = false
        end
      else
        p.x, p.y = nx, ny
      end
      alive = nx > -3 and nx < env.w + 3
    end
    if alive then
      keep[#keep + 1] = p
    end
  end
  self.list = keep
end

--- 範囲内の花びらを弾き飛ばす(猫が払う・振り落とす)。
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param kx number
---@param ky number
---@return integer 弾いた枚数
function P:kick(x1, y1, x2, y2, kx, ky)
  local n = 0
  for _, p in ipairs(self.list) do
    if p.x >= x1 and p.x <= x2 and p.y >= y1 and p.y <= y2 then
      p.rest, p.lands = nil, false
      p.kx, p.ky = kx * (0.6 + math.random() * 0.8), ky * (0.6 + math.random() * 0.8)
      n = n + 1
    end
  end
  return n
end

---@param canvas wisteria.Canvas
function P:draw(canvas)
  for _, p in ipairs(self.list) do
    canvas:set(math.floor(p.x + 0.5), math.floor(p.y + 0.5), p.color)
  end
end

return M
