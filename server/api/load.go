package main

import (
	"fmt"
	"github.com/gin-gonic/gin"
	"time"
)

func loadHandler(c *gin.Context) {
	begin := time.Now()
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

	var timezoneOffsetSec = toInt(c.Query("tzos"))

	resultCols := []map[string]interface{}{
		{"label": "time", "type": "number"},
		{"label": "speed", "type": "number"},
		{"label": "battery", "type": "number"},
	}
	var resultRows []map[string]interface{}
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
		resultRows = append(resultRows, map[string]interface{}{
			"c": []map[string]interface{}{
				{"v": ts, "f": time.Unix(int64(ts), 0).Format(time.Kitchen)},
				{"v": speed},
				{"v": battery},
			},
		})
	}
	c.JSON(200, gin.H{
		"status": "success",
		"data": map[string]interface{}{
			"cols": resultCols,
			"rows": resultRows,
		},
		"series": map[int]map[string]int{
			0: {"targetAxisIndex": 0},
			1: {"targetAxisIndex": 1},
		},
		"vAxes": map[int]map[string]string{
			0: {"title": "speed"},
			1: {"title": "battery"},
		},
		"z" : map[string]interface{}{
			"timezoneOffsetSec": timezoneOffsetSec,
			"rowsCount": rowsCount,
		},
	})
	if config.debug {
		fmt.Println("loaded in ", time.Now().Sub(begin).Seconds())
	}
}
