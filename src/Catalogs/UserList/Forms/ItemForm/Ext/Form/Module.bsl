
&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	CheckAllUsersDisabled(Cancel);
	If Constants.VersionNumber.Get() = 3 Then
		CheckNumberOfAllowedUsers(Cancel, 2);
		If Cancel = True Then
			Return;
		EndIf;
	EndIf;
	If Constants.VersionNumber.Get() = 5 Then
		CheckNumberOfAllowedUsers(Cancel, 10);
		If Cancel = True Then
			Return;
		EndIf;
	EndIf;
	If Constants.VersionNumber.Get() = 6 Then
		CheckNumberOfAllowedUsers(Cancel, 3);
		If Cancel = True Then
			Return;
		EndIf;
	EndIf;
	
	//If Constants.ServiceDB.Get() = True Then
	
		SetPrivilegedMode(True);
		
		If Object.Ref.IsEmpty() Then
			                  
			NewUser = InfoBaseUsers.CreateUser();
			//NewUser.Name = Object.Description + Right(SessionParameters.TenantValue,7);
			NewUser.Name = Object.Description;
			NewUser.FullName = Object.Description;
			NewUser.StandardAuthentication = True;
			//RNG = New RandomNumberGenerator(255);	
			NewUser.Password = Password;
			//NewUser.Roles.Add(Metadata.Roles.FullAccess1);
			
			If IsBankAccountingOnline() = True Then
				 NewUser.Roles.Add(MetaData.Roles.BankAccounting);			
			Else
				
				If Object.AdminAccess = True Then
					NewUser.Roles.Add(MetaData.Roles.FullAccess1);
				Else

					If Object.Sales = "Full" Then
						NewUser.Roles.Add(Metadata.Roles.SalesFull);
						If NOT NewUser.Roles.Contains(Metadata.Roles.ListUser) Then
							NewUser.Roles.Add(MetaData.Roles.ListUser);	
						EndIf;
					Endif;
				
					If Object.Sales = "View" Then
						NewUser.Roles.Add(Metadata.Roles.SalesView);
						If NOT NewUser.Roles.Contains(Metadata.Roles.ListUser) Then
							NewUser.Roles.Add(MetaData.Roles.ListUser);	
						EndIf;
					Endif;
				
					If Object.Purchasing = "Full" Then
						NewUser.Roles.Add(Metadata.Roles.PurchasingFull);
						If NOT NewUser.Roles.Contains(Metadata.Roles.ListUser) Then
							NewUser.Roles.Add(MetaData.Roles.ListUser);	
						EndIf;
					Endif;
				
					If Object.Purchasing = "View" Then
						NewUser.Roles.Add(Metadata.Roles.PurchasingView);
						If NOT NewUser.Roles.Contains(Metadata.Roles.ListUser) Then
							NewUser.Roles.Add(MetaData.Roles.ListUser);	
						EndIf;
					Endif;
				
					If Object.Warehouse = "Full" Then
						NewUser.Roles.Add(Metadata.Roles.WarehouseFull);
						If NOT NewUser.Roles.Contains(Metadata.Roles.ListUser) Then
							NewUser.Roles.Add(MetaData.Roles.ListUser);	
						EndIf;
					Endif;
				
					If Object.Warehouse = "View" Then
						NewUser.Roles.Add(Metadata.Roles.WarehouseView);
						If NOT NewUser.Roles.Contains(Metadata.Roles.ListUser) Then
							NewUser.Roles.Add(MetaData.Roles.ListUser);	
						EndIf;
					Endif;
				
					If Object.BankReceive = "Full" Then
						NewUser.Roles.Add(Metadata.Roles.BankReceiveFull);
						If NOT NewUser.Roles.Contains(Metadata.Roles.ListUser) Then
							NewUser.Roles.Add(MetaData.Roles.ListUser);	
						EndIf;
					Endif;
				
					If Object.BankReceive = "View" Then
						NewUser.Roles.Add(Metadata.Roles.BankReceiveView);
						If NOT NewUser.Roles.Contains(Metadata.Roles.ListUser) Then
							NewUser.Roles.Add(MetaData.Roles.ListUser);	
						EndIf;
					Endif;
				
					If Object.BankSend = "Full" Then
						NewUser.Roles.Add(Metadata.Roles.BankSendFull);
						If NOT NewUser.Roles.Contains(Metadata.Roles.ListUser) Then
							NewUser.Roles.Add(MetaData.Roles.ListUser);	
						EndIf;
					Endif;
				
					If Object.BankSend = "View" Then
						NewUser.Roles.Add(Metadata.Roles.BankSendView);
						If NOT NewUser.Roles.Contains(Metadata.Roles.ListUser) Then
							NewUser.Roles.Add(MetaData.Roles.ListUser);	
						EndIf;
					Endif;
				
					If Object.Accounting = "Full" Then
						NewUser.Roles.Add(Metadata.Roles.AccountingFull);
						If NOT NewUser.Roles.Contains(Metadata.Roles.ListUser) Then
							NewUser.Roles.Add(MetaData.Roles.ListUser);	
						EndIf;
					Endif;
				
					If Object.Accounting = "View" Then
						NewUser.Roles.Add(Metadata.Roles.AccountingView);
					Endif;
										
					If Object.Projects = "Full" Then
						NewUser.Roles.Add(Metadata.Roles.ProjectsFull);
						If NOT NewUser.Roles.Contains(Metadata.Roles.ListUser) Then
							NewUser.Roles.Add(MetaData.Roles.ListUser);	
						EndIf;
					Endif;
				
					If Object.Projects = "View" Then
						NewUser.Roles.Add(Metadata.Roles.ProjectsView);
						If NOT NewUser.Roles.Contains(Metadata.Roles.ListUser) Then
							NewUser.Roles.Add(MetaData.Roles.ListUser);	
						EndIf;
					Endif;
					
					If Object.TimeTrack = "Full" Then
						NewUser.Roles.Add(Metadata.Roles.TimeTrackFull);
						If NOT NewUser.Roles.Contains(Metadata.Roles.ListUser) Then
							NewUser.Roles.Add(MetaData.Roles.ListUser);	
						EndIf;
					Endif;
				
					If Object.TimeTrack = "View" Then
						NewUser.Roles.Add(Metadata.Roles.TimeTrackView);
						If NOT NewUser.Roles.Contains(Metadata.Roles.ListUser) Then
							NewUser.Roles.Add(MetaData.Roles.ListUser);	
						EndIf;
					Endif;
					
					If Object.ItemReceipt = "Full" Then
						NewUser.Roles.Add(Metadata.Roles.ItemReceiptFull);
					EndIf;
					
					If Object.Shipment = "Full" Then
						NewUser.Roles.Add(Metadata.Roles.ShipmentFull);
					EndIf;

					If Object.ReportsOnly = True Then
						NewUser.Roles.Add(Metadata.Roles.ReportOnly);
						//If NOT NewUser.Roles.Contains(Metadata.Roles.ListUser) Then
							//NewUser.Roles.Add(MetaData.Roles.ListUser);	
						//EndIf;
					Endif;
				
				EndIf;
				
			EndIf;

			NewUser.ShowInList = False;

			NewUser.Write();
			
			If Object.Disabled = False Then
			
				// API call
				
				Object.EmailSent = True;
				
			EndIf;
			
		Else
			
			
		 ExistingUser = InfobaseUsers.FindByName(Object.Description);
		 ExistingUser.Roles.Clear();
		 
	 	If IsBankAccountingOnline() = True Then
			 ExistingUser.Roles.Add(MetaData.Roles.BankAccounting);			
		Else
		 
		    If Object.AdminAccess = True Then
		    	ExistingUser.Roles.Add(MetaData.Roles.FullAccess1);
		    Else

		    	If Object.Sales = "Full" Then
		    		ExistingUser.Roles.Add(Metadata.Roles.SalesFull);
					If NOT ExistingUser.Roles.Contains(Metadata.Roles.ListUser) Then
						ExistingUser.Roles.Add(MetaData.Roles.ListUser);	
					EndIf;
		    	Endif;
		    
		    	If Object.Sales = "View" Then
		    		ExistingUser.Roles.Add(Metadata.Roles.SalesView);
					If NOT ExistingUser.Roles.Contains(Metadata.Roles.ListUser) Then
						ExistingUser.Roles.Add(MetaData.Roles.ListUser);	
					EndIf;
		    	Endif;
		    
		    	If Object.Purchasing = "Full" Then
		    		ExistingUser.Roles.Add(Metadata.Roles.PurchasingFull);
					If NOT ExistingUser.Roles.Contains(Metadata.Roles.ListUser) Then
						ExistingUser.Roles.Add(MetaData.Roles.ListUser);	
					EndIf;
		    	Endif;
		    
		    	If Object.Purchasing = "View" Then
		    		ExistingUser.Roles.Add(Metadata.Roles.PurchasingView);
					If NOT ExistingUser.Roles.Contains(Metadata.Roles.ListUser) Then
						ExistingUser.Roles.Add(MetaData.Roles.ListUser);	
					EndIf;
		    	Endif;
		    
		    	If Object.Warehouse = "Full" Then
		    		ExistingUser.Roles.Add(Metadata.Roles.WarehouseFull);
					If NOT ExistingUser.Roles.Contains(Metadata.Roles.ListUser) Then
						ExistingUser.Roles.Add(MetaData.Roles.ListUser);	
					EndIf;
		    	Endif;
		    
		    	If Object.Warehouse = "View" Then
		    		ExistingUser.Roles.Add(Metadata.Roles.WarehouseView);
					If NOT ExistingUser.Roles.Contains(Metadata.Roles.ListUser) Then
						ExistingUser.Roles.Add(MetaData.Roles.ListUser);	
					EndIf;
		    	Endif;
		    
		    	If Object.BankReceive = "Full" Then
		    		ExistingUser.Roles.Add(Metadata.Roles.BankReceiveFull);
					If NOT ExistingUser.Roles.Contains(Metadata.Roles.ListUser) Then
						ExistingUser.Roles.Add(MetaData.Roles.ListUser);	
					EndIf;
		    	Endif;
		    
		    	If Object.BankReceive = "View" Then
		    		ExistingUser.Roles.Add(Metadata.Roles.BankReceiveView);
					If NOT ExistingUser.Roles.Contains(Metadata.Roles.ListUser) Then
						ExistingUser.Roles.Add(MetaData.Roles.ListUser);	
					EndIf;

		    	Endif;
		    
		    	If Object.BankSend = "Full" Then
		    		ExistingUser.Roles.Add(Metadata.Roles.BankSendFull);
					If NOT ExistingUser.Roles.Contains(Metadata.Roles.ListUser) Then
						ExistingUser.Roles.Add(MetaData.Roles.ListUser);	
					EndIf;
		    	Endif;
		    
		    	If Object.BankSend = "View" Then
		    		ExistingUser.Roles.Add(Metadata.Roles.BankSendView);
					If NOT ExistingUser.Roles.Contains(Metadata.Roles.ListUser) Then
						ExistingUser.Roles.Add(MetaData.Roles.ListUser);	
					EndIf;
		    	Endif;
		    
		    	If Object.Accounting = "Full" Then
		    		ExistingUser.Roles.Add(Metadata.Roles.AccountingFull);
					If NOT ExistingUser.Roles.Contains(Metadata.Roles.ListUser) Then
						ExistingUser.Roles.Add(MetaData.Roles.ListUser);	
					EndIf;
		    	Endif;
		    
		    	If Object.Accounting = "View" Then
		    		ExistingUser.Roles.Add(Metadata.Roles.AccountingView);
					If NOT ExistingUser.Roles.Contains(Metadata.Roles.ListUser) Then
						ExistingUser.Roles.Add(MetaData.Roles.ListUser);	
					EndIf;

				Endif;
				
				If Object.Projects = "Full" Then
					ExistingUser.Roles.Add(Metadata.Roles.ProjectsFull);
					If NOT ExistingUser.Roles.Contains(Metadata.Roles.ListUser) Then
						ExistingUser.Roles.Add(MetaData.Roles.ListUser);	
					EndIf;

				Endif;
			
				If Object.Projects = "View" Then
					ExistingUser.Roles.Add(Metadata.Roles.ProjectsView);
					If NOT ExistingUser.Roles.Contains(Metadata.Roles.ListUser) Then
						ExistingUser.Roles.Add(MetaData.Roles.ListUser);	
					EndIf;

				Endif;
				
				If Object.TimeTrack = "Full" Then
					ExistingUser.Roles.Add(Metadata.Roles.TimeTrackFull);
					If NOT ExistingUser.Roles.Contains(Metadata.Roles.ListUser) Then
						ExistingUser.Roles.Add(MetaData.Roles.ListUser);	
					EndIf;
				Endif;
			
				If Object.TimeTrack = "View" Then
					ExistingUser.Roles.Add(Metadata.Roles.TimeTrackView);
					If NOT ExistingUser.Roles.Contains(Metadata.Roles.ListUser) Then
						ExistingUser.Roles.Add(MetaData.Roles.ListUser);	
					EndIf;
				Endif;

				If Object.ItemReceipt = "Full" Then
					ExistingUser.Roles.Add(Metadata.Roles.ItemReceiptFull);
				EndIf;
				
				If Object.Shipment = "Full" Then
					ExistingUser.Roles.Add(Metadata.Roles.ShipmentFull);
				EndIf;
				
				If Object.ReportsOnly = True Then
					ExistingUser.Roles.Add(Metadata.Roles.ReportOnly);
					//If NOT ExistingUser.Roles.Contains(Metadata.Roles.ListUser) Then
						//ExistingUser.Roles.Add(MetaData.Roles.ListUser);	
					//EndIf;
				Endif;

		    	
			Endif;
			
		EndIf;
			
		ExistingUser.Password = Password;
		ExistingUser.Write();
			
			If Object.Disabled = False AND Object.EmailSent = False Then
				
				If Not Object.Verified Then
					// API call
					
					Object.EmailSent = True;
				EndIf;
				
			EndIf;
				
		EndIf;
		
		SetPrivilegedMode(False);
		
	//EndIf;			
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// check correct e-mail address formatting
	
Object.Description = Lower(Object.Description);	
	
If Object.Ref.IsEmpty() Then

	
	If NOT GeneralFunctions.EmailCheck(Object.Description) Then
		
		Message = New UserMessage();
		Message.Text=NStr("en='Please enter a correct e-mail address'");
		//Message.Field = "Object.Description";
		Message.Message();
		Cancel = True;
		Return;
		
	EndIf;
	
	// check uniqueness of the name
		
	Query = New Query("SELECT
	                  |	UserList.Ref
	                  |FROM
	                  |	Catalog.UserList AS UserList
	                  |WHERE
	                  |	UserList.Description = &Description");
					  
	Query.SetParameter("Description", Object.Description);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
	Else
		
		Message = New UserMessage();
		Message.Text=NStr("en='E-mail address is not unique'");
		//Message.Field = "Object.Description";
		Message.Message();
		Cancel = True;
		Return;

	EndIf;
	
Endif;
	
	// check if there is at least one user with admin rights available
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If NOT FullAccessCheck() Then
		If IsBankAccountingOnline() = False Then
			Items.Disabled.ReadOnly = True;
			Items.Disabled.Visible = False;
		Else
		EndIf;

	EndIf;
	
	If NOT Object.Ref.IsEmpty() Then
		
		Items.Description.ReadOnly = True;
		
			//Message = New UserMessage();
			//Message.Text=NStr("en='User editing feature is not available at this moment.'");
			//Message.Field = "Object.Description";
			//Message.Message();
			//Cancel = True;
			//Return;	
			
	EndIf;

EndProcedure

&AtServer
Function IsBankAccountingOnline()
	
	If Constants.VersionNumber.Get() = 3 Then
		Return True
	Else
		Return False
	EndIf;
	
EndFunction

&AtClient
Procedure OnOpen(Cancel)
	
	If IsBankAccountingOnline() = True Then
		
		Items.AdminAccess.Visible = False;
		Items.ReportsOnly.Visible = False;
		Items.Sales.Visible = False;
		Items.Purchasing.Visible = False;
		Items.Warehouse.Visible = False;
		Items.BankReceive.Visible = False;
		Items.BankSend.Visible = False;
		Items.Accounting.Visible = False;
		Items.Projects.Visible = False;
		Items.TimeTrack.Visible = False;
		Items.ItemReceipt.Visible = False;
		Items.Shipment.Visible = False;
		
	Else
	
		If Object.Ref.IsEmpty() Then
			Object.Sales = "Full";       // Full
			Object.Purchasing = "Full";
			Object.Warehouse = "Full";
			Object.BankReceive = "Full";
			Object.BankSend = "Full";
			Object.Accounting = "Full";
			Object.Projects = "Full";
			Object.TimeTrack = "Full";
			Object.ItemReceipt = "Full";
			Object.Shipment = "Full";
			Object.ReportsOnly = False;
		Else
			Items.Verified.Visible = True;
			AdminBox(Object);
			ReportBox(Object);
			If FullAccessCheck() = False Then
				
				Items.Name.ReadOnly = True;
				Items.Description.ReadOnly = True;
				Items.Ttile.ReadOnly = True;
				Items.Phone.ReadOnly = True;
				Items.AdminAccess.ReadOnly = True;
				Items.Sales.ReadOnly = True;
				Items.Purchasing.ReadOnly = True;
				Items.Warehouse.ReadOnly = True;
				Items.BankReceive.ReadOnly = True;
				Items.BankSend.ReadOnly = True;
				Items.Accounting.ReadOnly = True;
				Items.Projects.ReadOnly = True;
				Items.TimeTrack.ReadOnly = True;
				Items.ReportsOnly.ReadOnly = True;
				Items.Shipment.ReadOnly = True;
				Items.ItemReceipt.ReadOnly = True;

			Endif;
		EndIf;
	EndIf;
	 
	 
EndProcedure

&AtServer
Function FullAccessCheck()
	CurUser = InfoBaseUsers.FindByName(SessionParameters.ACSUser);
	Return CurUser.Roles.Contains(Metadata.Roles.FullAccess1)
EndFunction


&AtClient
Procedure AdminBox(Object)
	
	If Object.AdminAccess = True Then
		Object.Sales = "Full";
		Items.Sales.ReadOnly = True;
		Object.Purchasing = "Full";
		Items.Purchasing.ReadOnly = True;
		Object.Warehouse = "Full";
		Items.Warehouse.ReadOnly = True;
		Object.BankReceive = "Full";
		Items.BankReceive.ReadOnly = True;
		Object.BankSend = "Full";
		Items.BankSend.ReadOnly = True;
		Object.Accounting = "Full";
		Items.Accounting.ReadOnly = True;
		Object.Projects = "Full";
		Items.Projects.ReadOnly = True;
		Object.TimeTrack = "Full";
		Items.TimeTrack.ReadOnly = True;
		Object.ItemReceipt = "Full";
		Items.ItemReceipt.ReadOnly = True;
		Object.Shipment = "Full";
		Items.Shipment.ReadOnly = True;
		Object.ReportsOnly = false;
		Items.ReportsOnly.ReadOnly = True;
		
		
	Endif;                
	
	If Object.AdminAccess = False Then
		
		Items.Sales.ReadOnly = false;
		Items.Purchasing.ReadOnly = false;
		Items.Warehouse.ReadOnly = false;
		Items.BankReceive.ReadOnly = false;
		Items.BankSend.ReadOnly = false;
		Items.Accounting.ReadOnly = false;
		Items.Projects.ReadOnly = false;
		Items.TimeTrack.ReadOnly = false;
		Items.ReportsOnly.ReadOnly = false;
		Items.Shipment.ReadOnly = false;
		Items.ItemReceipt.ReadOnly = false;
	Endif;

EndProcedure
&AtClient
Procedure ChoiceProcessing()
	
AdminBox(Object);
ReportBox(Object);

EndProcedure

&AtClient
Procedure ReportBox(Object)
	
	If Object.ReportsOnly = True Then
		Object.AdminAccess = false;
		Items.AdminAccess.ReadOnly = True;
		Object.Sales = "None";
		Items.Sales.ReadOnly = True;
		Object.Purchasing = "None";
		Items.Purchasing.ReadOnly = True;
		Object.Warehouse = "None";
		Items.Warehouse.ReadOnly = True;
		Object.BankReceive = "None";
		Items.BankReceive.ReadOnly = True;
		Object.BankSend = "None";
		Items.BankSend.ReadOnly = True;
		Object.Accounting = "None";
		Items.Accounting.ReadOnly = True;
		Object.Projects = "None";
		Items.Projects.ReadOnly = True;
		Object.ItemReceipt = "None";
		Items.ItemReceipt.ReadOnly = True;
		Object.Shipment = "None";
		Items.Shipment.ReadOnly = True;
		Object.TimeTrack = "None";
		Items.TimeTrack.ReadOnly = True;

		
	Endif;
	
	If Object.ReportsOnly = False Then
		If Object.AdminAccess = false Then
		
		Items.AdminAccess.ReadOnly = false;
		Items.Sales.ReadOnly = false;
		Items.Purchasing.ReadOnly = false;
		Items.Warehouse.ReadOnly = false;
		Items.BankReceive.ReadOnly = false;
		Items.BankSend.ReadOnly = false;
		Items.Accounting.ReadOnly = false;
		Items.Projects.ReadOnly = false;
		Items.TimeTrack.ReadOnly = false;
		Items.ItemReceipt.ReadOnly = false;
		Items.Shipment.ReadOnly = false;
		Endif;
	Endif;

EndProcedure

&AtServer
Procedure CheckNumberOfAllowedUsers(Cancel, AllowedUserNum) 
	
	If Object.Disabled = False Then
		Query = New Query("SELECT
		                  |	UserList.Ref
		                  |FROM
		                  |	Catalog.UserList AS UserList
		                  |WHERE
		                  |	UserList.Disabled = &Disabled
		                  |	AND NOT UserList.Description LIKE &Description");
		Query.SetParameter("Disabled", False);
		Query.SetParameter("Description", "%@accountingsuite.com");
		QueryResult = Query.Execute();
		Dataset = QueryResult.Unload();
		If Dataset.Count() > AllowedUserNum Then
			Object.Disabled = True;
			Message("Number of active users exceeded. Must disable a different user before enabling this one.");
			Cancel = True;
		EndIf;			
	EndIf;
		
EndProcedure

Procedure CheckAllUsersDisabled(Cancel)
	Query = New Query("SELECT
		                  |	UserList.Ref
		                  |FROM
		                  |	Catalog.UserList AS UserList
		                  |WHERE
		                  |	UserList.Disabled = &Disabled");
		Query.SetParameter("Disabled", False);
		QueryResult = Query.Execute();
		Dataset = QueryResult.Unload();
		If Dataset.Count() <= 0 Then
			Object.Disabled = False;
			Message("Cannot disable all users. There will be no access to this database.");
			Cancel = True;
		EndIf;
EndProcedure
