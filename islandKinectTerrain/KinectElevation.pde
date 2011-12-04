class KinectElevation {
    
  float deg = 0; // Start at _ degrees

  float[] depthLookUp = new float[2048];

  int NOISE_SEED = 23;
  float NOISE_AMP = 360;
  float NOISE_SCALE = 0.08f;
  
  int BLUR_RADIUS = 2;
  float WATER_LEVEL = 40;
  
  int KINECT_W = 640;
  int KINECT_H = 480;
  
  int DIMx = 120;
  int DIMz = 90;

  int[] el_gray;
  float[] elevation_last;
  float[] elevation;
  float[] el_noise;
  
  Vec2D highest_point = new Vec2D();
  int highest_point_el = 0;  

//  ControlP5 controlP5;
  ControlWindow controlWindow;

  int MAX_X = 590;
  int MIN_X = 174;
  int RANGE_X = MAX_X - MIN_X;
  int MAX_Z = 420;
  int MIN_Z = 110;
  int RANGE_Z = MAX_Z - MIN_Z;
  
  int SCALE_X = RANGE_X/DIMx;
  int SCALE_Z = RANGE_Z/DIMz;

  int MAX_Y = 1139;
  int MIN_Y = 1091;
  int RANGE_Y = MAX_Y - MIN_Y;
  float SCALE_Y = 6.5;
  float CHANGE_SPEED = .05;



  KinectElevation(int dimx, int dimz) {
    DIMx = dimx;
    DIMz = dimz;
    SCALE_X = RANGE_X/DIMx;
    SCALE_Z = RANGE_Z/DIMz;
    
    el_gray = new int[DIMx*DIMz];
    elevation_last = new float[DIMx*DIMz];
    elevation = new float[DIMx*DIMz];
    for (int i = 0; i<el_gray.length; i++ ) {
      el_gray[i] = 0;
      elevation_last[i] = 0.0;
      elevation[i] = 0.0;
    }

    el_noise = new float[DIMx*DIMz];
    setNoiseSeed(NOISE_SEED);
    
//    kinect.start();
//    kinect.enableDepth(true);
//    kinect.processDepthImage(false);
//    kinect.enableRGB(false);
//    kinect.enableIR(false);
//    kinect.tilt(deg);
    NativeKinect.init();
    NativeKinect.start();

    // Lookup table for all possible depth values (0 - 2047)
    for (int i = 0; i < depthLookUp.length; i++) {
      depthLookUp[i] = rawDepthToMeters(i);
    }


  
  }
  
  void setupControls(ControlP5 controlP5) {
    controlWindow = controlP5.addControlWindow("island", 0, 0, 1200, 75);
    controlWindow.hideCoordinates();
    controlWindow.setBackground(color(40));
    Controller mySlider = controlP5.addSlider("NOISE_SEED",   0, 100, 10, 10, 300, 15);
    mySlider.setWindow(controlWindow);
    mySlider.setValue(NOISE_SEED);
    Controller mySlider6 = controlP5.addSlider("NOISE_AMP",   0, 1000, 10, 30, 300, 15);
    mySlider6.setWindow(controlWindow);
    mySlider6.setValue(NOISE_AMP);
    Controller mySlider2 = controlP5.addSlider("NOISE_SCALE", 0, 2,   10, 50, 300, 15);
    mySlider2.setWindow(controlWindow);
    mySlider2.setValue(NOISE_SCALE);

    Controller mySlider3 = controlP5.addSlider("BLUR_RADIUS",   0, 10, 400, 10, 300, 15);
    mySlider3.setWindow(controlWindow);
    mySlider3.setValue(BLUR_RADIUS);
    Controller mySlider4 = controlP5.addSlider("SCALE_Y",       0, 20, 400, 30, 300, 15);
    mySlider4.setWindow(controlWindow);
    mySlider4.setValue(SCALE_Y);
    Controller mySlider5 = controlP5.addSlider("WATER_LEVEL",   0, 500, 400, 50, 300, 15);
    mySlider5.setWindow(controlWindow);
    mySlider5.setValue(WATER_LEVEL);

    Controller miny = controlP5.addSlider("MIN_Y",   0, 2047, 800, 10, 300, 15);
    miny.setWindow(controlWindow);
    miny.setValue(MIN_Y);
    Controller maxy = controlP5.addSlider("MAX_Y",   0, 2047, 800, 30, 300, 15);
    maxy.setWindow(controlWindow);
    maxy.setValue(MAX_Y);
    Controller changespeed = controlP5.addSlider("CHANGE_SPEED", 0, 1, 800, 50, 300, 15);
    changespeed.setWindow(controlWindow);
    changespeed.setValue(CHANGE_SPEED);
  }
  
  void setThis(String name, float value) {
    if (name == "NOISE_SEED") {
      setNoiseSeed((int)value);
    }
    if (name == "NOISE_SCALE") {
      setNoiseScale(value);
    }
    if (name == "BLUR_RADIUS") {
      BLUR_RADIUS = (int)value;
    }
    if (name == "SCALE_Y") {
      SCALE_Y = value;
    }
    if (name == "WATER_LEVEL") {
      WATER_LEVEL = value;
    }
    if (name == "NOISE_AMP") {
      NOISE_AMP = value;
      setNoiseScale(NOISE_SCALE);
    }
    if (name == "MIN_Y") {
      MIN_Y = (int)value;
      MIN_Y = min(MAX_Y-5, MIN_Y);
      RANGE_Y = MAX_Y - MIN_Y;
    }
    if (name == "MAX_Y") {
      MAX_Y = (int)value;
      MAX_Y = max(MIN_Y+5, MAX_Y);
      RANGE_Y = MAX_Y - MIN_Y;
    }
    if (name == "CHANGE_SPEED") {
      CHANGE_SPEED = value;
    }
  }
    
  void setNoiseSeed (int _seed) {
    NOISE_SEED = _seed;
    noiseSeed(NOISE_SEED);
    setNoiseScale(NOISE_SCALE);
  }
  void setNoiseScale (float _scale) {
    NOISE_SCALE = _scale;
    for (int z = 0, i = 0; z < DIMz; z++) {
      for (int x = 0; x < DIMx; x++) {
        el_noise[i++] = noise(x * NOISE_SCALE, z * NOISE_SCALE) * NOISE_AMP - NOISE_AMP/2;
      }
    }
  }

//  void setBlur (int _blur) {
//    BLUR_RADIUS = _blur;
//  }
//  void setScaleY (int _scale) {
//    SCALE_Y = _scale;
//  }
//  void setWaterLevel (float _waterlevel) {
//    WATER_LEVEL = _waterlevel;
//  }

  float[] getElevations() {
    // Create the grayscale elevation map
    short[] depth = NativeKinect.getDepthMapRaw();
    int i = 0;
    highest_point_el = 0;
    for (int z = 0; z < DIMz; z++) {
      for (int x = 0; x < DIMx; x++) {
        int e = 2047 - depth[(z*SCALE_Z+MIN_Z)*KINECT_W + (x*SCALE_X+MIN_X)];
        e = max(e, MIN_Y);
        e = min(e, MAX_Y);
        e = floor(float(e - MIN_Y) / RANGE_Y * 256);
        el_gray[i] = e;

        if (e > highest_point_el) {
          highest_point.x = x;
          highest_point.y = z;
          highest_point_el = e;
        }

        i++;
      }
    }
  
    // Blur the grayscale
    int[] blurred = fastblur(el_gray, BLUR_RADIUS);
    
    // Scale up to elevation
    for (i = 0; i<elevation.length; i++) {
      float el = blurred[i] * SCALE_Y - WATER_LEVEL;
      if (el > 10) el += el_noise[i];
      el = lerp(elevation_last[i], el, CHANGE_SPEED);
      elevation[i] = el;
    }
    elevation_last = elevation;
    return elevation;
  }
  
  Vec2D getHighestPoint() {
    return highest_point;
  }
  
  float rawDepthToMeters(int depthValue) {
    if (depthValue < 2047) {
      return (float)(1.0 / ((double)(depthValue) * -0.0030711016 + 3.3309495161));
    }
    return 0.0f;
  }

  float rawDepthToElevation(int depthValue) {
    if (depthValue < 2047) {
      return (float)(1.0 / ((double)(depthValue) * -0.0030711016 + 3.3309495161));
    }
    return 0.0f;
  }


  int[] fastblur(int[] input, int radius){
    
    // Forked from http://incubator.quasimondo.com/processing/superfastblur.pde
    // Super Fast Blur v1.1
    // by Mario Klingemann <http://incubator.quasimondo.com>
  
    if (radius<1){
      return input;
    }
    int w = DIMx;
    int h = DIMz;
    int wm=w-1;
    int hm=h-1;
    int wh=w*h;
    int div=radius+radius+1;
    int b[]=new int[wh];
    int bsum,x,y,i,p,p1,p2,yp,yi,yw;
    int vmin[] = new int[max(w,h)];
    int vmax[] = new int[max(w,h)];
    int[] pix = input;
    int dv[]=new int[256*div];
    for (i=0;i<256*div;i++){
      dv[i]=(i/div); 
    }
    
    yw=yi=0;
   
    for (y=0;y<h;y++){
      bsum=0;
      for(i=-radius;i<=radius;i++){
        p=pix[yi+min(wm,max(i,0))];
        bsum+= p & 0x0000ff;
      }
      for (x=0;x<w;x++){
        b[yi]=dv[bsum];
  
        if(y==0){
          vmin[x]=min(x+radius+1,wm);
          vmax[x]=max(x-radius,0);
         } 
         p1=pix[yw+vmin[x]];
         p2=pix[yw+vmax[x]];
        bsum+= (p1 & 0x0000ff)-(p2 & 0x0000ff);
        yi++;
      }
      yw+=w;
    }
    
    for (x=0;x<w;x++){
      bsum=0;
      yp=-radius*w;
      for(i=-radius;i<=radius;i++){
        yi=max(0,yp)+x;
        bsum+=b[yi];
        yp+=w;
      }
      yi=x;
      for (y=0;y<h;y++){
        pix[yi]=dv[bsum];
        if(x==0){
          vmin[y]=min(y+radius+1,hm)*w;
          vmax[y]=max(y-radius,0)*w;
        } 
        p1=x+vmin[y];
        p2=x+vmax[y];
  
        bsum+=b[p1]-b[p2];
  
        yi+=w;
      }
    }
    
    return pix;
  
  }

  
}

