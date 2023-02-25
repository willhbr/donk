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
  def self.require(path : String) : Bool
    donk_path = ENV["DONK_PATH"]? || Path["~/.donk/src/build_defs"].expand(home: true).to_s
    dirs = [Dir.current] + donk_path.split(':')
    unless path.ends_with? ".rb"
      path += ".rb"
    end
    dirs.each do |dir|
      p = Path[path].expand(base: dir)
      if File.exists? p
        return false if @@paths.includes? p
        Anyolite::RbRefTable.get_current_interpreter.load_script_from_file p.to_s
        @@paths << p
        return true
      end
    end
    raise "unable to find #{path} in any of #{dirs}"
  end
end
