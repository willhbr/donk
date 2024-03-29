def jekyll_dev(**opts)
  build(opts[:name]) do |img|
    # Liquid doesn't work on 3.2 yet
    img.from("ruby:3.1.3-alpine3.17")
    img.workdir "/src"
    img.run %w(apk add --no-cache g++ musl-dev make libstdc++)
    img.copy "Gemfile*", "."
    img.run ["bundle", "install"]
    img.entrypoint %w(bundle exec jekyll serve --host=0 -w)
  end
  run(opts[:name]) do |runner|
    port = opts[:port] || 4000
    runner.bind_port port, 4000
    # Mount the files so we can do live editing
    runner.mount ".", "/src"
  end
end
