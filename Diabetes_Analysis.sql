-- STEP 1:Create a clean version of the data set 
CREATE OR REPLACE VIEW diabetes_clean AS 
SELECT
    pregnancies,
    glucose,
    NULLIF (bloodpressure,0) AS bloodpressure,
    NULLIF (skinthickness,0) AS skinthickness,
    NULLIF (insulin,0) AS insulin,
    NULLIF (BMI,0) AS bmi,
    diabetespedigreefunction,
    age,
    outcome
FROM diabetes_data;

-- STEP 2: Total row count
SELECT count(*) AS total_rows 
FROM diabetes_clean;

-- STEP 3: Outcome distribution
SELECT Outcome, count(*) AS count_by_outcome
FROM diabetes_clean
GROUP BY OUTCOME;

-- STEP 4: Avergae glucose, BMI, and age by outcome
SELECT
	Outcome,
    Round (AVG(Glucose),2) AS avg_glucose,
    Round(AVG(BMI),2) AS avg_bmi,
    Round (AVG(Age),2) AS avg_age
    FROM diabetes_clean
    GROUP BY OUTCOME;
    
    -- Step 5: Missing /Null value check 
SELECT
	sum(CASE WHEN Glucose is NULL THEN 1 ELSE 0 END) as null_glucose,
    sum(CASE WHEN BloodPressure is NULL THEN 1 ELSE 0 END) as null_bp,
    sum(CASE WHEN SkinThickness is NULL THEN 1 ELSE 0 END) as null_skin,
    sum(CASE WHEN Insulin is NULL THEN 1 ELSE 0 END) as null_insulin,
    sum(CASE WHEN BMI is NULL THEN 1 ELSE 0 END) as null_bmi
    FROM diabetes_clean;
    
    -- Step 6: High risk Group by Outcome(glucose>140 and BMI>30)
    SELECT
    round (avg(BMI),2) as high_risk_BMI ,
    round(avg(Glucose),2) as high_risk_glucose, 
    count(*) as high_risk_patient_count,
    OUTCOME
    FROM diabetes_clean
    WHERE BMI>30 AND GLUCOSE>140
    group by OUTCOME;

       
-- STEP 7: Total High-Risk Group and percentage  (Glucose>140 & BMI>30)
SELECT count(*) as high_risk_count,
round(100.0 * COUNT(*)/ (SELECT COUNT(*) FROM diabetes_clean),2) AS perentage_of_total
FROM diabetes_clean 
Where BMI>30 AND GLUCOSE > 140;

-- STEP 8: Glucose level Distribution
Select
CASE
	WHEN glucose <100 Then '<100'
    WHEN Glucose between 100 and 125 then '100-125'
    WHEN Glucose between 126 and 140 then '126-140'
    WHEN Glucose between 141 and 199 then '141-199'
    ELSE '200+'
END as glucose_bucket,
count(*) AS pateint_count,
round(100.00* sum(case when outcome = 1 then 1 else 0 end)/(SELECT count(*) FROM diabetes_clean),2) as diabetic_percentage
FROM diabetes_clean
Group by glucose_bucket
order by 
case 
	when glucose_bucket = '<100' THEN 1
    when glucose_bucket = '100-125' THEN 2
    when glucose_bucket = '126-140' THEN 3
    when glucose_bucket = '141-199' THEN 4
    when glucose_bucket = '200+' THEN 5
END;


-- STEP 9 Age Group vs  Outcome: Average Glucose & Blood Pressure Trends
Select
Case
WHEN Age < 30 then 'Under 30'
WHEN age between 30 and 50 then '30-50'
ELSE 'Over 50'
END AS age_group,
avg(glucose) as avg_glucose,
avg(bloodpressure) as avg_bp,
Round(100.0* Count(*)/(SELECT COUNT(*) FROM diabetes_clean),2) as percentage_of_total,
Round(100.0* SUM(CASE WHEN OUTCOME = 1 THEN 1 ELSE 0 END)/(SELECT COUNT(*) FROM diabetes_clean),2) as diabetic_percentage
FROM diabetes_clean
GROUP BY age_group
Order by 
case
	WHEN age_group = 'Under 30' Then 1
    WHEN age_group = '30-50' Then 2
    else 3
end,age_group;

-- STEP 10: Relationship between Insulin and Glucose
SELECT
outcome,
round(avg(insulin),2) as avg_insulin,
round(avg(glucose),2) as avg_glucose,
round(stddev(insulin),2) as std_insulin,
round(stddev(glucose),2) as std_glucose
from diabetes_clean
where insulin is not null and glucose is not null
Group by Outcome;

-- STEP 11:Relationship between BMI and Skin Thickness
SELECT
outcome,
ROUND(avg(BMI),2) AS avg_bmi,
ROUND(avg(skinthickness),2) as avg_skin
FROM diabetes_clean
WHERE BMI is not null and skinthickness is not null 
group by outcome;

-- Step 12 Blood Pressure vs Diabetes coutcome 
SELECT
Outcome,
Round(avg(bloodpressure),2) as avg_bp,
Round(MIN(bloodpressure),2) as min_bp,
Round(MAX(bloodpressure),2) as max_bp
From diabetes_clean
GROUP BY Outcome;

-- STEP 13: Composite Clinical Risk Index
SELECT 
CASE
	WHEN GLUCOSE >140 AND BMI>30 AND BLOODPRESSURE >80 THEN 'HIGH RISK' 
    WHEN ( GLUCOSE BETWEEN 100 AND 140) OR (BMI between 25 AND 30) THEN 'PRE-DIABETEIC RISK'
    ELSE 'LOW RISK'
END AS RISK_LEVEL,
COUNT(*) AS patient_count,
ROUND(100.00*SUM(CASE WHEN OUTCOME = 1 THEN 1 ELSE 0 END)/(SELECT COUNT(*) FROM diabetes_clean),2) as diabetic_percentage
FROM diabetes_clean
GROUP BY RISK_LEVEL;


-- STEP 14: BMI CATERGORY VS DIABETES OUTCOME
SELECT
CASE
	WHEN BMI < 18.5 THEN 'Underweight'
    WHEN BMI BETWEEN 18.5 AND 24.9 THEN 'Normal'
    WHEN BMI BETWEEN 25 and 29.9 THEN 'Overweight'
    ELSE 'Obese'
END AS BMI_Category,
COUNT(*) AS patient_count,
ROUND(100.0* sum(case when outcome = 1 then 1 else 0 end)/(select count(*) from diabetes_clean),2) as diabetic_percentage
FROM diabetes_clean
WHERE BMI IS NOT NULL 
GROUP BY BMI_CATEGORY
ORDER BY FIELD(BMI_Category, 'Underweight', 'Normal' , 'Overweight', 'Obese');
	
-- STEP 15: PREGNANCY VS DIABETIC OUTCOMES 
SELECT
CASE
	WHEN PREGNANCIES = 0 THEN 'NO PREGNANCIES'
    WHEN PREGNANCIES BETWEEN 1 AND 2 THEN 'LOW FERTILTITY'
    WHEN PREGNANCIES BETWEEN 3 AND 5 THEN 'MODERATE FERTILITY'
    WHEN PREGNANCIES >= 6 THEN 'HIGH FERTILTIY'
END AS FERTILITY_CATEGORY,
COUNT(*) as total_patients,
ROUND(AVG(GLUCOSE),2) as AVG_GLUCOSE ,
ROUND (AVG(AGE),2) AS AVG_age,
ROUND(100.0 * SUM(CASE WHEN OUTCOME = 1 THEN 1 ELSE 0 END) / COUNT(*),2) AS Diabeteic_Percentage
FROM diabetes_clean
GROUP BY FERTILITY_CATEGORY
order by
case
	when FERTILITY_CATEGORY = 'NO PREGNANCIES' THEN 1
	when FERTILITY_CATEGORY = 'LOW FERTILITY' THEN 2
	when FERTILITY_CATEGORY = 'MODERATE FERTILTIY' THEN 3
	when FERTILITY_CATEGORY = 'HIGH FERTILTIY' THEN 4
END;


