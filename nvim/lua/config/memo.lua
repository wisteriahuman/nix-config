-- 軽いメモ: main-vault/inbox/YYYY-MM-DD.md に1日1ファイルで追記する。
-- vault は Prometheus 管理なのでフロントマター必須（id は Prometheus が自動付与）。
local M = {}

M.dir = vim.fn.expand("~/Vaults/main-vault/inbox")

local function utc_now()
  return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

function M.today()
  vim.fn.mkdir(M.dir, "p")
  local date = os.date("%Y-%m-%d")
  local path = M.dir .. "/" .. date .. ".md"
  if vim.fn.filereadable(path) == 0 then
    local now = utc_now()
    vim.fn.writefile({
      "---",
      ('title: "%s"'):format(date),
      ('created: "%s"'):format(now),
      ('modified: "%s"'):format(now),
      "tags: [inbox]",
      "---",
      "",
      "# " .. date,
    }, path)
  end

  vim.cmd.edit(vim.fn.fnameescape(path))
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  while #lines > 0 and lines[#lines] == "" do
    table.remove(lines)
  end
  if lines[#lines] and lines[#lines]:match("^## %d%d:%d%d$") then
    table.remove(lines)
    while #lines > 0 and lines[#lines] == "" do
      table.remove(lines)
    end
  end
  table.insert(lines, "")
  table.insert(lines, "## " .. os.date("%H:%M"))
  table.insert(lines, "")
  table.insert(lines, "")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { #lines, 0 })
  vim.cmd("startinsert")
end

function M.find()
  require("fzf-lua").files({ cwd = M.dir })
end

function M.grep()
  require("fzf-lua").live_grep({ cwd = M.dir })
end

vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("memo_modified", { clear = true }),
  pattern = M.dir .. "/*.md",
  callback = function(args)
    local head = vim.api.nvim_buf_get_lines(args.buf, 0, 10, false)
    for i, line in ipairs(head) do
      if line:match("^modified:") then
        vim.api.nvim_buf_set_lines(args.buf, i - 1, i, false, { ('modified: "%s"'):format(utc_now()) })
        return
      end
    end
  end,
})

vim.keymap.set("n", "<leader>mn", M.today, { desc = "Memo: Today" })
vim.keymap.set("n", "<leader>mf", M.find, { desc = "Memo: Find File" })
vim.keymap.set("n", "<leader>mg", M.grep, { desc = "Memo: Grep" })

return M
