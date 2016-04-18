
&AtClient
Procedure ListOnActivateRow(Item)
	//Item = Items.List.CurrentData;
	//If NOT ValueIsFilled(NewItemDescription) and Item <> Undefined Then
	//	NewItemDescription = Item.Description;	
	//EndIf; 
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//If Parameters.Save Then
	//	ThisForm.CloseOnChoice = False;
	//EndIf; 
	
EndProcedure

&AtServer
Procedure AddNewItemAtServer()

	//Query = New Query("SELECT
	//                  |	UserSettings.Ref
	//                  |FROM
	//                  |	Catalog.UserSettings AS UserSettings
	//                  |WHERE
	//                  |	UserSettings.ObjectID = &ObjectID
	//                  |	AND UserSettings.Type = VALUE(Enum.UserSettingsTypes.ReportSetting)
	//                  |	AND (UserSettings.AvailableToAllUsers = TRUE OR UserSettings.User = &User)");
	//				  
	//Query.SetParameter("ObjectID",Parameters.ObjectID);
	////Query.SetParameter("User",Parameters.ObjectID);
	////Result = Query.Execute().Select();
	////If Result.Next() Then
	////	CurObj = Result.Ref.GetObject();
	////Else	
	////	CurObj = Catalogs.UserSettings.CreateItem();	
	////    CurObj.ObjectID = ObjectTypeID;
	////	CurObj.AvailableToAllUsers = True;
	////	CurObj.Type = Enums.UserSettingsTypes.PagePrintSetting;
	////EndIf; 
	
EndProcedure

&AtClient
Procedure AddNewItem(Command)
	AddNewItemAtServer();
EndProcedure
