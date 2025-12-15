local release = "${DRONE_TAG:-latest}";

local build(board, arch, mode, distro) = {
    local base_image = board + "-base.img",
    local suffix = if mode == "sd" then "-sd" else "",
    local tool_suffix = if arch == "amd64" then "-amd64" else "",
    local size = if mode == "sd" then "10M" else "5G",
    local image_name = "syncloud-" + board  + suffix + "-" + release,
    local image = image_name + ".img",
    local rootfs = "25.02",
    kind: "pipeline",
    name: board + "-" + mode + "-" + distro,

    platform: {
        os: "linux",
        arch: "amd64"
    },
    steps: [
    {
        name: "extract",
        image: "debian:bookworm-slim",
        commands: [
            "./tools/extract"+tool_suffix+".sh " + board + " " + base_image
        ],
        privileged: true
    },
    {
        name: "boot",
        image: "debian:bookworm-slim",
        commands: [
            "./tools/boot"+tool_suffix+".sh " + board  + " " + image + " " + size
        ],
        privileged: true
    }] + 
    (if mode == "all" then
    [{
        name: "rootfs",
        image: "debian:bookworm-slim",
        commands: [
            "./tools/rootfs"+tool_suffix+".sh " + board + " " + arch + " " + image + " " + rootfs + " " + distro
        ],
        privileged: true
    }] else []) +
    (if board == "amd64" then
    [
    {
        name: "virtualbox",
        image: "debian:bookworm-slim",
        environment: {
            HOST: {
                from_secret: "virtualbox_host"
            },
            KEY: {
                from_secret: "virtualbox_key"
            },
        },
        commands: [
            "./vbox.sh " + image_name + " " + distro
        ],
    }] else []) + 
    [{
        name: "zip",
        image: "debian:bookworm-slim",
        commands: [
            "./tools/zip.sh " + image
        ],
        privileged: true
    },
   {
            name: "publish to github",
            image: "plugins/github-release:1.0.0",
            settings: {
                api_key: {
                    from_secret: "github_token"
                },
                files: image_name + "*.xz",
                overwrite: true,
                file_exists: "overwrite"
            },
            when: {
                event: [ "tag" ]
            }
        },
    {
        name: "artifact",
        image: "appleboy/drone-scp:1.6.4",
        settings: {
            host: {
                from_secret: "artifact_host"
            },
            username: "artifact",
            key: {
                from_secret: "artifact_key"
            },
            command_timeout: "2m",
            target: "/home/artifact/repo/image",
            source: image_name + "*.xz"
        }
    },
    {
        name : "cleanup",
        image: "debian:bookworm-slim",
        commands: [
            "./cleanup.sh"
        ],
        privileged: true,
        when: {
            status: [ "failure", "success" ]
        }
    }]
};

[
    build(board.name, board.arch, board.type, distro)
    for board in [
        { name: "amd64", arch: "amd64", type: "all"},
        { name: "cubieboard2", arch: "arm", type: "all" },
//        { name: "cubieboard", arch: "arm", type: "all" },
//        { name: "beagleboneblack", arch: "arm", type: "all" },
//        { name: "bananapim3", arch: "arm", type: "all" },
//        { name: "rock64", arch: "arm", type: "all" },
//        { name: "helios4", arch: "arm", type: "all" },
//        { name: "helios64", arch: "arm", type: "all" },
//        { name: "raspberrypi", arch: "arm", type: "all" },
//        { name: "raspberrypi-64", arch: "arm64", type: "all" },
//        { name: "raspberrypi2", arch: "arm", type: "all" },
//        { name: "odroid-xu3and4", arch: "arm", type: "all" },
//        { name: "odroid-xu3and4", arch: "arm", type: "sd" },
//        { name: "jetson-nano", arch: "arm64", type: "all" },
//        { name: "odroid-c2", arch: "arm", type: "all" },
//        { name: "odroid-u3", arch: "arm", type: "all" },
//        { name: "bananapim2", arch: "arm", type: "all" },
//        { name: "bananapim1", arch: "arm", type: "all" },
//        { name: "cubietruck", arch: "arm", type: "all" },
//        { name: "tinker", arch: "arm", type: "all" },
//        { name: "odroid-n2", arch: "arm", type: "all" },
//        { name: "lime2", arch: "arm", type: "all" },
//        { name: "btt-cb1", arch: "arm64", type: "all" },
//        { name: "odroid-hc4", arch: "arm64", type: "all"},
    ]
    for distro in [
        "bookworm"
    ]
]
