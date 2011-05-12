class KinectElevation {
    
  float deg = 0; // Start at _ degrees

  float[] depthLookUp = new float[2048];

  int NOISE_SEED = 23;
  float NOISE_SCALE = 0.08f;
  int BLUR_RADIUS = 4;
  float WATER_LEVEL = 6;
  
  int DIMx=80;
  int DIMz=80;

  int[] el_gray;
  float[] elevation_last;
  float[] elevation;
  float[] el_noise;
  
  Vec2D highest_point = new Vec2D();
  int highest_point_el = 0;
  
  int KINECT_W = 640;
  int KINECT_H = 480;
  
  int SCALE_X = KINECT_W/DIMx;
  int SCALE_Z = KINECT_H/DIMz;
  
  int MAX_Y = 1700;
  int MIN_Y = 1050;
  int RANGE_Y = MAX_Y - MIN_Y;
  int SCALE_Y = 8;

  KinectElevation(int dimx, int dimz) {
    DIMx = dimx;
    DIMz = dimz;
    SCALE_X = KINECT_W/DIMx;
    SCALE_Z = KINECT_H/DIMz;
    
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
    
    kinect.start();
    kinect.enableDepth(true);
    kinect.processDepthImage(false);
    kinect.enableRGB(false);
    kinect.enableIR(false);
    kinect.tilt(deg);
    
    // Lookup table for all possible depth values (0 - 2047)
    for (int i = 0; i < depthLookUp.length; i++) {
      depthLookUp[i] = rawDepthToMeters(i);
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
        el_noise[i++] = noise(x * NOISE_SCALE, z * NOISE_SCALE) * 15;
      }
    }
  }

  void setBlur (int _blur) {
    BLUR_RADIUS = _blur;
  }
  void setScaleY (int _scale) {
    SCALE_Y = _scale;
  }
  void setWaterLevel (float _waterlevel) {
    WATER_LEVEL = _waterlevel;
  }

  float[] getElevations() {
    // Create the grayscale elevation map
    int[] depth = kinect.getRawDepth();
    int i = 0;
    highest_point_el = 0;
    for (int z = 0; z < DIMz; z++) {
      for (int x = 0; x < DIMx; x++) {
        int e = 2047 - depth[(z*SCALE_Z*KINECT_W) + (x*SCALE_X)];
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
      float el = blurred[i] * SCALE_Y;
      el = lerp(elevation_last[i], el, .05) + el_noise[i] - WATER_LEVEL;
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
//    int r[]=new int[wh];
//    int g[]=new int[wh];
    int b[]=new int[wh];
//    int rsum,gsum,
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
//      rsum=gsum=
      bsum=0;
      for(i=-radius;i<=radius;i++){
        p=pix[yi+min(wm,max(i,0))];
//        rsum+=(p & 0xff0000)>>16;
//        gsum+=(p & 0x00ff00)>>8;
        bsum+= p & 0x0000ff;
      }
      for (x=0;x<w;x++){
      
//        r[yi]=dv[rsum];
//        g[yi]=dv[gsum];
        b[yi]=dv[bsum];
  
        if(y==0){
          vmin[x]=min(x+radius+1,wm);
          vmax[x]=max(x-radius,0);
         } 
         p1=pix[yw+vmin[x]];
         p2=pix[yw+vmax[x]];
  
//        rsum+=((p1 & 0xff0000)-(p2 & 0xff0000))>>16;
//        gsum+=((p1 & 0x00ff00)-(p2 & 0x00ff00))>>8;
        bsum+= (p1 & 0x0000ff)-(p2 & 0x0000ff);
        yi++;
      }
      yw+=w;
    }
    
    for (x=0;x<w;x++){
//      rsum=gsum=
      bsum=0;
      yp=-radius*w;
      for(i=-radius;i<=radius;i++){
        yi=max(0,yp)+x;
//        rsum+=r[yi];
//        gsum+=g[yi];
        bsum+=b[yi];
        yp+=w;
      }
      yi=x;
      for (y=0;y<h;y++){
//        pix[yi]=0xff000000 | (dv[rsum]<<16) | (dv[gsum]<<8) | dv[bsum];
        pix[yi]=dv[bsum];
        if(x==0){
          vmin[y]=min(y+radius+1,hm)*w;
          vmax[y]=max(y-radius,0)*w;
        } 
        p1=x+vmin[y];
        p2=x+vmax[y];
  
//        rsum+=r[p1]-r[p2];
//        gsum+=g[p1]-g[p2];
        bsum+=b[p1]-b[p2];
  
        yi+=w;
      }
    }
    
    return pix;
  
  }

  
}

