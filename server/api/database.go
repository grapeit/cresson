package main

import (
	"database/sql"
	"github.com/go-sql-driver/mysql"
	"sort"
)
import _ "github.com/go-sql-driver/mysql"

const (
	dataLogTable = "data_log"
	dataLogIdColumn = "bike"
)

var dataLogColumnsSorted = []string {
	"ts",
	"k_gear", "k_throttle", "k_rpm", "k_speed", "k_coolant", "k_battery",
	"s_map",
	"l_latitude", "l_longitude", "l_altitude", "l_speed", "l_heading",
	"l_hor_accuracy", "l_vert_accuracy", "l_head_accuracy",
	"c_trip",
}

var database *sql.DB

func initDatabase() {
	sort.Strings(dataLogColumnsSorted)
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
