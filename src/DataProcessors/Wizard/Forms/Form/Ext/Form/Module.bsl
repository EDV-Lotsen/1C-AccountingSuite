
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Try
		Stop = Not Parameters.RunFromFirstLaunch;
	Except
		Stop = Constants.FirstLaunch.Get();
	EndTry;	
	If Stop Then
		Message("Wizard can be run on first launch.");
		Cancel = True;
		Return;
	EndIf;	
	///////////// PREDEFINED SETTINGS TO SKIP PAGES /////////////
	ProductOrService = "Both";
	PricePrecision = 2;
	////////////////////////////////////////////////////////////
	
	MaxPageCounter = 1;
	MainAttributesTable.Clear();
	MainTableSettingList = DataProcessors.Wizard.GetTemplate("MainTableSettingList");
	For Count = 2 to MainTableSettingList.TableHeight Do 
		MainSettingsRow = MainAttributesTable.Add();
		MainSettingsRow.Order = Number(MainTableSettingList.Area(count,1,count,1).Text);
		MainSettingsRow.Active = ?(TrimAll(MainTableSettingList.Area(count,2,count,2).Text) = "1",True,False);
		MainSettingsRow.TabName = TrimAll(MainTableSettingList.Area(count,3,count,3).Text);
		MainSettingsRow.BackName = TrimAll(MainTableSettingList.Area(count,4,count,4).Text);
		MainSettingsRow.NextName = TrimAll(MainTableSettingList.Area(count,5,count,5).Text);
		MainSettingsRow.OnClose = TrimAll(MainTableSettingList.Area(count,6,count,6).Text);
		MainSettingsRow.OnOpen = TrimAll(MainTableSettingList.Area(count,7,count,7).Text);
		
		CurActive = MainSettingsRow.Active;
		If (MainSettingsRow.Order > MaxPageCounter) And CurActive Then 
			MaxPageCounter = MainSettingsRow.Order;
		EndIf;
	EndDo;
	
	PageCounter = 0;
	NextAtServer();
	
	Items.PricePrecisionVisibleGroup.Visible = UsePricePrecision;
	Items.QuantityPrecisionVisibleGroup.Visible = UseQuantityPrecision;
	
	ConstantSetNamesListStage1.Clear();
	ConstantSetNamesListStage1.Add("SystemTitle");
	ConstantSetNamesListStage1.Add("FederalTaxID");
	ConstantSetNamesListStage1.Add("StateTaxID");
	ConstantSetNamesListStage1.Add("FirstName");
	ConstantSetNamesListStage1.Add("MiddleName");
	ConstantSetNamesListStage1.Add("LastName");
	ConstantSetNamesListStage1.Add("Phone");
	ConstantSetNamesListStage1.Add("Cell");
	ConstantSetNamesListStage1.Add("Fax");
	ConstantSetNamesListStage1.Add("ZIP");
	ConstantSetNamesListStage1.Add("Country");
	ConstantSetNamesListStage1.Add("State");
	ConstantSetNamesListStage1.Add("City");
	ConstantSetNamesListStage1.Add("AddressLine2");
	ConstantSetNamesListStage1.Add("AddressLine1");
	ConstantSetNamesListStage1.Add("Website");
	
	
	ConstantSetNamesListStage2.Clear();
	ConstantSetNamesListStage2.Add("FirstMonthOfFiscalYear");
	
	
	ConstantSetNamesListStage3.Clear();
	ConstantSetNamesListStage3.Add("SalesTaxCharging");
	ConstantSetNamesListStage3.Add("MultiLocation");
	ConstantSetNamesListStage3.Add("EnableAssembly");
	ConstantSetNamesListStage3.Add("EnableLots");
	ConstantSetNamesListStage3.Add("EnhancedInventoryShipping");
	ConstantSetNamesListStage3.Add("EnhancedInventoryReceiving");
	
	
	ConstantSetNamesListStage4.Clear();
	ConstantSetNamesListStage4.Add("UsePricePrecision");
	ConstantSetNamesListStage4.Add("PricePrecision");
	ConstantSetNamesListStage4.Add("QtyPrecision");
	
	For Each ConstName in ConstantSetNamesListStage1 Do 
		CurConstantsSet[ConstName.Value] = Constants[ConstName.Value].Get();
	EndDo;
	
	For Each ConstName in ConstantSetNamesListStage2 Do 
		CurConstantsSet[ConstName.Value] = Constants[ConstName.Value].Get();
	EndDo;
	
	For Each ConstName in ConstantSetNamesListStage3 Do 
		CurConstantsSet[ConstName.Value] = Constants[ConstName.Value].Get();
	EndDo;
	
	For Each ConstName in ConstantSetNamesListStage4 Do 
		CurConstantsSet[ConstName.Value] = Constants[ConstName.Value].Get();
	EndDo;
	
	
EndProcedure

&AtClient
Procedure StepsOnCurrentPageChange(Item, CurrentPage)
	StepsOnCurrentPageChangeAtServer();
EndProcedure

&AtServer
Procedure StepsOnCurrentPageChangeAtServer()
	// Insert handler contents.
EndProcedure

&AtClient
Procedure Back(Command)
	BackAtServer();
EndProcedure

&AtServer
Procedure BackAtServer()
	
	If PageCounter = 1 Then 
		//Items.Back.Visible = False;
		Return;
	EndIf;	
	PageCounter = PageCounter - 1;
	Filter = New Structure("Order",PageCounter);
	NextPages = MainAttributesTable.FindRows(Filter);
	If NextPages.Count() = 0 Then 
		BackAtServer();
	ElsIf NextPages[0].Active Then
		SkipPage = False;
		If TrimAll(NextPages[0].OnOpen) <> "" Then 
			Execute NextPages[0].OnOpen;
		EndIf;	
		If SkipPage Then 
			BackAtServer();
		Else 	
			FillCurrentPage(NextPages[0]);
		EndIf;
	Else 
		BackAtServer();
	EndIf;	
	
EndProcedure

&AtClient
Procedure Next(Command)
	NextAtServer();
EndProcedure

&AtServer
Procedure NextAtServer()
	If PageCounter = MaxPageCounter Then 
		//Items.Next.Visible = False;
		//Return;
	Else 	
		PageCounter = PageCounter + 1;
	EndIf;	
	
	Filter = New Structure("Order",PageCounter);
	NextPages = MainAttributesTable.FindRows(Filter);
	If ProcedureToExecute <> "" Then 
		Execute ProcedureToExecute;
	EndIf;	
	If NextPages.Count() = 0 Then 
		NextAtServer();
	ElsIf NextPages[0].Active Then
		SkipPage = False;
		If TrimAll(NextPages[0].OnOpen) <> "" Then 
			Execute NextPages[0].OnOpen;
		EndIf;	
		If SkipPage Then 
			NextAtServer();
		Else 	
			FillCurrentPage(NextPages[0]);
		EndIf;	
	Else 
		NextAtServer();
	EndIf;
EndProcedure

&AtServer
Procedure FillCurrentPage(RowOfPage)
	
	Items.ProgressMessage.Title = "Page #" + PageCounter + " of " +MaxPageCounter;
	
	Items.Next.Visible = ValueIsFilled(RowOfPage.NextName);
	Items.Back.Visible = ValueIsFilled(RowOfPage.BackName);
	
	For Each SubPage in Items.Steps.ChildItems Do 
		SubPage.Visible = False;
	EndDo;
	
	Items[RowOfPage.TabName].Visible = True;
	//MessageToUser = RowOfPage.MainMessageText;
	Items.Back.Title = TrimAll(RowOfPage.BackName);
	Items.Next.Title = TrimAll(RowOfPage.NextName);
	ProcedureToExecute = RowOfPage.OnClose;
	
EndProcedure	

//////////////////////// Regular Event processing /////////////////////////////
&AtClient
Procedure UsePricePrecisionOnChange(Item)
	Items.PricePrecisionVisibleGroup.Visible = CurConstantsSet.UsePricePrecision;
	If Not CurConstantsSet.UsePricePrecision  Then 
		CurConstantsSet.PricePrecision = 2;
	EndIf;	
EndProcedure

&AtClient
Procedure UseQuantityPrecisionOnChange(Item)
	Items.QuantityPrecisionVisibleGroup.Visible = UseQuantityPrecision;
	If Not UseQuantityPrecision  Then 
		CurConstantsSet.QtyPrecision = 0;
	EndIf;	
EndProcedure


//////////////////////// Reusable Event Processing ////////////////////////////
&AtServer
Procedure ProcessChartOfAccounts()
	GeneralFunctions.CreateChartOfAccounts(EntityType, CurConstantsSet.EnhancedInventoryReceiving);	
EndProcedure	

&AtServer
Procedure CheckStage3()
	If ProductOrService = "Service-based" Then 
		SkipPage = True;
	EndIf;	
	
	Items.UseSalesTax.ReadOnly =  CurConstantsSet.SalesTaxCharging;
	Items.UseMultipleLocations.ReadOnly = CurConstantsSet.MultiLocation;
	Items.UseAssemby.ReadOnly = CurConstantsSet.EnableAssembly;
	Items.UseLotsSerialNumbers.ReadOnly = CurConstantsSet.EnableLots;
	Items.UseItemReceipts.ReadOnly = CurConstantsSet.EnhancedInventoryReceiving;
	Items.UseShipping.ReadOnly = CurConstantsSet.EnhancedInventoryShipping;
	
EndProcedure	

&AtServer
Procedure CheckStage4()
	If ProductOrService = "Service-based" Then 
		If CurConstantsSet.QtyPrecision < 2 Then 
			CurConstantsSet.QtyPrecision = 2;
		EndIf;	
	EndIf;	
	
	If CurConstantsSet.QtyPrecision  > 0 Then 
		UseQuantityPrecision = True;
	EndIf;	
	
	Items.UseQuantityPrecision.ReadOnly = (Constants.QtyPrecision.Get() > 0);
	Items.UsePricePrecision.ReadOnly = (Constants.PricePrecision.Get() > 2);
	
	Items.PricePrecision.MinValue = CurConstantsSet.PricePrecision;
	Items.PricePrecisionVisibleGroup.Visible = CurConstantsSet.UsePricePrecision;
	
	Items.QuantityPrecision.MinValue = CurConstantsSet.QtyPrecision;
	Items.QuantityPrecisionVisibleGroup.Visible = UseQuantityPrecision;
	
EndProcedure	

&AtServer
Procedure SaveStage1()
	
	For Each ConstName in ConstantSetNamesListStage1 Do 
		Constants[ConstName.Value].Set(CurConstantsSet[ConstName.Value]);
	EndDo;	
	
EndProcedure

&AtServer
Procedure SaveStage2()
	
	For Each ConstName in ConstantSetNamesListStage2 Do 
		Constants[ConstName.Value].Set(CurConstantsSet[ConstName.Value]);
	EndDo;	
	
EndProcedure

&AtServer
Procedure SaveStage3()
	
	For Each ConstName in ConstantSetNamesListStage3 Do 
		Constants[ConstName.Value].Set(CurConstantsSet[ConstName.Value]);
	EndDo;	
	
EndProcedure

&AtServer
Procedure SaveStage4()
	
	For Each ConstName in ConstantSetNamesListStage4 Do 
		Constants[ConstName.Value].Set(CurConstantsSet[ConstName.Value]);
	EndDo;	
		
EndProcedure

&AtServer
Procedure SaveLogo()
		
EndProcedure
