
&AtClient
Procedure LineItemOnChange(Item)
	
	Item.CurrentData.Total = Item.CurrentData.Jan + Item.CurrentData.Feb + Item.CurrentData.Mar + Item.CurrentData.Apr + Item.CurrentData.May + Item.CurrentData.Jun + Item.CurrentData.Jul + Item.CurrentData.Aug + Item.CurrentData.Sep + Item.CurrentData.Oct + Item.CurrentData.Nov + Item.CurrentData.Dec;	
	LineItemOnChangeAtServer();
EndProcedure

&AtServer
Procedure LineItemOnChangeAtServer()
	// Insert handler contents.
	
EndProcedure

&AtClient
Procedure LineItemTotalOnChange(Item)
	
TabularPartRow = Items.LineItem.CurrentData;	
DivisionVal = TabularPartRow.Total / 12;

TabularPartRow.Jan = DivisionVal;
TabularPartRow.Feb = DivisionVal; 
TabularPartRow.Mar = DivisionVal;
TabularPartRow.Apr = DivisionVal;
TabularPartRow.May = DivisionVal;
TabularPartRow.Jun = DivisionVal;
TabularPartRow.Jul = DivisionVal;
TabularPartRow.Aug = DivisionVal;
TabularPartRow.Sep = DivisionVal;
TabularPartRow.Oct = DivisionVal;
TabularPartRow.Nov = DivisionVal;
TabularPartRow.Dec = DivisionVal;
EndProcedure


