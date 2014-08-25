
&AtClient
Procedure GenInvoice(Command)
	SelectedItem = Items.List.CurrentData;
	
	If SelectedItem <> Undefined Then
		Valid = False;
		Str = New Structure;
		Valid = GenInvoiceAtServer(SelectedItem,Str,Valid);
		OpenInvoiceDateForm(Str,Valid);	
	Else
		Message("There are no entries to generate an invoice");
	EndIf;
EndProcedure

&AtClient
Procedure OpenInvoiceDateForm(Str,Valid)
		
If Valid = True Then
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
Function GenInvoiceAtServer(SelectedItem,Str,Valid)
	
	RefObject = SelectedItem.Ref.GetObject();
	
	//If RefObject.SalesInvoice.IsEmpty() Then
	//Else
	//	Message("A selected document is currently linked to an existing invoice. The invoice will be unlinked and a new invoice will be created.");
	//EndIf;
	
	rowcount = items.List.SelectedRows.Count();
	rownum = 0;
	DocBillable = True;
	While rownum < rowcount Do
		CheckRow = Items.List.SelectedRows.Get(rownum);
		If CheckRow.InvoiceStatus = Enums.TimeTrackStatus.Unbillable  Then
			DocBillable = False;			
		Endif;
			
		rownum = rownum + 1;	
	EndDo;
	
	
	If DocBillable = false Then
		Message("Either one or more of the selected documents are considered non-billable");
	Else
		
		TabularPartRow = SelectedItem;
				
		rowcount = items.List.SelectedRows.Count();
		rownum = 0;
		companymatch = true;
		While rownum < rowcount Do
			 CheckRow = Items.List.SelectedRows.Get(rownum);
			 If CheckRow.Company <> TabularPartRow.Company Then
			 	companymatch = false;			
			Endif;
			
		rownum = rownum + 1;	
		EndDo;
		
		
		If companymatch = true Then
			
			rownum = 0;			
			TObj = new Array;				
			While rownum < rowcount Do
				TabularPartRow = Items.List.SelectedRows.Get(rownum);
				TObj.Add(TabularPartRow);
			
				rownum = rownum + 1;
			EndDo;
					
			Str.insert("timetrackobjs",Tobj);
			
			Return True;
	
		
		Else
			Message("Selected item companies do not all match");
		Endif;
		
	Endif;

	                         	
EndFunction
&AtClient
Procedure RefreshItems(Command)
	Items.List.Refresh();
EndProcedure

&AtServer
Function Increment(NumberToInc)
	
	//Last = Constants.SalesInvoiceLastNumber.Get();
	Last = NumberToInc;
	//Last = "AAAAA";
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
