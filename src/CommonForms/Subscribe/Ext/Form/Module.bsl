
&AtClient
Procedure Entrepreneur(Command)
	GoToURL("https://pay.accountingsuite.com/monthly?token=yDU8qbKeihtBvjpri9O1&state=" + TenantV());
EndProcedure

&AtServer
Function TenantV()
	
	Return SessionParameters.TenantValue;
	
EndFunction

&AtClient
Procedure Premium(Command)
	GoToURL("https://pay.accountingsuite.com/monthly?token=jQswFppCrhgGMw8Avoz4&state=" + TenantV());
EndProcedure

&AtClient
Procedure SmallBusiness(Command)
	GoToURL("https://pay.accountingsuite.com/monthly?token=j9S512cxZHXMU6j4RhX7&state=" + TenantV());
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
        If Constants.SubStatus.Get() = ""  Then
                If SubscribeVersion() = 0 Then
                        Items.SubStatus.Title = "Your Plan: Free Trial (Entrepreneur)";
                Elsif SubscribeVersion() = 1 Then
                        Items.SubStatus.Title = "Your Plan: Free Trial (Small Business)";
                Elsif SubscribeVersion() = 2 Then
                        Items.SubStatus.Title = "Your Plan: Free Trial (Premium)";
                Else
                        Items.SubStatus.Title = "Your Plan: Free Trial";
                EndIf;
                Items.Decoration1.Visible = False;
        Else
                Items.SubStatus.Title = "Your Plan: " + Constants.SubStatus.Get();
				Items.SubscribeButton.Visible = False;
                Items.Decoration1.Visible = True;
        Endif;
        test = constants.FreeTrial30.Get();
        Query = New Query;
        Query.Text = "SELECT
                     |  DATEDIFF(&CurrentDate, FreeTrial30.Value, DAY) AS DateDiff
                     |FROM
                     |  Constant.FreeTrial30 AS FreeTrial30";
        Query.Parameters.Insert("CurrentDate", CurrentSessionDate());
        QueryResult = Query.Execute().Unload();
        RemainingDays = QueryResult[0].DateDiff;
       
        If RemainingDays <= 0 AND Constants.SubStatus.Get() = "" Then
                RemainingDays = 0;
                Items.TimeLeftLabel.Title = "Your trial has expired.";
        Elsif Constants.SubStatus.Get() = "" Then        
                  Items.TimeLeftLabel.Title = "You have " + RemainingDays + " days left in your trial.";
        EndIf;

	
EndProcedure

&AtClient
Procedure SubscribeButton(Command)
	
	FreeTrialVersion = SubscribeVersion();
	
	If FreeTrialVersion = 0 Then
		GoToURL("https://pay.accountingsuite.com/monthly?token=yDU8qbKeihtBvjpri9O1&state=" + TenantV());
	Elsif FreeTrialVersion = 1 Then
		GoToURL("https://pay.accountingsuite.com/monthly?token=j9S512cxZHXMU6j4RhX7&state=" + TenantV());
	Elsif FreeTrialVersion = 2 Then
		GoToURL("https://pay.accountingsuite.com/monthly?token=jQswFppCrhgGMw8Avoz4&state=" + TenantV());
	EndIf;

EndProcedure

&AtServer
Function SubscribeVersion()
	   Return Constants.VersionNumber.Get();
EndFunction





