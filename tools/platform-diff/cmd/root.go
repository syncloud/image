package cmd

import (
	"github.com/spf13/cobra"

	"github.com/syncloud/image/tools/platform-diff/internal/app"
)

func New(a *app.App) *cobra.Command {
	var fromImage, toRootfs string
	c := &cobra.Command{
		Use:   "platform-diff",
		Short: "Show platform commits between an image's rootfs and a target rootfs tag",
		RunE: func(cmd *cobra.Command, args []string) error {
			return a.Run(fromImage, toRootfs)
		},
	}
	c.Flags().StringVar(&fromImage, "from-image", "", "from image tag (default: latest image release)")
	c.Flags().StringVar(&toRootfs, "to-rootfs", "", "to rootfs tag (default: latest rootfs release)")
	return c
}
