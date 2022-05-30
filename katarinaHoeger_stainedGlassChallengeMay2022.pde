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
float pointDelta = 0.01;
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
int paletteSize;         // # of items in palette  // choose curent color
int colorChosen ;        // current color variable
float r, g, b;           // color components

Tile[] tileListVertical, tileListHorizontal;      // set of Vertical & Horizontal Tiles
int totalTiles = 10000 ;                          // # of tiles to generate

// tile values
float low ;              // smallest tile w/h
float high ;             // largest tile w/h
float xRect, yRect;      // tile placement
float middleBorder;
float tileSWeight;
float tileDelta;

// FRAME
PShape frame1, frame2, frame3 ;

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
  low = 5;                // smallest tile size
  high = 20;              // largest tile size
  middleBorder = 25;      // overlap between tiles and center pic
  pointDelta = 0.01;      // how far voronoi points shift each frame 
  tileSWeight = 3;        // how thick is each tile's stroke
  tileDelta = 0.05;       // amount a tile moves each frame


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
    colorSeen ++) {                                 // loop through pixels, add colors to dictionary 

    r = red(highlight.pixels[colorSeen]);
    g = green(highlight.pixels[colorSeen]);
    b = blue(highlight.pixels[colorSeen]);

    String thisKey = str(r)+"_"+str(g)+"_"+str(b); // r_g_b color is string key


    if (colorList.hasKey(thisKey) == true) {      // increment key if exist / (color count increases)
      colorList.increment(thisKey);
    } else {                                      // initialize key if it doesn't exist
      colorList.set(thisKey, 1);
    }
  }
  colorList.sortValuesReverse();                                 // colors sorted in Descending order of frequency

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

  // space for new tiles
  tileListVertical = new Tile [totalTiles/2];          
  tileListHorizontal = new Tile [totalTiles/2];

  // Create tiles
  for ( int tilesGenerated = 0; tilesGenerated < totalTiles/2; tilesGenerated ++) {
    // Vertically placed tiles
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
    tileListVertical[tilesGenerated] = new Tile(xRect, yRect, // add tile
      palette[colorChosen][0], palette[colorChosen][1], palette[colorChosen][2], 
      low, high, tileSWeight, tileDelta);

    // horizontally placed tiles
    // allowedY  - outside of central image box 
    colorChosen = int(random (palette.length));  
    if (random(1) < 0.5) {
      yRect = random(0, (height - highlight.height)/2);
      xRect = random(0, width);
    } else {
      yRect = random(height - (height - highlight.height)/2, height);
      xRect = random(0, width);
    }
    tileListHorizontal[tilesGenerated] = new Tile(xRect, yRect, // add tile
      palette[colorChosen][0], palette[colorChosen][1], palette[colorChosen][2], 
      low, high, tileSWeight, tileDelta);
  }

  // -- FRAME
  float outerXLeft = 0;
  float outerXRight = width;
  float outerYTop = 150;
  float outerYBottom = height;

  frame1 = createShape();
  frame1.beginShape();
  frame1.stroke(0);
  frame1.strokeWeight(max((width - highlight.width)/2,(height - highlight.height)/2 ));
  frame1.noFill();
  frame1.beginShape();
  frame1.vertex(outerXLeft, outerYTop);
  frame1.vertex(outerXLeft + (width - highlight.width)/5 , outerYTop - (height - highlight.height)/5 );
  frame1.vertex(outerXLeft + (width - highlight.width)/4 , outerYTop - (height - highlight.height)/4 );
  frame1.vertex(outerXLeft + (width - highlight.width)/3 , outerYTop - (height - highlight.height)/3 );
  frame1.vertex(width/2,  outerYTop - (height - highlight.height)/2 );
  frame1.vertex(outerXRight - (width - highlight.width)/3 , outerYTop - (height - highlight.height)/3 );
  frame1.vertex(outerXRight - (width - highlight.width)/4 , outerYTop - (height - highlight.height)/4 );
  frame1.vertex(outerXRight - (width - highlight.width)/5 , outerYTop - (height - highlight.height)/5 );
  frame1.vertex(outerXRight, outerYTop);
  frame1.vertex(outerXRight, outerYBottom);
  frame1.vertex(outerXLeft, outerYBottom);
  frame1.endShape(CLOSE);
  
  frame2 = createShape();
  frame2.beginShape();
  frame2.stroke(edgeColor);
  frame2.strokeWeight(max((width - highlight.width)/2,(height - highlight.height)/2 )-100);
  frame2.noFill();
  frame2.beginShape();
  frame2.vertex(outerXLeft, outerYTop);
  frame2.vertex(outerXLeft + (width - highlight.width)/5 , outerYTop - (height - highlight.height)/5 );
  frame2.vertex(outerXLeft + (width - highlight.width)/4 , outerYTop - (height - highlight.height)/4 );
  frame2.vertex(outerXLeft + (width - highlight.width)/3 , outerYTop - (height - highlight.height)/3 );
  frame2.vertex(width/2,  outerYTop - (height - highlight.height)/2 );
  frame2.vertex(outerXRight - (width - highlight.width)/3 , outerYTop - (height - highlight.height)/3 );
  frame2.vertex(outerXRight - (width - highlight.width)/4 , outerYTop - (height - highlight.height)/4 );
  frame2.vertex(outerXRight - (width - highlight.width)/5 , outerYTop - (height - highlight.height)/5 );
  frame2.vertex(outerXRight, outerYTop);
  frame2.vertex(outerXRight, outerYBottom);
  frame2.vertex(outerXLeft, outerYBottom);
  frame2.endShape(CLOSE);
  
  frame3 = createShape();
  frame3.beginShape();
  frame3.stroke(0);
  frame3.strokeWeight(max((width - highlight.width)/2,(height - highlight.height)/2 )-150);
  frame3.noFill();
  frame3.beginShape();
  frame3.vertex(outerXLeft, outerYTop);
  frame3.vertex(outerXLeft + (width - highlight.width)/5 , outerYTop - (height - highlight.height)/5 );
  frame3.vertex(outerXLeft + (width - highlight.width)/4 , outerYTop - (height - highlight.height)/4 );
  frame3.vertex(outerXLeft + (width - highlight.width)/3 , outerYTop - (height - highlight.height)/3 );
  frame3.vertex(width/2,  outerYTop - (height - highlight.height)/2 );
  frame3.vertex(outerXRight - (width - highlight.width)/3 , outerYTop - (height - highlight.height)/3 );
  frame3.vertex(outerXRight - (width - highlight.width)/4 , outerYTop - (height - highlight.height)/4 );
  frame3.vertex(outerXRight - (width - highlight.width)/5 , outerYTop - (height - highlight.height)/5 );
  frame3.vertex(outerXRight, outerYTop);
  frame3.vertex(outerXRight, outerYBottom);
  frame3.vertex(outerXLeft, outerYBottom);
  frame3.endShape(CLOSE);
  

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
    // update point position
  
  for ( float[] point : points){
    point[0] += random(-pointDelta, pointDelta);
    point[1] += random(-pointDelta, pointDelta);
  }


  for ( Tile tileShown : tileListVertical) {    // draw and show tiles on left or right
    tileShown.display();
    tileShown.moveHorizontal();
  }
  for ( Tile tileShown : tileListHorizontal) {  // draw and show tiles on top or bottom
    tileShown.display();
    tileShown.moveVertical();
  }



  shape(frame1);
  shape(frame2);
  shape(frame3);


}


class Tile {
  float x, y;
  float r, g, b;
  float wh;
  float sWeight;
  float delta;

  Tile( float x_, float y_, float r_, float g_, float b_, float lowWH_, float highWH_ , float tileSWeight_ , float tileDelta_ ) {
    x = x_;
    y = y_;
    r = r_;
    g = g_;
    b = b_;
    wh = random( lowWH_, highWH_ );
    sWeight = tileSWeight_;
    delta = tileDelta_;
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

    boolean overLeftEdgeOfMiddle = x > (width - highlight.width)/2 + middleBorder;
    boolean overRightEdgeOfMiddle = x < width-(width - highlight.width)/2 - middleBorder;

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

    boolean overTopEdgeOfMiddle = y > (height - highlight.height)/2 + middleBorder;
    boolean overBottomEdgeOfMiddle = y < height-(height - highlight.height)/2 - middleBorder;

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

void mousePressed() {
  saveFrame("stainedGlassChallenge.jpg");
}
