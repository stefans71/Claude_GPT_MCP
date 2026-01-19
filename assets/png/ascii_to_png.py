#!/usr/bin/env python3
"""
ASCII Logo to PNG Converter
Converts ASCII art logos to PNG images with transparent backgrounds
"""

from PIL import Image, ImageDraw, ImageFont
import os

# Brand colors (RGB)
COLORS = {
    'anthropic_orange': (255, 135, 0),      # Orange #FF8700
    'openrouter_blue': (0, 135, 255),       # Blue #0087FF
    'github_gray': (180, 180, 180),         # Light gray
    'white': (255, 255, 255),
    'green': (0, 255, 0),
    'cyan': (0, 255, 255),
}

# ASCII Logos
ANTHROPIC_LOGO = """
        506     3091   385 4008000087 091    09  19808891      40087    6808882   06       28081        
       58904    28882  285    706     093    097 790   7407  892  1985  681   484 786    8857 7985      
      286 105   282389 385     04     0800800897 198000009  805     867 689968081  185  684             
     388888885  282  90884     04     091    09  190  7607  784    604  68          385  091   686      
    309     405 205   1005     06     083    087 790    506   3900027   907          204  1600827       
"""

OPENROUTER_LOGO = """
 ██████╗ ██████╗ ███████╗███╗   ██╗██████╗  ██████╗ ██╗   ██╗████████╗███████╗██████╗ 
██╔═══██╗██╔══██╗██╔════╝████╗  ██║██╔══██╗██╔═══██╗██║   ██║╚══██╔══╝██╔════╝██╔══██╗
██║   ██║██████╔╝█████╗  ██╔██╗ ██║██████╔╝██║   ██║██║   ██║   ██║   █████╗  ██████╔╝
██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║██╔══██╗██║   ██║██║   ██║   ██║   ██╔══╝  ██╔══██╗
╚██████╔╝██║     ███████╗██║ ╚████║██║  ██║╚██████╔╝╚██████╔╝   ██║   ███████╗██║  ██║
 ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝╚═╝  ╚═╝
"""

GITHUB_LOGO = """
                 ----------                      
             -------------------*                 
          -------------------------*              
        ------------------------------            
      *----   *----------------*   -----          
     -----       -          *      ------         
   -------                         --------       
   --------                        --------       
  -------*                           -------      
  -------                            *------      
  ------*                            *------      
  -------                            *------      
  -------                            -------      
  -------*                          --------      
  ---------                        --------*      
   ---*-*----                    ----------       
    ----   -------          -------------*        
     ----    *--*            ------------         
       ---                   ----------           
         ---                 --------             
           *-----            ------               
              ---            ---                  
"""

def get_font(size=14):
    """Try to get a good monospace font"""
    font_paths = [
        # Windows
        "C:/Windows/Fonts/consola.ttf",
        "C:/Windows/Fonts/cour.ttf",
        # Linux
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
        "/usr/share/fonts/truetype/ubuntu/UbuntuMono-R.ttf",
        # Mac
        "/System/Library/Fonts/Monaco.ttf",
        "/Library/Fonts/Courier New.ttf",
    ]
    
    for path in font_paths:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    
    # Fallback to default
    try:
        return ImageFont.truetype("DejaVuSansMono.ttf", size)
    except:
        return ImageFont.load_default()

def ascii_to_png(ascii_art, color, output_path, font_size=16, padding=20, scale=1):
    """
    Convert ASCII art to PNG with transparent background
    
    Args:
        ascii_art: The ASCII art string
        color: RGB tuple for text color
        output_path: Where to save the PNG
        font_size: Font size in pixels
        padding: Padding around the image
        scale: Scale factor for the final image
    """
    # Clean up the ASCII art
    lines = ascii_art.strip('\n').split('\n')
    
    # Get font
    font = get_font(font_size)
    
    # Calculate image size
    # Use a temporary image to measure text
    temp_img = Image.new('RGBA', (1, 1), (0, 0, 0, 0))
    temp_draw = ImageDraw.Draw(temp_img)
    
    # Find the widest line and total height
    max_width = 0
    line_height = font_size + 2
    
    for line in lines:
        bbox = temp_draw.textbbox((0, 0), line, font=font)
        width = bbox[2] - bbox[0]
        if width > max_width:
            max_width = width
    
    total_height = len(lines) * line_height
    
    # Create the actual image with transparent background
    img_width = max_width + (padding * 2)
    img_height = total_height + (padding * 2)
    
    img = Image.new('RGBA', (img_width, img_height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw each line
    y = padding
    for line in lines:
        draw.text((padding, y), line, font=font, fill=(*color, 255))
        y += line_height
    
    # Scale if needed
    if scale != 1:
        new_size = (int(img_width * scale), int(img_height * scale))
        img = img.resize(new_size, Image.LANCZOS)
    
    # Save
    img.save(output_path, 'PNG')
    print(f"✓ Saved: {output_path} ({img.width}x{img.height})")
    return img

def create_all_logos(output_dir="logos"):
    """Create all logo variations"""
    
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    print("Creating ASCII logo PNGs...\n")
    
    # Anthropic - Orange
    ascii_to_png(
        ANTHROPIC_LOGO,
        COLORS['anthropic_orange'],
        f"{output_dir}/anthropic-logo.png",
        font_size=16
    )
    ascii_to_png(
        ANTHROPIC_LOGO,
        COLORS['anthropic_orange'],
        f"{output_dir}/anthropic-logo-small.png",
        font_size=10
    )
    
    # OpenRouter - Blue
    ascii_to_png(
        OPENROUTER_LOGO,
        COLORS['openrouter_blue'],
        f"{output_dir}/openrouter-logo.png",
        font_size=16
    )
    ascii_to_png(
        OPENROUTER_LOGO,
        COLORS['openrouter_blue'],
        f"{output_dir}/openrouter-logo-small.png",
        font_size=10
    )
    
    # GitHub - Gray
    ascii_to_png(
        GITHUB_LOGO,
        COLORS['github_gray'],
        f"{output_dir}/github-logo.png",
        font_size=16
    )
    ascii_to_png(
        GITHUB_LOGO,
        COLORS['github_gray'],
        f"{output_dir}/github-logo-small.png",
        font_size=10
    )
    
    print(f"\n✓ All logos saved to '{output_dir}/' directory")
    print("\nUsage in README.md:")
    print('  ![Anthropic](logos/anthropic-logo.png)')
    print('  ![OpenRouter](logos/openrouter-logo.png)')
    print('  ![GitHub](logos/github-logo.png)')

if __name__ == "__main__":
    create_all_logos()
