"""
    This script generates the bitmap for the rotated sprites.
    
    All the generation is done programmatically, which tends to 
    give nicer results that rotating a bitmap.
"""

PI = 3.14159265
import math
half_width = 8 # this is half-width
tri_radius = half_width + .5
angle_shift = 6
angle_count = 1 << angle_shift

def inside(p1, p2, test):
    """ Check which side of a line p1-p2 the point "test" lies. """
    p1p2   = (  p2[0] - p1[0],   p2[1] - p1[1])
    p1test = (test[0] - p1[0], test[1] - p1[1])

    # generate normal
    normal = (p1p2[1], -p1p2[0])

    dot_p1test = normal[0] * p1test[0] + normal[1] * p1test[1]
    return dot_p1test >= 0

class tri_test:
    def __init__(self, base_angle, tri_radius):
        # Generate points
        rad2 = base_angle + 1 * 2 * PI / 3
        rad3 = base_angle + 2 * 2 * PI / 3
        self.p1 = (tri_radius * math.sin(base_angle), tri_radius * math.cos(base_angle))
        self.p2 = (tri_radius * math.sin(rad2), tri_radius * math.cos(rad2))
        self.p3 = (tri_radius * math.sin(rad3), tri_radius * math.cos(rad3))
    def inside(self, x, y):
        test = (x + .5, y + .5)
        set = True
        set &= inside(self.p1, self.p2, test)
        set &= inside(self.p2, self.p3, test)
        set &= inside(self.p3, self.p1, test)                        
        return set

class quad_test:
    def __init__(self, base_angle, tri_radius):
        # Generate points
        rad2 = base_angle + 1 * 2 * PI / 4
        rad3 = base_angle + 2 * 2 * PI / 4
        rad4 = base_angle + 3 * 2 * PI / 4
        self.p1 = (tri_radius * math.sin(base_angle), tri_radius * math.cos(base_angle))
        self.p2 = (tri_radius * math.sin(rad2), tri_radius * math.cos(rad2))
        self.p3 = (tri_radius * math.sin(rad3), tri_radius * math.cos(rad3))
        self.p4 = (tri_radius * math.sin(rad4), tri_radius * math.cos(rad4))
    def inside(self, x, y):
        test = (x + .5, y + .5)
        set = True
        set &= inside(self.p1, self.p2, test)
        set &= inside(self.p2, self.p3, test)
        set &= inside(self.p3, self.p4, test)                        
        set &= inside(self.p4, self.p1, test)                        
        return set

class stick_test:
    def __init__(self, base_angle, tri_radius):
        # Generate rotated rectangle
        b = 3
        a = tri_radius

        m00 =  math.cos(base_angle)
        m01 =  math.sin(base_angle)
        m10 = -math.sin(base_angle)
        m11 =  math.cos(base_angle)
        def mul(a, b):
            return (a * m00 + b * m01, a * m10 + b * m11) 
        self.p1 = mul(+a, +b)
        self.p2 = mul(+a, -b)
        self.p3 = mul(-a, -b)
        self.p4 = mul(-a, +b)

    def inside(self, x, y):
        test = (x + .5, y + .5)
        set = True
        set &= inside(self.p1, self.p2, test)
        set &= inside(self.p2, self.p3, test)
        set &= inside(self.p3, self.p4, test)                        
        set &= inside(self.p4, self.p1, test)                        
        return set


class arrow_test:
    def __init__(self, base_angle, tri_radius):
        # Generate rotated rectangle
        b = 3
        a = tri_radius

        m00 =  math.cos(base_angle)
        m01 =  math.sin(base_angle)
        m10 = -math.sin(base_angle)
        m11 =  math.cos(base_angle)
        def mul(a, b):
            return (a * m00 + b * m01, a * m10 + b * m11)

        self.p1 = mul( 0, +b)
        self.p2 = mul( 0, -b)
        self.p3 = mul(-a, -b)
        self.p4 = mul(-a, +b)

        self.tip1 = mul(0, +a)
        self.tip2 = mul(+a, 0)
        self.tip3 = mul(0, -a)

    def inside(self, x, y):
        test = (x + .5, y + .5)
        set = True
        set &= inside(self.p1, self.p2, test)
        set &= inside(self.p2, self.p3, test)
        set &= inside(self.p3, self.p4, test)
        set &= inside(self.p4, self.p1, test)

        tip = True
        tip &= inside(self.tip1, self.tip2, test)
        tip &= inside(self.tip2, self.tip3, test)
        tip &= inside(self.tip3, self.tip1
                      , test)

        return set | tip


print("SPRITE_ANGLE_SHIFT=%d" % angle_shift)
print("SPRITE_ANGLE_COUNT=%d" % angle_count)
print("BYTES_PER_SPRITE=%d" % (half_width * half_width * 2 * 2 / 8))
print("SPRITE_DATA_SIZE=%d" % (angle_count * 32))

def generate(name, classfunc):
    print("sprite_%s:" % name)
    for ang in range(0, angle_count):
        base_angle = ang * 2 * PI / angle_count
        t = classfunc(base_angle,tri_radius)
        for y in range(-half_width, half_width):
            s = ''
            for x in range(-half_width, half_width):
                set = t.inside(x, y)
                if set:
                    s += "1"
                else:
                    s += "0"
            print(" dc.w %%%s" % s)
        print


generate("tri2", tri_test)
generate("quad", quad_test)
generate("stick2", stick_test)
generate("arrow", arrow_test)
