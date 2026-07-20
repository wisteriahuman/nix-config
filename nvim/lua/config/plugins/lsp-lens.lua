return {
  {
    "VidocqH/lsp-lens.nvim",
    event = "LspAttach",
    -- 上流が未メンテのため pin して更新対象から外し、build で再インストール時に自動パッチを当てる:
    --   1. `client.supports_method` (非推奨) → コロン呼び出し
    --   2. get_recent_editor が git blame のパイプ/プロセスハンドルを閉じない FD リーク
    --      (放置するとバッファ切替のたびに fd が溜まり、上限到達で他プラグインの
    --       jobstart が E903 "bad file descriptor" で死ぬ)
    pin = true,
    build = function(plugin)
      local path = plugin.dir .. "/lua/lsp-lens/lens-util.lua"
      local file = io.open(path, "r")
      if not file then
        return
      end
      local content = file:read("*a")
      file:close()

      -- パターンでなく素の文字列で全置換
      local function replace_plain(text, from, to)
        local result, pos = {}, 1
        while true do
          local s, e = text:find(from, pos, true)
          if not s then
            result[#result + 1] = text:sub(pos)
            break
          end
          result[#result + 1] = text:sub(pos, s - 1) .. to
          pos = e + 1
        end
        return table.concat(result)
      end

      local patched = replace_plain(content, "client.supports_method(method)", "client:supports_method(method)")

      patched = replace_plain(
        patched,
        [[
  local authors = {}
  local most_recent_editor = nil
  vim.loop.spawn("git", {
    args = { "blame", "-L", start_row .. "," .. end_row, "--incremental", file_path },
    stdio = { nil, stdout, nil },
  }, function(_, _)
    local authors_arr = {}
    for author_name, _ in pairs(authors) do
      table.insert(authors_arr, author_name)
    end
    callback(most_recent_editor, authors_arr)
  end)
  vim.loop.read_start(stdout, function(err, data)
    if data == nil then
      return
    end]],
        [[
  local authors = {}
  local most_recent_editor = nil
  local handle
  handle = vim.loop.spawn("git", {
    args = { "blame", "-L", start_row .. "," .. end_row, "--incremental", file_path },
    stdio = { nil, stdout, nil },
  }, function(_, _)
    if handle and not handle:is_closing() then
      handle:close()
    end
  end)
  if handle == nil then
    stdout:close()
    return
  end
  vim.loop.read_start(stdout, function(err, data)
    if err or data == nil then
      -- EOF: 全出力を読み切ったのでパイプを閉じてから結果を返す
      if not stdout:is_closing() then
        stdout:read_stop()
        stdout:close()
      end
      local authors_arr = {}
      for author_name, _ in pairs(authors) do
        table.insert(authors_arr, author_name)
      end
      callback(most_recent_editor, authors_arr)
      return
    end]]
      )

      if patched ~= content then
        local out = io.open(path, "w")
        if out then
          out:write(patched)
          out:close()
        end
      end
    end,
    opts = {
      sections = {
        definition = false,
        references = function(count)
          return "参照: " .. count
        end,
        implements = function(count)
          return "実装: " .. count
        end,
        git_authors = function(latest_author, count)
          return "著者: " .. latest_author .. (count - 1 == 0 and "" or (" 他" .. (count - 1) .. "人"))
        end,
      },
      ignore_filetype = {
        "prisma",
        "markdown",
        "text",
        "json",
        "yaml",
        "toml",
      },
    },
    keys = {
      { "<leader>uL", "<cmd>LspLensToggle<CR>", desc = "Toggle LSP Lens" },
    },
  },
}
