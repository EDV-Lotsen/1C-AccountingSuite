
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	AuditLogList.Parameters.SetParameterValue("DocUUID", Parameters.Filter.DocUUID);
EndProcedure
