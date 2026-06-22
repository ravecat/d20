version_settings(constraint = ">=0.22.2")

allow_k8s_contexts("k3d-d20")
docker_prune_settings(disable = True)

def modules():
    workspace = os.path.dirname(config.main_dir)
    current = os.path.realpath(config.main_path)
    marker = 'namespace = "d20"'

    found = str(local([
        "find",
        workspace,
        "-mindepth", "2",
        "-maxdepth", "2",
        "-name", "Tiltfile",
        "-type", "f",
        "-print",
    ], quiet = True))

    tiltfiles = []

    for path in found.splitlines():
        path = path.strip()

        if not path:
            continue

        path = os.path.realpath(path)

        if path == current:
            continue

        if marker not in str(read_file(path)):
            continue

        tiltfiles.append(path)

    return sorted(tiltfiles)

local_resource(
    "base-images",
    cmd = (
        "nix build .#toolchainImage --out-link /tmp/d20-toolchain-image"
        + " && /tmp/d20-toolchain-image | docker load"
        + " && nix build .#runtimeImage --out-link /tmp/d20-runtime-image"
        + " && /tmp/d20-runtime-image | docker load"
    ),
    deps = ["flake.nix", "flake.lock"],
)

docker_build(
    "d20/backend",
    ".",
    target = "development",
    live_update = [
        fall_back_on("Dockerfile"),
        fall_back_on("flake.nix"),
        fall_back_on("flake.lock"),
        fall_back_on("mix.exs"),
        fall_back_on("mix.lock"),
        fall_back_on("config/config.exs"),
        fall_back_on("config/dev.exs"),
        fall_back_on("config/prod.exs"),
        fall_back_on("config/runtime.exs"),
        fall_back_on("config/test.exs"),
        fall_back_on("assets/package.json"),
        fall_back_on("assets/bun.lock"),
        sync("assets", "/app/assets"),
        sync("lib", "/app/lib"),
        sync("priv", "/app/priv"),
        sync("rel", "/app/rel"),
    ],
)

k8s_yaml([
    "cluster/namespace.yaml",
    "cluster/postgres.yaml",
    "cluster/backend.yaml",
])

k8s_resource("postgres", labels = ["database"])
k8s_resource("backend", links = ["http://d20.localhost"], labels = ["backend"], resource_deps = ["base-images", "postgres"])

for tiltfile in modules():
    symbols = load_dynamic(tiltfile)

    if symbols.get("namespace", None) != "d20":
        continue

    register = symbols.get("register", None)

    if not register:
        fail("missing register() in " + tiltfile)

    register()
