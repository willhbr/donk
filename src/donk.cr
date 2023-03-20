require "anyolite"
require "geode"
require "json"

require "./donk/*"
require "clim"

module Donk
  def self.make_interpreter
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

  def self.setup : Tuple(Anyolite::RbInterpreter, BuildContext)
    rb = Donk.make_interpreter
    context = BuildContext.new
    Funcs.context = context
    config_path = context.donk_config_path

    if File.exists? config_path
      rb.load_script_from_file(config_path.to_s)
    end

    if File.exists? "Donk.rb"
      rb.load_script_from_file("Donk.rb")
    else
      Log.info { "no Donk.rb file :(" }
    end
    return {rb, context}
  end
end

class Donk::CLI < Clim
  main do
    desc "DONK"
    usage "donk [options] [arguments] ..."
    version "Version 0.0.1"
    run do |opts, args|
      _, context = Donk.setup
      puts context.config.to_yaml
    end

    sub "build" do
      desc "build an image"
      usage "donk build <target> -- [arguments]"
      argument "target", type: String, desc: "build target", required: true
      run do |opts, args|
        rb, context = Donk.setup
        # target = DonkPath.parse(args.target)
        # context.build_rules[target]
        rb.close
      end
    end

    sub "list" do
      desc "list targets"
      usage "donk list [arguments]"
      run do |opts, args|
        rb, context = Donk.setup
        puts context.build_rules.keys.join('\n')
        rb.close
      end
    end
  end
end

Log.setup do |l|
  l.stderr
end

Donk::CLI.start ARGV
