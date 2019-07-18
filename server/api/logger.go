package main

import (
	"fmt"
	"time"
)

const (
	LL_DEBUG = iota    // logging for development purposes. will be ignored if debug mode is not set
	LL_WARNING = iota  // service is OK but something (like user input or resources availability) is not as expected
	LL_ERROR = iota    // something went wrong that affects service operation
)

func logDebug(message ...interface{}) {
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
	return fmt.Sprintf("[%d]", level)
}

func log(level int, message ...interface{}) {
	if level == LL_DEBUG && !config.debug {
		return
	}
	prefix := []interface{}{errorLevelString(level), time.Now().Format(time.RFC1123), "|"}
	fmt.Println(append(prefix, message...)...)
}
