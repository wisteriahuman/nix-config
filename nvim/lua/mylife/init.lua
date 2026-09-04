local M = {}

local default_cli = "/Users/wisteria/Projects/mylife/tools/mylife-cli/bin/mylife.mjs"

function M.setup(options)
  options = options or {}
  local cli = options.cli or default_cli

  vim.api.nvim_create_user_command("MylifeReflection", function()
    vim.system({ "node", cli, "print" }, { text = true }, function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          vim.notify(result.stderr ~= "" and result.stderr or "振り返りを読み込めませんでした", vim.log.levels.ERROR)
          return
        end

        local buffer = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_name(buffer, "mylife://today/reflection")
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, vim.split(result.stdout, "\n", { plain = true }))
        vim.bo[buffer].filetype = "markdown"
        vim.bo[buffer].buftype = "acwrite"
        vim.api.nvim_set_current_buf(buffer)

        vim.api.nvim_create_autocmd("BufWriteCmd", {
          buffer = buffer,
          callback = function()
            local text = table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), "\n")
            vim.system({ "node", cli, "save", "--stdin" }, { text = true, stdin = text }, function(saved)
              vim.schedule(function()
                if saved.code == 0 then
                  vim.bo[buffer].modified = false
                  vim.notify("今日の振り返りを保存しました")
                else
                  vim.notify(saved.stderr ~= "" and saved.stderr or "保存できませんでした", vim.log.levels.ERROR)
                end
              end)
            end)
          end,
        })
      end)
    end)
  end, { desc = "今日の振り返りを開く" })
end

return M
