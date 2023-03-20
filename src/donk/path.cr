struct DonkPath
  getter path : Path

  def initialize(dir : Path, name : String)
    @path = dir / name
  end

  def self.parse(root : Path, current : Path, path : String)
    if path.starts_with? "//"
      path = path[2..]
      p = (root / path).relative_to(root)
    else
      p = (current / path).relative_to(root)
    end

    new(p.parent, p.basename)
  end

  def name : String
    path.basename
  end

  def from_root(root : Path) : Path
    root / @path
  end

  def to_s(io)
    io << "//"
    @path.to_s(io)
  end
end
