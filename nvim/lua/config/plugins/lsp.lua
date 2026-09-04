return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
      local registry = require("mason-registry")
      local tools = { "stylua", "biome", "ruff" }
      for _, tool in ipairs(tools) do
        if not registry.is_installed(tool) then
          registry.get_package(tool):install()
        end
      end
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "gopls",
          "pyright",
          "ts_ls",
          "html",
          "cssls",
          "jsonls",
          "astro",
          "rust_analyzer",
          "dockerls",
          "docker_compose_language_service",
          "mermaid_ls",
          "sqls",
        },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason-lspconfig.nvim" },
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
          local opts = { buffer = args.buf, silent = true }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
          vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set({ "i", "n" }, "<C-k>", vim.lsp.buf.signature_help, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "<leader>ds", vim.lsp.buf.document_symbol, opts)
          vim.keymap.set("n", "<leader>ws", vim.lsp.buf.workspace_symbol, opts)

          local client = vim.lsp.get_client_by_id(args.data.client_id)

          if client and client.name == "sqls" then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end

          if client and client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
          end
        end,
      })

      vim.lsp.enable("lua_ls")
      vim.lsp.enable("gopls")
      vim.lsp.enable("pyright")
      vim.lsp.enable("ts_ls")
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
      vim.lsp.enable("mermaid_ls")
      vim.lsp.enable("sqls")

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
