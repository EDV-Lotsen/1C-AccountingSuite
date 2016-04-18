
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//Load paper sizes
	PageSizes = GetCommonTemplate("PageSizes");
	For i = 1 to PageSizes.TableHeight Do 
		PageSizeTitle = StrReplace(TrimAll(PageSizes.Area(i, 1, i, 1).Text), ";", "");
		Items.PageSize.ChoiceList.Add(PageSizeTitle, PageSizeTitle);
	EndDo;
	
	PageSetupStructure 	= new Structure("PageSize, PrintPageOrientation, LeftMargin, RightMargin, TopMargin, BottomMargin, HeaderSize, FooterSize, PrintScale, 
	|FitToPage, PerPage, BlackAndWhite", "Letter", 0, 31.75, 31.75, 25.4, 25.4, 0, 0, 100, True, 1, True); //PageOrientation = Portrait
	
	ObjectTypeID = Parameters.ObjectTypeID;
	PrintPageSetupVS = PrintFormFunctions.GetFromUserSetting(ObjectTypeID);
	
	If PrintPageSetupVS <> Undefined Then
		PPS					= PrintPageSetupVS.Get();
		If TypeOf(PPS) = Type("Structure") Then
			FillPropertyValues(PageSetupStructure, PPS);
		EndIf;
	EndIf;
	
	If ObjectTypeID = "Document.Check (Check)" Or ObjectTypeID = "Document.InvoicePayment (Check)" Then
		PageSetupStructure.LeftMargin = 17 + Constants.CheckHorizontalAdj.Get();
		PageSetupStructure.TopMargin = 15 + Constants.CheckVerticalAdj.Get()
	EndIf;
	
	FillPropertyValues(ThisForm, PageSetupStructure);
	PrintingOption = ?(BlackAndWhite, 1, 0);
	If FitToPage Then
		PrintScaling = 1;
	Else
		PrintScaling = 0;
	EndIf;
	LeftMarginInches	= LeftMargin/25.4;
	RightMarginInches	= RightMargin/25.4;
	TopMarginInches		= TopMargin/25.4;
	BottomMarginInches	= BottomMargin/25.4;
	HeaderSizeInches	= HeaderSize/25.4;
	FooterSizeInches	= FooterSize/25.4;
	
EndProcedure

&AtServer
Procedure SavePageSetupAtServer()
	
	If Not AccessRight("SaveUserData", Metadata) Then
		return;
	EndIf;
	//PageSetupStructure	= new Structure("PrintPageOrientation, LeftMargin, RightMargin, TopMargin, BottomMargin, HeaderSize, FooterSize, PrintScale, 
	//|PerPage, BlackAndWhite");
	PageSetupStructure	= new Structure("PageSize, PrintPageOrientation, LeftMargin, RightMargin, TopMargin, BottomMargin, HeaderSize, FooterSize, PrintScale, 
	|FitToPage, PerPage, BlackAndWhite");
	FillPropertyValues(PageSetupStructure, ThisForm);
	PageSetupStructure.BlackAndWhite = ?(PrintingOption = 1, True, False);
	PageSetupStructure.LeftMargin		= LeftMarginInches*25.4;
	PageSetupStructure.RightMargin		= RightMarginInches*25.4;
	PageSetupStructure.TopMargin		= TopMarginInches*25.4;
	PageSetupStructure.BottomMargin	= BottomMarginInches*25.4;
	PageSetupStructure.HeaderSize		= HeaderSizeInches*25.4;
	PageSetupStructure.FooterSize		= FooterSizeInches*25.4;
	PrintPageSetupVS	= new ValueStorage(PageSetupStructure);
	//If AccessRight("SaveUserData", Metadata) Then
	//	CommonSettingsStorage.Save("PrintFormSettings",, PrintPageSetupVS);
	//EndIf;
	
	BeginTransaction();
	Query = New Query("SELECT
	                  |	UserSettings.Ref
	                  |FROM
	                  |	Catalog.UserSettings AS UserSettings
	                  |WHERE
	                  |	UserSettings.ObjectID = &ObjectID
	                  |	AND UserSettings.Type = VALUE(Enum.UserSettingsTypes.PagePrintSetting)
	                  |	AND UserSettings.AvailableToAllUsers = TRUE");
					  
	Query.SetParameter("ObjectID",ObjectTypeID);
	Result = Query.Execute().Select();
	If Result.Next() Then
		USObj = Result.Ref.GetObject();
	Else	
		USObj = Catalogs.UserSettings.CreateItem();	
	    USObj.ObjectID = ObjectTypeID;
		USObj.AvailableToAllUsers = True;
		USObj.Type = Enums.UserSettingsTypes.PagePrintSetting;
	EndIf; 
	USObj.SettingValue = PrintPageSetupVS;
	USObj.Write();
	
	If ObjectTypeID = "Document.Check (Check)" Or ObjectTypeID = "Document.InvoicePayment (Check)" Then
		Constants.CheckHorizontalAdj.Set(PageSetupStructure.LeftMargin - 17);
		Constants.CheckVerticalAdj.Set(PageSetupStructure.TopMargin - 15);
	EndIf;
	
	CommitTransaction();
	
EndProcedure

&AtClient
Procedure CommandOK(Command)
	
	SavePageSetupAtServer();
	
	Close(DialogReturnCode.OK);
	
EndProcedure

&AtClient
Procedure CommandPrint(Command)
	
	SavePageSetupAtServer();
	
	Close("PrintReport");
	
EndProcedure

&AtClient
Procedure PrintScalingOnChange(Item)
	
	If PrintScaling = 0 Then
		FitToPage = False;
	Else
		FitToPage = True;
	EndIf;
	
EndProcedure



