def jekyll_dev(**opts)
  name = opts[:name]

  # Liquid doesn't work on 3.2 yet
  img = define_image("ruby:3.1.3-alpine3.17")
  img.workdir "/src"
  img.run %w(apk add --no-cache g++ musl-dev make libstdc++)
  img.copy "Gemfile*", "."
  img.run ["bundle", "install"]
  img.entrypoint %w(bundle exec jekyll serve --host=0 -w)

  port = opts[:port] || 4000
  run = run_image(name)
  run.bind_port port, 4000
  # Mount the files so we can do live editing
  run.mount ".", "/src"

  define_rule(name) do
    build_image(img, name)
    run.run
  end
end
