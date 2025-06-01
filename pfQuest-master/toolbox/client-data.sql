DROP TABLE IF EXISTS `WorldMapArea_vanilla`;
CREATE TABLE `WorldMapArea_vanilla` (
  `zoneID` smallint(3) unsigned NOT NULL,
  `mapID` smallint(3) unsigned NOT NULL,
  `areatableID` smallint(3) unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  `x_min` float NOT NULL DEFAULT 0.0,
  `x_max` float NOT NULL DEFAULT 0.0,
  `y_min` float NOT NULL DEFAULT 0.0,
  `y_max` float NOT NULL DEFAULT 0.0
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=FIXED COMMENT='WorldMapArea';

DROP TABLE IF EXISTS `WorldMapArea_turtle`;
CREATE TABLE `WorldMapArea_turtle` (
  `zoneID` smallint(3) unsigned NOT NULL,
  `mapID` smallint(3) unsigned NOT NULL,
  `areatableID` smallint(3) unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  `x_min` float NOT NULL DEFAULT 0.0,
  `x_max` float NOT NULL DEFAULT 0.0,
  `y_min` float NOT NULL DEFAULT 0.0,
  `y_max` float NOT NULL DEFAULT 0.0
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=FIXED COMMENT='WorldMapArea';

DROP TABLE IF EXISTS `WorldMapArea_tbc`;
CREATE TABLE `WorldMapArea_tbc` (
  `zoneID` smallint(3) unsigned NOT NULL,
  `mapID` smallint(3) unsigned NOT NULL,
  `areatableID` smallint(3) unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  `x_min` float NOT NULL DEFAULT 0.0,
  `x_max` float NOT NULL DEFAULT 0.0,
  `y_min` float NOT NULL DEFAULT 0.0,
  `y_max` float NOT NULL DEFAULT 0.0
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=FIXED COMMENT='WorldMapArea';

DROP TABLE IF EXISTS `WorldMapArea_wotlk`;
CREATE TABLE `WorldMapArea_wotlk` (
  `zoneID` smallint(3) unsigned NOT NULL,
  `mapID` smallint(3) unsigned NOT NULL,
  `areatableID` smallint(3) unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  `x_min` float NOT NULL DEFAULT 0.0,
  `x_max` float NOT NULL DEFAULT 0.0,
  `y_min` float NOT NULL DEFAULT 0.0,
  `y_max` float NOT NULL DEFAULT 0.0
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=FIXED COMMENT='WorldMapArea';

INSERT INTO `WorldMapArea_wotlk` VALUES (101, 1, 405, "Desolace", -262.5, 4233.333, -2545.833, 452.0833);
INSERT INTO `WorldMapArea_wotlk` VALUES (11, 1, 17, "Barrens", -7510.417, 2622.917, -5143.75, 1612.5);
INSERT INTO `WorldMapArea_wotlk` VALUES (121, 1, 357, "Feralas", -1508.333, 5441.667, -7000, -2366.667);
INSERT INTO `WorldMapArea_wotlk` VALUES (13, 1, 0, "Kalimdor", -19733.21, 17066.6, -11733.3, 12799.9);
INSERT INTO `WorldMapArea_wotlk` VALUES (14, 0, 0, "Azeroth", -22569.21, 18171.97, -15973.34, 11176.34);
INSERT INTO `WorldMapArea_wotlk` VALUES (141, 1, 15, "Dustwallow", -6225, -974.9999, -5533.333, -2033.333);
INSERT INTO `WorldMapArea_wotlk` VALUES (15, 0, 36, "Alterac", -2016.667, 783.3333, -366.6667, 1500);
INSERT INTO `WorldMapArea_wotlk` VALUES (16, 0, 45, "Arathi", -4466.667, -866.6666, -2533.333, -133.3333);
INSERT INTO `WorldMapArea_wotlk` VALUES (161, 1, 440, "Tanaris", -7118.75, -218.75, -10475, -5875);
INSERT INTO `WorldMapArea_wotlk` VALUES (17, 0, 3, "Badlands", -4566.667, -2079.167, -7547.917, -5889.583);
INSERT INTO `WorldMapArea_wotlk` VALUES (181, 1, 16, "Aszhara", -8347.916, -3277.083, 1960.417, 5341.667);
INSERT INTO `WorldMapArea_wotlk` VALUES (182, 1, 361, "Felwood", -4108.333, 1641.667, 3300, 7133.333);
INSERT INTO `WorldMapArea_wotlk` VALUES (19, 0, 4, "BlastedLands", -4591.667, -1241.667, -12800, -10566.67);
INSERT INTO `WorldMapArea_wotlk` VALUES (20, 0, 85, "Tirisfal", -1485.417, 3033.333, 824.9999, 3837.5);
INSERT INTO `WorldMapArea_wotlk` VALUES (201, 1, 490, "UngoroCrater", -3166.667, 533.3333, -8433.333, -5966.667);
INSERT INTO `WorldMapArea_wotlk` VALUES (21, 0, 130, "Silverpine", -750, 3450, -1133.333, 1666.667);
INSERT INTO `WorldMapArea_wotlk` VALUES (22, 0, 28, "WesternPlaguelands", -3883.333, 416.6667, 500, 3366.667);
INSERT INTO `WorldMapArea_wotlk` VALUES (23, 0, 139, "EasternPlaguelands", -6318.75, -2287.5, 1016.667, 3704.167);
INSERT INTO `WorldMapArea_wotlk` VALUES (24, 0, 267, "Hilsbrad", -2133.333, 1066.667, -1733.333, 400);
INSERT INTO `WorldMapArea_wotlk` VALUES (241, 1, 493, "Moonglade", -3689.583, -1381.25, 6952.083, 8491.666);
INSERT INTO `WorldMapArea_wotlk` VALUES (26, 0, 47, "Hinterlands", -5425, -1575, -1100, 1466.667);
INSERT INTO `WorldMapArea_wotlk` VALUES (261, 1, 1377, "Silithus", -945.834, 2537.5, -8281.25, -5958.334);
INSERT INTO `WorldMapArea_wotlk` VALUES (27, 0, 1, "DunMorogh", -3122.917, 1802.083, -7160.417, -3877.083);
INSERT INTO `WorldMapArea_wotlk` VALUES (28, 0, 51, "SearingGorge", -2554.167, -322.9167, -7587.5, -6100);
INSERT INTO `WorldMapArea_wotlk` VALUES (281, 1, 618, "Winterspring", -7416.667, -316.6667, 3800, 8533.333);
INSERT INTO `WorldMapArea_wotlk` VALUES (29, 0, 46, "BurningSteppes", -3195.833, -266.6667, -8983.333, -7031.25);
INSERT INTO `WorldMapArea_wotlk` VALUES (30, 0, 12, "Elwynn", -1935.417, 1535.417, -10254.17, -7939.583);
INSERT INTO `WorldMapArea_wotlk` VALUES (301, 0, 1519, "Stormwind", -14.58333, 1722.917, -9154.166, -7995.833);
INSERT INTO `WorldMapArea_wotlk` VALUES (32, 0, 41, "DeadwindPass", -3333.333, -833.3333, -11533.33, -9866.666);
INSERT INTO `WorldMapArea_wotlk` VALUES (321, 1, 1637, "Ogrimmar", -5083.206, -3680.601, 1338.461, 2273.877);
INSERT INTO `WorldMapArea_wotlk` VALUES (34, 0, 10, "Duskwood", -1866.667, 833.3333, -11516.67, -9716.666);
INSERT INTO `WorldMapArea_wotlk` VALUES (341, 0, 1537, "Ironforge", -1504.216, -713.5914, -5096.846, -4569.241);
INSERT INTO `WorldMapArea_wotlk` VALUES (35, 0, 38, "LochModan", -4752.083, -1993.75, -6327.083, -4487.5);
INSERT INTO `WorldMapArea_wotlk` VALUES (36, 0, 44, "Redridge", -3741.667, -1570.833, -10022.92, -8575);
INSERT INTO `WorldMapArea_wotlk` VALUES (362, 1, 1638, "ThunderBluff", -527.0833, 516.6666, -1545.833, -849.9999);
INSERT INTO `WorldMapArea_wotlk` VALUES (37, 0, 33, "Stranglethorn", -4160.417, 2220.833, -15422.92, -11168.75);
INSERT INTO `WorldMapArea_wotlk` VALUES (38, 0, 8, "SwampOfSorrows", -4516.667, -2222.917, -11150, -9620.833);
INSERT INTO `WorldMapArea_wotlk` VALUES (381, 1, 1657, "Darnassis", 1880.03, 2938.363, 9532.587, 10238.32);
INSERT INTO `WorldMapArea_wotlk` VALUES (382, 0, 1497, "Undercity", -86.1824, 873.1926, 1237.841, 1877.945);
INSERT INTO `WorldMapArea_wotlk` VALUES (39, 0, 40, "Westfall", -483.3333, 3016.667, -11733.33, -9400);
INSERT INTO `WorldMapArea_wotlk` VALUES (4, 1, 14, "Durotar", -7250, -1962.5, -1716.667, 1808.333);
INSERT INTO `WorldMapArea_wotlk` VALUES (40, 0, 11, "Wetlands", -4525, -389.5833, -4904.167, -2147.917);
INSERT INTO `WorldMapArea_wotlk` VALUES (401, 30, 2597, "AlteracValley", -2456.25, 1781.25, -1739.583, 1085.417);
INSERT INTO `WorldMapArea_wotlk` VALUES (41, 1, 141, "Teldrassil", -1277.083, 3814.583, 8437.5, 11831.25);
INSERT INTO `WorldMapArea_wotlk` VALUES (42, 1, 148, "Darkshore", -3608.333, 2941.667, 3966.667, 8333.333);
INSERT INTO `WorldMapArea_wotlk` VALUES (43, 1, 331, "Ashenvale", -4066.667, 1700, 829.1666, 4672.917);
INSERT INTO `WorldMapArea_wotlk` VALUES (443, 489, 3277, "WarsongGulch", 895.8333, 2041.667, 862.4999, 1627.083);
INSERT INTO `WorldMapArea_wotlk` VALUES (461, 529, 3358, "ArathiBasin", 102.0833, 1858.333, 337.5, 1508.333);
INSERT INTO `WorldMapArea_wotlk` VALUES (462, 530, 3430, "EversongWoods", -9412.5, -4487.5, 7758.333, 11041.67);
INSERT INTO `WorldMapArea_wotlk` VALUES (463, 530, 3433, "Ghostlands", -8583.333, -5283.333, 6066.667, 8266.666);
INSERT INTO `WorldMapArea_wotlk` VALUES (464, 530, 3524, "AzuremystIsle", -14570.83, -10500, -5508.333, -2793.75);
INSERT INTO `WorldMapArea_wotlk` VALUES (465, 530, 3483, "Hellfire", 375, 5539.583, -1962.5, 1481.25);
INSERT INTO `WorldMapArea_wotlk` VALUES (466, 530, 0, "Expansion01", -4468.039, 12996.04, -5821.359, 5821.359);
INSERT INTO `WorldMapArea_wotlk` VALUES (467, 530, 3521, "Zangarmarsh", 4447.917, 9475, -1416.667, 1935.417);
INSERT INTO `WorldMapArea_wotlk` VALUES (471, 530, 3557, "TheExodar", -12123.14, -11066.37, -4314.371, -3609.683);
INSERT INTO `WorldMapArea_wotlk` VALUES (473, 530, 3520, "ShadowmoonValley", -1275, 4225, -5614.583, -1947.917);
INSERT INTO `WorldMapArea_wotlk` VALUES (475, 530, 3522, "BladesEdgeMountains", 3420.833, 8845.833, 791.6666, 4408.333);
INSERT INTO `WorldMapArea_wotlk` VALUES (476, 530, 3525, "BloodmystIsle", -13337.5, -10075, -2933.333, -758.3333);
INSERT INTO `WorldMapArea_wotlk` VALUES (477, 530, 3518, "Nagrand", 4770.833, 10295.83, -3641.667, 41.66666);
INSERT INTO `WorldMapArea_wotlk` VALUES (478, 530, 3519, "TerokkarForest", 1683.333, 7083.333, -4600, -999.9999);
INSERT INTO `WorldMapArea_wotlk` VALUES (479, 530, 3523, "Netherstorm", -91.66666, 5483.333, 1739.583, 5456.25);
INSERT INTO `WorldMapArea_wotlk` VALUES (480, 530, 3487, "SilvermoonCity", -7612.208, -6400.75, 9346.938, 10153.71);
INSERT INTO `WorldMapArea_wotlk` VALUES (481, 530, 3703, "ShattrathCity", 4829.009, 6135.259, -2344.788, -1473.954);
INSERT INTO `WorldMapArea_wotlk` VALUES (482, 566, 3820, "NetherstormArena", 389.5833, 2660.417, 1404.167, 2918.75);
INSERT INTO `WorldMapArea_wotlk` VALUES (485, 571, 0, "Northrend", -8534.246, 9217.152, -1240.89, 10593.38);
INSERT INTO `WorldMapArea_wotlk` VALUES (486, 571, 3537, "BoreanTundra", 2806.25, 8570.833, 1054.167, 4897.917);
INSERT INTO `WorldMapArea_wotlk` VALUES (488, 571, 65, "Dragonblight", -1981.25, 3627.083, 1835.417, 5575);
INSERT INTO `WorldMapArea_wotlk` VALUES (490, 571, 394, "GrizzlyHills", -6360.417, -1110.417, 2016.667, 5516.667);
INSERT INTO `WorldMapArea_wotlk` VALUES (491, 571, 495, "HowlingFjord", -7443.75, -1397.917, -914.5833, 3116.667);
INSERT INTO `WorldMapArea_wotlk` VALUES (492, 571, 210, "IcecrownGlacier", -827.0833, 5443.75, 5245.833, 9427.083);
INSERT INTO `WorldMapArea_wotlk` VALUES (493, 571, 3711, "SholazarBasin", 2572.917, 6929.167, 4383.333, 7287.5);
INSERT INTO `WorldMapArea_wotlk` VALUES (495, 571, 67, "TheStormPeaks", -5270.833, 1841.667, 5456.25, 10197.92);
INSERT INTO `WorldMapArea_wotlk` VALUES (496, 571, 66, "ZulDrak", -5593.75, -600, 4339.583, 7668.75);
INSERT INTO `WorldMapArea_wotlk` VALUES (499, 530, 4080, "Sunwell", -8629.166, -5302.083, 11350, 13568.75);
INSERT INTO `WorldMapArea_wotlk` VALUES (501, 571, 4197, "LakeWintergrasp", 1354.167, 4329.167, 3733.333, 5716.667);
INSERT INTO `WorldMapArea_wotlk` VALUES (502, 609, 4298, "ScarletEnclave", -7210.417, -4047.917, 979.1666, 3087.5);
INSERT INTO `WorldMapArea_wotlk` VALUES (504, 571, 4395, "Dalaran", 0, 0, 0, 0);
INSERT INTO `WorldMapArea_wotlk` VALUES (510, 571, 2817, "CrystalsongForest", -1279.167, 1443.75, 4687.5, 6502.083);
INSERT INTO `WorldMapArea_wotlk` VALUES (512, 607, 4384, "StrandoftheAncients", -956.2499, 787.5, 720.8333, 1883.333);
INSERT INTO `WorldMapArea_wotlk` VALUES (520, 576, 4265, "TheNexus", 0, 0, 0, 0);
INSERT INTO `WorldMapArea_wotlk` VALUES (521, 595, 4100, "CoTStratholme", 327.0833, 2152.083, 1081.25, 2297.917);
INSERT INTO `WorldMapArea_wotlk` VALUES (522, 619, 4494, "Ahnkahet", -1206.25, -233.3333, 202.0833, 849.9999);
INSERT INTO `WorldMapArea_wotlk` VALUES (523, 574, 206, "UtgardeKeep", 0, 0, 0, 0);
INSERT INTO `WorldMapArea_wotlk` VALUES (524, 575, 1196, "UtgardePinnacle", -3275, 3275, -2200, 2166.667);
INSERT INTO `WorldMapArea_wotlk` VALUES (525, 602, 4272, "HallsofLightning", -899.9999, 2500, -66.66666, 2200);
INSERT INTO `WorldMapArea_wotlk` VALUES (526, 599, 4264, "Ulduar77", -633.3333, 2766.667, -66.66666, 2200);
INSERT INTO `WorldMapArea_wotlk` VALUES (527, 616, 4500, "TheEyeofEternity", -633.3333, 2766.667, -66.66666, 2200);
INSERT INTO `WorldMapArea_wotlk` VALUES (528, 578, 4228, "Nexus80", -262.5, 2337.5, 222.9167, 1956.25);
INSERT INTO `WorldMapArea_wotlk` VALUES (529, 603, 4273, "Ulduar", -1704.167, 1583.333, -1022.917, 1168.75);
INSERT INTO `WorldMapArea_wotlk` VALUES (530, 604, 4416, "Gundrak", 166.6667, 1310.417, 1360.417, 2122.917);
INSERT INTO `WorldMapArea_wotlk` VALUES (531, 615, 4493, "TheObsidianSanctum", -29.16667, 1133.333, 2841.667, 3616.667);
INSERT INTO `WorldMapArea_wotlk` VALUES (532, 624, 4603, "VaultofArchavon", -1566.667, 1033.333, -1133.333, 600);
INSERT INTO `WorldMapArea_wotlk` VALUES (533, 601, 4277, "AzjolNerub", -52.08333, 1020.833, 158.3333, 872.9166);
INSERT INTO `WorldMapArea_wotlk` VALUES (534, 600, 4196, "DrakTharonKeep", -1004.167, -377.0833, -587.5, -168.75);
INSERT INTO `WorldMapArea_wotlk` VALUES (535, 533, 3456, "Naxxramas", -4377.083, -2520.833, 2360.417, 3597.917);
INSERT INTO `WorldMapArea_wotlk` VALUES (536, 608, 4415, "VioletHold", 600, 983.3333, 1750, 2006.25);
INSERT INTO `WorldMapArea_wotlk` VALUES (540, 628, 4710, "IsleofConquest", -2125, 525, -58.33333, 1708.333);
INSERT INTO `WorldMapArea_wotlk` VALUES (541, 571, 4742, "HrothgarsLanding", -879.1666, 2797.917, 8329.166, 10781.25);
INSERT INTO `WorldMapArea_wotlk` VALUES (542, 650, 4723, "TheArgentColiseum", -500, 2100, 466.6667, 2200);
INSERT INTO `WorldMapArea_wotlk` VALUES (543, 649, 4722, "TheArgentColiseum", -500, 2100, 466.6667, 2200);
INSERT INTO `WorldMapArea_wotlk` VALUES (61, 1, 400, "ThousandNeedles", -4833.333, -433.3333, -6900, -3966.667);
INSERT INTO `WorldMapArea_wotlk` VALUES (81, 1, 406, "StonetalonMountains", -1637.5, 3245.833, -339.5833, 2916.667);
INSERT INTO `WorldMapArea_wotlk` VALUES (9, 1, 215, "Mulgore", -3089.583, 2047.917, -3697.917, -272.9167);
