/*
    CLIENT ONBOARDING IS DEPENDENT ON THE SIGNED OPPORTUNITIES. MAKE SURE TO LOAD THE #SignedOpportunities TEMP TABLE FIRST
*/

SELECT OpportunityUID 
		     , OpportunityId
		     , OpportunityName 
		     , ClientId
		     , CONVERT(NVARCHAR(255), ClientNumber) AS ClientNumber
			 , HouseholdUID
			 , CONVERT(NVARCHAR(255), @UnknownNumberValue) AS OnboardingUID --ONBOARDING CASES DO NOT EXIST WITHIN GFI
			 , CONVERT(NVARCHAR(255), @UnknownNumberValue) AS OnboardingId --ONBOARDING CASES DO NOT EXIST WITHIN GFI
			 , OpportunityStartDate AS OnboardingDate 
             , SignedAmountBase
             , SignedAmountUSD            
			 , TargetAssetsBase
             , TargetAssetsUSD
             , CurrencyCode
             , OpportunityStartDate
             , OpportunityEndDate
			 , SourceSystemIndicator
		  FROM #SignedOpportunities 
		 WHERE SourceSystemIndicator = 'GFI' --GFI DOES NOT HAVE OPPORTUNITIES. ONBOARDING IS THE SAME AS THE SIGNED OPPORTUNITIES 
