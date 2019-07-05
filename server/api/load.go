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
	resultCols := []map[string]interface{}{
		{"label": "time", "type": "number"},
		{"label": "speed", "type": "number"},
		{"label": "battery", "type": "number"},
	}
	var resultRows [][]map[string]interface{}
	var rowsCount = 0
	for rows.Next() {
		var (
			ts float64
			speed float64
			battery float64
		)
		if rows.Scan(&ts, &speed, &battery) != nil {
			break
		}
		rowsCount += 1
		ts -= float64(timezoneOffsetSec)
		resultRows = append(resultRows, []map[string]interface{}{
			{"v": ts, "f": time.Unix(int64(ts), 0).Format(time.Kitchen)},
			{"v": speed},
			{"v": battery},
		})
	}
	c.JSON(200, gin.H{
		"status": "success",
		"cols": resultCols,
		"rows": resultRows,
		"z" : map[string]interface{}{
			"timeElapsedSec": time.Now().Sub(dbBegin).Seconds(),
			"timezoneOffsetSec": timezoneOffsetSec,
			"rowsCount": rowsCount,
		},
	})
}
