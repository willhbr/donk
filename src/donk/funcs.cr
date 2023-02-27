require "anyolite"

module Funcs
  @@context : BuildContext? = nil
  @@paths = Set(Path).new

  def self.config
    @@context.not_nil!.config
  end

  @[Anyolite::Exclude]
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
    return ImageDef.new context, from, named
  end

  @[Anyolite::WrapWithoutKeywords]
  def self.build_image(image : ImageDef, name : String)
    config = image.render_config
    dockerfile = IO::Memory.new(config)

    status = Process.run(
      @@context.not_nil!.container_binary,
      args: ["build", "-t", context.full_name(name), "-f", "-", context.root_dir.to_s],
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

  @[Anyolite::WrapWithoutKeywords(1)]
  @[Anyolite::StoreBlockArg]
  def self.define_rule(name : String, type : String? = nil)
    unless block = Anyolite.obtain_given_rb_block
      raise "expected block given to define_rule"
    end
    rule = BuildRule.new(type, name, block)
    @@context.not_nil!.define_rule(rule)
    nil
  end

  @[Anyolite::WrapWithoutKeywords]
  def self._require_internal(current_file : String, path_pattern : String)
    unless path_pattern.ends_with? ".rb"
      path_pattern += ".rb"
    end
    if require_from(Path[current_file].parent, path_pattern)
      return
    end
    @@context.not_nil!.config.library_paths.each do |library|
      if require_from(library, path_pattern)
        return
      end
    end
    raise "no paths matched in any library folder: #{path_pattern}"
  end

  # Returns true if the
  private def self.require_from(root : Path, pattern : String) : Bool
    expanded = Path[pattern].expand(base: root, home: true)
    globs = Dir.glob(expanded, expanded)
    if globs.empty?
      return false
    end
    globs.each do |p|
      path = Path[p]
      next if @@paths.includes? path
      Anyolite::RbRefTable.get_current_interpreter.load_script_from_file path.to_s
      @@paths << path
    end
    return true
  end
end
