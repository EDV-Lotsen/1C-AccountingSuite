
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Items.Group1.Visible = Constants.UseExtendedDiscountsInPayments.Get();
EndProcedure
