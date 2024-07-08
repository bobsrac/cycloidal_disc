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
