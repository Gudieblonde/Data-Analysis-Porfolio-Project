--	COVID EFFECT DEMOGRAPHICS IN COUNTRRIES


SELECT *
FROM [SQL Project 1]..[covid death flat 2]
WHERE Continent is NOT NULL
ORDER BY 3,4

SELECT *
FROM [SQL Project 1].dbo.[covid vac flat]
ORDER BY 3,4



--SELECT THE DATA TO BE USED

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [SQL Project 1]..[covid death flat 2]
ORDER BY 1,2      


--Looking for total Cases vs total Deaths
--Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases, total_deaths, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0))*100 as DeathPercentage
FROM [SQL Project 1]..[covid death flat 2]
WHERE Location LIKE '%states%'
ORDER BY 1,2  


--Looking at the Total Cases vs Population
--Shows what percentage of population has covid

Select Location, date, total_cases, population, (CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0))*100 as PercentofDeathPopulation
FROM [SQL Project 1]..[covid death flat 2]
ORDER BY 1,2  


--Looking for countries with highest infections

Select Location, Population, MAX(total_cases) AS HighestInfectionCount, population, (CONVERT(float, MAX (total_cases)) / NULLIF(CONVERT(float, population), 0))*100 as PercentPopulationInfected
FROM [SQL Project 1]..[covid death flat 2]
GROUP BY Location, Population
ORDER BY 1,2


--Looking for countries with highest infections compared to Population

Select Location, Population, MAX(total_cases) AS HighestInfectionCount, population, (CONVERT(float, MAX (total_cases)) / NULLIF(CONVERT(float, population), 0))*100 as PercentPopulationInfected
FROM [SQL Project 1]..[covid death flat 2]
GROUP BY Location, Population
ORDER BY PercentPopulationInfected desc


--Showing countries with Highest Death Count per Population
Select Location, MAX(CAST(Total_deaths AS Int)) AS TotalDeathCount
FROM [SQL Project 1]..[covid death flat 2]
--Remove continent Name
WHERE Continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount desc


--LET'S BREAK THINGS DOWN BY CONTINENT
Select Continent, MAX(CAST(Total_deaths AS Int)) AS TotalDeathCount
FROM [SQL Project 1]..[covid death flat 2]
WHERE Continent IS NOT NULL
GROUP BY Continent
ORDER BY TotalDeathCount desc


--Global Numbers - calculating the total new COVID-19 cases, total new deaths, and the death percentage across all continents
--use agregate functions (SUM,MAX) where there are several 

Select SUM(CONVERT(float, new_cases)) AS Total_cases, SUM(CONVERT(float, new_deaths)) AS Total_deaths, SUM(CONVERT(float, new_deaths)) / SUM(CONVERT(float, new_cases))*100 AS DeathPercentage 
FROM [SQL Project 1]..[covid death flat 2]
--ORDER BY 1,2
WHERE Continent IS NOT Null
ORDER BY 1,2  



--Looking at TOTAL POPULATION VS VACINATION
--retrieving data about COVID-19 vaccinations and deaths, showing the continent, location, date, population, and new vaccinations, while also calculating the cumulative sum of new vaccinations for each location, ordered by location and date

SELECT dea.continent, dea.Location, Dea.Date, Dea.Population, Vac.New_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by Dea.Location Order by Dea.Location, Dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/Population)*100 AS MAXRPV
FROM [SQL Project 1]..[covid vac flat] AS Vac
JOIN [SQL Project 1]..[covid death flat 2] AS Dea
	ON Dea.Location = Vac.Location
	and Dea.Date = Vac.Date
WHERE dea.Continent IS NOT Null
ORDER BY 1,2,3


--USING CTE to call RollingPeopleVaccinated

WITH PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
as
--NB = Number of CTE colums should be equal to the number of actual columns
(
SELECT dea.continent, dea.Location, Dea.Date, Dea.Population, Vac.New_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by Dea.Location Order by Dea.Location, Dea.Date) as RollingPeopleVaccinated
--, (as RollingPeopleVaccinated/Population)*100 AS MAXRPV
FROM [SQL Project 1]..[covid vac flat] AS Vac
JOIN [SQL Project 1]..[covid death flat 2] AS Dea
	ON Dea.Location = Vac.Location
	and Dea.Date = Vac.Date
WHERE dea.Continent IS NOT Null
--ORDER BY 1,2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac --must run everything form (WITH)

--##This query is creating a Common Table Expression (CTE) called PopvsVac, which combines COVID-19 vaccination and death data, calculates the rolling sum of people vaccinated for each location, and then, in the main query, it's selecting all columns from the CTE and adding a new column showing the percentage of people vaccinated out of the total population for each location and date


--TEMP TABLE
Drop Table if exists #PercentagePopulationVac
Create Table #PercentagePopulationVac
(
Continent nvarchar (255),
Location nvarchar (255),
Date datetime,
Population nvarchar (255),
New_Vaccination nvarchar (255),
RollingPeopleVaccinated nvarchar (255)
)

Insert into #PercentagePopulationVac
SELECT dea.continent, dea.Location, Dea.Date, Dea.Population, Vac.New_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by Dea.Location Order by Dea.Location, Dea.Date) as RollingPeopleVaccinated
--, (as RollingPeopleVaccinated/Population)*100 AS MAXRPV
FROM [SQL Project 1]..[covid vac flat] AS Vac
JOIN [SQL Project 1]..[covid death flat 2] AS Dea
	ON Dea.Location = Vac.Location
	and Dea.Date = Vac.Date
WHERE dea.Continent IS NOT Null
--ORDER BY 1,2,3


--This could have worked, but the number overflows an integer and I'm converting from NVARCHAR
--SELECT
--    CONVERT(int, Population) AS Population,
--    CONVERT(int, New_Vaccination) AS New_Vaccination,
--    CONVERT(int, RollingPeopleVaccinated) AS RollingPeopleVaccinated,
--    (RollingPeopleVaccinated * 100.0) / NULLIF(Population, 0) AS VaccinationPercentage
--FROM #PercentagePopulationVac 


--This could have worked, but the nvarchar columns contain non-numeric characters, such as commas, spaces, or special characters.
--You should clean the data in those columns before attempting the conversion. Here are steps you can take to address this issue:

--SELECT
--    CONVERT(bigint, Population) AS Population,
--    CONVERT(bigint, New_Vaccination) AS New_Vaccination,
--    CONVERT(bigint, RollingPeopleVaccinated) AS RollingPeopleVaccinated,
--    (RollingPeopleVaccinated * 100.0) / NULLIF(Population, 0) AS VaccinationPercentage
--FROM #PercentagePopulationVac 

SELECT *
FROM #PercentagePopulationVac 
WHERE ISNUMERIC(Population) = 0 OR ISNUMERIC(New_Vaccination) = 0 OR ISNUMERIC(RollingPeopleVaccinated) = 0;


--SELECT *, (RollingPeopleVaccinated/Population)*100
--FROM #PercentagePopulationVac --must run everything form (WITH)

--### FIX THIS MESS LATER



--Creating a View

DROP VIEW IF EXISTS PercentagePopulationVac

CREATE VIEW PercPopulationVac AS
SELECT dea.continent, dea.Location, Dea.Date, Dea.Population, Vac.New_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by Dea.Location Order by Dea.Location, Dea.Date) as RollingPeopleVaccinated
--, (as RollingPeopleVaccinated/Population)*100 AS MAXRPV
FROM [SQL Project 1]..[covid vac flat] AS Vac
JOIN [SQL Project 1]..[covid death flat 2] AS Dea
	ON Dea.Location = Vac.Location
	and Dea.Date = Vac.Date
WHERE dea.Continent IS NOT Null
--ORDER BY 1,2,3

Select * 
From PercPopulationVac