package main

import "base:intrinsics"
import "core:fmt"
import "core:log"
import "core:strings"
import rl "vendor:raylib"

ACTIVE_TAB_COLOR: rl.Color : {99, 226, 212, 255}
INACTIVE_TAB_COLOR: rl.Color : {48, 153, 156, 255}


Tab_Group :: struct($T: typeid) where intrinsics.type_is_enum(T) {
	font_color:     rl.Color,
	active_color:   rl.Color,
	inactive_color: rl.Color,
	layout:         Tab_Group_Layout,
	font_size:      i32,
	padding:        i32,
	margin:         i32,
	value_ptr:      ^T,
}

Tab_Group_Layout :: enum {
	Row,
	Column,
}

ui_context: UI_Context

UI_Context :: struct {
	window_positions: [UI_Window][2]f32,
	window_held:      [UI_Window]bool,
	window_visible:   [UI_Window]bool,
}

UI_Window :: enum {
	Editor,
}

init_ui_context :: proc() {
	ui_context = UI_Context {
		window_positions = {.Editor = {200, 100}},
		window_held = {.Editor = false},
		window_visible = {.Editor = true},
	}
}

draw_editor_window :: proc(u: ^UI_Context) {
	editor_position := u.window_positions[.Editor]
	banner_rect := rl.Rectangle {
		x      = editor_position.x,
		y      = editor_position.y,
		width  = 500,
		height = 50,
	}

	body_rect := rl.Rectangle {
		x      = editor_position.x,
		y      = editor_position.y + 50,
		width  = 500,
		height = 800,
	}
	rl.DrawRectanglePro(banner_rect, {0, 0}, 0, ACTIVE_TAB_COLOR)
	rl.DrawRectanglePro(body_rect, {0, 0}, 0, INACTIVE_TAB_COLOR)
}

ui_point_inside :: #force_inline proc(p: [2]f32, b: [2][2]f32) -> bool {
	return p.x >= b[0].x && p.y >= b[0].y && p.x <= b[1].x && p.y <= b[1].y
}

pickup_editor_window :: proc(u: ^UI_Context) {
	editor_position := u.window_positions[.Editor]
	mouse_pos := rl.GetMousePosition()
	banner_bounds := [2][2]f32 {
		{editor_position.x, editor_position.y},
		{editor_position.x + 500, editor_position.y + 50},
	}

	if ui_point_inside(mouse_pos, banner_bounds) && rl.IsMouseButtonPressed(.LEFT) {
		u.window_held[.Editor] = true
	}
}

release_editor_window :: proc(u: ^UI_Context) {
	if rl.IsMouseButtonReleased(.LEFT) {
		for v in UI_Window {
			u.window_held[v] = false
		}
	}
}

drag_editor_window :: proc(u: ^UI_Context) {
	mouse_delta := rl.GetMouseDelta()
	for v in UI_Window {
		if u.window_held[v] {
			u.window_positions[v] += mouse_delta
		}
	}
}

ui_test :: proc() {
	// if rl.IsKeyPressed(.TAB) {
	// 	cycle_editor_mode()
	// }
	pickup_editor_window(&ui_context)
	release_editor_window(&ui_context)
	drag_editor_window(&ui_context)
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)
	// draw_ui()
	draw_scene()
	draw_editor_window(&ui_context)
	rl.EndDrawing()
}

draw_ui :: proc() {
	tab_offset := draw_tab_group(&tg, {50, 50})
}

cycle_editor_mode :: proc() {
	switch em {
	case .Point:
		em = .Edge
	case .Edge:
		em = .Face
	case .Face:
		em = .Point
	}
}

// Create an arena for editor data
draw_tab_group :: proc(tg: ^Tab_Group($T), position: [2]i32) -> (offset: [2]i32) {
	offset = position
	for v in T {
		s_value := fmt.tprintf("%v", v)
		s_string := strings.clone_to_cstring(s_value, allocator = context.temp_allocator)
		text_width := rl.MeasureText(s_string, tg.font_size)
		width := (tg.padding * 2) + text_width
		height := (tg.padding * 2) + tg.font_size
		color := v == tg.value_ptr^ ? tg.active_color : tg.inactive_color
		rl.DrawRectangle(offset.x, offset.y, width, height, color)
		rl.DrawText(
			s_string,
			offset.x + tg.padding,
			offset.y + tg.padding,
			tg.font_size,
			tg.font_color,
		)

		if tg.layout == .Row {
			offset += {width + tg.margin, 0}
		} else {
			offset += {0, height + tg.margin}
		}
	}
	return
}
