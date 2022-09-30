--Question 1
/*How many npi numbers appear in the prescriber table but not in the prescription table?*/
SELECT COUNT(DISTINCT npi)
FROM prescriber
WHERE npi NOT IN 
	(SELECT DISTINCT(npi)
	FROM prescription);
--4458

--Question 2
/*a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.*/
--by claims
SELECT generic_name, SUM(total_claim_count) AS total_claims
FROM prescription LEFT JOIN drug USING(drug_name)
				  LEFT JOIN prescriber USING(npi)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;
/*"LEVOTHYROXINE SODIUM"	406547
"LISINOPRIL"	311506
"ATORVASTATIN CALCIUM"	308523
"AMLODIPINE BESYLATE"	304343
"OMEPRAZOLE"	273570*/

--by days supplied
SELECT generic_name, SUM(total_day_supply) AS total_days_supplied
FROM prescription LEFT JOIN drug USING(drug_name)
				  LEFT JOIN prescriber USING(npi)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY total_days_supplied DESC
LIMIT 5;
/*"LEVOTHYROXINE SODIUM"	21725836
"ATORVASTATIN CALCIUM"	18197873
"LISINOPRIL"	17808882
"AMLODIPINE BESYLATE"	16858953
"METFORMIN HCL"	16004668*/

/*b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.*/
--by claims
SELECT generic_name, SUM(total_claim_count) AS total_claims
FROM prescription LEFT JOIN drug USING(drug_name)
				  LEFT JOIN prescriber USING(npi)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;
/*"ATORVASTATIN CALCIUM"	120662
"CARVEDILOL"	106812
"METOPROLOL TARTRATE"	93940
"CLOPIDOGREL BISULFATE"	87025
"AMLODIPINE BESYLATE"	86928 */
--by days supplied
SELECT generic_name, SUM(total_day_supply) AS total_days_supplied
FROM prescription LEFT JOIN drug USING(drug_name)
				  LEFT JOIN prescriber USING(npi)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY total_days_supplied DESC
LIMIT 5;
/*"ATORVASTATIN CALCIUM"	7266774
"CARVEDILOL"	6060856
"METOPROLOL TARTRATE"	5325871
"AMLODIPINE BESYLATE"	5086616
"CLOPIDOGREL BISULFATE"	4948344 */

/*c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? 
Combine what you did for parts a and b into a single query to answer this question.*/
--by claims
WITH top_fp_c AS	(SELECT generic_name, SUM(total_claim_count) AS total_claims
					FROM prescription LEFT JOIN drug USING(drug_name)
									  LEFT JOIN prescriber USING(npi)
					WHERE specialty_description = 'Family Practice'
					GROUP BY generic_name
					ORDER BY total_claims DESC
					LIMIT 5),
top_c_c AS		(SELECT generic_name, SUM(total_claim_count) AS total_claims
				FROM prescription LEFT JOIN drug USING(drug_name)
								  LEFT JOIN prescriber USING(npi)
				WHERE specialty_description = 'Cardiology'
				GROUP BY generic_name
				ORDER BY total_claims DESC
				LIMIT 5)
SELECT generic_name
FROM top_fp_c INNER JOIN top_c_c USING(generic_name);
/*"ATORVASTATIN CALCIUM"
"AMLODIPINE BESYLATE"*/

--by days supplied
WITH top_fp_ds AS	(SELECT generic_name, SUM(total_day_supply) AS total_days_supplied
					FROM prescription LEFT JOIN drug USING(drug_name)
									  LEFT JOIN prescriber USING(npi)
					WHERE specialty_description = 'Family Practice'
					GROUP BY generic_name
					ORDER BY total_days_supplied DESC
					LIMIT 5),
top_c_ds AS		(SELECT generic_name, SUM(total_day_supply) AS total_days_supplied
				FROM prescription LEFT JOIN drug USING(drug_name)
								  LEFT JOIN prescriber USING(npi)
				WHERE specialty_description = 'Cardiology'
				GROUP BY generic_name
				ORDER BY total_days_supplied DESC
				LIMIT 5)
SELECT generic_name
FROM top_fp_ds INNER JOIN top_c_ds USING(generic_name);
/*"ATORVASTATIN CALCIUM"
"AMLODIPINE BESYLATE"*/


--Question 3 
/*Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan 
areas of Tennessee.*/
/*a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims 
(total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.*/


/*b. Now, report the same for Memphis.*/
	
/*c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.*/

--Question 4 
/*Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.*/

--Question 5
/*a. Write a query that finds the total population of Tennessee.*/


/*b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, 
its population, and the percentage of the total population of Tennessee that is contained in that county.*/