PYTHON_DEFAULT_IMAGE = "python:alpine"

def _python_imgdef(opts)
  main = opts[:main]

  build_image = opts[:build_image] || PYTHON_DEFAULT_IMAGE
  imgdef = define_image(build_image)
  imgdef.workdir "/src"
  imgdef.copy ".", "."
  imgdef.entrypoint ["python", main]
  return imgdef
end

def python_runnable(**opts)
  name = opts[:name]

  imgdef = _python_imgdef(opts)

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

def python_image(**opts)
  name = opts[:name]

  imgdef = _python_imgdef(opts)

  define_rule(name) do
    build_image(imgdef, name)
  end
end

