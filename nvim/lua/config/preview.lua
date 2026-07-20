local M = {}

local state = { jobid = nil }

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Preview" })
end

function M.openapi()
  local file = vim.fn.expand("%:p")
  if file == "" then
    notify("ファイルが開かれていません", vim.log.levels.WARN)
    return
  end

  if state.jobid and vim.fn.jobwait({ state.jobid }, 0)[1] == -1 then
    notify("既にプレビューが起動中です。:OpenApiPreviewStop で停止", vim.log.levels.WARN)
    return
  end

  state.jobid = vim.fn.jobstart({ "swagger-ui-watcher", "--port", "8765", file }, {
    detach = false,
    on_exit = function(_, code)
      state.jobid = nil
      if code ~= 0 then
        notify("swagger-ui-watcher 終了コード: " .. code, vim.log.levels.WARN)
      end
    end,
  })

  if state.jobid <= 0 then
    notify("swagger-ui-watcher の起動に失敗（PATHを確認）", vim.log.levels.ERROR)
    state.jobid = nil
    return
  end

  notify("OpenAPI Preview 起動: " .. vim.fn.fnamemodify(file, ":t") .. " (port 8765)")
end

function M.openapi_stop()
  if not state.jobid then
    notify("プレビューは起動していません")
    return
  end
  vim.fn.jobstop(state.jobid)
  state.jobid = nil
  notify("OpenAPI Preview 停止")
end

vim.api.nvim_create_user_command("OpenApiPreview", M.openapi, {})
vim.api.nvim_create_user_command("OpenApiPreviewStop", M.openapi_stop, {})

vim.keymap.set("n", "<leader>po", M.openapi, { desc = "OpenAPI Preview (Arc)" })
vim.keymap.set("n", "<leader>pO", M.openapi_stop, { desc = "OpenAPI Preview Stop" })

return M
