class BuildRule
  class Config
    def initialize(@context : BuildContext)
      @buffer = IO::Memory.new
    end

    @[Anyolite::WrapWithoutKeywords]
    def run(command : Array(String))
      cmd("RUN", command.to_json)
      nil
    end

    @[Anyolite::WrapWithoutKeywords]
    def entrypoint(command : Array(String))
      cmd("ENTRYPOINT", command.to_json)
      nil
    end

    @[Anyolite::WrapWithoutKeywords]
    def workdir(path : String)
      cmd("WORKDIR", path.to_json)
      nil
    end

    @[Anyolite::WrapWithoutKeywords(2)]
    def copy(src : String, dest : String, from : String? = nil)
      cmd("COPY",
        from.nil? ? nil : "--from=#{from}", @context.expand_path(src).to_s, dest)
      nil
    end

    @[Anyolite::WrapWithoutKeywords(1)]
    def from(image : String, named : String? = nil)
      cmd("FROM", image, named.nil? ? nil : " as #{named}")
      nil
    end

    def render_config
      @buffer.to_s
    end

    def inspect(io)
      @buffer.to_s io
      nil
    end

    @[Anyolite::Exclude]
    def cmd(name, *args)
      @buffer << name << ' '
      args.each do |arg|
        @buffer << arg << ' ' unless arg.nil?
      end
      @buffer << '\n'
    end
  end

  getter path : DonkPath

  def initialize(@context : BuildContext, @path, @block : Anyolite::RbRef)
  end

  def build
    conf = Config.new(@context)
    call_rb_block(@block, [conf])
    dockerfile = IO::Memory.new(conf.render_config)

    status = Process.run(
      @context.container_binary,
      args: ["build", "-t", @path.no_prefix,
             "-f", "-", @context.root_dir.to_s],
      input: dockerfile,
      output: Process::Redirect::Inherit,
      error: Process::Redirect::Inherit,
    )
    raise "Process failed: #{status}" unless status.success?
  end
end

class RunRule
  class Config
    getter mounts = Array(Tuple(String, String)).new
    getter ports = Array(Tuple(Int32, Int32)).new

    def initialize(@context : BuildContext)
    end

    @[Anyolite::WrapWithoutKeywords]
    def mount(local : String, container : String)
      local = Path[local].expand.to_s
      @mounts << {local, container}
      nil
    end

    @[Anyolite::WrapWithoutKeywords]
    def bind_port(local : Int32, container : Int32)
      @ports << {local, container}
      nil
    end
  end

  getter path : DonkPath

  def initialize(@context : BuildContext, @path, @block : Anyolite::RbRef)
  end

  def args : Array(String)
    conf = Config.new(@context)
    call_rb_block(@block, [conf])

    args = ["run"]

    conf.mounts.each do |mount|
      l, c = mount
      args << "--mount"
      args << "type=bind,source=#{l},target=#{c}"
    end

    conf.ports.each do |port|
      l, c = port
      args << "-p"
      args << "#{l}:#{c}"
    end

    args.concat(["-it", "--rm", @path.no_prefix])
    args
  end

  def run
    status = Process.run(
      @context.container_binary,
      args: self.args,
      input: Process::Redirect::Inherit,
      output: Process::Redirect::Inherit,
      error: Process::Redirect::Inherit,
    )
    raise "Process failed: #{status}" unless status.success?
  end
end
