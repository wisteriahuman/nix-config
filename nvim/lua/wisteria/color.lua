local M = {}

function M.rgb(hex)
  return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
end

function M.hex(r, g, b)
  return string.format("#%02x%02x%02x", math.floor(r + 0.5), math.floor(g + 0.5), math.floor(b + 0.5))
end

--- a から b へ t(0..1) だけ寄せる
function M.mix(a, b, t)
  local ar, ag, ab = M.rgb(a)
  local br, bg, bb = M.rgb(b)
  return M.hex(ar + (br - ar) * t, ag + (bg - ag) * t, ab + (bb - ab) * t)
end

return M
