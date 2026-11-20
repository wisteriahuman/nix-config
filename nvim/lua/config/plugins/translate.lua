local translate_code = require("config.translate_code")

return {
  {
    "uga-rosa/translate.nvim",
    event = "VeryLazy",
    config = function()
      local languages = { JA = "Japanese", EN = "English" }

      -- remote_host があればそのホストの plamo-translate サーバーへ ssh で訳させる。ローカルなら nil
      local function plamo_command(remote_host)
        return {
          cmd = function(lines, command_args)
            -- 逐次出力だと最初の断片で結果が確定してしまう
            local args = { "--no-stream", "--to", languages[command_args.target:upper()] or command_args.target }
            if command_args.source then
              vim.list_extend(args, { "--from", languages[command_args.source:upper()] or command_args.source })
            end
            -- 先頭が "-" の文でもオプションと誤読されないよう "=" でつなぐ
            table.insert(args, "--input=" .. table.concat(lines, "\n"))
            -- 訳文と末尾の改行が別の断片で届き、空の断片が結果を上書きする。$(...) で改行を落として1回で出す
            if remote_host then
              local quoted = table.concat(vim.tbl_map(vim.fn.shellescape, args), " ")
              local script = 'printf %s "$(~/.local/bin/plamo-translate ' .. quoted .. ')"'
              return "ssh", { "-o", "BatchMode=yes", "-o", "ConnectTimeout=5", remote_host, script }
            end
            return "sh", vim.list_extend({ "-c", 'printf %s "$(plamo-translate "$@")"', "sh" }, args)
          end,
          complete_list = function()
            return vim.tbl_keys(languages)
          end,
        }
      end

      -- 比較用に `-command=deepl_free` でも訳せるようにしておく
      vim.g.deepl_api_auth_key = vim.fn.getenv("DEEPL_API_KEY")

      require("translate").setup({
        default = {
          parse_before = "trim,split_case,natural",
          command = "plamo",
          parse_after = "plamo,head",
        },
        command = {
          plamo = plamo_command("surface"),
          plamo_local = plamo_command(),
        },
        parse_after = {
          plamo = {
            -- replace.after が先に走り、文字列が {文字列} に包まれて届く
            cmd = function(text)
              if type(text) == "table" then
                text = table.concat(text, "\n")
              end
              return vim.split(vim.trim(text), "\n")
            end,
          },
        },
        parse_before = {
          split_case = translate_code.split_case,
          code = translate_code.code,
        },
        preset = {
          output = {
            floating = {
              -- ホバー (zindex=50) より手前に翻訳結果を表示する。
              zindex = 80,
            },
            split = {
              append = true,
            },
          },
        },
      })

      local map = vim.keymap.set
      map("n", "<leader>tj", "<cmd>Translate JA<CR>", { desc = "日本語に翻訳" })
      map("n", "<leader>te", "<cmd>Translate EN<CR>", { desc = "英語に翻訳" })
      -- <cmd> だと移動なしの V で選択範囲を取り損ねる
      map("x", "<leader>tj", ":Translate JA<CR>", { desc = "日本語に翻訳" })
      map("x", "<leader>te", ":Translate EN<CR>", { desc = "英語に翻訳" })
      map("n", "<leader>tc", "<cmd>Translate JA -parse_before=trim,code<CR>", { desc = "コードを日本語に翻訳" })
      map("x", "<leader>tc", ":Translate JA -parse_before=trim,code<CR>", { desc = "コードを日本語に翻訳" })
    end,
  },
}
