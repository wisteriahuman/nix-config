-- 起動時のオープニング演出の進行表。
local M = {}

---@class wisteria.Timeline
---@field duration number 全体の秒数
---@field petal? number[] 最初の1枚の花びらが落ちる区間 {開始, 終了}
---@field grow number[] 藤が上から伸びる区間
---@field logo number[] ロゴが左から灯る区間
---@field cat number[] 猫がロゴの後ろから出てくる区間
---@field menu number[] メニューと一覧が上から現れる区間

---@type table<string, wisteria.Timeline>
M.timelines = {
  short = { duration = 1.8, grow = { 0, 1.0 }, logo = { 0.5, 1.1 }, cat = { 0.9, 1.4 }, menu = { 1.0, 1.8 } },
  long = {
    duration = 4.7,
    petal = { 0, 1.0 },
    grow = { 0.7, 2.4 },
    logo = { 2.1, 3.1 },
    cat = { 3.0, 3.7 },
    menu = { 3.5, 4.6 },
  },
}

---@class wisteria.Opening
---@field kind "short"|"long"
---@field t number
---@field line wisteria.Timeline
---@field skip? boolean キーが押されたら true

---@param kind "short"|"long"
---@return wisteria.Opening
function M.new(kind)
  return { kind = kind, t = 0, line = M.timelines[kind] }
end

--- その場面がどこまで進んだか(0..1)。終わりに向かって減速する。
---@param op wisteria.Opening
---@param scene string
---@return number
function M.progress(op, scene)
  local range = op.line[scene]
  if not range then
    return 1
  end
  local p = math.min(1, math.max(0, (op.t - range[1]) / (range[2] - range[1])))
  return 1 - (1 - p) ^ 2
end

--- その日の最初の起動なら長い版。日付は午前4時で切り替える。
---@return "short"|"long"
function M.kind_for_today()
  local path = vim.fn.stdpath("state") .. "/wisteria_opening"
  local today = os.date("%Y%m%d", os.time() - 4 * 3600)
  local last = vim.fn.filereadable(path) == 1 and vim.fn.readfile(path)[1] or nil
  if last == today then
    return "short"
  end
  vim.fn.writefile({ today }, path)
  return "long"
end

return M
