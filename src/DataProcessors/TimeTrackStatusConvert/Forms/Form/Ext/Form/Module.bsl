
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Query = New Query;
	Query.Text = "SELECT
	             |	TimeTrack.InvoiceSent,
	             |	TimeTrack.Ref
	             |FROM
	             |	Document.TimeTrack AS TimeTrack";
	Selection = Query.Execute().Unload();
	For Each TimeTrackEntry In Selection Do
		TimeEntry = TimeTrackEntry.Ref.GetObject();
		
		If TimeTrackEntry.InvoiceSent = "Unbilled" Then
			TimeEntry.InvoiceStatus = Enums.TimeTrackStatus.Unbilled;
			TimeEntry.Write(DocumentWriteMode.Posting)
		Elsif TimeTrackEntry.InvoiceSent = "Unbillable" Then
			TimeEntry.InvoiceStatus = Enums.TimeTrackStatus.Unbillable;
			TimeEntry.Write(DocumentWriteMode.Posting);
		Elsif TimeTrackEntry.InvoiceSent = "Billed" Then
			TimeEntry.InvoiceStatus = Enums.TimeTrackStatus.Billed;
			TimeEntry.Write(DocumentWriteMode.Posting);
		Endif;
	EndDo;
	
EndProcedure
