package main

import "strconv"

func toInt(v interface{}) int {
	switch v.(type) {
	case int:
		return v.(int)
	case float64:
		return int(v.(float64))
	case float32:
		return int(v.(float32))
	case int64:
		return int(v.(int64))
	case int32:
		return int(v.(int32))
	case uint64:
		return int(v.(uint64))
	case uint32:
		return int(v.(uint32))
	case uint:
		return int(v.(uint))
	case string:
		v, e := strconv.Atoi(v.(string))
		if e == nil {
			return v
		} else {
			return 0
		}
	}
	return 0
}
