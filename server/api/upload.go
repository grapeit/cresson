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
	"time"
)

var sqlInsertPrefix = ""

func init() {
	var sb strings.Builder
	sb.WriteString("INSERT INTO ")
	sb.WriteString(dataLogTable)
	sb.WriteString(" (")
	sb.WriteString(dataLogIdColumn)
	for i := 0; i < len(dataLogColumns); i++ {
		sb.WriteByte(',')
		sb.WriteString(dataLogColumns[i])
	}
	sb.WriteString(") VALUES ")
	sqlInsertPrefix = sb.String()
}

func uploadHandler(c *gin.Context) {
	bikeId, err := verifyBike(c)
	if err != nil {
		if config.debug {
			fmt.Println("Verification error: ", err.Error())
		}
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
				if config.debug {
					fmt.Println("Data read error: ", err.Error())
				}
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
		for i := 0; i < len(dataLogColumns); i++ {
			sqlStatement.WriteByte(',')
			sqlStatement.WriteString(strconv.FormatFloat(row[dataLogColumns[i]], 'f', -1, 64))
		}
		sqlStatement.WriteByte(')')
	}
	dbBegin := time.Now()
	res, err := database.Exec(sqlStatement.String())
	if err != nil {
		if isDuplicateError(err) {
			if config.debug {
				fmt.Println("Already there")
			}
		} else {
			if config.debug {
				fmt.Println("insert error: ", err.Error())
			}
			c.JSON(500, gin.H{
				"status": "failure",
				"error": "database error",
			})
			return
		}
	} else {
		rows, _ := res.RowsAffected()
		if config.debug {
			fmt.Println("Rows affected: ", rows, "in", time.Now().Sub(dbBegin))
		}
	}
	c.JSON(200, gin.H{
		"status": "ok",
	})
}
