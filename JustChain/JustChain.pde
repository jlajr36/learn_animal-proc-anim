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

Chain chain;

void setup() {
  size(800, 600);
  chain = new Chain(new PVector(width/2, height/2), 10, 30);
}

void draw() {
  background(40, 44, 52);

  // Resolve toward mouse
  PVector target = new PVector(mouseX, mouseY);
  chain.resolve(target);

  chain.display();
}
