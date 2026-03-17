/*
 * ============================================================================
 * CS171 Computer Systems Project - Gobang Game with Personalized Skill System
 * Student: Zhangjie Zhuo | Student ID: 25126997
 * Development Environment: Processing 3.5.4 | OS: Windows 11
 * 
 * EXTERNAL LIBRARIES AND REFERENCES:
 * ============================================================================
 * 1. Processing Core Library
 *    - Source: https://processing.org/
 *    - Usage: Basic graphics, event handling, and application framework
 *    - Modified: Extended with custom game logic and personalized mechanics
 * 
 * 2. Processing Sound Library (processing.sound.*)
 *    - Source: https://processing.org/reference/libraries/sound/
 *    - Version: Included with Processing 3.5.4
 *    - Usage: Audio playback for game sounds and background music
 *    - Modified: Integrated with game events and skill activation
 * 
 * 3. Java Collections Framework (java.util.*)
 *    - Source: Standard Java SE Library
 *    - Usage: ArrayList, Collections for data management
 *    - Modified: Used for game state tracking and AI decision-making
 * 
 * 4. Game Design Patterns Reference
 *    - Source: General game development principles
 *    - Inspired by: State Machine pattern for game flow control
 *    - Implementation: Custom 4-state FSM (LOGIN, LOADING, CHARACTER_SELECT, GAME)
 * 
 * 5. Five-in-a-Row (Gomoku) AI Algorithms
 *    - Reference: Common heuristic approaches for board game AI
 *    - Adapted from: Basic threat detection and strategic positioning concepts
 *    - Modifications: Enhanced with 4-layer decision hierarchy and skill integration
 * 
 * 6. Original Work and Customizations:
 *    - All game mechanics, skill systems, and student ID integration are original
 *    - Personalized skill cooldown algorithm using student ID 25126997
 *    - Custom animation systems for piece movement and visual effects
 *    - Original UI design and character selection system
 * ============================================================================
 */

// External Library Import: Processing Sound Library
// Documentation: https://processing.org/reference/libraries/sound/
import processing.sound.*;

// External Library Import: Java Utilities
// Documentation: https://docs.oracle.com/javase/8/docs/api/java/util/package-summary.html
import java.util.*;

// Global variables
SoundFile bgMusic, startSound, winSound, loseSound;
SoundFile[] skillSounds;
SoundFile[] moveSounds;
PImage loginBG;
PImage[] characters = new PImage[5];
PImage selectedCharacter;
PImage opponentCharacter;
PImage broomImg;
PFont gameFont;

// Student ID integration for personalized game mechanics
// ORIGINAL IMPLEMENTATION: Custom algorithm using student ID as deterministic seed
String studentID = "25126997";
int[] studentDigits = {2, 5, 1, 2, 6, 9, 9, 7}; // Digits of student ID
int digitIndex = 0;

// Game states - ORIGINAL: Custom state machine implementation
final int LOGIN = 0;
final int LOADING = 1;
final int CHARACTER_SELECT = 2;
final int GAME = 3;
int gameState = LOGIN;

// Login screen related
boolean showSkillPopup = false;
float popupX, popupY;
boolean showCharacterSelect = false;

// Loading screen related
float loadingProgress = 0;
long loadingStartTime;
boolean loadingComplete = false;

// Character selection related - ORIGINAL: Custom character system
String[] characterNames = {"zhangcheng.png", "zhangxingchao.png", "lijiacheng.png", "wangguang.png", "baojie.png"};
int selectedCharIndex = -1;

// Board related - ORIGINAL: Custom board implementation
final int BOARD_SIZE = 400;
final int BOARD_X = 40;
final int BOARD_Y = 40;
final int GRID_SIZE = 15;
final int CELL_SIZE = BOARD_SIZE / (GRID_SIZE + 1);
int[][] board = new int[GRID_SIZE][GRID_SIZE];
boolean isBlackTurn = true;
boolean playerIsBlack = true;
boolean playerControlsBlack = true; // The color the player actually controls
int currentPlayer = 1;
boolean gameOver = false;
int winner = 0;

// Skill cooldown counter - ORIGINAL: Personalized cooldown system
int movesSinceLastSkill = 0; // Number of moves since last skill use
final int SKILL_COOLDOWN_MOVES = 4; // Need 4 moves (two turns) to use a skill

// Flying pieces - ORIGINAL: Custom animation system
ArrayList<FlyingPiece> flyingPieces = new ArrayList<FlyingPiece>();
ArrayList<PieceAnimation> pieceAnimations = new ArrayList<PieceAnimation>();

// Skill data - ORIGINAL: Custom skill system with 7 unique abilities
String[] skillNames = {
  "Rockfall", "Finders Keepers", "Still Water", "Role Reversal", 
  "Herculean Might", "Cleanup Service", "Fresh Start"
};
int[] skillMaxUses = {2, 1, 1, 1, 2, 1, 1};
int[] skillUses = new int[7];
boolean[] skillAvailable = new boolean[7];
boolean[] skillGrayed = new boolean[7];
float[] skillButtonsX = new float[7];
float[] skillButtonsY = new float[7];
float[] skillButtonsW = new float[7];
float[] skillButtonsH = new float[7];
float[] skillOriginalW = new float[7];
float[] skillOriginalH = new float[7];
int[] skillOriginalColor = new int[7];

// Character animation - ORIGINAL: Custom animation system
float playerScale = 1.0;
float opponentScale = 1.0;
float playerAngle = 0;
float opponentAngle = 0;
boolean playerShaking = false;
boolean opponentShaking = false;
float shakeDirection = 1;
long lastShakeTime = 0;
final float SHAKE_ANGLE = 0.05;
final int SHAKE_INTERVAL = 100;

// Computer thinking
long computerThinkStart = 0;
int computerThinkDuration = 0;
boolean computerIsThinking = false;

// Computer AI variables
int[] lastMove = {-1, -1};

// Skill activation states
boolean rockfallActive = false;
boolean rockfallByPlayer = false;

// Track removed pieces - ORIGINAL: Custom data structure
class RemovedPiece {
  int x, y;
  int type;
  int removedBy; // 1 = player, 2 = computer
  
  RemovedPiece(int x, int y, int type, int removedBy) {
    this.x = x;
    this.y = y;
    this.type = type;
    this.removedBy = removedBy;
  }
}
ArrayList<RemovedPiece> removedPieces = new ArrayList<RemovedPiece>();

boolean stillWaterActivePlayer = false;
boolean stillWaterActiveComputer = false;
int stillWaterMovesLeftPlayer = 0;
int stillWaterMovesLeftComputer = 0;

boolean roleReversalUsedPlayer = false;
boolean roleReversalUsedComputer = false;

boolean herculeanMightActive = false;
float boardAngle = 0;
int boardShakesLeft = 0;
boolean boardShaking = false;

boolean cleanupActive = false;
float broomY = 0;
float broomX = 0;
int[] columnsToClean = new int[3];
boolean cleaning = false;

boolean freshStartUsedPlayer = false;
boolean freshStartUsedComputer = false;

// Message display
String message = "";
long messageStartTime = 0;
final long MESSAGE_DURATION = 3000;

// Game over time
long gameOverTime = 0;

// Click areas for login screen
float skillAreaWidth, skillAreaHeight, charAreaWidth, charAreaHeight;
float skillAreaX, skillAreaY, charAreaX, charAreaY;

// Computer skill usage
int[] computerSkillUses = new int[7];
boolean[] computerSkillAvailable = new boolean[7];
boolean[] computerSkillGrayed = new boolean[7];

// Skill cooldown and state management
long lastSkillTime = 0;
final long SKILL_COOLDOWN = 500;
boolean skillInProgress = false;

// Broom animation
float broomScale = 1.0;
float broomSpeed = 8;
float broomTargetY = 0;

// Track piece animations for restoration - ORIGINAL: Custom animation class
class RestoreAnimation {
  float startX, startY;
  float targetX, targetY;
  float currentX, currentY;
  float speed;
  int type;
  boolean active;
  
  RestoreAnimation(float sx, float sy, float tx, float ty, int type) {
    startX = sx;
    startY = sy;
    targetX = tx;
    targetY = ty;
    currentX = sx;
    currentY = sy;
    this.type = type;
    speed = 5.0;
    active = true;
  }
  
  boolean update() {
    float dx = targetX - currentX;
    float dy = targetY - currentY;
    float dist = sqrt(dx*dx + dy*dy);
    
    if (dist < speed) {
      currentX = targetX;
      currentY = targetY;
      return true;
    } else {
      currentX += (dx / dist) * speed;
      currentY += (dy / dist) * speed;
      return false;
    }
  }
  
  void display() {
    pushMatrix();
    translate(currentX, currentY);
    if (type == 1) {
      fill(0);
      stroke(255);
    } else {
      fill(255);
      stroke(0);
    }
    strokeWeight(2);
    ellipse(0, 0, CELL_SIZE * 0.8, CELL_SIZE * 0.8);
    popMatrix();
  }
}
ArrayList<RestoreAnimation> restoreAnimations = new ArrayList<RestoreAnimation>();

// ORIGINAL: Custom flying piece animation class
class FlyingPiece {
  float x, y;
  float vx, vy;
  int type;
  float life;
  float startTime;
  
  FlyingPiece(float startX, float startY, int t) {
    x = startX;
    y = startY;
    type = t;
    life = 2.5;
    startTime = millis();
    float angle = random(TWO_PI);
    float speed = random(3, 6);
    vx = cos(angle) * speed;
    vy = sin(angle) * speed;
  }
  
  void update() {
    x += vx;
    y += vy;
    life = 2.5 - (millis() - startTime) / 1000.0;
    
    if (x < -50 || x > width + 50 || y < -50 || y > height + 50) {
      life = 0;
    }
  }
  
  void display() {
    pushMatrix();
    translate(x, y);
    
    float alpha = map(life, 0, 2.5, 0, 255);
    
    if (type == 1) {
      fill(0, alpha);
      stroke(255, alpha);
    } else {
      fill(255, alpha);
      stroke(0, alpha);
    }
    strokeWeight(2);
    ellipse(0, 0, CELL_SIZE * 0.8, CELL_SIZE * 0.8);
    popMatrix();
  }
  
  boolean isAlive() {
    return life > 0;
  }
}

// ORIGINAL: Custom piece animation class
class PieceAnimation {
  float x, y;
  float scale;
  int type;
  boolean growing;
  
  PieceAnimation(float x, float y, int t) {
    this.x = x;
    this.y = y;
    this.type = t;
    this.scale = 0;
    this.growing = true;
  }
  
  void update() {
    if (growing) {
      scale += 0.1;
      if (scale >= 1.0) {
        scale = 1.0;
        growing = false;
      }
    }
  }
  
  void display() {
    pushMatrix();
    translate(x, y);
    scale(scale);
    if (type == 1) {
      fill(0);
      stroke(255);
    } else {
      fill(255);
      stroke(0);
    }
    strokeWeight(2);
    ellipse(0, 0, CELL_SIZE * 0.8, CELL_SIZE * 0.8);
    popMatrix();
  }
  
  boolean isComplete() {
    return !growing;
  }
}

// Setup function using Processing framework
void setup() {
  // Processing graphics window initialization
  size(640, 853);
  
  calculateClickAreas();
  
  loadResources();
  
  initSkills();
  
  initBoard();
  
  // Processing font creation
  gameFont = createFont("Arial", 12);
  textFont(gameFont);
}

void calculateClickAreas() {
  skillAreaHeight = height / 7;
  skillAreaWidth = width * 3 / 5;
  skillAreaY = height - skillAreaHeight;
  skillAreaX = 0;
  
  charAreaHeight = height / 7;
  charAreaWidth = width * 2 / 5;
  charAreaY = height - charAreaHeight;
  charAreaX = width - charAreaWidth;
}

// Resource loading using Processing image and sound libraries
void loadResources() {
  println("Loading resources...");
  
  // Processing image loading
  loginBG = loadImage("fengmian.jpg");
  
  for (int i = 0; i < 5; i++) {
    characters[i] = loadImage(characterNames[i]);
  }
  
  broomImg = loadImage("saoba.png");
  
  // Processing Sound Library usage for audio files
  try {
    bgMusic = new SoundFile(this, "jnwzq.wav");
  } catch (Exception e) {}
  
  try {
    startSound = new SoundFile(this, "kaichang.wav");
  } catch (Exception e) {}
  
  try {
    winSound = new SoundFile(this, "win.wav");
  } catch (Exception e) {}
  
  try {
    loseSound = new SoundFile(this, "lose.wav");
  } catch (Exception e) {}
  
  skillSounds = new SoundFile[7];
  String[] skillSoundFiles = {
    "feishazoushi.wav", "shijinbumei.wav", "jingruzhishui.wav",
    "liangjifanzhuan.wav", "libashanxi.wav", "baojieshangmen.wav",
    "dongshanzaiqi.wav"
  };
  
  for (int i = 0; i < 7; i++) {
    try {
      skillSounds[i] = new SoundFile(this, skillSoundFiles[i]);
    } catch (Exception e) {}
  }
  
  moveSounds = new SoundFile[2];
  try {
    moveSounds[0] = new SoundFile(this, "zhanghei.wav");
  } catch (Exception e) {}
  
  try {
    moveSounds[1] = new SoundFile(this, "lihei.wav");
  } catch (Exception e) {}
  
  if (bgMusic != null) {
    // Sound Library looping functionality
    bgMusic.loop();
  }
}

// ORIGINAL: Skill system initialization
void initSkills() {
  float skillX = BOARD_X + BOARD_SIZE + 20;
  float skillY = 100;
  float skillW = 150;
  float skillH = 30;
  float skillSpacing = 10;
  
  for (int i = 0; i < 7; i++) {
    skillButtonsX[i] = skillX;
    skillButtonsY[i] = skillY + i * (skillH + skillSpacing);
    skillButtonsW[i] = skillW;
    skillButtonsH[i] = skillH;
    skillOriginalW[i] = skillW;
    skillOriginalH[i] = skillH;
    skillUses[i] = 0;
    skillAvailable[i] = true;
    skillGrayed[i] = false;
    skillOriginalColor[i] = color(135, 206, 235);
    
    computerSkillUses[i] = 0;
    computerSkillAvailable[i] = true;
    computerSkillGrayed[i] = false;
  }
}

// ORIGINAL: Board initialization with personalized elements
void initBoard() {
  for (int i = 0; i < GRID_SIZE; i++) {
    for (int j = 0; j < GRID_SIZE; j++) {
      board[i][j] = 0;
    }
  }
  
  // Random assignment of player control color
  playerControlsBlack = random(1) > 0.5;
  playerIsBlack = playerControlsBlack; // Initial color player controls
  
  // Black always moves first
  isBlackTurn = true; 
  currentPlayer = playerControlsBlack ? 1 : 2; // If player controls black, player moves first; otherwise computer moves first
  
  // Reset skill cooldown
  movesSinceLastSkill = 0;
  
  for (int i = 0; i < 7; i++) {
    skillUses[i] = 0;
    skillAvailable[i] = true;
    skillGrayed[i] = false;
    
    computerSkillUses[i] = 0;
    computerSkillAvailable[i] = true;
    computerSkillGrayed[i] = false;
  }
  
  gameOver = false;
  winner = 0;
  
  rockfallActive = false;
  rockfallByPlayer = false;
  stillWaterActivePlayer = false;
  stillWaterActiveComputer = false;
  stillWaterMovesLeftPlayer = 0;
  stillWaterMovesLeftComputer = 0;
  roleReversalUsedPlayer = false;
  roleReversalUsedComputer = false;
  herculeanMightActive = false;
  boardShaking = false;
  boardShakesLeft = 0;
  cleanupActive = false;
  cleaning = false;
  freshStartUsedPlayer = false;
  freshStartUsedComputer = false;
  
  flyingPieces.clear();
  pieceAnimations.clear();
  removedPieces.clear();
  restoreAnimations.clear();
  
  lastMove[0] = -1;
  lastMove[1] = -1;
  
  playerShaking = (currentPlayer == 1);
  opponentShaking = (currentPlayer == 2);
  skillInProgress = false;
  
  // Display message about student ID integration
  message = "Student ID " + studentID + " affects skill cooldown!";
  messageStartTime = millis();
}

// Main draw loop using Processing event system
void draw() {
  switch (gameState) {
    case LOGIN:
      drawLoginScreen();
      break;
    case LOADING:
      drawLoadingScreen();
      break;
    case CHARACTER_SELECT:
      drawCharacterSelect();
      break;
    case GAME:
      drawGame();
      break;
  }
}

// ORIGINAL: Login screen rendering
void drawLoginScreen() {
  if (loginBG != null) {
    image(loginBG, 0, 0, width, height);
  } else {
    background(255, 253, 208);
    fill(0);
    textSize(12);
    textAlign(CENTER);
    text("Gomoku Game - Login Screen", width/2, height/2 - 25);
    textSize(8);
    text("Click bottom-left 3/5 area for skills", width/2, height/2);
    text("Click bottom-right 2/5 area for character", width/2, height/2 + 15);
  }
  
  if (showSkillPopup) {
    drawSkillPopup();
  }
  
  if (showCharacterSelect) {
    drawCharacterSelectPopup();
  }
}

// ORIGINAL: Skill popup rendering
void drawSkillPopup() {
  fill(0, 150);
  noStroke();
  rect(0, 0, width, height);
  
  fill(255, 165, 0);
  stroke(255, 200, 0);
  strokeWeight(2);
  float popupWidth = 200;
  float popupHeight = 250;
  float actualX = constrain(popupX, 0, width - popupWidth);
  float actualY = constrain(popupY - popupHeight, 0, height - popupHeight);
  rect(actualX, actualY, popupWidth, popupHeight, 10);
  
  fill(0);
  textSize(8);
  textAlign(LEFT, TOP);
  String[] skillDescriptions = {
    "Rockfall: Discard opponent piece (2 uses)",
    "Finders Keepers: Retrieve discarded piece (1 use)",
    "Still Water: Freeze opponent, take 2 moves (1 use)",
    "Role Reversal: Swap colors and turn order (1 use)",
    "Herculean Might: Shake board, swap pieces (2 uses)",
    "Cleanup Service: Clear 3 random columns (1 use)",
    "Fresh Start: Clear board, restart game (1 use)"
  };
  
  float textY = actualY + 10;
  for (int i = 0; i < skillDescriptions.length; i++) {
    text(skillDescriptions[i], actualX + 10, textY, 180, 50);
    textY += 35;
  }
}

// ORIGINAL: Character selection popup
void drawCharacterSelectPopup() {
  fill(0, 150);
  noStroke();
  rect(0, 0, width, height);
  
  fill(255, 253, 208);
  stroke(200, 180, 120);
  strokeWeight(3);
  float popupWidth = 250;
  float popupHeight = 300;
  float popupXPos = (width - popupWidth) / 2;
  float popupYPos = (height - popupHeight) / 2;
  
  rect(popupXPos, popupYPos, popupWidth, popupHeight, 15);
  
  fill(0);
  textSize(18);
  textAlign(CENTER);
  text("Select Your Character", popupXPos + popupWidth/2, popupYPos + 25);
  
  float startX = popupXPos + 25;
  float startY = popupYPos + 60;
  
  for (int i = 0; i < characters.length; i++) {
    float x = startX + (i % 3) * 80;
    float y = startY + (i / 3) * 90;
    
    if (characters[i] != null) {
      image(characters[i], x, y, 70, 70);
      
      if (mouseX >= x && mouseX <= x + 70 &&
          mouseY >= y && mouseY <= y + 70) {
        stroke(255, 0, 0);
        noFill();
        strokeWeight(2);
        rect(x - 5, y - 5, 80, 80);
      }
    }
  }
}

// ORIGINAL: Loading screen with custom animations
void drawLoadingScreen() {
  background(255, 253, 208);
  
  drawBubbles();
  
  textSize(36);
  textAlign(CENTER);
  fill(255, 105, 180);
  text("LOADING...", width/2, height/2 - 80);
  
  stroke(255, 182, 193);
  strokeWeight(4);
  noFill();
  rect(width/2 - 120, height/2 - 20, 240, 40, 20);
  
  loadingProgress = min((millis() - loadingStartTime) / 3000.0, 1.0);
  fill(255, 215, 0);
  noStroke();
  float barWidth = 240 * loadingProgress;
  rect(width/2 - 120, height/2 - 20, barWidth, 40, 20);
  
  float bounce = sin(millis() * 0.01) * 3;
  fill(255, 105, 180);
  textSize(24);
  text(int(loadingProgress * 100) + "%", width/2, height/2 + 70 + bounce);
  
  if (loadingProgress >= 1.0 && !loadingComplete) {
    loadingComplete = true;
    gameState = GAME;
  }
}

// ORIGINAL: Bubble animation for loading screen
void drawBubbles() {
  noStroke();
  for (int i = 0; i < 15; i++) {
    float x = (millis() * 0.03 + i * 100) % width;
    float y = height/2 - 150 + sin(millis() * 0.001 + i) * 50;
    float size = 20 + sin(millis() * 0.002 + i) * 10;
    
    fill(255, 215, 0, 150);
    ellipse(x, y, size, size);
    
    fill(255, 255, 255, 100);
    ellipse(x - size/4, y - size/4, size/3, size/3);
  }
}

void drawCharacterSelect() {
  background(255, 253, 208);
  textSize(18);
  fill(0);
  textAlign(CENTER);
  text("Character Selection", width/2, 50);
}

// Main game rendering function
void drawGame() {
  background(255, 253, 208);
  
  drawBoard();
  drawPieces();
  
  for (int i = flyingPieces.size() - 1; i >= 0; i--) {
    FlyingPiece fp = flyingPieces.get(i);
    fp.update();
    fp.display();
    if (!fp.isAlive()) {
      flyingPieces.remove(i);
    }
  }
  
  for (int i = pieceAnimations.size() - 1; i >= 0; i--) {
    PieceAnimation pa = pieceAnimations.get(i);
    pa.update();
    pa.display();
    if (pa.isComplete()) {
      pieceAnimations.remove(i);
    }
  }
  
  for (int i = restoreAnimations.size() - 1; i >= 0; i--) {
    RestoreAnimation ra = restoreAnimations.get(i);
    ra.display();
    if (ra.update()) {
      int gridX = (int)((ra.targetX - BOARD_X) / CELL_SIZE);
      int gridY = (int)((ra.targetY - BOARD_Y) / CELL_SIZE);
      if (gridX >= 0 && gridX < GRID_SIZE && gridY >= 0 && gridY < GRID_SIZE) {
        board[gridX][gridY] = ra.type;
      }
      restoreAnimations.remove(i);
    }
  }
  
  drawSkillButtons();
  drawCharacters();
  drawMessage();
  
  if (cleaning) {
    drawBroomAnimation();
  }
  
  updateCharacterAnimation();
  updateBoardAnimation();
  
  if (!gameOver && currentPlayer == 2 && !computerIsThinking && 
      !skillInProgress && !rockfallActive && !cleaning && !boardShaking) {
    computerThinkStart = millis();
    computerThinkDuration = (int)random(800, 1500);
    computerIsThinking = true;
    opponentShaking = true;
    playerShaking = false;
  }
  
  if (computerIsThinking && millis() - computerThinkStart > computerThinkDuration) {
    computerMove();
    computerIsThinking = false;
    opponentShaking = false;
    playerShaking = true;
  }
  
  if (gameOver) {
    drawGameOver();
  }
}

// ORIGINAL: Board rendering with custom graphics
void drawBoard() {
  pushMatrix();
  if (boardShaking) {
    translate(width/2, height/2);
    rotate(boardAngle);
    translate(-width/2, -height/2);
  }
  
  fill(222, 184, 135);
  stroke(139, 69, 19);
  strokeWeight(6);
  rect(BOARD_X - 15, BOARD_Y - 15, BOARD_SIZE + 30, BOARD_SIZE + 30, 15);
  
  stroke(0);
  strokeWeight(1.5);
  
  for (int i = 0; i <= GRID_SIZE; i++) {
    float y = BOARD_Y + i * CELL_SIZE;
    line(BOARD_X, y, BOARD_X + BOARD_SIZE, y);
  }
  
  for (int i = 0; i <= GRID_SIZE; i++) {
    float x = BOARD_X + i * CELL_SIZE;
    line(x, BOARD_Y, x, BOARD_Y + BOARD_SIZE);
  }
  
  fill(0);
  noStroke();
  int[] stars = {3, 7, 11};
  for (int i = 0; i < stars.length; i++) {
    for (int j = 0; j < stars.length; j++) {
      ellipse(BOARD_X + stars[i] * CELL_SIZE, BOARD_Y + stars[j] * CELL_SIZE, 8, 8);
    }
  }
  
  popMatrix();
}

// ORIGINAL: Piece rendering
void drawPieces() {
  for (int i = 0; i < GRID_SIZE; i++) {
    for (int j = 0; j < GRID_SIZE; j++) {
      if (board[i][j] != 0) {
        float x = BOARD_X + i * CELL_SIZE;
        float y = BOARD_Y + j * CELL_SIZE;
        
        pushMatrix();
        translate(x, y);
        
        if (board[i][j] == 1) {
          fill(0);
          stroke(255);
        } else {
          fill(255);
          stroke(0);
        }
        strokeWeight(2);
        ellipse(0, 0, CELL_SIZE * 0.9, CELL_SIZE * 0.9);
        
        popMatrix();
      }
    }
  }
}

// MODIFIED: Student ID integration for skill cooldown - ORIGINAL algorithm
void drawSkillButtons() {
  // Calculate skill cooldown with student ID influence
  int requiredMoves = SKILL_COOLDOWN_MOVES;
  boolean isLuckyMove = false;
  
  // Check if current move count matches any student ID digit
  int currentDigit = studentDigits[digitIndex % studentDigits.length];
  
  // When last digit of move count matches student ID digit, reduce cooldown by 1 move
  // ORIGINAL: Personalized cooldown reduction algorithm
  if (movesSinceLastSkill % 10 == currentDigit && movesSinceLastSkill > 0) {
    requiredMoves = max(2, SKILL_COOLDOWN_MOVES - 1); // Minimum 2 moves required
    isLuckyMove = true;
    digitIndex++; // Move to next digit for next lucky move
  }
  
  // Check if skill can be used
  boolean canUseSkill = (movesSinceLastSkill >= requiredMoves);
  
  // Display skill cooldown status with student ID influence
  textSize(10);
  fill(0);
  textAlign(CENTER);
  
  String cooldownText = "Skill Cooldown: " + movesSinceLastSkill + "/" + requiredMoves + " moves";
  if (isLuckyMove) {
    cooldownText += " (Lucky ID: " + currentDigit + ")";
  }
  
  text(cooldownText, skillButtonsX[0] + skillButtonsW[0]/2, skillButtonsY[0] - 10);
  
  // Display student ID in small text
  textSize(8);
  fill(100);
  text("Student ID: " + studentID, skillButtonsX[0] + skillButtonsW[0]/2, skillButtonsY[0] - 20);
  
  for (int i = 0; i < 7; i++) {
    if (skillGrayed[i] || !skillAvailable[i] || !canUseSkill) {
      fill(150);
      skillButtonsW[i] = skillOriginalW[i] * 0.9;
      skillButtonsH[i] = skillOriginalH[i] * 0.9;
    } else {
      fill(skillOriginalColor[i]);
      skillButtonsW[i] = skillOriginalW[i];
      skillButtonsH[i] = skillOriginalH[i];
    }
    
    stroke(0, 191, 255);
    strokeWeight(2);
    rect(skillButtonsX[i], skillButtonsY[i], skillButtonsW[i], skillButtonsH[i], 8);
    
    if (skillGrayed[i] || !skillAvailable[i] || !canUseSkill) {
      fill(100);
    } else {
      fill(255);
    }
    textSize(10);
    textAlign(CENTER, CENTER);
    text(skillNames[i], skillButtonsX[i] + skillButtonsW[i]/2, 
         skillButtonsY[i] + skillButtonsH[i]/2);
    
    textSize(8);
    fill(0);
    text(skillUses[i] + "/" + skillMaxUses[i], 
         skillButtonsX[i] + skillButtonsW[i] - 15, 
         skillButtonsY[i] + skillButtonsH[i] - 10);
    
    if (isMouseOverSkill(i) && skillAvailable[i] && currentPlayer == 1 && 
        !skillInProgress && !gameOver && canUseSkill) {
      stroke(255, 255, 0);
      strokeWeight(2);
      noFill();
      rect(skillButtonsX[i] - 4, skillButtonsY[i] - 4, 
           skillButtonsW[i] + 8, skillButtonsH[i] + 8, 10);
    }
    
    // Show cooldown state
    if (!canUseSkill && skillAvailable[i]) {
      fill(0, 0, 0, 100);
      rect(skillButtonsX[i], skillButtonsY[i], skillButtonsW[i], skillButtonsH[i], 8);
      
      fill(255);
      textSize(8);
      textAlign(CENTER, CENTER);
      text("Cooling down!", skillButtonsX[i] + skillButtonsW[i]/2, 
           skillButtonsY[i] + skillButtonsH[i]/2);
    }
  }
}

boolean isMouseOverSkill(int index) {
  return mouseX >= skillButtonsX[index] && 
         mouseX <= skillButtonsX[index] + skillButtonsW[index] &&
         mouseY >= skillButtonsY[index] && 
         mouseY <= skillButtonsY[index] + skillButtonsH[index];
}

// ORIGINAL: Character rendering with animations
void drawCharacters() {
  if (selectedCharacter != null) {
    pushMatrix();
    float playerX = width - 160;
    float playerY = height - 160;
    
    translate(playerX + 75, playerY + 75);
    if (playerShaking) {
      rotate(playerAngle);
      scale(playerScale);
    }
    
    image(selectedCharacter, -75, -75, 150, 150);
    
    popMatrix();
  }
  
  if (opponentCharacter != null) {
    pushMatrix();
    float opponentX = 30;
    float opponentY = height - 160;
    
    translate(opponentX + 75, opponentY + 75);
    if (opponentShaking) {
      rotate(opponentAngle);
      scale(opponentScale);
    }
    
    image(opponentCharacter, -75, -75, 150, 150);
    
    popMatrix();
  }
}

// ORIGINAL: Character animation update
void updateCharacterAnimation() {
  if (millis() - lastShakeTime > SHAKE_INTERVAL) {
    if (playerShaking) {
      playerAngle += SHAKE_ANGLE * shakeDirection;
      if (abs(playerAngle) > SHAKE_ANGLE * 3) {
        shakeDirection *= -1;
      }
    }
    
    if (opponentShaking) {
      opponentAngle += SHAKE_ANGLE * shakeDirection;
      if (abs(opponentAngle) > SHAKE_ANGLE * 3) {
        shakeDirection *= -1;
      }
    }
    
    lastShakeTime = millis();
  }
  
  if (playerShaking) {
    playerScale = lerp(playerScale, 1.2, 0.1);
  } else {
    playerScale = lerp(playerScale, 1.0, 0.1);
  }
  
  if (opponentShaking) {
    opponentScale = lerp(opponentScale, 1.2, 0.1);
  } else {
    opponentScale = lerp(opponentScale, 1.0, 0.1);
  }
}

// ORIGINAL: Board animation update
void updateBoardAnimation() {
  if (boardShaking && boardShakesLeft > 0) {
    boardAngle = sin(frameCount * 0.3) * 0.03;
    boardShakesLeft--;
    
    if (boardShakesLeft <= 0) {
      boardShaking = false;
      boardAngle = 0;
      // Herculean Might: Swap nearby pieces without causing immediate win
      exchangeNearbyPieces();
      skillInProgress = false;
    }
  }
}

// Herculean Might: Swap nearby pieces - ORIGINAL algorithm
void exchangeNearbyPieces() {
  int exchanges = 3; // Only swap 3 pairs of pieces
  
  // Collect all piece positions
  ArrayList<int[]> piecePositions = new ArrayList<int[]>();
  for (int i = 0; i < GRID_SIZE; i++) {
    for (int j = 0; j < GRID_SIZE; j++) {
      if (board[i][j] != 0) {
        piecePositions.add(new int[]{i, j});
      }
    }
  }
  
  if (piecePositions.size() < 2) return;
  
  // Save original board state
  int[][] originalBoard = new int[GRID_SIZE][GRID_SIZE];
  for (int i = 0; i < GRID_SIZE; i++) {
    for (int j = 0; j < GRID_SIZE; j++) {
      originalBoard[i][j] = board[i][j];
    }
  }
  
  // Try swapping, ensure it doesn't cause immediate win
  boolean successful = false;
  int attempts = 0;
  while (!successful && attempts < 10) {
    attempts++;
    
    // Restore original board
    for (int i = 0; i < GRID_SIZE; i++) {
      for (int j = 0; j < GRID_SIZE; j++) {
        board[i][j] = originalBoard[i][j];
      }
    }
    
    // Perform limited swaps (only nearby pieces)
    for (int e = 0; e < exchanges && piecePositions.size() >= 2; e++) {
      // Randomly select a piece
      int idx1 = (int)random(piecePositions.size());
      int[] pos1 = piecePositions.get(idx1);
      
      // Find nearby pieces (distance no more than 3 cells)
      ArrayList<int[]> nearbyPieces = new ArrayList<int[]>();
      for (int[] pos : piecePositions) {
        if (pos != pos1) {
          int dist = abs(pos[0] - pos1[0]) + abs(pos[1] - pos1[1]);
          if (dist <= 3) { // Only swap pieces within 3 cells
            nearbyPieces.add(pos);
          }
        }
      }
      
      if (nearbyPieces.size() > 0) {
        // Randomly select a nearby piece to swap
        int[] pos2 = nearbyPieces.get((int)random(nearbyPieces.size()));
        
        // Swap pieces
        int temp = board[pos1[0]][pos1[1]];
        board[pos1[0]][pos1[1]] = board[pos2[0]][pos2[1]];
        board[pos2[0]][pos2[1]] = temp;
      }
    }
    
    // Check if swap causes immediate win
    boolean causesWin = false;
    for (int i = 0; i < GRID_SIZE; i++) {
      for (int j = 0; j < GRID_SIZE; j++) {
        if (board[i][j] != 0 && checkFiveInRow(i, j)) {
          causesWin = true;
          break;
        }
      }
      if (causesWin) break;
    }
    
    if (!causesWin) {
      successful = true;
    }
  }
  
  // If 10 attempts fail, restore original board
  if (!successful) {
    for (int i = 0; i < GRID_SIZE; i++) {
      for (int j = 0; j < GRID_SIZE; j++) {
        board[i][j] = originalBoard[i][j];
      }
    }
  }
}

void drawMessage() {
  if (message.length() > 0 && millis() - messageStartTime < MESSAGE_DURATION) {
    fill(0, 200, 255, 200);
    noStroke();
    rect(width/2 - 100, height/2 - 20, 200, 40, 10);
    
    fill(255);
    textSize(14);
    textAlign(CENTER, CENTER);
    text(message, width/2, height/2);
  }
}

// ORIGINAL: Broom animation for Cleanup Service skill
void drawBroomAnimation() {
  pushMatrix();
  
  translate(broomX, broomY);
  scale(broomScale);
  
  if (broomImg != null) {
    image(broomImg, -100, -133, 200, 266);
  } else {
    fill(139, 69, 19);
    rect(-20, 0, 40, 80);
    fill(200, 150, 100);
    triangle(-30, 80, 30, 80, 0, 160);
  }
  
  popMatrix();
  
  if (broomY < broomTargetY) {
    broomY += broomSpeed;
    if (broomY >= broomTargetY) {
      broomY = broomTargetY;
      cleanColumns();
      cleaning = false;
      cleanupActive = false;
      skillInProgress = false;
      
      if (currentPlayer == 2) {
        computerIsThinking = true;
        computerThinkStart = millis();
      }
    }
  }
}

// ORIGINAL: Column cleaning logic
void cleanColumns() {
  int[][] originalBoard = new int[GRID_SIZE][GRID_SIZE];
  for (int i = 0; i < GRID_SIZE; i++) {
    for (int j = 0; j < GRID_SIZE; j++) {
      originalBoard[i][j] = board[i][j];
    }
  }
  
  for (int colIdx = 0; colIdx < columnsToClean.length; colIdx++) {
    int col = columnsToClean[colIdx];
    for (int row = 0; row < GRID_SIZE; row++) {
      if (board[col][row] != 0) {
        removedPieces.add(new RemovedPiece(col, row, board[col][row], currentPlayer));
        board[col][row] = 0;
      }
    }
  }
  
  boolean causesWin = false;
  for (int i = 0; i < GRID_SIZE; i++) {
    for (int j = 0; j < GRID_SIZE; j++) {
      if (board[i][j] != 0 && checkFiveInRow(i, j)) {
        causesWin = true;
        break;
      }
    }
    if (causesWin) break;
  }
  
  if (causesWin) {
    for (int i = 0; i < GRID_SIZE; i++) {
      for (int j = 0; j < GRID_SIZE; j++) {
        board[i][j] = originalBoard[i][j];
      }
    }
    for (int i = removedPieces.size() - 1; i >= 0; i--) {
      RemovedPiece rp = removedPieces.get(i);
      for (int colIdx = 0; colIdx < columnsToClean.length; colIdx++) {
        if (rp.x == columnsToClean[colIdx]) {
          removedPieces.remove(i);
          break;
        }
      }
    }
    message = "Cannot clean columns that cause immediate win!";
    messageStartTime = millis();
  }
}

// Fixed: Game over screen, returns to login after 5 seconds
void drawGameOver() {
  fill(0, 0, 0, 150);
  noStroke();
  rect(0, 0, width, height);
  
  textSize(32);
  textAlign(CENTER, CENTER);
  
  if (winner == 1) {
    fill(0, 255, 0);
    text("YOU WIN!", width/2, height/2 - 50);
  } else if (winner == 2) {
    fill(255, 0, 0);
    text("YOU LOSE!", width/2, height/2 - 50);
  } else {
    fill(255, 255, 0);
    text("DRAW!", width/2, height/2 - 50);
  }
  
  textSize(16);
  fill(255);
  text("Click to return to login", width/2, height/2 + 25);
  
  // Automatically return to login after 5 seconds
  if (millis() - gameOverTime > 5000) {
    resetToLogin();
  }
}

void resetToLogin() {
  gameState = LOGIN;
  loadingComplete = false;
  if (bgMusic != null && !bgMusic.isPlaying()) {
    bgMusic.loop();
  }
  initBoard();
  flyingPieces.clear();
  pieceAnimations.clear();
  restoreAnimations.clear();
  showSkillPopup = false;
  showCharacterSelect = false;
}

// Processing mouse event handling
void mousePressed() {
  switch (gameState) {
    case LOGIN:
      handleLoginMouse();
      break;
    case LOADING:
      break;
    case CHARACTER_SELECT:
      break;
    case GAME:
      if (gameOver) {
        resetToLogin();
        return;
      }
      handleGameMouse();
      break;
  }
}

void handleLoginMouse() {
  if (mouseX >= skillAreaX && mouseX <= skillAreaX + skillAreaWidth &&
      mouseY >= skillAreaY && mouseY <= skillAreaY + skillAreaHeight) {
    showSkillPopup = true;
    popupX = mouseX;
    popupY = mouseY;
    showCharacterSelect = false;
  } else if (mouseX >= charAreaX && mouseX <= charAreaX + charAreaWidth &&
           mouseY >= charAreaY && mouseY <= charAreaY + charAreaHeight) {
    showCharacterSelect = true;
    showSkillPopup = false;
  } else if (showCharacterSelect) {
    handleCharacterPopupClick();
  } else {
    showSkillPopup = false;
    showCharacterSelect = false;
  }
}

void handleCharacterPopupClick() {
  float popupWidth = 250;
  float popupHeight = 300;
  float popupXPos = (width - popupWidth) / 2;
  float popupYPos = (height - popupHeight) / 2;
  
  float startX = popupXPos + 25;
  float startY = popupYPos + 60;
  
  for (int i = 0; i < characters.length; i++) {
    float x = startX + (i % 3) * 80;
    float y = startY + (i / 3) * 90;
    
    if (mouseX >= x && mouseX <= x + 70 &&
        mouseY >= y && mouseY <= y + 70) {
      selectedCharIndex = i;
      selectedCharacter = characters[i];
      
      int opponentIndex;
      do {
        opponentIndex = (int)random(characters.length);
      } while (opponentIndex == selectedCharIndex);
      opponentCharacter = characters[opponentIndex];
      
      gameState = LOADING;
      loadingStartTime = millis();
      loadingProgress = 0;
      loadingComplete = false;
      
      if (bgMusic != null) {
        bgMusic.stop();
      }
      if (startSound != null) {
        startSound.play();
      }
      
      showCharacterSelect = false;
      return;
    }
  }
}

// MODIFIED: Check skill cooldown with student ID influence - ORIGINAL algorithm
void handleGameMouse() {
  if (gameOver) return;
  
  // Calculate required moves with student ID influence
  int requiredMoves = SKILL_COOLDOWN_MOVES;
  int currentDigit = studentDigits[digitIndex % studentDigits.length];
  
  // Check for lucky move based on student ID digit
  // ORIGINAL: Personalized skill activation logic
  if (movesSinceLastSkill % 10 == currentDigit && movesSinceLastSkill > 0) {
    requiredMoves = max(2, SKILL_COOLDOWN_MOVES - 1);
  }
  
  // Check skill cooldown
  boolean canUseSkill = (movesSinceLastSkill >= requiredMoves);
  
  for (int i = 0; i < 7; i++) {
    if (isMouseOverSkill(i) && skillAvailable[i] && skillUses[i] < skillMaxUses[i] && 
        currentPlayer == 1 && canUseSkill) {
      if (millis() - lastSkillTime < SKILL_COOLDOWN) {
        message = "Skill on cooldown!";
        messageStartTime = millis();
        return;
      }
      
      activateSkill(i);
      lastSkillTime = millis();
      return;
    }
  }
  
  int gridX = (int)((mouseX - BOARD_X + CELL_SIZE/2) / CELL_SIZE);
  int gridY = (int)((mouseY - BOARD_Y + CELL_SIZE/2) / CELL_SIZE);
  
  if (gridX >= 0 && gridX < GRID_SIZE && gridY >= 0 && gridY < GRID_SIZE) {
    if (rockfallActive && rockfallByPlayer) {
      handlePlayerRockfall(gridX, gridY);
    } 
    else if (!rockfallActive && currentPlayer == 1 && board[gridX][gridY] == 0) {
      handleNormalMove(gridX, gridY);
    }
  }
}

// ORIGINAL: Rockfall skill handling
void handlePlayerRockfall(int gridX, int gridY) {
  int pieceType = board[gridX][gridY];
  
  if (pieceType == 0) {
    message = "Click on an opponent's piece to discard!";
    messageStartTime = millis();
    return;
  }
  
  // Determine if it's opponent's piece: player's current controlled color
  int playerControlledColor = playerControlsBlack ? 1 : 2;
  boolean isComputerPiece = (pieceType != playerControlledColor);
  
  if (isComputerPiece) {
    float startX = BOARD_X + gridX * CELL_SIZE;
    float startY = BOARD_Y + gridY * CELL_SIZE;
    flyingPieces.add(new FlyingPiece(startX, startY, pieceType));
    
    removedPieces.add(new RemovedPiece(gridX, gridY, pieceType, 1));
    
    board[gridX][gridY] = 0;
    
    rockfallActive = false;
    rockfallByPlayer = false;
    
    skillUses[0]++;
    if (skillUses[0] >= skillMaxUses[0]) {
      skillAvailable[0] = false;
      skillGrayed[0] = true;
    }
    
    // Reset cooldown count after using skill
    movesSinceLastSkill = 0;
    
    message = "Piece discarded! You can make another move.";
    messageStartTime = millis();
    
    checkWinCondition();
  } else {
    message = "You can only discard opponent's pieces!";
    messageStartTime = millis();
  }
}

// ORIGINAL: Normal move handling
void handleNormalMove(int gridX, int gridY) {
  if (skillInProgress) {
    skillInProgress = false;
  }
  
  // Place piece based on currently controlled color
  int playerType = playerControlsBlack ? 1 : 2;
  
  // Player always places their controlled color
  placePiece(gridX, gridY, playerType);
  
  lastMove[0] = gridX;
  lastMove[1] = gridY;
  
  // Increment move count
  movesSinceLastSkill++;
  
  if (stillWaterActivePlayer && stillWaterMovesLeftPlayer > 0) {
    stillWaterMovesLeftPlayer--;
    if (stillWaterMovesLeftPlayer == 0) {
      stillWaterActivePlayer = false;
      isBlackTurn = !isBlackTurn;
      currentPlayer = 2;
      playerShaking = false;
      opponentShaking = true;
    }
  } else {
    isBlackTurn = !isBlackTurn;
    currentPlayer = 2;
    playerShaking = false;
    opponentShaking = true;
  }
  
  checkWinCondition();
}

// MODIFIED: Check skill cooldown with student ID influence - ORIGINAL algorithm
void activateSkill(int skillIndex) {
  // Calculate required moves with student ID influence
  int requiredMoves = SKILL_COOLDOWN_MOVES;
  int currentDigit = studentDigits[digitIndex % studentDigits.length];
  
  // Check for lucky move based on student ID digit
  // ORIGINAL: Personalized skill activation logic
  if (movesSinceLastSkill % 10 == currentDigit && movesSinceLastSkill > 0) {
    requiredMoves = max(2, SKILL_COOLDOWN_MOVES - 1);
  }
  
  // Check skill cooldown
  if (movesSinceLastSkill < requiredMoves) {
    message = "Need " + (requiredMoves - movesSinceLastSkill) + " more moves to use skill!";
    messageStartTime = millis();
    return;
  }
  
  // Sound Library usage for skill sounds
  if (skillIndex < skillSounds.length && skillSounds[skillIndex] != null) {
    skillSounds[skillIndex].play();
  }
  
  skillInProgress = true;
  
  switch (skillIndex) {
    case 0: // Rockfall
      if (skillUses[skillIndex] < skillMaxUses[skillIndex]) {
        rockfallActive = true;
        rockfallByPlayer = true;
        message = "Click on an opponent's piece to discard";
        messageStartTime = millis();
      } else {
        skillInProgress = false;
      }
      break;
      
    case 1: // Finders Keepers
      if (skillUses[skillIndex] < skillMaxUses[skillIndex]) {
        RemovedPiece pieceToRestore = null;
        for (int i = removedPieces.size() - 1; i >= 0; i--) {
          RemovedPiece rp = removedPieces.get(i);
          int playerType = playerControlsBlack ? 1 : 2;
          if (rp.type == playerType && rp.removedBy == 2) {
            pieceToRestore = rp;
            removedPieces.remove(i);
            break;
          }
        }
        
        if (pieceToRestore != null) {
          float startX = random(width);
          float startY = random(-200, 0);
          float targetX = BOARD_X + pieceToRestore.x * CELL_SIZE;
          float targetY = BOARD_Y + pieceToRestore.y * CELL_SIZE;
          restoreAnimations.add(new RestoreAnimation(startX, startY, targetX, targetY, pieceToRestore.type));
          useSkill(1);
          message = "Piece restored!";
          messageStartTime = millis();
        } else {
          message = "No pieces to restore!";
          messageStartTime = millis();
        }
        
        // Reset cooldown count after using skill
        movesSinceLastSkill = 0;
        
        skillInProgress = false;
      }
      break;
      
    case 2: // Still Water
      if (skillUses[skillIndex] < skillMaxUses[skillIndex] && !stillWaterActivePlayer) {
        stillWaterActivePlayer = true;
        stillWaterMovesLeftPlayer = 2;
        opponentShaking = false;
        useSkill(2);
        message = "Still Water activated - 2 moves!";
        messageStartTime = millis();
        
        // Reset cooldown count after using skill
        movesSinceLastSkill = 0;
        
        skillInProgress = false;
      }
      break;
      
    case 3: // Role Reversal
      if (skillUses[skillIndex] < skillMaxUses[skillIndex] && !roleReversalUsedPlayer) {
        roleReversalUsedPlayer = true;
        
        // Role Reversal: Only change player's controlled color, not board pieces
        playerControlsBlack = !playerControlsBlack;
        
        useSkill(3);
        message = "Roles Reversed! You now control " + (playerControlsBlack ? "Black" : "White") + " pieces.";
        messageStartTime = millis();
        
        // Reset cooldown count after using skill
        movesSinceLastSkill = 0;
        
        skillInProgress = false;
      }
      break;
      
    case 4: // Herculean Might
      if (skillUses[skillIndex] < skillMaxUses[skillIndex]) {
        herculeanMightActive = true;
        boardShaking = true;
        boardShakesLeft = 30;
        useSkill(4);
        message = "Herculean Might! Board shaking!";
        messageStartTime = millis();
        
        // Reset cooldown count after using skill
        movesSinceLastSkill = 0;
        
        skillInProgress = false;
      }
      break;
      
    case 5: // Cleanup Service
      if (skillUses[skillIndex] < skillMaxUses[skillIndex]) {
        cleanupActive = true;
        cleaning = true;
        
        selectRandomColumnsWithPieces();
        
        broomX = BOARD_X + columnsToClean[0] * CELL_SIZE + random(-50, 50);
        broomY = -500;
        broomTargetY = BOARD_Y + BOARD_SIZE + 200;
        
        useSkill(5);
        message = "Cleanup Service!";
        messageStartTime = millis();
        
        // Reset cooldown count after using skill
        movesSinceLastSkill = 0;
      }
      break;
      
    case 6: // Fresh Start
      if (skillUses[skillIndex] < skillMaxUses[skillIndex] && !freshStartUsedPlayer) {
        freshStartUsedPlayer = true;
        
        // Fresh Start: Only clear the board, don't change player's controlled color
        for (int i = 0; i < GRID_SIZE; i++) {
          for (int j = 0; j < GRID_SIZE; j++) {
            board[i][j] = 0;
          }
        }
        
        flyingPieces.clear();
        pieceAnimations.clear();
        restoreAnimations.clear();
        
        useSkill(6);
        message = "Fresh Start - Board cleared! You control " + (playerControlsBlack ? "Black" : "White") + " pieces.";
        messageStartTime = millis();
        skillInProgress = false;
        
        // Reset cooldown count after using skill
        movesSinceLastSkill = 0;
        
        // The one who uses Fresh Start moves first, black always goes first
        isBlackTurn = true;
        currentPlayer = 1; // Player moves first
        playerShaking = true;
        opponentShaking = false;
      }
      break;
  }
}

// Swap colors of all pieces on the board (no longer used, Role Reversal doesn't change board)
void swapBoardPieceColors() {
  for (int i = 0; i < GRID_SIZE; i++) {
    for (int j = 0; j < GRID_SIZE; j++) {
      if (board[i][j] == 1) {
        board[i][j] = 2;
      } else if (board[i][j] == 2) {
        board[i][j] = 1;
      }
    }
  }
}

// ORIGINAL: Random column selection for Cleanup Service
void selectRandomColumnsWithPieces() {
  ArrayList<Integer> columnsWithPieces = new ArrayList<Integer>();
  for (int col = 0; col < GRID_SIZE; col++) {
    for (int row = 0; row < GRID_SIZE; row++) {
      if (board[col][row] != 0) {
        if (!columnsWithPieces.contains(col)) {
          columnsWithPieces.add(col);
        }
        break;
      }
    }
  }
  
  // Java Collections Framework usage
  if (columnsWithPieces.size() >= 3) {
    Collections.shuffle(columnsWithPieces);
    for (int i = 0; i < 3; i++) {
      columnsToClean[i] = columnsWithPieces.get(i);
    }
  } else {
    columnsToClean[0] = (int)random(GRID_SIZE);
    do {
      columnsToClean[1] = (int)random(GRID_SIZE);
    } while (columnsToClean[1] == columnsToClean[0]);
    do {
      columnsToClean[2] = (int)random(GRID_SIZE);
    } while (columnsToClean[2] == columnsToClean[0] || columnsToClean[2] == columnsToClean[1]);
  }
}

void useSkill(int index) {
  if (skillAvailable[index] && skillUses[index] < skillMaxUses[index]) {
    skillUses[index]++;
    if (skillUses[index] >= skillMaxUses[index]) {
      skillAvailable[index] = false;
      skillGrayed[index] = true;
    }
  }
}

// ORIGINAL: Piece placement with animation
void placePiece(int x, int y, int type) {
  board[x][y] = type;
  
  float pieceX = BOARD_X + x * CELL_SIZE;
  float pieceY = BOARD_Y + y * CELL_SIZE;
  pieceAnimations.add(new PieceAnimation(pieceX, pieceY, type));
  
  // Sound Library usage for move sounds
  if (currentPlayer == 1) {
    if (moveSounds[1] != null) {
      moveSounds[1].play();
    }
  } else {
    if (moveSounds[0] != null) {
      moveSounds[0].play();
    }
  }
}

boolean checkImmediateWinCondition() {
  int playerType = playerControlsBlack ? 1 : 2;
  int computerType = playerControlsBlack ? 2 : 1;
  
  for (int i = 0; i < GRID_SIZE; i++) {
    for (int j = 0; j < GRID_SIZE; j++) {
      if (board[i][j] == 0) {
        board[i][j] = playerType;
        if (checkFiveInRow(i, j)) {
          board[i][j] = 0;
          return true;
        }
        board[i][j] = 0;
        
        board[i][j] = computerType;
        if (checkFiveInRow(i, j)) {
          board[i][j] = 0;
          return true;
        }
        board[i][j] = 0;
      }
    }
  }
  
  return false;
}

// Improved computer AI - ORIGINAL: Custom AI implementation
void computerMove() {
  if (shouldComputerUseSkill()) {
    int skillToUse = selectComputerSkill();
    if (skillToUse != -1) {
      useComputerSkill(skillToUse);
      return;
    }
  }
  
  int[] move = findComputerMove();
  
  if (move != null) {
    // Computer places piece based on its controlled color
    int computerType = playerControlsBlack ? 2 : 1;
    
    // Computer always places its controlled color
    placePiece(move[0], move[1], computerType);
    
    lastMove[0] = move[0];
    lastMove[1] = move[1];
    
    // Increment move count
    movesSinceLastSkill++;
    
    if (stillWaterActiveComputer && stillWaterMovesLeftComputer > 0) {
      stillWaterMovesLeftComputer--;
      if (stillWaterMovesLeftComputer == 0) {
        stillWaterActiveComputer = false;
        isBlackTurn = !isBlackTurn;
        currentPlayer = 1;
        playerShaking = true;
        opponentShaking = false;
        skillInProgress = false;
      }
    } else {
      isBlackTurn = !isBlackTurn;
      currentPlayer = 1;
      playerShaking = true;
      opponentShaking = false;
      skillInProgress = false;
    }
    
    checkWinCondition();
  }
}

// Intelligent computer move selection - ORIGINAL: Custom AI algorithm
// Inspired by common Gomoku AI strategies but significantly adapted
int[] findComputerMove() {
  int computerType = playerControlsBlack ? 2 : 1;
  int playerType = playerControlsBlack ? 1 : 2;
  
  // 1. Check if computer can win immediately
  for (int i = 0; i < GRID_SIZE; i++) {
    for (int j = 0; j < GRID_SIZE; j++) {
      if (board[i][j] == 0) {
        board[i][j] = computerType;
        if (checkFiveInRow(i, j)) {
          board[i][j] = 0;
          return new int[]{i, j};
        }
        board[i][j] = 0;
      }
    }
  }
  
  // 2. Check if player can win immediately
  for (int i = 0; i < GRID_SIZE; i++) {
    for (int j = 0; j < GRID_SIZE; j++) {
      if (board[i][j] == 0) {
        board[i][j] = playerType;
        if (checkFiveInRow(i, j)) {
          board[i][j] = 0;
          return new int[]{i, j};
        }
        board[i][j] = 0;
      }
    }
  }
  
  // 3. Check if player has four in a row
  for (int i = 0; i < GRID_SIZE; i++) {
    for (int j = 0; j < GRID_SIZE; j++) {
      if (board[i][j] == 0) {
        board[i][j] = playerType;
        if (countMaxConsecutive(i, j, playerType) >= 4) {
          board[i][j] = 0;
          return new int[]{i, j};
        }
        board[i][j] = 0;
      }
    }
  }
  
  // 4. Check if player has live three
  for (int i = 0; i < GRID_SIZE; i++) {
    for (int j = 0; j < GRID_SIZE; j++) {
      if (board[i][j] == 0) {
        if (wouldFormLiveThree(i, j, playerType)) {
          return new int[]{i, j};
        }
      }
    }
  }
  
  // 5. Computer creates its own opportunities
  for (int i = 0; i < GRID_SIZE; i++) {
    for (int j = 0; j < GRID_SIZE; j++) {
      if (board[i][j] == 0) {
        if (wouldFormLiveThree(i, j, computerType)) {
          return new int[]{i, j};
        }
      }
    }
  }
  
  // 6. Strategic positions
  return findStrategicMove(computerType, playerType);
}

// Calculate maximum consecutive count - ORIGINAL: Custom evaluation function
int countMaxConsecutive(int x, int y, int type) {
  int maxCount = 0;
  int[][] directions = {{1, 0}, {0, 1}, {1, 1}, {1, -1}};
  
  for (int[] dir : directions) {
    int count = 1;
    
    for (int i = 1; i <= 4; i++) {
      int newX = x + dir[0] * i;
      int newY = y + dir[1] * i;
      if (newX >= 0 && newX < GRID_SIZE && newY >= 0 && newY < GRID_SIZE && board[newX][newY] == type) {
        count++;
      } else {
        break;
      }
    }
    
    for (int i = 1; i <= 4; i++) {
      int newX = x - dir[0] * i;
      int newY = y - dir[1] * i;
      if (newX >= 0 && newX < GRID_SIZE && newY >= 0 && newY < GRID_SIZE && board[newX][newY] == type) {
        count++;
      } else {
        break;
      }
    }
    
    if (count > maxCount) {
      maxCount = count;
    }
  }
  
  return maxCount;
}

// Check if would form a live three - ORIGINAL: Threat detection algorithm
boolean wouldFormLiveThree(int x, int y, int type) {
  board[x][y] = type;
  
  int[][] directions = {{1, 0}, {0, 1}, {1, 1}, {1, -1}};
  
  for (int[] dir : directions) {
    int count = 1;
    
    for (int i = 1; i <= 4; i++) {
      int newX = x + dir[0] * i;
      int newY = y + dir[1] * i;
      if (newX >= 0 && newX < GRID_SIZE && newY >= 0 && newY < GRID_SIZE && 
          board[newX][newY] == type) {
        count++;
      } else {
        break;
      }
    }
    
    for (int i = 1; i <= 4; i++) {
      int newX = x - dir[0] * i;
      int newY = y - dir[1] * i;
      if (newX >= 0 && newX < GRID_SIZE && newY >= 0 && newY < GRID_SIZE && 
          board[newX][newY] == type) {
        count++;
      } else {
        break;
      }
    }
    
    if (count == 3) {
      board[x][y] = 0;
      return true;
    }
  }
  
  board[x][y] = 0;
  return false;
}

// ORIGINAL: Strategic position evaluation for AI
int[] findStrategicMove(int computerType, int playerType) {
  int bestScore = -1000000;
  int[] bestMove = null;
  int center = GRID_SIZE / 2;
  
  for (int i = 0; i < GRID_SIZE; i++) {
    for (int j = 0; j < GRID_SIZE; j++) {
      if (board[i][j] == 0) {
        int score = 0;
        
        int distFromCenter = abs(i - center) + abs(j - center);
        score += (GRID_SIZE - distFromCenter) * 30;
        
        for (int dx = -2; dx <= 2; dx++) {
          for (int dy = -2; dy <= 2; dy++) {
            if (dx == 0 && dy == 0) continue;
            int nx = i + dx;
            int ny = j + dy;
            if (nx >= 0 && nx < GRID_SIZE && ny >= 0 && ny < GRID_SIZE) {
              if (board[nx][ny] == computerType) {
                score += 150;
              } else if (board[nx][ny] == playerType) {
                score += 80;
              }
            }
          }
        }
        
        // Gomoku strategy: prioritize key points
        // Reference: Common Gomoku opening strategies
        if ((i == 7 && j == 7) || (i == 3 && j == 3) || (i == 11 && j == 11) || 
            (i == 3 && j == 11) || (i == 11 && j == 3)) {
          score += 200;
        }
        
        if (score > bestScore) {
          bestScore = score;
          bestMove = new int[]{i, j};
        }
      }
    }
  }
  
  if (bestMove != null) {
    return bestMove;
  }
  
  ArrayList<int[]> emptyCells = new ArrayList<int[]>();
  for (int i = 0; i < GRID_SIZE; i++) {
    for (int j = 0; j < GRID_SIZE; j++) {
      if (board[i][j] == 0) {
        emptyCells.add(new int[]{i, j});
      }
    }
  }
  
  if (emptyCells.size() > 0) {
    return emptyCells.get((int)random(emptyCells.size()));
  }
  
  return null;
}

// Improved computer skill usage judgment - ORIGINAL: AI skill decision logic
boolean shouldComputerUseSkill() {
  if (currentPlayer != 2 || skillInProgress || rockfallActive || cleaning || boardShaking) {
    return false;
  }
  
  // Check skill cooldown
  if (movesSinceLastSkill < SKILL_COOLDOWN_MOVES) {
    return false;
  }
  
  // If player has threat, increase skill usage probability
  int playerType = playerControlsBlack ? 1 : 2;
  
  // Check if player has four in a row
  boolean playerHasFour = false;
  for (int i = 0; i < GRID_SIZE; i++) {
    for (int j = 0; j < GRID_SIZE; j++) {
      if (board[i][j] == playerType) {
        if (countMaxConsecutive(i, j, playerType) >= 4) {
          playerHasFour = true;
          break;
        }
      }
    }
    if (playerHasFour) break;
  }
  
  float skillProbability = 0.1;
  
  if (playerHasFour) {
    skillProbability = 0.8;
  }
  
  return random(1) < skillProbability;
}

// ORIGINAL: AI skill selection algorithm
int selectComputerSkill() {
  ArrayList<Integer> availableSkills = new ArrayList<Integer>();
  
  for (int i = 0; i < 7; i++) {
    if (computerSkillAvailable[i] && computerSkillUses[i] < skillMaxUses[i]) {
      if (i == 0) { // Rockfall
        int playerType = playerControlsBlack ? 1 : 2;
        boolean hasPlayerPieces = false;
        for (int x = 0; x < GRID_SIZE; x++) {
          for (int y = 0; y < GRID_SIZE; y++) {
            if (board[x][y] == playerType) {
              hasPlayerPieces = true;
              break;
            }
          }
          if (hasPlayerPieces) break;
        }
        if (hasPlayerPieces) availableSkills.add(i);
      } else if (i == 1) { // Finders Keepers
        boolean hasComputerPiecesRemoved = false;
        for (RemovedPiece rp : removedPieces) {
          int computerType = playerControlsBlack ? 2 : 1;
          if (rp.type == computerType && rp.removedBy == 1) {
            hasComputerPiecesRemoved = true;
            break;
          }
        }
        if (hasComputerPiecesRemoved) availableSkills.add(i);
      } else if (i == 2 && !stillWaterActiveComputer) {
        availableSkills.add(i);
      } else if (i == 3 && !roleReversalUsedComputer) {
        availableSkills.add(i);
      } else if (i == 4) {
        availableSkills.add(i);
      } else if (i == 5) {
        availableSkills.add(i);
      } else if (i == 6 && !freshStartUsedComputer) {
        availableSkills.add(i);
      }
    }
  }
  
  if (availableSkills.size() > 0) {
    // Prioritize offensive skills
    int playerType = playerControlsBlack ? 1 : 2;
    
    // Check if player has four-in-a-row threat
    boolean playerHasFourThreat = false;
    for (int i = 0; i < GRID_SIZE; i++) {
      for (int j = 0; j < GRID_SIZE; j++) {
        if (board[i][j] == playerType) {
          if (countMaxConsecutive(i, j, playerType) >= 4) {
            playerHasFourThreat = true;
            break;
          }
        }
      }
      if (playerHasFourThreat) break;
    }
    
    if (playerHasFourThreat) {
      if (availableSkills.contains(0)) return 0;
      if (availableSkills.contains(5)) return 5;
    }
    
    return availableSkills.get((int)random(availableSkills.size()));
  }
  
  return -1;
}

// ORIGINAL: Computer skill activation
void useComputerSkill(int skillIndex) {
  String[] skillMessages = {
    "Opponent used Rockfall!",
    "Opponent used Finders Keepers!",
    "Opponent used Still Water!",
    "Opponent used Role Reversal!",
    "Opponent used Herculean Might!",
    "Opponent used Cleanup Service!",
    "Opponent used Fresh Start!"
  };
  
  message = skillMessages[skillIndex];
  messageStartTime = millis();
  skillInProgress = true;
  
  switch(skillIndex) {
    case 0:
      computerUseRockfall();
      break;
    case 1:
      computerUseFindersKeepers();
      break;
    case 2:
      stillWaterActiveComputer = true;
      stillWaterMovesLeftComputer = 2;
      playerShaking = false;
      
      // Reset cooldown count after using skill
      movesSinceLastSkill = 0;
      
      skillInProgress = false;
      break;
    case 3: // Role Reversal (computer use)
      roleReversalUsedComputer = true;
      
      // Computer uses Role Reversal: change player's controlled color
      playerControlsBlack = !playerControlsBlack;
      
      // Reset cooldown count after using skill
      movesSinceLastSkill = 0;
      
      skillInProgress = false;
      break;
    case 4: // Herculean Might (computer use)
      herculeanMightActive = true;
      boardShaking = true;
      boardShakesLeft = 30;
      
      // Reset cooldown count after using skill
      movesSinceLastSkill = 0;
      
      skillInProgress = false;
      break;
    case 5:
      computerUseCleanupService();
      break;
    case 6: // Fresh Start (computer use)
      freshStartUsedComputer = true;
      
      // Computer uses Fresh Start: clear the board, don't change player's controlled color
      for (int i = 0; i < GRID_SIZE; i++) {
        for (int j = 0; j < GRID_SIZE; j++) {
          board[i][j] = 0;
        }
      }
      
      // Reset cooldown count after using skill
      movesSinceLastSkill = 0;
      
      skillInProgress = false;
      
      // The one who uses Fresh Start moves first
      isBlackTurn = true;
      currentPlayer = 2; // Computer moves first
      playerShaking = false;
      opponentShaking = true;
      break;
  }
  
  computerSkillUses[skillIndex]++;
  if (computerSkillUses[skillIndex] >= skillMaxUses[skillIndex]) {
    computerSkillAvailable[skillIndex] = false;
    computerSkillGrayed[skillIndex] = true;
  }
}

// ORIGINAL: Computer Rockfall implementation
void computerUseRockfall() {
  int playerType = playerControlsBlack ? 1 : 2;
  
  ArrayList<int[]> playerPieces = new ArrayList<int[]>();
  
  for (int i = 0; i < GRID_SIZE; i++) {
    for (int j = 0; j < GRID_SIZE; j++) {
      if (board[i][j] == playerType) {
        playerPieces.add(new int[]{i, j});
      }
    }
  }
  
  if (playerPieces.size() > 0) {
    int[] piece = playerPieces.get((int)random(playerPieces.size()));
    int pieceType = board[piece[0]][piece[1]];
    
    float startX = BOARD_X + piece[0] * CELL_SIZE;
    float startY = BOARD_Y + piece[1] * CELL_SIZE;
    flyingPieces.add(new FlyingPiece(startX, startY, pieceType));
    
    removedPieces.add(new RemovedPiece(piece[0], piece[1], pieceType, 2));
    
    board[piece[0]][piece[1]] = 0;
    
    // Reset cooldown count after using skill
    movesSinceLastSkill = 0;
    
    skillInProgress = false;
    
    checkWinCondition();
  } else {
    skillInProgress = false;
  }
}

// ORIGINAL: Computer Finders Keepers implementation
void computerUseFindersKeepers() {
  RemovedPiece pieceToRestore = null;
  for (int i = removedPieces.size() - 1; i >= 0; i--) {
    RemovedPiece rp = removedPieces.get(i);
    int computerType = playerControlsBlack ? 2 : 1;
    if (rp.type == computerType && rp.removedBy == 1) {
      pieceToRestore = rp;
      removedPieces.remove(i);
      break;
    }
  }
  
  if (pieceToRestore != null) {
    float startX = random(width);
    float startY = random(-200, 0);
    float targetX = BOARD_X + pieceToRestore.x * CELL_SIZE;
    float targetY = BOARD_Y + pieceToRestore.y * CELL_SIZE;
    restoreAnimations.add(new RestoreAnimation(startX, startY, targetX, targetY, pieceToRestore.type));
  }
  
  // Reset cooldown count after using skill
  movesSinceLastSkill = 0;
  
  skillInProgress = false;
}

// ORIGINAL: Computer Cleanup Service implementation
void computerUseCleanupService() {
  cleanupActive = true;
  cleaning = true;
  
  selectComputerCleanupColumns();
  
  broomX = BOARD_X + columnsToClean[0] * CELL_SIZE + random(-30, 30);
  broomY = -500;
  broomTargetY = BOARD_Y + BOARD_SIZE + 200;
  
  // Reset cooldown count after using skill
  movesSinceLastSkill = 0;
}

// ORIGINAL: Computer column selection for Cleanup Service
void selectComputerCleanupColumns() {
  int playerType = playerControlsBlack ? 1 : 2;
  
  ArrayList<int[]> columnPlayerPieces = new ArrayList<int[]>();
  
  for (int col = 0; col < GRID_SIZE; col++) {
    int playerPieceCount = 0;
    for (int row = 0; row < GRID_SIZE; row++) {
      if (board[col][row] == playerType) {
        playerPieceCount++;
      }
    }
    columnPlayerPieces.add(new int[]{col, playerPieceCount});
  }
  
  // Java Collections sorting
  columnPlayerPieces.sort((a, b) -> Integer.compare(b[1], a[1]));
  
  for (int i = 0; i < 3 && i < columnPlayerPieces.size(); i++) {
    columnsToClean[i] = columnPlayerPieces.get(i)[0];
  }
  
  for (int i = columnPlayerPieces.size(); i < 3; i++) {
    columnsToClean[i] = (int)random(GRID_SIZE);
  }
}

// ORIGINAL: Five-in-a-row detection algorithm
boolean checkFiveInRow(int x, int y) {
  int type = board[x][y];
  if (type == 0) return false;
  
  int[][] directions = {{1, 0}, {0, 1}, {1, 1}, {1, -1}};
  
  for (int[] dir : directions) {
    int count = 1;
    
    for (int i = 1; i <= 4; i++) {
      int newX = x + dir[0] * i;
      int newY = y + dir[1] * i;
      if (newX >= 0 && newX < GRID_SIZE && newY >= 0 && newY < GRID_SIZE && 
          board[newX][newY] == type) {
        count++;
      } else {
        break;
      }
    }
    
    for (int i = 1; i <= 4; i++) {
      int newX = x - dir[0] * i;
      int newY = y - dir[1] * i;
      if (newX >= 0 && newX < GRID_SIZE && newY >= 0 && newY < GRID_SIZE && 
          board[newX][newY] == type) {
        count++;
      } else {
        break;
      }
    }
    
    if (count >= 5) {
      return true;
    }
  }
  
  return false;
}

// Key fix: Correct win condition check - ORIGINAL implementation
void checkWinCondition() {
  // Check entire board for five in a row
  for (int i = 0; i < GRID_SIZE; i++) {
    for (int j = 0; j < GRID_SIZE; j++) {
      if (board[i][j] != 0) {
        if (checkFiveInRow(i, j)) {
          gameOver = true;
          
          // Piece type on board: 1=black, 2=white
          int winningColor = board[i][j];
          
          // Determine winner: if winning color is player's currently controlled color, player wins
          int playerControlledColor = playerControlsBlack ? 1 : 2;
          
          if (winningColor == playerControlledColor) {
            winner = 1; // Player wins
          } else {
            winner = 2; // Computer wins
          }
          
          // Sound Library usage for win/lose sounds
          if (winner == 1 && winSound != null) {
            winSound.play();
          } else if (winner == 2 && loseSound != null) {
            loseSound.play();
          }
          
          gameOverTime = millis();
          return;
        }
      }
    }
  }
  
  // Check draw (board full)
  boolean boardFull = true;
  for (int i = 0; i < GRID_SIZE; i++) {
    for (int j = 0; j < GRID_SIZE; j++) {
      if (board[i][j] == 0) {
        boardFull = false;
        break;
      }
    }
    if (!boardFull) break;
  }
  
  if (boardFull) {
    gameOver = true;
    winner = 0; // Draw
    gameOverTime = millis();
  }
}
