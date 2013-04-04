
////////////////////////////////////////////////////////////////////////////////
// Open Office Writer - specific functions

// Print form and template ref description
// Structure with the fields:
// ServiceManager - service manager, open office
// Desktop 		  - application Open Office (service UNO)
// Document 	  - document (print form)
// Type     	  - type of the print form ("ODT")
//
//

////////////////////////////////////////////////////////////////////////////////
// Export functions

Function InitializePrintFormOOWriter() Export
	
	Try
		ServiceManager = New COMObject("com.sun.star.ServiceManager");
	Except
		Raise(NStr("en = 'Connection with service manager error (com.sun.star.ServiceManager).""Contact system administrator.'"));
	EndTry;
	
	Try
		Desktop = ServiceManager.CreateInstance("com.sun.star.frame.Desktop");
	Except
		Raise(NStr("en = 'Run mode error of service Desktop (com.sun.star.frame.Desktop).""Contact system administrator.'"));
	EndTry;
	
	Parameters = GetComSafeArray();
#If Not WebClient Then
	Parameters.SetValue(0, ValueProperty(ServiceManager, "Hidden", True));
#EndIf
	
	Document = Desktop.LoadComponentFromURL("private:factory/swriter", "_blank", 0, Parameters);
	
#If WebClient Then
	Document.getCurrentController().getFrame().getContainerWindow().setVisible(False);
#EndIf

	// Prepare template ref
	Handler 				= New Structure("ServiceManager,Desktop,Document,Type");
	Handler.ServiceManager 	= ServiceManager;
	Handler.Desktop 		= Desktop;
	Handler.Document 		= Document;
	
	Return Handler;
	
EndFunction

// Parameters:
// LayoutBinaryData - BinaryData - template binary data
// Value returned:
// structure 		- ref template
//
Function GetOOWriterTemplate(Val TemplateBinaryData, TemporaryFileName) Export
	
	Handler = New Structure("ServiceManager,Desktop,Document,FileName");
	
	Try
		ServiceManager = New COMObject("com.sun.star.ServiceManager");
	Except
		Raise(NStr("en = 'Connection with service manager error (com.sun.star.ServiceManager).""Contact system administrator.'"));
	EndTry;
	
	Try
		Desktop = ServiceManager.CreateInstance("com.sun.star.frame.Desktop");
	Except
		Raise(NStr("en = 'Run mode error of service Desktop (com.sun.star.frame.Desktop).""Contact system administrator.'"));
	EndTry;
	
#If NOT WebClient Then
	TemporaryFileName = GetTempFileName("ODT");
	TemplateBinaryData.Write(TemporaryFileName);
#EndIf
	
	Parameters = GetComSafeArray();
#If Not WebClient Then
	Parameters.SetValue(0, ValueProperty(ServiceManager, "Hidden", True));
#EndIf
	
	Document = Desktop.LoadComponentFromURL("file:///" + TemporaryFileName, "_blank", 0, Parameters);
	
#If WebClient Then
	Document.getCurrentController().getFrame().getContainerWindow().setVisible(False);
#EndIf
	
	// Prepare template ref
	Handler.ServiceManager  = ServiceManager;
	Handler.Desktop 		= Desktop;
	Handler.Document 		= Document;
	Handler.FileName 		= TemporaryFileName;
	
	Return Handler;
	
EndFunction

Function GetComSafeArray()
	
#If WebClient Then	
	scr 			= New COMObject("MSScriptControl.ScriptControl");
	scr.language 	= "javascript";
	scr.eval("Array=new Array()");
	Return scr.eval("Array");
#Else
	Return New COMSafeArray("Vt_dispatch", 1);
#EndIf
	
EndFunction

Function CloseConnection(Handler, Val CloseApplication) Export
	
	If CloseApplication Then
		Handler.Document.Close(0);
	EndIf;
	
	Handler.Document 		= Undefined;
	Handler.Desktop 		= Undefined;
	Handler.ServiceManager 	= Undefined;
	ScriptControl 			= Undefined;
	
	If Handler.Property("FileName") Then
		DeleteFiles(Handler.FileName);
	EndIf;
	
	Handler = Undefined;
	
EndFunction

// Sets visibility property for OO Writer
// Handler - ref to the print form
//
Procedure ShowOOWriterDocument(Val Handler) Export
	
	ContainerWindow = Handler.Document.getCurrentController().getFrame().getContainerWindow();
	ContainerWindow.setVisible(True);
	ContainerWindow.setFocus();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Block of functions for operations with template

// Gets area from template.
// Parameters
// Handler 		- template ref
// AreaName 	- area name in template
// ShiftBegin 	- offset relative to area start
//					offset by default: 1 - area is taken without carriage return
//					char, after operator bracket of area opening
// ShiftEnding  - offset relative to area ending,
//					offset by default: -11 - means that area is taken without
//					carriage return char, before operator bracket of area ending
//
Function GetTemplateArea(Val Handler, Val AreaName) Export
	
	Result = New Structure("Document,Start,End");
	
	Result.Start 	= GetAreaBeginPosition(Handler.Document, AreaName);
	Result.End   	= GetAreaEndPosition(Handler.Document, AreaName);
	Result.Document = Handler.Document;
	
	Return Result;
	
EndFunction

Function GetTopFooterArea(Val TemplateRef) Export
	
	Return New Structure("Document, ServiceManager", TemplateRef.Document, TemplateRef.ServiceManager);
	
EndFunction

Function GetLowerFooterArea(TemplateRef) Export
	
	Return New Structure("Document, ServiceManager", TemplateRef.Document, TemplateRef.ServiceManager);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Block of functions for operations with print form

// Inserts break to a next line
// Parameters
// Handler - ref to the MS Word document where break need to be added
//
Procedure InsertBreakAtNewLine(Val Handler) Export
	
	oText 	= Handler.Document.getText();
	oCursor = oText.createTextCursor();
	oCursor.gotoEnd(False);
	oText.insertControlCharacter(oCursor, 0, False);
	
EndProcedure

Procedure AddHeader(Val PrintForm,
									Val Area) Export
	
	Template_oTxtCrsr  = SetMainCursorOnHeader(Area);
	While Template_oTxtCrsr.goRight(1, True) Do
	EndDo;
	TransferableObject = Area.Document.getCurrentController().Frame.controller.getTransferable();
	
	SetMainCursorOnHeader(PrintForm);
	PrintForm.Document.getCurrentController().insertTransferable(TransferableObject);
	
EndProcedure

Procedure AddFooter(Val PrintForm,
									Val Area) Export
	
	Template_oTxtCrsr  = SetMainCursorOnFooter(Area);
	While Template_oTxtCrsr.goRight(1, True) Do
	EndDo;
	TransferableObject = Area.Document.getCurrentController().Frame.controller.getTransferable();
	
	SetMainCursorOnFooter(PrintForm);
	PrintForm.Document.getCurrentController().insertTransferable(TransferableObject);
	
EndProcedure

// Adds area to the print form from template, at the same time
// replacing parameters in the area with the values from object data.
// Used when area is being output alone.
//
// Parameters
// PrintForm 	 - ref to the print form
// AreaHandler 	 - ref to the area in template.
// GoToNext_Line - boolean, if break should be inserted after area output
//
// Value returned:
// AreaCoordinates
//
Procedure JoinArea(Val PrintFormHandler,
							Val AreaHandler,
							Val GoToNext_Line 	= True,
							Val JoinStringTable = False) Export
	
	Template_oTxtCrsr = AreaHandler.Document.getCurrentController().getViewCursor();
	Template_oTxtCrsr.gotoRange(AreaHandler.Start, False);
	
	If NOT JoinStringTable Then
		Template_oTxtCrsr.goRight(1, False);
	EndIf;
	
	Template_oTxtCrsr.gotoRange(AreaHandler.End, True);
	
	TransferableObject = AreaHandler.Document.getCurrentController().Frame.controller.getTransferable();
	PrintFormHandler.Document.getCurrentController().insertTransferable(TransferableObject);
	
	If JoinStringTable Then
		DeleteLine(PrintFormHandler);
	EndIf;
	
	If GoToNext_Line Then
		InsertBreakAtNewLine(PrintFormHandler);
	EndIf;
	
EndProcedure

Procedure FillParameters(PrintForm, Data) Export
	
	For Each KeyValue In Data Do
		If TypeOf(KeyValue) <> Type("Array") Then
			PF_oDoc = PrintForm.Document;
			PF_ReplaceDescriptor = PF_oDoc.createReplaceDescriptor();
			PF_ReplaceDescriptor.SearchString = "{v8 " + KeyValue.Key + "}";
			PF_ReplaceDescriptor.ReplaceString = String(KeyValue.Value);
			PF_oDoc.replaceAll(PF_ReplaceDescriptor);
		EndIf;
	EndDo;
	
EndProcedure

Procedure JoinAndFillCollection(Val PrintFormHandler,
										  Val AreaHandler,
										  Val Data,
										  Val ThisIsTableRow = False,
										  Val GoToNext_Line  = True) Export
	
	Template_oTxtCrsr = AreaHandler.Document.getCurrentController().getViewCursor();
	Template_oTxtCrsr.gotoRange(AreaHandler.Start, False);
	
	If NOT ThisIsTableRow Then
		Template_oTxtCrsr.goRight(1, False);
	EndIf;
	Template_oTxtCrsr.gotoRange(AreaHandler.End, True);
	
	TransferableObject = AreaHandler.Document.getCurrentController().Frame.controller.getTransferable();
	
	For Each RowWithData In Data Do
		PrintFormHandler.Document.getCurrentController().insertTransferable(TransferableObject);
		If ThisIsTableRow Then
			DeleteLine(PrintFormHandler);
		EndIf;
		FillParameters(PrintFormHandler, RowWithData);
	EndDo;
	
	If GoToNext_Line Then
		InsertBreakAtNewLine(PrintFormHandler);
	EndIf;
	
EndProcedure

Procedure SetMainCursorOnDocumentBody(Val DocumentRef) Export
	
	oDoc 		= DocumentRef.Document;
	oViewCursor = oDoc.getCurrentController().getViewCursor();
	oTextCursor = oDoc.Text.createTextCursor();
	oViewCursor.gotoRange(oTextCursor, False);
	oViewCursor.gotoEnd(False);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Service functions

// Gets special structure, used to assign parameters for UNO
// objects.
//
Function ValueProperty(Val ServiceManager, Val Property, Val Value)
	
	PropertyValue 		= ServiceManager.Bridge_GetStruct("com.sun.star.beans.PropertyValue");
	PropertyValue.Name  = Property;
	PropertyValue.Value = Value;
	
	Return PropertyValue;
	
EndFunction

Function GetAreaBeginPosition(Val xDocument, Val AreaName)
	
	TextForSearch = "{v8 Area." + AreaName + "}";
	
	xSearchDescr 				  	 = xDocument.createSearchDescriptor();
	xSearchDescr.SearchString 		 = TextForSearch;
	xSearchDescr.SearchCaseSensitive = False;
	xSearchDescr.SearchWords 		 = True;
	xFound 							 = xDocument.findFirst(xSearchDescr);
	If xFound = Undefined Then
		Raise NStr("en = 'Beginning of template are not found'") + " " + AreaName;	
	EndIf;
	Return xFound.End;
	
EndFunction

Function GetAreaEndPosition(Val xDocument, Val AreaName)
	
	TextForSearch = "{/v8 Area." + AreaName + "}";
	
	xSearchDescr 			   		 = xDocument.createSearchDescriptor();
	xSearchDescr.SearchString 		 = TextForSearch;
	xSearchDescr.SearchCaseSensitive = False;
	xSearchDescr.SearchWords  		 = True;
	xFound = xDocument.findFirst(xSearchDescr);
	If xFound = Undefined Then
		Raise NStr("en = 'End of template area not found'") + " " + AreaName;	
	EndIf;
	Return xFound.Start;
	
EndFunction

Procedure DeleteLine(PrintFormHandler)
	
	oFrame = PrintFormHandler.Document.getCurrentController().Frame;
	
	dispatcher = PrintFormHandler.ServiceManager.CreateInstance ("com.sun.star.frame.DispatchHelper");
	
	oViewCursor = PrintFormHandler.Document.getCurrentController().getViewCursor();
	
	dispatcher.executeDispatch(oFrame, ".uno:GoUp", "", 0, GetComSafeArray());
	
	While oViewCursor.TextTable <> Undefined Do
		dispatcher.executeDispatch(oFrame, ".uno:GoUp", "", 0, GetComSafeArray());
	EndDo;
	
	dispatcher.executeDispatch(oFrame, ".uno:Delete", "", 0, GetComSafeArray());
	
	While oViewCursor.TextTable <> Undefined Do
		dispatcher.executeDispatch(oFrame, ".uno:GoDown", "", 0, GetComSafeArray());
	EndDo;
	
EndProcedure

Function SetMainCursorOnHeader(Val DocumentRef) Export
	
	xCursor 			= DocumentRef.Document.getCurrentController().getViewCursor();
	PageStyleName 		= xCursor.getPropertyValue("PageStyleName");
	oPStyle 			= DocumentRef.Document.getStyleFamilies().getByName("PageStyles").getByName(PageStyleName);
	oPStyle.HeaderIsOn 	= True;
	HeaderTextCursor 	= oPStyle.getPropertyValue("HeaderText").createTextCursor();
	xCursor.gotoRange(HeaderTextCursor, False);
	Return xCursor;
	
EndFunction

Function SetMainCursorOnFooter(Val DocumentRef) Export
	                	
	xCursor 			= DocumentRef.Document.getCurrentController().getViewCursor();
	PageStyleName 		= xCursor.getPropertyValue("PageStyleName");
	oPStyle 			= DocumentRef.Document.getStyleFamilies().getByName("PageStyles").getByName(PageStyleName);
	oPStyle.FooterIsOn 	= True;
	FooterTextCursor 	= oPStyle.getPropertyValue("FooterText").createTextCursor();
	xCursor.gotoRange(FooterTextCursor, False);
	Return xCursor;
	
EndFunction
