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
  getter rules
  getter container_binary : String
  property name : String

  def initialize
    @rules = Hash(String, BuildRule).new
    @container_binary = Process.find_executable("docker").not_nil!
    @name = File.basename(Dir.current)
  end

  def define_rule(rule : BuildRule)
    @rules[rule.name] = rule
  end

  @[Anyolite::Exclude]
  def full_name(name)
    "#{@name}/#{name}"
  end
end
