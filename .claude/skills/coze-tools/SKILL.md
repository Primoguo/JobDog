---
name: coze-tools
description: '需要从互联网获取信息 (搜索关键词、抓取 URL) 或生成媒体 (图片、音频、视频) 时使用。触发: 问时事/最新消息/训练截止后的事实, 给 URL 让你看/总结网页, 要求出图/朗读/做视频。'
---

# coze-tools: Coze CLI 工具集

`coze` CLI 提供两组 agent 自身能力之外的工具:

- **网页工具** (`coze agent web ...`): 突破训练截止时间, 拿互联网信息
- **媒体生成** (`coze generate ...`): 文本生成图片 / 音频 / 视频

单聊和群聊都适用。

## 触发条件 (满足任一就考虑用)

| 用户意图 | 用哪个命令 |
|---|---|
| 问时事 / 最新消息 / 训练截止后的事实 | `coze agent web search` |
| 让你看 URL / 总结网页 | `coze agent web fetch` |
| 找官方文档 / 权威来源核实 | `web search` + `web fetch` |
| 画图 / 出图 / 生成插图 | `coze generate image` |
| 文字转语音 / TTS / 朗读 | `coze generate audio` |
| 生成视频 / 动画 | `coze generate video create` |

## 不使用此技能的时机

- 一般概念 / 编程问题——agent 已知就直接答, 别浪费 API
- 简单可由对话上下文回答的问题

## 从 `<coze-context>` 提取参数 (web 工具需要)

`<coze-context>` 有单聊 / 群聊两种格式 (单聊没有 `group_id`):

**单聊消息**:
```
<coze-context>
单聊消息
account_id: 7639...001
agent_id: 7639...571
session_id: 7639...999
</coze-context>
```

**群聊消息**:
```
<coze-context>
群聊消息
account_id: 7639...001
agent_id: 7639...571
session_id: 7639...999
group_id: 7639...888
</coze-context>
```

参数映射:

| 字段 | `web` 命令 | `generate` 命令 |
|---|---|---|
| `agent_id` | **必带** `--agent-id` | 不用 |
| `account_id` | **必带** `--org-id` | 通常不用 (有默认配置, override 时才传 `--org-id`) |
| `group_id` (有则) | 群聊**必带** `--project-id` | 不用 (generate 用 `--space-id`, 通常不用传) |

## 两个命令家族的参数规矩对比

两个家族的 flag 规矩**完全不同**, 不要混用:

| 家族 | `--json` | `--agent-id` | 项目维度 |
|---|---|---|---|
| `coze agent web *` | 不用 | **必带** | `--project-id` (群聊带, 单聊不带) |
| `coze generate *` | 不用 (用 `--format json/text`) | 不用 | `--space-id` (通常不用) |

下文 `$A` / `$O` / `$P` 分别指 `$agent_id` / `$account_id` / `$group_id`。

---

# 网页工具 (`coze agent web`)

## `web search` — 关键词搜索

**单聊**:
```bash
coze agent web search \
  --agent-id "$A" --org-id "$O" \
  --query-list '["关键词"]'
```

**群聊** (加 `--project-id`):
```bash
coze agent web search \
  --agent-id "$A" --org-id "$O" --project-id "$P" \
  --query-list '["关键词"]'
```

参数:
- `--query-list`: **必填**, **JSON 数组字符串** (一次可以多查询, 后端逐个搜索并合并结果)
  - 单查询: `'["特朗普"]'`
  - 多查询: `'["GPT-5 发布", "OpenAI 最新动态"]'`
  - **上限 5 个 query**, 超过会被 CLI 拒绝
- shell 引用要点: 整个 JSON **用单引号包**, 内部字符串用 JSON 标准的双引号——`'["..."]'` 不能写成 `"[\"...\"]"`, 也不能写 `--query-list 特朗普` (会被当成多个 arg)

**典型用法**:

```bash
# 单查询
coze agent web search --agent-id "$A" --org-id "$O" \
  --query-list '["特朗普 最近"]'

# 多角度查同一事件 (一次调用合并多查询, 最多 5 个)
coze agent web search --agent-id "$A" --org-id "$O" \
  --query-list '["GPT-5 发布", "GPT-5 价格", "GPT-5 vs Claude"]'
```

## `web fetch` — 单 URL 抓取

```bash
# 单聊
coze agent web fetch \
  --agent-id "$A" --org-id "$O" \
  --url "https://example.com/article"

# 群聊
coze agent web fetch \
  --agent-id "$A" --org-id "$O" --project-id "$P" \
  --url "https://example.com/article"
```

参数:
- `--url`: **必填**, 完整 URL (含 `http://` 或 `https://` scheme)

## 工作流: 搜索 → 抓取 → 摘要

```bash
# 群聊场景提前定义 P_FLAG="--project-id $P"; 单聊场景 P_FLAG=""

# 1. 搜索拿候选
coze agent web search --agent-id "$A" --org-id "$O" $P_FLAG \
  --query-list '["问题关键词"]' > /tmp/search.out

# 2. 看输出结构 (首次调用必看)
cat /tmp/search.out

# 3. 选最权威 / 最相关那个 URL, fetch 全文
coze agent web fetch --agent-id "$A" --org-id "$O" $P_FLAG \
  --url "<选中的 URL>"
```

## 何时不要 fetch

- 搜索结果的 snippet 已经够回答问题 → 不用 fetch (省 API + 更快)
- URL 是 PDF / 视频 / 二进制 → fetch 大概率拿不到有用文本
- 需要登录 / paywall 的页面 → 大概率失败

## 给用户呈现 web 结果的姿势

- **永远引用来源**: 把 URL / 网站名贴在事实后面, 让用户能自己核实 ("根据 example.com 报道...")
- **不要 100% 复读**: 摘要 + 引用关键句, 不要把 fetch 回来的全文直接倒给用户
- **多源矛盾就说**: 来源 A / B 说法不一时老实说"A 说 X, B 说 Y", 不要硬选一个
- **加时效标注**: "截至搜索时" / "搜索结果显示, 实际可能已变"

---

# 媒体生成工具 (`coze generate`)

## CLI 调用约束

跟 `coze agent ...` **完全不同**, 别套老规矩:

- 顶层命令是 `coze generate ...`, **不是** `coze agent generate ...`
- **用 `--space-id`**, **不是** `--project-id` (而且通常不用传, 走默认配置)
- **没有 `--agent-id`** flag
- **没有 `--json`** flag (用 `--format json/text`, 默认 `text` 人话格式)
- `--output-path <dir>` 指定生成文件保存目录 (**强烈建议传**, 不传找不到文件)

**通用 shell**:
```bash
coze generate <subcommand> "<prompt-or-text>" \
  [--output-path <dir>] \
  [--format json]
```

shell 退出码 0 表示成功 (生成完成); 非零失败, stderr 有错误描述。

## `generate image` — 文生图

```bash
coze generate image "<prompt>" --output-path ./out
```

参数:
- 位置参数: 图片描述 prompt (中英都行)
- `--output-path`: 生成文件落到这个目录 (**强烈建议传**)
- `--format`: 默认 `text`; 想 jq 提取就 `--format json`

**典型用法**:

```bash
# 基本 (用户说"画一只穿西装的猫")
coze generate image "一只穿西装的猫" --output-path ./out

# 结构化输出 (后续从输出里提取文件路径)
coze generate image "一只穿西装的猫" --output-path ./out --format json
```

> 首次跑一次, 看 `./out/` 下生成的文件名 / 扩展名 (通常 `.png` 或 `.jpg`)。

## `generate audio` — 文生音 / TTS

```bash
coze generate audio "<text>" --output-path ./out
```

参数:
- 位置参数: 要朗读的文本
- `--output-path`: 音频文件保存目录

**典型用法**:

```bash
coze generate audio "你好, 这是测试" --output-path ./out
# 生成的音频通常是 .mp3 或 .wav, 看实际产物
```

## `generate video create` — 文生视频

```bash
coze generate video create "<prompt>" --output-path ./out
```

⚠️ 注意是 **`video create`** (双层 subcommand), 不能漏 `create`。

```bash
coze generate video create "一只跳舞的狗" --output-path ./out
```

> 视频生成**比图片 / 音频慢很多** (几十秒到几分钟), 不要让用户干等——先告诉用户"正在生成, 大概 X 分钟", 再启动命令。

---

## 不要做的事

**通用**:
- ❌ 简单问题硬上工具——agent 已知就直接答, 别浪费 API
- ❌ 凭印象猜字段名 / 输出格式——以实际为准, 首次调用先看

**网页工具**:
- ❌ 不带 `--agent-id`——web 工具按 agent 鉴权, 没这个 flag 命令直接失败
- ❌ 加 `--json`——web 不需要
- ❌ 单聊场景硬塞 `--project-id`——没 group_id, 别编, 直接省这个 flag
- ❌ 群聊场景忘加 `--project-id`——群里要带, 不带可能路由不对
- ❌ `--query-list` 写错 JSON——是 JSON 数组字符串, 最常见错: `--query-list "特朗普"` (应为 `'["特朗普"]'`)
- ❌ `--query-list` 一次塞 > 5 个 query——硬上限, 多了 CLI 拒绝; 需要更多就拆成多次 search 调用
- ❌ 结果不引用来源——用户没法核实, 像幻觉
- ❌ fetch 回的全文直接倒给用户——摘要 + 关键句引用

**媒体生成**:
- ❌ 写成 `coze agent generate ...`——它是顶层 `coze generate ...`
- ❌ 用 `--project-id`——generate 用 `--space-id` (而且通常不用传)
- ❌ 加 `--agent-id`——generate 不需要
- ❌ 加 `--json`——generate 用 `--format json/text`
- ❌ 不传 `--output-path`——不传不知道文件落哪了
- ❌ `video create` 写成 `video "<prompt>"`——video 是双层 subcommand, 漏 `create` 直接失败
- ❌ 同步等视频生成不告诉用户——视频慢, 先告诉用户预估时间, 别让用户干等
