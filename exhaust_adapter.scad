// this attaches to the window end of the exhaust hose of a chinanordica
// "9000BTU" A007G-09C portable AC unit

// FIXME: use proper cylinder sectors instead of the cube simplification?

// this adapter goes to a panel that replaces one of my window frames for the summer
// the previous hack had a 16cm hose
panel_hole_diameter = 160;
// the pipe goes through the panel
panel_thickness = 30;

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
// also the length of the outer part for symmetry
pipe_full_length = 30;

// fight the z
eps = 0.01;

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

difference() {
	pipe(pipe_full_length, outer_diameter / 2, inner_diameter / 2);
	union() {
		notch();
		rotate([0, 0, 360/3]) notch();
		rotate([0, 0, 2*360/3]) notch();
	}
}
