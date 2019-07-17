package main

import (
	"fmt"
	"github.com/gin-gonic/gin"
	"sort"
	"strings"
	"time"
)

const maxLoadPeriodSec = 60 * 60 * 24 * 7

var sortedDataLogColumns []string

func getCols(cols string) []string {
	if len(sortedDataLogColumns) == 0 {
		sortedDataLogColumns = dataLogColumns
		sort.Strings(sortedDataLogColumns)
	}
	var sc = strings.Split(cols, ",")
	if len(sc) > len(sortedDataLogColumns) {
		return nil
	}
	for _, sv := range sc {
		i := sort.SearchStrings(sortedDataLogColumns, sv)
		if i >= len(sortedDataLogColumns) || sortedDataLogColumns[i] != sv {
			return nil
		}
	}
	return sc
}

func loadHandler(c *gin.Context) {
	begin := time.Now()
	var dataColumns = getCols(c.Query("cols"))
	var fromTs = toInt(c.Query("from"))
	var toTs = toInt(c.Query("to"))

	if len(dataColumns) == 0 || toTs < fromTs || toTs - fromTs > maxLoadPeriodSec {
		if config.debug {
			fmt.Println("cols: ", dataColumns, " (", c.Query("cols"), ") from: ", fromTs, " to: ", toTs)
		}
		c.JSON(500, gin.H{
			"status": "failure",
			"error": "bad request",
		})
		return
	}

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
	rows, err := database.Query(query.String(), fromTs, toTs)
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
	minRealTs := float64(toTs)
	maxRealTs := float64(fromTs)
	for rows.Next() {
		results := make([]float64, 1 + len(dataColumns))
		scanParam := make([]interface{}, 1 + len(dataColumns))
		for i, _ := range results {
			scanParam[i] = &results[i]
		}
		err := rows.Scan(scanParam...)
		if err != nil {
			fmt.Println("row error: ", err.Error())
			break
		}
		ts := results[0] - timezoneOffsetSec
		if minRealTs > ts {
			minRealTs = ts
		}
		if maxRealTs < ts {
			maxRealTs = ts
		}
		rr := []map[string]interface{}{ makeTimestampValue(ts) }
		for _, v := range results[1:] {
			rr = append(rr, map[string]interface{}{ "v": v })
		}
		resultRows = append(resultRows, map[string]interface{}{ "c": rr })
	}

	resultHAxisTicks := makeXAxisTicks(minRealTs, maxRealTs)

	ready := time.Now()
	c.JSON(200, gin.H{
		"status": "success",
		"data": map[string]interface{}{
			"cols": resultCols,
			"rows": resultRows,
		},
		"chart": map[string]interface{}{
			"series": resultSeries,
			"vAxis":  resultVAxis,
			"hAxis":  map[string]interface{}{
				"ticks": resultHAxisTicks,
			},
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

func makeXAxisTicks(from float64, to float64) []map[string]interface{} {
	if from > to {
		return nil
	}
	const ticks = 10.0
	var values = []map[string]interface{}{ makeTimestampValue(from) }
	scope := to - from
	step := scope / ticks
	start := from + step
	for ts := start; ts < to; ts += step {
		values = append(values, makeTimestampValue(ts))
	}
	return append(values, makeTimestampValue(to))
}

func makeTimestampValue(timestamp float64) map[string]interface{} {
	return map[string]interface{}{
		"v": timestamp,
		"f": time.Unix(int64(timestamp), 0).Format(time.Kitchen),
	}
}
