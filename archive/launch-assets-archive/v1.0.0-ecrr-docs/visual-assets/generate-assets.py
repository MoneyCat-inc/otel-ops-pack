#!/usr/bin/env python3
"""
Generate PNG assets from HTML banners for ECRR v1.0.0
Requires: playwright, pillow
Usage: python generate-assets.py
"""

import os
import asyncio
from playwright.async_api import async_playwright
from PIL import Image
import io

# Asset configurations
ASSETS = {
    'twitter': {
        'html': 'social-media/twitter-draft.html',
        'output': 'social-media/twitter-draft.png',
        'width': 1200,
        'height': 675
    },
    'linkedin': {
        'html': 'social-media/linkedin-draft.html',
        'output': 'social-media/linkedin-draft.png',
        'width': 1200,
        'height': 627
    },
    'instagram': {
        'html': 'social-media/instagram-story-draft.html',
        'output': 'social-media/instagram-story-draft.png',
        'width': 1080,
        'height': 1920
    },
    'bluesky': {
        'html': 'social-media/bluesky-draft.html',
        'output': 'social-media/bluesky-draft.png',
        'width': 1200,
        'height': 630
    },
    'youtube': {
        'html': 'video/youtube-thumbnail-draft.html',
        'output': 'video/youtube-thumbnail-draft.png',
        'width': 1280,
        'height': 720
    },
    'email_header': {
        'html': 'email/email-header-draft.html',
        'output': 'email/email-header-draft.png',
        'width': 600,
        'height': 200
    },
    'email_banner': {
        'html': 'email/email-banner-draft.html',
        'output': 'email/email-banner-draft.png',
        'width': 600,
        'height': 300
    }
}

async def generate_asset(playwright, asset_name, config):
    """Generate a single asset from HTML"""
    browser = await playwright.chromium.launch()
    page = await browser.new_page()
    
    # Set viewport size
    await page.set_viewport_size({
        'width': config['width'],
        'height': config['height']
    })
    
    # Load HTML file
    html_path = os.path.join('visual-assets-draft', config['html'])
    await page.goto(f'file://{os.path.abspath(html_path)}')
    
    # Wait for fonts to load
    await page.wait_for_load_state('networkidle')
    
    # Take screenshot
    screenshot = await page.screenshot(
        type='png',
        full_page=True,
        omit_background=True
    )
    
    # Save to file
    output_path = os.path.join('visual-assets-draft', config['output'])
    with open(output_path, 'wb') as f:
        f.write(screenshot)
    
    print(f"✅ Generated {asset_name}: {output_path}")
    
    await browser.close()

async def main():
    """Generate all assets"""
    print("🎨 Generating ECRR v1.0.0 visual assets...")
    
    async with async_playwright() as playwright:
        tasks = []
        for asset_name, config in ASSETS.items():
            task = generate_asset(playwright, asset_name, config)
            tasks.append(task)
        
        await asyncio.gather(*tasks)
    
    print("\n🎉 All assets generated successfully!")
    print("\n📁 Generated files:")
    for asset_name, config in ASSETS.items():
        print(f"  - {config['output']}")

if __name__ == "__main__":
    asyncio.run(main())
