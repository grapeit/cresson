CREATE TABLE IF NOT EXISTS `data_log` (
  bike INT NOT NULL,
  ts DOUBLE NOT NULL,
  gear DOUBLE,
  throttle DOUBLE,
  rpm DOUBLE,
  speed DOUBLE,
  coolant DOUBLE,
  battery DOUBLE,
  map DOUBLE,
  trip DOUBLE,
  odometer DOUBLE,
  PRIMARY KEY `pk` (`bike`,`ts`)
) DEFAULT CHARSET=utf8;
