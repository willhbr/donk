require "crystal"

crystal_runnable(
  name: "test",
  target: "donk",
)

crystal_image(
  name: "hello_world",
  target: "donk",
  build_flags: %w(--release),
)
