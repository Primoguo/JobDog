# 搜索分析能力

本能力用于“基于外部信息的批量检索与结构化分析”。

优先级如下：

1. 对实时、最新、会变化的信息，优先使用可用的联网检索能力。
2. 如果执行环境具备内部 workflow API 访问条件，可使用本目录中的 Python 封装做批量化处理。
3. 如果两者都不可用，要明确说明受限原因，不要编造结果。

推荐导入方式：

```python
from web_search_api import batch_search_and_analyze
```

推荐执行方式：

```bash
SKILL_DIR="<skill_base_dir>" PYTHONPATH="$SKILL_DIR/scripts" python <workspace_script.py>
```

## 核心原则

1. 这项能力是“信息检索 + 分析”，不是大规模爬虫。
2. 能批量时优先批量，不要手写一层“搜索-读取-分析”循环来重复造轮子。
3. 对时效性信息，必须优先保证来源可追溯。

## 适用场景

| 场景 | 示例 |
| :--- | :--- |
| 实时信息查询 | 最新价格、新闻、天气、法规、版本信息 |
| 技术 / 市场调研 | 多个产品或技术方案对比 |
| 事实核查 | 验证多个说法是否成立 |
| 官方文档检索 | 查找某工具或库的最新用法 |

## API 定义

```python
from web_search_api import batch_search_and_analyze
from typing import Any, Dict, List

def batch_search_and_analyze(
    query_template: str,
    analysis_prompt_template: str,
    output_schema: Dict[str, Any],
    input_list: List[Dict[str, Any]]
) -> List[Dict[str, Any]]:
    ...
```

## 使用步骤

### 1. 设计 Query Template

使用关键词式查询，不要写成长问句。

推荐：

```python
query_template = "{entity} latest version release notes"
```

### 2. 设计 Analysis Prompt

分析模板必须包含：

- `{search_results}`
- 任务本身用到的上下文字段

### 3. 定义输出 Schema

建议把来源信息也纳入结构化结果，例如：

- `source_url`
- `source_title`
- `release_date`

### 4. 执行并消费结果

```python
from web_search_api import batch_search_and_analyze

results = batch_search_and_analyze(
    query_template=query_template,
    analysis_prompt_template=analysis_prompt_template,
    output_schema=output_schema,
    input_list=input_list,
)
```

## 时效性建议

如果任务明确要求“最新”“今天”“当前”“最近”“官方说法”，优先使用联网检索结果，而不是只依赖本地缓存或静态知识。

## 失败处理

以下情况不要硬走本模块：

- 网络不可用
- 缺少 `identity_ticket`
- workflow API 返回错误

处理方式：

1. 对单条或整批失败保留错误信息。
2. 能使用其他联网检索方式时，优先切过去。
3. 仍不可用时，明确告诉用户“无法联网核实”，不要输出伪造结论。

## 最佳实践

1. 搜索词质量会直接决定结果质量，先优化 `query_template`。
2. 输出里尽量保留来源链接，方便人工复核。
3. Prompt 中要显式要求“找不到就返回空值”，降低幻觉风险。
4. 若脚本位于 workspace，保持脚本留在 workspace，并通过 `PYTHONPATH="$SKILL_DIR/scripts"` 暴露本模块。
