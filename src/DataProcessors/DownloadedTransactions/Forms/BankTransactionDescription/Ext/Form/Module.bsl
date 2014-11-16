
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not ValueIsFilled(Parameters.Document) Then
		Cancel = True;
		return;
	EndIf;
	Request = New Query("SELECT
	                    |	BankTransactions.TransactionDate,
	                    |	BankTransactions.BankAccount,
	                    |	BankTransactions.Company,
	                    |	BankTransactions.Description,
	                    |	BankTransactions.Amount,
	                    |	BankTransactions.Category,
	                    |	BankTransactions.Document,
	                    |	BankTransactions.Accepted,
	                    |	BankTransactions.Class,
	                    |	BankTransactions.Project
	                    |FROM
	                    |	InformationRegister.BankTransactions AS BankTransactions
	                    |WHERE
	                    |	BankTransactions.Document = &Document");
	Request.SetParameter("Document", Parameters.Document);
	Res = Request.Execute();
	If Res.IsEmpty() Then
		Cancel = True;
		return;
	EndIf;
	Sel = Res.Select();
	Sel.Next();
	Document 	= Sel.Document;
	BankAccount = Sel.BankAccount;
	Date 		= Sel.TransactionDate;
	Company		= Sel.Company;
	Description	= Sel.Description;
	Amount		= Sel.Amount;
	Category	= Sel.Category;
	Class 		= Sel.Class;
	Project		= Sel.Project;
	Accepted	= ?(Sel.Accepted, "Accepted", "Not accepted");
	Items.Accepted.TextColor = ?(Sel.Accepted, WebColors.Green, WebColors.DimGray);	
EndProcedure
