&AtServer
Procedure AddSampleBankTransactions(BankAccount, DateStart=Undefined, DateEnd=Undefined) Export
	SetPrivilegedMode(True);
	BeginTransaction(DataLockControlMode.Managed);
	Try
		
		SessionDate	= CurrentSessionDate();
		If DateStart = Undefined Then
			DateStart = BegOfDay(AddMonth(SessionDate, -1));
		EndIf;
		If DateEnd = Undefined Then
			DateEnd = BegOfDay(SessionDate);
		EndIf;
		ArrayOfIncomingDescriptions = New Array;
		ArrayOfIncomingDescriptions.Add(New Structure("Description, Category", "ACH_STRIPE TRANSFER", 32));
		ArrayOfIncomingDescriptions.Add(New Structure("Description, Category", "Transfer from Checking", 28));
		ArrayOfIncomingDescriptions.Add(New Structure("Description, Category", "Payment for services", 94));
		ArrayOfIncomingDescriptions.Add(New Structure("Description, Category", "Bank interest", 96));
		ArrayOfOutcomingDescriptions = New Array;
		ArrayOfOutcomingDescriptions.Add(New Structure("Description, Category", "Transfer to Checking", 28));
		ArrayOfOutcomingDescriptions.Add(New Structure("Description, Category", "Fee", 24));
		ArrayOfOutcomingDescriptions.Add(New Structure("Description, Category", "Fruits & Groceries Co", 10));
		ArrayOfOutcomingDescriptions.Add(New Structure("Description, Category", "Payment to the service provider", 16));
		NumberOfDays = Round((DateEnd - DateStart)/(24*3600));
		RNG = New RandomNumberGenerator();
		For i = 0 To NumberOfDays Do
			NumberOfIncomings = RNG.RandomNumber(0, 3);
			NumberOfOutcomings = RNG.RandomNumber(0, 3);
			TransactionDate = DateStart + i * 24 * 3600; 
			For NI = 1 To NumberOfIncomings Do
				CreateBankTransaction(BankAccount, TransactionDate, TRUE, ArrayOfIncomingDescriptions, ArrayOfOutcomingDescriptions, RNG);
			EndDo;
			For NI = 1 To NumberOfOutcomings Do
				CreateBankTransaction(BankAccount, TransactionDate, FALSE, ArrayOfIncomingDescriptions, ArrayOfOutcomingDescriptions, RNG);
			EndDo;		
		EndDo;
	
		CommitTransaction();
		WriteLogEvent(
			"Infobase.PrimaryDemobasePopulation",
			EventLogLevel.Information,
			,
			,
			"Sample bank transactions for the Demo were created successfully.");
	Except
		ErrorDescription = ErrorDescription();
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		WriteLogEvent(
			"Infobase.PrimaryDemobasePopulation",
			EventLogLevel.Error,
			,
			,
			"Creation of sample bank transactions for the Demo failed. Reason:" + ErrorDescription);
	EndTry;
		
EndProcedure

&AtServer
Procedure CreateBankTransaction(BankAccount, TransactionDate, IsIncoming, IncomingDescriptions, OutcomingDescriptions, RNG)
	RecordSet = InformationRegisters.BankTransactions.CreateRecordSet();
	NewID = New UUID();
	RecordSet.Filter.ID.Set(NewID);
	NewRecord = RecordSet.Add();
	NewRecord.ID = NewID;
	NewRecord.TransactionDate = TransactionDate;
	NewRecord.BankAccount = BankAccount;
	If IsIncoming Then
		NewRecord.Amount = RNG.RandomNumber(1, 100)*10;
		InDesc = IncomingDescriptions[RNG.RandomNumber(0,3)];
		NewRecord.Description = InDesc.Description;
		NewRecord.CategoryID = InDesc.Category;
	Else
		NewRecord.Amount = -1 * RNG.RandomNumber(1, 100)*10;
		OutDesc = OutcomingDescriptions[RNG.RandomNumber(0,3)];
		NewRecord.Description = OutDesc.Description;
		NewRecord.CategoryID = OutDesc.Category;
	EndIf;	
	RecordSet.Write = True;
	RecordSet.Write();
EndProcedure
