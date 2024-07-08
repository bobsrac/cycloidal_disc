ratio = 9; // inp/out ratio
inp_shaft_dia = 8; // roller diameter (mm)
inp_pin_dia = 4; // roller diameter (mm)
out_pin_dia = 4; // roller diameter (mm)
eccentricity = 1; // eccentricity (mm)
thick = 3;
mark_dia = 1;

simulate = false;
if (simulate) {
  $fn        =  60; // number of circle segments
  n_trochoid = 180; // number of wedge segments
} else {
  $t = 0;
  $fn        = 1440; // number of circle segments
  n_trochoid = 1440; // number of wedge segments
}

inp_pin_radius = inp_pin_dia/2;
out_pin_radius = out_pin_dia/2;

// pitch radius of the epitrochoid disc
disc_pitch_radius    = inp_pin_radius * (ratio+1);
// pitch radius of the fixed input pins
inp_pin_pitch_radius = disc_pitch_radius;
// pitch radius of the output pins coupled to output shaft
out_pin_pitch_radius = inp_pin_radius * (ratio-2.75);

inp_ang0 = 0;
inp_ang = inp_ang0 + $t * (360 * ratio);
out_ang0 = 0;
out_ang = inp_ang / -ratio;

//----
// fixed inp pins

inp_pin_cnt = ratio + 1;
inp_pin_incr_ang = 360 / inp_pin_cnt;

if (simulate) {
// for (ii=[0:inp_pin_cnt - 1]) {
//     color("green")
//     rotate(ii * inp_pin_incr_ang)
//     translate([inp_pin_pitch_radius,0,0])
//     cylinder(
//         h = thick,
//         r = inp_pin_radius,
//         center = true
//     );
// }
}

//----
// output pins

out_pin_cnt = ratio;
out_pin_incr_ang = 360 / out_pin_cnt;

if (simulate) {
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
}

//----
// epitrochoid disc

mark_radius = mark_dia/2;
timing_mark_radius = disc_pitch_radius - inp_pin_radius - eccentricity - 1*mark_radius;
rotate(inp_ang)
translate([eccentricity,0,0]) {
  rotate(-(1 + 1/ratio) * inp_ang) {
    difference() {
      // the disc
      cycloidal_disc(
        inp_pin_pitch_radius = inp_pin_pitch_radius, // pitch radius of the disc
        inp_pin_radius       = inp_pin_radius   , // radius of the (ratio+1) input pins
        eccentricity         = eccentricity     , // eccentricity (distance of the disc center from the input shaft axis)
        ratio                = ratio            , // gear ratio
        n                    = n_trochoid       , // number of segments to approximate the curve
        height               = thick              // extruded height
      );
      // eccentric inp axis
      cylinder(
        h = 2 * thick,
        r = inp_shaft_dia,
        center = true
      );
      // output holes
      for (ii=[0:ratio-1]) {
        rotate((ii+0.5) * 360/ratio)
        translate([out_pin_pitch_radius,0,0])
        cylinder(
          h = 2 * thick,
          r = out_pin_radius + eccentricity,
          center = true
        );
      }
      // timing mark
      rotate(360/(4*ratio))
      translate([timing_mark_radius,0,0]) // place on surface of disc, on inside edge
      cylinder(
        h = 2 * thick,
        r = mark_radius,
        center = true
      );
    }
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

/* Cycloidal Gearbox Disc Extrusion

  NOTE: I am aware of the existence of the trochoids library module epitrochoid, but this isn't
  actually the curve for a cycloidal gearbox disc, and the sampling method used there injects a
  systematic error of undersized lobes and oversized troughs. This module uses a cubic spline to
  eliminate that bias.

  reference:
  Title: "Building a Cycloidal Drive with SOLIDWORKS"
  Author: Omar Younis
  url: https://blogs.solidworks.com/teacher/wp-content/uploads/sites/3/Building-a-Cycloidal-Drive-with-SOLIDWORKS.pdf

  E : eccentricity (offset from input shaft axis to center of rotor)
  R : radius of the epitrochoid disc
  Rr: radius of input pins
  ratio: inp/out ratio

  NOTE: theta is clockwise in the reference's equations, hence major term of y is negative.  That
  has been converted to a counter-clockwise angle in this module.

  x(theta) =
    + R  * cos(theta)
    - Rr * cos(
      theta
      + arctan(
        sin(-ratio * theta)
        /
        ( (R/EN) - cos(-ratio * theta) )
      )
    )
    - E  * cos( (ratio+1) * theta)

  y(theta) =
    - R  * sin(theta)
    + Rr * sin(
      theta
      + arctan(
        sin(-ratio * theta)
        /
        ( (R/EN) - sin(-ratio * theta) )
      )
    )
    + E  * sin( (ratio+1) * theta)
*/
module cycloidal_disc(
  inp_pin_pitch_radius, // radius of the (ratio+1) input pins
  inp_pin_radius      , // radius of the (ratio+1) input pins
  eccentricity        , // eccentricity (distance of the disc center from the input shaft axis)
  ratio               , // gear ratio
  n                   , // number of segments to approximate the curve
  height                // extruded height
) {
	incr_ang = 360/n;
  // echo("R_pitch: ", pitch_radius);
  // echo("incr_ang: ", incr_ang);

  function dang(
    inp_pin_pitch_radius  , // pitch radius of the disc
    inp_pin_radius, // radius of the (ratio+1) input pins
    eccentricity  , // eccentricity (distance of the disc center from the input shaft axis)
    ratio         , // gear ratio
    theta           // degrees
  ) =
      -theta
      + atan(
        sin(ratio * theta)
        /
        ( inp_pin_pitch_radius/eccentricity/(ratio+1) - cos(ratio * theta) )
      );

  function surface_x(
    inp_pin_pitch_radius  , // pitch radius of the disc
    inp_pin_radius, // radius of the (ratio+1) input pins
    eccentricity  , // eccentricity (distance of the disc center from the input shaft axis)
    ratio         , // gear ratio
    theta           // degrees
  ) =
    inp_pin_pitch_radius * cos(theta)
    - inp_pin_radius * cos(dang(inp_pin_pitch_radius, inp_pin_radius, eccentricity, ratio, theta))
    - eccentricity * cos((ratio+1) * theta);

  function surface_y(
    inp_pin_pitch_radius  , // pitch radius of the disc
    inp_pin_radius, // radius of the (ratio+1) input pins
    eccentricity  , // eccentricity (distance of the disc center from the input shaft axis)
    ratio         , // gear ratio
    theta           // degrees
  ) =
    inp_pin_pitch_radius * sin(theta)
    + inp_pin_radius * sin(dang(inp_pin_pitch_radius, inp_pin_radius, eccentricity, ratio, theta))
    - eccentricity * sin((ratio+1) * theta);

  // returns x(0.5) given [x(-1), x(0), x(1), x(2)]
  function intrp(
    x // [x(-1), x(0), x(1), x(2)]
  ) = x[0]/-16 + 9/16*x[1] + 9/16*x[2] + -x[3]/16;

  // Extrude a polygon.  By placing the polygon vertices on the ideal curve, we will be undersized
  // near the outer tips of the lobes and oversized near the troughs.  To eliminate this
  // nonlinearity, we will sample the ideal curve, then use a cubic spline over the previous two
  // and next two points to generate the polygon vertices.

  all_ang = [ for(jj=[0:n-1]) jj*incr_ang ];
  // all_cos_dang = [ for(jj=[0:n-1]) cos(dang(inp_pin_pitch_radius, inp_pin_radius, eccentricity, ratio, all_ang[jj])) ];
  all_x   = [ for(jj=[0:n-1]) surface_x(inp_pin_pitch_radius, inp_pin_radius, eccentricity, ratio, all_ang[jj]) ];
  all_y   = [ for(jj=[0:n-1]) surface_y(inp_pin_pitch_radius, inp_pin_radius, eccentricity, ratio, all_ang[jj]) ];
  // echo("ang      : ", all_ang);
  // echo("cos(dang): ", all_cos_dang);
  // echo("all_x: ", all_x);
  // echo("all_y: ", all_y);

	for (ii = [0:n-1]) {
    // ang_start = incr_ang * (ii - 0.5);
    // ang_end   = incr_ang * (ii + 0.5);

    x03 = [ for(jj=[-2:1]) all_x[((ii+jj)+n) % n] ];
    x14 = [ for(jj=[-1:2]) all_x[((ii+jj)+n) % n] ];
    y03 = [ for(jj=[-2:1]) all_y[((ii+jj)+n) % n] ];
    y14 = [ for(jj=[-1:2]) all_y[((ii+jj)+n) % n] ];

    // echo("x03: ", x03);
    // echo("x14: ", x14);
    // echo("y03: ", y03);
    // echo("y14: ", y14);

    xs = intrp(x03);
    xe = intrp(x14);
    ys = intrp(y03);
    ye = intrp(y14);
    
    // echo("xs, xe, ys, ye: ", xs, xe, ys, ye);
    //
    polyhedron(
      points = [
        [ 0,  0,  -height/2], // 0
        [xs, ys,  -height/2], // 1
        [xe, ye,  -height/2], // 2
        [ 0,  0,  +height/2], // 3
        [xs, ys,  +height/2], // 4
        [xe, ye,  +height/2], // 5
      ],
      faces = [
        [0, 2, 1], // bottom
        [0, 1, 3], // ang0 vert-face, lower/inner-triangle
        [3, 1, 4], // ang0 vert-face, upper/outer-triangle
        [3, 4, 5], // top
        [0, 3, 2], // ang1 vert-face, lower/inner-triangle
        [2, 3, 5], // ang1 vert-face, upper/outer-triangle
        [1, 2, 4], // outer_face, lower/angs-triangle
        [2, 5, 4]  // outer_face, upper/ange-triangle
      ]
    );
	}
}
