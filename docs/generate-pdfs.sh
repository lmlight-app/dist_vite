#!/bin/zsh
# Generate PDFs and upload to R2
# Usage: ./generate-pdfs.sh         (generate only)
#        ./generate-pdfs.sh upload   (generate + upload to R2)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"
PDF_DIR="$SCRIPT_DIR/pdf"
VENV_DIR="$SCRIPT_DIR/.venv"
R2_DEST="r2:lmlightbinary/docs/"

export DYLD_LIBRARY_PATH="/opt/homebrew/lib:$DYLD_LIBRARY_PATH"
export PATH="/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin:$PATH"

mkdir -p "$PDF_DIR"

# Setup venv if needed
if [[ ! -f "$VENV_DIR/bin/python" ]]; then
  echo "Setting up Python venv..."
  uv venv "$VENV_DIR" 2>/dev/null
  uv pip install markdown weasyprint --python "$VENV_DIR/bin/python" 2>&1 | tail -3
fi

# Generate all PDFs from src/*.md -> pdf/*.pdf
SRC_DIR="$SRC_DIR" PDF_DIR="$PDF_DIR" "$VENV_DIR/bin/python" << 'PYEOF'
import os, re, glob, markdown
from weasyprint import HTML

SRC_DIR = os.environ.get("SRC_DIR", ".")
PDF_DIR = os.environ.get("PDF_DIR", ".")

CSS = """
@page { size: A4; margin: 20mm 18mm; }
body { font-family: "Hiragino Kaku Gothic ProN", "Noto Sans JP", "Meiryo", sans-serif; font-size: 11pt; line-height: 1.6; color: #333; }
h1 { font-size: 20pt; border-bottom: 2px solid #333; padding-bottom: 8px; }
h2 { font-size: 15pt; border-bottom: 1px solid #ccc; padding-bottom: 4px; margin-top: 24px; }
h3 { font-size: 13pt; margin-top: 18px; }
table { border-collapse: collapse; width: 100%; margin: 12px 0; font-size: 10pt; }
th, td { border: 1px solid #ccc; padding: 6px 10px; text-align: left; }
th { background-color: #f5f5f5; font-weight: bold; }
code { background: #f5f5f5; padding: 2px 4px; border-radius: 3px; font-size: 9pt; font-family: monospace; }
pre { background: #f5f5f5; padding: 12px; border-radius: 4px; font-size: 9pt; overflow-x: auto; white-space: pre-wrap; }
pre code { background: none; padding: 0; }
blockquote { border-left: 3px solid #ccc; padding-left: 12px; color: #666; margin-left: 0; }
hr { border: none; border-top: 1px solid #ddd; margin: 20px 0; }
"""

files = sorted(glob.glob(os.path.join(SRC_DIR, "*.md")))
success = 0

for src in files:
    name = os.path.splitext(os.path.basename(src))[0]
    out = os.path.join(PDF_DIR, f"{name}.pdf")
    print(f"{name}.pdf ...", end=" ", flush=True)
    try:
        with open(src, "r", encoding="utf-8") as f:
            md_text = f.read()
        md_text = re.sub(r'```mermaid\n.*?```', '<p><em>(図はシステム構成図を参照)</em></p>', md_text, flags=re.DOTALL)
        html_body = markdown.markdown(md_text, extensions=["tables", "fenced_code"])
        full_html = f'<!DOCTYPE html><html><head><meta charset="utf-8"><style>{CSS}</style></head><body>{html_body}</body></html>'
        HTML(string=full_html).write_pdf(out)
        print(f"OK ({os.path.getsize(out)//1024}KB)")
        success += 1
    except Exception as e:
        print(f"FAIL: {e}")

print(f"\nDone: {success}/{len(files)}")
PYEOF

# Upload to R2 if requested
if [[ "$1" == "upload" ]]; then
  echo ""
  echo "Uploading to R2..."
  rclone copy "$PDF_DIR/" "$R2_DEST" --progress --s3-no-check-bucket
  echo ""
  echo "Public URL: https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/docs/"
fi
