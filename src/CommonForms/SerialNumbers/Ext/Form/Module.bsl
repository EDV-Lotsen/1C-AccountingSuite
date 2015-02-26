
////////////////////////////////////////////////////////////////////////////////
// Serial Numbers: Common form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Var SerialNumbersStr;
	
	// Read parameters to form attributes.
	If Parameters.Property("SerialNumbers", SerialNumbersStr) Then
		SerialNumbersArr = LotsSerialNumbersClientServer.GetSerialNumbersArrayFromStr(SerialNumbersStr);
		For Each SerialNumber In SerialNumbersArr Do
			Row = SerialNumbers.Add();
			Row.SerialNumber = SerialNumber;
		EndDo;
	EndIf;
	
	// Set form height.
	SerialNumbersCount = SerialNumbers.Count() + 1;
	Items.SerialNumbers.HeightInTableRows = ?(SerialNumbersCount < 5, 5,
	                                        ?(SerialNumbersCount > 20, 20,
	                                          SerialNumbersCount));
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region CONTROLS_EVENTS_HANDLERS

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region TABULAR_SECTION_EVENTS_HANDLERS

&AtClient
Procedure SerialNumbersSerialNumberTextEditEnd(Item, Text, ChoiceData, Parameters, StandardProcessing)
	
	// Decode array of serial numbers from entered string.
	SerialNumbersArr = LotsSerialNumbersClientServer.GetSerialNumbersArrayFromStr(Text);
	
	// Fill serial numbers from array.
	If SerialNumbersArr.Count() > 0 Then
		// Fill current item with the first array value.
		Row = Items.SerialNumbers.CurrentData;
		Row.SerialNumber = SerialNumbersArr[0];
		
		// Add new items to the table.
		CurrentRowNumber = Items.SerialNumbers.CurrentRow;
		For i = 1 To SerialNumbersArr.Count() - 1 Do
			If CurrentRowNumber + i > SerialNumbers.Count() Then
				Row = SerialNumbers.Add();
			Else
				Row = SerialNumbers.Insert(CurrentRowNumber + i);
			EndIf;
			Row.SerialNumber = SerialNumbersArr[i];
		EndDo;
		
		// Adjust height of control to serial numbers content.
		SerialNumbersCount = SerialNumbers.Count() + 1;
		If  Items.SerialNumbers.HeightInTableRows < SerialNumbersCount
		And Items.SerialNumbers.HeightInTableRows < 20 Then
			// Update table high.
			Items.SerialNumbers.HeightInTableRows = ?(SerialNumbersCount > 20, 20, SerialNumbersCount);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SerialNumbersBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	
	// Adjust height of control to serial numbers content.
	SerialNumbersCount = SerialNumbers.Count() + 1;
	If  Items.SerialNumbers.HeightInTableRows < SerialNumbersCount
	And Items.SerialNumbers.HeightInTableRows < 20 Then
		// Update table high.
		Items.SerialNumbers.HeightInTableRows = ?(SerialNumbersCount > 20, 20, SerialNumbersCount);
	EndIf;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

&AtClient
Procedure FormWriteAndClose(Command)
	
	// Save the serial numbers change.
	SerialNumbersArr = New Array;
	For Each Row In SerialNumbers Do
		SerialNumbersArr.Add(Row.SerialNumber);
	EndDo;
	SerialNumbersStr = StringFunctionsClientServer.GetStringFromSubstringArray(SerialNumbersArr,", ");
	
	// Complete form closing.
	ThisForm.Close(SerialNumbersStr);
	
EndProcedure

&AtClient
Procedure FormClose(Command)
	
	// Complete form closing.
	ThisForm.Close(Undefined);
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

#EndRegion
