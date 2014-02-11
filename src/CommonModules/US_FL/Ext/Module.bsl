//////////////////////////////////////////////////////////////////////////////// 
// THIS MODULE CONTAINS FUNCTIONS AND PROCEDURES USED BY
// THE US FINANCIAL LOCALIZATION FUNCTIONALITY
// 


// Returns a dataset used in 1099 reporting.
//
// Parameter:
// String - date filter for selecting GL transactions.
//
// Returned value:
// ValueTable.
//
Function Data1099(WhereCase) Export
	
	// Selecting all 1099 Accounts
	
	Query = New Query("SELECT
	                  |	ChartOfAccounts.Ref,
	                  |	USTaxCategories1099.Threshold,
	                  |	USTaxCategories1099.Description
	                  |FROM
	                  |	Catalog.USTaxCategories1099 AS USTaxCategories1099
	                  |		INNER JOIN ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                  |		ON ChartOfAccounts.Category1099 = USTaxCategories1099.Ref");
					  
					  
					  
	Accounts = Query.Execute().Unload();
	
	// Selecting all 1099 Vendors
	
	Query = New Query("SELECT
	                  |	Companies.Ref,
	                  |	Companies.Description
	                  |FROM
	                  |	Catalog.Companies AS Companies
	                  |WHERE
	                  |	Companies.Vendor1099 = TRUE");
					  
	Vendors = Query.Execute().Unload();
	
	// For each 1099 account select all GL transactions within the time period.
	// Then for each vendor filter the dataset selecting only transactions where the vendor is the
	// counterparty. Add the result to the value table, group by vendor and 1099 category.
		
	Data1099 = New ValueTable();
	Data1099.Columns.Add("Category1099");
	Data1099.Columns.Add("AmountRC");
	Data1099.Columns.Add("Vendor");	
	
	For i = 0 to Accounts.Count() - 1 Do
				
		Query = New Query("SELECT
		                  |	GeneralJournal.RecordType,
		                  |	GeneralJournal.AmountRC,
		                  |	GeneralJournal.Account,
		                  |	GeneralJournal.Recorder,
		                  |	GeneralJournal.Account.Category1099 AS Category1099
		                  |FROM
		                  |	AccountingRegister.GeneralJournal AS GeneralJournal
		                  |WHERE
		                  |	GeneralJournal.Account = &Account
						  | " + WhereCase + "");
		Query.Parameters.Insert("Account", Accounts[i].Ref);				  
		Dataset = Query.Execute().Unload();
		
		For y = 0 to Vendors.Count() - 1 Do
			
			For z = 0 To Dataset.Count() - 1 Do
				
				If Dataset[z].Recorder.Company = Vendors[y].Ref Then
					
					Data1099Row = Data1099.Add();
					Data1099Row.Category1099 = Dataset[z].Category1099;
					Data1099Row.AmountRC = Dataset[z].AmountRC;
					Data1099Row.Vendor = Vendors[y].Ref;
					
				EndIf;
				
			EndDo;
			
		EndDo;
	
	EndDo;
	
	Data1099.GroupBy("Category1099, Vendor", "AmountRC");
	Data1099.Sort("Vendor");
	
	Return Data1099;
	
EndFunction
