package main

import "core:fmt"
import "core:math"
import l "core:math/linalg"
import rl "vendor:raylib"

camera: rl.Camera3D
Vec3 :: [3]f32

// xyz: position, w: radius
Sphere :: distinct [4]f32

Triangle :: distinct [3]Vec3

Editor_Mode :: enum {
	Point,
	Edge,
	Face,
}

em: Editor_Mode

tg := Tab_Group(Editor_Mode) {
	font_color     = rl.WHITE,
	active_color   = ACTIVE_TAB_COLOR,
	inactive_color = INACTIVE_TAB_COLOR,
	font_size      = 24,
	padding        = 8,
	margin         = 0,
	value_ptr      = &em,
}

tri := Triangle{{-5, 0, -1}, {1, 0, -1}, {2, 0, 2}}
sphere := Sphere{1, 3, 2, 1}
colliding: bool
projected: Vec3
pen_normal: Vec3
pen_depth: f32


main :: proc() {
	rl.InitWindow(1920, 1080, "GJK")
	camera = rl.Camera3D {
		fovy     = 90,
		position = {5, 5, -10},
		up       = {0, 1, 0},
	}

	for !rl.WindowShouldClose() {
		rl.UpdateCamera(&camera, .ORBITAL)
		move_sphere()
		projected = project_point_onto_triangle_face(sphere, tri)
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		draw_tab_group(&tg, {50, 50})
		rl.BeginMode3D(camera)
		colliding, pen_normal, pen_depth = sphere_triangle_collision(sphere, tri, false)
		if pen_normal != {0, 0, 0} {
			sphere.xyz += pen_depth * pen_normal
		}
		draw_grid()
		draw_triangle(tri)
		draw_sphere(sphere)
		draw_nearest()
		rl.EndMode3D()
		rl.EndDrawing()
	}
}

move_sphere :: proc() {
	delta := rl.GetFrameTime()
	if rl.IsKeyDown(.W) {
		sphere[2] += delta * 5
	}
	if rl.IsKeyDown(.S) {
		sphere[2] -= delta * 5
	}
	if rl.IsKeyDown(.D) {
		sphere[0] += delta * 5
	}
	if rl.IsKeyDown(.A) {
		sphere[0] -= delta * 5
	}
	if rl.IsKeyDown(.UP) {
		sphere[1] += delta * 5
	}
	if rl.IsKeyDown(.DOWN) {
		sphere[1] -= delta * 5
	}
}


draw_grid :: proc() {
	rl.DrawLine3D({0, -10, 0}, {0, 10, 0}, rl.YELLOW)
	rl.DrawLine3D({0, 0, -10}, {0, 0, 10}, rl.RED)
	rl.DrawLine3D({-10, 0, 0}, {10, 0, 0}, rl.BLUE)
}

same_direction :: proc(a, b: Vec3) -> bool {
	return l.dot(a, b) > 0
}

triangle_normal :: proc(t: Triangle) -> (normal: Vec3) {
	normal = l.normalize0(l.cross(t[2] - t[0], t[1] - t[0])) //Triangle Normal
	return
}

draw_triangle :: proc(t: Triangle) {
	rl.DrawSphere(t[0], 0.25, rl.BLUE)
	rl.DrawSphere(t[1], 0.25, rl.PINK)
	rl.DrawSphere(t[2], 0.25, rl.BEIGE)
	rl.DrawLine3D(t[0], t[1], rl.RED)
	rl.DrawLine3D(t[0], t[2], rl.RED)
	rl.DrawLine3D(t[1], t[2], rl.RED)

	normal := triangle_normal(t)
	center := (t[0] + t[1] + t[2]) / 3
	rl.DrawLine3D(center, center + normal * 2, rl.YELLOW)
}

draw_sphere :: proc(s: Sphere) {
	rl.DrawSphereWires(s.xyz, s.w, 8, 8, colliding ? rl.RED : rl.BLUE)
	rl.DrawLine3D(s.xyz, s.xyz + (pen_depth * pen_normal), rl.GRAY)
}

draw_nearest :: proc() {
	p1 := closest_point_on_line_segment(tri[0], tri[1], sphere.xyz)
	p2 := closest_point_on_line_segment(tri[0], tri[2], sphere.xyz)
	p3 := closest_point_on_line_segment(tri[1], tri[2], sphere.xyz)
	rl.DrawSphere(p1, 0.25, rl.GREEN)
	rl.DrawSphere(p2, 0.25, rl.GREEN)
	rl.DrawSphere(p3, 0.25, rl.GREEN)
	rl.DrawSphere(projected, 0.25, rl.GREEN)
}


sphere_triangle_collision :: proc(
	s: Sphere,
	t: Triangle,
	double_sided := false,
) -> (
	collision: bool,
	penetration_normal: Vec3,
	penetration_depth: f32,
) {
	n: Vec3 = l.normalize0(l.cross(t[1] - t[0], t[2] - t[0])) //Triangle Normal
	dist: f32 = l.dot(s.xyz - t[0], n) // Signed distance between sphere and plane
	if !double_sided && dist > 0 {
		// We can pass through the back of the triangle
		return
	}

	if dist < -s.w || dist > s.w {
		// No collision
		return
	}

	// If we hit this line, the sphere does intersect the infinite plane of the triangle, and we can continue solving
	p0: Vec3 = s.xyz - n * dist // Projected sphere center onto the plane

	// Now determine if the projected center (p0) is contained within the triangle
	c0: Vec3 = l.cross(p0 - t[0], t[1] - t[0])
	c1: Vec3 = l.cross(p0 - t[1], t[2] - t[1])
	c2: Vec3 = l.cross(p0 - t[2], t[0] - t[2])
	inside := l.dot(c0, n) <= 0 && l.dot(c1, n) <= 0 && l.dot(c2, n) <= 0
	intersects, np := edges_intersect(t, s)

	if inside || intersects {
		best_point := p0
		intersection_vec: Vec3

		if inside {
			intersection_vec = s.xyz - p0
		} else {
			d := s.xyz - np[0]
			best_distsq := l.dot(d, d)
			best_point = np[0]
			intersection_vec = d

			d = s.xyz - np[1]
			distsq := l.dot(d, d)
			if distsq < best_distsq {
				distsq = best_distsq
				best_point = np[1]
				intersection_vec = d
			}

			d = s.xyz - np[2]
			distsq = l.dot(d, d)
			if distsq < best_distsq {
				distsq = best_distsq
				best_point = np[2]
				intersection_vec = d
			}
		}

		// if l.distance(best_point, s.xyz) < s.w {
		len := l.length(intersection_vec)
		penetration_normal = intersection_vec / len
		penetration_depth = s.w - len
		collision = true
		// }
	}
	return
}

sphere_triangle_sdf :: proc(s: Sphere, t: Triangle) -> (distance: f32) {
	n := triangle_normal(t)
	distance = l.dot(s.w - t[0], n) // Signed distance between sphere and plane
	return
}

closest_point_on_line_segment :: proc(a, b, p: Vec3) -> (point: Vec3) {
	ab := b - a
	t := l.dot(p - a, ab) / l.dot(ab, ab) // A vector dotted against itself equals its squared magnitude
	saturate := math.min(math.max(t, 0), 1)
	point = a + saturate * ab
	return point
}


project_point_onto_triangle_face :: proc(s: Sphere, t: Triangle) -> (point: Vec3) {
	n: Vec3 = l.normalize0(l.cross(t[1] - t[0], t[2] - t[0])) //Triangle Normal
	dist: f32 = l.dot(s.xyz - t[0], n) // Signed distance between sphere and plane
	// If we hit this line, the sphere does intersect the infinite plane of the triangle, and we can continue solving
	point = s.xyz - n * dist // Projected sphere center onto the plane
	return
}


edges_intersect :: proc(t: Triangle, s: Sphere) -> (intersects: bool, np: [3]Vec3) {
	rsq := s.w * s.w
	// Edge AB
	np[0] = closest_point_on_line_segment(t[0], t[1], s.xyz)
	v1 := s.xyz - np[0]
	dist_sq1 := l.dot(v1, v1)
	int1 := dist_sq1 < rsq
	// Edge AC
	np[1] = closest_point_on_line_segment(t[0], t[2], s.xyz)
	v2 := s.xyz - np[1]
	dist_sq2 := l.dot(v2, v2)
	int2 := dist_sq2 < rsq
	// Edge BC
	np[2] = closest_point_on_line_segment(t[1], t[2], s.xyz)
	v3 := s.xyz - np[2]
	dist_sq3 := l.dot(v3, v3)
	int3 := dist_sq3 < rsq
	intersects = int1 || int2 || int3
	return
}

debug_text :: proc() {
}
