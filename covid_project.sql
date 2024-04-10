USE portfolio_project;

SELECT *
FROM covid_deaths;

-- Selecting the data we're going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
ORDER BY 1, 2;

-- Looking at total cases vs. total deaths

-- CREATE VIEW total_cases_vs_total_deaths AS
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM covid_deaths
WHERE location LIKE 'finland'
ORDER BY 1, 2 DESC;

-- Total cases vs. population (How many have gotten covid)

-- CREATE VIEW total_cases_vs_population AS
SELECT location, date, total_cases, population, (total_cases/population)*100 AS infected_percentage
FROM covid_deaths
WHERE location LIKE 'finland'
ORDER BY 1, 2 DESC;


-- Looking at coutries with highest infection rate compared to population

-- CREATE VIEW highest_infection_rate_to_population AS
SELECT 
	location, 
    population, 
    MAX(total_cases) as hihgest_infection_per_country, 
	MAX((total_cases/population))*100 AS infected_percentage
FROM covid_deaths
GROUP BY location, population
ORDER BY 4 DESC;


-- Countries with the highest deathcount per population

-- CREATE VIEW highest_death_count_per_population AS
SELECT 
	location, 
	MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent <> "" 
GROUP BY location
ORDER BY 2 DESC;


-- Previous but by continent (use location but WITH continent = "")
-- Showing the continents with the highest death count

SELECT 
	location, 
	MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent = "" AND (location <> "High income" 
				     AND location <> "Upper middle income"
                     AND location <> "Low income"
                     AND location <> "Lower middle income")
GROUP BY location
ORDER BY 2 DESC;

-- Above gives the right answer but lets use the below one for visualization

-- CREATE VIEW highest_death_count AS
SELECT 
	continent, 
	MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent <> ""
GROUP BY continent
ORDER BY 2 DESC;


-- Global numebrs
-- CREATE VIEW global_numbers AS
SELECT SUM(new_cases) AS total_cases, 
	   SUM(new_deaths) AS total_deaths, 
	   SUM(new_deaths)/SUM(new_cases)*100 AS death_percentage
FROM covid_deaths
WHERE continent <> ""
ORDER BY 1, 2 DESC;


-- Joining tables with vaccines table
-- Looking at total population vs. vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
    -- ,(rolling_people_vaccinated/population)*100
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> ""
ORDER BY 2, 3;


-- Use CTE (use our new created rolling_people_vaccinated)

WITH pop_vs_vac (Continent, Location, Date, Population, New_vaccinations, Rolling_people_vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> "" 
)
SELECT *, 
	(rolling_people_vaccinated/population)*100 AS percent_vaccinated
FROM pop_vs_vac;


-- Temp table

DROP TABLE IF EXISTS percent_population_vaccinated;
CREATE TEMPORARY TABLE percent_population_vaccinated
(
continent VARCHAR(255),
location VARCHAR(255),
date DATE,
population INT,
new_vaccinations INT,
rolling_people_vaccinated NUMERIC
);

INSERT INTO percent_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> "" ;

SELECT *, 
	(rolling_people_vaccinated/population)*100 AS percent_vaccinated
FROM percent_population_vaccinated;


-- Creating a view to store data for later

CREATE VIEW people_vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> "" 












