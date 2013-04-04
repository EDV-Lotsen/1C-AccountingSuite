

// Open new message edit form.
// Parameters
// Sender  			- ValueList, CatalogRef.EmailAccounts -
//                		 account(s) (list) used to send email
//                		 message. If type is value list, then
//                  	 presentation 	- account description,
//                   Value 				- account ref
//
// Recipient      	- ValueList, String:
//                   	if value list, then presentation 	 - recipient name
//                                            value      	 - email address
//                   		if string then list of email addresses,
//                   		in the format of proper e-mail address*
//
// Subject          - String 	- message subject
// Text           	- String 	- message body
//
// FileList    		- ValueList, where
//                   presentation 	- string 		- attachment description
//                   value      	- BinaryData 	- attachment binary data
//                                 	- String 		- file address in temporary storage
//                                 	- String 		- path to a file at client
//
// DeleteFilesAfterSending - boolean - delete temporary files after sending the message
//
Procedure OpenEmailMessageSendForm(Val Sender = Undefined,
                                   Recipient 			   = Undefined,
                                   Subject 				   = "",
                                   Text 				   = "",
                                   FileList 			   = Undefined,
                                   DeleteFilesAfterSending = False) Export
	
	MessageParameters = New Structure;
	
	MessageParameters.Insert("UserAccount", 			Sender);
	MessageParameters.Insert("Recipient", 				Recipient);
	MessageParameters.Insert("Subject", 				Subject);
	MessageParameters.Insert("Body", 				    Text);
	MessageParameters.Insert("Attachments", 		    FileList);
	MessageParameters.Insert("DeleteFilesAfterSending", DeleteFilesAfterSending);
	
	OpenForm("CommonForm.NewEmailEditing", MessageParameters);
	
EndProcedure
