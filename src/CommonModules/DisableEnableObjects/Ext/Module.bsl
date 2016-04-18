
////////////////////////////////////////////////////////////////////////////////
// Disable/Enable Objects: Common server functions
//------------------------------------------------------------------------------
// Available on:
// - Server
//

////////////////////////////////////////////////////////////////////////////////
// Primary functions:
// - set conditional apperance by attribute InArchive;

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

Procedure SetConditionalAppearance(Form) Export
	
	// Set strikethrough font for archived items in List settings.
	ElementCA = Form.List.ConditionalAppearance.Items.Add(); 
	
	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue      = New DataCompositionField("InArchive"); 
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal; 
	FilterElement.RightValue     = True; 
	FilterElement.Use            = True;
	
	CurrentFont       = Form.Items.List.Font;
	FontStrikethrough = New Font(CurrentFont,,,,,,True);
	ElementCA.Appearance.SetParameterValue("Font", FontStrikethrough);
	
EndProcedure

#EndRegion



