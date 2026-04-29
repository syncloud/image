package image

import (
	"fmt"
	"regexp"

	"github.com/syncloud/image/tools/platform-diff/internal/gh"
)

const repo = "syncloud/image"

var rootfsRe = regexp.MustCompile(`local\s+rootfs\s*=\s*"([^"]+)"`)

type Image struct {
	gh *gh.Client
}

func New(gh *gh.Client) *Image {
	return &Image{gh: gh}
}

func (i *Image) LatestTag() (string, error) {
	return i.gh.LatestReleaseTag(repo)
}

func (i *Image) RootfsTag(imageTag string) (string, error) {
	body, err := i.gh.RawFile(repo, imageTag, ".drone.jsonnet")
	if err != nil {
		return "", err
	}
	m := rootfsRe.FindStringSubmatch(body)
	if m == nil {
		return "", fmt.Errorf("rootfs not found in image@%s/.drone.jsonnet", imageTag)
	}
	return m[1], nil
}
