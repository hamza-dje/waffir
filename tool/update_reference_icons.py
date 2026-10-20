"""Apply the supplied symbol to project copies of the HTML references."""
from pathlib import Path
import re

root = Path(__file__).resolve().parent.parent
svg = (root / 'assets/dzd.svg').read_text(encoding='utf-8')
svg = svg[svg.index('<svg '):]
# Preserve geometry; let each preview choose the ink color.
svg = svg.replace('fill:rgb(255,0,0)', 'fill:currentColor')
for path in (root / 'references').glob('*.html'):
    html = path.read_text(encoding='utf-8')
    replacement = '<symbol id="app-icon" viewBox="0 0 120 120"><rect width="120" height="120" rx="20" fill="#34D399"/><svg x="34" y="18" width="52" height="84" viewBox="0 0 624 993" style="color:#06251A">' + svg[svg.index('>') + 1:svg.rindex('</svg>')] + '</svg></symbol>'
    html = re.sub(r'<symbol\b[^>]*\bid="app-icon"[^>]*>.*?</symbol>', lambda _: replacement, html, flags=re.S)
    html = re.sub(r'(<div class="brand-mark">).*?(</div>)', lambda m: m[1] + svg.replace('<svg ', '<svg style="width:24px;height:32px;color:#06251A" ', 1) + m[2], html, flags=re.S)
    path.write_text(html, encoding='utf-8')
