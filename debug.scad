// this attaches to the window end of the exhaust hose of a chinanordica
// "9000BTU" A007G-09C portable AC unit

// model the tooth notch receptable as cylinder geometry, not cube
accurate_tooth = false;

// measurements of the existing hose attachment:

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

// fight the z with 1% the feature size
eps = 0.01;
// very long
inf = 1000;

// cylinder minus inner cylinder
module pipe(h, outer_r, inner_r) {
	difference() {
		cylinder(h=h, r=outer_r, $fa=10);
		translate([0, 0, -eps])
			cylinder(h=h+2*eps, r=inner_r, $fa=10);
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
	intersection() {
		pipe(h, outer_r, inner_r);
		pizzamask(angle);
	}
}

module pizzaslice(h, r, angle) {
	intersection() {
		cylinder(h=h, r=r, $fa=10);
		pizzamask(angle);
	}
}

// for matching pizza slice angles with mm dimensions
// a/360 * 2*pi*r = s
function angle_for_circumference(s, r) = 180 / PI * s / r;

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

module hose_part() {
	color("yellow") {
		// Change this difference to union to debug the slow rendering
		difference() {
			pipe(pipe_overlap, outer_diameter / 2, inner_diameter / 2);
			union() {
				if(1) // 2 -> 36 CSG elements
				lock_notch_receptable();
				if(0) // 36 -> 486 elements
				rotate([0, 0, 360/3])
					lock_notch_receptable();
				if(0) // 486 -> 5832 elements
				rotate([0, 0, 2*360/3])
					lock_notch_receptable();
				if(0) // 0 elements??
				rotate([0, 0, 1*360/6])
					lock_notch_receptable();
			}
		}
	}
}
hose_part();
