package drone

import (
	"fmt"

	"github.com/syncloud/image/tools/platform-diff/internal/httpx"
)

type Step struct {
	Number int    `json:"number"`
	Name   string `json:"name"`
}

type Stage struct {
	Number int    `json:"number"`
	Name   string `json:"name"`
	Steps  []Step `json:"steps"`
}

type Build struct {
	Number int     `json:"number"`
	Status string  `json:"status"`
	Event  string  `json:"event"`
	Ref    string  `json:"ref"`
	After  string  `json:"after"`
	Stages []Stage `json:"stages"`
}

type LogLine struct {
	Out string `json:"out"`
}

type Client struct {
	http *httpx.Client
	base string
}

func New(http *httpx.Client, baseURL string) *Client {
	return &Client{http: http, base: baseURL}
}

func (c *Client) Build(repo string, n int) (Build, error) {
	var b Build
	err := c.http.JSON(fmt.Sprintf("%s/api/repos/%s/builds/%d", c.base, repo, n), &b)
	return b, err
}

func (c *Client) Builds(repo string, page, limit int) ([]Build, error) {
	var bs []Build
	err := c.http.JSON(fmt.Sprintf("%s/api/repos/%s/builds?page=%d&limit=%d", c.base, repo, page, limit), &bs)
	return bs, err
}

func (c *Client) Log(repo string, build, stage, step int) ([]LogLine, error) {
	var lines []LogLine
	err := c.http.JSON(fmt.Sprintf("%s/api/repos/%s/builds/%d/logs/%d/%d", c.base, repo, build, stage, step), &lines)
	return lines, err
}

func (c *Client) SuccessfulTagBuild(repo, tag string) (Build, error) {
	for page := 1; page <= 5; page++ {
		bs, err := c.Builds(repo, page, 100)
		if err != nil {
			return Build{}, err
		}
		if len(bs) == 0 {
			break
		}
		for _, b := range bs {
			if b.Event == "tag" && b.Ref == "refs/tags/"+tag && b.Status == "success" {
				return c.Build(repo, b.Number)
			}
		}
	}
	return Build{}, fmt.Errorf("no successful tag build for %s in %s", tag, repo)
}
