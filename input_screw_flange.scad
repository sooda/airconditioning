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

module helix() {
	linear_extrude(height=screw_rotations * screw_lead,
			twist=-360 * screw_rotations,
			slices=50 * screw_rotations)
		translate([hose_outer_diameter / 2 - screw_depth, 0, 0])
			square([screw_depth + eps, screw_thickness]); // FIXME: thickness doesn't work like this
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
	body();
	translate([0, 0, 40])
	helix();
}

flanged_screw();
