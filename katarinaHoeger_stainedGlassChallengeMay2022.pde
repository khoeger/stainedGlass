/* 
 
 Katarina Hoeger
 5/29/2022
 
 Submission to Raphaël de Courville's challenge: Stained Glass
 
 Notes:
 It has not been organized as well as I'd like or refactored. 
 My apologies.
 It has also not been tested on other images. 
 (This was fun, but I ran out of time).
 
 Techniques from:
 Image Processing:  
 https://github.com/milchreis/processing-imageprocessing
 Voronoi: 
 http://leebyron.com/mesh/#:~:text=Voronoi%20Diagrams%20show%20the%20regions%20of%20space%20closest,is%20particulary%20useful%20for%20optimization%20in%20game%20design.
 
 Image from here: https://leceneridipinocchio.blogspot.com/2015/01/il-tango.html
 
 */

/* Imports */
// Voronoi
import megamu.mesh.*;
// Image Processing
import milchreis.imageprocessing.*;
import milchreis.imageprocessing.utils.*;

/* Declarations */
// -- Voronoi
// points
float[][] points;      // list of all points
int numVoronoiPoints;  // total # of points created
// edges
color edgeColor;
// -- Palette Generation & Use
IntDict colorList ;    // list of all colors in picture
// -- Canvas
int boundaryHeight;    // space along edge of middle picture
// -- Image Processing
PImage inputPhoto ;    // unaltered photo
PImage quantizedImage ;// reduced color image
PImage edgesFound ;    // image with edges emphasized
PImage colorsInverted ;// image with inverted color  of edges
PImage erode;          // image with outline chunkier
PImage blend;          // image with outline and reduced color image
PImage balance ;       // image with blend but more satured 
PImage highlight ;     // image with balance but brighter

int quantizeShades; // # of shades : 0 - 255
int erosionLevel;   // # to control erosion : 0 - 255
float blendLevel;   // amount of blend: 0.0 - 1.0
float highlightLevel; // amount to highlight : -1.0 - 1.0

String[] paletteString ; // list of colors in palette, in string form
float [][] palette;      // stores palette rgb
int paletteSize;         // # of items in palette

float r, g, b;

Tile[] tileListVertical, tileListHorizontal;
int totalTiles = 10000 ;

void setup() {
  // -- Canvas Setup
  size(731, 1000); // !!! ALTER FOR NEW IMAGES!!! - canvas size chosen based off of image dimensions  
  pixelDensity(1); // display well on screens
  //  -- Modes
  imageMode(CENTER);
  rectMode(CENTER);

  // -- Variables
  edgeColor = color(50);  // color of edges
  boundaryHeight = 200;   // size of border around central image
  numVoronoiPoints = 100; // # of points in voronoi
  quantizeShades = 5;      // # of shades : 0 - 255
  erosionLevel = 7;       //# to control erosion : 0 - 255
  blendLevel = 0.2;       // amount of blend: 0.0 - 1.
  highlightLevel = 1.0;   // amount to highlight : -1.0 - 1.0
  paletteSize = 10 ;


  // -- Image
  // Load
  inputPhoto = loadImage("tango.jpg");
  // Resize: For photos taller than wide
  inputPhoto.resize(0, height - 2* boundaryHeight);
  // Process
  quantizedImage = Quantization.apply(inputPhoto, quantizeShades);                  // reduce colors
  edgesFound = CannyEdgeDetector.apply(quantizedImage);                             // outline: Find edges
  colorsInverted = InvertColors.apply( edgesFound, true, true, true );              // outline: make darker 
  erode = Erosion.apply(colorsInverted, erosionLevel);                              // outline: make larger
  blend = Blend.apply(quantizedImage, erode, blendLevel);                           // mix image with outline
  balance = AutoBalance.apply(blend);                                               // make colors more saturated 
  highlight = Lights.apply(balance, highlightLevel);                                // brighten



  // -- Voronoi
  // create space for points
  points = new float[numVoronoiPoints][ 2 ];
  // generate points
  for ( int pointGenerated = 0; pointGenerated < numVoronoiPoints; pointGenerated ++ ) {  // generate points inside of central image only
    points[pointGenerated][0] = random((width - inputPhoto.width)/2, width - (width - inputPhoto.width)/2);      //  point i, x;
    points[pointGenerated][1] = random((height - inputPhoto.height)/2, height - (height - inputPhoto.height)/2); //  point i, y
  }

  // -- Palette Creation
  colorList = new IntDict();      // Dictionary for counting colors that occur

  highlight.loadPixels();         // load pixels in central image

  for (  int colorSeen = 0; 
    colorSeen < highlight.width * highlight.height; 
    colorSeen ++) {          // loop through pixels, add colors to dictionary 

    r = red(highlight.pixels[colorSeen]);
    g = green(highlight.pixels[colorSeen]);
    b = blue(highlight.pixels[colorSeen]);

    String thisKey = str(r)+"_"+str(g)+"_"+str(b); // rgb color is key


    if (colorList.hasKey(thisKey) == true) {      // increment key if exist / (color count increases)
      colorList.increment(thisKey);
    } else {                                      // initialize key if it doesn't exist
      colorList.set(thisKey, 1);
    }
  }
  colorList.sortValuesReverse();                  // colors sorted in Descending order of frequency

  // space for list of palette strings
  if ( colorList.keyArray().length < paletteSize ) {   
    paletteString = new String [ colorList.keyArray().length ];
  } else {
    paletteString = new String [ paletteSize ];
  }
  // add strings to list of palette strings
  for ( int paletteIndex = 0; paletteIndex < paletteString.length; paletteIndex ++) {
    paletteString[paletteIndex] = colorList.keyArray()[paletteIndex];
  }

  // set aside space for palette 
  palette = new float[paletteString.length][3];
  // fill palette with r g b values
  for ( int paletteColorIndex = 0; paletteColorIndex < palette.length; paletteColorIndex ++ ) {

    palette[paletteColorIndex][0] = float( int ( splitTokens(paletteString[paletteColorIndex], "_")[0]) ) ;
    palette[paletteColorIndex][1] = float( int ( splitTokens(paletteString[paletteColorIndex], "_")[1]) ) ;
    palette[paletteColorIndex][2] = float( int ( splitTokens(paletteString[paletteColorIndex], "_")[2]) ) ;
  }

  // choose curent color
  int colorChosen ;

  // generate tiles
  tileListVertical = new Tile [totalTiles/2];
  tileListHorizontal = new Tile [totalTiles/2];

  // tile values
  float low = 5;
  float high = 20;
  float xRect, yRect;
  for ( int tilesGenerated = 0; tilesGenerated < totalTiles/2; tilesGenerated ++) {
    
    // current color
    colorChosen = int(random (palette.length));  

    // allowedX  - outside ofcentral image box 
    if (random(1) < 0.5) {
      xRect = random(0, (width - highlight.width)/2);
      yRect = random(0, height);
    } else {
      xRect = random(width - (width - highlight.width)/2, width);
      yRect = random(0, height);
    }
    tileListVertical[tilesGenerated] = new Tile(xRect, yRect,                      // add tile
      palette[colorChosen][0], palette[colorChosen][1], palette[colorChosen][2], 
      low, high);


    // allowedY  - outside of central image box 
    colorChosen = int(random (palette.length));  
    if (random(1) < 0.5) {
      yRect = random(0, (height - highlight.height)/2);
      xRect = random(0, width);
    } else {
      yRect = random(height - (height - highlight.height)/2, height);
      xRect = random(0, width);
    }
    tileListHorizontal[tilesGenerated] = new Tile(xRect, yRect,                    // add tile
      palette[colorChosen][0], palette[colorChosen][1], palette[colorChosen][2], 
      low, high);
  }
}

void draw() {
  background(edgeColor);

  // load central image
  image(highlight, width/2, height/2);

  // Voronoi for tiling of central image
  Voronoi myVoronoi = new Voronoi( points );     // create voronoi
  float[][] myEdges = myVoronoi.getEdges();     // list of edges in voronoi
  strokeWeight(4);                              // make edges this weight
  stroke(edgeColor);                            // make edges this color
  for (int i=0; i<myEdges.length; i++)          // loop through voronoi edges to draw
  {
    float startX = myEdges[i][0];
    float startY = myEdges[i][1];
    float endX = myEdges[i][2];
    float endY = myEdges[i][3];
    line( startX, startY, endX, endY );
  }


  for ( Tile tileShown : tileListVertical) {    // draw and show tiles on left or right
    tileShown.display();
    tileShown.moveHorizontal();
  }
  for ( Tile tileShown : tileListHorizontal) {  // draw and show tiles on top or bottom
    tileShown.display();
    tileShown.moveVertical();
  }
}


class Tile {
  float x, y;
  float r, g, b;
  float wh;
  int sWeight;
  float delta;

  Tile( float x_, float y_, float r_, float g_, float b_, float lowWH_, float highWH_ ) {
    x = x_;
    y = y_;
    r = r_;
    g = g_;
    b = b_;
    wh = random( lowWH_, highWH_ );
    sWeight = 3;
    delta = 1;
  }

  void display() {
    stroke(edgeColor);
    strokeWeight( sWeight);
    fill( r, g, b);
    rect( x, y, wh, wh);
  }

  void moveHorizontal() {
    x += random(-delta, delta);
    y += random(-delta, delta);

    boolean overLeftEdgeOfMiddle = x > (width - highlight.width)/2;
    boolean overRightEdgeOfMiddle = x < width-(width - highlight.width)/2;

    // crossed from L or R into middle
    if ( overLeftEdgeOfMiddle && overRightEdgeOfMiddle) {
      if (random(1) < 0.5) {
        x = random(0, (width - highlight.width)/2);
      } else {
        x = random(width- (width - highlight.width)/2, width);
      }
    }
  }

  void moveVertical() {
    x += random(-delta, delta);
    y += random(-delta, delta);

    boolean overTopEdgeOfMiddle = y > (height - highlight.height)/2;
    boolean overBottomEdgeOfMiddle = y < height-(height - highlight.height)/2;

    // crossed from T or B into middle
    if ( overTopEdgeOfMiddle && overBottomEdgeOfMiddle) {
      if (random(1) < 0.5) {
        y = random(0, (height - highlight.height)/2);
      } else {
        y = random(height- (height - highlight.height)/2, height);
      }
    }
  }
}

void mousePressed(){
  saveFrame("stainedGlassChallenge.jpg");
}
