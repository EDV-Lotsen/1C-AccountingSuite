
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	BankAccount = Parameters.BankAccount;
	PerformCategorization = Parameters.PerformCategorization;
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
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	AttachIdleHandler("DispatchCategorizeTransactions", 0.3, True);
EndProcedure

&AtClient
Procedure DispatchCategorizeTransactions() Export
	Progress = GetFromTempStorage(TempStorageAddress);
	If TypeOf(Progress) <> Type("Structure") Then
		ShowMessageBox(, "An error occured while categorizing transactions",, "Categorizing transactions");
		return;
	EndIf;
	
	If (Progress.CurrentStatus = True) Or (ValueIsFilled(Progress.ErrorDescription)) Then
		If Progress.Property("AffectedRows") Then
			Close(Progress.AffectedRows);
		Else
			Close();
		EndIf;
	Else
		AttachIdleHandler("DispatchCategorizeTransactions", 0.3, True);
	EndIf; 
EndProcedure
