mkdir -p build/
odin build src/ -show-timings -collection:src=src -out:build/raytracer -no-bounds-check -microarch:native -thread-count:4 -no-type-assert
