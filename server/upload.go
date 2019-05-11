package main

import (
	"bufio"
	"compress/flate"
	"database/sql"
	"encoding/json"
	"fmt"
	"github.com/gin-gonic/gin"
	"github.com/go-sql-driver/mysql"
	"io"
	"strconv"
	"strings"
	"time"
)
import _ "github.com/go-sql-driver/mysql"

const (
	tableName = "data_log"
	idColumn = "user"
)
var database *sql.DB
var dataColumns = [...]string {"ts", "gear", "throttle", "rpm", "speed", "coolant", "battery", "map", "trip", "odometer"}
var sqlInsertPrefix = ""

func initUpload() {
	db, err := sql.Open(config.DbDriverName, config.DbConnectString)
	if err != nil {
		panic(err.Error())
	}
	database = db
	initSqlInsertPrefix()
}

func initSqlInsertPrefix() {
	var sb strings.Builder
	sb.WriteString("INSERT INTO ")
	sb.WriteString(tableName)
	sb.WriteString(" (")
	sb.WriteString(idColumn)
	for _, i := range dataColumns {
		sb.WriteByte(',')
		sb.WriteString(i)
	}
	sb.WriteString(") VALUES ")
	sqlInsertPrefix = sb.String()
}

func uploadHandler(c *gin.Context) {
	logReader := bufio.NewReader(flate.NewReader(c.Request.Body))
	var sqlStatement strings.Builder
	sqlStatement.WriteString(sqlInsertPrefix)
	userId := "0"
	firstRow := true
	for {
		line, err := logReader.ReadBytes('\n')
		if err != nil {
			if err == io.EOF {
				break
			} else {
				fmt.Println("Error: ", err.Error())
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
		sqlStatement.WriteString(userId)
		for _, i := range dataColumns {
			sqlStatement.WriteByte(',')
			sqlStatement.WriteString(strconv.FormatFloat(row[i], 'f', -1, 64))
		}
		sqlStatement.WriteByte(')')
	}
	dbBegin := time.Now()
	res, err := database.Exec(sqlStatement.String());
	if err != nil {
		if isDuplicate(err) {
			fmt.Println("Already there")
		} else {
			fmt.Println("Error: ", err.Error())
			c.String(501, err.Error())
			return
		}
	} else {
		rows, _ := res.RowsAffected()
		fmt.Println("Rows affected: ", rows, "in", time.Now().Sub(dbBegin));
	}
	c.JSON(200, gin.H{
		"status": "implementing...",
	})
}

func isDuplicate(err error) bool {
	mysqlerr, ok := err.(*mysql.MySQLError)
	return ok && mysqlerr.Number == 1062
}
