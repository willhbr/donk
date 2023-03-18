def _python_image(name, **opts)
  build(name) do |img|
    img.from 'python:alpine'
    if pkg = opts[:packages]
      img.run %w(apk add -u) + pkg
    end
    img.workdir "/src"
    img.copy "requirements.txt", "."
    img.run %w(pip install)
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

def python_image(**opts)
  _python_image(opts[:name], **opts) do |img|
    img.entrypoint ['python', opts[:main]]
  end
end
