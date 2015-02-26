
&AtClient
Procedure CheckReorderQty(Command)
	
	NotificationsServerFullRights.CheckReorderQty();
	Items.List.Refresh();
	
EndProcedure
