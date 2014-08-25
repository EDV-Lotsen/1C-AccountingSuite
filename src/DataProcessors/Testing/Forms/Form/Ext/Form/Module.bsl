
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetPrivilegedMode(True);
	
	Try
		BeginTransaction(DataLockControlMode.Managed);
		//Lock ChartOfAccounts
		DLock = New DataLock();
		LockItem = DLock.Add("ChartOfAccounts.ChartOfAccounts");
		LockItem.Mode = DataLockMode.Exclusive;
		DLock.Lock();
		Request = New Query("SELECT
		                    |	ChartOfAccounts.Ref
		                    |FROM
		                    |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
		                    |WHERE
		                    |	ChartOfAccounts.DeletionMark = TRUE");
		Res = Request.Execute().Select();
		While Res.Next() Do
			AccountObject = Res.Ref.GetObject();
			AccountObject.DeletionMark = False;
			AccountObject.Write();
		EndDo;

	Except
	EndTry;
	CommitTransaction();

	
EndProcedure