
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Update prices presentation.
	PriceFormat = GeneralFunctionsReusable.DefaultPriceFormat();
	Items.Price.Format = PriceFormat;
	Items.Cost.Format  = PriceFormat;
	
EndProcedure
