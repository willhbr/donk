require "anyolite"

module Funcs
  @@context : BuildContext? = nil
  @@paths = Set(Path).new

  def self.context
    @@context.not_nil!
  end

  @[Anyolite::Exclude]
  def self.context=(@@context : BuildContext)
  end

  @[Anyolite::WrapWithoutKeywords]
  def self.expand(path : String) : String
    context.expand_path(path).to_s
  end

  @[Anyolite::WrapWithoutKeywords(1)]
  def self.define_image(from : String, named : String? = nil) : ImageDef
    return ImageDef.new from, named
  end

  @[Anyolite::WrapWithoutKeywords]
  def self.build_image(image : ImageDef, name : String)
    config = image.render_config
    dockerfile = IO::Memory.new(config)

    status = Process.run(
      @@context.not_nil!.container_binary,
      args: ["build", "-t", context.full_name(name), "-f", "-", "."],
      input: dockerfile,
      output: Process::Redirect::Inherit,
      error: Process::Redirect::Inherit,
    )
    raise "Process failed: #{status}" unless status.success?
  end

  @[Anyolite::WrapWithoutKeywords]
  def self.run_image(name : String) : RunImage
    return RunImage.new(context.full_name(name))
  end

  @[Anyolite::WrapWithoutKeywords]
  @[Anyolite::StoreBlockArg]
  def self.define_rule(name : String)
    unless block = Anyolite.obtain_given_rb_block
      raise "expected block given to define_rule"
    end
    rule = RubyBlockBuildRule.new(name, block)
    @@context.not_nil!.define_rule(rule)
    nil
  end

  @[Anyolite::WrapWithoutKeywords]
  def self._require_internal(current : String, path_pattern : String) : Bool
    unless path_pattern.ends_with? ".rb"
      path_pattern += ".rb"
    end
    expanded = Path[path_pattern].expand(base: context.root_dir, home: true)
    current_path = Path[current].parent
    expanded_current = Path[path_pattern].parent.expand(base: current_path, home: true)
    one_file_matched = false
    globs = Dir.glob(expanded_current, expanded)
    if globs.empty?
      raise "No files matched: #{expanded}"
    end
    loaded = 0
    globs.each do |p|
      path = Path[p]
      next if @@paths.includes? path
      loaded += 1
      Anyolite::RbRefTable.get_current_interpreter.load_script_from_file path.to_s
      @@paths << path
    end
    return loaded > 0
  end
end
