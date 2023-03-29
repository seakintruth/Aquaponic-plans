// Description:
//
/* [Building] */
// (feet)
building_width_ft=8.4;
// (feet)
building_length_ft=12 ;
// (inches)
door_width=31.5;
// (inches)
door_height=79.5;
/*[Rafter]*/
// (inches)
rib_spacing = 16.1;
// (inches) Rafter height needs to be adjusted to match the elipse height of the PVC Pipe
rafter_height = 27.1;
// (inches) Rafter angle needs to be adjusted to match the elipse height of the PVC Pipe
rafter_angle = 25.1;
/*[Quality]*/
// fn is the default number of facets to generate. This should be an even number 4 or more and less than 128. Four makes for a square everything, 80 or higher makes near perfect circles.
$fn=80;
/* [Debugging] */
explode_parts = false;


// ----------------
// constants 
// ----------------
// add this constant to all other constants so they are excluded from the customizer
C_Null=0+0;
//some calculations
building_width=building_width_ft*12;
building_length=building_length_ft*12;

//create the thing
#build_shed();

//-------------------------
// modules
//-------------------------
module build_shed(){
    explode([building_width,0,0],true,explode_parts){
        frame_base();
        translate([0,0,door_height+5]) frame_base();
        cinder_block_frame();
        #translate([0,building_length,0]){
            build_end_doors();
        }
        #translate([building_width,0,0]){
            build_side_doors();
        };
        build_pvc_ribbs();
        #build_end_doors();
        #build_side_doors();        
        build_rafters();
    }
}

module build_rafters(){
        //Length of building
        translate([1/2*building_width+3.5,3.5,door_height+5.5+rafter_height]) 2by6(building_length);      
        single_rafter();
        translate([0,building_length,0]) single_rafter();
}

module single_rafter(){
    //degree angled board one
    translate ([3,3.5,door_height+12]) 
        rotate([rafter_angle,0,-90])
            2by4(1/2*building_width+1/13*building_width);
    //degree angled board two
    mirror([90,0,0])
        translate ([
            -building_width-6,
            3.5,
            (door_height+12)
        ]) 
            rotate([rafter_angle,0,-90])
                2by4(1/2*building_width+1/13*building_width);
    //Verital Beam
    translate ([1/2*building_width+7,3.5,door_height+12]) 
        rotate([90,0,-90])
            2by6(rafter_height );
};


module build_pvc_ribbs(){
    pvc_ribb();
    horizontal_array( building_length/(rib_spacing),rib_spacing ,0
    ){ 
        pvc_ribb();
    };
};

module frame_base(){
    translate([3.25,3.25,8]){
        framed_2x4_box(
            building_width,
            building_length
        );    
    };
};

module build_end_doors(){
    number_of_doors_wide=(building_width_ft/(door_width/12));
    for ( i= [0:number_of_doors_wide-1]){
        translate([i*(door_width+2),0,0]){
            build_door_frame();
        };
    };
};


module build_side_doors(){
    number_of_doors_long=(building_length_ft/(door_width/12));
    rotate([0,0,90]){
        for ( i= [0:number_of_doors_long-1]){
            translate([i*(door_width+2),-3.5-3.5,0]){
                build_door_frame();
            };
        };
    };
};

module build_door_frame(){
    translate([3.5+1.5,3.15,8.1+3.5]){
        door();
        translate([-1.5-.25,1.5,-0.25]){
            rotate([90,0,0]){
                framed_2x4_box(
                    door_width+3.5,door_height+2
                );    
            };
        };
    };
};

module door(){
    difference(){
        cube([door_width,1.5,door_height]);
        translate([4.5,-.1,door_height/2-1.5]){
            cube([door_width-9,2,door_height/2-3]);
        }
    }
    
};

module pvc_ribb(){
    roof_height_to_width_ratio = 0.5;
    translate([
        building_width/2+3,
        3.5,
        door_height+13.5
    ]){
        rotate([90,0,0]){
            scale([1.0,roof_height_to_width_ratio ,1.0]){
                linear_extrude(1){
                    difference(){
                        circle(building_width/2);
                        union(){
                            circle(building_width/2-1.5);
                            mirror([0,90,0]){
                                square([building_width,building_width]);
                            };
                            mirror([90,90,0]){
                                square([building_width,building_width]);
                            };
                        };                    
                    };
                };
            };
        };
    };  
};

module cinder_block_frame(){
    blocks_long = building_length_ft/(16/12);
    blocks_wide = building_width_ft/(16/12);
    cinderblock_row(blocks_long);
    translate([building_width-1.5,0,0]){
        cinderblock_row(blocks_long);
    };
    translate([8.1,8,0]){
        rotate([0,0,-90]){
        cinderblock_row(blocks_wide);
        };    
    };
    translate([8.1,building_length+6.5,0]){
        rotate([0,0,-90]){
            cinderblock_row(blocks_wide);
        };    
    };
};

module cinderblock_row(number_blocks){
    cinder_block();
        horizontal_array(number_blocks-1,16.25,0){
            cinder_block();
        };
};

module vertical_array( occurance, distance, rotation_degrees ){
    for ( i= [1:1:occurance])  {
        translate([0,0,distance*i]) 
            rotate(a=rotation_degrees*i,v=[0,0,1])
                children();
    }
}

module horizontal_array( occurance, distance, rotation_degrees ){
    for ( i= [1:1:occurance])  {
        translate([0,distance*i,0]) 
            rotate(a=rotation_degrees*i,v=[0,0,1])
                children();
    };
};

module cinder_block(){
    difference(){
        cube([8,16,8]);
        translate([1.5,1.5,-0.5]){
            union(){
            cube([5,5.75,9]);
                translate([0,7.5,0]){
                    cube([5,5.75,9]);
                };
            };
        };
    };
};

module 2by4(inch_length){
    cube([1.5,inch_length,3.5]);
};

module 2by6(inch_length){
    cube([1.5,inch_length,5.5]);
};

module 2by8(inch_length){
    cube([1.5,inch_length,7.5]);
};

module 2by10(inch_length){
    cube([1.5,inch_length,9.5]);
};

module 2by12(inch_length){
    cube([1.5,inch_length,11.5]);
};

module 4by4(inch_length){
    cube([3.5,inch_length,3.5]);
};

module framed_4x4_box(inch_length,inch_width){
    4by4(inch_width);
    translate([0,1.5,0]){
        rotate([0,0,-90]){
            4by4(inch_length);
        };
    };
    translate([inch_length-3.5,1.5,0]){
        4by4(inch_width);
    };
    translate([0,inch_width+1.5,0]){
        rotate([0,0,-90]){
            4by4(inch_length);
        };
    };
};

module framed_2x4_box(inch_length,inch_width){
    2by4(inch_width);
    translate([0,1.5,0]){
        rotate([0,0,-90]){
            2by4(inch_length);
        };
    };
    translate([inch_length-1.5,0,0]){
        2by4(inch_width);
    };
    translate([0,inch_width,0]){
        rotate([0,0,-90]){
            2by4(inch_length);
        };
    };
};

// For debugging
// from https://github.com/mathcodeprint/openscad-fiddlybits/blob/master/explode.scad
module explode( distance, center, enable ) {
    if ( (enable) && (!center) ) {

        
     for ( i= [0:1:$children-1])   // step needed in case $children < 2                
        translate( [i*distance[0],i*distance[1],i*distance[2]] ) {
            children(i);
        } 
    }
    
    //CENTERED
    
    if ( (enable) && (center) ) {
        count = $children - 1;
        explode_start = ( [ (count*distance[0])/2 * -1, (count*distance[1])/2 *-1,(count*distance[2])/2 * -1 ] ) ;
        


        for ( i= [0:1:$children-1])   // step needed in case $children < 2  
        translate( explode_start ) {
            translate( [i*distance[0],i*distance[1],i*distance[2] ] ) {
                children(i);
            }    
        }
    }

    //NOT ENABLED - Include un-altered children

    if (!enable) {        
        for ( i= [0:1:$children-1]){   // step needed in case $children < 2     


            children(i);
        }         
    }
}
