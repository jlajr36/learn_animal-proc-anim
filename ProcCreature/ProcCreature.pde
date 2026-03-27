// This is from a tutorial by Programming Chaos
// It is a procedural animated creature.

class segment {
  float x, y;
  float angle;
  float distance;
  float radius;
  float hue;
  
  segment(float nx, float ny, float a, float d, float r, float h) {
    x = nx;
    y = ny;
    angle = a;
    distance = d;
    radius = r;
    hue = h;
  }
  
  void display() {
    pushMatrix();
    translate(x, y);
    rotate(angle);
    circle(0, 0, 2*radius);
    line(0, 0, distance, 0);
    popMatrix();
  }
}

class creature {
  ArrayList<segment> body;
  int len = 8; // Number of body segments
  
  creature() {
    body = new ArrayList<segment>();
    float r1 = 30; // radius of first segment
    for (int i = 0; i < len; i++) {
      float r = r1 - i*(r1/(len-1));
      body.add(new segment(width*0.5-i*r1, height*0.5, 0, r, r, i * 10.0));
    }
  }
  
  void display() {
    for (int i = 0; i < len; i++) {
      segment s = body.get(i);
      s.display();
    }
  }
}

creature _creature;

void setup() {
  size(800, 1000);
  _creature = new creature();
}

void draw() {
  _creature.display();
}
