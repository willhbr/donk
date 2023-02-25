require "utils"

NODE_DEFAULT_IMAGE = "node:18-alpine"

def _node_imgdef(opts)
  main = opts[:main]

  build_image = opts[:build_image] || NODE_DEFAULT_IMAGE
  imgdef = define_image(build_image)
  imgdef.workdir "/src"
  if File.exists? "package.json"
    imgdef.copy "package*.json", "."
    imgdef.run %w(npm install)
  end
  imgdef.copy ".", "."
  imgdef.entrypoint ["node", main]
  return imgdef
end

def node_runnable(**opts)
  name = opts[:name]

  imgdef = _node_imgdef(opts)

  runner = run_image(name)
  _add_ports_and_mounts(runner, opts)

  define_rule(name) do
    build_image(imgdef, name)
    runner.run
  end
end

def node_image(**opts)
  name = opts[:name]

  imgdef = _node_imgdef(opts)

  define_rule(name) do
    build_image(imgdef, name)
  end
end

