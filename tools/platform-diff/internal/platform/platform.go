package platform

import (
	"fmt"

	"github.com/syncloud/image/tools/platform-diff/internal/drone"
	"github.com/syncloud/image/tools/platform-diff/internal/gh"
)

const repo = "syncloud/platform"

type Platform struct {
	drone *drone.Client
	gh    *gh.Client
}

func New(d *drone.Client, g *gh.Client) *Platform {
	return &Platform{drone: d, gh: g}
}

func (p *Platform) CommitForBuild(n int) (string, error) {
	b, err := p.drone.Build(repo, n)
	if err != nil {
		return "", err
	}
	if b.After == "" {
		return "", fmt.Errorf("platform build %d has no commit SHA", n)
	}
	return b.After, nil
}

func (p *Platform) Compare(base, head string) ([]gh.Commit, error) {
	return p.gh.Compare(repo, base, head)
}
