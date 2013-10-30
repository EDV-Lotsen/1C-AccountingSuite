
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.User = Catalogs.UserList.EmptyRef() Then
		Object.User =  Catalogs.UserList.FindByDescription(GeneralFunctions.GetUserName());
		//Object.LogType = "Single";
	Endif;
	
	If Object.Ref = Documents.TimeTrack.EmptyRef() Then
		Object.LogType = "Single";
	Endif;
	
	LogTypeOnChangeAtServer();
EndProcedure

&AtClient
Procedure TaskOnChange(Item)
	TaskOnChangeAtServer();
EndProcedure

&AtServer
Procedure TaskOnChangeAtServer()
	// Insert handler contents.
	Object.Price = GeneralFunctions.RetailPrice(CurrentDate(),Object.Task,Catalogs.Companies.EmptyRef());
EndProcedure

&AtClient
Procedure DateToOnChange(Item)
	
	If Object.Ref.IsEmpty() Then		
		Object.DateTo = Object.DateFrom + 6*60*60*24;
		Items.day1.title = Format(Object.DateFrom,"DLF=D"); //+ 6*60*60*24;
		Items.day2.title = Format(Object.DateFrom + 1*60*60*24,"DLF=D");
		Items.day3.title = Format(Object.DateFrom + 2*60*60*24,"DLF=D");
		Items.day4.title = Format(Object.DateFrom + 3*60*60*24,"DLF=D");
		Items.day5.title = Format(Object.DateFrom + 4*60*60*24,"DLF=D");
		Items.day6.title = Format(Object.DateFrom + 5*60*60*24,"DLF=D");
		Items.day7.title = Format(Object.DateFrom + 6*60*60*24,"DLF=D");

	Endif;
	
EndProcedure

&AtClient
Procedure LogTypeOnChange(Item)
	LogTypeOnChangeAtServer();
EndProcedure

&AtServer
Procedure LogTypeOnChangeAtServer()
	
	If Object.LogType = "Single" Then
		Items.DateFrom.ToolTipRepresentation = ToolTipRepresentation.None;
		Items.DateTo.Visible = False;
		Items.DateFrom.Title = "Date";
		Items.Week.Visible = False;
	Else
		Object.TimeComplete = 0;
		Items.TimeComplete.ReadOnly = True;
		Items.DateFrom.ToolTip = "Make sure this day is a Monday.";
		Items.DateFrom.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
		Items.DateTo.Visible = True;
		Items.DateFrom.Title = "Date From";
		Items.DateTo.ReadOnly = True;
		Items.Week.Visible = True;
		Object.TimeComplete = Object.Mon + Object.Tue + Object.Wed + Object.Thur + Object.Fri + Object.Sat + Object.Sun;
	Endif;
	

EndProcedure

&AtClient
Procedure ReviseHours()
	
	If Object.LogType = "Week" Then
		Object.TimeComplete = Object.Mon + Object.Tue + Object.Wed + Object.Thur + Object.Fri + Object.Sat + Object.Sun;
	Endif;
	
EndProcedure

