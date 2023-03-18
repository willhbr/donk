require "crystal"

crystal_runnable(
  name: "test",
  target: "donk",
  packages: %w(yaml-dev)
)

crystal_release(
  name: "hello_world",
  target: "donk",
  build_flags: %w(--release),
  includes: {
    "/deps/geode" => "//geode"
  }
)
