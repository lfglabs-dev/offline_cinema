#!/usr/bin/env python3
"""
Generate macOS app icons from the offline_cinema.icon/Assets/output.png.
Creates properly sized icons for macOS app bundle.
"""

from PIL import Image
import os
import subprocess
import shutil
import json

# Icon sizes for macOS (size, scale, filename)
ICON_SIZES = [
    (16, 1, "icon_16x16.png"),
    (16, 2, "icon_16x16@2x.png"),
    (32, 1, "icon_32x32.png"),
    (32, 2, "icon_32x32@2x.png"),
    (128, 1, "icon_128x128.png"),
    (128, 2, "icon_128x128@2x.png"),
    (256, 1, "icon_256x256.png"),
    (256, 2, "icon_256x256@2x.png"),
    (512, 1, "icon_512x512.png"),
    (512, 2, "icon_512x512@2x.png"),
]


def create_icon(source_img, output_path, size, scale):
    """
    Create a macOS-style app icon at the specified size and scale.
    The source image should already have the proper design - we just resize.
    """
    actual_size = size * scale
    
    # Resize with high-quality resampling
    resized = source_img.resize((actual_size, actual_size), Image.Resampling.LANCZOS)
    
    # Ensure RGB (no alpha) - macOS applies its own mask
    # The source has black background which is perfect
    if resized.mode == "RGBA":
        # Composite over black background
        background = Image.new("RGB", (actual_size, actual_size), (0, 0, 0))
        background.paste(resized, (0, 0), resized)
        resized = background
    elif resized.mode != "RGB":
        resized = resized.convert("RGB")
    
    resized.save(output_path, "PNG")
    print(f"Created: {output_path} ({actual_size}x{actual_size})")


def generate_icns(input_dir, output_path):
    """Generate .icns file from iconset directory using iconutil."""
    try:
        iconset_path = output_path.replace(".icns", ".iconset")
        os.makedirs(iconset_path, exist_ok=True)

        icon_mapping = [
            ("icon_16x16.png", "icon_16x16.png"),
            ("icon_16x16@2x.png", "icon_16x16@2x.png"),
            ("icon_32x32.png", "icon_32x32.png"),
            ("icon_32x32@2x.png", "icon_32x32@2x.png"),
            ("icon_128x128.png", "icon_128x128.png"),
            ("icon_128x128@2x.png", "icon_128x128@2x.png"),
            ("icon_256x256.png", "icon_256x256.png"),
            ("icon_256x256@2x.png", "icon_256x256@2x.png"),
            ("icon_512x512.png", "icon_512x512.png"),
            ("icon_512x512@2x.png", "icon_512x512@2x.png"),
        ]

        for src_name, dst_name in icon_mapping:
            src = os.path.join(input_dir, src_name)
            dst = os.path.join(iconset_path, dst_name)
            if os.path.exists(src):
                shutil.copy2(src, dst)

        result = subprocess.run(
            ["iconutil", "-c", "icns", iconset_path, "-o", output_path],
            capture_output=True,
            text=True,
        )

        if result.returncode == 0:
            print(f"Created: {output_path}")
            shutil.rmtree(iconset_path)
            return True
        else:
            print(f"Error creating .icns: {result.stderr}")
            return False

    except Exception as e:
        print(f"Error generating .icns: {e}")
        return False


def update_contents_json(output_dir):
    """Update the Contents.json file with the generated icon filenames."""
    contents = {
        "images": [
            {"filename": "icon_16x16.png", "idiom": "mac", "scale": "1x", "size": "16x16"},
            {"filename": "icon_16x16@2x.png", "idiom": "mac", "scale": "2x", "size": "16x16"},
            {"filename": "icon_32x32.png", "idiom": "mac", "scale": "1x", "size": "32x32"},
            {"filename": "icon_32x32@2x.png", "idiom": "mac", "scale": "2x", "size": "32x32"},
            {"filename": "icon_128x128.png", "idiom": "mac", "scale": "1x", "size": "128x128"},
            {"filename": "icon_128x128@2x.png", "idiom": "mac", "scale": "2x", "size": "128x128"},
            {"filename": "icon_256x256.png", "idiom": "mac", "scale": "1x", "size": "256x256"},
            {"filename": "icon_256x256@2x.png", "idiom": "mac", "scale": "2x", "size": "256x256"},
            {"filename": "icon_512x512.png", "idiom": "mac", "scale": "1x", "size": "512x512"},
            {"filename": "icon_512x512@2x.png", "idiom": "mac", "scale": "2x", "size": "512x512"},
        ],
        "info": {"author": "xcode", "version": 1},
    }

    contents_path = os.path.join(output_dir, "Contents.json")
    with open(contents_path, "w") as f:
        json.dump(contents, f, indent=2)
    print(f"Updated: {contents_path}")


def crop_to_square(img):
    """Crop image to center square."""
    width, height = img.size
    if width == height:
        return img
    
    # Crop to center square
    size = min(width, height)
    left = (width - size) // 2
    top = (height - size) // 2
    right = left + size
    bottom = top + size
    
    return img.crop((left, top, right, bottom))


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    source_path = os.path.join(script_dir, "offline_cinema.icon", "Assets", "output.png")
    output_dir = os.path.join(script_dir, "OfflineCinema", "Assets.xcassets", "AppIcon.appiconset")
    icns_path = os.path.join(script_dir, "OfflineCinema.app", "Contents", "Resources", "AppIcon.icns")

    if not os.path.exists(source_path):
        print(f"Error: Source icon not found at {source_path}")
        return 1

    os.makedirs(output_dir, exist_ok=True)

    print("=" * 60)
    print("Generating macOS app icons for Offline Cinema")
    print("=" * 60)
    print(f"Source: {source_path}")
    print(f"Output: {output_dir}")
    print()

    # Load source image and crop to square
    source_img = Image.open(source_path).convert("RGBA")
    print(f"Original image size: {source_img.size}")
    source_img = crop_to_square(source_img)
    print(f"Cropped to square: {source_img.size}")
    print()

    # Generate all icon sizes
    for size, scale, filename in ICON_SIZES:
        output_path = os.path.join(output_dir, filename)
        create_icon(source_img, output_path, size, scale)

    # Update Contents.json
    update_contents_json(output_dir)

    # Generate .icns file - save to branding folder (persistent) and app bundle
    branding_icns = os.path.join(script_dir, "branding", "AppIcon.icns")
    os.makedirs(os.path.dirname(branding_icns), exist_ok=True)
    
    print()
    print("Generating .icns file...")
    generate_icns(output_dir, branding_icns)
    
    # Also copy to app bundle if it exists
    icns_dir = os.path.dirname(icns_path)
    if os.path.exists(icns_dir):
        shutil.copy2(branding_icns, icns_path)
        print(f"Copied to: {icns_path}")

    print()
    print("=" * 60)
    print("✅ App icons generated successfully!")
    print("=" * 60)
    print()
    print("Next steps:")
    print("1. Open Xcode and verify the icons in Assets.xcassets")
    print("2. Rebuild the app to apply the new icons")
    print()

    return 0


if __name__ == "__main__":
    exit(main())

