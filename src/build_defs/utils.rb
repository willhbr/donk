def _add_ports_and_mounts(runner, opts)
  if opts[:ports]
    opts[:ports].each do |local, container|
      runner.bind_port local.to_i, container.to_i
    end
  end
  if opts[:mounts]
    opts[:mounts].each do |local, container|
      runner.mount local, container
    end
  end
end
