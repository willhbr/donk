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

  @[Anyolite::WrapWithoutKeywords]
  @[Anyolite::StoreBlockArg]
  def self.build(name : String) : BuildRule
    unless block = Anyolite.obtain_given_rb_block
      raise "expected block given to build()"
    end
    rule = BuildRule.new(context, name, block)
    context.define_rule(rule)
    rule
  end

  @[Anyolite::WrapWithoutKeywords]
  @[Anyolite::StoreBlockArg]
  def self.run(name : String) : RunRule
    unless block = Anyolite.obtain_given_rb_block
      raise "expected block given to run()"
    end
    rule = RunRule.new(context, name, block)
    context.define_rule(rule)
    rule
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
