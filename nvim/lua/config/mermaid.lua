local M = {}

-- otter-ls は formatting を中継しないので、otter バッファ側の mermaid_lsp に直接整形させて結果を写す
function M.format_blocks(main_nr)
  main_nr = main_nr or vim.api.nvim_get_current_buf()
  local ok, keeper = pcall(require, "otter.keeper")
  local raft = ok and keeper.rafts[main_nr]
  local otter_nr = raft and raft.buffers.mermaid
  if not otter_nr then
    return
  end
  local client = vim.lsp.get_clients({ bufnr = otter_nr, name = "mermaid_lsp" })[1]
  if not client then
    return
  end
  keeper.sync_raft(main_nr, "mermaid")

  local params = {
    textDocument = { uri = vim.uri_from_bufnr(otter_nr) },
    options = { tabSize = vim.bo[main_nr].shiftwidth, insertSpaces = vim.bo[main_nr].expandtab },
  }
  client:request("textDocument/formatting", params, function(err, edits)
    if err or not edits or not vim.api.nvim_buf_is_valid(main_nr) then
      return
    end
    for _, edit in ipairs(edits) do
      local lnum = edit.range.start.line
      local main = vim.api.nvim_buf_get_lines(main_nr, lnum, lnum + 1, false)[1]
      local otter = vim.api.nvim_buf_get_lines(otter_nr, lnum, lnum + 1, false)[1]
      -- otter はリスト内ブロックの共通インデントを削るので、削られた分を戻す
      if main and otter and main:sub(#main - #otter + 1) == otter then
        local text = edit.newText == "" and "" or main:sub(1, #main - #otter) .. edit.newText
        if text ~= main then
          vim.api.nvim_buf_set_lines(main_nr, lnum, lnum + 1, false, { text })
        end
      end
    end
  end, otter_nr)
end

return M
