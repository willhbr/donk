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
        target = DonkPath.parse(context.root_dir, Path[Dir.current], args.target)
        donkfile = target.from_root(context.root_dir).parent / "Donk.rb"
        if File.exists? donkfile
          context.@dirs << donkfile.parent
          rb.load_script_from_file(donkfile.to_s)
        else
          raise "No Donk.rb file in #{donkfile.parent} for #{target}"
        end
        unless rule = context.build_rules[target]?
          raise "no such target: #{target}"
        end
        rule.build
        rb.close
      end
    end

    sub "run" do
      desc "run an image"
      usage "donk run <target> -- [arguments]"
      option "-r RUN_ONLY", "--run_only=RUN_ONLY", type: Bool, desc: "Run only, no build", default: false

      argument "target", type: String, desc: "run target", required: true
      run do |opts, args|
        rb, context = Donk.setup
        target = DonkPath.parse(context.root_dir, Path[Dir.current], args.target)
        donkfile = target.from_root(context.root_dir).parent / "Donk.rb"
        if File.exists? donkfile
          context.@dirs << donkfile.parent
          rb.load_script_from_file(donkfile.to_s)
        else
          raise "No Donk.rb file in #{donkfile.parent} for #{target}"
        end
        unless opts.run_only
          unless rule = context.build_rules[target]?
            raise "no such target: #{target}"
          end
          rule.build
        end
        unless rule = context.run_rules[target]?
          raise "no such target: #{target}"
        end
        rule.run
        rb.close
      end
    end

    sub "list" do
      desc "list targets"
      usage "donk list [arguments]"
      argument "target", type: String, desc: "list targets", default: "."
      run do |opts, args|
        rb, context = Donk.setup
        target = DonkPath.parse(context.root_dir, Path[Dir.current], args.target)
        donkfile = target.from_root(context.root_dir) / "Donk.rb"
        if File.exists? donkfile
          context.@dirs << donkfile.parent
          rb.load_script_from_file(donkfile.to_s)
        else
          raise "No Donk.rb file in #{donkfile.parent} for #{target}"
        end
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
