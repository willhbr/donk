def _ruby_image(name, **opts)
  build(name) do |img|
    img.from 'ruby:alpine'
    if pkg = opts[:packages]
      img.run %w(apk add -u) + pkg
    end
    img.workdir "/src"
    img.copy "Gemfile*", "."
    img.run ["bundle"]
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

def ruby_image(**opts)
  _ruby_image(opts[:name], **opts) do |img|
    img.entrypoint ['ruby', opts[:main]]
  end
end
