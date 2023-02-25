require "crystal"

run_crystal(
  name: "test",
  main: "test.cr",
)

crystal_image(
  name: "hello_world",
  main: "test.cr",
  build_flags: %w(--release)
)
