// === ANGLE HELPERS ===

// Constrain the vector to be at a certain distance from anchor
PVector constrainDistance(PVector pos, PVector anchor, float constraint) {
  return PVector.add(anchor, PVector.sub(pos, anchor).setMag(constraint));
}

// Constrain the angle to be within a certain range of the anchor
float constrainAngle(float angle, float anchor, float constraint) {
  float diff = relativeAngleDiff(angle, anchor);
  if (abs(diff) <= constraint) return simplifyAngle(angle);
  return simplifyAngle(anchor + (diff > 0 ? -constraint : constraint));
}

// How many radians to turn angle to match anchor
float relativeAngleDiff(float angle, float anchor) {
  angle = simplifyAngle(angle + PI - anchor);
  return PI - angle;
}

// Simplify angle to [0, 2*PI)
float simplifyAngle(float angle) {
  while (angle >= TWO_PI) angle -= TWO_PI;
  while (angle < 0) angle += TWO_PI;
  return angle;
}

// === CHAIN CLASS ===
class Chain {
  ArrayList<PVector> joints;
  ArrayList<Float> angles;
  int linkSize;
  float angleConstraint;

  Chain(PVector origin, int jointCount, int linkSize) {
    this(origin, jointCount, linkSize, TWO_PI);
  }

  Chain(PVector origin, int jointCount, int linkSize, float angleConstraint) {
    this.linkSize = linkSize;
    this.angleConstraint = angleConstraint;
    joints = new ArrayList<>();
    angles = new ArrayList<>();
    joints.add(origin.copy());
    angles.add(0f);
    for (int i = 1; i < jointCount; i++) {
      joints.add(PVector.add(joints.get(i-1), new PVector(0, linkSize)));
      angles.add(0f);
    }
  }

  void resolve(PVector pos) {
    angles.set(0, PVector.sub(pos, joints.get(0)).heading());
    joints.set(0, pos);
    for (int i = 1; i < joints.size(); i++) {
      float curAngle = PVector.sub(joints.get(i-1), joints.get(i)).heading();
      angles.set(i, constrainAngle(curAngle, angles.get(i-1), angleConstraint));
      joints.set(i, PVector.sub(joints.get(i-1), PVector.fromAngle(angles.get(i)).setMag(linkSize)));
    }
  }

  void fabrikResolve(PVector pos, PVector anchor) {
    // Forward
    joints.set(0, pos);
    for (int i = 1; i < joints.size(); i++) {
      joints.set(i, constrainDistance(joints.get(i), joints.get(i-1), linkSize));
    }
    // Backward
    joints.set(joints.size()-1, anchor);
    for (int i = joints.size()-2; i >= 0; i--) {
      joints.set(i, constrainDistance(joints.get(i), joints.get(i+1), linkSize));
    }
  }

  void display() {
    strokeWeight(8);
    stroke(255);
    for (int i = 0; i < joints.size()-1; i++) {
      line(joints.get(i).x, joints.get(i).y, joints.get(i+1).x, joints.get(i+1).y);
    }

    fill(42,44,53);
    for (PVector joint : joints) ellipse(joint.x, joint.y, 32, 32);
  }
}

// === FISH CLASS ===
class Fish {
  Chain spine;
  color bodyColor = color(58,124,165);
  color finColor  = color(129,195,215);
  float[] bodyWidth = {68,81,84,83,77,64,51,38,32,19};

  Fish(PVector origin) {
    spine = new Chain(origin, 12, 64, PI/8);
  }

  void resolve() {
    PVector head = spine.joints.get(0);
    PVector target = PVector.add(head, PVector.sub(new PVector(mouseX, mouseY), head).setMag(16));
    spine.resolve(target);
  }

  void display() {
    ArrayList<PVector> joints = spine.joints;
    ArrayList<Float> angles = spine.angles;

    strokeWeight(4);
    stroke(255);
    fill(finColor);

    // === FINS ===
    drawFin(2, 3, PI/3, PI/4, 160, 64); // pectoral
    drawFin(2, 3, -PI/3, -PI/4, 160, 64); // pectoral
    drawFin(6, 7, PI/2, PI/4, 96, 32); // ventral
    drawFin(6, 7, -PI/2, -PI/4, 96, 32); // ventral

    // === BODY ===
    fill(bodyColor);
    beginShape();
    for (int i=0;i<10;i++) curveVertex(getPosX(i, PI/2,0), getPosY(i, PI/2,0));
    curveVertex(getPosX(9, PI,0), getPosY(9, PI,0));
    for (int i=9;i>=0;i--) curveVertex(getPosX(i,-PI/2,0), getPosY(i,-PI/2,0));
    curveVertex(getPosX(0,-PI/6,0), getPosY(0,-PI/6,0));
    curveVertex(getPosX(0,0,4), getPosY(0,0,4));
    curveVertex(getPosX(0,PI/6,0), getPosY(0,PI/6,0));
    // curveVertex overlap for proper rendering
    for (int i=0;i<3;i++) curveVertex(getPosX(i,PI/2,0), getPosY(i,PI/2,0));
    endShape(CLOSE);

    // === DORSAL FIN ===
    fill(finColor);
    float headToMid1 = relativeAngleDiff(angles.get(0), angles.get(6));
    float headToMid2 = relativeAngleDiff(angles.get(0), angles.get(7));
    beginShape();
    vertex(joints.get(4).x, joints.get(4).y);
    bezierVertex(joints.get(5).x, joints.get(5).y, joints.get(6).x, joints.get(6).y, joints.get(7).x, joints.get(7).y);
    bezierVertex(
      joints.get(6).x + cos(angles.get(6)+PI/2)*headToMid2*16,
      joints.get(6).y + sin(angles.get(6)+PI/2)*headToMid2*16,
      joints.get(5).x + cos(angles.get(5)+PI/2)*headToMid1*16,
      joints.get(5).y + sin(angles.get(5)+PI/2)*headToMid1*16,
      joints.get(4).x, joints.get(4).y
    );
    endShape();

    // === EYES ===
    fill(255);
    ellipse(getPosX(0,PI/2,-18), getPosY(0,PI/2,-18),24,24);
    ellipse(getPosX(0,-PI/2,-18), getPosY(0,-PI/2,-18),24,24);
  }

  // HELPER TO DRAW FINS
  void drawFin(int baseAngleIndex, int jointIndex, float offset, float rotateOffset, float w, float h) {
    pushMatrix();
    translate(getPosX(jointIndex, offset,0), getPosY(jointIndex, offset,0));
    rotate(spine.angles.get(baseAngleIndex)+rotateOffset);
    ellipse(0,0,w,h);
    popMatrix();
  }

  float getPosX(int i, float angleOffset, float lengthOffset) {
    return spine.joints.get(i).x + cos(spine.angles.get(i)+angleOffset)*(bodyWidth[i]+lengthOffset);
  }

  float getPosY(int i, float angleOffset, float lengthOffset) {
    return spine.joints.get(i).y + sin(spine.angles.get(i)+angleOffset)*(bodyWidth[i]+lengthOffset);
  }

  void debugDisplay() { spine.display(); }
}

Fish fish;

void setup() {
  size(1280, 720, P2D);
  fish = new Fish(new PVector(width/2, height/2));
}

void draw() {
  background(40,44,52);
  fish.resolve();
  pushMatrix();
  translate(width/2, height/2);
  scale(0.1);
  translate(-width/2, -height/2);
  fish.display();
  popMatrix();
}
