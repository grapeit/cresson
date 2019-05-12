package main

import (
	"github.com/gin-gonic/gin"
)

func main() {
	// config must be initialized first
	initConfig()
	initUpload()

	var ginMode string
	if config.Debug {
		ginMode = gin.DebugMode
	} else {
		ginMode = gin.ReleaseMode
	}
	gin.SetMode(ginMode)
	r := gin.Default()
	r.POST("/upload", uploadHandler)
	_ = r.Run(config.Listen)
}
