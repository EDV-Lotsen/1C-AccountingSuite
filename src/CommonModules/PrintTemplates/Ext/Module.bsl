//////////////////////////////////////////////////////////////////////////////// 
// THIS MODULE CONTAINS FUNCTIONS AND PROCEDURES USED FOR
// GENERATING DOCUMENT PRINT FORMS
//

Function ContactInfoDataset(Company, Type, ShipTo) Export
	
	If Type = "UsBill" Then
		Info = New Structure("UsCode, UsName, UsBillLine1, UsBillLine2, UsBillLine1Line2, UsBillCity, UsBillState, UsBillZIP, UsBillCityStateZIP, UsBillCountry, UsBillEmail, UsBillPhone, UsBillFax, UsBillFirstName, UsBillMiddleName, UsBillLastName");
	ElsIf Type = "ThemShip" Then
		Info = New Structure("ThemCode, ThemName, ThemShipLine1, ThemShipLine1Line2, ThemShipLine2, ThemShipCity, ThemShipState, ThemShipZIP, ThemShipCityStateZIP, ThemShipCountry, ThemShipEmail, ThemShipPhone, ThemShipFax, ThemShipFirstName, ThemShipMiddleName, ThemShipLastName");
	ElsIf Type = "ThemBill" Then
		Info = New Structure("ThemCode, ThemName, ThemBillLine1, ThemBillLine2, ThemBillLine1Line2, ThemBillCity, ThemBillState, ThemBillZIP, ThemBillCityStateZIP, ThemBillCountry, ThemBillEmail, ThemBillPhone, ThemBillFax, ThemBillFirstName, ThemBillMiddleName, ThemBillLastName");
	EndIf;
	
	If Type = "UsBill" OR Type = "ThemBill" Then
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
		                  |	Addresses.State,
		                  |	Addresses.Country,
		                  |	Addresses.ZIP
		                  |FROM
		                  |	Catalog.Addresses AS Addresses
		                  |WHERE
		                  |	Addresses.Owner = &Company
		                  |	AND Addresses.DefaultBilling = TRUE");
		Query.SetParameter("Company", Company);
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
		                  |	Addresses.State,
		                  |	Addresses.Country,
		                  |	Addresses.ZIP
		                  |FROM
		                  |	Catalog.Addresses AS Addresses
		                  |WHERE
		                  |	Addresses.Ref = &ShipTo");
		Query.SetParameter("ShipTo", ShipTo);
	EndIf;
	
	QueryResult = Query.Execute();	
	Dataset = QueryResult.Unload();
	
	// If no data found - rturn empty structure
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
	CityStateZIP = Dataset[0].City + " " + Dataset[0].State + " " + Dataset[0].ZIP;
	
	If Type = "UsBill" Then
		Info.Insert("UsCode", Company.Code);
		Info.Insert("UsName", Company.Description);	
		Info.Insert("UsBillLine1", Dataset[0].AddressLine1);
		Info.Insert("UsBillLine2", Dataset[0].AddressLine2);	
		Info.Insert("UsBillLine1Line2", Line1Line2);
		Info.Insert("UsBillCity", Dataset[0].City);
		Info.Insert("UsBillState", Dataset[0].State);
		Info.Insert("UsBillZIP", Dataset[0].ZIP);
		Info.Insert("UsBillCityStateZIP", CityStateZIP);
		Info.Insert("UsBillCountry", Dataset[0].Country);
		Info.Insert("UsBillEmail", Dataset[0].Email);
		Info.Insert("UsBillPhone", Dataset[0].Phone);
		Info.Insert("UsBillFax", Dataset[0].Fax);
		Info.Insert("UsBillFirstName", Dataset[0].FirstName);
		Info.Insert("UsBillMiddleName", Dataset[0].MiddleName);
		Info.Insert("UsBillLastName", Dataset[0].Lastname);
	ElsIf Type = "ThemShip" Then
        Info.Insert("ThemCode", Company.Code);
		Info.Insert("ThemName", Company.Description);	
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
	EndIf;

	Return Info;
	
EndFunction
