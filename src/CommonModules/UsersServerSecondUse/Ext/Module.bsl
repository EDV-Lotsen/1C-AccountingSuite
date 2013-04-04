
// Function TreeOfSubsystems() returns tree of name values of all configuration subsystems.
//
// Value returned:
//  ValueTree
//      FullName   - String, for example, <Parent subsystem name>.<Subsystem name>
//      Name       - String.
//      Synonym    - String.
//
Function TreeOfSubsystems() Export
	
	Tree = New ValueTree;
	Tree.Columns.Add("FullName", 	New TypeDescription("String"));
	Tree.Columns.Add("Name",        New TypeDescription("String", , New StringQualifiers(1000)));
	Tree.Columns.Add("Synonym",   	New TypeDescription("String", , New StringQualifiers(1000)));
	
	FillSubsystems(Tree.Rows);
	
	Return Tree;
	
EndFunction

// Function AllRoles() returns value table of names of all configuration roles.
//
// Parameters:
//  OnlyRoleNames - Boolean. If false - additional info being returned: role synonyms, subsystem names and synonyms.
//
// Value returned:
//  ValueTable               
//      Name         		 - String.
//                          // If OnlyRoleNames = False, then:
//      Synonym           	 - String.
//      SubsystemNames   	 - String, for example, "StandardSubsystems, StandardSubsystems.BasicFunctionality".
//      SynonymsOfSubsystems - String, for example, "Standard subsystems, Standard subsystems.Basic functionality".
//
Function AllRoles(OnlyRoleNames = False) Export
	
	Table = New ValueTable;
	Table.Columns.Add("Name", New TypeDescription("String", , New StringQualifiers(1000)));
	
	If NOT OnlyRoleNames Then
		Table.Columns.Add("Synonym",           		New TypeDescription("String"));
		Table.Columns.Add("SubsystemNames",    		New TypeDescription("String"));
		Table.Columns.Add("SynonymsOfSubsystems", 	New TypeDescription("String"));
	EndIf;
	
	For each Role In Metadata.Roles Do
	
		String = Table.Add();
		String.Name = Role.Name;
		
		If NOT OnlyRoleNames Then
			String.Synonym = Role.Synonym;
			FillSubsystemsOfRoles(Role, String.SubsystemNames, String.SynonymsOfSubsystems);
		EndIf;
	EndDo;
	
	Return Table;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Auxiliary module procedures
////////////////////////////////////////////////////////////////////////////////

Procedure FillSubsystems(CollectionOfTreeRows, Subsystems = Undefined, ParentSubsystemNames = "")
	
	If Subsystems = Undefined Then
		Subsystems = Metadata.Subsystems;
	EndIf;
	
	If ValueIsFilled(ParentSubsystemNames) Then
		ParentSubsystemNames = ParentSubsystemNames + ".";
	EndIf;
	
	For each Subsystem In Subsystems Do
		
		TreeRow = CollectionOfTreeRows.Add();
		TreeRow.FullName   = ParentSubsystemNames + Subsystem.Name;
		TreeRow.Name       = Subsystem.Name;
		TreeRow.Synonym    = Subsystem.Synonym;
			
		FillSubsystems(TreeRow.Rows, Subsystem.Subsystems, ParentSubsystemNames + Subsystem.Name);
	EndDo;
	
EndProcedure

Procedure FillSubsystemsOfRoles(MetadataObject, SubsystemNames, SynonymsOfSubsystems, Subsystems = Undefined, ParentSubsystemNames1 = "", SynonymsOfParentalSubsystems = "")
	
	If Subsystems = Undefined Then
		Subsystems = Metadata.Subsystems;
	EndIf;
	
	If ValueIsFilled(ParentSubsystemNames1) Then
		ParentSubsystemNames1    	 = ParentSubsystemNames1    	    + ".";
		SynonymsOfParentalSubsystems = SynonymsOfParentalSubsystems + ".";
	EndIf;
	
	For each Subsystem In Subsystems Do
		If Subsystem.Content.Contains(MetadataObject) Then
			If ValueIsFilled(SubsystemNames) Then
				SubsystemNames       = SubsystemNames       + ", ";
				SynonymsOfSubsystems = SynonymsOfSubsystems + ", ";
			EndIf;
			SubsystemNames       = SubsystemNames       + ParentSubsystemNames1        + Subsystem.Name;
			SynonymsOfSubsystems = SynonymsOfSubsystems + SynonymsOfParentalSubsystems + Subsystem.Synonym;
		EndIf;
		FillSubsystemsOfRoles(MetadataObject, SubsystemNames, SynonymsOfSubsystems, Subsystem.Subsystems, ParentSubsystemNames1 + Subsystem.Name, SynonymsOfParentalSubsystems + Subsystem.Synonym);
	EndDo;
	
EndProcedure

