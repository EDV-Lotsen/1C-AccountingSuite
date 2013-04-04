

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	Date                    = Parameters.Date;
	UserName             	= Parameters.UserName;
	ApplicationPresentation = Parameters.ApplicationPresentation;
	Computer                = Parameters.Computer;
	Event                   = Parameters.Event;
	EventPresentation       = Parameters.EventPresentation;
	Comment                 = Parameters.Comment;
	MetadataPresentation    = Parameters.MetadataPresentation;
	Data                    = Parameters.Data;
	DataPresentation        = Parameters.DataPresentation;
	TransactionID           = Parameters.TransactionID;
	TransactionStatus       = Parameters.TransactionStatus;
	SessionNumber                 = Parameters.SessionNumber;
	ServerName              = Parameters.ServerName;
	Port              		= Parameters.Port;
	SyncPort       			= Parameters.SyncPort;
	
	// 'Open' button is enabled for a list of metadata
	If TypeOf(MetadataPresentation) = Type("ValueList") Then
		Items.MetadataPresentation.OpenButton = True;
		Items.AccessMetadataPresentation.OpenButton = True;
		Items.AccessRightRefusalMetadataPresentation.OpenButton = True;
		Items.AccessActionRefusalMetadataPresentation.OpenButton = True;
	EndIf;
	
	// Processing data of special events
	Items.AccessData.Visible = False;
	Items.DataRefusalAccessRights.Visible = False;
	Items.DataRefusalAccessAction.Visible = False;
	Items.AuthenticationData.Visible = False;
	Items.IBUserData.Visible = False;
	Items.SimpleData.Visible = False;
	Items.DataPresentations.PagesRepresentation = FormPagesRepresentation.None;
	
	If Event = "_$Access$_.Access" Then
		Items.DataPresentations.CurrentPage = Items.AccessData;
		Items.AccessData.Visible = True;
		EventData = GetFromTempStorage(Parameters.DataAddress);
		CreateFormTable("AccessDataTable", "DataTable", EventData.Data);
		Items.Comment.VerticalStretch = False;
		Items.Comment.Height = 1;
		
	ElsIf Event = "_$Access$_.AccessDenied" Then
		EventData = GetFromTempStorage(Parameters.DataAddress);
		
		If EventData.Property("Right") Then
			Items.DataPresentations.CurrentPage = Items.DataRefusalAccessRights;
			Items.DataRefusalAccessRights.Visible = True;
			CancellationOfAccessRight = EventData.Right;
		Else
			Items.DataPresentations.CurrentPage = Items.DataRefusalAccessAction;
			Items.DataRefusalAccessAction.Visible = True;
			CancellationOfAccessAction = EventData.Action;
			CreateFormTable("DataTableRefusalAccessAction", "DataTable", EventData.Data);
			Items.Comment.VerticalStretch = False;
			Items.Comment.Height = 1;
		EndIf;
		
	ElsIf Event = "_$SessionNumber$_.Authentication"
		  OR Event = "_$SessionNumber$_.AuthenticationError" Then
		EventData = GetFromTempStorage(Parameters.DataAddress);
		Items.DataPresentations.CurrentPage = Items.AuthenticationData;
		Items.AuthenticationData.Visible = True;
		EventData.Property("Name",          AuthenticationUserName);
		EventData.Property("OSUser",        AuthenticationOSUser);
		EventData.Property("CurrentOSUser", AuthenticationCurrentOSUser);
		
	ElsIf Event = "_$User$_.Delete"
		  OR Event = "_$User$_.New"
		  OR Event = "_$User$_.Update" Then
		EventData = GetFromTempStorage(Parameters.DataAddress);
		Items.DataPresentations.CurrentPage = Items.IBUserData;
		Items.IBUserData.Visible = True;
		IBUserProperties = New ValueTable;
		IBUserProperties.Columns.Add("Name");
		IBUserProperties.Columns.Add("Value");
		RolesArray = Undefined;
		For each KeyAndValue IN EventData Do
			If KeyAndValue.Key = "Roles" Then
				RolesArray = KeyAndValue.Value;
				Continue;
			EndIf;
			NewRow 			= IBUserProperties.Add();
			NewRow.Name     = KeyAndValue.Key;
			NewRow.Value 	= KeyAndValue.Value;
		EndDo;
		CreateFormTable("TableOfIBUserProperties", "DataTable", IBUserProperties);
		If RolesArray <> Undefined Then
			IBUserRoles = New ValueTable;
			IBUserRoles.Columns.Add("Role",, NStr("en = 'Role'"));
			For each CurrentRole In RolesArray Do
				IBUserRoles.Add().Role = CurrentRole;
			EndDo;
			CreateFormTable("TableOfRolesOfIBUser", "Roles", IBUserRoles);
		EndIf;
		Items.Comment.VerticalStretch = False;
		Items.Comment.Height = 1;
		
	Else
		Items.DataPresentations.CurrentPage = Items.SimpleData;
		Items.SimpleData.Visible = True;
	EndIf;
	
EndProcedure

Procedure CreateFormTable(Val FieldNameOfFormTable, Val AttributeNameFormDataCollection, Val ValueTable)
	
	If TypeOf(ValueTable) <> Type("ValueTable") Then
		ValueTable = New ValueTable;
		ValueTable.Columns.Add("Undefined", , " ");
	EndIf;
	
	// Add attributes to the form table
	AttributesBeingAdded = New Array;
	For each Column In ValueTable.Columns Do
		AttributesBeingAdded.Add(New FormAttribute(Column.Name, Column.ValueType, AttributeNameFormDataCollection, Column.Title));
	EndDo;
	ChangeAttributes(AttributesBeingAdded);
	
	// Add items to the form
	For each Column In ValueTable.Columns Do
		AttributeItem = Items.Add(FieldNameOfFormTable + Column.Name, Type("FormField"), Items[FieldNameOfFormTable]);
		AttributeItem.DataPath = AttributeNameFormDataCollection + "." + Column.Name;
	EndDo;
	
	ValueToFormAttribute(ValueTable, AttributeNameFormDataCollection);
	
EndProcedure

&AtClient
Procedure MetadataPresentationOpening(Item, StandardProcessing)
	
	OpenValue(MetadataPresentation);
	
EndProcedure

&AtClient
Procedure DataTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	OpenValue(Item.CurrentData[Mid(Field.Name, StrLen(Item.Name)+1)]);
	
EndProcedure
