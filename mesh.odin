package main

import rl "vendor:raylib"

mesh_from_collision_object :: proc(co: ^Collision_Object) -> (mesh: rl.Mesh) {
	mesh.vertexCount = i32(len(co.verts))
	mesh.triangleCount = i32(len(co.faces))

	// Convert our verts array to the format raylib expects them
	vertices := make([dynamic]f32, 0, 3 * mesh.vertexCount, allocator = context.temp_allocator)
	indices := make([dynamic]u16, 0, mesh.triangleCount * 3, allocator = context.temp_allocator)

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
	mesh.vertices = raw_data(vertices[:])
	mesh.indices = raw_data(indices[:])
	return mesh
}
