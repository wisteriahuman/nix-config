-- リネームの入口: LSP が扱えない対象は provider が引き受け、それ以外は vim.lsp.buf.rename に流す。
-- provider は { name, detect(buf) -> { old, ... } | nil, edits(target, new) -> { [path] = { {lnum, line}, ... } } }。
-- 編集は LSP のリネームと同じく WorkspaceEdit で適用する（バッファは未保存のまま残る）。
local M = {}

M.providers = {}

function M.register(provider)
  table.insert(M.providers, provider)
end

local function read_lines(path)
  local buf = vim.fn.bufnr(path)
  if buf ~= -1 and vim.api.nvim_buf_is_loaded(buf) then
    return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  end
  return vim.fn.readfile(path)
end
M.read_lines = read_lines

local function apply(changes)
  local workspace_edit, files = { changes = {} }, 0
  for path, replaced in pairs(changes) do
    local lines, edits = read_lines(path), {}
    for _, r in ipairs(replaced) do
      local lnum, text = r[1], r[2]
      table.insert(edits, {
        range = {
          start = { line = lnum - 1, character = 0 },
          ["end"] = { line = lnum - 1, character = vim.str_utfindex(lines[lnum], "utf-16") },
        },
        newText = text,
      })
    end
    if #edits > 0 then
      workspace_edit.changes[vim.uri_from_fname(path)] = edits
      files = files + 1
    end
  end
  vim.lsp.util.apply_workspace_edit(workspace_edit, "utf-16")
  return files
end

function M.rename()
  local buf = vim.api.nvim_get_current_buf()
  for _, provider in ipairs(M.providers) do
    local target = provider.detect(buf)
    if target then
      vim.ui.input({ prompt = provider.name .. ": ", default = target.old }, function(new)
        if not new or new == "" or new == target.old then
          return
        end
        local files = apply(provider.edits(target, new))
        vim.notify(("%s → %s（%d ファイル、未保存）"):format(target.old, new, files))
      end)
      return
    end
  end
  vim.lsp.buf.rename()
end

-- Go: go.mod の module 行で呼ぶと、module パスと配下の import をまとめて書き換える。
local function go_files(dir, acc)
  for name, type in vim.fs.dir(dir) do
    local path = dir .. "/" .. name
    if type == "file" and name:sub(-3) == ".go" then
      table.insert(acc, path)
    elseif
      type == "directory"
      and name ~= "vendor"
      and name:sub(1, 1) ~= "."
      and vim.fn.filereadable(path .. "/go.mod") == 0 -- 入れ子の module は別物
    then
      go_files(path, acc)
    end
  end
  return acc
end

M.register({
  name = "Go module",
  detect = function(buf)
    local path = vim.api.nvim_buf_get_name(buf)
    if vim.fs.basename(path) ~= "go.mod" then
      return nil
    end
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local old = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1]:match("^module%s+(%S+)")
    return old and { old = old, path = path, lnum = lnum }
  end,
  edits = function(target, new)
    local changes = { [target.path] = { { target.lnum, "module " .. new } } }
    local pat = '"' .. vim.pesc(target.old) .. '([/"])'
    local rep = '"' .. new:gsub("%%", "%%%%") .. "%1"
    for _, file in ipairs(go_files(vim.fs.dirname(target.path), {})) do
      local replaced, in_block = {}, false
      for lnum, line in ipairs(read_lines(file)) do
        if line:match("^import%s*%(") then
          in_block = true
        elseif in_block and line:match("^%)") then
          in_block = false
        elseif in_block or line:match("^import%s") then
          local text, n = line:gsub(pat, rep)
          if n > 0 then
            table.insert(replaced, { lnum, text })
          end
        end
      end
      changes[file] = replaced
    end
    return changes
  end,
})

return M
