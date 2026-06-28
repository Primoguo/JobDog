"""
网络搜索工具的Python实现 - 基于Coze工作流API
封装工作流调用接口。
"""

import os
import json
import httpx
from typing import Dict, List, Optional, Any
from concurrent.futures import ThreadPoolExecutor


try:
    from .workflow_api_client import WorkflowAPIClient
except ImportError:
    from workflow_api_client import WorkflowAPIClient

DEFAULT_SEARCH_WORKFLOW_ID = "7587791635304742975"


def batch_search_and_analyze(
    query_template: str,
    analysis_prompt_template: str,
    output_schema: Dict[str, Any],
    input_list: List[Dict[str, Any]]
) -> List[Dict[str, Any]]:
    """
    批量执行搜索并分析结果 (使用搜索工作流)
    """
    if not input_list:
        return []

    # 初始化工作流客户端
    client = WorkflowAPIClient(workflow_id=DEFAULT_SEARCH_WORKFLOW_ID)
    
    # 分批处理，每批最多200条
    batch_size = 200
    batches = [input_list[i:i + batch_size] for i in range(0, len(input_list), batch_size)]
    
    def process_batch(batch_data: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        parameters = {
            "query_template": query_template,
            "analysis_prompt_temp": analysis_prompt_template,
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


if __name__ == "__main__":
    # 测试代码
    print("Testing batch_search_and_analyze with workflow...")
    
    inputs = [
        {"language": "Python", "version": "3.13"},
        {"language": "Go", "version": "1.23"}
    ]
    
    query_template = "{language} {version} 新特性"
    analysis_prompt_template = "分析搜索结果并提取 {language} {version} 的新特性"
    schema = {
        "type": "object",
        "properties": {
            "features": {"type": "array", "items": {"type": "string"}}
        }
    }
    
    results = batch_search_and_analyze(
        query_template=query_template,
        analysis_prompt_template=analysis_prompt_template,
        output_schema=schema,
        input_list=inputs
    )
    
    print(json.dumps(results, ensure_ascii=False, indent=2))
