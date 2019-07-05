package main

import (
	"database/sql"
	"github.com/go-sql-driver/mysql"
)
import _ "github.com/go-sql-driver/mysql"

const (
	dataLogTable = "data_log"
	dataLogIdColumn = "bike"
)

var database *sql.DB

func initDatabase() {
	db, err := sql.Open(config.dbDriverName, config.dbConnectString)
	if err != nil {
		panic(err.Error())
	}
	database = db
}

func isDuplicateError(err error) bool {
	mysqlerr, ok := err.(*mysql.MySQLError)
	return ok && mysqlerr.Number == 1062
}
