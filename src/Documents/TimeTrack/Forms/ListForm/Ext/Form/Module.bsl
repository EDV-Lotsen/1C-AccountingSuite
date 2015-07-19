
&AtClient
Procedure GenInvoice(Command)
	
	If Items.List.SelectedRows.Count() > 0 Then 
		Cancel = False;
		QuantityMessageError = "";
		Str = GenInvoiceAtServer(Cancel, QuantityMessageError);
		
		Params = New Structure;
		Params.Insert("Str",Str);
		Params.Insert("Cancel",Cancel);
		If QuantityMessageError <> "" Then 
			MsgNotify = New NotifyDescription("OpenInvoiceDateForm", ThisObject, Params);
			ShowMessageBox(MsgNotify,QuantityMessageError);
		Else 	
			OpenInvoiceDateForm(Params);	
		EndIf;	
	Else
		Message("There are no entries to generate an invoice");
	EndIf;
EndProcedure

&AtClient
Procedure OpenInvoiceDateForm(Params) Export   
	
	Cancel = Params.Cancel;
	Str = Params.Str;
	
	If Not Cancel Then
		TempAddress = PutToTempStorage(Str,ThisForm.UUID);
		Notify = New NotifyDescription("OpenInvoice", ThisObject);
		OpenForm("CommonForm.TimeTrackToInvoiceForm",,ThisForm,,,,Notify,FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenInvoice(Parameter1,Parameter2) Export
	
	NewStr = GetFromTempStorage(TempAddress);
	NewStr.Insert("InvoiceDate",Parameter1);
	If Parameter1 <> Undefined Then
		OpenForm("Document.SalesInvoice.Form.DocumentForm",NewStr);	
	EndIf;
	
EndProcedure

&AtServer
Function GenInvoiceAtServer(Cancel, QuantityMessageError)
	
	ReturnStructure = New Structure;
	ProcessedRows = Items.List.SelectedRows;
	CurCompany = Undefined;
	TimeTrackObjects = New Array;
	
	QtyPrecision = Constants.QtyPrecision.Get();
	
	If QtyPrecision < 2 Then 
		QuantityMessageError = "Quantity field decimals setttings is "+ QtyPrecision + ". Quantity of hours in Invoice will be rounded." + Chars.LF + "You can change Quantity precision in ""Settings"" -> ""Features"".";
	EndIf;	
	
	
	For Each CheckRow In ProcessedRows Do 
		
		If CurCompany = Undefined Then //Predefine company from 1st row
			CurCompany = CheckRow.Company;
		EndIf;	
		
		If CheckRow.InvoiceStatus = Enums.TimeTrackStatus.Unbillable  Then
			Cancel = True;
			Message("Either one or more of the selected documents are considered non-billable");
			Return New Structure;
		Else 
			If CheckRow.Company <> CurCompany Then
				Cancel = True;
				Message("Selected item companies do not all match");
				Return New Structure;
			Endif;
			TimeTrackObjects.Add(CheckRow);
		Endif;
	EndDo;
	
	ReturnStructure.insert("timetrackobjs",TimeTrackObjects);
	Return ReturnStructure;
	
	
EndFunction

&AtClient
Procedure RefreshItems(Command)
	Items.List.Refresh();
EndProcedure

&AtServer
Function Increment(NumberToInc)
	
	Last = NumberToInc;
	LastCount = StrLen(Last);
	Digits = new Array();
	For i = 1 to LastCount Do	
		Digits.Add(Mid(Last,i,1));
		
	EndDo;
	
	NumPos = 9999;
	lengthcount = 0;
	firstnum = false;
	j = 0;
	While j < LastCount Do
		If NumCheck(Digits[LastCount - 1 - j]) Then
			if firstnum = false then //first number encountered, remember position
				firstnum = true;
				NumPos = LastCount - 1 - j;
				lengthcount = lengthcount + 1;
			Else
				If firstnum = true Then
					If NumCheck(Digits[LastCount - j]) Then //if the previous char is a number
						lengthcount = lengthcount + 1;  //next numbers, add to length.
					Else
						break;
					Endif;
				Endif;
			Endif;
			
		Endif;
		j = j + 1;
	EndDo;
	
	NewString = "";
	
	If lengthcount > 0 Then //if there are numbers in the string
		changenumber = Mid(Last,(NumPos - lengthcount + 2),lengthcount);
		NumVal = Number(changenumber);
		NumVal = NumVal + 1;
		StringVal = String(NumVal);
		
		StringValLen = StrLen(StringVal);
		changenumberlen = StrLen(changenumber);
		LeadingZeros = Left(changenumber,(changenumberlen - StringValLen));
		
		StringVal = StrReplace(StringVal,",","");
		LeftSide = Left(Last,(NumPos - lengthcount + 1));
		RightSide = Right(Last,(LastCount - NumPos - 1));
		NewString = LeftSide + LeadingZeros + StringVal + RightSide; //left side + incremented number + right side
		
	Endif;
	
	Next = NewString;
	
	return NewString;
	
EndFunction

&AtServer
Function NumCheck(CheckValue)
	
	For i = 0 to  9 Do
		If CheckValue = String(i) Then
			Return True;
		Endif;
	EndDo;
	
	Return False;
	
EndFunction

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Update prices presentation.
	PriceFormat = GeneralFunctionsReusable.DefaultPriceFormat();
	Items.Price.Format      = PriceFormat;	
	
EndProcedure

&AtClient
Procedure MultiEntry(Command)
	OpenForm("Document.TimeTrack.Form.MultiDayForm");
EndProcedure
