
&AtClient
Procedure AccountFromOnChange(Item)
	
	Items.AccFromLabel.Title =
		CommonUse.GetAttributeValue(Object.AccountFrom, "Description");
		
EndProcedure

&AtClient
Procedure AccountToOnChange(Item)
	
	Items.AccToLabel.Title =
		CommonUse.GetAttributeValue(Object.AccountTo, "Description");

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//ConstantBankTransfer = Constants.BankTransferLastNumber.Get();
	//If Object.Ref.IsEmpty() Then		
	//	
	//	Object.Number = Constants.BankTransferLastNumber.Get();
	//Endif;

	
	Items.AccFromLabel.Title =
		CommonUse.GetAttributeValue(Object.AccountFrom, "Description");
	
	Items.AccToLabel.Title =
		CommonUse.GetAttributeValue(Object.AccountTo, "Description");
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)

	If Object.AccountFrom = Object.AccountTo Then
		
		Message = New UserMessage();
		Message.Text=NStr("en='Account from and Account to can not be the same'");
		Message.Message();
		Cancel = True;
		Return;

		
	EndIf;
	
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
		StringVal = StrReplace(StringVal,",","");
		
		StringValLen = StrLen(StringVal);
		changenumberlen = StrLen(changenumber);
		LeadingZeros = Left(changenumber,(changenumberlen - StringValLen));

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
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	//
	//If Object.Ref.IsEmpty() Then
	//
	//	MatchVal = Increment(Constants.BankTransferLastNumber.Get());
	//	If Object.Number = MatchVal Then
	//		Constants.BankTransferLastNumber.Set(MatchVal);
	//	Else
	//		If Increment(Object.Number) = "" Then
	//		Else
	//			If StrLen(Increment(Object.Number)) > 20 Then
	//				 Constants.BankTransferLastNumber.Set("");
	//			Else
	//				Constants.BankTransferLastNumber.Set(Increment(Object.Number));
	//			Endif;

	//		Endif;
	//	Endif;
	//Endif;
	//
	//If Object.Number = "" Then
	//	Message("BankTransfer Number is empty");
	//	Cancel = True;
	//Endif;
	
EndProcedure

