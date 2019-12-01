CREATE DATABASE IF NOT EXISTS `cresson` CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `cresson`;


CREATE TABLE IF NOT EXISTS `users` (
  `id` INT AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `bikes` (
  `id` INT AUTO_INCREMENT,
  `user` INT NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `user_index` (`user`),
  FOREIGN KEY (`user`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `data_log` (
  `bike` INT NOT NULL,
  `ts` DOUBLE NOT NULL,
  `k_gear` DOUBLE,
  `k_throttle` DOUBLE,
  `k_rpm` DOUBLE,
  `k_speed` DOUBLE,
  `k_coolant` DOUBLE,
  `k_battery` DOUBLE,
  `k_map` DOUBLE,
  `l_latitude` DOUBLE,
  `l_longitude` DOUBLE,
  `l_altitude` DOUBLE,
  `l_speed` DOUBLE,
  `l_heading` DOUBLE,
  `c_trip` DOUBLE,
  PRIMARY KEY `pk` (`bike`,`ts`),
  INDEX `bike_index` (`bike`),
  FOREIGN KEY (`bike`) REFERENCES `bikes`(`id`) ON DELETE CASCADE,
  INDEX `ts_index` (`ts`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
