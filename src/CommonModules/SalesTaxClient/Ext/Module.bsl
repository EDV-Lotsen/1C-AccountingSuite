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
		AgenciesRates = SalesTax.GetCurrentAgenciesRates(SalesTaxRate);
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
