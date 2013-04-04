
// Idle handler checks, that information base has been updated dynamically, and
// displays message to user.
//
Procedure InfobaseDynamicChangesCheckIdleHandler() Export
	
	If DynamicUpdateMonitoring.InfoBaseConfigurationChangedDynamically() Then
		
		DetachIdleHandler("InfobaseDynamicChangesCheckIdleHandler");
		
		MessageText = NStr("en = 'Infobase configuration has been changed. It is recommended to restart the system. Restart now?'");
		
		If DoQueryBox(MessageText, QuestionDialogMode.YesNo) = DialogReturnCode.Yes Then
			Exit(True, True);
		EndIf;
		
		AttachIdleHandler("InfobaseDynamicChangesCheckIdleHandler", 20 * 60);
		
	EndIf;
	
EndProcedure
