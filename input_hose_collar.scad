// #87-3828 152mm 3m air hose:
// https://www.biltema.fi/rakentaminen/lvi/ilmanvaihto/ilmanvaihtoletkut/ilmanvaihtoletku-2000031439

// This piece goes directly through the window panel! The two-piece construction on the exhaust hose
// is just to match and reuse the existing collar on it.

// make the outer body translucent
debug_threads = true;

// outmost hose dimensions, by chance it's the same as the outer diameter of the exhaust hose collar
hose_outer_diameter = 152;
// gap between the hose and the inner face of the pipe
thread_tolerance = 2;
// 160 mm matches the other window panel hole and thickness becomes 2 mm
outer_diameter = 160;

// the outer dimension is more important than this one, although do mind this as well
thickness = (outer_diameter - hose_outer_diameter) / 2 - thread_tolerance;

// this much overlap with the hose
visible_length = 30;

// the pipe goes through the panel and an outdoor part aligns with this inner face
panel_thickness = 30;
// a flange bit to keep the part close to the panel; "radius" dimension
collar_width = 7;
// The collar overlaps with the threaded bit and is this long before reaching the window panel face. Some flat is left for better finger grip
collar_length = 20;

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
thread_inner_diameter = inner_diameter - 2 * thread_depth;

// fight the z with 1% the feature size
eps = 0.01;
// very long
inf = 1000;

include <utils.scad>

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
	translate([0, 0, 0]) {
		difference() {
			rotate([0, -90, 0]) {
				thread_extrude(cross_section,
					inner_diameter / 2 - thread_depth + 0.05, // XXX: beware of gaps, depends on face count
					thread_length, thread_lead, 360/2);
			}
			// Make the thread tip less blunt by cutting off a slice at an angle. The cut size is
			// chosen for aesthetic reasons to align smoothly to the thread's inner face. The cut
			// begins from the very end and meets the inner face in parallel, forming a 90 degree
			// angle with a line that goes towards the center.
			//
			// This messes up the preview pretty badly depending on the view angle, no clue what
			// that's about.
			//
			// This is also not super general, might not work with very tight threads due to the cut
			// bit being aligned to the very top. These threads are not parallel to the cube face.
			translate([0, 0, -thread_spacing / 2]) {
				// Thanks, Pythagoras
				cut_length = sqrt(pow(inner_diameter / 2, 2) - pow(thread_inner_diameter / 2, 2));
				// law of sines
				cut_triangle_angle = asin(cut_length / (inner_diameter / 2));
				rotate([0, 0, cut_triangle_angle]) {
					cube([
						thread_inner_diameter / 2 + eps,
						thread_inner_diameter / 2,
						thread_thickness_body + thread_spacing]
					);
				}
			}
		}
	}
}

module outer_body() {
	pipe(visible_length + panel_thickness, outer_diameter / 2, inner_diameter / 2);
	translate([0, 0, visible_length - collar_length]) {
		pipe_outer_bevel(collar_length,
			outer_diameter / 2,
			outer_diameter / 2 + collar_width,
			inner_diameter / 2 + eps);
	}
}

module threaded_body() {
	if (debug_threads) {
		#outer_body();
	} else {
		outer_body();
	}
	helix();
}

module hose_collar() {
	threaded_body();
}

hose_collar();
