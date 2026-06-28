"""
大模型 API 调用封装模块

提供结构化输出的 LLM API 调用能力,支持批量处理和错误处理。
"""

import os
import json
import httpx
import re
from typing import List, Dict, Any, Optional
from concurrent.futures import ThreadPoolExecutor


class ValidationError(Exception):
    """输入参数校验异常"""
    pass


def validate_json_schema(schema: Dict[str, Any], schema_name: str = "output_schema") -> None:
    """
    校验 JSON Schema 的合法性
    
    Args:
        schema: 待校验的 JSON Schema
        schema_name: Schema 名称，用于错误提示
        
    Raises:
        ValidationError: Schema 不合法时抛出
    """
    if not isinstance(schema, dict):
        raise ValidationError(f"{schema_name} 必须是字典类型，当前类型: {type(schema).__name__}")
    
    if "type" not in schema:
        raise ValidationError(f"{schema_name} 必须包含 'type' 字段")
    
    valid_types = {"string", "number", "integer", "boolean", "array", "object", "null"}
    schema_type = schema.get("type")
    
    if schema_type not in valid_types:
        raise ValidationError(
            f"{schema_name} 的 'type' 字段值无效: {schema_type}，"
            f"必须是以下之一: {', '.join(valid_types)}"
        )
    
    if schema_type == "object":
        if "properties" not in schema:
            raise ValidationError(f"{schema_name} 类型为 object 时必须包含 'properties' 字段")
        
        if not isinstance(schema["properties"], dict):
            raise ValidationError(f"{schema_name} 的 'properties' 必须是字典类型")
        
        if "required" in schema and not isinstance(schema["required"], list):
            raise ValidationError(f"{schema_name} 的 'required' 必须是列表类型")
    
    elif schema_type == "array":
        if "items" not in schema:
            raise ValidationError(f"{schema_name} 类型为 array 时必须包含 'items' 字段")


def validate_prompt_template(template: str, variables: Dict[str, Any]) -> None:
    """
    校验 prompt 模板与变量的匹配性
    
    Args:
        template: prompt 模板字符串
        variables: 变量字典
        
    Raises:
        ValidationError: 模板或变量不合法时抛出
    """
    if not isinstance(template, str):
        raise ValidationError(f"prompt 模板必须是字符串类型，当前类型: {type(template).__name__}")
    
    if not template.strip():
        raise ValidationError("prompt 模板不能为空")
    
    if not isinstance(variables, dict):
        raise ValidationError(f"变量必须是字典类型，当前类型: {type(variables).__name__}")
    
    template_vars = set(re.findall(r'\{(\w+)\}', template))
    
    if not template_vars:
        return
    
    provided_vars = set(variables.keys())
    missing_vars = template_vars - provided_vars
    
    if missing_vars:
        raise ValidationError(
            f"prompt 模板中的变量 {missing_vars} 在输入数据中缺失。"
            f"模板需要: {template_vars}，提供的: {provided_vars}"
        )




def format_prompt(template: str, variables: Dict[str, Any]) -> str:
    """
    格式化 prompt 模板
    
    Args:
        template: 包含占位符的模板字符串,如 "分析文本: {text}"
        variables: 变量字典
        
    Returns:
        格式化后的字符串
    """
    try:
        return template.format(**variables)
    except KeyError as e:
        raise ValidationError(f"模板变量缺失: {e}")


try:
    from .workflow_api_client import WorkflowAPIClient
except ImportError:
    from workflow_api_client import WorkflowAPIClient

LLM_API_WORKFLOW_ID = "7587772817400692776"


def batch_call_llm(
    user_prompt_template: str,
    output_schema: Dict[str, Any],
    input_list: List[Dict[str, Any]]
) -> List[Dict[str, Any]]:
    """
    批量调用 LLM API
    """
    if not isinstance(user_prompt_template, str) or not user_prompt_template.strip():
        raise ValidationError(f"user_prompt_template 必须是非空字符串。")
    
    validate_json_schema(output_schema, "output_schema")
    
    if not isinstance(input_list, list):
        raise ValidationError(f"input_list 必须是列表类型。")
    
    if not input_list:
        return []

    for i, item in enumerate(input_list):
        if not isinstance(item, dict):
            raise ValidationError(f"input_list[{i}] 必须是字典类型。")
        validate_prompt_template(user_prompt_template, item)

    # 初始化工作流客户端
    client = WorkflowAPIClient(workflow_id=LLM_API_WORKFLOW_ID)
    
    # 分批处理，每批最多200条
    batch_size = 200
    batches = [input_list[i:i + batch_size] for i in range(0, len(input_list), batch_size)]
    
    def process_batch(batch_data: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        parameters = {
            "user_prompt_template": user_prompt_template,
            "output_schema": output_schema,
            "input_list": batch_data
        }
        try:
            result = client.call(parameters=parameters)
            if not result["success"]:
                return [{
                    "success": False,
                    "error": result["error"],
                    "raw_response": result["raw_response"]
                } for _ in range(len(batch_data))]
            
            batch_results = result["data"]
            if not isinstance(batch_results, list):
                if isinstance(batch_results, dict) and "output" in batch_results:
                    batch_results = batch_results["output"]
                else:
                    return [{
                        "success": False,
                        "error": "Workflow returned unexpected format",
                        "raw_response": result["raw_response"]
                    } for _ in range(len(batch_data))]
            
            results = []
            for i in range(len(batch_data)):
                if i < len(batch_results):
                    item = batch_results[i]
                    if isinstance(item, dict) and "success" in item:
                        results.append(item)
                    else:
                        results.append({
                            "success": True,
                            "data": item,
                            "raw_response": json.dumps(item, ensure_ascii=False)
                        })
                else:
                    results.append({"success": False, "error": "No result for index", "raw_response": ""})
            return results
        except Exception as e:
            return [{
                "success": False,
                "error": f"处理异常: {str(e)}",
                "raw_response": ""
            } for _ in range(len(batch_data))]

    # 并发执行各个批次
    all_results = []
    with ThreadPoolExecutor(max_workers=min(len(batches), 10)) as executor:
        batch_responses = list(executor.map(process_batch, batches))
    
    # 按照批次顺序合并结果
    for batch_res in batch_responses:
        all_results.extend(batch_res)
    
    return all_results


# 示例用法
if __name__ == "__main__":
    # 测试 batch_call_llm
    prompt_template = "请将以下内容翻译成英文: {text}"
    inputs = [
        {"text": "你好，世界"},
        {"text": "今天天气不错"}
    ]
    
    # 注意: 现在 output_schema 在工作流调用中可能不再是必须的(取决于工作流内部逻辑)
    # 但为了保持签名兼容，我们仍然传入
    schema = {"type": "object", "properties": {"translated_text": {"type": "string"}}}
    
    print("开始测试工作流批量调用...")
    results = batch_call_llm(
        user_prompt_template=prompt_template,
        output_schema=schema,
        input_list=inputs
    )
    
    for i, result in enumerate(results):
        print(f"\n结果 {i+1}:")
        if result["success"]:
            print(f"数据: {result['data']}")
        else:
            print(f"错误: {result['error']}")
