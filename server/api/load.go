package main

import (
	"fmt"
	"github.com/gin-gonic/gin"
	"strings"
	"time"
)

func loadHandler(c *gin.Context) {
	begin := time.Now()
	var dataColumns = [...]string {"speed", "battery"}
	const startTs = 1560574800
	const finishTs = 1560661200

	resultCols := []map[string]interface{}{
		{"label": "time", "type": "number"},
	}
	resultSeries := map[int]map[string]int{}
	resultVAxis := 	map[int]map[string]string{}

	var query strings.Builder
	query.WriteString("SELECT ts")
	for i, c := range dataColumns {
		query.WriteString(", ")
		query.WriteString(c)
		resultCols = append(resultCols, map[string]interface{}{
			"label": c, "type": "number",
		})
		resultSeries[i] = map[string]int { "targetAxisIndex": i }
		resultVAxis[i] = map[string]string{ "title": c }
	}
	query.WriteString(" FROM ")
	query.WriteString(dataLogTable)
	query.WriteString(" WHERE ts > ? AND ts < ?")
	rows, err := database.Query(query.String(), startTs, finishTs)
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

	timezoneOffsetSec := float64(toInt(c.Query("tzos")))

	var resultRows []map[string]interface{}
	for rows.Next() {
		vals := make([]interface{}, 1 + len(dataColumns))
		if rows.Scan(vals...) != nil {
			break
		}
		ts := vals[0].(float64)
		rr := []map[string]interface{}{
			{
				"v": ts - timezoneOffsetSec,
				"f": time.Unix(int64(ts), 0).Format(time.Kitchen),
			},
		}
		for i, v := range vals {
			if i == 0 {
				continue
			}
			rr = append(rr, map[string]interface{}{ "v": v })
		}
		resultRows = append(resultRows, map[string]interface{}{ "c": rr })
	}
	ready := time.Now()
	c.JSON(200, gin.H{
		"status": "success",
		"data": map[string]interface{}{
			"cols": resultCols,
			"rows": resultRows,
		},
		"chart": map[string]interface{}{
			"series": resultSeries,
			"vAxes":  resultVAxis,
		},
		"z" : map[string]interface{}{
			"timezoneOffsetSec": timezoneOffsetSec,
			"rowsCount": len(resultRows),
		},
	})
	if config.debug {
		fmt.Println("load timing: prepare = ", ready.Sub(begin).Seconds(), " done = ", time.Now().Sub(begin).Seconds())
	}
}
