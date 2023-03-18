def _node_image(name, **opts)
  build(name) do |img|
    img.from 'node:18-alpine'
    if pkg = opts[:packages]
      img.run %w(apk add -u) + pkg
    end
    img.workdir "/src"
    img.copy "package.json", "."
    img.run %w(npm install)
    img.copy '.', '.'
    yield img
  end

  run(name) do |runner|
    opts[:ports]&.each do |local, container|
      runner.bind_port local.to_i, container.to_i
    end
    opts[:mounts]&.each do |local, container|
      runner.mount local, container
    end
  end
end

def node_image(**opts)
  _node_image(opts[:name], **opts) do |img|
    img.entrypoint ['node', opts[:main]]
  end
end
