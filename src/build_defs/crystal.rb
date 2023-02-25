CRYSTAL_BUILD_DEFAULT_IMAGE = "alpine:latest"
CRYSTAL_RUN_DEFAULT_IMAGE = "busybox"

def _crystal_build(opts)
  build_image = opts[:build_image] || CRYSTAL_BUILD_DEFAULT_IMAGE
  imgdef = define_image(build_image, named: "builder")
  imgdef.run %w(apk add -u crystal shards libc-dev)
  imgdef.workdir "/src"
  imgdef.copy "shard.*", "."
  imgdef.run %w(shards install)
  imgdef.copy ".", "."
  return imgdef
end

def crystal_runnable(**opts)
  name = opts[:name]
  target = opts[:target]

  imgdef = _crystal_build(opts)
  args = ["shards", "run", target]
  if opts[:build_flags]
    args += opts[:build_flags]
  end
  imgdef.entrypoint args

  runner = run_image(name)
  if opts[:ports]
    opts[:ports].each do |local, container|
      runner.bind_port local.to_i, container.to_i
    end
  end
  if opts[:mounts]
    opts[:mounts].each do |local, container|
      runner.mount local, container
    end
  end

  define_rule(name) do
    build_image(imgdef, name)
    runner.run
  end
end

def crystal_image(**opts)
  name = opts[:name]
  target = opts[:target]

  run_image = opts[:run_image] || CRYSTAL_RUN_DEFAULT_IMAGE

  imgdef = _crystal_build(opts)
  args = ["shards", "build", target, "--static"]
  if opts[:build_flags]
    args += opts[:build_flags]
  end
  imgdef.run args

  imgdef.new_stage(run_image)
  imgdef.workdir "/app"
  imgdef.copy "/src/bin/" + target, "/app/" + target, from: "builder"
  imgdef.entrypoint ["/app/" + target]

  define_rule(name) do
    build_image(imgdef, name)
  end
end

