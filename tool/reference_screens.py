"""Make local, unscaled visual QA pages from the supplied HTML (no source edits)."""
from pathlib import Path
import re

source = Path('.codex/references/deepseek_html_20261020_60ee13.html').read_text(encoding='utf-8')
head = source[:source.index('</head>')]
sprite = re.search(r'<svg width="0".*?</svg>', source, re.S).group()
fonts = ''.join(f"@font-face{{font-family:'{family}';font-weight:{weight};src:url('/assets/fonts/{family}-{weight}.ttf')}}"
                for family, weights in [('Geist', [400,500,600,700]), ('GeistMono', [400,500]), ('Rubik', [400,500,600])]
                for weight in weights)
fonts += "body{margin:0;padding:0;background:#0F1115}.phone{width:384px;height:720px;padding:12px;box-shadow:none;border-radius:0;margin:-12px}.screen{border-radius:0}.btn-primary{border-radius:14px}"
for index, match in enumerate(re.finditer(r'<div class="phone">', source)):
    depth = 0
    for tag in re.finditer(r'</?div\b[^>]*>', source[match.start():]):
        depth += -1 if tag.group().startswith('</') else 1
        if depth == 0:
            phone = source[match.start():match.start()+tag.end()]
            break
    html = head + '<style>' + fonts + '</style></head><body>' + sprite + phone + '</body></html>'
    Path(f'build/reference-{index}.html').write_text(html, encoding='utf-8')
print('Created six 360 × 696 content reference pages in build/.')
