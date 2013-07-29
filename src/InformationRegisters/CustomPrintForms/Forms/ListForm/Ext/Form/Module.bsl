
&AtClient
Procedure Upload(Command)
	
	ImageAddress = "";
	
	NotifyDescription = New NotifyDescription("FileUpload",ThisForm);
	BeginPutFile(NotifyDescription,ImageAddress,"",True);
EndProcedure

&AtClient
Procedure FileUpload(a,b,c,d) Export
	
	PlaceImageFile(b);
	
EndProcedure

&AtServer
Procedure PlaceImageFile(TempStorageName)
	
	BinaryData = GetFromTempStorage(TempStorageName);	
	NewRow = InformationRegisters.CustomPrintForms.CreateRecordManager();
	NewRow.ObjectName = "document name (e.g. Document.SalesInvoice)";
	NewRow.TemplateName = "template name (e.g. Sales invoice)";
	NewRow.Template = New ValueStorage(BinaryData, New Deflation(9));
	NewRow.Write();	
	DeleteFromTempStorage(TempStorageName);
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	
	ObjectNameForDeleteRow = ObjectNameDimension(Items.List.CurrentRow);	
	TemplateNameForDeleteRow = TemplateNameDimension(Items.List.CurrentRow);
	
EndProcedure

&AtServer
Function ObjectNameDimension(RefObject)
	
	Return RefObject.ObjectName;	
	
EndFunction

&AtServer
Function TemplateNameDimension(RefObject)
	
	Return RefObject.TemplateName;	
	
EndFunction


&AtClient
Procedure ListAfterDeleteRow(Item)
	
	CustomPrintFormsRowServer();
  	
EndProcedure

Procedure CustomPrintFormsRowServer()
		
	RecordSet = InformationRegisters.CustomPrintForms.CreateRecordSet();
	RecordSet.Filter.ObjectName.Set(ObjectNameForDelete);
	RecordSet.Filter.TemplateName.Set(TemplateNameForDelete);	
	RecordSet.Write();  	
	
EndProcedure



