# 🔹 Helper Functions (Math Utilities)

## 1. Constraining distance between two points

```java
PVector constrainDistance(PVector pos, PVector anchor, float constraint) {
  return PVector.add(anchor, PVector.sub(pos, anchor).setMag(constraint));
}
```

### What this does:

This function forces a point (`pos`) to stay at a fixed distance (`constraint`) from another point (`anchor`).

### Step-by-step:

* `PVector.sub(pos, anchor)`
  → Creates a vector pointing from anchor → pos

* `.setMag(constraint)`
  → Resizes that vector so its length equals `constraint`

* `PVector.add(anchor, ...)`
  → Moves the scaled vector back relative to the anchor

✅ Result: a point exactly `constraint` units away from the anchor, in the same direction.

---

## 2. Constraining angles

```java
float constrainAngle(float angle, float anchor, float constraint) {
```

### Purpose:

Limits how far an angle can differ from another angle.

---

```java
  if (abs(relativeAngleDiff(angle, anchor)) <= constraint) {
    return simplifyAngle(angle);
  }
```

* If the angle is already within the allowed range:
  → just return it (no change)

---

```java
  if (relativeAngleDiff(angle, anchor) > constraint) {
    return simplifyAngle(anchor - constraint);
  }
```

* If the angle is too far in the positive direction:
  → clamp it to the maximum allowed angle

---

```java
  return simplifyAngle(anchor + constraint);
}
```

* Otherwise:
  → clamp it in the opposite direction

---

## 3. Angle difference calculation

```java
float relativeAngleDiff(float angle, float anchor) {
```

### Purpose:

Finds how far one angle is from another, correctly handling circular wrapping (0 ↔ 2π).

---

```java
angle = simplifyAngle(angle + PI - anchor);
anchor = PI;
```

* This "shifts" the coordinate system so that:
  → the anchor is treated as π (center)
* This avoids issues where angles wrap around 0 / 2π

---

```java
return anchor - angle;
```

* Returns how far `angle` is from the anchor

---

## 4. Normalize angles

```java
float simplifyAngle(float angle) {
```

### Purpose:

Keeps angles within `[0, 2π)`.

---

```java
while (angle >= TWO_PI) {
  angle -= TWO_PI;
}
```

* If angle is too large → wrap it down

---

```java
while (angle < 0) {
  angle += TWO_PI;
}
```

* If angle is negative → wrap it up

---

```java
return angle;
```

---

# 🔹 The Chain Class

```java
class Chain {
```

This represents a **chain of connected joints** (like a robotic arm or snake).

---

## Variables

```java
ArrayList<PVector> joints;
```

* Stores the positions of each joint

---

```java
int linkSize;
```

* Distance between each joint

---

```java
ArrayList<Float> angles;
```

* Stores the angle of each segment

---

```java
float angleConstraint;
```

* Maximum allowed angle difference between joints

---

# 🔹 Constructor

```java
Chain(PVector origin, int jointCount, int linkSize) {
  this(origin, jointCount, linkSize, TWO_PI);
}
```

* Calls the main constructor with no angle restriction

---

```java
Chain(PVector origin, int jointCount, int linkSize, float angleConstraint) {
```

Main constructor.

---

```java
this.linkSize = linkSize;
this.angleConstraint = angleConstraint;
```

* Stores parameters

---

```java
joints = new ArrayList<>();
angles = new ArrayList<>();
```

* Initializes lists

---

```java
joints.add(origin.copy());
angles.add(0f);
```

* First joint is the origin
* Initial angle is 0

---

```java
for (int i = 1; i < jointCount; i++) {
```

* Create the rest of the joints

---

```java
joints.add(PVector.add(joints.get(i - 1), new PVector(0, this.linkSize)));
```

* Each joint is placed directly below the previous one

---

```java
angles.add(0f);
```

* Initialize angle for each joint

---

# 🔹 Angle-Constrained Solver

```java
void resolve(PVector pos) {
```

* Moves the chain so the head reaches `pos`

---

```java
angles.set(0, PVector.sub(pos, joints.get(0)).heading());
```

* First joint points toward the target

---

```java
joints.set(0, pos);
```

* Move the first joint to the target

---

```java
for (int i = 1; i < joints.size(); i++) {
```

* Iterate through remaining joints

---

```java
float curAngle = PVector.sub(joints.get(i - 1), joints.get(i)).heading();
```

* Compute the angle between this joint and the previous one

---

```java
angles.set(i, constrainAngle(curAngle, angles.get(i - 1), angleConstraint));
```

* Limit the angle relative to the previous joint

---

```java
joints.set(i, PVector.sub(joints.get(i - 1), PVector.fromAngle(angles.get(i)).setMag(linkSize)));
```

* Reposition the joint based on the constrained angle and fixed length

---

# 🔹 FABRIK Solver

```java
void fabrikResolve(PVector pos, PVector anchor) {
```

* Alternative solver using distance constraints

---

## Forward pass

```java
joints.set(0, pos);
```

* Move first joint to the target

---

```java
for (int i = 1; i < joints.size(); i++) {
  joints.set(i, constrainDistance(joints.get(i), joints.get(i-1), linkSize));
}
```

* Each joint follows the previous one while keeping fixed distance

---

## Backward pass

```java
joints.set(joints.size() - 1, anchor);
```

* Lock the last joint to a fixed anchor

---

```java
for (int i = joints.size() - 2; i >= 0; i--) {
  joints.set(i, constrainDistance(joints.get(i), joints.get(i+1), linkSize));
}
```

* Move backward through the chain enforcing distances

---

# 🔹 Drawing the chain

```java
void display() {
```

---

```java
strokeWeight(8);
stroke(255);
```

* Set line thickness and color

---

```java
for (int i = 0; i < joints.size() - 1; i++) {
```

* Loop through each segment

---

```java
line(startJoint.x, startJoint.y, endJoint.x, endJoint.y);
```

* Draw line between joints

---

```java
fill(42, 44, 53);
for (PVector joint : joints) {
  ellipse(joint.x, joint.y, 32, 32);
}
```

* Draw each joint as a circle

---

# 🔹 Global Setup

```java
Chain chain;
```

* Declare the chain object

---

```java
void setup() {
  size(800, 600);
```

* Create the window

---

```java
chain = new Chain(new PVector(width/2, height/2), 10, 30);
```

* Create a chain:

  * Centered in screen
  * 10 joints
  * Each link is 30 pixels long

---

# 🔹 Main Loop

```java
void draw() {
  background(40, 44, 52);
```

* Clear screen each frame

---

```java
PVector target = new PVector(mouseX, mouseY);
```

* Target is the mouse position

---

```java
chain.resolve(target);
```

* Update chain to follow the mouse

---

```java
chain.display();
```

* Draw the chain

---

# 🧾 Big Picture Summary

* You created a **chain of joints**
* Each frame:

  * The chain tries to reach the mouse
  * Constraints keep it realistic:

    * Fixed link lengths
    * Optional angle limits
* You implemented:

  * A **custom angle-based IK solver**
  * A **FABRIK solver**