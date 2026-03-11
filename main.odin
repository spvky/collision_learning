package main

import "base:runtime"
import "core:log"
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
	margin         = 4,
	value_ptr      = &em,
}

tri := Triangle{{-5, 0, -1}, {1, 0, -1}, {2, 0, 2}}
sphere := Sphere{1, 3, 2, 1}
colliding: bool
projected: Vec3
pen_normal: Vec3
pen_depth: f32


main :: proc() {
	context.logger = log.create_console_logger(
		opt = runtime.Logger_Options{.Level, .Short_File_Path, .Line},
	)
	rl.InitWindow(1920, 1080, "GJK")
	load_assets()
	init_ui_context()
	camera = rl.Camera3D {
		fovy     = 90,
		position = {5, 2, -10},
		up       = {0, 1, 0},
	}
	init_collision_objects()
	init_editor_event_manager()

	for !rl.WindowShouldClose() {
		// rl.UpdateCamera(&camera, .ORBITAL)
		ui_test()
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
		sphere[0] -= delta * 5
	}
	if rl.IsKeyDown(.A) {
		sphere[0] += delta * 5
	}
	if rl.IsKeyDown(.UP) {
		sphere[1] += delta * 5
	}
	if rl.IsKeyDown(.DOWN) {
		sphere[1] -= delta * 5
	}
}


draw_grid :: proc(size: int = 10) {
	f_size := f32(size)
	grid_white: rl.Color = {255, 255, 255, 80}
	rl.DrawLine3D({0, -f_size, 0}, {0, f_size, 0}, rl.YELLOW)
	rl.DrawLine3D({0, 0, -f_size}, {0, 0, f_size}, rl.RED)
	rl.DrawLine3D({-f_size, 0, 0}, {f_size, 0, 0}, rl.BLUE)
	for i in 1 ..< size {
		f_i := f32(i)
		// X-Z
		rl.DrawLine3D({f_i, 0, -f_size}, {f_i, 0, f_size}, grid_white)
		rl.DrawLine3D({-f_i, 0, -f_size}, {-f_i, 0, f_size}, grid_white)
		rl.DrawLine3D({-f_size, 0, f_i}, {f_size, 0, f_i}, grid_white)
		rl.DrawLine3D({-f_size, 0, -f_i}, {f_size, 0, -f_i}, grid_white)
		// Y-X
		rl.DrawLine3D({-f_size, f_i, 0}, {f_size, f_i, 0}, grid_white)
		rl.DrawLine3D({-f_size, -f_i, 0}, {f_size, -f_i, 0}, grid_white)
		rl.DrawLine3D({f_i, -f_size, 0}, {f_i, f_size, 0}, grid_white)
		rl.DrawLine3D({-f_i, -f_size, 0}, {-f_i, f_size, 0}, grid_white)

	}
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


debug_text :: proc() {
}
