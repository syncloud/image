package main

import (
	"fmt"
	"os"

	"github.com/syncloud/image/tools/platform-diff/cmd"
	"github.com/syncloud/image/tools/platform-diff/internal/app"
	"github.com/syncloud/image/tools/platform-diff/internal/drone"
	"github.com/syncloud/image/tools/platform-diff/internal/gh"
	"github.com/syncloud/image/tools/platform-diff/internal/httpx"
	"github.com/syncloud/image/tools/platform-diff/internal/image"
	"github.com/syncloud/image/tools/platform-diff/internal/platform"
	"github.com/syncloud/image/tools/platform-diff/internal/rootfs"
)

const droneBaseURL = "http://ci.syncloud.org:8080"

func main() {
	http := httpx.New()
	ghc := gh.New(http)
	dronec := drone.New(http, droneBaseURL)

	img := image.New(ghc)
	rfs := rootfs.New(dronec, ghc)
	plat := platform.New(dronec, ghc)
	a := app.New(img, rfs, plat, os.Stdout)

	if err := cmd.New(a).Execute(); err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}
}
