-- DB: isuumo
-- table_name  engine  num_rows  avg_row_length  size_mb  data_mb  index_mb
-- estate      InnoDB  28645     531             14.516   14.516   0.000
-- chair       InnoDB  28668     494             13.516   13.516   0.000


CREATE TABLE `chair` (
  `id` int(11) NOT NULL,
  `name` varchar(64) NOT NULL,
  `description` varchar(4096) NOT NULL,
  `thumbnail` varchar(128) NOT NULL,
  `price` int(11) NOT NULL,
  `height` int(11) NOT NULL,
  `width` int(11) NOT NULL,
  `depth` int(11) NOT NULL,
  `color` varchar(64) NOT NULL,
  `features` varchar(64) NOT NULL,
  `kind` varchar(64) NOT NULL,
  `popularity` int(11) NOT NULL,
  `stock` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;



CREATE TABLE `estate` (
  `id` int(11) NOT NULL,
  `name` varchar(64) NOT NULL,
  `description` varchar(4096) NOT NULL,
  `thumbnail` varchar(128) NOT NULL,
  `address` varchar(128) NOT NULL,
  `latitude` double NOT NULL,
  `longitude` double NOT NULL,
  `rent` int(11) NOT NULL,
  `door_height` int(11) NOT NULL,
  `door_width` int(11) NOT NULL,
  `features` varchar(64) NOT NULL,
  `popularity` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

