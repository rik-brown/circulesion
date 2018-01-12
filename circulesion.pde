// Sketch to explore applications of cyclic paths through 3D noise space
// Building from a short demo by Golan Levin (@golan) which was in turn inspired by, and created in support of:
// "Drawing from noise, and then making animated loopy GIFs from there" by Etienne Jacob (@n_disorder)
// https://necessarydisorder.wordpress.com/2017/11/15/drawing-from-noise-and-then-making-animated-loopy-gifs-from-there/

// TO DO: Implement a 'stepped' mode which does not render every frame, but jumps in configurable steps (2018-01-04)
// TO DO: Try using RGB mode to make gradients from one hue to another, instead of light/dark etc. (2018-01-04)
// TO DO: Add start-time & end-time to the logfile, to get an idea of expected rendertime for longer videos.
// TO DO: Use variables for bkgCol throughout (remove local hardcodes)
// TO DO: Make sure logfiles logs everything needed to recreate a given sketch /2018-01-10)
// TO DO: Instead of 2D noisefield use an image and pick out the colour values from the pxels!!! Vary radius of circular path for each cycle :D
// Observation: When making video timelapse, the pathway to construct each each frame need not be circular! 

// Consider the names:
// Minor cycle - resulting in one timelapse frame
// Major cycle - resulting in one timelapse video

import com.hamoid.*;     // For converting frames to a .mp4 video file 
import processing.pdf.*; // For exporting output as a .pdf file

VideoExport videoExport;

// Noise variables:
float noise1Scale, noise2Scale, noise3Scale, noiseFactor;
float noiseFactorMin = 20; // Last: 2  From 2 to 10 is a dramatic change!
float noiseFactorMax = 1; // Last: 2  From 2 to 10 is a dramatic change!
float noise1Factor = 5;
float noise2Factor = 5;
float noise3Factor = 5;
float radiusMedian; // If a static value is used (maybe a dynamic one is preferable?)
float radiusFactor = 0;   // By how much (+/- %) should the radius vary throughout the timelapse cycle?
int loopFrames = 500;       // Total number of frames in the loop 
float seed1 =random(1000);  // To give random variation between the 3D noisespaces
float seed2 =random(1000);  // One seed per noisespace
float seed3 =random(1000);

// Cartesian Grid variables: 
int columns, rows, h, w;
float colOffset, rowOffset, hwRatio;
float ellipseMaxSize = 6.0; // last 2
float stripeWidth = loopFrames * 0.1; // Number of frames for a 'stripe pair' of colour 1 & colour 2

// File Management variables:
int batch = 2;
String applicationName = "circulesion";
String logFileName;   // Name & location of logfile (.log)
String pngFile;       // Name & location of saved output (.png final image)
String pdfFile;       // Name & location of saved output (.pdf file)
String framedumpPath; // Name & location of saved output (individual frames) NOT IN USE
String mp4File;       // Name & location of video output (.mp4 file)

// Loop Control variables
int maxCycles = 600;    //The number of timelapse frames in the video (Divide by 60 for duration (sec) @60fps, or 30 @30fps)
int cycleCount = 1;    //The equivalent of frameCount for major cycles. First cycle # = 1 (just like first frame # = 1)

// Output configuration toggles:
boolean makePDF = false;
boolean savePNG = true;
boolean makeMPEG_1 = false; // Enable video output for animation of a single cycle (one frame per draw cycle, one video per loopFrames sequence)
boolean makeMPEG_2 = true;  // Enable video output for animation of a series of cycles (one frame per loopFrames cycle, one video per maxCycles sequence)
boolean runOnce = true;     // Stop after one loopCycle (one 'timelapse' sequence)

PrintWriter logFile;    // Object for writing to the settings logfile

void setup() {
  //fullScreen();
  //size(10000, 10000);
  //size(6000, 6000);
  //size(4000, 4000);
  //size(2000, 2000);
  size(1000, 1000);
  //size(800, 800);
  //size(400,400);
  //background(0,255,255);
  noiseSeed(0); //To make the noisespace identical each time (for repeatability) 
  background(0);
  colorMode(HSB, 360, 255, 255, 255);
  noStroke();
  //stroke(0);
  ellipseMode(RADIUS);
  rectMode(RADIUS);
  h = height;
  w = width;
  radiusMedian = w * 0.2; // Better to scale radiusMedian to the current canvas size than use a static value
  hwRatio = h/w;
  println("Width: " + w + " Height: " + h + " h/w ratio: " + hwRatio);
  //columns = int(random(3, 7));
  columns = 9;
  rows = int(hwRatio * columns);
  //rows = columns;
  //rows=5;
  colOffset = w/(columns*2);
  rowOffset = h/(rows*2);
  //noise1Scale /= noiseFactor*w;
  //noise2Scale /= noiseFactor*w;
  //noise3Scale /= noiseFactor*w;
  getReady();
  if (makeMPEG_1) {makeMPEG_2 = false; runOnce = true;}
  if (makeMPEG_2) {makeMPEG_1 = false; runOnce = false;}
  if (makeMPEG_1 || makeMPEG_2) {
    videoExport = new VideoExport(this, mp4File);
    videoExport.setQuality(85, 128);
    videoExport.setFrameRate(60); // fps setting for output video (should not be lower than 30)
    videoExport.setDebugging(false);
    videoExport.startMovie();
  }
}

void draw() {
  int currStep = frameCount%loopFrames; //frameCount always starts at 1, so the first time currStep=0 will be when frameCount = loopFrames (and each successive cycle)
  int cycleStep = cycleCount%maxCycles; //cycleCount always starts at 1, so the first time cycleStep=0 will be when cycleCount = maxCycles (and each successive cycle)
  if (currStep==0) {
    if (runOnce) {shutdown();} // Exit criteria from the draw loop when runOnce is enabled
    else {
      if (makeMPEG_2) {videoExport.saveFrame();}
      cycleCount ++;  // If runOnce is disabled, increase the cycle counter and continue
      if (cycleStep == 0) {shutdown();}
      background(0); //Refresh the background
    }
  }
  float cycleStepAngle = PI + map(cycleStep, 0, maxCycles-1, 0, TWO_PI); // Angle will turn through a full circle throughout one cycleStep
  float cycleStepSineWave = sin(cycleStepAngle); // Range: -1 to +1
  float radius = radiusMedian * map(cycleStepSineWave, -1, 1, 1-radiusFactor, 1+radiusFactor); //radius is scaled by cycleStep
  //float remainingSteps = loopFrames - currStep; //For stripes that are a % of remainingSteps in the loop
  //stripeWidth = (remainingSteps * 0.3) + 10;
  //stripeWidth = map(currStep, 0, loopFrames, loopFrames*0.25, loopFrames*0.1);
  float stripeStep = frameCount%stripeWidth; //step counter (not sure how robust this method is when stripeWidth is modulated)
  float stripeFactor = map(currStep, 0, loopFrames-1, 0.5, 0.5);
  float ellipseSize = map(currStep, 0, loopFrames-1, ellipseMaxSize, 0); // The scaling factor for ellipseSize  from max to zero as the minor loop runs
  float t = map(currStep, 0, loopFrames, 0, TWO_PI); // The angle for various cyclic calculations increases from zero to 2PI as the minor loop runs
  float sineWave = sin(t);
  float cosWave = cos(t);
  //float bkg_Hue = 240;
  float bkg_Hue = map(sineWave, -1, 1, 240, 200);
  float bkg_Sat = 255;
  float bkg_Bri = map(sineWave, -1, 1, 100, 255);
  noiseFactor = sq(map(cycleStepSineWave, -1, 1, noiseFactorMin, noiseFactorMax));
  noise1Scale = noise1Factor/(noiseFactor*w);
  noise2Scale = noise2Factor/(noiseFactor*w);
  noise3Scale = noise3Factor/(noiseFactor*w);
  
  //background(bkg_Hue, bkg_Sat, bkg_Bri);
  //background(0);
  //background(bkg_Hue, 0, bkg_Bri);
   
  //float px = width*0.5 + radius * cos(t); 
  //float py = height*0.5 + radius * sin(t);
  //float tz = t; // This angle will be used to move through the z axis
  //float pz = width*0.5 + radius * cos(tz); // Offset is arbitrary but must stay positive
  
  println("Frame: " + currStep + " cycleStep: " + cycleStep + " noiseFactor: " + noiseFactor);
  
  //loop through all the elements in the cartesian grid
  for(int col = 0; col<columns; col++) {
    for(int row = 0; row<rows; row++) {
      // This is where the code for each element in the grid goes
      // All the calculations which are specific to the individual element
      
      // 1) Map the grid coords (row/col) to the x/y coords in the canvas space 
      float gridx = map (col, 0, columns, 0, width) + colOffset; // gridx is in 'canvas space'
      float gridy = map (row, 0, rows, 0, height) + rowOffset;   // gridy is in 'canvas space'
      
      // 2) A useful value for modulating other parameters can be calculated: 
      float distToCenter = dist(gridx, gridy, width*0.5, height*0.5);  // distToCenter is in 'canvas space'
      
      // 3) The radius for the x-y(z) noise loop can now be calculated (if not already done so):
      //radius = radiusMedian * map(distToCenter, 0, width*0.7, 0.5, 1.0); // In this case, radius is influenced by the distToCenter value
      
      // 4) The x-y co-ordinates (in canvas space) of the circular path can now be calculated:
      float px = width*0.5 + radius * cosWave;   // px is in 'canvas space'
      float py = height*0.5 + radius * sineWave; // py is in 'canvas space'
      
      //noise1Scale = map(distToCenter, 0, width*0.7, 0.0005, 0.05); // If Scale factor is to be influenced by dist2C: 
      
      //noiseN is a 3D noise value comprised of these 3 components:
      // X co-ordinate:
      // gridx (cartesian grid position on the 2D canvas)
      // +
      // px (x co-ordinate of the current point of the circular noisepath on the 2D canvas)
      // +
      // seedN (arbitrary noise seed number offsetting the canvas along the x-axis)
      //
      // The sum of these values is multiplied by the constant scaling factor 'noise1Scale' (whose values does not change relative to window size)
      
      // Y co-ordinate:
      // gridy (cartesian grid position on the 2D canvas)
      // +
      // py (y co-ordinate of the current point of the circular noisepath on the 2D canvas)
      // +
      // seedN (arbitrary noise seed number offsetting the canvas along the x-axis)
      //
      // The sum of these values is multiplied by the constant scaling factor 'noise1Scale' (whose values does not change relative to window size)
      
      // Z co-ordinate:
      // Z is different from X & Y as it only needs to follow a one-dimensional cyclic path (returning to where it starts)
      // It could keep a constant rate of change up & down (like an elevator) but I thought a sinewave might be more interesting
      // It occurred to me that I could just as well re-use either px or py (and not even bother offsetting the angle to start at a max or min)
      // I haven't really experimented with any other strategies, so I could be missing something here.
      // I have a nagging feeling that the 3D pathway should be more sophisticated (e.g. mapping the surface of a sphere)
      // but I'm not certain enough to invest the time learning the more advanced math required. (TO DO...)
      //
      // px (x co-ordinate of the current point of the circular noisepath on the 2D canvas)
      // +
      // seedN (arbitrary noise seed number offsetting the canvas along the x-axis)
      //
      // The sum of these values is multiplied by the constant scaling factor 'noise1Scale' (whose values does not change relative to window size)
      
      //noise1, 2 & 3 are basically 3 identical 'grid systems' offset at 3 arbitrary locations in the 3D noisespace.
      
      float noise1 = noise(noise1Scale*(gridx + px + seed1), noise1Scale*(gridy + py + seed1), noise1Scale*(px + seed1));
      float noise2 = noise(noise2Scale*(gridx + px + seed2), noise2Scale*(gridy + py + seed2), noise2Scale*(px + seed2));
      float noise3 = noise(noise3Scale*(gridx + px + seed3), noise3Scale*(gridy + py + seed3), noise3Scale*(px + seed3));
      
      float rx = map(noise2,0,1,0,colOffset*ellipseSize);
      //float ry = map(noise3,0,1,0,rowOffset*ellipseSize);
      float ry = map(noise3,0,1,0.5,1.0);
      float fill_Hue = map(noise1, 0, 1, 210,270);
      //float fill_Sat = map(noise3, 0, 1, 128,255);
      float fill_Sat = map(currStep, 0, loopFrames, 255, 64);
      //float fill_Bri = map(noise2, 0, 1, 128,255);
      float fill_Bri = map(currStep, 0, loopFrames, 32, 255);
      
      //draw the thing
      pushMatrix();
      translate(gridx, gridy); // Go to the grid location
      rotate(map(noise1,0,1,0,TWO_PI)); // Rotate to the current angle
      //fill(fill_Hue, fill_Sat, fill_Bri); // Set the fill color
      //fill(fill_Hue, 0, fill_Bri); // Set the fill color B+W
      //fill(fill_Hue, fill_Sat, fill_Bri); // Set the fill color
      fill(fill_Bri);
      //if (noise1 >= 0.5) {fill(360);} else {fill(0);}
      if (stripeStep >= stripeWidth * stripeFactor) {fill(360);} else {fill(0);}
      //if (stripeStep >= stripeWidth * stripeFactor) {fill(240,fill_Sat,fill_Bri);} else {fill(fill_Hue,255,255);}
      //stroke(0,64);
      //stroke(255,32);
      //noFill();
      // These shapes require that ry is a value in a similar range to rx
      //ellipse(0,0,rx,ry); // Draw an ellipse
      //triangle(0, -ry, (rx*0.866), (ry*0.5) ,-(rx*0.866), (ry*0.5)); // Draw a triangle
      //rect(0,0,rx,ry); // Draw a rectangle
      
      
      // These shapes requires that ry is a scaling factor (e.g. in range 0.5 - 1.0)
      //ellipse(0,0,rx,rx*ry); // Draw an ellipse
      triangle(0, -rx*ry, (rx*0.866), (rx*ry*0.5) ,-(rx*0.866), (rx*ry*0.5)); // Draw a triangle
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
  logFile.println("noise1Scale = " + noise1Scale);
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