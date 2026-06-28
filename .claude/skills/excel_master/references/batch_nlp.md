# NLP 处理能力

本能力用于批量文本理解与结构化输出，优先通过 `SKILL_DIR/scripts/llm_api.py` 提供的封装执行。

约定：

- 模型生成的处理脚本放在 workspace
- 本模块位于 `SKILL_DIR/scripts`
- 运行脚本时通过 `PYTHONPATH="$SKILL_DIR/scripts"` 暴露导入路径

推荐导入方式：

```python
from llm_api import batch_call_llm
```

推荐执行方式：

```bash
SKILL_DIR="<skill_base_dir>" PYTHONPATH="$SKILL_DIR/scripts" python <workspace_script.py>
```

## 触发规则

只要满足以下任一条件，就把任务视为 batch NLP，并默认优先使用 `batch_call_llm`：

- 对 Excel / CSV 中的一列或多列文本逐行分类
- 对每行文本做情感分析、标签生成、摘要、翻译、改写
- 从每行文本里抽取实体、金额、日期、联系人、主题、风险点
- 把自然语言描述批量转成结构化字段

反过来，以下都不应作为首选方案：

- `if/else` 关键词匹配
- 大段正则规则硬编码
- `pandas.apply(...)` 中逐行写启发式逻辑冒充语义理解
- 为每一行手工拼一个不同 prompt 再自己管理并发和分批

## 核心原则

1. 语义任务优先使用模型能力，不要用规则拼凑。
2. `batch_call_llm` 已经内置批处理和并发，不需要在外部再手动切块。
3. 如果 workflow API 不可用，不要卡死；应切换到其他可验证方案，并明确告知用户。
4. 如果输入本质上是“表格里的文本列”，默认先把 DataFrame 清洗成 `input_list`，再调用 `batch_call_llm`。

## 适用场景

| 场景 | 示例 |
| :--- | :--- |
| 文本分类 / 情感分析 | 评论情感、工单分流、优先级判断 |
| 信息抽取 | 从合同、简历、公告里抽取人名、日期、金额 |
| 非结构化转结构化 | 将纪要整理成待办，将自然语言转成表格字段 |
| 文本生成 / 改写 | 批量摘要、翻译、润色、标签生成 |

> 注意：本能力只处理“已提供的文本”。如需实时外部信息，请查看 `SKILL_DIR/references/batch_search_analysis.md`。

## API 定义

```python
from llm_api import batch_call_llm
from typing import Any, Dict, List

def batch_call_llm(
    user_prompt_template: str,
    output_schema: Dict[str, Any],
    input_list: List[Dict[str, Any]]
) -> List[Dict[str, Any]]:
    ...
```

返回结果与 `input_list` 顺序一致。每项包含：

- `success`
- `data`
- `error`

## 使用步骤

### 1. 定义输出 Schema

优先定义简洁、约束明确的 JSON Schema。对离散值使用 `enum`，对关键字段使用 `required`。

### 2. 设计 Prompt 模板

模板中使用 `{variable}` 占位符，并保证变量名和输入字段一致。

### 3. 构造输入列表

把每条待处理记录组织成一个字典，放入 `input_list`。

典型模式：

```python
input_list = [
    {"content": str(v).strip()}
    for v in df["评论内容"].fillna("")
]
```

### 4. 调用并消费结果

```python
from llm_api import batch_call_llm

output_schema = {
    "type": "object",
    "properties": {
        "sentiment": {
            "type": "string",
            "enum": ["POSITIVE", "NEUTRAL", "NEGATIVE"]
        },
        "score": {"type": "number"}
    },
    "required": ["sentiment", "score"],
    "additionalProperties": False,
}

prompt_template = """
请分析以下文本的情感倾向：
{content}
"""

input_list = [{"content": text} for text in raw_comments]

results = batch_call_llm(
    user_prompt_template=prompt_template,
    output_schema=output_schema,
    input_list=input_list,
)
```

### 5. 回填到 DataFrame

```python
df["sentiment"] = [
    item["data"]["sentiment"] if item["success"] else ""
    for item in results
]
df["score"] = [
    item["data"]["score"] if item["success"] else None
    for item in results
]
```

## 推荐工作流

处理 Excel / CSV 中的文本列时，优先采用这条路径：

1. 用 `pandas` 读表
2. 明确哪几列是 NLP 输入列
3. 构造 `input_list`
4. 用 `batch_call_llm` 一次性处理
5. 把结果回填到 DataFrame
6. 导出结果文件并抽样复核

## 失败处理

在以下场景下，不要强依赖本模块：

- 环境缺少 `identity_ticket`
- 网络不可用
- workflow API 调用失败

处理方式：

1. 先记录失败原因。
2. 切换到其他可验证的语义处理方案。
3. 在最终结果中注明哪些记录使用了替代处理方式。

## 最佳实践

1. 先校验模板变量与输入字段是否一致。
2. 对单条失败结果单独处理，不要假设整批都会成功。
3. 任务要求可核验时，在输出中保留原文、标签和置信度，方便抽样复核。
4. 如果通过脚本调用本模块，脚本优先放在 workspace，模块路径通过 `PYTHONPATH="$SKILL_DIR/scripts"` 提供。
5. 当用户说“帮我分析这一列评论”“给每条工单打标签”“提取每行联系人”，不要重新发明流程，直接使用本能力。
