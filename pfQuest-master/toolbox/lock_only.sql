-- Load only essential DBC tables for pfQuest extractor

-- Lock table for gameobject relations
DROP TABLE IF EXISTS `Lock_wotlk`;
CREATE TABLE `Lock_wotlk` (
`id` smallint(3) unsigned NOT NULL,
`locktype` smallint(3) NOT NULL,
`data` smallint(3) unsigned NOT NULL,
`skill` smallint(3) unsigned NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=FIXED COMMENT='Lock';

INSERT INTO `Lock_wotlk` VALUES ("2", "2", "1", "25");
INSERT INTO `Lock_wotlk` VALUES ("4", "2", "1", "50");
INSERT INTO `Lock_wotlk` VALUES ("5", "0", "0", "0");
INSERT INTO `Lock_wotlk` VALUES ("8", "2", "2", "25");
INSERT INTO `Lock_wotlk` VALUES ("9", "2", "2", "50");
INSERT INTO `Lock_wotlk` VALUES ("10", "2", "2", "75");
INSERT INTO `Lock_wotlk` VALUES ("11", "2", "2", "100");
INSERT INTO `Lock_wotlk` VALUES ("12", "2", "4", "0");
INSERT INTO `Lock_wotlk` VALUES ("13", "2", "4", "25");
INSERT INTO `Lock_wotlk` VALUES ("14", "2", "4", "50");
INSERT INTO `Lock_wotlk` VALUES ("15", "2", "4", "75");
INSERT INTO `Lock_wotlk` VALUES ("16", "2", "4", "100");
INSERT INTO `Lock_wotlk` VALUES ("17", "2", "4", "125");
INSERT INTO `Lock_wotlk` VALUES ("18", "2", "4", "150");
INSERT INTO `Lock_wotlk` VALUES ("19", "2", "4", "175");
INSERT INTO `Lock_wotlk` VALUES ("20", "2", "4", "200");
INSERT INTO `Lock_wotlk` VALUES ("21", "2", "4", "225");
INSERT INTO `Lock_wotlk` VALUES ("22", "2", "4", "250");
INSERT INTO `Lock_wotlk` VALUES ("23", "2", "4", "275");
INSERT INTO `Lock_wotlk` VALUES ("24", "2", "4", "300");
INSERT INTO `Lock_wotlk` VALUES ("25", "2", "4", "325");
INSERT INTO `Lock_wotlk` VALUES ("26", "2", "4", "350");
INSERT INTO `Lock_wotlk` VALUES ("27", "2", "4", "375");
INSERT INTO `Lock_wotlk` VALUES ("28", "2", "4", "400");
INSERT INTO `Lock_wotlk` VALUES ("29", "2", "4", "425");
INSERT INTO `Lock_wotlk` VALUES ("30", "2", "4", "450");
INSERT INTO `Lock_wotlk` VALUES ("57", "2", "1", "0");
