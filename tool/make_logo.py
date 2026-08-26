"""Génère le logo de l'app Quotient : dégradé indigo→rose, anneau de progression + coche."""
from PIL import Image, ImageDraw
import math

S = 1024          # taille finale
SCALE = 4         # supersampling pour l'anticrénelage
W = S * SCALE

# --- Dégradé diagonal indigo -> violet -> rose ---
c1 = (108, 99, 255)   # indigo
c2 = (168, 85, 247)   # violet
c3 = (236, 72, 153)   # rose

img = Image.new("RGB", (W, W), c1)
px = img.load()
for y in range(W):
    for x in range(0, W, SCALE):  # échantillonner puis lisser via resize
        t = (x + y) / (2 * W)
        if t < 0.5:
            k = t / 0.5
            r = int(c1[0] + (c2[0] - c1[0]) * k)
            g = int(c1[1] + (c2[1] - c1[1]) * k)
            b = int(c1[2] + (c2[2] - c1[2]) * k)
        else:
            k = (t - 0.5) / 0.5
            r = int(c2[0] + (c3[0] - c2[0]) * k)
            g = int(c2[1] + (c3[1] - c2[1]) * k)
            b = int(c2[2] + (c3[2] - c2[2]) * k)
        for dx in range(SCALE):
            if x + dx < W:
                px[x + dx, y] = (r, g, b)

draw = ImageDraw.Draw(img)

cx, cy = W / 2, W / 2

# --- Anneau de fond (semi-transparent blanc) ---
ring_r = W * 0.30
ring_w = int(W * 0.075)
bg_ring_color = (255, 255, 255, 90)
overlay = Image.new("RGBA", (W, W), (0, 0, 0, 0))
odraw = ImageDraw.Draw(overlay)
bbox = [cx - ring_r, cy - ring_r, cx + ring_r, cy + ring_r]
odraw.arc(bbox, start=0, end=360, fill=bg_ring_color, width=ring_w)

# --- Arc de progression (75%) en blanc plein ---
prog_color = (255, 255, 255, 255)
start_angle = -90
end_angle = -90 + 270
odraw.arc(bbox, start=start_angle, end=end_angle, fill=prog_color, width=ring_w)

# Point d'arrondi à la fin de l'arc
er = ring_w / 2 - 1
ex = cx + ring_r * math.cos(math.radians(end_angle))
ey = cy + ring_r * math.sin(math.radians(end_angle))
odraw.ellipse([ex - er, ey - er, ex + er, ey + er], fill=prog_color)

img = Image.alpha_composite(img.convert("RGBA"), overlay)
draw = ImageDraw.Draw(img)

# --- Coche blanche centrée dans l'anneau ---
check_pts = [
    (cx - W * 0.115, cy + W * 0.005),
    (cx - W * 0.03, cy + W * 0.09),
    (cx + W * 0.125, cy - W * 0.085),
]
draw.line(check_pts, fill=(255, 255, 255), width=int(W * 0.055), joint="curve")
# bouts arrondis
cw = W * 0.0275
for p in (check_pts[0], check_pts[2]):
    draw.ellipse([p[0] - cw, p[1] - cw, p[0] + cw, p[1] + cw], fill=(255, 255, 255))

# --- Redimensionnement final (lissage) ---
final = img.resize((S, S), Image.LANCZOS).convert("RGB")
final.save("assets/logo.png")
print("Logo créé : assets/logo.png")

# Version adaptative Android (foreground avec marges de safe-zone ~66%)
fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
inner = final.resize((int(S * 0.62), int(S * 0.62)), Image.LANCZOS)
fg.paste(inner, ((S - inner.width) // 2, (S - inner.height) // 2))
fg.save("assets/logo_foreground.png")
print("Foreground créé : assets/logo_foreground.png")
