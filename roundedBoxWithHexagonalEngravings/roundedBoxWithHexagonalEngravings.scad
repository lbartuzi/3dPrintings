/*
Rounded rectangular open-top box with smooth wrapped hex side engraving

Features:
- Open top
- Rounded vertical corners as one continuous shell
- Side hex pattern wraps around full perimeter, including rounded corners
- Side hexagons are smooth 6-sided engravings, not sliced/stepped
- Side hexagons are closed/recessed, not through-holes by default
- Bottom remains a true open hex mesh
- Hexagons are regular and not stretched
- Number of side hexagons is calculated from box size
- Resizing changes the number of cells, not the hexagon shape

All dimensions are in mm.
*/


// ------------------------------------------------------------
// Quality
// ------------------------------------------------------------

$fn = 96;
$fa = 2;
$fs = 0.25;


// ------------------------------------------------------------
// Main dimensions
// ------------------------------------------------------------

box_length = 180;              // outer X
box_depth  = 70;              // outer Y
box_height = 45;               // outer Z

wall_thickness   = 2.0;
bottom_thickness = 2.4;

corner_radius = 8;


// ------------------------------------------------------------
// Side-wall hex engraving
// ------------------------------------------------------------

// false = recessed/engraved closed hexagons, best for Cura
// true  = through-holes in side wall
side_hex_through_holes = false;

// For Cura 4.6.1, shallow engraving is much safer.
// Recommended: 0.55 to 0.85 mm
side_hex_groove_depth = 0.70;

// If side_hex_through_holes = true, this controls the remaining membrane.
// Example:
// wall_thickness = 2.0;
// side_membrane_thickness = 0.45;
// through-style depth becomes 1.55 mm, leaving 0.45 mm membrane.
side_membrane_thickness = 0.45;


// ------------------------------------------------------------
// Hex pattern parameters
// ------------------------------------------------------------

hex_radius  = 5.0;             // center-to-corner radius
web_width   = 1.2;             // spacing/material between hexagons
edge_border = 4.0;             // solid top/bottom side border

bottom_is_mesh = true;
side_walls_have_hex_pattern = true;


// ------------------------------------------------------------
// Safety checks
// ------------------------------------------------------------

assert(corner_radius > wall_thickness,
       "corner_radius must be larger than wall_thickness");

assert(corner_radius < box_length / 2,
       "corner_radius too large for box_length");

assert(corner_radius < box_depth / 2,
       "corner_radius too large for box_depth");

assert(box_height > 2 * edge_border + 2 * hex_radius,
       "box_height too small for selected hex_radius and edge_border");


// ------------------------------------------------------------
// Helper functions
// ------------------------------------------------------------

function hex_opening_width(r)  = sqrt(3) * r;
function hex_opening_height(r) = 2 * r;

function straight_x() = box_length - 2 * corner_radius;
function straight_y() = box_depth  - 2 * corner_radius;

function quarter_arc() = PI * corner_radius / 2;

function s1() = straight_x();
function s2() = straight_x() + quarter_arc();
function s3() = straight_x() + quarter_arc() + straight_y();
function s4() = straight_x() + 2 * quarter_arc() + straight_y();
function s5() = 2 * straight_x() + 2 * quarter_arc() + straight_y();
function s6() = 2 * straight_x() + 3 * quarter_arc() + straight_y();
function s7() = 2 * straight_x() + 3 * quarter_arc() + 2 * straight_y();

function perimeter_length() =
    2 * straight_x()
  + 2 * straight_y()
  + 4 * quarter_arc();

function wrap_s(s) =
    s - floor(s / perimeter_length()) * perimeter_length();


// Put the wrap seam on the rear wall instead of the front.
function pattern_seam_offset() =
    s4() + straight_x() / 2;

function physical_s(s) =
    wrap_s(s + pattern_seam_offset());


// ------------------------------------------------------------
// Perimeter surface functions
// ------------------------------------------------------------

function normal_angle_raw(s) =
    wrap_s(s) <= s1() ? -90 :

    wrap_s(s) <= s2() ?
        -90 + ((wrap_s(s) - s1()) / corner_radius) * 180 / PI :

    wrap_s(s) <= s3() ? 0 :

    wrap_s(s) <= s4() ?
        0 + ((wrap_s(s) - s3()) / corner_radius) * 180 / PI :

    wrap_s(s) <= s5() ? 90 :

    wrap_s(s) <= s6() ?
        90 + ((wrap_s(s) - s5()) / corner_radius) * 180 / PI :

    wrap_s(s) <= s7() ? 180 :

    180 + ((wrap_s(s) - s7()) / corner_radius) * 180 / PI;


function normal_angle(s) =
    normal_angle_raw(physical_s(s));


function surf_x_raw(s) =
    wrap_s(s) <= s1() ?
        corner_radius + wrap_s(s) :

    wrap_s(s) <= s2() ?
        box_length - corner_radius
        + corner_radius * cos(normal_angle_raw(s)) :

    wrap_s(s) <= s3() ?
        box_length :

    wrap_s(s) <= s4() ?
        box_length - corner_radius
        + corner_radius * cos(normal_angle_raw(s)) :

    wrap_s(s) <= s5() ?
        box_length - corner_radius - (wrap_s(s) - s4()) :

    wrap_s(s) <= s6() ?
        corner_radius
        + corner_radius * cos(normal_angle_raw(s)) :

    wrap_s(s) <= s7() ?
        0 :

    corner_radius
    + corner_radius * cos(normal_angle_raw(s));


function surf_y_raw(s) =
    wrap_s(s) <= s1() ?
        0 :

    wrap_s(s) <= s2() ?
        corner_radius
        + corner_radius * sin(normal_angle_raw(s)) :

    wrap_s(s) <= s3() ?
        corner_radius + (wrap_s(s) - s2()) :

    wrap_s(s) <= s4() ?
        box_depth - corner_radius
        + corner_radius * sin(normal_angle_raw(s)) :

    wrap_s(s) <= s5() ?
        box_depth :

    wrap_s(s) <= s6() ?
        box_depth - corner_radius
        + corner_radius * sin(normal_angle_raw(s)) :

    wrap_s(s) <= s7() ?
        box_depth - corner_radius - (wrap_s(s) - s6()) :

    corner_radius
    + corner_radius * sin(normal_angle_raw(s));


function surf_x(s) = surf_x_raw(physical_s(s));
function surf_y(s) = surf_y_raw(physical_s(s));


// ------------------------------------------------------------
// 2D rounded rectangle
// ------------------------------------------------------------

module rounded_rect_2d(w, h, r) {
    hull() {
        translate([r,     r    ]) circle(r=r);
        translate([w - r, r    ]) circle(r=r);
        translate([w - r, h - r]) circle(r=r);
        translate([r,     h - r]) circle(r=r);
    }
}


// ------------------------------------------------------------
// Regular point-up hexagon
// ------------------------------------------------------------

module regular_hex_pointup(r) {
    polygon(points = [
        [0,                         r],
        [hex_opening_width(r) / 2,   r / 2],
        [hex_opening_width(r) / 2,  -r / 2],
        [0,                        -r],
        [-hex_opening_width(r) / 2, -r / 2],
        [-hex_opening_width(r) / 2,  r / 2]
    ]);
}


// ------------------------------------------------------------
// Bottom hex grid
// ------------------------------------------------------------

module hex_hole_grid_2d(panel_w, panel_h, r, web, border) {
    hw = hex_opening_width(r);
    hh = hex_opening_height(r);

    pitch_x = hw + web;
    pitch_y = 1.5 * r + web;

    col_extent = ceil(panel_w / pitch_x) + 4;
    row_extent = ceil(panel_h / pitch_y) + 4;

    for (row = [-row_extent : row_extent]) {
        y = panel_h / 2 + row * pitch_y;
        x_shift = ((row % 2) == 0) ? 0 : pitch_x / 2;

        for (col = [-col_extent : col_extent]) {
            x = panel_w / 2 + col * pitch_x + x_shift;

            if (
                x >= border + hw / 2 &&
                x <= panel_w - border - hw / 2 &&
                y >= border + hh / 2 &&
                y <= panel_h - border - hh / 2
            ) {
                translate([x, y])
                    regular_hex_pointup(r);
            }
        }
    }
}


module rounded_bottom_mesh_2d() {
    difference() {
        rounded_rect_2d(box_length, box_depth, corner_radius);

        if (bottom_is_mesh) {
            hex_hole_grid_2d(
                box_length,
                box_depth,
                hex_radius,
                web_width,
                edge_border
            );
        }
    }
}


module bottom_panel() {
    linear_extrude(height=bottom_thickness, convexity=10)
        rounded_bottom_mesh_2d();
}


// ------------------------------------------------------------
// Continuous rounded side shell
// ------------------------------------------------------------

module side_shell_solid() {
    inner_corner_radius = max(0.01, corner_radius - wall_thickness);

    difference() {
        linear_extrude(height=box_height, convexity=10)
            rounded_rect_2d(
                box_length,
                box_depth,
                corner_radius
            );

        translate([wall_thickness, wall_thickness, -0.1])
            linear_extrude(height=box_height + 0.2, convexity=10)
                rounded_rect_2d(
                    box_length - 2 * wall_thickness,
                    box_depth  - 2 * wall_thickness,
                    inner_corner_radius
                );
    }
}


// ------------------------------------------------------------
// Smooth tangent hex cutter for side wall
//
// Local cutter coordinate system:
// X = perimeter direction
// Y = vertical Z direction
// local extrusion Z = outward normal
//
// The cutter is one clean 6-sided hexagonal prism.
// No vertical slice approximation.
// ------------------------------------------------------------

module smooth_side_hex_cutter(sc, zc, cut_depth) {
    outside_extra = 0.9;
    total_depth = cut_depth + outside_extra;

    translate([surf_x(sc), surf_y(sc), zc])
        rotate([0, 0, normal_angle(sc) + 90])
            rotate([90, 0, 0])
                translate([0, 0, -cut_depth])
                    linear_extrude(height=total_depth, convexity=10)
                        regular_hex_pointup(hex_radius);
}


// ------------------------------------------------------------
// Wrapped smooth side-wall hex pattern
// ------------------------------------------------------------

module wrapped_smooth_side_hexes() {
    hw = hex_opening_width(hex_radius);
    p = perimeter_length();

    nominal_pitch_s = hw + web_width;

    // Number of columns is calculated from perimeter.
    columns = max(3, floor(p / nominal_pitch_s));

    // Pitch is slightly adjusted so the pattern closes around the box.
    // The hexagon itself is not scaled or stretched.
    pitch_s = p / columns;

    pitch_z = 1.5 * hex_radius + web_width;

    // Number of rows is calculated from box height.
    rows =
        max(
            0,
            floor(
                (box_height - 2 * edge_border - 2 * hex_radius)
                / pitch_z
            ) + 1
        );

    cut_depth =
        side_hex_through_holes
        ? wall_thickness + 1.0
        : min(
            wall_thickness - 0.05,
            side_hex_groove_depth
          );

    //seam_margin = hw / 2 + web_width + 1.0;
    seam_margin = hw / 2 + 0.2;

    if (rows > 0) {
        for (row = [0 : rows - 1]) {
            zc = edge_border + hex_radius + row * pitch_z;

            row_shift = ((row % 2) == 0) ? 0 : pitch_s / 2;
            start_s = pitch_s / 2 + row_shift;

            for (col = [0 : columns - 1]) {
                sc = start_s + col * pitch_s;

                // Skip only the hidden seam zone so cutters do not wrap
                // over the seam and create CGAL artifacts.
                if (
                    sc > seam_margin &&
                    sc < p - seam_margin &&
                    zc >= edge_border + hex_radius &&
                    zc <= box_height - edge_border - hex_radius
                ) {
                    smooth_side_hex_cutter(
                        sc,
                        zc,
                        cut_depth
                    );
                }
            }
        }
    }
}


// ------------------------------------------------------------
// Side shell with smooth wrapped engraving
// ------------------------------------------------------------

module wrapped_hex_side_shell() {
    difference() {
        side_shell_solid();

        if (side_walls_have_hex_pattern) {
            wrapped_smooth_side_hexes();
        }
    }
}


// ------------------------------------------------------------
// Final box
// ------------------------------------------------------------

module rounded_wrapped_hex_box() {
    union() {
        bottom_panel();
        wrapped_hex_side_shell();
    }
}


rounded_wrapped_hex_box();
