local release = "20.01";

local build(board, arch, mode) = {
    local base_image = board + "-base.img",
    local image = "syncloud-" + board + "-" + release + ".img",

    kind: "pipeline",
    name: board + "-" + mode,

    platform: {
        os: "linux",
        arch: "amd64"
    },
    steps: [
    {
        name: "extract",
        image: "syncloud/build-deps-amd64",
        commands: [
            "./tools/extract.sh " + board + " " + base_image
        ],
        privileged: true
    },
    {
        name: "boot",
        image: "syncloud/build-deps-amd64",
        commands: [
            "./tools/boot.sh " + board  + " " + image
        ],
        privileged: true
    },
    if mode == "boot" then {} else
    {
        name: "rootfs",
        image: "syncloud/build-deps-amd64",
        commands: [
            "./tools/rootfs.sh " + board + " " + arch + " " + image + " " + release
        ],
        privileged: true
    },
    {
        name: "zip",
        image: "syncloud/build-deps-amd64",
        commands: [
            "./tools/zip.sh " + image + " " + mode
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
build("cubieboard2", "atm", "all"),
build("cubieboard", "atm", "all"),
build("beagleboneblack", "atm", "all"),
build("bananapim3", "atm", "all"),
build("rock64", "atm", "all"),
build("helios4", "atm", "all"),
build("raspberrypi3", "atm", "all"),
build("raspberrypi4", "atm", "all"),
build("raspberrypi2", "atm", "all"),
build("odroid-xu3and4", "atm", "all"),
build("odroid-xu3and4", "atm", "boot"),
build("odroid-c2", "atm", "all"),
build("odroid-u3", "atm", "all"),
build("bananapim2", "atm", "all"),
build("bananapim1", "atm", "all"),
build("cubietruck", "atm", "all"),
build("tinker", "atm", "all"),
build("odroid-n2", "atm", "all"),
build("amd64", "amd64", "all"),
build("lime2", "atm", "all"),
]
