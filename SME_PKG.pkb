CREATE OR REPLACE PACKAGE STG.SME_PKG AS

PROCEDURE LOADING_INTO_STG;

PROCEDURE LOADING_INTO_ADB;

PROCEDURE DELETE_AND_LOAD_INTO_PDB;

PROCEDURE DELETE_STAGING_TABLE;

PROCEDURE LOAD_ALL ;

END SME_PKG ;

CREATE OR REPLACE PACKAGE BODY STG.SME_PKG AS

PROCEDURE LOAD_ALL IS
BEGIN

DELETE_STAGING_TABLE;
LOADING_INTO_STG;
LOADING_INTO_ADB;
DELETE_AND_LOAD_INTO_PDB;
DELETE_STAGING_TABLE;




END LOAD_ALL;


PROCEDURE DELETE_STAGING_TABLE
IS
BEGIN


DELETE FROM STG.ORDERS;
COMMIT; 

DELETE FROM STG.CUSTOMERS;
COMMIT; 

DELETE FROM STG.PRODUCTS;
COMMIT; 

DELETE FROM STG.PRODUCTS_CUSTOMERS;
COMMIT; 

DELETE FROM STG.PRODUCTS_ORDERS;
COMMIT; 


END DELETE_STAGING_TABLE;

PROCEDURE DELETE_AND_LOAD_INTO_PDB
IS
BEGIN

------------------------DELETE PDB PRODUCTS_ORDERS------------------------ 
DELETE FROM PDB.PRODUCTS_ORDERS A WHERE EXISTS (
SELECT 1 FROM STG.PRODUCTS_ORDERS B
WHERE A.PROD_ORD_ID = B.PROD_ORD_ID
);
COMMIT;

------------------------DELETE PDB PRODUCTS_CUSTOMERS------------------------ 
DELETE FROM PDB.PRODUCTS_CUSTOMERS A WHERE EXISTS (
SELECT 1 FROM STG.PRODUCTS_CUSTOMERS B
WHERE A.PRODUCT_ID = B.PRODUCT_ID AND A.CUSTOMER_ID = B.CUSTOMER_ID
);
COMMIT;

------------------------DELETE PDB CUSTOMERS------------------------ 
DELETE FROM PDB.CUSTOMERS A WHERE EXISTS (
SELECT 1 FROM STG.CUSTOMERS B
WHERE A.CUSTOMER_ID = B.CUSTOMER_ID
);
COMMIT;

------------------------DELETE PDB PRODUCTS------------------------ 
DELETE FROM PDB.PRODUCTS A WHERE EXISTS (
SELECT 1 FROM STG.PRODUCTS B
WHERE A.PRODUCT_ID = B.PRODUCT_ID
);
COMMIT;


------------------------DELETE PDB ORDERS------------------------ 

DELETE FROM PDB.ORDERS A WHERE EXISTS (
SELECT 1 FROM STG.ORDERS B
WHERE A.ORDER_ID = B.ORDER_ID
);
COMMIT;    

------------------------INSERT PDB PRODUCTS------------------------ 
INSERT INTO PDB.PRODUCTS
SELECT * FROM STG.PRODUCTS;
COMMIT;

------------------------INSERT PDB CUSTOMERS------------------------ 
INSERT INTO PDB.CUSTOMERS
SELECT * FROM STG.CUSTOMERS;
COMMIT;


------------------------INSERT PDB ORDERS------------------------ 
INSERT INTO PDB.ORDERS
SELECT * FROM STG.ORDERS;
COMMIT;

------------------------INSERT PDB PRODUCTS_ORDERS------------------------ 
INSERT INTO PDB.PRODUCTS_ORDERS
SELECT DISTINCT A.* 
FROM STG.PRODUCTS_ORDERS A;
COMMIT;

------------------------INSERT PDB PRODUCTS_CUSTOMERS------------------------ 
INSERT INTO PDB.PRODUCTS_CUSTOMERS
SELECT  DISTINCT A.* 
  FROM STG.PRODUCTS_CUSTOMERS A;
COMMIT;


END DELETE_AND_LOAD_INTO_PDB;

PROCEDURE LOADING_INTO_ADB
IS

BEGIN


------------------------LOAD ADB ORDERS------------------------ 
  INSERT INTO ADB.ORDERS
SELECT A.* , SYSDATE FROM PDB.ORDERS A
WHERE EXISTS (
SELECT 1 FROM STG.ORDERS B
WHERE A.ORDER_ID = B.ORDER_ID
);
COMMIT;


------------------------LOAD ADB PRODUCTS------------------------ 
INSERT INTO ADB.PRODUCTS
SELECT A.* , TO_DATE(SYSDATE) FROM PDB.PRODUCTS A
WHERE EXISTS (
SELECT 1 FROM STG.PRODUCTS B
WHERE A.PRODUCT_ID = B.PRODUCT_ID
);
COMMIT;

------------------------LOAD ADB CUSTOMERS------------------------ 
INSERT INTO ADB.CUSTOMERS
SELECT A.* , TO_DATE(SYSDATE) FROM PDB.CUSTOMERS A
WHERE EXISTS (
SELECT 1 FROM STG.CUSTOMERS B
WHERE A.CUSTOMER_ID = B.CUSTOMER_ID
);
COMMIT;



END LOADING_INTO_ADB;


 PROCEDURE LOADING_INTO_STG
IS

BEGIN


------------------------LOAD STG PRODUCTS_ORDERS------------------------ 
--INSERT INTO STG.PRODUCTS_ORDERS
--SELECT NVL(PROD_ORD_ID , STG.PROD_ORD_SEQ.NEXTVAL) , A.PRODUCT_ID, A.ORDER_ID, 
--   A.SALES, A.QUANTITY, A.DISCOUNT, 
--   A.PROFIT, TO_DATE(SYSDATE) LOAD_DATE   
--  FROM STG.ORDERS_FILES A
--  LEFT JOIN PDB.PRODUCTS_ORDERS B ON A.PRODUCT_ID = B.PRODUCT_ID AND A.ORDER_ID = B.ORDER_ID;
--COMMIT;
INSERT INTO STG.PRODUCTS_ORDERS
SELECT NVL(PROD_ORD_ID , STG.PROD_ORD_SEQ.NEXTVAL) , PRODUCT_ID, ORDER_ID, 
   SALES, QUANTITY, DISCOUNT, 
   PROFIT, SYSDATE LOAD_DATE FROM   
 (  select   B.PROD_ORD_ID, A.PRODUCT_ID, A.ORDER_ID, 
   A.SALES, A.QUANTITY, A.DISCOUNT, A.PROFIT, B.LOAD_DATE
  FROM STG.ORDERS_FILES A
  LEFT JOIN STG.PRODUCTS_ORDERS B ON A.PRODUCT_ID = B.PRODUCT_ID AND A.ORDER_ID = B.ORDER_ID
  AND A.SALES = B.SALES AND A.QUANTITY = B.QUANTITY AND A.DISCOUNT = B.DISCOUNT
  AND A.PROFIT = B.PROFIT
 group by B.PROD_ORD_ID, A.PRODUCT_ID, A.ORDER_ID, 
   A.SALES, A.QUANTITY, A.DISCOUNT, A.PROFIT, B.LOAD_DATE
)
;COMMIT;

------------------------LOAD STG PRODUCTS_CUSTOMERS------------------------ 
INSERT INTO STG.PRODUCTS_CUSTOMERS
SELECT DISTINCT A.PRODUCT_ID, A.CUSTOMER_ID , TO_DATE(SYSDATE)
  FROM STG.ORDERS_FILES A;
COMMIT;

------------------------LOAD STG ORDERS------------------------
INSERT INTO STG.ORDERS
SELECT DISTINCT ORDER_ID,
case  
WHEN  MONTH_ORDER_DATE > 12 AND LENGTH(DAY_ORDER_DATE) < 4
 THEN  TO_DATE(MONTH_ORDER_DATE || '/' || DAY_ORDER_DATE  || '/' || YEAR_ORDER_DATE ,'DD/MM/YYYY')
WHEN LENGTH(DAY_ORDER_DATE) > 2 AND LENGTH(YEAR_ORDER_DATE) <4 
    THEN TO_DATE(YEAR_ORDER_DATE || '/' || MONTH_ORDER_DATE  || '/' || DAY_ORDER_DATE ,'DD/MM/YYYY')
ELSE  TO_DATE(DAY_ORDER_DATE || '/' || MONTH_ORDER_DATE || '/' || YEAR_ORDER_DATE ,'DD/MM/YYYY')
END  ORDER_DATE_FORMATED  ,
case  
WHEN  MONTH_SHIP_DATE >12 
THEN  TO_DATE(MONTH_SHIP_DATE || '/' || DAY_SHIP_DATE  || '/' || YEAR_SHIP_DATE ,'DD/MM/YYYY')
ELSE  TO_DATE(DAY_SHIP_DATE || '/' || MONTH_SHIP_DATE || '/' || YEAR_SHIP_DATE,'DD/MM/YYYY')
END SHIP_DATE_FORMATED,
SHIP_MODE,
COUNTRY,
CITY,
STATE,
to_number (POSTAL_CODE),
REGION
FROM ( 
SELECT 
    CASE
    WHEN LENGTH(SUBSTR(REPLACE(ORDER_DATE , '-','/') , 1,  INSTR(REPLACE(ORDER_DATE , '-','/') , '/')-1 )) = 1 THEN  '0' || SUBSTR(REPLACE(ORDER_DATE , '-','/') , 1,  INSTR(REPLACE(ORDER_DATE , '-','/') , '/')-1 )
    WHEN LENGTH(SUBSTR(REPLACE(ORDER_DATE , '-','/') , 1,  INSTR(REPLACE(ORDER_DATE , '-','/') , '/')-1 )) = 2 THEN   SUBSTR(REPLACE(ORDER_DATE , '-','/') , 1,  INSTR(REPLACE(ORDER_DATE , '-','/') , '/')-1 )
    WHEN LENGTH(SUBSTR(REPLACE(ORDER_DATE , '-','/') , 1,  INSTR(REPLACE(ORDER_DATE , '-','/') , '/')-1 )) = 4 THEN SUBSTR(REPLACE(ORDER_DATE , '-','/') , 1,  INSTR(REPLACE(ORDER_DATE , '-','/') , '/')-1 )
    END  DAY_ORDER_DATE,
    CASE
    WHEN LENGTH(SUBSTR(REPLACE(ORDER_DATE , '-','/') ,   INSTR(REPLACE(ORDER_DATE , '-','/') , '/',1,1) +1,2 )) = 1 THEN '0' || SUBSTR(REPLACE(ORDER_DATE , '-','/') , 1,  INSTR(REPLACE(ORDER_DATE , '-','/') , '/')-1 )
    WHEN LENGTH(SUBSTR(REPLACE(ORDER_DATE , '-','/') ,   INSTR(REPLACE(ORDER_DATE , '-','/') , '/',1,1) +1,2 )) = 2 THEN  SUBSTR(REPLACE(ORDER_DATE , '-','/') ,  INSTR(REPLACE(ORDER_DATE , '-','/') , '/',1,1)+1 ,2 )
    END  MONTH_ORDER_DATE ,
    SUBSTR(REPLACE(ORDER_DATE , '-','/') , INSTR(REPLACE(ORDER_DATE , '-','/'),'/',1,2 ) +1)
    YEAR_ORDER_DATE,
        CASE
    WHEN LENGTH(SUBSTR(REPLACE(SHIP_DATE , '-','/') , 1,  INSTR(REPLACE(SHIP_DATE , '-','/') , '/')-1 )) = 1 THEN  '0' || SUBSTR(REPLACE(SHIP_DATE , '-','/') , 1,  INSTR(REPLACE(SHIP_DATE , '-','/') , '/')-1 )
    WHEN LENGTH(SUBSTR(REPLACE(SHIP_DATE , '-','/') , 1,  INSTR(REPLACE(SHIP_DATE , '-','/') , '/')-1 )) = 2 THEN   SUBSTR(REPLACE(SHIP_DATE , '-','/') , 1,  INSTR(REPLACE(SHIP_DATE , '-','/') , '/')-1 )
    END  DAY_SHIP_DATE,
    CASE
    WHEN LENGTH(SUBSTR(REPLACE(SHIP_DATE , '-','/') ,   INSTR(REPLACE(SHIP_DATE , '-','/') , '/',1,1) +1,2 )) = 1 THEN '0' || SUBSTR(REPLACE(SHIP_DATE , '-','/') , 1,  INSTR(REPLACE(SHIP_DATE , '-','/') , '/')-1 )
    WHEN LENGTH(SUBSTR(REPLACE(SHIP_DATE , '-','/') ,   INSTR(REPLACE(SHIP_DATE , '-','/') , '/',1,1) +1,2 )) = 2 THEN  SUBSTR(REPLACE(SHIP_DATE , '-','/') ,  INSTR(REPLACE(SHIP_DATE , '-','/') , '/',1,1)+1 ,2 )
    END  MONTH_SHIP_DATE ,
    SUBSTR(REPLACE(SHIP_DATE , '-','/') , INSTR(REPLACE(SHIP_DATE , '-','/'),'/',1,2 ) +1)  YEAR_SHIP_DATE , A.*
FROM STG.ORDERS_FILES A
) B;

       COMMIT;
       
------------------------LOAD STG PRODUCTS------------------------
INSERT INTO STG.PRODUCTS
SELECT  PRODUCT_ID, CATEGORY, SUB_CATEGORY, 
   MAX(TO_CHAR(PRODUCT_NAME))
FROM STG.ORDERS_FILES
GROUP BY PRODUCT_ID,CATEGORY,SUB_CATEGORY;
COMMIT;

------------------------LOAD STG CUSTOMERS------------------------
INSERT INTO STG.CUSTOMERS
SELECT DISTINCT CUSTOMER_ID,CUSTOMER_NAME,SEGMENT
FROM STG.ORDERS_FILES A;
COMMIT;



END LOADING_INTO_STG;


END SME_PKG;