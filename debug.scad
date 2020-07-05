// Fight the z. The magnitude doesn't affect the element count.
eps = 0.01;
// Big enough to cover the geometry. The magnitude doesn't affect the count.
inf = 1000;

extruded = true;

// Cylinder minus inner cylinder. This doesn't seem to be the problem (i.e.,
// it's as hard with just a cylinder); this is easier to visualize with the
// inside carved out.
module pipe(h, outer_r, inner_r) {
	difference() {
		cylinder(h=h, r=outer_r, $fa=10);
		translate([0, 0, -eps])
			cylinder(h=h+2*eps, r=inner_r, $fa=10);
	}
}

// A pizza slice is under 90 degrees big and exists in the first quadant. It
// lies on top of the x axis, grows counterclockwise.
module pizzamask(angle) {
	// linear_extrude makes the problem initially smaller, but the complexity
	// still grows exponentially
	if (!extruded) intersection() {
		// first quadrant
		translate([0, 0, -inf/2])
			cube([inf, inf, inf]);

		// from x axis ccw
		rotate([0, 0, angle - 90])
			translate([0, 0, -inf/2])
				cube([inf, inf, inf]);
	}
	else linear_extrude(height = inf) intersection() {
		square([inf, inf]);

		// from x axis ccw
		rotate([0, 0, angle - 90])
			square([inf, inf]);
	}
}

// a whole sector
module pizzaslice(h, r, angle) {
	intersection() {
		cylinder(h=h, r=r, $fa=10);
		pizzamask(angle);
	}
}

module holed_pizzacrust() {
	//union() { // visualize the subtraction elements
	difference() { // reproduce the problem
		pipe(10, 50, 40);
		// extruded: 0:0 -> 16, 0:1 -> 96, 0:2 -> 512, 0:3 -> 2560
		// !extruded: 0:0 -> 36, 0:1 -> 486, 0:2 -> 5832
		for (pos=[0:2]) {
			rotate([0, 0, pos*360/4]) {
				translate([0, 0, 1])
					pizzaslice(2, 50+eps, 15);
				translate([0, 0, 7])
					pizzaslice(2, 50+eps, 15);
			}
		}
	}
}

holed_pizzacrust();
