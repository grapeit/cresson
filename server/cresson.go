package main

import (
	"bytes"
	"encoding/json"
	"github.com/gin-gonic/gin"
	"fmt"
)

func main() {
	gin.SetMode(gin.DebugMode)
	r := gin.Default()
	r.POST("/upload", UploadHandler)
	r.Run("0.0.0.0:2224")
}

func UploadHandler(c *gin.Context) {
	data, error := c.GetRawData()
	if error != nil {
		c.String(501, error.Error())
		return
	}
	fmt.Println(len(data))
	reader := bytes.NewBuffer(data)
	for {
		line, error := reader.ReadBytes('\n')
		if error != nil {
			c.String(501, error.Error())
			return
		}
		var j map[string]interface{}
		json.Unmarshal(line, &j)
		for k, v := range j {
			fmt.Println("k:", k, "v:", v)
		}
	}
	c.JSON(200, gin.H{
		"status": "implementing...",
	})
}
