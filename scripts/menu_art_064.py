#!/usr/bin/env python3
"""v0.64: fit the title key art + boss-select monitor wall to the 398×224 viewport."""
from PIL import Image
A = "/home/box/agent-data/agents/66a8307e-b09a-4029-be0a-f63b78f273f6/assets/"
for src, dst in [("6d886d832ba5fb5139521a5f4b3c885b262562e55290f626be7cc4f3ffdafcf8.jpg", "title_keyart.png"),
                 ("899249207ea590ff86bf77bad6aed099b9f81db214d4f0b6a0c06249c836d3ff.jpg", "bossselect_wall.png")]:
    im = Image.open(A + src).convert("RGB")
    # 16:9 -> 398×224 (2px crop); box filter keeps chunky pixels crisp without ringing
    im = im.resize((398, 224), Image.BOX)
    im.save("game/assets/sprites/ui/" + dst)
    print(dst, im.size)
