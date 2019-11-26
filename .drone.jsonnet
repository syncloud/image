local release = "19.12";

local build(board, arch) = {
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
        name: "merge",
        image: "syncloud/build-deps-amd64",
        commands: [
            "./tools/merge.sh " + board + " " + arch + " " + image
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
            password: {
                from_secret: "artifact_password"
            },
            command_timeout: "2m",
            target: "/home/artifact/repo/image",
            source: image + ".xz"
        }
    },
    {
        name : "cleanup",
        image: "syncloud/build-deps-amd64",
        commands: [
            "./cleanup.sh " + base_image,
            "./cleanup.sh " + image
        ],
        privileged: true,
        when: {
            status: [ "failure", "success" ]
        }
    }]
};

[
   build("beagleboneblack", "arm"),
 //build("bananapim3", "arm"),
    build("rock64", "arm"),
   build("helios4", "arm"),
    build("raspberrypi3", "arm"),
    build("raspberrypi4", "arm"),
   build("raspberrypi2", "arm"),
   build("odroid-xu3and4", "arm"),
   build("odroid-c2", "arm"),
   build("odroid-u3", "arm"),
    build("cubieboard2", "arm"),
    build("cubieboard", "arm"),
  build("bananapim2", "arm"),
    build("bananapim1", "arm"),
    build("cubietruck", "arm"),
    build("tinker", "arm"),
    build("odroid-n2", "arm"),
    build("amd64", "amd64"),
   build("lime2", "arm"),
]
