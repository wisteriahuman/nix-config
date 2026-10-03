-- 半角ブロック文字(▀▄█)で、1セル=縦2ドットのドット絵を描くためのキャンバス。
local M = {}
M.__index = M

local hl_cache = {}

local function hl(fg, bg)
  local name = "WisteriaPx_" .. fg:sub(2) .. "_" .. (bg and bg:sub(2) or "none")
  if not hl_cache[name] then
    vim.api.nvim_set_hl(0, name, { fg = fg, bg = bg })
    hl_cache[name] = true
  end
  return name
end

function M.clear_hl_cache()
  hl_cache = {}
end

---@param cols integer セル単位の幅
---@param rows integer セル単位の高さ(ドットでは rows*2)
function M.new(cols, rows)
  return setmetatable({ cols = cols, rows = rows, w = cols, h = rows * 2, px = {} }, M)
end

function M:set(x, y, color)
  if x >= 0 and x < self.w and y >= 0 and y < self.h then
    self.px[y * self.w + x] = color
  end
end

function M:get(x, y)
  if x < 0 or x >= self.w or y < 0 or y >= self.h then
    return nil
  end
  return self.px[y * self.w + x]
end

function M:clear()
  self.px = {}
end

--- 行ごとに、連続して描くセルの並びを作る。blocked(row, col) が true のセルは描かない。
---@param blocked fun(row: integer, col: integer): boolean
---@return table<integer, { col: integer, cells: { [1]: string, [2]: string, [3]: string? }[] }[]> cells は {文字, 前景色, 背景色?}
function M:runs(blocked)
  local out = {}
  for row = 0, self.rows - 1 do
    local runs, cur = {}, nil
    for col = 0, self.cols - 1 do
      local top, bottom = self.px[row * 2 * self.w + col], self.px[(row * 2 + 1) * self.w + col]
      local cell
      if (top or bottom) and not blocked(row, col) then
        if top and bottom then
          cell = top == bottom and { "█", top } or { "▀", top, bottom }
        elseif top then
          cell = { "▀", top }
        else
          cell = { "▄", bottom }
        end
      end
      if cell then
        if not cur then
          cur = { col = col, cells = {} }
          runs[#runs + 1] = cur
        end
        cur.cells[#cur.cells + 1] = cell
      else
        cur = nil
      end
    end
    if #runs > 0 then
      out[row] = runs
    end
  end
  return out
end

--- バッファに extmark として描画する。
--- バッファの行がある範囲は、その行に重ねて描く。それより下は、最終行の下に仮想行として描く
--- (実際の行を足すと、カーソルがそこへ入れてしまうため)。
---@param row_bg fun(row: integer): string その行の背景色
function M:draw(buf, ns, blocked, row_bg)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local line_count = vim.api.nvim_buf_line_count(buf)
  local runs_by_row = self:runs(blocked)

  for row, runs in pairs(runs_by_row) do
    if row < line_count then
      for _, run in ipairs(runs) do
        local chunks = {}
        for i, cell in ipairs(run.cells) do
          chunks[i] = { cell[1], hl(cell[2], cell[3]) }
        end
        vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
          virt_text = chunks,
          virt_text_win_col = run.col,
          hl_mode = "combine",
          priority = 200,
        })
      end
    end
  end

  if self.rows > line_count and line_count > 0 then
    local virt_lines = {}
    for row = line_count, self.rows - 1 do
      local bg = row_bg(row)
      local blank = hl(bg, bg)
      local chunks, col = {}, 0
      for _, run in ipairs(runs_by_row[row] or {}) do
        if run.col > col then
          chunks[#chunks + 1] = { string.rep(" ", run.col - col), blank }
        end
        for _, cell in ipairs(run.cells) do
          chunks[#chunks + 1] = { cell[1], hl(cell[2], cell[3] or bg) }
        end
        col = run.col + #run.cells
      end
      if col < self.cols then
        chunks[#chunks + 1] = { string.rep(" ", self.cols - col), blank }
      end
      virt_lines[#virt_lines + 1] = chunks
    end
    vim.api.nvim_buf_set_extmark(buf, ns, line_count - 1, 0, { virt_lines = virt_lines, priority = 200 })
  end
end

return M
