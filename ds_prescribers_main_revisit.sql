-- 1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT npi,
	   SUM(total_claim_count) AS total_claims
FROM prescription
GROUP BY npi
ORDER BY total_claims DESC
LIMIT 5;
-- provider with npi 1881634483 had 99,707 total claims, the next closest provider had just over 2/3 of that amount

--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT nppes_provider_first_name, 
	   nppes_provider_last_org_name,  
	   specialty_description,
	   SUM(total_claim_count) AS total_claims
FROM prescriber
	 INNER JOIN prescription
	 USING(npi)
GROUP BY nppes_provider_first_name, 
	   	 nppes_provider_last_org_name,
		 specialty_description,
		 npi
ORDER BY total_claims DESC
LIMIT 5;
-- Bruce Pendley who works in Family Practice

-- 2. a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT specialty_description,
	   SUM(total_claim_count) AS total_claims
FROM prescriber
	 INNER JOIN prescription
	 USING(npi)
GROUP BY specialty_description
ORDER BY total_claims DESC
LIMIT 5;
-- Family Practice with 9,752,347 claims

--     b. Which specialty had the most total number of claims for opioids?
SELECT specialty_description,
	   SUM(total_claim_count) AS total_claims
FROM prescriber
	 INNER JOIN prescription
	 USING(npi)
	 INNER JOIN drug
	 USING(drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY total_claims DESC
LIMIT 5;
-- Nurse Practitioners with 900,845 (Family Practice is 2nd with just over half that amount)
-- Tomo pointed out that there are instances when a drug_name has multiple associated generic_names
SELECT drug_name,
	   COUNT(generic_name)
FROM drug
--WHERE antibiotic_drug_flag = 'Y'
GROUP BY drug_name
HAVING COUNT(generic_name) > 1;

SELECT drug_name,
	   generic_name
FROM drug
WHERE drug_name = 'METRONIDAZOLE';
--Then we looked at whether this messed with the opioids
SELECT drug_name
FROM drug
GROUP BY drug_name
HAVING COUNT(DISTINCT opioid_drug_flag) = 2;
-- And for 5 drugs, it does! NO GOOD!
SELECT *
FROM drug
WHERE drug_name ILIKE '%cod%'
	OR generic_name ILIKE '%cod%'
ORDER BY generic_name;
-- All the opioids with multiple generic names, only one is flagged as an opioid
SELECT drug_name
FROM drug
WHERE opioid_drug_flag = 'Y'
GROUP BY drug_name
HAVING COUNT(generic_name) > 1;

SELECT *
FROM prescription
	 INNER JOIN drug
	 USING(drug_name)
WHERE drug_name ILIKE '%INFUMORPH%';


SELECT specialty_description, 
		SUM(total_claim_count) AS total_claims
FROM prescription 
	 INNER JOIN prescriber
	 USING(npi)
	 INNER JOIN (SELECT DISTINCT drug_name,
				 		opioid_drug_flag
				 FROM drug) AS sub
	 USING(drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY total_claims DESC;


--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT specialty_description
FROM prescriber
	 LEFT JOIN prescription
	 USING(npi)
GROUP BY specialty_description
HAVING SUM(total_claim_count) IS NULL;
-- Yes, there are 15 such specialties, none of which appear to be professionals who are allowed to prescribe drugs

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
SELECT specialty_description,
	   SUM(total_claim_count) AS total_claims,
	   COALESCE(SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count END),0) AS total_opioid_claims,
	   COALESCE(ROUND(SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count END) * 100.0 / SUM(total_claim_count), 2), 0) AS percent_opioid_claims
FROM prescriber
	 INNER JOIN prescription
	 USING(npi)
	 INNER JOIN (SELECT DISTINCT drug_name, opioid_drug_flag FROM drug) AS d_drug
	 USING(drug_name)
GROUP BY specialty_description
ORDER BY percent_opioid_claims DESC;
-- Case Manager/Care Coordinator (very low total # of claims),Orthopaedic Surgery (low total # of claims), Interventional Pain Managment, Anesthesiology, Pain Management, Hand Surgery, Surgical Oncology are all over 50%
SELECT p1.specialty_description,
	   opioid_claim.opioid_claim_count,
	   SUM(p2.total_claim_count),
	   ROUND(( opioid_claim.opioid_claim_count / SUM(p2.total_claim_count)) * 100, 2) AS opioid_claim_percentage	  
FROM prescriber AS p1
	 INNER JOIN prescription AS p2
	 USING(npi)
	 INNER JOIN
				(SELECT DISTINCT(p1.specialty_description)
	   				   ,SUM(p2.total_claim_count) AS opioid_claim_count
 				 FROM prescriber AS p1
	  			 INNER JOIN prescription AS p2
	  			 USING(npi)
				 INNER JOIN drug
				 USING(drug_name)
 				 WHERE opioid_drug_flag = 'Y'
 				 GROUP BY p1.specialty_description) AS opioid_claim				 
	 USING(specialty_description) 
GROUP BY p1.specialty_description, opioid_claim.opioid_claim_count
ORDER BY opioid_claim_percentage DESC;

SELECT prvdr.specialty_description,
	SUM(CASE WHEN prscrpt.drug_name IN (SELECT drug_name
										FROM drug
										WHERE opioid_drug_flag = 'Y') --summing the opioids 
	THEN prscrpt.total_claim_count END) AS opioid_prescriptions,
	SUM(prscrpt.total_claim_count) AS total_specialty_claims, --summing the total claims per specialty
	ROUND((SUM(CASE WHEN prscrpt.drug_name IN (SELECT drug_name
											   FROM drug
											   WHERE opioid_drug_flag = 'Y') --mashing the last 2 together and getting the %
	THEN prscrpt.total_claim_count END) / SUM(prscrpt.total_claim_count)) * 100,2) AS opioid_prescription_percentage
FROM prescription AS prscrpt
INNER JOIN prescriber AS prvdr
	USING (npi)
GROUP BY prvdr.specialty_description
ORDER BY opioid_prescription_percentage DESC NULLS LAST;

SELECT *
FROM prescription
WHERE drug_name IN (SELECT drug_name
				    FROM drug
				    WHERE opioid_drug_flag = 'Y');
					
SELECT *
FROM prescription
INNER JOIN drug
USING(drug_name)
WHERE opioid_drug_flag = 'Y';


-- 3. a. Which drug (generic_name) had the highest total drug cost?
SELECT generic_name,
	   SUM(total_drug_cost)::money AS total_cost
FROM prescription
	 INNER JOIN drug
	 USING (drug_name)
GROUP BY generic_name
ORDER BY total_cost DESC
LIMIT 5;
-- INSULIN GLARGINE,HUM.REC.ANLOG has the highest total cost $104,264,066.35


--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.
SELECT generic_name,
	   ROUND(SUM(total_drug_cost) * 100 / SUM(total_day_supply), 2)::money AS cost_per_day
FROM prescription
	 INNER JOIN drug
	 --(SELECT DISTINCT drug_name, generic_name FROM drug) AS d_drug
	 USING(drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC
LIMIT 5;
--C1 ESTERASE INHIBITOR has the highest cost per day at $349,521.90

-- 4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT drug_name,
	   CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	   		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ELSE 'neither' END AS drug_type
FROM drug;

--Michael referenced you could also use UNION, so I looked at it
(SELECT drug_name,
	   'opioid' AS type
FROM drug
WHERE opioid_drug_flag = 'Y')
UNION
(SELECT drug_name,
	   'antibiotic' AS type
FROM drug
WHERE antibiotic_drug_flag = 'Y')
UNION
(SELECT drug_name,
	   'neither' AS type
FROM drug
WHERE opioid_drug_flag = 'N'
 	AND antibiotic_drug_flag = 'N');
--The UNION, as opposed to UNION ALL eliminates, the duplicates that exist within each of these queries because of the multiple generic names for some drug names, so this is like adding in 'DISTINCT' to my original query

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_drug_cost END)::money AS opioid_cost,
	   SUM(CASE WHEN antibiotic_drug_flag = 'Y' THEN total_drug_cost END)::money AS antibiotic_cost
FROM drug
	 INNER JOIN prescription
	 USING(drug_name);
-- Significantly more was spent on opioids $105,080,626.37 vs. $38,435,121.26
-- addressing the multiple rows for some drug_name values
SELECT SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_drug_cost END)::money AS opioid_cost,
	   SUM(CASE WHEN antibiotic_drug_flag = 'Y' THEN total_drug_cost END)::money AS antibiotic_cost
FROM (SELECT DISTINCT drug_name,
				 		opioid_drug_flag,
	  					antibiotic_drug_flag
		FROM drug
	 WHERE opioid_drug_flag = 'Y'
	 	OR antibiotic_drug_flag = 'Y') AS sub
	 INNER JOIN prescription
	 USING(drug_name); 
-- this drops the total for antibiotics to $34,972,135.84, indicating that there are antibiotics in the list that have multiple generic names for a given drug name, and both are flagged as antibiotics

SELECT  SUM(total_drug_cost)::money,
		(CASE
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 WHEN opioid_drug_flag='Y' THEN 'opioid'
		 ELSE 'neither' END)
FROM drug INNER JOIN prescription USING  (drug_name)
GROUP BY opioid_drug_flag,antibiotic_drug_flag;

-- 5. a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT(DISTINCT cbsaname)
FROM cbsa
	 INNER JOIN fips_county
	 USING(fipscounty)
WHERE cbsaname LIKE '%TN%';
--10
	 
--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT cbsaname,
	   SUM(population) AS cbsa_pop
FROM cbsa
	 INNER JOIN fips_county
	 USING(fipscounty)
	 INNER JOIN population
	 USING(fipscounty)
WHERE cbsaname = 	(SELECT cbsaname
					FROM cbsa
						 INNER JOIN fips_county
						 USING(fipscounty)
						 INNER JOIN population
						 USING(fipscounty)
					WHERE state = 'TN'
					GROUP BY cbsaname
					ORDER BY SUM(population) DESC
					LIMIT 1)
	OR cbsaname =	(SELECT cbsaname
					FROM cbsa
						 INNER JOIN fips_county
						 USING(fipscounty)
						 INNER JOIN population
						 USING(fipscounty)
					WHERE state = 'TN'
					GROUP BY cbsaname
					ORDER BY SUM(population)
					LIMIT 1)
GROUP BY cbsaname
ORDER BY cbsa_pop DESC;
--with UNION
(SELECT cbsaname,
 		SUM(population) AS cbsa_pop,
 		'smallest' AS status
FROM cbsa
	 INNER JOIN fips_county
	 USING(fipscounty)
	 INNER JOIN population
	 USING(fipscounty)
WHERE state = 'TN'
GROUP BY cbsaname
ORDER BY SUM(population)
LIMIT 1)
UNION
(SELECT cbsaname,
 		SUM(population) AS cbsa_pop,
 		'largest' AS status
FROM cbsa
	 INNER JOIN fips_county
	 USING(fipscounty)
	 INNER JOIN population
	 USING(fipscounty)
WHERE state = 'TN'
GROUP BY cbsaname
ORDER BY SUM(population) DESC
LIMIT 1);

--Nashville-Davidson--Murfreesboro--Franklin, TN is the largest, Morristown, TN is the smallest

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT county,
	   population
FROM cbsa
	 FULL JOIN fips_county
	 USING(fipscounty)
	 INNER JOIN population
	 USING(fipscounty)
WHERE state = 'TN'
	AND cbsa IS NULL
ORDER BY population DESC;
-- Sevier county with 95,523

-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name,
	   total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT drug_name,
	   total_claim_count,
	   opioid_drug_flag
FROM prescription
	 INNER JOIN drug
	 USING(drug_name)
WHERE total_claim_count >= 3000;

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT drug_name,
	   total_claim_count,
	   opioid_drug_flag,
	   nppes_provider_first_name, 
	   nppes_provider_last_org_name,
	   specialty_description
FROM prescription
	 INNER JOIN drug
	 USING(drug_name)
	 INNER JOIN prescriber
	 USING(npi)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.
--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT npi,
	   drug_name
FROM prescriber
	 CROSS JOIN drug --(SELECT DISTINCT drug_name FROM drug WHERE opioid_drug_flag = 'Y') AS d_drug
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
ORDER BY npi;

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
WITH cross_j AS	(SELECT npi,
					   drug_name
				FROM prescriber
					 CROSS JOIN drug
				WHERE specialty_description = 'Pain Management'
					AND nppes_provider_city = 'NASHVILLE'
					AND opioid_drug_flag = 'Y'
				ORDER BY npi)
SELECT npi,
	   drug_name,
	   total_claim_count AS total_claims
FROM cross_j 
	 LEFT JOIN prescription
	 USING(npi, drug_name);
--Exploring FULL JOIN weirdness
WITH cross_j AS	(SELECT npi,
					   drug_name,
				 	   specialty_description,
					   nppes_provider_city,
				 	   opioid_drug_flag
				FROM prescriber
					 CROSS JOIN drug
				WHERE specialty_description = 'Pain Management'
					AND nppes_provider_city = 'NASHVILLE'
					AND opioid_drug_flag = 'Y'
				ORDER BY npi)
SELECT npi,
	   drug_name,
	   specialty_description,
	   nppes_provider_city,
	   opioid_drug_flag,
	   total_claim_count AS total_claims
FROM cross_j 
	 FULL JOIN prescription
	 USING(npi, drug_name)
WHERE specialty_description = 'Pain Management'
					AND nppes_provider_city = 'NASHVILLE'
					AND opioid_drug_flag = 'Y';
	 
SELECT npi,
	   drug.drug_name,
	   total_claim_count AS total_claims
FROM prescriber
	 CROSS JOIN drug 
	 FULL JOIN prescription
	 USING(npi, drug_name)
WHERE specialty_description = 'Pain Management'
					AND nppes_provider_city = 'NASHVILLE'
					AND opioid_drug_flag = 'Y';

--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
WITH cross_j AS	(SELECT npi,
	   nppes_provider_first_name, 
	   nppes_provider_last_org_name,
					   drug_name
				FROM prescriber
					 CROSS JOIN drug
				WHERE specialty_description = 'Pain Management'
					AND nppes_provider_city = 'NASHVILLE'
					AND opioid_drug_flag = 'Y'
				ORDER BY npi)
SELECT npi,
	   nppes_provider_first_name, 
	   nppes_provider_last_org_name,
	   drug_name,
	   COALESCE(total_claim_count, 0) AS total_claims
FROM cross_j 
	 LEFT JOIN prescription
	 USING(npi, drug_name)
ORDER BY total_claims DESC;