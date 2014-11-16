#Region PUBLIC_INTERFACE

//Returns calculated sales tax across sales tax rate components
// Parameters:
//  TaxableSubtotal - Number - defines sales tax taxable amount
//  SalesTaxRate    - CatalogRef.SalesTaxRates - defines sales tax agency and rate. If Combined defines combination of agencies and respective rates
//
// Returns:
//  Array - returns calculated total amount of sales tax and across sales tax agencies
//   * Structure
//    * Agency  - CatalogRef.SalesTaxAgencies
//    * Rate	- Number
//    * Amount	- Number
Function CalculateSalesTax(TaxableSubtotal, SalesTaxRate, CurrentAgenciesRates = Undefined) Export
	If Not ValueIsFilled(SalesTaxRate) Then
		return New Array();
	EndIf;
	
	If CurrentAgenciesRates = Undefined Then
		Request = New Query("SELECT
		                    |	SalesTaxRates.Agency,
		                    |	SalesTaxRates.Rate AS Rate,
		                    |	CAST(0 AS NUMBER(17, 2)) AS Amount,
		                    |	SalesTaxRates.Ref AS SalesTaxRate,
		                    |	SalesTaxRates.SalesTaxComponent
		                    |FROM
		                    |	Catalog.SalesTaxRates AS SalesTaxRates
		                    |WHERE
		                    |	(SalesTaxRates.Parent = &SalesRate
		                    |			OR SalesTaxRates.Ref = &SalesRate)
		                    |	AND SalesTaxRates.CombinedTaxRate = FALSE
		                    |
		                    |ORDER BY
		                    |	Rate");
		Request.SetParameter("SalesRate", SalesTaxRate);
		AgenciesRatesVT = Request.Execute().Unload();
		AgenciesRates = CommonUse.ValueTableToArray(AgenciesRatesVT);
	Else
		For Each CurrentAgencyRate In CurrentAgenciesRates Do
			CurrentAgencyRate.Insert("Amount", 0);
		EndDo;
		AgenciesRates = CurrentAgenciesRates;
	EndIf;
	For Each AgencyRate IN AgenciesRates Do
		AgencyRate.Amount = ROUND(TaxableSubtotal * AgencyRate.Rate / 100, 2);
	EndDo;
	return AgenciesRates;
	
EndFunction

////Returns sales tax agencies and rates
// Parameters:
//  SalesTaxRate    - CatalogRef.SalesTaxRates - defines sales tax agency and rate. If Combined defines combination of agencies and respective rates
//
// Returns:
//  Array - returns template of sales tax across sales tax agencies
//   * Structure
//    * Agency  - CatalogRef.SalesTaxAgencies
//    * Rate	- Number
//    * Amount	- Number
Function GetCurrentAgenciesRates(SalesTaxRate) Export
	Request = New Query("SELECT
	                    |	SalesTaxRates.Agency,
	                    |	SalesTaxRates.Rate AS Rate,
	                    |	CAST(0 AS NUMBER(17, 2)) AS Amount,
	                    |	SalesTaxRates.Ref AS SalesTaxRate,
	                    |	SalesTaxRates.SalesTaxComponent
	                    |FROM
	                    |	Catalog.SalesTaxRates AS SalesTaxRates
	                    |WHERE
	                    |	(SalesTaxRates.Parent = &SalesRate
	                    |			OR SalesTaxRates.Ref = &SalesRate)
	                    |	AND SalesTaxRates.CombinedTaxRate = FALSE
	                    |
	                    |ORDER BY
	                    |	Rate");
	Request.SetParameter("SalesRate", SalesTaxRate);
	AgenciesRatesVT = Request.Execute().Unload();
	AgenciesRates = CommonUse.ValueTableToArray(AgenciesRatesVT);
	return AgenciesRates;
EndFunction

//Returns list of sales tax rates
Function GetSalesTaxRatesList() Export
	Request = New Query("SELECT
	                    |	SalesTaxRates.Ref AS Ref,
	                    |	SalesTaxRates.Presentation
	                    |FROM
	                    |	Catalog.SalesTaxRates AS SalesTaxRates
	                    |WHERE
	                    |	SalesTaxRates.Parent = VALUE(Catalog.SalesTaxRates.EmptyRef)
	                    |
	                    |ORDER BY
	                    |	Ref");
	TaxRatesTab = Request.Execute().Unload();
	RatesList = New ValueList();
	For Each TaxRate In TaxRatesTab Do
		RatesList.Add(TaxRate.Ref, TaxRate.Presentation);
	EndDo;	
	//No sales tax
	RatesList.Add(Catalogs.SalesTaxRates.EmptyRef(), "No sales tax (0%)");
	return RatesList;
EndFunction

//Determines whether document's sales tax rate is inactive (differs from what is stored in the catalog)
// Parameters:
//  SalesTaxRate - CatalogRef.SalesTaxRates
//  AgenciesRates - Array - array of agencies and rates
//   * AgencyRate - Structure - contains agency and rate combination
//    * Agency 	- CatalogRef.Agencies - Agency
//    * Rate	- Number - Rate
// Returns:
//  Boolean - True if inactive 
Function DocumentSalesTaxRateIsInactive(SalesTaxRate, AgenciesRates) Export
	//Empty sales tax rate is not inactive
	If SalesTaxRate = Catalogs.SalesTaxRates.EmptyRef() Then
		return False;
	EndIf;
	AgenciesRatesVT = New ValueTable();
	STAType = New TypeDescription("CatalogRef.SalesTaxAgencies");
	QN 		= New NumberQualifiers(4,2);
	NumberType = New TypeDescription("Number", , QN);
	AgenciesRatesVT.Columns.Add("Agency", STAType);
	AgenciesRatesVT.Columns.Add("Rate", NumberType);
	For Each AgencyRate In AgenciesRates Do
		NewRow = AgenciesRatesVT.Add();
		FillPropertyValues(NewRow, AgencyRate);
	EndDo;
	Request = New Query("SELECT
	                    |	DocumentAgenciesRates.Agency,
	                    |	DocumentAgenciesRates.Rate
	                    |INTO DocumentAgenciesRates
	                    |FROM
	                    |	&DocumentAgenciesRates AS DocumentAgenciesRates
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	SalesTaxRates.Agency,
	                    |	SalesTaxRates.Rate
	                    |INTO NewAgenciesRates
	                    |FROM
	                    |	Catalog.SalesTaxRates AS SalesTaxRates
	                    |WHERE
	                    |	(SalesTaxRates.Ref = &SalesTax
	                    |			OR SalesTaxRates.Parent = &SalesTax)
	                    |	AND SalesTaxRates.CombinedTaxRate = FALSE
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	1 AS Field1
	                    |FROM
	                    |	NewAgenciesRates AS NewAgenciesRates
	                    |		FULL JOIN DocumentAgenciesRates AS DocumentAgenciesRates
	                    |		ON NewAgenciesRates.Agency = DocumentAgenciesRates.Agency
	                    |			AND NewAgenciesRates.Rate = DocumentAgenciesRates.Rate
	                    |WHERE
	                    |	(DocumentAgenciesRates.Agency IS NULL 
	                    |			OR NewAgenciesRates.Agency IS NULL )");
	Request.SetParameter("SalesTax", SalesTaxRate);
	Request.SetParameter("DocumentAgenciesRates", AgenciesRatesVT);
	return Not Request.Execute().IsEmpty();
EndFunction

//Returns the presentation of a sales tax rate item
// Parameters:
//  Description - String - the description of an item
//  Rate		- Number - the rate of an item
// Returns:
//  String - the Presentation of an item
Function GetSalesTaxRatePresentation(Description, Rate) Export
	return Description + " (" + Format(Rate, "NZ=") + "%)";
EndFunction

//Returns the default sales tax rate for given company
// Parameters:
//  Company - CatalogRef.Companies - given company
// Returns:
//  CatalogRef.SalesTaxRates - default sales tax rate
Function GetDefaultSalesTaxRate(Company) Export
	If Not GeneralFunctionsReusable.FunctionalOptionValue("SalesTaxCharging") Then
		return Catalogs.SalesTaxRates.EmptyRef();
	EndIf;
	
	Request = New Query("SELECT
	                    |	CompanySettings.Taxable AS CompanyIsTaxable,
	                    |	CompanySettings.SalesTaxRate AS CompanySalesTaxRate,
	                    |	SalesTaxDefault.Value AS DefaultSalesTaxRate
	                    |FROM
	                    |	(SELECT
	                    |		Companies.Taxable AS Taxable,
	                    |		Companies.SalesTaxRate AS SalesTaxRate
	                    |	FROM
	                    |		Catalog.Companies AS Companies
	                    |	WHERE
	                    |		Companies.Ref = &Company) AS CompanySettings,
	                    |	Constant.SalesTaxDefault AS SalesTaxDefault");
	Request.SetParameter("Company", Company);
	Sel = Request.Execute().Select();
	Sel.Next();
	If Sel.CompanyIsTaxable Then
		return ?(ValueIsFilled(Sel.CompanySalesTaxRate), Sel.CompanySalesTaxRate, Sel.DefaultSalesTaxRate);
	Else
		return Catalogs.SalesTaxRates.EmptyRef();
	EndIf;
EndFunction
#EndRegion