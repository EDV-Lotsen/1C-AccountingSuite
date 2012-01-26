//////////////////////////////////////////////////////////////////////////////// 
// THIS MODULE CONTAINS FUNCTIONS AND PROCEDURES USED BY
// THE BRAZIL FINANCIAL LOCALIZATION FUNCTIONALITY
// 


// Selects an item's group for ICMS tax (Impostos Sobre Circulação de Mercadorias e Prestação de
// Serviços) calculation.
//
// Parameters:
// Catalogs.Items - an item for which the function selects its item group.
//
// Returned value:
// Catalogs.ICMSProductGroups.
// A item's ICMS product group (for example: soft drinks, vehicle spare parts, ...).
//
Function GetProductGroup(Product) Export
	
	Query = New Query("SELECT
	                  |	Products.ICMSProductGroup
	                  |FROM
	                  |	Catalog.Products AS Products
	                  |WHERE
	                  |	Products.Ref = &Product");
	
	Query.SetParameter("Product", Product);
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return 0;
	Else
		Dataset = QueryResult.Unload();
		Return Dataset[0][0];
	EndIf;
	
EndFunction


// Selects an ICMS tax rate from the tax table, or if not found returns a default value from
//the constant.
//
// Parameters:
// CFOP - a CFOP transaction type code (Código Fiscal de Operações e Prestações).
// ProductGroup - a product group.
// StateOrigin - state where the product is shipped from.
// StateDestination - state where the product is being shipped.
//
// Returned value:
// Number.
// A corresponding ICMS tax rate if found in the table, or a default rate retrieved from the constant.
//
Function GetICMSTaxRate(CFOP, ProductGroup, StateOrigin, StateDestination) Export
	
	Query = New Query ("SELECT
	                   |	ICMSTaxTable.TaxRate
	                   |FROM
	                   |	Catalog.ICMSTaxTable AS ICMSTaxTable
	                   |WHERE
	                   |	ICMSTaxTable.CFOP = &CFOP
	                   |	AND ICMSTaxTable.ProductGroup = &ProductGroup
	                   |	AND ICMSTaxTable.StateOrigin = &StateOrigin
	                   |	AND ICMSTaxTable.StateDestination = &StateDestination");
		
	Query.SetParameter("CFOP", CFOP);
	Query.SetParameter("ProductGroup", ProductGroup);
	Query.SetParameter("StateOrigin", StateOrigin);
	Query.SetParameter("StateDestination", StateDestination);
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return Constants.BrazilICMSTaxDefault.Get();
	Else
		Dataset = QueryResult.Unload();
		Return Dataset[0][0];
	EndIf;
	
EndFunction

// Selects a company's geographic state - used for retrieving "ship from" and "ship to"
// states which are then used
// in selecting an ICMS tax rate from the tax table.
//
// Parameters:
// Company - a company for which the function retrieves its state.
//
// Returned value:
// Catalogs.States.
// A company's state (for example: Sao Paulo, Rio De Janeiro, ...).
//
Function GetState(Company) Export
	
	Query = New Query("SELECT
	                  |	Companies.State AS State
	                  |FROM
	                  |	Catalog.Companies AS Companies
	                  |WHERE
	                  |	Companies.Ref = &Company");
	
	Query.SetParameter("Company", Company);
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return 0;
	Else
		Dataset = QueryResult.Unload();
		Return Dataset[0][0];
	EndIf;
	
EndFunction


