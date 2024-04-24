	      SELECT RM.ProjectNumber AS ClientNumber
             , MIN(ACCT.C_BSF_First_Trading_Day) AS ClearanceDate
          FROM GFI.tblAS0010_PJ0135 AS RM
          LEFT
          JOIN GFI.tblLOAStartRelationship AS LOA 
		        ON LOA.RelationshipNumber = RM.ProjectNumber
          LEFT
          JOIN GFI.tblAS0010_PJ0063 AS ACCT
		        ON ACCT.C_BSF_RelationshipId = RM.Id
           AND ACCT.C_BSF_First_Trading_Day > LOA.C_BSF_LOA_Start
         WHERE ACCT.C_BSF_First_Trading_Day IS NOT NULL
         GROUP
            BY RM.ProjectNumber
