Table table;
IntDict genreCounts;

// State management variables
int screenState = 0; // 0 = Genre Grid, 1 = Zoomed Genre Detail
String selectedGenre = "";

// Store button positions for click detection in State 0
ArrayList<GenreButton> genreButtons = new ArrayList<GenreButton>();

void setup() {
  size(1100, 850);
  table = loadTable("watch_history.csv", "header");
  genreCounts = new IntDict();

  // Count frequencies of each primary genre
  for (int i = 0; i < table.getRowCount(); i++) {
    String genre = table.getString(i, "Primary Genre");
    if (genre != null && !genre.isEmpty()) {
      genreCounts.increment(genre);
    }
  }
  genreCounts.sortValuesReverse();

  // Setup grid button coordinates
  calculateGridButtons();
}

void draw() {
  background(245);

  if (screenState == 0) {
    drawGenreGrid();
  } else if (screenState == 1) {
    drawGenreDetailView(selectedGenre);
  }
}

// --- STATE 0: GRID VIEW ---
void calculateGridButtons() {
  float startX = 90;
  float startY = 120;
  float spacingX = 160;
  float spacingY = 150;
  float currentX = startX;
  float currentY = startY;

  for (int i = 0; i < genreCounts.size(); i++) {
    String genre = genreCounts.key(i);
    int count = genreCounts.value(i);
    
    float size = constrain(map(count, 1, 30, 26, 70), 26, 70);

    genreButtons.add(new GenreButton(genre, currentX, currentY, size, count));

    currentX += spacingX;
    if (currentX > width - 100) {
      currentX = startX;
      currentY += spacingY;
    }
  }
}

void drawGenreGrid() {
  fill(30);
  textSize(22);
  textAlign(LEFT, TOP);
  text("Watch History: Click a genre to view duration breakdown", 70, 40);

  for (GenreButton btn : genreButtons) {
    pushMatrix();
    translate(btn.x, btn.y);

    noStroke();
    
    // Custom shape and color mapping with lower-bound lighter shades
    if (btn.count == 1) {
      fill(140, 180, 210); // Lighter triangle
      drawPolygon(3, btn.size);
    }
    else if (btn.count == 2) {
      fill(70, 130, 180); // Standard triangle
      drawPolygon(3, btn.size);
    } 
    else if (btn.count >= 3 && btn.count <= 4) {
      if (btn.count == 3) {
        fill(150, 210, 180); 
      } else {
        fill(90, 170, 140); 
      }
      drawPolygon(4, btn.size);
    } 
    else if (btn.count >= 5 && btn.count <= 6) {
      if (btn.count == 5) {
        fill(240, 215, 175); 
      } else {
        fill(222, 184, 135); 
      }
      drawPolygon(5, btn.size);
    } 
    else if (btn.count >= 7 && btn.count <= 8) {
      if (btn.count == 7) {
        fill(240, 160, 120); 
      } else {
        fill(220, 120, 80); 
      }
      drawPolygon(6, btn.size);
    } 
    else {
      if (btn.count == 9) {
        fill(235, 140, 140); 
      } else {
        fill(205, 92, 92);  
      }
      ellipse(0, 0, btn.size, btn.size);
    }

    float textOffsetY = 38;
    fill(40);
    textAlign(CENTER, TOP);
    textSize(11);
    text(btn.genre, 0, textOffsetY);
    
    textSize(10);
    fill(120);
    text("(" + btn.count + ")", 0, textOffsetY + 15);

    popMatrix();
  }
}

void drawPolygon(int sides, float diameter) {
  float radius = diameter / 2;
  beginShape();
  for (int i = 0; i < sides; i++) {
    float angle = TWO_PI / sides * i - HALF_PI;
    float x = cos(angle) * radius;
    float y = sin(angle) * radius;
    vertex(x, y);
  }
  endShape(CLOSE);
}

// --- STATE 1: ZOOMED DETAIL VIEW (PIE CHART WITH DISTINCT COLORS) ---
void drawGenreDetailView(String genreName) {
  fill(30);
  textSize(24);
  textAlign(LEFT, TOP);
  text("Genre Breakdown: " + genreName, 70, 40);

  fill(200, 50, 50);
  rectMode(CORNER);
  rect(width - 150, 40, 90, 35, 5);
  fill(255);
  textSize(14);
  textAlign(CENTER, CENTER);
  text("<- Back", width - 105, 57);

  int countLE5 = 0;
  int countLE10 = 0;
  int countLE30 = 0;
  int countLE60 = 0;
  int countGT60 = 0;

  for (int i = 0; i < table.getRowCount(); i++) {
    String g = table.getString(i, "Primary Genre");
    if (g.equals(genreName)) {
      String durStr = table.getString(i, "Duration");
      float durationMinutes = parseDurationToMinutes(durStr);
      
      if (durationMinutes <= 5) countLE5++;
      else if (durationMinutes <= 10) countLE10++;
      else if (durationMinutes <= 30) countLE30++;
      else if (durationMinutes <= 60) countLE60++;
      else countGT60++;
    }
  }

  int totalGenreVideos = countLE5 + countLE10 + countLE30 + countLE60 + countGT60;

  float centerX = width / 2 - 90;
  float centerY = height / 2 + 40;
  float diameter = 340;

  if (totalGenreVideos == 0) {
    fill(150);
    textAlign(CENTER, CENTER);
    textSize(16);
    text("No video duration data found for this genre.", centerX, centerY);
    return;
  }

  // Distinct, high-contrast color palette for duration ranges
  color[] sliceColors = {
    color(70, 160, 160),  // <= 5 mins (Teal)
    color(230, 150, 60),  // 5 - 10 mins (Amber/Orange)
    color(210, 80, 90),   // 10 - 30 mins (Coral Red)
    color(130, 90, 180),  // 30 - 60 mins (Purple)
    color(70, 100, 140)   // > 60 mins (Steel Blue)
  };

  int[] counts = {countLE5, countLE10, countLE30, countLE60, countGT60};
  String[] labels = {"<= 5 mins", "5 - 10 mins", "10 - 30 mins", "30 - 60 mins", "> 60 mins"};

  float lastAngle = -HALF_PI;
  noStroke();
  
  for (int i = 0; i < counts.length; i++) {
    if (counts[i] > 0) {
      float sliceAngle = (float(counts[i]) / totalGenreVideos) * TWO_PI;
      fill(sliceColors[i]);
      arc(centerX, centerY, diameter, diameter, lastAngle, lastAngle + sliceAngle, PIE);
      lastAngle += sliceAngle;
    }
  }

  // Donut hole overlay
  fill(245);
  ellipse(centerX, centerY, 130, 130);
  
  fill(50);
  textAlign(CENTER, CENTER);
  textSize(14);
  text("Total", centerX, centerY - 9);
  textSize(18);
  text(totalGenreVideos, centerX, centerY + 11);

  // Draw Legend on the side
  float legendX = centerX + diameter / 2 + 70;
  float legendY = centerY - 100;
  
  for (int i = 0; i < labels.length; i++) {
    fill(sliceColors[i]);
    rectMode(CORNER);
    rect(legendX, legendY + (i * 38), 18, 18, 3);
    
    fill(40);
    textSize(13);
    textAlign(LEFT, CENTER);
    text(labels[i] + ": " + counts[i], legendX + 30, legendY + (i * 38) + 9);
  }
}

float parseDurationToMinutes(String durStr) {
  if (durStr == null || durStr.isEmpty()) return 0;
  String[] parts = split(durStr.trim(), ':');
  if (parts.length == 2) {
    return int(parts[0]) + int(parts[1]) / 60.0;
  } else if (parts.length == 3) {
    return int(parts[0]) * 60 + int(parts[1]) + int(parts[2]) / 60.0;
  }
  return 0;
}

void mousePressed() {
  if (screenState == 0) {
    for (GenreButton btn : genreButtons) {
      if (dist(mouseX, mouseY, btn.x, btn.y) < btn.size / 2) {
        selectedGenre = btn.genre;
        screenState = 1;
        break;
      }
    }
  } else if (screenState == 1) {
    if (mouseX >= width - 150 && mouseX <= width - 60 && mouseY >= 40 && mouseY <= 75) {
      screenState = 0;
    }
  }
}

class GenreButton {
  String genre;
  float x, y, size;
  int count;

  GenreButton(String genre, float x, float y, float size, int count) {
    this.genre = genre;
    this.x = x;
    this.y = y;
    this.size = size;
    this.count = count;
  }
}