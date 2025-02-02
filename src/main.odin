package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "core:mem/virtual"
import "core:os"
import "core:slice"
import "core:strings"

Color :: distinct linalg.Vector3f64
Vec3 :: linalg.Vector3f64

FILE_PATH :: "./output.ppm"
IMAGE_WIDTH :: 1600
ASPECT_RATIO :: f32(16.) / f32(9.)

Ray :: struct {
	origin:    Vec3,
	direction: Vec3,
}

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

Sphere :: struct {
	center: Vec3,
	radius: f64,
}

Hittable :: union {
	Sphere,
	[]Hittable,
}

HitRecord :: struct {
	front_face: bool,
	point:      Vec3,
	normal:     Vec3,
	t:          f64,
}

PixelCoords :: struct {
	x: int,
	y: int,
}

RaytracerContext :: struct {
	world:  []Hittable,
	camera: Camera,
}

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

	rt_context: RaytracerContext
	// World
	rt_context.world = world_init()

	// Camera setup
	rt_context.camera = camera_init(IMAGE_WIDTH, IMAGE_HEIGHT)

	pixel_colors := make_slice([]Color, IMAGE_WIDTH * IMAGE_HEIGHT)

	for j in 0 ..< IMAGE_HEIGHT {
		for i in 0 ..< IMAGE_WIDTH {

            pixel := PixelCoords{i, j}

            paint_pixel(&rt_context, pixel, pixel_colors)
		}
	}

	fmt.println("Writing file to disk...")
	write_colors(fd, pixel_colors[:])

	fmt.println("Done")
}

paint_pixel :: proc(rt_context: ^RaytracerContext, pixel: PixelCoords, pixel_colors: []Color) {

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

        pixel_color += pixel_samples_scale * ray_color(&ray, rt_context.world[:])
    }

    pixel_colors[get_index(pixel, IMAGE_WIDTH)] = pixel_color
}

get_index :: proc "contextless" (pixel: PixelCoords, image_width: int) -> (index: int) {
	index = pixel.x + image_width * pixel.y
	return
}

pixel_comparator :: proc(a: PixelCoords, b: PixelCoords) -> (order: slice.Ordering) {

	index_a := a.x + IMAGE_WIDTH * a.y
	index_b := b.x + IMAGE_WIDTH * b.y

	if      (index_a == index_b) {order = .Equal}
    else if (index_a < index_b)  {order = .Less}
    else if (index_a > index_b)  {order = .Greater}

	return
}


world_init :: proc() -> []Hittable {
	world: [dynamic]Hittable

	append(&world, Hittable(Sphere{Vec3{0, 0, -1}, 0.5}))
	append(&world, Hittable(Sphere{Vec3{0, -100.5, -1}, 100}))

	return world[:]
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

// #region: HitRecord methods
set_face_normal :: proc(self: ^HitRecord, ray: ^Ray, outward_normal: ^Vec3) {
	self.front_face = linalg.dot(ray.direction, outward_normal^) < 0
	self.normal = self.front_face ? outward_normal^ : -outward_normal^
}
// #endregion

// #region: Hittable methods
hit :: proc(
	self: ^Hittable,
	ray: ^Ray,
	ray_tmin: f64,
	ray_tmax: f64,
) -> (
	record: HitRecord,
	did_hit: bool,
) {
	switch hit_type in self {
	case Sphere:
		sphere := hit_type
		// at² - bt - c = 0
		delta_origin_center := sphere.center - ray.origin
		a := linalg.dot(ray.direction, ray.direction)
		//b := -2.0 * linalg.dot(ray.direction, delta_origin_center)
		// Use h = -b / 2 to simplify calculations
		h := linalg.dot(ray.direction, delta_origin_center)
		c := linalg.dot(delta_origin_center, delta_origin_center) - sphere.radius * sphere.radius

		discriminant := h * h - a * c

		if discriminant < 0 {
			did_hit = false
			return
		}

		sqrt_d := math.sqrt(discriminant)

		// Try the first root
		root := (h - sqrt_d) / a
		if (root <= ray_tmin || ray_tmax <= root) {
			// Try the second root
			root := (h - sqrt_d) / a
			if (root <= ray_tmin || ray_tmax <= root) {
				// Fail if no root meets the criteria
				did_hit = false
				return
			}
		}

		record.t = root
		record.point = ray.origin + root * ray.direction
		outward_normal := (record.point - sphere.center) / sphere.radius

		// Sets the remaining fields
		set_face_normal(&record, ray, &outward_normal)
		did_hit = true
		return

	case []Hittable:
		objects := hit_type
		closest_so_far := ray_tmax

		for &object in objects {

			temp_record, temp_hit := hit(&object, ray, ray_tmin, closest_so_far)

			if temp_hit {
				did_hit = true
				closest_so_far = temp_record.t
				record = temp_record
			}
		}

		return
	}

	unreachable()
}
// #endregion: Hittable methods

write_colors :: proc(fd: os.Handle, pixel_colors: []Color) {

	builder: strings.Builder
	for pixel_color in pixel_colors {
		output_r := int(255.99 * pixel_color.r)
		output_g := int(255.99 * pixel_color.g)
		output_b := int(255.99 * pixel_color.b)

		fmt.sbprintfln(&builder, "%d %d %d", output_r, output_g, output_b)
	}

	os.write_string(fd, strings.to_string(builder))
}

ray_color :: proc(ray: ^Ray, world: []Hittable) -> Color {

	world_hittable := Hittable(world)
	hit_record, did_hit := hit(&world_hittable, ray, 0.0, math.inf_f64(1))
	if did_hit {
		return 0.5 * (Color(hit_record.normal) + Color{1.0, 1.0, 1.0})
	}


	unit_direction := linalg.vector_normalize(ray.direction)
	t := 0.5 * (unit_direction.y + 1.0)
	return (1 - t) * Color{1.0, 1.0, 1.0} + t * Color{0.5, 0.7, 1.0}
}
