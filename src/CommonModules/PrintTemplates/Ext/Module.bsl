//////////////////////////////////////////////////////////////////////////////// 
// THIS MODULE CONTAINS FUNCTIONS AND PROCEDURES USED FOR
// GENERATING DOCUMENT PRINT FORMS
//

// Returns a document's subtotal
//
// Parameters:
// Ref - a document
//
// Returned value:
// Number.
//
Function Subtotal(Ref) Export
	
	If TypeOf(Ref) = Type("DocumentRef.SalesInvoice") Then DocType = "SalesInvoice" EndIf;
	If TypeOf(Ref) = Type("DocumentRef.SalesQuote") Then DocType = "SalesQuote" EndIf;
	If TypeOf(Ref) = Type("DocumentRef.SalesOrder") Then DocType = "SalesOrder" EndIf;

	
	Query = New Query("SELECT
	                  |	SUM(" + DocType + "LineItems.LineTotal)
	                  |FROM
	                  |	Document." + DocType + ".LineItems AS " + DocType + "LineItems
	                  |WHERE
	                  |	" + DocType + "LineItems.Ref = &Ref");
					  
	Query.SetParameter("Ref", Ref);	
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
		Return 0;
	Else
		Dataset = QueryResult.Unload();
		Return Dataset[0][0];
	EndIf;
	
EndFunction

// Returns a company's contact information
//
// Parameters:
// Catalog.Company
//
// Returned value:
// Structure.
//
Function ContactInfo(Company) Export
	
	Info = New Structure("Name, Address, ZIP, Country, Phone, Email");
	
	Query = New Query("SELECT
	                  |	Companies.Name,
	                  |	Companies.AddressLine1,
	                  |	Companies.AddressLine2,
	                  |	Companies.City,
	                  |	Companies.ZIP,
	                  |	Companies.Country,
	                  |	Companies.Email,
	                  |	Companies.Phone,
	                  |	Companies.State
	                  |FROM
	                  |	Catalog.Companies AS Companies
	                  |WHERE
	                  |	Companies.Ref = &Company");
	
	Query.SetParameter("Company", Company);
	QueryResult = Query.Execute();
	
	Dataset = QueryResult.Unload();
	Name = Dataset[0].Name;
	AddressLine1 = Dataset[0].AddressLine1;
	AddressLine2 = Dataset[0].AddressLine2;
	City = Dataset[0].City;
	ZIP = Dataset[0].ZIP;
	State = Dataset[0].State;
	Country = Dataset[0].Country;
	Email = Dataset[0].Email;
	Phone = Dataset[0].Phone;
	
	Info.Insert("Name", Name);
	
	If AddressLine2 = "" Then
		Address = AddressLine1;	
	Else
		Address = AddressLine1 + ", " + AddressLine2;
	EndIf;
	
	Info.Insert("Address", Address);
	
	ZIP = City + " " + State + " " + ZIP;

	Info.Insert("ZIP", ZIP);
	
	Info.Insert("Phone", Phone);
	
	Info.Insert("Email", Email);
	
	Info.Insert("Country", Country);
		
	Return Info;
	
	
EndFunction

// Returns a bank's contact and bank specific (e.g. SWIFT code) information
//
// Parameters:
// Catalog.Bank.
//
// Returned value:
// Structure.
//
Function BankContactInfo(Bank) Export
	
	Info = New Structure("BankName, BankAddress, BankZIP, BankCountry, AccountNumber, IBAN, BIC, RoutingNumber, AccountHolder");
	
	Query = New Query("SELECT
	                  |	Banks.Description,
	                  |	Banks.AddressLine1,
	                  |	Banks.AddressLine2,
	                  |	Banks.City,
	                  |	Banks.ZIP,
	                  |	Banks.Country,
	                  |	Banks.State,
	                  |	Banks.AccountNumber,
	                  |	Banks.IBAN,
					  |	Banks.BIC,
					  | Banks.RoutingNumber,
					  | Banks.AccountHolder
	                  |FROM
	                  |	Catalog.Banks AS Banks
	                  |WHERE
	                  |	Banks.Ref = &Bank");
	
	Query.SetParameter("Bank", Bank);
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return Info;
	Else
		Dataset = QueryResult.Unload();
		
		Description = Dataset[0].Description;
		AddressLine1 = Dataset[0].AddressLine1;
		AddressLine2 = Dataset[0].AddressLine2;
		City = Dataset[0].City;
		ZIP = Dataset[0].ZIP;
		State = Dataset[0].State;
		Country = Dataset[0].Country;
		
		Info.Insert("BankName", Description);
		
		If AddressLine2 = "" Then
			Address = AddressLine1;	
		Else
			Address = AddressLine1 + ", " + AddressLine2;
		EndIf;
		
		Info.Insert("BankAddress", Address);
		
		ZIP = City + " " + State + " " + ZIP;

		Info.Insert("BankZIP", ZIP);
			
		Info.Insert("BankCountry", Country);
		
		Info.Insert("AccountNumber", Dataset[0].AccountNumber);
		Info.Insert("IBAN", Dataset[0].IBAN);
		Info.Insert("BIC", Dataset[0].BIC);
		Info.Insert("RoutingNumber", Dataset[0].RoutingNumber);
		Info.Insert("AccountHolder", Dataset[0].AccountHolder);
			
		Return Info;
	EndIf;
	
EndFunction