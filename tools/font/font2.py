import sys, random, math
from PIL import Image

import struct
fh = open("../../atari/demo/data/font_100.s", "w")
sys.stdout = fh

# -----------------------------------------------------------------------------
with Image.open("font1.png") as im:
    def scan_for(im, x, y, height, wanted):
        while x < 320:
            match = False
            for ytmp in range(y, y + height):
                if im.getpixel((x, ytmp)) != 0:
                    match = True
                    break
            if match == wanted:
                return x
            x += 1
        return None

    i = 0
    letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ/'+.-012345"

    widths = {}
    print("font_100_bitmaps:")
    for ybase in (0, 16):
        x = 0
        while True:
            x2 = scan_for(im, x, ybase, 16, False)
            c = letters[i]
            print(" ;", c, "-> ", x, " to ", x2, "width:", x2 - x)
            widths[c] = [x2 - x + 2, 32 * i]
            i += 1

            # Write out range
            vals = []
            for y in range(ybase, ybase + 16):
                acc = 0
                write = 0x8000
                for xt in range(x, x2):
                    if im.getpixel((xt, y)) != 0:
                        acc |= write
                    write >>= 1
                vals.append("$%x" % acc)

            print(" dc.w ", ','.join(vals))

            # Find start of next char
            x = scan_for(im, x2, ybase, 16, True)
            if x is None:
                break

print("font_100_widths:")
for i in range(32, 127):
    c = chr(i)
    if c in widths:
        print(" dc.w %d,%d  ;" % tuple(widths[c]) + c)
    else:
        print(" dc.w 8,-1")

fh.close()