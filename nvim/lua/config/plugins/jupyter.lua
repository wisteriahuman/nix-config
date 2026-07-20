local function cell_bounds()
  local cur = vim.fn.line(".")
  local last_line = vim.fn.line("$")
  local first = 1
  local last = last_line

  for line = cur, 1, -1 do
    if vim.fn.getline(line):match("^# %%%%") then
      first = line + 1
      break
    end
  end

  for line = cur + 1, last_line do
    if vim.fn.getline(line):match("^# %%%%") then
      last = line - 1
      break
    end
  end

  while first <= last and vim.fn.getline(first):match("^%s*$") do
    first = first + 1
  end
  while last >= first and vim.fn.getline(last):match("^%s*$") do
    last = last - 1
  end

  return first, last
end

local function eval_cell(move_next)
  local ok_colab, colab = pcall(require, "colab.proxy")
  if not ok_colab or not colab.is_ready() then
    vim.notify("Colab is not connected; run :ColabNew --gpu T4 first", vim.log.levels.WARN)
    return
  end

  if vim.fn.exists(":MoltenInit") == 0 then
    require("lazy").load({ plugins = { "molten-nvim" } })
  end
  if vim.fn.exists(":MoltenInit") == 0 then
    vim.notify("Molten is not registered; run :UpdateRemotePlugins and restart Neovim", vim.log.levels.ERROR)
    return
  end

  local first, last = cell_bounds()
  if first > last then
    vim.notify("No code in this cell", vim.log.levels.WARN)
    return
  end
  local marker = first > 1 and vim.fn.getline(first - 1) or ""
  if marker:match("%[markdown%]") then
    vim.notify("Markdown cells are rendered text, not executable code", vim.log.levels.INFO)
    return
  end

  local ok, err = pcall(vim.fn.MoltenEvaluateRange, first, last)
  if not ok then
    vim.notify("MoltenEvaluateRange failed: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  if move_next then
    for line = last + 1, vim.fn.line("$") do
      if vim.fn.getline(line):match("^# %%%%") then
        vim.api.nvim_win_set_cursor(0, { line, 0 })
        return
      end
    end
  end
end

local function goto_cell(direction)
  local cur = vim.fn.line(".")
  local stop = direction > 0 and vim.fn.line("$") or 1
  for line = cur + direction, stop, direction do
    if vim.fn.getline(line):match("^# %%%%") then
      vim.api.nvim_win_set_cursor(0, { line, 0 })
      return
    end
  end
  vim.notify("No more cells", vim.log.levels.INFO)
end

return {
  {
    "goerz/jupytext.nvim",
    version = "0.2.0",
    opts = {
      format = "py:percent",
    },
  },
  {
    "wisteriahuman/colab.nvim",
    lazy = false,
    build = "uv sync",
    opts = {
      default_accelerator = "T4",
      auto_attach_molten = true,
    },
  },
  {
    "willothy/wezterm.nvim",
    lazy = true,
    cond = function()
      return vim.env.WEZTERM_PANE ~= nil
    end,
  },
  {
    "benlubas/molten-nvim",
    ft = { "python" },
    build = function()
      local python = vim.g.python3_host_prog or "python3"
      vim.system({
        "uv",
        "pip",
        "install",
        "--python",
        python,
        "pynvim",
        "jupyter-client",
        "requests",
        "websocket-client",
        "pillow",
      }):wait()
      vim.cmd("UpdateRemotePlugins")
    end,
    dependencies = { "willothy/wezterm.nvim" },
    init = function()
      vim.g.molten_image_provider = vim.env.WEZTERM_PANE and "wezterm" or "none"
      vim.g.molten_auto_open_output = false
      vim.g.molten_auto_open_html_in_browser = true
      vim.g.molten_open_cmd = "open"
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_output_win_max_width = 90
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_text_output = true
      vim.g.molten_virt_text_max_lines = 12
      vim.g.molten_split_direction = "right"
      vim.g.molten_split_size = 40
      vim.g.molten_tick_rate = 200
    end,
    config = function()
      local map = vim.keymap.set

      map("n", "<leader>ji", "<cmd>MoltenInit<CR>", { desc = "Jupyter Init Kernel" })
      map("n", "<leader>jI", "<cmd>MoltenInfo<CR>", { desc = "Jupyter Kernel Info" })
      map("n", "<leader>jc", function() eval_cell(false) end, { desc = "Jupyter Run Cell" })
      map("n", "<leader>jC", function() eval_cell(true) end, { desc = "Jupyter Run Cell and Next" })
      map("n", "<leader>jl", "<cmd>MoltenEvaluateLine<CR>", { desc = "Jupyter Run Line" })
      map("v", "<leader>jr", ":<C-u>MoltenEvaluateVisual<CR>gv", { desc = "Jupyter Run Selection" })
      map("n", "<leader>jn", function() goto_cell(1) end, { desc = "Jupyter Next Cell" })
      map("n", "<leader>jp", function() goto_cell(-1) end, { desc = "Jupyter Previous Cell" })
      map("n", "<leader>jo", "<cmd>MoltenShowOutput<CR>", { desc = "Jupyter Show Output" })
      map("n", "<leader>jh", "<cmd>MoltenHideOutput<CR>", { desc = "Jupyter Hide Output" })
      map("n", "<leader>jb", "<cmd>MoltenOpenInBrowser<CR>", { desc = "Jupyter Open HTML Output" })
      map("n", "<leader>jx", "<cmd>MoltenInterrupt<CR>", { desc = "Jupyter Interrupt" })
      map("n", "<leader>jR", "<cmd>MoltenRestart!<CR>", { desc = "Jupyter Restart Kernel" })
      map("n", "<leader>jd", "<cmd>MoltenDelete<CR>", { desc = "Jupyter Delete Output" })
      map("n", "<leader>jD", "<cmd>MoltenDelete!<CR>", { desc = "Jupyter Delete All Outputs" })

      local ok, wk = pcall(require, "which-key")
      if ok then
        wk.add({ { "<leader>j", group = "jupyter" } })
      end
    end,
  },
}
