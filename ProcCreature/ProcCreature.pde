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
  
  void update(segment prev) {
    angle = atan2(prev.y-y,prev.x-x);
    float d = sqrt(pow(prev.x-x,2)+pow(prev.y-y,2));
    if(d > distance) {
      float delta = d - distance;
      x += delta*cos(angle);
      y += delta*sin(angle);
    }
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
  int len = 20; // Number of body segments
  float speed = 4; // Update speed
  
  creature() {
    body = new ArrayList<segment>();
    float r1 = 30; // radius of first segment
    for (int i = 0; i < len; i++) {
      float r = r1 - i*(r1/(len-1));
      body.add(new segment(width*0.5-i*r1, height*0.5, 0, r, r, i * 10));
    }
  }
  
  void update() {
    segment head = body.get(0);
    float a = atan2(mouseY-head.y, mouseX-head.x);
    float delta = a-head.angle;
    while (delta < -PI) {delta += (2*PI);}
    while (delta > PI) {delta -= (2*PI);}
    head.angle += 0.015*delta;
    head.x += speed*cos(head.angle);
    head.y += speed*sin(head.angle);
    for (int i = 1; i < len; i++) {
      segment current = body.get(i);
      segment pervious = body.get(i-1);
      current.update(pervious);
    }
  }
  
  void display() {
    segment head = body.get(0);
    noFill();
    pushMatrix();
    translate(head.x, head.y);
    rotate(head.angle);
    arc(0, 0, head.radius*4, head.radius*2, -0.5*PI, 0.5*PI);
    popMatrix();
    for (int i = 0; i < len-1; i++) {
      segment s = body.get(i);
      segment next = body.get(i+1);
      float x1, y1, x2, y2;
      x1 = s.x + s.radius*cos(s.angle-0.5*PI);
      y1 = s.y + s.radius*sin(s.angle-0.5*PI);
      x2 = next.x + next.radius*cos(next.angle-0.5*PI);
      y2 = next.y + next.radius*sin(next.angle-0.5*PI);
      line(x1, y1, x2, y2); // A line to one side to connect body segments
      x1 = s.x + s.radius*cos(s.angle+0.5*PI);
      y1 = s.y + s.radius*sin(s.angle+0.5*PI);
      x2 = next.x + next.radius*cos(next.angle+0.5*PI);
      y2 = next.y + next.radius*sin(next.angle+0.5*PI);
      line(x1, y1, x2, y2); // A line to the other side to connect body segments
      //s.display(); // display the circle
    }
  }
}

creature _creature;

void setup() {
  size(800, 1000);
  _creature = new creature();
}

void draw() {
  background(200);
  _creature.update();
  _creature.display();
}
