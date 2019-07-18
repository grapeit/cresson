package main

import (
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func main() {
	initConfig()   // config must be initialized first
	initDatabase()
	initUpload()   // initialize upload after database

	if config.debug {
		gin.SetMode(gin.DebugMode)
	} else {
		gin.SetMode(gin.ReleaseMode)
	}
	r := gin.Default()
	r.Use(cors.Default())
	r.GET("/authorize", authorizeHandler)
	r.POST("/upload", uploadHandler)
	r.GET("/load", loadHandler)
	_ = r.Run(config.listen)
}
