//
// Parametric Table Lamp Shade
// Smooth outer wall + smooth inner wall
// Conformal radial honeycomb bridge mesh connecting both walls
// Simple adjustable table-lamp holder mount with 3 triangular arms
//
// CGAL-safer version:
// - no intersection() clipping for the honeycomb
// - honeycomb is generated inside the wall by construction
// - honeycomb ribs are conformal to the organic shell
// - no duplicated overlapping honeycomb ribs
// - all custom polyhedrons use triangulated faces only
//

$fn = 72;

// --------------------------------------------------
// Main shade parameters
// --------------------------------------------------
shade_height               = 145;
bottom_diameter            = 150;
top_diameter               = 92;

// Outer shape character
profile_steps              = 56;
angle_steps                = 120;

profile_belly_amount       = 0.18;
profile_waist_amount       = 0.07;

petal_count                = 6;
petal_amplitude            = 0.045;
petal_twist_degrees        = 28;

// Top option
open_top                   = true;
top_rim_height             = 3.0;
closed_top_thickness       = 1.2;

// --------------------------------------------------
// Wall construction
// --------------------------------------------------
outer_skin_thickness       = 0.75;
inner_skin_thickness       = 0.75;
wall_gap                   = 3.8;

bottom_rim_height          = 4.0;

total_wall_thickness =
    outer_skin_thickness + wall_gap + inner_skin_thickness;

// --------------------------------------------------
// Embedded conformal honeycomb core
// --------------------------------------------------
hex_core_enabled           = true;

// Vertical working range for the embedded core
hex_core_z_start           = 12;
hex_core_z_end_from_top    = 16;

// Honeycomb geometry
hex_core_cell_side         = 6.8;
hex_core_frame_thickness   = 0.95;

// How far the honeycomb enters the skins.
// This does NOT allow protrusion through the visible surfaces.
// With 0.75 mm skins and 0.55 mm embed, the honeycomb stays
// 0.20 mm below the visible inner/outer shell surfaces.
hex_core_embed_into_walls  = 0.55;

// Extra safety clearance from visible surfaces.
// The effective clearance is whichever is larger:
// surface clearance OR remaining skin above the honeycomb.
hex_core_surface_clearance = 0.18;

// --------------------------------------------------
// Universal table-lamp holder mount
// --------------------------------------------------
holder_hole_diameter        = 42;
holder_disk_outer_diameter  = 72;
holder_disk_thickness       = 6.0;

// Adjustable mount position
holder_mount_z              = 10.0;

// --------------------------------------------------
// Three simple triangular arms
// --------------------------------------------------
arm_count                   = 3;
arm_width                   = 13;
arm_height_at_disk          = 6;
arm_height_at_wall          = 11;

arm_wall_overlap            = 1.2;

arm_cut_enabled             = false;
arm_cut_margin              = 1.4;

// --------------------------------------------------
// Derived values
// --------------------------------------------------
hex_core_z_end =
    shade_height - hex_core_z_end_from_top;

// --------------------------------------------------
// Utility functions
// --------------------------------------------------
function clamp(v, lo, hi) =
    min(max(v, lo), hi);

function lerp(a, b, t) =
    a + (b - a) * t;

function z_t(z) =
    clamp(z / shade_height, 0, 1);

function base_radius_at_z(z) =
    lerp(bottom_diameter / 2, top_diameter / 2, z_t(z));

function profile_multiplier(z) =
    1
    + profile_belly_amount * sin(180 * z_t(z))
    - profile_waist_amount * sin(360 * z_t(z));

function petal_multiplier(angle, z) =
    1
    + petal_amplitude
      * sin(petal_count * angle + petal_twist_degrees * z_t(z));

function outer_radius(angle, z) =
    base_radius_at_z(z)
    * profile_multiplier(z)
    * petal_multiplier(angle, z);

function inner_radius(angle, z) =
    outer_radius(angle, z) - total_wall_thickness;

function polar_x(r, a) =
    r * cos(a);

function polar_y(r, a) =
    r * sin(a);

function arm_start_radius() =
    holder_disk_outer_diameter / 2;

function arm_length_at_angle(a) =
    max(
        inner_radius(a, holder_mount_z) - arm_start_radius() + arm_wall_overlap,
        5
    );

// --------------------------------------------------
// Honeycomb helper functions
// --------------------------------------------------
function safe_hex_core_embed() =
    max(
        0,
        min(
            hex_core_embed_into_walls,
            outer_skin_thickness - 0.05,
            inner_skin_thickness - 0.05
        )
    );

function safe_core_surface_clearance() =
    max(
        0.01,
        min(
            hex_core_surface_clearance,
            outer_skin_thickness / 2,
            inner_skin_thickness / 2
        )
    );

// Offset from visible outer surface where honeycomb may start.
// Example:
// outer_skin = 0.75
// embed = 0.55
// result = 0.20 mm below visible outside surface.
function core_outer_offset() =
    max(
        safe_core_surface_clearance(),
        outer_skin_thickness - safe_hex_core_embed()
    );

// Offset from visible outer surface where honeycomb may end.
// This places the inner end inside the inner skin but not through it.
function core_inner_offset() =
    total_wall_thickness
    - max(
        safe_core_surface_clearance(),
        inner_skin_thickness - safe_hex_core_embed()
    );

function hex_core_mid_radius(angle, z) =
    outer_radius(angle, z)
    - (core_outer_offset() + core_inner_offset()) / 2;

function honeycomb_cell_width(side) =
    sqrt(3) * side;

function honeycomb_row_pitch(side) =
    1.5 * side;

function honeycomb_half_height(side, wall) =
    side + wall / 2;

function pointy_hex_points(side) =
    let(w = sqrt(3) * side / 2)
    [
        [0,  side],
        [w,  side / 2],
        [w, -side / 2],
        [0, -side],
        [-w, -side / 2],
        [-w,  side / 2]
    ];

// Converts local honeycomb coordinates to organic shade coordinates.
// local X = tangential distance in mm
// local Y = vertical distance in mm
function local_to_angle(a0, z0, x) =
    a0 + (x / max(hex_core_mid_radius(a0, z0), 1)) * 180 / PI;

function core_point(a, z, offset_from_outer_surface) =
    [
        polar_x(outer_radius(a, z) - offset_from_outer_surface, a),
        polar_y(outer_radius(a, z) - offset_from_outer_surface, a),
        z
    ];

// --------------------------------------------------
// CGAL-safe organic shell section builder
// All faces are triangles.
// --------------------------------------------------
module surface_shell(
    radius_outer_offset,
    radius_inner_offset,
    z_min,
    z_max
) {
    points_outer = [
        for (zi = [0 : profile_steps])
            for (ai = [0 : angle_steps - 1])
                [
                    polar_x(
                        outer_radius(
                            ai * 360 / angle_steps,
                            lerp(z_min, z_max, zi / profile_steps)
                        ) - radius_outer_offset,
                        ai * 360 / angle_steps
                    ),
                    polar_y(
                        outer_radius(
                            ai * 360 / angle_steps,
                            lerp(z_min, z_max, zi / profile_steps)
                        ) - radius_outer_offset,
                        ai * 360 / angle_steps
                    ),
                    lerp(z_min, z_max, zi / profile_steps)
                ]
    ];

    points_inner = [
        for (zi = [0 : profile_steps])
            for (ai = [0 : angle_steps - 1])
                [
                    polar_x(
                        outer_radius(
                            ai * 360 / angle_steps,
                            lerp(z_min, z_max, zi / profile_steps)
                        ) - radius_inner_offset,
                        ai * 360 / angle_steps
                    ),
                    polar_y(
                        outer_radius(
                            ai * 360 / angle_steps,
                            lerp(z_min, z_max, zi / profile_steps)
                        ) - radius_inner_offset,
                        ai * 360 / angle_steps
                    ),
                    lerp(z_min, z_max, zi / profile_steps)
                ]
    ];

    points_all = concat(points_outer, points_inner);

    inner_offset = (profile_steps + 1) * angle_steps;

    outer_faces_a = [
        for (zi = [0 : profile_steps - 1])
            for (ai = [0 : angle_steps - 1])
                [
                    zi * angle_steps + ai,
                    zi * angle_steps + ((ai + 1) % angle_steps),
                    (zi + 1) * angle_steps + ((ai + 1) % angle_steps)
                ]
    ];

    outer_faces_b = [
        for (zi = [0 : profile_steps - 1])
            for (ai = [0 : angle_steps - 1])
                [
                    zi * angle_steps + ai,
                    (zi + 1) * angle_steps + ((ai + 1) % angle_steps),
                    (zi + 1) * angle_steps + ai
                ]
    ];

    inner_faces_a = [
        for (zi = [0 : profile_steps - 1])
            for (ai = [0 : angle_steps - 1])
                [
                    inner_offset + (zi + 1) * angle_steps + ai,
                    inner_offset + (zi + 1) * angle_steps + ((ai + 1) % angle_steps),
                    inner_offset + zi * angle_steps + ((ai + 1) % angle_steps)
                ]
    ];

    inner_faces_b = [
        for (zi = [0 : profile_steps - 1])
            for (ai = [0 : angle_steps - 1])
                [
                    inner_offset + (zi + 1) * angle_steps + ai,
                    inner_offset + zi * angle_steps + ((ai + 1) % angle_steps),
                    inner_offset + zi * angle_steps + ai
                ]
    ];

    bottom_faces_a = [
        for (ai = [0 : angle_steps - 1])
            [
                ai,
                inner_offset + ai,
                inner_offset + ((ai + 1) % angle_steps)
            ]
    ];

    bottom_faces_b = [
        for (ai = [0 : angle_steps - 1])
            [
                ai,
                inner_offset + ((ai + 1) % angle_steps),
                ((ai + 1) % angle_steps)
            ]
    ];

    top_outer_start = profile_steps * angle_steps;
    top_inner_start = inner_offset + profile_steps * angle_steps;

    top_faces_a = [
        for (ai = [0 : angle_steps - 1])
            [
                top_outer_start + ai,
                top_outer_start + ((ai + 1) % angle_steps),
                top_inner_start + ((ai + 1) % angle_steps)
            ]
    ];

    top_faces_b = [
        for (ai = [0 : angle_steps - 1])
            [
                top_outer_start + ai,
                top_inner_start + ((ai + 1) % angle_steps),
                top_inner_start + ai
            ]
    ];

    polyhedron(
        points = points_all,
        faces = concat(
            outer_faces_a,
            outer_faces_b,
            inner_faces_a,
            inner_faces_b,
            bottom_faces_a,
            bottom_faces_b,
            top_faces_a,
            top_faces_b
        ),
        convexity = 10
    );
}

// --------------------------------------------------
// Main shade walls
// --------------------------------------------------
module outer_skin() {
    surface_shell(
        0,
        outer_skin_thickness,
        0,
        shade_height
    );
}

module inner_skin() {
    surface_shell(
        outer_skin_thickness + wall_gap,
        total_wall_thickness,
        0,
        shade_height
    );
}

module bottom_rim() {
    surface_shell(
        0,
        total_wall_thickness,
        0,
        bottom_rim_height
    );
}

module top_rim() {
    if (open_top) {
        surface_shell(
            0,
            total_wall_thickness,
            shade_height - top_rim_height,
            shade_height
        );
    }
}

module closed_top() {
    if (!open_top) {
        translate([0, 0, shade_height - closed_top_thickness])
            difference() {
                cylinder(
                    h = closed_top_thickness,
                    r = outer_radius(0, shade_height)
                );

                translate([0, 0, -0.1])
                    cylinder(
                        h = closed_top_thickness + 0.2,
                        d = holder_hole_diameter + 8
                    );
            }
    }
}

// --------------------------------------------------
// One conformal honeycomb rib
//
// The rib is defined between two local honeycomb points.
// It is widened in the local tangential/vertical plane,
// then its outer and inner radial faces are placed directly
// on safe offset surfaces of the organic shade.
//
// This means the honeycomb does not need boolean clipping.
// It is already inside the allowed wall volume.
// --------------------------------------------------
module conformal_honeycomb_rib(a0, z0, p1, p2) {
    dx = p2[0] - p1[0];
    dy = p2[1] - p1[1];

    rib_len = sqrt(dx * dx + dy * dy);

    if (rib_len > 0.001) {
        nx = -dy / rib_len;
        ny =  dx / rib_len;

        hw = hex_core_frame_thickness / 2;

        c0 = [p1[0] + nx * hw, p1[1] + ny * hw];
        c1 = [p2[0] + nx * hw, p2[1] + ny * hw];
        c2 = [p2[0] - nx * hw, p2[1] - ny * hw];
        c3 = [p1[0] - nx * hw, p1[1] - ny * hw];

        a0c = local_to_angle(a0, z0, c0[0]);
        a1c = local_to_angle(a0, z0, c1[0]);
        a2c = local_to_angle(a0, z0, c2[0]);
        a3c = local_to_angle(a0, z0, c3[0]);

        z0c = z0 + c0[1];
        z1c = z0 + c1[1];
        z2c = z0 + c2[1];
        z3c = z0 + c3[1];

        points = [
            // Outer radial side of the honeycomb rib
            core_point(a0c, z0c, core_outer_offset()),
            core_point(a1c, z1c, core_outer_offset()),
            core_point(a2c, z2c, core_outer_offset()),
            core_point(a3c, z3c, core_outer_offset()),

            // Inner radial side of the honeycomb rib
            core_point(a0c, z0c, core_inner_offset()),
            core_point(a1c, z1c, core_inner_offset()),
            core_point(a2c, z2c, core_inner_offset()),
            core_point(a3c, z3c, core_inner_offset())
        ];

        polyhedron(
            points = points,
            faces = [
                // outer radial face
                [0, 1, 2],
                [0, 2, 3],

                // inner radial face
                [7, 6, 5],
                [7, 5, 4],

                // side faces
                [0, 4, 5],
                [0, 5, 1],

                [1, 5, 6],
                [1, 6, 2],

                [2, 6, 7],
                [2, 7, 3],

                [3, 7, 4],
                [3, 4, 0]
            ],
            convexity = 4
        );
    }
}

// --------------------------------------------------
// One honeycomb cell, but only three edges are generated.
//
// This is intentional.
// Full hex cells would duplicate shared ribs between
// neighbouring cells, causing overlapping coplanar geometry.
// These three edges are enough to form the honeycomb network
// once cells are repeated in a staggered pattern.
// --------------------------------------------------
module conformal_honeycomb_cell(a, z) {
    pts = pointy_hex_points(hex_core_cell_side);

    conformal_honeycomb_rib(a, z, pts[0], pts[1]);
    conformal_honeycomb_rib(a, z, pts[1], pts[2]);
    conformal_honeycomb_rib(a, z, pts[2], pts[3]);
}

// --------------------------------------------------
// Embedded conformal radial honeycomb bridge core
// --------------------------------------------------
module embedded_hex_core() {
    if (hex_core_enabled) {
        row_pitch = honeycomb_row_pitch(hex_core_cell_side);
        col_pitch = honeycomb_cell_width(hex_core_cell_side);

        z_margin = honeycomb_half_height(
            hex_core_cell_side,
            hex_core_frame_thickness
        );

        row_count = max(
            1,
            floor(
                (hex_core_z_end - hex_core_z_start - 2 * z_margin)
                / row_pitch
            ) + 1
        );

        for (row = [0 : row_count - 1]) {
            z =
                hex_core_z_start
                + z_margin
                + row * row_pitch;

            if (z <= hex_core_z_end - z_margin) {
                avg_mid_radius =
                    base_radius_at_z(z)
                    * profile_multiplier(z)
                    - (core_outer_offset() + core_inner_offset()) / 2;

                circumference = 2 * PI * avg_mid_radius;

                col_count = max(
                    12,
                    round(circumference / col_pitch)
                );

                a_step = 360 / col_count;
                row_offset = (row % 2) * a_step / 2;

                for (col = [0 : col_count - 1]) {
                    a = col * a_step + row_offset;

                    conformal_honeycomb_cell(a, z);
                }
            }
        }
    }
}

// --------------------------------------------------
// Simple adjustable holder disk
// --------------------------------------------------
module holder_adapter_disk() {
    difference() {
        translate([0, 0, holder_mount_z - holder_disk_thickness / 2])
            cylinder(
                h = holder_disk_thickness,
                d = holder_disk_outer_diameter
            );

        translate([0, 0, holder_mount_z - holder_disk_thickness / 2 - 0.1])
            cylinder(
                h = holder_disk_thickness + 0.2,
                d = holder_hole_diameter
            );
    }
}

// --------------------------------------------------
// Simple triangular support arms
// All faces are triangles to avoid non-planar quad errors.
// --------------------------------------------------
module triangular_arm_body(len) {
    polyhedron(
        points = [
            [0,   -arm_width / 2, 0],
            [0,    arm_width / 2, 0],
            [0,    0,             arm_height_at_disk],

            [len, -arm_width / 2, 0],
            [len,  arm_width / 2, 0],
            [len,  0,             arm_height_at_wall]
        ],
        faces = [
            // disk-side triangular end
            [0, 2, 1],

            // wall-side triangular end
            [3, 4, 5],

            // bottom face, triangulated
            [0, 1, 4],
            [0, 4, 3],

            // one sloped side, triangulated
            [1, 2, 5],
            [1, 5, 4],

            // other sloped side, triangulated
            [0, 3, 5],
            [0, 5, 2]
        ],
        convexity = 4
    );
}

module spider_arm(len) {
    difference() {
        triangular_arm_body(len);

        if (arm_cut_enabled) {
            translate([len * 0.22, -arm_width / 2 - 0.2, arm_cut_margin])
                rotate([90, 0, 0])
                    linear_extrude(height = arm_width + 0.4)
                        polygon(points = [
                            [0,          0],
                            [len * 0.48, 0],
                            [len * 0.48, arm_height_at_wall - arm_cut_margin * 2]
                        ]);
        }
    }
}

module spider_arms() {
    for (a = [0 : 360 / arm_count : 360 - 360 / arm_count]) {
        rotate([0, 0, a])
            translate([
                arm_start_radius() - 0.1,
                0,
                holder_mount_z - arm_height_at_disk / 2
            ])
                spider_arm(arm_length_at_angle(a));
    }
}

// --------------------------------------------------
// Final assembly
// --------------------------------------------------
module table_lamp_shade() {
    union() {
        outer_skin();
        inner_skin();

        bottom_rim();
        top_rim();
        closed_top();

        embedded_hex_core();

        holder_adapter_disk();
        spider_arms();
    }
}

table_lamp_shade();
