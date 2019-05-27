package main

import (
	"github.com/gin-gonic/gin"
)

func main() {
	// config must be initialized first
	initConfig()
	initUpload()

	if config.Debug {
		gin.SetMode(gin.DebugMode)
	} else {
		gin.SetMode(gin.ReleaseMode)
	}
	r := gin.Default()
	r.GET("/authorize", authorizeHandler)
	r.POST("/upload", uploadHandler)
	_ = r.Run(config.Listen)
}
