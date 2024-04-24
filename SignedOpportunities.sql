/*
    THE CONCEPT OF SALES OPPORTUNITIES DO NOT EXIST WITHIN GFI. GIVEN THAT SALES OPPORTUNITIES ARE PART OF THE NEW CLEARANCE MODEL REDESGIN, WE'LL USE THE CLIENT'S ONBOARDING 
    SIGNED DATE AS THE OPPORTUNITY SIGNED DATE.
*/

IF OBJECT_ID ('TEMPDB..#SignedOpportunities') IS NOT NULL 
	DROP TABLE #SignedOpportunities

CREATE TABLE #SignedOpportunities (
       OpportunityId NVARCHAR(255)
     , OpportunityUID NVARCHAR(255)
     , OpportunityName NVARCHAR(255)
     , ClientId UNIQUEIDENTIFIER 
     , ClientNumber NVARCHAR(255)
     , HouseholdUID NVARCHAR(255)
     , SignedAmountBase DECIMAL(18, 2) 
     , SignedAmountUSD DECIMAL(18, 2)     
     , TargetAssetsBase DECIMAL(18, 2)  
     , TargetAssetsUSD DECIMAL(18, 2) 
     , CurrencyCode NVARCHAR(25)
     , OpportunityStartDate	DATETIME
     , OpportunityEndDate DATETIME
     , SourceSystemIndicator NVARCHAR(25)
     , IsDeleted NVARCHAR(10)
)


;WITH SalesOpportunities AS ( 

    SELECT OpportunityUID
		 , OpportunityId 
		 , LEFT(OpportunityName, 255) AS OpportunityName
		 , ClientId
		 , CONVERT(NVARCHAR(255), ClientNumber) AS ClientNumber
		 , HouseholdUID
		 , SUM(SignedAmountBase) AS SignedAmountBase
		 , SUM(TargetAssetsBase) AS TargetAssetsBase
		 , CurrencyCode
		 , MIN(OnboardingDate) AS OpportunityStartDate --GFI DOES NOT HAVE OPPORTUNITIES - WE'LL USE ONBOARDING DATE AS THE OPPORUNITY DATE AND SIGNED DATE
		 , SourceSystemIndicator
	  FROM (
				   --GFI SIGNED AMOUNTS ARE ON AN ACCOUNT LEVEL
				   SELECT DISTINCT 
						  CONVERT(NVARCHAR(255), @UnknownNumberValue) AS OpportunityUID --OPPORTUNITIES DO NOT EXIST WITHIN GFI
						, CONVERT(NVARCHAR(255), @UnknownNumberValue) AS OpportunityId --OPPORTUNITIES DO NOT EXIST WITHIN GFI
						, CONCAT('GFI Signed Opportunity | ', RM.ProjectNumber) AS OpportunityName --OPPORTUNITIES DO NOT EXIST WITHIN GFI
						, NULL AS ClientId
						, RM.ProjectNumber AS ClientNumber
						, NULL AS HouseholdUID
						, MAP.P_Number AS AcctId
						, FND.C_BSF_Initial_funding_Date
						, FND.C_BSF_LOA_signed
						, FND.C_BSF_Boarding_Date
						, CASE WHEN C_BSF_LOA_signed < '2020-05-01' THEN C_BSF_LOA_signed ELSE C_BSF_Boarding_Date END AS OnboardingDate --PER GFI MAPPING DOCUMENTATION PROVIDED IN PDDTI-1341
						, CONVERT(DECIMAL(18,2), FND.C_BSF_Sales_Board) AS SignedAmountBase
						, CONVERT(DECIMAL(18,2), FND.C_BSF_Sales_Board) AS TargetAssetsBase
						, 'EUR' AS CurrencyCode
					    , 'GFI' AS SourceSystemIndicator

					FROM GFI.tblAS0010_PJ0063 AS FND

					JOIN GFI.tblAS0010 AS ACCT
					  ON ACCT.Id = FND.IdAddress 

					JOIN GFI.tblRNumber_PNumber AS MAP
					  ON ACCT.Number = MAP.P_Number

					JOIN GFI.tblAS0010_PJ0135 AS RM
					  ON MAP.R_Number = RM.ProjectNumber

					--BELOW LOGIC FOUND IN EXISTING ON-PREM GFI SALES BOARD VIEW DEFINITION LIVING ON DATA SERVICES
					WHERE FND.C_BSF_LOA_signed IS NOT NULL
					  AND FND.IdState IN (2104, 2106, 2110)
					--2104: Board Sales & Funding ticket 90 days after first trading day- active ticket
					--2106: Board Sales & Funding ticket  within 90 days after first trading day or no trading day yet - active ticket
					--2110: terminated - ticket no longer in use
					  AND CAST(FND.C_BSF_Sales_Board AS DECIMAL(16,2)) > 0.00
	       ) AS GFI
	 GROUP 
	    BY OpportunityUID
		 , OpportunityId 
		 , OpportunityName
		 , ClientId
		 , ClientNumber
		 , HouseholdUID
		 , CurrencyCode
		 , SourceSystemIndicator
) 

, OpportunitiesFinal AS ( 

	SELECT OpportunityUID
		 , OpportunityId
		 , OpportunityName 
		 , ClientId
		 , ClientNumber		 
		 , HouseholdUID
		 , SignedAmountBase
		 , TargetAssetsBase
		 , CurrencyCode
		 , OpportunityStartDate	
		 , LEAD (OpportunityStartDate, 1, @MaxDateValue) OVER (PARTITION BY ISNULL(ClientNumber, HouseholdUID) ORDER BY OpportunityStartDate, OpportunityUID) AS OpportunityEndDate
		 , SourceSystemIndicator
	  FROM SalesOpportunities

) 


	INSERT
	  INTO #SignedOpportunities (
		   OpportunityUID
		 , OpportunityId
		 , OpportunityName 
		 , ClientId
		 , ClientNumber		 
		 , HouseholdUID
		 , SignedAmountBase
		 , SignedAmountUSD		 
		 , TargetAssetsBase
		 , TargetAssetsUSD
		 , CurrencyCode
		 , OpportunityStartDate	
		 , OpportunityEndDate
		 , SourceSystemIndicator
   )


	SELECT OpportunityUID
		 , OpportunityId
		 , OpportunityName 
		 , ClientId
		 , ClientNumber		 
		 , HouseholdUID
		 , SignedAmountBase
		 , CONVERT(DECIMAL(18,2), CASE 
			  WHEN OPF.SignedAmountBase = 0 
			  THEN 0 
			  WHEN OPF.SignedAmountBase IS NULL OR CE.ExchangeRate IS NULL 
			  THEN NULL
			  ELSE OPF.SignedAmountBase/CE.ExchangeRate
		   END) AS SignedAmountUSD		 
		 , TargetAssetsBase
		 , CONVERT(DECIMAL(18,2), CASE 
			  WHEN OPF.TargetAssetsBase = 0 
			  THEN 0 
			  WHEN OPF.TargetAssetsBase IS NULL OR CE.ExchangeRate IS NULL 
			  THEN NULL
			  ELSE OPF.TargetAssetsBase/CE.ExchangeRate
		   END) AS TargetAssetsUSD
		 , CurrencyCode
		 , OpportunityStartDate
		 , OpportunityEndDate
		 , SourceSystemIndicator
      FROM OpportunitiesFinal AS OPF
	  LEFT
	  JOIN REF.CurrencyExchangeUSD AS CE
	    ON OPF.CurrencyCode = CE.BaseCurrency
	   AND CONVERT(DATE, OPF.OpportunityStartDate) = CONVERT(DATE, CE.EffectiveDate)
