package main

import (
	"bufio"
	"compress/flate"
	"encoding/json"
	"fmt"
	"github.com/gin-gonic/gin"
	"io"
	"strconv"
	"strings"
)

var tableName = "cresson"
var dataColumns = []string {"ts", "gear", "throttle", "rpm", "speed", "coolant", "battery", "map", "trip", "odometer"}
var sqlInsertPrefix = ""

func main() {
	initSqlInsertPrefix()
	gin.SetMode(gin.DebugMode)
	r := gin.Default()
	r.POST("/upload", uploadHandler)
	_ = r.Run("0.0.0.0:2222")
}

func initSqlInsertPrefix() {
	var sb strings.Builder
	sb.WriteString("INSERT INTO ")
	sb.WriteString(tableName)
	sb.WriteString(" (")
	firstColumn := true
	for _, i := range dataColumns {
		if firstColumn {
			firstColumn = false
		} else {
			sb.WriteByte(',')
		}
		sb.WriteString(i)
	}
	sb.WriteString(") VALUES ")
	sqlInsertPrefix = sb.String()
}

func uploadHandler(c *gin.Context) {
	logReader := bufio.NewReader(flate.NewReader(c.Request.Body))
	var sqlStatement strings.Builder
	sqlStatement.WriteString(sqlInsertPrefix)
	firstRow := true
	for {
		line, err := logReader.ReadBytes('\n')
		if err != nil {
			if err == io.EOF {
				break
			} else {
				c.String(501, err.Error())
				return
			}
		}
		var row map[string]float64
		err = json.Unmarshal(line, &row)
		if err != nil {
			continue
		}
		if firstRow {
			firstRow = false
		} else {
			sqlStatement.WriteByte(',')
		}
		sqlStatement.WriteByte('(')
		firstColumn := true
		for _, i := range dataColumns {
			if firstColumn {
				firstColumn = false
			} else {
				sqlStatement.WriteByte(',')
			}
			sqlStatement.WriteString(strconv.FormatFloat(row[i], 'f', -1, 64))
		}
		sqlStatement.WriteByte(')')
	}
	sql := sqlStatement.String()
	fmt.Println(len(sql), sql)
	c.JSON(200, gin.H{
		"status": "implementing...",
	})
}
