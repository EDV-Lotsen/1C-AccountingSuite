// Generates and outputs a message that can be linked with a form element.
//
//  Parameters
//  UserMessageText - String - message text.
//  DataKey                - Any reference to an infobase object.
//                               Reference to an infobase object this message is intended for, or a record key.
//  Field                       - String - form attribute name
//  DataPath                - String - data path (path to a form attribute)
//  Cancel                      - Boolean - Output parameter
//                               Always set to True
//
// This is an abridged procedure description, for the full one see the Subsystems Library (SL)
//
Procedure NotifyUser(
		val UserMessageText,
		val DataKey = Undefined,
		val Field = "",
		val DataPath = "",
		Cancel = False) Export
	
	Message = New UserMessage;
	Message.Text = UserMessageText;
	Message.Field = Field;
	
	ThisObject = False;
	
#If NOT (ThinClient OR WebClient) Then
	If DataKey <> Undefined
	   И XMLTypeOf(DataKey) <> Undefined Then
		ValueTypeString = XMLTypeOf(DataKey).TypeName;
		ThisObject = Find(ValueTypeString, "Object.") > 0;
	EndIf;
#EndIf
	
	If ThisObject Then
		Message.SetData(DataKey);
	Else
		Message.DataKey = DataKey;
	EndIf;
	
	If NOT IsBlankString(DataPath) Then
		Message.DataPath = DataPath;
	EndIf;
		
	Message.Message();
	
	Cancel = True;
	
EndProcedure

// Delete all instances of the specified type
//
// Parameters:
//  Array - array from which values are deleted
//  Type – type, instances of which need to be deleted from the collection
// 
Procedure DeleteAllInstancesOfTypeFromArray(Array, Type) Export
	
	CollectionItemsQty = Array.Count();
	
	For InverseIndex = 1 To CollectionItemsQty Do
		
		Index = CollectionItemsQty - InverseIndex;
		
		If TypeOf(Array[Index]) = Type Then
			
			Array.Delete(Index);
			
		EndIf;
		
	EndDo;
	
EndProcedure

