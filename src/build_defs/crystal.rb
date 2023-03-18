def _crystal_binary(name, **opts)
  build(name) do |img|
    img.from 'alpine:latest'
    img.run %w(apk add -u crystal shards libc-dev)
    if pkg = opts[:packages]
      img.run %w(apk add -u) + pkg
    end
    img.workdir "/src"
    img.copy "shard.*", "."
    if shards = opts[:local_shards]
      shards.each do |path|
        img.copy path, '/deps/' + File.basename(path)
      end
    end
    img.copy '.', '.'
    yield img
  end

  run(name) do |runner|
    opts[:ports]&.each do |local, container|
      runner.bind_port local.to_i, container.to_i
    end
    opts[:ports]&.each do |local, container|
      runner.bind_port local.to_i, container.to_i
    end
  end
end

def crystal_runnable(**opts)
  _crystal_binary(opts[:name], **opts) do |img|
    img.entrypoint ['shards', 'run', opts[:target]]
  end
end

def crystal_release(**opts)
  _crystal_binary(opts[:name], **opts) do |img|
    img.run ['shards', 'build', opts[:target], '--static']

    img.from(run_image)
    img.workdir "/app"
    img.copy "/src/bin/" + target, "/app/" + target, from: '0'
    img.entrypoint ["/app/" + target]
  end
end

