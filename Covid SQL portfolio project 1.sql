select * from PortfolioProject.. CovidDeaths
where continent is not null and continent != ''
order by 3,4



-- select * from PortfolioProject.. CovidVaccinations
-- order by 3,4

-- Select data that we are going to be using

select Location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject.. CovidDeaths
order by 1,2

-- Lokking at Total Cases vs Total Deaths
-- likelihood of dying if you get covid in the united states
select Location, date, total_cases, total_deaths, (convert(float, total_deaths)/NULLIF(convert(float,total_cases), 0))*100 
as DeathPercentage 
from PortfolioProject.. CovidDeaths
where location like '%states%'
order by 1,2


-- looking at total cases vs population
-- shows what percentage of population got covid
select Location, date, population, total_cases, (convert(float, total_cases)/NULLIF(convert(float,population), 0))*100 
as PercentageOfPopulationInfected 
from PortfolioProject.. CovidDeaths
where location like '%states%'
order by 1,2

--looking at countries with highest infection rate compared to population

select Location, population, MAX(total_cases) as HighestInfectionCount, MAX( (cast(total_cases as float)/population))*100 
as PercentageOfPopulationInfected  
from PortfolioProject.. CovidDeaths
-- where Location like '%states%'
group by Location, population
order by PercentageOfPopulationInfected desc

--showing countries with highest death count per population

select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject.. CovidDeaths
where continent != ''
-- where Location like '%states%'
group by Location, population
order by TotalDeathCount desc

-- breaking things down by continent
-- Showing continents with the highest death count

select location, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject.. CovidDeaths
where (continent = '') and location not like '%income%'
-- where Location like '%states%'
group by location
order by TotalDeathCount desc

-- GLOBAL NUMBERS

select SUM(cast(new_cases as float)) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/NULLIF(SUM(cast(new_cases as float)), 0)*100 
as DeathPercentage 
from PortfolioProject.. CovidDeaths
-- where location like '%states%'
where continent != ''
-- group by date
order by 1,2


-- looking at total population vs vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, SUM(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject.. CovidDeaths dea
join PortfolioProject.. CovidVaccinations vac
 on dea.location = vac.location
 and dea.date = vac.date
 where dea.continent != ''
 order by 2,3

 -- Use CTE

 with PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
 as
 (
 select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, SUM(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject.. CovidDeaths dea
join PortfolioProject.. CovidVaccinations vac
 on dea.location = vac.location
 and dea.date = vac.date
 where dea.continent != '' and dea.continent is not null
 -- order by 2,3
 )
 select *, (cast(RollingPeopleVaccinated as decimal)/population)*100 as total from PopvsVac


 


 ---Temp table
-- drop table if exists #PercentPeopleVaccinated

 CREATE TABLE #PercentPeopleVaccinated
(
 continent NVARCHAR(255),
 location NVARCHAR(255),
 date DATETIME,
 population NUMERIC,
 New_vaccinations NUMERIC,
 RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPeopleVaccinated
SELECT
  dea.continent,
  dea.location,
  dea.date,
  CAST(dea.population AS NUMERIC),
  CAST(vac.new_vaccinations AS NUMERIC),
  SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
 ON dea.location = vac.location
 AND dea.date = vac.date
WHERE dea.continent != ''
  AND ISNUMERIC(dea.population) = 1
  AND ISNUMERIC(vac.new_vaccinations) = 1
ORDER BY 2, 3;

 select *, (RollingPeopleVaccinated/population)*100 as total from #PercentPeopleVaccinated



 -- creating view to store data for later visulaizations

 create view PercentPeopleVaccinated as 
  select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, SUM(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject.. CovidDeaths dea
join PortfolioProject.. CovidVaccinations vac
 on dea.location = vac.location
 and dea.date = vac.date
 where dea.continent != '' and dea.continent is not null
