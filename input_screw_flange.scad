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
screw_revolutions = 3;
screw_length = screw_lead * screw_revolutions;

inner_diameter = hose_outer_diameter + 2 * thread_tolerance;
outer_diameter = hose_outer_diameter + 2 * thickness;

// fight the z with 1% the feature size
eps = 0.01;
// very long
inf = 1000;

include <utils.scad>

// along x axis, right hand rule
function screw_track_point(r, lead, a) = [
	a / 360 * lead,
	r * cos(a),
	r * sin(a),
];

function screw_track(r, lead, xs) = [
	for (x=xs) screw_track_point(r, lead, x)
];

function rz(a) = [
	[1,      0,       0],
	[0, cos(a), -sin(a)],
	[0, sin(a),  cos(a)]
];

module screw_extrude(face_vertices, r, length, lead, rev_resolution) {
	face_size = len(face_vertices);
	revolutions = length / lead;
	// the track with n volume sections has n+1 face segments
	segments = rev_resolution * revolutions + 1;
	//track = screw_track(10, 360, [0:n-1]);
	pts = [
		for (i=[0:segments-1])
			for (p = face_vertices)
				rz(i / rev_resolution * 360) * [p[0], p[1], 0]
						+ screw_track_point(r, lead, i / rev_resolution * 360)
	];

	front_face = [[for (i=[0:face_size-1]) i]];
	back_face = [[for (i=[len(pts) - face_size:len(pts)-1]) i]];
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

module helix() {
	// clockwise
	cross_section = [
		[(screw_thickness_body - screw_thickness) / 2, 0],
		[screw_thickness - (screw_thickness_body - screw_thickness) / 2, 0],
		[screw_thickness, screw_depth],
		[0, screw_depth],
	];
	screw_extrude(cross_section, inner_diameter / 2, screw_length, screw_lead, 360/5);
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
