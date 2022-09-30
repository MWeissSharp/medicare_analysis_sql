--Question 1
/*a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and 
the total number of claims.*/
SELECT prescriber.npi, SUM(total_claim_count) AS grand_total_claims
FROM prescriber INNER JOIN prescription USING(npi)
GROUP BY prescriber.npi
ORDER BY grand_total_claims DESC
LIMIT 1;
--npi 1881634483 has 99707 total claims

/*b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  
specialty_description, and the total number of claims.*/
SELECT prescriber.npi, 
	   nppes_provider_first_name, 
	   nppes_provider_last_org_name, 
	   specialty_description, 
	   SUM(total_claim_count) AS grand_total_claims
FROM prescriber INNER JOIN prescription USING(npi)
GROUP BY prescriber.npi, nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
ORDER BY grand_total_claims DESC
LIMIT 1;
--Bruce Pendley, Family Practice with 99707 total claims
/*Alternative solution w/ subquery*/
SELECT prescriber.npi, 
	   nppes_provider_first_name, 
	   nppes_provider_last_org_name, 
	   specialty_description, 
	   grand_total_claims
FROM prescriber INNER JOIN
	(SELECT prescriber.npi, SUM(total_claim_count) AS grand_total_claims
	FROM prescriber INNER JOIN prescription USING(npi)
	GROUP BY prescriber.npi
	ORDER BY SUM(total_claim_count) DESC
	LIMIT 1) AS high_prescriber
	ON prescriber.npi = high_prescriber.npi;

--Question 2
/*a. Which specialty had the most total number of claims (totaled over all drugs)?*/
SELECT specialty_description, 
	   SUM(total_claim_count) AS grand_total_claims
FROM prescriber 
	 INNER JOIN prescription 
	 USING(npi)
GROUP BY specialty_description
ORDER BY grand_total_claims DESC
LIMIT 1;
--Family Practice with 9752347

/*b. Which specialty had the most total number of claims for opioids?*/
SELECT specialty_description, 
	   SUM(total_claim_count) AS grand_total_claims
FROM prescriber 
	 INNER JOIN prescription 
	 USING(npi)
	 LEFT JOIN drug
	 USING(drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY grand_total_claims DESC
LIMIT 1;
--Nurse Practitioners with 900845 claims

/*c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated 
prescriptions in the prescription table?*/
SELECT specialty_description, 
	   SUM(total_claim_count) AS grand_total_claims
FROM prescriber 
	 LEFT JOIN prescription 
	 USING(npi)
GROUP BY specialty_description
HAVING SUM(total_claim_count) IS NULL;
--Yes, there are 15 specialties with no associated prescriptions 

/*d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, 
report the percentage of total claims by that specialty which are for opioids. Which specialties have a 
high percentage of opioids?*/
SELECT specialty_description, 
	   ROUND(SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count END)
	   / SUM(total_claim_count) * 100, 2) AS opioid_percentage
FROM prescriber 
	 INNER JOIN prescription 
	 USING(npi)
	 LEFT JOIN drug
	 USING(drug_name)
GROUP BY specialty_description
ORDER BY opioid_percentage DESC NULLS LAST;

--Question 3
/*a. Which drug (generic_name) had the highest total drug cost?*/
SELECT generic_name, SUM(total_drug_cost) AS grand_total_cost
FROM prescription LEFT JOIN drug USING(drug_name)
GROUP BY generic_name
ORDER BY grand_total_cost DESC
LIMIT 1;
--INSULIN GLARGINE,HUM.REC.ANLOG $104264066.35

/*b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column 
to 2 decimal places. Google ROUND to see how this works.*/
SELECT generic_name, ROUND(SUM(total_drug_cost)/ SUM(total_day_supply), 2) AS avg_cost_per_day
FROM prescription LEFT JOIN drug USING(drug_name)
GROUP BY generic_name
ORDER BY avg_cost_per_day DESC
LIMIT 1;
--C1 ESTERASE INHIBITOR $3495.22

--Question 4
/*a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' 
for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', 
and says 'neither' for all other drugs.*/
SELECT 
	drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 ELSE 'neither' END AS drug_type
FROM drug;

/*b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids 
or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.*/
SELECT drug_type, SUM(total_drug_cost)::money AS grand_total_cost
FROM prescription LEFT JOIN 
	(SELECT 
	drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 ELSE 'neither' END AS drug_type
	FROM drug) AS drug_detail 
	USING(drug_name)
WHERE drug_type IN ('antibiotic', 'opioid')
GROUP BY drug_type;
--A good bit more is spent on opiods ($105,080,626.37 vs $38,435,121.26)

--Question 5
/*a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just 
Tennessee.*/
SELECT COUNT(DISTINCT cbsa) AS TN_cbsa_count
FROM cbsa LEFT JOIN fips_county USING(fipscounty)
WHERE state = 'TN';

/*b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total 
population.*/
SELECT cbsaname, SUM(population) AS total_cbsa_pop
FROM cbsa INNER JOIN population USING(fipscounty)
GROUP BY cbsaname
ORDER BY total_cbsa_pop DESC
LIMIT 1;
--Largest is Nashville-Davidson--Murfreesboro--Franklin, TN with pop of 1830410
SELECT cbsaname, SUM(population) AS total_cbsa_pop
FROM cbsa INNER JOIN population USING(fipscounty)
GROUP BY cbsaname
ORDER BY total_cbsa_pop
LIMIT 1;
--Smallest Morristown, TN with pop of 116352

/*c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county 
name and population.*/
SELECT county, cbsa, population
FROM population LEFT JOIN fips_county USING(fipscounty)
				LEFT JOIN cbsa USING(fipscounty)
WHERE cbsa IS NULL
ORDER BY population DESC
LIMIT 1;
--Sevier County with a pop of 95523

--Question 6
/*a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the 
total_claim_count.*/
SELECT drug_name, total_claim_count
FROM prescription LEFT JOIN drug USING(drug_name)
WHERE total_claim_count > 3000;

/*b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.*/
SELECT drug_name, total_claim_count, opioid_drug_flag
FROM prescription LEFT JOIN drug USING(drug_name)
WHERE total_claim_count > 3000;

/*c. Add another column to you answer from the previous part which gives the prescriber first and last name 
associated with each row.*/
SELECT 
	nppes_provider_first_name,
	nppes_provider_last_org_name,
	drug_name, 
	total_claim_count, 
	opioid_drug_flag
FROM prescription LEFT JOIN drug USING(drug_name)
				  INNER JOIN prescriber USING(npi)
WHERE total_claim_count > 3000;

/*Question 7 The goal of this exercise is to generate a full list of all pain management specialists in Nashville 
and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.*/
/*a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') 
in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). 
**Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need 
the claims numbers yet.*/
SELECT npi, drug_name
FROM prescriber CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
	  AND nppes_provider_city = 'NASHVILLE'
	  AND opioid_drug_flag = 'Y'
ORDER BY npi, drug_name;
	  
/*b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber 
had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).*/
SELECT 
	npi, 
	drug_name, 
	total_claim_count::money
FROM prescriber CROSS JOIN drug
				LEFT JOIN prescription USING(npi, drug_name)
WHERE specialty_description = 'Pain Management'
	  AND nppes_provider_city = 'NASHVILLE'
	  AND opioid_drug_flag = 'Y'
ORDER BY npi, drug_name;

/*c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. 
Hint - Google the COALESCE function.*/
SELECT 
	npi, 
	drug_name, 
	COALESCE(total_claim_count, 0)::money total_claim_count
FROM prescriber CROSS JOIN drug
				LEFT JOIN prescription USING(npi, drug_name)
WHERE specialty_description = 'Pain Management'
	  AND nppes_provider_city = 'NASHVILLE'
	  AND opioid_drug_flag = 'Y'
ORDER BY npi, drug_name;

