# FROM alpine:latest as builder
# RUN apk add -u crystal shards libc-dev
# WORKDIR /src
# COPY . .
# RUN crystal build --release --static test.cr -o /src/test
# 
# FROM busybox
# WORKDIR /app
# COPY --from=builder /src/test /app/test
# ENTRYPOINT ["/app/test"]

def run_crystal(opts)
  name = opts[:name]
  main = opts[:main]
  # these images should have default tags
  imgdef = define_image("alpine:latest")
  imgdef.run %w(apk add -u crystal shards libc-dev)
  imgdef.workdir "/src"
  imgdef.copy ".", "."
  imgdef.entrypoint ["crystal", "run", main]
  define_rule(name) do
    build_image(imgdef, name)
    # this needs to be a temp container
    run_image(name)
  end
end

def crystal_image(opts)
  # todo add builder here
  name = opts[:name]
  entrypoint = opts[:entrypoint]
  imgdef = define_image("busybox")
  imgdef.workdir "/app"
  imgdef.copy ".", ".", from: "builder"
  imgdef.run ["crystal", "run", entrypoint]
  define_rule(name) do
    build_image(imgdef, name)
    # this needs to be a temp container
    run_image(name)
  end
end

run_crystal(
  name: "test",
  main: "test.cr",
)

# crystal_image(
#   name: "hello_world",
#   entrypoint: "./test.cr",
#   build_flags: %w(--release)
# )
