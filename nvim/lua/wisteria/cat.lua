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
  -- 花びらを目で追う(顔ごと少し向ける)
  look_l = {
    ".W.....W...",
    ".WW...WW...",
    ".WPWWWPW...",
    ".WWWWWWW...",
    ".EWWWEWW...",
    ".WWPWWWW...",
    "..WWWWW....",
    ".WWWWWWW.S.",
    ".WWWWWWWWS.",
    ".WW.WW.WSS.",
  },
  look_r = {
    ".W.....W...",
    ".WW...WW...",
    ".WPWWWPW...",
    ".WWWWWWW...",
    ".WWEWWWE...",
    ".WWWWPWW...",
    "..WWWWW....",
    ".WWWWWWW.S.",
    ".WWWWWWWWS.",
    ".WW.WW.WSS.",
  },
  look_up = {
    ".W.....W...",
    ".WW...WW...",
    ".WPWWWPW...",
    ".WEWWWEW...",
    ".WWWPWWW...",
    ".WWWWWWW...",
    "..WWWWW....",
    ".WWWWWWW.S.",
    ".WWWWWWWWS.",
    ".WW.WW.WSS.",
  },
  -- 手を上げる → 払う
  paw_up = {
    ".W.....W...",
    ".WW...WW.W.",
    ".WPWWWPW.W.",
    ".WEWWWEWWW.",
    ".WWWPWWWW..",
    ".WWWWWWW...",
    "..WWWWW....",
    ".WWWWWWW.S.",
    ".WWWWWWWWS.",
    ".WW.WW.WSS.",
  },
  paw_swipe = {
    ".W.....W...",
    ".WW...WW...",
    ".WPWWWPW...",
    ".WWEWWWE...",
    ".WWWWPWWWWW",
    ".WWWWWWW...",
    "..WWWWW....",
    ".WWWWWWW.S.",
    ".WWWWWWWWS.",
    ".WW.WW.WSS.",
  },
  -- 頭に乗った花びらを振り落とす
  shake_l = {
    "W.....W....",
    "WW...WW....",
    "WPWWWPW....",
    "WWWWWWW....",
    "WSWWWSW....",
    "WWWPWWW....",
    "..WWWWW....",
    ".WWWWWWW.S.",
    ".WWWWWWWWS.",
    ".WW.WW.WSS.",
  },
  shake_r = {
    "..W.....W..",
    "..WW...WW..",
    "..WPWWWPW..",
    "..WWWWWWW..",
    "..WSWWWSW..",
    "..WWWPWWW..",
    "..WWWWW....",
    ".WWWWWWW.S.",
    ".WWWWWWWWS.",
    ".WW.WW.WSS.",
  },
  yawn = {
    ".W.....W...",
    ".WW...WW...",
    ".WPWWWPW...",
    ".WWWWWWW...",
    ".WSWWWSW...",
    ".WWWPWWW...",
    "..WWPWW....",
    ".WWWWWWW.S.",
    ".WWWWWWWWS.",
    ".WW.WW.WSS.",
  },
  -- 毛づくろい(前足で顔を洗う)
  groom1 = {
    ".W.....W...",
    ".WW...WW...",
    ".WPWWWPW...",
    ".WWWWWWW...",
    "WWSWWWSW...",
    "WWWWPWWW...",
    "W.WWWWW....",
    "WWWWWWWW.S.",
    ".WWWWWWWWS.",
    ".WW.WW.WSS.",
  },
  groom2 = {
    ".W.....W...",
    ".WW...WW...",
    ".WPWWWPW...",
    ".WWWWWWW...",
    ".WSWWWSW...",
    "WWWWPWWW...",
    "WWWWWWW....",
    "WWWWWWWW.S.",
    ".WWWWWWWWS.",
    ".WW.WW.WSS.",
  },
  -- 耳がぴくっと動く
  ear = {
    ".W......W..",
    ".WW...WWW..",
    ".WPWWWPW...",
    ".WWWWWWW...",
    ".WEWWWEW...",
    ".WWWPWWW...",
    "..WWWWW....",
    ".WWWWWWW.S.",
    ".WWWWWWWWS.",
    ".WW.WW.WSS.",
  },
  sleep_ear = {
    "...........",
    "...........",
    "...........",
    "...........",
    "...........",
    ".W....W....",
    ".WW.WWW.SS.",
    ".WWWWWWWWS.",
    "WEEWEEWWWWS",
    "WWWPWWWWWSS",
  },
  -- 横向き(右向き)に歩く
  walk1 = {
    "...........",
    "...........",
    "...........",
    ".......W.W.",
    "S......WWWW",
    "S......WWEW",
    ".SWWWWWWWWP",
    "..WWWWWWW..",
    "..WW...WW..",
    ".WW.....WW.",
  },
  walk2 = {
    "...........",
    "...........",
    "...........",
    ".......W.W.",
    ".S.....WWWW",
    ".S.....WWEW",
    ".SWWWWWWWWP",
    "..WWWWWWW..",
    "...WW.WW...",
    "...W...W...",
  },
  -- 飛び降りる途中
  jump = {
    "...........",
    "...........",
    "S......W.W.",
    ".S.....WWWW",
    "..S....WWEW",
    "..WWWWWWWWP",
    "..WWWWWWWW.",
    ".WW.....WW.",
    "WW.......WW",
    "...........",
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
---@param max_y? integer これより下のドットは描かない(ものの後ろから出てくるとき用)
function M.draw(canvas, pose, x, y, period, max_y)
  for row, line in ipairs(M.poses[pose]) do
    for col = 1, #line do
      local c = PALETTE[line:sub(col, col)]
      if c and (not max_y or y + row - 1 <= max_y) then
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

-- ひと続きの動き。{ポーズ, 秒} の並び。
local ACTIONS = {
  blink = { { "sit_blink", 0.2 } },
  tail = { { "sit_tail", 0.45 } },
  ear = { { "ear", 0.14 }, { "sit", 0.1 }, { "ear", 0.14 } },
  yawn = { { "sit_blink", 0.25 }, { "yawn", 1.0 }, { "sit_blink", 0.3 } },
  groom = {
    { "groom1", 0.28 },
    { "groom2", 0.28 },
    { "groom1", 0.28 },
    { "groom2", 0.28 },
    { "groom1", 0.28 },
    { "groom2", 0.28 },
  },
  stretch = { { "stretch", 2.4 } },
  bat = { { "paw_up", 0.22 }, { "paw_swipe", 0.16 }, { "paw_up", 0.12 } },
  shake = { { "shake_l", 0.09 }, { "shake_r", 0.09 }, { "shake_l", 0.09 }, { "shake_r", 0.09 } },
  sleep_ear = { { "sleep_ear", 0.2 } },
}

---@class wisteria.CatState
---@field t number 経過秒
---@field action? { name: string, step: integer, left: number } 実行中の動き
---@field next table<string, number> 動きごとの、次にやってよい時刻
---@field on_head number 頭に花びらが乗っている秒数
---@field look? string いま向いている方向のポーズ

---@return wisteria.CatState
function M.new_state()
  return {
    t = 0,
    on_head = 0,
    next = { blink = 2, tail = 4, ear = 7, yawn = 18, groom = 26, stretch = 6, bat = 1, look = 0, sleep_ear = 9 },
  }
end

local function begin(state, name, cooldown)
  state.action = { name = name, step = 1, left = ACTIONS[name][1][2] }
  state.next[name] = state.t + cooldown
  return name
end

---@class wisteria.CatContext
---@field petals wisteria.Petal[]
---@field x integer 猫の左端(ドット)
---@field y integer 猫の上端(ドット)

--- 時刻・経過時間・花びらの位置から、いまのポーズを決める。
---@param state wisteria.CatState
---@param period wisteria.Period
---@param dt number
---@param ctx? wisteria.CatContext
---@return string pose
---@return string? event いま始めた動きの名前(吹き出しや花びらへの作用に使う)
function M.pose(state, period, dt, ctx)
  state.t = state.t + dt
  local t, next = state.t, state.next

  -- 実行中の動きを進める
  local action = state.action
  if action then
    action.left = action.left - dt
    while action.left <= 0 do
      action.step = action.step + 1
      local step = ACTIONS[action.name][action.step]
      if not step then
        state.action, action = nil, nil
        break
      end
      action.left = action.left + step[2]
    end
    if action then
      local pose = ACTIONS[action.name][action.step][1]
      -- 手を払った瞬間だけ知らせる
      return pose,
        (pose == "paw_swipe" and not action.hit) and (function()
          action.hit = true
          return "swipe"
        end)() or nil
    end
  end

  if period.name == "midnight" then
    if t > next.sleep_ear then
      begin(state, "sleep_ear", 6 + math.random() * 10)
      return "sleep_ear"
    end
    return (t % 4 < 2) and "sleep" or "sleep_breath"
  end

  -- 花びらへの反応
  local look
  if ctx then
    local head, nearest, best = false, nil, 400
    for _, p in ipairs(ctx.petals) do
      local dx, dy = p.x - (ctx.x + 4), p.y - (ctx.y + 4)
      if p.rest then
        if dx >= -4 and dx <= 4 and dy >= -6 and dy <= 0 then
          head = true
        end
      else
        -- 右手の届くところに来たら払う
        if dx >= 3 and dx <= 9 and dy >= -6 and dy <= 2 and t > next.bat then
          return ACTIONS.bat[1][1], begin(state, "bat", 4 + math.random() * 5)
        end
        local d = dx * dx + dy * dy
        if d < best then
          best, nearest = d, { dx, dy }
        end
      end
    end
    -- 頭に乗ったままだと、しばらくして振り落とす
    state.on_head = head and state.on_head + dt or 0
    if state.on_head > 1.6 then
      state.on_head = 0
      return ACTIONS.shake[1][1], begin(state, "shake", 0)
    end
    -- 目移りしすぎないよう、向きはしばらく保つ
    if nearest and t > next.look then
      state.look = nearest[2] < -5 and math.abs(nearest[1]) < 5 and "look_up"
        or (nearest[1] < 0 and "look_l" or "look_r")
      next.look = t + 0.6
    elseif not nearest and t > next.look then
      state.look = nil
    end
    look = state.look
  end

  -- 気まぐれな動き
  if period.name == "morning" and t > next.stretch then
    begin(state, "stretch", 11 + math.random() * 8)
    return "stretch", "stretch"
  end
  if t > next.yawn then
    begin(state, "yawn", 22 + math.random() * 20)
    return "sit_blink", "yawn"
  end
  if t > next.groom then
    begin(state, "groom", 28 + math.random() * 25)
    return "groom1", "groom"
  end
  if t > next.blink then
    begin(state, "blink", 2.5 + math.random() * 4)
    return "sit_blink"
  end
  if t > next.tail then
    begin(state, "tail", 3 + math.random() * 5)
    return "sit_tail"
  end
  if t > next.ear then
    begin(state, "ear", 5 + math.random() * 8)
    return "ear"
  end
  return look or "sit"
end

return M
