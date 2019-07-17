package main

import (
	"fmt"
	"time"
)

const (
	LL_DEBUG = iota    // everything is in order, just logging for development purposes
	LL_WARNING = iota  // service is OK but something (like user input or resources availability) is not as expected
	LL_ERROR = iota    // something went wrong that affects service operation
)

func logDebug(message ...interface{}) {
	if !config.debug {
		return
	}
	log(LL_DEBUG, message...)
}

func logWarning(message ...interface{}) {
	log(LL_WARNING, message...)
}

func logError(message ...interface{}) {
	log(LL_ERROR, message...)
}

func errorLevelString(level int) string {
	switch level {
	case LL_DEBUG:
		return "[DEBUG]"
	case LL_WARNING:
		return "[WARN]"
	case LL_ERROR:
		return "[ERROR]"
	}
	return "[???]"
}

func log(level int, message ...interface{}) {
	prefix := []interface{}{errorLevelString(level), time.Now().Format(time.RFC1123), "|"}
	fmt.Println(append(prefix, message...)...)
}
