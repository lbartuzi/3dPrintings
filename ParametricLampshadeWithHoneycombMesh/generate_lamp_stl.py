import math
import numpy as np
import trimesh
from pathlib import Path

# Parametric Table Lamp Shade - generated from provided OpenSCAD equations
# Units: mm
FN = 72
shade_height = 145.0
bottom_diameter = 150.0
top_diameter = 92.0
profile_steps = 56
angle_steps = 120
profile_belly_amount = 0.18
profile_waist_amount = 0.07
petal_count = 6
petal_amplitude = 0.045
petal_twist_degrees = 28.0
open_top = True
top_rim_height = 3.0
closed_top_thickness = 1.2
outer_skin_thickness = 0.75
inner_skin_thickness = 0.75
wall_gap = 3.8
bottom_rim_height = 4.0
total_wall_thickness = outer_skin_thickness + wall_gap + inner_skin_thickness
hex_core_enabled = True
hex_core_z_start = 12.0
hex_core_z_end_from_top = 16.0
hex_core_cell_side = 6.8
hex_core_frame_thickness = 0.95
hex_core_embed_into_walls = 0.55
hex_core_surface_clearance = 0.18
holder_hole_diameter = 42.0
holder_disk_outer_diameter = 72.0
holder_disk_thickness = 6.0
holder_mount_z = 10.0
arm_count = 3
arm_width = 13.0
arm_height_at_disk = 6.0
arm_height_at_wall = 11.0
arm_wall_overlap = 1.2
arm_cut_enabled = False
arm_cut_margin = 1.4
hex_core_z_end = shade_height - hex_core_z_end_from_top


def sind(x): return math.sin(math.radians(x))
def cosd(x): return math.cos(math.radians(x))
def clamp(v, lo, hi): return min(max(v, lo), hi)
def lerp(a, b, t): return a + (b - a) * t
def z_t(z): return clamp(z / shade_height, 0.0, 1.0)
def base_radius_at_z(z): return lerp(bottom_diameter / 2, top_diameter / 2, z_t(z))
def profile_multiplier(z):
    return 1 + profile_belly_amount * sind(180 * z_t(z)) - profile_waist_amount * sind(360 * z_t(z))
def petal_multiplier(angle, z):
    return 1 + petal_amplitude * sind(petal_count * angle + petal_twist_degrees * z_t(z))
def outer_radius(angle, z):
    return base_radius_at_z(z) * profile_multiplier(z) * petal_multiplier(angle, z)
def inner_radius(angle, z):
    return outer_radius(angle, z) - total_wall_thickness
def polar_x(r, a): return r * cosd(a)
def polar_y(r, a): return r * sind(a)
def arm_start_radius(): return holder_disk_outer_diameter / 2
def arm_length_at_angle(a): return max(inner_radius(a, holder_mount_z) - arm_start_radius() + arm_wall_overlap, 5.0)

def safe_hex_core_embed():
    return max(0.0, min(hex_core_embed_into_walls, outer_skin_thickness - 0.05, inner_skin_thickness - 0.05))
def safe_core_surface_clearance():
    return max(0.01, min(hex_core_surface_clearance, outer_skin_thickness / 2, inner_skin_thickness / 2))
def core_outer_offset():
    return max(safe_core_surface_clearance(), outer_skin_thickness - safe_hex_core_embed())
def core_inner_offset():
    return total_wall_thickness - max(safe_core_surface_clearance(), inner_skin_thickness - safe_hex_core_embed())
def hex_core_mid_radius(angle, z):
    return outer_radius(angle, z) - (core_outer_offset() + core_inner_offset()) / 2
def honeycomb_cell_width(side): return math.sqrt(3) * side
def honeycomb_row_pitch(side): return 1.5 * side
def honeycomb_half_height(side, wall): return side + wall / 2

def pointy_hex_points(side):
    w = math.sqrt(3) * side / 2
    return np.array([
        [0, side], [w, side/2], [w, -side/2], [0, -side], [-w, -side/2], [-w, side/2]
    ], dtype=float)

def local_to_angle(a0, z0, x):
    return a0 + (x / max(hex_core_mid_radius(a0, z0), 1.0)) * 180 / math.pi

def core_point(a, z, offset_from_outer_surface):
    r = outer_radius(a, z) - offset_from_outer_surface
    return [polar_x(r, a), polar_y(r, a), z]


def make_mesh(points, faces, name=''):
    mesh = trimesh.Trimesh(vertices=np.array(points, dtype=float), faces=np.array(faces, dtype=np.int64), process=False)
    mesh.metadata['name'] = name
    return mesh


def surface_shell(radius_outer_offset, radius_inner_offset, z_min, z_max, name='surface_shell'):
    points_outer = []
    for zi in range(profile_steps + 1):
        z = lerp(z_min, z_max, zi / profile_steps)
        for ai in range(angle_steps):
            a = ai * 360 / angle_steps
            r = outer_radius(a, z) - radius_outer_offset
            points_outer.append([polar_x(r, a), polar_y(r, a), z])
    points_inner = []
    for zi in range(profile_steps + 1):
        z = lerp(z_min, z_max, zi / profile_steps)
        for ai in range(angle_steps):
            a = ai * 360 / angle_steps
            r = outer_radius(a, z) - radius_inner_offset
            points_inner.append([polar_x(r, a), polar_y(r, a), z])
    points_all = points_outer + points_inner
    inner_offset = (profile_steps + 1) * angle_steps
    faces = []
    # outer surface
    for zi in range(profile_steps):
        for ai in range(angle_steps):
            faces.append([zi * angle_steps + ai,
                          zi * angle_steps + ((ai + 1) % angle_steps),
                          (zi + 1) * angle_steps + ((ai + 1) % angle_steps)])
            faces.append([zi * angle_steps + ai,
                          (zi + 1) * angle_steps + ((ai + 1) % angle_steps),
                          (zi + 1) * angle_steps + ai])
    # inner surface reverse
    for zi in range(profile_steps):
        for ai in range(angle_steps):
            faces.append([inner_offset + (zi + 1) * angle_steps + ai,
                          inner_offset + (zi + 1) * angle_steps + ((ai + 1) % angle_steps),
                          inner_offset + zi * angle_steps + ((ai + 1) % angle_steps)])
            faces.append([inner_offset + (zi + 1) * angle_steps + ai,
                          inner_offset + zi * angle_steps + ((ai + 1) % angle_steps),
                          inner_offset + zi * angle_steps + ai])
    # bottom ring
    for ai in range(angle_steps):
        faces.append([ai, inner_offset + ai, inner_offset + ((ai + 1) % angle_steps)])
        faces.append([ai, inner_offset + ((ai + 1) % angle_steps), ((ai + 1) % angle_steps)])
    # top ring
    top_outer_start = profile_steps * angle_steps
    top_inner_start = inner_offset + profile_steps * angle_steps
    for ai in range(angle_steps):
        faces.append([top_outer_start + ai,
                      top_outer_start + ((ai + 1) % angle_steps),
                      top_inner_start + ((ai + 1) % angle_steps)])
        faces.append([top_outer_start + ai,
                      top_inner_start + ((ai + 1) % angle_steps),
                      top_inner_start + ai])
    return make_mesh(points_all, faces, name)


def conformal_honeycomb_rib(a0, z0, p1, p2):
    dx, dy = p2[0] - p1[0], p2[1] - p1[1]
    rib_len = math.hypot(dx, dy)
    if rib_len <= 0.001:
        return None
    nx, ny = -dy / rib_len, dx / rib_len
    hw = hex_core_frame_thickness / 2
    c0 = [p1[0] + nx * hw, p1[1] + ny * hw]
    c1 = [p2[0] + nx * hw, p2[1] + ny * hw]
    c2 = [p2[0] - nx * hw, p2[1] - ny * hw]
    c3 = [p1[0] - nx * hw, p1[1] - ny * hw]
    cs = [c0, c1, c2, c3]
    aa = [local_to_angle(a0, z0, c[0]) for c in cs]
    zz = [z0 + c[1] for c in cs]
    points = [core_point(aa[i], zz[i], core_outer_offset()) for i in range(4)] + \
             [core_point(aa[i], zz[i], core_inner_offset()) for i in range(4)]
    faces = [
        [0, 1, 2], [0, 2, 3],
        [7, 6, 5], [7, 5, 4],
        [0, 4, 5], [0, 5, 1],
        [1, 5, 6], [1, 6, 2],
        [2, 6, 7], [2, 7, 3],
        [3, 7, 4], [3, 4, 0]
    ]
    return make_mesh(points, faces, 'rib')


def embedded_hex_core_meshes():
    meshes = []
    if not hex_core_enabled:
        return meshes
    row_pitch = honeycomb_row_pitch(hex_core_cell_side)
    col_pitch = honeycomb_cell_width(hex_core_cell_side)
    z_margin = honeycomb_half_height(hex_core_cell_side, hex_core_frame_thickness)
    row_count = max(1, math.floor((hex_core_z_end - hex_core_z_start - 2 * z_margin) / row_pitch) + 1)
    pts = pointy_hex_points(hex_core_cell_side)
    edges = [(0,1),(1,2),(2,3)]
    for row in range(row_count):
        z = hex_core_z_start + z_margin + row * row_pitch
        if z <= hex_core_z_end - z_margin:
            avg_mid_radius = base_radius_at_z(z) * profile_multiplier(z) - (core_outer_offset() + core_inner_offset()) / 2
            circumference = 2 * math.pi * avg_mid_radius
            col_count = max(12, round(circumference / col_pitch))
            a_step = 360 / col_count
            row_offset = (row % 2) * a_step / 2
            for col in range(col_count):
                a = col * a_step + row_offset
                for e0, e1 in edges:
                    m = conformal_honeycomb_rib(a, z, pts[e0], pts[e1])
                    if m is not None:
                        meshes.append(m)
    return meshes


def annular_cylinder(outer_d, inner_d, h, z_center, segments=FN, name='annular_cylinder'):
    ro, ri = outer_d / 2, inner_d / 2
    z0, z1 = z_center - h / 2, z_center + h / 2
    pts = []
    # bottom outer, bottom inner, top outer, top inner
    for z in [z0]:
        for i in range(segments):
            a = i * 360 / segments
            pts.append([polar_x(ro, a), polar_y(ro, a), z])
        for i in range(segments):
            a = i * 360 / segments
            pts.append([polar_x(ri, a), polar_y(ri, a), z])
    for z in [z1]:
        for i in range(segments):
            a = i * 360 / segments
            pts.append([polar_x(ro, a), polar_y(ro, a), z])
        for i in range(segments):
            a = i * 360 / segments
            pts.append([polar_x(ri, a), polar_y(ri, a), z])
    bo, bi, to, ti = 0, segments, 2 * segments, 3 * segments
    faces = []
    for i in range(segments):
        j = (i + 1) % segments
        # outer wall
        faces.append([bo+i, bo+j, to+j]); faces.append([bo+i, to+j, to+i])
        # inner wall reverse
        faces.append([bi+j, bi+i, ti+i]); faces.append([bi+j, ti+i, ti+j])
        # bottom annulus
        faces.append([bo+j, bo+i, bi+i]); faces.append([bo+j, bi+i, bi+j])
        # top annulus
        faces.append([to+i, to+j, ti+j]); faces.append([to+i, ti+j, ti+i])
    return make_mesh(pts, faces, name)


def triangular_arm_body(len_):
    pts = np.array([
        [0, -arm_width / 2, 0],
        [0,  arm_width / 2, 0],
        [0, 0, arm_height_at_disk],
        [len_, -arm_width / 2, 0],
        [len_,  arm_width / 2, 0],
        [len_, 0, arm_height_at_wall],
    ], dtype=float)
    faces = np.array([
        [0, 2, 1],
        [3, 4, 5],
        [0, 1, 4], [0, 4, 3],
        [1, 2, 5], [1, 5, 4],
        [0, 3, 5], [0, 5, 2],
    ], dtype=np.int64)
    return trimesh.Trimesh(vertices=pts, faces=faces, process=False)


def transform_arm(mesh, angle_deg):
    # OpenSCAD order: rotate([0,0,a]) translate([r,0,z]) spider_arm(len)
    r = arm_start_radius() - 0.1
    z = holder_mount_z - arm_height_at_disk / 2
    T = np.eye(4); T[:3, 3] = [r, 0, z]
    R = trimesh.transformations.rotation_matrix(math.radians(angle_deg), [0, 0, 1])
    m = mesh.copy()
    m.apply_transform(R @ T)
    return m


def spider_arm_meshes():
    meshes = []
    for i in range(arm_count):
        a = i * 360 / arm_count
        body = triangular_arm_body(arm_length_at_angle(a))
        meshes.append(transform_arm(body, a))
    return meshes


def build():
    parts = []
    parts.append(surface_shell(0, outer_skin_thickness, 0, shade_height, 'outer_skin'))
    parts.append(surface_shell(outer_skin_thickness + wall_gap, total_wall_thickness, 0, shade_height, 'inner_skin'))
    parts.append(surface_shell(0, total_wall_thickness, 0, bottom_rim_height, 'bottom_rim'))
    if open_top:
        parts.append(surface_shell(0, total_wall_thickness, shade_height - top_rim_height, shade_height, 'top_rim'))
    # closed_top intentionally skipped; open_top=True
    parts.extend(embedded_hex_core_meshes())
    parts.append(annular_cylinder(holder_disk_outer_diameter, holder_hole_diameter, holder_disk_thickness, holder_mount_z, FN, 'holder_adapter_disk'))
    parts.extend(spider_arm_meshes())
    combined = trimesh.util.concatenate(parts)
    # Merge exact duplicates for smaller file, keep multi-shell geometry intact.
    combined.merge_vertices(digits_vertex=8)
    trimesh.repair.fix_normals(combined, multibody=True)
    return combined, parts

if __name__ == '__main__':
    mesh, parts = build()
    out = Path('/mnt/data/parametric_table_lamp_shade_generated.stl')
    mesh.export(out)
    bounds = mesh.bounds
    print('exported', out)
    print('vertices', len(mesh.vertices), 'faces', len(mesh.faces), 'parts', len(parts))
    print('bounds_min', bounds[0], 'bounds_max', bounds[1])
    print('extents', mesh.extents)
    print('is_watertight', mesh.is_watertight)
    print('volume', mesh.volume)
