// this attaches to the window end of the exhaust hose of a chinanordica
// "9000BTU" A007G-09C portable AC unit

// FIXME: use proper cylinder sectors instead of the cube simplification?
// the connector adapter
render_hose_part = true;
// the rain filter
render_outdoor_part = true;

// this adapter goes to a panel that replaces one of my window frames for the summer
// the previous hack had a 16cm hose
panel_hole_diameter = 160;
// a flange bit to keep the part close to the panel; "radius" dimension
collar_width = 7;
// the pipe goes through the panel
panel_thickness = 30;
// the bit between outer_diameter and panel_hole_diameter
expansion_length = 15;

// outermost dimension
outer_diameter = 152; // 151...152.8
// not inside the connector, but the outer part of the smaller bit that goes inside this adapter
inner_diameter = outer_diameter - 2 * 4.4;
// from the outer bit to the lock tooth lip with some margin
lock_notch_depth = 2.2;
// the tooth is a slope, this is the nonzero end
lock_tooth_thickness = 1.7;
// some margin so the locks don't need to be pushed all the way
lock_tooth_ease = 0.5 * lock_tooth_thickness;
// lock tooth size in the radial direction
tooth_width = 20;
// basically pipe_overlap - lock_notch_depth
tooth_height = 10;
// length of the smaller bit
pipe_overlap = 12.6;
// the collar where the hose screws into
outer_part_length = 30;
// for nice symmetry, outer + expansion = same as outer
pipe_full_length = outer_part_length - expansion_length;

// the window side part
flappipe_length = panel_thickness;
// doesn't need to be very heavy, just smooth
flappipe_thickness = 2;

// the two parts will rotate and clip on together
lockring_thickness = 1;
// thickness and some extra; calibrate this based on your layer height
lockring_groove = 1.2;
// how far the bit to snap against is from the end of the lock cutout
lockblob_distance = 5;

// fight the z
eps = 0.01;
// very long
inf = 1000;

module pipe2(h, outerr_r, outer_r, inner_r) {
	difference() {
		cylinder(h=h, r1=outer_r, r2=outerr_r, center=false, $fn=360);
		translate([0, 0, -eps])
			cylinder(h=h+2*eps, r1=inner_r, r2=inner_r, center=false, $fn=360);
	}
}

module pipe(h, outer_r, inner_r) {
	difference() {
		cylinder(h=h, r1=outer_r, r2=outer_r, center=false, $fn=360);
		translate([0, 0, -eps])
			cylinder(h=h+2*eps, r1=inner_r, r2=inner_r, center=false, $fn=360);
	}
}

module notch() {
	translate([0, -tooth_width / 2, 0]) {
		translate([0, 0, lock_notch_depth])
			cube([outer_diameter / 2 + eps, tooth_width, tooth_height]);
		translate([0, 0, -eps])
			cube([inner_diameter / 2 + lock_tooth_ease, tooth_width, tooth_height]);
	}
}

if (render_hose_part) {
	color("yellow") {
		difference() {
			pipe(pipe_full_length, outer_diameter / 2, inner_diameter / 2);
			union() {
				notch();
				rotate([0, 0, 360/3]) notch();
				rotate([0, 0, 2*360/3]) notch();
			}
		}
		translate([0, 0, pipe_full_length])
			pipe2(expansion_length, panel_hole_diameter / 2 + collar_width, outer_diameter / 2, inner_diameter / 2);
		translate([0, 0, pipe_full_length + expansion_length])
			pipe(panel_thickness, panel_hole_diameter / 2, inner_diameter / 2);
	}
}

// a pizza slice is under 90 degrees big and exists in the first quadant, lies on top of the x axis
module pizzamask(angle) {
	intersection() {
		// first quadrant
		translate([0, 0, -inf/2])
			cube([inf, inf, inf]);

		// from x axis counterclockwise
		rotate([0,0,angle-90]) translate([0, 0, -inf/2])
			cube([inf, inf, inf]);
	}
}

// a difference of two of these will glitch in the outer face no matter how big epsilon
module pizzapipe(h, outer_r, inner_r, angle) {
	intersection() {
		pipe(h, outer_r, inner_r);
		pizzamask(angle);
	}
}

// for matching pizza slice angles with mm dimensions
// a/360 * 2*pi*r = s
function angle_for_circumference(s, r) = 180 / PI * s / r;

if (render_outdoor_part) {
	translate([0, 0, pipe_full_length + expansion_length]) {
		color("green") {
			pipe(flappipe_length, inner_diameter / 2, inner_diameter / 2 - flappipe_thickness);
		}
		color("magenta") {
			// the sync ring
			translate([0,0, lockring_groove + lockring_thickness])
				pipe(1, inner_diameter / 2 + lockring_thickness, inner_diameter / 2);
			// the slider
			difference() {
				pizzapipe(lockring_groove + lockring_thickness,
						inner_diameter / 2 + lockring_thickness,
						inner_diameter / 2, 45);
				// cutout a bit higher and offset for the stop
				rotate([0, 0, -angle_for_circumference(lockring_thickness, inner_diameter / 2)]) {
					translate([0, 0, lockring_thickness]) { // groove will fit here
						pizzapipe(10, inner_diameter / 2 + lockring_thickness + eps, inner_diameter / 2 - eps, 45 + 2 * eps);
					}
				}
			}
			// the lock blob
			rotate([0,0,45-angle_for_circumference(lockblob_distance, inner_diameter / 2)])
			translate([inner_diameter / 2, 0, lockring_thickness]) {
				cylinder(h=lockring_groove, r=lockring_thickness / 2, $fs=0.1);
			}
		}
	}
}
