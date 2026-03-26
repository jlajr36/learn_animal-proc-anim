// Constrain the vector to be at a certain range of the anchor
PVector constrainDistance(PVector pos, PVector anchor, float constraint) {
  return PVector.add(anchor, PVector.sub(pos, anchor).setMag(constraint));
}

// Constrain the angle to be within a certain range of the anchor
float constrainAngle(float angle, float anchor, float constraint) {
  if (abs(relativeAngleDiff(angle, anchor)) <= constraint) {
    return simplifyAngle(angle);
  }

  if (relativeAngleDiff(angle, anchor) > constraint) {
    return simplifyAngle(anchor - constraint);
  }

  return simplifyAngle(anchor + constraint);
}

// i.e. How many radians do you need to turn the angle to match the anchor?
float relativeAngleDiff(float angle, float anchor) {
  // Since angles are represented by values in [0, 2pi), it's helpful to rotate
  // the coordinate space such that PI is at the anchor. That way we don't have
  // to worry about the "seam" between 0 and 2pi.
  angle = simplifyAngle(angle + PI - anchor);
  anchor = PI;

  return anchor - angle;
}

// Simplify the angle to be in the range [0, 2pi)
float simplifyAngle(float angle) {
  while (angle >= TWO_PI) {
    angle -= TWO_PI;
  }

  while (angle < 0) {
    angle += TWO_PI;
  }

  return angle;
}

class Chain {
  ArrayList<PVector> joints;
  int linkSize; // Space between joints

  // Only used in non-FABRIK resolution
  ArrayList<Float> angles;
  float angleConstraint; // Max angle diff between two adjacent joints, higher = loose, lower = rigid

  Chain(PVector origin, int jointCount, int linkSize) {
    this(origin, jointCount, linkSize, TWO_PI);
  }

  Chain(PVector origin, int jointCount, int linkSize, float angleConstraint) {
    this.linkSize = linkSize;
    this.angleConstraint = angleConstraint;
    joints = new ArrayList<>(); // Assumed to be >= 2, otherwise it wouldn't be much of a chain
    angles = new ArrayList<>();
    joints.add(origin.copy());
    angles.add(0f);
    for (int i = 1; i < jointCount; i++) {
      joints.add(PVector.add(joints.get(i - 1), new PVector(0, this.linkSize)));
      angles.add(0f);
    }
  }

  void resolve(PVector pos) {
    angles.set(0, PVector.sub(pos, joints.get(0)).heading());
    joints.set(0, pos);
    for (int i = 1; i < joints.size(); i++) {
      float curAngle = PVector.sub(joints.get(i - 1), joints.get(i)).heading();
      angles.set(i, constrainAngle(curAngle, angles.get(i - 1), angleConstraint));
      joints.set(i, PVector.sub(joints.get(i - 1), PVector.fromAngle(angles.get(i)).setMag(linkSize)));
    }
  }

  void fabrikResolve(PVector pos, PVector anchor) {
    // Forward pass
    joints.set(0, pos);
    for (int i = 1; i < joints.size(); i++) {
      joints.set(i, constrainDistance(joints.get(i), joints.get(i-1), linkSize));
    }

    // Backward pass
    joints.set(joints.size() - 1, anchor);
    for (int i = joints.size() - 2; i >= 0; i--) {
      joints.set(i, constrainDistance(joints.get(i), joints.get(i+1), linkSize));
    }
  }

  void display() {
    strokeWeight(8);
    stroke(255);
    for (int i = 0; i < joints.size() - 1; i++) {
      PVector startJoint = joints.get(i);
      PVector endJoint = joints.get(i + 1);
      line(startJoint.x, startJoint.y, endJoint.x, endJoint.y);
    }

    fill(42, 44, 53);
    for (PVector joint : joints) {
      ellipse(joint.x, joint.y, 32, 32);
    }
  }
}

class Fish {
  Chain spine;

  color bodyColor = color(58, 124, 165);
  color finColor = color(129, 195, 215);

  // Width of the fish at each vertabra
  float[] bodyWidth = {68, 81, 84, 83, 77, 64, 51, 38, 32, 19};

  Fish(PVector origin) {
    // 12 segments, first 10 for body, last 2 for caudal fin
    spine = new Chain(origin, 12, 64, PI/8);
  }

  void resolve() {
    PVector headPos = spine.joints.get(0);
    PVector mousePos = new PVector(mouseX, mouseY);
    PVector targetPos = PVector.add(headPos, PVector.sub(mousePos, headPos).setMag(16));
    spine.resolve(targetPos);
  }

  void display() {
    strokeWeight(4);
    stroke(255);
    fill(finColor);

    // Alternate labels for shorter lines of code
    ArrayList<PVector> j = spine.joints;
    ArrayList<Float> a = spine.angles;

    // Relative angle differences are used in some hacky computation for the dorsal fin
    float headToMid1 = relativeAngleDiff(a.get(0), a.get(6));
    float headToMid2 = relativeAngleDiff(a.get(0), a.get(7));

    // For the caudal fin, we need to compute the relative angle difference from the head to the tail, but given
    // a joint count of 12 and angle constraint of PI/8, the maximum difference between head and tail is 11PI/8,
    // which is >PI. This complicates the relative angle calculation (flips the sign when curving too tightly).
    // A quick workaround is to compute the angle difference from the head to the middle of the fish, and then
    // from the middle of the fish to the tail.
    float headToTail = headToMid1 + relativeAngleDiff(a.get(6), a.get(11));

    // === START PECTORAL FINS ===
    pushMatrix();
    translate(getPosX(3, PI/3, 0), getPosY(3, PI/3, 0));
    rotate(a.get(2) - PI/4);
    ellipse(0, 0, 160, 64); // Right
    popMatrix();
    pushMatrix();
    translate(getPosX(3, -PI/3, 0), getPosY(3, -PI/3, 0));
    rotate(a.get(2) + PI/4);
    ellipse(0, 0, 160, 64); // Left
    popMatrix();
    // === END PECTORAL FINS ===

    // === START VENTRAL FINS ===
    pushMatrix();
    translate(getPosX(7, PI/2, 0), getPosY(7, PI/2, 0));
    rotate(a.get(6) - PI/4);
    ellipse(0, 0, 96, 32); // Right
    popMatrix();
    pushMatrix();
    translate(getPosX(7, -PI/2, 0), getPosY(7, -PI/2, 0));
    rotate(a.get(6) + PI/4);
    ellipse(0, 0, 96, 32); // Left
    popMatrix();
    // === END VENTRAL FINS ===

    // === START CAUDAL FINS ===
    beginShape();
    // "Bottom" of the fish
    for (int i = 8; i < 12; i++) {
      float tailWidth = 1.5 * headToTail * (i - 8) * (i - 8);
      curveVertex(j.get(i).x + cos(a.get(i) - PI/2) * tailWidth, j.get(i).y + sin(a.get(i) - PI/2) * tailWidth);
    }

    // "Top" of the fish
    for (int i = 11; i >= 8; i--) {
      float tailWidth = max(-13, min(13, headToTail * 6));
      curveVertex(j.get(i).x + cos(a.get(i) + PI/2) * tailWidth, j.get(i).y + sin(a.get(i) + PI/2) * tailWidth);
    }
    endShape(CLOSE);
    // === END CAUDAL FINS ===

    fill(bodyColor);

    // === START BODY ===
    beginShape();

    // Right half of the fish
    for (int i = 0; i < 10; i++) {
      curveVertex(getPosX(i, PI/2, 0), getPosY(i, PI/2, 0));
    }

    // Bottom of the fish
    curveVertex(getPosX(9, PI, 0), getPosY(9, PI, 0));

    // Left half of the fish
    for (int i = 9; i >= 0; i--) {
      curveVertex(getPosX(i, -PI/2, 0), getPosY(i, -PI/2, 0));
    }


    // Top of the head (completes the loop)
    curveVertex(getPosX(0, -PI/6, 0), getPosY(0, -PI/6, 0));
    curveVertex(getPosX(0, 0, 4), getPosY(0, 0, 4));
    curveVertex(getPosX(0, PI/6, 0), getPosY(0, PI/6, 0));

    // Some overlap needed because curveVertex requires extra vertices that are not rendered
    curveVertex(getPosX(0, PI/2, 0), getPosY(0, PI/2, 0));
    curveVertex(getPosX(1, PI/2, 0), getPosY(1, PI/2, 0));
    curveVertex(getPosX(2, PI/2, 0), getPosY(2, PI/2, 0));

    endShape(CLOSE);
    // === END BODY ===

    fill(finColor);

    // === START DORSAL FIN ===
    beginShape();
    vertex(j.get(4).x, j.get(4).y);
    bezierVertex(j.get(5).x, j.get(5).y, j.get(6).x, j.get(6).y, j.get(7).x, j.get(7).y);
    bezierVertex(j.get(6).x + cos(a.get(6) + PI/2) * headToMid2 * 16, j.get(6).y + sin(a.get(6) + PI/2) * headToMid2 * 16, j.get(5).x + cos(a.get(5) + PI/2) * headToMid1 * 16, j.get(5).y + sin(a.get(5) + PI/2) * headToMid1 * 16, j.get(4).x, j.get(4).y);
    endShape();
    // === END DORSAL FIN ===

    // === START EYES ===
    fill(255);
    ellipse(getPosX(0, PI/2, -18), getPosY(0, PI/2, -18), 24, 24);
    ellipse(getPosX(0, -PI/2, -18), getPosY(0, -PI/2, -18), 24, 24);
    // === END EYES ===
  }

  void debugDisplay() {
    spine.display();
  }

  // Various helpers to shorten lines

  float getPosX(int i, float angleOffset, float lengthOffset) {
    return spine.joints.get(i).x + cos(spine.angles.get(i) + angleOffset) * (bodyWidth[i] + lengthOffset);
  }

  float getPosY(int i, float angleOffset, float lengthOffset) {
    return spine.joints.get(i).y + sin(spine.angles.get(i) + angleOffset) * (bodyWidth[i] + lengthOffset);
  }
}

Fish fish;

void setup() {
  size(1280, 720, P2D);
  fish = new Fish(new PVector(width/2, height/2));
}

void draw() {
  background(40, 44, 52);

    fish.resolve();
    fish.display();

}
