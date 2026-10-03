local color = require("wisteria.color")

local M = {}

local PALETTE = {
  W = "#f6f0fc", -- 体
  S = "#cfc3e2", -- 影・閉じた目
  P = "#ff9fbf", -- 耳の内側・鼻
  E = "#3a2a4a", -- 目
}

-- 1文字=1ドット。"." は透明。どのポーズも同じ大きさで、足元が下端。
M.poses = {
  sit = {
    ".W.....W...",
    ".WW...WW...",
    ".WPWWWPW...",
    ".WWWWWWW...",
    ".WEWWWEW...",
    ".WWWPWWW...",
    "..WWWWW....",
    ".WWWWWWW.S.",
    ".WWWWWWWWS.",
    ".WW.WW.WSS.",
  },
  sit_blink = {
    ".W.....W...",
    ".WW...WW...",
    ".WPWWWPW...",
    ".WWWWWWW...",
    ".WSWWWSW...",
    ".WWWPWWW...",
    "..WWWWW....",
    ".WWWWWWW.S.",
    ".WWWWWWWWS.",
    ".WW.WW.WSS.",
  },
  sit_tail = {
    ".W.....W...",
    ".WW...WW...",
    ".WPWWWPW...",
    ".WWWWWWW...",
    ".WEWWWEW...",
    ".WWWPWWW...",
    "..WWWWW..S.",
    ".WWWWWWW.S.",
    ".WWWWWWWWS.",
    ".WW.WW.WS..",
  },
  stretch = {
    "...........",
    "...........",
    "...........",
    ".........S.",
    "........SS.",
    "W.W....WWW.",
    "WWWW..WWWW.",
    "WSWWWWWWWW.",
    "WWWWWWWWW..",
    ".WW....WW..",
  },
  sleep = {
    "...........",
    "...........",
    "...........",
    "...........",
    "...........",
    ".W...W.....",
    ".WW.WW.SS..",
    ".WWWWWWWWS.",
    "WEEWEEWWWWS",
    "WWWPWWWWWSS",
  },
  sleep_breath = {
    "...........",
    "...........",
    "...........",
    "...........",
    "...........",
    ".W...W.SS..",
    ".WW.WWWWWS.",
    ".WWWWWWWWS.",
    "WEEWEEWWWWS",
    "WWWPWWWWWSS",
  },
}

M.width = 11
M.height = 10

---@param canvas wisteria.Canvas
---@param pose string
---@param x integer 左端(ドット)
---@param y integer 上端(ドット)
---@param period? wisteria.Period
function M.draw(canvas, pose, x, y, period)
  for row, line in ipairs(M.poses[pose]) do
    for col = 1, #line do
      local c = PALETTE[line:sub(col, col)]
      if c then
        if period and period.tint then
          c = color.mix(c, period.tint, period.amount * 0.6)
        end
        canvas:set(x + col - 1, y + row - 1, c)
      end
    end
  end
end

--- そのドットに猫の体があるか(花びらの当たり判定用)
function M.solid(pose, dx, dy)
  local line = M.poses[pose][dy + 1]
  return line ~= nil and dx >= 0 and dx < #line and line:sub(dx + 1, dx + 1) ~= "."
end

---@class wisteria.CatState
---@field t number 経過秒
---@field next_blink number
---@field next_tail number
---@field next_stretch number

---@return wisteria.CatState
function M.new_state()
  return { t = 0, next_blink = 2, next_tail = 4, next_stretch = 6 }
end

--- 時刻と経過時間から、いまのポーズを決める。
---@param state wisteria.CatState
---@param period wisteria.Period
---@param dt number
---@return string
function M.pose(state, period, dt)
  state.t = state.t + dt
  local t = state.t
  if period.name == "midnight" then
    return (t % 4 < 2) and "sleep" or "sleep_breath"
  end
  if period.name == "morning" then
    if t > state.next_stretch + 2.5 then
      state.next_stretch = t + 9 + math.random() * 8
    elseif t > state.next_stretch then
      return "stretch"
    end
  end
  if t > state.next_blink + 0.25 then
    state.next_blink = t + 2.5 + math.random() * 4
  elseif t > state.next_blink then
    return "sit_blink"
  end
  if t > state.next_tail + 0.5 then
    state.next_tail = t + 3 + math.random() * 5
  elseif t > state.next_tail then
    return "sit_tail"
  end
  return "sit"
end

return M
