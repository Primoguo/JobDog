---
name: coze-agent
version: 1.0.0
description: "Coze Agent 授权流程控制：强制前台完成 OAuth 授权、防止未授权启动后台任务导致全链路失败。当 Agent 需要执行任何需要认证的 Coze CLI 操作时触发，确保在启动后台任务前已完成授权。"
metadata:
  requires:
    bins: ["coze"]
  cliHelp: "coze auth --help"
---

# Coze Agent 授权流程控制

> **前置条件：** 本模块是所有其他业务模块的**前置守卫**，必须最先执行。
> **核心目标：** 确保 Agent 在执行任何后台任务前，**必须先在前台完成 OAuth 授权流程**。

## 核心问题

### 致命错误：未授权直接进入后台任务

**问题场景：**
```
用户：用 Coze CLI 帮我生成一段语音

Agent（错误做法）：
1. 直接创建后台任务 → 执行 coze generate audio ...
2. 后台报错：[Auth] No API token found
3. 整个任务链失败，用户等待后收到无意义错误信息
```

**根本原因分析：**

- Agent 在未确认授权状态的情况下就启动了需要认证的后台任务
- 后台任务无法与用户交互（无法提示授权链接或等待浏览器操作）
- 导致任务链全部失败，用户体验极差，且浪费计算资源

## 强制授权流程（三步走）

### Step 1：检查授权状态（任何操作前必做）

```bash
coze auth status --format json
```

**返回值判断标准：**

| 状态值 | 含义 | 后续操作 |
|--------|------|---------|
| `active` | 已授权，Token 有效 | ✅ 可直接进入后续操作 |
| `expired` | Token 过期 | ⚠️ CLI 会尝试自动刷新；若刷新失败则进入 Step 2 |
| `not_logged_in` | 未登录 | ❌ 必须进入 Step 2 完成授权 |

### Step 2：前台获取授权链接（唯一目的）

**关键规则（必须严格遵守）：**

- ✅ **前台命令执行**（禁止使用 `background: true` 或 `&`）
- ✅ **唯一目标**：从输出中提取授权链接和设备码（Code）
- ✅ **立即返回**：拿到链接后立刻停止等待，返回给用户
- ❌ **禁止行为**：不要在此步骤创建任何后台任务或启动后续操作

```bash
# 前台执行（合并捕获 stderr 和 stdout）
coze auth login 2>&1
```

**输出解析要点：**

- 设备码（Code）通常输出在 stderr，必须用 `2>&1` 合并输出流才能完整捕获
- Code 格式示例：`ABC-DEF-GHI`（由大写字母和数字组成）
- 完整授权链接格式：`https://www.coze.cn/oauth/device-activation?user_code=ABC-DEF-GHI`
- **有效期限制**：Code 只有 **10 分钟有效期**，超时需重新获取

**提效技巧：**

将 Code 拼接到授权链接中直接返回给用户，免去手动输入步骤：

```
请点击以下链接完成 Coze CLI 授权（10分钟内有效）：
https://www.coze.cn/oauth/device-activation?user_code=ABC-DEF-GHI
```

### Step 3：等待用户完成授权后再新建后台任务

**关键规则（必须严格遵守）：**

- ✅ **止步于 Step 2**：返回链接后不创建任何后台任务
- ✅ **等待用户反馈**：用户明确告知"已授权"或重新检查 `coze auth status`
- ✅ **显式验证**：确认 `status: active` 后才允许新建后台任务
- ❌ **禁止假设**：不能假设用户会完成授权就直接启动任务

**验证命令：**
```bash
coze auth status --format json
# 确认返回 { "status": "active" } 后方可继续
```

## Agent 禁止行为清单

以下行为会导致任务链失败或用户体验极差，Agent 必须**严格避免**：

| 编号 | 禁止行为 | 后果 |
|------|---------|------|
| ❌ 1 | 未检查授权状态就直接执行需要认证的命令 | 任务立即失败，报 Auth 错误 |
| ❌ 2 | 使用后台模式（`&`/`nohup`）执行 `coze auth login` | 无法提取授权链接，用户无法完成授权 |
| ❌ 3 | 拿到授权链接后继续等待或创建后台任务 | 违反"立即返回"原则，可能阻塞超时 |
| ❌ 4 | 假设用户已完成授权就启动新任务 | 可能因未授权再次失败 |
| ❌ 5 | 在授权未完成时调用 `coze code project create` / `coze generate` / `coze deploy` 等 | 全链路失败 |

## 正确 vs 错误流程对比

### 场景：用户要求使用 Coze CLI 生成图片

**❌ 错误流程（典型错误）：**

```
Step 1: 不检查授权，直接执行
  → 后台执行: coze generate image "描述" --output-path /tmp/img
  
Step 2: 后台报错
  → [Auth] No API token found
  
Step 3: 尝试补救（但已晚）
  → 用户看到错误信息，体验差
```

**✅ 正确流程（三步走）：**

```
Phase 1 - 授权阶段（前台交互）：
  Step 1: coze auth status → 发现 not_logged_in
  Step 2: 前台执行 coze auth login 2>&1 → 提取到 Code: XYZ-123
  Step 3: 立即返回用户："请点击 https://... 完成授权"

Phase 2 - 等待确认：
  → 用户回复"已完成授权"

Phase 3 - 验证并新建后台任务：
  Step 1: coze auth status → 确认 active
  Step 2: 新建后台任务: coze generate image ... (此时可安全使用后台)
```

## 典型场景示例

### 示例 1：用户首次使用 Coze CLI

```
用户请求：帮我用 Coze CLI 生成一张图片

Agent 执行：
1️⃣ [Step 1] 执行授权状态检查
   命令: coze auth status --format json
   结果: { status: "not_logged_in", user_id: null }

2️⃣ [Step 2] 前台执行登录命令
   命令: coze auth login 2>&1
   输出: ... user_code=XYZ-123-456 ...
   
3️⃣ 提取并返回用户
   回复: 请先完成 Coze CLI 授权（10分钟内有效）：
         https://www.coze.cn/oauth/device-activation?user_code=XYZ-123-456
   
4️⃣ 止步于此，不创建任何任务

5️⃣ 用户回复："已授权"

6️⃣ [Step 3] 验证并启动
   验证: coze auth status --format json → { status: "active" }
   启动: 新建后台任务执行 coze generate image ...
```

### 示例 2：Token 过期场景

```
Agent 执行：
1️⃣ [Step 1] 检查状态
   结果: { status: "expired", token_expires_at: "2024-01-01T00:00:00Z" }

2️⃣ 注意：CLI 会尝试自动刷新 Token
   - 若刷新成功：直接继续，无需用户干预
   - 若刷新失败（仍为 expired/not_logged_in）：进入 Step 2 授权流程
```

### 示例 3：长耗时任务的正确拆分

```
用户请求：用 Coze CLI 创建项目并部署一个应用

✅ Phase 1 - 授权阶段（前台，必须最先完成）：
  - 检查状态 → 获取授权链接 → 返回用户 → 等待确认

✅ Phase 2 - 项目创建阶段（后台，授权通过后）：
  - coze code project create ...

✅ Phase 3 - 开发阶段（后台）：
  - coze code message send ...

✅ Phase 4 - 部署阶段（后台）：
  - coze deploy <project-id> ...

❌ 错误做法：一口气执行所有步骤（包括未授权的后台部署）
```

## 避坑指南

### 坑 1：OAuth 链接输出位置异常

- **现象**：授权链接和设备码通常输出在 `stderr`，不是 stdout
- **解决**：必须用 `2>&1` 合并输出流，否则可能遗漏关键信息

### 坑 2：设备码有效期短

- **现象**：Code 只有 **10 分钟有效期**（注意不同版本可能为 5 分钟）
- **解决**：立即返回给用户，不要在本地缓存或延迟发送

### 坑 3：前台阻塞风险

- **现象**：`coze auth login` 会前台阻塞等待用户浏览器完成授权
- **解决**：一旦从输出中提取到链接就终止该进程（Ctrl+C 或 kill），不要一直等

### 坑 4：组织/空间上下文丢失

- **现象**：切换组织会清空 Space ID，可能导致权限错误
- **解决**：授权完成后若遇到权限问题，按顺序检查：
  ```bash
  coze config list          # 查看当前配置
  coze organization list    # 查看可用组织
  coze space list           # 查看当前组织下的空间
  ```

## 快速决策树

```
需要执行 Coze CLI 操作？
│
├─ 否 → 使用其他能力，无需处理授权
│
└─ 是 → 进入授权守卫流程：
   │
   ├─ 已知授权状态？
   │  ├─ 否 → coze auth status （检查）
   │  └─ 是 → 继续判断
   │     │
   │     ├─ active → ✅ 可直接执行（可安全使用后台模式）
   │     └─ expired / not_logged_in → 进入前台授权流程
   │        │
   │        ├─ 前台执行：coze auth login 2>&1
   │        ├─ 提取 Code + 拼接完整授权链接
   │        ├─ 立即返回用户（终止当前进程）
   │        └─ 等待用户确认 → 验证状态 → 新建后台任务
```

## 与其他模块的协作关系

本模块是所有业务模块的**第 0 步前置守卫**：

| 执行顺序 | 模块名称 | 触发条件 | 是否需要授权 |
|---------|---------|---------|:----------:|
| **第 0 步（前置）** | **coze-agent (本文档)** | **任何 Coze CLI 操作前必须先执行此模块** | - |
| 第 1 步 | SKILL.md | 基础配置与全局原则 | - |
| 第 2 步 | coze-generate | 生成图片/音频/视频 | ✅ 需要 |
| 第 3 步 | coze-code | 创建项目/开发/部署 | ✅ 需要 |
| 第 4 步 | coze-file | 上传文件获取在线链接 | ✅ 需要 |

**核心原则：只有 coze-agent 通过（确认 active），才允许调用后续模块的后台任务功能！**

## 关键提醒

1. **授权是单点故障源**：未授权 = 所有后台任务必定失败
2. **前台交互不可省略**：OAuth 需要用户在浏览器操作，Agent 无法替代
3. **立即返回是关键**：不要尝试优化或延迟，拿到链接就返回
4. **验证后再行动**：用户说"完成了" ≠ 真的完成了，必须用命令验证
5. **每个新任务都要检查**：不要复用旧的授权状态判断结果
