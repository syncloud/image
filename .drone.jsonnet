local release = "20.04";

local build(board, arch, mode, distro) = {
    local base_image = board + "-base.img",
    local suffix = if mode == "sd" then "-sd" else "",
    local size = if mode == "sd" then "10M" else "3G",
    local image = "syncloud-" + board  + suffix + "-" + distro + "-" + release + ".img",

    kind: "pipeline",
    name: board + "-" + mode + "-" + distro,

    platform: {
        os: "linux",
        arch: "amd64"
    },
    steps: [
    {
        name: "extract",
        image: "syncloud/build-deps-amd64",
        commands: [
            "./tools/extract.sh " + board + " " + base_image + " " + distro
        ],
        privileged: true
    },
    {
        name: "boot",
        image: "syncloud/build-deps-amd64",
        commands: [
            "./tools/boot.sh " + board  + " " + image + " " + size
        ],
        privileged: true
    },
    if mode == "all" then
    {
        name: "rootfs",
        image: "syncloud/build-deps-amd64",
        commands: [
            "./tools/rootfs.sh " + board + " " + arch + " " + image + " " + release + " " + distro
        ],
        privileged: true
    } else {},
    if board == "amd64" then
    {
        name: "virtualbox prepare",
        image: "appleboy/drone-scp",
        settings: {
            host: {
                from_secret: "virtualbox_host"
            },
            username: "root",
            key: {
                from_secret: "virtualbox_key"
            },
            command_timeout: "2m",
            target: "/data/drone-" + distro,
            source: [
                image,
                "create_vbox_image.sh"
            ]
        }
    },
    if board == "amd64" then
    {
        name: "virtualbox",
        image: "appleboy/drone-ssh",
        settings: {
            host: {
                from_secret: "virtualbox_host"
            },
            username: "root",
            port: 22,
            key: {
                from_secret: "virtualbox_key"
            },
            command_timeout: "20m",
            script_stop: true,
            script: [
                "cd /data/drone-" + distro,
                "./create_vbox_image.sh " + image
            ],
        },
        privileged: true
    } else {},
    {
        name: "zip",
        image: "syncloud/build-deps-amd64",
        commands: [
            "./tools/zip.sh " + image
        ],
        privileged: true
    },
    {
        name: "artifact",
        image: "appleboy/drone-scp",
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
            source: image + "*.xz"
        }
    },
    {
        name : "cleanup",
        image: "syncloud/build-deps-amd64",
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
//{ name: "cubieboard2", arch: "arm", type: "all"},
//build("cubieboard", "arm", "all"),
//build("beagleboneblack", "arm", "all"),
//build("bananapim3", "arm", "all"),
//build("rock64", "arm", "all"),
//build("helios4", "arm", "all"),
//build("raspberrypi3", "arm", "all"),
//build("raspberrypi4", "arm", "all"),
//build("raspberrypi2", "arm", "all"),
{name: "odroid-xu3and4", arch: "arm", type:  "all"},
{name: "odroid-xu3and4", arch: "arm", type: "sd"},
//build("odroid-c2", "arm", "all"),
//build("odroid-u3", "arm", "all"),
//build("bananapim2", "arm", "all"),
//build("bananapim1", "arm", "all"),
//build("cubietruck", "arm", "all"),
{name: "tinker", arch: "arm", type: "all"},
//build("odroid-n2", "arm", "all"),
//build("lime2", "arm", "all"),
{name: "amd64", arch: "amd64", type: "all"}
]
for distro in [
    "buster",
    "jessie"
    ]
]
