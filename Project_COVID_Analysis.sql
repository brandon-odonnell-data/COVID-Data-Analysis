/* 
PROJECT: COVID-19 Data Exploration and Analysis in SQL

FEATURED SKILLS: Aggregate Functions, Converting Data Types, Joins, CTEs, Temp Tables, Windows Functions, Creating Views
*/

--Exploratory queries for covid_deaths table
SELECT *
FROM Project_COVID_Analysis..covid_deaths
ORDER BY location, date;

--Exploratory queries for covid_vaccinations table
SELECT *
FROM Project_COVID_Analysis..covid_vaccinations
ORDER BY location, date;


--ANALYSES AT COUNTRY LEVEL

SELECT
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM Project_COVID_Analysis..covid_deaths
WHERE continent IS NOT NULL
ORDER BY location, date;

--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract COVID in country selected
SELECT
	location,
	date,
	total_cases,
	total_deaths,
	ROUND((total_deaths/total_cases) * 100,2) AS death_percent_cases
FROM Project_COVID_Analysis..covid_deaths
WHERE location = 'United Kingdom' AND continent IS NOT NULL
ORDER BY location, date;

--Looking at Total Cases vs Population
--Shows percentage of population that contracted COVID in country selected
SELECT
	location,
	date,
	population,
	total_cases,
	total_deaths,
	ROUND((total_cases/population) * 100,5) AS cases_percent_population
FROM Project_COVID_Analysis..covid_deaths
WHERE location = 'United Kingdom' AND continent IS NOT NULL
ORDER BY location, date;

--Looking at Countries with Highest Infection Rate compared to Population
--Shows maximum percentage of population that contracted COVID in country selected
SELECT
	location,
	population,
	MAX(total_cases) AS highest_infection_count,
	ROUND(MAX((total_cases/population)) * 100, 2) AS percent_population_infected
FROM Project_COVID_Analysis..covid_deaths
--WHERE location = 'United Kingdom'
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_population_infected DESC;

--Looking at Countries with Highest Death Count as percentage of Population
SELECT
	location,
	population,
	MAX(CAST(total_deaths AS INT)) AS highest_death_count,
	ROUND(MAX((CAST(total_deaths AS INT)/population)) * 100, 3) AS percent_population_deceased
FROM Project_COVID_Analysis..covid_deaths
--WHERE location = 'United Kingdom'
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_population_deceased DESC;


--ANALYSES AT CONTINENT LEVEL

--Looking at Highest Death Count as percentage of Population by Continent
/*Population is linked to Location (a country OR continent), so Population used for Max % Deceased calculation 
has been linked to most recent Date using Subquery*/
SELECT
	continent, 
	SUM(CAST(total_deaths AS INT)) AS total_deaths,
	ROUND(MAX((CAST(total_deaths AS FLOAT)/population)) * 100, 3) AS percent_population_deceased
FROM Project_COVID_Analysis..covid_deaths
WHERE date = (SELECT MAX(date) FROM Project_COVID_Analysis..covid_deaths)
	AND continent IS NOT NULL
GROUP BY continent
ORDER BY percent_population_deceased DESC;


--ANALYSES AT GLOBAL LEVEL

--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract COVID across all recorded Dates
SELECT
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS INT)) AS total_deaths,
	ROUND((SUM(CAST(new_deaths AS FLOAT))/SUM(new_cases)) * 100, 2) AS death_percent_cases
FROM Project_COVID_Analysis..covid_deaths
WHERE continent IS NOT NULL
ORDER BY total_cases, total_deaths; 

--Shows likelihood of dying if you contract COVID on each recorded Date
SELECT
	date,
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS INT)) AS total_deaths,
	ROUND((SUM(CAST(new_deaths AS FLOAT))/SUM(new_cases)) * 100, 4) AS death_percent_cases
FROM Project_COVID_Analysis..covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date; 


--ANALYSES RELATED TO VACCINATIONS

--Looking at Total Population vs Vaccinations
--Join covid_deaths and covid_vaccinations tables
SELECT
	cd.continent, 
	cd.location, 
	cd.date, 
	cd.population,
	cv.new_vaccinations,
	SUM(CONVERT(INT,cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS running_total_new_vaccinations
FROM Project_COVID_Analysis..covid_deaths AS cd
JOIN Project_COVID_Analysis..covid_vaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY cd.location, cd.date;

--Looking at Total Population vs Vaccinations, using CTE
WITH pop_vs_vac (
	continent,
	location,
	date,
	population,
	new_vaccinations,
	running_total_new_vaccinations
	) AS
(SELECT
	cd.continent, 
	cd.location, 
	cd.date, 
	cd.population,
	cv.new_vaccinations,
	SUM(CONVERT(INT,cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS running_total_new_vaccinations
FROM Project_COVID_Analysis..covid_deaths AS cd
JOIN Project_COVID_Analysis..covid_vaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
)
SELECT *, ROUND((running_total_new_vaccinations/population * 100), 4) AS percent_population_vaccinated
FROM pop_vs_vac;

--Looking at Total Population vs Vaccinations, using Temp Table
DROP TABLE IF EXISTS #percent_population_vaccinated
Create Table #percent_population_vaccinated (
	continent NVARCHAR(255),
	location NVARCHAR(255),
	date DATETIME,
	population NUMERIC,
	new_vaccinations NUMERIC,
	running_total_new_vaccinations NUMERIC
	)

INSERT INTO #percent_population_vaccinated
SELECT
	cd.continent, 
	cd.location, 
	cd.date, 
	cd.population,
	cv.new_vaccinations,
	SUM(CONVERT(INT,cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS running_total_new_vaccinations
FROM Project_COVID_Analysis..covid_deaths AS cd
JOIN Project_COVID_Analysis..covid_vaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL

SELECT *, ROUND((running_total_new_vaccinations/population * 100), 4) AS percent_population_vaccinated
FROM #percent_population_vaccinated;


--Creating View to store data for later visualisations
CREATE VIEW percent_population_vaccinated AS  
SELECT
	continent, 
	SUM(CAST(total_deaths AS INT)) AS total_deaths,
	ROUND(MAX((CAST(total_deaths AS FLOAT)/population)) * 100, 3) AS percent_population_deceased
FROM Project_COVID_Analysis..covid_deaths
WHERE date = (SELECT MAX(date) FROM Project_COVID_Analysis..covid_deaths)
	AND continent IS NOT NULL
GROUP BY continent;

--Using View created above
SELECT *
FROM percent_population_vaccinated;