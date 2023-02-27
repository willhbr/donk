require "yaml"

class BuildRule
  getter name : String
  getter type : String?

  def initialize(@type : String?, @name : String, @block : Anyolite::RbRef)
  end

  def run
    call_rb_block(@block, [] of Nil)
  end
end

class Config
  include YAML::Serializable

  @container_binary : String? = nil
  getter library_paths = Set(Path).new

  def initialize
  end

  @[Anyolite::WrapWithoutKeywords]
  def add_library(path : String)
    @library_paths << Path[path].expand(home: true)
    nil
  end

  def container_binary : String
    @container_binary ||= Process.find_executable("docker").not_nil!
  end

  def container_binary=(bin : String)
    if b = Process.find_executable(bin)
      @container_binary = b
    else
      raise "could not find #{bin}"
    end
  end
end

class BuildContext
  DONKROOT_FILE_NAME = "DonkConfig.rb"
  getter rules
  property name : String
  getter root_dir : Path

  getter config = Config.new

  def initialize
    @rules = Hash(String, BuildRule).new
    @name = File.basename(Dir.current)
    @root_dir = BuildContext.get_root(Dir.current)
  end

  def container_binary : String
    @config.container_binary
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
