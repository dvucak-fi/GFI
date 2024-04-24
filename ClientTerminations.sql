	   SELECT ProjectNumber AS ClientNumber
			    , 'Client - Trading Termination' TerminationTypeDesc
			    , C_TerminationDate AS TerminationDate 
	     FROM GFI.tblAS0010_PJ0135
		  WHERE C_TerminationDate IS NOT NULL --TERM DATE MUST EXIST	
		    AND C_CountTermination = 1 --CLIENT TERMINATION    
