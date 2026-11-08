#!/usr/bin/env python3
"""Генератор фирменного стиля Fox Company.
Лиса — та же геометрическая мордочка, что в Fox Browser (lib/widgets/fox_logo.dart),
палитра «песок и кофе» (lib/theme.dart), шрифт Google Sans (текст переведён в контуры)."""
import os, random, sys
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

FONTS = sys.argv[1]           # папка со шрифтами GoogleSans-*.ttf
OUT = sys.argv[2]             # куда писать SVG
os.makedirs(OUT, exist_ok=True)

C = dict(sand='#F3EADF', cream='#FBF6EF', linen='#EDE2D3', latte='#8B6B4A', caramel='#B89B7A', espresso='#3B2F25',
         bark='#6E5A47', light='#D6BEA0', night='#1E1813', mocha='#29211A', cocoa='#352B22', roast='#43362B', beige='#D9BF9E')

def fox(x, y, s, brown=C['latte'], dark=C['espresso'], cream=C['cream'], light=C['light']):
    """Мордочка лисы в квадрате (x, y, s) — координаты из fox_logo.dart."""
    P = lambda pts: ' '.join(f'{x + a * s:.2f},{y + b * s:.2f}' for a, b in pts)
    polys = [
        ([(.18, .42), (.22, .08), (.45, .32)], brown), ([(.82, .42), (.78, .08), (.55, .32)], brown),
        ([(.24, .36), (.255, .16), (.40, .31)], dark), ([(.76, .36), (.745, .16), (.60, .31)], dark),
        ([(.15, .38), (.5, .28), (.85, .38), (.5, .92)], brown),
        ([(.15, .38), (.5, .62), (.5, .92)], cream), ([(.85, .38), (.5, .62), (.5, .92)], light),
        ([(.455, .85), (.545, .85), (.5, .92)], dark),
    ]
    out = ''.join(f'<polygon points="{P(p)}" fill="{c}"/>' for p, c in polys)
    for ex in (.37, .63):
        out += f'<circle cx="{x + ex * s:.2f}" cy="{y + .49 * s:.2f}" r="{.035 * s:.2f}" fill="{dark}"/>'
    return out

_fonts = {}
def text_path(txt, weight, size, x, y, fill, spacing=0.0, anchor='start'):
    """Текст в контурах. y — базовая линия, spacing — доля кегля между буквами."""
    if weight not in _fonts:
        f = TTFont(os.path.join(FONTS, f'GoogleSans-{weight}.ttf')); _fonts[weight] = f
    f = _fonts[weight]; gs = f.getGlyphSet(); cmap = f.getBestCmap(); upm = f['head'].unitsPerEm
    k = size / upm
    width = 0; glyphs = []
    for ch in txt:
        g = cmap.get(ord(ch)); glyphs.append((g, width))
        width += gs[g].width * k + spacing * size
    width -= spacing * size
    x0 = x - (width / 2 if anchor == 'middle' else width if anchor == 'end' else 0)
    d = ''
    for g, off in glyphs:
        pen = SVGPathPen(gs)
        gs[g].draw(TransformPen(pen, (k, 0, 0, -k, x0 + off, y)))
        d += pen.getCommands()
    return f'<path d="{d}" fill="{fill}"/>', width

def wrap(w, h, body, bg=None):
    rect = f'<rect width="{w}" height="{h}" fill="{bg}"/>' if bg else ''
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{rect}{body}</svg>\n'

def save(name, svg): open(os.path.join(OUT, name), 'w').write(svg)

def mark_circle(cx, cy, r, ring=None):
    """Круглый знак: лиса на кофейном круге (как во второй версии браузера)."""
    out = f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#52402F"/>'
    if ring: out += f'<circle cx="{cx}" cy="{cy}" r="{r - ring[1] / 2}" fill="none" stroke="{ring[0]}" stroke-width="{ring[1]}"/>'
    s = r * 1.42
    return out + fox(cx - s / 2, cy - s * 0.53, s)

# 1. Значок приложения / соцсетей (светлый и тёмный)
S = 1024
save('icon-light.svg', wrap(S, S, f'<rect width="{S}" height="{S}" rx="230" fill="{C["sand"]}"/>' + fox(S * .17, S * .14, S * .66)))
save('icon-dark.svg', wrap(S, S, f'<rect width="{S}" height="{S}" rx="230" fill="{C["night"]}"/>' + fox(S * .17, S * .14, S * .66, light=C['beige'])))
save('icon-circle.svg', wrap(S, S, f'<rect width="{S}" height="{S}" rx="230" fill="{C["sand"]}"/>' + mark_circle(S / 2, S / 2, S * .4)))

# 2. Аватар YouTube 800×800 (YouTube обрежет по кругу — всё важное в центре)
A = 800
save('youtube-avatar.svg', wrap(A, A, mark_circle(A / 2, A / 2, A * .44, ring=(C['caramel'], 10)), bg=C['sand']))

# 3. Водяной знак для видео (прозрачный фон)
save('watermark.svg', wrap(300, 300, mark_circle(150, 150, 140, ring=(C['cream'], 10))))

# 4. Горизонтальный логотип: знак + FOX COMPANY
def horizontal(dark_bg):
    H = 400; r = 170
    body = mark_circle(r + 20, H / 2, r)
    fox_t, w1 = text_path('FOX', 'Bold', 190, 2 * r + 80, H / 2 + 20, C['cream'] if dark_bg else C['espresso'], spacing=0.02)
    comp_t, w2 = text_path('COMPANY', 'Medium', 70, 2 * r + 86, H / 2 + 112, C['beige'] if dark_bg else C['latte'], spacing=0.32)
    W = int(2 * r + 80 + max(w1, w2) + 40)
    return wrap(W, H, body + fox_t + comp_t)
save('logo-horizontal-light.svg', horizontal(False))
save('logo-horizontal-dark.svg', horizontal(True))

# 5. Вертикальный логотип (знак над надписью)
def vertical(dark_bg):
    W, H = 900, 1000; r = 300
    body = mark_circle(W / 2, 330, r)
    t1, _ = text_path('FOX', 'Bold', 170, W / 2, 820, C['cream'] if dark_bg else C['espresso'], spacing=0.04, anchor='middle')
    t2, _ = text_path('COMPANY', 'Medium', 62, W / 2, 915, C['beige'] if dark_bg else C['latte'], spacing=0.4, anchor='middle')
    return wrap(W, H, body + t1 + t2)
save('logo-vertical-light.svg', vertical(False))
save('logo-vertical-dark.svg', vertical(True))

# 6. Баннер YouTube 2560×1440: низкополигональный «кофейный» фон, всё важное — в безопасной зоне 1546×423 в центре
BW, BH = 2560, 1440
rnd = random.Random(7)
cols = [C['night'], C['mocha'], C['cocoa'], C['roast'], '#2E251D', '#3A2E24']
step = 160
pts = {}
for j in range(-1, BH // step + 2):
    for i in range(-1, BW // step + 2):
        pts[(i, j)] = (i * step + rnd.uniform(-55, 55), j * step + rnd.uniform(-55, 55))
tris = ''
for j in range(-1, BH // step + 1):
    for i in range(-1, BW // step + 1):
        a, b, c, d = pts[(i, j)], pts[(i + 1, j)], pts[(i, j + 1)], pts[(i + 1, j + 1)]
        for tri in ((a, b, c), (b, d, c)):
            cx = sum(p[0] for p in tri) / 3; cy = sum(p[1] for p in tri) / 3
            dist = ((cx - BW / 2) / BW) ** 2 + ((cy - BH / 2) / BH) ** 2
            col = rnd.choice(cols[:4] if dist < 0.05 else cols)
            tris += f'<polygon points="{" ".join(f"{p[0]:.0f},{p[1]:.0f}" for p in tri)}" fill="{col}" stroke="{col}" stroke-width="1"/>'
# пара светлых «осколков» по краям в цветах лисы
deco = ''
for _ in range(26):
    x = rnd.choice([rnd.uniform(0, 420), rnd.uniform(BW - 420, BW)]); y = rnd.uniform(0, BH); s = rnd.uniform(30, 110)
    col = rnd.choice([C['latte'], C['caramel'], C['bark'], C['beige']])
    deco += f'<polygon points="{x:.0f},{y:.0f} {x + s:.0f},{y + s * .35:.0f} {x + s * .3:.0f},{y + s:.0f}" fill="{col}" opacity="{rnd.uniform(.25, .6):.2f}"/>'
glow = (f'<defs><radialGradient id="g" cx="50%" cy="50%" r="45%"><stop offset="0" stop-color="{C["latte"]}" stop-opacity=".35"/>'
        f'<stop offset="1" stop-color="{C["latte"]}" stop-opacity="0"/></radialGradient></defs><rect width="{BW}" height="{BH}" fill="url(#g)"/>')
r = 175; cx0 = BW / 2 - 420; cy0 = BH / 2
title, tw = text_path('FOX', 'Bold', 200, cx0 + r + 70, cy0 + 30, C['cream'], spacing=0.02)
comp, cw = text_path('COMPANY', 'Medium', 76, cx0 + r + 76, cy0 + 128, C['beige'], spacing=0.32)
tag, _ = text_path('браузеры · приложения · игры', 'Regular', 46, BW / 2, cy0 + 235, C['caramel'], spacing=0.02, anchor='middle')
banner = tris + deco + glow + mark_circle(cx0, cy0, r, ring=(C['caramel'], 8)) + title + comp + tag
save('youtube-banner.svg', wrap(BW, BH, banner))
print('ok')
