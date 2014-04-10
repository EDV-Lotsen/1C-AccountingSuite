
&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
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
			           
			If Object.AdminAccess = True Then
				NewUser.Roles.Add(MetaData.Roles.FullAccess1);
			Else
				
				NewUser.Roles.Add(MetaData.Roles.ListUser);

				If Object.Sales = "Full" Then
					NewUser.Roles.Add(Metadata.Roles.SalesFull);
				Endif;
			
				If Object.Sales = "View" Then
					NewUser.Roles.Add(Metadata.Roles.SalesView);
				Endif;
			
				If Object.Purchasing = "Full" Then
					NewUser.Roles.Add(Metadata.Roles.PurchasingFull);
				Endif;
			
				If Object.Purchasing = "View" Then
					NewUser.Roles.Add(Metadata.Roles.PurchasingView);
				Endif;
			
				If Object.Warehouse = "Full" Then
					NewUser.Roles.Add(Metadata.Roles.WarehouseFull);
				Endif;
			
				If Object.Warehouse = "View" Then
					NewUser.Roles.Add(Metadata.Roles.WarehouseView);
				Endif;
			
				If Object.BankReceive = "Full" Then
					NewUser.Roles.Add(Metadata.Roles.BankReceiveFull);
				Endif;
			
				If Object.BankReceive = "View" Then
					NewUser.Roles.Add(Metadata.Roles.BankReceiveView);
				Endif;
			
				If Object.BankSend = "Full" Then
					NewUser.Roles.Add(Metadata.Roles.BankSendFull);
				Endif;
			
				If Object.BankSend = "View" Then
					NewUser.Roles.Add(Metadata.Roles.BankSendView);
				Endif;
			
				If Object.Accounting = "Full" Then
					NewUser.Roles.Add(Metadata.Roles.AccountingFull);
				Endif;
			
				If Object.Accounting = "View" Then
					NewUser.Roles.Add(Metadata.Roles.AccountingView);
				Endif;
									
				If Object.Projects = "Full" Then
					NewUser.Roles.Add(Metadata.Roles.ProjectsFull);
				Endif;
			
				If Object.Projects = "View" Then
					NewUser.Roles.Add(Metadata.Roles.ProjectsView);
				Endif;
				
				If Object.TimeTrack = "Full" Then
					NewUser.Roles.Add(Metadata.Roles.TimeTrackFull);
				Endif;
			
				If Object.TimeTrack = "View" Then
					NewUser.Roles.Add(Metadata.Roles.TimeTrackView);
				Endif;


			
				If Object.ReportsOnly = True Then
					NewUser.Roles.Add(Metadata.Roles.ReportOnly);
				Endif;
			
			Endif;

			NewUser.ShowInList = False;

			NewUser.Write();
						
		Else
			
			
		 ExistingUser = InfobaseUsers.FindByName(Object.Description);
		 ExistingUser.Roles.Clear();
		 
		    If Object.AdminAccess = True Then
		    	ExistingUser.Roles.Add(MetaData.Roles.FullAccess1);
		    Else
		    	              
		    	ExistingUser.Roles.Add(MetaData.Roles.ListUser);

		    	If Object.Sales = "Full" Then
		    		ExistingUser.Roles.Add(Metadata.Roles.SalesFull);
		    	Endif;
		    
		    	If Object.Sales = "View" Then
		    		ExistingUser.Roles.Add(Metadata.Roles.SalesView);
		    	Endif;
		    
		    	If Object.Purchasing = "Full" Then
		    		ExistingUser.Roles.Add(Metadata.Roles.PurchasingFull);
		    	Endif;
		    
		    	If Object.Purchasing = "View" Then
		    		ExistingUser.Roles.Add(Metadata.Roles.PurchasingView);
		    	Endif;
		    
		    	If Object.Warehouse = "Full" Then
		    		ExistingUser.Roles.Add(Metadata.Roles.WarehouseFull);
		    	Endif;
		    
		    	If Object.Warehouse = "View" Then
		    		ExistingUser.Roles.Add(Metadata.Roles.WarehouseView);
		    	Endif;
		    
		    	If Object.BankReceive = "Full" Then
		    		ExistingUser.Roles.Add(Metadata.Roles.BankReceiveFull);
		    	Endif;
		    
		    	If Object.BankReceive = "View" Then
		    		ExistingUser.Roles.Add(Metadata.Roles.BankReceiveView);
		    	Endif;
		    
		    	If Object.BankSend = "Full" Then
		    		ExistingUser.Roles.Add(Metadata.Roles.BankSendFull);
		    	Endif;
		    
		    	If Object.BankSend = "View" Then
		    		ExistingUser.Roles.Add(Metadata.Roles.BankSendView);
		    	Endif;
		    
		    	If Object.Accounting = "Full" Then
		    		ExistingUser.Roles.Add(Metadata.Roles.AccountingFull);
		    	Endif;
		    
		    	If Object.Accounting = "View" Then
		    		ExistingUser.Roles.Add(Metadata.Roles.AccountingView);
				Endif;
				
				If Object.Projects = "Full" Then
					ExistingUser.Roles.Add(Metadata.Roles.ProjectsFull);
				Endif;
			
				If Object.Projects = "View" Then
					ExistingUser.Roles.Add(Metadata.Roles.ProjectsView);
				Endif;
				
				If Object.TimeTrack = "Full" Then
					ExistingUser.Roles.Add(Metadata.Roles.TimeTrackFull);
				Endif;
			
				If Object.TimeTrack = "View" Then
					ExistingUser.Roles.Add(Metadata.Roles.TimeTrackView);
				Endif;

				
				If Object.ReportsOnly = True Then
					ExistingUser.Roles.Add(Metadata.Roles.ReportOnly);
				Endif;

		    	
		    Endif;
			
			ExistingUser.Password = Password;
			ExistingUser.Write();
				
		EndIf;
		
		SetPrivilegedMode(False);
	
			
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// check correct e-mail address formatting
	
Object.Description = Lower(Object.Description);	
	
If Object.Ref.IsEmpty() Then

	
	If NOT EmailCheck(Object.Description) Then
		
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


Function EmailCheck(StringToCheck)
	
	Template = ".+@.+\..+";
	RegExp = New COMObject("VBScript.RegExp");
	RegExp.MultiLine = False;
	RegExp.Global = True;
	RegExp.IgnoreCase = True;
	RegExp.Pattern = Template;
	If RegExp.Test(StringToCheck) Then
	     Return True;
	Else
	     Return False;
	EndIf;
	 
EndFunction

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
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

&AtClient
Procedure OnOpen(Cancel)
	
	If Object.Ref.IsEmpty() Then
		Object.Sales = "Full";       // Full
		Object.Purchasing = "Full";
		Object.Warehouse = "Full";
		Object.BankReceive = "Full";
		Object.BankSend = "Full";
		Object.Accounting = "Full";
		Object.Projects = "Full";
		Object.TimeTrack = "Full";
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

		Endif;

		
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
		Endif;
	Endif;

EndProcedure
