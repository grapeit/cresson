package main

import (
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

var requestHandlers = []func(*gin.Engine) {}

func addRequestHandler(f func(*gin.Engine)) {
	requestHandlers = append(requestHandlers, f)
}

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
	for _, i := range requestHandlers {
		i(r)
	}
	_ = r.Run(config.listen)
}
