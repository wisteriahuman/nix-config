-- 昼の藤に寄ってくるクマバチ。房の先を飛び回り、ときどき止まる。猫に払われると逃げる。
local M = {}

local COLORS = {
  k = "#7a5a48", -- 体(真っ黒だと暗い背景に沈むので、こげ茶にしている)
  y = "#ffcf5a", -- 胸の黄色
  w = "#f4eefc", -- 羽
}

-- 1文字=1ドット。羽ばたきの2コマと、止まっているとき。
local FRAMES = {
  up = { ".ww.", "kyyk", ".kk." },
  down = { "....", "kyyk", "wkkw" },
  rest = { "....", "kyyk", ".kk." },
}

local SPEED = 15 -- 飛ぶ速さ(ドット/秒)

---@class wisteria.Bee
---@field x number
---@field y number
---@field tx number 向かっている先
---@field ty number
---@field wait number 着いた先でとどまる残り秒数
---@field perched boolean 止まっているか(羽を閉じる)
---@field scared number 逃げている残り秒数
---@field phase number
---@field t number

---@class wisteria.Bees
---@field list wisteria.Bee[]
---@field spots { [1]: integer, [2]: integer }[] 房の先(とまり場所)
---@field w integer
---@field h integer
local B = {}
B.__index = B

---@param count integer
---@param parts wisteria.Parts
---@param w integer
---@param h integer
function M.new(count, parts, w, h)
  local self = setmetatable({ list = {}, spots = {}, w = w, h = h }, B)
  for _, r in ipairs(parts.racemes) do
    if r.front and r.length >= 8 then
      self.spots[#self.spots + 1] = { r.x, 4 + r.length }
    end
  end
  for i = 1, (#self.spots > 0 and count or 0) do
    -- 画面の左右の外から、藤の下あたりの高さで飛んでくる
    local bee = {
      x = (i % 2 == 1) and -6 or (w + 6),
      y = math.random(12, math.max(13, math.floor(h * 0.4))),
      wait = 0,
      perched = false,
      scared = 0,
      phase = i * 2.1,
      t = 0,
    }
    self:retarget(bee)
    self.list[i] = bee
  end
  return self
end

--- 次に向かう房を決める
function B:retarget(bee)
  local spot = self.spots[math.random(#self.spots)]
  -- 最初の1回は、入ってきた側とは反対の半分にある房を目指す(画面を横切って見せる)
  if not bee.tx then
    for _ = 1, 8 do
      if (bee.x < 0) == (spot[1] > self.w * 0.4) then
        break
      end
      spot = self.spots[math.random(#self.spots)]
    end
  end
  bee.tx, bee.ty = spot[1] + math.random(-3, 3), spot[2] + math.random(-1, 4)
  bee.perched = false
end

---@param dt number
function B:step(dt)
  for _, bee in ipairs(self.list) do
    bee.t = bee.t + dt
    bee.scared = math.max(0, bee.scared - dt)
    local dx, dy = bee.tx - bee.x, bee.ty - bee.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > 1.2 then
      -- ふらふらしながら目的地へ。逃げているときは速い。
      local speed = (bee.scared > 0 and 3 or 1) * SPEED
      bee.x = bee.x + dx / dist * speed * dt + math.sin(bee.t * 9 + bee.phase) * 5 * dt
      bee.y = bee.y + dy / dist * speed * dt + math.cos(bee.t * 7 + bee.phase) * 4 * dt
      bee.wait = 1 + math.random() * 3
    else
      -- 着いたら、しばらくとどまる。半分は房に止まって羽を休める。
      if bee.wait > 0 and not bee.perched and math.random() < dt * 0.5 then
        bee.perched = true
      end
      bee.wait = bee.wait - dt
      if bee.wait <= 0 then
        self:retarget(bee)
      end
    end
  end
end

--- 範囲内の蜂を驚かせて逃がす(猫が払ったとき)。
---@return integer 逃げた数
function B:scare(x1, y1, x2, y2)
  local n = 0
  for _, bee in ipairs(self.list) do
    if bee.x >= x1 and bee.x <= x2 and bee.y >= y1 and bee.y <= y2 then
      self:retarget(bee)
      -- いったん上へ逃げる
      bee.ty = math.max(5, bee.ty - 8)
      bee.scared = 1.2
      n = n + 1
    end
  end
  return n
end

---@param canvas wisteria.Canvas
function B:draw(canvas)
  for _, bee in ipairs(self.list) do
    local frame = bee.perched and FRAMES.rest or (math.floor(bee.t / 0.1) % 2 == 0 and FRAMES.up or FRAMES.down)
    local x0, y0 = math.floor(bee.x + 0.5) - 1, math.floor(bee.y + 0.5) - 1
    for row, line in ipairs(frame) do
      for col = 1, #line do
        local c = COLORS[line:sub(col, col)]
        if c then
          canvas:set(x0 + col - 1, y0 + row - 1, c)
        end
      end
    end
  end
end

return M
