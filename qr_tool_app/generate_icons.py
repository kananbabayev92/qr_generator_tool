import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

def create_ontero_logo(size=1024):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pad = int(size * 0.06)
    radius = int(size * 0.22)
    bg_box = [pad, pad, size - pad, size - pad]

    # Arxa fon üçün gradient effekti
    for i in range(pad, size - pad):
        factor = (i - pad) / (size - 2 * pad)
        # Deep Slate Navy (#0F172A) to Deep Indigo (#1E1B4B)
        r = int(15 + (30 - 15) * factor)
        g = int(23 + (27 - 23) * factor)
        b = int(42 + (75 - 42) * factor)
        img_line = ImageDraw.Draw(img)
        img_line.line([(pad, i), (size - pad, i)], fill=(r, g, b, 255))

    mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(bg_box, radius=radius, fill=255)
    img.putalpha(mask)

    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle(bg_box, radius=radius, outline=(99, 102, 241, 120), width=int(size * 0.015))

    center = size // 2
    box_size = int(size * 0.58)
    left = center - box_size // 2
    top = center - box_size // 2
    right = center + box_size // 2
    bottom = center + box_size // 2

    # Skaner Küncləri (Scanner Reticle Corners)
    corner_len = int(box_size * 0.26)
    c_w = int(size * 0.032)
    cyan_color = (6, 182, 212, 255)    # #06B6D4
    indigo_color = (99, 102, 241, 255)  # #6366F1

    # Sol Üst & Sağ Üst
    draw.line([(left, top), (left + corner_len, top)], fill=cyan_color, width=c_w)
    draw.line([(left, top), (left, top + corner_len)], fill=cyan_color, width=c_w)
    draw.line([(right - corner_len, top), (right, top)], fill=cyan_color, width=c_w)
    draw.line([(right, top), (right, top + corner_len)], fill=cyan_color, width=c_w)

    # Sol Aşağı & Sağ Aşağı
    draw.line([(left, bottom - corner_len), (left, bottom)], fill=indigo_color, width=c_w)
    draw.line([(left, bottom), (left + corner_len, bottom)], fill=indigo_color, width=c_w)
    draw.line([(right - corner_len, bottom), (right, bottom)], fill=indigo_color, width=c_w)
    draw.line([(right, bottom - corner_len), (right, bottom)], fill=indigo_color, width=c_w)

    def draw_finder_pattern(x, y, sz):
        draw.rounded_rectangle([x, y, x + sz, y + sz], radius=int(sz * 0.22), outline=(255, 255, 255, 240), width=int(sz * 0.2))
        in_p = int(sz * 0.35)
        draw.rounded_rectangle([x + in_p, y + in_p, x + sz - in_p, y + sz - in_p], radius=int(sz * 0.12), fill=cyan_color)

    p_size = int(box_size * 0.26)
    p_offset = int(box_size * 0.06)

    draw_finder_pattern(left + p_offset, top + p_offset, p_size)
    draw_finder_pattern(right - p_offset - p_size, top + p_offset, p_size)
    draw_finder_pattern(left + p_offset, bottom - p_offset - p_size, p_size)

    # QR Dekorativ Bitlər
    dot_sz = int(box_size * 0.06)
    dots = [
        (right - p_offset - p_size + dot_sz, bottom - p_offset - p_size),
        (right - p_offset - dot_sz * 2, bottom - p_offset - p_size + dot_sz),
        (right - p_offset - p_size // 2, bottom - p_offset - dot_sz * 2),
        (left + box_size // 2, top + p_offset + dot_sz),
        (left + box_size // 2 - dot_sz, bottom - p_offset - dot_sz),
        (right - p_offset - p_size + dot_sz * 2, bottom - p_offset - dot_sz * 2),
    ]
    for dx, dy in dots:
        draw.rounded_rectangle([dx, dy, dx + dot_sz, dy + dot_sz], radius=int(dot_sz * 0.3), fill=(255, 255, 255, 180))

    # Mərkəzdə parlaq 'O' (Ontero) simvolu
    o_outer_rad = int(box_size * 0.21)
    o_thick = int(size * 0.038)
    o_box = [center - o_outer_rad, center - o_outer_rad, center + o_outer_rad, center + o_outer_rad]
    draw.ellipse(o_box, outline=(255, 255, 255, 255), width=o_thick)
    
    # Mərkəzdə cyan fokus nöqtəsi
    dot_rad = int(size * 0.02)
    draw.ellipse([center - dot_rad, center - dot_rad, center + dot_rad, center + dot_rad], fill=cyan_color)

    # Neon Lazer Şüası
    laser_y = center + int(box_size * 0.12)
    laser_h = int(size * 0.012)
    draw.rectangle([left - int(size * 0.01), laser_y - laser_h, right + int(size * 0.01), laser_y + laser_h * 2], fill=(6, 182, 212, 90))
    draw.line([(left, laser_y), (right, laser_y)], fill=(255, 255, 255, 255), width=int(laser_h * 0.7))

    return img

def main():
    base_dir = r"e:\qr_tool\qr_tool_app"
    assets_dir = os.path.join(base_dir, "assets", "images")
    os.makedirs(assets_dir, exist_ok=True)

    master_logo = create_ontero_logo(1024)
    master_logo.save(os.path.join(assets_dir, "ontero_logo_1024.png"), "PNG")
    
    logo_512 = master_logo.resize((512, 512), Image.Resampling.LANCZOS)
    logo_512.save(os.path.join(assets_dir, "ontero_logo.png"), "PNG")
    print("Created assets/images/ontero_logo.png")

    mipmap_configs = [
        ("mipmap-mdpi", 48),
        ("mipmap-hdpi", 72),
        ("mipmap-xhdpi", 96),
        ("mipmap-xxhdpi", 144),
        ("mipmap-xxxhdpi", 192),
    ]
    res_base = os.path.join(base_dir, "android", "app", "src", "main", "res")
    for folder, dim in mipmap_configs:
        folder_path = os.path.join(res_base, folder)
        os.makedirs(folder_path, exist_ok=True)
        icon_img = master_logo.resize((dim, dim), Image.Resampling.LANCZOS)
        out_path = os.path.join(folder_path, "ic_launcher.png")
        icon_img.save(out_path, "PNG")
        print(f"Generated {folder}/ic_launcher.png ({dim}x{dim})")

if __name__ == "__main__":
    main()
