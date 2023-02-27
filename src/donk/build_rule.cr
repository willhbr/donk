module BuildRule
  getter name : String

  abstract def run
end

class RubyBlockBuildRule
  include BuildRule

  def initialize(@name : String, @block : Anyolite::RbRef)
  end

  def run
    Anyolite.call_rb_block(@block, nil)
  end
end

class BuildContext
  DONKROOT_FILE_NAME = "DonkConfig.rb"
  getter rules
  getter container_binary : String
  property name : String
  getter root_dir : Path

  def initialize
    @rules = Hash(String, BuildRule).new
    @container_binary = Process.find_executable("docker").not_nil!
    @name = File.basename(Dir.current)
    @root_dir = BuildContext.get_root(Dir.current)
  end

  def define_rule(rule : BuildRule)
    @rules[rule.name] = rule
  end

  @[Anyolite::Exclude]
  def full_name(name)
    "#{@name}/#{name}"
  end

  @[Anyolite::Exclude]
  def expand_path(path_str : String) : Path
    root = @root_dir
    if path_str.starts_with?("//")
      path_str = path_str[2..]
      return (root / path_str).relative_to(root)
    else
      return (Path[Dir.current] / path_str).relative_to(root)
    end
  end

  @[Anyolite::Exclude]
  def self.get_root(current) : Path
    c = Path[current]
    c.parents.reverse.each do |path|
      config = path / DONKROOT_FILE_NAME
      if File.exists? config
        return path
      end
    end
    return c
  end

  def donk_config_path : Path
    @root_dir / DONKROOT_FILE_NAME
  end
end
