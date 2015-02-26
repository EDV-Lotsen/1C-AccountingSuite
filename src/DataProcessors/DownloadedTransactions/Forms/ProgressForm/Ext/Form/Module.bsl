&AtClient
Var CurrentMatchingStep, OperationsResults;

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	BankAccount 			= Parameters.BankAccount;
	PerformCategorization 	= Parameters.PerformCategorization;
	PerformMatching 		= Parameters.PerformMatching;
	PerformAccept			= Parameters.PerformAccept;
	AccountingAccount		= Parameters.AccountingAccount;
	If ValueIsFilled(BankAccount) Then
		ThisForm.Title = String(BankAccount);
	EndIf;
	If PerformCategorization Then
		Items.ProgressDescription.Title = "Categorizing transactions...";
		
		Progress = New Structure("CurrentStatus, ErrorDescription", False, "");
		TempStorageAddress = PutToTempStorage(Progress, ThisForm.UUID);

		//Prepare data for background execution
		ProcParameters = New Array;
 		ProcParameters.Add(BankAccount);
 		ProcParameters.Add(TempStorageAddress);
	
		//Performing background operation
		JobTitle = NStr("en = 'Starting the bank account categorization process'");
		Job = BackgroundJobs.Execute("Categorization.CategorizeTransactionsAtServer", ProcParameters, , JobTitle);
	EndIf;
	If PerformAccept Then
		Items.ProgressDescription.Title = "Approving transactions...";
		
		Progress = New Structure("CurrentStatus, ErrorDescription", False, "");
		TempStorageAddress = PutToTempStorage(Progress, ThisForm.UUID);

		//Prepare data for background execution
		ProcParameters = New Array;
 		ProcParameters.Add(Parameters.ListOfTransactions);
		ProcParameters.Add(Parameters.ListOfCategories);
		ProcParameters.Add(AccountingAccount);
 		ProcParameters.Add(TempStorageAddress);
	
		//Performing background operation
		JobTitle = NStr("en = 'Starting the process of approving the transactions'");
		Job = BackgroundJobs.Execute("Categorization.AcceptTransactionsAtServer", ProcParameters, , JobTitle);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If PerformCategorization Then
		AttachIdleHandler("DispatchCategorizeTransactions", 0.3, True);
	ElsIf PerformAccept Then
		AttachIdleHandler("DispatchAcceptingTransactions", 0.3, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure DispatchCategorizeTransactions() Export
	
	CategorizingResult = GetFromTempStorage(TempStorageAddress);
	If TypeOf(CategorizingResult) <> Type("Structure") Then
		ShowMessageBox(, "An error occured while categorizing transactions",, "Categorizing transactions");
		return;
	EndIf;
	
	If (CategorizingResult.CurrentStatus = True) Or (ValueIsFilled(CategorizingResult.ErrorDescription)) Then
		CategorizingResult.Insert("CurrentStep", "Categorizing");
		If PerformMatching Then
			//Start matching
			OperationsResults.Clear();
			CurrentMatchingStep = 0;
			OperationsResults.Add(CategorizingResult);
			StartMatchingTransactions(CurrentMatchingStep);
			AttachIdleHandler("DispatchMatchingTransactions", 0.3, True);
		Else
			Close(CategorizingResult);
		EndIf;
	Else
		AttachIdleHandler("DispatchCategorizeTransactions", 0.3, True);
	EndIf; 
	
EndProcedure

&AtServer
Procedure StartMatchingTransactions(CurrentMatchingStep)
	
	If PerformMatching Then
		Items.ProgressDescription.Title = "Matching with the documents...";
		
		Progress = New Structure("CurrentStatus, ErrorDescription", False, "");
		TempStorageAddress = PutToTempStorage(Progress, ThisForm.UUID);

		//Prepare data for background execution
		ProcParameters = New Array;
 		ProcParameters.Add(BankAccount);
		ProcParameters.Add(AccountingAccount);
 		ProcParameters.Add(TempStorageAddress);
	
		//Performing background operation
		JobTitle = NStr("en = 'Matching transactions with Transfer documents'");
		If CurrentMatchingStep = 0 Then
			Job = BackgroundJobs.Execute("Categorization.MatchTransferDocuments", ProcParameters, , JobTitle);
			CurrentMatchingStep = CurrentMatchingStep + 1;
		ElsIf CurrentMatchingStep = 1 Then
			Job = BackgroundJobs.Execute("Categorization.MatchChecks", ProcParameters, , JobTitle);
			CurrentMatchingStep = CurrentMatchingStep + 1;
		ElsIf CurrentMatchingStep = 2 Then
			Job = BackgroundJobs.Execute("Categorization.MatchDepositDocuments", ProcParameters, , JobTitle);
			CurrentMatchingStep = CurrentMatchingStep + 1;
		ElsIf CurrentMatchingStep = 3 Then
			Job = BackgroundJobs.Execute("Categorization.MatchCheckDocuments", ProcParameters, , JobTitle);
			CurrentMatchingStep = CurrentMatchingStep + 1;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure DispatchMatchingTransactions() Export
	
	MatchingProgress = GetFromTempStorage(TempStorageAddress);
	If TypeOf(MatchingProgress) <> Type("Structure") Then
		ShowMessageBox(, "An error occured while matching transactions",, "Matching transactions");
		return;
	EndIf;
	
	If (MatchingProgress.CurrentStatus = True) Or (ValueIsFilled(MatchingProgress.ErrorDescription)) Then
		If CurrentMatchingStep = 1 Then
			MatchingProgress.Insert("CurrentStep", "MatchTransferDocuments");
		ElsIf CurrentMatchingStep = 2 Then
			MatchingProgress.Insert("CurrentStep", "MatchChecks");
		ElsIf CurrentMatchingStep = 3 Then
			MatchingProgress.Insert("CurrentStep", "MatchDepositDocuments");
		ElsIf CurrentMatchingStep = 4 Then
			MatchingProgress.Insert("CurrentStep", "MatchCheckDocuments");
		EndIf;
		OperationsResults.Add(MatchingProgress);
		If CurrentMatchingStep < 4 Then
			StartMatchingTransactions(CurrentMatchingStep);
			AttachIdleHandler("DispatchMatchingTransactions", 0.3, True);
		ElsIf CurrentMatchingStep = 4 Then
			Close(OperationsResults);
		EndIf;
	Else
		AttachIdleHandler("DispatchMatchingTransactions", 0.3, True);
	EndIf; 
	
EndProcedure

&AtClient
Procedure DispatchAcceptingTransactions() Export
	
	AcceptingResult = GetFromTempStorage(TempStorageAddress);
	If TypeOf(AcceptingResult) <> Type("Structure") Then
		ShowMessageBox(, "An error occured while approving transactions",, "Approving transactions");
		return;
	EndIf;
	
	If (AcceptingResult.CurrentStatus = True) Or (ValueIsFilled(AcceptingResult.ErrorDescription)) Then
		Close(AcceptingResult);
	Else
		AttachIdleHandler("DispatchAcceptingTransactions", 0.3, True);
	EndIf; 
	
EndProcedure

CurrentMatchingStep = 0;
OperationsResults 	= New Array();