CRYSTAL_BUILD_DEFAULT_IMAGE = "alpine:latest"
CRYSTAL_RUN_DEFAULT_IMAGE = "busybox"

def _crystal_build(opts)
  build_image = opts[:build_image] || CRYSTAL_BUILD_DEFAULT_IMAGE
  imgdef = define_image(build_image, named: "builder")
  imgdef.run %w(apk add -u crystal shards libc-dev)
  imgdef.workdir "/src"
  imgdef.copy ".", "."
  return imgdef
end

def run_crystal(**opts)
  name = opts[:name]
  main = opts[:main]

  imgdef = _crystal_build(opts)
  imgdef.entrypoint ["shards", "run", main]

  define_rule(name) do
    build_image(imgdef, name)
    run_image(name).run
  end
end

def crystal_image(**opts)
  name = opts[:name]
  main = opts[:main]

  run_image = opts[:run_image] || CRYSTAL_RUN_DEFAULT_IMAGE

  imgdef = _crystal_build(opts)
  imgdef.run ["shards", "build", main, "--static"]

  imgdef.new_stage(run_image)
  imgdef.workdir "/app"
  imgdef.copy "/src/bin/" + name, "/app/" + name, from: "builder"
  imgdef.entrypoint ["/app/" + name]

  define_rule(name) do
    build_image(imgdef, name)
    run_image(name).run
  end
end

