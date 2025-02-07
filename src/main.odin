package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "core:mem/virtual"
import "core:os"
import "core:slice"
import "core:strings"
import "core:thread"

import "raytracer"

Ray :: raytracer.Ray

Color :: raytracer.Color

FILE_PATH :: "./output.ppm"
IMAGE_WIDTH :: 1600
ASPECT_RATIO :: f32(16.) / f32(9.)

main :: proc() {
	IMAGE_HEIGHT := int(math.floor(IMAGE_WIDTH / ASPECT_RATIO))
	IMAGE_HEIGHT = IMAGE_HEIGHT >= 1 ? IMAGE_HEIGHT : 1

	// File setup
	fd, err := os.open(FILE_PATH, os.O_CREATE | os.O_WRONLY)
	defer os.close(fd)
	if err != nil {
		fmt.eprintf(os.error_string(err))
		panic("Could not find or create file descriptor")
	}

	os.write_string(fd, fmt.tprintfln("P3\n%d %d\n255", IMAGE_WIDTH, IMAGE_HEIGHT))

	rt_context: raytracer.RaytracerContext
	// World
	rt_context.world = world_init()

	// Camera setup
	rt_context.camera = raytracer.camera_init(IMAGE_WIDTH, IMAGE_HEIGHT)

	pixel_colors := make_slice([]Color, IMAGE_WIDTH * IMAGE_HEIGHT)

	for j in 0 ..< IMAGE_HEIGHT {
		for i in 0 ..< IMAGE_WIDTH {

	           pixel := raytracer.PixelCoords{i, j}

               //raytracer.paint_pixel(&rt_context, pixel, IMAGE_WIDTH, pixel_colors)
	           thread.run_with_poly_data4(&rt_context, pixel, IMAGE_WIDTH, pixel_colors, raytracer.paint_pixel)
		}
	}

	fmt.println("Writing file to disk...")
	write_colors(fd, pixel_colors[:])

	fmt.println("Done")
}

world_init :: proc() -> []raytracer.Hittable {
    using raytracer

	world: [dynamic]Hittable

	material_ground := Lambertian{Color{0.8, 0.8, 0.0}}
	material_center := Lambertian{Color{0.1, 0.2, 0.5}}
    // Glass sphere
	material_left := Dielectric{1.5}
    // Air bubble inside the glass
	material_bubble := Dielectric{1.0 / 1.5}
	material_right := Metal{Color{0.8, 0.6, 0.2}, 1.0}


	append(&world, Hittable(Sphere{Vec3{ 0.0, -100.5, -1.0}, 100, material_ground}))
	append(&world, Hittable(Sphere{Vec3{ 0.0,    0.0, -1.2}, 0.5, material_center}))
	append(&world, Hittable(Sphere{Vec3{-1.0,    0.0, -1.0}, 0.5, material_left  }))
	append(&world, Hittable(Sphere{Vec3{-1.0,    0.0, -1.0}, 0.4, material_bubble}))
	append(&world, Hittable(Sphere{Vec3{ 1.0,    0.0, -1.0}, 0.5, material_right }))

	return world[:]
}

write_colors :: proc(fd: os.Handle, pixel_colors: []Color) {

	builder: strings.Builder
	for pixel_color in pixel_colors {
		output_r := int(255.99 * linear_to_gamma(pixel_color.r))
		output_g := int(255.99 * linear_to_gamma(pixel_color.g))
		output_b := int(255.99 * linear_to_gamma(pixel_color.b))

		fmt.sbprintfln(&builder, "%d %d %d", output_r, output_g, output_b)
	}

	os.write_string(fd, strings.to_string(builder))
}

linear_to_gamma :: proc "contextless" (linear_component: f64) -> f64 {
    if linear_component > 0 {
        return math.sqrt(linear_component)
    } else {
        return 0
    }
}
