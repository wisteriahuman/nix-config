-- translate.nvim の parse_before。識別子とコードの式を、DeepL が読める英文に書き換える。
local M = {}

local non_verbs = { is = true, has = true, can = true, should = true, will = true, was = true, did = true, to = true, on = true, as = true }

function M.split_identifier(word)
  if not (word:find("%w_+%w") or word:find("%l%u")) or word:find("^%l%u%l*$") then
    return word
  end
  local s = word:gsub("_+", " "):gsub("(%l)(%u)", "%1 %2"):gsub("(%u)(%u%l)", "%1 %2")
  local screaming = not word:find("%l")
  return (s:gsub("%S+", function(w)
    if screaming or not w:find("^%u+$") then
      return w:lower()
    end
  end))
end

local function split_words(text)
  return (text:gsub("[%w_]+", M.split_identifier))
end

local separators = { "::", "->", ".", ":" }

local function closing_paren(s, open)
  local depth = 0
  for i = open, #s do
    local c = s:sub(i, i)
    if c == "(" then
      depth = depth + 1
    elseif c == ")" then
      depth = depth - 1
      if depth == 0 then
        return i
      end
    end
  end
end

local rewrite

local function parse_chain(s, i)
  local segments = {}
  local name, j = s:match("^([%a_][%w_]*)()", i)
  segments[1] = { name = name }
  while true do
    if s:sub(j, j) == "(" then
      local close = closing_paren(s, j)
      if not close then
        break
      end
      segments[#segments].args = s:sub(j + 1, close - 1)
      j = close + 1
    else
      local matched
      for _, sep in ipairs(separators) do
        local after = j + #sep
        if s:sub(j, after - 1) == sep and s:find("^[%a_]", after) then
          name, j = s:match("^([%a_][%w_]*)()", after)
          table.insert(segments, { name = name })
          matched = true
          break
        end
      end
      if not matched then
        break
      end
    end
  end
  return segments, j
end

local function args_text(seg)
  if not seg.args or seg.args == "" then
    return ""
  end
  return " (" .. rewrite(seg.args) .. ")"
end

local function render_owner(segments, n)
  local pieces = {}
  for k = 1, n do
    local seg = segments[k]
    local getter = seg.args and seg.name:match("^get([%u_].*)")
    if getter then
      local words = M.split_identifier((getter:gsub("^_", "")))
      if words:find("^%u%l*$") then
        words = words:lower()
      end
      table.insert(pieces, words .. args_text(seg))
    else
      table.insert(pieces, M.split_identifier(seg.name) .. args_text(seg))
    end
  end
  return table.concat(pieces, "'s ")
end

local function render_chain(segments)
  local n = #segments
  local last = segments[n]
  if n == 1 then
    return M.split_identifier(last.name) .. args_text(last)
  end
  local words = M.split_identifier(last.name)
  local verb, rest = words:match("^(%S+)%s*(.*)$")
  if not last.args or non_verbs[verb:lower()] then
    return render_owner(segments, n)
  end
  local owner = render_owner(segments, n - 1)
  local object = rest ~= "" and (rest .. " of " .. owner) or owner
  return verb .. " " .. object .. args_text(last)
end

function rewrite(s)
  local out, i = {}, 1
  while i <= #s do
    if s:find("^[%a_]", i) and not s:sub(i - 1, i - 1):find("[%w_]") then
      local segments, j = parse_chain(s, i)
      table.insert(out, render_chain(segments))
      i = j
    else
      table.insert(out, s:sub(i, i))
      i = i + 1
    end
  end
  return table.concat(out)
end

local function comment_marker()
  local marker = vim.bo.commentstring:match("^(.-)%s*%%s")
  if marker and marker ~= "" then
    return marker
  end
end

-- 文字列とコメントは地の文として、識別子の分割だけかける
local function rewrite_line(line, marker)
  local out, code_start, i = {}, 1, 1
  local function flush(upto)
    table.insert(out, rewrite(line:sub(code_start, upto)))
  end
  while i <= #line do
    local c = line:sub(i, i)
    if marker and line:sub(i, i + #marker - 1) == marker then
      flush(i - 1)
      table.insert(out, split_words(line:sub(i)))
      return table.concat(out)
    elseif c == '"' or c == "'" or c == "`" then
      local j = i + 1
      while j <= #line and line:sub(j, j) ~= c do
        j = j + (line:sub(j, j) == "\\" and 2 or 1)
      end
      flush(i - 1)
      table.insert(out, split_words(line:sub(i, j)))
      i, code_start = j + 1, j + 1
    else
      i = i + 1
    end
  end
  flush(#line)
  return table.concat(out)
end

M.split_case = {
  cmd = function(lines)
    return vim.tbl_map(split_words, lines)
  end,
}

M.code = {
  cmd = function(lines)
    local marker = comment_marker()
    return vim.tbl_map(function(line)
      return rewrite_line(line, marker)
    end, lines)
  end,
}

return M
