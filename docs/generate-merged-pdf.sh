#!/bin/zsh
# Generate a single merged PDF from all docs/src/*.md for IT導入補助金 supplementary submission
# Usage: ./generate-merged-pdf.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"
IMG_DIR="$SCRIPT_DIR/src/img"
PDF_DIR="$SCRIPT_DIR/pdf"
VENV_DIR="$SCRIPT_DIR/.venv"

export DYLD_LIBRARY_PATH="/opt/homebrew/lib:$DYLD_LIBRARY_PATH"
export PATH="/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin:$PATH"

mkdir -p "$PDF_DIR"

if [[ ! -f "$VENV_DIR/bin/python" ]]; then
  echo "Setting up Python venv..."
  uv venv "$VENV_DIR" 2>/dev/null
  uv pip install markdown weasyprint --python "$VENV_DIR/bin/python" 2>&1 | tail -3
fi

OUTPUT="$PDF_DIR/DigitalBase_IT導入補助金_補足資料一式.pdf" \
SRC_DIR="$SRC_DIR" IMG_DIR="$IMG_DIR" "$VENV_DIR/bin/python" << 'PYEOF'
import os, re, glob, markdown
from weasyprint import HTML

SRC_DIR = os.environ["SRC_DIR"]
IMG_DIR = os.environ["IMG_DIR"]
OUTPUT = os.environ["OUTPUT"]

CSS = """
@page {
  size: A4;
  margin: 20mm 18mm 20mm 18mm;
  @bottom-center {
    content: counter(page) " / " counter(pages);
    font-size: 9pt;
    color: #666;
  }
  @top-right {
    content: "DigitalBase — IT導入補助金 補足資料";
    font-size: 8pt;
    color: #999;
  }
}
body {
  font-family: "Hiragino Kaku Gothic ProN", "Noto Sans JP", "Meiryo", sans-serif;
  font-size: 10.5pt;
  line-height: 1.65;
  color: #222;
}
h1 {
  font-size: 22pt;
  border-bottom: 3px solid #000;
  padding-bottom: 8px;
  margin-top: 0;
  page-break-before: always;
}
h1:first-of-type { page-break-before: avoid; }
h2 {
  font-size: 15pt;
  border-bottom: 1px solid #888;
  padding-bottom: 4px;
  margin-top: 22px;
}
h3 { font-size: 12.5pt; margin-top: 16px; }
h4 { font-size: 11pt; margin-top: 12px; }
table {
  border-collapse: collapse;
  width: 100%;
  margin: 10px 0;
  font-size: 9.5pt;
  page-break-inside: avoid;
}
th, td { border: 1px solid #888; padding: 5px 8px; text-align: left; vertical-align: top; }
th { background-color: #eee; font-weight: bold; }
code {
  background: #f0f0f0;
  padding: 1px 4px;
  border-radius: 2px;
  font-size: 9pt;
  font-family: "SF Mono", Menlo, monospace;
}
pre {
  background: #f5f5f5;
  padding: 10px;
  border-radius: 3px;
  font-size: 8.5pt;
  overflow-x: auto;
  white-space: pre-wrap;
  page-break-inside: avoid;
}
pre code { background: none; padding: 0; }
blockquote {
  border-left: 3px solid #888;
  padding-left: 10px;
  color: #555;
  margin-left: 0;
}
hr { border: none; border-top: 1px solid #bbb; margin: 16px 0; }
img { max-width: 100%; height: auto; page-break-inside: avoid; }
.toc { page-break-after: always; }
.toc ol { padding-left: 20px; }
.toc li { margin: 3px 0; font-size: 10.5pt; }
.cover {
  text-align: center;
  margin-top: 80px;
  page-break-after: always;
}
.cover h1 {
  font-size: 28pt;
  border: none;
  padding: 0;
}
.cover .subtitle { font-size: 14pt; margin-top: 12px; color: #555; }
.cover .meta { margin-top: 80px; font-size: 11pt; }
.ai-marker {
  background-color: #ffeb3b;
  padding: 2px 6px;
  border: 1px solid #f57f17;
  border-radius: 3px;
  font-weight: bold;
}
.doc-divider {
  page-break-before: always;
}
"""

# Documents to include (order matters)
ORDER = [
    "20_IT導入補助金_機能説明資料",
    "21_IT導入補助金_価格説明資料",
    "10_製品概要",
    "11_料金表",
    "13_導入事例",
    "17_システム構成図",
    "14_競合比較表",
    "15_FAQ",
    "16_セキュリティチェックシート",
    "12_導入提案書",
    "09_会社概要",
    "18_リリースノート",
    "05_SLA",
    "06_保守契約書",
    "02_EULA",
    "03_利用規約",
    "04_プライバシーポリシー",
]

# Build cover + TOC
cover_html = f"""
<div class="cover">
  <h1>DigitalBase</h1>
  <div class="subtitle">IT導入補助金 ITツール登録 補足資料（全資料マージ版）</div>
  <div class="meta">
    <p><strong>ITツール名:</strong> DigitalBase（デジタルベース）</p>
    <p><strong>開発メーカー名:</strong> デジタルベース株式会社</p>
    <p><strong>申請対象プラン:</strong> 永年買い切り スタンダード（1ユーザー）</p>
    <p><strong>最終更新日:</strong> 2026年4月</p>
  </div>
</div>
<div class="toc">
  <h1 style="page-break-before: avoid;">目次</h1>
  <ol>
"""
for i, name in enumerate(ORDER, 1):
    title = re.sub(r'^\d+_', '', name).replace('_', ' ')
    cover_html += f'    <li>{title}</li>\n'
cover_html += "  </ol>\n</div>\n"

# Merge all markdown files
merged_html = ""
for name in ORDER:
    src = os.path.join(SRC_DIR, f"{name}.md")
    if not os.path.exists(src):
        print(f"SKIP: {name}.md not found")
        continue
    print(f"Merging: {name}.md ...")
    with open(src, "r", encoding="utf-8") as f:
        md_text = f.read()
    # Strip mermaid blocks
    md_text = re.sub(r'```mermaid\n.*?```', '', md_text, flags=re.DOTALL)
    # Resolve img/ paths to absolute paths for WeasyPrint
    md_text = re.sub(
        r'!\[([^\]]*)\]\(img/([^)]+)\)',
        lambda m: f'![{m.group(1)}]({IMG_DIR}/{m.group(2)})',
        md_text
    )
    html_body = markdown.markdown(md_text, extensions=["tables", "fenced_code"])
    merged_html += f'<div class="doc-divider">{html_body}</div>\n'

full_html = f"""<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>DigitalBase IT導入補助金 補足資料</title>
  <style>{CSS}</style>
</head>
<body>
  {cover_html}
  {merged_html}
</body>
</html>
"""

print(f"\nGenerating PDF: {OUTPUT}")
HTML(string=full_html, base_url=SRC_DIR).write_pdf(OUTPUT)
size_kb = os.path.getsize(OUTPUT) // 1024
print(f"Done: {OUTPUT} ({size_kb} KB)")
PYEOF
