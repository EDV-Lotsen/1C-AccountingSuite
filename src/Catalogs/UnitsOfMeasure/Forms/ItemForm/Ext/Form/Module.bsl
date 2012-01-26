
&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Object.ConversionRatio <= 0 Then
		
		Message = New UserMessage();
		Message.Text=NStr("en='Conversion ratio has to be > 0'");
		Message.Field = "Object.ConversionRatio";
		Message.Message();
		Cancel = True;
		Return;
		
	EndIf;

EndProcedure
