class ImageDef
  def initialize(@context : BuildContext, from : String, named : String?)
    @buffer = IO::Memory.new
    self.new_stage(from, named)
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
  def new_stage(image : String, named : String? = nil)
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

class RunImage
  @mounts = Array(Tuple(String, String)).new
  @ports = Array(Tuple(Int32, Int32)).new

  def initialize(@name : String)
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

  def run
    args = ["run"]

    @mounts.each do |mount|
      l, c = mount
      args << "--mount"
      args << "type=bind,source=#{l},target=#{c}"
    end

    @ports.each do |port|
      l, c = port
      args << "-p"
      args << "#{l}:#{c}"
    end

    args.concat(["-it", "--rm", @name])

    status = Process.run(
      Funcs.context.container_binary,
      args: args,
      input: Process::Redirect::Inherit,
      output: Process::Redirect::Inherit,
      error: Process::Redirect::Inherit,
    )
    raise "Process failed: #{status}" unless status.success?
  end
end
