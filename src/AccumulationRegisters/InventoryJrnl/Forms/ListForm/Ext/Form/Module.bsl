
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.Qty.Format = "NFD=" + Constants.QtyPrecision.Get();
	
EndProcedure
