
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Update prices presentation.
	PriceFormat = GeneralFunctionsReusable.DefaultPriceFormat();
	Items.Cost.Format = PriceFormat;
	
EndProcedure
