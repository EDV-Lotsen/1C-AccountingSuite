
//&AtClient
//Procedure BeforeClose(Cancel, StandardProcessing)
//	BeforeCloseAtServer(Cancel);
//EndProcedure

//&AtServer
//Procedure BeforeCloseAtServer(Cancel)
//	
//	oneShipping = False;
//	 oneBilling = False;
//	 
//	 query = New Query("SELECT
//					   | Addresses.Ref,
//					   | Addresses.DefaultBilling,
//					   | Addresses.DefaultShipping
//					   |FROM
//					   | Catalog.Addresses AS Addresses
//					   |WHERE
//					   | Addresses.Owner.Ref = &owner");
//	 query.SetParameter("owner",List.Filter.Items[0].RightValue );
//	 addrQuery = query.Execute();
//	 allAddr = addrQuery.Unload();
//	 
//	 If NOT addrQuery.IsEmpty() Then
//	 
//		 For Each addr in allAddr Do
//		  If addr.DefaultBilling = True Then
//		   oneBilling = True;
//		  EndIf;
//		  If addr.DefaultShipping = True Then
//		   oneShipping = True;
//		  EndIf;
//		 EndDo;
//		 
//		 If oneBilling = False Then
//		  Message("Must have a default billing address");
//		  Cancel = True;
//		 EndIf;
//		 If oneShipping = False Then
//		  Message("Must have a default shipping address");
//		  Cancel = True;
//	  	 EndIf;
//		 
//	 EndIf;

//EndProcedure
