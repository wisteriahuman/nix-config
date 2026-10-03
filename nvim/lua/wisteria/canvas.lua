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

--- 行ごとの virt_text チャンク列を作る。blocked(row, col) が true のセルは描かない。
---@param blocked fun(row: integer, col: integer): boolean
---@return table<integer, {col: integer, chunks: table}[]>
function M:runs(blocked)
  local out = {}
  for row = 0, self.rows - 1 do
    local runs, cur = {}, nil
    for col = 0, self.cols - 1 do
      local top, bottom = self.px[row * 2 * self.w + col], self.px[(row * 2 + 1) * self.w + col]
      local chunk
      if (top or bottom) and not blocked(row, col) then
        if top and bottom then
          chunk = top == bottom and { "█", hl(top) } or { "▀", hl(top, bottom) }
        elseif top then
          chunk = { "▀", hl(top) }
        else
          chunk = { "▄", hl(bottom) }
        end
      end
      if chunk then
        if not cur then
          cur = { col = col, chunks = {} }
          runs[#runs + 1] = cur
        end
        cur.chunks[#cur.chunks + 1] = chunk
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
function M:draw(buf, ns, blocked)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local line_count = vim.api.nvim_buf_line_count(buf)
  for row, runs in pairs(self:runs(blocked)) do
    if row < line_count then
      for _, run in ipairs(runs) do
        vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
          virt_text = run.chunks,
          virt_text_win_col = run.col,
          hl_mode = "combine",
          priority = 200,
        })
      end
    end
  end
end

return M
