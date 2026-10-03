return {
  {
    "neovim/nvim-lspconfig",
    dependencies = { "b0o/SchemaStore.nvim" },
    config = function()
      -- サーバが diagnostics: null を送ると vim.NIL のまま届き
      -- runtime の handle_diagnostics が #diagnostics で落ちるため空配列に正規化する
      local publish_diagnostics = vim.lsp.handlers["textDocument/publishDiagnostics"]
      vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx)
        if result and (result.diagnostics == nil or result.diagnostics == vim.NIL) then
          result.diagnostics = {}
        end
        return publish_diagnostics(err, result, ctx)
      end

      vim.lsp.config("pyright", {
        before_init = function(_, config)
          local venv = vim.fs.find(".venv", {
            path = config.root_dir,
            upward = true,
            type = "directory",
          })[1]
          if venv then
            config.settings.python.pythonPath = venv .. "/bin/python"
          end
        end,
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "basic",
            },
          },
        },
      })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
          },
        },
      })

      vim.lsp.config("gopls", {
        settings = {
          gopls = {
            staticcheck = true,
            usePlaceholders = true,
            analyses = {
              nilness = true,
              unusedparams = true,
              unusedwrite = true,
              useany = true,
            },
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              constantValues = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
          },
        },
      })

      local ts_settings = {
        updateImportsOnFileMove = { enabled = "always" },
        suggest = { completeFunctionCalls = true },
        inlayHints = {
          parameterNames = { enabled = "literals" },
          variableTypes = { enabled = true, suppressWhenTypeMatchesName = true },
          functionLikeReturnTypes = { enabled = true },
          enumMemberValues = { enabled = true },
        },
      }
      vim.lsp.config("vtsls", {
        settings = {
          vtsls = {
            autoUseWorkspaceTsdk = true,
            experimental = { completion = { enableServerSideFuzzyMatch = true } },
          },
          typescript = ts_settings,
          javascript = ts_settings,
        },
      })

      vim.lsp.config("bashls", {
        filetypes = { "sh", "bash", "zsh" },
      })

      vim.lsp.config("mermaid_lsp", {
        cmd = { "mermaid-lsp" },
        filetypes = { "mermaid" },
      })

      vim.lsp.config("yamlls", {
        settings = {
          redhat = { telemetry = { enabled = false } },
          yaml = {
            -- 組み込みのスキーマ取得は切り、SchemaStore.nvim の一覧を使う
            schemaStore = { enable = false, url = "" },
            schemas = require("schemastore").yaml.schemas(),
          },
        },
      })

      vim.lsp.config("jsonls", {
        settings = {
          json = {
            schemas = require("schemastore").json.schemas(),
            validate = { enable = true },
          },
        },
      })

      vim.lsp.config("ruby_lsp", {
        cmd = { "ruby-lsp" },
        filetypes = { "ruby", "eruby" },
        root_markers = { "Gemfile", ".git" },
        init_options = {
          formatter = "auto",
          linters = { "rubocop" },
          enabledFeatures = {
            codeActions = true,
            codeLens = true,
            completion = true,
            definition = true,
            diagnostics = true,
            documentHighlights = true,
            documentLink = true,
            documentSymbols = true,
            foldingRanges = true,
            formatting = true,
            hover = true,
            inlayHint = true,
            onTypeFormatting = true,
            selectionRanges = true,
            semanticHighlighting = true,
            signatureHelp = true,
            typeHierarchy = true,
            workspaceSymbol = true,
          },
          featuresConfiguration = {
            inlayHint = {
              implicitHashValue = true,
              implicitRescue = true,
            },
          },
        },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local function map(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = args.buf, silent = true, desc = desc })
          end
          local function fzf(picker)
            return function()
              require("fzf-lua")[picker]()
            end
          end

          map("gd", fzf("lsp_definitions"), "定義へ")
          map("gD", vim.lsp.buf.declaration, "宣言へ")
          map("K", vim.lsp.buf.hover, "ホバー")
          map("grr", fzf("lsp_references"), "参照一覧")
          map("gri", fzf("lsp_implementations"), "実装一覧")
          map("grt", fzf("lsp_typedefs"), "型定義へ")
          map("gO", fzf("lsp_document_symbols"), "ファイル内シンボル")
          map("<leader>rn", vim.lsp.buf.rename, "リネーム")

          local function action_map(lhs)
            vim.keymap.set(
              { "n", "x" },
              lhs,
              fzf("lsp_code_actions"),
              { buffer = args.buf, silent = true, desc = "コードアクション" }
            )
          end
          action_map("gra")
          action_map("<leader>ca")
          action_map("<leader>la")

          map("<leader>lr", vim.lsp.buf.rename, "リネーム")
          map("<leader>lf", fzf("lsp_finder"), "定義・参照・実装をまとめて表示")
          map("<leader>ls", fzf("lsp_document_symbols"), "ファイル内シンボル")
          map("<leader>lS", fzf("lsp_live_workspace_symbols"), "プロジェクト全体のシンボル")
          map("<leader>li", fzf("lsp_incoming_calls"), "この関数を呼んでいる箇所")
          map("<leader>lo", fzf("lsp_outgoing_calls"), "この関数が呼んでいる関数")
        end,
      })

      local map = vim.keymap.set
      map("n", "<leader>ld", "<cmd>FzfLua diagnostics_document<CR>", { desc = "このファイルの診断" })
      map("n", "<leader>lD", "<cmd>FzfLua diagnostics_workspace<CR>", { desc = "プロジェクト全体の診断" })
      map("n", "<leader>ll", vim.diagnostic.open_float, { desc = "この行の診断を全文表示" })
      map("n", "<leader>lI", "<cmd>checkhealth vim.lsp<CR>", { desc = "LSP の状態" })

      -- stdpath("config") は nix store 経由の symlink なので実体のパスを開く
      local snippets_dir = vim.uv.fs_realpath(vim.fn.stdpath("config")) .. "/snippets"
      map("n", "<leader>le", function()
        vim.cmd.edit(snippets_dir .. "/" .. vim.bo.filetype .. ".json")
      end, { desc = "このファイルタイプの自作スニペットを編集" })
      vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = snippets_dir .. "/*.json",
        callback = function()
          if package.loaded["blink.cmp"] then
            require("blink.cmp").reload("snippets")
          end
        end,
      })

      local hints = true
      vim.lsp.inlay_hint.enable(hints)
      map("n", "<leader>lh", function()
        hints = not hints
        vim.lsp.inlay_hint.enable(hints)
      end, { desc = "inlay hints 切り替え" })
      vim.api.nvim_create_autocmd({ "InsertEnter", "InsertLeave" }, {
        callback = function(args)
          vim.lsp.inlay_hint.enable(hints and args.event == "InsertLeave")
        end,
      })

      local icons = { ERROR = "\u{f057}", WARN = "\u{f071}", INFO = "\u{f05a}", HINT = "\u{f0335}" }
      local signs = {}
      for name, icon in pairs(icons) do
        signs[vim.diagnostic.severity[name]] = icon
      end
      -- virtual_lines は診断位置の桁から始まり折り返さないので、残り幅で自前で折り返す
      local function wrap_to_window(diagnostic)
        local win = vim.fn.bufwinid(diagnostic.bufnr)
        if win == -1 then
          return diagnostic.message
        end
        local used = vim.fn.virtcol({ diagnostic.lnum + 1, diagnostic.col + 1 }, false, win)
        local width = vim.api.nvim_win_get_width(win) - vim.fn.getwininfo(win)[1].textoff - used - 8
        width = math.max(width, 30)
        local lines = {}
        for _, paragraph in ipairs(vim.split(diagnostic.message, "\n")) do
          local line = ""
          for word in paragraph:gmatch("%S+") do
            if line ~= "" and vim.fn.strdisplaywidth(line .. " " .. word) > width then
              table.insert(lines, line)
              line = word
            else
              line = line == "" and word or (line .. " " .. word)
            end
          end
          table.insert(lines, line)
        end
        return table.concat(lines, "\n")
      end

      vim.diagnostic.config({
        severity_sort = true,
        signs = { text = signs },
        virtual_text = { current_line = false },
        virtual_lines = { current_line = true, format = wrap_to_window },
        float = { border = "rounded", source = true },
      })

      vim.lsp.enable("lua_ls")
      vim.lsp.enable("gopls")
      vim.lsp.enable("pyright")
      vim.lsp.enable("vtsls")
      vim.lsp.enable("biome")
      vim.lsp.enable("eslint")
      vim.lsp.enable("html")
      vim.lsp.enable("cssls")
      vim.lsp.enable("jsonls")
      vim.lsp.enable("astro")
      vim.lsp.enable("rust_analyzer")
      vim.lsp.enable("sourcekit")
      vim.lsp.enable("ruby_lsp")
      vim.lsp.enable("gleam")
      vim.lsp.enable("tsp_server")
      vim.lsp.enable("dockerls")
      vim.lsp.enable("docker_compose_language_service")
      vim.lsp.enable("bashls")
      vim.lsp.enable("yamlls")
      vim.lsp.enable("taplo")
      vim.lsp.enable("marksman")
      vim.lsp.enable("mermaid_lsp")
      vim.lsp.enable("nixd")

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "swift",
        callback = function()
          local root = vim.fs.root(0, function(name)
            return name:match("%.xcodeproj$")
          end)
          if not root then
            return
          end
          local bsj = root .. "/buildServer.json"
          if vim.uv.fs_stat(bsj) then
            return
          end
          local xcodeproj = vim.fs.find(function(name)
            return name:match("%.xcodeproj$")
          end, { path = root, type = "directory" })[1]
          if xcodeproj then
            local project = vim.fn.fnamemodify(xcodeproj, ":t")
            local scheme = project:gsub("%.xcodeproj$", "")
            vim
              .system({
                "xcode-build-server",
                "config",
                "-project",
                project,
                "-scheme",
                scheme,
              }, { cwd = root })
              :wait()
            vim.notify("xcode-build-server configured: " .. scheme, vim.log.levels.INFO)
          end
        end,
      })
    end,
  },
}
