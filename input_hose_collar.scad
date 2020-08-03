// #87-3828 152mm 3m air hose:
// https://www.biltema.fi/rakentaminen/lvi/ilmanvaihto/ilmanvaihtoletkut/ilmanvaihtoletku-2000031439

// This piece goes directly through the window panel! The two-piece construction on the exhaust hose
// is just to match and reuse the existing collar on it.

// the collar itself
render_hose_part = true;
// use this to check alignment and to debug the threads
hose_translucent = true;
// the rain filter
render_outdoor_part = true;

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

// how much to reserve outside the panel hole to glue to the actual flap mechanism
flappipe_joinlength = 2;
// this goes inside the hose attachment adapter
flappipe_length = panel_thickness + flappipe_joinlength;
// doesn't need to be very heavy, just smooth
flappipe_thickness = 2;
// there has to be some slop so the flap pipe that goes inside can be inserted smoothly
flappipe_tolerance = 0.2;
// the inner diameter is NOT consistent throughout the parts because the outer body is so thin
flappipe_outer_diameter = inner_diameter - 2 * flappipe_tolerance;
flappipe_inner_diameter = flappipe_outer_diameter - 2 * flappipe_thickness;
// how much until full thickness
flappipe_bevel_length = 10;
// how much to take off from flappipe_thickness
flappipe_bevel_thickness = 2;

// the knob to join the indoor and outdoor parts is situated in the outdoor border and is this big
lockknob_diameter = 10;
// insertion depth
lockslot_depth = 20;
// "tangential" length along the side
lockslot_length = 30;
// total slop, not in "both sides" like the others here
lockslot_clearance = 0.1;
// "negative" clearance on the edge where the locking action should happen. This tiny fit blob is likely unnecessary, but let's see what happens with it.
lockslot_tightfit = 0.2;

// use this to lift the inner bit out for debugging
parts_shift = 0;
// angle for visual debugging of the lock knob
lockviz_delta = 0;

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

module lockknob_receptable(angle) {
	lockknob_ang = angle_for_circumference(lockknob_diameter + 2 * lockslot_clearance, inner_diameter / 2);
	lockslot_length_ang = angle_for_circumference(lockslot_length, inner_diameter / 2);
	rotate([0, 0, angle - lockknob_ang / 2]) {
		// cut down for the insertion slot
		pizzaslice(lockslot_depth, inf, lockknob_ang);
		difference() {
			// cut along the main cylinder for rotation, ccw for cw locking
			pizzaslice(lockknob_diameter + 2 * lockslot_clearance, inf, -(lockknob_ang + lockslot_length_ang));
			// add back the tiny lock blob. This is not exactly the right position at the end, but
			// doesn't matter, it's close enough, or might not even exist depending on your print slicing.
			rotate([0, 0, -(lockslot_length_ang + 0.25 * lockknob_ang)])
				rotate([0, 90, 0])
					cylinder(h=2*inf, r=lockslot_clearance + lockslot_tightfit, $fn=30);
		}
	}
}

module hose_body() {
	difference() {
		pipe(visible_length + panel_thickness, outer_diameter / 2, inner_diameter / 2);
		translate([0, 0, visible_length + panel_thickness - lockslot_depth + eps]) {
			lockknob_receptable(0);
			lockknob_receptable(180);
		}
	}
	translate([0, 0, visible_length - collar_length]) {
		pipe_outer_bevel(collar_length,
			outer_diameter / 2,
			outer_diameter / 2 + collar_width,
			inner_diameter / 2 + eps);
	}
}

module threaded_body() {
	if (hose_translucent) {
		#hose_body();
	} else {
		hose_body();
	}
	helix();
}

module lockknob(ang) {
	rotate([0, 0, ang]) {
		translate([flappipe_inner_diameter / 2, 0, 0])
		rotate([0, 90, 0]) {
			// XXX: should be a half cone maybe
			cylinder(flappipe_thickness + thickness, r=lockknob_diameter / 2, $fs=0.1);
		}
	}
}

module outdoor_part() {
	// this part is positioned exactly at the panel face
	translate([0, 0, visible_length]) {
		if (true) {
			color("green") {
				difference() {
					pipe(flappipe_length,
						flappipe_outer_diameter / 2,
						flappipe_inner_diameter / 2);
					translate([0, 0, -eps])
					pipe_inner_bevel(flappipe_bevel_length,
						flappipe_outer_diameter / 2 + eps,
						flappipe_outer_diameter / 2 - flappipe_bevel_thickness,
						flappipe_outer_diameter / 2
						);
				}
			}
		}
		color("magenta") {
			translate([0, 0, panel_thickness - 3 * lockknob_diameter / 2]) {
				lockknob(0);
				lockknob(180);
			}
		}
	}
}

module hose_collar() {
	if (render_hose_part)
		threaded_body();
	if (render_outdoor_part)
	translate([0, 0, parts_shift])
		rotate([0, 0, lockviz_delta])
			outdoor_part();
}

hose_collar();
