// +-------------------------------------------------+
// Title:           Parametric Print at Once Bell Siphon
// Version:         1.001
// Release Date:    2023-02-16 (ISO 8601)
// Author:          Jeremy D. Gerdes
// Version Control: 
// License: This work is released with CC0 into the public domain.
// https://creativecommons.org/publicdomain/zero/1.0/
// 
// Todo:         1) Add snorkle with bucket option (if siphon lock needs assistance to break) 
// +--------------------------------------------------+
//
// Description:
//
/* [Bell Siphon] */
// How thick to make all walls (mm). Note: max of Wall Thickness and (3*'Extruder Line Thickness') over writes this vale
Wall_Thickness=2.4;
/* [Stand Pipe] */
// larger diameter allows for a higher flow rate, modifies bell and shrowd diameters (mm)
Standpipe_Inner_Diameter=32.1;
// Cone Heigth as a percentage of standpipe inner diammeter 1 = 100 %, 
Cone_Height_Factor=1.18;
// Total standpipe height (mm)
Standpipe_Height=194.1;
// Total number of bell arches to allow flow into the bell, arches provide additional support durring print, but limit total flow into the bell, Maximum_Print_Height can override this value (mm)  
/* [Bell] */
// Number of inflow arches at the bottom of the bell (mm)
Bell_Cutout_Count=14;
// Width of inflow arches on the bell    
Bell_Cutout_Width=7.1;
// Height of the rectangle portion for the inflow arches on the bell
Bell_Cutout_Height_Rectangle=10.1;
/* [Shroud] */
// How wide should the shroud (gravel gaurd) be? values less than (Bell's threads+5mm) are ignored.
Shroud_Inner_Diameter=145;
// Extend the height of the shroud, Caution! this only works if the shroud diameter is larger than the widest part of the bell, if you see a halo then increase shroud diameter
Shroud_Height_Extention=45;

// Number of inflow arches per row of the shrowd - for more of a screen use 80
Shroud_Cutout_Count_per_Row=18;
// Width of inflow cuts on the shrowd - for more of a screen use 1.6 mm
Shroud_Cutout_Width=2.9;
// Height of the rectangle portion for the inflow cuts on the shrowd  - for more of a screen use 8 mm
Shroud_Cutout_Height_Rectangle=12.8;
// Number of rows of inflow cuts from the bottom up  - for more of a screen use 16
Shroud_Inflow_Rows=19;

/*[Support Structure]*/
// Recommend 4.8, Supports help fix the standpipe in place, if this is too wide then flow will be restricted too much to create a siphon (mm)
Support_Width = 4.8;
// Beam Count Recommend between 2 and 6
Support_Beam_Count = 3;
//Row Count Recommend between 2 and 4
Support_Row_Count = 3;

/*[Bulkhead Connection Adapter]*/
// Common Thread Pitch Value for Bulkhead Connection Adapter. Setting the Bulkhead_Thread_Pitch=0 forces the default ISO 724 coarse threading: Engineeringtoolbox.com/metric-threads-d_777.html
Bulkhead_Thread_Pitch=6.0;
// (0 to 2) ISO metric counter sink depth in wall thiknesses, set to any value less than 0 to remove counter sink
Bulkhead_Bolt_Counter_Sink=.7;
/* [Printer Settings] */
// minimum object wall thickness shouldn't be less than 3x extruder_line_thickness this helps ensure a water tight seal (mm)
Extruder_Line_Thickness=0.8;
//Enter you're printer's max height. Will reduce object's total height to match Maximum_Print_Height [not yet implemented] (mm)
// Maximum_Print_Height=250;
/*[Object Generation Options]*/
// Standpipe with funnel at top to induce siphon. Bell provides inflow at the bottom and a travel path to the top of the standpipe. This design requires both to be printed at the same time, as the standpipe funnel OD is larger than the bell ID.
Generate_Standpipe_and_Bell=true;
// Threads on Bell that connect to Bulkhead Connection
Generate_Bell_Bulkhead_Threads = true;
// Supports fix the standpipe to the bell, so 'Generate Standpipe and Bell' must be selected for this option to apply.
Generate_Bell_Support=true;

// Media Shroud prevents grow bed media from entering bell
Generate_Shroud=true;
// Bulkhead connection adapter provides a method of joining unit to bottom of the grow bed
Generate_Bulkhead_Connection=true;

/*[Quality]*/
// fn is the default number of facets to generate. This should be an even number 4 or more and less than 256. Four makes for a square everything, 80 or higher makes near perfect circles.
$fn=180;

// ----------------
// constants 
// ----------------
// add this constant to all other constants so they are excluded from the customizer
C_Null=0+0;
C_MIN_STANDPIPE_HEIGHT=65+C_Null;
C_MIN_FN=4+C_Null;
C_MAX_FN=200+C_Null;
C_Min_Shroud_Inflow_Rows=2+C_Null;

/* this doesn't work as "The value for a regular variable is assigned at compile time and is thus static for all calls."
// set minimum faces
let($fn=(2*floor((1+clip($fn,C_MIN_FN,C_MAX_FN))/2)));
we would have to start using the fn= argument of everything and use our own variable for this to work.
https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Other_Language_Features#$fa,_$fs_and_$fn
*/
//calculations
// force thickness to be at least 3 line thicknesses
calculated_thickness = clip(Wall_Thickness,Extruder_Line_Thickness*3,Wall_Thickness+1);
calculated_Bell_Cutout_Height_Rectangle =Bell_Cutout_Height_Rectangle;

//+bulkhead_connection_thread_height;
//If would be nice if this worked, keep getting syntax errors, so need to research functions
//function iif ( condition,if_true,if_false ) = ( condition == true ) ?  if_true  : if_false
// used to create a long support, this get's trimmed to bell or shroud if either is enabled
C_Support_Length = 4*Standpipe_Inner_Diameter-calculated_thickness/2+C_Null;
// Set max inflow rows to be less than expected height of object.
Max_Shroud_Inflow_Rows=1+(Standpipe_Height+Shroud_Height_Extention)/(((Shroud_Cutout_Height_Rectangle+Shroud_Cutout_Width)*1.2))-2+C_Null;
calculated_shroud_Inflow_Rows=clip(Shroud_Inflow_Rows,C_Min_Shroud_Inflow_Rows,Max_Shroud_Inflow_Rows);
Cone_Height=Cone_Height_Factor * Standpipe_Inner_Diameter; //+calculated_thickness;
//bell calculations
bell_inner_diameter=2*Standpipe_Inner_Diameter+2*calculated_thickness;
bell_cone_height=0.8*bell_inner_diameter;
//bulkhead adapter calcs
bulkhead_bolt_radius=calculated_thickness+(bell_inner_diameter-(Standpipe_Inner_Diameter/2))/2;
bulkhead_bolt_diameter=2.25*calculated_thickness;
bulkhead_connection_thread_height=6*calculated_thickness;

// Shroud Diameter calculations
C_Min_Shroud_Diameter = (bell_inner_diameter+3*calculated_thickness+Standpipe_Inner_Diameter/2)+C_Null ; //(2*calculated_thickness+bell_inner_diameter+Standpipe_Inner_Diameter/2)+5+C_Null; 

calculated_shroud_diameter = clip(Shroud_Inner_Diameter,C_Min_Shroud_Diameter,Shroud_Inner_Diameter);

Bulkhead_Bolt_Counter_Sink_Wall_Thicknesses  = clip(Bulkhead_Bolt_Counter_Sink,-0.1,2);

// new pieces
new_piece_distance=calculated_shroud_diameter+7*calculated_thickness;

/* 
------------------
 Build the Things!
------------------
*/
union(){
  #if (Generate_Standpipe_and_Bell){
    //  Generate Standpipe
    create_standpipe();
    // Generate Bell
    create_bell();
  }

  /*
  ---------------------
  Generate shroud
  ---------------------
  */

  #if(Generate_Shroud){
    create_shroud();
  }

  //Generate Bulkhead Connector
  if(Generate_Bulkhead_Connection){
    create_bulkhead_connection();
  }

  if(Generate_Bell_Support && Generate_Standpipe_and_Bell){
    create_supports();
  }
}

// +------------------------------------+
// Functions and macros
// +------------------------------------+

module create_supports(){
  //add supports
  difference(){
    // support out to the bell remove remaining, don't connect supports to shroud,
    difference(){
      Generate_Bell_Support(Support_Beam_Count,C_Support_Length,Support_Width, Support_Row_Count);
      hollow_pipe(height = Standpipe_Height*10, inner_diameter = (bell_inner_diameter), thickness = 40*Standpipe_Inner_Diameter);
    }
    {
      union(){
        cylinder(h = Standpipe_Height*2, r = Standpipe_Inner_Diameter/2);
        translate([0,0,Standpipe_Height+Standpipe_Inner_Diameter*50]){
          cube(Standpipe_Inner_Diameter*100,center=true);
        }
      }
    }
  }
}

module create_shroud(){
  // Move the shroud top out as a seperate piece to print.
  translate([0,new_piece_distance, .5*bulkhead_connection_thread_height]){
    // cuts the inflow holes
    difference(){
      //cuts the top cone, and trims total height
      difference(){
        union(){
          // Generate the shroud
          translate([0,0,(Standpipe_Height+Shroud_Height_Extention)/2]){
            hollow_pipe(
              Standpipe_Height + Shroud_Height_Extention
              ,calculated_shroud_diameter
              ,calculated_thickness
            );
            //calculated_shroud_diameter used to be {bell_inner_diameter+3*calculated_thickness+Standpipe_Inner_Diameter/2} before it was made into a parameter
     
          }
        }
        create_shroud_cutouts();
      }
      translate([0,0, bulkhead_connection_thread_height+2*calculated_thickness]){
        // Generate cutouts for the shroud    
        vertical_array(
          calculated_shroud_Inflow_Rows,
          (Shroud_Cutout_Height_Rectangle+Shroud_Cutout_Width)*1.2,
          15
          //180/Shroud_Cutout_Count_per_Row
        ){
          generate_stacked_cutouts(
            Shroud_Cutout_Width,Shroud_Cutout_Height_Rectangle,Shroud_Cutout_Count_per_Row
          );
        }
      }
    }
  }
}

module create_bulkhead_connection(){
      // move connector next to the object.
    translate([0,new_piece_distance,0]){
        union(){
            // Build the female connector to bulkhead bell section
            difference(){
                RodEnd(
                    //diameter=bell_inner_diameter+(10*calculated_thickness), 
                    diameter=calculated_shroud_diameter+2*calculated_thickness, //(2*calculated_thickness+bell_inner_diameter+3*calculated_thickness+Standpipe_Inner_Diameter/2),
                    height=(2*calculated_thickness+1.15*bulkhead_connection_thread_height),
                    thread_len=(1.15*bulkhead_connection_thread_height),
                    thread_diam=(calculated_thickness+bell_inner_diameter+Standpipe_Inner_Diameter/2),
                    thread_pitch=Bulkhead_Thread_Pitch
                );
                union(){
                    // standpipe outflow hole
                    cylinder(d=Standpipe_Inner_Diameter,h=10*calculated_thickness);
                    // bolt/screw holes with counter sink to affix bulkhead connector.  
                    polar_array(bulkhead_bolt_radius,5){
                        union(){
                            cylinder(d=bulkhead_bolt_diameter,h=10*calculated_thickness,$fn=80);
                   translate([0,0,4*calculated_thickness-Bulkhead_Bolt_Counter_Sink_Wall_Thicknesses*calculated_thickness]){
                       // standard cone creates a 90 degree counter sink, this is ISO Metric
                        cone_solid(calculated_thickness+bulkhead_bolt_diameter,10*calculated_thickness, true,$fn=80);
                            }
                            
                        } 
                    }
                }
            }
        }
    }
}

module create_shroud_cutouts(){
  union(){
    //Cut away the top cone again + 3 * calculated_thickness to seperate the shroud from the bell.
    translate([0,0,Standpipe_Height- 3*calculated_thickness]){
        cone_solid(bell_cone_height, 3*calculated_thickness,true);  
    }
    // trim the bottom
    cylinder(h=1*bulkhead_connection_thread_height,d=(2*bell_inner_diameter)+(2.5*calculated_thickness),center=false);
    // trim the top
    translate([0,0,Standpipe_Height- 3.1*calculated_thickness]){
      cylinder(h=bulkhead_connection_thread_height,d=(2*bell_inner_diameter)+(2.5*calculated_thickness),center=false);
    }
  }
}

module create_bell(){
  // add supports to bell cutout feet
  polar_array(0,Bell_Cutout_Count){
    translate([0,(Standpipe_Inner_Diameter+2*calculated_thickness)/2,calculated_thickness*4]){
      //l=((PI*D) / n) - Cw
      supportFoot(
        l = calculated_thickness/2, // ((PI*bell_inner_diameter)/Bell_Cutout_Count)-Bell_Cutout_Width,
        w = (bell_inner_diameter)/2-(Standpipe_Inner_Diameter+(0.5*calculated_thickness))/2,
        h = Bell_Cutout_Height_Rectangle+1.5*Bell_Cutout_Width
      );
    };
  };
    
  difference(){
    union(){ //add
      translate([0,0,(Standpipe_Height+bulkhead_connection_thread_height-calculated_thickness)/2]){
        //height,inner_diameter,thickness
        // h=Standpipe_Height,r=bell_inner_diameter/2,center=true);
        hollow_pipe(height=Standpipe_Height+calculated_thickness-bulkhead_connection_thread_height,inner_diameter=bell_inner_diameter,thickness=calculated_thickness);
      }
      // bell top 
      translate([0,0,Standpipe_Height]){
        cone_hollow (bell_cone_height,calculated_thickness,true); 
      }
      if(Generate_Bell_Bulkhead_Threads){
          // threaded bottom
          RodStart(
            diameter=0, 
            height=0,
            thread_len=(bulkhead_connection_thread_height),
            //thread_diam=bell_inner_diameter+(8*calculated_thickness),
            thread_diam=(calculated_thickness+bell_inner_diameter+Standpipe_Inner_Diameter/2),
            thread_pitch=Bulkhead_Thread_Pitch
          );
      } else {
          translate([0,0,bulkhead_connection_thread_height/2]) hollow_pipe(height=bulkhead_connection_thread_height,inner_diameter=Standpipe_Inner_Diameter,thickness=(bell_inner_diameter-Standpipe_Inner_Diameter)/2+calculated_thickness);
      }
      
      // Add the bell cap, after cutting the funnel
    }
    { //remove
      union(){
        // bell cutout arches
        translate([0,0,bulkhead_connection_thread_height]){   
            generate_cutouts(Bell_Cutout_Width,calculated_Bell_Cutout_Height_Rectangle,Bell_Cutout_Count);
        }
        // top cone funnel cut out
        {           
        translate([0,0,Standpipe_Height+calculated_thickness]){
            cone_solid(bell_cone_height,calculated_thickness,true);    }
        }
        // remove inner diameter of standpipe 
        cylinder(h=3*Standpipe_Height,r=(Standpipe_Inner_Diameter/2),center=true);
        
        // remove inner diameter of bell
        translate([0,0,Standpipe_Height/2 + bulkhead_connection_thread_height]){   
          cylinder(h=Standpipe_Height,r=(bell_inner_diameter/2),center=true);
        }
      }
    }
  }
  create_bell_cap();
}

module create_bell_cap(){
  translate([0,0,Standpipe_Height])
    {cone_hollow (bell_cone_height,calculated_thickness);}
}

module create_standpipe(){
  translate([0,0,Standpipe_Height/2]){
    difference(){
      hollow_pipe(Standpipe_Height,Standpipe_Inner_Diameter,calculated_thickness);
      translate([0,0,Standpipe_Height/2]) rotate([0,180,0]) 
        cylinder(r1=(Cone_Height*2)/2-(calculated_thickness), r2=0, h=Cone_Height-calculated_thickness);
    }
  }
  //create funnel cone
  translate([0,0,Standpipe_Height])
    difference(){
        cone_hollow (Cone_Height,calculated_thickness,true);   
        cylinder(h=Standpipe_Height,r=(Standpipe_Inner_Diameter)/2, center=true);
    }
}


module Generate_Bell_Support(count,length,width,row_count){
    vertical_array(occurance = row_count, distance = C_Support_Length/2, rotation_degrees = 180/3){
        rotate([180,0,0]){
            polar_array(radius = 0, count = count){
                rotate([0,45,0]){
                        cylinder(h = length, r = width/2);
                }
            }
        }
    }
}

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
function clip ( x, x_min, x_max ) = ( x < x_min ) ? x_min : ( x > x_max ) ? x_max : x;

module supportFoot(l,w,h){
  //https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Primitive_Solids#polyhedron
  //polyhedron( points = [ [X0, Y0, Z0], [X1, Y1, Z1], ... ], faces = [ [P0, P1, P2, P3, ...], ... ], convexity = N);
  polyhedron( 
    points=[[0,0,0], [l,0,0], [l,w,0], [0,w,0], [0,w,h], [l,w,h]],
    faces=[[0,1,2,3],[5,4,3,2],[0,4,5,1],[0,3,4],[5,2,1]]
  );
}

//usage:
//vertical_array(20,20,15) generate_stacked_cutouts(cutout_width,cutout_height,cutout_count);
module vertical_array( occurance, distance, rotation_degrees ){
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
    if(f_invert){
        rotate([0,180,0]) difference(){
            cylinder(r1=base/2, r2=0, h=height);
        }
    ;}else {
            cylinder(r1=base/2, r2=0, h=height)    ;}  
}
module cone_hollow ( height, thickness, f_invert = false)
{
    // make 45 degree hollow cone with thickness
    // set base to create 45 degree cone
    base=height*2;
    if(f_invert){
        rotate([0,180,0]) difference(){
            cylinder(r1=base/2, r2=0, h=height);
            cylinder(r1=base/2-(thickness), r2=0, h=height-thickness);
        }
    ;}else {
        difference(){
            cylinder(r1=base/2, r2=0, h=height);
            cylinder(r1=base/2-(thickness), r2=0, h=height-thickness);
        }
    ;}
}

// build an array of objects arround the z axis from the object
module polar_array( radius, count){
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


    //rotate(a=0,v=[0,0,1]) 
    polar_array(0,co_count) 
    union(){
        // start with a solid rectagular cube
        cube([cutout_extrude_length,co_width,co_height]);
        // add a pritable cap
        translate([cutout_extrude_length,0,0]){
            rotate(a=-90,v=[0,1,0]) 
            linear_extrude(cutout_extrude_length) 
                polygon(points = [ [co_height,0],[co_height, co_width],[    co_height+(co_width/2),co_width/2]]);
         }
    }
}

module generate_stacked_cutouts(cutout_width,cutout_height,cutout_count){
  //constants
  // extrude the cutouts far more than is needed...
  cutout_extrude_length=10000;
    // drop the bottom cutout to z0
    translate([0,0,-1*(cutout_height+2*cutout_width)]){
        polar_array(0,cutout_count){
            rotate([45,0,0]){
                union(){
                // start with a cube
                  cube([cutout_extrude_length,cutout_width,cutout_height]);
                }
            }
        }
    }
}

module hollow_pipe(height,inner_diameter,thickness){
    difference(){
        cylinder(h=height,r=thickness+(inner_diameter/2), center=true);
        cylinder( h=height,r=inner_diameter/2,center=true);
    }
}


// The following is an exerpt from the scad library 'Threads' from: https://github.com/rcolyer/threads-scad/blob/master/threads.scad
  // Script Author's note: for something short like this, I'd rather embed in the script then force users to use an external library
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
  module ClosePoints(pointarrays){
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
  module ScrewThread(outer_diam, height, pitch=0, tooth_angle=30, tolerance=0.8, tip_height=0, tooth_height=0, tip_min_fract=0){

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

  // Create a standard sized metric countersunk (flat) bolt with hex key drive.
  // In compliance with convention, the length for this includes the head.
  module MetricCountersunkBolt(diameter, length, tolerance=0.8){
    drive_tolerance = pow(3*tolerance/CountersunkDriveAcrossCorners(diameter),2)
      + 0.75*tolerance;

    difference(){
      cylinder(h=diameter/2, r1=diameter, r2=diameter/2, $fn=24*diameter);
      cylinder(h=0.8*diameter,
        r=(CountersunkDriveAcrossCorners(diameter)+drive_tolerance)/2, $fn=6,
        center=true);
    }
    translate([0,0,diameter/2-0.01])
      ScrewThread(diameter, length-diameter/2+0.01, tolerance=tolerance,
        tip_height=ThreadPitch(diameter), tip_min_fract=0.75);
  }

  // Solid rod on the bottom, external threads on the top.
  module RodStart(diameter, height, thread_len=0, thread_diam=0, thread_pitch=0){
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
  module RodEnd(diameter, height, thread_len=0, thread_diam=0, thread_pitch=0){
    // A reasonable default.
    thread_diam = (thread_diam==0) ? 0.75*diameter : thread_diam;
    thread_len = (thread_len==0) ? 0.5*diameter : thread_len;
    thread_pitch = (thread_pitch==0) ? ThreadPitch(thread_diam) : thread_pitch;

    ScrewHole(thread_diam, thread_len, [0, 0, height], [180,0,0], thread_pitch)
      cylinder(r=diameter/2, h=height, $fn=24*diameter);
  }


  // This creates a threaded hole in its children using metric standards by default
  // default tolerance=0.4 increasing for large threads
  module ScrewHole(outer_diam, height, position=[0,0,0], rotation=[0,0,0], pitch=0, tooth_angle=30, tolerance=0.8, tooth_height=0){
    extra_height = 0.001 * height;

    difference(){
      children();
      translate(position)
        rotate(rotation)
        translate([0, 0, -extra_height/2])
        ScrewThread(1.01*outer_diam + 1.25*tolerance, height + extra_height,
          pitch, tooth_angle, tolerance, tooth_height=tooth_height);
    }
  }
// END library 'Threads'
