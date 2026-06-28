# coze-agent-files: 群文件操作参考

**这是 coze-project skill 的群文件操作参考。** 触发条件 / 协作流程 / 跨技能衔接见同目录 [`SKILL.md`](./SKILL.md); 群信息查询 (info / member / message) 见 [`coze-agent-query.md`](./coze-agent-query.md)。本文件讲**群文件 CRUD 的详细语法 + shell 引用细节**。

需要敲 `coze agent file ...` 时 Read 本文件。

## CLI 调用约束 (所有 `coze agent` 命令通用)

**前提**:
- `coze` 在 PATH (平台保证), 已登录
- 每个命令带 `--format json` (拿到可解析的 JSON 输出)
- 每个命令带 `--org-id "$account_id" --project-id "$group_id"` (从 `<coze-context>` 抄, 见 SKILL.md)

**输出信封分两类** (文件命令两类都有, 用对应字段判成功):

- **A 类 `{code, msg, data}`** → `file write` / `file edit`。成功是 `.code == 0`, 结果在 `.data`。
  ```json
  { "code": 0, "msg": "success", "data": { "file_path": "/x.md", "size": 6 } }
  ```
- **B 类 `{ok, ..., logid}`** → `file list` / `file read` / `file upload` / `file download`。成功是 **`.ok == true`**, 内容字段直接挂顶层。
  ```json
  { "ok": true, "project_file_path": "/x.md", "content": "..." }
  ```

**校验**: shell 退出码 == 0 **且** (A 类看 `.code == 0` / B 类看 `.ok == true`)。

`jq` 模板 (B 类 `file read` 为例; stderr 捕到文件):
```bash
err=$(mktemp)
out=$(coze agent file read --org-id "$account_id" --project-id "$group_id" \
        --project-file-path "$path" --format json 2>"$err") \
  || { cat "$err" >&2; rm -f "$err"; exit 1; }
rm -f "$err"
[ "$(echo "$out" | jq -r '.ok')" = "true" ] \
  || { echo "API error: $out" >&2; exit 1; }
echo "$out" | jq -r '.content'
```

> `$(...)` 只捕 stdout, CLI 的错误 JSON 走 stderr——用 `2>"$err"` 把 stderr 捕到文件, 失败时才看得到原因。

**错误码** (JSON 错误写 stderr, 非零退出):

| 代码 | 含义 | 怎么办 |
|---|---|---|
| `E1100` / `E1101` | 选项 / 子命令拼写问题 | 对照本文件改命令重试 |
| `E1102` / `E1103` | 缺必填参数 / 缺选项值 | 补齐参数重试 |
| `E2001` | 鉴权失败 (token 缺失/过期) | 让用户跑 `coze auth login` |
| `E5000` | 服务端错 / 无权限 | 确认带了 `--org-id`; 仍报则转给用户 |

## 群文件路径语义

群文件路径都是**绝对路径**, `/` 开头, 相对项目云盘根 (`/` 即根)。

路径参数有两个 flag, 按命令选用:

| 命令 | 路径 flag | 指向 |
|---|---|---|
| `file read` / `file write` / `file edit` / `file download` | `--project-file-path` | 具体**文件** |
| `file list` | `--project-dir` | **目录** (默认根) |
| `file upload` | `--project-dir` | 目标**目录** (默认根; 文件名沿用本地 basename) |

写法示例:
- 文件: `/example.md`
- 子目录: `/notes`
- 子目录下的文件: `/notes/example.md`

`file list` 返回的 `path` 字段形如 `/./example.md`; 后续 read / edit 用你自己的用户面向路径 (`/example.md`) 即可。

## 子命令一览

| 子命令 | 用途 | 信封 |
|---|---|---|
| `agent file list` | 列群文件 / 目录树 | B 类 `{ok}` |
| `agent file read` | 读群文件内容 | B 类 `{ok}` |
| `agent file write` | 创建 / 整文件覆盖 (从字符串内容) | A 类 `{code}` |
| `agent file edit` | 外科手术式修改 (replace / append) | A 类 `{code}` |
| `agent file upload` | **本地文件** → 群文件 (适合二进制 / 大文件 / 已有本地产物) | B 类 `{ok}` |
| `agent file download` | 群文件 → **本地文件** (适合二进制 / 想拿到本地处理) | B 类 `{ok}` |

下文 `$account_id` / `$group_id` 都指你从 `<coze-context>` 抄来的值。

## `agent file list` — 群文件目录列表

```bash
# 项目云盘根目录 (--project-dir 省略即列根)
coze agent file list --org-id "$account_id" --project-id "$group_id" --format json

# 特定子目录, 递归 5 层
coze agent file list \
  --org-id "$account_id" --project-id "$group_id" \
  --project-dir "/notes" \
  --depth 5 --format json
```

参数:
- `--project-dir`: 起始目录 (绝对路径, `/` 开头, e.g. `/notes`; 省略则列根)
- `--depth`: 递归深度 (默认 1, 即只列直接子项)

返回 B 类, 列表在 **`.files`** 下, 每项含:
- `path`: 绝对路径 (形如 `/./name`)
- `type`: `"file"` 或 `"dir"`

```bash
coze agent file list --org-id "$account_id" --project-id "$group_id" --depth 5 --format json \
  | jq -r '.files[] | "\(.type) \(.path)"'
```

## `agent file read` — 读群文件

```bash
# 整文件
coze agent file read \
  --org-id "$account_id" --project-id "$group_id" \
  --project-file-path "/example.md" --format json

# 仅第 1–20 行
coze agent file read \
  --org-id "$account_id" --project-id "$group_id" \
  --project-file-path "/example.md" \
  --offset 1 --limit 20 --format json
```

参数:
- `--project-file-path`: **必填**, 群文件绝对路径 (`/` 开头)
- `--offset`: 起始行号 (从 1 开始)
- `--limit`: 读多少行

返回 B 类:
- `.content`: 文件正文 (字符串, 直接挂顶层)
- `.project_file_path`: 回显的文件路径
- `.ok`: 成功标志

```bash
content=$(coze agent file read --org-id "$account_id" --project-id "$group_id" \
            --project-file-path "/example.md" --format json | jq -r '.content')
```

> 大文件探索时先读窗口 (`--offset` / `--limit`), 既省 token 又稳。

## `agent file write` — 创建或整文件覆盖

```bash
coze agent file write \
  --org-id "$account_id" --project-id "$group_id" \
  --project-file-path "/example.md" \
  --content "# title" --format json
```

参数:
- `--project-file-path`: **必填**, 群文件绝对路径 (`/` 开头); 不存在的中间目录后端会自动创建
- `--content`: **必填**, 整文件内容 (字符串)

返回 A 类: `.data.file_path` / `.data.size`。

`file write` 覆盖整个文件。适用场景:
- 新建文件 (e.g. 第一次沉淀本周周报)
- 文件结构整体重写 (确认要全覆盖)

只改一部分时用 `file edit` (见下), 既精确又避开 shell 引用长内容的麻烦。

## `agent file edit` — 外科手术式修改

任务是"编辑"或"更新"群文件时, 通常这个比 write 合适。按意图选模式 (`--mode` **必填**):

| 模式 | 用途 | 必需参数 |
|---|---|---|
| `replace_one` | 替换唯一字符串第一次出现。先读文件、有明确锚点的外科手术编辑首选。 | `--old-string`, `--new-string` |
| `replace_all` | 全局重命名 / 全局替换 (大小写敏感)。 | `--old-string`, `--new-string` |
| `append` | 文件末尾追加, 无前导换行 (直接接在最后一行尾部)。 | `--append-content` |
| `append_newline` | 文件末尾新起一行追加。**"追加新条目"选这个**。 | `--append-content` |

```bash
# 全局重命名 config (大小写敏感)
coze agent file edit \
  --org-id "$account_id" --project-id "$group_id" \
  --project-file-path "/config.md" \
  --mode replace_all \
  --old-string "model: gpt-4" --new-string "model: claude-sonnet-4-5" --format json

# 追加新 todo 条目 (另起一行)
coze agent file edit \
  --org-id "$account_id" --project-id "$group_id" \
  --project-file-path "/todo.md" \
  --mode append_newline \
  --append-content "- review PR #42" --format json
```

参数:
- `--project-file-path`: **必填**
- `--mode`: **必填**, 上表四选一
- `--old-string` / `--new-string`: replace 模式用
- `--append-content`: append 模式用

返回 A 类: `.data.file_path`。

**`replace_one` 用法关键点**:
- 先 `file read` 看一下, 找出在文件里明显唯一的 `--old-string` 锚点
- 把锚点选得比要替换的核心多带一两行上下文, 确保唯一

**`append` vs `append_newline`**:
- 想在已有最后一行尾巴继续接 → `append` (e.g. `last` + `<X>` → `last<X>`)
- 想起新一行 (新 todo、新章节) → `append_newline`

## `agent file upload` — 本地文件上传到群

把**本地已有文件**整个传进群文件 (write 是从字符串内容创建; upload 是传本地文件流, 不解析内容)。

```bash
coze agent file upload \
  --org-id "$account_id" --project-id "$group_id" \
  --local-file-path ./report.md \
  --project-dir /reports \
  --format json
```

参数:
- `--local-file-path`: **必填**, 本地文件路径 (OS 本地 fs 路径, 相对当前目录或绝对路径)
- `--project-dir`: 目标群目录 (省略默认根; 上传后文件名沿用本地 basename)

返回 B 类: `.project_file_path` (上传后的群内路径)。

**适用场景**:
- 你刚生成的本地文件 (e.g. `coze generate image` 出图后) 沉淀到群
- 用户给你本地路径让你把文件放到群里
- 二进制 / 大文件——直接传文件流

**典型用法**:

```bash
# 上传报告到群的 /reports/ 子目录
coze agent file upload \
  --org-id "$account_id" --project-id "$group_id" \
  --local-file-path ./Q4-report.pdf --project-dir /reports --format json

# 上传截图到群文件根目录 (--project-dir 省略即根)
coze agent file upload \
  --org-id "$account_id" --project-id "$group_id" \
  --local-file-path /tmp/screenshot.png --format json
```

## `agent file download` — 从群下载到本地

把**群文件**整个落到本地 fs (read 返回 JSON 里的 `.content` 字符串, 适合小文本; download 适合二进制 / 大文件 / 需要本地工具加工的产物)。

```bash
coze agent file download \
  --org-id "$account_id" --project-id "$group_id" \
  --project-file-path /reports/report.md \
  --format json
```

参数:
- `--project-file-path`: **必填**, 群文件路径 (要下载哪个文件)

download 把文件落到**当前工作目录**, 文件名沿用群文件 basename。要放到指定目录, 先 `cd` 过去再下载。返回 B 类: `.local_file_path` (实际落盘的绝对路径)。

**适用场景**:
- 用户在群里上传了 PDF / 图片, 你想本地处理 (OCR / 提取 / 转格式)
- 群里的二进制文件——download 拿到原始字节
- 处理完想再传回去——download + 本地处理 + upload 回去

**典型用法**:

```bash
# 下载到指定目录 (先建目录并 cd, download 落当前目录)
mkdir -p ./downloads && cd ./downloads
coze agent file download \
  --org-id "$account_id" --project-id "$group_id" \
  --project-file-path /reports/Q4-report.pdf --format json
# 文件落到 ./downloads/Q4-report.pdf
cd -
```

**download + 本地处理 + upload 回流**:

```bash
# 1. 下载 (落到 /tmp)
cd /tmp
coze agent file download --org-id "$O" --project-id "$P" \
  --project-file-path /raw/scan.pdf --format json

# 2. 本地处理 (e.g. OCR)
ocrmypdf /tmp/scan.pdf /tmp/scan-ocr.pdf

# 3. 上传回群
coze agent file upload --org-id "$O" --project-id "$P" \
  --local-file-path /tmp/scan-ocr.pdf --project-dir /processed --format json
```

## Shell 引用提示 (主要在 file write/edit)

`--content` / `--old-string` / `--new-string` / `--append-content` 都是普通 shell 参数, 引用要小心:

- **纯 ASCII 无引号无 `$`**: 双引号即可 — `--content "hello world"`
- **含双引号或 shell 元字符 (`$`、` ` `、`!`)**: 单引号整段, 或用 `$'...'` C 风格字面量
- **多行内容**: heredoc 灌变量最稳:
  ```bash
  content=$(cat <<'EOF'
  line 1
  line 2 with "quotes" and $vars not expanded
  EOF
  )
  coze agent file write --org-id "$account_id" --project-id "$group_id" \
    --project-file-path /a.md --content "$content" --format json
  ```
  (`<<'EOF'` 加引号让变量在 heredoc 里按字面量处理)
- **超长内容 (几百 KB 起)**: 命令行参数长度可能爆 (`E2BIG`)。先 `file write` 写骨架, 再 `file edit append_newline` 增量补
- **内容里有反引号 / `$(...)`**: 走单引号或 heredoc, 让 shell 按字面量处理
