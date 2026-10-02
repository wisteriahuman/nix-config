-- Markdown 用スラッシュコマンド（blink.cmp のソース）。行頭か空白の直後で "/" を打つと候補が出る。
local Kind = require("blink.cmp.types").CompletionItemKind

local commands = {
  { "h1", "見出し1", "# ${1}" },
  { "h2", "見出し2", "## ${1}" },
  { "h3", "見出し3", "### ${1}" },
  { "todo", "チェックボックス", "- [ ] ${1}" },
  { "bullet", "箇条書き", "- ${1}" },
  { "number", "番号付きリスト", "1. ${1}" },
  { "quote", "引用", "> ${1}" },
  { "code", "コードブロック", "```${1:lang}\n${2}\n```" },
  { "table", "表", "| ${1:列1} | ${2:列2} |\n| --- | --- |\n| ${3} | ${4} |" },
  { "note", "callout: NOTE", "> [!NOTE]\n> ${1}" },
  { "tip", "callout: TIP", "> [!TIP]\n> ${1}" },
  { "warning", "callout: WARNING", "> [!WARNING]\n> ${1}" },
  { "toggle", "折りたたみ", "<details>\n<summary>${1:タイトル}</summary>\n\n${2}\n\n</details>" },
  { "divider", "区切り線", "---" },
  { "link", "リンク", "[${1:text}](${2:url})" },
  { "image", "画像", "![${1:alt}](${2:path})" },
  -- mermaid は雛形を Vim の操作で直すので、挿入後はノーマルモードで図の1行目に置く
  { "mermaid-flow", "mermaid: フローチャート", "```mermaid\nflowchart TD\n  A[開始] --> B[処理]\n  B --> C[終了]\n```", true },
  {
    "mermaid-er",
    "mermaid: ER図",
    "```mermaid\nerDiagram\n  USER {\n    int id PK\n    string name\n  }\n  POST {\n    int id PK\n    int user_id FK\n  }\n\n  USER ||--o{ POST : writes\n```",
    true,
  },
  { "mermaid-seq", "mermaid: シーケンス図", "```mermaid\nsequenceDiagram\n  Client->>Server: request\n  Server-->>Client: response\n```", true },
  { "mermaid-class", "mermaid: クラス図", "```mermaid\nclassDiagram\n  class Name {\n    +field\n    +method()\n  }\n```", true },
  { "mermaid-state", "mermaid: 状態遷移図", "```mermaid\nstateDiagram-v2\n  [*] --> Idle\n  Idle --> Running : start\n  Running --> [*]\n```", true },
  { "mermaid-gantt", "mermaid: ガントチャート", "```mermaid\ngantt\n  dateFormat YYYY-MM-DD\n  section Phase\n  Task : 2026-10-01, 7d\n```", true },
  { "date", "今日の日付", function() return os.date("%Y-%m-%d") end },
}

local source = {}

function source.new()
  return setmetatable({}, { __index = source })
end

function source:enabled()
  return vim.bo.filetype == "markdown"
end

function source:get_trigger_characters()
  return { "/" }
end

function source:get_completions(ctx, callback)
  local row, col = ctx.cursor[1], ctx.cursor[2]
  local before = ctx.line:sub(1, col)
  local start = before:match("()/[%w%-]*$")
  -- a/b のようなパスの途中では出さない
  if not start or (start > 1 and not before:sub(start - 1, start - 1):match("%s")) then
    callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
    return
  end

  local range = {
    start = { line = row - 1, character = start - 1 },
    ["end"] = { line = row - 1, character = col },
  }
  local items = {}
  for _, c in ipairs(commands) do
    local body = type(c[3]) == "function" and c[3]() or c[3]
    table.insert(items, {
      label = c[1],
      labelDetails = { description = c[2] },
      filterText = c[1],
      kind = Kind.Snippet,
      insertTextFormat = c[4] and vim.lsp.protocol.InsertTextFormat.PlainText
        or vim.lsp.protocol.InsertTextFormat.Snippet,
      textEdit = { newText = body, range = range },
      data = { normal = c[4], row = row },
    })
  end
  callback({ items = items, is_incomplete_forward = false, is_incomplete_backward = false })
end

function source:execute(_, item, callback, default_implementation)
  default_implementation()
  if item.data.normal then
    -- stopinsert はカーソルを1つ左に戻すので、ノーマルモードに入ってから置き直す
    vim.api.nvim_create_autocmd("ModeChanged", {
      pattern = "*:n",
      once = true,
      callback = function()
        vim.api.nvim_win_set_cursor(0, { item.data.row + 2, 0 })
        vim.cmd("normal! ^")
      end,
    })
    vim.schedule(function()
      vim.cmd("stopinsert")
    end)
  end
  callback()
end

return source
