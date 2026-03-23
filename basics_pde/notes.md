# 🧠 High-level idea

This sketch simulates a **chain of connected joints** that tries to follow the mouse using a simplified inverse kinematics approach (in the style of FABRIK).

* Each joint is a `PVector` (a 2D position).
* The joints are connected by fixed-length segments (`linkSize`).
* On every frame:

  * The chain is adjusted toward the mouse (`fabrik`)
  * Then drawn (`drawChain`)

---

# 📦 Global variables

```java
ArrayList<PVector> joints;
int linkSize = 20;
int jointCount = 6;
```

* `joints`: stores the positions of all joints in the chain.
* `linkSize`: the fixed distance between each pair of joints.
* `jointCount`: total number of joints in the chain.

---

# ⚙️ setup()

```java
void setup() {
  size(600, 400);
  
  joints = new ArrayList<PVector>();
  
  PVector start = new PVector(width/2, height/2);
  joints.add(start.copy());
  
  for (int i = 1; i < jointCount; i++) {
    joints.add(PVector.add(joints.get(i-1), new PVector(0, linkSize)));
  }
}
```

### What happens here:

1. **Create the window**

   ```java
   size(600, 400);
   ```

2. **Initialize the joint list**

   ```java
   joints = new ArrayList<PVector>();
   ```

3. **Create the first joint (root)**

   ```java
   PVector start = new PVector(width/2, height/2);
   joints.add(start.copy());
   ```

   * Places the first joint at the center of the screen.

4. **Create the rest of the chain**

   ```java
   for (int i = 1; i < jointCount; i++) {
     joints.add(PVector.add(joints.get(i-1), new PVector(0, linkSize)));
   }
   ```

   * Each new joint is placed **below the previous one** by `linkSize`.
   * This initializes a straight vertical chain.

---

# 🔁 draw()

```java
void draw() {
  background(40, 44, 52);
  PVector target = new PVector(mouseX, mouseY);
  fabrik(target);
  drawChain(target);
}
```

Each frame:

1. Clear the screen.
2. Create a `target` at the mouse position.
3. Call `fabrik(target)` to adjust the joints.
4. Draw the chain and target.

---

# 🧮 fabrik(PVector target)

This is the core of the simulation.

```java
void fabrik(PVector target) {
```

Despite the name, this is not a full FABRIK implementation—it behaves more like a **two-pass constraint relaxation**.

---

## 🔽 Forward pass (as implemented)

```java
joints.set(0, target.copy());
for (int i = 1; i < joints.size(); i++) {
  PVector dir = PVector.sub(joints.get(i), joints.get(i-1));
  dir.setMag(linkSize);
  joints.set(i, PVector.add(joints.get(i-1), dir));
}
```

### Step-by-step:

### 1. Force the first joint to the target

```java
joints.set(0, target.copy());
```

* The root of the chain is moved directly to the mouse.

---

### 2. Propagate positions forward

For each joint:

```java
PVector dir = PVector.sub(joints.get(i), joints.get(i-1));
```

* Compute the vector from the previous joint to the current one.

```java
dir.setMag(linkSize);
```

* Normalize it and scale it to exactly `linkSize`.

```java
joints.set(i, PVector.add(joints.get(i-1), dir));
```

* Reposition joint `i` so it is exactly `linkSize` away from joint `i-1`.

### Effect:

* The chain is stretched outward from the target, maintaining segment lengths.

---

## 🔼 Backward pass

```java
PVector anchor = joints.get(joints.size()-1).copy();
joints.set(joints.size()-1, anchor);
```

* Copies the last joint into `anchor`.
* Then immediately sets the last joint to itself (this line has no real effect).

---

### Propagate backward:

```java
for (int i = joints.size()-2; i >= 0; i--) {
  PVector dir = PVector.sub(joints.get(i), joints.get(i+1));
  dir.setMag(linkSize);
  joints.set(i, PVector.add(joints.get(i+1), dir));
}
```

For each joint from the second-to-last back to the first:

1. Compute direction from the next joint to the current one.
2. Normalize and scale it to `linkSize`.
3. Reposition the current joint so it is exactly `linkSize` away from the next joint.

### Effect:

* The chain is adjusted backward to maintain segment lengths relative to the end.

---

# 🎨 drawChain(PVector target)

```java
void drawChain(PVector target) {
```

This function visualizes the chain and the target.

---

## 🔗 Draw links

```java
stroke(255);
strokeWeight(4);
for (int i = 0; i < joints.size() - 1; i++) {
  PVector a = joints.get(i);
  PVector b = joints.get(i+1);
  line(a.x, a.y, b.x, b.y);
}
```

* Draws a line between each pair of adjacent joints.
* Produces the “bones” of the chain.

---

## ⚪ Draw joints

```java
noStroke();
fill(255);
for (PVector j : joints) {
  ellipse(j.x, j.y, 10, 10);
}
```

* Draws each joint as a small circle.

---

## 🔴 Draw target

```java
fill(255, 0, 0);
ellipse(target.x, target.y, 12, 12);
```

* Draws a red circle at the mouse position.

---

# 🧩 What the system is doing overall

Each frame:

1. The first joint is snapped to the mouse.
2. The rest of the chain is adjusted forward to preserve segment lengths.
3. Then a backward pass tries to maintain distances relative to the end.
4. The result is a chain that visually follows the mouse.

---

# ⚠️ Important behavioral notes (as-is)

* The root is not fixed—it moves with the mouse.
* The "anchor" concept in the backward pass is ineffective in this code.
* The algorithm does not truly follow FABRIK’s root–end constraint model.
* Despite that, the chain still behaves like a stretchy IK chain.