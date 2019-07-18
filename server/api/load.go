package main

import (
	"github.com/gin-gonic/gin"
	"sort"
	"strings"
	"time"
)

const maxLoadPeriodSec = 60 * 60 * 24 * 7

func getCols(cols string) []string {
	var sc = strings.Split(cols, ",")
	if len(sc) > len(dataLogColumnsSorted) {
		return nil
	}
	for _, sv := range sc {
		i := sort.SearchStrings(dataLogColumnsSorted, sv)
		if i >= len(dataLogColumnsSorted) || dataLogColumnsSorted[i] != sv {
			return nil
		}
	}
	return sc
}

func loadHandler(c *gin.Context) {
	begin := time.Now()
	var requestedColumns = c.Query("cols")
	var dataColumns = getCols(requestedColumns)
	var fromTs = toInt(c.Query("from"))
	var toTs = toInt(c.Query("to"))

	if len(dataColumns) == 0 || toTs < fromTs || toTs - fromTs > maxLoadPeriodSec {
		logWarning("invalid request", "|",
			"columns:", dataColumns, "|",
			"requested columns:", requestedColumns, "|",
			"from:", fromTs, "|",
			"to:", toTs)
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
		logError("SELECT error:", err.Error())
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
			logError("row scan error:", err.Error())
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
	logDebug("load timing", "|",
		"prepare:", ready.Sub(begin).Seconds(), "|",
		"total:", time.Now().Sub(begin).Seconds())
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
