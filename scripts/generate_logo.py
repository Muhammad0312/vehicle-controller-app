#!/usr/bin/env python3
"""
Simple logo generator for Vehicle Controller app
Creates a clean, minimal logo with a steering wheel design
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_logo(size=1024, output_path="../assets/icons/vehicle_controller_logo.png"):
    """Create a simple vehicle controller logo"""
    
    # Create a new image with transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Background color (same as app icon background)
    bg_color = (1, 37, 44)  # #01252c
    draw.ellipse([0, 0, size, size], fill=bg_color)
    
    # Draw a simple steering wheel design
    center = size // 2
    radius = int(size * 0.35)
    
    # Outer circle (steering wheel rim)
    draw.ellipse(
        [center - radius, center - radius, center + radius, center + radius],
        outline=(255, 255, 255, 255),
        width=int(size * 0.08)
    )
    
    # Inner circle (steering wheel center)
    inner_radius = int(radius * 0.3)
    draw.ellipse(
        [center - inner_radius, center - inner_radius, center + inner_radius, center + inner_radius],
        fill=(255, 255, 255, 255)
    )
    
    # Horizontal spoke
    draw.line(
        [center - radius, center, center + radius, center],
        fill=(255, 255, 255, 255),
        width=int(size * 0.06)
    )
    
    # Vertical spoke
    draw.line(
        [center, center - radius, center, center + radius],
        fill=(255, 255, 255, 255),
        width=int(size * 0.06)
    )
    
    # Create directory if it doesn't exist
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    # Save the image
    img.save(output_path, 'PNG')
    print(f"Logo created: {output_path}")
    return output_path

if __name__ == "__main__":
    # Create logo at different sizes for app icon
    sizes = [1024, 512, 256, 128]
    for size in sizes:
        output = f"../assets/icons/vehicle_controller_logo_{size}.png"
        create_logo(size, output)
    
    # Also create the main logo file
    create_logo(1024, "../assets/icons/vehicle_controller_logo.png")
    print("\nAll logo files created successfully!")
