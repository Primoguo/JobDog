---
name: technical-solution-blueprint
description: 当用户需要中文技术方案、系统设计、架构设计、技术选型、容量规划、压测方案、风险降级、实施路线图、工程设计评审文档时使用；输入可来自业务目标、需求说明、代码仓库或调研材料，默认面向中文用户输出可评审、可落地的技术方案。
---

# Technical Solution Blueprint

## Core Rules

Produce a review-ready engineering document, not a generic architecture article.

- Start from the business goal, constraints, current system, and measurable success criteria.
- Separate facts, assumptions, recommendations, and unknowns. Never invent traffic, latency, cost, benchmark, staffing, or risk data.
- Prefer local repository files, internal docs, and user-provided material before external research. Use official or primary sources when web research is needed.
- Ask one focused question only when a blocker prevents a useful first pass. Otherwise continue with explicit assumptions.
- Record every important source or input in an evidence ledger.
- For each major decision, show the rejected alternatives and the condition that would change the decision.
- For each serious risk, include detection, mitigation, degradation, rollback, and owner.
- Use a dynamic draft path when creating files: `./drafts/technical-solution-{slug}-{YYYYMMDD-HHMMSS}.md`.
- Default to Chinese for prompts, headings, labels, tables, assumptions, risks, and final deliverables. Use another language only when the user explicitly asks for it.

## Intake

Extract these fields before designing:

| Field | What to capture |
| --- | --- |
| Problem | business goal, user group, pain point, expected outcome |
| Scope | in-scope features, out-of-scope items, launch boundary |
| Success metrics | business metrics, SLO, latency, throughput, cost, quality, adoption |
| Current state | existing architecture, repo modules, data stores, deployment, dependencies |
| Constraints | deadline, team, budget, tech stack, security, compliance, migration limits |
| Scale | traffic shape, data volume, retention, peak pattern, geography |
| Risk posture | availability target, failure tolerance, rollback requirements |

If the user only provides a vague goal, create an assumption block and mark confidence as low. Do not block unless the goal itself is unclear.

## Execution Protocol

Use this source order unless the user specifies otherwise:

| Order | Source | How to use | If unavailable |
| ---: | --- | --- | --- |
| 1 | User brief and attachments | Treat as primary requirements. Quote only concise identifiers, not long passages. | Ask one blocker question only if the goal or scope is impossible to infer. |
| 2 | Local repository | Inspect `README`, `docs`, ADRs, API specs, package manifests, deploy configs, tests, monitoring and migration files. | Mark "repo evidence unavailable" and continue from user inputs. |
| 3 | Internal knowledge or docs | Look for business background, existing architecture, platform constraints, security baseline, prior incidents. | Mark "internal evidence unavailable"; do not invent company rules. |
| 4 | External research | Prefer official docs, standards, vendor docs, benchmark reports, and credible engineering incident writeups. | Use a TODO or validation task when no reliable source exists. |
| 5 | Reasoned assumptions | Use formulas and explicit confidence only after sources above are exhausted. | Put the assumption in the evidence ledger and open questions. |

When tools are available, use them in that order. When a named tool is not available, use the closest safe equivalent and record the source type in the evidence ledger.

For long tasks, create or update the draft after each major phase. Append concise findings, not raw notes. Re-read the draft before composing the final document so earlier evidence, TODOs, and assumptions are not lost.

## Workflow

### 1. Build the Evidence Base

Search the most relevant available sources:

- Repository: `README`, `docs`, ADRs, API specs, package manifests, deployment files, tests, monitoring configs.
- Internal knowledge: product background, existing platform constraints, security baseline, historical decisions.
- External sources: official docs, benchmark reports, vendor docs, standards, incident writeups, credible engineering posts.

Maintain a compact ledger:

| ID | Claim or input | Source | Freshness | Confidence | Used in |
| --- | --- | --- | --- | --- | --- |
| E1 | ... | user brief / repo / URL | date or unknown | high / medium / low | decision, risk, capacity |

Unsupported numbers must be written as assumptions or TODOs, never as facts.

### 1.5 Manage the Draft

Create a draft when the answer will be more than a short focused artifact.

```text
./drafts/technical-solution-{slug}-{YYYYMMDD-HHMMSS}.md
```

Append these sections as they become available:

```markdown
## Intake
## Evidence Ledger
## Requirements
## Option Notes
## Architecture Notes
## Capacity Notes
## Risk Notes
## Open Questions
```

Keep the draft useful for synthesis:

- Write decisions, claims, TODOs, and assumptions in structured bullets or tables.
- Do not paste full source documents into the draft.
- Mark stale or contradicted evidence instead of silently deleting it.
- Before final output, scan the draft for unresolved P0 gaps and either resolve them or list them as blockers.

### 2. Model Requirements

Convert the brief into structured requirements:

- Functional requirements: user journeys, API behavior, data lifecycle, admin/ops needs.
- Non-functional requirements: latency, throughput, availability, consistency, security, privacy, maintainability, observability.
- Priority: P0 for launch blockers, P1 for important follow-ups, P2 for optional improvements.
- Quality scenarios: describe trigger, environment, response, and measurable target.

Example quality scenario:

| Quality | Scenario | Target | Verification |
| --- | --- | --- | --- |
| Availability | primary dependency times out during peak traffic | degrade within 2s and keep core read path available | fault injection test |

### 3. Compare Options

Create two or three viable designs or technology choices. Use a weighted matrix only for consequential decisions.

| Criterion | Weight | Option A | Option B | Option C | Notes |
| --- | ---: | ---: | ---: | ---: | --- |
| Product fit | 20 | 4 | 3 | 5 | link to requirement |
| Delivery risk | 20 | 5 | 3 | 2 | team familiarity, migration size |
| Reliability | 20 | 4 | 5 | 3 | failure isolation, recovery |
| Scalability | 15 | 3 | 5 | 4 | growth path |
| Operability | 15 | 4 | 3 | 2 | monitoring, maintenance |
| Cost | 10 | 5 | 3 | 2 | infra and vendor cost |

After the matrix, write:

- Recommendation and why it wins.
- Why each rejected option is not chosen now.
- Reversal trigger: what evidence would make the team revisit the decision.
- Confidence level and remaining validation.
- If only one realistic option exists, write a constraint-based decision record: fixed constraints, validation plan, and what would make alternatives viable later.

### 4. Design the Target Architecture

Use multiple views instead of one oversized diagram:

- Context view: users, upstream systems, downstream systems, trust boundaries.
- Container or component view: services, stores, queues, caches, third-party dependencies.
- Runtime view: important request flows, async flows, retries, idempotency, timeouts.
- Data view: ownership, schema shape, retention, consistency, migration, privacy.
- Failure view: degradation path, circuit breakers, rollback and recovery.

Use Mermaid when the target environment supports it. Otherwise use ASCII diagrams. Keep diagrams simple enough that every node has a clear responsibility.

Default to ASCII diagrams when the final destination is unknown, plain Markdown, email, or a platform with uncertain Mermaid support. Use Mermaid only when the user, repository, or target tool clearly supports it.

### 5. Detail Critical Modules

For each critical module, specify:

- Responsibility and non-responsibility.
- Public contract: API, event, CLI, job, or UI boundary.
- Data model: entity ownership, indexes, retention, schema evolution.
- Key logic: state machine, concurrency control, idempotency, retry, timeout.
- Observability: logs, metrics, traces, dashboards, alerts.
- Security: authn/authz, data classification, encryption, audit, rate limits.
- Tests: unit, integration, contract, migration, load, chaos or fault injection.

Prefer concrete names, endpoints, events, tables, and config keys when known. Use placeholders only for information that is truly missing.

### 6. Estimate Capacity and Performance

Show formulas and assumptions. Mark confidence.

Common formulas:

```text
peak_qps = daily_requests * peak_ratio / peak_window_seconds
write_qps = active_users * writes_per_user_per_day * peak_ratio / peak_window_seconds
storage = rows_per_day * avg_row_bytes * retention_days * replication_factor
cache_memory = hot_keys * avg_value_bytes / target_memory_utilization
```

For every numeric claim, include one of:

- Source: official docs, benchmark report, internal measurement, production dashboard.
- Formula: inputs, assumption source, confidence.
- TODO: measurement still required before final approval.

Capacity output should include expected traffic, bottlenecks, resource estimate, scaling strategy, load-test plan, and exit criteria.

### 7. Plan Reliability, Security, and Rollout

Use a risk register that can drive execution:

| Risk | Trigger | Impact | Detection | Mitigation | Degradation | Rollback | Owner |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ... | metric or event | user/system impact | alert/log/test | preventive work | reduced capability | concrete rollback step | role |

Rollout plan must include:

- Migration steps and backward compatibility.
- Feature flags or traffic ramp.
- Pre-launch checks.
- Monitoring and alert thresholds.
- Rollback decision criteria.
- Post-launch validation window.

### 7.5 Handle Missing or Weak Evidence

Use this policy instead of guessing:

| Situation | Required behavior |
| --- | --- |
| No reliable performance benchmark | Write "暂无可靠基准；上线前必须压测验证" and provide a load-test plan. |
| Missing traffic or data volume | Derive only from user-provided numbers; otherwise create low-confidence scenarios such as small/medium/large. |
| Missing current architecture | State the assumption, design integration boundaries, and list repo/internal-doc checks as open tasks. |
| Missing owner | Use role owners such as TL, Backend, SRE, Security, DBA, PM until names are known. |
| Source is outdated or vendor-biased | Mark confidence low/medium and require validation against internal telemetry or tests. |
| Security/compliance requirement is unclear | Apply conservative defaults: least privilege, audit, encryption, retention, data minimization, approval for sensitive exports. |
| P0 requirement cannot be designed safely | Stop that part of the recommendation and list it as a blocker with the minimum information needed. |
| Non-P0 detail is unknown | Continue with an explicit assumption and add a follow-up validation task. |

### 8. Generate the Final Document

Use this Chinese structure for Chinese requests unless the user asks for a narrower artifact:

```markdown
# {Solution Name} 技术方案

> 状态: Draft / Review / Approved
> 日期: YYYY-MM-DD
> 负责人: {role or name}
> 置信度: high / medium / low

## 1. 方案摘要
- 推荐架构:
- 关键决策:
- 预期收益:
- 最大风险:
- 评审阻塞项:

## 2. 背景与目标
| 项 | 内容 |
| --- | --- |
| 业务背景 | ... |
| 技术目标 | ... |
| 成功标准 | ... |

## 3. 范围与非目标
| In Scope | Non-Goals |
| --- | --- |
| ... | ... |

## 4. 需求与成功指标
| 编号 | 类型 | 要求 | 优先级 | 验证方式 |
| --- | --- | --- | --- | --- |
| R-001 | 功能/非功能 | ... | P0 | ... |

## 5. 证据台账与假设
| ID | 事实/假设 | 来源 | 新鲜度 | 置信度 | 用于 |
| --- | --- | --- | --- | --- | --- |
| E1 | ... | ... | ... | high/medium/low | ... |

## 6. 方案选型与决策
| 决策点 | 推荐方案 | 放弃方案 | 选择理由 | 反转条件 | 置信度 |
| --- | --- | --- | --- | --- | --- |
| ... | ... | ... | ... | ... | ... |

### 6.1 关键选型矩阵
| 评估标准 | 权重 | 方案 A | 方案 B | 方案 C | 证据 |
| --- | ---: | ---: | ---: | ---: | --- |
| ... | ... | ... | ... | ... | E1/E2 |

## 7. 目标架构
- Context view:
- Component view:
- Runtime flow:
- Data view:
- Failure view:

## 8. 关键模块设计
| 模块 | 职责 | 非职责 | 接口/事件 | 数据 | 可观测性 | 安全 | 测试 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ... | ... | ... | ... | ... | ... | ... | ... |

## 9. API、事件与数据契约
| 契约 | 类型 | 请求/字段 | 响应/状态 | 幂等/重试 | 兼容性 |
| --- | --- | --- | --- | --- | --- |
| ... | API/Event/Table | ... | ... | ... | ... |

## 10. 容量、性能与压测计划
| 项 | 公式/来源 | 估算值 | 置信度 | 验证方式 |
| --- | --- | --- | --- | --- |
| ... | ... | ... | ... | ... |

| 压测场景 | 负载模型 | 通过标准 | 观测指标 |
| --- | --- | --- | --- |
| ... | ... | ... | ... |

## 11. 安全、隐私与合规
| 风险点 | 控制措施 | 验证方式 |
| --- | --- | --- |
| ... | ... | ... |

## 12. 可靠性、降级与回滚
| 风险 | 触发条件 | 影响 | 检测 | 缓解 | 降级 | 回滚 | Owner |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ... | ... | ... | ... | ... | ... | ... | ... |

## 13. 实施计划
| 阶段 | 时间 | 交付物 | 依赖 | 验收 | Owner |
| --- | --- | --- | --- | --- | --- |
| ... | ... | ... | ... | ... | ... |

## 14. 验证计划
| 验证项 | 方法 | 通过标准 | 负责人 |
| --- | --- | --- | --- |
| ... | ... | ... | ... |

## 15. 开放问题
| 优先级 | 问题 | 影响 | 需要谁确认 |
| --- | --- | --- | --- |
| P0/P1/P2 | ... | ... | ... |
```

For English requests, translate the same structure rather than changing the required content.

## Narrow Request Modes

If the user asks for only one part, return the focused artifact and keep the same rigor:

| User intent | Output |
| --- | --- |
| 技术选型 | candidate list, criteria, weighted matrix, recommendation, reversal trigger |
| 架构方案 | architecture views, module boundaries, data flow, failure path, rollout notes |
| 容量规划 | assumptions, formulas, resource estimate, bottlenecks, load-test plan |
| 压测方案 | workload model, test scenarios, environment, metrics, thresholds, report template |
| 风险评审 | risk register, degradation, rollback, owners, residual risk |
| 方案评审 | findings first, missing evidence, decision risks, test or rollout gaps |
| 系统设计 | scope, architecture views, module contracts, data model, reliability, rollout |
| 技术调研 | evidence ledger, option comparison, recommendation, unknowns, validation plan |

## Ambiguous Cases

| Case | Behavior |
| --- | --- |
| User only says "写个技术方案" | Ask for the business goal if absent. If a goal exists, continue with assumptions. |
| User asks only for "架构图" | Provide a compact architecture view plus node responsibilities and key tradeoffs. |
| User asks only for "技术选型" | Do not generate the full document; return decision matrix, recommendation, reversal trigger, and validation tasks. |
| User provides conflicting requirements | Surface the conflict first, propose resolution options, and avoid pretending both can be fully satisfied. |
| User wants exact infra sizing without telemetry | Provide formulas, scenarios, and required measurements; do not state final instance counts as fact. |
| User asks for final approval | Run the quality gate and list blockers before saying the plan is ready. |

## Quality Gate

Before final output, verify:

- The document answers the actual business goal and not just the technology topic.
- Every major decision has evidence, alternatives, and a reversal trigger.
- Every important number has a source, formula, or TODO.
- Every P0 requirement maps to at least one module, test, and rollout step.
- Every high or medium risk has detection, degradation, rollback, and owner.
- Security and compliance are not isolated footnotes; they appear in module and rollout design where relevant.
- Unknowns are explicit, prioritized, and phrased as decision blockers or follow-up tasks.
- The implementation plan has sequenced milestones, dependencies, verification, and rollback.

### Evidence and Consistency Gate

Run these checks for every final technical solution, regardless of domain:

| Gate | Required behavior |
| --- | --- |
| Evidence confidence | Mark `high` only for user-provided requirements, local repository/internal docs, official docs, papers, production telemetry, or benchmarks with clear test conditions. Blogs, secondhand summaries, unsourced "multi-source validation", or vendor marketing are at most `medium` and usually require validation. |
| External numbers | Any external performance, cost, accuracy, capacity, or latency number must include a source identifier plus applicable conditions such as version, hardware, data size, workload, concurrency, region, or test method. Without those details, use it only as a reference or assumption, not as the final capacity conclusion. |
| Arithmetic and units | Recalculate every formula before final output. Check KB/MB/GB/TB, rows vs documents vs chunks, QPS vs concurrency, peak factors, retention, replication, P95/P99, and currency/time units. If uncertain, downgrade confidence and add a validation task. |
| Metric consistency | Keep the same metric definition across summary, assumptions, capacity tables, load tests, risks, and open questions. If two numbers represent different concepts, name them explicitly, for example "online concurrency" vs "request QPS". |
| Blocker consistency | If `Open Questions` contains any P0 item, the summary must list it as a review blocker. Do not write "no blockers" while P0 unknowns remain. Each P0 blocker must map to a risk, validation task, milestone, or fallback decision. |
| Absolute claims | Avoid absolute guarantees such as "杜绝", "0 泄露", "100% 一致", "必达", "完全保证" as design claims. They may appear only as targets or pass criteria, paired with mechanisms, tests, residual risks, and monitoring. |
| Mechanism boundaries | For each key technical mechanism, state what it guarantees, what it does not guarantee, and the conditions where it applies. Do not let a mechanism's name imply stronger behavior than it actually provides. |

If the gate fails:

- Block final recommendation when a P0 requirement lacks any feasible design, security treatment, or rollback path.
- Continue with low-confidence assumptions when missing information is non-P0 or can be validated before launch.
- Put every unresolved blocker in `Open Questions` with owner and impact.
