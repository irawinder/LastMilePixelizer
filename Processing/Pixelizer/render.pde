// How big your table is, in pixels
int tableWidth = 800;
int tableHeight = int(tableWidth * float(displayV)/displayU);

//Global Text and Background Color
int textColor = 255;
int background = 0;
String align = "RIGHT";

color tanBrick =   #FFEA00;
color blueBrick =  #0000FF;
color redBrick =   #FF0000;
color blackBrick = #000000;
color greenBrick = #00FF00;

boolean flagResize = true;

/* Graphics Architecture:
 * 
 * projector  <-  main  <-  table  <-  (p)opulation, (h)eatmap, (s)tores(s), (l)ines, (c)ursor
 *                 ^
 *                 |
 *               screen <-  (i)nfo <-  minimap, legendH, legendP
 */
 
PGraphics screen, table;
PGraphics h, s, l, i, c, p, input, output, pieces;
float gridWidth, gridHeight;
PGraphics legendH, legendP, legendI, legendO;

// Standard Minimum Margin Width
int STANDARD_MARGIN = 25;

// Horizontal Offset for Table Display Window
int TABLE_IMAGE_OFFSET = 550;

// Table Canvas Width and Height
int TABLE_IMAGE_HEIGHT, TABLE_IMAGE_WIDTH;

void renderTable() {
  table.beginDraw();
  table.clear();
  table.background(background);
  
  // Draws a Google Satellite Image
  renderBasemap(table);
  
  if (showPopulationData){
    table.image(p, 0, 0);
  }
  
  if (showDeliveryData) {
    table.image(h, 0, 0);
  }
 
  if (showStores) {
    table.image(s, 0, 0);
  }
  
  if (showOutputData) {
    table.image(output, 0, 0);
  }
  
  if (showInputData) {
    table.image(input, 0, 0);
  }
  
  // Draws lines
  table.image(l, 0, 0);
  
  // Draws Cursor
  renderCursor(c);
  table.image(c, 0, 0);
  
  table.endDraw();
}

void renderScreen() {
  screen.beginDraw();
  screen.clear();
  renderInfo(i, 2*TABLE_IMAGE_OFFSET + TABLE_IMAGE_WIDTH, STANDARD_MARGIN, mapRatio*TABLE_IMAGE_WIDTH, mapRatio*TABLE_IMAGE_HEIGHT);
  screen.image(i, 0, 0);
  
  // Draws Menu
  buttonHovering = false;
  hideMenu.draw(screen);
  if (showMainMenu) {
    mainMenu.draw(screen);
  }
  screen.endDraw();
}

void reRender() {
  
  // Renders Static Data Layers to Canvases
  renderStaticTableLayers(h, s, p);
  
  // Renders Dynamic Table Layers to Canvases
  renderDynamicTableLayers(input);
  
  // Renders Output Table Layers to Canvases
  renderOutputTableLayers(output);
  
  // reRender Minimap
  reRenderMiniMap(miniMap);
  
  // Renders Outlines of Lego Data Modules (a 4x4 lego stud piece)
  renderLines(l);
  
  // Renders Legends
  renderLegends();
  
  // Renders Text
  renderInfo(i, 2*TABLE_IMAGE_OFFSET + TABLE_IMAGE_WIDTH, STANDARD_MARGIN, mapRatio*TABLE_IMAGE_WIDTH, mapRatio*TABLE_IMAGE_HEIGHT);
}

// Graphics Objects for Data Layers
void initDataGraphics() {
  
  screen = createGraphics(screenWidth, screenHeight);
  i = createGraphics(screen.width, screen.height); // Information
  miniMap = createGraphics(4*displayU, 4*displayV);

  // Table Layers
  table = createGraphics(tableWidth, tableHeight); // Main Table Canvas
  h = createGraphics(table.width, table.height);   // Heatmap Cells
  p = createGraphics(table.width, table.height);   // Population Cells
  s = createGraphics(table.width, table.height);   // Store Dots
  l = createGraphics(table.width, table.height);   // lines
  c = createGraphics(table.width, table.height);   // Cursor
  input = createGraphics(table.width, table.height);   // Input Data
  output = createGraphics(table.width, table.height);  // Output Data
  pieces = createGraphics(table.width, table.height);  // Superficial coloring of Pieces
  
  int legendWidth = 40;
  int legendHeight = 100;
  legendH = createGraphics(legendWidth, legendHeight);
  legendP = createGraphics(legendWidth, legendHeight);
  
  
  legendI = createGraphics(legendWidth, legendHeight);
  legendO = createGraphics(legendWidth, legendHeight);
}

// Draws a Google Satellite Image
void renderBasemap(PGraphics graphic) {
  if (showBasemap) {
    graphic.image(basemap, 0, 0, table.width, table.height);
  }
}

// Methods for handling parameter changes due to screen resize

  void initScreenOffsets() {
    screenWidth = width;
    screenHeight = height;
    screen = createGraphics(screenWidth, screenHeight);
    i = createGraphics(screenWidth, screenHeight);
           
    TABLE_IMAGE_HEIGHT = screenHeight - 2*STANDARD_MARGIN;
    TABLE_IMAGE_WIDTH = int(((float)displayU/displayV)*TABLE_IMAGE_HEIGHT);
  }

// Methods for drawing Layers onto Table

    float POP_RENDER_MIN = 10.0; // per 1 SQ KM
      
    // Rully Renders Every Possible Layer we would want to draw on canvas
    void renderStaticTableLayers(PGraphics h, PGraphics s, PGraphics p) {
      
      // Dynamically adjusts grid size to fit within canvas dimensions
      gridWidth = float(table.width)/displayU;
      gridHeight= float(table.height)/displayV;
      
      // clear canvases
      h.beginDraw();
      h.clear();
      
      s.beginDraw();
      s.clear();
      
      p.beginDraw();
      p.clear();
      
      // makes it so that colors are defined by Hue, Saturation, and Brightness values (0-255 by default)
      h.colorMode(HSB);
      s.colorMode(HSB);
      p.colorMode(HSB);
      
      for (int u=0; u<displayU; u++) {
        for (int v=0; v<displayV; v++) {
          // Only loads data within bounds of dataset
          if (u+gridPanU>=0 && u+gridPanU<gridU && v+gridPanV>=0 && v+gridPanV<gridV) {
            float normalized;
            color from, to; 
            
            // HEATMAP
            if (valueMode.equals("source")) {
              normalized = findStoreFill(h, heatmap[u+gridPanU][v+gridPanV]);
              if (normalized == 0) {h.noFill();}
            } else {
              normalized = findHeatmapFill(h, heatmap[u+gridPanU][v+gridPanV]);
            }
            // Doesn't draw a rectangle for values of 0
            h.noStroke(); // No lines draw around grid cells
            if (normalized >= 0) {
              h.rect(u*gridWidth, v*gridHeight, gridWidth, gridHeight);
            }
            
            // POPULATION
            if (pop[u+gridPanU][v+gridPanV] > 10.0*sq(gridSize)) {
              normalized = findPopFill(p, pop[u+gridPanU][v+gridPanV]);
              // Doesn't draw a rectangle for values of 0
              p.noStroke(); // No lines draw around grid cells
              p.rect(u*gridWidth, v*gridHeight, gridWidth, gridHeight);
            }
            
            //STORES
            normalized = findStoreFill(s, stores[u+gridPanU][v+gridPanV]);
            //Outlines stores
            s.strokeWeight(4);
            s.stroke(background);
            s.fill(greenBrick);
            // Doesn't draw a rectangle for values of 0
            if (normalized != 0) {
              s.ellipse((u+.5)*gridWidth, (v+.5)*gridHeight, gridWidth, gridHeight);
            }
          }
        }
      }
      h.endDraw();
      s.endDraw();
      p.endDraw();
    }
    
    float findHeatmapFill(PGraphics graphic, float heatmap) {
        float normalized;
        color from, to;        
        
        //BEGIN Drawing HEATMAP
        from = color(0,255,0);
        to = color(255,0,0);
        
        // Draw Heatmap
        try {
          // heatmap value is normalized to a value between 0 and 1;
          normalized = (heatmap - heatmapMIN)/(heatmapMAX-heatmapMIN);
        } catch(Exception ex) {
          normalized = (0 - heatmapMIN)/(heatmapMAX-heatmapMIN);
        }
        
        // Hue Color of the grid is function of heatmap value;
        // 0.25 coefficient narrows the range of colors used
        // 100 + var offsets the range of colors used
        
        graphic.colorMode(HSB);
        
        int alpha = 100;
        
        if (valueMode.equals("totes") || valueMode.equals("deliveries")) {
          // Narrower Color Range
          graphic.fill(0.75*255*(1-normalized), 255, 255, alpha);
          graphic.stroke(0.75*255*(1-normalized), 255, 255, alpha);
        } else if (valueMode.equals("source")) {
          // Less Narrower Color Range
          graphic.fill(0.75*255*normalized, 255, 255, alpha);
          graphic.stroke(0.75*255*normalized, 255, 255, alpha);
        } else if (valueMode.equals("doorstep")) {
          // Less Narrower Color Range, reversed
          graphic.fill(lerpColor(from,to,normalized), alpha);
          graphic.stroke(lerpColor(from,to,normalized), alpha);
        } else {
          // Full Color Range
          graphic.fill(255*normalized, 255, 255, alpha);
          graphic.stroke(255*normalized, 255, 255, alpha);
        }
        
        return normalized;
    }
    
    float findPopFill(PGraphics graphic, float pop) {
        float normalized;
        color from, to;  
        
        //BEGIN Drawing POPULATION
        from = color(#000AF7, 100); // Blue
        to = color(#FF0000);   // Red
        
        // Draw Population
        try {
        // heatmap value is normalized to a value between 0 and 1;
    //      normalized = ( sqrt(sqrt(pop)) - sqrt(sqrt(popMIN)))/sqrt(sqrt(popMAX-popMIN));
            normalized = ( sqrt(pop) - sqrt(popMIN))/sqrt(popMAX-popMIN);
    //      normalized = ( pop - popMIN)/(popMAX-popMIN);
        } catch(Exception ex) {
          normalized = (0 - popMIN)/(popMAX-popMIN);
        }
        
        graphic.colorMode(HSB);
        graphic.fill(lerpColor(from,to,normalized));
        graphic.stroke(lerpColor(from,to,normalized));
        
        return normalized;
    }
    
    float findStoreFill(PGraphics graphic, float stores) {
        float normalized;  
        int alpha = 100;
        
        // BEGIN Drawing Draws Store Locations
        try {
          // heatmap value is normalized to a value between 0 and 1;
          normalized = (stores - storesMIN)/(storesMAX-storesMIN);
        } catch(Exception ex) {
          normalized = (0 - storesMIN)/(storesMAX-storesMIN);
        }
      
        // Full Color Range
        graphic.colorMode(HSB);
        graphic.fill(255*normalized, 255, 255, alpha);
        graphic.stroke(255*normalized, 255, 255, alpha);
            
        return normalized;
    }
    
    // Rully Renders Every Possible Dynamic Layer we would want to draw on canvas
    void renderDynamicTableLayers(PGraphics input) {
      
      // Dynamically adjusts grid size to fit within canvas dimensions
      gridWidth = float(table.width)/displayU;
      gridHeight= float(table.height)/displayV;
      
      // clear canvases
      input.beginDraw();
      input.clear();
      
      // makes it so that colors are defined by Hue, Saturation, and Brightness values (0-255 by default)
      input.colorMode(HSB);
      
      if (showFacilities) {
        for (int i=0; i<facilitiesList.size(); i++) {
          Facility current = facilitiesList.get(i);
          input.fill(float(i)/facilitiesList.size()*255, 255, 255); // Temp Color Gradient
          input.stroke(float(i)/facilitiesList.size()*255, 255, 255); // Temp Color Gradient
          input.strokeWeight(4);
          input.rect(current.u*gridWidth, current.v*gridHeight, gridWidth, gridHeight);
        }
      }
            
      for (int u=0; u<displayU; u++) {
        for (int v=0; v<displayV; v++) {
          // Only loads data within bounds of dataset
          if (u+gridPanU>=0 && u+gridPanU<gridU && v+gridPanV>=0 && v+gridPanV<gridV) {
            
            float ID;
            input.noStroke(); // No lines draw around grid cells
            
            if (showMarket) {
              ID = market[u+gridPanU][v+gridPanV];
              input.fill(#FFFFFF);
              if (ID >= 1) {
                input.rect(u*gridWidth, v*gridHeight, gridWidth, gridHeight);
              }
            }
            
            if (showObstacles) {
              ID = obstacles[u+gridPanU][v+gridPanV];
              input.fill(0);
              if (ID == 1) {
                input.rect(u*gridWidth, v*gridHeight, gridWidth, gridHeight);
              }
            }
            
            if (showForm) {
              findFormFill(input, form[u+gridPanU][v+gridPanV]);
              input.rect(u*gridWidth, v*gridHeight, gridWidth, gridHeight);
            }
            
          }
        }
      }
      input.endDraw();
    }
    
    void findFormFill(PGraphics input, int ID) {
      if (ID == 0) {
        input.noFill();
      } else if (ID == 1) {
        input.fill(tanBrick);
      } else if (ID == 2) {
        input.fill(blueBrick);
      } else if (ID == 3) {
        input.fill(redBrick);
      } else if (ID == 4) {
        input.fill(blackBrick);
      } else if (ID == 5) {
        input.fill(greenBrick);
      }
    }

    // Methods for Drawing "Output" Layers 
    // Fully Renders Every Possible Output Layer we would want to draw on canvas
    // (i.e. layers resulting from an external simulation client)
    
    float MAX_DELIVERY_COST_RENDER = 30.0;
    
    void renderOutputTableLayers(PGraphics output) {
      
      float normalized;
      color from, to;  
      
      //BEGIN Drawing POPULATION
      to = color(#FF0000, 75); // Red
      from = color(#00FF00, 75);   // Green
        
      // Dynamically adjusts grid size to fit within canvas dimensions
      gridWidth = float(table.width)/displayU;
      gridHeight= float(table.height)/displayV;
      
      // clear canvases
      output.beginDraw();
      output.clear();
      
      // makes it so that colors are defined by Hue, Saturation, and Brightness values (0-255 by default)
      output.colorMode(HSB);
      
      for (int u=0; u<displayU; u++) {
        for (int v=0; v<displayV; v++) {
          // Only loads data within bounds of dataset
          if (u+gridPanU>=0 && u+gridPanU<gridU && v+gridPanV>=0 && v+gridPanV<gridV) {
            
//            if ( pop[u][v] > POP_RENDER_MIN ) {
              float value;
              output.noStroke(); // No lines draw around grid cells
              
              if (showDeliveryCost && pop[u][v] > POP_RENDER_MIN ) {
                //value = (deliveryCost[u+gridPanU][v+gridPanV] - deliveryCostMIN)/deliveryCostMAX;
                value = deliveryCost[u+gridPanU][v+gridPanV]/MAX_DELIVERY_COST_RENDER;
                if (value >= 0 && value != Float.POSITIVE_INFINITY) {
                  output.fill(lerpColor(from, to, value));
                  output.rect(u*gridWidth, v*gridHeight, gridWidth, gridHeight);
                }
              }
              
              if (showTotalCost) {
                value = totalCost[u+gridPanU][v+gridPanV];
                if (value >= 0  && value != Float.POSITIVE_INFINITY) {
                  output.fill(lerpColor(from, to, value));
                  output.rect(u*gridWidth, v*gridHeight, gridWidth, gridHeight);
                }
              }
              
              if (showAllocation && pop[u][v] > POP_RENDER_MIN ) {
                value = allocation[u+gridPanU][v+gridPanV];
                if (value != 0) {
                  output.fill(value/facilitiesList.size()*255, 255, 255, 100); // Temp Color Gradient
                  output.rect(u*gridWidth, v*gridHeight, gridWidth, gridHeight);
                }
              }
              
              if (showVehicle) {
                value = vehicle[u+gridPanU][v+gridPanV];
                if (value != 0) {
                  output.fill(value/5.0*255, 255, 255, 100); // Temp Color Gradient
                  output.rect(u*gridWidth, v*gridHeight, gridWidth, gridHeight);
                }
              }
//            }
          }
        }
      }
      output.endDraw();
    }

// Methods for drawing lines representing lego piece boundaries

    // Draws Outlines of Lego Data Modules (a 4x4 lego stud piece)
    void renderLines(PGraphics l) {
      l.beginDraw();
      l.clear();
      l.stroke(255, 50);
      l.strokeWeight(1.5);
      for (int i=1; i<displayU/4; i++) {
        l.line(table.width*i/(displayU/4.0), 0, table.width*i/(displayU/4.0), table.height);
      }
      for (int i=1; i<displayV/4; i++) {
        l.line(0, table.height*i/(displayV/4.0), table.width, table.height*i/(displayV/4.0));
      }
      l.endDraw();
    }

// Methods for drawing text information on Screen

    void renderInfo(PGraphics i, int x_0, int y_0, float w, float h) {
      i.beginDraw();
      i.clear();
      
      // Draw Rectangle around main canvas
      i.noFill();
      i.stroke(textColor);
      i.strokeWeight(1);
      i.rect(TABLE_IMAGE_OFFSET, STANDARD_MARGIN, TABLE_IMAGE_WIDTH, TABLE_IMAGE_HEIGHT);
      
      
      i.translate(TABLE_IMAGE_OFFSET - STANDARD_MARGIN - w, STANDARD_MARGIN + TABLE_IMAGE_HEIGHT);
      
        // Draw Scale
        
        int scale_0 = 10;
        int scale_1 = int(w + STANDARD_MARGIN);
        i.translate(-scale_0, 0);
        float scalePix = float(TABLE_IMAGE_HEIGHT)/displayV;
        i.translate(0, -4*scalePix);
        i.line(scale_0, 0, scale_1, 0);
        i.line(scale_0, -4*scalePix, scale_1, -4*scalePix);
        i.line(2*scale_0, 0, 2*scale_0, -scalePix);
        i.line(2*scale_0, -3*scalePix, 2*scale_0, -4*scalePix);
        i.text(4*gridSize + " km", 0, -1.5*scalePix);
        i.translate(scale_0, 0);
        
        if (showPopulationData) {
          float legendPix = -STANDARD_MARGIN-4*scalePix-legendP.height;
          // Draw Legends
          i.image(legendP, 0, legendPix);
          
          int demandMIN = 0;
          int demandMAX = 0;
          
          demandMIN = int(dailyDemand(popMIN+1));
          demandMAX = int(dailyDemand(popMAX));
          
          i.text("Demand Potential", 0, legendPix - 35);
          i.text("Source: 2010 U.S. Census Data", 0, legendPix - 20);
          i.text(int(demandMIN) + " deliveries per day", STANDARD_MARGIN + legendP.width, legendPix + legendP.height);
          i.text(int(demandMAX) + " deliveries per day", STANDARD_MARGIN + legendP.width, legendPix+10);
        }
        
        if (showDeliveryData) {
          float legendPix = -3*STANDARD_MARGIN-4*scalePix-2*legendH.height-20;
          if (valueMode.equals("source")) {
            float normalized;
            int column = -1;
            i.text("Delivery Facility Allocations", 0, legendPix - 35);
            i.text("Source: Walmart 2015", 0, legendPix - 20);
            for (int j=0; j<storeID.size(); j++) {
              if (j % 8 == 0) {
                column++;
              }
              normalized = findHeatmapFill(i, (float)storeID.get(j));
              for (int k=0; k<4; k++) i.text("StoreID: " + storeID.get(j), STANDARD_MARGIN*(column*5+1), legendPix+10+(j-column*8)*15);
            }
          } else { 
            // Draw Legends
            i.image(legendH, 0, legendPix);
            i.text("Delivery Data", 0, legendPix - 35);
            i.text("Source: Walmart 2015", 0, legendPix - 20);
            i.text(int(heatmapMIN+1) + " " + valueMode, STANDARD_MARGIN + legendP.width, legendPix + legendP.height);
            i.text(int(heatmapMAX) + " " + valueMode, STANDARD_MARGIN + legendP.width, legendPix+10);
          }
        }
      
      i.translate(0, +4*scalePix);
      
      i.translate(-(TABLE_IMAGE_OFFSET - STANDARD_MARGIN - w), -(STANDARD_MARGIN + TABLE_IMAGE_HEIGHT));
      
      i.fill(textColor);
      i.textAlign(RIGHT);
      i.text("Pixelizer v1.0", screen.width - 10, screen.height - STANDARD_MARGIN - 15);
      i.text("Ira Winder, jiw@mit.edu", screen.width - 10, screen.height - STANDARD_MARGIN);
      
    
      i.textAlign(LEFT);
      String suffix = "";
      String prefix = "";
      if (valueMode.equals("totes") || valueMode.equals("deliveries") ) {
        suffix = " " + valueMode;
      } else if ( valueMode.equals("source") ) {
        prefix = "StoreID ";
      }  else if ( valueMode.equals("doorstep") ) {
        suffix = " seconds";
      }
      
      i.translate(TABLE_IMAGE_OFFSET - STANDARD_MARGIN - w, 2*STANDARD_MARGIN + h + 10);
      
      // Main Info
      i.fill(textColor);
      i.text(fileName.toUpperCase(), 0, 0);
      i.text("Last Mile Logistics", 0, 15);
      
      if (showFrameRate) {
        i.text("FrameRate: " + frameRate, 0, 45);
      }
      
      i.translate(0, 80);
      
      if (showDeliveryData || showPopulationData || showOutputData) {
        i.text("CELL INFO", 0, 0);
        i.text("2015 Delivery Data:", 0, 20);
        i.text("Population Value:", 0, 50);
        i.text("Demand Potential:", 0, 80);
        i.text("Cost Per Delivery:", 0, 110);
      }
      i.colorMode(RGB);
      i.fill(0,255,255);
      String value = "";
      if (showDeliveryData) {
        value = "";
        if ((int)getCellValue(mouseToU(), mouseToV()) == -1) {
          value = "NO_DATA";
        } else {
          value += (int)getCellValue(mouseToU(), mouseToV());
          i.text(prefix + value + suffix, 0, 35);
        }
      }
      if (showPopulationData) {
        value = "";
        if ((int)getCellPop(mouseToU(), mouseToV()) == -1) {
          value = "NO_DATA";
        } else {
          value += (int)getCellPop(mouseToU(), mouseToV());
          i.text(value + " " + popMode, 0, 65);
          float temp = float(value);
          if (popMode.equals("POP10")) {
            i.text(int(temp/HOUSEHOLD_SIZE*WEEKS_IN_YEAR*WALMART_MARKET_SHARE/DAYS_IN_YEAR) + " Deliveries per Day", 0, 95);
          } else if (popMode.equals("HOUSING10")) {
            i.text(int(temp*WEEKS_IN_YEAR*WALMART_MARKET_SHARE/DAYS_IN_YEAR) + " Deliveries per Day", 0, 95);
          }
        }
      }
      if (showOutputData) {
        value = "";
        if (getCellDeliveryCost(mouseToU(), mouseToV()) == -1) {
          value = "NO_DATA";
        } else {
          value += getCellDeliveryCost(mouseToU(), mouseToV());
          i.text(value, 0, 125);
        }
      }
      
      i.endDraw();
      
      
      // Draw MiniMap
      i.beginDraw();
      i.translate(TABLE_IMAGE_OFFSET - STANDARD_MARGIN - w, y_0);  
      i.image(miniMap, 0, 0, w, h);
      i.noFill();
      i.stroke(textColor);
      i.rect(w*gridPanU/gridU, h*gridPanV/gridV, w*(0.5*gridSize), h*(0.5*gridSize));
    
      i.endDraw();
    }
    
    int mouseToU() {
      return int(displayU*(float)(mouseX - TABLE_IMAGE_OFFSET)/TABLE_IMAGE_WIDTH) + gridPanU;   
    }
    
    int mouseToV() {
      return int(displayV*(float)(mouseY - STANDARD_MARGIN)/TABLE_IMAGE_HEIGHT) + gridPanV;
    }
    
    float getCellValue(int u, int v) {
      try {
        return heatmap[u][v];
      }  catch(RuntimeException e) {
        return -1;
      }
    }
    
    float getCellPop(int u, int v) {
      try {  
        return pop[u][v];
      }  catch(RuntimeException e) {
        return -1;
      }
    }
    
    float getCellDeliveryCost(int u, int v) {
      try {  
        return deliveryCost[u][v];
      }  catch(RuntimeException e) {
        return -1;
      }
    }

// Methods for Rendering Cursor

    void renderCursor(PGraphics c) {
      c.beginDraw();
      c.clear();
      c.noFill();
      c.strokeWeight(2);
      
      int x, y;
      
      // Render Mouse
      c.stroke(0, 255, 255);
      x = mouseToU() - gridPanU;
      y = mouseToV() - gridPanV;
      c.rect(x*gridWidth, y*gridWidth, gridWidth, gridWidth);
      
    //  // Render Selection
    //  c.stroke(0, 255, 0);
    //  x = selectionU - gridPanU;
    //  y = selectionV - gridPanV;
    //  c.rect(x*gridWidth, y*gridWidth, gridWidth, gridWidth);
      
      c.endDraw();
    }

// Methods for Rendering Legend

    void renderLegends() {
      
      float normalized;
      int intervals = 10;
      int h = legendP.height/intervals;
      
      
      legendP.beginDraw();
      legendP.clear();
      for (int i=0; i<intervals; i++) {
         normalized = findPopFill(legendP, (intervals-i-1)*popMAX/intervals);
         legendP.rect(0, i*h, legendP.width, h);
      }
      legendP.endDraw();
      
      legendH.beginDraw();
      legendH.clear();
      for (int i=0; i<intervals; i++) {
         normalized = findHeatmapFill(legendH, (intervals-i-1)*heatmapMAX/intervals);
         legendH.rect(0, i*h, legendH.width, h);
      }
      legendH.endDraw();
    }

// Methods for Rendering a MiniMap

    PGraphics miniMap;
    PImage miniBaseMap;
    float mapRatio = 0.3;
    
    void loadMiniBaseMap() {
      miniBaseMap = loadImage("data/" + mapColor + "/" + fileName + "_2000.png");
      miniBaseMap.resize(2*displayU, 2*displayV);
    }
    
    void reRenderMiniMap(PGraphics miniMap) {
      
      //println(miniMap.width, miniMap.height);
      
      miniMap.beginDraw();
      miniMap.clear();
      miniMap.background(background);
      if (showBasemap) {
        miniMap.image(miniBaseMap, 0, 0, miniMap.width, miniMap.height);
      }
      miniMap.colorMode(HSB);
      miniMap.fill(textColor);
      
      float normalized;
      color from, to;
      
      miniMap.stroke(textColor);
      miniMap.strokeWeight(1);
      
      float pixel_per_U = (float)miniMap.width/gridU;
      float pixel_per_V = (float)miniMap.height/gridV;
      
      for (int u=0; u<gridU; u++) {
        for (int v=0; v<gridV; v++) {
          
          if (showPopulationData){
            if (pop[u][v] > 10.0*sq(gridSize)) {
              // HEATMAP
              normalized = findPopFill(miniMap, pop[u][v]);
              miniMap.noStroke();
              miniMap.rect(u*pixel_per_U,v*pixel_per_V, pixel_per_U, pixel_per_V);
            }
          }
          if (showDeliveryData) {
            if (heatmap[u][v] > 0) {
              // HEATMAP
              normalized = findHeatmapFill(miniMap, heatmap[u][v]);
              miniMap.noStroke();
              miniMap.rect(u*pixel_per_U,v*pixel_per_V, pixel_per_U, pixel_per_V);
            }
          }
          if (showInputData) {
            if (showForm) {
              findFormFill(miniMap, form[u][v]);
              miniMap.noStroke();
              miniMap.rect(u*pixel_per_U,v*pixel_per_V, pixel_per_U, pixel_per_V);
            } else {
              if (facilities[u][v] > 0) {
                // HEATMAP
                miniMap.fill(greenBrick);
                miniMap.noStroke();
                miniMap.rect(u*pixel_per_U,v*pixel_per_V, pixel_per_U, pixel_per_V);
              }
              if (market[u][v] > 0) {
                // HEATMAP
                miniMap.fill(blackBrick);
                miniMap.noStroke();
                miniMap.rect(u*pixel_per_U,v*pixel_per_V, pixel_per_U, pixel_per_V);
              }
            }
          }
        }
      }
      
      miniMap.endDraw();
      miniMap.beginDraw();
      
      if (showStores) {
        for (int u=0; u<gridU; u++) {
          for (int v=0; v<gridV; v++) {
            if (stores[u][v] != 0) {
              // HEATMAP
              normalized = findStoreFill(miniMap, stores[u][v]);
              if (normalized == 0) {
                miniMap.noFill();
              } else {
                miniMap.fill(greenBrick);
              }
              miniMap.stroke(background);
              miniMap.strokeWeight(4);
              miniMap.ellipse(u*pixel_per_U,v*pixel_per_V,12,12);
            }
          }
        }
      }
          
      miniMap.endDraw();
    }
    
// Draw Piece Typologies

  void renderPieceLegend(PGraphics legendI) {
    legendI.beginDraw();
    
  }
