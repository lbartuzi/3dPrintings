/*
  Modular rectangular-to-round duct adapter for 200x200x200 mm printer
  --------------------------------------------------------------------
  Units: millimetres

  Target dimensions:
  - Circular outlet: 200 mm external diameter, 190 mm internal diameter
  - Rectangular inlet: 310 x 130 mm internal opening
  - Rectangular flange: 20 mm flat flange on every side
  - Split into 3 printable pieces along the long 310 mm direction

  Usage:
  - Set show_part = "left", "middle", or "right" and export each STL separately.
  - show_part = "all" shows the 3 pieces slightly separated for checking.
  - show_part = "complete" shows the unsplit duct.

  Printer fit:
  - Each split part is about 117 x 200 x 159 mm.
  - 200 mm OD is exactly at the bed limit. If needed set:
      circle_od = 198;
      circle_id = 188;

  PETG suggestion:
  - Print upright, rectangular flange on build plate.
  - 4-5 walls/perimeters, 25-40% infill.
  - Sand/roughen split faces before gluing.
*/

// ---------------- USER PARAMETERS ----------------
show_part = "all";     // "all", "left", "middle", "right", "complete"

rect_iw = 310;         // rectangular internal width, long side
rect_id = 130;         // rectangular internal depth, short side
circle_od = 200;       // circular external diameter
circle_id = 190;       // circular internal diameter

wall = (circle_od - circle_id) / 2;   // normally 5 mm
flange_extension = 20;                // flat flange around rectangular opening
flange_t = 4;                         // flange thickness
transition_h = 120;                   // rectangular-to-round transition height
collar_h = 35;                        // straight circular collar height

segments = 96;        // circular resolution; lower = faster render, 64 is also OK
exploded_gap = 18;    // visual gap for show_part="all"
eps = 0.05;

// ---------------- DERIVED DIMENSIONS ----------------
rect_ow = rect_iw + 2 * wall;
rect_od = rect_id + 2 * wall;
flange_w = rect_iw + 2 * flange_extension;
flange_d = rect_id + 2 * flange_extension;
total_h = flange_t + transition_h + collar_h;
clip_d = max(circle_od, flange_d) + 2;

split_x1 = -flange_w / 2;
split_x2 = -flange_w / 6;
split_x3 =  flange_w / 6;
split_x4 =  flange_w / 2;

// ---------------- PROFILE FUNCTIONS ----------------
// OpenSCAD trig functions use degrees.
function safe_abs(v) = max(abs(v), 0.000001);

// Point on a rectangle boundary found by shooting a ray from centre.
// This produces a rectangle profile with the same vertex count as the circle.
function rect_ray_point(i, n, w, d) =
    let(a = 360 * i / n,
        c = cos(a),
        s = sin(a),
        hx = w / 2,
        hy = d / 2,
        scale = min(hx / safe_abs(c), hy / safe_abs(s)))
    [scale * c, scale * s];

function circle_point(i, n, r) =
    let(a = 360 * i / n)
    [r * cos(a), r * sin(a)];

function rect_profile(n, w, d) = [for (i = [0:n-1]) rect_ray_point(i, n, w, d)];
function circle_profile(n, r) = [for (i = [0:n-1]) circle_point(i, n, r)];

// ---------------- BASIC GEOMETRY ----------------
module loft(profile_a, profile_b, z_a, z_b) {
    n = len(profile_a);

    pts = concat(
        [for (p = profile_a) [p[0], p[1], z_a]],
        [for (p = profile_b) [p[0], p[1], z_b]]
    );

    bottom_face = [[for (i = [n-1:-1:0]) i]];
    top_face    = [[for (i = [0:n-1]) n + i]];

    side_faces = [
        for (i = [0:n-1], tri = [
            [i, (i + 1) % n, n + ((i + 1) % n)],
            [i, n + ((i + 1) % n), n + i]
        ]) tri
    ];

    polyhedron(points = pts, faces = concat(bottom_face, top_face, side_faces), convexity = 10);
}

module rectangular_flange() {
    difference() {
        translate([0, 0, flange_t / 2])
            cube([flange_w, flange_d, flange_t], center = true);

        // Exact rectangular airflow opening through the flange.
        translate([0, 0, flange_t / 2])
            cube([rect_iw, rect_id, flange_t + 2 * eps], center = true);
    }
}

module transition_shell() {
    difference() {
        loft(
            rect_profile(segments, rect_ow, rect_od),
            circle_profile(segments, circle_od / 2),
            flange_t,
            flange_t + transition_h
        );

        // Slightly over-extended cutter avoids coincident faces.
        loft(
            rect_profile(segments, rect_iw, rect_id),
            circle_profile(segments, circle_id / 2),
            flange_t - eps,
            flange_t + transition_h + eps
        );
    }
}

module circular_collar() {
    translate([0, 0, flange_t + transition_h])
        difference() {
            cylinder(h = collar_h, r = circle_od / 2, $fn = segments);
            translate([0, 0, -eps])
                cylinder(h = collar_h + 2 * eps, r = circle_id / 2, $fn = segments);
        }
}

module complete_duct() {
    union() {
        rectangular_flange();
        transition_shell();
        circular_collar();
    }
}

// ---------------- SPLITTING ----------------
module clip_x(x_min, x_max) {
    intersection() {
        complete_duct();
        translate([(x_min + x_max) / 2, 0, total_h / 2])
            cube([x_max - x_min, clip_d, total_h + 2], center = true);
    }
}

module part_left()   { clip_x(split_x1, split_x2); }
module part_middle() { clip_x(split_x2, split_x3); }
module part_right()  { clip_x(split_x3, split_x4); }

// ---------------- OUTPUT SELECTOR ----------------
if (show_part == "complete") {
    complete_duct();
}
else if (show_part == "left") {
    part_left();
}
else if (show_part == "middle") {
    part_middle();
}
else if (show_part == "right") {
    part_right();
}
else { // "all"
    translate([-exploded_gap, 0, 0]) part_left();
    part_middle();
    translate([ exploded_gap, 0, 0]) part_right();
}
