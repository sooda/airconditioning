// cylinder minus inner cylinder
module pipe(h, outer_r, inner_r) {
	difference() {
		cylinder(h=h, r=outer_r, $fn=180);
		translate([0, 0, -eps])
			cylinder(h=h+2*eps, r=inner_r, $fn=180);
	}
}

// cone minus inner cylinder
module pipe_outer_bevel(h, outer_r1, outer_r2, inner_r) {
	difference() {
		cylinder(h=h, r1=outer_r1, r2=outer_r2, $fn=180);
		translate([0, 0, -eps])
			cylinder(h=h+2*eps, r=inner_r, $fn=180);
	}
}

// cylinder minus inner cone
module pipe_inner_bevel(h, outer_r, inner_r1, inner_r2) {
	difference() {
		cylinder(h=h, r=outer_r, $fn=180);
		translate([0, 0, -eps])
			cylinder(h=h+2*eps, r1=inner_r1, r2=inner_r2, $fn=180);
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
	render() // avoid exponential growth
	intersection() {
		pipe(h, outer_r, inner_r);
		pizzamask(angle);
	}
}

module pizzaslice(h, r, angle) {
	render() // avoid exponential growth
	intersection() {
		cylinder(h=h, r=r, $fn=180);
		pizzamask(angle);
	}
}

// for matching pizza slice angles with mm dimensions
// a/360 * 2*pi*r = s
function angle_for_circumference(s, r) = 180 / PI * s / r;
