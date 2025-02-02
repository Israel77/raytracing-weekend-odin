package raytracer

Camera :: struct {
	focal_length: f64,
    samples_per_pixel: int,
	center:       Vec3,
	viewport:     Viewport,
}

Viewport :: struct {
	width:                 f64,
	height:                f64,
	u:                     Vec3,
	v:                     Vec3,
	delta_u:               Vec3,
	delta_v:               Vec3,
	starting_pixel_center: Vec3,
}

camera_init :: proc "contextless" (image_width: int, image_height: int) -> Camera {
	camera: Camera

    camera.samples_per_pixel = 10
	camera.focal_length = 1.0
	camera.viewport.height = 2.0
	// Use the exact ratio between IMAGE_WIDTH and IMAGE_HEIGHT instead of ASPECT_RATIO
	// due to the previous rounding step when calculating IMAGE_HEIGHT
	camera.viewport.width = camera.viewport.height * f64(image_width) / f64(image_height)
	camera.center = Vec3{0.0, 0.0, 0.0}

	// Vectors that span each axis of the 2d viewport
	camera.viewport.u = Vec3{camera.viewport.width, 0, 0}
	camera.viewport.v = Vec3{0, -camera.viewport.height, 0}

	// Basis for the viewport coordinates
	camera.viewport.delta_u = camera.viewport.u / f64(image_width)
	camera.viewport.delta_v = camera.viewport.v / f64(image_height)

	upper_left :=
		camera.center -
		Vec3{0, 0, camera.focal_length} -
		camera.viewport.u / 2 -
		camera.viewport.v / 2

	camera.viewport.starting_pixel_center =
		upper_left + 0.5 * (camera.viewport.delta_u + camera.viewport.delta_v)


	return camera
}
