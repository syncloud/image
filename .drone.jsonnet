local build(board, arch) = {
    kind: "pipeline",
    name: board,

    platform: {
        os: "linux",
        arch: "amd64"
    },
    steps: [
    {
        name: "image",
        environment: {
            AWS_ACCESS_KEY_ID: {
                from_secret: "AWS_ACCESS_KEY_ID"
            },
            AWS_SECRET_ACCESS_KEY: {
                from_secret: "AWS_SECRET_ACCESS_KEY"
            },
            ARTIFACT_SSH_KEY: {
                from_secret: "ARTIFACT_SSH_KEY"
            }
        },
        image: "syncloud/build-deps-amd64",
        commands: [
            "RELEASE=19.10",
            "echo " + board + "-base.img > BASE_IMAGE",
            "echo syncloud-" + board + "-$RELEASE.img > IMAGE",
            "./extract-merge-upload.sh " + board + " " + arch + " $(cat BASE_IMAGE) $(cat IMAGE)"
        ],
        privileged: true
    },
    {
        name : "cleanup",
        image: "syncloud/build-deps-amd64",
        commands: [
            "./cleanup.sh $(cat BASE_IMAGE)",
            "./cleanup.sh $(cat IMAGE)"
        ],
        privileged: true,
        when: {
            status: [ "failure", "success" ]
        }
    }]
};

[
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
    build("bananapim3", "arm"),
    build("bananapim2", "arm"),
    build("beagleboneblack", "arm"),
    build("bananapim1", "arm"),
    build("cubietruck", "arm"),
    build("tinker", "arm"),
    build("odroid-n2", "arm"),
    build("amd64", "amd64"),
    build("lime2", "arm"),
]
