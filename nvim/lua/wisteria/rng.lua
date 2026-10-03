-- 再現できる乱数(同じ種なら同じ絵になる)。
local M = {}
M.__index = M

function M.new(seed)
  return setmetatable({ s = seed % 2147483647 }, M)
end

--- 0 以上 1 未満
function M:next()
  self.s = (self.s * 48271) % 2147483647
  return self.s / 2147483647
end

function M:int(lo, hi)
  return lo + math.floor(self:next() * (hi - lo + 1))
end

return M
