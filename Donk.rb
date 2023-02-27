require "crystal"

crystal_runnable(
  name: "test",
  target: "donk",
  includes: {
    "/deps/geode" => "//geode"
  }
)

crystal_image(
  name: "hello_world",
  target: "donk",
  build_flags: %w(--release),
  includes: {
    "/deps/geode" => "//geode"
  }
)
