package main

import (
	"github.com/gin-gonic/gin"
)

func main() {
	// config must be initialized first
	initConfig()
	initUpload()
	gin.SetMode(gin.DebugMode)
	r := gin.Default()
	r.POST("/upload", uploadHandler)
	_ = r.Run(config.Listen)
}
