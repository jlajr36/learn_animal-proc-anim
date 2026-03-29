// --- Random Color Palettes ---
float[][] palettes = {
  {180, 60, 100, 50, 80, 90},
  {210, 70, 70, 0, 80, 85},
  {270, 30, 95, 330, 60, 85}
};

// Creature parameters
int NUM_CREATURES = 200;
ArrayList<Creature> school = new ArrayList<Creature>();

void setup() {
  size(1200, 800);
  colorMode(HSB, 360, 100, 100);
  for (int i = 0; i < NUM_CREATURES; i++) {
    school.add(new Creature());
  }
}

void draw() {
  background(0, 0, 95);

  for (Creature c : school) {
    c.applyBoidRules(school);
    c.update();
    c.display();
  }
}

// --- Segment Class ---
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
  void display(float H, float S, float B) {
    fill(H, S, B);
    noStroke();
    circle(x, y, 2*radius);
  }
}

// --- Creature Class ---
class Creature {
  ArrayList<Segment> body = new ArrayList<Segment>();
  int len = 12;
  float speed;
  float BODY_H, BODY_S, BODY_B, FIN_H, FIN_S, FIN_B;

  Creature() {
    // Pick random palette
    int p = int(random(palettes.length));
    BODY_H = palettes[p][0];
    BODY_S = palettes[p][1];
    BODY_B = palettes[p][2];
    FIN_H = palettes[p][3];
    FIN_S = palettes[p][4];
    FIN_B = palettes[p][5];

    speed = random(2, 4);

    float r1 = 6;
    for (int i = 0; i < len; i++) {
      float r = r1 - i * (r1 / (len - 1));
      body.add(new Segment(random(width), random(height), random(TWO_PI), r, r, i*10));
    }
  }

  void applyBoidRules(ArrayList<Creature> others) {
    float neighDist = 50;
    PVector alignment = new PVector();
    PVector cohesion = new PVector();
    PVector separation = new PVector();
    int count = 0;

    Segment head = body.get(0);
    PVector headPos = new PVector(head.x, head.y);

    for (Creature other : others) {
      if (other == this) continue;
      Segment oHead = other.body.get(0);
      PVector oPos = new PVector(oHead.x, oHead.y);
      float d = PVector.dist(headPos, oPos);
      if (d < neighDist) {
        alignment.add(PVector.fromAngle(oHead.angle));
        cohesion.add(oPos);
        PVector diff = PVector.sub(headPos, oPos);
        diff.div(d*d);
        separation.add(diff);
        count++;
      }
    }

    if (count > 0) {
      alignment.div(count);
      alignment.setMag(0.03);
      cohesion.div(count);
      cohesion.sub(headPos);
      cohesion.setMag(0.03);
      separation.setMag(0.05);

      PVector force = new PVector();
      force.add(alignment);
      force.add(cohesion);
      force.add(separation);

      float desiredAngle = force.heading();
      float delta = desiredAngle - head.angle;
      delta = (delta + PI) % (2*PI) - PI;
      head.angle += delta * 0.05;
    }
  }

  void update() {
    Segment head = body.get(0);
    head.x += speed * cos(head.angle);
    head.y += speed * sin(head.angle);

    // Bounce off edges
    if (head.x < 0) head.angle = PI - head.angle;
    if (head.x > width) head.angle = PI - head.angle;
    if (head.y < 0) head.angle = -head.angle;
    if (head.y > height) head.angle = -head.angle;

    // Update body segments
    for (int i = 1; i < len; i++) {
      body.get(i).update(body.get(i-1));
    }
  }

  void display() {
    drawBody();
    drawFins();
  }

  void drawBody() {
    for (int i = 0; i < len; i++) {
      Segment s = body.get(i);
      s.display(BODY_H, BODY_S, BODY_B);
    }
  }

  void drawFins() {
    for (int i = 1; i < 4; i++) {
      Segment s = body.get(i);
      pushMatrix();
      translate(s.x, s.y);
      rotate(s.angle);
      stroke(FIN_H, FIN_S, FIN_B);
      strokeWeight(1.5);
      line(0, 0, -3*s.radius, 0);
      popMatrix();
    }
  }
}
