// Sketch to explore applications of cyclic paths through 3D noise space
// Building from a short demo by Golan Levin (@golan) which was in turn inspired by, and created in support of:
// "Drawing from noise, and then making animated loopy GIFs from there" by Etienne Jacob (@n_disorder)
// https://necessarydisorder.wordpress.com/2017/11/15/drawing-from-noise-and-then-making-animated-loopy-gifs-from-there/

import com.hamoid.*;

VideoExport videoExport;

float myScale = 0.005;     // If a static value is used (maybe a dynamic one is preferable?)
float radius = 200.0;      // If a static value is used (maybe a dynamic one is preferable?)
int loopFrames = 600;      // Total number of frames in the loop (Divide by 60 for duration in sec at 60FPS)
float seed1 =random(1000); // To give random variation between the 3D noisespaces
float seed2 =random(1000); // One seed per noisespace
float seed3 =random(1000);

int columns, rows;
float colOffset, rowOffset, hwRatio;
float ellipseSize = 2.0;

void setup() {
  //fullScreen();
  //size(2000, 2000);
  size(1000, 1000);
  colorMode(HSB, 360, 255, 255, 255);
  noStroke();
  ellipseMode(RADIUS);
  rectMode(RADIUS);
  float h = height;
  float w = width;
  hwRatio = h/w;
  println("Width: " + w + " Height: " + h + " h/w ratio: " + hwRatio);
  columns = int(random(3, 33));
  rows = int(hwRatio * columns);
  //columns = 49;
  //rows = columns;
  colOffset = w/(columns*2);
  rowOffset = h/(rows*2);
  videoExport = new VideoExport(this, "../videoExport/circulesion.mp4"); //WARNING! The destination folder must exist already!
  videoExport.setQuality(85, 128);
  videoExport.setFrameRate(60);
  videoExport.setDebugging(false);
  videoExport.startMovie();
}

void draw() {
  int currStep = frameCount%loopFrames;
  println("Frame: " + currStep);
  float t = map(currStep, 0, loopFrames, 0, TWO_PI);
  float sineWave = sin(t);
  float cosWave = cos(t);
  float bkg_Hue = 240;
  float bkg_Sat = 255;
  float bkg_Bri = map(sineWave, -1, 1, 100, 255);
  background(bkg_Hue, bkg_Sat, bkg_Bri);
   
  //float px = width*0.5 + radius * cos(t); 
  //float py = height*0.5 + radius * sin(t);
  //float tz = t; // This angle will be used to move through the z axis
  //float pz = width*0.5 + radius * cos(tz); // Offset is arbitrary but must stay positive
  
  //loop for cartesian grid
  for(int col = 0; col<columns; col++) {
    for(int row = 0; row<rows; row++) {
      // This is where the code for each element in the grid goes
      // All the calculations which are specific to the individual element
      float gridx = map (col, 0, columns, 0, width) + colOffset;
      float gridy = map (row, 0, rows, 0, height) + rowOffset;
      float distToCenter = dist(gridx, gridy, width*0.5, height*0.5);
      radius = map(distToCenter, 0, width*0.7, 50, 200);
      float px = width*0.5 + radius * cosWave; 
      float py = height*0.5 + radius * sineWave;
      //myScale = map(distToCenter, 0, width*0.7, 0.0005, 0.05); 
      float noise1 = noise(myScale*(gridx + px+seed1), myScale*(gridy + py+seed1), myScale*(px+seed1));
      float noise2 = noise(myScale*(gridx + px+seed2), myScale*(gridy + py+seed2), myScale*(px+seed2));
      float noise3 = noise(myScale*(gridx + px+seed3), myScale*(gridy + py+seed3), myScale*(px+seed3));
      float rx = map(noise2,0,1,0,colOffset*ellipseSize);
      //float ry = map(noise3,0,1,0,rowOffset*ellipseSize);
      float ry = map(noise3,0,1,0.5,1.0);
      float fill_Hue = map(noise1, 0, 1, 0,30);
      float fill_Sat = map(noise3, 0, 1, 223,255);
      float fill_Bri = map(noise2, 0, 1, 64,255);
      
      //draw the thing
      pushMatrix();
      translate(gridx, gridy); // Go to the grid location
      rotate(map(noise1,0,1,0,TWO_PI)); // Rotate to the current angle
      fill(fill_Hue, fill_Sat, fill_Bri); // Set the fill color
      
      // These shapes require that ry is a value in a similar range to rx
      //ellipse(0,0,rx,ry); // Draw an ellipse
      //triangle(0, -ry, (rx*0.866), (ry*0.5) ,-(rx*0.866), (ry*0.5)); // Draw a triangle
      //rect(0,0,rx,ry); // Draw a rectangle
      
      
      // These shapes requires that ry is a scaling factor (e.g. in range 0.5 - 1.0)
      //ellipse(0,0,rx,rx*ry); // Draw an ellipse
      triangle(0, -rx*ry, (rx*0.866), (rx*ry*0.5) ,-(rx*0.866), (rx*ry*0.5)); // Draw a triangle
      //rect(0,0,rx,rx*ry); // Draw a rectangle
      
      popMatrix();
    }
  }
  videoExport.saveFrame();
  if (currStep==0) {
    videoExport.endMovie();
    exit();
  }
  // Save frames for the purpose of 
  // making an animated GIF loop, 
  // e.g. with http://gifmaker.me/
  if (frameCount < loopFrames) {
    //saveFrame( "save/"+ nf(currStep, 3)+ ".jpg");
  }
}

void keyPressed() {
  if (key == 'q') {
    videoExport.endMovie();
    exit();
  }
}