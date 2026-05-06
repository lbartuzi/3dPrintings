# Rounded Wrapped Hex Box — OpenSCAD README

This README explains how to use and tune the rounded rectangular open-top box design with a wrapped hexagonal side pattern.

The design is intended for FDM printing, especially PETG, and was developed to avoid stringing-prone open side-wall mesh while keeping the visual look of a honeycomb/hex mesh wrapped around the whole box.

---

## What this model creates

The OpenSCAD file generates a parametric rectangular box with:

- rounded vertical corners
- open top
- scalable wall thickness
- scalable bottom thickness
- bottom as a real open hex mesh
- side walls as one continuous rounded shell
- side hexagons as smooth recessed engravings
- side pattern calculated from the box dimensions
- regular hexagons that are not stretched when the box is resized

The side-wall hexagons are not open holes by default. They are shallow recessed engravings. This makes the print much easier for Cura and reduces stringing problems.

---

## Recommended starting values

These values are a good starting point for PETG with a 0.4 mm nozzle:

```scad
box_length = 160;
box_depth  = 100;
box_height = 70;

wall_thickness   = 2.0;
bottom_thickness = 2.4;

corner_radius = 14;

side_hex_through_holes = false;
side_hex_groove_depth = 0.70;

hex_radius  = 5.0;
web_width   = 1.2;
edge_border = 4.0;
```

For a denser hex pattern with more rows:

```scad
hex_radius  = 4.2;
web_width   = 1.0;
edge_border = 4.0;
```

---

## Main parameters

### Box size

```scad
box_length = 160;
box_depth  = 100;
box_height = 70;
```

These control the outer size of the smooth base box body.

The side-wall hex pattern is recalculated automatically when these values change.

---

### Wall and bottom thickness

```scad
wall_thickness   = 2.0;
bottom_thickness = 2.4;
```

`wall_thickness` controls the thickness of the side wall.

`bottom_thickness` controls the thickness of the bottom mesh.

Recommended values:

```scad
wall_thickness = 2.0;
bottom_thickness = 2.4;
```

For a stronger box:

```scad
wall_thickness = 2.4;
bottom_thickness = 3.0;
```

---

### Rounded corners

```scad
corner_radius = 14;
```

This controls the vertical corner radius.

Larger values make the box more rounded. Smaller values make it more rectangular.

Rules:

```text
corner_radius must be larger than wall_thickness
corner_radius must be less than box_length / 2
corner_radius must be less than box_depth / 2
```

Recommended:

```scad
corner_radius = 10;  // subtle rounding
corner_radius = 14;  // good default
corner_radius = 20;  // very rounded
```

---

## Side-wall hex engraving

### Through-holes or recessed engravings

```scad
side_hex_through_holes = false;
```

Recommended:

```scad
side_hex_through_holes = false;
```

This makes the side-wall hexagons shallow recessed pockets instead of through-holes.

That is better for:

- PETG
- Cura 4.6.1
- reduced stringing
- fewer separate tiny slicing islands
- stronger side walls

Only use this if you really want open side-wall holes:

```scad
side_hex_through_holes = true;
```

---

### Side engraving depth

```scad
side_hex_groove_depth = 0.70;
```

This controls how deep the side-wall hexagons are engraved into the wall.

Recommended values:

```scad
side_hex_groove_depth = 0.55;  // subtle engraving
side_hex_groove_depth = 0.70;  // good default
side_hex_groove_depth = 0.85;  // deeper visual effect
```

Avoid making this almost equal to the full wall thickness unless you really need very deep pockets.

For example, with:

```scad
wall_thickness = 2.0;
side_hex_groove_depth = 0.70;
```

the wall still has about:

```text
2.0 - 0.70 = 1.30 mm
```

of solid material behind the hex pattern.

That is much easier for Cura to slice cleanly than a 0.4 mm membrane.

---

### Side membrane thickness

```scad
side_membrane_thickness = 0.45;
```

This value is mainly relevant when using through-style side pockets or older versions of the design.

For the recommended shallow engraving mode:

```scad
side_hex_through_holes = false;
```

the more important parameter is:

```scad
side_hex_groove_depth
```

---

## Hex pattern size

### Hex radius

```scad
hex_radius = 5.0;
```

This is the center-to-corner radius of each hexagon.

A point-up hexagon has:

```text
height = 2 * hex_radius
width  = sqrt(3) * hex_radius
```

Examples:

```text
hex_radius = 5.0 mm
hex height ≈ 10.0 mm
hex width  ≈ 8.66 mm
```

Smaller radius gives more hexagons. Larger radius gives fewer, larger hexagons.

---

### Web width

```scad
web_width = 1.2;
```

This controls the spacing between neighboring hexagons.

Smaller value = denser pattern.

Larger value = more solid material between hexagons.

Recommended:

```scad
web_width = 1.0;  // dense
web_width = 1.2;  // good default
web_width = 1.5;  // stronger, more solid
```

For a 0.4 mm nozzle, avoid extremely small web widths.

---

### Top and bottom side border

```scad
edge_border = 4.0;
```

This keeps a solid band at the top and bottom of the side wall.

Increasing this makes the box stronger but reduces the number of hex rows.

Decreasing this allows more rows.

Recommended:

```scad
edge_border = 4.0;  // compact border, more rows
edge_border = 6.0;  // stronger border
edge_border = 7.0;  // very safe border
```

---

## How the number of side hexagons is calculated

The number of side-wall hexagons is not manually entered.

It is calculated from:

```scad
box_length
box_depth
box_height
corner_radius
hex_radius
web_width
edge_border
```

### Columns around the box

The code calculates the rounded rectangle perimeter and fits as many hexagons as possible using:

```scad
nominal_pitch_s = hex_opening_width(hex_radius) + web_width;
columns = floor(perimeter_length() / nominal_pitch_s);
pitch_s = perimeter_length() / columns;
```

This means the hexagon count changes when the box size changes.

The hexagons themselves are not stretched.

The spacing is adjusted slightly so the pattern closes around the box.

---

### Rows vertically

Rows are calculated from the usable side-wall height:

```scad
pitch_z = 1.5 * hex_radius + web_width;

rows =
    floor(
        (box_height - 2 * edge_border - 2 * hex_radius)
        / pitch_z
    ) + 1;
```

To get more rows:

```scad
edge_border = 4.0;
hex_radius = 4.2;
web_width = 1.0;
```

To get fewer, larger rows:

```scad
edge_border = 6.0;
hex_radius = 5.5;
web_width = 1.3;
```

---

## About the visible seam or gap

The wrapped side pattern has one unavoidable seam where the unwrapped pattern starts and ends.

The design intentionally avoids placing hexagons directly across this seam to prevent OpenSCAD/CGAL geometry problems.

If you see a plain vertical gap, it is the seam.

### Move the seam to a rounded corner

Use this:

```scad
function pattern_seam_offset() =
    s2();
```

This places the seam at a rounded corner where it is less visible.

### Move the seam to the back wall

Use this:

```scad
function pattern_seam_offset() =
    s4() + straight_x() / 2;
```

This places it around the middle of the rear long wall.

### Make the seam gap smaller

Find:

```scad
seam_margin = hw / 2 + web_width + 1.0;
```

Try:

```scad
seam_margin = hw / 2 + 0.2;
```

A smaller seam margin gives a smaller visual gap, but it gives OpenSCAD less safety margin.

---

## Bottom mesh

The bottom is different from the side walls.

The bottom remains a true open hex mesh:

```scad
bottom_is_mesh = true;
```

To make the bottom solid:

```scad
bottom_is_mesh = false;
```

The bottom hex mesh uses the same:

```scad
hex_radius
web_width
edge_border
```

as the side pattern.

---

## Why the side hexes are recessed, not open holes

Originally, open hex side walls caused two problems:

1. PETG stringing across the open holes
2. Cura printing many tiny separate wall islands

The current design avoids that by using shallow hex engravings.

This gives the visual mesh effect while keeping the side wall continuous and printable.

Recommended:

```scad
side_hex_through_holes = false;
side_hex_groove_depth = 0.55 to 0.85;
```

---

## Cura 4.6.1 recommended settings

These are starting-point settings, not absolute rules.

### Shell

```text
Wall Line Count: 3
Wall Line Width: 0.4 or 0.45
Outer Wall Before Inner Walls: OFF
Optimize Wall Printing Order: ON
Print Thin Walls: ON
Fill Gaps Between Walls: Everywhere
```

### Travel

```text
Enable Retraction: ON
Combing Mode: Off
Avoid Printed Parts When Traveling: OFF
Z Hop When Retracted: OFF unless the nozzle hits the print
Outer Wall Wipe Distance: 0.2 to 0.4 mm
```

### Mesh Fixes

```text
Union Overlapping Volumes: ON
Remove All Holes: OFF
Extensive Stitching: only ON if Cura shows model errors
```

Do not enable `Remove All Holes`, because it can damage or remove the bottom mesh.

---

## PETG anti-stringing tips

PETG can string badly, especially on decorative mesh-style models.

Recommended:

- dry the filament before printing
- lower nozzle temperature slightly if stringing is heavy
- use tuned retraction
- use wipe/coast if available and already tested
- avoid very high nozzle temperature
- keep travel moves fast
- avoid through-hole side walls unless necessary

The side-wall engraving mode is the main geometry-level anti-stringing feature.

---

## OpenSCAD version warning

If you see:

```text
WARNING: Ignoring unknown module 'assert'.
```

your OpenSCAD version is old and does not support `assert()`.

The `assert()` lines are only safety checks. They do not create geometry.

You can remove the `assert()` section or replace it with:

```scad
if (!(corner_radius > wall_thickness))
    echo("WARNING: corner_radius must be larger than wall_thickness");

if (!(corner_radius < box_length / 2))
    echo("WARNING: corner_radius too large for box_length");

if (!(corner_radius < box_depth / 2))
    echo("WARNING: corner_radius too large for box_depth");

if (!(box_height > 2 * edge_border + 2 * hex_radius))
    echo("WARNING: box_height too small for selected hex_radius and edge_border");
```

---

## Troubleshooting

### The side pattern has a large plain gap

That is the seam.

Move it to a corner:

```scad
function pattern_seam_offset() =
    s2();
```

Make it smaller:

```scad
seam_margin = hw / 2 + 0.2;
```

---

### I want more side-wall hex rows

Reduce one or more of these:

```scad
edge_border
hex_radius
web_width
```

Example:

```scad
edge_border = 4.0;
hex_radius = 4.2;
web_width = 1.0;
```

---

### The side hexagons look too shallow

Increase:

```scad
side_hex_groove_depth = 0.85;
```

Do not exceed:

```text
wall_thickness - 0.05
```

unless you intentionally want through-holes.

---

### Cura creates strange artifacts around the hex pattern

Use shallow side engraving:

```scad
side_hex_through_holes = false;
side_hex_groove_depth = 0.55;
```

Also try:

```scad
web_width = 1.4;
edge_border = 6.0;
```

---

### The model renders slowly in OpenSCAD

Use lower preview quality while adjusting dimensions:

```scad
$fn = 48;
$fa = 4;
$fs = 0.5;
```

For final export:

```scad
$fn = 96;
$fa = 2;
$fs = 0.25;
```

---

## Suggested workflow

1. Open the `.scad` file in OpenSCAD.
2. Adjust the main dimensions:
   ```scad
   box_length
   box_depth
   box_height
   ```
3. Choose the corner radius:
   ```scad
   corner_radius
   ```
4. Tune the hex pattern:
   ```scad
   hex_radius
   web_width
   edge_border
   ```
5. Keep side walls in engraving mode:
   ```scad
   side_hex_through_holes = false;
   side_hex_groove_depth = 0.70;
   ```
6. Preview with F5.
7. Render with F6.
8. Export STL.
9. Slice in Cura.
10. Check layer preview before printing.

---

## Good preset examples

### Balanced default

```scad
box_length = 160;
box_depth  = 100;
box_height = 70;

wall_thickness = 2.0;
bottom_thickness = 2.4;
corner_radius = 14;

hex_radius = 5.0;
web_width = 1.2;
edge_border = 4.0;

side_hex_through_holes = false;
side_hex_groove_depth = 0.70;
```

### Denser decorative pattern

```scad
hex_radius = 4.2;
web_width = 1.0;
edge_border = 4.0;
side_hex_groove_depth = 0.60;
```

### Stronger, less delicate pattern

```scad
hex_radius = 5.5;
web_width = 1.5;
edge_border = 6.0;
side_hex_groove_depth = 0.55;
wall_thickness = 2.4;
```

---

## Design philosophy

The design balances appearance and printability.

A fully open side-wall hex mesh looks attractive, but for PETG it can cause severe stringing and Cura slicing artifacts.

This design keeps the visual style of a wrapped hex mesh but uses a continuous side shell with shallow, smooth hex engravings. The bottom can remain open because it prints flat on the bed and does not create the same side-wall bridging/stringing problem.

