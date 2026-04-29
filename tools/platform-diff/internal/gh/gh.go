package gh

import (
	"fmt"

	"github.com/syncloud/image/tools/platform-diff/internal/httpx"
)

const (
	api = "https://api.github.com"
	raw = "https://raw.githubusercontent.com"
)

type Commit struct {
	SHA    string `json:"sha"`
	Commit struct {
		Message string `json:"message"`
	} `json:"commit"`
}

type compareResp struct {
	Commits []Commit `json:"commits"`
}

type release struct {
	TagName string `json:"tag_name"`
}

type Client struct {
	http *httpx.Client
}

func New(http *httpx.Client) *Client {
	return &Client{http: http}
}

func (c *Client) LatestReleaseTag(repo string) (string, error) {
	var r release
	if err := c.http.JSON(api+"/repos/"+repo+"/releases/latest", &r); err != nil {
		return "", err
	}
	return r.TagName, nil
}

func (c *Client) RawFile(repo, ref, path string) (string, error) {
	return c.http.Text(fmt.Sprintf("%s/%s/%s/%s", raw, repo, ref, path))
}

func (c *Client) Compare(repo, base, head string) ([]Commit, error) {
	var r compareResp
	url := fmt.Sprintf("%s/repos/%s/compare/%s...%s?per_page=250", api, repo, base, head)
	if err := c.http.JSON(url, &r); err != nil {
		return nil, err
	}
	return r.Commits, nil
}
