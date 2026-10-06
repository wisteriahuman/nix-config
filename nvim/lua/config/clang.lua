local M = {}

-- コンパイルフラグの指定が無い C ファイルに、clangd と clang-tidy の両方で使う
M.fallback_flags = { "-std=c17", "-Wall", "-Wextra" }

-- LSP サーバーのメモリ上限(MB)。超えたら止める。キーはサーバー名で、プロセス名と同じであること。
-- 普通の C ファイルなら clangd は 60〜150MB。巨大な配列の初期化子を持つヘッダを読むと数秒で GB に届く。
-- Linux カーネルのような、正常でも 1GB を超えるプロジェクトを開くときは上げる
M.memory_limits_mb = { clangd = 1024 }

M.analyze_timeout_ms = 5000

local blocked = {} -- 絶対パス → true。止めたときにサーバーが付いていたファイル
local pending = {} -- client id → 止める直前に解析中だったバッファ
local busy = {} -- uri → true。clangd が解析中のファイル
local timer

function M.is_blocked(bufnr)
  return blocked[vim.api.nvim_buf_get_name(bufnr)] == true
end

-- 直接 include しているローカルのヘッダのうち 1MB を超えるもの。孫 include までは追わない
local function large_includes(bufnr)
  local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
  local found = {}
  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    local name = line:match('^%s*#%s*include%s*"([^"]+)"')
    local stat = name and vim.uv.fs_stat(dir .. "/" .. name)
    if stat and stat.size > 1e6 then
      table.insert(found, ("%s (%dMB)"):format(name, stat.size / 1e6))
    end
  end
  return found
end

-- vim.lsp.config の handlers["textDocument/clangd.fileStatus"] に渡す
function M.on_file_status(_, result)
  busy[result.uri] = result.state ~= "idle" or nil
end

local function stop(name, pid)
  -- 同名のクライアントが複数あると、どれのプロセスかは終了の通知(on_exit)が来るまで分からない
  for _, client in ipairs(vim.lsp.get_clients({ name = name })) do
    local attached = vim.tbl_keys(client.attached_buffers)
    -- 解析が終わっているファイルは原因ではないので巻き込まない
    local culprits = vim.tbl_filter(function(bufnr)
      return busy[vim.uri_from_bufnr(bufnr)]
    end, attached)
    pending[client.id] = #culprits > 0 and culprits or attached
  end
  vim.uv.kill(pid, "sigkill")
end

local function check()
  local watching = false
  for name in pairs(M.memory_limits_mb) do
    watching = watching or #vim.lsp.get_clients({ name = name }) > 0
  end
  if not watching then
    timer:stop()
    return
  end
  for _, pid in ipairs(vim.api.nvim_get_proc_children(vim.fn.getpid())) do
    local proc = vim.api.nvim_get_proc(pid)
    local limit = proc and M.memory_limits_mb[proc.name]
    if limit then
      vim.system(
        { "ps", "-o", "rss=", "-p", tostring(pid) },
        { text = true },
        vim.schedule_wrap(function(out)
          local mb = (tonumber(vim.trim(out.stdout or "")) or 0) / 1024
          if mb > limit then
            stop(proc.name, pid)
          end
        end)
      )
    end
  end
end

-- vim.lsp.config の on_exit に渡す。上限超えで止めたクライアントのファイルをブロックする
function M.on_exit(_, signal, client_id)
  local bufs = pending[client_id]
  pending[client_id] = nil
  if not bufs or signal ~= 9 then
    return
  end
  vim.schedule(function()
    local files, suspects = {}, {}
    for _, bufnr in ipairs(bufs) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        local path = vim.api.nvim_buf_get_name(bufnr)
        blocked[path] = true
        table.insert(files, vim.fs.basename(path))
        vim.list_extend(suspects, large_includes(bufnr))
      end
    end
    local lines = {
      ("clangd がメモリ %dMB を超えたので止めました: %s"):format(
        M.memory_limits_mb.clangd,
        table.concat(files, ", ")
      ),
    }
    if #suspects > 0 then
      table.insert(lines, "原因の候補: " .. table.concat(suspects, ", "))
    end
    table.insert(
      lines,
      "このファイルでは Neovim を閉じるまで clangd を起動しません。解除は :ClangdUnblock"
    )
    vim.notify(table.concat(lines, "\n"), vim.log.levels.WARN)
    -- 巻き込まれて clangd を失った他のファイルに付け直す
    vim.cmd("doautoall nvim.lsp.enable FileType")
  end)
end

function M.setup()
  timer = assert(vim.uv.new_timer())
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and M.memory_limits_mb[client.name] and not timer:is_active() then
        timer:start(2000, 2000, vim.schedule_wrap(check))
      end
    end,
  })

  vim.api.nvim_create_user_command("ClangdUnblock", function()
    blocked = {}
    vim.cmd("doautoall nvim.lsp.enable FileType")
  end, { desc = "メモリ上限で止めた clangd のブロックを解除して付け直す" })
end

local ns = vim.api.nvim_create_namespace("clangtidy")
local running = {} -- bufnr → 実行中の clang-tidy
local timed_out = {} -- 絶対パス → true。打ち切りの通知は 1 ファイル 1 回だけ
local sdk -- nix の clang-tidy は macOS の SDK を自分では見つけられない

-- clangd 内蔵の clang-tidy は clang-analyzer-* を動かせないので、それだけを保存時に走らせる。
-- ディスク上のファイルを読むので、未保存の変更は見えない
function M.analyze(bufnr)
  if M.is_blocked(bufnr) or vim.fn.executable("clang-tidy") == 0 then
    return
  end
  if sdk == nil then
    sdk = false
    if vim.fn.executable("xcrun") == 1 then
      local out = vim.system({ "xcrun", "--show-sdk-path" }, { text = true }):wait()
      sdk = out.code == 0 and vim.trim(out.stdout) or false
    end
  end

  local file = vim.api.nvim_buf_get_name(bufnr)
  -- nix の clang-tidy はシェルのラッパーで、止めても本体が孤児になって走り続ける。
  -- SDK を自前で渡せる mac では本体を直接呼ぶ
  local unwrapped = sdk and vim.fn.executable("clang-tidy-unwrapped") == 1
  local cmd = { unwrapped and "clang-tidy-unwrapped" or "clang-tidy", "--quiet", "--checks=-*,clang-analyzer-*" }
  if sdk then
    vim.list_extend(cmd, { "--extra-arg=-isysroot", "--extra-arg=" .. sdk })
  end
  table.insert(cmd, file)
  if not vim.fs.root(bufnr, { "compile_commands.json", "compile_flags.txt" }) then
    table.insert(cmd, "--")
    vim.list_extend(cmd, M.fallback_flags)
  end

  if running[bufnr] then
    running[bufnr]:kill("sigkill")
  end
  local cwd = vim.fs.dirname(file)
  local proc
  proc = vim.system(
    cmd,
    { text = true, cwd = cwd, timeout = M.analyze_timeout_ms },
    vim.schedule_wrap(function(out)
      if running[bufnr] ~= proc then
        return -- 新しい実行に置き換わった
      end
      running[bufnr] = nil
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end
      if out.code == 124 then
        vim.diagnostic.reset(ns, bufnr)
        if not timed_out[file] and not M.is_blocked(bufnr) then
          timed_out[file] = true
          vim.notify(
            ("clang-tidy が %d 秒で終わらなかったので打ち切りました: %s"):format(
              M.analyze_timeout_ms / 1000,
              vim.fs.basename(file)
            ),
            vim.log.levels.WARN
          )
        end
        return
      end
      vim.diagnostic.set(ns, bufnr, require("lint.linters.clangtidy").parser(out.stdout or "", bufnr, cwd))
    end)
  )
  running[bufnr] = proc
end

return M
