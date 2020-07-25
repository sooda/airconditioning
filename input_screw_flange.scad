// #87-3828 152mm 3m air hose:
// https://www.biltema.fi/rakentaminen/lvi/ilmanvaihto/ilmanvaihtoletkut/ilmanvaihtoletku-2000031439

// outmost hose dimension
hose_outer_diameter = 152;
// gap between the hose and the inner face of the pipe
thread_tolerance = 2;
// general rigidity of the structure
thickness = 2;

// this much overlap with the hose
length = 30;
// the flange where this is attached to something
flange_expansion = 13;
// a fillet between the pipe and the flange
flange_ease_radius = 3;
// the flanged bit is screwed to an air box
mounting_hole_diameter = 4.4;
// Five is right out.
mounting_hole_count = 6;

// FIXME: the thread cuts off in a straight angle at the end where the hose is screwed on. It gets
// easily stuck on the hose plastic, so a tapered cut on the beginning would be nice.

// keep this less than ~17mm
thread_depth = 8;
// thread face dimension on the visible (hose) side. A trapezoidal cross section may cause your slicer to generate a more complex thread surface that will slide easier but is a pain to clean up from the supports.
thread_thickness_side = 1.5;
// thread face dimension on the pipe side
thread_thickness_body = 3;
// spacing between facing thread faces to contribute to the lead aka pitch, compare against the hose flex
thread_spacing = 4;
thread_lead = thread_thickness_body + thread_spacing;
// Three shall be the number thou shalt count, and the number of the counting shall be three.
thread_revolutions = 3;

thread_length = thread_lead * thread_revolutions;

inner_diameter = hose_outer_diameter + 2 * thread_tolerance;
outer_diameter = inner_diameter + 2 * thickness;

// fight the z with 1% the feature size
eps = 0.01;
// very long
inf = 1000;

include <utils.scad>

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

module helix() {
	//     body
	//    ______
	// ^ \      /
	// y  \____/
	// |   side
	// +--x> (not to scale)
	// ccw
	cross_section = [
		[(thread_thickness_body - thread_thickness_side) / 2, 0],
		[(thread_thickness_body - thread_thickness_side) / 2 + thread_thickness_side, 0],
		[thread_thickness_body, thread_depth],
		[0, thread_depth],
	];
	translate([0, 0, length - thread_length - thread_thickness_body]) {
		rotate([0, -90, 0]) {
			thread_extrude(cross_section,
				inner_diameter / 2 - thread_depth + 0.05, // XXX: beware of gaps, depends on face count
				thread_length, thread_lead, 360/2);
		}
	}
}

module body() {
	// main body
	translate([0, 0, eps])
		pipe(length, outer_diameter / 2, inner_diameter / 2);
	difference() {
		// flange
		pipe(thickness, outer_diameter / 2 + flange_expansion, inner_diameter / 2 - eps);
		// mount holes
		translate([0, 0, -eps]) {
			for (angle=[0:360/mounting_hole_count:360]) {
				rotate([0, 0, angle])
					translate([outer_diameter / 2 +
							flange_ease_radius +
							(flange_expansion - flange_ease_radius) / 2, 0, 0])
					cylinder(h=inf, r=mounting_hole_diameter / 2, $fn=90);
			}
		}
	}
	// a concave fillet between the flange and the pipe body
	translate([0, 0, thickness - eps]) {
		rotate_extrude($fa=2) {
			translate([outer_diameter / 2, 0, 0]) {
				difference() {
					square([flange_ease_radius, flange_ease_radius]);
					translate([flange_ease_radius, flange_ease_radius])
						circle(flange_ease_radius, $fn=60);
				}
			}
		}
	}
}

module flange_nut() {
	body();
	helix();
}

flange_nut();
