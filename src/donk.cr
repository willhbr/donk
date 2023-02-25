require "anyolite"
require "geode"
require "json"

module Colorize
  @[Anyolite::ExcludeInstanceMethod("colorize")]
  module ObjectExtensions
  end
end

class ImageDef
  def initialize(@from : String)
    @buffer = IO::Memory.new
  end

  @[Anyolite::WrapWithoutKeywords]
  def run(command : Array(String))
    @buffer << "RUN "
    command.to_json @buffer
    @buffer << '\n'
    nil
  end

  @[Anyolite::WrapWithoutKeywords]
  def entrypoint(command : Array(String))
    @buffer << "ENTRYPOINT "
    command.to_json @buffer
    @buffer << '\n'
    nil
  end

  @[Anyolite::WrapWithoutKeywords]
  def workdir(path : String)
    @buffer << "WORKDIR "
    path.to_json @buffer
    @buffer << '\n'
    nil
  end

  @[Anyolite::WrapWithoutKeywords]
  def copy(src : String, dest : String)
    @buffer << "COPY "
    @buffer << src
    @buffer << ' '
    @buffer << dest
    @buffer << '\n'
    nil
  end

  def render_config
    String::Builder.build do |io|
      io << "FROM " << @from << '\n'
      @buffer.to_s io
    end
  end

  def inspect(io)
    io << "FROM " << @from << '\n'
    @buffer.to_s io
    nil
  end
end

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

  def initialize
    @rules = Hash(String, BuildRule).new
    @container_binary = Process.find_executable("docker").not_nil!
  end

  def define_rule(rule : BuildRule)
    @rules[rule.name] = rule
  end
end

module Funcs
  @@context : BuildContext? = nil

  @[Anyolite::Exclude]
  def self.context=(@@context : BuildContext)
  end

  @[Anyolite::WrapWithoutKeywords]
  def self.define_image(from : String) : ImageDef
    return ImageDef.new from
  end

  @[Anyolite::WrapWithoutKeywords]
  def self.build_image(image : ImageDef, name : String)
    Log.info { "building image: #{name}" }
    # docker build -t "name" - < dockerfile
    config = image.render_config
    Log.info { "Config:\n#{config}" }
    dockerfile = IO::Memory.new(config)

    status = Process.run(
      @@context.not_nil!.container_binary,
      args: ["build", "-t", name, "-f", "-", "."],
      input: dockerfile,
      output: Process::Redirect::Inherit,
      error: Process::Redirect::Inherit,
    )
    raise "Process failed: #{status}" unless status.success?
    Log.info { "Image built: #{status}" }
  end

  @[Anyolite::WrapWithoutKeywords]
  def self.run_image(name : String)
    Log.info { "running image: #{name}" }

    status = Process.run(
      @@context.not_nil!.container_binary,
      args: ["run", "-it", "--rm", name],
      input: Process::Redirect::Inherit,
      output: Process::Redirect::Inherit,
      error: Process::Redirect::Inherit,
    )
    raise "Process failed: #{status}" unless status.success?
    Log.info { "Container finished: #{status}" }
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
end

Log.setup do |l|
  l.stderr
end

Anyolite::RbInterpreter.create do |rb|
  context = BuildContext.new
  Funcs.context = context
  Anyolite.wrap(rb, Funcs)
  Anyolite.wrap(rb, ImageDef)
  rb.execute_script_line("include Funcs")
  rb.load_script_from_file("Donk.rb")

  p context.rules

  rule = context.rules[ARGV[0]]
  rule.run
rescue err
  p err
end
