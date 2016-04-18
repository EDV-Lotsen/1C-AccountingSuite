// Function checks if there is duplicate by given attribute and value.
//
// Parameters:
//  Ref           - CatalogRef.Addresses - reference to current Address.
//  Owner         - CatalogRef.Companies - reference to company that is address owner.
//  AttributeName - String               - name of attribute.
// 
// Returns:
//  Boolean - true, if there is no duplicate, false, if there is a duplicate.
//
Function CheckDuplicateByAttribute(Ref, Owner, AttributeName, Value) Export
	
	Query = New Query;
	Query.SetParameter("Owner", Owner);
	Query.SetParameter("Ref"  , Ref);
	Query.SetParameter("Value", Value);
	Query.Text = "
		|SELECT
		|	Addresses.Ref AS Address
		|FROM
		|	Catalog.Addresses AS Addresses
		|WHERE
		|	Addresses.Owner = &Owner
		|	AND NOT Addresses.Ref = &Ref
		|	AND &CurrentField = &Value";
	Query.Text = StrReplace(Query.Text, "&CurrentField", "Addresses." + AttributeName);
	
	If Query.Execute().IsEmpty() Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction