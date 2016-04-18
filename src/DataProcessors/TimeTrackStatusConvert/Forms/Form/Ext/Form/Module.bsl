&AtClient
Procedure Timer()
	MinuteInc = False;
	HourInc = False;
	If Seconds = 59 Then
		Seconds = 0;
		Minutes = Minutes + 1;
		MinuteInc = True;
	EndIf;
	If Minutes = 59 Then
		Minutes = 0;
		Hours = Hours + 1;
		HourInc = True;
	EndIf;	
	
	If MinuteInc Then
		MinuteInc = False;
	Else
		Seconds = Seconds + 1;
	EndIf;
	TimerCounter = String(Hours) + ":" + String(Minutes) + ":" + String(Seconds);
EndProcedure


&AtClient
Procedure OnClose()
	DetachIdleHandler("Timer");
EndProcedure

&AtClient
Procedure TimerControl(Command)
	If NOT TimerStart Then
		Items.FormTimerControl.Title = "Stop";
		AttachIdleHandler("Timer",1);
		TimerStart = True;
	Else
		Items.FormTimerControl.Title = "Start";
		DetachIdleHandler("Timer");
		TimerStart = False;
		TimeTrackOutput = Hours + (Minutes/100);
	EndIf;
EndProcedure

