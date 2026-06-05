/*
  Single-piece rectangular-to-round duct adapter with MOVABLE aerodynamic blades
  --------------------------------------------------------------------------
  Units: millimetres

  What this file generates:
  - One printable duct body: 200 x 130 mm rectangular outside by default,
    150 mm circular outside, 150 mm total height.
  - Rectangular straight section: 50 mm high, no flange.
  - Circular straight section: 50 mm high.
  - Transition height is calculated from total_h.
  - 10 separate movable aerodynamic louver/guide blades.
  - Mounting holes are cut through the rectangular side walls at the middle
    of the 50 mm rectangular section height.

  Coordinate convention:
  - X = long rectangular side, default 200 mm outside.
  - Y = short rectangular side, default 130 mm outside.
  - Z = duct height.
  - Each blade spans across Y, the smaller 130 mm direction.
  - Blades are distributed across X.
  - Each blade pivots around the Y axis.

  Recommended workflow:
  1. Set show_part = "duct_only" and export STL for the duct.
  2. Set show_part = "blade_set" and export STL for all 10 blades.
  3. Optionally set show_part = "blade_only" to inspect one blade.
  4. Use show_part = "assembly_preview" only to check fit/angle.

  Practical assembly note:
  - The default blade uses integral printed axle pins.
  - Because the duct is one rigid piece, insertion requires a little wall/blade flex.
    PETG normally gives enough flex for this size if the clearances are not too tight.
  - If you prefer metal/plastic rods instead of integral pins, set:
        blade_integral_pins = false;
        blade_pivot_bore = true;
    and use the same hole positions in the duct as rod guides.
*/

// ---------------- USER PARAMETERS ----------------
show_part = "assembly_preview";       // "duct_only", "blade_only", "blade_set", "assembly_preview", "cutaway"

rect_size_mode = "outer";      // "outer" = rect_w/rect_d are outside dimensions; "inner" = airflow opening
rect_w = 200;                  // rectangle width, long side, mm
rect_d = 130;                  // rectangle depth, short side, mm

circle_od = 150;               // circular outside diameter, mm
circle_id_override = 0;        // 0 = auto from wall; otherwise set exact circular inside diameter

wall = 3;                      // wall thickness, mm

total_h = 150;                 // total model height, mm
rect_section_h = 50;           // straight rectangular section height, mm
circle_section_h = 50;         // straight circular section height, mm

// Movable blade / louver system
blade_count = 10;
blade_angle_y = 0;             // assembly preview only: blade rotation around Y, degrees
blade_gap_between = 2.2;       // auto chord = blade pitch - this gap
blade_chord_override = 0;      // 0 = auto; otherwise set chord length in X/Z cross-section
blade_max_thickness = 6.0;     // aerodynamic profile max thickness, also affects pin strength
blade_side_clearance = 0.65;   // clearance between blade body and inside side walls
blade_print_gap = 3.0;         // gap between blades in blade_set print layout

airfoil_steps = 28;            // higher = smoother blade profile, 20-36 is usually enough

// Axle / mounting holes
pivot_pin_d = 4.0;             // integral printed axle pin diameter
hole_clearance = 0.45;         // PETG movable clearance; increase to 0.6 if your printer over-extrudes
mount_hole_d = pivot_pin_d + hole_clearance;
mount_z_override = 0;          // 0 = middle of rectangular section; otherwise absolute Z position
pin_projection_override = 0;   // 0 = auto, flush-ish with outside wall

blade_integral_pins = true;    // true = blade has printed axle pins on both ends
blade_pivot_bore = false;      // true = cut a bore through blade for separate rod/pin
pivot_bore_d = 3.2;            // useful for M3 rod/screw if blade_pivot_bore = true

// Geometry quality
segments = 96;                 // circular/loft resolution; 64 faster, 128 smoother
eps = 0.05;
join_overlap = 0.15;           // tiny overlap between sections to avoid fragile coincident joins

// ---------------- DERIVED DIMENSIONS ----------------
function clamp(v, lo, hi) = min(max(v, lo), hi);
function safe_abs(v) = max(abs(v), 0.000001);

rect_ow = rect_size_mode == "inner" ? rect_w + 2 * wall : rect_w;
rect_od = rect_size_mode == "inner" ? rect_d + 2 * wall : rect_d;
rect_iw = rect_size_mode == "inner" ? rect_w : rect_w - 2 * wall;
rect_id = rect_size_mode == "inner" ? rect_d : rect_d - 2 * wall;

circle_id = circle_id_override > 0 ? circle_id_override : circle_od - 2 * wall;
transition_h = max(total_h - rect_section_h - circle_section_h, 1);
actual_total_h = rect_section_h + transition_h + circle_section_h;

mount_z = mount_z_override > 0 ? mount_z_override : rect_section_h / 2;
blade_pitch = rect_iw / (blade_count + 1);
blade_chord = blade_chord_override > 0 ? blade_chord_override : clamp(blade_pitch - blade_gap_between, 8, 16);
blade_body_span = rect_id - 2 * blade_side_clearance;
pin_projection_auto = (rect_od - blade_body_span) / 2;
pin_projection = pin_projection_override > 0 ? pin_projection_override : pin_projection_auto;
blade_total_span = blade_body_span + 2 * pin_projection;

// ---------------- PROFILE FUNCTIONS ----------------
// Rectangle boundary point by shooting a ray from the centre.
// This gives a rectangle profile with the same point count as the circle.
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

// Symmetric NACA-like rounded airfoil profile.
// chord = total length in the blade cross-section, thick = max full thickness.
function airfoil_y(x, chord, thick) =
    let(u = clamp(x / chord, 0, 1),
        t = thick / chord)
    5 * t * chord * (
        0.2969 * sqrt(u)
      - 0.1260 * u
      - 0.3516 * u * u
      + 0.2843 * u * u * u
      - 0.1036 * u * u * u * u
    );

function airfoil_points(n, chord, thick) =
    concat(
        [for (i = [0:n])
            let(x = chord * i / n, y = airfoil_y(x, chord, thick))
            [x - chord / 2, y]
        ],
        [for (i = [n-1:-1:1])
            let(x = chord * i / n, y = -airfoil_y(x, chord, thick))
            [x - chord / 2, y]
        ]
    );

function blade_x_pos(i) = -rect_iw / 2 + i * blade_pitch;

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

module rectangular_straight_section() {
    difference() {
        translate([0, 0, rect_section_h / 2])
            cube([rect_ow, rect_od, rect_section_h], center = true);

        translate([0, 0, rect_section_h / 2])
            cube([rect_iw, rect_id, rect_section_h + 2 * eps], center = true);
    }
}

module transition_shell() {
    z0 = rect_section_h - join_overlap;
    z1 = rect_section_h + transition_h + join_overlap;

    difference() {
        loft(
            rect_profile(segments, rect_ow, rect_od),
            circle_profile(segments, circle_od / 2),
            z0,
            z1
        );

        loft(
            rect_profile(segments, rect_iw, rect_id),
            circle_profile(segments, circle_id / 2),
            z0 - eps,
            z1 + eps
        );
    }
}

module circular_straight_section() {
    translate([0, 0, rect_section_h + transition_h])
        difference() {
            cylinder(h = circle_section_h, r = circle_od / 2, $fn = segments);
            translate([0, 0, -eps])
                cylinder(h = circle_section_h + 2 * eps, r = circle_id / 2, $fn = segments);
        }
}

module blade_mount_holes() {
    for (i = [1:blade_count]) {
        translate([blade_x_pos(i), 0, mount_z])
            rotate([90, 0, 0])
                cylinder(h = rect_od + 2 * eps, d = mount_hole_d, center = true, $fn = 36);
    }
}

module duct_body_without_blades() {
    difference() {
        union() {
            rectangular_straight_section();
            transition_shell();
            circular_straight_section();
        }
        blade_mount_holes();
    }
}

// Aerodynamic blade body, centred around pivot axis at [0,0,0].
// Span is along Y; chord is mostly along X; thickness is along Z.
module aerodynamic_blade_body() {
    rotate([90, 0, 0])
        linear_extrude(height = blade_body_span, center = true, convexity = 10)
            polygon(points = airfoil_points(airfoil_steps, blade_chord, blade_max_thickness));
}

module integral_axle_pins() {
    if (blade_integral_pins) {
        translate([0, blade_body_span / 2 + pin_projection / 2, 0])
            rotate([90, 0, 0])
                cylinder(h = pin_projection, d = pivot_pin_d, center = true, $fn = 36);

        translate([0, -blade_body_span / 2 - pin_projection / 2, 0])
            rotate([90, 0, 0])
                cylinder(h = pin_projection, d = pivot_pin_d, center = true, $fn = 36);
    }
}

module blade_pivot_bore_cut() {
    if (blade_pivot_bore) {
        rotate([90, 0, 0])
            cylinder(h = blade_total_span + 2 * eps, d = pivot_bore_d, center = true, $fn = 36);
    }
}

module movable_blade_centered() {
    difference() {
        union() {
            aerodynamic_blade_body();
            integral_axle_pins();
        }
        blade_pivot_bore_cut();
    }
}

module movable_blade_for_print() {
    // Lift so the blade sits on the slicer bed instead of being centred around Z=0.
    translate([0, 0, blade_max_thickness / 2])
        movable_blade_centered();
}

module blade_set_for_print() {
    for (i = [0:blade_count-1]) {
        translate([(i - (blade_count - 1) / 2) * (blade_chord + blade_print_gap), 0, blade_max_thickness / 2])
            movable_blade_centered();
    }
}

module assembly_preview() {
    color("lightgray") duct_body_without_blades();

    for (i = [1:blade_count]) {
        translate([blade_x_pos(i), 0, mount_z])
            rotate([0, blade_angle_y, 0])
                color("orange") movable_blade_centered();
    }
}

module cutaway_preview() {
    difference() {
        assembly_preview();
        // remove one quarter so the mounting holes and movable blades are visible
        translate([rect_ow / 4, -rect_od / 4, actual_total_h / 2])
            cube([rect_ow / 2 + circle_od, rect_od / 2 + circle_od, actual_total_h + 2], center = true);
    }
}

// ---------------- OUTPUT SELECTOR ----------------
if (show_part == "blade_only") {
    movable_blade_for_print();
}
else if (show_part == "blade_set") {
    blade_set_for_print();
}
else if (show_part == "assembly_preview") {
    assembly_preview();
}
else if (show_part == "cutaway") {
    cutaway_preview();
}
else {
    duct_body_without_blades();
}
