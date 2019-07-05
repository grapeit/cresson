package main

import (
	"fmt"
	"github.com/gin-gonic/gin"
	"time"
)

func loadHandler(c *gin.Context) {
	dbBegin := time.Now()
	const startTs = 1560574800
	const finishTs = 1560661200
	const query = "SELECT ts, speed, battery FROM " + dataLogTable + " WHERE ts > ? AND ts < ?"
	rows, err := database.Query(query, startTs, finishTs)
	if err != nil {
		if config.debug {
			fmt.Println("select error: ", err.Error())
		}
		c.JSON(500, gin.H{
			"status": "failure",
			"error": "database error",
		})
		return
	}
	var timezoneOffsetSec = c.GetInt("tzos")
	var resultRows []map[string]interface{}
	for rows.Next() {
		var (
			ts float64
			speed float64
			battery float64
		)
		if rows.Scan(&ts, &speed, &battery) != nil {
			break
		}
		ts -= float64(timezoneOffsetSec)
		resultRows = append(resultRows, map[string]interface{}{
			"ts": ts,
			"speed": speed,
			"battery": battery,
		})
	}
	c.JSON(200, gin.H{
		"status": "success",
		"rows": resultRows,
		"zp" : map[string]interface{}{
			"time_elapsed_secs": time.Now().Sub(dbBegin).Seconds(),
		},
	})
}
