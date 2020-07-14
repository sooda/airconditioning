// this attaches to the window end of the exhaust hose of a chinanordica
// "9000BTU" A007G-09C portable AC unit

// FIXME: use proper cylinder sectors instead of the cube simplification?
// the connector adapter
render_hose_part = true;
// use this to check alignment
hose_translucent = true;
// the rain filter
render_outdoor_part = true;
// render the full pipe, turn off to see the lock parts
show_body = true;
// model the tooth notch receptable as cylinder geometry, not cube
accurate_tooth = true;

// measurements of the existing hose attachment:

// the collar where the hose screws into
outer_length = 30;
// outermost dimension
outer_diameter = 152; // 151...152.8
// not inside the connector, but the outer part of the smaller bit that goes inside this adapter
inner_diameter = outer_diameter - 2 * 4.4;
// from the outer bit to the lock tooth lip with some margin
lock_tooth_notch_depth = 2.2;
// the tooth is a slope, this is the nonzero end measured against inner_diameter
lock_tooth_thickness = 1.7;
// some margin so the locks don't need to be pushed all the way
lock_tooth_ease = 0.5 * lock_tooth_thickness;
// lock tooth size in the radial direction
tooth_width = 20;
// basically pipe_overlap - lock_tooth_notch_depth
tooth_height = 10;
// length of the smaller bit
pipe_overlap = 12.6;

// general body sizes:

// this adapter goes to a panel that replaces one of my window frames for the summer
// the previous hack had a 16cm hose and this goes to the same cutout
panel_hole_diameter = 160;
// the pipe goes through the panel
panel_thickness = 30;
// a flange bit to keep the part close to the panel; "radius" dimension
collar_width = 7;
// the collar bit aesthetic length between outer_diameter and panel_hole_diameter; like this for symmetry
collar_length = outer_length - pipe_overlap;
// before the collar, goes around the pipe_overlap bit with inner_diameter
// XXX: this is a bad name
pipe_full_length = pipe_overlap;//outer_length - collar_length;

// the "outdoor" side part that will have flaps of some sort to block rain:

// how much to reserve outside the panel hole to glue to the actual flap mechanism
flappipe_joinlength = 2;
// this goes inside the hose attachment adapter
flappipe_length = panel_thickness + flappipe_joinlength;
// doesn't need to be very heavy, just smooth. XXX: quantize according to your 3d printer nozzle
flappipe_thickness = 4;
// the inner diameter is consistent throughout the parts
flappipe_outer_diameter = inner_diameter + 2 * flappipe_thickness;

// the two pipes lock together slightly to ensure consistency:

// groove depth into the flap pipe. XXX: quantize according to your 3d printer nozzle
lockring_depth = 2;
// the two parts will rotate and clip on together; this is measured against the indoor end of the outdoor pipe
lockring_length = 2;
// length and some extra slop; XXX: quantize
lockring_groove_clearance = 0.2;
// consistent dimensions just with slop
lockring_groove = lockring_length + lockring_groove_clearance;
// how far the snap knob is from the end of the latch head, measured along the inner_diameter surface
lockblob_distance = 8;
// multiplier for how much bigger the notch is than the blob
lockblob_clearance = 1.05;
// how long the lock mechanism is around the cylinder surface
lockring_length_angle = 45;

// debug and dev stuff:

// use this to lift the inner bit out for debugging
parts_shift = 0;
//parts_shift = 1.5 * panel_thickness;

// angle for visual debugging of the lock knob
lockviz_delta = 0;

// fight the z with 1% the feature size
eps = 0.01;
// very long
inf = 1000;

include <utils.scad>

// a positive geometry to reduce from the indoor pipe body
module lock_notch_receptable() {
	if(!accurate_tooth) {
		// fast mode
		translate([0, -tooth_width / 2, 0]) {
			translate([0, 0, lock_tooth_notch_depth]) {
				// the hole bit
				cube([outer_diameter / 2 + eps, tooth_width, tooth_height]);
			}
			translate([0, 0, -eps]) {
				// the ease bit measured from the floor of the pipe
				cube([inner_diameter / 2 + lock_tooth_ease + eps, tooth_width, tooth_height]);
			}
		}
	} else {
		// this way makes the preview extremely slow, and buggy depending on the view angle and the
		// below choices, or makes the whole design disappear. The render will be fine though. I'll
		// debug why some day. Might be a bug/feature with the huge boxes in the pizza pipe.
		// Swap the inner true to false to use pizza pipes and the whole preview vanishes.

		if (true) translate([0, 0, lock_tooth_notch_depth]) {
			// the hole bit
			if (true) {
				pizzaslice(tooth_height,
					outer_diameter / 2 + eps,
					angle_for_circumference(tooth_width, inner_diameter / 2));
			} else {
				pizzapipe(tooth_height,
					outer_diameter / 2 + eps,
					inner_diameter / 2 - eps,
					angle_for_circumference(tooth_width, inner_diameter / 2));
			}
		}
		if (true) translate([0, 0, -eps]) {
			// the ease bit measured from the floor of the pipe
			if (true) {
				pizzaslice(lock_tooth_notch_depth + 2*eps,
					inner_diameter / 2 + lock_tooth_ease,
					angle_for_circumference(tooth_width, inner_diameter / 2));
			} else {
				pizzapipe(lock_tooth_notch_depth + 2*eps,
					inner_diameter / 2 + lock_tooth_ease,
					inner_diameter / 2 - eps,
					angle_for_circumference(tooth_width, inner_diameter / 2));
			}
		}
	}
}

// the indoor side of the pipe locking mechanism
module latchpin(angle) {
	translate([0, 0, lockring_length + lockring_groove_clearance / 2]) {
		// rotate away from the stop bit
		rotate([0, 0, angle - angle_for_circumference(lockring_length, inner_diameter / 2)]) {
			difference() {
				// the pin itself. The added epsilon gets rid of flickering that supposedly comes
				// from the pin pizza CSGing exactly against the pipe surface; although it's a
				// separate operation, it gets visible and might cause some nasty zero-size
				// geometry? Again, it would be nice to be able to constraint this on exactly the
				// inner surface, but here we are with floating point math.
				pizzapipe(lockring_length,
						flappipe_outer_diameter / 2 + eps,
						flappipe_outer_diameter / 2 - lockring_depth,
						lockring_length_angle);
				// the lock notch cut away from the pin
				rotate([0, 0, lockring_length_angle
						- angle_for_circumference(lockblob_distance - lockring_length, inner_diameter / 2)]) {
					// FIXME: make some of the geometry common for the pin and the groove
					translate([flappipe_outer_diameter / 2 - lockring_depth, 0, -eps]) {
						cylinder(h=lockring_length + 2*eps,
							r=lockblob_clearance * lockring_depth / 2,
							$fs=0.1);
					}
				}
			}
		}
	}
}

// the outdoor side of the pipe locking mechanism
module lockslider(angle) {
	translate([0, 0, eps]) // fuck that flicker and wrong colors on surfaces
	rotate([0, 0, angle]) {
		// the slider including the end stop
		difference() {
			// yes, +eps. This ensures the surface goes inside the other
			pizzapipe(lockring_length + lockring_groove + eps,
					flappipe_outer_diameter / 2,
					flappipe_outer_diameter / 2 - lockring_depth - eps,
					lockring_length_angle);
			// the pin groove is a bit higher and offset for the stop
			rotate([0, 0, -angle_for_circumference(lockring_length, inner_diameter / 2)]) {
				translate([0, 0, lockring_length]) {
					pizzapipe(lockring_groove + 2 * eps,
						flappipe_outer_diameter / 2 + eps,
						flappipe_outer_diameter / 2 - lockring_depth - 2 * eps,
						lockring_length_angle);
				}
			}
		}
		// the lock blob
		rotate([0, 0, lockring_length_angle
				- angle_for_circumference(lockblob_distance, inner_diameter / 2)]) {
			translate([flappipe_outer_diameter / 2 - lockring_depth, 0, lockring_length]) {
				cylinder(h=lockring_groove, r=lockring_depth / 2, $fs=0.1);
			}
		}
	}
}

module hose_part() {
	if (show_body) {
		color("yellow") {
			// Change this difference to union to debug the slow rendering
			difference() {
				pipe(pipe_full_length, outer_diameter / 2, inner_diameter / 2);
				render()
				union() {
					lock_notch_receptable();
					rotate([0, 0, 360/3])
						lock_notch_receptable();
					rotate([0, 0, 2*360/3])
						lock_notch_receptable();
				}
			}
			// the collar goes from the interface bit to the face of the panel.
			// why does the epsilon trick not help here with that hot pixel flicker on the inner face?
			translate([0, 0, pipe_full_length - eps])
				pipe_outer_bevel(eps + collar_length,
					outer_diameter / 2,
					panel_hole_diameter / 2 + collar_width,
					inner_diameter / 2);
			// the bit inside the panel. The inner diameter grabs to the outdoor pipe
			translate([0, 0, pipe_full_length + collar_length - eps])
				pipe(eps + panel_thickness,
					panel_hole_diameter / 2,
					flappipe_outer_diameter / 2);
		}
	}

	color("blue") {
		// note: no stop ring needed - the panel part is larger inside to fit the outdoor pipe
		translate([0, 0, pipe_full_length + collar_length]) {
			// the latch pins hover above the stop ring
			latchpin(0);
			latchpin(180);
		}
	}
}

module outdoor_part() {
	// this part is positioned exactly at the panel face
	translate([0, 0, pipe_full_length + collar_length]) {
		if (show_body) {
			color("green") {
				difference() {
					pipe(flappipe_length,
						flappipe_outer_diameter / 2,
						inner_diameter / 2);
					// cut out a bit for the lock mechanism
					translate([0, 0, -eps])
						pipe(lockring_length + lockring_groove + 2*eps,
								flappipe_outer_diameter / 2 + eps,
								flappipe_outer_diameter / 2 - lockring_depth);
				}
			}
		}
		color("magenta") {
			lockslider(0);
			lockslider(180);
		}
	}
}

if (render_hose_part) {
	if (hose_translucent)
		#hose_part();
	else
		hose_part();
}

if (render_outdoor_part) {
	translate([0, 0, parts_shift])
		rotate([0, 0, lockviz_delta])
			outdoor_part();
}
