
////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("PrintedForm") Then
		Record.PrintedForm = Parameters.PrintedForm;
	EndIf;
	
	GetFooterImages();
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region CONTROLS_EVENTS_HANDLERS

&AtClient
Procedure PrintedFormOnChange(Item)
	
	GetFooterImages();
	
EndProcedure

&AtClient
Procedure ShowDeliveryDateColumnOnChange(Item)
	
	If Record.ShowDeliveryDateColumn Then 
		Record.ShowLotColumn      = False;
		Record.ShowDiscountColumn = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowLotColumnOnChange(Item)
	
	If Record.ShowLotColumn Then 
		Record.ShowDeliveryDateColumn = False;
		Record.ShowDiscountColumn     = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowDiscountColumnOnChange(Item)
	
	If Record.ShowDiscountColumn Then 
		Record.ShowDeliveryDateColumn = False;
		Record.ShowLotColumn          = False;
	EndIf;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

&AtClient
Procedure UploadLeftImage(Command)

	FooterImageLeft = "";
	
	NotifyDescription = New NotifyDescription("FileUpload", ThisForm, NameFooterImageLeft);
	BeginPutFile(NotifyDescription,,"",True);
	
EndProcedure

&AtClient
Procedure UploadCenterImage(Command)
	
	FooterImageCenter = "";
	
	NotifyDescription = New NotifyDescription("FileUpload", ThisForm, NameFooterImageCenter);
	BeginPutFile(NotifyDescription,,"",True);
	
EndProcedure

&AtClient
Procedure UploadRightImage(Command)

	FooterImageRight = "";
	
	NotifyDescription = New NotifyDescription("FileUpload", ThisForm, NameFooterImageRight);
	BeginPutFile(NotifyDescription,,"",True);

EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

&AtServer
Function GetFooterImages()
	
	UpdateVisibility();
	
	//Attributes
	NameFooterImageLeft   = "";	
	NameFooterImageCenter = "";	
	NameFooterImageRight  = "";	
	
	FooterImageLeft   = "";
	FooterImageCenter = "";
	FooterImageRight  = "";
		
	If Record.PrintedForm = Enums.PrintedForms.StatementMainForm Then
		
		NameFooterImageLeft   = "StatementFooterLeft";	
		NameFooterImageCenter = "StatementFooterCenter";	
		NameFooterImageRight  = "StatementFooterRight";	
		
	ElsIf Record.PrintedForm = Enums.PrintedForms.AssemblyMainForm Then
		
		NameFooterImageLeft   = "AssemblyFooterLeft";	
		NameFooterImageCenter = "AssemblyFooterCenter";	
		NameFooterImageRight  = "AssemblyFooterRight";	
 
		//ElsIf Then
	EndIf;
	
	//FooterImageLeft
	BinaryLogo = GeneralFunctions.GetFooterPO(NameFooterImageLeft);
	If BinaryLogo <> Undefined Then 
		FooterImageLeft = PutToTempStorage(BinaryLogo);
		Items.FooterImageLeft.PictureSize = PictureSize.AutoSize;
	EndIf;
	
	//FooterImageCenter
	BinaryLogo = GeneralFunctions.GetFooterPO(NameFooterImageCenter);
	If BinaryLogo <> Undefined Then 
		FooterImageCenter = PutToTempStorage(BinaryLogo);
		Items.FooterImageCenter.PictureSize = PictureSize.AutoSize;
	EndIf;
	
	//FooterImageRight
	BinaryLogo = GeneralFunctions.GetFooterPO(NameFooterImageRight);
	If BinaryLogo <> Undefined Then 
		FooterImageRight = PutToTempStorage(BinaryLogo);
		Items.FooterImageRight.PictureSize = PictureSize.AutoSize;
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtServer
Function UpdateVisibility() 
	
	Items.EnvelopeSize.Visible           = True;
	Items.ShowEmail.Visible              = True;
	Items.ShowMobile.Visible             = True;
	Items.ShowWebsite.Visible            = True;
	Items.ShowFax.Visible                = True;
	Items.ShowFederalTaxID.Visible       = True;
	Items.ShowContactName.Visible        = True;
	Items.ShowCountry.Visible            = True;
	Items.ShowShipTo.Visible             = True;
	Items.ShowDeliveryDateColumn.Visible = True;
	Items.ShowLotColumn.Visible          = True;
	Items.ShowDiscountColumn.Visible     = True;
	
	If Record.PrintedForm = Enums.PrintedForms.StatementMainForm Then
		
		Items.ShowShipTo.Visible             = False;
		Items.ShowDeliveryDateColumn.Visible = False;
		Items.ShowLotColumn.Visible          = False;
		Items.ShowDiscountColumn.Visible     = False;
		
	ElsIf Record.PrintedForm = Enums.PrintedForms.AssemblyMainForm Then
		
		Items.EnvelopeSize.Visible           = False;
		Items.ShowFederalTaxID.Visible       = False;
		Items.ShowContactName.Visible        = False;
		Items.ShowCountry.Visible            = False;
		Items.ShowShipTo.Visible             = False;
		Items.ShowDeliveryDateColumn.Visible = False;
		Items.ShowLotColumn.Visible          = False;
		Items.ShowDiscountColumn.Visible     = False;
		
	EndIf;
	
EndFunction

&AtClient
Procedure FileUpload(a,b,c,d) Export
	
	PlaceImageFile(b, d);
	
	BinaryLogo = GeneralFunctions.GetFooterPO(d);
	TempStorageAddress = PutToTempStorage(BinaryLogo);
	
	If d = "StatementFooterLeft" 
		Or d = "AssemblyFooterLeft"
		//--//Or  
		Then
		FooterImageLeft = TempStorageAddress;
	ElsIf d = "StatementFooterCenter"
		Or d = "AssemblyFooterCenter" 
		//--//Or  
		Then  
		FooterImageCenter = TempStorageAddress;
	ElsIf d = "StatementFooterRight"
		Or d = "AssemblyFooterRight"
		//--//Or  
		Then  
		FooterImageRight = TempStorageAddress;
	EndIf;
	
EndProcedure

&AtServer
Procedure PlaceImageFile(TempStorageName, ImageName)
	
	If NOT TempStorageName = Undefined Then
	
		BinaryData = GetFromTempStorage(TempStorageName);
				
		NewRow = InformationRegisters.CustomPrintForms.CreateRecordManager();
		NewRow.ObjectName = ImageName;
		NewRow.TemplateName = ImageName;
		NewRow.Template = New ValueStorage(BinaryData, New Deflation(9));
		NewRow.Write();	
		DeleteFromTempStorage(TempStorageName);
		
	EndIf;
	  	
EndProcedure

#EndRegion