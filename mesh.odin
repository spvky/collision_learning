package main

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
