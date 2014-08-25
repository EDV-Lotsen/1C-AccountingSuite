
Procedure BeforeWrite(Cancel)
	
	If IsNew() Then
		NewObject = True;
	  addrQuery = New Query("SELECT
	                        | Addresses.Ref
	                        |FROM
	                        | Catalog.Addresses AS Addresses
	                        |WHERE
	                        | Addresses.Description = &Desc
	                        | AND Addresses.Owner.Ref = &Ref");
	       
	  addrQuery.SetParameter("Desc", Description);
	  addrQuery.SetParameter("Ref", Owner.Ref);
	  result = addrQuery.Execute();
	  If NOT result.IsEmpty() Then
	   Message("The address id already exists.");
	   Cancel = True;
	  EndIf;
	 
	  billQuery = New Query("SELECT
	                        | Addresses.Ref
	                        |FROM
	                        | Catalog.Addresses AS Addresses
	                        |WHERE
	                        | Addresses.DefaultBilling = TRUE
	                        | AND Addresses.Owner.Ref = &Ref");
	       
	  billQuery.SetParameter("Ref", Owner.Ref);     
	  billResult = billQuery.Execute();
	  If NOT billResult.IsEmpty() AND DefaultBilling = True Then
	   Message("Another address is already set as the default billing address.");
	   Cancel = True;
	  EndIf;
	  
	  shipQuery = New Query("SELECT
	                        | Addresses.Ref
	                        |FROM
	                        | Catalog.Addresses AS Addresses
	                        |WHERE
	                        | Addresses.DefaultShipping = TRUE
	                        | AND Addresses.Owner.Ref = &Ref");
	       
	  shipQuery.SetParameter("Ref", Owner.Ref);
	  shipResult = shipQuery.Execute();
	  If NOT shipResult.IsEmpty() AND DefaultShipping = True Then
	   Message("Another address is already set as the default shipping address.");
	   Cancel = True;
	  EndIf;
  Else
	  NewObject = False;
	  addrQuery = New Query("SELECT
	                        | Addresses.Ref
	                        |FROM
	                        | Catalog.Addresses AS Addresses
	                        |WHERE
	                        | Addresses.Description = &Desc
	                        | AND Addresses.Owner.Ref = &Ref");
	       
	  addrQuery.SetParameter("Desc", Description);
	  addrQuery.SetParameter("Ref", Owner.Ref);
	  result = addrQuery.Execute();
	  addr = result.Unload();
	  
	  If (NOT result.IsEmpty()) Then
	   If  addr[0].Ref <> Ref  Then
	    Message("The address id already exists.");
	    Cancel = True;
	   Endif;
	  EndIf; 
	EndIf;

EndProcedure
