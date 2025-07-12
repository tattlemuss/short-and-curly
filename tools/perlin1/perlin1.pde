int time = 0;
int partcount = 2;

int lat_size = 128;    // lattice size in px
float speed = 100;

class Vec2
{
  float x;
  float y;

  Vec2(float _x, float _y)
  {
    x = _x;
    y = _y;
  }
}

class SampleConf
{
  boolean divide = false;
}

class Part
{
  float x;
  float y;
  float mass;
  int _time;

  void reset()
  {
    float midx = 150.0 + 100.0 * sin(time * 0.02);
    float midy = 150.0 + 100.0 * sin(time * 0.01);
    x = random(70) + midx;
    y = random(70) + midy;
    mass = 300 + random(100);
    _time = int(random(300));
  }
}

Part[] parts = new Part[partcount];

float[][] gridx = new float[32][32];
float[][] gridy = new float[32][32];

Vec2 gridval(int x, int y)
{
  return new Vec2(gridx[x & 31][y & 31], gridy[x & 31][y & 31]);
}

float dot(Vec2 v, float x, float y)
{
  return v.x * x + v.y * y;
}

float sstep(float x)
{
  return x*x * (3 - 2 * x);
}

float interp(float a, float b, float sc)
{
  return a + (b-a) * sstep(sc);
}

float perlin(float x, float y)
{
  int xfl = floor(x);
  int yfl = floor(y);
  float xfr = x - xfl;
  float yfr = y - yfl;

  Vec2 v00 = gridval(xfl, yfl);
  Vec2 v01 = gridval(xfl + 1, yfl);
  Vec2 v10 = gridval(xfl, yfl + 1);
  Vec2 v11 = gridval(xfl + 1, yfl + 1);

  float d00 = dot(v00, -xfr, -yfr);
  float d01 = dot(v01, 1 - xfr, -yfr);
  float d10 = dot(v10, -xfr, 1 - yfr);
  float d11 = dot(v11, 1 - xfr, 1 - yfr);

  float di0 = interp(d00, d01, xfr);
  float di1 = interp(d10, d11, xfr);

  float dfinal = interp(di0, di1, yfr);
  return dfinal;
}

float ramp(float x)
{
  if (x < -1 || x > 1)
    return x;

  return (15.0 * x -
    10.0 * x*x*x +
    3.0 * x*x*x*x*x) / 8;
}

float dist(float x, float y)
{
  float dx = x - mouseX;
  float dy = y - mouseY;
  // "d(~x) is the distance to all solid boundaries"
  float d = sqrt(dx*dx + dy*dy) - 50;
  d /= lat_size;
  return d;
}

float sample(float x, float y, SampleConf sc)
{
  float basex = 0; // 2000 * sin(time * 0.002);
  float p = perlin((basex + x) / lat_size, y / lat_size);

  // Scale based on some factor
  //p *= 1 - (abs(y - mouseY) / 200);
  //    p *= (y / r400);

  p += 0.5 * perlin((basex + x) * 2 / lat_size, y * 2 / lat_size);

  /*
  // Border control
   float edgedist = 3000;
   edgedist = min(edgedist, x);
   edgedist = min(edgedist, y);
   edgedist = min(edgedist, 320 - x);
   edgedist = min(edgedist, 200 - y);
   if (sc.divide) {
   
   edgedist = min(edgedist, abs(152 - x));
   edgedist = min(edgedist, abs(168 - x));
   }
   if (edgedist < 32)
   p *= ramp( edgedist / 32.0);
   if (false) {
   float d = dist(x, y);
   if (d < 1)
   {
   p *= ramp(abs(d));
   }
   }
   */
  return p;
}


void init_grid(int seed)
{
  randomSeed(seed);
  for (int x = 0; x < 32; ++x)
    for (int y = 0; y < 32; ++y)
    {
      float ang = random(PI * 2);
      gridx[x][y] = cos(ang);
      gridy[x][y] = sin(ang);
    }
}

void init_parts() {
  for (int i = 0; i < partcount; ++i)
  {
    parts[i] = new Part();
    parts[i].reset();
  }
}

void write_buffer(String name, float speed, SampleConf sc) {
  PrintWriter output = createWriter("../../atari/demo/data/flowdat" + name + ".s");
  float dx = 0.01;
  float dy = 0.01;
  // Use 9:7 bits for the range
  int scalar = 1 << 7;
  for (int y = 0; y < 200; y+=8) {
    output.print(" dc.w ");
    for (int x = 0; x < 320; x+=8) {
      float s = sample(x, y, sc);
      float cx = +(sample(x, y + dy, sc) - s) / dy * speed;
      float cy = -(sample(x + dx, y, sc) - s) / dx * speed;

      if (x >= 320-8) {
        cx = -2;
      } else if (x <= 0) {
        cx += 2;
      }

      if (y >= 200-8) {
        cy = -2;
      } else if (y <= 0) {
        cy += 2;
      }

      if (x != 0) {
        output.write(",");
      }
      output.write(
        String.format("$%04x", int(cx * scalar) & 0xffff) + "," + 
        String.format("$%04x", int(cy * scalar) & 0xffff));
    }
    output.println();
  }
  output.close();
}


void write_buffer_divided(String name, float speed) {
  SampleConf sc = new SampleConf();
  sc.divide = true;

  PrintWriter output = createWriter("../../atari/demo/data/flowdat" + name + ".s");
  float dx = 0.01;
  float dy = 0.01;
  // Use 9:7 bits for the range
  int scalar = 1 << 7;
  for (int y = 0; y < 200; y+=8) {
    output.print(" dc.w ");
    for (int x = 0; x < 320; x+=8) {
      float s = sample(x, y, sc);
      float cx = +(sample(x, y + dy, sc) - s) / dy * speed;
      float cy = -(sample(x + dx, y, sc) - s) / dx * speed;

      if (x != 0) {
        output.write(",");
      }
      output.write(
        String.format("$%04x", int(cx * scalar) & 0xffff) + "," + 
        String.format("$%04x", int(cy * scalar) & 0xffff));
    }
    output.println();
  }
  output.close();
}

void write_buffer_burst() {
  float speed = 3.0f;
  PrintWriter output = createWriter("../../atari/demo/data/flowburst.s");
  // Use 9:7 bits for the range
  int scalar = 1 << 7;
  for (int y = 0; y < 200; y+=8) {
    output.print(" dc.w ");
    for (int x = 0; x < 320; x+=8) {
      float cx = x - 160;
      float cy = y - 100;
      float l = sqrt(cx*cx + cy*cy);
      cx /= l;
      cy /= l;
      if (x != 0) {
        output.write(",");
      }

      float speed2 = speed * ((320-l) / 320);    // slight falloff on edges
      output.write(
        String.format("$%04x", int(cx * speed2 * scalar) & 0xffff) + "," + 
        String.format("$%04x", int(cy * speed2 * scalar) & 0xffff));
    }
    output.println();
  }
  output.close();
}


void setup()
{
  size(400, 400);
  SampleConf sc = new SampleConf();

  init_grid(1);
  write_buffer("0", speed, sc);
  write_buffer_divided("div0", speed);

  init_grid(2);
  write_buffer("1", speed / 2, sc);
  init_grid(2);
  write_buffer("2", speed * 1.5, sc);
  write_buffer("tiny", 10, sc);

  init_grid(3);
  write_buffer("fast", speed * 3, sc);


  write_buffer_burst();

  init_grid(1);
  init_parts();
  noSmooth();
}

void draw() {
  //float lat_size = 0.01 + 0.05 * sin(time * 0.02);
  time++;
  SampleConf sc = new SampleConf();
  sc.divide = false;

  /*
  for (int x = 0; x < 400; ++x)
   {
   for (int y = 0; y < 400; ++y)
   {
   float p = perlin(x * lat_size, y * lat_size);
   //p += 0.5 * perlin(x * 0.04, y * 0.04);
   //p += 0.25 * perlin(x * 0.08, y * 0.08);
   stroke(int((p + 1) * 127));
   point(x, y);
   }
   }
   */
  float dx = 0.01;
  float dy = 0.01;

  //background(192);
  noStroke();
  stroke(0);
  //if (false)
  for (int i = 0; i < partcount; ++i)
  {
    Part p = parts[i];
    //float x = ((int)p.x / 8) * 8;
    //float y = ((int)p.y / 8) * 8;
    float x = p.x;
    float y = p.y;

    // Curl
    float s = sample(x, y, sc);
    float cx = +(sample(x, y + dy, sc) - s) / dy;
    float cy = -(sample(x + dx, y, sc) - s) / dx;

    //    int old_x = (int)p.x;
    //    int old_y = (int)p.y;
    p.x += cx * speed;
    p.y += cy * speed;

    float r = dist(p.x, p.y);
    /*
    if (r < 0)
     {
     fill(255, 0, 0);
     //      p.reset();
     } else if (r < 1)
     fill(0, 0, 255);
     else
     fill(0);
     */
    point(p.x, p.y);
    //    rect(old_x -2, old_y-2, 5, 5); // (int)p.x, (int) p.y);

    /*
    p._time -= 1;
     if (p._time < 0) {
     p.reset();
     p._time = 300;
     }
     */
  }

  stroke(192, 0, 0);
  fill(192, 0, 0);
  if (true)
    for (int x = 0; x < 400; x += 32)
    {
      for (int y = 0; y < 400; y += 32)
      {
        float s = sample(x, y, sc);
        float cx = +(sample(x, y + dy, sc) - s) / dy;
        float cy = -(sample(x + dx, y, sc) - s) / dx;
        float xe = x + lat_size * cx * 14;
        float ye = y + lat_size * cy * 14;
        line(x, y, xe, ye);
        ellipse(xe, ye, 2, 2);
      }
    }

  // ball
  ///  noFill();
  //  ellipse(mouseX, mouseY, 100, 100);
}

void keyPressed() {
  if (key == 't') {
    init_grid(0);
  }
  if (key == 's') {
    save("pic1.png");
  }
}
