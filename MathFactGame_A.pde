//TODO:
//Time_allotted calculation
//Create Wrapper Screen

import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

Minim minim;
AudioSnippet bg;
AudioSnippet level1;
AudioSnippet level2;
AudioSnippet level3;
AudioSample coins;
AudioSample bubbleBurst;

//Settings
int displayH = displayHeight;
int roundsPerDay = 3;
char gameType = 'A';
int boardHeight = 700;
int boardWidth = 1000;
int thresholdScore = 12; //score to get to the next level
int ansLength = 2; //length of all answers

//styling
int boardx0 = (displayWidth-boardWidth)/2;
int boardy0 = (displayH-boardHeight)/2;
int brickWidth = 200;
int brickHeight = 50;
int brickPadding = 50;
int initBrickY = boardHeight-brickWidth+brickPadding;
int initBrickX = (boardWidth-brickWidth);
int textFieldWidth = 300;
int textFieldHeight = 100;
int textPadding = 15;
int submitWidth = 100;
int submitHeight = 50;
int submitPadding = 10;
int titleHeight = 200;
int titleWidth = 500;
int titlePadding = 10;
int scorePadding = 10;
int scoreHeight = 50;
int scoreWidth = 0;
float topEndOfBoard = (displayH-boardHeight)/2;
float distanceBubbleTravels = initBrickY-topEndOfBoard;
int ship_y = (displayHeight)/2;
int ship_x = (displayWidth-boardWidth)/2;
int shipWidth = 300;
int shipHeight = 200;

//Global Variables
Game game;
PImage bg_img;
PFont font; 
PImage coin_img;
PImage falling_coins_img;
PImage pile_img;
PImage bubble_img;
PImage ocean_bg;
PImage ocean_fg;
PImage pirate_ship;
PImage parchment;
PImage pirate_chest;
PImage between_round_ship;
PImage between_round_pirate;
int probsPerRound = 14;
int fr = 20;
int timeDec = 500;//decrease in time_allotted between rounds
int initTimeAllotted = 10000;//ms allotted
Caption betweenRoundsTitle;
//int initTimeAllotted = initTimeAllotted/fr; //account for frame rate

void setup(){
  //fullScreen
  font = loadFont("Apple-Chancery-30.vlw");
  smooth();
  minim = new Minim(this);
  bg = minim.loadSnippet("bg.wav");
  level1 = minim.loadSnippet("Netherworld Shanty.wav");
  level2 = minim.loadSnippet("Netherworld Shanty.wav");
  level3 = minim.loadSnippet("Netherworld Shanty.wav");
  coins = minim.loadSample("coins.wav");
  bubbleBurst = minim.loadSample("burst1.mp3");
  bg.loop();
  size(displayWidth, displayHeight);
  bg_img = loadImage("ship.jpg");
  coin_img = loadImage("gold-n-bubble.png");
  pile_img = loadImage("pile-of-gold-coins.png");
  ocean_bg = loadImage("ocean_background.jpeg");
  ocean_fg = loadImage("ocean_fg.png");
  pirate_ship = loadImage("pirate_ship.png");
  parchment = loadImage("pirateWMap.png");
  pirate_chest = loadImage("pirateWGold.png");
  between_round_ship = loadImage("Pirate-Ship-Deck.jpg");
  between_round_pirate = loadImage("Pirate-with-old-treasure-chest.png");
  falling_coins_img = loadImage("falling_coins_img.png");
  //bubble_img = loadImage("bubble.png");
  frameRate(fr);
  background(51);
  fill(0);
  ship_y = (displayHeight-boardHeight)/2+shipHeight;
  ship_x = (displayWidth-boardWidth)/2;
  boardx0 = (displayWidth-boardWidth)/2;
  boardy0 = (displayH-boardHeight)/2;
  initBrickX = (displayWidth-brickWidth)/2;
  rect((displayWidth-boardWidth)/2, (displayHeight-boardHeight)/2, boardWidth, boardHeight, 7);
  betweenRoundsTitle = new Caption("Congratulations! You finished that round.\n\nReady to start the next round?");
  game = new Game();
}



void stop() {
    //close down sound stuff nicely...
    bg.close();
    //for (int i=0; i<4; i++) snd[i].close();
    minim.stop(); //...and turn off Minim.
    super.stop();
}

void draw(){
  background(51);
  game.drawBoard();
  //game.printStatus();
}

void keyPressed(){
  game.sendToListener(key);
}

void mouseClicked(){
  game.sendMouseToListener(mouseX, mouseY);
}


boolean sketchFullScreen() {
  return false;
}

//Is this necessary?
void selectbuffFile(File selection){
  game.bf = createReader(selection.getAbsolutePath());
  game.loadData(game.pid, game.day);
}

/*
Classes (in alphabetical order)
*/

class Board {
  int gamestate;
  
  Board(int state){
    gamestate = state;
  }
  
  void changeState(int state){
    gamestate = state; 
  }
  
  void drawBoard(ArrayList<BoardObj> objs){
    if(gamestate<4&&gamestate!=2){
      fill(0);
      //translate(0,0,-50);
      //rect((displayWidth-boardWidth)/2, (displayHeight-boardHeight)/2, boardWidth, boardHeight, 7);
      image(bg_img, (displayWidth-boardWidth)/2, (displayHeight-boardHeight)/2, boardWidth, boardHeight);
      //println("I'm drawing the board: "+objs.size());
      //pushStyle();
      
      //popStyle();
      //Draw a white rectangle Gameboard
      pushStyle();
      
      for(BoardObj obj : objs){
        obj.display();
      }
      popStyle();
    }
    if(gamestate==6){
      fill(0);
      image(between_round_ship, (displayWidth-boardWidth)/2, (displayHeight-boardHeight)/2, boardWidth, boardHeight);
      image(between_round_pirate, (displayWidth-shipWidth)/2, (displayHeight-shipHeight)/2+shipHeight, shipWidth, shipHeight);
      betweenRoundsTitle.display();
    }
  }

}

//Board Object
//Base class for any object that
//will be drawn on the board.
class BoardObj{
  void display(){}
}

//Brick
//The Brick on the board. It is constructed
//with its problem and displays the problem.
class Brick extends BoardObj{
  Problem myProb;
  int xpos, ypos;
  Datum datum;
  int sign;
  float increase_y;
  float increase_x;
  float temp_x;
  float temp_y;
  boolean burst;
  boolean burstDone;
 
  Brick(Problem prob, Datum d){
    xpos = initBrickX;
    ypos = initBrickY;
    temp_y = ypos;
    temp_x = xpos;
    increase_y=0;
    increase_x=0;
    myProb = prob;
    datum = d;
    sign = int(random(0,2));
    if(sign==0)sign = -1;
    burst = false;
    burstDone = false;
  } 

  void explode(){
    burst = true;
  }

  boolean burstFinished(){
    return burstDone;
  }

  @Override
  void display(){
    if(!burst){
      xpos = int(temp_x+increase_x);
      ypos = int(temp_y-increase_y);
      pushStyle();
      //image(bubble_img, xpos-brickPadding/2, ypos-brickHeight*2, (brickWidth+brickPadding), (brickWidth+brickPadding));
      tint(230, 255);
      image(coin_img, xpos, ypos, (brickWidth+brickPadding), (brickWidth+brickPadding));
      popStyle();
      //box
      //fill(255, 255, 0);
      noStroke();
      //rect(xpos, ypos, brickWidth, brickHeight, 7);

      //fill(106,156,255,120);
      //ellipseMode(RADIUS);
      //ellipse(xpos+brickWidth/2, ypos+brickHeight/2, (brickWidth+brickPadding)/2, (brickWidth+brickPadding)/2);
      //value
      fill(0);
      textSize(32); 
      textAlign(CENTER, CENTER);
      text(myProb.getStimulus(), xpos, ypos, (brickWidth+brickPadding), (brickWidth+brickPadding));
    } else {
      if(ypos+brickHeight+brickPadding>=(displayHeight+boardHeight)/2){
        coins.trigger();
        burstDone = true;
      }
      image(falling_coins_img, xpos, ypos, (brickWidth+brickPadding), (brickHeight+brickPadding));
      ypos+=40;
    }
  }

  String getAnswer(){
    return myProb.getAnswer();
  }

  void update(float inc){
    
    if(xpos+brickWidth+brickPadding>(displayWidth-boardWidth)/2+boardWidth || xpos<(displayWidth-boardWidth)/2+scorePadding+scoreWidth+inc){
      sign*=-1;
    }
    increase_x += inc*sign/float(fr);
    increase_y += inc/float(fr);
    //println("inc="+inc+" x_inc="+increase_x+" y_inc="+increase_y);
  } 

  void addResponse(String resp, int onset){
    datum.addResponse(resp, onset);
  }
}

class ClickableObj extends BoardObj{
  int xpos;
  int ypos;
  int objHeight;
  int objWidth;

  void display(){}

  int getX(){
    return xpos;
  }

  int getY(){
    return ypos;
  }

  boolean inBounds(int x, int y){
    return (x<=xpos+objWidth&&x>=xpos&&y<=ypos+objHeight&&y>=ypos);
  }

}

class Datum{
  int time_allotted; //in ms
  String problem;
  String correct_sum;
  // participant response(s) (if incorrect responses separated by ‘/’)
  String responses = "";
  //Time of first response
  int firstResponseTime;
  //Time of correct response (blank if no correct response) 
  int correctResponseTime=0;
  //Accuracy for first response (If participant was correct on first try)
  int accuracy_first;
  //Accuracy for the whole trial (if participant was correct at any point)
  int accuracy_whole=0;
  //number of responses.
  int numResponses;
  int beginDisp;
  int round;
  int probNum;
  ArrayList<Integer> responseTimes;

  Datum(Problem prob, int onset, float skillLevel, int rnd, int pn, int tA){
    probNum = pn;
    round = rnd;
    time_allotted = tA;
    problem = prob.getStimulus();
    correct_sum = prob.getAnswer();
    beginDisp = onset;
    responseTimes = new ArrayList<Integer>();
    //time_allotted = 1000*(initBrickY-(displayHeight-boardHeight)/2)/skillLevel/fr;
  }
  
  public String toCSV(){
    String csv = round+","+probNum+","+time_allotted+","+problem+","+correct_sum+","+responses+","+firstResponseTime+","+correctResponseTime+","+accuracy_first+","+accuracy_whole+","+numResponses;
    return csv;
  }

  void addResponse(String resp, int respTime){
    if (responses.equals("")){
      responses+=resp;
      firstResponseTime = respTime-beginDisp;
      if(responses.equals(correct_sum)){
        accuracy_first=1;
        accuracy_whole=1;
        correctResponseTime = firstResponseTime;
      } else {
        accuracy_first=0;
      }
    }else{ 
      responses+="/"+resp;
      if(resp.equals(correct_sum)){
        correctResponseTime = respTime-beginDisp;
        accuracy_whole=1;
      }
    }
    numResponses++;
  }
}

//Data 
//This class keeps track of all of the data to be written to 
//a file. Each time a new problem is displayed, it will come with
//a datum to record the necessary statistics.
class Data{
  ArrayList<Datum> dataList;
  String pid;
  String day;
  PrintWriter output;

  Data(String newPID, String newDay){
    pid = newPID;
    day = newDay;
    dataList = new ArrayList<Datum>();
    output = createWriter(pid+"_day"+day+".csv");
  }

  Datum addNewDatum(Problem curProblem, int onset, float skillLevel, int round, int probNum, int time_allotted){
    Datum newDatum = new Datum(curProblem, onset, skillLevel, round, probNum, time_allotted);
    dataList.add(newDatum);
    return newDatum;
  }

  Datum getCurDatum(){
    return dataList.get(dataList.size()-1);
  }

  void setPID(String newPID){
    pid = newPID;
  }

  void setDay(String newDay){
    day = newDay;
  }
  
  boolean isEmpty(){
    return dataList.isEmpty();
  }
  
  void csv(){
    //println("Making CSV");
    String headers="pid,day,round,problem_number,time_allotted,problem,correct_sum,responses,firstResponseTime,correctResponseTime,accuracy_first,accuracy_whole,numResponses";
    output.println(headers);
    String lead = ""+pid+','+day+',';
    for(Datum d : dataList){
      output.println(lead+d.toCSV());
    }
    output.flush();
    output.close();  
  }
  
}

class Caption{
  String message;
  
  Caption(String msg){
    message = msg;
  }
  
  void display(){
    pushStyle();
    textSize(32);
    textAlign(CENTER, CENTER);
    fill(100, 200);
    noStroke();
    rect((displayWidth-titleWidth*2)/2, (displayHeight-titleHeight)/2-1*titleHeight, 2*titleWidth, titleHeight+titlePadding);
    fill(255,255,0);
    text(message, (displayWidth-titleWidth*2)/2+titlePadding, (displayHeight-titleHeight)/2-titleHeight, 2*(titleWidth-2*titlePadding), titleHeight);
    popStyle();
  }
}


//Game
//This is the main class. It holds all the other objects inside it and tells
//everything what to do. 
//TODO: Change setting Skill Level to setting Time allotted
//
class Game{
  Data data;
  Board board;
  Scoreboard sb;
  //CSVWriter csv;
  //gamestate: 0='Setup', 1='General Gameplay', 2='End game screen', 3='Press any key to start', 4='Story Screen 1', 5='Story Screen 2', 6='Between Rounds'
  int gamestate;
  ArrayList<Round> rounds;
  String pid;
  String day;
  //float skillLevel;
  Round curRound;
  Brick curBrick;
  //Problem curProblem;
  ArrayList<BoardObj> toDisplay;
  float skillLevel;
  String curResponse = "";
  int onset = 0;
  int answered = 0;
  ArrayList<TextField> textfields;
  TextField selectedTextField;
  TextField pidField;
  TextField dayField;
  SubmitButton submit;
  Title title;
  BufferedReader bf;
  Title waitForKey;
  boolean csvMade = false;
  int roundNum;
  int score = 0;
  int time_allotted = initTimeAllotted;

  ArrayList<ClickableObj> clickableObjs;
  
  Game(){
    toDisplay = new ArrayList<BoardObj>();
    clickableObjs = new ArrayList<ClickableObj>();
    gamestate = 0; //TESTING GAMEPLAY
    board = new Board(gamestate);
    rounds = setupRounds();
    sb = new Scoreboard();
    setupScreen();
    roundNum=0;
    distanceBubbleTravels = boardHeight-brickWidth-brickPadding/2;
    skillLevel = distanceBubbleTravels/float(time_allotted)*1000.0;
    //println("Distance: "+distanceBubbleTravels+", time_allotted= "+time_allotted+", increase="+skillLevel);
  }

  //Continuous methods

  public void drawBoard(){
    if (gamestate == 1){
    //gameplay
      if(curBrick==null){ //There is no brick
        chooseNewProblem();
        if(gamestate!=1) return; //case where the round is over.
      } else {
        curBrick.update(skillLevel);
      }
      if(outOfTime()||curBrick.burstDone){
        removeBrick();
      }
    }else if (gamestate == 2){
      if(csvMade==false){
        data.csv();
        csvMade=true;
      }
      endScreen();
      //display end screen 
    } else if (gamestate == 3){
      setupCurRound();
    } else if(gamestate == 4){
      storyScreenA();
    } else if(gamestate == 5){
      storyScreenB();
    } else if(gamestate ==6){
      setupCurRound();
    }
    board.drawBoard(toDisplay);
  }

  void storyScreenA(){
    if(ship_x<boardx0+boardWidth-shipWidth){
      //println(ship_x+","+ship_y);
      int increase =  int(10*sin(PI/2.0*float(millis()+1000)/1000.0))-10;
      image(ocean_bg, (displayWidth-boardWidth)/2, (displayHeight-boardHeight)/2, boardWidth, boardHeight);
      image(pirate_ship, ship_x, ship_y, shipWidth, shipHeight);
      image(ocean_fg, (displayWidth-boardWidth)/2, (displayHeight-boardHeight)/2+increase, boardWidth, boardHeight);
      ship_x+=5;
      ship_y+=int(5*sin(PI/2.0*float(millis())/1000.0));
      Title title = new Title("Rough seas for our pirate friend Jack!");
      title.display();
    } else {
      changeState(5);
    }
  }


  void storyScreenB(){
    image(bg_img, (displayWidth-boardWidth)/2, (displayHeight-boardHeight)/2, boardWidth, boardHeight);
    image(pirate_chest, (displayWidth-300)/2, (displayHeight-boardHeight)/2+boardHeight/2, 500, boardHeight/2);
    Caption cap = new Caption("Jack loves to keep his gold clean, but with the boat shaking so much, all his gold is getting caught in soap bubbles!!!\nHelp pop the bubbles by answering the questions right!");
    cap.display();
  }

  void setupCurRound(){
    if(curRound!=null && curRound.isEmpty()){
      rounds.remove(0);
      curRound=null;
      //newRound();
    }
    if(curRound==null){
      curRound = getNextRound();
      if(curRound==null){//no more rounds
        changeState(2);
        return;
      }
      newRound();
    }
  }

  void endScreen(){
    //level3.close();
    boardy0 = (displayHeight-boardHeight)/2;
    image(bg_img, (displayWidth-boardWidth)/2, (displayHeight-boardHeight)/2, boardWidth, boardHeight);
    bg.play();
    pushStyle();
    textAlign(CENTER, CENTER);
    textFont(font);
    image(parchment, (displayWidth-600)/2, boardy0, 600, boardHeight);
    text("Thank you for helping me get my treasure back!\nYou've earned a piece of treasure!\n\nYou scored: "+score+"!", (displayWidth-500)/2+175, boardy0+40, 300, boardHeight-50);
    popStyle();
  }

  void checkAnswer(){
    if(curBrick==null) return;
    if(curBrick.getAnswer().equals(curResponse)){
      correctAnswer();
    } else {
      wrongAnswer();
    }
  }

  void correctAnswer(){
    if(answeredCorrect()){
      score++;
      bubbleBurst.trigger();
      curBrick.addResponse(curResponse, millis());
      curRound.addScore();
      sb.incScore();
      curBrick.explode();
    }
  }



  void wrongAnswer(){
    curBrick.addResponse(curResponse, millis());
    curResponse = "";
  }

  void chooseNewProblem(){
    Problem curProblem = curRound.nextProblem();
    if(curProblem==null){
      changeState(6);
      return;
    }
    onset = millis();
    curBrick = new Brick(curProblem, data.addNewDatum(curProblem, onset, skillLevel, roundNum, curRound.getProbNum(), time_allotted));
    //Datum curDatum = data.getCurDatum();
    //listener.newDatum(curDatum);
    toDisplay.add(curBrick);
  }

  Round getNextRound(){
    if (!rounds.isEmpty()){
      return rounds.get(0);
    } else {
      return null;
    }
  }

  void sendMouseToListener(int x, int y){
    if(gamestate==0){
      ClickableObj selected = findMouseSelect(x, y);
      if(selected!=null){
        if(selected instanceof TextField && selected!=selectedTextField){
          changeSelected();
        } else {
          submit();
          
        }
      }
    }
  }

  public void sendToListener(char k){
    if(gamestate==1){
      if(k<='9'&&k>='0'){
        curResponse+=k;
        while(curResponse.length()>ansLength) curResponse=curResponse.substring(1);
      }else if(k==ENTER){
        checkAnswer(); //TODO: create this functionality
      }
    } else if (gamestate==0) {
      if(k==TAB){
        changeSelected();
      }else if (k==ENTER){
        submit();
      }else{
        selectedTextField.changeValue(k);
      }
      //press any key:
    } else if(gamestate==3 || gamestate==6){
      changeState(1);
    } else if(gamestate==4){
      changeState(5);
    } else if(gamestate==5){
      changeState(3);
    } else if(gamestate==2){
      exit();
    }

  }



  //Gamestate 0 ==== setup screen

  void setupScreen(){
    textfields = new ArrayList<TextField>();
    dayField = new TextField("day", false, (displayWidth - textFieldWidth)/2, (displayHeight - textFieldHeight)/2 + textFieldHeight*2+textPadding);
    pidField = new TextField("participant id", true,(displayWidth - textFieldWidth)/2, (displayHeight - textFieldHeight)/2 + textFieldHeight);
    textfields.add(pidField);
    textfields.add(dayField);
    submit = new SubmitButton((displayWidth - submitWidth)/2, (displayHeight - submitHeight)/2 + textFieldHeight*3+textPadding);
    clickableObjs.add(dayField);
    clickableObjs.add(pidField);
    clickableObjs.add(submit);
    title = new Title("Welcome to the Treasure Game!");
    toDisplay.add(pidField);
    toDisplay.add(dayField);
    toDisplay.add(submit);
    toDisplay.add(title);
    selectedTextField = pidField;
  }
  
  void changeSelected(){
    if(selectedTextField == dayField){
      selectedTextField = pidField;
      pidField.select();
      dayField.unselect();
    }else{
      selectedTextField = dayField;
      dayField.select();
      pidField.unselect();
    }
  }

  void submit(){
    day = dayField.getValue();
    pid = pidField.getValue();
    data = new Data(pid, day);
    //println(day+" "+pid);
    if(!day.equals("") && !pid.equals("")){
      if(!day.equals("1")){
        if(bf==null)createbuffReader(pid, day);
        if(bf!=null)loadData(pid, day);
      }
     if(day.equals("1")||bf!=null)changeState(4);
    }
  }
  
  
  
  
  void createbuffReader(String pid, String day){
    InputStream test = createInput(pid+"_day"+(Integer.parseInt(day)-1)+".csv");
    //println(test);
    
    if(test==null){
      //println(test==null);
      selectInput("Select previous day's data:", "selectbuffFile");
    } else {
      bf = createReader(pid+"_day"+(Integer.parseInt(day)-1)+".csv");
    }
  }

  void loadData(String pid, String day){
    
    String line;
    String prevLine = "";
    //Look for datafile
    try {
      line = bf.readLine();
      //String prevLine;
      while(line!=null){
        prevLine = line;
        line = bf.readLine();
      }
    } catch(IOException e){
      e.printStackTrace();
      line = null;
    }
    //println("Found last line: "+prevLine);
    String timeAllotted = "0";
    if(!prevLine.equals("")) {
      //println(prevLine);
      String subStr = prevLine.substring(pid.length()+day.length()+7);
      //println(subStr.substring(0,subStr.indexOf(',')));
      time_allotted = Integer.parseInt(subStr.substring(0,subStr.indexOf(',')));
      //println("time allocated: "+time_allotted);
      time_allotted+=500; //add half a second
    }
    if(!timeAllotted.equals("0")){
      println("Could not find correct time allotted");
      time_allotted = initTimeAllotted;
      //skillLevel = int(1000.0*float(initBrickY-(displayHeight-boardHeight)/2)/(float(Integer.parseInt(timeAllotted)))/float(fr));
      //println("found time allotted to be: "+timeAllotted+" and frame rate to be: "+fr);
      //frameRate(fr-frameRateInc);//starting at skillLevel before.
    }
  }
    //if no datafile look for last datafile
    //if no datafiles don't change skillevel

  ClickableObj findMouseSelect(int x, int y){
    for(ClickableObj obj : clickableObjs){
      //println("Mouse clicked at ("+x+","+y+")");
      if (obj.inBounds(x, y)) return obj;
    }
    return null;
  }

  private void changeState(int newState){
    gamestate = newState;
    board.changeState(newState);
    toDisplay.clear();
    if(newState==1){
      toDisplay.add(sb);
    }else if (newState==3){ //Before every round
      waitForKey = new Title("Press any key to begin");
      toDisplay.add(waitForKey);
    } 
  }
  
  private void printStatus(){
    println(roundNum);
    if(curRound!=null) println(curRound.getProbNum());
    println("skill level:"+skillLevel);
    println("time allotted"+time_allotted);
    println(distanceBubbleTravels);
    println(distanceBubbleTravels/float(time_allotted)*1000.0);
    //if(curBrick!=null) println("Brick Position: ("+curBrick.xpos+","+curBrick.ypos+")");
    //if(curProblem!=null) println("Current Problem: "+curProblem.getStimulus());
    println("Last Response Time: "+answered);
  }
  
  
  
  //

   private boolean outOfTime(){
    //print(curBrick.datum.beginDisp+"+"+time_allotted+" < "+millis());
    return time_allotted<=millis()-curBrick.datum.beginDisp;
  }
  
  
  private boolean answeredCorrect(){
    return curBrick.getAnswer().equals(curResponse);
  }
  public void removeBrick(){
     toDisplay.remove(curBrick);
     curBrick = null;
     //curProblem = null;
  }
  //TODO: create update function


  void newRound(){
    roundNum++;
    switch(roundNum){
      case 1:
        bg.pause();
        level1.loop();
        break;
      case 2:
        level1.close();
        level2.loop();
        break;
      case 3:
        level2.close();
        level3.loop();
        break;
    }
    if(sb.getScore()>=thresholdScore){
      //fr+=frameRateInc;
      time_allotted-=timeDec;//decrease by 500 ms
      skillLevel = distanceBubbleTravels/float(time_allotted)*1000.0;
      //frameRate(fr);
    }
    sb.reset();
  }
  
  //Creates correct number of rounds for the day
  private ArrayList<Round> setupRounds(){
    rounds = new ArrayList<Round>(roundsPerDay);
    for(int i=0; i<roundsPerDay; i++){
      Round round = new Round();
      rounds.add(round);
    }
    return rounds;
  }
  
  //When key is pressed it is sent
  //to the listener
  
}

//Problem
//Object that holds both the stimulus and the answer
class Problem{
  String stimulus;
  String answer;
    
  Problem(String stim, String ans){
    stimulus = stim;  
    answer = ans;
  }
  
  public String getStimulus(){
    return stimulus;
  }
  
  public String getAnswer(){
    return answer;
  }
  
  public boolean isAnswer(String attempt){
    return attempt == answer;
  }
}

//Round
//Object that holds all of the Problems for a round and 
//takes a random one from the list, keeping track of
//how many are left.
class Round{
  ArrayList<Problem> problems;
  float skillLevel;
  int score;
  int probNumber;

  Round(){
    //skillLevel = skill
    problems = setupProblems();
    score = 0;
    probNumber = 0;
    
  }

  void addScore(){
    score++;
  }

  int getScore(){
    return score;
  }

  boolean isEmpty(){
    return problems.isEmpty();
  }


  public Problem nextProblem(){
    if(problems.isEmpty()){
      //println("something went wrong. There are no more problems in this round");
      return null; 
    }
    int randIndx = (int)random(problems.size());
    Problem prob = problems.get(randIndx);
    problems.remove(randIndx);
    probNumber++;
    //println(probNumber);
    return prob;
  }

  public int getProbNum(){
    return probNumber;
  }

  ArrayList<Problem> setupProblems(){
      ArrayList<Problem> problems = new ArrayList<Problem>(14);
      if(gameType == 'A'){
        problems.add(addNewProb("6+29","35"));
        problems.add(addNewProb("8+36","44"));
        problems.add(addNewProb("9+47","56"));
        problems.add(addNewProb("3+56","59"));
        problems.add(addNewProb("4+65","69"));
        problems.add(addNewProb("6+72","78"));
        problems.add(addNewProb("2+84","86"));
        problems.add(addNewProb("25+2","27"));
        problems.add(addNewProb("38+3","41"));
        problems.add(addNewProb("43+7","50"));
        problems.add(addNewProb("57+5","62"));
        problems.add(addNewProb("64+9","73"));
        problems.add(addNewProb("75+8","83"));
        problems.add(addNewProb("87+4","91"));
      } else {
        problems.add(addNewProb("2+27","29"));
        problems.add(addNewProb("6+37","43"));
        problems.add(addNewProb("7+48","55"));
        problems.add(addNewProb("5+53","58"));
        problems.add(addNewProb("3+62","65"));
        problems.add(addNewProb("9+78","87"));
        problems.add(addNewProb("8+82","90"));
        problems.add(addNewProb("28+4","32"));
        problems.add(addNewProb("34+6","40"));
        problems.add(addNewProb("46+5","51"));
        problems.add(addNewProb("52+9","61"));
        problems.add(addNewProb("69+3","72"));
        problems.add(addNewProb("73+4","77"));
        problems.add(addNewProb("85+9","94"));
      }
      return problems;
  }
  
  Problem addNewProb(String stim, String ans){
    Problem prob = new Problem(stim,ans);
    return prob;
  }
}

//Scoreboard
//This is the scoreboard that is displayed.
//It needs to be signaled each time the score increases
//or it needs to be reset.
//TODO: Have it return the score to the data
class Scoreboard extends BoardObj{
  int score = 0;
  
  int scoreX = (displayWidth-boardWidth)/2+scorePadding;
  int scoreY = (displayHeight-boardHeight)/2+boardHeight-scoreHeight;
  
  void reset(){
    score = 0;
  }
  
  void incScore(){
    score++;
  }
  
  int getScore(){
    return score;  
  }
  
  @Override
  void display(){
    //for(int i=0;i<probsPerRound;i++){
      //pushStyle();
      //strokeWeight(5);
      
    image(pile_img, scoreX, scoreY-score*(scoreHeight-scorePadding), scoreWidth, score*scoreHeight);
      //}else{
        //noFill();
      //rect(scoreX, scoreY-i*(scoreHeight+scorePadding), scoreWidth, scoreHeight, 7);
      //popStyle();
    
  }
}

class SubmitButton extends ClickableObj{
  
  
  SubmitButton(int x, int y){
    xpos = x;
    ypos = y;
    objHeight = submitHeight;
    objWidth = submitWidth;
  }
  
  void display(){
    pushStyle();
    fill(200);
    textAlign(CENTER, CENTER);
    rect(xpos, ypos, objWidth, objHeight);
    textSize(18);
    fill(0);
    text("Submit", xpos+submitPadding, ypos, objWidth-2*submitPadding, objHeight); 
    popStyle();
  }
}

class TextField extends ClickableObj{
  boolean selected;
  String value = "";
  String label;

  TextField(String lab, boolean sel, int x, int y){
    objWidth = textFieldWidth;
    objHeight = textFieldHeight;
    selected = sel;
    xpos = x;
    ypos = y;
    label = lab;
  }

  String getValue(){
    return value;
  }

  void changeValue(char key){
    if(key==BACKSPACE){ 
      if(value.length()>0){
        value = value.substring(0, value.length()-1);
      }
    }  else if(key==TAB){
      //Switch to next thing?
    }else{
      value += key;
    }
  }

  boolean isSelected(){
    return selected;
  }

  void select(){
    selected = true;
  }

  void unselect(){
    selected = false;
  }

  void display(){
    pushStyle();
    if(selected){
      strokeWeight(3);
      stroke(81,120,213); 
    }
    textSize(32);
    pushStyle();
    fill(255);
    rect(xpos, ypos, textFieldWidth, textFieldHeight);
    popStyle();
    fill(0);
    textAlign(LEFT, CENTER);
    if(value.equals("")){
      pushStyle();
      fill(150);
      text(label, xpos+textPadding, ypos, textFieldWidth-2*textPadding, textFieldHeight);
      popStyle();
    }else{
      text(value, xpos+textPadding, ypos, textFieldWidth-2*textPadding, textFieldHeight);
    }
    popStyle();
  }
}

class Title extends BoardObj{
  String message;
  
  Title(String msg){
    message = msg;
  }
  
  void display(){
    pushStyle();
    textSize(40);
    textAlign(CENTER, CENTER);
    fill(100, 200);
    noStroke();
    rect((displayWidth-titleWidth)/2, (displayHeight-titleHeight)/2-1*titleHeight, titleWidth, titleHeight+titlePadding);
    fill(255,255,0);
    text(message, (displayWidth-titleWidth)/2+titlePadding, (displayHeight-titleHeight)/2-1*titleHeight, titleWidth-2*titlePadding, titleHeight);
    popStyle();
  }
}

