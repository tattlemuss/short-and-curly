import math
import struct

if __name__=='__main__':
    # Calc all offsets
    vals = []
    for y in range(0, 25):
        for x in range(0, 40):
            dy = y - 12.5
            dx = x - 20
            dist = math.sqrt(dx*dx + dy*dy)
            vals.append((dist, x, y))

    vals.sort(key=lambda a : a[0], reverse=False)       # central first
    assert(len(vals) == 1000)
    wipe_fh = open("../../atari/demo/data/wipe_circle.bin", "wb")
    for v in vals:
        off = 4 * (v[1] + 40*v[2])
        t = struct.pack(">H", off)
        wipe_fh.write(t)
    wipe_fh.close()
