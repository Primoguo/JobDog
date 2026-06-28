**重要提示：您必须按顺序完成这些步骤。不要跳转到编写代码。**

如果您需要填写PDF表单，首先检查PDF是否有可填写的表单字段。从此文件的目录运行以下脚本：
 `python scripts/check_fillable_fields <file.pdf>`，根据结果转到"可填写字段"或"不可填写字段"并按照相应说明操作。

# 可填写字段
如果PDF有可填写的表单字段：
- 从此文件的目录运行以下脚本：`python scripts/extract_form_field_info.py <input.pdf> <field_info.json>`。它将创建一个JSON文件，其中包含以下格式的字段列表：
```
[
  {
    "field_id": (字段的唯一ID),
    "page": (页码，从1开始),
    "rect": ([left, bottom, right, top] PDF坐标中的边界框，y=0是页面底部),
    "type": ("text"、"checkbox"、"radio_group"或"choice"),
  },
  // 复选框有"checked_value"和"unchecked_value"属性：
  {
    "field_id": (字段的唯一ID),
    "page": (页码，从1开始),
    "type": "checkbox",
    "checked_value": (设置字段为此值以选中复选框),
    "unchecked_value": (设置字段为此值以取消选中复选框),
  },
  // 单选组有"radio_options"列表，包含可能的选项：
  {
    "field_id": (字段的唯一ID),
    "page": (页码，从1开始),
    "type": "radio_group",
    "radio_options": [
      {
        "value": (设置字段为此值以选择此单选选项),
        "rect": (此选项的单选按钮的边界框)
      },
      // 其他单选选项
    ]
  },
  // 多选字段有"choice_options"列表，包含可能的选项：
  {
    "field_id": (字段的唯一ID),
    "page": (页码，从1开始),
    "type": "choice",
    "choice_options": [
      {
        "value": (设置字段为此值以选择此选项),
        "text": (选项的显示文本)
      },
      // 其他选项
    ]
  }
]
```
- 根据您要输入的数据填充字段。字段条目的格式为：
```
[
  {
    "field_id": (字段的唯一ID，匹配上面field_info.json中的field_id),
    "page": (页码，从1开始),
    "value": (要为字段设置的值)
  },
  // 额外的表单字段条目
]
```
- 创建一个包含填写数据的JSON文件（例如 `data.json`），然后运行以下脚本：`python scripts/fill_fillable_fields.py <input_pdf_path> <field_info.json> <data.json> <output_pdf_path>`

# 不可填写字段
如果PDF没有可填写的表单字段，您需要使用注释方法。请按照以下步骤操作：

### 步骤1：将PDF转换为图像
将PDF的每一页转换为图像文件。您可以使用以下脚本：`python scripts/convert_pdf_to_images.py <input.pdf> <output_directory>`，或者使用其他工具。

### 步骤2：分析表单字段
对于每个字段，您需要在JSON文件中创建一个条目，描述其位置和类型。字段条目的格式为：
```
[
  {
    "field_id": "unique_identifier_for_field",
    "page": 1,
    "type": "text" | "checkbox" | "other",
    "entry_bounding_box": [left, bottom, right, top],  // 输入区域的边界框
    "field_label": "字段标签（可选，用于参考）",
    "label_bounding_box": [left, bottom, right, top],  // 字段标签文本的边界框（可选）
    "entry_text": {
      "text": "要输入的文本（对于文本字段）"
    }
  },
  // 复选框示例：
  {
    "field_id": "checkbox_field_1",
    "page": 1,
    "type": "checkbox",
    "entry_bounding_box": [140, 525, 155, 540],  // 复选框上方的小框
    "field_label": "是",
    "label_bounding_box": [100, 525, 132, 540],  // 包含"是"文本的框
    // 使用"X"来选中复选框。
    "entry_text": {
      "text": "X",
    }
  }
  // 额外的表单字段条目
]
```
通过运行以下脚本为每一页创建验证图像（从此文件的目录）：
`python scripts/create_validation_image.py <page_number> <path_to_fields.json> <input_image_path> <output_image_path>`

验证图像将在应输入文本的位置显示红色矩形，在标签文本上方显示蓝色矩形。

### 步骤3：验证边界框（必需）
#### 自动交集检查
- 通过使用`check_bounding_boxes.py`脚本检查fields.json文件（从此文件的目录运行），验证边界框不相交且输入边界框足够高：
`python scripts/check_bounding_boxes.py <JSON file>`

如果有错误，重新分析相关字段，调整边界框，并迭代直到没有剩余错误。记住：标签（蓝色）边界框应包含文本标签，条目（红色）框不应包含。

#### 手动图像检查
**关键：不要在没有视觉检查验证图像的情况下继续操作**
- 红色矩形必须仅覆盖输入区域
- 红色矩形不得包含任何文本
- 蓝色矩形应包含标签文本
- 对于复选框：
  - 红色矩形必须以复选框方块为中心
  - 蓝色矩形应覆盖复选框的文本标签

- 如果任何矩形看起来不对，请修复fields.json，重新生成验证图像，然后再次验证。重复此过程，直到边界框完全准确。

### 步骤4：向PDF添加注释
从此文件的目录运行以下脚本，使用fields.json中的信息创建填写的PDF：
`python scripts/fill_pdf_form_with_annotations.py <input_pdf_path> <path_to_fields.json> <output_pdf_path>`
