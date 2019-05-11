package main

import (
	"github.com/gin-gonic/gin"
)

func main() {
	gin.SetMode(gin.DebugMode)
	r := gin.Default()
	r.POST("/upload", uploadHandler)
	_ = r.Run("0.0.0.0:2222")
}
