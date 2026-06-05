# Single-piece Rectangular-to-Round Duct with Movable Aerodynamic Blades

This OpenSCAD model creates a **single-piece rectangular-to-round duct adapter** with **separately printed movable aerodynamic guide blades**.

The default design is intended for a printer with a **200 × 200 mm bed**, such as the Tronxy D01.

## Main dimensions

Default dimensions are in **millimetres**.

| Part | Default value |
|---|---:|
| Rectangular outside size | 200 × 130 mm |
| Circular outside diameter | 150 mm |
| Total height | 150 mm |
| Rectangular straight section height | 50 mm |
| Circular straight section height | 50 mm |
| Transition height | 50 mm, calculated automatically |
| Wall thickness | 3 mm |
| Number of blades | 10 |
| Blade pivot height | 25 mm, middle of the rectangular section |

The rectangular part has **no flange**. It is a straight 50 mm high rectangular duct section with mounting holes for the movable blades.

## Files

Main OpenSCAD file:

```text
single_piece_rect_to_round_duct_movable_blades.scad
```

This README explains how to use that file and which parameters are most important.

## Coordinate system

The model uses this orientation:

- **X** = long side of the rectangle, default 200 mm.
- **Y** = short side of the rectangle, default 130 mm.
- **Z** = total height of the duct.
- The blades are distributed across the **X** direction.
- Each blade spans across the **Y** direction.
- Each blade pivots around the **Y axis**.

This means the 10 blades sit side-by-side across the 200 mm rectangular width and each blade crosses the 130 mm smaller opening.

## Output modes

The file uses the `show_part` parameter to choose what OpenSCAD displays or exports.

```scad
show_part = "duct_only";
```

Available modes:

| Mode | Purpose |
|---|---|
| `duct_only` | Export only the duct body with blade mounting holes. |
| `blade_only` | Export one separate aerodynamic blade. |
| `blade_set` | Export all 10 blades laid out for printing. |
| `assembly_preview` | Preview duct and blades together. Do not use this for final printing. |
| `cutaway` | Preview with part of the model cut away so the internal blade system is visible. |

## Recommended workflow

### 1. Export the duct

Set:

```scad
show_part = "duct_only";
```

Then render and export the STL from OpenSCAD.

In OpenSCAD:

1. Press **F6** to render.
2. Go to **File → Export → Export as STL**.
3. Save as something like:

```text
duct_body.stl
```

### 2. Export the blades

Set:

```scad
show_part = "blade_set";
```

Then render and export again as STL.

Suggested filename:

```text
blade_set_10x.stl
```

### 3. Optional: inspect one blade

Set:

```scad
show_part = "blade_only";
```

This is useful if you want to test-print a single blade before printing all 10.

### 4. Optional: check the assembled preview

Set:

```scad
show_part = "assembly_preview";
```

This shows the duct with all blades inserted. It is meant for visual checking only.

Do **not** export this mode for printing unless you intentionally want a non-moving fused preview model.

## Important parameters

### Main duct dimensions

```scad
rect_size_mode = "outer";
rect_w = 200;
rect_d = 130;

circle_od = 150;
wall = 3;

total_h = 150;
rect_section_h = 50;
circle_section_h = 50;
```

With `rect_size_mode = "outer"`, the printed outside footprint is exactly **200 × 130 mm**.

This is recommended for a 200 × 200 mm bed.

If you change this to:

```scad
rect_size_mode = "inner";
```

then `rect_w` and `rect_d` become the internal airflow opening. The outside size becomes larger because wall thickness is added on both sides.

For example, with `wall = 3`, a 200 × 130 mm internal opening becomes a 206 × 136 mm outside footprint.

## Blade system

Default blade settings:

```scad
blade_count = 10;
blade_angle_y = 0;
blade_gap_between = 2.2;
blade_max_thickness = 6.0;
blade_side_clearance = 0.65;
airfoil_steps = 28;
```

The blades are separate printed parts. They are not fused into the duct.

The blade profile is a rounded symmetric airfoil-like shape, which should create less turbulence and less noise than a flat rectangular plate.

### Blade angle

```scad
blade_angle_y = 0;
```

This affects only `assembly_preview` and `cutaway` mode.

It does not change the printed blade STL unless you modify the blade print modules yourself.

Typical preview values:

```scad
blade_angle_y = 0;    // straight airflow
blade_angle_y = 15;   // slight direction change
blade_angle_y = 30;   // stronger direction change
blade_angle_y = -30;  // opposite direction
```

## Mounting holes

The mounting holes are cut through the rectangular side walls.

Default parameters:

```scad
pivot_pin_d = 4.0;
hole_clearance = 0.45;
mount_hole_d = pivot_pin_d + hole_clearance;
mount_z_override = 0;
```

With the default values:

```scad
mount_hole_d = 4.45;
```

The default hole height is calculated automatically:

```scad
mount_z = rect_section_h / 2;
```

Because the rectangular section is 50 mm high, the holes are at:

```text
25 mm from the bottom
```

To manually set another mounting height, use:

```scad
mount_z_override = 30;
```

This would place the blade axle holes at 30 mm from the bottom.

## Integral pins versus separate rod

There are two possible blade mounting styles.

### Option A: printed integral axle pins

Default:

```scad
blade_integral_pins = true;
blade_pivot_bore = false;
```

Each blade has printed axle pins on both sides.

This is the simplest option, but installation requires slight flex in the duct wall or blade. PETG is usually flexible enough for this, but the fit depends on your printer accuracy.

### Option B: separate rod or screw

Alternative:

```scad
blade_integral_pins = false;
blade_pivot_bore = true;
pivot_bore_d = 3.2;
```

This removes the printed axle pins and cuts a hole through the blade. This can be used with an M3 screw, M3 rod, or another small rod.

This option is more mechanically reliable if the blades need to be adjusted often.

## Tuning clearances

For PETG, the default clearance is intentionally not too tight:

```scad
hole_clearance = 0.45;
blade_side_clearance = 0.65;
```

If the blades are too tight:

```scad
hole_clearance = 0.60;
blade_side_clearance = 0.80;
```

If the blades are too loose:

```scad
hole_clearance = 0.30;
blade_side_clearance = 0.45;
```

For a first test, print one blade using:

```scad
show_part = "blade_only";
```

Then test the fit in one pair of duct holes before printing all blades.

## Printing recommendations for PETG

These are practical starting points, not strict requirements.

### Duct body

Recommended orientation:

- Print the rectangular side on the bed.
- Circular outlet points upward.
- No support should normally be required for the transition if the slope is not too aggressive.

Suggested Cura settings for a quick functional PETG print:

| Setting | Suggested value |
|---|---:|
| Layer height | 0.24–0.28 mm |
| Wall line count | 3 |
| Top/bottom layers | 4–5 |
| Infill | 10–15% |
| Print speed | 45–60 mm/s |
| Nozzle temperature | according to filament, often 235–245 °C |
| Bed temperature | 75–85 °C |
| Cooling | low, around 20–40% |
| Brim | recommended if bed adhesion is questionable |

### Blades

The blades are small and should be printed more carefully than the duct body.

Suggested settings:

| Setting | Suggested value |
|---|---:|
| Layer height | 0.16–0.20 mm |
| Wall line count | 3 |
| Infill | 30–60% |
| Print speed | 30–45 mm/s |
| Cooling | enough to keep the airfoil clean, but not too much for PETG |

For better strength, use the separate rod option if the blades will be moved regularly.

## Assembly notes

1. Clean the mounting holes after printing.
2. Remove stringing from the blades, especially around the pins or pivot bore.
3. Insert each blade into the matching left/right hole pair.
4. Check that every blade rotates freely.
5. If blades are stiff, lightly sand the pin ends or increase `hole_clearance` and reprint.
6. If air leakage around the blade holes matters, use small washers, printed collars, or flexible sealant after final positioning.

## Noise and airflow notes

The blades are designed as rounded aerodynamic profiles to reduce turbulence compared with simple flat plates.

To reduce noise further:

- Avoid extreme blade angles.
- Keep all blades aligned at the same angle.
- Avoid sharp internal edges and heavy stringing.
- Sand or deburr the blade leading and trailing edges if needed.
- Do not make the blade gap too small, otherwise airflow may whistle.

## Common changes

### Change from 10 to 8 blades

```scad
blade_count = 8;
```

### Increase total height

```scad
total_h = 180;
```

The transition height is calculated automatically:

```text
transition_h = total_h - rect_section_h - circle_section_h
```

### Make the wall thicker

```scad
wall = 4;
```

Remember: if `rect_size_mode = "outer"`, the outside size remains 200 × 130 mm and the internal airflow opening becomes smaller.

### Make the circular outlet larger or smaller

```scad
circle_od = 150;
```

For example:

```scad
circle_od = 160;
```

Check that the model still fits your printer bed.

## Notes for OpenSCAD performance

The model uses lofted geometry and airfoil polygons. If OpenSCAD becomes slow, reduce:

```scad
segments = 64;
airfoil_steps = 20;
```

For smoother output, increase:

```scad
segments = 128;
airfoil_steps = 36;
```

Higher values create cleaner curves but slower rendering and larger STL files.

## Version notes

This README describes the movable-blade version of the duct model.


