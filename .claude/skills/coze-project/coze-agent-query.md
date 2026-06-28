# coze-agent-query: 群信息查询参考

**这是 coze-project skill 的群信息查询参考。** 触发条件 / 协作流程 / 跨技能衔接见同目录 [`SKILL.md`](./SKILL.md); 群文件 CRUD 操作见 [`coze-agent-files.md`](./coze-agent-files.md)。本文件讲**项目元数据 / 群成员 / 群消息历史查询的详细语法**。

需要敲 `coze agent info` / `member` / `message` 时 Read 本文件。

## CLI 调用约束 (所有 `coze agent` 命令通用)

**前提**:
- `coze` 在 PATH (平台保证), 已登录
- 每个命令带 `--format json` (拿到可解析的 JSON 输出)
- 每个命令带 `--org-id "$account_id" --project-id "$group_id"` (从 `<coze-context>` 抄, 见 SKILL.md)

**输出信封分两类** (stdout 成功) — 用对应的字段判成功:

- **A 类 `{code, msg, data}`**: `info` / `member list` / `message list` (以及文件的 `write` / `edit`)。成功是 `.code == 0`, 结果在 `.data`。
  ```json
  { "code": 0, "msg": "", "data": { ... } }
  ```
- **B 类 `{ok, ..., logid}`**: 文件的 `list` / `read` / `upload` / `download` (见 files 参考)。成功是 `.ok == true`, 内容字段直接挂顶层。

本文件三条命令 (`info` / `member list` / `message list`) **都是 A 类**, 校验 `.code == 0`。

**校验两层才用结果**: shell 退出码 == 0 **且** `.code == 0`。

`jq` 模板 (stderr 捕到文件, 失败时能看到原因):
```bash
err=$(mktemp)
out=$(coze agent info --org-id "$account_id" --project-id "$group_id" --format json 2>"$err") \
  || { cat "$err" >&2; rm -f "$err"; exit 1; }
rm -f "$err"
[ "$(echo "$out" | jq -r '.code')" = "0" ] \
  || { echo "API error: $out" >&2; exit 1; }
echo "$out" | jq '.data'
```

> `$(...)` 只捕 stdout, CLI 的错误 JSON 走 stderr——用 `2>"$err"` 把 stderr 捕到文件, 失败时才看得到原因。

**错误码** (JSON 错误写 stderr, 非零退出):

| 代码 | 含义 | 怎么办 |
|---|---|---|
| `E1100` / `E1101` | 选项 / 子命令拼写问题 | 对照本文件改命令重试 |
| `E1102` / `E1103` | 缺必填参数 / 缺选项值 | 补齐参数重试 |
| `E2001` | 鉴权失败 (token 缺失/过期) | 让用户跑 `coze auth login` |
| `E5000` | 服务端错 / 无权限 | 确认带了 `--org-id`; 仍报则把消息转给用户 |

## 子命令一览

| 子命令 | 用途 | 用户提问示例 |
|---|---|---|
| `agent info` | 项目元数据 | "这个项目是啥", "项目设置" |
| `agent member list` | 群成员 | "谁在群里", "有谁的权限" |
| `agent message list` | 群聊历史 | "上次说啥", "之前讨论过的结论" |

下文 `$account_id` / `$group_id` 都指你从 `<coze-context>` 抄来的值。

## `agent info` — 项目元数据

```bash
coze agent info --org-id "$account_id" --project-id "$group_id" --format json
```

参数: `--project-id` 必填; `--org-id` 必带。

返回 A 类信封, 项目记录在 **`.data.session`** 下:
- `.data.session.name`: 项目 / 群名
- `.data.session.desc`: 项目描述
- `.data.session.owner_uid`: 所有者 user_id (想要名字去 `member list` 里按 uid 找)
- `.data.session.account_id`: 所属组织
- `.data.session.create_time` / `.data.session.last_msg_time`: 毫秒时间戳字符串
- `.data.session.member_count` / `.data.session.agent_count`: 人数 / agent 数

**典型用法**:

```bash
# 拿项目名
name=$(coze agent info --org-id "$account_id" --project-id "$group_id" --format json \
       | jq -r '.data.session.name')

# 整个元数据展示给用户
coze agent info --org-id "$account_id" --project-id "$group_id" --format json | jq '.data.session'
```

## `agent member list` — 群成员

```bash
coze agent member list --org-id "$account_id" --project-id "$group_id" --format json
```

参数: `--project-id` 必填; `--org-id` 必带。

返回 A 类信封, 成员列表在 **`.data.members`** 下, 每项含:
- `user_id`: 用户 ID
- `nickname`: 名字
- `user_type`: `1` = 真人, `2` = agent (claw)
- `user_level`: 权限等级 (数字, e.g. `1` / `10`, 等级越高权限越大)
- `account_id` / `created_at` 等; agent 成员还带 `claw_id` 和 `owner_member` (归属的真人)

汇总数在 `.data.member_count` / `.data.agent_count`。所有者对照 `info` 的 `.data.session.owner_uid`。

**典型用法**:

```bash
# 列出所有成员名 + 等级
coze agent member list --org-id "$account_id" --project-id "$group_id" --format json \
  | jq -r '.data.members[] | "\(.user_level): \(.nickname)"'

# 只看真人成员
coze agent member list --org-id "$account_id" --project-id "$group_id" --format json \
  | jq -r '.data.members[] | select(.user_type == 1) | .nickname'
```

## `agent message list` — 群聊历史

```bash
# 最近 5 条
coze agent message list --org-id "$account_id" --project-id "$group_id" --size 5 --format json

# 最旧的在前, 包含被引用的消息
coze agent message list --org-id "$account_id" --project-id "$group_id" \
  --asc-mode --need-reference --format json

# 下一页
coze agent message list --org-id "$account_id" --project-id "$group_id" \
  --cursor "$next_cursor" --format json
```

参数:
- `--size`: 单页消息数, 上限 **10**。要拿更多就用 `--cursor` 翻页累积。
- `--asc-mode`: 翻为最旧在前 (默认最新在前)
- `--need-reference`: 内联包含被引用 / 被回复的消息
- `--conversation-id`: 项目里有多个会话时过滤到单个 (顶层群消息用 `0`)

返回 A 类信封:
- `.data.messages`: 消息数组, 每项含 `id` / `source` / `content` / `create_time` / `sender` / `message_type` / `conversation_id` 等 (有引用 / reaction 时还带 `at_members` / `reaction` 等)
- `.data.next_cursor`: 下一页游标 (字符串)

**翻页累积 pattern** (用户要"最近 30 条"):

```bash
A="$account_id"; P="$group_id"
all_msgs="[]"
cursor=""
remaining=30

while [ "$remaining" -gt 0 ]; do
  size=$([ "$remaining" -gt 10 ] && echo 10 || echo "$remaining")
  if [ -z "$cursor" ]; then
    page=$(coze agent message list --org-id "$A" --project-id "$P" --size "$size" --format json)
  else
    page=$(coze agent message list --org-id "$A" --project-id "$P" --size "$size" --cursor "$cursor" --format json)
  fi
  # 信封校验 (A 类, 见顶部"CLI 调用约束")
  [ "$(echo "$page" | jq -r '.code')" = "0" ] || break

  all_msgs=$(echo "$all_msgs $page" | jq -s '.[0] + .[1].data.messages')
  cursor=$(echo "$page" | jq -r '.data.next_cursor // ""')
  [ -z "$cursor" ] || [ "$cursor" = "null" ] && break

  remaining=$((remaining - size))
done

echo "$all_msgs" | jq '.'
```

**追溯讨论结论的常见姿势** (用户问"上次怎么决定的"):

1. `--asc-mode` 从最旧拉, 保留时间顺序
2. `--need-reference` 让"A 引用 B 然后说 ..."的上下文连贯
3. `--cursor` 翻页累积到一个合理深度 (e.g. 30-50 条)
4. 把关键节点 (决策、结论、行动项) 摘要给用户
