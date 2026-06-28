# Excel API 能力

本能力提供一套基于 `openpyxl` 的 Excel 读写封装，适合保留格式、模板微调、区域复制、按范围删除等复杂操作。

推荐导入方式：

```python
from excel_api import General, Workbook, Worksheet
```

推荐执行方式：

```bash
SKILL_DIR="<skill_base_dir>" PYTHONPATH="$SKILL_DIR/scripts" python <workspace_script.py>
```

## 适用边界

优先用于：

- 保留原工作簿样式
- 修改模板
- 处理合并单元格或复杂布局
- 复制区域、删除行、调整列宽

如果任务只是标准数据分析、筛选、聚合，通常优先使用 `pandas`。

## 核心原则

1. 本 API 更适合精细修改，不适合重型分析。
2. 仅读值时可直接读取；改格式、改公式、改布局时要谨慎保存并另存。
3. 公式读取依赖 Excel 已缓存的值，不要默认它一定是最新的。

## 核心类与方法

```python
from excel_api import General, Workbook, Worksheet
```

### Workbook

| 方法 | 说明 |
| :--- | :--- |
| `Workbook(path)` | 打开现有 `.xlsx` 文件 |
| `wb.get_sheet(index_or_name)` | 获取工作表 |
| `wb.get_sheet_names()` | 获取全部 sheet 名称 |
| `wb.save(path)` | 保存结果 |
| `wb.close()` | 释放资源 |

### Worksheet

常见用法：

```python
value = sheet.get_raw_cell_data("A1", calc_formula=True)
data = sheet.get_raw_range_data("A1:C10", calc_formula=True)
```

搜索：

```python
results = sheet.regex_search(
    patterns=[r"^ID-\d{4}$", r"Error"],
    match_case=False,
)
```

删除并上移：

```python
max_row = sheet.get_max_row_with_data_in_column("A")
sheet.shift_up_cells("A5:E10", max_row)
```

列宽调整：

```python
sheet.auto_resize_columns()
```

### General

跨工作簿复制区域：

```python
General.copy_range_from_workbook(
    from_workbook=source_wb,
    from_range="Sheet1!A1:D20",
    to_workbook=target_wb,
    to_range="Data!A1",
)
```

## 性能与正确性要求

### 1. 不要逐行删除

逐行调用 `shift_up_cells` 会产生明显性能问题。先合并连续区间，再从底向上删。

### 2. 注意公式缓存

`calc_formula=True` 读到的是缓存值，不等于实时重算值。若刚修改过上游单元格，缓存可能过期。

### 3. 记得关闭工作簿

操作结束后调用 `wb.close()`，避免文件锁和内存占用问题。

## 示例

```python
from excel_api import General, Workbook

src_wb = Workbook("source_data.xlsx")
src_sheet = src_wb.get_sheet("Sales")

matches = src_sheet.regex_search([r"ORD-2024-\d+"])

tgt_wb = Workbook()

if matches:
    first_match_row = matches[0]["address"][1:]
    General.copy_range_from_workbook(
        from_workbook=src_wb,
        from_range=f"Sales!A{first_match_row}:F{first_match_row}",
        to_workbook=tgt_wb,
        to_range="Sheet1!A1",
    )

tgt_wb.save("filtered_orders.xlsx")
src_wb.close()
tgt_wb.close()
```

## 使用建议

1. 输出文件优先写到当前 workspace。
2. 如果只是为了快速检查 sheet 和单元格，不要过度封装，直接写最小脚本即可。
3. 交付时在最终答复中给出产物绝对路径。
4. 如果脚本位于 workspace，保持脚本留在 workspace，并通过 `PYTHONPATH="$SKILL_DIR/scripts"` 导入本模块。
