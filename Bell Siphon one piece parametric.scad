// +-------------------------------------------------+
// Title:           Parametric One Piece Bell Siphon
// Version:         0.93
// Release Date:    2023-02-16 (ISO 8601)
// Author:          Jeremy D. Gerdes
// Version Control: 
// License: This work is released with CC0 into the public domain.
// https://creativecommons.org/publicdomain/zero/1.0/
// 
// Todo:         1) Add snorkle with bucket inside the shroud (if siphon lock needs assistance to break)
//               2) (TESTING) Add Treads to the bottom of the standpipe, and corresponding hull connection.   
// +--------------------------------------------------+
//
// Description:
//
/* [Bell Siphon] */
// How thick to make all walls (mm) except shroud wall will be 1/2 this thickness
Wall_Thickness=1.8;
/* [Stand Pipe] */
// larger diameter allows for a higher flow rate, bell and shrowd diameters are calculated from this (mm)
Standpipe_Inner_Diameter=32.1;
// Cone Heigth as a percentage of standpipe inner diammeter 1 = 100 %
Cone_Height_Factor=1.18;
// Total standpipe height (mm)
Standpipe_Height=198.1;
// Total number of bell arches to allow flow into the bell, arches provide additional support durring print, but limit total flow into the bell, Maximum_Print_Height can override this value (mm)  
/* [Bell] */
// Number of inflow arches at the bottom of the bell (mm)
Bell_Cutout_Count=17;
// Width of inflow arches on the bell    
Bell_Cutout_Width=6;
// Height of the rectangle portion for the inflow arches on the bell
Bell_Cutout_Height_Rectangle=12.1;
/* [Shroud] */
// Number of inflow arches per row of the shrowd - for more of a screen use 80
Shroud_Cutout_Count_per_Row=25;
// Width of inflow cuts on the shrowd - for more of a screen use 1.6 mm
Shroud_Cutout_Width=2.8;
// Height of the rectangle portion for the inflow cuts on the shrowd  - for more of a screen use 8 mm
Shroud_Cutout_Height_Rectangle=20.1;
// Number of rows of inflow cuts from the bottom up  - for more of a screen use 16
Shroud_Inflow_Rows=7;

/* [Printer Settings] */
// minimum object wall thickness shouldn't be less than 3x extruder_line_thickness this helps ensure a water tight seal (mm)
Extruder_Line_Thickness=0.6;
//Enter you're printer's max height. Will reduce object's total height to match Maximum_Print_Height [not yet implemented] (mm)
Maximum_Print_Height=260;

/*[Support Structure]*/
// Recommend 3.2 Supports help fix the standpipe in place, if this is too wide then flow will be restricted too much to create a siphon (mm)
Support_Width = 3.2;
// Beam Count Recommend between 2 and 6
Support_Beam_Count = 3;
//Row Count Recommend between 2 and 4
Support_Row_Count = 4;
let(Support_Row_Count = Support_Row_Count+1);
/*
Optionally Generate inverted supports to hold the standpipe in place
*/
/*[Generation Options]*/
Generate_Standpipe=true;
Generate_Bell=true;
Generate_Shroud=true;
Generate_Bulkhead_Connection=true;
// Supports fix the standpipe to the bell or shroud, so a standpipe and either the bell or shroud must be generated prior to generating supports.
Generate_Support=true;
// fn is the default Number of Faces for each object. This should be an even number 4 or more and less than 128.
$fn=30;
// ----------------
// constants 
// ----------------
// add this constant to all other constants so they are excluded from the customizer
C_Null=0+0;
C_MIN_STANDPIPE_HEIGHT=65+C_Null;
C_MIN_FN=4+C_Null;
C_MAX_FN=200+C_Null;
C_Min_Shroud_Inflow_Rows=1+C_Null;
/* this doesn't work as "The value for a regular variable is assigned at compile time and is thus static for all calls."
// set minimum faces
let($fn=(2*floor((1+clip($fn,C_MIN_FN,C_MAX_FN))/2)));
we would have to start using the fn= argument of everything and use our own variable for this to work.
https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Other_Language_Features#$fa,_$fs_and_$fn
*/
//calculations
// force thickness to be at least 3 line thicknesses
actual_thickness = clip(Wall_Thickness,Extruder_Line_Thickness*3,Wall_Thickness+1);
actual_Bell_Cutout_Height_Rectangle = 
    ( Generate_Bulkhead_Connection == true ) ? 
        Bell_Cutout_Height_Rectangle+2*actual_thickness : 
        Bell_Cutout_Height_Rectangle 
    ;
//If would be nice if this worked, keep getting syntax errors, so need to research functions
//function iif ( condition,if_true,if_false ) = ( condition == true ) ?  if_true  : if_false
// used to create a long support, this get's trimmed to bell or shroud if either is enabled
C_Support_Length = 4*Standpipe_Inner_Diameter-actual_thickness/2+C_Null;
// Set max inflow rows to be less than expected height of object.
Max_Shroud_Inflow_Rows=Standpipe_Height/(((Shroud_Cutout_Height_Rectangle+Shroud_Cutout_Width)*1.2))-2+C_Null;
let(Shroud_Inflow_Rows=clip(Shroud_Inflow_Rows,C_Min_Shroud_Inflow_Rows,Max_Shroud_Inflow_Rows));
Cone_Height=Cone_Height_Factor * Standpipe_Inner_Diameter; //+actual_thickness;
//bell calculations
bell_inner_diameter=2*Standpipe_Inner_Diameter+2*actual_thickness;
bell_cone_height=0.8*bell_inner_diameter;
//bulkhead adapter calcs
bulkhead_bolt_radius=(bell_inner_diameter-(Standpipe_Inner_Diameter/2))/2;
bulkhead_bolt_diameter=2*actual_thickness;
bulkhead_connection_thread_height=3*actual_thickness;
bulkhead_pitch=2.4;
        
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
    if(Generate_Bulkhead_Connection){
        // Male threads outside the bell
        difference() {
            //RodStart(diameter, height, thread_len=0, thread_diam=0, thread_pitch=0)
            RodStart(diameter=0, height=0,thread_len=(bulkhead_connection_thread_height),thread_diam=bell_inner_diameter+(2*actual_thickness),thread_pitch=bulkhead_pitch);
            cylinder(d=Standpipe_Inner_Diameter,h=3*actual_thickness);
        };
        // Build the connector to bulkhead, next to the object.
        // module RodEnd(diameter, height, thread_len=0, thread_diam=0, thread_pitch=0) {
        translate([bell_inner_diameter+Standpipe_Inner_Diameter,0,0]){
            difference() {
                RodEnd(
                    diameter=bell_inner_diameter+(4*actual_thickness), 
                    height=(2*bulkhead_connection_thread_height),
                    thread_len=(bulkhead_connection_thread_height),
                    thread_diam=bell_inner_diameter+(2*actual_thickness),
                    thread_pitch=bulkhead_pitch
                );
                union(){
                    cylinder(d=Standpipe_Inner_Diameter,h=10*actual_thickness);
                    polar_array(bulkhead_bolt_radius,5){
                        cylinder(d=bulkhead_bolt_diameter,h=10*actual_thickness);
                    };
                };
            };
        };
    };

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
                    generate_cutouts(Bell_Cutout_Width,actual_Bell_Cutout_Height_Rectangle,Bell_Cutout_Count);
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
    translate([0,0,actual_thickness/4]) {
        hollow_pipe(height = actual_thickness/2, inner_diameter = Standpipe_Inner_Diameter, thickness = (bell_inner_diameter/2)+actual_thickness);
    }
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
    if(Generate_Bulkhead_Connection){
        // Male threads outside the shroud
        #difference() {
            //RodStart(diameter, height, thread_len=0, thread_diam=0, thread_pitch=0)
            RodStart(diameter=0, height=0,thread_len=(bulkhead_connection_thread_height),thread_diam=bell_inner_diameter+4*actual_thickness+Standpipe_Inner_Diameter/2,thread_pitch=bulkhead_pitch);
            cylinder(d=bell_inner_diameter+Standpipe_Inner_Diameter/2,h=3*actual_thickness);
        };
        // [todo] Build the connector to bulkhead, next to the object.
        // module RodEnd(diameter, height, thread_len=0, thread_diam=0, thread_pitch=0) {
        translate([bell_inner_diameter+Standpipe_Inner_Diameter,0,0]){
            difference() {
                RodEnd(
                    diameter=bell_inner_diameter+6*actual_thickness+Standpipe_Inner_Diameter/2, 
                    height=(2*bulkhead_connection_thread_height),
                    thread_len=(bulkhead_connection_thread_height),
                    thread_diam=bell_inner_diameter+4*actual_thickness+Standpipe_Inner_Diameter/2,
                    thread_pitch=bulkhead_pitch
                );
                union(){
                    cylinder(d=Standpipe_Inner_Diameter,h=10*actual_thickness);
                    polar_array(bulkhead_bolt_radius,5){
                        cylinder(d=bulkhead_bolt_diameter,h=10*actual_thickness);
                    };
                };
            };
        };
    };

    #difference() {
        // Generate the shroud
        translate([0,0,Standpipe_Height/2]){
            hollow_pipe(Standpipe_Height,bell_inner_diameter+actual_thickness+Standpipe_Inner_Diameter/2,actual_thickness);
        };
        union(){
            // Generate cutouts for the shroud    
            vertical_array(
                Shroud_Inflow_Rows,
                (Shroud_Cutout_Height_Rectangle+Shroud_Cutout_Width)*1.2,
                180/Shroud_Cutout_Count_per_Row
            ) generate_stacked_cutouts(
                Shroud_Cutout_Width,Shroud_Cutout_Height_Rectangle,Shroud_Cutout_Count_per_Row
            );
            //Cut away the top cone again + 2 * actual_thickness to seperate the shroud from the bell.
            translate([0,0,Standpipe_Height]) 
            {
                cone_solid(bell_cone_height, 3 * actual_thickness,true);               
            };
        }
    }
}

/* no longer adding support plate out to the shroud, screwing into bulkhead connector instead in this space
if (Generate_Standpipe && Generate_Shroud) {
    translate([0,0,actual_thickness/4])  
        hollow_pipe(height = actual_thickness/2, inner_diameter = Standpipe_Inner_Diameter, thickness = (bell_inner_diameter+actual_thickness+Standpipe_Inner_Diameter/2)-Standpipe_Inner_Diameter);
};
*/

if(Generate_Support && ((Generate_Standpipe && Generate_Bell))){
    difference() {
        // support out to the bell remove remaining, don't connect supports to shroud,
        difference(){
            generate_support(Support_Beam_Count,C_Support_Length,Support_Width, Support_Row_Count);
            hollow_pipe(height = Standpipe_Height*10, inner_diameter = (bell_inner_diameter), thickness = 4*Standpipe_Inner_Diameter);
        }
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

module generate_support(count,length,width,row_count){
    vertical_array(occurance = row_count, distance = C_Support_Length/2, rotation_degrees = 180/3){
        rotate([180,0,0]){
            polar_array(radius = 0, count = count){
                rotate([0,45,0]) {
                        cylinder(h = length, r = width/2);
                };
            }
        }
    }
}

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

// build an array of objects arround the z axis from the object
module polar_array( radius, count) {
    for ( i= [1:360/count:360])  {
        rotate(a=i,v=[0,0,1]) 
        translate([radius,0,0 ] )
        children();       
    }
}

module generate_cutouts(co_width,co_height,co_count){
    // co_count might be a ratio 

    //constants
    cutout_extrude_length=10000;


    rotate(a=-1,v=[0,0,1]) 
    polar_array(0,co_count) 
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
        polar_array(0,cutout_count) {
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


// The following is the entire threads scad library from: https://github.com/rcolyer/threads-scad/blob/master/threads.scad
// for something short like this, I'd rather embed the entire thing in the script...
// -----------------------------------------------------------------------------------------------------------------------
// Created 2016-2017 by Ryan A. Colyer.
// This work is released with CC0 into the public domain.
// https://creativecommons.org/publicdomain/zero/1.0/
//
// https://www.thingiverse.com/thing:1686322
//
// v2.1


screw_resolution = 0.2;  // in mm


// Provides standard metric thread pitches.
function ThreadPitch(diameter) =
  (diameter <= 64) ?
    lookup(diameter, [
      [2, 0.4],
      [2.5, 0.45],
      [3, 0.5],
      [4, 0.7],
      [5, 0.8],
      [6, 1.0],
      [7, 1.0],
      [8, 1.25],
      [10, 1.5],
      [12, 1.75],
      [14, 2.0],
      [16, 2.0],
      [18, 2.5],
      [20, 2.5],
      [22, 2.5],
      [24, 3.0],
      [27, 3.0],
      [30, 3.5],
      [33, 3.5],
      [36, 4.0],
      [39, 4.0],
      [42, 4.5],
      [48, 5.0],
      [52, 5.0],
      [56, 5.5],
      [60, 5.5],
      [64, 6.0]
    ]) :
    diameter * 6.0 / 64;


// Provides standard metric hex head widths across the flats.
function HexAcrossFlats(diameter) =
  (diameter <= 64) ?
    lookup(diameter, [
      [2, 4],
      [2.5, 5],
      [3, 5.5],
      [3.5, 6],
      [4, 7],
      [5, 8],
      [6, 10],
      [7, 11],
      [8, 13],
      [10, 16],
      [12, 18],
      [14, 21],
      [16, 24],
      [18, 27],
      [20, 30],
      [22, 34],
      [24, 36],
      [27, 41],
      [30, 46],
      [33, 50],
      [36, 55],
      [39, 60],
      [42, 65],
      [48, 75],
      [52, 80],
      [56, 85],
      [60, 90],
      [64, 95]
    ]) :
    diameter * 95 / 64;

// Provides standard metric hex head widths across the corners.
function HexAcrossCorners(diameter) =
  HexAcrossFlats(diameter) / cos(30);


// Provides standard metric hex (Allen) drive widths across the flats.
function HexDriveAcrossFlats(diameter) =
  (diameter <= 64) ?
    lookup(diameter, [
      [2, 1.5],
      [2.5, 2],
      [3, 2.5],
      [3.5, 3],
      [4, 3],
      [5, 4],
      [6, 5],
      [7, 5],
      [8, 6],
      [10, 8],
      [12, 10],
      [14, 12],
      [16, 14],
      [18, 15],
      [20, 17],
      [22, 18],
      [24, 19],
      [27, 20],
      [30, 22],
      [33, 24],
      [36, 27],
      [39, 30],
      [42, 32],
      [48, 36],
      [52, 36],
      [56, 41],
      [60, 42],
      [64, 46]
    ]) :
    diameter * 46 / 64;

// Provides standard metric hex (Allen) drive widths across the corners.
function HexDriveAcrossCorners(diameter) =
  HexDriveAcrossFlats(diameter) / cos(30);

// Provides metric countersunk hex (Allen) drive widths across the flats.
function CountersunkDriveAcrossFlats(diameter) =
  (diameter <= 14) ?
    HexDriveAcrossFlats(HexDriveAcrossFlats(diameter)) :
    round(0.6*diameter);

// Provides metric countersunk hex (Allen) drive widths across the corners.
function CountersunkDriveAcrossCorners(diameter) =
  CountersunkDriveAcrossFlats(diameter) / cos(30);

// Provides standard metric nut thickness.
function NutThickness(diameter) =
  (diameter <= 64) ?
    lookup(diameter, [
      [2, 1.6],
      [2.5, 2],
      [3, 2.4],
      [3.5, 2.8],
      [4, 3.2],
      [5, 4.7],
      [6, 5.2],
      [7, 6.0],
      [8, 6.8],
      [10, 8.4],
      [12, 10.8],
      [14, 12.8],
      [16, 14.8],
      [18, 15.8],
      [20, 18.0],
      [22, 21.1],
      [24, 21.5],
      [27, 23.8],
      [30, 25.6],
      [33, 28.7],
      [36, 31.0],
      [42, 34],
      [48, 38],
      [56, 45],
      [64, 51]
    ]) :
    diameter * 51 / 64;


// This generates a closed polyhedron from an array of arrays of points,
// with each inner array tracing out one loop outlining the polyhedron.
// pointarrays should contain an array of N arrays each of size P outlining a
// closed manifold.  The points must obey the right-hand rule.  For example,
// looking down, the P points in the inner arrays are counter-clockwise in a
// loop, while the N point arrays increase in height.  Points in each inner
// array do not need to be equal height, but they usually should not meet or
// cross the line segments from the adjacent points in the other arrays.
// (N>=2, P>=3)
// Core triangles:
//   [j][i], [j+1][i], [j+1][(i+1)%P]
//   [j][i], [j+1][(i+1)%P], [j][(i+1)%P]
//   Then triangles are formed in a loop with the middle point of the first
//   and last array.
module ClosePoints(pointarrays) {
  function recurse_avg(arr, n=0, p=[0,0,0]) = (n>=len(arr)) ? p :
    recurse_avg(arr, n+1, p+(arr[n]-p)/(n+1));

  N = len(pointarrays);
  P = len(pointarrays[0]);
  NP = N*P;
  lastarr = pointarrays[N-1];
  midbot = recurse_avg(pointarrays[0]);
  midtop = recurse_avg(pointarrays[N-1]);

  faces_bot = [
    for (i=[0:P-1])
      [0,i+1,1+(i+1)%len(pointarrays[0])]
  ];

  loop_offset = 1;
  bot_len = loop_offset + P;

  faces_loop = [
    for (j=[0:N-2], i=[0:P-1], t=[0:1])
      [loop_offset, loop_offset, loop_offset] + (t==0 ?
      [j*P+i, (j+1)*P+i, (j+1)*P+(i+1)%P] :
      [j*P+i, (j+1)*P+(i+1)%P, j*P+(i+1)%P])
  ];

  top_offset = loop_offset + NP - P;
  midtop_offset = top_offset + P;

  faces_top = [
    for (i=[0:P-1])
      [midtop_offset,top_offset+(i+1)%P,top_offset+i]
  ];

  points = [
    for (i=[-1:NP])
      (i<0) ? midbot :
      ((i==NP) ? midtop :
      pointarrays[floor(i/P)][i%P])
  ];
  faces = concat(faces_bot, faces_loop, faces_top);

  polyhedron(points=points, faces=faces);
}



// This creates a vertical rod at the origin with external threads.  It uses
// metric standards by default.
module ScrewThread(outer_diam, height, pitch=0, tooth_angle=30, tolerance=0.4, tip_height=0, tooth_height=0, tip_min_fract=0) {

  pitch = (pitch==0) ? ThreadPitch(outer_diam) : pitch;
  tooth_height = (tooth_height==0) ? pitch : tooth_height;
  tip_min_fract = (tip_min_fract<0) ? 0 :
    ((tip_min_fract>0.9999) ? 0.9999 : tip_min_fract);

  outer_diam_cor = outer_diam + 0.25*tolerance; // Plastic shrinkage correction
  inner_diam = outer_diam - tooth_height/tan(tooth_angle);
  or = (outer_diam_cor < screw_resolution) ?
    screw_resolution/2 : outer_diam_cor / 2;
  ir = (inner_diam < screw_resolution) ? screw_resolution/2 : inner_diam / 2;
  height = (height < screw_resolution) ? screw_resolution : height;

  steps_per_loop_try = ceil(2*3.14159265359*or / screw_resolution);
  steps_per_loop = (steps_per_loop_try < 4) ? 4 : steps_per_loop_try;
  hs_ext = 3;
  hsteps = ceil(3 * height / pitch) + 2*hs_ext;

  extent = or - ir;

  tip_start = height-tip_height;
  tip_height_sc = tip_height / (1-tip_min_fract);

  tip_height_ir = (tip_height_sc > tooth_height/2) ?
    tip_height_sc - tooth_height/2 : tip_height_sc;

  tip_height_w = (tip_height_sc > tooth_height) ? tooth_height : tip_height_sc;
  tip_wstart = height + tip_height_sc - tip_height - tip_height_w;


  function tooth_width(a, h, pitch, tooth_height, extent) =
    let(
      ang_full = h*360.0/pitch-a,
      ang_pn = atan2(sin(ang_full), cos(ang_full)),
      ang = ang_pn < 0 ? ang_pn+360 : ang_pn,
      frac = ang/360,
      tfrac_half = tooth_height / (2*pitch),
      tfrac_cut = 2*tfrac_half
    )
    (frac > tfrac_cut) ? 0 : (
      (frac <= tfrac_half) ?
        ((frac / tfrac_half) * extent) :
        ((1 - (frac - tfrac_half)/tfrac_half) * extent)
    );


  pointarrays = [
    for (hs=[0:hsteps])
      [
        for (s=[0:steps_per_loop-1])
          let(
            ang_full = s*360.0/steps_per_loop,
            ang_pn = atan2(sin(ang_full), cos(ang_full)),
            ang = ang_pn < 0 ? ang_pn+360 : ang_pn,

            h_fudge = pitch*0.001,

            h_mod =
              (hs%3 == 2) ?
                ((s == steps_per_loop-1) ? tooth_height - h_fudge : (
                 (s == steps_per_loop-2) ? tooth_height/2 : 0)) : (
              (hs%3 == 0) ?
                ((s == steps_per_loop-1) ? pitch-tooth_height/2 : (
                 (s == steps_per_loop-2) ? pitch-tooth_height + h_fudge : 0)) :
                ((s == steps_per_loop-1) ? pitch-tooth_height/2 + h_fudge : (
                 (s == steps_per_loop-2) ? tooth_height/2 : 0))
              ),

            h_level =
              (hs%3 == 2) ? tooth_height - h_fudge : (
              (hs%3 == 0) ? 0 : tooth_height/2),

            h_ub = floor((hs-hs_ext)/3) * pitch
              + h_level + ang*pitch/360.0 - h_mod,
            h_max = height - (hsteps-hs) * h_fudge,
            h_min = hs * h_fudge,
            h = (h_ub < h_min) ? h_min : ((h_ub > h_max) ? h_max : h_ub),

            ht = h - tip_start,
            hf_ir = ht/tip_height_ir,
            ht_w = h - tip_wstart,
            hf_w_t = ht_w/tip_height_w,
            hf_w = (hf_w_t < 0) ? 0 : ((hf_w_t > 1) ? 1 : hf_w_t),

            ext_tip = (h <= tip_wstart) ? extent : (1-hf_w) * extent,
            wnormal = tooth_width(ang, h, pitch, tooth_height, ext_tip),
            w = (h <= tip_wstart) ? wnormal :
              (1-hf_w) * wnormal +
              hf_w * (0.1*screw_resolution + (wnormal * wnormal * wnormal /
                (ext_tip*ext_tip+0.1*screw_resolution))),
            r = (ht <= 0) ? ir + w :
              ( (ht < tip_height_ir ? ((2/(1+(hf_ir*hf_ir))-1) * ir) : 0) + w)
          )
          [r*cos(ang), r*sin(ang), h]
      ]
  ];


  ClosePoints(pointarrays);
}


// This creates a vertical rod at the origin with external auger-style
// threads.
module AugerThread(outer_diam, inner_diam, height, pitch, tooth_angle=30, tolerance=0.4, tip_height=0, tip_min_fract=0) {
  tooth_height = tan(tooth_angle)*(outer_diam-inner_diam);
  ScrewThread(outer_diam, height, pitch, tooth_angle, tolerance, tip_height,
    tooth_height, tip_min_fract);
}


// This creates a threaded hole in its children using metric standards by
// default.
module ScrewHole(outer_diam, height, position=[0,0,0], rotation=[0,0,0], pitch=0, tooth_angle=30, tolerance=0.4, tooth_height=0) {
  extra_height = 0.001 * height;

  difference() {
    children();
    translate(position)
      rotate(rotation)
      translate([0, 0, -extra_height/2])
      ScrewThread(1.01*outer_diam + 1.25*tolerance, height + extra_height,
        pitch, tooth_angle, tolerance, tooth_height=tooth_height);
  }
}


// This creates an auger-style threaded hole in its children.
module AugerHole(outer_diam, inner_diam, height, pitch, position=[0,0,0], rotation=[0,0,0], tooth_angle=30, tolerance=0.4) {
  tooth_height = tan(tooth_angle)*(outer_diam-inner_diam);
  ScrewHole(outer_diam, height, position, rotation, pitch, tooth_angle,
    tolerance, tooth_height=tooth_height) children();
}


// This inserts a ClearanceHole in its children.
// The rotation vector is applied first, then the position translation,
// starting from a position upward from the z-axis at z=0.
module ClearanceHole(diameter, height, position=[0,0,0], rotation=[0,0,0], tolerance=0.4) {
  extra_height = 0.001 * height;

  difference() {
    children();
    translate(position)
      rotate(rotation)
      translate([0, 0, -extra_height/2])
      cylinder(h=height + extra_height, r=(diameter/2+tolerance));
  }
}


// This inserts a ClearanceHole with a recessed bolt hole in its children.
// The rotation vector is applied first, then the position translation,
// starting from a position upward from the z-axis at z=0.  The default
// recessed parameters fit a standard metric bolt.
module RecessedClearanceHole(diameter, height, position=[0,0,0], rotation=[0,0,0], recessed_diam=-1, recessed_height=-1, tolerance=0.4) {
  recessed_diam = (recessed_diam < 0) ?
    HexAcrossCorners(diameter) : recessed_diam;
  recessed_height = (recessed_height < 0) ? diameter : recessed_height;
  extra_height = 0.001 * height;

  difference() {
    children();
    translate(position)
      rotate(rotation)
      translate([0, 0, -extra_height/2])
      cylinder(h=height + extra_height, r=(diameter/2+tolerance));
    translate(position)
      rotate(rotation)
      translate([0, 0, -extra_height/2])
      cylinder(h=recessed_height + extra_height/2,
        r=(recessed_diam/2+tolerance));
  }
}


// This inserts a countersunk ClearanceHole in its children.
// The rotation vector is applied first, then the position translation,
// starting from a position upward from the z-axis at z=0.
// The countersunk side is on the bottom by default.
module CountersunkClearanceHole(diameter, height, position=[0,0,0], rotation=[0,0,0], sinkdiam=0, sinkangle=45, tolerance=0.4) {
  extra_height = 0.001 * height;
  sinkdiam = (sinkdiam==0) ? 2*diameter : sinkdiam;
  sinkheight = ((sinkdiam-diameter)/2)/tan(sinkangle);

  difference() {
    children();
    translate(position)
      rotate(rotation)
      translate([0, 0, -extra_height/2])
      union() {
        cylinder(h=height + extra_height, r=(diameter/2+tolerance));
        cylinder(h=sinkheight + extra_height, r1=(sinkdiam/2+tolerance), r2=(diameter/2+tolerance), $fn=24*diameter);
      }
  }
}


// This inserts a Phillips tip shaped hole into its children.
// The rotation vector is applied first, then the position translation,
// starting from a position upward from the z-axis at z=0.
module PhillipsTip(width=7, thickness=0, straightdepth=0, position=[0,0,0], rotation=[0,0,0]) {
  thickness = (thickness <= 0) ? width*2.5/7 : thickness;
  straightdepth = (straightdepth <= 0) ? width*3.5/7 : straightdepth;
  angledepth = (width-thickness)/2;
  height = straightdepth + angledepth;
  extra_height = 0.001 * height;

  difference() {
    children();
    translate(position)
      rotate(rotation)
      union() {
        hull() {
          translate([-width/2, -thickness/2, -extra_height/2])
            cube([width, thickness, straightdepth+extra_height]);
          translate([-thickness/2, -thickness/2, height-extra_height])
            cube([thickness, thickness, extra_height]);
        }
        hull() {
          translate([-thickness/2, -width/2, -extra_height/2])
            cube([thickness, width, straightdepth+extra_height]);
          translate([-thickness/2, -thickness/2, height-extra_height])
            cube([thickness, thickness, extra_height]);
        }
      }
  }
}



// Create a standard sized metric bolt with hex head and hex key.
module MetricBolt(diameter, length, tolerance=0.4) {
  drive_tolerance = pow(3*tolerance/HexDriveAcrossCorners(diameter),2)
    + 0.75*tolerance;

  difference() {
    cylinder(h=diameter, r=(HexAcrossCorners(diameter)/2-0.5*tolerance), $fn=6);
    cylinder(h=diameter,
      r=(HexDriveAcrossCorners(diameter)+drive_tolerance)/2, $fn=6,
      center=true);
  }
  translate([0,0,diameter-0.01])
    ScrewThread(diameter, length+0.01, tolerance=tolerance,
      tip_height=ThreadPitch(diameter), tip_min_fract=0.75);
}


// Create a standard sized metric countersunk (flat) bolt with hex key drive.
// In compliance with convention, the length for this includes the head.
module MetricCountersunkBolt(diameter, length, tolerance=0.4) {
  drive_tolerance = pow(3*tolerance/CountersunkDriveAcrossCorners(diameter),2)
    + 0.75*tolerance;

  difference() {
    cylinder(h=diameter/2, r1=diameter, r2=diameter/2, $fn=24*diameter);
    cylinder(h=0.8*diameter,
      r=(CountersunkDriveAcrossCorners(diameter)+drive_tolerance)/2, $fn=6,
      center=true);
  }
  translate([0,0,diameter/2-0.01])
    ScrewThread(diameter, length-diameter/2+0.01, tolerance=tolerance,
      tip_height=ThreadPitch(diameter), tip_min_fract=0.75);
}


// Create a standard sized metric countersunk (flat) bolt with hex key drive.
// In compliance with convention, the length for this includes the head.
module MetricWoodScrew(diameter, length, tolerance=0.4) {
  drive_tolerance = pow(3*tolerance/CountersunkDriveAcrossCorners(diameter),2)
    + 0.75*tolerance;

  PhillipsTip(diameter-2)
    union() {
      cylinder(h=diameter/2, r1=diameter, r2=diameter/2, $fn=24*diameter);

      translate([0,0,diameter/2-0.01])
        ScrewThread(diameter, length-diameter/2+0.01, tolerance=tolerance,
          tip_height=diameter);
    }
}


// Create a standard sized metric hex nut.
module MetricNut(diameter, thickness=0, tolerance=0.4) {
  thickness = (thickness==0) ? NutThickness(diameter) : thickness;
  ScrewHole(diameter, thickness, tolerance=tolerance)
    cylinder(h=thickness, r=HexAcrossCorners(diameter)/2-0.5*tolerance, $fn=6);
}


// Create a convenient washer size for a metric nominal thread diameter.
module MetricWasher(diameter) {
  difference() {
    cylinder(h=diameter/5, r=1.15*diameter, $fn=24*diameter);
    cylinder(h=2*diameter, r=0.575*diameter, $fn=12*diameter, center=true);
  }
}


// Solid rod on the bottom, external threads on the top.
module RodStart(diameter, height, thread_len=0, thread_diam=0, thread_pitch=0) {
  // A reasonable default.
  thread_diam = (thread_diam==0) ? 0.75*diameter : thread_diam;
  thread_len = (thread_len==0) ? 0.5*diameter : thread_len;
  thread_pitch = (thread_pitch==0) ? ThreadPitch(thread_diam) : thread_pitch;

  cylinder(r=diameter/2, h=height, $fn=24*diameter);

  translate([0, 0, height])
    ScrewThread(thread_diam, thread_len, thread_pitch,
      tip_height=thread_pitch, tip_min_fract=0.75);
}


// Solid rod on the bottom, internal threads on the top.
// Flips around x-axis after printing to pair with RodStart.
module RodEnd(diameter, height, thread_len=0, thread_diam=0, thread_pitch=0) {
  // A reasonable default.
  thread_diam = (thread_diam==0) ? 0.75*diameter : thread_diam;
  thread_len = (thread_len==0) ? 0.5*diameter : thread_len;
  thread_pitch = (thread_pitch==0) ? ThreadPitch(thread_diam) : thread_pitch;

  ScrewHole(thread_diam, thread_len, [0, 0, height], [180,0,0], thread_pitch)
    cylinder(r=diameter/2, h=height, $fn=24*diameter);
}


// Internal threads on the bottom, external threads on the top.
module RodExtender(diameter, height, thread_len=0, thread_diam=0, thread_pitch=0) {
  // A reasonable default.
  thread_diam = (thread_diam==0) ? 0.75*diameter : thread_diam;
  thread_len = (thread_len==0) ? 0.5*diameter : thread_len;
  thread_pitch = (thread_pitch==0) ? ThreadPitch(thread_diam) : thread_pitch;

  max_bridge = height - thread_len;
  // Use 60 degree slope if it will fit.
  bridge_height = ((thread_diam/4) < max_bridge) ? thread_diam/4 : max_bridge;

  difference() {
    union() {
      ScrewHole(thread_diam, thread_len, pitch=thread_pitch)
        cylinder(r=diameter/2, h=height, $fn=24*diameter);

      translate([0,0,height])
        ScrewThread(thread_diam, thread_len, pitch=thread_pitch,
          tip_height=thread_pitch, tip_min_fract=0.75);
    }
    // Carve out a small conical area as a bridge.
    translate([0,0,thread_len])
      cylinder(h=bridge_height, r1=thread_diam/2, r2=0.1);
  }
}


// Produces a matching set of metric bolts, nuts, and washers.
module MetricBoltSet(diameter, length, quantity=1) {
  for (i=[0:quantity-1]) {
    translate([0, i*4*diameter, 0]) MetricBolt(diameter, length);
    translate([4*diameter, i*4*diameter, 0]) MetricNut(diameter);
    translate([8*diameter, i*4*diameter, 0]) MetricWasher(diameter);
  }
}


module Demo() {
  translate([0,-0,0]) MetricBoltSet(3, 8);
  translate([0,-20,0]) MetricBoltSet(4, 8);
  translate([0,-40,0]) MetricBoltSet(5, 8);
  translate([0,-60,0]) MetricBoltSet(6, 8);
  translate([0,-80,0]) MetricBoltSet(8, 8);

  translate([0,25,0]) MetricCountersunkBolt(5, 10);
  translate([23,18,5])
    scale([1,1,-1])
    CountersunkClearanceHole(5, 8, [7,7,0], [0,0,0])
    cube([14, 14, 5]);

  translate([70, -10, 0])
    RodStart(20, 30);
  translate([70, 20, 0])
    RodEnd(20, 30);

  translate([70, -45, 0])
    MetricWoodScrew(8, 20);

  translate([12, 50, 0])
    union() {
      translate([0, 0, 5.99])
        AugerThread(15, 3.5, 22, 7, tooth_angle=15, tip_height=7);
      translate([-4, -9, 0]) cube([8, 18, 6]);
    }
}


// Demo();

// MetricBoltSet(6, 8, 10);
