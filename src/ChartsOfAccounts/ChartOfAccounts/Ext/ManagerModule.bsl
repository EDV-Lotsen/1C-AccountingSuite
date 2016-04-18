
Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	StandardProcessing = False;
	Fields.Add("Code");
	Fields.Add("Description");
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	StandardProcessing = False;
	Presentation = Data.Code + " " + Data.Description;
EndProcedure

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Parameters.Property("BankAccountType") Then
		
		StandardProcessing = False;
		Request = new Query("SELECT
		                    |	ChartOfAccounts.Ref,
		                    |	ChartOfAccounts.DeletionMark
		                    |FROM
		                    |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
		                    |WHERE
		                    |	(ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.Bank)
		                    |			OR ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.OtherCurrentLiability)
		                    |				AND ChartOfAccounts.CreditCard)
		                    |	AND (ChartOfAccounts.Description LIKE &SearchString
		                    |			OR ChartOfAccounts.Code LIKE &SearchString)
		                    |
		                    |ORDER BY
		                    |	ChartOfAccounts.Code");
		Request.SetParameter("SearchString", "%" + Parameters.SearchString + "%");
		
		AccList = new ValueList();
		
		Sel = Request.Execute().Select();
		While Sel.Next() Do
			Struct = new Structure("Value, DeletionMark", Sel.Ref, Sel.DeletionMark);
			AccList.Add(Struct);
		EndDo;
		ChoiceData = AccList;
		
	EndIf;
	
EndProcedure


