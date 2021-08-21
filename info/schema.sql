-- DB: isucondition
-- table_name              engine  num_rows  avg_row_length  size_mb  data_mb  index_mb
-- isu_condition           InnoDB  72969     194             19.063   13.516   5.547
-- isu                     InnoDB  71        37152           2.531    2.516    0.016
-- isu_association_config  InnoDB  0         0               0.031    0.016    0.016
-- user                    InnoDB  13        1260            0.016    0.016    0.000


CREATE TABLE `isu` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `jia_isu_uuid` char(36) NOT NULL,
  `name` varchar(255) NOT NULL,
  `image` longblob DEFAULT NULL,
  `character` varchar(255) DEFAULT NULL,
  `jia_user_id` varchar(255) NOT NULL,
  `created_at` datetime(6) DEFAULT current_timestamp(6),
  `updated_at` datetime(6) DEFAULT current_timestamp(6) ON UPDATE current_timestamp(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `jia_isu_uuid` (`jia_isu_uuid`)
) ENGINE=InnoDB AUTO_INCREMENT=83 DEFAULT CHARSET=utf8mb4;



CREATE TABLE `isu_association_config` (
  `name` varchar(255) NOT NULL,
  `url` varchar(255) NOT NULL,
  PRIMARY KEY (`name`),
  UNIQUE KEY `url` (`url`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;



CREATE TABLE `isu_condition` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `jia_isu_uuid` char(36) NOT NULL,
  `timestamp` datetime NOT NULL,
  `is_sitting` tinyint(1) NOT NULL,
  `condition` varchar(255) NOT NULL,
  `message` varchar(255) NOT NULL,
  `created_at` datetime(6) DEFAULT current_timestamp(6),
  PRIMARY KEY (`id`),
  KEY `jia_isu_uuid_timestamp_idx` (`jia_isu_uuid`,`timestamp`)
) ENGINE=InnoDB AUTO_INCREMENT=72803 DEFAULT CHARSET=utf8mb4;



CREATE TABLE `user` (
  `jia_user_id` varchar(255) NOT NULL,
  `created_at` datetime(6) DEFAULT current_timestamp(6),
  PRIMARY KEY (`jia_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

