# Debugging CI failures

When a CI build fails, always start by identifying the failing step:
```
curl -s "http://ci.syncloud.org:8080/api/repos/syncloud/image/builds/{N}" | python3 -c "
import json,sys
b=json.load(sys.stdin)
for stage in b.get('stages',[]):
    for step in stage.get('steps',[]):
        if step.get('status') == 'failure':
            print(step.get('name'), '-', step.get('status'))
"
```

Then get the step log. The API path uses stage number and step number (both 1-indexed, matching the SPA URL `/syncloud/image/{build}/{stage}/{step}`). Logs are only available after the step finishes — a running step returns `{"message":"sql: no rows in result set"}`:
```
curl -s "http://ci.syncloud.org:8080/api/repos/syncloud/image/builds/{N}/logs/{stage}/{step}" | python3 -c "
import json,sys; [print(l.get('out',''), end='') for l in json.load(sys.stdin)]
" | tail -80
```

# CI

http://ci.syncloud.org:8080/syncloud/image

CI is Drone CI (JS SPA). Check builds via API:
```
curl -s "http://ci.syncloud.org:8080/api/repos/syncloud/image/builds?limit=5"
```

## CI Artifacts

Artifacts are served at `http://ci.syncloud.org:8081` (returns JSON directory listings).

Browse artifacts for a build:
```
curl -s "http://ci.syncloud.org:8081/files/image/"
```

# Project Structure

- **Image builder** for Syncloud single-board computer and amd64 images
- Builds bootable `.img.xz` files for 24 board/architecture combinations
- CI pipelines defined in `.drone.jsonnet`

## Key files

- `.drone.jsonnet` — Drone CI pipeline definitions (24 parallel board builds)
- `tools/extract.sh` / `tools/extract-amd64.sh` — Extract base OS images from GitHub releases
- `tools/boot.sh` / `tools/boot-amd64.sh` — Create boot partitions
- `tools/rootfs.sh` / `tools/rootfs-amd64.sh` — Install rootfs from GitHub releases
- `tools/zip.sh` — Compress images with xz
- `tools/functions.sh` — Shared utility functions
- `vbox.sh` / `create_vbox_image.sh` — VirtualBox image creation (amd64 only)
- `cleanup.sh` — Clean up loop devices after build

## Build pipeline steps (per board)

1. `extract` — Download and extract base image from syncloud/base-image GitHub releases
2. `boot` — Create bootable image with partition layout
3. `rootfs` — Install rootfs from syncloud/rootfs GitHub releases (mode=all only)
4. `virtualbox` — Create VirtualBox image (amd64 only)
5. `zip` — Compress image with xz
6. `publish to github` — Upload to GitHub release (tag events only)
7. `artifact` — Upload to artifact server via SCP
8. `cleanup` — Clean up loop devices

# Running Drone builds locally

Generate `.drone.yml` from jsonnet (run from project root):
```
drone jsonnet --stdout --stream > .drone.yml
```

# Bumping rootfs and tagging a new image

When upgrading the rootfs version in `.drone.jsonnet` (the `local rootfs = "X"` line), the commit/tag message should describe the *platform* changes that the new rootfs brings, since the platform snap is the user-visible delta. Image tags carry no annotation; the commit message at HEAD is what Drone surfaces and what becomes the GitHub release notes.

Use `tools/platform-diff` to generate that message:
```
./tools/platform-diff/build.sh
./tools/platform-diff/platform-diff
```
With no flags it compares the **latest image release** (resolves its pinned rootfs from `.drone.jsonnet@<image-tag>`, then reads platform revision from rootfs CI logs) against the **latest rootfs release**, and prints the platform commit list between them via the GitHub compare API.

Override either side: `--from-image <tag>` / `--to-rootfs <tag>`.

Workflow when bumping rootfs in image:
1. Edit `.drone.jsonnet`, bump `local rootfs = "<new-tag>"`. (`.drone.yml` regeneration is local-validation only — Drone reads `.drone.jsonnet` directly.)
2. Run `platform-diff` (defaults work — old image vs new rootfs).
3. Use the printed commit list as the body of the bump commit message.
4. Commit + tag (matching the new rootfs tag) + push together — see `feedback_push_retag.md` in memory.
