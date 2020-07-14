// #87-3828 152mm 3m air hose:
// https://www.biltema.fi/rakentaminen/lvi/ilmanvaihto/ilmanvaihtoletkut/ilmanvaihtoletku-2000031439

// outmost hose dimension
hose_outer_diameter = 152;
// gap between the hose and the inner face of the pipe
thread_tolerance = 1;
// general rigidity of the structure
thickness = 2;

// this much overlap with the hose
length = 30;
// the flange where this is attached to something
flange_expansion = 10;
// a fillet between the pipe and the flange
flange_ease_radius = 3;

// keep this less than ~17mm
screw_depth = 8;
// teeth face on the visible side
screw_thickness = 1.5;
// teeth face on the pipe side
screw_thickness_body = 2;
// spacing between teeth
screw_lead = 3;
// Three shall be the number thou shalt count, and the number of the counting shall be three.
screw_rotations = 3;

inner_diameter = hose_outer_diameter + 2 * thread_tolerance;
outer_diameter = hose_outer_diameter + 2 * thickness;

// fight the z with 1% the feature size
eps = 0.01;
// very long
inf = 1000;

include <utils.scad>

// along x axis, right hand rule
function screw_track_point(r, lead, x) = [
	x/8.90123,
	r * cos(x),
	r * sin(x),
];

function screw_track(r, lead, xs) = [
	for (x=xs) screw_track_point(r, lead, x)
];

function rot(v, a) = [
	cos(a) * v[0] - sin(a) * v[1],
	sin(a) * v[0] + cos(a) * v[1]
];

function transformq(p, i) = p + [0, 0, i];

function rz(a) = [
	[1,      0,       0],
	[0, cos(a), -sin(a)],
	[0, sin(a),  cos(a)]
];

module screw_extrude(face, r, n) {
	face_size = len(face);
	track = screw_track(10, 360, [0:n-1]);
	/*
	pts = [
		for (trackpoint=track)
			for (p = face)
				[rot(p, 0)[0], rot(p, 0)[1], 0] + trackpoint
	];
	*/
	pts = [
		for (i=[0:n-1])
			for (p = face)
				rz(i) * [p[0], p[1], 0] + screw_track_point(10, 360, i)
	];

	//front_face = [0:face_size-1];
	//back_face = [len(pts)-1 - face_size:len(pts)-1];
	front_face = [[for (i=[0:face_size-1]) i]];
	back_face = [[for (i=[len(pts) - face_size:len(pts)-1]) i]];
	inner_faces = [
		for (begin_slice = [0:n-2])
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

module helix() {
	// clockwise
	cross_section = [
		[(screw_thickness_body - screw_thickness) / 2, 0],
		[screw_thickness - (screw_thickness_body - screw_thickness) / 2, 0],
		[screw_thickness, screw_depth],
		[0, screw_depth],
	];
	screw_extrude(cross_section, inner_diameter / 2, 90);
}

module body() {
	// flange (TODO: a few screw holes)
	#pipe(thickness, outer_diameter / 2 + flange_expansion, inner_diameter / 2 - eps);
	// main body
	#translate([0, 0, eps])
		pipe(length, outer_diameter / 2, inner_diameter / 2);
	// a concave fillet between the flange and the pipe body
	translate([0, 0, thickness]) {
		rotate_extrude($fa=5) {
			translate([outer_diameter / 2, 0, 0]) {
				difference() {
					square([flange_ease_radius, flange_ease_radius]);
					translate([flange_ease_radius, flange_ease_radius])
						circle(flange_ease_radius, $fn=90);
				}
			}
		}
	}
}

module flanged_screw() {
	//body();
	helix();
}

flanged_screw();
