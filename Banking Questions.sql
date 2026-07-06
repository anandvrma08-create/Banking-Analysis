CREATE DATABASE IF NOT EXISTS banking;
use banking;

ALTER TABLE `banking_clean.csv`
RENAME TO banking_clean;
--  (We Dropped 77 Rows In Cleaning)



-- Identify the top 10 customers with the highest total bank deposits.
-- Business use: VIP customer identification and wealth-management targeting.
    SELECT `Clinet ID`,SUM(`Bank Deposits`) as total_deposit
     from banking_clean GROUP BY `Clinet ID` order by 2 DESC limit 5;

--How many unique customers currently maintain a zero bank deposit balance?
SELECT count(DISTINCT `Clinet ID`) as zero_deposit 
from banking_clean where `Bank Deposits`=0 ;

-- Find the  customer age segments contributing the highest percentage of total deposits.
-- Business use: Find the bank’s most valuable age segments.
    SELECT `Age Category`,round(SUM(`Bank Deposits`),2) as Deposit,
    round((SUM(`Bank Deposits`)*100)/(SELECT SUM(`Bank Deposits`) from banking_clean) ,2) as `% Contribution`
    FROM banking_clean 
    GROUP BY `Age Category` ORDER BY 2 DESC; 
    -- (Senior Citizen COntributes nearly 50 % of Deposits and
    -- underage and young people contributes nearly 2.5% each)


-- Identify customers whose bank deposits are at least 50% higher than the average deposit.
-- Business use: Find high-value customers using a meaningful benchmark.
    SELECT `Clinet ID`,SUM(`Bank Deposits`) as deposit,
    (select round(AVG(`Bank Deposits`),2) from banking_clean) as avg_bank_deposit 
    FROM banking_clean
    GROUP BY `Clinet ID`
    HAVING deposit>((SELECT AVG(`Bank Deposits`) from banking_clean)*0.5)
    order by 2;

-- Identify the top 10 customers with the highest total credit exposure.
-- Business use: Credit-risk monitoring and exposure concentration.
    SELECT `Clinet ID`,`Name`,`Nationality` ,
    round(SUM(`Credit Card Balance`)+SUM(`Bank Loans`)+SUM(`Business Lending`),2) as `Total_Credit_Exposure`
     FROM banking_clean GROUP BY `Clinet ID`,`Name`,`Nationality`  limit 10 ;

-- Find customers whose total loans exceed 60% of their bank deposits.
-- Business use: Identify potentially high-leverage customer relationships.
    SELECT `Clinet ID`,`Name`,
    SUM(`Bank Deposits`) as deposit,sum(`Bank Loans`) as loan 
    FROM banking_clean GROUP BY `Clinet ID`,`Name` HAVING loan > deposit*0.6;

-- Find the top 5 occupations with the highest average income but below-average bank deposits.
-- Business use: Identify high-income segments with untapped deposit potential.
 SELECT `Occupation`,AVG(`Estimated Income`) as avg_income,
 AVG(`Bank Deposits`) as deposit,
 (SELECT AVG(`Bank Loans`) FROM banking_clean) as avg_bank_loan
 FROM banking_clean GROUP BY `Occupation` 
 HAVING AVG(`Bank Deposits`) < (SELECT AVG(`Bank Deposits`) FROM banking_clean)
 ORDER BY 2 DESC LIMIT 5;

-- Identify customers in the top 20% by income but, below the overall bank average deposits.
-- Business use: Excellent cross-selling and deposit-conversion problem.
    WITH income_20 as(
    SELECT `Clinet ID`,`Name`,SUM(`Estimated Income`),SUM(`Bank Deposits`) as dep,
    NTILE(5) OVER(ORDER BY SUM(`Estimated Income`) DESC) as rnk
    FROM banking_clean 
    GROUP BY `Clinet ID`,`Name` )
    SELECT * from income_20 
    where rnk=1 and dep <(SELECT AVG(`Bank Deposits`) FROM banking_clean
    order by SUM(`Estimated Income`))


-- Find the top 10 customers with the largest gap between estimated income and bank deposits.
-- Business use: Detect customers whose financial potential is underutilized.
    SELECT `Name`,`Estimated Income`,`Bank Deposits`,
    `Estimated Income`-`Bank Deposits` as In_dep_Diff
     FROM banking_clean ORDER BY 4 DESC; 


-- Determine what percentage of total deposits is controlled by the top 10% of customers.
-- Business use: Deposit concentration risk.
    SELECT ROUND(
        ((select 
    sum(deposit) from
    (SELECT `Bank Deposits` as deposit,
    NTILE(10) OVER(order by `Estimated Income` DESC) as rnk
    FROM banking_clean)t
    where rnk=1) * 100)
    /(SELECT SUM(`Estimated Income`) FROM banking_clean)
    ,2) ;
 -- select 
 -- sum(income) from
 -- (SELECT `Estimated Income` as income,
 -- NTILE(10) OVER(order by `Estimated Income` DESC) as rnk
 -- FROM banking_clean)t
 -- where rnk=1;      NUMERATOR

-- Identify the smallest number of customers responsible for 50% of total bank deposits.
-- Business use: Shows dependency on high-value customers using cumulative totals.
    
     SELECT count(*) FROM
    (SELECT `Clinet ID`,`Name`, `Bank Deposits` , 
    ROUND(SUM(`Bank Deposits`) OVER(ORDER BY `Bank Deposits` DESC),2) running_deposit
     from banking_clean )t 
    where (running_deposit < (SELECT SUM(`Bank Deposits`) FROM banking_clean) *0.5) 
    or 
    (running_deposit = (SELECT SUM(`Bank Deposits`) FROM banking_clean) *0.5)

-- Rank the top 3 nationalities by average deposits within each income category.
-- Business use: Multi-dimensional customer segmentation.
    SELECT `Nationality`,`Income Category`,AVG(`Bank Deposits`),AVG(`Estimated Income`) 
    FROM banking_clean GROUP BY `Nationality`,`Income Category`order by 1,3 desc limit 10;

-- Find customer age segments where average credit-card balance exceeds 25% of average income.
-- Business use: Highlights age segments with relatively high revolving credit exposure.

    SELECT `Age Category`,avg(`Estimated Income`) avg_income,AVG(`Credit Card Balance`) avg_cc_balance
    from banking_clean GROUP BY `Age Category`
    HAVING AVG(`Credit Card Balance`) > AVG(`Estimated Income`) *0.25;
        --  NO AGE CATEGORY FALLS INTO THIS QUESTION (NULL TABLE)


-- Rank each customer within their income category and return the top 5 by deposits.
-- Business use: Finds high-value customers relative to similar peers.
    SELECT * FROM
    (SELECT `Clinet ID`,`Name`,`Age Category`,`Bank Deposits`,
        ROW_NUMBER() OVER(PARTITION BY `Age Category` ORDER BY `Bank Deposits` DESC) as rnk   
     FROM banking_clean )t 
     WHERE rnk <=5 ;

-- Identify customer income segments contributing at least 10% of total deposits but less than 5% of total loans.
-- Business use: Finds underpenetrated lending opportunities among valuable deposit segments.   

    SELECT `Income Category` AS customer_segment,
ROUND(SUM(`Bank Deposits`) * 100.0 / SUM(SUM(`Bank Deposits`)) OVER (), 2) AS deposit_percentage,

ROUND(SUM(`Bank Loans` +`Business Lending` + `Credit Card Balance`) * 100.0/ 
SUM(SUM(`Bank Loans` + `Business Lending` + `Credit Card Balance`)) OVER (),2) AS loan_percentage
FROM banking_clean GROUP BY `Income Category`
HAVING SUM(`Bank Deposits`) * 100.0 / SUM(SUM(`Bank Deposits`)) OVER () >= 10 
AND
    SUM(`Bank Loans`+ `Business Lending` + `Credit Card Balance`) * 100.0
/ SUM(SUM(`Bank Loans` + `Business Lending` + `Credit Card Balance`)) OVER () < 5;
