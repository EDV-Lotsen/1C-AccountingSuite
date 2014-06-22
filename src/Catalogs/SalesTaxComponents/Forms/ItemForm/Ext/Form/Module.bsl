
&AtClient
Procedure AfterWrite(WriteParameters)
	NotifyChanged(PredefinedValue("Catalog.SalesTaxRates.EmptyRef"));
EndProcedure
