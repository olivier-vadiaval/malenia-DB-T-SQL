-- Author: Olivier Vadiavalooo

-- Database on Player Deaths to Malenia, Blade of Miquella
-- Source: https://www.kaggle.com/code/rogerwells/melania/data

SELECT *
FROM MaleniaDB..MaleniaDB


-- For each host build find the level with the highest number of deaths.
WITH deaths_per_build AS (
	SELECT Host_Build, [Level], COUNT(*) AS [No Of Deaths]
	FROM MaleniaDB..MaleniaDB
	GROUP BY Host_Build, [Level]
)
SELECT dpb1.Host_Build, dpb1.[Level] AS [Level With Most Deaths], dpb1.[No Of Deaths]
FROM deaths_per_build dpb1
WHERE dpb1.[No Of Deaths] = (
	SELECT MAX(dpb2.[No Of Deaths])
	FROM deaths_per_build dpb2
	WHERE dpb1.Host_Build = dpb2.Host_Build
)


-- Find the host build with the most minimum damage dealt
SELECT TOP(1) Host_Build AS [Host Build with Most Min Damage], Min_Damage AS [Min Damage]
FROM MaleniaDB..MaleniaDB
ORDER BY Min_Damage DESC


-- Find the level that the dealt the most minimum damage on average for each host build.
WITH avg_min_damage AS (
	SELECT Host_Build,
		   [Level],
		   AVG(Min_Damage) AS [Avg Min Damage]
	FROM MaleniaDB..MaleniaDB
	GROUP BY Host_Build, [Level]
),
most_avg_damage AS (
	SELECT Host_Build, 
		   MAX([Avg Min Damage]) AS [Max Avg Min Damage]
	FROM avg_min_damage
	GROUP BY Host_Build
)
SELECT amd.Host_Build AS [Host Build], 
	   amd.[Level], 
	   ROUND(mad.[Max Avg Min Damage], 3) AS [Max Avg Min Damage]
FROM avg_min_damage amd INNER JOIN
	 most_avg_damage mad ON
	 amd.Host_Build = mad.Host_Build
WHERE amd.[Avg Min Damage] = mad.[Max Avg Min Damage]


-- Find the most minimum damage dealt for each host build and phantom count
SELECT Host_Build AS [Host Build],
	   [1] AS [No Phantom],
	   [2] AS [One Phantom]
FROM (
	SELECT Host_Build, Min_Damage, Phantom_Count
	FROM MaleniaDB..MaleniaDB
) AS base
PIVOT (
	MAX(Min_Damage) FOR Phantom_Count IN ([1], [2])
) AS piv_table


-- For each host build, find the level with the most deaths, the location
-- that yielded the most deaths and if more than 50% of the players used 
-- a phantom
WITH host_level_deathcount AS (
	SELECT Host_Build, [Level], COUNT(*) AS [Death Count]
	FROM MaleniaDB..MaleniaDB
	GROUP BY Host_Build, [Level]
),
host_level_most_deaths AS (
	SELECT hld1.Host_Build, hld1.[Level], hld1.[Death Count]
	FROM host_level_deathcount hld1
	WHERE hld1.[Death Count] = (
		SELECT MAX([Death Count])
		FROM host_level_deathcount hld2
		WHERE hld1.Host_Build = hld2.Host_Build
	)
),
host_loc_deathcount AS (
	SELECT Host_Build, [Location], COUNT(*) AS [Death Count]
	FROM MaleniaDB..MaleniaDB
	GROUP BY Host_Build, [Location]
),
host_loc_most_deaths AS (
	SELECT hld1.Host_Build, hld1.[Location], hld1.[Death Count]
	FROM host_loc_deathcount hld1
	WHERE hld1.[Death Count] = (
		SELECT MAX([Death Count])
		FROM host_loc_deathcount hld2
		WHERE hld1.Host_Build = hld2.Host_Build
	)
),
host_deathcount AS (
	SELECT Host_Build, 
		   CAST(COUNT(*) AS FLOAT) AS Host_DeathCount
	FROM MaleniaDB..MaleniaDB
	GROUP BY Host_Build
),
host_phantuser_count AS (
	SELECT Host_Build,
		   CAST(COUNT(*) AS FLOAT) AS Phant_UserCount
	FROM MaleniaDB..MaleniaDB
	WHERE Phantom_Count = 2
	GROUP BY Host_Build
),
host_ifmajor_phant AS (
	SELECT hd.Host_Build,
		   CASE 
			WHEN (hpc.Phant_UserCount / hd.Host_DeathCount) > 0.5 THEN '>50% used a phantom'
				 ELSE '>50% did NOT use a phantom'
		   END AS [Mostly Used Phantom?]
	FROM host_phantuser_count hpc INNER JOIN
		 host_deathcount hd ON
		 hpc.Host_Build = hd.Host_Build
)
SELECT level_md.Host_Build AS [Host Build],
	   level_md.[Level] AS [Level(s) With Most Deaths],
	   loc_md.[Location] AS [Location(s) With Most Deaths],
	   maj_phant.[Mostly Used Phantom?]
FROM host_level_most_deaths level_md INNER JOIN
	 host_loc_most_deaths loc_md ON
	 level_md.Host_Build = loc_md.Host_Build INNER JOIN
	 host_ifmajor_phant maj_phant ON
	 maj_phant.Host_Build = level_md.Host_Build