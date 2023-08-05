--Question 1
/*How many npi numbers appear in the prescriber table but not in the prescription table?*/
SELECT COUNT(npi)
FROM(
	(SELECT npi
	FROM prescriber)
	EXCEPT
	(SELECT npi
	FROM prescription)) AS non_prescribers;
--4458

--Question 2
/*a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.*/
SELECT generic_name
FROM prescription
	 INNER JOIN prescriber
	 USING(npi)
	 INNER JOIN drug
	 USING(drug_name)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY SUM(total_claim_count) DESC
LIMIT 5;

/*b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.*/
SELECT generic_name
FROM prescription
	 INNER JOIN prescriber
	 USING(npi)
	 INNER JOIN drug
	 USING(drug_name)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY SUM(total_claim_count) DESC
LIMIT 5;

/*c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? 
Combine what you did for parts a and b into a single query to answer this question.*/
(SELECT generic_name
FROM prescription
	 INNER JOIN prescriber
	 USING(npi)
	 INNER JOIN drug
	 USING(drug_name)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY SUM(total_claim_count) DESC
LIMIT 5)
INTERSECT
(SELECT generic_name
FROM prescription
	 INNER JOIN prescriber
	 USING(npi)
	 INNER JOIN drug
	 USING(drug_name)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY SUM(total_claim_count) DESC
LIMIT 5);
-- They have these in common: ATORVASTATIN CALCIUM & AMLODIPINE BESYLATE


--Question 3 
/*Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan 
areas of Tennessee.*/
/*a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.*/
SELECT npi,
	   SUM(total_claim_count) AS total_claims,
	   nppes_provider_city
FROM prescriber
	 INNER JOIN prescription
	 USING(npi)
WHERE nppes_provider_city ILIKE 'Nashville'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5; 

/*b. Now, report the same for Memphis.*/
SELECT npi,
	   SUM(total_claim_count) AS total_claims,
	   nppes_provider_city
FROM prescriber
	 INNER JOIN prescription
	 USING(npi)
WHERE nppes_provider_city ILIKE 'Memphis'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5; 

/*c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.*/
SELECT npi,
	   nppes_provider_city,
	   total_claims
FROM 	(SELECT npi,
			   nppes_provider_city,
			   SUM(total_claim_count) AS total_claims,
			   RANK() OVER(PARTITION by nppes_provider_city ORDER BY SUM(total_claim_count) DESC)
		FROM prescriber
			 INNER JOIN prescription
			 USING(npi)
		WHERE nppes_provider_city IN ('NASHVILLE', 'MEMPHIS', 'CHATTANOOGA', 'KNOXVILLE')
		GROUP BY npi, nppes_provider_city) AS ranks
WHERE rank <= 5
ORDER BY nppes_provider_city, rank;

--Question 4 
/*Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.*/
WITH od_avg AS(	SELECT year, AVG(overdose_deaths)
				FROM overdose
				GROUP BY year
			   )
SELECT county, year, overdose_deaths
FROM overdose
	 LEFT JOIN od_avg
	 USING(year)
	 INNER JOIN fips_county
	 USING(fipscounty)
WHERE overdose_deaths > avg
ORDER BY year, county;

--Question 5
/*a. Write a query that finds the total population of Tennessee.*/
SELECT SUM(population) AS total_tn_pop
FROM population;

/*b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, 
its population, and the percentage of the total population of Tennessee that is contained in that county.*/
SELECT county,
	   population,
	   ROUND(population * 100.0 / (SELECT SUM(population) AS total_tn_pop
							FROM population), 3) AS percentage_of_tn_pop
FROM population
	 LEFT JOIN fips_county
	 USING(fipscounty)
ORDER BY percentage_of_tn_pop DESC;