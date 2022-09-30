--Question #1
/*How many npi numbers appear in the prescriber table but not in the prescription table?*/
SELECT COUNT(DISTINCT npi)
FROM prescriber
WHERE npi NOT IN (SELECT DISTINCT npi
				  FROM prescription);
--4458

--Question #2
/*a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.*/
SELECT generic_name,
	   SUM(total_claim_count) AS combined_total
FROM drug INNER JOIN prescription USING(drug_name)
		   INNER JOIN prescriber USING(npi)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY combined_total DESC
LIMIT 5;
/*b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.*/
SELECT generic_name,
	   SUM(total_claim_count) AS combined_total
FROM drug INNER JOIN prescription USING(drug_name)
		   INNER JOIN prescriber USING(npi)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY combined_total DESC
LIMIT 5;
/*c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists?
Combine what you did for parts a and b into a single query to answer this question.*/
--If meaning to look at the top 5 when you combine all scripts from Family Practice and Cardiology practitioners
SELECT generic_name,
	   SUM(total_claim_count) AS combined_total
FROM drug INNER JOIN prescription USING(drug_name)
		   INNER JOIN prescriber USING(npi)
WHERE specialty_description IN ('Cardiology', 'Family Practice')
GROUP BY generic_name
ORDER BY combined_total DESC
LIMIT 5;
--If meaning to find the drugs that are in the top five for both specialties separately
(SELECT generic_name
FROM drug INNER JOIN prescription USING(drug_name)
		   INNER JOIN prescriber USING(npi)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY SUM(total_claim_count) DESC
LIMIT 5)
INTERSECT
(SELECT generic_name
FROM drug INNER JOIN prescription USING(drug_name)
		   INNER JOIN prescriber USING(npi)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY SUM(total_claim_count) DESC
LIMIT 5);

--Question #3
/*Your goal in this question is to generate a list of the top prescribers in each of the major 
metropolitan areas of Tennessee.*/
/*a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number 
of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include 
a column showing the city.*/
SELECT npi,
	   SUM(total_claim_count) AS combined_claim_count,
	   nppes_provider_city
FROM prescriber INNER JOIN prescription USING(npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY combined_claim_count DESC
LIMIT 5;
/*b. Now, report the same for Memphis.*/
SELECT npi,
	   SUM(total_claim_count) AS combined_claim_count,
	   nppes_provider_city
FROM prescriber INNER JOIN prescription USING(npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY npi, nppes_provider_city
ORDER BY combined_claim_count DESC
LIMIT 5;
/*c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.*/
SELECT npi,
	   combined_claim_count,
	   nppes_provider_city
FROM(
	SELECT npi,
		   SUM(total_claim_count) AS combined_claim_count,
		   nppes_provider_city,
		   RANK() OVER(PARTITION BY nppes_provider_city ORDER BY SUM(total_claim_count) DESC) AS rank
	FROM prescriber INNER JOIN prescription USING(npi)
	WHERE nppes_provider_city IN ('MEMPHIS', 'NASHVILLE', 'KNOXVILLE', 'CHATTANOOGA')
	GROUP BY npi, nppes_provider_city) AS ranks
WHERE rank BETWEEN 1 AND 5
ORDER BY nppes_provider_city;

--Question #4
/*Find all counties which had an above-average number of overdose deaths. 
Report the county name and number of overdose deaths.*/
SELECT county,
	   deaths
FROM overdoses INNER JOIN fips_county USING(fipscounty)
WHERE deaths > (SELECT AVG(deaths)
				   FROM overdoses);

--Question #5
/*a. Write a query that finds the total population of Tennessee.*/
SELECT SUM(population) AS TN_pop
FROM population;
/*b. Build off of the query that you wrote in part a to write a query that returns for each county that county's 
name, its population, and the percentage of the total population of Tennessee that is contained in that county.*/
SELECT county,
	   population,
	   population / (SELECT SUM(population) FROM population) *100 AS percent_of_total_sq,
	   population / SUM(population) OVER() * 100 AS percent_of_total_window
FROM fips_county INNER JOIN population USING(fipscounty);
