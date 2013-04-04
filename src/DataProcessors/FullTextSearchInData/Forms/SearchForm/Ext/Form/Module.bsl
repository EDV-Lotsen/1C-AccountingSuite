
&AtClient
Function ThisIsURL(Ref)
	
	If Find(Ref, "e1cib/data/") <> 0 Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction	

&AtClient
Procedure OpenSearchValue(Value)
	StandardProcessing = True;
	FullTextSearchClientOverrided.OnObjectOpen(Value, StandardProcessing);
	
	If StandardProcessing = True Then
		OpenValue(Value);
	EndIf;
EndProcedure

// Returns array of objects (perhaps containig single item) to display to user
&AtServerNoContext
Function GetValuesForOpening(Object)
	Result = New Array;
	
	// Object of referencial type
	If CommonUse.IsReferentialTypeValue(Object) Then
		Result.Add(Object);
		Return Result;
	EndIf;
	
	ObjectMetadata = Metadata.FindByType(TypeOf(Object));
	NameOfMetadata = ObjectMetadata.Name;
	
	FullObjectName = UPPER(Metadata.FindByType(TypeOf(Object)).FullName());
	ThisIsInformationRegister = (Find(FullObjectName, "INFORMATIONREGISTER.") > 0);

	If Not ThisIsInformationRegister Then // Accounting register or accumulation register, or calculation register
		Recorder = Object["Recorder"];
		Result.Add(Recorder);
		Return Result;
	EndIf;

	// Below - this is already information register
	If ObjectMetadata.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate Then
		Recorder = Object["Recorder"];
		Result.Add(Recorder);
		Return Result;
	EndIf;

	// Independent information register
	// first - main types
	For Each Dimension In ObjectMetadata.Dimensions Do
		If Dimension.Master Then 
			DimensionValue = Object[Dimension.Name];
			
			If CommonUse.IsReferentialTypeValue(DimensionValue) Then
				Result.Add(DimensionValue);
			EndIf;
			
		EndIf;
	EndDo;

	If Result.Count() = 0 Then
		// now - any types
		For Each Dimension In ObjectMetadata.Dimensions Do
			If Dimension.Master Then 
				DimensionValue = Object[Dimension.Name];
				Result.Add(DimensionValue);
			EndIf;
		EndDo;
	EndIf;
	
	// There is no one master dimension - return information register key
	If Result.Count() = 0 Then
		Result.Add(Object);
	EndIf;

	Return Result;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Service functions
//

&AtServerNoContext
Procedure SaveSearchString(ChoiceList, SearchString)
	
	SavedString = ChoiceList.FindByValue(SearchString);
	
	If SavedString <> Undefined Then
		ChoiceList.Delete(SavedString);
	EndIf;
		
	ChoiceList.Insert(0, SearchString);
	
	RowsCount = ChoiceList.Count();
	
	If RowsCount > 20 Then
		ChoiceList.Delete(RowsCount - 1);
	EndIf;
	
	Rows = ChoiceList.UnloadValues();
	
	CommonSettingsStorage.Save("FullTextStringSearchOfFullTextSearch", , Rows);
	
EndProcedure	

&AtServer
Procedure UpdateIndexServer()
	SetPrivilegedMode(True);
	FullTextSearch.UpdateIndex(False, False);
	
	DateActualityIndex = FullTextSearch.UpdateDate();
	IndexTrue = FullTextSearch.IndexTrue();
	Items.GroupIndexUpdate.Visible = Not IndexTrue;
	Items.UpdateIndex.Enabled = Not IndexTrue;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Handlers are mapped to these functions
//

// Search procedure, get and display result
//
&AtClient
Procedure Search_(Direction)
	
	Try
		If IsBlankString(SearchString) Then
			DoMessageBox(NStr("en = 'Enter, search text!'"));
			Return;
		EndIf;
		
		If ThisIsURL(SearchString) Then
			GotoURL(SearchString);
			SearchString = "";
			Return;
		EndIf;
		
		NString = StringFunctionsClientServer.SubstitureParametersInString(NStr("en = 'Searches for ""%1""...'"), SearchString);
		Status(NString);
		
		ChoiceList = Items.SearchString.ChoiceList.Copy();
		Result = RunSearch(Direction, CurrentPosition, SearchString, ChoiceList);
		Items.SearchString.ChoiceList.Clear();
		For Each ChoiceListItem In ChoiceList Do
			Items.SearchString.ChoiceList.Add(ChoiceListItem.Value, ChoiceListItem.Presentation);
		EndDo;
		
		If ThisIsFileBase Then
			UpdateIndexActuality();
		EndIf;
		
		Status();
		
		SearchResults = Result.SearchResult;
		HTMLText = Result.HTMLText;
		CurrentPosition = Result.CurrentPosition;
		TotalCount = Result.TotalCount;
		
		If SearchResults.Count() <> 0 Then
			
			ResultsShownFromTo = StringFunctionsClientServer.SubstitureParametersInString(
			                            NStr("en = 'Indicated %1 - %2 from %3'"),
			                            String(CurrentPosition + 1),
			                            String(CurrentPosition + SearchResults.Count()),
			                            String(TotalCount) );
			
			Items.NextStep.Enabled = (TotalCount - CurrentPosition) > SearchResults.Count();
			Items.Back.Enabled = (CurrentPosition > 0);
		Else
			ResultsShownFromTo = NStr("en = 'Not found'");
			Items.NextStep.Enabled = False;
			Items.Back.Enabled = False;
		EndIf;
		
		If Direction = 0 And Result.CurrentPosition = 0 And Result.TooManyResults Then
			DoMessageBox(NStr("en = 'Too many results, refine query.'"));
		EndIf;
		
	Except
		DoMessageBox(BriefErrorDescription(ErrorInfo()));
	EndTry	
			
EndProcedure

&AtServer
Procedure UpdateIndexActuality()
	
	If ThisIsFileBase Then
		Items.GroupIndexUpdate.Visible = True;
		
		Try
			DateActualityIndex = FullTextSearch.UpdateDate();
			If DateActualityIndex <> '00010101000000' Then
				Items.StatusOfIndex.ToolTip = NStr("en = 'Last index update:'") + String(DateActualityIndex);
			EndIf;
			
			IndexTrue = FullTextSearch.IndexTrue();
			Items.GroupIndexUpdate.Visible = Not IndexTrue;
			Items.UpdateIndex.Enabled = Not IndexTrue;
			If Not IndexTrue Then
				StatusOfIndex = NStr("en = 'Index update required.'");
			EndIf;
		Except
		EndTry;
		
	Else
		Items.GroupIndexUpdate.Visible = False;
	EndIf;
	
EndProcedure

// Procedure does full-text search
//
&AtServerNoContext
Function RunSearch(Direction, CurrentPosition, SearchString, ChoiceList) Export
	
	SaveSearchString(ChoiceList, SearchString);
	
	Return SearchExecuteServer(Direction, CurrentPosition, SearchString);
	
EndFunction

// Procedure does full-text search
//
&AtServerNoContext
Function SearchExecuteServer(Direction, CurrentPosition, SearchString) Export
	
	PortionSize = 20;
	
	SearchList = FullTextSearch.CreateList(SearchString, PortionSize);
	
	If Direction = 0 Then
		SearchList.FirstPart();
	ElsIf Direction = -1 Then
		SearchList.PreviousPart(CurrentPosition);
	ElsIf Direction = 1 Then
		SearchList.NextPart(CurrentPosition);
	EndIf;
	
	SearchResults = New ValueList;
	SearchResults.Clear();
	For Each Result In SearchList Do
		ResultStructure = New Structure;
		ResultStructure.Insert("Value", Result.Value);
		ResultStructure.Insert("ValuesForOpen", GetValuesForOpening(Result.Value));
		SearchResults.Add(ResultStructure);
	EndDo;
	
	HTMLText = SearchList.GetRepresentation(FullTextSearchRepresentationType.HTMLText);
	
	HTMLText = StrReplace(HTMLText, "<td>", "<td><font face=""Arial"" size=""2"">");
	HTMLText = StrReplace(HTMLText, "<td valign=top width=1>", "<td valign=top width=1><font face=""Arial"" size=""1"">");
	HTMLText = StrReplace(HTMLText, "<body>", "<body topmargin=0 leftmargin=0 scroll=auto>");
	HTMLText = StrReplace(HTMLText, "</td>", "</font></td>");
	HTMLText = StrReplace(HTMLText, "<b>", "");
	HTMLText = StrReplace(HTMLText, "</b>", "");
	
	CurrentPosition = SearchList.StartPosition();
	TotalCount = SearchList.TotalCount();
	TooManyResults = SearchList.TooManyResults();
	
	Result = New Structure;
	Result.Insert("SearchResult", SearchResults);
	Result.Insert("CurrentPosition", CurrentPosition);
	Result.Insert("TotalCount", TotalCount);
	Result.Insert("HTMLText", HTMLText);
	Result.Insert("TooManyResults", TooManyResults);
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Handlers of form and form item events
//

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	StringOfConnectionWithDB = InfoBaseConnectionString();
	ThisIsFileBase = CommonUse.FileInformationBase(StringOfConnectionWithDB);
	UpdateIndexActuality();
	
	Try
		ResultsShownFromTo = NStr("en = 'Enter the search string.'");
		CurrentPosition = 0;
		
		Items.NextStep.Enabled = False;
		Items.Back.Enabled = False;
		
		Array = CommonSettingsStorage.Load("FullTextStringSearchOfFullTextSearch");
		
		If Array <> Undefined Then
			Items.SearchString.ChoiceList.LoadValues(Array);
		EndIf;	
		
		If Not IsBlankString(Parameters.PassedSearchString) Then
			SearchString = Parameters.PassedSearchString;
			
			SaveSearchString(Items, SearchString);
			Result = SearchExecuteServer(0, CurrentPosition, SearchString);
			
			SearchResults = Result.SearchResult;
			HTMLText = Result.HTMLText;
			CurrentPosition = Result.CurrentPosition;
			TotalCount = Result.TotalCount;
			
			If SearchResults.Count() <> 0 Then
				
				ResultsShownFromTo = StringFunctionsClientServer.SubstitureParametersInString(
				                            NStr("en = 'Indicated %1 - %2 from %3'"),
				                            String(CurrentPosition + 1),
				                            String(CurrentPosition + SearchResults.Count()),
				                            String(TotalCount) );
				
				Items.NextStep.Enabled = (TotalCount - CurrentPosition) > SearchResults.Count();
				Items.Back.Enabled = (CurrentPosition > 0);
			Else
				ResultsShownFromTo = NStr("en = 'Not found'");
				Items.NextStep.Enabled = False;
				Items.Back.Enabled = False;
			EndIf;
		Else
			HTMLText = "<html>
						|<head>
						|<meta http-equiv=""Content-Style-Type"" content=""text/css"">
						|</head>
						|<body topmargin=0 leftmargin=0 scroll=auto>
						|<table border=""0"" width=""100%"" cellspacing=""5"">
						|</table>
						|</body>
						|</html>";
		EndIf;	
	Except	
	EndTry;
EndProcedure

&AtClient
Procedure SearchStringOnChange(Item)
	
	Search_(0);
	
EndProcedure

&AtClient
Procedure SearchStringChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	SearchString = ValueSelected;
	Search_(0);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Handlers of form commands
//

// Processing of command Find
//
&AtClient
Procedure SearchExecute()
	
	Search_(0);
	
EndProcedure

// Handler of command Next
//
&AtClient
Procedure NextRun()
	
	Search_(1);
	
EndProcedure

// Handler of command Back
//
&AtClient
Procedure BackExecute()
	Search_(-1);
EndProcedure

&AtClient
Procedure UpdateIndex(Command)
	
	Status(NStr("en = 'Updating fullsearch index..."
				"Please wait.'"));
	
	UpdateIndexServer();
	
	Status(NStr("en = 'Updates of the full text index has been completed'"));
	
EndProcedure

&AtClient
Procedure HTMLTextOnClick(Item, EventData, StandardProcessing)
	HTMLElement = EventData.Anchor;
	
	If HTMLElement = Undefined Then
		Return;
	EndIf;
	
	If (HTMLElement.id = "FullTextSearchListItem") Then
		URLPart = HTMLElement.pathName;
		CharPosition = StringFunctionsClientServer.FindCharFromEnd(URLPart, "/");
		If CharPosition <> 0 Then
			URLPart = Mid(URLPart, CharPosition + 1);
		EndIf;		
			
		NumberInList = Number(URLPart);
		ResultStructure = SearchResults[NumberInList].Value;
		RowSelected = ResultStructure.Value;
		ObjectsArray = ResultStructure.ValuesForOpen;

		If ObjectsArray.Count() = 1 Then
			OpenSearchValue(ObjectsArray[0]);
		ElsIf ObjectsArray.Count() <> 0 Then
			List = New ValueList;
			For Each ArrayItem In ObjectsArray Do
				List.Add(ArrayItem);
			EndDo;
			SelectedObject = ChooseFromList(List, Items.HTMLText);
			If SelectedObject <> Undefined Then
				OpenSearchValue(SelectedObject.Value);
			EndIf;
		EndIf;

		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure OpenNew(Command)
	GotoURL("https://login.accountingsuite.com");
EndProcedure

&AtClient
Procedure Support(Command)
	GotoURL("http://support.accountingsuite.com");
EndProcedure

&AtClient
Procedure UserGuide(Command)
	OpenHelpContent();
EndProcedure

