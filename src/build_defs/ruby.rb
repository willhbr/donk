require "utils"

RUBY_DEFAULT_IMAGE = "ruby:alpine"

def _ruby_imgdef(opts)
  main = opts[:main]

  build_image = opts[:build_image] || RUBY_DEFAULT_IMAGE
  imgdef = define_image(build_image)
  imgdef.workdir "/src"
  if File.exists? "Gemfile"
    imgdef.copy "Gemfile*", "."
    imgdef.run %w(bundle install)
  end
  imgdef.copy ".", "."
  imgdef.entrypoint ["ruby", main]
  return imgdef
end

def ruby_runnable(**opts)
  name = opts[:name]

  define_rule(name, type: __method__.to_s) do
    imgdef = _ruby_imgdef(opts)

    runner = run_image(name)
    _add_ports_and_mounts(runner, opts)

    build_image(imgdef, name)
    runner.run
  end
end

def ruby_image(**opts)
  name = opts[:name]


  define_rule(name, type: __method__.to_s) do
    build_image(_ruby_imgdef(opts), name)
  end
end

