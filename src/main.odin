package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "core:mem/virtual"
import "core:os"
import "core:slice"
import "core:strings"

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
	rt_context.world = raytracer.world_init()

	// Camera setup
	rt_context.camera = raytracer.camera_init(IMAGE_WIDTH, IMAGE_HEIGHT)

	pixel_colors := make_slice([]Color, IMAGE_WIDTH * IMAGE_HEIGHT)

	for j in 0 ..< IMAGE_HEIGHT {
		for i in 0 ..< IMAGE_WIDTH {

	           pixel := raytracer.PixelCoords{i, j}

	           raytracer.paint_pixel(&rt_context, pixel, IMAGE_WIDTH, pixel_colors)
		}
	}

	fmt.println("Writing file to disk...")
	write_colors(fd, pixel_colors[:])

	fmt.println("Done")
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
