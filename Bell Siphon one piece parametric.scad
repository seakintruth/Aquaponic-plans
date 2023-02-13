// +-------------------------------------+
// Title:        Parametric One Piece Bell Siphon
// Version:      0.9
// Release Date: 2023-02-12 (ISO 8601)
// Author:       Jeremy D. Gerdes
// +-------------------------------------+
//
// Description:
//

/* [Bell Siphon] */
// How thick to make all walls (mm)
Wall_Thickness=1.8;
/* [Stand Pipe] */
// larger diameter allows for a higher flow rate, bell and shrowd diameters are calculated from this (mm)
Standpipe_Inner_Diameter=32.1;
// Total standpipe height (mm)
Standpipe_Height=220.1;
// Total number of bell arches to allow flow into the bell, arches provide additional support durring print, but limit total flow into the bell, Maximum_Print_Height can override this value (mm)  
/* [Bell] */
// Number of inflow arches at the bottom of the bell (mm)
Bell_Cutout_Count=17;
// Width of inflow arches on the bell    
Bell_Cutout_Width=6;
// Height of the rectangle portion for the inflow arches on the bell
Bell_Cutout_Height_Rectangle=12.1;
/* [Shroud] */
// Number of inflow arches per row of the shrowd(mm)
Shroud_Cutout_Count_per_Row=15;
// Width of inflow cuts on the shrowd
Shroud_Cutout_Width=4.1;
// Height of the rectangle portion for the inflow cuts on the shrowd
Shroud_Cutout_Height_Rectangle=20.1;
// Number of rows of inflow cuts from the bottom up
Shroud_Inflow_Rows=7;

/* [Printer Settings] */
// minimum object wall thickness shouldn't be less than 3x extruder_line_thickness this helps ensure a water tight seal (mm)
Extruder_Line_Thickness=1.6;
//Enter you're printer's max height. Will reduce object's total height to match Maximum_Print_Height [not yet implemented] (mm)
Maximum_Print_Height=260;

/*[Support Structure]*/
// Supports help fix the standpipe in place
Support_Width = 3;
//
Support_Beam_Count = 3;
/*
Optionally Generate inverted supports to hold the standpipe in place
*/


/*[Generation Options]*/
Generate_Standpipe=true;
Generate_Bell=true;
Generate_Shroud=true;
// Supports fix the standpipe to the bell or shroud, so a standpipe and either the bell or shroud must be generated prior to generating supports.

Generate_Support=true;
// fn is the default Number of Faces for each object. This should be an even number 4 or more and less than 128.
$fn=45;
// ----------------
// constants 
// ----------------
// add this constant to all other constants so they are excluded from the customizer
C_Null=0+0;
C_MIN_STANDPIPE_HEIGHT=65+C_Null;
C_MIN_FN=4+C_Null;
C_MAX_FN=200+C_Null;
C_Min_Shroud_Inflow_Rows=1+C_Null;
C_Support_Length = 4*Standpipe_Inner_Diameter+C_Null;

/* this doesn't work as "The value for a regular variable is assigned at compile time and is thus static for all calls."
// set minimum faces
let($fn=(2*floor((1+clip($fn,C_MIN_FN,C_MAX_FN))/2)));

we would have to start using the fn= argument of everything and use our own variable for this to work.
https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Other_Language_Features#$fa,_$fs_and_$fn
*/

//calculations
// force thickness to be at least 3 line thicknesses
actual_thickness = clip(Wall_Thickness,Extruder_Line_Thickness*3,Wall_Thickness+1);
// Set max inflow rows to be less than expected height of object.
Max_Shroud_Inflow_Rows=Standpipe_Height/(((Shroud_Cutout_Height_Rectangle+Shroud_Cutout_Width)*1.2))-2+C_Null;
let(Shroud_Inflow_Rows=clip(Shroud_Inflow_Rows,C_Min_Shroud_Inflow_Rows,Max_Shroud_Inflow_Rows));
Cone_Height=Standpipe_Inner_Diameter; //+actual_thickness;
//bell calculations
bell_inner_diameter=2*Standpipe_Inner_Diameter+2*actual_thickness;
bell_cone_height=0.8*bell_inner_diameter;
/*
---------------------
Generate Standpipe
---------------------
*/

if (Generate_Standpipe) {
    union(){
        //create stand pipe
        translate([0,0,Standpipe_Height/2])
            difference() {
                hollow_pipe(Standpipe_Height,Standpipe_Inner_Diameter,actual_thickness);
                translate([0,0,Standpipe_Height/2]) rotate([0,180,0]) 
                    cylinder(r1=(Cone_Height*2)/2-(actual_thickness), r2=0, h=Cone_Height-actual_thickness);
           };
            //create funnel cone
            translate([0,0,Standpipe_Height])
            difference() {
                cone_hollow (Cone_Height,actual_thickness,true);   
                cylinder(h=Standpipe_Height,r=(Standpipe_Inner_Diameter)/2, center=true);
            };
    };
};
/*
--------------------- 
Generate Bell
---------------------
*/
if(Generate_Bell){

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
                    generate_cutouts(Bell_Cutout_Width,Bell_Cutout_Height_Rectangle,Bell_Cutout_Count);
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
// Add bell Plate to join standpipe
if (Generate_Standpipe && Generate_Bell) {
    translate([0,0,actual_thickness/4])  hollow_pipe(height = actual_thickness/2, inner_diameter = Standpipe_Inner_Diameter, thickness = (bell_inner_diameter/2)+actual_thickness);
};
/*
---------------------
Generate shroud
---------------------
// Number of inflow arches per row of the shrowd(mm)
Shroud_Cutout_Count_per_Row=25;
// Width of inflow cuts on the shrowd
Shroud_Cutout_Width=5;
// Height of the rectangle portion for the inflow cuts on the shrowd
Shroud_Cutout_Height_Rectangle=12.1;
// Number of rows of inflow cuts from the bottom up
Shroud_Inflow_Rows=10;
*/
if(Generate_Shroud){
    #difference() {
        // Generate the shroud
        translate([0,0,Standpipe_Height/2]){
            hollow_pipe(Standpipe_Height,bell_inner_diameter+actual_thickness+Standpipe_Inner_Diameter/2,actual_thickness);
        };
        // Generate cutouts for the shroud    
        vertical_array(
            Shroud_Inflow_Rows,
            (Shroud_Cutout_Height_Rectangle+Shroud_Cutout_Width)*1.2,
            180/Shroud_Cutout_Count_per_Row
        ) generate_stacked_cutouts(
            Shroud_Cutout_Width,Shroud_Cutout_Height_Rectangle,Shroud_Cutout_Count_per_Row
        );
    }
}

if((Generate_Standpipe && Generate_Bell) || (Generate_Standpipe && Generate_Shroud)){
    difference() {
        if (Generate_Shroud) {
            // support out to the shroud remove remaining
            difference(){
                generate_support(Support_Beam_Count,C_Support_Length,Support_Width);
                hollow_pipe(height = Standpipe_Height*10, inner_diameter = (bell_inner_diameter+2*actual_thickness+Standpipe_Inner_Diameter/2), thickness = 4*Standpipe_Inner_Diameter);
            }
        } else {  
        // support out to the bell remove remaining
            difference(){
                generate_support(Support_Beam_Count,C_Support_Length,Support_Width);
                hollow_pipe(height = Standpipe_Height*10, inner_diameter = (bell_inner_diameter+2*actual_thickness), thickness = 4*Standpipe_Inner_Diameter);
            }
        };
        {
            union(){
                cylinder(h = Standpipe_Height*2, r = Standpipe_Inner_Diameter/2);
                translate([0,0,Standpipe_Height+Standpipe_Inner_Diameter*50]){
                    cube(Standpipe_Inner_Diameter*100,center=true);
                };
            };
        };
    };
}

module generate_support(count,length,width){
    vertical_array(occurance = 9, distance = C_Support_Length/2, rotation_degrees = 180/3){
        rotate([180,0,0]){
            polar_array(radius = 0, count = count, axis = [0,0,1]){
                rotate([0,45,0]) {
                        cylinder(h = length, r = width);
                };
            }
        }
    }
}
// +------------------------------------+
// Functions and macros
// +------------------------------------+
//: Clip :
// Description:
// - Clips an input value, to a minimum and maximum value.
//   x_min <= x <= x_max
// Parameters:
// - x
//   Input value.
// - x_min
//   Minimal value constraint. Any x less than x_min, is set to x_min. 
// - x_max
//   Maximum value constraint. Any x greater than x_max, is set to x_max.
//  for conditional testing with ? see: https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Conditional_and_Iterator_Functions#Conditional_?_:
// +------------------------------------+

function clip ( x, x_min, x_max ) = ( x < x_min ) ? x_min : ( x > x_max ) ? x_max : x;

module vertical_array( occurance, distance, rotation_degrees ) {
    for ( i= [1:1:occurance])  {
        translate([0,0,distance*i]) 
            rotate(a=rotation_degrees*i,v=[0,0,1])
                children();
    }
}

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
    cutout_extrude_length=10000;


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

//usage:
//vertical_array(20,20,15) generate_stacked_cutouts(cutout_width,cutout_height,cutout_count);

module generate_stacked_cutouts(cutout_width,cutout_height,cutout_count){
  //constants
  // extrude the cutouts far more than is needed...
  cutout_extrude_length=10000;
    // drop the bottom cutout to z0
    translate([0,0,-1*(cutout_height+2*cutout_width)]){
        polar_array(0,cutout_count,[0,0,1]) {
            union(){
            // start with a cube
                cube([cutout_extrude_length,cutout_width,cutout_height]);
                // add a pritable cap
                translate([cutout_extrude_length,0,0])
                    rotate(a=-90,v=[0,1,0]) 
                    linear_extrude(cutout_extrude_length) 
                        polygon(points = [ [cutout_height,0],[cutout_height,cutout_width],[cutout_height+(cutout_width/2),cutout_width/2]]);
                // add a pritable bottom cap
                translate([0,0,cutout_height])
                    rotate(a=90,v=[0,1,0]) 
                    linear_extrude(cutout_extrude_length) 
                        polygon(points = [ [cutout_height,0],[cutout_height,cutout_width],[    cutout_height+(cutout_width/2),cutout_width/2]]);
            }
        }
    } 
}

module hollow_pipe(height,inner_diameter,thickness){
    difference() {
        cylinder(h=height,r=(inner_diameter+thickness)/2, center=true);
        cylinder( h=height,r=inner_diameter/2,center=true);
    };
}
