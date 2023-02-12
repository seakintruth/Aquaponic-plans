// +-------------------------------------+
// Title:        Parametric One Piece Bell Siphon
// Version:      3.8
// Release Date: 2023-02-10 (ISO 8601)
// Author:       Jeremy D. Gerdes
// +-------------------------------------+
//
// Description:
//

/* [Bell Siphon] */
// How thick to make all walls (mm)
Wall_Thickness=1.2;
// larger diameter allows for a higher flow rate, bell and shrowd diameters are calculated from this (mm)
Standpipe_Inner_Diameter=32.1;
// Total standpipe height (mm)
Standpipe_Height=220.1;
// Total number of bell arches to allow flow into the bell, arches provide additional support durring print, but limit total flow into the bell
Bell_Cutout_Count=15;
// Width of bell arches to allow flow into the bell    
Bell_Cutout_Width=3.6;
// Height of bell arches to allow flow into the bell    
Bell_Cutout_Height=12.1;

/* [Printer Settings] */
// minimum object wall thickness shouldn't be less than 3x extruder_line_thickness this helps ensure a water tight seal (mm)
Extruder_Line_Thickness=1.2;
//Enter you're printer's max height. Will reduce standpipe height to match Maximum_Print_Height [not yet implemented] (mm)
Maximum_Print_Height=260;

/*[Generation Options]*/
Generate_Standpipe=true;
Generate_Bell=true;
Generate_Shroud=true;
Draft_Resolution=true;

// ----------------
// constants 
// ----------------
// add this constant to all other constants so they are excluded from the customizer
C_Null=0+0;
C_MIN_STANDPIPE_HEIGHT=65+C_Null;
face_resolution=40+C_Null;

// set minimum faces
if(Draft_Resolution) {
    face_resolution=face_resolution/2;
}

$fn=face_resolution;

//calculations
// force thickness to be at least 3 line thicknesses
actual_thickness = clip(Wall_Thickness,Extruder_Line_Thickness*3,Wall_Thickness+1) ;


/*
---------------------
Generate Standpipe
---------------------
*/

if (Generate_Standpipe) {
    // trim standpipe to funnel
    // ...........
    Cone_Height=Standpipe_Inner_Diameter; //+actual_thickness;
    
    difference()
    {
     //create stand pipe
    translate([0,0,Standpipe_Height/2])
        difference() {
            cylinder(h=Standpipe_Height,r=(Standpipe_Inner_Diameter+actual_thickness)/2, center=true);
            cylinder( h=Standpipe_Height,r=Standpipe_Inner_Diameter/2,center=true);
            };
        translate([0,0,Standpipe_Height]) 
        {
            cone_solid (Cone_Height,actual_thickness,true);   
        };
    };

    // stand pipe funnel
    translate([0,0,Standpipe_Height-actual_thickness]) 
    {
        difference(){
            //union() {
            cone_hollow (Cone_Height,actual_thickness,true);   
                
                
            //};
            cylinder(h=Standpipe_Height*10,r=(Standpipe_Inner_Diameter+actual_thickness)/2, center=true);
            }
    };    
}


/*
--------------------- 
Generate Bell
---------------------
*/
if(Generate_Bell){
    //calculations
    bell_inner_diameter=2*Standpipe_Inner_Diameter+2*actual_thickness;
    bell_cone_height=0.8*bell_inner_diameter;

    //create bell pipe
    #difference(){
        union(){
            translate([0,0,Standpipe_Height/2]){
                cylinder(h=Standpipe_Height,r=bell_inner_diameter/2,center=true);
            };
            //Create bell top
            translate([0,0,Standpipe_Height]) 
            {
                cone_hollow (bell_cone_height,actual_thickness,true);               
            };
        };
        { 
            union(){
                {   
                    // bell cutout arches
                    generate_cutouts(Bell_Cutout_Width,Bell_Cutout_Height,Bell_Cutout_Count);
                };
                {           
                translate([0,0,Standpipe_Height+actual_thickness]) {
                   cone_solid(bell_cone_height,actual_thickness,true);    } 
                };
                {
                    translate([0,0,Standpipe_Height/2]){
                        // remove inner diameter of bell
                        //scale(1,1,1.01){
                        cylinder(h=Standpipe_Height,r=(bell_inner_diameter-actual_thickness)/2,center=true                  );
                    };
                };
                {  
                    translate([0,0,Standpipe_Height/2]){
                    // remove inner diameter of bell
                    cylinder(h=Standpipe_Height,r=(bell_inner_diameter-actual_thickness)/2,center=true);
                    };
                };
            };
        };
    }
    // Add the bell cap
    #translate([0,0,Standpipe_Height]) 
        { cone_hollow (bell_cone_height,actual_thickness); }    
}

/*
---------------------
Generate shroud
---------------------
*/
if(Generate_Shroud){
    
}
// +------------------------------------+
// Function: Clip
//
// Description:
//
// - Clips an input value, to a minimum and maximum value.
//
//   x_min <= x <= x_max
// 
// Parameters:
//
// - x
//   Input value.
//
// - x_min
//   Minimal value constraint. Any x less than x_min, is set to x_min. 
//
// - x_max
//   Maximum value constraint. Any x greater than x_max, is set to x_max.
//
// +------------------------------------+

function clip ( x, x_min, x_max ) = ( x < x_min ) ? x_min : ( x > x_max ) ? x_max : x;

module cone_solid ( height, thickness, f_invert = false)
{
    // make 45 degree hollow cone with thickness
    // set base to create 45 degree cone
    base=height*2;
    if(f_invert) {
        rotate([0,180,0]) difference() {
            cylinder(r1=base/2, r2=0, h=height);
        }
    ;} else {
            cylinder(r1=base/2, r2=0, h=height)    ;}    
}
module cone_hollow ( height, thickness, f_invert = false)
{
    // make 45 degree hollow cone with thickness
    // set base to create 45 degree cone
    base=height*2;
    if(f_invert) {
        rotate([0,180,0]) difference() {
            cylinder(r1=base/2, r2=0, h=height);
            cylinder(r1=base/2-(thickness), r2=0, h=height-thickness);
        }
    ;} else {
        difference() {
            cylinder(r1=base/2, r2=0, h=height);
            cylinder(r1=base/2-(thickness), r2=0, h=height-thickness);
        }
    ;}
}

module polar_array( radius, count, axis ) {
    for ( i= [1:360/count:360])  {
        rotate(a=i,v=axis) 
        translate([radius,0,0 ] )
        children();       
    }
}

module generate_cutouts(co_width,co_height,co_count){
// co_count might be a ratio 

//constants
C_NULL=0+0;
cutout_extrude_length=800+C_NULL;


rotate(a=-1,v=[0,0,1]) 
  polar_array(0,co_count,[0,0,1]) 
    union(){
      // start with a cube
      cube([cutout_extrude_length,co_width,co_height]);
      // add a pritable cap
      translate([cutout_extrude_length,0,0])
        rotate(a=-90,v=[0,1,0]) 
          linear_extrude(cutout_extrude_length) 
            polygon(points = [ [co_height,0],[co_height,co_width],[    co_height+(co_width/2),co_width/2]]);
  }
}
