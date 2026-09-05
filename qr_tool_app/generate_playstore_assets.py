import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

def create_feature_graphic(width=1024, height=500):
    # Google Play Feature Graphic MUST be RGB (no transparency)
    img = Image.new("RGB", (width, height), (15, 23, 42)) # Deep Slate Navy #0F172A
    draw = ImageDraw.Draw(img)

    # 1. Subtle futuristic background gradient
    for y in range(height):
        factor = y / height
        r = int(15 + (10 - 15) * factor)
        g = int(23 + (15 - 23) * factor)
        b = int(42 + (75 - 42) * factor)
        draw.line([(0, y), (width, y)], fill=(r, g, b))

    # 2. Geometric grid / radar background lines
    grid_color = (30, 41, 59, 120)
    for x in range(0, width, 40):
        draw.line([(x, 0), (x, height)], fill=(26, 38, 64))
    for y in range(0, height, 40):
        draw.line([(0, y), (width, y)], fill=(26, 38, 64))

    # 3. Soft ambient glow behind the logo (cyan & indigo)
    glow_img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_img)
    glow_draw.ellipse([100, 100, 420, 420], fill=(6, 182, 212, 45))
    glow_draw.ellipse([550, 150, 950, 550], fill=(99, 102, 241, 35))
    glow_img = glow_img.filter(ImageFilter.GaussianBlur(50))
    img.paste(glow_img, (0, 0), glow_img)

    # 4. Load or render Ontero Logo on the left side
    logo_path = r"e:\qr_tool\qr_tool_app\assets\images\ontero_logo.png"
    if os.path.exists(logo_path):
        logo = Image.open(logo_path).convert("RGBA")
        logo_resized = logo.resize((260, 260), Image.Resampling.LANCZOS)
        # Position logo at (110, 120)
        img.paste(logo_resized, (110, 120), logo_resized)
    
    # 5. Right side typography: ONTERO QR + Tagline + Badges
    draw = ImageDraw.Draw(img)

    # Draw Badge "OFFICIAL • GLOBAL RELEASE"
    badge_x, badge_y = 420, 125
    badge_w, badge_h = 240, 28
    draw.rounded_rectangle([badge_x, badge_y, badge_x + badge_w, badge_y + badge_h], radius=14, fill=(6, 182, 212, 40), outline=(6, 182, 212), width=1)
    draw.text((badge_x + 18, badge_y + 6), "★ FAST & SECURE QR TOOL", fill=(34, 211, 238))

    # Big Title: "ONTERO QR"
    # Using fallback default or built-in font drawing
    try:
        font_title = ImageFont.truetype("arialbd.ttf", 62)
        font_sub = ImageFont.truetype("arialbd.ttf", 26)
        font_desc = ImageFont.truetype("arial.ttf", 18)
        font_badge = ImageFont.truetype("arialbd.ttf", 13)
    except Exception:
        font_title = ImageFont.load_default()
        font_sub = ImageFont.load_default()
        font_desc = ImageFont.load_default()
        font_badge = ImageFont.load_default()

    draw.text((420, 165), "ONTERO QR", fill=(255, 255, 255), font=font_title)
    draw.text((422, 240), "Scanner & Custom Generator", fill=(99, 102, 241), font=font_sub)

    # Feature points with checkmark bullets
    features = [
        "Instant Real-Time Camera & Gallery Scanner",
        "Generate Custom & Colored QR Codes (Wi-Fi, URLs, WhatsApp)",
        "Zero-Knowledge & 100% Offline Privacy Protection",
    ]

    y_pos = 295
    for feat in features:
        # Cyan glowing bullet
        draw.ellipse([422, y_pos + 4, 432, y_pos + 14], fill=(6, 182, 212))
        draw.text((444, y_pos), feat, fill=(226, 232, 240), font=font_desc)
        y_pos += 30

    # Modern bottom accent line
    for x in range(width):
        frac = x / width
        r = int(6 + (99 - 6) * frac)
        g = int(182 + (102 - 182) * frac)
        b = int(212 + (241 - 212) * frac)
        draw.line([(x, height - 6), (x, height)], fill=(r, g, b))

    return img

def main():
    output_dirs = [
        r"e:\qr_tool\playstore_assets",
        r"e:\qr_tool\qr_tool_app\assets\images",
    ]
    for d in output_dirs:
        os.makedirs(d, exist_ok=True)

    graphic = create_feature_graphic(1024, 500)
    for d in output_dirs:
        out_path = os.path.join(d, "feature_graphic_1024x500.png")
        graphic.save(out_path, "PNG", quality=95)
        print(f"Generated Feature Graphic: {out_path} ({graphic.size[0]}x{graphic.size[1]})")

if __name__ == "__main__":
    main()
