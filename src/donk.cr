require "anyolite"
require "option_parser"
require "geode"
require "json"

require "./donk/*"

def make_interpreter
  rb = Anyolite::RbInterpreter.new
  Anyolite.wrap(rb, Funcs)
  Anyolite.wrap(rb, RunRule)
  Anyolite.wrap(rb, BuildRule)
  Anyolite.wrap(rb, BuildContext)
  Anyolite.wrap(rb, Config)
  Funcs.setup
  rb.execute_script_line("include Funcs")
  rb.execute_script_line({{ read_file("src/builtin.rb").strip }})
  rb
end

Log.setup do |l|
  l.stderr
end

rb = make_interpreter
context = BuildContext.new
Funcs.context = context

config_path = context.donk_config_path

puts config_path
if File.exists? config_path
  rb.load_script_from_file(config_path.to_s)
end

if File.exists? "Donk.rb"
  rb.load_script_from_file("Donk.rb")
else
  puts "no Donk.rb file :("
end

parser = OptionParser.new do |parser|
  parser.banner = "Usage: #{PROGRAM_NAME} [args] [subcommand] [more args]"
  parser.on("-h", "--help", "Show this help") do
    puts parser
    puts context.config.to_yaml
    exit
  end

  parser.on("list", "list rules") do
    puts context.build_rules.keys.join('\n')
  end

  parser.on("build", "build a rule") do
    context.build_rules.values.each do |rule|
      parser.on(rule.name, "Build #{rule.name}") do
        Log.info { "Building #{rule.name}" }
        rule.build
      end
    end
  end
  parser.on("run", "run a rule") do
    context.run_rules.values.each do |rule|
      parser.on(rule.name, "Run #{rule.name}") do
        if build = context.build_rules[rule.name]
          Log.info { "Building #{rule.name}" }
          build.build
        end
        Log.info { "Running #{rule.name}" }
        rule.run
      end
    end
  end
end

parser.parse

rb.close
