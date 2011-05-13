/**
 * Forrest Oliphant, 2011, http://sembiki.com/
 * Modified from the following
 * 
 * 1-4: camera presets
 * w: move camera up
 * s: move camera down
 */



/**
 * This demo shows a simple 2D car steering algorithm and alignment of
 * the car on the 3D terrain surface. The demo also features a third
 * person camera, following the car and re-orienting itself towards the
 * current direction of movement. The camera ensures it's always positioned
 * above ground level too...
 *
 * <p>Usage: use cursor keys to control car
 * <ul>
 * <li>up: accelerate</li>
 * <li>down: break</li>
 * <li>left/right: steer</li>
 * </ul>
 * </p>
 */

/* 
 * Copyright (c) 2010 Karsten Schmidt
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * http://creativecommons.org/licenses/LGPL/2.1/
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */
import toxi.geom.*;
import toxi.geom.mesh.*;
import toxi.math.*;
import toxi.processing.*;

import processing.opengl.*;

//import org.openkinect.*;
//import org.openkinect.processing.*;
import king.kinect.*;

//Kinect kinect;
KinectElevation ke;

import processing.video.*;
MovieMaker mm;
boolean recording = false;


//float NOISE_SCALE = 0.08f;
int DIMx=120;
int DIMz=90;

Terrain terrain;
ToxiclibsSupport gfx;
Mesh3D mesh;
Avatar car;

Vec3D camOffset = new Vec3D(0, 2000, 300);
Vec3D eyePos = new Vec3D(0, 4000, 300);

InterpolateStrategy sigmoid = new SigmoidInterpolation();
InterpolateStrategy linear = new LinearInterpolation();
InterpolateStrategy interpolate = linear;
float interpolate_factor = 0.05f;

Plane water = new Plane(new Vec3D(0, 0, 0), new Vec3D(0, 1, 0));





import controlP5.*;

ControlP5 controlP5;
//ControlWindow controlWindow;

//int NOISE_SEED = 23;
//float NOISE_SCALE = 0.08f;
//int BLUR_RADIUS = 4;
//int SCALE_Y = 8;
//float WATER_LEVEL = 6;




void setup() {
//  kinect = new Kinect(this);
    
  size(1280, 720, OPENGL);
  hint(ENABLE_OPENGL_4X_SMOOTH);  

  frameRate(24);

  // create terrain & generate elevation data
  ke = new KinectElevation(DIMx, DIMz);
  terrain = new Terrain(DIMx, DIMz, 50);
  updateMesh();
  // create avatar
  car = new Avatar(DIMx/2, DIMz/2);
  // attach drawing utils
  gfx = new ToxiclibsSupport(this);
  
  
  controlP5 = new ControlP5(this);
  controlP5.setAutoDraw(false);
//  controlWindow = controlP5.addControlWindow("controlP5window", 0, 0, 400, 300);
//  controlWindow.hideCoordinates();
//  controlWindow.setBackground(color(40));

  ke.setupControls(controlP5);
  
  
  
  
  
//  mm = new MovieMaker(this, width, height, "island.mov", 24, MovieMaker.ANIMATION, MovieMaker.HIGH);
}

void updateMesh() {
  terrain.setElevation( ke.getElevations() );
  // create mesh
  mesh = terrain.toMesh();
}

//void setNoiseSeed (int _seed) {
//  NOISE_SEED = _seed;
//  ke.setNoiseSeed(NOISE_SEED);
//}
//
//void setNoiseScale (float _scale) {
//  NOISE_SCALE = _scale;
//  ke.setNoiseScale(NOISE_SCALE);
//}
//
//void setBlur (int _blur) {
//  BLUR_RADIUS = _blur;
//  ke.setBlur(BLUR_RADIUS);
//}
//
//void setScaleY (int _scale) {
//  SCALE_Y = _scale;
//  ke.setScaleY(SCALE_Y);
//}
//void setWaterLevel (float _waterlevel) {
//  WATER_LEVEL = _waterlevel;
//  ke.setWaterLevel(WATER_LEVEL);
//}


void draw() {
      
  if (keyPressed) {
    if (key == '1') {
      camOffset.x = 0;
      camOffset.y = 100;
      camOffset.z = 300;
      
      interpolate = linear;
      interpolate_factor = 0.05;
    } else if (key == '2') {
      camOffset.x = 0;
      camOffset.y = 4000;
      camOffset.z = 300;
      
      interpolate = sigmoid;
      interpolate_factor = 0.3;
    } else if (key == '3') {
      camOffset.x = -3000;
      camOffset.y = 100;
      camOffset.z = 300;
      
      interpolate = sigmoid;
      interpolate_factor = 0.3;
    } else if (key == '4') {
      camOffset.x = 3000;
      camOffset.y = 100;
      camOffset.z = 300;
      interpolate = sigmoid;
      interpolate_factor = 0.3;
    }

    if (key == 'w') {
      camOffset.y += 50;
      interpolate = linear;
      interpolate_factor = 0.05;
    } else if (key == 's') {
      camOffset.y -= 50;
      interpolate = linear;
      interpolate_factor = 0.05;
    }
    
    if (key == 'a') {
      camOffset.x += 50;
      interpolate = linear;
      interpolate_factor = 0.05;
    } else if (key == 'd') {
      camOffset.x -= 50;
      interpolate = linear;
      interpolate_factor = 0.05;
    }

    if (keyCode == UP) {
      car.accelerate(1);
      interpolate = linear;
      interpolate_factor = 0.05;
    } else if (keyCode == DOWN) {
      car.accelerate(-1);
      interpolate = linear;
      interpolate_factor = 0.05;
    }
    if (keyCode == LEFT) {
      car.steer(0.1f);
      interpolate = linear;
      interpolate_factor = 0.05;
    } else if (keyCode == RIGHT) {
      car.steer(-0.1f);
      interpolate = linear;
      interpolate_factor = 0.05;
    }
    if (key == 'p') {
      startRecording();
    }
    if (key == 'o') {
      stopRecording();
    }
    if (key == 'q') {
      kill();
    }
    if (key == ' ') {
      println("c2: "+car.x+", "+car.y);
      println("c3: "+car.pos.x+", "+car.pos.y+", "+car.pos.z);
      println("h2: "+ke.getHighestPoint().x+", "+ke.getHighestPoint().y);
      
    }
  }

  updateMesh();
  
  
  // Move car to highest
  car.setTarget(ke.getHighestPoint());

  // update steering & position
  car.update();
  
  // adjust camera offset & rotate behind car based on current steering angle
  Vec3D camPos = car.pos.add(camOffset.getRotatedY(car.currTheta + HALF_PI));
//  camPos.constrain(mesh.getBoundingBox());
  float y = terrain.getHeightAtPoint(camPos.x, camPos.z);
  if (!Float.isNaN(y)) {
    camPos.y = max(camPos.y, y + 100);
  }
  eyePos.interpolateToSelf(camPos, interpolate_factor, interpolate);
  background(0x000000);
  camera(eyePos.x, eyePos.y, eyePos.z, car.pos.x, car.pos.y, car.pos.z, 0, -1, 0);
  // setup lights
  directionalLight(192, 192, 192, 0, -1000, -0.5f);
  directionalLight(64, 64, 64, 0.5f, -0.1f, 0.5f);
  fill(255);
  noStroke();
  // draw mesh & car
  gfx.mesh(mesh, false);
  car.draw();
  
  gfx.plane(water, 10000000);
  
  

  
  if (mm != null && recording) {
    mm.addFrame();
  }
}

void kill() {
  if (mm != null) {
    mm.finish();
  }
//  kinect.quit();
  exit();
}





void startRecording() {
  recording = true;
}

void stopRecording() {
  recording = false;
}


public void controlEvent(ControlEvent e) {
  ke.setThis(e.name(), e.value());
}

