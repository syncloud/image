local release = "20.01";

local build(board, arch, mode) = {
    local base_image = board + "-base.img",
    local image = "syncloud-" + board + "-" + release + ".img",

    kind: "pipeline",
    name: board,

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
// build("cubieboard2", "arm"),
// build("cubieboard", "arm"),
// build("beagleboneblack", "arm"),
// build("bananapim3", "arm"),
// build("rock64", "arm"),
// build("helios4", "arm"),
// build("raspberrypi3", "arm"),
// build("raspberrypi4", "arm"),
// build("raspberrypi2", "arm"),
build("odroid-xu3and4", "arm", "all"),
build("odroid-xu3and4", "arm", "boot"),
// build("odroid-c2", "arm"),
// build("odroid-u3", "arm"),
// build("bananapim2", "arm"),
// build("bananapim1", "arm"),
// build("cubietruck", "arm"),
// build("tinker", "arm"),
// build("odroid-n2", "arm"),
// build("amd64", "amd64"),
// build("lime2", "arm"),
]
