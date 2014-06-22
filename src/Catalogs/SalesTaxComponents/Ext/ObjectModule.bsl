
Procedure OnWrite(Cancel)
	If DataExchange.Load Then
		return;
	EndIf;
	Request = New Query("SELECT
	                    |	SalesTaxRates.Ref,
	                    |	SalesTaxRates.Parent
	                    |INTO TaxRatesAffected
	                    |FROM
	                    |	Catalog.SalesTaxRates AS SalesTaxRates
	                    |WHERE
	                    |	SalesTaxRates.SalesTaxComponent = &SalesTaxComponent
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT DISTINCT
	                    |	TaxRatesAffected.Ref
	                    |FROM
	                    |	TaxRatesAffected AS TaxRatesAffected
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	SalesTaxRates.Ref,
	                    |	SalesTaxRates.Parent,
	                    |	SalesTaxRates.Rate
	                    |FROM
	                    |	TaxRatesAffected AS TaxRatesAffected
	                    |		INNER JOIN Catalog.SalesTaxRates AS SalesTaxRates
	                    |		ON (TaxRatesAffected.Ref = SalesTaxRates.Ref
	                    |				OR (TaxRatesAffected.Parent = SalesTaxRates.Ref
	                    |					OR TaxRatesAffected.Parent = SalesTaxRates.Parent)
	                    |					AND TaxRatesAffected.Parent <> VALUE(Catalog.SalesTaxRates.EmptyRef))");
	Request.SetParameter("SalesTaxComponent", Ref);
	ResArray		= Request.ExecuteBatch();
	//Lock all sales tax rates affected
	RefsForLock		= ResArray[2].Unload();
	TaxRatesLock	= New DataLock();
	TaxRatesLockItem = TaxRatesLock.Add("Catalog.SalesTaxRates");
	TaxRatesLockItem.DataSource = RefsForLock;
	TaxRatesLockItem.UseFromDataSource("Ref", "Ref");
	TaxRatesLockItem.Mode = DataLockMode.Exclusive;
	TaxRatesLock.Lock();
	
	//First process sales tax rates components and after that recalculate total tax rate of combined sales tax rates items
	ComponentsToProcess 	= ResArray[1].Unload();
	
	For Each ComponentRate In ComponentsToProcess Do
		ComponentTaxRateObject 				= ComponentRate.Ref.GetObject();
		ComponentTaxRateObject.Description 	= Description;
		ComponentTaxRateObject.Agency 		= Agency;
		ComponentTaxRateObject.Rate			= Rate;
		ComponentTaxRateObject.Write();
	EndDo;
	
	//Execute query for the second time, after data locks are applied
	//to calculate total rates
		
	//Recalculating totals of the affected combined tax rates
	CombinedTaxRates = Request.Execute().Unload();
	CombinedTaxRates.GroupBy("Parent", "Rate");
	For Each CombinedTaxRate In CombinedTaxRates Do
		If CombinedTaxRate.Parent = Catalogs.SalesTaxRates.EmptyRef() Then
			Continue;
		EndIf;
		CombinedTaxRateObject = CombinedTaxRate.Parent.GetObject();
		CombinedTaxRateObject.Rate = CombinedTaxRate.Rate;
		CombinedTaxRateObject.Write();
	EndDo;	
EndProcedure
