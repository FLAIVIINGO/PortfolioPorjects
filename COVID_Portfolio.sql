SELECT * 
FROM PortfolioProject..CovidDeaths 
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT * FROM PortfolioProject..CovidVaccinations ORDER BY 3,4

-- Select Data that will be used

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelishood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
AND continent IS NOT NULL
ORDER BY 1,2

-- Total Cases vs Population
-- Percentage of population that got Covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentOfPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
AND continent IS NOT NULL
ORDER BY 1,2

-- Countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, (MAX(total_cases)/population)*100 AS PercentOfPopulationInfected
FROM PortfolioProject..CovidDeaths
-- WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentOfPopulationInfected DESC

-- Countries with highest death count per population

SELECT location, MAX(CAST(total_deaths AS BIGINT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
-- WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Something interesting here is income. Possibly query for later
--SELECT location, MAX(CAST(total_deaths AS BIGINT)) as TotalDeathCount
--FROM PortfolioProject..CovidDeaths
--WHERE continent IS NULL
--GROUP BY location
--ORDER BY TotalDeathCount DESC

-- Breaking down by continent
-- Showing continents with the highest death count per population

SELECT continent, MAX(CAST(total_deaths AS BIGINT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Global Numbers
-- Display by date

SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS BIGINT)) AS total_deaths, SUM(CAST(new_deaths AS BIGINT)) / 
SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
-- WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2
-- Display by sum of total cases vs total deaths

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS BIGINT)) AS total_deaths, SUM(CAST(new_deaths AS BIGINT)) / 
SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
-- WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

-- Total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Use CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated / population) * 100
FROM PopvsVac

-- Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent NVARCHAR(255),
location NVARCHAR(255),
date DATETIME,
population NUMERIC,
new_vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated / population) * 100
FROM #PercentPopulationVaccinated

-- Create View to Store Data for Visualizations
USE PortfolioProject
GO
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated
