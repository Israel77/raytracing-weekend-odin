package raytracer

import "core:math/rand"
import "core:slice"

PixelCoords :: struct {
	x: int,
	y: int,
}

paint_pixel :: proc(rt_context: ^RaytracerContext, pixel: PixelCoords, image_width: int, pixel_colors: []Color) {

    pixel_color: Color
    pixel_samples_scale := 1.0 / f64(rt_context.camera.samples_per_pixel)

    for _ in 0..<rt_context.camera.samples_per_pixel {
        offset := Vec3{rand.float64() - 0.5, rand.float64() - 0.5, 0}
        pixel_center :=
            rt_context.camera.viewport.starting_pixel_center +
            (f64(pixel.x) + offset.x) * rt_context.camera.viewport.delta_u +
            (f64(pixel.y) + offset.y) * rt_context.camera.viewport.delta_v

        ray_direction := pixel_center - rt_context.camera.center
        ray := Ray{rt_context.camera.center, ray_direction}

        pixel_color += pixel_samples_scale * ray_color(&ray, rt_context.world[:], rt_context.camera.max_depth)
    }

    pixel_colors[get_index(pixel, image_width)] = pixel_color
}

get_index :: proc "contextless" (pixel: PixelCoords, image_width: int) -> (index: int) {
	index = pixel.x + image_width * pixel.y
	return
}
