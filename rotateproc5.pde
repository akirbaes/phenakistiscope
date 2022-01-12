Boolean VIDEO_EXPORT = true;
String ffmpeg_path = "ffmpeg";

java.io.File folder;
PImage mainImage;
PImage centerImage;
ArrayList<PImage> previews = new ArrayList<PImage>();
String[] filenames;
int current_image=0;
int scaling = 4;
int clickx = 200;
int clicky = 300;

int centerx, centery;

int rotations = 16;
int current_rotation = 0;

PImage rotateSquare;
int leftborder;
int topborder;
int centersize;

PGraphics previewmask;
PImage cropMask;

PImage outputImage;
int outputsize;

int WIDE = 0;
int TIGHT = 1;
int crop_mode = TIGHT;

//int additional_crop = 0;
//int crop_x = 0;
//int crop_y = 0;
float crop_ratio=0;

ArrayList<PImage> rotateImages = new ArrayList<PImage>();

//void import_image(String droppedfile){
//  String basename = FilenameUtils.getBaseName(fileName);
//  String extension = FilenameUtils.getExtension(fileName);
//}

void generate_previews() {

  for (int i = 0; i < filenames.length; i++) {
    PImage previewImage = loadImage(filenames[i]);
    println("loading", filenames[i]);
    previewImage.resize(100, 100);
    previews.add(previewImage);
  }
}

void generate_center() {
  if (current_image<filenames.length) {
    mainImage = loadImage(filenames[current_image]);

    int c = int(min(mainImage.width, mainImage.height)/scaling);
    int cx = mainImage.width/2;
    int cy = mainImage.height/2;

    centersize = c;
    leftborder = cx-c/2;
    topborder = cy-c/2;

    centerImage = mainImage.get(leftborder, topborder, centersize, centersize);
    centerImage.resize(400, 400);
  }
}

void generate_rotations() {
  if (current_image<filenames.length) {
    int c = min(mainImage.width, mainImage.height);
    int cx = mainImage.width/2;
    int cy = mainImage.height/2;
    centerx = (clickx)*centersize/400+leftborder;
    centery = (clicky-100)*centersize/400+topborder;
    if (crop_mode==WIDE)
      outputsize = min(c+abs(centerx-cx)*2, c+abs(centery-cy)*2);
    else
      outputsize = min(c-abs(centerx-cx)*2, c-abs(centery-cy)*2);

    rotateSquare = mainImage.get(centerx-outputsize/2, centery-outputsize/2, outputsize, outputsize);
    //outputImage = rotateSquare.get();
    rotateSquare.resize(600, 600);
    
  }
}

PGraphics generate_mask(int size){
  return generate_mask(size, 3);
}
  
PGraphics generate_mask(int size, int cropsize){
  PGraphics pg = createGraphics(size,size);
  pg.beginDraw();
  pg.background(255);
  pg.fill(0);
  pg.stroke(255);
  pg.strokeWeight(0);
  pg.ellipseMode(CENTER);
  pg.ellipse(float(size)/2,float(size)/2,size-cropsize,size-cropsize);
  pg.endDraw();
  
  PGraphics pm = createGraphics(size,size);
  pm.beginDraw();
  pm.background(0);
  pm.endDraw();
  pm.mask(pg);
  return pm;
  
  //PImage mask = pm.get();
  ////createImage(600,600, ARGB);
  //mask.mask(pg);
  //return mask;
}



class ExportRotations extends Thread {
  String inputfile;
  PImage inputImage;
  int outputsize;
  int centerx;
  int centery;
  int rotations;
  String basename;
  float crop_ratio;
  public ExportRotations(String inputfile, PImage inputImage, int outputsize, int centerx, int centery, int rotations, float crop_ratio) {
    this.inputfile=inputfile; //filenames[current_image]
    this.inputImage = inputImage;
    System.out.println(crop_ratio);
    this.outputsize = int(ceil(outputsize*(1.0-crop_ratio))/2)*2;//outputsize;//
    this.centerx=centerx;
    this.centery=centery;
    this.rotations=rotations;
    this.basename = this.inputfile.split("\\.")[0];
    //this.crop_ratio = crop_ratio;
    current_image+=1;
  }
  Boolean captureProcess(String[] cmds) {
    //https://discourse.processing.org/t/create-and-run-bat-file-for-ffmpeg-code/33482/2
    //https://discourse.processing.org/t/monitoring-process-of-ffmpeg-in-processing/17950/8
    //https://stackoverflow.com/questions/14165517/processbuilder-forwarding-stdout-and-stderr-of-started-processes-without-blocki
    ProcessBuilder processBuilder = new ProcessBuilder(cmds).inheritIO();
    Process process;
    try {
      process = processBuilder.start();
      process.waitFor();
    }
    catch (Exception e) {
      e.printStackTrace();
      System.out.flush();
      return false;
    }
    System.out.flush();
    return true;
  }

  void ffmpeg_call() {
    String inputfilename = sketchPath(basename + File.separator + basename +"[%02d].jpg");
    String[] processCommands  = {ffmpeg_path, "-r", "12", "-f", "image2", "-s", String.format("%d", outputsize)+"x"+String.format("%d", outputsize), "-i", inputfilename, "-vcodec", "libx264", "-crf", "25", "-pix_fmt", "yuv420p", sketchPath(basename+".mp4"), "-y"};
    println((Object[])processCommands);
    if (captureProcess(processCommands))
      println("Saved video", basename+".mp4 !");
    else
      println("Could not save video", basename+".mp4 !");
  }

  //Works but no output visible
  //Process p = launch(processCommands);
  //try {
  //    int result = p.waitFor();
  //    println("the process returned " + result);
  //  }
  //  catch (InterruptedException e) {
  //    println(e);
  //  }

  //Doesn't work
  // try{
  //Process p = Runtime.getRuntime().exec(processCommands);
  // Runtime.getRuntime().exec(processCommands);
  // }
  // catch(Exception e){
  // println(e);
  // }


  public void run() {
    PGraphics pg=createGraphics(this.outputsize, this.outputsize);
    pg.beginDraw();
    //PImage mask = generate_mask(this.outputsize,int(this.outputsize*this.crop_ratio));
    PImage mask = generate_mask(this.outputsize);
    for (int i = 0; i<this.rotations; i++) {
      pg.background(255, 255, 255);
      pg.pushMatrix();
      pg.translate(this.outputsize/2, this.outputsize/2);
      pg.rotate(PI*2/this.rotations*i);
      //translate(-centerx*400/mainImage.width,-centery*400/mainImage.height);
      pg.translate(-this.centerx, -this.centery);
      //pg.image(outputImage,0,0);
      pg.image(this.inputImage, 0, 0);
      pg.popMatrix();
      pg.image(mask,0,0);

      File f = new File(basename);
      f.mkdir();
      String outputfilename = basename+File.separator+basename+"["+String.format("%02d", (i+1))+"]"+".jpg";
      
      int newsize = int(this.outputsize * (1.0-this.crop_ratio));
      int borders = int(this.crop_ratio*this.outputsize)/2;
      //pg.get(borders,borders,newsize,newsize).save(outputfilename);
      pg.save(outputfilename);
      println("Output", outputfilename);
      //fill(255,128,128);
      //rect(200,500,100,100);
      //fill(0);
      //text("Exporting...",208,550);
    }

    if (VIDEO_EXPORT)ffmpeg_call();
  }
}


void setup() {
  color(0, 255, 0);
  noFill();

  size(1000, 600);
  frameRate(30);
  folder = new java.io.File(dataPath(""));
  filenames = folder.list(new java.io.FilenameFilter() {
    @Override
      public boolean accept(File dir, String name) {
      return !name.equals(".DS_Store");
    }
  }
  );
  println(filenames.length + " files in specified directory");
  for (int i = 0; i < filenames.length; i++) {
    println(filenames[i]);
  }

  thread("generate_previews");
  previewmask = generate_mask(600);
  generate_center();
  generate_rotations();
  
}

void mouseWheel(MouseEvent event) {
  int e = event.getCount();
  if (mouseX>0 && mouseX<400 && mouseY>100 && mouseY<500) {
    scaling=max(1, scaling-event.getCount());
    generate_center();
    generate_rotations();
  } else if (mouseX>400 && mouseX<1000 && mouseY>0 && mouseY<600) {
    rotations=max(1, rotations-event.getCount());
    generate_rotations();
  }
}

void mouseClicked(MouseEvent event) {

  if (mouse_inbox(0, 100, 400, 400)) {
    if(event.getButton() == LEFT){
      generate_rotations();
      clickx=mouseX;
      clicky=mouseY;
    }
  }
  else if (mouse_inbox(400,0,1000,600))
  {
    int dist = int(sqrt((mouseX-700)*(mouseX-700)+(mouseY-300)*(mouseY-300)));
    int additional_crop = 300-(dist);//;
    previewmask = generate_mask(600,additional_crop*2);
    crop_ratio = float(additional_crop)/300.0;
  } else if (mouse_inbox(300, 500, 100, 100)) {
    new ExportRotations(filenames[current_image], mainImage, outputsize, centerx, centery, rotations, crop_ratio).start();
    generate_center();
    generate_rotations();
    previewmask = generate_mask(600);
    crop_ratio = 0;
  } else if (mouse_inbox(0, 0, 50, 100)) {
    current_image=max(0, current_image-1);
    generate_center();
    generate_rotations();
    previewmask = generate_mask(600);
    crop_ratio = 0;
  } else if (mouse_inbox(350, 0, 50, 100)) {
    current_image=current_image+1;
    generate_center();
    generate_rotations();
    previewmask = generate_mask(600);
    crop_ratio = 0;
  } else if (mouse_inbox(50, 500, 50, 50)) {
    scaling=max(1, scaling+1);
    generate_center();
    generate_rotations();
  } else if (mouse_inbox(50, 550, 50, 50)) {
    scaling=max(1, scaling-1);
    generate_center();
    generate_rotations();
  } else if (mouse_inbox(150, 500, 50, 50)) {
    rotations=max(1, rotations+1);
    generate_rotations();
  } else if (mouse_inbox(150, 550, 50, 50)) {
    rotations=max(1, rotations-1);
    generate_rotations();
  } 
  //else if (mouse_inbox(250, 500, 50, 50)) {
  //  crop_mode = WIDE;
  //  generate_rotations();
  //} else if (mouse_inbox(250, 550, 50, 50)) {
  //  crop_mode = TIGHT;
  //  generate_rotations();
  //}
}

void keyPressed() {
  if (key == ' ') {

    new ExportRotations(filenames[current_image], mainImage, outputsize, centerx, centery, rotations, crop_ratio).start();
    //export_rotations();
    //generate_previews();
    generate_center();
    generate_rotations();
  }
}


Boolean mouse_inbox(int left, int top, int width, int height) {
  return mouseX>left && mouseX<left+width && mouseY>top && mouseY<top+height;
}

void drawbox(int left, int top, int width, int height, String texts) {
  fill(128, 128, 128, 128);
  if (mouse_inbox(left, top, width, height))fill(255, 128, 128, 128);
  rect(left, top, width, height);
  fill(0);
  text(texts, left+8, top+height/2);
}



int coin = 0;

void draw() {
  background(255, 255, 255);
  fill(0, 255, 0);
  if (current_image<filenames.length) {

    pushMatrix();
    //for (int i = 0; i < rotations; i++) {
    translate(700, 300);
    rotate(PI*2/rotations*current_rotation);
    //translate(-centerx*400/mainImage.width,-centery*400/mainImage.height);
    translate(-300, -300);
    image(rotateSquare, 0, 0);
    //}
    popMatrix();




    image(centerImage, 0, 100);
    line(clickx, 100, clickx, clicky-4);
    line(clickx, 500, clickx, clicky+4);
    line(0, clicky, clickx-4, clicky);
    line(400, clicky, clickx+4, clicky);
    rect(clickx-4, clicky-4, 8, 8);
  }

  image(previewmask,400,0);
  coin = (coin+1)%2;
  current_rotation = (current_rotation + coin)%rotations;

  for (int i=max(0, current_image-1); i<previews.size(); i++) {
    image(previews.get(i), (i-current_image)*100+50, 0);
  }
  fill(0, 0, 0);
  text("Scale:", 0, 510);
  text(String.valueOf(scaling), 16, 550);
  text("Rotation:", 100, 510);
  text(String.valueOf(rotations), 108, 550);

  drawbox(50, 500, 50, 50, "+");
  drawbox(50, 550, 50, 50, "-");

  drawbox(150, 500, 50, 50, "+");
  drawbox(150, 550, 50, 50, "-");

  drawbox(300, 500, 100, 100, "Export");

  drawbox(0, 0, 50, 100, "Prev");
  drawbox(350, 0, 50, 100, "Next");

  text("Crop:", 200, 510);
  //if (crop_mode==TIGHT)
  //  text(String.valueOf("TIGHT"), 208, 550);
  //else
  //  text(String.valueOf("WIDE"), 208, 550);
  text(""+int(crop_ratio*100)+"%", 208, 550);

  //drawbox(250, 500, 50, 50, "WIDE");
  //drawbox(250, 550, 50, 50, "TIGHT");
  //ellipse(0,0,250,250);


  //fill(128,128,128);
  //if((mouseX>200 && mouseX<300 && mouseY>500))
  //  fill(255,128,128);
  //rect(200,500,100,100);
  //fill(0);
  //text("Export",208,550);
}
