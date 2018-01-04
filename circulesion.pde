// Sketch to explore applications of cyclic paths through 3D noise space
// Building from a short demo by Golan Levin (@golan) which was in turn inspired by, and created in support of:
// "Drawing from noise, and then making animated loopy GIFs from there" by Etienne Jacob (@n_disorder)
// https://necessarydisorder.wordpress.com/2017/11/15/drawing-from-noise-and-then-making-animated-loopy-gifs-from-there/

// TO DO: Implement a higher-level loop for saving timelapse-frames to video (2018-01-03)
// TO DO: Implement a 'stepped' mode which does not render every frame, but jumps in configurable steps (2018-01-04)
// TO DO: Try using RGB mode to make gradients from one hue to another, instead of light/dark etc. (2018-01-04)
// TO DO: Add start-time & end-time to the logfile, to get an idea of expected rendertime for longer videos.

import com.hamoid.*;     // For converting frames to a .mp4 video file 
import processing.pdf.*; // For exporting output as a .pdf file

VideoExport videoExport;

// Noise variables: 
float myScale = 0.0006;     // If a static value is used (maybe a dynamic one is preferable?)
float radiusMedian = 400.0;      // If a static value is used (maybe a dynamic one is preferable?)
float radiusFactor = 0.2;
int loopFrames = 1000;      // Total number of frames in the loop (Divide by 60 for duration in sec at 60FPS)
float seed1 =random(1000); // To give random variation between the 3D noisespaces
float seed2 =random(1000); // One seed per noisespace
float seed3 =random(1000);

// Cartesian Grid variables: 
int columns, rows;
float colOffset, rowOffset, hwRatio;
float ellipseMaxSize = 5.0;
float stripeWidth = 100; // Number of frames for a 'stripe pair' of colour 1 & colour 2

// File Management variables:
int batch = 2;
String applicationName = "circulesion";
String logFileName;   // Name & location of logfile (.log)
String pngFile;       // Name & location of saved output (.png final image)
String pdfFile;       // Name & location of saved output (.pdf file)
String framedumpPath; // Name & location of saved output (individual frames) NOT IN USE
String mp4File;       // Name & location of video output (.mp4 file)

// Loop Control variables
int maxCycles = 600;
int runCycle = 0;

// Output configuration toggles:
boolean makePDF = false;
boolean savePNG = true;
boolean makeMPEG_1 = false; // Enable video output for animation of a single cycle (one frame per draw cycle, one video per loopFrames sequence)
boolean makeMPEG_2 = true; // Enable video output for animation of a series of cycles (one frame per loopFrames cycle, one video per maxCycles sequence)
boolean runOnce = true;

PrintWriter logFile;    // Object for writing to the settings logfile

void setup() {
  //fullScreen();
  //size(10000, 10000);
  //size(6000, 6000);
  //size(4000, 4000);
  //size(2000, 2000);
  size(1000, 1000);
  //size(800, 800);
  //background(0,255,255);
  background(360);
  colorMode(HSB, 360, 255, 255, 255);
  noStroke();
  //stroke(0);
  ellipseMode(RADIUS);
  rectMode(RADIUS);
  float h = height;
  float w = width;
  radiusMedian = w * 0.4; // Better to scale radiusMedian to the current canvas size than use a static value
  hwRatio = h/w;
  println("Width: " + w + " Height: " + h + " h/w ratio: " + hwRatio);
  //columns = int(random(3, 7));
  columns = 8;
  rows = int(hwRatio * columns);
  //rows = columns;
  //rows=5;
  colOffset = w/(columns*2);
  rowOffset = h/(rows*2);
  getReady();
  if (makeMPEG_1) {makeMPEG_2 = false; runOnce = true;}
  if (makeMPEG_2) {makeMPEG_1 = false; runOnce = false;}
  if (makeMPEG_1 || makeMPEG_2) {
    videoExport = new VideoExport(this, mp4File);
    videoExport.setQuality(85, 128);
    videoExport.setFrameRate(60);
    videoExport.setDebugging(false);
    videoExport.startMovie();
  }
}

void draw() {
  int currStep = frameCount%loopFrames; //frameCount always starts at 0, so the first time currStep=0 will be when frameCount = loopFrames (and each successive cycle)
  if (currStep==0) {
    if (runOnce) {shutdown();} // Exit criteria from the draw loop when runOnce is enabled
    else {
      if (makeMPEG_2) {videoExport.saveFrame();}
      runCycle ++;  // If runOnce is disabled, increase the runCycle counter and continue
      if (runCycle >= maxCycles) {shutdown();}
      background(360); //Refresh the background
    }
  }
  float runCycleAngle = map (runCycle, 0, maxCycles-1, 0, TWO_PI); // Angle will turn through a full circle throughout one runCycle
  float runCycleSineWave = sin(runCycleAngle); // Range: -1 to +1
  float radius = radiusMedian * map(runCycleSineWave, -1, 1, 1-radiusFactor, 1+radiusFactor);
  float remainingSteps = loopFrames - currStep;
  //stripeWidth = (remainingSteps * 0.3) + 10;
  //stripeWidth = map(currStep, 0, loopFrames, loopFrames*0.25, loopFrames*0.1);
  float stripeStep = frameCount%stripeWidth;
  float stripeFactor = map(currStep, 0, loopFrames, 0.4, 0.6);
  println("Frame: " + currStep + " RunCycle: " + runCycle);
  float ellipseSize = map(currStep, 0, loopFrames, ellipseMaxSize, 0);
  float t = map(currStep, 0, loopFrames, 0, TWO_PI);
  float sineWave = sin(t);
  float cosWave = cos(t);
  //float bkg_Hue = 240;
  float bkg_Hue = map(sineWave, -1, 1, 240, 200);
  float bkg_Sat = 255;
  float bkg_Bri = map(sineWave, -1, 1, 100, 255);
  //background(bkg_Hue, bkg_Sat, bkg_Bri);
  //background(0);
  //background(bkg_Hue, 0, bkg_Bri);
   
  //float px = width*0.5 + radius * cos(t); 
  //float py = height*0.5 + radius * sin(t);
  //float tz = t; // This angle will be used to move through the z axis
  //float pz = width*0.5 + radius * cos(tz); // Offset is arbitrary but must stay positive
  
  //loop through all the elements in the cartesian grid
  for(int col = 0; col<columns; col++) {
    for(int row = 0; row<rows; row++) {
      // This is where the code for each element in the grid goes
      // All the calculations which are specific to the individual element
      
      // 1) Map the grid coords (row/col) to the x/y coords in the canvas space 
      float gridx = map (col, 0, columns, 0, width) + colOffset;
      float gridy = map (row, 0, rows, 0, height) + rowOffset;
      
      // 2) A useful value for modulating other parameters can be calculated: 
      float distToCenter = dist(gridx, gridy, width*0.5, height*0.5);
      
      // 3) The radius for the x-y(z) noise loop can now be calculated (if not already done so):
      //radius = radiusMedian * map(distToCenter, 0, width*0.7, 0.5, 1.0); // In this case, radius is influenced by the distToCenter value
      
      // 4) The x-y co-ordinates (in canvas space) of the circular path can now be calculated:
      float px = width*0.5 + radius * cosWave; 
      float py = height*0.5 + radius * sineWave;
      
      //myScale = map(distToCenter, 0, width*0.7, 0.0005, 0.05); // If Scale factor is to be influenced by dist2C: 
      float noise1 = noise(myScale*(gridx + px+seed1), myScale*(gridy + py+seed1), myScale*(px+seed1));
      float noise2 = noise(myScale*(gridx + px+seed2), myScale*(gridy + py+seed2), myScale*(px+seed2));
      float noise3 = noise(myScale*(gridx + px+seed3), myScale*(gridy + py+seed3), myScale*(px+seed3));
      float rx = map(noise2,0,1,0,colOffset*ellipseSize);
      //float ry = map(noise3,0,1,0,rowOffset*ellipseSize);
      float ry = map(noise3,0,1,0.5,1.0);
      float fill_Hue = map(noise1, 0, 1, 210,270);
      //float fill_Sat = map(noise3, 0, 1, 128,255);
      float fill_Sat = map(currStep, 0, loopFrames, 255, 64);
      //float fill_Bri = map(noise2, 0, 1, 128,255);
      float fill_Bri = map(currStep, 0, loopFrames, 255, 0);
      
      //draw the thing
      pushMatrix();
      translate(gridx, gridy); // Go to the grid location
      rotate(map(noise1,0,1,0,TWO_PI)); // Rotate to the current angle
      //fill(fill_Hue, fill_Sat, fill_Bri); // Set the fill color
      //fill(fill_Hue, 0, fill_Bri); // Set the fill color B+W
      //fill(fill_Hue, fill_Sat, fill_Bri); // Set the fill color
      //fill(fill_Bri);
      //if (noise1 >= 0.5) {fill(360);} else {fill(0);}
      if (stripeStep >= stripeWidth * stripeFactor) {fill(360);} else {fill(0);}
      //if (stripeStep >= stripeWidth * stripeFactor) {fill(240,fill_Sat,fill_Bri);} else {fill(fill_Hue,255,255);}
      
      // These shapes require that ry is a value in a similar range to rx
      //ellipse(0,0,rx,ry); // Draw an ellipse
      //triangle(0, -ry, (rx*0.866), (ry*0.5) ,-(rx*0.866), (ry*0.5)); // Draw a triangle
      //rect(0,0,rx,ry); // Draw a rectangle
      
      
      // These shapes requires that ry is a scaling factor (e.g. in range 0.5 - 1.0)
      ellipse(0,0,rx,rx*ry); // Draw an ellipse
      //triangle(0, -rx*ry, (rx*0.866), (rx*ry*0.5) ,-(rx*0.866), (rx*ry*0.5)); // Draw a triangle
      //rect(0,0,rx,rx*ry); // Draw a rectangle
      
      popMatrix();
    } //Closes 'rows' loop
  } //Closes 'columns' loop
  
  //Do this after you have drawn all the elements in the cartesian grid:
  if (makeMPEG_1) {videoExport.saveFrame();}
  // Save frames for the purpose of 
  // making an animated GIF loop, 
  // e.g. with http://gifmaker.me/
  
  if (frameCount < loopFrames) {
    //saveFrame( "save/"+ nf(currStep, 3)+ ".jpg"); //Uncomment this if you want to save every frame drawn (consider making a toggle for this!)
  }
} //Closes draw() loop

void keyPressed() {
  if (key == 'q') {
    if (makeMPEG_1 || makeMPEG_2) {videoExport.endMovie();}
    exit();
  }
}

// prepares pathnames for various file outputs
void getReady() {
  String batchName = String.valueOf(nf(batch,3));
  String timestamp = timeStamp();
  String pathName = "../../output/" + applicationName + "/" + batchName + "/" + String.valueOf(width) + "x" + String.valueOf(height) + "/"; //local
  pngFile = pathName + "png/" + applicationName + "-" + batchName + "-" + timestamp + ".png";
  //screendumpPath = "../output.png"; // For use when running from local bot
  pdfFile = pathName + "pdf/" + applicationName + "-" + batchName + "-" + timestamp + ".pdf";
  mp4File = pathName + applicationName + "-" + batchName + "-" + timestamp + ".mp4";
  logFileName = pathName + "settings/" + applicationName + "-" + batchName + "-" + timestamp + ".log";
  logFile = createWriter(logFileName); //Open a new settings logfile
  logStart();
  if (makePDF) {
    runOnce = true;
    beginRecord(PDF, pdfFile);
  }
}

void logStart() {
  logFile.println(pngFile);
  logFile.println("loopFrames = " + loopFrames);
  logFile.println("columns = " + columns);
  logFile.println("rows = " + rows);
  logFile.println("ellipseMaxSize = " + ellipseMaxSize);
  logFile.println("seed1 = " + seed1);
  logFile.println("seed2 = " + seed2);
  logFile.println("seed3 = " + seed3);
  logFile.println("myScale = " + myScale);
}

void logEnd() {
  logFile.flush();
  logFile.close(); //Flush and close the settings file
}


// saves an image of the final frame, closes any pdf & mpeg files and exits
void shutdown() {
  // Close the logfile
  println("Saving .log file: " + logFileName);
  logEnd();
  
  // If I'm in PNG-mode, export a .png of how the image looked when it was terminated
  if (savePNG) {
    saveFrame(pngFile);
    println("Saving .png file: " + pngFile);
  }
  
  // If I'm in PDF-mode, complete & close the file
  if (makePDF) {
    println("Saving .pdf file: " + pdfFile);
    endRecord();
  }
  
  // If I'm in MPEG mode, complete & close the file
  if (makeMPEG_1 || makeMPEG_2) {
    println("Saving .mp4 file: " + mp4File);
    videoExport.endMovie();}
  exit();
}

//returns a string with the date & time in the format 'yyyymmdd-hhmmss'
String timeStamp() {
  String s = String.valueOf(nf(second(),2));
  String m = String.valueOf(nf(minute(),2));
  String h = String.valueOf(nf(hour(),2));
  String d = String.valueOf(nf(day(),2));
  String mo = String.valueOf(nf(month(),2));
  String y = String.valueOf(nf(year(),4));
  String timestamp = y + mo + d + "-" + h + m + s;
  return timestamp;
}