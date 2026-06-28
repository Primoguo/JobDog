#!/usr/bin/env python3
"""
PDF布局重叠检测工具

功能：检测PDF中文字元素是否存在位置重叠
输入：PDF文件路径
输出：重叠检测报告

使用方法：
    python check_layout_overlap.py <pdf_file>
"""

import sys
from dataclasses import dataclass
from typing import List, Tuple

try:
    import pdfplumber
except ImportError:
    print("错误: 请先安装 pdfplumber: pip install pdfplumber")
    sys.exit(1)


@dataclass
class TextBlock:
    """文字块数据结构"""
    text: str
    x0: float
    y0: float  # top
    x1: float
    y1: float  # bottom
    page: int
    
    @property
    def height(self) -> float:
        return self.y1 - self.y0
    
    @property
    def width(self) -> float:
        return self.x1 - self.x0


def boxes_overlap(b1: TextBlock, b2: TextBlock, tolerance: float = 2.0) -> bool:
    """
    检测两个文字块是否重叠
    
    Args:
        b1, b2: 两个文字块
        tolerance: 容差值，小于此值的重叠忽略（处理微小的渲染误差）
    
    Returns:
        是否存在显著重叠
    """
    if b1.page != b2.page:
        return False
    
    # 计算重叠区域
    x_overlap = max(0, min(b1.x1, b2.x1) - max(b1.x0, b2.x0))
    y_overlap = max(0, min(b1.y1, b2.y1) - max(b1.y0, b2.y0))
    
    # 如果重叠面积大于容差，认为存在重叠
    overlap_area = x_overlap * y_overlap
    
    # 同时检查重叠是否显著（至少覆盖其中一个块的10%）
    b1_area = b1.width * b1.height
    b2_area = b2.width * b2.height
    min_area = min(b1_area, b2_area) if min(b1_area, b2_area) > 0 else 1
    
    return overlap_area > tolerance and (overlap_area / min_area) > 0.1


def extract_text_blocks(pdf_path: str) -> List[TextBlock]:
    """从PDF提取所有文字块"""
    blocks = []
    
    with pdfplumber.open(pdf_path) as pdf:
        for page_num, page in enumerate(pdf.pages, 1):
            words = page.extract_words()
            for w in words:
                # 过滤掉空文本或emoji占位符
                text = w.get('text', '').strip()
                if not text or len(text) == 0:
                    continue
                    
                blocks.append(TextBlock(
                    text=text,
                    x0=w['x0'],
                    y0=w['top'],
                    x1=w['x1'],
                    y1=w['bottom'],
                    page=page_num
                ))
    
    return blocks


def check_overlaps(blocks: List[TextBlock]) -> List[Tuple[TextBlock, TextBlock, float]]:
    """
    检测所有文字块之间的重叠
    
    Returns:
        重叠的文字块对列表，包含 (block1, block2, overlap_percentage)
    """
    overlaps = []
    
    for i, b1 in enumerate(blocks):
        for j in range(i + 1, len(blocks)):
            b2 = blocks[j]
            
            if boxes_overlap(b1, b2):
                # 计算重叠百分比
                x_overlap = max(0, min(b1.x1, b2.x1) - max(b1.x0, b2.x0))
                y_overlap = max(0, min(b1.y1, b2.y1) - max(b1.y0, b2.y0))
                overlap_area = x_overlap * y_overlap
                
                smaller_area = min(b1.width * b1.height, b2.width * b2.height)
                overlap_pct = (overlap_area / smaller_area * 100) if smaller_area > 0 else 0
                
                overlaps.append((b1, b2, overlap_pct))
    
    return overlaps


def analyze_pdf(pdf_path: str) -> List[str]:
    """
    分析PDF布局并返回检测消息
    
    Args:
        pdf_path: PDF文件路径
        
    Returns:
        检测消息列表
    """
    messages = []
    
    try:
        blocks = extract_text_blocks(pdf_path)
        messages.append(f"文件: {pdf_path}")
        messages.append(f"检测到 {len(blocks)} 个文字块")
        messages.append("")
        
        overlaps = check_overlaps(blocks)
        
        if overlaps:
            messages.append(f"发现 {len(overlaps)} 处重叠:")
            messages.append("-" * 50)
            
            for b1, b2, pct in overlaps:
                text1 = b1.text[:15] + "..." if len(b1.text) > 15 else b1.text
                text2 = b2.text[:15] + "..." if len(b2.text) > 15 else b2.text
                messages.append(f"  '{text1}' 与 '{text2}'")
                messages.append(f"     页码: {b1.page} | 重叠度: {pct:.1f}%")
                messages.append(f"     位置1: Y={b1.y0:.1f}-{b1.y1:.1f}, X={b1.x0:.1f}-{b1.x1:.1f}")
                messages.append(f"     位置2: Y={b2.y0:.1f}-{b2.y1:.1f}, X={b2.x0:.1f}-{b2.x1:.1f}")
                messages.append("")
                
            messages.append("建议: 调整元素间距，确保各文字块不重叠")
        else:
            messages.append("SUCCESS: 未检测到文字重叠，布局正常")
            
    except FileNotFoundError:
        messages.append(f"错误: 文件不存在 - {pdf_path}")
    except Exception as e:
        messages.append(f"错误: {str(e)}")
    
    return messages


def main():
    if len(sys.argv) < 2:
        print("用法: python check_layout_overlap.py <pdf_file> [pdf_file2 ...]")
        print("示例: python check_layout_overlap.py invitation.pdf")
        sys.exit(1)
    
    for pdf_path in sys.argv[1:]:
        messages = analyze_pdf(pdf_path)
        for msg in messages:
            print(msg)
        print("\n" + "=" * 50 + "\n")


if __name__ == "__main__":
    main()
