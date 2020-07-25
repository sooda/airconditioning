// cylinder minus inner cylinder
module pipe(h, outer_r, inner_r) {
	difference() {
		cylinder(h=h, r=outer_r, $fn=180);
		translate([0, 0, -eps])
			cylinder(h=h+2*eps, r=inner_r, $fn=180);
	}
}

// cone minus inner cylinder
module pipe_outer_bevel(h, outer_r1, outer_r2, inner_r) {
	difference() {
		cylinder(h=h, r1=outer_r1, r2=outer_r2, $fn=180);
		translate([0, 0, -eps])
			cylinder(h=h+2*eps, r=inner_r, $fn=180);
	}
}

// cylinder minus inner cone
module pipe_inner_bevel(h, outer_r, inner_r1, inner_r2) {
	difference() {
		cylinder(h=h, r=outer_r, $fn=180);
		translate([0, 0, -eps])
			cylinder(h=h+2*eps, r1=inner_r1, r2=inner_r2, $fn=180);
	}
}

// a pizza slice is under 90 degrees big and exists in the first quadant, lies on top of the x axis
module pizzamask(angle) {
	intersection() {
		// first quadrant
		translate([0, 0, -inf/2])
			cube([inf, inf, inf]);

		// from x axis counterclockwise
		rotate([0, 0, angle - 90])
			translate([0, 0, -inf/2])
				cube([inf, inf, inf]);
	}
}

// a difference of two of these may glitch in the outer face no matter how big epsilon,
// depending on your gpu driver version?? (in preview mode only)
module pizzapipe(h, outer_r, inner_r, angle) {
	render() // avoid exponential growth
	intersection() {
		pipe(h, outer_r, inner_r);
		pizzamask(angle);
	}
}

module pizzaslice(h, r, angle) {
	render() // avoid exponential growth
	intersection() {
		cylinder(h=h, r=r, $fn=180);
		pizzamask(angle);
	}
}

// for matching pizza slice angles with mm dimensions
// a/360 * 2*pi*r = s
function angle_for_circumference(s, r) = 180 / PI * s / r;

// along x axis, right hand rule
function thread_track_point(r, lead, a) = [
	a / 360 * lead,
	r * cos(a),
	r * sin(a),
];

function thread_track(r, lead, xs) = [
	for (x=xs) thread_track_point(r, lead, x)
];

function rz(a) = [
	[1,      0,       0],
	[0, cos(a), -sin(a)],
	[0, sin(a),  cos(a)]
];

// face_vertices shall be counterclockwise, as it'll be the underside: when
// looking from the top, this grows initially towards the viewer.
module thread_extrude(face_vertices, r, length, lead, rev_resolution) {
	face_size = len(face_vertices);
	revolutions = length / lead;
	// the track with n volume sections has n+1 face segments
	segments = rev_resolution * revolutions + 1;
	//track = thread_track(10, 360, [0:n-1]);
	pts = [
		for (i=[0:segments-1])
			for (p = face_vertices)
				rz(i / rev_resolution * 360) * [p[0], p[1], 0]
						+ thread_track_point(r, lead, i / rev_resolution * 360)
	];

	front_face = [[for (i=[0:face_size-1]) i]];
	back_face = [[for (i=[0:face_size-1]) len(pts) - 1 - i]];
	inner_faces = [
		for (begin_slice = [0:segments-2])
			for (begin_vert = [0:face_size-1]) [
				 begin_slice      * face_size + begin_vert,
				(begin_slice + 1) * face_size + begin_vert,
				(begin_slice + 1) * face_size + (begin_vert + 1) % face_size,
				 begin_slice      * face_size + (begin_vert + 1) % face_size
			]
	];
	faces = concat(front_face, inner_faces, back_face);
	polyhedron(pts, faces);
}

