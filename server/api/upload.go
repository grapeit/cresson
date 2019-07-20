package main

import (
	"bufio"
	"compress/flate"
	"encoding/json"
	"github.com/gin-gonic/gin"
	"io"
	"strconv"
	"strings"
	"time"
)

var sqlInsertPrefix = ""

func init() {
	addRequestHandler(func (e *gin.Engine) {
		e.POST("/upload", uploadHandler)
	})
}

func initUpload() {
	var sb strings.Builder
	sb.WriteString("INSERT INTO ")
	sb.WriteString(dataLogTable)
	sb.WriteString(" (")
	sb.WriteString(dataLogIdColumn)
	for _, i := range dataLogColumnsSorted {
		sb.WriteByte(',')
		sb.WriteString(i)
	}
	sb.WriteString(") VALUES ")
	sqlInsertPrefix = sb.String()
}

func uploadHandler(c *gin.Context) {
	bikeId, err := verifyBike(c)
	if err != nil {
		logWarning("verification error:", err.Error())
		c.JSON(403, gin.H{
			"status": "failure",
			"error": "unauthorized",
		})
		return
	}
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
				logWarning("data read error:", err.Error())
				c.JSON(500, gin.H{
					"status": "failure",
					"error": "bad data",
				})
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
		sqlStatement.WriteString(strconv.Itoa(bikeId))
		for _, i := range dataLogColumnsSorted {
			sqlStatement.WriteByte(',')
			sqlStatement.WriteString(strconv.FormatFloat(row[i], 'f', -1, 64))
		}
		sqlStatement.WriteByte(')')
	}
	dbBegin := time.Now()
	request := sqlStatement.String()
	res, err := database.Exec(request)
	if err != nil {
		if isDuplicateError(err) {
			logWarning("already there:", request)
		} else {
			logError("INSERT error:", err.Error())
			c.JSON(500, gin.H{
				"status": "failure",
				"error": "database error",
			})
			return
		}
	} else {
		rows, _ := res.RowsAffected()
		logDebug("rows affected:", rows, "in", time.Now().Sub(dbBegin))
	}
	c.JSON(200, gin.H{
		"status": "ok",
	})
}
