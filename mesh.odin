package main

import "core:fmt"
import l "core:math/linalg"
import "core:slice"
import rl "vendor:raylib"

mesh_from_collision_object :: proc(co: ^Collision_Object) -> (mesh: rl.Mesh) {
	mesh.vertexCount = i32(len(co.verts))
	mesh.triangleCount = i32(len(co.faces))

	// Convert our verts array to the format raylib expects them
	vertices := make([dynamic]f32, 0, 3 * mesh.vertexCount, allocator = context.temp_allocator)
	indices := make([dynamic]u16, 0, mesh.triangleCount * 3, allocator = context.temp_allocator)
	tex_coords := make([dynamic]f32, 0, mesh.vertexCount * 2, allocator = context.temp_allocator)
	colors := make([dynamic]u8, 0, mesh.vertexCount * 4, allocator = context.temp_allocator)
	normals := make([dynamic]f32, 0, mesh.vertexCount * 3, allocator = context.temp_allocator)

	for v in co.verts {
		for i in 0 ..< 3 {
			append(&vertices, v[i])
		}
	}

	for t in co.faces {
		for i in 0 ..< 3 {
			append(&indices, u16(t[i]))
		}
	}

	for _ in 0 ..< mesh.vertexCount * 2 {
		append(&tex_coords, 0.5)
	}

	for _ in 0 ..< mesh.vertexCount * 4 {
		append(&colors, 255)
	}

	for _ in 0 ..< mesh.vertexCount {
		append(&normals, 0)
		append(&normals, 1)
		append(&normals, 0)
	}


	mesh.vertices = raw_data(vertices[:])
	mesh.indices = raw_data(indices[:])
	mesh.texcoords = raw_data(tex_coords[:])
	mesh.texcoords2 = raw_data(tex_coords[:])
	mesh.colors = raw_data(colors[:])
	mesh.normals = raw_data(normals[:])
	rl.UploadMesh(&mesh, false)
	return mesh
}

mesh_from_collision_object_ex :: proc(co: ^Collision_Object) -> (mesh: rl.Mesh) {
	tri_count := len(co.faces)
	vert_count := tri_count * 3
	mesh.vertexCount = i32(vert_count)
	mesh.triangleCount = i32(tri_count)

	// Convert our verts array to the format raylib expects them
	vertices := make([dynamic]f32, 0, 3 * vert_count, allocator = context.temp_allocator)
	colors := make([dynamic]u8, 0, vert_count * 4, allocator = context.temp_allocator)
	normals := make([dynamic]f32, 0, vert_count * 3, allocator = context.temp_allocator)
	tex_coords := make([dynamic]f32, 0, vert_count * 2, allocator = context.temp_allocator)

	first := true
	for face in co.faces {
		a := co.verts[face[0]]
		b := co.verts[face[1]]
		c := co.verts[face[2]]
		center := (a + b + c) / 3
		normal := l.normalize(l.cross(b - a, c - a))
		red_val := l.dot(normal, Vec3{1, 0, 0}) * 155
		green_val := l.dot(normal, Vec3{0, 1, 0}) * 155
		blue_val := l.dot(normal, Vec3{0, 0, 1}) * 155

		for i in 0 ..< 3 {
			current_vert := co.verts[face[i]]
			for ii in 0 ..< 3 {
				append(&vertices, current_vert[ii])
				for iii in 0 ..< 3 {
					append(&normals, normal[iii])
				}


				append(&colors, u8(red_val) + 100)
				append(&colors, 0) //u8(green_val) + 100)
				append(&colors, u8(blue_val) + 100)
				append(&colors, 255)
			}
		}

		if first {
			append(&tex_coords, 0)
			append(&tex_coords, 0)

			append(&tex_coords, 0)
			append(&tex_coords, 1)

			append(&tex_coords, 1)
			append(&tex_coords, 0)
		} else {

			append(&tex_coords, 1)
			append(&tex_coords, 1)

			append(&tex_coords, 0)
			append(&tex_coords, 1)

			append(&tex_coords, 1)
			append(&tex_coords, 0)
		}
		first = !first
	}

	mesh.vertices = raw_data(vertices[:])
	mesh.colors = raw_data(colors[:])
	mesh.normals = raw_data(normals[:])
	mesh.texcoords = raw_data(tex_coords[:])
	rl.UploadMesh(&mesh, false)
	return mesh
}

get_triangles_from_mesh :: proc(m: ^rl.Model) -> (triangles: [dynamic]Triangle) {
	total_face_count: int
	for i in 0 ..< m.meshCount {
		total_face_count += int(m.meshes[i].triangleCount)
	}
	// triangles := make([dynamic]Triangle, 0, total_face_count)
	for i in 0 ..< m.meshCount {
		// ii: int
		// for i32(ii) < m.meshes[i].vertexCount {
		// 	triangle: Triangle
		// 	for iii in 0 ..< 3 {
		// 		vertex: Vec3
		// 		for k in 0 ..< 3 {
		// 			vertex[k] = m.meshes[i].vertices[ii + k]
		// 		}
		// 		triangle[iii] = vertex
		// 		ii += 3
		// 	}
		// 	append(&triangles, triangle)
		// }
		ii: int
		mesh := &m.meshes[i]
		triangle_slice := (cast([^]Triangle)mesh.vertices)[:mesh.triangleCount]
		fmt.printfln("TRI COUNT: %v", mesh.triangleCount)
		triangles = slice.clone_to_dynamic(triangle_slice)
		// for ii < mesh.vertexCount {
		// 	triangle_ptr := cast(^Triangle)mesh.vertices[ii:ii + 9]
		// 	append(&triangles, triangle_ptr^)
		// 	ii += 9
		// }
	}
	return triangles
}
