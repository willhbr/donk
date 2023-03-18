struct DonkPath
  getter path : Path

  def initialize(dir : Path, name : String?)
    @path = dir
    @name = name
  end

  def self.parse(root : Path, path : String)
    if idx = path.rindex(':')
      dir = path[0...idx]
      name = path[(idx + 1)..-1]
    else
      dir = path.to_s
      name = nil
    end
    if dir.starts_with? "//"
      dir = dir[2..]
      p = (root / dir).relative_to(root)
    else
      p = (Path[Dir.current] / dir).relative_to(root)
    end

    return new(p, name)
  end

  def from_root(root : Path) : Path
    root / @path
  end

  def to_s(io)
    io << "//"
    @path.to_s(io)
    if name = @name
      io << ':' << name
    end
  end
end
