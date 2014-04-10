
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	ApplyConditionalAppearance();
EndProcedure

&AtServer
Procedure ApplyConditionalAppearance()
	CA = ThisForm.List.ConditionalAppearance;
	CA.Items.Clear();
	//Highlight final tax with Bold font
	ElementCA = CA.Items.Add(); 
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("Description"); 
 	FieldAppearance.Use = True; 
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("Agency"); 
 	FieldAppearance.Use = True; 
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("Rate"); 
 	FieldAppearance.Use = True; 
	
 	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("Parent"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= Catalogs.SalesTaxRates.EmptyRef(); 
	FilterElement.Use				= True;
	
	BoldFont	=New Font(StyleFonts.NormalTextFont,,,True,,,); //Bold font
	ElementCA.Appearance.SetParameterValue("Font", BoldFont); 
	
	//Highlight tax components with the grey background
	ElementCA = CA.Items.Add(); 
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("Description"); 
 	FieldAppearance.Use = True; 
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("Agency"); 
 	FieldAppearance.Use = True; 
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("Rate"); 
 	FieldAppearance.Use = True; 
	
 	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("Parent"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.NotEqual; 
	FilterElement.RightValue 		= Catalogs.SalesTaxRates.EmptyRef(); 
	FilterElement.Use				= True;
	
	ElementCA.Appearance.SetParameterValue("BackColor", WebColors.WhiteSmoke); 
EndProcedure
