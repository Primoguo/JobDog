import os
import json
import httpx
import math
from typing import Dict, Any, Optional

# Workflow Configuration
WORKFLOW_API_URL = "https://sd500jqlh74m0t5ldnsig.apigateway-cn-beijing-inner.volceapi.com/v1/workflow/run"
BEARER_TOKEN = os.getenv('identity_ticket')

def sanitize_data(data: Any) -> Any:
    """
    递归地将数据中的 NaN 处理为空字符串，以便进行 JSON 序列化。
    """
    if isinstance(data, dict):
        return {k: sanitize_data(v) for k, v in data.items()}
    elif isinstance(data, list):
        return [sanitize_data(i) for i in data]
    elif isinstance(data, float):
        if math.isnan(data) or math.isinf(data):
            return ""
        return data
    return data

class WorkflowAPIClient:
    """Coze/Volcengine 工作流 API 客户端"""
    
    def __init__(
        self,
        workflow_id: str,
        bearer_token: Optional[str] = None,
        timeout: int = 600
    ):
        """
        初始化工作流客户端
        """
        self.workflow_id = workflow_id
        self.bearer_token = bearer_token or BEARER_TOKEN
        self.timeout = timeout

    def call(
        self,
        parameters: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        同步调用工作流 API
        """
        if not self.bearer_token:
            return {
                "success": False,
                "error": "Bearer token (identity_ticket) is not set in environment or provided.",
                "raw_response": ""
            }

        payload = {
            "workflow_id": self.workflow_id,
            "parameters": sanitize_data(parameters)
        }
        
        headers = {
            "Authorization": f"Bearer {self.bearer_token}",
            "Content-Type": "application/json"
        }

        # print(f"Calling workflow API...: \nworkflow_url: {WORKFLOW_API_URL}\nheaders: {headers}\npayload: {payload}")
        
        with httpx.Client(timeout=self.timeout) as client:
            try:
                response = client.post(
                    WORKFLOW_API_URL,
                    headers=headers,
                    json=payload
                )
                
                # print(f"Workflow API response: {response.text}")
                
                if response.status_code != 200:
                    return {
                        "success": False,
                        "error": f"Workflow API request failed with status {response.status_code}: {response.text}",
                        "raw_response": response.text
                    }
                else:
                    print(f"调用工作流成功！")
                    if "input_list" in parameters:
                        print(f"总共处理了: {len(parameters['input_list'])} 条数据。")
                
                response_data = response.json()
                
                if response_data.get('code') != 0:
                    return {
                        "success": False,
                        "error": f"Workflow execution error: {response_data.get('msg', 'Unknown error')}",
                        "raw_response": json.dumps(response_data, ensure_ascii=False)
                    }
                
                data_val = response_data.get('data')
                parsed_data = None
                
                if isinstance(data_val, str):
                    try:
                        parsed_data = json.loads(data_val)
                    except json.JSONDecodeError:
                        parsed_data = data_val
                else:
                    parsed_data = data_val

                return {
                    "success": True,
                    "data": parsed_data,
                    "raw_response": json.dumps(response_data, ensure_ascii=False)
                }
                
            except Exception as e:
                # 兼容旧版本调用中的异常处理
                return {
                    "success": False,
                    "error": f"Workflow call exception: {str(e)}",
                    "raw_response": ""
                }
