/*
In this set of exercises you are going to explore additional ways to group and organize the output of a query when using postgres.

For the first few exercises, we are going to compare the total number of claims from Interventional Pain Management Specialists 
compared to those from Pain Management specialists.
*/

------------------------------------------------------------------------------------------ 1
/*

1. Write a query which returns the total number of claims for these two groups. 
Your output should look like this: 

specialty_description         |total_claims|
------------------------------|------------|
Interventional Pain Management|       55906|
Pain Management               |       70853|

*/

SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY specialty_description;

------------------------------------------------------------------------------------------ 2
/*

2. Now, let's say that we want our output to also include 
the total number of claims between these two groups. 
Combine two queries with the UNION keyword to accomplish this. 
Your output should look like this:

specialty_description         |total_claims|
------------------------------|------------|
                              |      126759|
Interventional Pain Management|       55906|
Pain Management               |       70853|

*/


(SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY specialty_description)
UNION
(SELECT '' AS specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management'))
ORDER BY specialty_description;


------------------------------------------------------------------------------------------ 3
/*

3. Now, instead of using UNION, make use of GROUPING SETS 
(https://www.postgresql.org/docs/10/queries-table-expressions.html#QUERIES-GROUPING-SETS) 
to achieve the same output.

*/

SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY GROUPING SETS (specialty_description, ());

------------------------------------------------------------------------------------------ 4
/*

4. In addition to comparing the total number of prescriptions by specialty, 
   let's also bring in information about the number of opioid vs. non-opioid 
   claims by these two specialties. Modify your query (still making use of GROUPING SETS 
   so that your output also shows the total number of opioid claims vs. non-opioid claims
   by these two specialites:

specialty_description         |opioid_drug_flag|total_claims|
------------------------------|----------------|------------|
                              |                |      129726|
                              |Y               |       76143|
                              |N               |       53583|
Pain Management               |                |       72487|
Interventional Pain Management|                |       57239|

*/

SELECT 
	specialty_description, 
	opioid_drug_flag, 
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
	USING (npi)
INNER JOIN drug
	USING (drug_name)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY GROUPING SETS (specialty_description, opioid_drug_flag, ())
ORDER BY specialty_description DESC, opioid_drug_flag DESC;

------------------------------------------------------------------------------------------ 5
/*

5. Modify your query by replacing the GROUPING SETS with 
   ROLLUP(opioid_drug_flag, specialty_description). 
   How is the result different from the output from the previous query?

*/

SELECT 
	specialty_description, 
	opioid_drug_flag, 
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
	USING (npi)
INNER JOIN drug
	USING (drug_name)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY ROLLUP (opioid_drug_flag, specialty_description)
ORDER BY specialty_description DESC, opioid_drug_flag DESC;

/*
This result adds each possible pairing of specialty_description with opioid_drug_flag,
but it does not include rows for the specialty_desciptions by themselves.
*/

------------------------------------------------------------------------------------------ 6
/*

6. Switch the order of the variables inside the ROLLUP. That is, use ROLLUP(specialty_description, opioid_drug_flag). How does this change the result?

*/

SELECT 
	specialty_description, 
	opioid_drug_flag, 
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
	USING (npi)
INNER JOIN drug
	USING (drug_name)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY ROLLUP (specialty_description, opioid_drug_flag)
ORDER BY specialty_description DESC, opioid_drug_flag DESC;

/*
Now we have each possible pairing, the specialty descriptions by themselves instead of 
the opioid drug flags, and we still have the overall total claims.
*/
------------------------------------------------------------------------------------------ 7
/*

7. Finally, change your query to use the CUBE function instead of ROLLUP. How does this impact the output?

*/

SELECT 
	specialty_description, 
	opioid_drug_flag, 
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
	USING (npi)
INNER JOIN drug
	USING (drug_name)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY CUBE (specialty_description, opioid_drug_flag)
ORDER BY specialty_description DESC, opioid_drug_flag DESC;

/*
We now have each possible pairing and each possible solo group for both variables, as
well as the overall, ungrouped total_claims.
*/

------------------------------------------------------------------------------------------ 8
/*
8. In this question, your goal is to create a pivot table showing for each of 
  the 4 largest cities in Tennessee (Nashville, Memphis, Knoxville, and Chattanooga), 
  the total claim count for each of six common types of opioids: 
  Hydrocodone, Oxycodone, Oxymorphone, Morphine, Codeine, and Fentanyl. 
  For the purpose of this question, we will put a drug into one of the 
  six listed categories if it has the category name as part of its generic name. 
  For example, we could count both of "ACETAMINOPHEN WITH CODEINE" and "CODEINE SULFATE"
  as being "CODEINE" for the purposes of this question.

The end result of this question should be a table formatted like this:

city       |codeine|fentanyl|hyrdocodone|morphine|oxycodone|oxymorphone|
-----------|-------|--------|-----------|--------|---------|-----------|
CHATTANOOGA|   1323|    3689|      68315|   12126|    49519|       1317|
KNOXVILLE  |   2744|    4811|      78529|   20946|    84730|       9186|
MEMPHIS    |   4697|    3666|      68036|    4898|    38295|        189|
NASHVILLE  |   2043|    6119|      88669|   13572|    62859|       1261|

For this question, you should look into use the crosstab function, which is part of the tablefunc extension (https://www.postgresql.org/docs/9.5/tablefunc.html). In order to use this function, you must (one time per database) run the command
	CREATE EXTENSION tablefunc;

Hint #1: First write a query which will label each drug in the drug table using the six categories listed above.
Hint #2: In order to use the crosstab function, you need to first write a query which will produce a table with one row_name column, one category column, and one value column. So in this case, you need to have a city column, a drug label column, and a total claim count column.
Hint #3: The sql statement that goes inside of crosstab must be surrounded by single quotes. If the query that you are using also uses single quotes, you'll need to escape them by turning them into double-single quotes.
*/

-- Create Extension

CREATE EXTENSION tablefunc;

-- Version with $$ (cleaner)
-- Output doesn't perfectly match Michael's

SELECT *
FROM 
CROSSTAB(
	$$SELECT 
		nppes_provider_city AS city,
		CASE WHEN drug_name ILIKE '%hydrocodone%' THEN 'hydrocodone' 
			 WHEN drug_name ILIKE '%oxycodone%' THEN 'oxycodone'
			 WHEN drug_name ILIKE '%oxymorphone%' THEN 'oxymorphone'
			 WHEN drug_name ILIKE '%morphine%' THEN 'morphine'
			 WHEN drug_name ILIKE '%codeine%' THEN 'codeine'
			 WHEN drug_name ILIKE '%fentanyl%' THEN 'fentanyl' END AS opioid_type,
		SUM(total_claim_count) AS total_claims
	FROM prescriber
	NATURAL JOIN prescription
	NATURAL JOIN drug
	WHERE nppes_provider_city IN ('NASHVILLE', 'MEMPHIS', 'KNOXVILLE', 'CHATTANOOGA')
	GROUP BY nppes_provider_city,
			CASE WHEN drug_name ILIKE '%hydrocodone%' THEN 'hydrocodone' 
				 WHEN drug_name ILIKE '%oxycodone%' THEN 'oxycodone'
				 WHEN drug_name ILIKE '%oxymorphone%' THEN 'oxymorphone'
				 WHEN drug_name ILIKE '%morphine%' THEN 'morphine'
				 WHEN drug_name ILIKE '%codeine%' THEN 'codeine'
				 WHEN drug_name ILIKE '%fentanyl%' THEN 'fentanyl' END
	ORDER BY city, opioid_type$$
	) AS ct(city text,
			codeine numeric, 
			fentanyl numeric, 
			hydrocodone numeric, 
			morphine numeric, 
			oxycodone numeric,
			oxymorphone numeric)

-- Cleaned up for readability, replaced drug_name with generic_name

SELECT *
FROM 
CROSSTAB(
	$$WITH city_special_ops AS (
		SELECT 
			nppes_provider_city AS city,
			CASE WHEN generic_name ILIKE '%hydrocodone%' THEN 'hydrocodone' 
				 WHEN generic_name ILIKE '%oxycodone%' THEN 'oxycodone'
				 WHEN generic_name ILIKE '%oxymorphone%' THEN 'oxymorphone'
				 WHEN generic_name ILIKE '%morphine%' THEN 'morphine'
				 WHEN generic_name ILIKE '%codeine%' THEN 'codeine'
				 WHEN generic_name ILIKE '%fentanyl%' THEN 'fentanyl' END AS opioid_type,
			total_claim_count
		FROM prescriber
		NATURAL JOIN prescription
		NATURAL JOIN drug
		WHERE nppes_provider_city IN ('NASHVILLE', 'MEMPHIS', 'KNOXVILLE', 'CHATTANOOGA')

	)
	SELECT 
		city,
		opioid_type,
		SUM(total_claim_count) AS total_claims
	FROM city_special_ops
	WHERE opioid_type IS NOT NULL
	GROUP BY city, opioid_type
	ORDER BY city, opioid_type
	$$
	) AS ct(city text,
			codeine numeric, 
			fentanyl numeric, 
			hydrocodone numeric, 
			morphine numeric, 
			oxycodone numeric,
			oxymorphone numeric);