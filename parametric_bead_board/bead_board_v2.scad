// ============================================================
//  Parametric Bead Design Board  (bamboo-style organizer)
//  - Row 1 (top)   : N pockets, last one optionally double width
//  - Row 2 (middle): N pockets, letters A.. assigned here FIRST
//  - Row 3 (bottom): optional; 1 full-width tray OR N pockets like row 2
//  - Rounded-rectangle pockets, per-row depth, magnet recesses
// ============================================================

$fn = 64;

/* [External dimensions (mm)] */
board_width        = 297;    // left-right
board_depth        = 210;    // front-back
board_thickness    = 12;     // complete height
board_corner_radius = 5;

/* [General layout] */
edge_margin          = 12;   // border between pockets and board edge
gap                  = 10;   // spacing between pockets (letters live here)
pocket_corner_radius = 5;

/* [Row 1 - top row] */
row1_count        = 5;       // number of pockets
row1_last_double  = true;    // true = last pocket spans 2 units (like "K")
row1_height       = 49;      // pocket size front-to-back
row1_pocket_depth = 6;

/* [Row 2 - middle row] */
row2_count        = 6;
row2_height       = 49;
row2_pocket_depth = 6;

/* [Row 3 - bottom row] */
row3_enabled      = true;    // false = no bottom row at all
row3_count        = 1;       // 1 = one full-width tray, >1 = pockets like row 2
row3_height       = 64;
row3_pocket_depth = 6;
row3_letters      = true;    // etch letters (continuing after row 1)

/* [Magnet recesses (4 corners)] */
magnet_diameter = 8;
magnet_depth    = 2.4;
magnet_inset    = 9;         // hole centre offset from each corner
magnet_from_top = true;      // false = recess milled from the bottom face

/* [Lettering] */
labels            = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"; // row2 first, then row1
letter_size       = 7;
letter_etch_depth = 0.8;
letter_font       = "Liberation Sans:style=Bold";

/* [Ruler (below row 3)] */
ruler_enabled      = true;
tick_spacing       = 5;      // etched marker every N mm
minor_tick_len     = 3;
major_tick_len     = 5.5;
tick_width         = 0.8;
ruler_number_every = 10;     // put a number every N mm (10 = every cm)
ruler_number_size  = 4;
ruler_etch_depth   = 0.6;

/* ---------------- derived values ---------------- */
avail_w = board_width - 2*edge_margin;

// row 2: equal pockets
row2_pw = (avail_w - (row2_count - 1)*gap) / row2_count;

// row 1: computed in "units"; a double last pocket consumes 2 units + 1 gap
row1_units  = row1_count + (row1_last_double ? 1 : 0);
row1_uw     = (avail_w - (row1_units - 1)*gap) / row1_units;
row1_last_w = row1_last_double ? 2*row1_uw + gap : row1_uw;

// row 3: equal pockets (count = 1 -> single full-width tray)
row3_pw = (avail_w - (row3_count - 1)*gap) / row3_count;

// vertical stack, y = 0 at the front (ruler) edge
y1_top = board_depth - edge_margin;
y1_bot = y1_top - row1_height;
y2_top = y1_bot - gap;
y2_bot = y2_top - row2_height;
y3_top = y2_bot - gap;
y3_bot = y3_top - row3_height;

// the ruler hangs below the lowest existing row
ruler_base = row3_enabled ? y3_bot : y2_bot;

/* ---------------- sanity checks ---------------- */
assert(row2_pw  > 2*pocket_corner_radius, "Row 2 pockets too narrow - reduce count/gap/margin");
assert(row1_uw  > 2*pocket_corner_radius, "Row 1 pockets too narrow - reduce count/gap/margin");
assert(!row3_enabled || row3_pw > 2*pocket_corner_radius,
       "Row 3 pockets too narrow - reduce count/gap/margin");
assert(ruler_base > (ruler_enabled ? major_tick_len + ruler_number_size + 4 : 2),
       "Rows do not fit vertically - reduce row heights or gaps");
assert(max(row1_pocket_depth, row2_pocket_depth,
           row3_enabled ? row3_pocket_depth : 0) < board_thickness,
       "A pocket depth is >= board thickness");

/* ---------------- helper modules ---------------- */
module rounded_plate(w, h, r) {
    translate([r, r]) offset(r) square([w - 2*r, h - 2*r]);
}

module pocket(x, y, w, h, depth) {
    translate([x, y, board_thickness - depth])
        linear_extrude(depth + 0.02)
            rounded_plate(w, h, pocket_corner_radius);
}

module etch_text(x, y, s, size) {
    translate([x, y, board_thickness - letter_etch_depth])
        linear_extrude(letter_etch_depth + 0.02)
            text(s, size = size, font = letter_font,
                 halign = "center", valign = "center");
}

/* ---------------- cut groups ---------------- */
module board_body() {
    linear_extrude(board_thickness)
        rounded_plate(board_width, board_depth, board_corner_radius);
}

module row1_cuts() {
    for (i = [0 : row1_count - 1]) {
        x = edge_margin + i*(row1_uw + gap);
        w = (i == row1_count - 1) ? row1_last_w : row1_uw;
        pocket(x, y1_bot, w, row1_height, row1_pocket_depth);
    }
}

module row2_cuts() {
    for (i = [0 : row2_count - 1]) {
        x = edge_margin + i*(row2_pw + gap);
        pocket(x, y2_bot, row2_pw, row2_height, row2_pocket_depth);
    }
}

module row3_cuts() {
    for (i = [0 : row3_count - 1]) {
        x = edge_margin + i*(row3_pw + gap);
        pocket(x, y3_bot, row3_pw, row3_height, row3_pocket_depth);
    }
}

module magnet_cuts() {
    zpos = magnet_from_top ? board_thickness - magnet_depth : -0.01;
    for (p = [[magnet_inset,               magnet_inset],
              [board_width - magnet_inset, magnet_inset],
              [magnet_inset,               board_depth - magnet_inset],
              [board_width - magnet_inset, board_depth - magnet_inset]])
        translate([p[0], p[1], zpos])
            cylinder(d = magnet_diameter, h = magnet_depth + 0.02);
}

module letter_cuts() {
    // Row 2 gets labels[0 .. row2_count-1]
    for (i = [0 : row2_count - 1]) {
        x = edge_margin + i*(row2_pw + gap);
        etch_text(x - gap/2, y2_bot + row2_height/2, labels[i], letter_size);
    }
    // Row 1 continues the alphabet
    for (i = [0 : row1_count - 1]) {
        x = edge_margin + i*(row1_uw + gap);
        etch_text(x - gap/2, y1_bot + row1_height/2,
                  labels[row2_count + i], letter_size);
    }
    // Row 3 continues after row 1 (optional)
    if (row3_enabled && row3_letters)
        for (i = [0 : row3_count - 1]) {
            x = edge_margin + i*(row3_pw + gap);
            etch_text(x - gap/2, y3_bot + row3_height/2,
                      labels[row2_count + row1_count + i], letter_size);
        }
}

module ruler_cuts() {
    n_ticks = floor(avail_w / tick_spacing);
    for (i = [0 : n_ticks]) {
        mm    = i * tick_spacing;
        xx    = edge_margin + mm;
        major = (mm % ruler_number_every == 0);
        tlen  = major ? major_tick_len : minor_tick_len;

        // tick, hanging downwards from the lowest row
        translate([xx - tick_width/2, ruler_base - tlen,
                   board_thickness - ruler_etch_depth])
            cube([tick_width, tlen, ruler_etch_depth + 0.02]);

        // number (in cm) under the major ticks
        if (major)
            etch_text(xx, ruler_base - major_tick_len - 1.5 - ruler_number_size/2,
                      str(mm / 10), ruler_number_size);
    }
}

/* ---------------- final part ---------------- */
difference() {
    board_body();
    row1_cuts();
    row2_cuts();
    if (row3_enabled) row3_cuts();
    magnet_cuts();
    letter_cuts();
    if (ruler_enabled) ruler_cuts();
}
