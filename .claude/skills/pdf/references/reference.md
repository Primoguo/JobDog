# PDF处理高级参考

本文档包含高级PDF处理功能、详细示例和主技能说明中未涵盖的其他库。

## pypdfium2库（Apache/BSD许可证）

### 概述
pypdfium2是PDFium（Chromium的PDF库）的Python绑定。它非常适合快速PDF渲染、图像生成，并作为PyMuPDF的替代品。

### 将PDF渲染为图像
```python
import pypdfium2 as pdfium
from PIL import Image

# 加载PDF
pdf = pdfium.PdfDocument("document.pdf")

# 将页面渲染为图像
page = pdf[0]  # 第一页
bitmap = page.render(
    scale=2.0,  # 更高分辨率
    rotation=0  # 无旋转
)

# 转换为PIL图像
img = bitmap.to_pil()
img.save("page_1.png", "PNG")

# 处理多个页面
for i, page in enumerate(pdf):
    bitmap = page.render(scale=1.5)
    img = bitmap.to_pil()
    img.save(f"page_{i+1}.jpg", "JPEG", quality=90)
```

### 使用pypdfium2提取文本
```python
import pypdfium2 as pdfium

pdf = pdfium.PdfDocument("document.pdf")
for i, page in enumerate(pdf):
    text = page.get_text()
    print(f"第 {i+1} 页文本长度: {len(text)} 个字符")
```

## JavaScript库

### pdf-lib（MIT许可证）

pdf-lib是一个强大的JavaScript库，用于在任何JavaScript环境中创建和修改PDF文档。

#### 加载和操作现有PDF
```javascript
import { PDFDocument } from 'pdf-lib';
import fs from 'fs';

async function manipulatePDF() {
    // 加载现有PDF
    const existingPdfBytes = fs.readFileSync('input.pdf');
    const pdfDoc = await PDFDocument.load(existingPdfBytes);

    // 获取页数
    const pageCount = pdfDoc.getPageCount();
    console.log(`文档有 ${pageCount} 页`);

    // 添加新页面
    const newPage = pdfDoc.addPage([600, 400]);
    newPage.drawText('由pdf-lib添加', {
        x: 100,
        y: 300,
        size: 16
    });

    // 保存修改后的PDF
    const pdfBytes = await pdfDoc.save();
    fs.writeFileSync('modified.pdf', pdfBytes);
}

manipulatePDF();
```

#### 创建新PDF
```javascript
import { PDFDocument, rgb } from 'pdf-lib';
import fs from 'fs';

async function createPDF() {
    const pdfDoc = await PDFDocument.create();

    // 添加页面
    const page = pdfDoc.addPage([600, 400]);

    // 绘制文本
    page.drawText('Hello PDF-lib!', {
        x: 50,
        y: 350,
        size: 24,
        color: rgb(0, 0, 0),
    });

    // 绘制矩形
    page.drawRectangle({
        x: 50,
        y: 250,
        width: 200,
        height: 50,
        borderColor: rgb(0.5, 0.5, 0.5),
        borderWidth: 2,
    });

    // 保存
    const pdfBytes = await pdfDoc.save();
    fs.writeFileSync('new.pdf', pdfBytes);
}

createPDF();
```

### pdfjs-dist（Apache许可证）

Mozilla的PDF.js库，用于在浏览器中渲染PDF。

#### 在浏览器中渲染PDF
```html
<!DOCTYPE html>
<html>
<head>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script>
</head>
<body>
    <canvas id="pdf-render"></canvas>
    <script>
        pdfjsLib.GlobalWorkerOptions.workerSrc = 
            'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';
        
        const url = 'document.pdf';
        const canvas = document.getElementById('pdf-render');
        const ctx = canvas.getContext('2d');
        
        pdfjsLib.getDocument(url).promise.then(pdf => {
            pdf.getPage(1).then(page => {
                const viewport = page.getViewport({scale: 1.5});
                canvas.height = viewport.height;
                canvas.width = viewport.width;
                
                page.render({
                    canvasContext: ctx,
                    viewport: viewport
                });
            });
        });
    </script>
</body>
</html>
```

## 高级技巧

### 1. 文本提取优化

#### 保留布局
```python
import pdfplumber

# 提取文本时保留布局
with pdfplumber.open("document.pdf") as pdf:
    for page in pdf.pages:
        text = page.extract_text(layout=True)
        print(text)
```

#### 提取特定区域
```python
import pdfplumber

# 提取特定区域内的文本
with pdfplumber.open("document.pdf") as pdf:
    page = pdf.pages[0]
    # 定义裁剪区域 (x0, top, x1, bottom)
    cropped = page.crop((100, 100, 500, 400))
    text = cropped.extract_text()
    print(text)
```

### 2. 表格处理

#### 处理复杂表格
```python
import pdfplumber

with pdfplumber.open("document.pdf") as pdf:
    for page in pdf.pages:
        # 使用自定义设置提取表格
        tables = page.extract_tables({
            "vertical_strategy": "text",
            "horizontal_strategy": "text",
            "snap_tolerance": 5,
            "join_tolerance": 5,
        })
        for table in tables:
            for row in table:
                print(row)
```

### 3. 图像提取优化

#### 使用pdfimages快速提取
```bash
# 提取所有图像
pdfimages -all input.pdf image_prefix

# 只提取JPEG
pdfimages -j input.jpg output_prefix

# 提取高分辨率图像
pdfimages -all -l 10 input.pdf output_prefix  # 前10页
```

### 4. 表单处理

#### 使用pdf-lib填写表单
```javascript
import { PDFDocument } from 'pdf-lib';
import fs from 'fs';

async function fillForm() {
    const pdfBytes = fs.readFileSync('form.pdf');
    const pdfDoc = await PDFDocument.load(pdfBytes);
    
    const form = pdfDoc.getForm();
    
    // 填写文本字段
    const nameField = form.getTextField('name');
    nameField.setText('John Doe');
    
    // 填写复选框
    const checkbox = form.getCheckBox('agree');
    checkbox.check();
    
    // 填写下拉菜单
    const dropdown = form.getDropdown('country');
    dropdown.select('USA');
    
    const filledPdfBytes = await pdfDoc.save();
    fs.writeFileSync('filled.pdf', filledPdfBytes);
}

fillForm();
```

### 5. 内存管理

```python
# 分块处理PDF
def process_large_pdf(pdf_path, chunk_size=10):
    reader = PdfReader(pdf_path)
    total_pages = len(reader.pages)
    
    for start_idx in range(0, total_pages, chunk_size):
        end_idx = min(start_idx + chunk_size, total_pages)
        writer = PdfWriter()
        
        for i in range(start_idx, end_idx):
            writer.add_page(reader.pages[i])
        
        # 处理分块
        with open(f"chunk_{start_idx//chunk_size}.pdf", "wb") as output:
            writer.write(output)
```

## 性能建议

### 1. 对于文本提取
- 使用pdfplumber进行布局感知提取
- 对于大文档，避免使用`pypdf.extract_text()`
- 使用pypdfium2进行纯文本提取

### 2. 对于表格提取
- 使用pdfplumber处理结构化数据和表格
- 避免对非常大的文档使用`pypdf.extract_text()`

### 3. 对于图像提取
- `pdfimages`比渲染页面快得多
- 使用低分辨率进行预览，使用高分辨率进行最终输出

### 4. 对于表单填写
- pdf-lib比大多数替代方案更好地维护表单结构
- 在处理前预先验证表单字段

### 5. 内存管理
```python
# 分块处理PDF
def process_large_pdf(pdf_path, chunk_size=10):
    reader = PdfReader(pdf_path)
    total_pages = len(reader.pages)
    
    for start_idx in range(0, total_pages, chunk_size):
        end_idx = min(start_idx + chunk_size, total_pages)
        writer = PdfWriter()
        
        for i in range(start_idx, end_idx):
            writer.add_page(reader.pages[i])
        
        # 处理分块
        with open(f"chunk_{start_idx//chunk_size}.pdf", "wb") as output:
            writer.write(output)
```

## 常见问题故障排除

### 加密PDF
```python
# 处理受密码保护的PDF
from pypdf import PdfReader

try:
    reader = PdfReader("encrypted.pdf")
    if reader.is_encrypted:
        reader.decrypt("password")
except Exception as e:
    print(f"解密失败: {e}")
```

### 损坏的PDF
```bash
# 使用qpdf修复
qpdf --check corrupted.pdf
qpdf --replace-input corrupted.pdf
```

### 文本提取问题
```python
# 对扫描的PDF使用OCR作为后备
import pytesseract
from pdf2image import convert_from_path

def extract_text_with_ocr(pdf_path):
    images = convert_from_path(pdf_path)
    text = ""
    for i, image in enumerate(images):
        text += pytesseract.image_to_string(image)
    return text
```

## 许可证信息

- **pypdf**: BSD许可证
- **pdfplumber**: MIT许可证
- **pypdfium2**: Apache/BSD许可证
- **reportlab**: BSD许可证
- **poppler-utils**: GPL-2许可证
- **qpdf**: Apache许可证
- **pdf-lib**: MIT许可证
- **pdfjs-dist**: Apache许可证
