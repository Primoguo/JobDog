from openpyxl import load_workbook
from openpyxl.utils import get_column_letter
import unicodedata
import datetime
from openpyxl.styles import numbers


def format_cell_value(cell) -> str:
    """根据单元格内容的实际类型格式化显示值"""
    value = cell.value
    if value is None:
        return ""

    # 处理字符串类型
    if isinstance(value, str):
        return value.strip()  # 去除首尾空白

    # 处理布尔类型
    if isinstance(value, bool):
        return "TRUE" if value else "FALSE"

    # 处理日期和时间类型
    if isinstance(value, (datetime.datetime, datetime.date, datetime.time)):
        # 检查是否为时间
        if isinstance(value, datetime.time):
            return value.strftime("%H:%M:%S")
        # 检查是否为日期时间
        elif isinstance(value, datetime.datetime):
            return value.strftime("%Y-%m-%d %H:%M:%S")
        # 纯日期
        else:
            return value.strftime("%Y-%m-%d")

    # 处理数值类型（整数、浮点数）
    if isinstance(value, (int, float)):
        # 检查是否是Excel日期序列号（通常大于25569，即1970-01-01）
        # 同时检查单元格格式是否为日期格式
        if (isinstance(value, float) and value > 25569 and
                cell.number_format in numbers.BUILTIN_FORMATS.values() and
                any(fmt in cell.number_format.lower() for fmt in ['yyyy', 'mm', 'dd', 'hh', 'ss'])):
            try:
                # 转换Excel日期序列号为Python日期
                return (datetime.datetime(1900, 1, 1) +
                        datetime.timedelta(days=value - 2)).strftime("%Y-%m-%d")
            except Exception:
                pass  # 转换失败则按普通数值处理

        # 处理百分比格式
        if cell.number_format in [numbers.FORMAT_PERCENTAGE, numbers.FORMAT_PERCENTAGE_00]:
            return f"{value:.2%}"

        # 处理货币格式
        if cell.number_format in [
            numbers.FORMAT_CURRENCY_USD_SIMPLE,
            numbers.FORMAT_CURRENCY_USD,
            numbers.FORMAT_CURRENCY_EUR_SIMPLE,
        ]:
            # 根据不同货币格式使用相应的货币符号
            if 'yen' in cell.number_format.lower():
                return f"¥{value:,.2f}"
            elif 'eur' in cell.number_format.lower():
                return f"€{value:,.2f}"
            else:  # 默认美元格式
                return f"${value:,.2f}"

        if cell.number_format == numbers.FORMAT_GENERAL:
            # 货币特征：保留2位小数或整数，通常用于财务数据
            is_currency_like = (
                    (isinstance(value, float) and round(value, 2) == value)  # 最多2位小数
                    or isinstance(value, int)  # 整数金额
            )
            # 可根据实际需求调整阈值，这里假设大于等于0.01的数值可能为货币
            if is_currency_like and abs(value) >= 0.01:
                return f"{value:,.2f}"

        # 处理整数
        if isinstance(value, int):
            return f"{value:,}"  # 添加千分位分隔符

        # 处理浮点数
        if isinstance(value, float):
            # 检查是否是整数形式的浮点数（如100.0）
            if value.is_integer():
                return f"{int(value):,}"
            # 普通浮点数保留两位小数
            return f"{value:,.2f}"

    # 处理其他类型（如公式结果等）
    return str(value)


def calculate_display_width(text: str, font_size: float = 11.0, bold: bool = False) -> float:
    """根据字符内容、字体大小、加粗情况计算列宽"""
    base_width = 0
    for char in text:
        if unicodedata.east_asian_width(char) in ('F', 'W'):
            base_width += 2.2
        elif char.isupper():
            base_width += 1.1
        elif char.islower():
            base_width += 0.8
        elif char.isdigit():
            base_width += 1.0
        else:
            base_width += 1.0

    # 字体大小缩放
    font_scale_factor = font_size / 11.0
    width = base_width * font_scale_factor

    # 加粗放大系数
    if bold:
        width *= 1.1

    return width
