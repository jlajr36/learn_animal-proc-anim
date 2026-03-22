ArrayList<PVector> joints;
int linkSize = 20;
int jointCount = 6;

void setup() {
  size(600, 400);
  
  joints = new ArrayList<PVector>();
  
  PVector start = new PVector(width/2, height/2);
  joints.add(start.copy());
  
  for (int i = 1; i < jointCount; i++) {
    joints.add(PVector.add(joints.get(i-1), new PVector(0, linkSize)));
  }
}

void draw() {
  background(40, 44, 52);
  PVector target = new PVector(mouseX, mouseY);
  fabrik(target);
  drawChain(target);
}

void fabrik(PVector target) {
  
  // Forward pass (pull chain toward target)
  joints.set(0, target.copy());
  for (int i = 1; i < joints.size(); i++) {
    PVector dir = PVector.sub(joints.get(i), joints.get(i-1));
    dir.setMag(linkSize);
    joints.set(i, PVector.add(joints.get(i-1), dir));
  }
  
  // Backward pass (anchor the last joint)
  PVector anchor = joints.get(joints.size()-1).copy();
  joints.set(joints.size()-1, anchor);
  for (int i = joints.size()-2; i >= 0; i--) {
    PVector dir = PVector.sub(joints.get(i), joints.get(i+1));
    dir.setMag(linkSize);
    joints.set(i, PVector.add(joints.get(i+1), dir));
  }
}

void drawChain(PVector target) {
  
  // Draw lines
  stroke(255);
  strokeWeight(4);
  for (int i = 0; i < joints.size() - 1; i++) {
    PVector a = joints.get(i);
    PVector b = joints.get(i+1);
    line(a.x, a.y, b.x, b.y);
  }
  
  // Draw joints
  noStroke();
  fill(255);
  for (PVector j : joints) {
    ellipse(j.x, j.y, 10, 10);
  }
  
  // Draw target
  fill(255, 0, 0);
  ellipse(target.x, target.y, 12, 12);
}
