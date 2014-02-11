Procedure UpdateFTSE() Export
	
	//WriteLogEvent(NStr("en = '8.3 FTS indexing'"),
	//EventLogLevel.Information, , ,
	//NStr("en = '8.3 FTS indexing'"));
	
	FullTextSearch.UpdateIndex(False, True);

	
EndProcedure

Procedure MergeFTSE() Export
	
	FullTextSearch.UpdateIndex(True);
	
EndProcedure 

Procedure ActiveUserList() Export
	
	If Constants.ServiceDB.Get() = True Then
	
		IBConnections = GetInfoBaseConnections();
		
		TimeStampValue = ToUniversalTime(CurrentDate()) - '19700101';
		//TimeStamp = Format(TimeStampValue,"NG=");
			
		UniqueNames = New Array();
		
		For Each Connection In IBConnections Do           		
			
			UserName = Connection.User.Name;
			
			//Index = UniqueNames.Find(UserName);
			
			//If Index = Undefined Then
			
				If UserName <> "" AND UserName <> "primary_support@accountingsuite.com" AND UserName <> "kurt@accountingsuite.com" AND UserName <> "kzuzik@accountingsuite.com" Then 
									
					NewRecord = Catalogs.UserLog.CreateItem();
					NewRecord.Description = UserName;
					NewRecord.timestamp = TimeStampValue;
					NewRecord.tenant_value = Connection.User.DataSeparation.Tenant;
					NewRecord.Write();
								
				//EndIf;
				
				//UniqueNames.Add(UserName);
				
			Else
			EndIf;
			
		EndDo;
		
	EndIf;

EndProcedure


