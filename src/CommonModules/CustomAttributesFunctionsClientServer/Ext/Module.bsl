
////////////////////////////////////////////////////////////////////////////////
// Custom attributes functions client server: Common server and client functions
//------------------------------------------------------------------------------
// Available on:
// - Server
// - Client
//

////////////////////////////////////////////////////////////////////////////////
// Primary functions:
// - get list of hidden custom attributes
// - get list of custom attributes and their presentations.


// Function returns array of custom attributes to hide them.
//
// Parameters:
//  ObjectTypeName           - String - name of object type: "Catalogs", "Documents" and etc.
//  ObjectName               - String - name of object: "Products", "Companies", "SalesOrder" and etc.
//  ObjectTabularSectionName - String - name of tabular section if needed.
// 
// Returns:
//  Array - of strings that are names of attributes to hide.
//
Function GetHiddenCustomAttributes(ObjectTypeName, ObjectName, ObjectTabularSectionName = "", AllCustomFields = False) Export
	
	AttributesArray = New Array;
	
	// Addresses custom attributes.
	If ObjectTypeName = "Catalogs" And ObjectName = "Addresses" And ObjectTabularSectionName = "" Then 
		                              
		ConstantsList  = New Array;
		ConstantsList.Add("CF1AType");
		ConstantsList.Add("CF2AType");
		ConstantsList.Add("CF3AType");
		ConstantsList.Add("CF4AType");
		ConstantsList.Add("CF5AType");
		ConstantValues = CommonUseServerCall.GetConstantsValues(ConstantsList);
		
		For k = 1 To 5 Do
			
			TypeName        = "CF" + k + "AType";
			StrAttributName = "CF" + k + "String";
			
			If ConstantValues[TypeName] = "None" Or ConstantValues[TypeName] = "" Or AllCustomFields Then
				AttributesArray.Add(StrAttributName);
			EndIf;
			
		EndDo;
		
	// Companies custom attributes.
	ElsIf ObjectTypeName = "Catalogs" And ObjectName = "Companies" And ObjectTabularSectionName = "" Then 
		
		ConstantsList  = New Array;
		ConstantsList.Add("CF1CType");
		ConstantsList.Add("CF2CType");
		ConstantsList.Add("CF3CType");
		ConstantsList.Add("CF4CType");
		ConstantsList.Add("CF5CType");
		ConstantValues = CommonUseServerCall.GetConstantsValues(ConstantsList);
		
		For k = 1 To 5 Do
			
			TypeName        = "CF" + k + "CType";
			StrAttributName = "CF" + k + "String";
			NumAttributName = "CF" + k + "Num";
			
			If ConstantValues[TypeName] = "None" Or ConstantValues[TypeName] = "" Or AllCustomFields Then
				AttributesArray.Add(StrAttributName);
				AttributesArray.Add(NumAttributName);
			ElsIf ConstantValues[TypeName] = "String" Then
				AttributesArray.Add(NumAttributName);
			ElsIf ConstantValues[TypeName] = "Number" Then
				AttributesArray.Add(StrAttributName);
			EndIf;
			
		EndDo;
		
	// Companies custom attributes.
	ElsIf ObjectTypeName = "Catalogs" And ObjectName = "Products" And ObjectTabularSectionName = "" Then 
		
		ConstantsList  = New Array;
		ConstantsList.Add("CF1Type");
		ConstantsList.Add("CF2Type");
		ConstantsList.Add("CF3Type");
		ConstantsList.Add("CF4Type");
		ConstantsList.Add("CF5Type");
		ConstantValues = CommonUseServerCall.GetConstantsValues(ConstantsList);
		
		For k = 1 To 5 Do
			
			TypeName        = "CF" + k + "Type";
			StrAttributName = "CF" + k + "String";
			NumAttributName = "CF" + k + "Num";
			
			If ConstantValues[TypeName] = "None" Or ConstantValues[TypeName] = "" Or AllCustomFields Then
				AttributesArray.Add(StrAttributName);
				AttributesArray.Add(NumAttributName);
			ElsIf ConstantValues[TypeName] = "String" Then
				AttributesArray.Add(NumAttributName);
			ElsIf ConstantValues[TypeName] = "Number" Then
				AttributesArray.Add(StrAttributName);
			EndIf;
			
		EndDo;
	EndIf;
	
	Return AttributesArray;
	
EndFunction

// Function returns array of custom attribute titles.
//
// Parameters:
//  ObjectTypeName           - String - name of object type: "Catalogs", "Documents" and etc.
//  ObjectName               - String - name of object: "Products", "Companies", "SalesOrder" and etc.
//  ObjectTabularSectionName - String - name of tabular section if needed.
// 
// Returns:
//  Structure - where Key is name of custom field and Value is title of custom field.
//
Function GetCustomAttributeTitles(ObjectTypeName, ObjectName, ObjectTabularSectionName = "") Export
	
	AttributeTitles = New Structure;
	
	// Addresses custom attributes.
	If ObjectTypeName = "Catalogs" And ObjectName = "Addresses" And ObjectTabularSectionName = "" Then 
		
		ConstantsList  = New Array;
		ConstantsList.Add("CF1AType");
		ConstantsList.Add("CF2AType");
		ConstantsList.Add("CF3AType");
		ConstantsList.Add("CF4AType");
		ConstantsList.Add("CF5AType");
		ConstantsList.Add("CF1AName");
		ConstantsList.Add("CF2AName");
		ConstantsList.Add("CF3AName");
		ConstantsList.Add("CF4AName");
		ConstantsList.Add("CF5AName");
		ConstantValues = CommonUseServerCall.GetConstantsValues(ConstantsList);
		
		For k = 1 To 5 Do
			
			TypeName        = "CF" + k + "AType";
			TitleName       = "CF" + k + "AName";
			StrAttributName = "CF" + k + "String";
			
			If ConstantValues[TypeName] = "String" Then
				AttributeTitles.Insert(StrAttributName, ConstantValues[TitleName]);
			EndIf;
			
		EndDo;
		
	// Companies custom attributes.
	ElsIf ObjectTypeName = "Catalogs" And ObjectName = "Companies" And ObjectTabularSectionName = "" Then
		
		ConstantsList  = New Array;
		ConstantsList.Add("CF1CType");
		ConstantsList.Add("CF2CType");
		ConstantsList.Add("CF3CType");
		ConstantsList.Add("CF4CType");
		ConstantsList.Add("CF5CType");
		ConstantsList.Add("CF1CName");
		ConstantsList.Add("CF2CName");
		ConstantsList.Add("CF3CName");
		ConstantsList.Add("CF4CName");
		ConstantsList.Add("CF5CName");
		ConstantValues = CommonUseServerCall.GetConstantsValues(ConstantsList);
		
		For k = 1 To 5 Do
			
			TypeName        = "CF" + k + "CType";
			TitleName       = "CF" + k + "CName";
			StrAttributName = "CF" + k + "String";
			NumAttributName = "CF" + k + "Num";
			
			If ConstantValues[TypeName] = "String" Then
				AttributeTitles.Insert(StrAttributName, ConstantValues[TitleName]);
			ElsIf ConstantValues[TypeName] = "Number" Then
				AttributeTitles.Insert(NumAttributName, ConstantValues[TitleName]);
			EndIf;
			
		EndDo;
		
	// Companies custom attributes.
	ElsIf ObjectTypeName = "Catalogs" And ObjectName = "Products" And ObjectTabularSectionName = "" Then 
		
		ConstantsList  = New Array;
		ConstantsList.Add("CF1Type");
		ConstantsList.Add("CF2Type");
		ConstantsList.Add("CF3Type");
		ConstantsList.Add("CF4Type");
		ConstantsList.Add("CF5Type");
		ConstantsList.Add("CF1Name");
		ConstantsList.Add("CF2Name");
		ConstantsList.Add("CF3Name");
		ConstantsList.Add("CF4Name");
		ConstantsList.Add("CF5Name");
		ConstantValues = CommonUseServerCall.GetConstantsValues(ConstantsList);
		
		For k = 1 To 5 Do
			
			TypeName        = "CF" + k + "Type";
			TitleName       = "CF" + k + "Name";
			StrAttributName = "CF" + k + "String";
			NumAttributName = "CF" + k + "Num";
			
			If ConstantValues[TypeName] = "String" Then
				AttributeTitles.Insert(StrAttributName, ConstantValues[TitleName]);
			ElsIf ConstantValues[TypeName] = "Number" Then
				AttributeTitles.Insert(NumAttributName, ConstantValues[TitleName]);
			EndIf;
			
		EndDo;
	EndIf;
	
	Return AttributeTitles;
	
EndFunction


