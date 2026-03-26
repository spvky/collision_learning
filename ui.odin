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
	Inspector,
}

init_ui_context :: proc() {
	ui_context = UI_Context {
		window_positions = {.Inspector = {200, 100}},
		window_held = {.Inspector = false},
		window_visible = {.Inspector = true},
	}
}


draw_editor_windows :: proc(u: ^UI_Context) {
	for v in UI_Window {
		if u.window_visible[v] {
			position := u.window_positions[v]
			banner_rect := rl.Rectangle {
				x      = position.x,
				y      = position.y,
				width  = 500,
				height = 50,
			}
			body_rect := rl.Rectangle {
				x      = position.x,
				y      = position.y + 50,
				width  = 500,
				height = 200,
			}
			rl.DrawRectanglePro(banner_rect, {0, 0}, 0, ACTIVE_TAB_COLOR)
			title := fmt.tprintf("%v", v)
			margin := get_window_margin(u, v)
			rl.DrawTextEx(
				assets.font,
				strings.clone_to_cstring(title, allocator = context.temp_allocator),
				{margin - 5, position.y + 5},
				40,
				0,
				rl.WHITE,
			)
			rl.DrawRectanglePro(body_rect, {0, 0}, 0, INACTIVE_TAB_COLOR)
			switch v {
			case .Inspector:
				for sv in selected_vertices {
					vertex := collision_objects[sv.object_idx].verts[sv.vert_idx]
					info_string, position_string: string
					switch em {
					case .Point:
						info_string = fmt.tprintf("Vertex [%v] | [%v]", sv.object_idx, sv.vert_idx)
						position_string = fmt.tprintf(
							"%.2f | %.2f | %.2f",
							vertex.x,
							vertex.y,
							vertex.z,
						)
					case .Edge:
					case .Face:
					}
					rl.DrawTextEx(
						assets.font,
						strings.clone_to_cstring(info_string, allocator = context.temp_allocator),
						{margin, position.y + 55},
						24,
						0,
						rl.WHITE,
					)
					rl.DrawTextEx(
						assets.font,
						strings.clone_to_cstring(
							position_string,
							allocator = context.temp_allocator,
						),
						{margin, position.y + 90},
						16,
						0,
						rl.WHITE,
					)
				}
			}
		}
	}
}

ui_point_inside :: #force_inline proc(p: [2]f32, b: [2][2]f32) -> bool {
	return p.x >= b[0].x && p.y >= b[0].y && p.x <= b[1].x && p.y <= b[1].y
}

get_window_margin :: #force_inline proc(u: ^UI_Context, v: UI_Window) -> f32 {
	return u.window_positions[v].x + 10
}

pickup_editor_windows :: proc(u: ^UI_Context) {
	for v in UI_Window {
		if u.window_visible[v] {
			position := u.window_positions[v]
			mouse_pos := rl.GetMousePosition()
			banner_bounds := [2][2]f32 {
				{position.x, position.y},
				{position.x + 500, position.y + 50},
			}

			if ui_point_inside(mouse_pos, banner_bounds) && rl.IsMouseButtonPressed(.LEFT) {
				u.window_held[v] = true
			}
		}
	}
}

release_editor_windows :: proc(u: ^UI_Context) {
	if rl.IsMouseButtonReleased(.LEFT) {
		for v in UI_Window {
			u.window_held[v] = false
		}
	}
}

drag_editor_windows :: proc(u: ^UI_Context) {
	mouse_delta := rl.GetMouseDelta()
	for v in UI_Window {
		if u.window_held[v] {
			u.window_positions[v] += mouse_delta
		}
	}
}

ui_test :: proc() {
	if rl.IsKeyPressed(.TAB) {
		cycle_editor_mode()
	}
	pickup_editor_windows(&ui_context)
	release_editor_windows(&ui_context)
	drag_editor_windows(&ui_context)
	if hit, hit_vertex := collision_object_raycast(); hit {
		found: bool
		found_index: int
		for sv, i in selected_vertices {
			if sv == hit_vertex {
				found = true
				found_index = i
				break
			}
		}
		shift_held := rl.IsKeyDown(.LEFT_SHIFT)
		if !found {
			if len(selected_vertices) > 0 && !shift_held {
				clear(&selected_vertices)
			}
			append(&selected_vertices, hit_vertex)
		} else {
			unordered_remove(&selected_vertices, found_index)
		}
	}
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)
	// draw_ui()
	draw_scene()
	// draw_editor_windows(&ui_context)
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
