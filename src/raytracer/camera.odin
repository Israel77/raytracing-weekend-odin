package raytracer

import "core:math" 
import "core:math/linalg" 

Camera :: struct {
	focal_length:      f64,
    vertical_fov:      f64,
	samples_per_pixel: int,
    max_depth:         int,
	center:            Vec3,
    look_from:         Vec3,
    look_at:           Vec3,
    view_up:           Vec3,
	viewport:          Viewport,
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

camera_init :: proc (image_width: int, image_height: int) -> Camera {
	camera: Camera

    camera.look_from = Vec3{-2,1,1}
    camera.look_at = Vec3{0,0,-1}
    camera.view_up = Vec3{0,1,0}

    camera.vertical_fov = 45;
	camera.focal_length = 1.0
    camera.samples_per_pixel = 10
    camera.max_depth = 20

    theta := math.to_radians(camera.vertical_fov)
    h := math.tan(theta/2)
	camera.viewport.height = 2 * h * camera.focal_length
	camera.viewport.width = camera.viewport.height * f64(image_width) / f64(image_height)
	camera.center = camera.look_from

    w := unit_vector(camera.look_from - camera.look_at)
    u := unit_vector(linalg.cross(camera.view_up, w))
    v := linalg.cross(w, u)

	// Vectors that span each axis of the 2d viewport
	camera.viewport.u = camera.viewport.width * u
	camera.viewport.v = camera.viewport.height * -v

	// Basis for the viewport coordinates
	camera.viewport.delta_u = camera.viewport.u / f64(image_width)
	camera.viewport.delta_v = camera.viewport.v / f64(image_height)

	upper_left :=
		camera.center -
		camera.focal_length * w -
		camera.viewport.u / 2 -
		camera.viewport.v / 2

	camera.viewport.starting_pixel_center =
		upper_left + 0.5 * (camera.viewport.delta_u + camera.viewport.delta_v)


	return camera
}
