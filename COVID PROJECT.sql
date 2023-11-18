--checking data type----
EXEC sp_help 'CovidDeaths2'
EXEC sp_help 'CovidVaccinations2'

----Exploring Data----
Select*
From Project1..CovidDeaths2
Where continent is not null 
order by 3,4

Select *
From Project1..CovidVaccinations2
order by 3,4

select distinct(continent)
From Project1..CovidVaccinations2

Select*
From Project1..CovidVaccinations2
where location in ('Morocco','United States') 

-----Add new column for months------

Alter table CovidDeaths2
add Months nvarchar(255)

update Project1..CovidDeaths2
set Months = CASE
    WHEN MONTH(date) = 1 THEN 'January'
    WHEN MONTH(date) = 2 THEN 'February'
    WHEN MONTH(date) = 3 THEN 'March'
    WHEN MONTH(date) = 4 THEN 'April'
    WHEN MONTH(date) = 5 THEN 'May'
    WHEN MONTH(date) = 6 THEN 'June'
    WHEN MONTH(date) = 7 THEN 'July'
    WHEN MONTH(date) = 8 THEN 'August'
    WHEN MONTH(date) = 9 THEN 'September'
    WHEN MONTH(date) = 10 THEN 'October'
    WHEN MONTH(date) = 11 THEN 'November'
    WHEN MONTH(date) = 12 THEN 'December'
    ELSE CONVERT(VARCHAR(2), MONTH(date))
  END 
FROM Project1..CovidDeaths2

-----Add new column for years------
Alter table CovidDeaths2
add Years nvarchar(255)

update CovidDeaths2
set Years = Year(date)


--Select Data that we are going to use------

Select location, date, population, total_cases, new_cases, total_deaths
From Project1..CovidDeaths
order by 1,2

--Converting data from string to real number-----

Alter table CovidDeaths2
Alter column total_cases float

Alter table CovidVaccinations2
Alter column new_vaccinations float

Alter table CovidVaccinations2
Alter column new_tests float

--Looking at total_deaths vs total_cases----
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as deathpercentage
From Project1..CovidDeaths2
Where location like '%states%'
order by 1,2


---------Rename the column deghe to Code------
sp_rename 'CovidDeaths2.deghe','code','column'


-----Percentage of population got COVID in USA------

With U as (Select location, Months, Month(date) as Month, Years, population, Sum(new_cases) as USA_monthly_cases
    From Project1..CovidDeaths2
    Where location in ('United States')
    group by location, Months, Month(date), Years, population ) 

Select location, Months, Month, Years, population, USA_monthly_cases, CAST((USA_monthly_cases/population)*100 as DECIMAL(5,2)) as Covidpercentage
from U
order by Years, Month


----showing what percentage of population got COVID-----
Select location, date, total_cases, population, (total_cases/population)*100 as Covidpercentage
From Project1..CovidDeaths2
where location = 'United states'
order by 1,2

---Looking at countries with highest infection rate compared to population-----
Select location, MAX(total_cases) as TotalCases, population, MAX((total_cases/population))*100 as PercentPopulationInfected
From Project1..CovidDeaths2
Group by location, population
order by PercentPopulationInfected desc

------Showing countries with highest death------
Select location, Sum(new_deaths) as totalDeaths
From Project1..CovidDeaths2
Where continent is not null
Group by location
order by totalDeaths desc

Select*
From Project1..CovidDeaths2
Where continent is not null and location like '%states%'
order by 3,4

-------Let's break things down by continent-----
Select location, MAX(total_deaths) as totalDeaths
From Project1..CovidDeaths2
Where continent is null
 and location <> 'High income' And location <> 'low income' And location <> 'lower middle income' and location <> 'upper middle income'
Group by location
order by totalDeaths desc

-----Convert data type in Covid Death table-----

Alter table CovidDeaths2
Alter column new_cases float

Alter table CovidDeaths2
Alter column new_deaths float

-------Death percentage-------
SELECT date, Sum(new_cases) AS totalCases1, Sum(new_deaths) AS totalDeaths1,
  CASE
    WHEN Sum(new_cases) <> 0 THEN (Sum(new_deaths) / Sum(new_cases)) * 100
    ELSE NULL
  END AS Deathpercentage1
FROM Project1..CovidDeaths2
Where continent is null
and location <> 'High income' And location <> 'low income' And location <> 'lower middle income' and location <> 'upper middle income'
GROUP BY date
ORDER BY date DESC

----Total deaths vs Total cases-----

Select MAX(total_cases) as totalCases1, MAX(total_deaths) as totalDeaths1, (MAX(total_deaths)/MAX(total_cases))*100 as Deathpercentage1
From Project1..CovidDeaths2
Where continent is null
 and location <> 'High income' And location <> 'low income' And location <> 'lower middle income' and location <> 'upper middle income'
----Group by date
----order by date desc

-------- Monthly cases and deaths in Morocco------
Select location, Months, Month(date), Years, Sum(new_cases) as Monthly_new_cases, sum(new_deaths) as Monthly_new_deaths
From Project1..CovidDeaths2
Where continent is not null and location in ('Morocco')
group by location, Years, Month(date), Months
order by location, Years, Month(date) asc



----Looking at Total population vs New vaccinations------
With PopvcVac as (
Select dea.date, dea.continent, dea.location, dea.population, vac.new_vaccinations, 
Sum(CONVERT(float, vac.new_vaccinations)) Over (partition by dea.location order by dea.date) as RollingPeopleVaccinated
From Project1..CovidDeaths2 dea
Join Project1..CovidVaccinations2 vac
On dea.date=vac.date
and dea.location=vac.location
Where dea.continent is not null
 and dea.location <> 'High income' And dea.location <> 'low income' And dea.location <> 'lower middle income' and dea.location <> 'upper middle income'
--order by 2,3
)
Select *, (RollingPeopleVaccinated/population)*100
From PopvcVac



----TEMP TABLE-----

Create table percentpopulationvaccinated
(
Date datetime,
Continent nvarchar(255),
Location nvarchar(255),
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric,)
Insert into percentpopulationvaccinated
Select dea.date, dea.continent, dea.location, dea.population, vac.new_vaccinations, 
Sum(CONVERT(float, vac.new_vaccinations)) Over (partition by dea.location order by dea.date) as RollingPeopleVaccinated
From Project1..CovidDeaths2 dea
Join Project1..CovidVaccinations2 vac
On dea.date=vac.date
and dea.location=vac.location
---Where dea.continent is not null
---and dea.location <> 'High income' And dea.location <> 'low income' And dea.location <> 'lower middle income' and dea.location <> 'upper middle income'
--order by 2,3
Select *, (RollingPeopleVaccinated/population)*100
From percentpopulationvaccinated



-----Creating a view to store data for visualisations------
Create view PRC2 as
Select dea.date, dea.continent, dea.location, dea.population, vac.new_vaccinations, 
Sum(CONVERT(float, vac.new_vaccinations)) Over (partition by dea.location order by dea.date) as RollingPeopleVaccinated
From Project1..CovidDeaths2 dea
Join Project1..CovidVaccinations2 vac
On dea.date=vac.date
and dea.location=vac.location
Where dea.continent is not null
 and dea.location <> 'High income' And dea.location <> 'low income' And dea.location <> 'lower middle income' and dea.location <> 'upper middle income'
--order by 2,3

select*
from PRC2

-----monthly new cases & new deaths in Morocco------

Select Location, Years, month([date]), Sum(new_cases), sum(new_deaths)
From Project1..CovidDeaths2
where location like 'Morocco' 
group by location, Years, month([date])
order by Years, month([date]) asc

Select*
From Project1..CovidDeaths2
where location like 'Morocco'
order by 3,4


-----Total cases et deaths per years-------
Select a.location, a.Years, Sum(a.new_cases) as Total_cases_per_continent, Sum(a.new_deaths) as Total_deaths_per_continent, Sum(b.new_tests) as Total_tests_per_continent
From Project1..CovidDeaths2 a
Join Project1..CovidVaccinations2 b
on a.location = b.location
and a.date = b.date
Where a.continent is null and b.continent is null
 and a.location <> 'High income' And a.location <> 'low income' And a.location <> 'lower middle income' and a.location <> 'upper middle income'
 and a.location <> 'World' and a.location <> 'European Union'
group by a.location, a.Years
order by a.location, a.Years



