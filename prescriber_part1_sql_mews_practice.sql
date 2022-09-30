--Question #1
/*  a. Which prescriber had the highest total number of claims 
(totaled over all drugs)? Report the npi and the total number of claims.*/
SELECT npi,
	   SUM(total_claim_count) AS sum_total_claim_count
FROM prescriber INNER JOIN prescription USING(npi)
GROUP BY npi
ORDER BY sum_total_claim_count DESC
LIMIT 3;
--1881634483
/*b. Repeat the above, but this time report the nppes_provider_first_name, 
nppes_provider_last_org_name,  specialty_description, and the total number of claims.*/
SELECT DISTINCT npi,
	   nppes_provider_first_name,
	   nppes_provider_last_org_name,
	   specialty_description,
	   SUM(total_claim_count) OVER(PARTITION BY npi)AS sum_total_claim_count
FROM prescriber INNER JOIN prescription USING(npi)
ORDER BY sum_total_claim_count DESC
LIMIT 3;
--Bruce Pendley, Family Practice
--Question #2
/*a. Which specialty had the most total number of claims (totaled over all drugs)?*/
SELECT specialty_description,
	   SUM(total_claim_count) AS sum_total_claim_count
FROM prescriber INNER JOIN prescription USING(npi)
GROUP BY specialty_description
ORDER BY sum_total_claim_count DESC;
--Family Practice
 /*b. Which specialty had the most total number of claims for opioids?*/
SELECT specialty_description,
	   SUM(total_claim_count) AS sum_total_claim_count_opioids
FROM prescriber INNER JOIN prescription USING(npi)
				INNER JOIN drug USING(drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY sum_total_claim_count_opioids DESC;
--Nurse Practitioners
/*c. **Challenge Question:** Are there any specialties that appear in the prescriber table 
that have no associated prescriptions in the prescription table?*/
SELECT specialty_description,
	   SUM(total_claim_count) AS sum_total_claim_count
FROM prescriber LEFT JOIN prescription USING(npi)
GROUP BY specialty_description
ORDER BY sum_total_claim_count;
--MY SOLUTION ABOVE WAS INCORRECT
--Josh's solution
SELECT DISTINCT specialty_description
FROM prescriber
WHERE specialty_description NOT IN
	(
	SELECT specialty_description
	FROM prescriber
	INNER JOIN prescription
	USING (npi)
	);
--15 specialties are listed
/*d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* 
For each specialty, report the percentage of total claims by that specialty which are for opioids. 
Which specialties have a high percentage of opioids?*/
WITH total_scripts AS (SELECT specialty_description,
							   SUM(total_claim_count) AS sum_total_claim_count
						FROM prescriber INNER JOIN prescription USING(npi)
						GROUP BY specialty_description
						ORDER BY sum_total_claim_count DESC),
     opioid_scripts AS (SELECT specialty_description,
							   SUM(total_claim_count) AS sum_total_claim_count_opioids
						FROM prescriber INNER JOIN prescription USING(npi)
										INNER JOIN drug USING(drug_name)
						WHERE opioid_drug_flag = 'Y'
						GROUP BY specialty_description
						ORDER BY sum_total_claim_count_opioids DESC)
SELECT specialty_description,
	   sum_total_claim_count_opioids,
	   sum_total_claim_count,
	   ROUND((sum_total_claim_count_opioids::decimal / sum_total_claim_count) * 100, 2) AS opioid_script_percen
FROM total_scripts LEFT JOIN opioid_scripts USING(specialty_description)
ORDER BY opioid_script_percen DESC NULLS LAST;
--Case Manager/Care Coordinator, Orthopaedic Surgery, Interventional Pain Management

--Question #3
/*a. Which drug (generic_name) had the highest total drug cost?*/
SELECT generic_name,
	   SUM(total_drug_cost) AS sum_total_drug_cost
FROM prescription INNER JOIN drug USING (drug_name)
GROUP BY generic_name
ORDER BY sum_total_drug_cost DESC;
--Insulin Glargine, Hum,Rec.Anlog at $104,264,066.35
/*b. Which drug (generic_name) has the hightest total cost per day? 
**Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.*/
SELECT generic_name,
	   ROUND(SUM(total_drug_cost) / SUM(total_day_supply), 2) AS cost_per_day
FROM prescription INNER JOIN drug USING (drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC;
--C1 Esterase Inhibitor at $3,495.22 per day

--Question #4
/*a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which 
says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which 
have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.*/
SELECT drug_name,
	   CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ELSE 'neither' END AS drug_type
FROM drug;
/*b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) 
on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.*/
WITH dtypes AS (SELECT drug_name,
			   CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
					WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
					ELSE 'neither' END AS drug_type
				FROM drug),
	  costs AS (SELECT drug_name,
			   		   SUM(total_drug_cost) AS total_drug_cost
				 FROM prescription
				 GROUP BY drug_name)
SELECT SUM(CASE WHEN drug_type = 'opioid' THEN total_drug_cost::money END) AS total_opioid_cost,
	   SUM(CASE WHEN drug_type = 'antibiotic' THEN total_drug_cost:: money END)AS total_antibiotic_cost
FROM dtypes INNER JOIN costs USING(drug_name);
--opioids $105,080,626.37, antibiotics $38,435,121.26
--Josh's solution
WITH drug_class AS (
	SELECT drug_name,
		CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			 ELSE 'neither' END AS drug_type
	FROM drug
)
SELECT drug_type,
	SUM(total_drug_cost)::money AS total_spent
FROM drug_class
NATURAL JOIN prescription
WHERE drug_type <> 'neither'
GROUP BY drug_type
ORDER BY total_spent DESC;

--Question #5
/*a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, 
not just Tennessee.*/
SELECT COUNT(DISTINCT cbsa)
FROM cbsa
WHERE cbsaname LIKE '%TN%';
--10
/*b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.*/
SELECT cbsaname,
	   SUM(population)
FROM cbsa INNER JOIN population USING(fipscounty)
GROUP BY cbsaname
ORDER BY SUM(population) DESC;
--Nashville-Davidson-Murfreesboro-Franklin 1,830,410, Morristown 116352
--Josh's solution
(SELECT cbsaname, SUM(population) AS total_pop, 'largest' AS largest_smallest
FROM cbsa
INNER JOIN population
	USING (fipscounty)
GROUP BY cbsaname
ORDER BY total_pop DESC
LIMIT 1)
UNION
(SELECT cbsaname, SUM(population) AS total_pop, 'smallest' AS largest_smallest
FROM cbsa
INNER JOIN population
	USING (fipscounty)
GROUP BY cbsaname
ORDER BY total_pop
LIMIT 1);
/*c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county 
name and population.*/
SELECT county,
	   SUM(population) AS combined_population
FROM cbsa RIGHT JOIN fips_county USING(fipscounty)
		  INNER JOIN population USING(fipscounty)
WHERE state = 'TN'
AND cbsa IS NULL
GROUP BY county
ORDER BY combined_population DESC
LIMIT 1;
--Sevier 95,523

--Question #6
/*  a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name 
and the total_claim_count.*/
SELECT drug_name,
	   total_claim_count
FROM prescription INNER JOIN drug USING(drug_name)
WHERE total_claim_count >= 3000;
/*  b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.*/
SELECT drug_name,
	   total_claim_count,
	   opioid_drug_flag
FROM prescription INNER JOIN drug USING(drug_name)
WHERE total_claim_count >= 3000
/*c. Add another column to you answer from the previous part which gives the prescriber first and last name 
associated with each row.*/
SELECT nppes_provider_first_name,
	   nppes_provider_last_org_name,
	   drug_name,
	   total_claim_count,
	   opioid_drug_flag
FROM prescription INNER JOIN drug USING(drug_name)
				  INNER JOIN prescriber USING(npi)
WHERE total_claim_count >= 3000;

--Question #7 
/*The goal of this exercise is to generate a full list of all pain management specialists in Nashville and 
the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.*/
/*a. First, create a list of all npi/drug_name combinations for pain management specialists 
(specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where 
the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will 
only need to use the prescriber and drug tables since you don't need the claims numbers yet.*/
SELECT npi,
	   drug_name
FROM prescriber CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y';
/*b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, 
whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of 
claims (total_claim_count).*/
WITH npi_drugs AS (SELECT npi,
				    	  drug_name
					FROM prescriber CROSS JOIN drug
					WHERE specialty_description = 'Pain Management'
					AND nppes_provider_city = 'NASHVILLE'
					AND opioid_drug_flag = 'Y')
SELECT npi_drugs.npi,
	   npi_drugs.drug_name,
	   total_claim_count
FROM npi_drugs LEFT JOIN prescription USING(npi, drug_name); 
/*c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. 
Hint - Google the COALESCE function.*/
WITH npi_drugs AS (SELECT npi,
				    	  drug_name
					FROM prescriber CROSS JOIN drug
					WHERE specialty_description = 'Pain Management'
					AND nppes_provider_city = 'NASHVILLE'
					AND opioid_drug_flag = 'Y')
SELECT npi_drugs.npi,
	   npi_drugs.drug_name,
	   COALESCE(total_claim_count, 0) AS total_claim_count
FROM npi_drugs LEFT JOIN prescription USING(npi, drug_name);
