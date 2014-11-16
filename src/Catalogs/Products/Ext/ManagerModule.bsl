
////////////////////////////////////////////////////////////////////////////////
// Products: Manager module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

// Checks whether added item to assembly is a parent assembly.
Function ItemIsParentAssembly(Item, Assembly) Export
	
	// Select all subassemblies and their parents.
	QueryText =
	"SELECT
	|	LineItems.Ref     AS Parent,
	|	LineItems.Product AS Child
	|FROM
	|	Catalog.Products.LineItems AS LineItems
	|WHERE
	|	 LineItems.Ref.Assembly = True
	|AND LineItems.Product.Assembly = True";
	Query = New Query(QueryText);
	Assemblies = Query.Execute().Unload();
	
	// Check group of items.
	If TypeOf(Item) = Type("Array") Then
		// Create an array of subassemblies.
		Result = New Map();
		For Each Element In Item Do
			Child = IsMyParent(Assembly, Element, Assemblies);
			If Child <> Undefined Then
				Result.Insert(Element, Child);
			EndIf;
		EndDo;
		
		// Return an array of first found subassemblies of searched parent.
		If Result.Count() > 0 Then
			Return Result;
		Else
			Return Undefined;
		EndIf;
		
	ElsIf TypeOf(Item) = Type("CatalogRef.Products") Then
		// Return a found first subassembly of searched parent.
		Return IsMyParent(Assembly, Item, Assemblies);
		
	Else
		// Unknown type. Can't be parent assembly.
		Return Undefined;
	EndIf;
	
EndFunction

// Recursive subroutine checking parents to childs.
Function IsMyParent(Child, Parent, Items)
	
	// Search for parents of selected child.
	Parents = Items.FindRows(New Structure("Child", Child));
	
	// Check all possible parents.
	For Each Item In Parents Do
		
		// Check parent itself.
		If Item.Parent = Parent Then
			// It is my parent.
			Return Child;
			
		// Check parent's parents.
		Else
			ChildOfParent = IsMyParent(Item.Parent, Parent, Items);
			If ChildOfParent <> Undefined Then
				// It is parent of my parents.
				Return ChildOfParent;
			EndIf;
		EndIf;
		
	EndDo;
	
	// This is not my parent (and not parent of my parents).
	Return Undefined;
	
EndFunction

#EndIf

#EndRegion

