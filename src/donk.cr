require "anyolite"
require "option_parser"
require "geode"
require "json"

require "./donk/*"

module Colorize
  @[Anyolite::ExcludeInstanceMethod("colorize")]
  module ObjectExtensions
  end
end

def make_interpreter
  rb = Anyolite::RbInterpreter.new
  Anyolite.wrap(rb, Funcs)
  Anyolite.wrap(rb, ImageDef)
  Anyolite.wrap(rb, RunImage)
  rb.execute_script_line("include Funcs")
  rb
end

Log.setup do |l|
  l.stderr
end

rb = make_interpreter
context = BuildContext.new
Funcs.context = context

if File.exists? "Donk.rb"
  rb.load_script_from_file("Donk.rb")
else
  puts "no Donk.rb file :("
end

parser = OptionParser.new do |parser|
  parser.banner = "Usage: #{PROGRAM_NAME} [args] [subcommand] [more args]"
  parser.on("welcome", "Print a greeting message") do
    puts "sup"
  end
  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end

  context.rules.values.each do |rule|
    parser.on(rule.name, "Run task #{rule.name}") do
      Log.info { "Running #{rule.name}" }
      rule.run
    end
  end
end

parser.parse

rb.close
