
////////////////////////////////////////////////////////////////////////////////
// Print templates: Generating document print forms
//------------------------------------------------------------------------------
// Available on:
// - Server
// - External Connection
//

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

//------------------------------------------------------------------------------
// Compatibility functions

Function ContactInfoDatasetUs() Export
	
	Info = New Structure("UsName, UsWebsite, UsBillLine1, UsBillLine1Line2, UsBillLine2, UsBillCity, UsBillState, UsBillZIP, UsBillCityStateZIP, UsBillCountry, UsBillEmail, UsBillPhone, UsBillCell, UsBillFax, UsBillFirstName, UsBillMiddleName, UsBillLastName, USBillFedTaxID");	
	
	Line1Line2 = "";
	If Constants.AddressLine2.Get() = "" Then
		Line1Line2 = Constants.AddressLine1.Get();	
	Else
		Line1Line2 = Constants.AddressLine1.Get() + ", " + Constants.AddressLine2.Get();
	EndIf;
	
	State = Constants.State.Get();
	
	CityStateZIP = "";
	If NOT Constants.City.Get() = "" Then
		CityStateZIP = Constants.City.Get() + ", " + State.Code + " " + Constants.ZIP.Get();
	EndIf;
	
	Info.Insert("UsName", Constants.SystemTitle.Get());	
	Info.Insert("UsBillLine1", Constants.AddressLine1.Get());
	Info.Insert("UsBillLine2", Constants.AddressLine2.Get());	
	Info.Insert("UsBillLine1Line2", Line1Line2);
	Info.Insert("UsBillCity", Constants.City.Get());
	
	Info.Insert("UsBillState", State.Code);
	Info.Insert("UsBillZIP", Constants.ZIP.Get());
	Info.Insert("UsBillCityStateZIP", CityStateZIP);
	Info.Insert("UsBillCountry", Constants.Country.Get());
	Info.Insert("UsBillEmail", Constants.Email.Get());
	Info.Insert("UsBillPhone", Constants.Phone.Get());
	Info.Insert("UsBillCell", Constants.Cell.Get());
	Info.Insert("UsBillFax", Constants.Fax.Get());
	Info.Insert("UsBillFirstName", Constants.FirstName.Get());
	Info.Insert("UsBillMiddleName", Constants.MiddleName.Get());
	Info.Insert("UsBillLastName", Constants.LastName.Get());
	Info.Insert("UsWebsite", Constants.Website.Get());
	Info.Insert("USBillFedTaxID", Constants.FederalTaxID.Get());

	Return Info;
	
EndFunction  

Function ContactInfoDataset(Company, Type, AddressID) Export
	
	If Type = "ThemShip" Then
		Info = New Structure("ThemCode, ThemName, ThemShipLine1, ThemShipLine1Line2, ThemShipLine2, ThemShipCity, ThemShipState, ThemShipZIP, ThemShipCityStateZIP, ThemShipCountry, ThemShipEmail, ThemShipPhone, ThemShipFax, ThemShipFirstName, ThemShipMiddleName, ThemShipLastName");
	ElsIf Type = "ThemBill" Then
		Info = New Structure("ThemCode, ThemName, ThemBillLine1, ThemBillLine2, ThemBillLine1Line2, ThemBillCity, ThemBillState, ThemBillZIP, ThemBillCityStateZIP, ThemBillCountry, ThemBillEmail, ThemBillPhone, ThemBillFax, ThemBillFirstName, ThemBillMiddleName, ThemBillLastName, RemitTo");
	EndIf;
	
	If Type = "ThemBill" Then
		Query = New Query("SELECT
		                  |	Addresses.FirstName,
		                  |	Addresses.MiddleName,
		                  |	Addresses.LastName,
		                  |	Addresses.Phone,
		                  |	Addresses.Fax,
		                  |	Addresses.Email,
		                  |	Addresses.AddressLine1,
		                  |	Addresses.AddressLine2,
		                  |	Addresses.City,
		                  |	Addresses.State.Code AS State,
		                  |	Addresses.Country,
		                  |	Addresses.ZIP,
		                  |	Addresses.RemitTo
		                  |FROM
		                  |	Catalog.Addresses AS Addresses
		                  |WHERE
		                  |	Addresses.Ref = &BillTo");
		Query.SetParameter("BillTo", AddressID);
	EndIf;
	
	If Type = "ThemShip" Then
		Query = New Query("SELECT
		                  |	Addresses.FirstName,
		                  |	Addresses.MiddleName,
		                  |	Addresses.LastName,
		                  |	Addresses.Phone,
		                  |	Addresses.Fax,
		                  |	Addresses.Email,
		                  |	Addresses.AddressLine1,
		                  |	Addresses.AddressLine2,
		                  |	Addresses.City,
		                  |	Addresses.State.Code AS State,
		                  |	Addresses.Country,
		                  |	Addresses.ZIP
		                  |FROM
		                  |	Catalog.Addresses AS Addresses
		                  |WHERE
		                  |	Addresses.Ref = &ShipTo");
		Query.SetParameter("ShipTo", AddressID);
	EndIf;
	
	QueryResult = Query.Execute();	
	Dataset = QueryResult.Unload();
	
	// If no data found - return empty structure
	If Dataset.Count() = 0 Then
		Return Info;
	EndIf;
	
	Line1Line2 = "";
	If Dataset[0].AddressLine2 = "" Then
		Line1Line2 = Dataset[0].AddressLine1;	
	Else
		Line1Line2 = Dataset[0].AddressLine1 + ", " + Dataset[0].AddressLine2;
	EndIf;
		
	CityStateZIP = "";
	If NOT Dataset[0].City = "" Then
		CityStateZIP = Dataset[0].City + ", " + Dataset[0].State + " " + Dataset[0].ZIP;
	EndIf;
	
	If Type = "ThemShip" Then
        Info.Insert("ThemCode", Company.Code);
		Info.Insert("ThemName", Company.Description);
		Info.Insert("ThemShipName", Company.Description);
		Info.Insert("ThemShipLine1", Dataset[0].AddressLine1);
		Info.Insert("ThemShipLine2", Dataset[0].AddressLine2);	
		Info.Insert("ThemShipLine1Line2", Line1Line2);
		Info.Insert("ThemShipCity", Dataset[0].City);
		Info.Insert("ThemShipState", Dataset[0].State);
		Info.Insert("ThemShipZIP", Dataset[0].ZIP);
		Info.Insert("ThemShipCityStateZIP", CityStateZIP);
		Info.Insert("ThemShipCountry", Dataset[0].Country);
		Info.Insert("ThemShipEmail", Dataset[0].Email);
		Info.Insert("ThemShipPhone", Dataset[0].Phone);
		Info.Insert("ThemShipFax", Dataset[0].Fax);
		Info.Insert("ThemShipFirstName", Dataset[0].FirstName);
		Info.Insert("ThemShipMiddleName", Dataset[0].MiddleName);
		Info.Insert("ThemShipLastName", Dataset[0].Lastname);
	ElsIf Type = "ThemBill" Then
		Info.Insert("ThemCode", Company.Code);
		Info.Insert("ThemName", Company.Description);
		Info.Insert("ThemBillName", Company.Description);
		Info.Insert("ThemBillLine1", Dataset[0].AddressLine1);
		Info.Insert("ThemBillLine2", Dataset[0].AddressLine2);	
		Info.Insert("ThemBillLine1Line2", Line1Line2);
		Info.Insert("ThemBillCity", Dataset[0].City);
		Info.Insert("ThemBillState", Dataset[0].State);
		Info.Insert("ThemBillZIP", Dataset[0].ZIP);
		Info.Insert("ThemBillCityStateZIP", CityStateZIP);
		Info.Insert("ThemBillCountry", Dataset[0].Country);
		Info.Insert("ThemBillEmail", Dataset[0].Email);
		Info.Insert("ThemBillPhone", Dataset[0].Phone);
		Info.Insert("ThemBillFax", Dataset[0].Fax);
		Info.Insert("ThemBillFirstName", Dataset[0].FirstName);
		Info.Insert("ThemBillMiddleName", Dataset[0].MiddleName);
		Info.Insert("ThemBillLastName", Dataset[0].Lastname);
		Info.Insert("RemitTo", Dataset[0].RemitTo);
	EndIf;

	Return Info;
	
EndFunction

#EndRegion
