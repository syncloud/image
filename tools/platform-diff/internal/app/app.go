package app

import (
	"fmt"
	"io"
	"strings"

	"github.com/syncloud/image/tools/platform-diff/internal/image"
	"github.com/syncloud/image/tools/platform-diff/internal/platform"
	"github.com/syncloud/image/tools/platform-diff/internal/rootfs"
)

type App struct {
	image    *image.Image
	rootfs   *rootfs.Rootfs
	platform *platform.Platform
	out      io.Writer
}

func New(img *image.Image, rfs *rootfs.Rootfs, plat *platform.Platform, out io.Writer) *App {
	return &App{image: img, rootfs: rfs, platform: plat, out: out}
}

func (a *App) Run(fromImage, toRootfs string) error {
	if fromImage == "" {
		t, err := a.image.LatestTag()
		if err != nil {
			return err
		}
		fromImage = t
	}
	if toRootfs == "" {
		t, err := a.rootfs.LatestTag()
		if err != nil {
			return err
		}
		toRootfs = t
	}

	fromRootfs, err := a.image.RootfsTag(fromImage)
	if err != nil {
		return err
	}

	fromRev, err := a.rootfs.PlatformRevision(fromRootfs)
	if err != nil {
		return err
	}
	toRev, err := a.rootfs.PlatformRevision(toRootfs)
	if err != nil {
		return err
	}

	fromSHA, err := a.platform.CommitForBuild(fromRev)
	if err != nil {
		return err
	}
	toSHA, err := a.platform.CommitForBuild(toRev)
	if err != nil {
		return err
	}

	fmt.Fprintf(a.out, "from image:   %s -> rootfs %s -> platform %d (%s)\n", fromImage, fromRootfs, fromRev, fromSHA[:8])
	fmt.Fprintf(a.out, "to rootfs:    %s -> platform %d (%s)\n\n", toRootfs, toRev, toSHA[:8])

	if fromSHA == toSHA {
		fmt.Fprintln(a.out, "no platform changes")
		return nil
	}

	commits, err := a.platform.Compare(fromSHA, toSHA)
	if err != nil {
		return err
	}
	fmt.Fprintf(a.out, "%d platform commits:\n", len(commits))
	for _, c := range commits {
		subj := strings.SplitN(c.Commit.Message, "\n", 2)[0]
		fmt.Fprintf(a.out, "  %s %s\n", c.SHA[:8], subj)
	}
	return nil
}
