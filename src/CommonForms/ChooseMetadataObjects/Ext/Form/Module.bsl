
////////////////////////////////////////////////////////////////////////////////
//                          FORM USAGE                               //
//
// Form is designated for choice of configuration metadata objects and passing
// selected objects to the calling context.
//
// Call parameters:
// CollectionsOfSelectedMetadataObjects - ValueList - in fact is a filter
//				of metadata object types, which can be selected.
//				For example:
//					FilterByReferencialMetadata = New ValueList;
//					FilterByReferencialMetadata.Add("Catalogs");
//					FilterByReferencialMetadata.Add("Documents");
//				Only metadata objects: catalogs and documents can be selected
// SelectedMetadataObjects - ValueList - already selected metadata objects.
//				In metadata tree these objects will be checked with a flag.
//				Can be used for setting up choice metadata objects by default
//				or redefining already defined list
//

///////////////////////////////////////////////////////////////////////////////
//                      BLOCK OF EVENT HANDLERS                              //
///////////////////////////////////////////////////////////////////////////////

// Procedure handler of event OnCreateAtServer of form
//
&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	SelectedMetadataObjects.LoadValues(Parameters.SelectedMetadataObjects.UnloadValues());
	
	If Parameters.FilterByMetadataObjects.Count() > 0 Then
		Parameters.CollectionsOfSelectedMetadataObjects.Clear();
		For Each MetadataObjectFullName In Parameters.FilterByMetadataObjects Do
			BaseTypeName = CommonUse.BaseTypeNameByMetadataObject(Metadata.FindByFullName(MetadataObjectFullName));
			If Parameters.CollectionsOfSelectedMetadataObjects.FindByValue(BaseTypeName) = Undefined Then
				Parameters.CollectionsOfSelectedMetadataObjects.Add(BaseTypeName);
			EndIf;
		EndDo;
	EndIf;
	
	MetadataObjectTreeFill();
	
EndProcedure

// Procedure handler of button click event of form "Select"
//
&AtClient
Procedure ChooseRun()
	
	SelectedMetadataObjects.Clear();
	
	DataReceiving();
	
	Notify("ChooseMetadataObjects", SelectedMetadataObjects, Parameters.UUIDSource);
	
	Close();
	
EndProcedure

// Procedure handler of click event of form "Close"
//
&AtClient
Procedure CloseExecute()
	
	Close();
	
EndProcedure

// Procedure handle of click event of field "Check" of form tree
//
&AtClient
Procedure CheckOnChange(Item)

	CurrentData = CurrentItem.CurrentData;
	If CurrentData.Check = 2 Then
		CurrentData.Check = 0;
	EndIf;
	MarkNestedElements(CurrentData);
	MarkParentItems(CurrentData);

EndProcedure

///////////////////////////////////////////////////////////////////////////////
//                      BLOCK OF AUXILIARY FUNCTIONS                         //
///////////////////////////////////////////////////////////////////////////////

// Procedure fills value tree of configuration objects.
// If value list "Parameters.CollectionsOfSelectedMetadataObjects" is not empty, then
// tree will be limited by passed list of metadata object collections.
//  If metadata objects in generated tree will be found in value list
// "Parameters.SelectedMetadataObjects", then they will be marked, as selected.
//
&AtServer
Procedure MetadataObjectTreeFill()
	
	CollectionsOfMetadataObjects = New ValueTable;
	CollectionsOfMetadataObjects.Columns.Add("Name");
	CollectionsOfMetadataObjects.Columns.Add("Synonym");
	CollectionsOfMetadataObjects.Columns.Add("Picture");
	CollectionsOfMetadataObjects.Columns.Add("ObjectPicture");
	CollectionsOfMetadataObjects.Columns.Add("ThisIsCollectionCommon");
	
	CollectionsOfMetadataObjects_NewRow("Subsystems",                   	"Subsystems",                     		35, 36, True, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("CommonModules",                  	"Common modules",                   	37, 38, True, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("SessionParameters",              	"SessionNumber parameters",               	39, 40, True, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("Roles",                         	"Roles",                           		41, 42, True, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("ExchangePlans",                  	"Exchange plans",                  	 	43, 44, True, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("FilterCriteria",               	"Filter criteria",                		45, 46, True, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("EventSubscriptions",            	"Subscriptions for events",             47, 48, True, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("ScheduledJobs",          			"Scheduled tasks",           			49, 50, True, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("FunctionalOptions",          		"Functional options",           		51, 52, True, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("FunctionalOptionsParameters", 		"Parameters of functional options", 	53, 54, True, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("SettingsStorages",            		"Settings storage",             		55, 56, True, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("CommonForms",                   	"Overall forms",                    	57, 58, True, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("CommonCommands",                 	"Overall commands",                  	59, 60, True, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("CommandGroups",                 	"Commands' folders",                  	61, 62, True, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("Interfaces",                   	"Interfaces",                     		63, 64, True, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("CommonTemplates",                  "Overall templates",                   	65, 66, True, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("CommonPictures",                	"Common pictures",                 		67, 68, True, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("XDTOPackages",                   	"XDTO-packages",                    	69, 70, True, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("WebServices",                   	"Web-services",                    		71, 72, True, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("WSReferences",                     "WS-links",                      		73, 74, True, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("Styles",                        	"Styles",                          		75, 76, True, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("Languages",                        "Languages",                        	77, 78, True, CollectionsOfMetadataObjects);
	
	CollectionsOfMetadataObjects_NewRow("Constants",                    	"Constants",                      	PictureLib.Constant,              		PictureLib.Constant,                    	 False, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("Catalogs",                  		"Catalogs",                    		PictureLib.Catalog,             		PictureLib.Catalog,                   		 False, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("Documents",                    	"Documents",                      	PictureLib.Document,               		PictureLib.DocumentObject,              	 False, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("DocumentJournals",            		"Document journals",             	PictureLib.DocumentJournal,      		PictureLib.DocumentJournal,             	 False, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("Enums",                 			"Enums",                   			PictureLib.Enum,           				PictureLib.Enum,                 			 False, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("Reports",                       	"Reports",                         	PictureLib.Report,                  	PictureLib.Report,                        	 False, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("DataProcessors",                   "DataProcessors",                   PictureLib.DataProcessor,               PictureLib.DataProcessor,                    False, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("ChartsOfCharacteristicTypes",      "Charts of characteristics types",  PictureLib.ChartOfCharacteristicTypes,  PictureLib.ChartOfCharacteristicTypesObject, False, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("ChartsOfAccounts",                 "Charts of accounts",               PictureLib.ChartOfAccounts,             PictureLib.ChartOfAccountsObject,            False, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("ChartsOfCalculationTypes",         "Chart of characteristics types",   PictureLib.ChartOfCharacteristicTypes,  PictureLib.ChartOfCharacteristicTypesObject, False, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("InformationRegisters",             "Information registers",            PictureLib.InformationRegister,         PictureLib.InformationRegister,              False, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("AccumulationRegisters",           	"Accumulation registers",           PictureLib.AccumulationRegister,        PictureLib.AccumulationRegister,             False, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("AccountingRegisters",         	 	"Accounting registers",             PictureLib.AccountingRegister,     		PictureLib.AccountingRegister,           	 False, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("CalculationRegisters",             "Calculation registers",            PictureLib.CalculationRegister,         PictureLib.CalculationRegister,              False, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("BusinessProcesses",                "Business-processes",               PictureLib.BusinessProcess,          	PictureLib.BusinessProcessObject,            False, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjects_NewRow("Tasks",                       		"Tasks",                         	PictureLib.Task,                 		PictureLib.TaskObject,                 	     False, CollectionsOfMetadataObjects);
	
	// Create predefined items.
	ItemConfiguration = NewRowOfTree(Metadata.Name, "", Metadata.Synonym, 79, MetadataObjectTree);
	ItemCommon        = NewRowOfTree("Overall",        "", "Overall",             0, ItemConfiguration);
	
	// Filling metadata objects tree.
	For each String IN CollectionsOfMetadataObjects Do
		If Parameters.CollectionsOfSelectedMetadataObjects.Count() = 0 OR
			 Parameters.CollectionsOfSelectedMetadataObjects.FindByValue(String.Name) <> Undefined Then
			OutputCollectionObjectsMetadata(String.Name,
											"",
											String.Synonym,
											String.Picture,
											String.ObjectPicture,
											?(String.ThisIsCollectionCommon, ItemCommon, ItemConfiguration),
											?(String.Name = "Subsystems", Metadata.Subsystems, Undefined));
		EndIf;
	EndDo;
	
	If ItemCommon.GetItems().Count() = 0 Then
		ItemConfiguration.GetItems().Delete(ItemCommon);
	EndIf;
	
EndProcedure

// Function, adding one row to form value tree - tree,
// and also filling full set of rows from metadata using passed parameter
// If Subsystem parameter is filled, then call is recursive because,
// subsystems may contain other subsystems
// Parameters:
// Name          	- name of parent item
// Synonym       	- synonym of parent item
// Check       		- Boolean, initial collection or metadata object mark.
// Picture      	- code of picture of parent item
// ObjectPicture 	- code of subitem picture
// Parent      		- ref to value tree item which is a root node
//                 	  for the item being added
// Subsystems    	- if filled - contains value Metadata.Subsystems
//                    i.e. collection of items
//
// Value returned:
//
//
&AtServer
Function OutputCollectionObjectsMetadata(Name, FullName, Synonym, Picture, ObjectPicture, Parent = Undefined, Subsystems = Undefined)
	
	NewRow = NewRowOfTree(Name, FullName, Synonym, Picture, Parent, Subsystems <> Undefined And Subsystems <> Metadata.Subsystems);
	
	If Subsystems = Undefined Then
		For each MetadataCollectionItem IN Metadata[Name] Do
			If Parameters.FilterByMetadataObjects.FindByValue(MetadataCollectionItem.FullName()) = Undefined Then
				Continue;
			EndIf;
			NewRowOfTree(MetadataCollectionItem.Name,
							MetadataCollectionItem.FullName(),
							MetadataCollectionItem.Synonym,
							ObjectPicture,
							NewRow,
							True);
		EndDo;
	Else
		For each MetadataCollectionItem IN Subsystems Do
			OutputCollectionObjectsMetadata(MetadataCollectionItem.Name,
											MetadataCollectionItem.FullName(),
											MetadataCollectionItem.Synonym,
											Picture,
											ObjectPicture,
											NewRow,
											MetadataCollectionItem.Subsystems);
		EndDo;
	EndIf;
	
	Return NewRow;
	
EndFunction

// Add  new row to form value tree
// Name           - item name
// Synonym        - item synonym
// Picture        - picture code
// Parent         - item of form value tree, for which new branch will be created
//
// Value returned:
//  FormDataItemTree - created tree branch
//
&AtServer
Function NewRowOfTree(Name, FullName, Synonym, Picture, Parent, ThisIsMetadataObject = False)
	
	Collection 					= Parent.GetItems();
	NewRow 						= Collection.Add();
	NewRow.Name                 = Name;
	NewRow.Presentation       	= ?(ValueIsFilled(Synonym), Synonym, Name);
	NewRow.Check             	= ?(Parameters.SelectedMetadataObjects.FindByValue(FullName) = Undefined, 0, 1);
	NewRow.Picture           	= Picture;
	NewRow.FullName           	= FullName;
	NewRow.ThisIsMetadataObject = ThisIsMetadataObject;
	
	Return NewRow;
	
EndFunction

// Adds new row to value table of metadata objects types
// of configuration
//
// Parameters:
// Name           			- name of metadata object or metadata object type
// Synonym       			- synonym of metadata object
// Picture      			- picture being mapped to metadata object
//                 	  		  or metadata object type
// ThisIsCollectionCommon 	- flag indicating, that current item contains subitems
//
&AtServer
Procedure CollectionsOfMetadataObjects_NewRow(Name, Synonym, Picture, ObjectPicture, ThisIsCollectionCommon, Tab)
	
	NewRow = Tab.Add();
	NewRow.Name               		= Name;
	NewRow.Synonym           		= Synonym;
	NewRow.Picture          		= Picture;
	NewRow.ObjectPicture   			= ObjectPicture;
	NewRow.ThisIsCollectionCommon 	= ThisIsCollectionCommon;
	
EndProcedure

// Procedure recursively sets/removes mark for parents of item being passed.
//
// Parameters:
// Item      - FormDataTreeItemCollection
//
&AtClient
Procedure MarkParentItems(Item)

	Parent = Item.GetParent();
	
	If Parent = Undefined Then
		Return;
	EndIf;
	
	If NOT Parent.ThisIsMetadataObject Then
	
		ParentItems = Parent.GetItems();
		If ParentItems.Count() = 0 Then
			Parent.Check = 0;
		ElsIf Item.Check = 2 Then
			Parent.Check = 2;
		Else
			Parent.Check = ItemsMarkValue(ParentItems);
		EndIf;

	EndIf;
	
	MarkParentItems(Parent);

EndProcedure

&AtClient
Function ItemsMarkValue(ParentItems)
	
	AreMarked    = False;
	AreUnmarked  = False;
	
	For each ParentItem1 In ParentItems Do
		
		If ParentItem1.Check = 2 OR (AreMarked And AreUnmarked) Then
			AreMarked    = True;
			AreUnmarked = True;
			Break;
		ElsIf ParentItem1.ThisIsMetadataObject Then
			AreMarked    = AreMarked    OR    ParentItem1.Check;
			AreUnmarked = AreUnmarked OR NOT ParentItem1.Check;
		Else
			NestedElements = ParentItem1.GetItems();
			If NestedElements.Count() = 0 Then
				Continue;
			EndIf;
			NestedItemsMarkValue = ItemsMarkValue(NestedElements);
			AreMarked    = AreMarked    OR    ParentItem1.Check OR    NestedItemsMarkValue;
			AreUnmarked = AreUnmarked OR NOT ParentItem1.Check OR NOT NestedItemsMarkValue;
		EndIf;
	EndDo;
	
	Return ?(AreMarked And AreUnmarked, 2, ?(AreMarked, 1, 0));
	
EndFunction

// Procedure CollectionsInitialCheck sets mark for collection
// of metadata objects, that do not have metadata objects (true) and
// that have metadata objects with specified mark.
//
// Parameters:
// Item      - FormDataTreeItemCollection
//
&AtClient
Procedure CollectionsInitialCheck(Parent = Undefined)

	If Parent = Undefined Then
		Parent = MetadataObjectTree.GetItems()[0];
	EndIf;
	
	If NOT Parent.ThisIsMetadataObject Then
		
		NestedElements = Parent.GetItems();
	
		If NestedElements.Count() = 0 Then
			Parent.Check = 0;
		ElsIf NestedElements[0].ThisIsMetadataObject Then
			MarkParentItems(NestedElements[0]);
		Else
			For each NestedElement IN NestedElements Do
				CollectionsInitialCheck(NestedElement);
			EndDo;
		EndIf;
		
	EndIf;

EndProcedure

// Procedure recursively sets/removes mark for nested items starting
// from item being passed.
//
// Parameters:
// Item      - FormDataTreeItemCollection
//
&AtClient
Procedure MarkNestedElements(Item)

	NestedElements = Item.GetItems();
	
	If NestedElements.Count() = 0 Then
		If NOT Item.ThisIsMetadataObject Then
			Item.Check = 0;
		EndIf;
	Else
		For Each NestedElement IN NestedElements Do
			NestedElement.Check = Item.Check;
			MarkNestedElements(NestedElement);
		EndDo;
	EndIf;
	
EndProcedure

// Procedure, filling list of tree selected items
// Recursively checks entire item tree and, if item
// selected 	- adds item FullName to the list of selected items.
//
// Parent      	- FormDataTreeItem
//
&AtServer
Procedure DataReceiving(Parent = Undefined)
	
	Parent = ?(Parent = Undefined, MetadataObjectTree, Parent);
	
	ItemCollection = Parent.GetItems();
	
	For each Item IN ItemCollection Do
		If Item.Check And NOT IsBlankString(Item.FullName) Then
			SelectedMetadataObjects.Add(Item.FullName);
		EndIf;
		DataReceiving(Item);
	EndDo;
	
EndProcedure


&AtClient
Procedure OnOpen(Cancellation)
	
	CollectionsInitialCheck();
	
EndProcedure

