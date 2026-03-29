// --- Random Color Palettes ---
// Each palette: {bodyH, bodyS, bodyB, finH, finS, finB}
float[][] palettes = {
  {180, 60, 100, 50, 80, 90},   // Bright cyan body, yellow fins
  {210, 70, 70, 0, 80, 85},     // Deep blue body, red fins
  {270, 30, 95, 330, 60, 85}    // Soft lavender body, pink fins
};

// Global color variables
float BODY_H, BODY_S, BODY_B;
float FIN_H, FIN_S, FIN_B;

class Segment {
  float x, y, angle, distance, radius, hue;

  Segment(float nx, float ny, float a, float d, float r, float h) {
    x = nx; y = ny; angle = a; distance = d; radius = r; hue = h;
  }

  void update(Segment prev) {
    angle = atan2(prev.y - y, prev.x - x);
    float d = dist(prev.x, prev.y, x, y);
    if (d > distance) {
      float delta = d - distance;
      x += delta * cos(angle);
      y += delta * sin(angle);
    }
  }

  void display() {
    fill(BODY_H, BODY_S, BODY_B);
    stroke(BODY_H, BODY_S, BODY_B);
    strokeWeight(1);
    pushMatrix();
    translate(x, y);
    rotate(angle);
    circle(0, 0, 2 * radius);
    popMatrix();
  }
}

class Creature {
  ArrayList<Segment> body = new ArrayList<Segment>();
  int len = 20;
  float speed = 4;

  Creature() {
    float r1 = 10;
    for (int i = 0; i < len; i++) {
      float r = r1 - i * (r1 / (len - 1));
      body.add(new Segment(width * 0.5 - i * r1, height * 0.5, 0, r, r, i * 10));
    }
  }

  void update() {
    Segment head = body.get(0);
    float a = atan2(mouseY - head.y, mouseX - head.x);
    float delta = a - head.angle;
    delta = (delta + PI) % (2 * PI) - PI;  // normalize delta to [-PI, PI]
    head.angle += 0.015 * delta;
    head.x += speed * cos(head.angle);
    head.y += speed * sin(head.angle);

    for (int i = 1; i < len; i++) {
      body.get(i).update(body.get(i - 1));
    }
  }

  void display() {
    drawHead();
    drawBody();
    drawFins();
  }

  void drawHead() {
    Segment head = body.get(0);
    fill(BODY_H, BODY_S, BODY_B);
    stroke(BODY_H, BODY_S, BODY_B);
    strokeWeight(1);
    pushMatrix();
    translate(head.x, head.y);
    rotate(head.angle);
    arc(0, 0, head.radius * 4, head.radius * 2, -0.5 * PI, 0.5 * PI);
    popMatrix();
  }

  void drawBody() {
    for (int i = 0; i < len - 1; i++) {
      Segment s = body.get(i);
      Segment next = body.get(i + 1);

      s.display();
      drawSegmentQuad(s, next);
    }
  }

  void drawSegmentQuad(Segment s, Segment next) {
    float[] x1 = {s.x + s.radius * cos(s.angle - 0.5 * PI), s.x + s.radius * cos(s.angle + 0.5 * PI)};
    float[] y1 = {s.y + s.radius * sin(s.angle - 0.5 * PI), s.y + s.radius * sin(s.angle + 0.5 * PI)};
    float[] x2 = {next.x + next.radius * cos(next.angle - 0.5 * PI), next.x + next.radius * cos(next.angle + 0.5 * PI)};
    float[] y2 = {next.y + next.radius * sin(next.angle - 0.5 * PI), next.y + next.radius * sin(next.angle + 0.5 * PI)};

    noStroke();
    fill(BODY_H, BODY_S, BODY_B);
    beginShape();
    vertex(x1[0], y1[0]);
    vertex(x2[0], y2[0]);
    vertex(x2[1], y2[1]);
    vertex(x1[1], y1[1]);
    endShape(CLOSE);

    stroke(BODY_H, BODY_S, BODY_B);
    strokeWeight(1);
    line(x1[0], y1[0], x2[0], y2[0]);
    line(x1[1], y1[1], x2[1], y2[1]);
  }

  void drawFins() {
    for (int i = 2; i < 5; i++) {
      Segment s = body.get(i);
      pushMatrix();
      translate(s.x, s.y);
      rotate(s.angle);
      stroke(FIN_H, FIN_S, FIN_B);
      strokeWeight(2);
      line(0, 0, -3 * s.distance, 0);
      popMatrix();
    }
  }
}

Creature _creature;

void setup() {
  size(800, 1000);
  colorMode(HSB, 360, 100, 100);

  // Pick a random palette at startup
  int p = int(random(palettes.length));
  BODY_H = palettes[p][0];
  BODY_S = palettes[p][1];
  BODY_B = palettes[p][2];
  FIN_H = palettes[p][3];
  FIN_S = palettes[p][4];
  FIN_B = palettes[p][5];

  _creature = new Creature();
}

void draw() {
  background(0, 0, 95);
  _creature.update();
  _creature.display();
}
