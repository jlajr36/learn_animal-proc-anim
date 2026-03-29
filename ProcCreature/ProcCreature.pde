float LIGHT_BLUE_H = 200;
float LIGHT_BLUE_S = 30;
float LIGHT_BLUE_B = 95;

float FIN_H = 20;
float FIN_S = 60;
float FIN_B = 85;

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
    angle = atan2(prev.y-y, prev.x-x);
    float d = sqrt(pow(prev.x-x,2) + pow(prev.y-y,2));
    if (d > distance) {
      float delta = d - distance;
      x += delta * cos(angle);
      y += delta * sin(angle);
    }
  }
  
  void display() {
    fill(LIGHT_BLUE_H, LIGHT_BLUE_S, LIGHT_BLUE_B);
    stroke(LIGHT_BLUE_H, LIGHT_BLUE_S, LIGHT_BLUE_B);
    strokeWeight(1);
    pushMatrix();
    translate(x, y);
    rotate(angle);
    circle(0, 0, 2*radius);
    popMatrix();
  }
}

class creature {
  ArrayList<segment> body;
  int len = 20;
  float speed = 4;
  
  creature() {
    body = new ArrayList<segment>();
    float r1 = 30;
    for (int i = 0; i < len; i++) {
      float r = r1 - i*(r1/(len-1));
      body.add(new segment(width*0.5 - i*r1, height*0.5, 0, r, r, i * 10));
    }
  }
  
  void update() {
    segment head = body.get(0);
    float a = atan2(mouseY - head.y, mouseX - head.x);
    float delta = a - head.angle;
    while (delta < -PI) { delta += (2*PI); }
    while (delta > PI) { delta -= (2*PI); }
    head.angle += 0.015 * delta;
    head.x += speed * cos(head.angle);
    head.y += speed * sin(head.angle);
    for (int i = 1; i < len; i++) {
      segment current = body.get(i);
      segment pervious = body.get(i-1);
      current.update(pervious);
    }
  }
  
  void display() {
    segment head = body.get(0);
    fill(LIGHT_BLUE_H, LIGHT_BLUE_S, LIGHT_BLUE_B);
    stroke(LIGHT_BLUE_H, LIGHT_BLUE_S, LIGHT_BLUE_B);
    strokeWeight(1);
    pushMatrix();
    translate(head.x, head.y);
    rotate(head.angle);
    arc(0, 0, head.radius*4, head.radius*2, -0.5*PI, 0.5*PI);
    popMatrix();
    for (int i = 0; i < len-1; i++) {
      segment s = body.get(i);
      s.display();
      segment next = body.get(i+1);
      
      float x1a = s.x + s.radius * cos(s.angle - 0.5*PI);
      float y1a = s.y + s.radius * sin(s.angle - 0.5*PI);
      float x1b = s.x + s.radius * cos(s.angle + 0.5*PI);
      float y1b = s.y + s.radius * sin(s.angle + 0.5*PI);
      float x2a = next.x + next.radius * cos(next.angle - 0.5*PI);
      float y2a = next.y + next.radius * sin(next.angle - 0.5*PI);
      float x2b = next.x + next.radius * cos(next.angle + 0.5*PI);
      float y2b = next.y + next.radius * sin(next.angle + 0.5*PI);

      noStroke();
      fill(LIGHT_BLUE_H, LIGHT_BLUE_S, LIGHT_BLUE_B);
      beginShape();
      vertex(x1a, y1a);
      vertex(x2a, y2a);
      vertex(x2b, y2b);
      vertex(x1b, y1b);
      endShape(CLOSE);
      
      stroke(LIGHT_BLUE_H, LIGHT_BLUE_S, LIGHT_BLUE_B);
      strokeWeight(1);
      line(x1a, y1a, x2a, y2a);
      line(x1b, y1b, x2b, y2b);
    }
    drawfin();
  }
  
  void drawfin() {
    for (int i = 2; i < 5; i++) {
      segment s = body.get(i);
      pushMatrix();
      translate(s.x, s.y);
      rotate(s.angle);
      stroke(FIN_H, FIN_S, FIN_B);
      strokeWeight(2);
      line(0, 0, -3*s.distance, 0);
      popMatrix();
    }
  }
}

creature _creature;

void setup() {
  size(800, 1000);
  _creature = new creature();
  colorMode(HSB, 360, 100, 100);
}

void draw() {
  background(0, 0, 95);
  _creature.update();
  _creature.display();
}
