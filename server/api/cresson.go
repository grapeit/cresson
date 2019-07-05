package main

import (
	"github.com/gin-gonic/gin"
)

func main() {
	// config must be initialized first
	initConfig()
	initDatabase()

	if config.debug {
		gin.SetMode(gin.DebugMode)
	} else {
		gin.SetMode(gin.ReleaseMode)
	}
	r := gin.Default()
	r.GET("/authorize", authorizeHandler)
	r.POST("/upload", uploadHandler)
	r.GET("/load", loadHandler)
	_ = r.Run(config.listen)
}
