// use <MCAD/trochoids.scad>

ratio = 9; // inp/out ratio
inp_pin_dia = 4; // roller diameter (mm)
out_pin_dia = 4; // roller diameter (mm)
eccentricity = 1; // eccentricity (mm)
thick = 3;
mark_dia = 1;

// !!! override animation time !!!
// $t = 0;
// $t = (1/ratio) / ratio;

$fn = 30;               // number of circle segments
n_trochoid = 180;       // number of wedge segments

inp_pin_radius = inp_pin_dia/2;
out_pin_radius = out_pin_dia/2;

// pitch radius of the epitrochoid disc
disc_pitch_radius    = inp_pin_radius * (ratio+1);
// pitch radius of the fixed input pins
inp_pin_pitch_radius = inp_pin_radius * (ratio+2);
// TODO: revise
out_pin_pitch_radius = inp_pin_radius * (ratio-2);

inp_ang0 = 0;
inp_ang = inp_ang0 + $t * (360 * ratio);
out_ang0 = 0;
out_ang = inp_ang / -ratio;

//----
// fixed inp pins

inp_pin_cnt = ratio + 1;
inp_pin_incr_ang = 360 / inp_pin_cnt;
for (ii=[0:inp_pin_cnt - 1]) {
    color("green")
    rotate(ii * inp_pin_incr_ang)
    translate([inp_pin_pitch_radius,0,0])
    cylinder(
        h = thick,
        r = inp_pin_radius,
        center = true
    );
}

//----
// output pins

out_pin_cnt = ratio;
out_pin_incr_ang = 360 / out_pin_cnt;

rotate(out_ang)
translate([0,0,2*thick])
for (ii=[0:out_pin_cnt - 1]) {
  color("blue")
  rotate((ii+0.5) * out_pin_incr_ang)
  translate([out_pin_pitch_radius,0,0])
  cylinder(
    h = thick,
    r = out_pin_radius,
    center = true
  );
}
// difference() {
//   cylinder(
//     h = thick,
//     r = out_pin_pitch_radius + out_pin_radius,
//     center = true
//   );
//   cylinder(
//     h = thick,
//     r = out_pin_pitch_radius - out_pin_radius,
//     center = true
//   );
// }

//----
// epitrochoid disc

mark_radius = mark_dia/2;
timing_mark_radius = disc_pitch_radius - eccentricity - mark_radius;
rotate(inp_ang)
translate([eccentricity,0,0]) {
  rotate(-(1 + 1/ratio) * inp_ang) {
    // the disc
    translate([0,0,-1/2 * thick]) // center in z
    epitrochoid(
      R = disc_pitch_radius - inp_pin_radius,
      r = inp_pin_radius,
      d = eccentricity,
      n = n_trochoid,
      h = thick
    );
    // placeholder output holes
    // TODO: subtract these from the epitrochoid disc
    for (ii=[0:ratio-1]) {
      color("green")
      rotate((ii+0.5) * 360/ratio)
      translate([out_pin_pitch_radius,0,thick])
      cylinder(
        h = thick,
        r = out_pin_radius + eccentricity,
        center = true
      );
    }
    // timing mark
    color("blue")
    translate([timing_mark_radius,0,thick]) // place on surface of disc, on inside edge
    cylinder(
      h =  thick,
      r = mark_radius,
      center = true
    );
    // eccentric inp axis
    color("red")
    translate([0,0,thick]) // place on surface of disc
    cylinder(
      h =  thick,
      r = mark_radius,
      center = true
    );
  }
}

//----
// output holes in epitrochoid disc

//color("green")
// difference() {
  // epitrochoid_disc;
  // rotate($t*360)
  // for (ii=[0:ratio-1]) {
  //     rotate((ii+0.5)*360/ratio)
  //     translate([50,0,0])
  //     cylinder(
  //         h=(3*thick),
  //         r=out_pins+eccentricity,
  //         center=true
  //     );
  // }
// }

//===========================================
// Epitrochoid
//
// R: radius of fixed/inner circle
// r: radius of rolling/outer circle
// d: radius on rolling/outer circle to trace
// n: number of segments to approximate the curve
// h: extruded height
module epitrochoid(R, r, d, n, h) {
	incr_ang = 360/n;
  pitch_radius = R + r;

	for (ii = [0:n-1]) {
    ang0 = incr_ang * (ii - 0.5);
    ang1 = incr_ang * (ii + 0.5);
    x0 = pitch_radius*cos(ang0) - d*cos(pitch_radius/r*ang0);
    x1 = pitch_radius*cos(ang1) - d*cos(pitch_radius/r*ang1);
    y0 = pitch_radius*sin(ang0) - d*sin(pitch_radius/r*ang0);
    y1 = pitch_radius*sin(ang1) - d*sin(pitch_radius/r*ang1);
    polyhedron(
      points = [
        [ 0,  0,  0],
        [x0, y0,  0],
        [x1, y1,  0],
        [ 0,  0,  h],
        [x0, y0,  h],
        [x1, y1,  h],
      ],
      faces = [
        [0, 2, 1],
        [0, 1, 3],
        [3, 1, 4],
        [3, 4, 5],
        [0, 3, 2],
        [2, 3, 5],
        [1, 2, 4],
        [2, 5, 4]
      ]
    );
	}
}

/*
reference:
Title: "Building a Cycloidal Drive with SOLIDWORKS"
Author: Omar Younis
url: https://blogs.solidworks.com/teacher/wp-content/uploads/sites/3/Building-a-Cycloidal-Drive-with-SOLIDWORKS.pdf

E : eccentricity (offset from input shaft axis to center of rotor)
R : radius of the epitrochoid disc
Rr: radius of input pins
ratio: inp/out ratio

x(theta) =
  + R  * cos(theta)
  - Rr * cos(
    + theta
    + arctan(
      sin(-ratio * theta)
      /
      ( (R/EN) - cos(-ratio * theta) )
    )
  )
  - E  * cos( (ratio+1) * theta)

*/
