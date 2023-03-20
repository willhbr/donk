require "yaml"

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
  getter build_rules = Hash(DonkPath, BuildRule).new
  getter run_rules = Hash(DonkPath, RunRule).new
  getter root_dir : Path

  getter config = Config.new

  def initialize
    @dirs = Array(Path).new
    @dirs << Path[Dir.current]
    @root_dir = BuildContext.get_root(Dir.current)
  end

  @[Anyolite::Exclude]
  def current_dir : Path
    @dirs.last.not_nil!
  end

  def container_binary : String
    @config.container_binary
  end

  @[Anyolite::Exclude]
  def define_rule(rule : BuildRule)
    @build_rules[rule.path] = rule
  end

  @[Anyolite::Exclude]
  def define_rule(rule : RunRule)
    @run_rules[rule.path] = rule
  end

  def expand_path(path : String) : Path
    p = DonkPath.parse(@root_dir, Path[Dir.current], path)
    (@root_dir / p.path).relative_to(@root_dir)
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
