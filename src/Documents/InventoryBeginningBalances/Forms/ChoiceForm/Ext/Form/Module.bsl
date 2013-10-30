
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	 Items.Quantity.Format = "NFD=" + Constants.QtyPrecision.Get();
	 
EndProcedure
