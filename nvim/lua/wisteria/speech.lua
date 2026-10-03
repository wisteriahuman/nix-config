-- 猫の吹き出し。あいさつ・日付・今日のメモ・Git の状況を順に言う。
local M = {}

local GREETINGS = {
  morning = {
    "おはよ。今日は早いじゃん",
    "ふあ…もう朝か",
    "朝から開くなんて、やる気あるね",
  },
  day = {
    "来たね。ぼくはここで見てるよ",
    "今日は何つくるの？",
    "昼だよ。ごはん食べた？",
  },
  evening = {
    "そろそろ休んだら？ ぼくは休むけど",
    "夕方だね。あと少しだけ？",
    "風、強くなってきたよ",
  },
  night = { "まだやるの？ 物好きだね", "夜は静かでいいよね", "目、疲れてない？" },
  midnight = { "…ねむ。先に寝るよ", "…zzz", "…起きてるの、きみだけだよ" },
}

local IDLE = {
  "花びら、頭に乗ってる？ 取らなくていいよ",
  "ここ、ぼくの席だから",
  "f を押すと速いよ。知ってると思うけど",
  "藤って、見てるだけでいいよね",
  "なでてもいいよ。画面越しだけど",
  "その設定、また変えるの？",
}

local WEEKDAYS = { "日", "月", "火", "水", "木", "金", "土" }

local function memo_line()
  local ok, memo = pcall(require, "config.memo")
  if not ok then
    return nil
  end
  local path = memo.dir .. "/" .. os.date("%Y-%m-%d") .. ".md"
  if vim.fn.filereadable(path) == 0 then
    return "今日のメモ、まだ書いてないよね？"
  end
  local n = 0
  for _, line in ipairs(vim.fn.readfile(path)) do
    if line:match("^## %d%d:%d%d") then
      n = n + 1
    end
  end
  return n > 0 and ("今日のメモ、%d個あるね。えらいじゃん"):format(n)
    or "メモ、開いただけで何も書いてないよ"
end

---@class wisteria.Speech
---@field lines string[]
---@field index integer
---@field t number
---@field override? string
---@field override_left? number
local S = {}
S.__index = S

---@param period_name string
function M.new(period_name)
  local self = setmetatable({ lines = {}, index = 1, t = 0 }, S)
  local greetings = GREETINGS[period_name] or GREETINGS.day
  self.lines[1] = greetings[math.random(#greetings)]
  if period_name ~= "midnight" then
    local d = os.date("*t")
    self.lines[#self.lines + 1] = ("%d/%d（%s）だよ"):format(d.month, d.day, WEEKDAYS[d.wday])
    self.lines[#self.lines + 1] = memo_line()
    self.lines[#self.lines + 1] = IDLE[math.random(#IDLE)]
    -- Git の状況は裏で調べて、分かったら足す
    vim.system({ "git", "status", "--porcelain" }, { text = true, cwd = vim.fn.getcwd() }, function(res)
      if res.code == 0 then
        local n = select(2, res.stdout:gsub("[^\n]+", ""))
        if n > 0 then
          table.insert(self.lines, 3, ("コミットしてないの、%dつあるよ。知ってた？"):format(n))
        end
      end
    end)
  end
  return self
end

-- 猫の動きに合わせた一言
local REACTIONS = {
  swipe = { "えいっ", "とった", "…外した" },
  shake = { "…もう。乗らないでよ", "ぷるぷる" },
  yawn = { "ふあ…", "…ねむ" },
  groom = { "いま忙しいから", "見ないでよ" },
  stretch = { "んー…っ" },
}

--- 動きに合わせて、しばらく別の一言を言う。
---@param event string
function S:react(event)
  local list = REACTIONS[event]
  if list then
    self.override, self.override_left = list[math.random(#list)], 2.2
  end
end

--- いま言っている一言。数秒ごとに次へ進む。
---@param dt number
---@return string
function S:current(dt)
  if self.override then
    self.override_left = self.override_left - dt
    if self.override_left > 0 then
      return self.override
    end
    self.override = nil
  end
  self.t = self.t + dt
  if self.t > 7 then
    self.t = 0
    self.index = self.index % #self.lines + 1
  end
  return self.lines[self.index]
end

--- 吹き出しを extmark で描く。占めたセルを返す(花びらが乗れるように)。
---@param buf integer
---@param ns integer
---@param text string
---@param row integer 吹き出しの中段の行
---@param col integer 左端の桁(しっぽの位置)
---@param max_col integer これより右には描かない
---@return { top: integer, bottom: integer, left: integer, right: integer }?
function M.draw(buf, ns, text, row, col, max_col)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local inner = vim.api.nvim_strwidth(text) + 2
  if row < 1 or col + inner + 3 > max_col then
    return nil
  end
  local border = string.rep("─", inner)
  local rows = {
    { { " ╭" .. border .. "╮", "WisteriaBubble" } },
    { { "◀│ ", "WisteriaBubble" }, { text, "WisteriaBubbleText" }, { " │", "WisteriaBubble" } },
    { { " ╰" .. border .. "╯", "WisteriaBubble" } },
  }
  for i, chunks in ipairs(rows) do
    vim.api.nvim_buf_set_extmark(buf, ns, row - 2 + i, 0, {
      virt_text = chunks,
      virt_text_win_col = col,
      hl_mode = "combine",
      priority = 300,
    })
  end
  return { top = row - 1, bottom = row + 1, left = col, right = col + inner + 2 }
end

return M
