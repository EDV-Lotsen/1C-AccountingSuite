
////////////////////////////////////////////////////////////////////////////////
// Internet connection: Client & Server
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application))
// - Server
// - External Connection
//

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

//------------------------------------------------------------------------------
// Establish and execute internet connection

#If Not WebClient Then
// HTTP connection & FTP connection objects are unavailable on the web-client

// Creates new internet (http, https, ftp, ftps) connection object.
//
// Parameters:
//  URL                      - String - file URL in the canonical format:
//   <schema>://<login>:<password>@<host>:<port>/<path>?<parameters>#<anchor>
//
//  ConnectionSettings       - Structure - describing connection settings, overrides
//                             URL settings - structure with the following fields:
//   Schema                  - String - type of protocol to be used.
//                             Supported protocols (schemas): http, https, ftp, ftps.
//                             or - Undefined, then default protocol http will be used.
//   Login                   - String - login on behalf of which the connection is
//                             established.
//                             or - Undefined, then anonimous connection will be used.
//   Password                - String - password of the user on behalf of which the
//                             connection is established.
//                             or - Undefined, then authorization (if login specified)
//                             will proceed using empty password.
//   Host                    - String - requested host name or IPv4 or IPv6 address.
//   Port                    - Number or String - port that is used for establishing
//                             the connection.
//                             or - Undefined, then default port for desired protocol
//                             will be used: http: 80, https: 443, ftp: 21, ftps: 990.
//   Path                    - String - path to the requested resource.
//                             or - Undefined if connection to root of specified host
//                             established.
//   Parameters              - String - string with defined pairs of request parameters.
//                             or - Undefined if no additional parameters specified.
//   ParametersDecoded       - ValueList - pairs of additional parameters in object style.
//                             or - Undefined if no additional parameters specified.
//   Anchor                  - String - position the document to selected text tag.
//                             or - Undefined if no anchor specified.
//   Timeout                 - Number - timeout for connection and operations
//                             in seconds.
//                             or - Undefined if no timeout specified, then internet
//                             connection will wait until connection will be closed
//                             or system socket connection timeout arrives.
//   Passive                 - Boolean - flag that shows whether the ftp connection
//                             will disable dual data exchange - data and commands
//                             separately using additional internet port (usually 22).
//                             or - Undefined, then passive connection will not be used.
//
//  SecureConnection         - OpenSSLSecureConnection - object filled
//                             acording to the standard rules.
//                             or:
//                           - NSSSecureConnection - object filled
//                             acording to the standard rules.
//                             or:
//                           - Undefined - to create unsecure connection.
//                             or:
//                           - Boolean - True to create OpenSSL connection
//                                       without specifying used certificates.
//                                     - False to create unsecure connection.
//                             or:
//                           - Structure - structure with the following fields:
//   Type                    - String - "OpenSSL" or "NSS" type of connection.
//   ClientCertificate       - OpenSSL:
//                             - FileClientCertificate object.
//                              or:
//                             - WindowsCertificateSelectMode object.
//                              or:
//                             - Undefined - do not use client certificate.
//                              or:
//                             - Empty string to use an OpenSSL client certificate,
//                               loaded from MS Windows system certificate store.
//                               The certificate is selected automatically.
//                              or:
//                             - String - Single-line string:
//                               Definition of file-based certificate in format:
//                                <file_name>:<password>
//                              or:
//                             - String - Multi-line string:
//                               Certificate contents in text format
//                             NSS:
//                            - String - Name of NSS storage client certificate
//                              being used. If not specified or an empty string,
//                              is set then the client certificate is selected
//                              automatically.
//   CertificationAuthorityCertificate
//                           - OpenSSL:
//                             - FileCertificationAuthorityCertificates object.
//                              or:
//                             - WindowsCertificationAuthorityCertificates object.
//                              or:
//                             - Undefined - do not use certification authorities
//                               certificate.
//                              or:
//                             - Empty string to use an OpenSSL authority centers 
//                               certificates, loaded from MS Windows operation
//                               system certificates store.
//                               The certificate is selected automatically.
//                              or:
//                             - String - Single-line string:
//                               Definition of file-based certificate in format:
//                                <file_name>:<password>
//                              or:
//                             - String - Multi-line string:
//                               Certificate contents in text format
//                           - NSS:
//                            - Boolean - Specifies the necessity to verify
//                              the server certificate using certificates of authority
//                              servers from the specified NSS certificate storage.
//   UserProfileDirectory    - NSS: String - User profile directory of NSS certificates
//                              storage.
//   UserPassword            - NSS: String - Password for NSS certificates storage.
//
//  ProxySettings            - InternetProxy - object filled acording to the standard
//                              rules.
//                             or:
//                           - Structure - structure with the following fields:
//   UseProxy                 - Boolean flag that shows whether the proxy server
//                              is used.
//   UseSystemSettings        - Boolean flag that shows whether system proxy server
//                              settings are used.
//   Host                     - String - proxy server address.
//   Port                     - String - proxy server port.
//   Login                    - String - name of the user for authorization
//                              at the proxy server.
//   Password                 - String - password of the user for authorization
//                              at the proxy server.
//   BypassProxyOnLocal       - Boolean flag that shows whether the proxy server
//                              is bypassed for the local addresses.
//   BypassProxyOnAddresses   - String - list of addresses, delimeted by (;)
//                              or - Array of strings of addresses -
//                              whose connections must be done without a proxy.
//                             or:
//                           - Undefined - for use standard system settings.
//
//  ExternalHandler          - CommonModule - object for override connection creation.
//                             If client connection creation will be supported,
//                             then common module should set Client Call flag.
//                             The module must implement CreateConnection method:
//                             CreateConnection(InternetConnectionType,
//                                              ConnectionSettingsArray).
//  ExternalParameters       - Structure - parameters for external handler.
//
// Returns:
//  Structure - with the following key and value:
//   Result                  - HTTPConnection or FTPConnection object if succeeded,
//                             or Undefined if failed.
//   Description             - String - contain an error message in case of failure.
//
//  ConnectionSettings       - Structure - describing connection settings, contains
//                             decoded URL settings - structure with the following
//                             fields:
//   Schema                  - String - type of used protocol.
//                             Supported protocols (schemas): http, https, ftp, ftps.
//   Login                   - String - login on behalf of which the connection is
//                             established.
//                             or - Undefined, then anonimous connection will be used.
//   Password                - String - password of the user on behalf of which the
//                             connection is established.
//                             or - Undefined, then authorization (if login specified)
//                             will proceed using empty password.
//   Host                    - String - requested host name or IPv4 or IPv6 address.
//   Port                    - Number - port that is used for establishing connection.
//                             or - Undefined, then default port for desired protocol
//                             will be used: http: 80, https: 443, ftp: 21, ftps: 990.
//   Path                    - String - path to the requested resource.
//   Parameters              - String - string with defined pairs of request parameters.
//                             or - Undefined if no additional parameters specified.
//   ParametersDecoded       - ValueList - pairs of additional parameters in object style.
//                             or - Undefined if no additional parameters specified.
//   Anchor                  - String - position the document to selected text tag.
//                             or - Undefined if no anchor specified.
//   Timeout                 - Number - timeout for connection and operations
//                             in seconds.
//                             or - Undefined if no timeout specified.
//   Passive                 - Boolean - flag that shows whether the ftp connection
//                             will disable dual data exchange.
//
Function CreateConnection(Val URL, ConnectionSettings = Undefined,
	SecureConnection = Undefined, ProxySettings = Undefined,
	ExternalHandler = Undefined, ExternalParameters = Undefined) Export
	
	//--------------------------------------------------------------------------
	// 1. Read and check connection parameters.
	
	// Declaration of connection settings.
	ConnectionData = New Structure("Schema, Login, Password, Host, Port,
	                               |Path, Parameters, ParametersDecoded,
	                               |Anchor, Timeout, Passive");
	
	// Apply connection settings, defined in passed URL, to ConnectionData.
	FillPropertyValues(ConnectionData, URLToStructure(URL));
	
	// Apply (and override) URL settings with connection settings,
	// passed in ConnectionSettings structure.
	If ConnectionSettings <> Undefined Then
		FillPropertyValues(ConnectionData, ConnectionSettings);
	EndIf;
	
	// Check schema and define type of usable internet connection object
	// and secure connection flag.
	Schema = Lower(ConnectionData.Schema);
	If IsBlankString(Schema) Then
		// By default empty schema is omitted "http://" request.
		InternetConnectionType = Type("HTTPConnection");
		IsSecureConnection = False;
		
	ElsIf (Schema = "http") Or (Schema = "https") Then
		InternetConnectionType = Type("HTTPConnection");
		IsSecureConnection = (Schema = "https");
		
	ElsIf (Schema = "ftps") Or (Schema = "ftp") Then
		InternetConnectionType = Type("FTPConnection");
		IsSecureConnection = (Schema = "ftps");
		
	Else
		Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
		                                    NStr("en = 'Passed %1 schema can not be used for creation of internet connection.'"),
		                                    Schema));
	EndIf;
	
	// Define and check the hostname.
	Host = Lower(ConnectionData.Host);
	If IsBlankString(Host) Then
		
		// Unknown host to which connection must be established
		Return ResultDescription(Undefined, NStr("en = 'Unknown host name specified.'"));
		
	EndIf;
	
	// Define connection port.
	Port = ?(ValueIsFilled(ConnectionData.Port), ConnectionData.Port, Undefined);
	If Port <> Undefined Then
		
		// Convert port to numeric representation.
		If TypeOf(Port) <> Type("Number") Then
			Try
				Port = Number(Port);
			Except
				Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
				                                    NStr("en = 'Wrong port number %1 specified.'"),
				                                    Port));
			EndTry;
		EndIf;
		
		// Check port range.
		If (Port < 0) Or (Port > 65535) Then // $0000 - $FFFF
			Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
			                                    NStr("en = 'Wrong port number %1 specified.
			                                         |The port number must be interger value in range 0 - 65535.'"),
			                                    Format(Port, "NZ=0; NG=")));
		EndIf;
	EndIf;
	
	// Define connection server authorization.
	IsAuthorizationUsed = ValueIsFilled(ConnectionData.Login);
	If IsAuthorizationUsed Then
		Login =    String(ConnectionData.Login);
		Password = ?(ValueIsFilled(ConnectionData.Password), String(ConnectionData.Password), Undefined);
	Else
		Login =    Undefined;
		Password = Undefined;
	EndIf;
	
	// Define connection timeout.
	Timeout = ?(ValueIsFilled(ConnectionData.Timeout), ConnectionData.Timeout, Undefined);
	If Timeout <> Undefined Then
		
		// Convert port to numeric representation.
		If TypeOf(Timeout) <> Type("Number") Then
			Try
				Timeout = Number(Timeout);
			Except
				// Set default timeout
				Timeout = 0;
			EndTry;
		EndIf;
		
		// Check timout value range.
		If Timeout < 0 Then
			Timeout = 0;
		ElsIf Timeout > 900 Then // More than 15 minutes.
			Timeout = 900;
		EndIf;
	EndIf;	
	
	// Define passive connection for ftp(s) servers.
	If (Schema = "ftps") Or (Schema = "ftp") Then
		Passive = ValueIsFilled(ConnectionData.Passive) And (ConnectionData.Passive);
	Else
		Passive = Undefined;
	EndIf;
	
	//--------------------------------------------------------------------------
	// 2. Read and check proxy server settings.
	
	// Define proxy server for the connection.
	If TypeOf(ProxySettings) = Type("InternetProxy") Then
		
		// Use passed object direct in internet connection.
		Proxy = ProxySettings;
		
	ElsIf TypeOf(ProxySettings) = Type("Structure") Then
		
		// Declaration of proxy server settings.
		ProxyData = New Structure("UseProxy, UseSystemSettings,
		                          |Host, Port, Login, Password,
		                          |BypassProxyOnLocal, BypassProxyOnAddresses");
		
		// Apply passed proxy server settings.
		FillPropertyValues(ProxyData, ProxySettings);
		
		// Create proxy object basing on passed parameters.
		If ValueIsFilled(ProxyData.UseProxy) And (ProxyData.UseProxy) Then
			
			// Check using system settings.
			If  ValueIsFilled(ProxyData.UseSystemSettings) And (ProxyData.UseSystemSettings) Then
				
				// Use system settings (see comment below).
				Proxy = New InternetProxy(True);
				
			Else
				
				// Fill proxy properties by the supplied values
				Proxy = New InternetProxy(False);
				
				// Define proxy server connection.
				ProxyHost = TrimAll(ProxyData.Host);
				If Not IsBlankString(ProxyHost) Then
					
					// Define proxy port.
					ProxyPort = ?(ValueIsFilled(ProxyData.Port), ProxyData.Port, Undefined);
					If ProxyPort <> Undefined Then
						
						// Convert port to numeric representation.
						If TypeOf(ProxyPort) <> Type("Number") Then
							Try
								ProxyPort = Number(ProxyPort);
							Except
								Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
								                                    NStr("en = 'Wrong port number %1 for proxy server specified.'"),
								                                    ProxyPort));
							EndTry;
						EndIf;
						
						// Check port range.
						If (ProxyPort < 0) Or (ProxyPort > 65535) Then // $0000 - $FFFF
							Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
							                                    NStr("en = 'Wrong port number %1 for proxy server specified.
							                                         |The port number must be interger value in range 0 - 65535.'"),
							                                    Format(ProxyPort, "NZ=0; NG=")));
						EndIf;
					EndIf;
					
					// Assign proxy server parameters for desired protocol.
					Proxy.Set(Schema, ProxyHost, ProxyPort);
					
					// Define proxy server authorization.
					IsAuthorizationUsed = ValueIsFilled(ProxyData.Login);
					If IsAuthorizationUsed Then
						Proxy.User =     String(ProxyData.Login);
						Proxy.Password = ?(ValueIsFilled(ProxyData.Password), String(ProxyData.Password), Undefined);
					EndIf;
					
					// Check bypass on local addresses.
					Proxy.BypassProxyOnLocal = ValueIsFilled(ProxyData.BypassProxyOnLocal) And (ProxyData.BypassProxyOnLocal);
					
					// Check bypass local addresses.
					If TypeOf(ProxyData.BypassProxyOnAddresses) = Type("String") And Not IsBlankString(ProxyData.BypassProxyOnAddresses) Then
						
						// Define bypass addresses array.
						BypassProxyOnAddresses = ProxyData.BypassProxyOnAddresses;
						
						// Go thru bypass string and get the bypass addresses.
						While StrLen(BypassProxyOnAddresses) > 0 Do
							
							// Get bypass address from the string.
							Position = Find(BypassProxyOnAddresses, ";");
							If Position > 0 Then
								// Current bypass address.
								BypassAddress          = Left(BypassProxyOnAddresses, Position - 1);
								BypassProxyOnAddresses  = Mid(BypassProxyOnAddresses, Position + 1);
							Else
								// Last bypass address.
								BypassAddress           = BypassProxyOnAddresses;
								BypassProxyOnAddresses  = "";
							EndIf;
							
							// Assign bypass address to an array.
							Proxy.BypassProxyOnAddresses.Add(Lower(BypassAddress));
						EndDo;
						
					ElsIf TypeOf(ProxyData.BypassProxyOnAddresses) = Type("Array") Then
						
						// Check and reassign the array items
						For i = 0 To ProxyData.BypassProxyOnAddresses.Count() - 1 Do
							If ValueIsFilled(ProxyData.BypassProxyOnAddresses[i]) Then
								Proxy.BypassProxyOnAddresses.Add(Lower(TrimAll(ProxyData.BypassProxyOnAddresses[i])));
							EndIf;
						EndDo;
					EndIf;
					
				Else
					// Proxy server is not specified, direct connection will be established.
				EndIf;
			EndIf;
			
		Else
			
			// Do not use proxy or UseProxy is not defined
			Proxy = New InternetProxy(False);
			
		EndIf;
			
	Else
		// Use system settings by the following way:
		// 1. Search for file in platform subcatalog: "\1cv8\<Version>\bin\conf\inetcfg.xml".
		// 2. If not found, then search for inetcfg.xml in path,
		//    defined in file in platform subcatalog: "\1cv8\<Version>\bin\conf\conf.cfg".
		// 3. If file inetcfg.xml is not found, then in Windows default browser settings
		//    will be used, and in Linux no proxy will be used.
		Proxy = New InternetProxy(True);
	EndIf;
	
	//--------------------------------------------------------------------------
	// 2. Read and check secure connection settings.
	
	// Security settings for the connection.
	If TypeOf(SecureConnection) = Type("OpenSSLSecureConnection") Then
		
		// Use passed object direct in internet connection.
		Security = SecureConnection;
		
	ElsIf TypeOf(SecureConnection) = Type("NSSSecureConnection") Then
		
		// Use passed object direct in internet connection.
		Security = SecureConnection;
		
	ElsIf TypeOf(SecureConnection) = Type("Structure") Then
		
		// Declaration of proxy server settings.
		SecurityData = New Structure("Type, 
		                             |ClientCertificate, CertificationAuthorityCertificate,
		                             |UserProfileDirectory, UserPassword");
		
		// Apply passed secure connection settings.
		FillPropertyValues(SecurityData, SecureConnection);
		
		// Define secure connection type.
		SecurityType = TrimAll(SecurityData.Type);
		If IsBlankString(SecurityType) Then
			
			// Empty connection type.
			// Use simple SSL connection without checking client and server certificates.
			Security = New OpenSSLSecureConnection();
			
		ElsIf SecurityType = "OpenSSL" Then
			
			// Define client certificate.
			OpenSSLClientCertificate = Undefined;
			If TypeOf(SecurityData.ClientCertificate) = Type("FileClientCertificate") Then
				
				// Use passed file client certificate
				OpenSSLClientCertificate = SecurityData.ClientCertificate;
				
			ElsIf TypeOf(SecurityData.ClientCertificate) = Type("WindowsClientCertificate") Then
				
				// Use passed windows client certificate
				OpenSSLClientCertificate = SecurityData.ClientCertificate;
				
			ElsIf SecurityData.ClientCertificate = Undefined Then
				
				// Do not use client certificate
				OpenSSLClientCertificate = Undefined;
				
			ElsIf IsBlankString(SecurityData.ClientCertificate) Then
				
				// Create an OpenSSL client certificate,
				// loaded from MS Windows system certificate store.
				// The certificate is selected automatically.
				OpenSSLClientCertificate = New WindowsClientCertificate();
				
			ElsIf Find(SecurityData.ClientCertificate, Chars.LF) = 0 Then
				
				// Treat certificate as file certificate
				FileName = TrimAll(SecurityData.ClientCertificate);
				FilePass = Undefined;
				Position = Find(FileName, ":");
				If Position > 0 Then
					FilePass = Mid(FileName, Position + 1);
					FileName = Left(FileName, Position - 1);
				EndIf;
				
				// Load certificate data from file.
				Try
					OpenSSLClientCertificate = New FileClientCertificate(FileName, FilePass);
				Except
					// Get exception cause.
					ErrorInfo = ErrorInfo();
					While TypeOf(ErrorInfo.Cause) = Type("ErrorInfo") Do
						ErrorInfo = ErrorInfo.Cause;
					EndDo;
					
					// Failed to create file client certificate.
					Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
					                                    NStr("en = 'Error creating client certificate for secure connection:
					                                         |%1'"),
					                                    ErrorInfo.Description));
					
				EndTry;
				
			Else // Multiline certificate
				
				// Temporary save certificate file
				FileName = GetTempFileName(".crt");
				
				// Treat certificate as text certificate
				FileContents = New TextDocument;
				FileContents.SetText(TrimAll(SecurityData.ClientCertificate));
				FileContents.Write(FileName, TextEncoding.UTF8, Chars.LF);
				
				// Load certificate data from file.
				Try
					OpenSSLClientCertificate = New FileClientCertificate(FileName);
				Except
					// Get exception cause.
					ErrorInfo = ErrorInfo();
					While TypeOf(ErrorInfo.Cause) = Type("ErrorInfo") Do
						ErrorInfo = ErrorInfo.Cause;
					EndDo;
					
					// Delete used temporary file
					SafeDeleteFile(FileName);
					
					// Failed to create file client certificate.
					Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
					                                    NStr("en = 'Error creating client certificate for secure connection:
					                                         |%1'"),
					                                    ErrorInfo.Description));
				EndTry;
				
				// Delete used temporary file
				SafeDeleteFile(FileName);
			EndIf;
			
			// Define certification authority certificate.
			OpenSSLCertificationAuthorityCertificate = Undefined;
			If TypeOf(SecurityData.CertificationAuthorityCertificate) = Type("FileCertificationAuthorityCertificates") Then
				
				// Use passed file certification authority certificate
				OpenSSLCertificationAuthorityCertificate = SecurityData.CertificationAuthorityCertificate;
				
			ElsIf TypeOf(SecurityData.CertificationAuthorityCertificate) = Type("WindowsCertificationAuthorityCertificates") Then
				
				// Use passed windows certification authority certificate
				OpenSSLCertificationAuthorityCertificate = SecurityData.CertificationAuthorityCertificate;
				
			ElsIf SecurityData.CertificationAuthorityCertificate = Undefined Then
				
				// Do not use certification authority certificate
				OpenSSLCertificationAuthorityCertificate = Undefined;
				
			ElsIf IsBlankString(SecurityData.CertificationAuthorityCertificate) Then
				
				// Create an OpenSSL certification authority certificate,
				// loaded from MS Windows system certificate store.
				// The certificate is selected automatically.
				OpenSSLCertificationAuthorityCertificate = New WindowsCertificationAuthorityCertificates;
				
			ElsIf Find(SecurityData.CertificationAuthorityCertificate, Chars.LF) = 0 Then
				
				// Treat certificate as file certificate
				FileName = TrimAll(SecurityData.CertificationAuthorityCertificate);
				FilePass = Undefined;
				Position = Find(FileName, ":");
				If Position > 0 Then
					FilePass = Mid(FileName, Position + 1);
					FileName = Left(FileName, Position - 1);
				EndIf;
				
				// Load certificate data from file.
				Try
					OpenSSLCertificationAuthorityCertificate = New FileCertificationAuthorityCertificates(FileName, FilePass);
				Except
					// Get exception cause.
					ErrorInfo = ErrorInfo();
					While TypeOf(ErrorInfo.Cause) = Type("ErrorInfo") Do
						ErrorInfo = ErrorInfo.Cause;
					EndDo;
					
					// Failed to create file client certificate.
					Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
					                                    NStr("en = 'Error creating certification authority certificate for secure connection:
					                                         |%1'"),
					                                    ErrorInfo.Description));
					
				EndTry;
				
			Else // Multiline certificate
				
				// Temporary save certificate file
				FileName = GetTempFileName(".crt");
				
				// Treat certificate as text certificate
				FileContents = New TextDocument;
				FileContents.SetText(TrimAll(SecurityData.CertificationAuthorityCertificate));
				FileContents.Write(FileName, TextEncoding.UTF8, Chars.LF);
				
				// Load certificate data from file.
				Try
					OpenSSLCertificationAuthorityCertificate = New FileCertificationAuthorityCertificates(FileName);
				Except
					// Get exception cause.
					ErrorInfo = ErrorInfo();
					While TypeOf(ErrorInfo.Cause) = Type("ErrorInfo") Do
						ErrorInfo = ErrorInfo.Cause;
					EndDo;
					
					// Delete used temporary file
					SafeDeleteFile(FileName);
					
					// Failed to create file client certificate.
					Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
					                                    NStr("en = 'Error creating certification authority certificate for secure connection:
					                                         |%1'"),
					                                    ErrorInfo.Description));
				EndTry;
				
				// Delete used temporary file
				SafeDeleteFile(FileName);
			EndIf;
			
			// Use SSL connection with checking client and/or server certificates.
			Security = New OpenSSLSecureConnection(OpenSSLClientCertificate,
			                                       OpenSSLCertificationAuthorityCertificate);
			
		ElsIf SecurityType = "NSS" Then
			
			// Request user profile for NSS connection.
			NSSUserProfileDirectory = TrimAll(SecurityData.UserProfileDirectory);
			If Not IsBlankString(NSSUserProfileDirectory) Then
				
				// Define password for user profile data.
				NSSUserPassword = TrimAll(SecurityData.UserPassword);
				
				// Define client certificate.
				NSSClientCertificate = TrimAll(SecurityData.ClientCertificate);
			
				// Define certification authority certificate.
				NSSCertificationAuthorityCertificate = ValueIsFilled(SecurityData.CertificationAuthorityCertificate)
				                                       And SecurityData.CertificationAuthorityCertificate;
				
				// Create NSS security connection.
				Try
					Security = New NSSSecureConnection(NSSUserProfileDirectory,
					                                   NSSUserPassword,
					                                   NSSCertificationAuthorityCertificate,
					                                   NSSClientCertificate);
				Except
					// Get exception cause.
					ErrorInfo = ErrorInfo();
					While TypeOf(ErrorInfo.Cause) = Type("ErrorInfo") Do
						ErrorInfo = ErrorInfo.Cause;
					EndDo;
					
					// Failed to create NSS Secure connection.
					Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
					                                    NStr("en = 'Error creating NSS secure connection:
					                                         |%1'"),
					                                    ErrorInfo.Description));
				EndTry;
				
			Else
				// User profile for NSS connection is not specified.
				Return ResultDescription(Undefined, NStr("en = 'Error creating NSS secure connection:
				                                         |User profile directory of NSS certificates storage is not specified.'"));
			EndIf;
			
		Else
			// Unknown type of security connection.
			// Use non-secured http/ftp connection.
			Security = Undefined;
		EndIf;
		
	ElsIf (IsSecureConnection) Or (TypeOf(SecureConnection) = Type("Boolean") And (SecureConnection)) Then
		
		// Use simple SSL connection without checking client and server certificates.
		Security = New OpenSSLSecureConnection();
		
	Else
		// Use non-secured http/ftp connection.
		Security = Undefined;
	EndIf;
	
	// Redefine IsSecureConnection flag, basing on Security data.
	IsSecureConnection = IsSecureConnection Or (Security <> Undefined);
	
	//--------------------------------------------------------------------------
	// 4. Fill and create internet connection object.
	
	// Add connection object initialization parameters
	ConnectionSettingsArray = New Array;
	ConnectionSettingsArray.Add(Host);
	ConnectionSettingsArray.Add(Port);
	ConnectionSettingsArray.Add(Login);
	ConnectionSettingsArray.Add(Password);
	ConnectionSettingsArray.Add(Proxy);
	If InternetConnectionType = Type("FTPConnection") Then
		ConnectionSettingsArray.Add(Passive);
	EndIf;
	ConnectionSettingsArray.Add(Timeout);
	ConnectionSettingsArray.Add(Security);
	
	Try
		If ExternalHandler <> Undefined Then
			Connection = ExternalHandler.CreateConnection(InternetConnectionType, ConnectionSettingsArray, ExternalParameters);
		Else
			Connection = New(InternetConnectionType, ConnectionSettingsArray);
		EndIf;
	Except
		// Get exception cause.
		ErrorInfo = ErrorInfo();
		While TypeOf(ErrorInfo.Cause) = Type("ErrorInfo") Do
			ErrorInfo = ErrorInfo.Cause;
		EndDo;
		
		// Failed to create server connection.
		Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
		                                    NStr("en = 'Error creating %1%2 connection with host %3:
		                                         |%4'"),
		                                    Schema, ?(IsSecureConnection, NStr("en = ' secure'"), ""),
		                                    Host + ?(ValueIsFilled(Port), ":" + Format(Port, "NZ=0; NG="), ""),
		                                    ErrorInfo.Description));
	EndTry;
	
	// Return back actual used connection settings
	ConnectionSettings = New Structure("Schema, Login, Password, Host, Port,
	                                   |Path, Parameters, ParametersDecoded,
	                                   |Anchor, Timeout, Passive",
	                                   Schema,
	                                   Login,
	                                   Password,
	                                   Host,
	                                   Port,
	                                   ?(TypeOf(ConnectionData.Path) = Type("String"), TrimAll(ConnectionData.Path), Undefined),
	                                   ?(TypeOf(ConnectionData.Parameters) = Type("String"), TrimAll(ConnectionData.Parameters), Undefined),
	                                   ?(TypeOf(ConnectionData.ParametersDecoded) = Type("ValueList"), ConnectionData.ParametersDecoded, Undefined),
	                                   ?(TypeOf(ConnectionData.Anchor) = Type("String"), TrimAll(ConnectionData.Anchor), Undefined),
	                                   Timeout,
	                                   Passive);
	
	// Return created connection and it's parameters
	Return ResultDescription(Connection);
	
EndFunction

// Opens existing internet connection and performs request by specified method.
//
// Parameters:
//  Connection               - HTTPConnection, FTPConnection - object to perform
//                             internet request operation.
//
//  Method                   - String - request method to the internet resource.
//                             Available methods for http and https protocols:
//                              Get, Post, Put, Delete
//                             Available methods for ftp and ftps protocol:
//                              Get, Put, Delete, Move,
//                              GetCurrentDirectory, SetCurrentDirectory,
//                              CreateDirectory, FindFiles.
//
//  ConnectionSettings       - Structure - describing connection settings, contains
//                             decoded URL settings - structure with the following
//                             fields:
//   Schema                  - String - type of used protocol.
//                             Supported protocols (schemas): http, https, ftp, ftps.
//   Login                   - String - login on behalf of which the connection is
//                             established.
//                             or - Undefined, then anonimous connection will be used.
//   Password                - String - password of the user on behalf of which the
//                             connection is established.
//                             or - Undefined, then authorization (if login specified)
//                             will proceed using empty password.
//   Host                    - String - requested host name or IPv4 or IPv6 address.
//   Port                    - Number - port that is used for establishing connection.
//                             or - Undefined, then default port for desired protocol
//                             will be used: http: 80, https: 443, ftp: 21, ftps: 990.
//   Path                    - String - path to the requested resource.
//   Parameters              - String - string with defined pairs of request parameters.
//                             or - Undefined if no additional parameters specified.
//   ParametersDecoded       - ValueList - pairs of additional parameters in object style.
//                             or - Undefined if no additional parameters specified.
//   Anchor                  - String - position the document to selected text tag.
//                             or - Undefined if no anchor specified.
//   Timeout                 - Number - timeout for connection and operations
//                             in seconds.
//                             or - Undefined if no timeout specified.
//   Passive                 - Boolean - flag that shows whether the ftp connection
//                             will disable dual data exchange.
//
//  Headers                  - Map - map with defined pairs of request headers.
//                             or - String of pairs of keys and their values
//                             in following format: <Key>: <Value> delimited by CR + LF.
//
//  InputData                - HTTPRequest - pass request directly (for HTTPConnection only).
//                           - String      - pass string directly.
//                           - Structure   - contains parameters for loading
//                             the upload data.
//   Storage                 - String - can take on the following values:
//                              "Request" - use HTTPRequest object directly.
//                              "File"    - load data from the file.
//                              "Storage" - load data from the temporary storage.
//                                          The data can be saved in binary or string type.
//                              "Binary"  - pass data directly as binary in parameters.
//                              "Base64"  - pass data directly as base64-encoded string in parameters.
//                              "String"  - pass data directly as string in parameters.
//   Path                    - String - path to a directory at client or at server,
//                              or an address in the temporary storage,
//                              or contents of data to be sent.
//                             or String containing the upload data.
//                             or Binary containing the upload data.
//                             or HTTPRequest - object containing source data to perform
//                             internet request operation (for HTTPConnection object only).
//
//  OutputData               - Structure - containing parameters for saving
//                             the downloaded data.
//   Storage                 - String - can take on the following values:
//                              "Response" - return HTTPResponse object directly (for HTTPConnection only).
//                              "File"     - save data in the file.
//                              "Storage"  - save data in the temporary storage.
//                              "Binary"   - return data directly as binary in parameters.
//                              "Base64"   - return data directly as base64-encoded string in parameters.
//                              "String"   - return data directly as string in parameters.
//   Path                    - String - path to a directory at client or at server,
//                              or an address in the temporary storage,
//                              or contents of requested data.
//                             If it is not specified, the String output will be generated.
//
//  ExternalHandler          - CommonModule - object for override connection creation.
//                             If client connection creation will be supported,
//                             then common module should set Client Call flag.
//                             The module must implement connection execution method:
//                             HTTPSendRequest(Connection, Method, Request)
//                             and/or FTPSendRequest(Connection, Method,
//                             PathToResource, SourceFile = "", OutputFile = "").
//  ExternalParameters       - Structure - parameters for external handler.
//
// Returns:
//  Structure - with the following key and value:
//   Result                  - String - path to a directory at client or at server,
//                                      or an address in the temporary storage,
//                                      or contents of requested data.
//                           - HTTPResponse - object containing requested data
//                             (for HTTPConnection object only).
//                           - Undefined - if request failed.
//   Description             - String - if succeded can take on the following values:
//                              "File" - data saved in the specified file.
//                              "Storage" - data saved to the temporary storage.
//                              "String" - data returned directly in Result parameter.
//                             or contain an error message in case of failure.
//
Function SendRequest(Connection, Method, ConnectionSettings = Undefined,
	HeadersData = Undefined, InputData = Undefined, OutputData = Undefined,
	ExternalHandler = Undefined, ExternalParameters = Undefined) Export
	
	//--------------------------------------------------------------------------
	// 1. Check passed connection data.
	
	// Security settings for the connection.
	If TypeOf(Connection) <> Type("HTTPConnection") And TypeOf(Connection) <> Type("FTPConnection") Then
		
		// Failed to access to server connection.
		Return ResultDescription(Undefined, NStr("en = 'No connection established for requested operation.'"));
		
	ElsIf TypeOf(Connection) = Type("HTTPConnection") Then
		
		// Define available methods for HTTP connection
		Methods = "Get, Put, Post, Delete";
		
	ElsIf TypeOf(Connection) = Type("FTPConnection") Then
		
		// Define available methods for FTP connection
		Methods = "Get, Put, Delete, Move, GetCurrentDirectory, SetCurrentDirectory, CreateDirectory, FindFiles";
		
	EndIf;
	
	// Check used connection method.
	If Find(Upper(", " + Methods + ","), Upper(", " + Method + ",")) = 0 Then
		
		// Unknown method used.
		Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
		                                    NStr("en = 'Unknown method %1 was used for %2 connection.'"),
		                                    Method,
		                                    StrReplace(Connection, "Connection", "")));
	EndIf;
	
	//--------------------------------------------------------------------------
	// 2. Define resource relative path.
	
	// Declaration of connection settings.
	ConnectionData = New Structure("Path, Parameters, ParametersDecoded, Anchor");
	
	// Apply passed connection settings to ConnectionData.
	If TypeOf(ConnectionSettings) = Type("Structure") Then
		FillPropertyValues(ConnectionData, ConnectionSettings);
	EndIf;
	
	// Create path to resource in URL format, defined in ConnectionData structure.
	EncodePercentStr = (TypeOf(Connection) = Type("HTTPConnection"));
	PathToResource = StructureToURL(ConnectionData, EncodePercentStr);
	If TypeOf(Connection) = Type("FTPConnection") And Left(PathToResource, 1) = "/" Then
		PathToResource = Mid(PathToResource, 2);
	EndIf;
	
	//--------------------------------------------------------------------------
	// 3. Check passed headers.
	
	// Define default headers;
	Headers = Undefined;
	
	// Check proper headers format.
	If HeadersData = Undefined Then
		// Headers are not defined.
		
	ElsIf TypeOf(HeadersData) = Type("Map") Then
		// Use headers directly.
		If HeadersData.Count() > 0 Then
			Headers = HeadersData;
		EndIf;
		
	ElsIf TypeOf(HeadersData) = Type("String") Then
		// Read headers in string format.
		If Not IsBlankString(HeadersData) Then
			
			// Assign text pairs to headers map.
			Headers = New Map;
			For i = 1 To StrLineCount(HeadersData) Do
				FailedRows = "";
				Row = TrimAll(StrGetLine(HeadersData, i));
				If StrOccurrenceCount(Row, ":") = 1 Then
					Pos = Find(Row, ":");
					Headers.Insert(Left(Row, Pos - 1), Mid(Row, Pos + 1));
				Else
					FailedRows = ?(IsBlankString(FailedRows), "", Chars.LF) + Row;
				EndIf;
			EndDo;
			
			// Create error description (if any).
			If Not IsBlankString(FailedRows) Then
				// The headers having wrong format.
				Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
				                                    NStr("en = 'HTTP request contains headers in wrong format:
				                                         |%1'"),
				                                    FailedRows));
			EndIf;
		EndIf;
		
	Else
		// Unknown header type.
		Return ResultDescription(Undefined, NStr("en = 'Unknown headers type supplied.'"));
	EndIf;
	
	//--------------------------------------------------------------------------
	// 4. Check source data and pass it to request data.
	
	// Define request data closest to the source data depending on connection type used.
	If TypeOf(Connection) = Type("HTTPConnection") Then
		
		// Create new HTTP request object.
		Request = New HTTPRequest;
		
		//--------------------------------------------------------------------------
		// 4.1.1. Check source data type.
		
		// Define data type to be sent to the resource.
		StorageType = ""; StorageData = Undefined;
		If TypeOf(InputData) = Type("String") Then
			// Storage data defined by the passed string.
			StorageType = "String";
			StorageData = InputData;
			
		ElsIf TypeOf(InputData) = Type("HTTPRequest") Then
			// Storage data defined by the passed request object.
			StorageType = "Request";
			StorageData = InputData;
			
		ElsIf TypeOf(InputData) = Type("Structure") Then
			// Fill snding data by the structure fields.
			InputData.Property("Storage", StorageType);
			InputData.Property("Path",    StorageData);
		EndIf;
		
		//--------------------------------------------------------------------------
		// 4.1.2. Load source data of specified type into request.
		
		// Load request data (if exists).
		If Not IsBlankString(StorageType) Then
			
			// Load data depending on source type.
			If StorageType = "Request" Then
				// Use passed object direct in internet connection.
				Request = StorageData;
				
			ElsIf StorageType = "File" Then
				// Assign source file from passed path.
				If IsBlankString(StorageData) Then
					// File name absent.
					Return ResultDescription(Undefined, NStr("en = 'Source data file is not specified.'"));
				EndIf;
				
				// Check file availability.
				File = New File(StorageData);
				If Not File.Exist() Then
					// File don't exist.
					Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
					                                    NStr("en = 'Source data file ""%1"" don''t exist.'"),
					                                    StorageData));
				ElsIf Not File.IsFile() Then
					// The suggested resource is not a data file.
					Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
					                                    NStr("en = 'Source resource ""%1"" is not a valid data file.'"),
					                                    StorageData));
				EndIf;
				
				// Load file data to the request.
				Request.SetBodyFileName(StorageData);
				
			ElsIf StorageType = "Storage" Then
				// Read data from temporary storage.
				If IsTempStorageURL(StorageData) Then
					// Request source data from temporary storage.
					BinaryData = GetFromTempStorage(StorageData);
					
					// Check data type placed in storage.
					If TypeOf(BinaryData) = Type("BinaryData") Then
						// Load binary data to the request.
						Request.SetBodyFromBinaryData(BinaryData);
						
					Else // Treat passed data as string.
						
						// Load string data to the request.
						Request.SetBodyFromString(StrToUTF8(String(BinaryData)), "ISO-8859-1");
					EndIf;
					
					// Free used resource from temporary storage.
					DeleteFromTempStorage(StorageData);
				Else
					// The suggested address is not a temporary storage location.
					Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
					                                    NStr("en = 'Source resource ""%1"" is not a valid URL.'"),
					                                    StorageData));
				EndIf;
				
			ElsIf StorageType = "Binary" Then
				// Check data type placed in storage.
				If TypeOf(StorageData) = Type("BinaryData") Then
					// Load binary data to the request.
					Request.SetBodyFromBinaryData(StorageData);
				Else
					// The suggested data is not a binary data.
					Return ResultDescription(Undefined, NStr("en = 'Passed data is not a valid binary data.'"));
				EndIf;
				
			ElsIf StorageType = "Base64" Then
				// Load data from passed Base64 string.
				Try
					// Convert passed Base64 string to the BinaryData.
					BinaryData = Base64Value(StorageData);
					
					// Load binary data to the request.
					Request.SetBodyFromBinaryData(BinaryData);
				Except
					// The suggested string is not a valid Base64-encoded string.
					Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
					                                    NStr("en = 'Passed data ""%1"" is not a valid Base64-encoded string.'"),
					                                    StorageData));
				EndTry;
				
			ElsIf StorageType = "String" Then
				// Load string data to the request.
				Request.SetBodyFromString(StrToUTF8(String(StorageData)), "ISO-8859-1");
			EndIf;
		EndIf;
		
		//--------------------------------------------------------------------------
		// 4.1.3. Assign requested resource path and headers.
		
		// Override resource path if is defined.
		If Not IsBlankString(PathToResource) Then
			Request.ResourceAddress = PathToResource;
		EndIf;
		
		// Override headers if are defined.
		If Headers <> Undefined Then
			Request.Headers = Headers;
		EndIf;
		
	ElsIf TypeOf(Connection) = Type("FTPConnection") Then
		
		//--------------------------------------------------------------------------
		// 4.2.1. Check source data type.
		
		// Define data type to be sent to the resource.
		SourceFile = ""; StorageType = ""; StorageData = "";
		If TypeOf(InputData) = Type("String") Then
			// Storage data defined by the passed string.
			StorageType = "String";
			StorageData = InputData;
			
		ElsIf TypeOf(InputData) = Type("Structure") Then
			// Fill sanding data by the structure fields.
			InputData.Property("Storage", StorageType);
			InputData.Property("Path",    StorageData);
		EndIf;
		
		//--------------------------------------------------------------------------
		// 4.2.2. Check source file / Save source data of specified type into temporary file.
		
		// Load request data (if exists).
		If Not IsBlankString(StorageType) Then
			
			// Load data depending on source type.
			If StorageType = "File" Then
				// Assign source file from passed path.
				SourceFile = StorageData;
				If IsBlankString(SourceFile) Then
					// File name absent.
					Return ResultDescription(Undefined, NStr("en = 'Source data file is not specified.'"));
				EndIf;
				
				// Check file availability.
				File = New File(SourceFile);
				If Not File.Exist() Then
					// File don't exist.
					Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
					                                    NStr("en = 'Source data file ""%1"" don''t exist.'"),
					                                    SourceFile));
				ElsIf Not File.IsFile() Then
					// The suggested resource is not a data file.
					Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
					                                    NStr("en = 'Source resource ""%1"" is not a valid data file.'"),
					                                    SourceFile));
				EndIf;
				
			ElsIf StorageType = "Storage" Then
				// Read data from temporary storage and save it to disk.
				If IsTempStorageURL(StorageData) Then
					// Define temporary file for saving source data.
					SourceFile = GetTempFileName();
					
					// Request source data from temporary storage.
					BinaryData = GetFromTempStorage(StorageData);
					
					// Check data type placed in storage.
					If TypeOf(BinaryData) = Type("BinaryData") Then
						// Write binary data to the file.
						BinaryData.Write(SourceFile);
						
					Else // Treat passed data as string.
						
						// Write string data to the file.
						FileContents = New TextDocument;
						FileContents.SetText(String(BinaryData));
						FileContents.Write(SourceFile, "ISO-8859-1", Chars.LF);
					EndIf;
					
					// Free used resource in temporary storage.
					DeleteFromTempStorage(StorageData);
				Else
					// The suggested address is not a temporary storage location.
					Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
					                                    NStr("en = 'Source resource ""%1"" is not a valid URL.'"),
					                                    StorageData));
				EndIf;
				
			ElsIf StorageType = "Binary" Then
				// Check data type placed in storage.
				If TypeOf(StorageData) = Type("BinaryData") Then
					// Define temporary file for saving source data.
					SourceFile = GetTempFileName();
					
					// Write binary data to the file.
					StorageData.Write(SourceFile);
				Else
					// The suggested data is not a binary data.
					Return ResultDescription(Undefined, NStr("en = 'Passed data is not a valid binary data.'"));
				EndIf;
				
			ElsIf StorageType = "Base64" Then
				// Load data from passed Base64 string.
				Try
					// Convert passed Base64 string to the BinaryData.
					BinaryData = Base64Value(StorageData);
					
					// Define temporary file for saving source data.
					SourceFile = GetTempFileName();
					
					// Write binary data to the file.
					BinaryData.Write(SourceFile);
				Except
					// The suggested string is not a valid Base64-encoded string.
					Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
					                                    NStr("en = 'Passed data ""%1"" is not a valid Base64-encoded string.'"),
					                                    SourceFile));
				EndTry;
				
			ElsIf StorageType = "String" Then
				// Check whether source data is properly specified.
				If StorageData = Undefined Then
					// Source data absent.
					Return ResultDescription(Undefined, NStr("en = 'Source data is not specified.'"));
				EndIf;
				
				// Request temporary file for saving source data.
				SourceFile = GetTempFileName();
				
				// Write source data to disk.
				FileContents = New TextDocument;
				FileContents.SetText(String(StorageData));
				FileContents.Write(SourceFile, "ISO-8859-1", Chars.LF);
			EndIf;
		EndIf;
		
		//--------------------------------------------------------------------------
		// 4.2.3. Set flag of deletion for temporary file.
		
		// Define status of used file (temporary or user file).
		SourceFileDeleteUsed = False;
		If (Not IsBlankString(SourceFile)) And (Not StorageType = "File") Then
			// Temporary file used for sending data.
			SourceFileDeleteUsed = True;
		EndIf;
	EndIf;
	
	//--------------------------------------------------------------------------
	// 5. Prepare output data / check output file.
	
	// Define data type to be sent to the resource.
	OutputFile = ""; StorageType = ""; StorageData = "";
	If TypeOf(OutputData) = Type("String") Then
		// Storage data defined by the passed string.
		StorageType = "String";
		StorageData = OutputData;
		
	ElsIf TypeOf(OutputData) = Type("Structure") Then
		// Fill snding data by the structure fields.
		OutputData.Property("Storage", StorageType);
		OutputData.Property("Path",    StorageData);
	EndIf;
	
	// Check passed storage type for resulting data.
	If IsBlankString(StorageType) Then
		// By default return result as text string
		StorageType = "String";
		
	ElsIf Find(?(TypeOf(Connection) = Type("HTTPConnection"),",Response","") + ",File,Storage,Binary,Base64,String,", "," + StorageType + ",") = 0 Then
		
		// The expected type of data is unknown.
		Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
		                                    NStr("en = 'Unable to output resulting data to %1.'"),
		                                    StorageType));
	EndIf;
	
	// Check availability of suggested storage.
	If StorageType = "File" Then
		// Assign output file from passed path.
		OutputFile = StorageData;
		If Not IsBlankString(OutputFile) Then
			
			// Check file availability.
			File = New File(OutputFile);
			FileExist = File.Exist();
			If FileExist And Not File.IsFile() Then
				// The suggested resource is not a data file.
				Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
				                                    NStr("en = 'Output resource ""%1"" already exist and not a valid data file.'"),
				                                    OutputFile));
			ElsIf FileExist Then
				// Delete existing output file.
				SafeDeleteFile(OutputFile);
				
				// Check wheter the file successfully deleted.
				If File.Exist() Then
					// The suggested resource is not accessible for writing.
					Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
					                                    NStr("en = 'Output file ""%1"" already exist and not accessible for writing.'"),
					                                    OutputFile));
				EndIf;
			EndIf;
			
		EndIf;
		
	ElsIf StorageType = "Storage" Then
		// If saving address is not specified, create new unique ID.
		If IsBlankString(StorageData)
		Or (TypeOf(StorageData) <> Type("UUID")) And (Not IsTempStorageURL(StorageData)) Then
			// New address should be allocated for the output data.
			StorageData = New UUID();
		EndIf;
		
	ElsIf StorageType = "Binary"
	Or    StorageType = "Base64"
	Or    StorageType = "String"
	Then
		// No additional storage required.
	EndIf;
	
	// Define default output file for FTP connection.
	If  TypeOf(Connection) = Type("FTPConnection")
	And IsBlankString(OutputFile)
	Then
		// Define temporary file for saving output data.
		OutputFile = GetTempFileName();
	EndIf;
	
	//--------------------------------------------------------------------------
	// 6. Open connection and perform HTTP/FTP request using passed method.
	
	// Execute passed command in connection.
	Try
		// Call command, requested for passed connection.
		If TypeOf(Connection) = Type("HTTPConnection") Then
			// Call HTTP method and become HTTPResponse as expected result.
			If ExternalHandler <> Undefined Then
				ResponseData = ExternalHandler.HTTPSendRequest(Connection, Method, Request, ExternalParameters);
			Else
				ResponseData = HTTPSendRequest(Connection, Method, Request);
			EndIf;
			
		ElsIf TypeOf(Connection) = Type("FTPConnection") Then
			// Call FTP method and save result to file.
			If ExternalHandler <> Undefined Then
				OutputDataSaved = ExternalHandler.FTPSendRequest(Connection, Method, PathToResource, SourceFile, OutputFile, ExternalParameters);
			Else
				OutputDataSaved = FTPSendRequest(Connection, Method, PathToResource, SourceFile, OutputFile);
			EndIf;
			
		EndIf;
		
	Except
		// Get exception cause.
		ErrorInfo = ErrorInfo();
		While TypeOf(ErrorInfo.Cause) = Type("ErrorInfo") Do
			ErrorInfo = ErrorInfo.Cause;
		EndDo;
		
		// Define connection properties.
		IsSecureConnection = Not (Connection.SecureConnection = Undefined);
		Schema = ?(TypeOf(Connection) = Type("HTTPConnection"), "http" , "ftp") + ?(IsSecureConnection, "s", "");
		
		// Failed to execute server connection.
		Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
		                                    NStr("en = 'Error executing %1 operation in %2%3 connection with host %4:
		                                         |%5'"),
		                                    Method, Schema, ?(IsSecureConnection, NStr("en = ' secure'"), ""),
		                                    Connection.Host + ?(ValueIsFilled(Connection.Port), ":" + Format(Connection.Port, "NZ=0; NG="), ""),
		                                    ErrorInfo.Description));
	EndTry;
	
	//--------------------------------------------------------------------------
	// 7. Store resulting output data, if available, in specified storage.
	
	// Process result of internet call.
	If TypeOf(Connection) = Type("HTTPConnection") Then
		
		// Save status code and headers in additional parameters.
		AdditionalParameters = New Structure("StatusCode, Headers");
		FillPropertyValues(AdditionalParameters, ResponseData);
		
		// Save response data depending on output type.
		If StorageType = "Response" Then
			// Return resulting response.
			Return ResultDescription(ResponseData, StorageType, AdditionalParameters);
			
		ElsIf StorageType = "File" Then
			// Request response as binary data.
			ResponseBinary = ResponseData.GetBodyAsBinaryData();
			If ResponseBinary <> Undefined Then
				
				// Check output file name.
				If IsBlankString(OutputFile) Then
					OutputFile = GetTempFileName();
				EndIf;
				
				// Save binary data to output file.
				ResponseBinary.Write(OutputFile);
				
				// Return output file name.
				Return ResultDescription(OutputFile, StorageType, AdditionalParameters);
			EndIf;
			
		ElsIf StorageType = "Storage" Then
			// Request response binary data.
			ResponseBinary = ResponseData.GetBodyAsBinaryData();
			If ResponseBinary <> Undefined Then
				// Place the resulting output in a temporary storage and return it's address.
				ResponseAddress = PutToTempStorage(ResponseBinary, StorageData);
				
				// Return address in temporary storage.
				Return ResultDescription(ResponseAddress, StorageType, AdditionalParameters);
			EndIf;
			
		ElsIf StorageType = "Binary" Then
			// Request response binary data.
			ResponseBinary = ResponseData.GetBodyAsBinaryData();
			If ResponseBinary <> Undefined Then
				// Return response binary.
				Return ResultDescription(ResponseBinary, StorageType, AdditionalParameters);
			EndIf;
			
		ElsIf StorageType = "Base64" Then
			// Request response binary data.
			ResponseBinary = ResponseData.GetBodyAsBinaryData();
			If ResponseBinary <> Undefined Then
				// Return response binary in Base64 format.
				Return ResultDescription(Base64String(ResponseBinary), StorageType, AdditionalParameters);
			EndIf;
			
		ElsIf StorageType = "String" Then
			// Read data as string using automatic content encoding detection.
			ResponseText = ResponseData.GetBodyAsString();
			If ResponseText <> Undefined Then
				// Return resulting string.
				Return ResultDescription(ResponseText, StorageType, AdditionalParameters);
			EndIf;
		EndIf;
		
	ElsIf TypeOf(Connection) = Type("FTPConnection") Then
		
		// Delete source temporary file.
		If  SourceFileDeleteUsed Then
			// Temporary file was used to save the source data - clear used file.
			SafeDeleteFile(SourceFile);
		EndIf;
		
		// Place resulting data from output file to the specified storage.
		If OutputDataSaved Then
			// Check file availability.
			File = New File(OutputFile);
			If Not File.Exist() Then
				// File don't exist.
				Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
				                                    NStr("en = 'Expected output data file ""%1"" don''t exist.'"),
				                                    OutputFile));
			ElsIf Not File.IsFile() Then
				// The suggested resource is not a data file.
				Return ResultDescription(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
				                                    NStr("en = 'Output resource ""%1"" is not a valid data file.'"),
				                                    OutputFile));
			EndIf;
			
			// Read and return file by the specified way.
			If StorageType = "File" Then
				
				// File already successfully saved.
				Return ResultDescription(OutputFile, StorageType);
				
			ElsIf StorageType = "Storage" Then
				// Read binary data from output file.
				Binary = New BinaryData(OutputFile);
				
				// Place the resulting output file in a temporary storage and return it's address.
				Address = PutToTempStorage(Binary, StorageData);
				
				// Delete used output file.
				SafeDeleteFile(OutputFile);
				
				// Return address in temporary storage.
				Return ResultDescription(Address, StorageType);
				
			ElsIf StorageType = "Binary" Then
				// Read binary data from output file.
				Binary = New BinaryData(OutputFile);
				
				// Delete used output file.
				SafeDeleteFile(OutputFile);
				
				// Return address in temporary storage.
				Return ResultDescription(Binary, StorageType);
				
			ElsIf StorageType = "Base64" Then
				// Read binary data from output file.
				Binary = New BinaryData(OutputFile);
				
				// Convert binary data to Base64 string.
				Base64 = Base64String(Binary);
				
				// Delete used output file.
				SafeDeleteFile(OutputFile);
				
				// Return address in temporary storage.
				Return ResultDescription(Base64, StorageType);
				
			ElsIf StorageType = "String" Then
				
				// Read saved output file and return it directly in result.
				FileContents = New TextDocument;
				FileContents.Read(OutputFile, "ISO-8859-1", Chars.LF);
				Result = FileContents.GetText();
				
				// Delete used output file.
				SafeDeleteFile(OutputFile);
				
				// Return resulting string.
				Return ResultDescription(Result, StorageType);
			EndIf;
		EndIf;
	EndIf;
	
	//--------------------------------------------------------------------------
	// 8. Operation was successfuly completed without any output.
	
	// Define connection properties.
	IsSecureConnection = Not (Connection.SecureConnection = Undefined);
	Schema = ?(TypeOf(Connection) = Type("HTTPConnection"), "http" , "ftp") + ?(IsSecureConnection, "s", "");
	
	// Successfully executed server connection.
	Return ResultDescription("", StringFunctionsClientServer.SubstituteParametersInString(
	                             NStr("en = 'The operation %1 in %2%3 connection with host %4 completed successfully.'"),
	                             Method, Schema, ?(IsSecureConnection, NStr("en = ' secure'"), ""),
	                             Connection.Host + ?(ValueIsFilled(Connection.Port), ":" + Format(Connection.Port, "NZ=0; NG="), "")));
	
EndFunction

// Creates new internet connection and performs request by specified method.
//
// Parameters:
//  URL                      - String - file URL in the canonical format:
//   <schema>://<login>:<password>@<host>:<port>/<path>?<parameters>#<anchor>
//   Secure connection can be defined using https or ftps schema.
//
//  Method                   - String - request method to the internet resource.
//                             Available methods for http and https protocols:
//                              Get, Post, Put, Delete
//                             Available methods for ftp and ftps protocol:
//                              Get, Put, Delete, Move,
//                              GetCurrentDirectory, SetCurrentDirectory,
//                              CreateDirectory, FindFiles.
//
//  HeadersData              - String of pairs of keys and their values
//                             in following format: <Key>: <Value> delimited by CR + LF.
//   For additional options of HeadersData see description of SendRequest method.
//
//  InputData                - String - pass request data directly as string.
//   For additional options of InputData see description of SendRequest method.
//
//  OutputData               - String - contains output data returned by the server.
//   For additional options of OutputData see description of SendRequest method.
//   If request cannot be sent, the OutputData contains an error description.
//
// Returns:
//  Boolean - True - the request was sent to the remote server,
//                   and the OutputData contains the server response;
//            False - otherwise.
//
Function CreateConnectionSendRequest(Val URL, Method,
	HeadersData = Undefined, InputData = Undefined, OutputData = Undefined) Export
	
	// Define connection settings.
	ConnectionSettings  = New Structure;
	
	// Create HTTP connection object.
	ConnectionStructure = CreateConnection(URL, ConnectionSettings);
	
	// Check connection result.
	If ConnectionStructure.Result = Undefined Then
		// Return error description.
		OutputData = ConnectionStructure.Description;
		Return False;
	EndIf;
	
	// Define connection object.
	Connection = ConnectionStructure.Result;
	
	// Open connection and request the data.
	RequestStructure  = SendRequest(Connection, Method, ConnectionSettings, HeadersData, InputData, OutputData);
	
	// Check request result.
	If RequestStructure.Result = Undefined Then
		// Return error description.
		OutputData = RequestStructure.Description;
		Return False;
	EndIf;
	
	// Convert resulting data to string.
	OutputData = String(RequestStructure.Result);
	Return True;
	
EndFunction

#EndIf

//------------------------------------------------------------------------------
// HTTP connection & FTP connection methods presentation.

// Returns structure of HTTP connection methods and their presentation.
// Used as alternative to enums for client calls.
//
// Returns:
//  Structure - Collection of HTTPConnection methods and their representation.
//
Function GetHTTPConnectionMethods() Export
	
	Return New FixedStructure("Get,   Put,   Post,   Delete",
	                          "Get", "Put", "Post", "Delete");
	
EndFunction

// Returns structure of FTP connection methods and their presentation.
// Used as alternative to enums for client calls.
//
// Returns:
//  Structure - Collection of FTPConnection methods and their representation.
//
Function GetFTPConnectionMethods() Export
	
	Return New FixedStructure("Get,   Put,   Delete,   Move,   GetCurrentDirectory,     SetCurrentDirectory,     CreateDirectory,    FindFiles",
	                          "Get", "Put", "Delete", "Move", "Get current directory", "Set current directory", "Create directory", "Find files");
	
EndFunction

//------------------------------------------------------------------------------
// Encode & decode parameters for internet request

// Encodes passed regular structured data to query string.
//
// Parameters:
//  QueryData                - Structure - standard structure
//                           - ValueList - pairs of value and key (presentation)
//                             to be posted on server for processing.
//  EncodePercentStr         - Boolean - defines whether data must be
//                             percent-encoded before placed in resulting string.
//
// Returns:
//  QueryString              - String - Encoded query string.
//
Function EncodeQueryData(QueryData, EncodePercentStr = True) Export
	Var QueryParameters;
	
	// Check query structure.
	If TypeOf(QueryData) = Type("Structure") Then
		
		// Recode structure to values list.
		QueryList = New ValueList;
		For Each Parameter In QueryData Do
			QueryList.Add(Parameter.Value, Parameter.Key);
		EndDo;
		QueryData = QueryList;
		
	ElsIf TypeOf(QueryData) = Type("ValueList") Then
		// Use value list directly.
		
	Else
		// Unknown type of parameters.
		Return "";
	EndIf;
	
	// Encode URL parameters from object-style to list style.
	EncodeURLParameters(QueryData, QueryParameters);
	
	// Get pairs and assign them to string
	StrParameters = "";
	For Each Parameter In QueryParameters Do
		StrParameters = ?(IsBlankString(StrParameters), "", StrParameters + "&")
		              + ?(EncodePercentStr,
		                  EncodeToPercentStr(Parameter.Presentation, "[]") + "=" + EncodeToPercentStr(String(Parameter.Value)),
		                  Parameter.Presentation + "=" + String(Parameter.Value));
	EndDo;
	
	Return StrParameters;
	
EndFunction

// Decodes passed query string to regular structured data.
//
// Parameters:
//  QueryString              - String - encoded query string.
//  DecodePercentStr         - Boolean - defines whether returned data must be
//                             percent-decoded before placed in resulting collection.
//  DecodeAsValueList        - Boolean - defines whether returned data must be
//                             placed in value list otherwise structure returned.
//
// Returns:
//  QueryData                - Structure - standard structure
//                           - ValueList - pairs of value and key (presentation)
//
Function DecodeQueryData(Val QueryString, DecodePercentStr = True,
	                                      DecodeAsValueList = True) Export
	
	// Remove insignificant characters.
	QueryString = TrimAll(QueryString);
	
	// Convert string parameters to the list of parameters.
	QueryList = New ValueList;
	While StrLen(QueryString) > 0 Do
		
		// Find parameter pairs delimiter.
		Position = Find(QueryString, "&amp;"); DelimLen = 5;
		If Position = 0 Then
			Position = Find(QueryString, "&"); DelimLen = 1;
		EndIf;
		
		// Get parameter pair.
		If Position > 0 Then
			// Current parameter pair.
			ParamPair = Left(QueryString, Position - 1);
			QueryString  = Mid(QueryString, Position + DelimLen);
		Else
			// Last parameter pair.
			ParamPair = QueryString;
			QueryString  = "";
		EndIf;
		
		// Assign parameter and value.
		Param = ParamPair;
		Value = "";
		Position = Find(ParamPair, "=");
		If Position > 0 Then
			Param = Left(ParamPair, Position - 1);
			Value = Mid(ParamPair, Position + 1);
		EndIf;
		
		// Decode percent strings.
		If DecodePercentStr Then
			If Find(Param, "%") > 0 Then
				Param = DecodeFromPercentStr(Param);
			EndIf;
			If Find(Value, "%") > 0 Then
				Value = DecodeFromPercentStr(Value);
			EndIf;
			If Find(Value, "\x") > 0 Then // IE<8 compatibility.
				Value = DecodeFromPercentStr(StrReplace(Value, "\x", "%"), False);
			EndIf;
		EndIf;
		
		// Add parameters to a map
		QueryList.Add(Value, Param);
	EndDo;
	
	// Try to detect types of passed values.
	DecodeURLParameters(QueryList);
	
	// Return desired collection type.
	If DecodeAsValueList Then
		// Return value list directly.
		Return QueryList;
		
	Else
		// Recode value list to structure.
		QueryData = New Structure;
		For Each Parameter In QueryList Do
			QueryData.Insert(Parameter.Presentation, Parameter.Value);
		EndDo;
		Return QueryData;
	EndIf;
	
EndFunction

//------------------------------------------------------------------------------
// Encode & decode JSON object data

// Encodes regular data collection to standard JSON string.
//
// Parameters:
//  Value         - Structure, Map, ValueList, Array - Regular data collection to be encoded.
//  UseWideRecord - Boolean  - Use human-readable representation,
//                             otherwise compact internet format will be used.
//  DateEncodingFormat       - Structure - describing encoding format of passed dates:
//   UseISODate              - Boolean - Use ISO 8601 string for encoding the datetime values,
//                             otherwise UNIX-time numeric will be used.
//   UseShortISODate         - Boolean - If date converted to ISO 8601
//                             has only data part without time used,
//                             then it will be saved only as data in short format,
//                             otherwise classic notation for date&time will be used.
//   UseLocalDate            - Boolean - If true then local date will be used without changes,
//                             otherwise date will be adjusted to UTC time zone.
//                             Numeric - -12 .. 0 .. 12 - Destination time zone in hours,
//                             the date should be encoded to - the difference between the time
//                             zone of local date and time zone of remote host will be adjusted.
//                             This setting does not affect fully encoded ISO 8601 dates.
//
// Returns:
//  String - standard JSON-encoded string.
//
Function EncodeJSON(Value, UseWideRecord = True, DateEncodingFormat = Undefined) Export
	// Define date encoding variables.
	Var UseISODate, UseShortISODate, TimeShift;
	
	// Define resulting string.
	Result = "";
	
	// Define date format parameters.
	DecodeDateParameters(DateEncodingFormat, UseISODate, UseShortISODate, TimeShift);
	
	// Encode 1C structure to JSON string format.
	EncodeJSONStructure(Value, Result,, UseWideRecord, UseISODate, UseShortISODate, TimeShift);
	
	// Return compiled JSON string.
	Return Result;
	
EndFunction

// Decodes standard JSON result and parses it in a regular structure.
//
// Parameters:
//  JSON                     - String - standard JSON-encoded structure.
//  DateDecodingFormat       - Structure - describing encoding format of passed dates:
//   UseLocalDate            - Boolean - If true then all dates treated as local dates,
//                             otherwise date treated as UTC date will be adjusted to local time.
//                             Numeric - -12 .. 0 .. 12 - Source time zone in hours,
//                             the date should be decoded from - the difference between the
//                             specified time zone of remote host will be adjusted to local time.
//                             This setting does not affect fully encoded ISO 8601 dates.
//
// Returns:
//  - Structure - decoded JSON data structure.
//  - Undefined - if format does not match JSON.
//
Function DecodeJSON(JSON, DateDecodingFormat = Undefined) Export
	// Define date decoding variables.
	Var TimeShift;
	
	// Define resulting object.
	Result = Undefined;
	
	// Define date format parameters.
	DecodeDateParameters(DateDecodingFormat,,, TimeShift);
	
	// Decode JSON string format to 1C structure.
	DecodeJSONStructure(String(JSON), Result, TimeShift);
	
	// Return compiled structure.
	Return Result;
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

//------------------------------------------------------------------------------
// Connection execution implementation

// Execute command in active HTTP connection.
// Does not perform checking of passed parameters.
//
// Parameters:
//  Connection               - HTTPConnection - object to perform internet request.
//  Method                   - String - request method to the internet resource.
//                             Possible HTTP(S) methods: Get, Put, Post, Delete.
//  Request                  - HTTPRequest - request obect containing relative path
//                             to the resource, headers, and data to be sent.
//
// Returns:
//  HTTPResponse             - Server response on sent HTTP request.
//
Function HTTPSendRequest(Connection, Method, Request)
	
	// Define default result.
	Result = Undefined;
	
	// Define called command.
	Command = Upper(Method);
	
	// Call command depending on connection type.
	If TypeOf(Connection) = Type("HTTPConnection") Then
		
		// Execute available methods for HTTP connection.
		If Command = "GET" Then
			// Request data from resource to the response storage.
			Result = Connection.Get(Request);
			
		ElsIf Command = "PUT" Then
			// Send data from local storage to the resource.
			Result = Connection.Put(Request);
			
		ElsIf Command = "POST" Then
			// Send request containing data from local storage
			// to the resource and collect processed result.
			Result = Connection.Post(Request);
			
		ElsIf Command = "DELETE" Then
			// Delete data from remote resource.
			Result = Connection.Delete(Request);
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Execute command in active FTP connection.
// Does not perform checking of passed parameters.
//
// Parameters:
//  Connection               - FTPConnection - object to perform internet request.
//  Method                   - String - request method to the internet resource.
//                             Possible FTP(S) methods: Get, Put, Delete, Move,
//                             GetCurrentDirectory, SetCurrentDirectory,
//                             CreateDirectory, FindFiles.
//  PathToResource           - String - requested relative path to the resource.
//                             Possible path extensions, defined using | delimiter:
//                             - For FTP Delete    method: PathToResource[|Mask]
//                             - For FTP Move      method: PathToFile1|PathToFile2
//                             - For FTP FindFiles method: PathToResource[|Mask]
//  SourceFile               - Full path to the file with source data to be sent.
//  OutputFile               - Full path to the file where output data will be stored.
//
// Returns:
//  Boolean                  - Is output data placed in specified output file.
//
Function FTPSendRequest(Connection, Method, PathToResource, SourceFile = "", OutputFile = "")
	
	// Define default result.
	Result = False;
	
	// Define called command.
	Command = Upper(Method);
	
	// Call command depending on connection type.
	If TypeOf(Connection) = Type("FTPConnection") Then
		
		// Execute available methods for FTP connection
		If Command = "GET" Then
			// Request file from resource to the local storage.
			Connection.Get(PathToResource, OutputFile);
			
			// Result data is placed to output file.
			Result = True;
			
		ElsIf Command = "PUT" Then
			// Send file from local storage to the resource.
			Connection.Put(SourceFile, PathToResource);
			
		ElsIf Command = "DELETE" Then
			// Check mask in resource path.
			DelimeterPos = Find(PathToResource, "|");
			If DelimeterPos > 0 Then
				Mask = Mid(PathToResource, DelimeterPos + 1);
				PathToResource = Left(PathToResource, DelimeterPos - 1);
			Else
				Mask = Undefined;
			EndIf;
			
			// Delete files from remote resource.
			Connection.Delete(PathToResource, Mask);
			
		ElsIf Command = "MOVE" Then
			// Check mask in resource path.
			DelimeterPos = Find(PathToResource, "|");
			If DelimeterPos > 0 Then
				PathToResource1 = Mid(PathToResource,  DelimeterPos + 1);
				PathToResource2 = Left(PathToResource, DelimeterPos - 1);
				
				// Rename files on remote resource.
				Connection.Move(PathToResource1, PathToResource2);
			EndIf;
			
		ElsIf Command = "GETCURRENTDIRECTORY" Then
			// Return string containing current directory.
			Result = Connection.GetCurrentDirectory();
			
			// Write output data to resulting file.
			FileContents = New TextDocument;
			FileContents.SetText(String(Result));
			FileContents.Write(OutputFile, "ISO-8859-1", Chars.LF);
			
			// Result data is placed to output file.
			Result = True;
			
		ElsIf Command = "SETCURRENTDIRECTORY" Then
			// Set current directory to passed resource.
			Connection.SetCurrentDirectory(PathToResource);
			
		ElsIf Command = "CREATEDIRECTORY" Then
			// Create directory at requested resource.
			Connection.CreateDirectory(PathToResource);
			
		ElsIf Command = "FINDFILES" Then
			// Check mask in resource path.
			DelimeterPos = Find(PathToResource, "|");
			If DelimeterPos > 0 Then
				Mask = Mid(PathToResource, DelimeterPos + 1);
				PathToResource = Left(PathToResource, DelimeterPos - 1);
			Else
				Mask = Undefined;
			EndIf;
			
			// Search for files in requested folder.
			FilesArray = Connection.FindFiles(PathToResource, Mask);
			
			// Add found files data in resulting list.
			Str = "";
			For Each FileData In FilesArray Do
				Str = Str + ?(IsBlankString(Str), "", Chars.LF)
				          +   FileData.FullName + ?(FileData.IsDirectory(), "/", "");
			EndDo;
			
			// Write output data to resulting file.
			FileContents = New TextDocument;
			FileContents.SetText(Str);
			FileContents.Write(OutputFile, "ISO-8859-1", Chars.LF);
			
			// Result data is placed to output file.
			Result = True;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

//------------------------------------------------------------------------------
// Decoding URL functions

// Splits the URL string into components
// according to RFC 3986 and returns it as a structure.
//
// Parameters:
// URLString - String - link to the resource in the following format
// (all fields are optional):
// 
//  <schema>://<login>:<password>@<host>:<port>/<path>?<parameters>#<anchor>
//             \________________/ \___________/
//                     |                |
//               authorization     server name
//               \____________________________/ \___________________________/
//                              |                             |
//                     connection string                path at server
//
// DecodePercentStr - Boolean - decode percent-encoded strings
//                              (path, parameters and anchor).
// DecodeParameters - Boolean - decode passed parameters and assign them
//                              proper value type.
//
// Returns:
//  Structure with the following fields:
//   Schema            - String.
//   Login             - String.
//   Password          - String.
//   ServerName        - String.
//   Host              - String.
//   Port              - String.
//   PathAtServer      - String.
//   Path              - String.
//   Parameters        - String containing pairs of parameters and theirs values.
//   ParametersDecoded - ValueList with pairs of parameters and theirs values.
//   Anchor            - String.
//
Function URLToStructure(Val URLString, DecodePercentStr = True,
	                                   DecodeParameters = True)
	
	// Remove insignificant characters.
	URLString = TrimAll(URLString);
	
	// Schema
	Schema = "";
	Position = Find(URLString, "://");
	If Position > 0 Then
		Schema = Lower(Left(URLString, Position - 1));
		URLString = Mid(URLString, Position + 3);
	EndIf;

	// Connection string and path at server
	ConnectionString = URLString;
	PathAtServer = "";
	Position = Find(ConnectionString, "/");
	If Position > 0 Then
		PathAtServer = Mid(ConnectionString, Position + 1);
		ConnectionString = Left(ConnectionString, Position - 1);
	EndIf;
	
	// User information and server name
	AuthorizationString = "";
	ServerName = ConnectionString;
	Position = Find(ConnectionString, "@");
	If Position > 0 Then
		AuthorizationString = Left(ConnectionString, Position - 1);
		ServerName = Mid(ConnectionString, Position + 1);
	EndIf;
	
	// Login and password
	Login = AuthorizationString;
	Password = "";
	Position = Find(AuthorizationString, ":");
	If Position > 0 Then
		Login = Left(AuthorizationString, Position - 1);
		Password = Mid(AuthorizationString, Position + 1);
	EndIf;
	
	// Host and port
	Host = ServerName;
	Port = "";
	Position = Find(ServerName, ":");
	If Position > 0 Then
		Host = Left(ServerName, Position - 1);
		Port = Mid(ServerName, Position + 1);
	EndIf;
	
	// Path, parameters string and anchor
	Path = PathAtServer;
	ParamStr = "";
	Position = Find(PathAtServer, "?");
	If Position > 0 Then
		Path = Left(PathAtServer, Position - 1);
		ParamStr = Mid(PathAtServer, Position + 1);
	EndIf;
	Anchor = "";
	Position = Find(ParamStr, "#");
	If Position > 0 Then
		Anchor = Mid(ParamStr, Position + 1);
		ParamStr = Left(ParamStr, Position - 1);
	EndIf;
	
	// Decode percent strings in path and anchor.
	If DecodePercentStr Then
		If Find(Path, "%") > 0 Then
			Path   = DecodeFromPercentStr(Path);
		EndIf;
		If Find(Anchor, "%") > 0 Then
			Anchor = DecodeFromPercentStr(Anchor);
		EndIf;
	EndIf;
	
	// Convert string parameters to the list of parameters.
	ParametersString  = ParamStr;
	ParametersDecoded = New ValueList;
	While StrLen(ParamStr) > 0 Do
		
		// Find parameter pairs delimiter.
		Position = Find(ParamStr, "&amp;"); DelimLen = 5;
		If Position = 0 Then
			Position = Find(ParamStr, "&"); DelimLen = 1;
		EndIf;
		
		// Get parameter pair.
		If Position > 0 Then
			// Current parameter pair.
			ParamPair = Left(ParamStr, Position - 1);
			ParamStr  = Mid(ParamStr, Position + DelimLen);
		Else
			// Last parameter pair.
			ParamPair = ParamStr;
			ParamStr  = "";
		EndIf;
		
		// Assign parameter and value.
		Param = ParamPair;
		Value = "";
		Position = Find(ParamPair, "=");
		If Position > 0 Then
			Param = Left(ParamPair, Position - 1);
			Value = Mid(ParamPair, Position + 1);
		EndIf;
		
		// Decode percent strings.
		If DecodePercentStr Then
			If Find(Param, "%") > 0 Then
				Param = DecodeFromPercentStr(Param);
			EndIf;
			If Find(Value, "%") > 0 Then
				Value = DecodeFromPercentStr(Value);
			EndIf;
			If Find(Value, "\x") > 0 Then // IE<8 compatibility.
				Value = DecodeFromPercentStr(StrReplace(Value, "\x", "%"), False);
			EndIf;
		EndIf;
		
		// Add parameters to a map
		ParametersDecoded.Add(Value, Param);
	EndDo;
	
	// Try to detect types of passed values.
	If DecodeParameters Then
		DecodeURLParameters(ParametersDecoded);
	EndIf;
	
	// Define resulting parameters structure.
	Result = New Structure;
	Result.Insert("Schema", Schema);
	Result.Insert("Login", Login);
	Result.Insert("Password", Password);
	Result.Insert("ServerName", ServerName);
	Result.Insert("Host", Host);
	Result.Insert("Port", Port);
	Result.Insert("PathAtServer", PathAtServer);
	Result.Insert("Path", Path);
	Result.Insert("Parameters", ParametersString);
	Result.Insert("ParametersDecoded", ParametersDecoded);
	Result.Insert("Anchor", Anchor);
	
	Return Result;
	
EndFunction

// Decodes percent string to native 1C string.
//
// Parameters:
//  PercentStr         - String  - containing percent-encoded characters.
//  PreferUTF8Decoding - Boolean - treat passed percent string as UTF first.
//                       True  for pathes (by default in all browsers).
//                       False for parameters values in FF and IE<10 by default.
//
// Returns:
//  String - Decoded 1C string.
//
Function DecodeFromPercentStr(Val PercentStr, PreferUTF8Decoding = True)
	
	// Define empty result.
	Result = "";
	
	// Define hex string.
	HexStr = "0123456789ABCDEF";
	MBytes = New Array;
	
	// Search for percent characters in a string.
	Pos = Find(PercentStr, "%");
	While Pos > 0 Do
		
		// Cut non-percent part of string.
		Result = Result + Left(PercentStr, Pos - 1);
		
		// Cut percent part.
		Percent = Upper(Mid(PercentStr, Pos+1, 2));
		PercentStr = Mid(PercentStr, Pos+3);
		
		// Check next percent symbol.
		While Left(PercentStr, 1) = "%" Do
			Percent = Percent + Upper(Mid(PercentStr, 2, 2));
			PercentStr = Mid(PercentStr, 4);
		EndDo;
		
		// Decode found percent string part.
		MBytes.Clear();
		While StrLen(Percent) > 0 Do
			// Convert hex value to byte
			High = Left(Percent, 1);
			Low  = Mid(Percent, 2, 1);
			Byte = 16 * (Find(HexStr, High)-1) + Find(HexStr, Low)-1;
			
			// Add byte to an array
			MBytes.Add(Byte);
			
			// Get next string part.
			Percent = Mid(Percent, 3);
		EndDo;
		
		// Check wethever it possible to convert it
		// using UTF-8 (according to standards).
		DecodedUTF8 = ?(PreferUTF8Decoding, UTF8ToStr(MBytes), "");
		If StrLen(DecodedUTF8) > 0 Then
			Result = Result + DecodedUTF8;
		Else
			// Treat passed bytes as ANSI string (IE compatible).
			Result = Result + ANSIToUnicode(MBytes); // UTF-16 compatible.
		EndIf;
		
		// Find next possible percent part.
		Pos = Find(PercentStr, "%");
	EndDo;
	
	// Add rest of a string.
	Result = Result + PercentStr;
	
	// Return decoded string.
	Return Result;
	
EndFunction

// Decodes types of passed in URL values and rebuild passed structures.
// Types decoding:
// - Arrays are decoded to structures (named fileds, id-compilant), maps
//    (named fileds, id-incompilant) or arrays (integer or empty iterator).
// - Numeric values are decoded in international standard without thousands
//    separators, decimal separator represented by ".", possible unar minus
//    or plus should be used as prefix.  Exponential values are not decoded
//    due to possible limitations of numeric values.
//   Date values are decoded in internet format according to RFC 3339.
// - Boolean values as "true" and "false".
// - All other values are preserved as stirngs without decoding/conversation.
// If an exception occurs during decoding then passed map remains unchanged.
//
// Parameters:
//  URLParameters - Map - pairs of parameters and their values.
//
// Returns:
//  URLParameters - Map - pairs of parameters and typed values
//                        and rebuilt structures.
//
Procedure DecodeURLParameters(URLParameters)
	
	// The procedure support decoding of primitives and arrays types.
	Try
		// Define storage for decoding multiple key values.
		MulKeysList = New ValueList;
		MulKeysTree = New Map;
		
		// Serch for possible structure.
		For Each Record In URLParameters Do
			
			// Check wheter current record is a true multiple values key.
			RecKey = GetMultipleValueKeyPresentation(Record.Presentation);
			If Not IsBlankString(RecKey) Then
				// Add collection key to sorting array.
				MulKeysList.Add(RecKey);
			EndIf;
		EndDo;
		
		// Create universal collections as a tree to hold childrens data (if any).
		If MulKeysList.Count() > 0 Then
			
			// Reorganize passed keys list.
			MulKeysList.SortByValue();
			
			// Recursive create tree elements.
			CreateURLParametersCollectionElements(MulKeysList.UnloadValues(), MulKeysTree);
		EndIf;
		
		// Reassign values to newly created parameters, and adjust their's types.
		NewParameters = New ValueList;
		KeysProcessed = New Map;
		ArraysIndexes = New Map;
		For Each Record In URLParameters Do
			
			// Convert value to the proper primitive type.
			Value = Record.Value;
			ConvertValueToPrimitiveType(Value);
			
			// Check wheter current record is a true multiple values key.
			RecKey = GetMultipleValueKeyPresentation(Record.Presentation);
			If Not IsBlankString(RecKey) Then // Multiple array value.
				
				// Check, whether it first occurence of the object.
				Path = "";
				Pos  = Find(RecKey, ".");
				Rec  = Left(RecKey, Pos - 1);
				If KeysProcessed.Get(Rec) = Undefined Then // First occurence.
					
					// Add tree to the parameters list.
					NewParameters.Add(MulKeysTree.Get(Rec), Rec);
					
					// Mark key as processed (the tree already added).
					KeysProcessed.Insert(Rec, NewParameters.Count() - 1);
				EndIf;
				
				// Find element in a structure to assign a value.
				Obj = NewParameters[KeysProcessed.Get(Rec)].Value; // Reference to top object.
				While Pos > 0 Do
					
					// Find next element of tree.
					RecKey = Mid(RecKey, Pos + 1);
					Path   = ?(Not IsBlankString(Path), Path + "." + Rec, Rec);
					Pos    = Find(RecKey, ".");
					Rec    = ?(Pos > 0, Left(RecKey, Pos - 1), RecKey);
					
					// Assign value to the tree element.
					if TypeOf(Obj) = Type("Array") Then
						
						// Define array index.
						If IsBlankString(Rec) Then // Index is not specified.
							// Get current index in this array by path.
							Index = ArraysIndexes.Get(Path);
							If Index = Undefined Then
								Index = -1; // = Pred(0);
							EndIf;
							Index = Index + 1;
							ArraysIndexes.Insert(Path, Index);
						Else
							Index = Number(Rec);
						EndIf;
						
						// Assign array value.
						If Index < 100 Then // Array overload protection.
							
							// Check subelements.
							If Pos > 0 Then
								// Has subelements - go to one level down.
								Obj = Obj[Index];
							Else
								// End point - assign a value.
								Obj[Index] = Value;
							EndIf;
							
						Else
							// Skip this value.
							Break;
						EndIf;
						
					ElsIf TypeOf(Obj) = Type("Structure") Then
						
						// Check subelements.
						If Pos > 0 Then
							// Has subelements - go to one level down.
							Obj.Property(Rec, Obj);
						Else
							// End point - assign a value.
							Obj.Insert(Rec, Value);
						EndIf;
						
					ElsIf TypeOf(Obj) = Type("Map") Then
						
						// Check subelements.
						If Pos > 0 Then
							// Has subelements - go to one level down.
							Obj = Obj.Get(Rec);
						Else
							// End point - assign a value.
							Obj.Insert(Rec, Value);
						EndIf;
					EndIf;
				EndDo;
					
			Else // Single value.
				
				// Add converted value to the parameters list.
				NewParameters.Add(Value, Record.Presentation);
			EndIf;
		EndDo;
		
		// Reassign the processed list.
		URLParameters = NewParameters;
		
	Except
		// Do not change contents of URLParameters array;
	EndTry;
	
EndProcedure

// Create structure of parameters (data tree) basing on declaration
// of elements passed in keys list array.
//
// Parameters:
//  KeysList      - Array - keys to transformate to the structure.
//  ParentKeys    - Array, Structure, Map - destination collection
//                  where new created keys are placed.
//
// Returns:
//  ParentKeys    - Destination collection where new created keys are placed.
//
Procedure CreateURLParametersCollectionElements(KeysList, ParentKeys)
	
	// Create subkeys collection.
	SubKeysList = New Array;
	
	// Define digits.
	Digits = "0123456789";
	
	// For array subkeys rearrange keys according to numeric order (and not a string order).
	If TypeOf(ParentKeys) = Type("Array") Then
		
		// Create sorting values list;
		SrtKeysList = New ValueList;
		j = 0;
		For i = 0 To KeysList.Count() - 1 Do
			Pos   = Find(KeysList[i], ".");
			Index = ?(Pos > 0, Left(KeysList[i], Pos - 1), KeysList[i]);
			If IsBlankString(Index) Then
				Order = j; // Current array element (if not specified).
				j = j + 1;
			Else
				Order = Number(Index);
			EndIf;
			SrtKeysList.Add(Order, KeysList[i]);
		EndDo;
		
		// Sort list according to numeric order.
		SrtKeysList.SortByValue();
		
		// Copy sorted list back to KeysList array.
		For i = 0 To KeysList.Count() - 1 Do
			KeysList[i] = SrtKeysList[i].Presentation;
		EndDo;
	EndIf;
	
	// Analyze list of passed keys.
	i = 0; PreviousKey = Undefined;
	While i <= KeysList.Count() Do
		
		// Check presence of subkeys in a key.
		If i < KeysList.Count() Then
			TheKey = KeysList[i];
			Pos    = Find(TheKey, ".");
			CurrentKey    = ?(Pos > 0, Left(TheKey, Pos - 1), TheKey);
			CurrentSubKey = ?(Pos > 0,  Mid(TheKey, Pos + 1), Undefined);
		Else
			// Final pass: process last found value.
			CurrentKey =    Undefined;
			CurrentSubKey = Undefined;
		EndIf;
		
		// Process current key
		If CurrentKey = PreviousKey Then
			
		// CurrentKey <> PreviousKey,
		// new key or subtree detected,
		// process previously found elements.
		ElsIf PreviousKey <> Undefined Then
			
			// Process previous key or subtree family
			If SubKeysList.Count() > 0 Then
				
				// Process previous key subkeys.
				l = 0; IsStructure = True; IsArray = True;
				For j = 0 To SubKeysList.Count() - 1 Do
					
					// Get current subkey.
					SubKey = SubKeysList[j];
					
					// If subkey is implicitly defined, then redefine key.
					If IsBlankString(SubKey) Then
						SubKeysList[j] = Format(l, "NZ=0; NG=");
						SubKey = SubKeysList[j];
						l = l + 1;
					EndIf;
					
					// Skip futher checks if map already defined.
					If (Not IsStructure) And (Not IsArray) Then
						Continue;
					EndIf;
					
					// Get subkey name.
					SubPos = Find(SubKey, ".");
					SubKey = ?(SubPos > 0, Left(SubKey, SubPos - 1), SubKey);
					
					// Check subkey name.
					If Find(Digits, Left(SubKey, 1)) > 0 Then // First symbol is digit.
						
						// It can't be a structure.
						IsStructure = False;
						
						// Check subkey as a possible number.
						For k = 2 To StrLen(SubKey) Do
							
							// Check all chars in a subkey.
							If Find(Digits, Mid(SubKey, k, 1)) = 0 Then
								IsArray = False;
								Break;
							EndIf;
						EndDo;
						
						// Array overload protection.
						If IsArray Then
							// Define current item index.
							Index = ?(IsBlankString(SubKey), 0, Number(SubKey));
							If Index > 100 Then
								// Array index is too big, use map instead.
								IsArray = False;
							EndIf;
						EndIf;
						
					Else // First symbol is alpha.
						
						// It can't be an array.
						IsArray = False;
					EndIf;
				EndDo;
				
				// Create defined collection.
				If IsArray Then
					Element = New Array;
					
				ElsIf IsStructure Then
					Element = New Structure;
					
				Else // IsMap
					Element = New Map;
				EndIf;
			Else
				// Does not has children.
				Element = Undefined;
			EndIf;
			
			// Add element to collection.
			If TypeOf(ParentKeys) = Type("Array") Then
				
				// Define index of new element in array.
				If IsBlankString(PreviousKey) Then
					Index = ParentKeys.Count(); // Last index + 1.
				Else
					Index = Number(PreviousKey);
				EndIf;
				
				// Add new element to an array.
				For j = ParentKeys.Count() To Index - 1 Do
					ParentKeys.Add();
				EndDo;
				ParentKeys.Add(Element);
			Else
				ParentKeys.Insert(PreviousKey, Element);
			EndIf;
			
			// Process childs.
			If SubKeysList.Count() > 0 Then
				CreateURLParametersCollectionElements(SubKeysList, Element);
				SubKeysList.Clear();
			EndIf;
			
			// Assign new current key.
			PreviousKey = CurrentKey;
		Else
			
			// Assign new current key.
			PreviousKey = CurrentKey;
		EndIf;
		
		// Add subkey to list,
		// it should not be used in previous key processing.
		If CurrentSubKey <> Undefined Then
			SubKeysList.Add(CurrentSubKey);
		EndIf;
		
		// Prepare next iteration.
		i = i + 1;
	EndDo;
	
EndProcedure

// Converts multiple value key (URL array) to it's object presentation.
//
// Parameters:
//  Key    - String - key, containing brackets.
//
// Returns:
//  String - Object key representation containing "." as delimiter.
//
Function GetMultipleValueKeyPresentation(Key)
	
	// Define default result.
	Result = "";
	
	// Define digits
	Digits = "0123456789";
	
	// Check wheter it a multiple values key.
	SimplKey = StrReplace(Key, "][", "");             // Exclude internal brackets.
	If  StrOccurrenceCount(SimplKey, "[") = 1         // Array dimension found.
	And StrOccurrenceCount(SimplKey, "]") = 1         // Array dimension finally closed.
	And IsURLStringRFC3986Compilant(Key, "[]", "-.~") // ID-compilant name (latin symbols, digits and underscore.
	And Find(Digits, Left(Key, 1)) = 0                // Does not begin from digit.
	Then
		// Apply multiple values key presentation.
		Result = StrReplace(StrReplace(StrReplace(Key, "][", "."), "[", "."), "]", "."); // Replace brackets with points.
		If Right(Result, 1) = "." Then
			Result = Mid(Result, 1, StrLen(Result) - 1);                                 // Cut final point.
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Checks whether passed string is compilant to RFC 3986,
// that is, does it contain unreserved characters only,
// and thus do not require percent encoding.
//
// Parameters:
//  URLString            - String - unicode string to be checked
//                                  on compilance.
//  AdditionalCharacters - String - additional characters to be skipped
//                                  while checking the string, used as
//                                  formatting and delimeters symbols.
//  ExcludeCharacters    - String - characters to be restricted and
//                                  excluded from standard RFC 3986
//                                  charcters specification while checking.
//
// Returns:
//  Boolean - is URLString compilant to RFC 3986 or not.
//
Function IsURLStringRFC3986Compilant(Val URLString,
	AdditionalCharacters = "", ExcludeCharacters = "")
	
	// Define RFC 3986 unreserved characters.
	RFC3986UnreservedCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"+
	                              "abcdefghijklmnopqrstuvwxyz"+
	                              "0123456789-_.~"
	                            + AdditionalCharacters;
	
	// Exclude characters from RFC 3986 reference string.
	For i = 1 To StrLen(ExcludeCharacters) Do
		RFC3986UnreservedCharacters =
		StrReplace(RFC3986UnreservedCharacters, Mid(ExcludeCharacters, i, 1), "");
	EndDo;
	
	// Define default result.
	Result = True;
	
	// Check all chars in a string.
	For i = 1 To StrLen(URLString) Do
		
		// Check current char in a string.
		If Find(RFC3986UnreservedCharacters, Mid(URLString, i, 1)) = 0 Then
			Result = False;
			Break;
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

//------------------------------------------------------------------------------
// Encoding URL functions

// Joins the URL string form its components passed by structure
// according to RFC 3986.
//
// Parameters:
//  URLSrtucture - Structure with the following fields (all fields are optional):
//   Schema             - String.
//   Login              - String.
//   Password           - String.
//   ServerName         - String.
//   or:
//    Host              - String.
//    Port              - Number
//                        or String containing port number.
//   PathAtServer       - String.
//   or:
//    Path              - String.
//    Parameters        - String containing request parameters.
//    ParametersDecoded - ValueList with pairs of parameters and theirs values,
//                        merges, overrides Parameters passed in string form.
//    Anchor            - String.
//
// EncodePercentStr     - Boolean - encode percent-encoded strings
//                                  (path, parameters and anchor).
//
// Returns:
//  URLString - String - link to the resource in the following format:
// 
//  <schema>://<login>:<password>@<host>:<port>/<path>?<parameters>#<anchor>
//             \________________/ \___________/
//                     |                |
//               authorization     server name
//               \____________________________/ \___________________________/
//                              |                             |
//                     connection string                path at server
//
Function StructureToURL(URLSrtucture, EncodePercentStr = True)
	Var Schema, Login, Password,
	    ServerName, Host, Port,
	    PathAtServer, Path, Anchor,
	    Parameters, ParametersDecoded, URLParameters;
	
	// Define resulting parameters structure.
	URLString = "";
	
	// Schema
	If  URLSrtucture.Property("Schema", Schema)
	And Not IsBlankString(Schema) Then
		URLString = URLString + Schema + "://";
	EndIf;
	
	// Authorization
	If  URLSrtucture.Property("Login", Login)
	And Not IsBlankString(Login) Then
		
		// Login
		URLString = URLString + Login;
		
		// Password
		If  URLSrtucture.Property("Password", Password)
		And Not IsBlankString(Password) Then
			URLString = URLString + ":" + Password;
		EndIf;
		URLString = URLString + "@";
	EndIf;
	
	// Server name
	If  URLSrtucture.Property("ServerName", ServerName)
	And Not IsBlankString(ServerName) Then
		
		// Full server name
		URLString = URLString + ServerName;
		
	ElsIf   URLSrtucture.Property("Host", Host)
	And Not IsBlankString(Host) Then
		
		// Host name
		URLString = URLString + Host;
		
		// Port number
		If  URLSrtucture.Property("Port", Port)
		And Not IsBlankString(Port) Then
			URLString = URLString + ":" +
			            ?(TypeOf(Port) = Type("Number"), Format(Port, "NFD=0; NG=; NZ=0"), String(Port));
		EndIf;
	EndIf;
	
	// Path at server
	If  URLSrtucture.Property("PathAtServer", PathAtServer)
	And Not IsBlankString(PathAtServer) Then
		
		// Full path to resource
		URLString = URLString + "/" +PathAtServer;
		
	ElsIf URLSrtucture.Property("Path", Path)
	And Not IsBlankString(Path) Then
		
		// Path to resource
		URLString = URLString + "/" + ?(EncodePercentStr, EncodeToPercentStr(Path, "/"), Path);
		
		// Check parameters existing.
		AreParamStr = URLSrtucture.Property("Parameters",        Parameters)
		              And Not IsBlankString(Parameters);
		
		AreParamObj = URLSrtucture.Property("ParametersDecoded", ParametersDecoded)
		              And TypeOf(ParametersDecoded) = Type("ValueList");
		
		// Process and merge parameters.
		If (AreParamStr) And (Not AreParamObj) Then    // Parameters are string-based only.
			
			// Parameters passed by string
			URLString = URLString + "?" + Parameters;
			
		ElsIf (Not AreParamStr) And (AreParamObj) Then // Parameters are object-based only.
			
			// Encode URL parameters from object-style to list style.
			EncodeURLParameters(ParametersDecoded, URLParameters);
			
			// Get pairs and assign them to string
			StrParameters = "";
			For Each Parameter In URLParameters Do
				StrParameters = ?(IsBlankString(StrParameters), "", StrParameters + "&")
				              + ?(EncodePercentStr,
				                  EncodeToPercentStr(Parameter.Presentation, "[]") + "=" + EncodeToPercentStr(String(Parameter.Value)),
				                  Parameter.Presentation + "=" + String(Parameter.Value));
			EndDo;
			
			// Add restored parameters to URL string.
			If Not IsBlankString(StrParameters) Then
				URLString = URLString + "?" + StrParameters;
			EndIf;
			
		ElsIf (AreParamStr) And (AreParamObj) Then     // Override parameters prioritizing string order and formatting.
			
			// Define final URl parameters.
			URLParameters = New ValueList;
			DecParameters = New ValueList;
			
			// Encode decoded parameters from object-style to list style.
			EncodeURLParameters(ParametersDecoded, DecParameters);
			
			// Decode original Str parameters to value list witout decoding values.
			ParametersFromString = URLToStructure(URLString + "?" + Parameters, True, False).ParametersDecoded;
			
			// Go thru parameters form string and copy those existing in decoded parameters with original formatting.
			OldParamSrc = Undefined;
			For Each ParamSrc In ParametersFromString Do
				
				// Get source value
				ValueSrc = ParamSrc.Value;
				ConvertValueToPrimitiveType(ValueSrc);
				
				// Find more closest value in overriden ParametersDecoded values list.
				For Each ParamOvr In DecParameters Do
					
					// Skip processed parameters
					If  ParamOvr.Check Then
						Continue;
					EndIf;
					
					// Compare keys and values of old and new list of parameters.
					ValueOvr = ParamOvr.Value;
					If  ParamSrc.Presentation = ParamOvr.Presentation // Key source = Key overriden.
					And ConvertValueToPrimitiveType(ValueOvr)         // Successfully converted to primitive type.
					And ValueSrc = ValueOvr Then                      // Decoded source value = Overridden value.
					
						// Both key name and value meaning are the same - use to copy with original formatting.
						ParamOvr.Check = True;
						URLParameters.Add(ParamSrc.Value, ParamSrc.Presentation);
						Break;
						
					ElsIf ParamSrc.Presentation = ParamOvr.Presentation Then // Key source = Key overriden.
						
						// If key is the same, then use the value anyway, override source value.
						ParamOvr.Check = True;
						URLParameters.Add(ParamOvr.Value, ParamOvr.Presentation);
						Break;
						
					ElsIf OldParamSrc <> Undefined Then
						
						// Check  additional values of the same multiple key.
						PosOld = Find(OldParamSrc.Presentation, "[");
						PosOvr = Find(ParamOvr.Presentation, "[");
						If  (PosOld > 0)
						And (PosOld = PosOvr)
						And  Left(OldParamSrc.Presentation, PosOld-1) = Left(ParamOvr.Presentation, PosOvr-1) Then
						
							// If some additional multiple key values are existing - add them to parameters.
							ParamOvr.Check = True;
							URLParameters.Add(ParamOvr.Value, ParamOvr.Presentation);
						EndIf;
					EndIf;
				EndDo;
				
				// Save old iteration volue to assign newly added values.
				OldParamSrc = ParamSrc;
			EndDo;
			
			// Process last OldParamSrc value.
			If OldParamSrc <> Undefined Then
				For Each ParamOvr In DecParameters Do
					
					// Skip processed parameters
					If  ParamOvr.Check Then
						Continue;
					EndIf;
					
					// Compare keys and values of old and new list of parameters.
					PosOld = Find(OldParamSrc.Presentation, "[");
					PosOvr = Find(ParamOvr.Presentation, "[");
					If  (PosOld > 0)
					And (PosOld = PosOvr)
					And  Left(OldParamSrc.Presentation, PosOld-1) = Left(ParamOvr.Presentation, PosOvr-1) Then // Additional values of the same multiple key.
					
						// If some additional multiple key values are existing - add them to parameters.
						ParamOvr.Check = True;
						URLParameters.Add(ParamOvr.Value, ParamOvr.Presentation);
					EndIf;
				EndDo;
			EndIf;
			
			// Add last additional items from overriden parameters.
			For Each ParamOvr In DecParameters Do
				If Not ParamOvr.Check Then
					URLParameters.Add(ParamOvr.Value, ParamOvr.Presentation);
				EndIf;
			EndDo;
			
			// Get pairs and assign them to string
			StrParameters = "";
			For Each Parameter In URLParameters Do
				StrParameters = ?(IsBlankString(StrParameters), "", StrParameters + "&")
				              + ?(EncodePercentStr,
				                  EncodeToPercentStr(Parameter.Presentation, "[]") + "=" + EncodeToPercentStr(String(Parameter.Value)),
				                  Parameter.Presentation + "=" + String(Parameter.Value));
			EndDo;
			
			// Add restored parameters to URL string.
			If Not IsBlankString(StrParameters) Then
				URLString = URLString + "?" + StrParameters;
			EndIf;
		EndIf;
		
		// Anchor
		If URLSrtucture.Property("Anchor", Anchor)
		And Not IsBlankString(Anchor) Then
			URLString = URLString + "#" +?(EncodePercentStr, EncodeToPercentStr(Anchor), Anchor);
		EndIf;
	EndIf;
	
	Return URLString;
	
EndFunction

// Replaces symbols out of unreserved set with percent-encoded string.
// According to RFC 3986 unreserved symbols are:
// - Numeric: (%30-%39),
// - Alpha:   (%41-%5A && %61-%7A),
// - Symbols: Hyphen (%2D), Full stop (%2E), Underscore (%5F) and Tilde (%7E).
//
// Parameters:
//  Str                  - String - to be checked according to RFC 3986
//                                  and if needed converted to percent string.
//  AdditionalCharacters - String - additional characters to be skipped
//                                  while checking the string, used as
//                                  formatting and delimeters symbols.
//  ExcludeCharacters    - String - characters to be restricted and
//                                  excluded from standard RFC 3986
//                                  charcters specification while checking.
//
// Returns:
//  String - Percent-encoded string according to RFC 3986.
//
Function EncodeToPercentStr(Str, AdditionalCharacters = "", ExcludeCharacters = "")
	
	// Define empty result.
	Result = "";
	
	// Define hex string.
	HexStr = "0123456789ABCDEF";
	MBytes = New Array;
	
	// Define RFC 3986 unreserved characters.
	Unreserved = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~"
	           + AdditionalCharacters;
	
	// Exclude characters from RFC 3986 reference string.
	For i = 1 To StrLen(ExcludeCharacters) Do
		RFC3986UnreservedCharacters =
		StrReplace(RFC3986UnreservedCharacters, Mid(ExcludeCharacters, i, 1), "");
	EndDo;

	// Recode string replacing chars out of unreserved.
	StrBuf = "";
	For i = 1 To StrLen(Str) Do
		
		// Get current char.
		Char = Mid(Str, i, 1);
		
		// Check char according to RFC 3986.
		If Find(Unreserved, Char) > 0 Then
			
			// Process buffer if previously used.
			If StrLen(StrBuf) > 0 Then
				
				// Convert buffer to an array of UTF-8 chars (bytes).
				MBCS = StrToUTF8(StrBuf, True);
				For Each MBC In MBCS Do
					// Convert byte to hex: // High half byte                   // Low half byte
					Result = Result + "%" + Mid(HexStr, Int(MBC / 16) + 1, 1) + Mid(HexStr, (MBC % 16) + 1, 1);
				EndDo;
				
				// Clear buffer.
				StrBuf = "";
			EndIf;
			
			// Unreserved char found.
			Result = Result + Char;
		Else
			
			// This is not an unreserved char.
			StrBuf = StrBuf + Char;
		EndIf;
	EndDo;
	
	// Process buffer if previously used.
	If StrLen(StrBuf) > 0 Then
		
		// Convert buffer to an array of UTF-8 chars (bytes).
		MBCS = StrToUTF8(StrBuf, True);
		For Each MBC In MBCS Do
			// Convert byte to hex: // High half byte                   // Low half byte
			Result = Result + "%" + Mid(HexStr, Int(MBC / 16) + 1, 1) + Mid(HexStr, (MBC % 16) + 1, 1);
		EndDo;
		
		// Clear buffer.
		StrBuf = "";
	EndIf;
	
	// Return decoded string.
	Return Result;
	
EndFunction

// Encode parameters of primitives and structures into standard URL parameters.
// Types encoding:
// - Structures, maps and arrays are recoded to arrays (named or integer).
// - Numeric values are encoded using international standard without thousands
//    separators, decimal separator represented by ".", unar minus as prefix.
// - Date types are encoded in UNIX-like numeric standard.
// - Boolean values as "true" and "false".
// - All other values are encoded as stirngs using their presentation.
//
// Parameters:
//  Parameters    - ValueList, Map, Structure, Array - Collection of parameters
//                  and typed values or sub-structures.
//  URLParameters - ValueList - Returned collecion of parameters and their values
//                  converted to string.
//  Key           - String - Current filling structure key (used in recursion).
//
// Returns:
//  URLParameters - ValueList - pairs of parameters and their values
//                  converted to string.
//
Procedure EncodeURLParameters(Parameters, URLParameters, Key = "")
	
	// Define resulting value list.
	If  URLParameters = Undefined Then
		URLParameters = New ValueList;
	EndIf;
	
	// Check if array has undefined (orderly numbered) elements.
	HasUndefinedElements = False;
	If TypeOf(Parameters) = Type("Array") Then
		For Each Element In Parameters Do
			If Element = Undefined Then
				HasUndefinedElements = True;
			EndIf;
		EndDo;
	EndIf;
	
	// Go thru paramters collection
	// and add appropriate values to final URL Parameters map.
	Index = 0;
	For Each Element In Parameters Do
		
		// Define current path and value in collection.
		If TypeOf(Parameters) = Type("Array") Then
			
			// Use iterator in an array.
			Path  = Key + "[" + ?(HasUndefinedElements, Format(Index, "NDS=.; NZ=0; NG="), "") + "]";
			Value = Element;
			Index = Index + 1;
			
		ElsIf TypeOf(Parameters) = Type("Map")
		   Or TypeOf(Parameters) = Type("Structure") Then
			
			// Use named fields in an array.
			Path  = Key + "[" + Element.Key + "]";
			Value = Element.Value;
			
		ElsIf TypeOf(Parameters) = Type("ValueList") Then
			
			// Use named fields in an array.
			Path  = Element.Presentation;
			Value = Element.Value;
		EndIf;
		
		// Format passed values.
		If Value = Undefined Then
			// Skip empty value.
			
		ElsIf TypeOf(Value) = Type("Array")
		   Or TypeOf(Value) = Type("Map")
		   Or TypeOf(Value) = Type("Structure") Then
			// Run the procedure recursively for all child elements.
			EncodeURLParameters(Value, URLParameters, Path);
			
		ElsIf TypeOf(Value) = Type("Number") Then
			URLParameters.Add(Format(Value, "NDS=.; NZ=0; NG="), Path);
			
		ElsIf TypeOf(Value) = Type("Date") Then
			URLParameters.Add(Format(Value, "DF=yyyy-MM-ddTHH:mm:ssZ"), Path);
			
		ElsIf TypeOf(Value) = Type("Boolean") Then
			URLParameters.Add(Format(Value, "BF=false; BT=true"), Path);
			
		Else // As string.
			URLParameters.Add(TrimAll(Value), Path);
		EndIf;
	EndDo;

EndProcedure

//------------------------------------------------------------------------------
// Decoding JSON functions

// Decodes standard JSON string to native structure.
//
// Parameters:
//  StrJSON   - String - contains standard JSON object to convert.
//  Parent    - Structure, Array - destination collection
//                       where new created keys are placed.
//  TimeShift - Number - Local time zone correction in seconds for use with UNIX dates
//                       and ISO 8601 dates without time zone specified.
//
// Returns:
//  Parent    - Destination collection where new created keys are placed.
//
Procedure DecodeJSONStructure(Val StrJSON, Parent, TimeShift = 0);
	
	// Define valid id symbols.
	CharsID = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789";
	CharsDg = "0123456789";
	
	// Process passed strings.
	While StrLen(StrJSON) > 0 Do
		
		// For structure use ID in value pair.
		If TypeOf(Parent) = Type("Structure") Then
			
			// 1. Get value ID.
			Pos = Find(StrJSON, """");
			If Pos = 0 Then
				// ID not found
				Return;
			ElsIf Not IsBlankString(Left(StrJSON, Pos-1)) Then
				// Some garbage found?
				Return;
			Else
				// Cut string to value ID.
				StrJSON = Mid(StrJSON, Pos+1);
			EndIf;
			
			// Cut value ID.
			StrID = ""; i = 1;
			While i <= StrLen(StrJSON) Do
				
				// Get current char.
				Ch = Mid(StrJSON, i , 1);
				If Ch <> """" Then
					// Simple char found.
					StrID = StrID + Ch;
					
				Else
					// Closing quote found.
					StrJSON = Mid(StrJSON, i + 1);
					Break;
				EndIf;
				
				// Next iteration.
				i = i + 1;
			EndDo;
			
			// Check value ID.
			If IsBlankString(StrID) Then
				// Value ID cannot be empty.
				Return;
				
			ElsIf Find(CharsDg, Left(StrID, 1)) > 0 Then
				// ID cannot begin from a digit.
				Return;
				
			Else // Check symbols passend to the ID rules.
				For i = 1 To StrLen(StrID) Do
					If Find(CharsID, Mid(StrID, i, 1)) = 0 Then
						Return;
					EndIf;
				EndDo;
			EndIf;
			
			// 2. Get value delimiter.
			Pos = Find(StrJSON, ":");
			If Pos = 0 Then
				// Delimiter not found
				Return;
			ElsIf Not IsBlankString(Left(StrJSON, Pos-1)) Then
				// Some garbage found?
				Return;
			Else
				// Cut string to Value.
				StrJSON = TrimL(Mid(StrJSON, Pos+1));
			EndIf;
		EndIf;
		
		// 3. Define possible value.
		// Get first char.
		Ch = Left(StrJSON, 1);
		
		// Check char according to possible values.
		If Ch = "{" Or Ch = "[" Then // Structure or array found.
			ChOp = Ch; ChCl = ?(Ch = "{", "}", "]");
			
			// One-char protection: char already processed.
			If StrLen(StrJSON) = 1 Then StrJSON = ""; EndIf;
			
			// Cut Structure.
			StrVal = ""; i = 2;
			InString = False; ItLevel = 1;
			While i <= StrLen(StrJSON) Do
				
				// Get current char.
				Ch = Mid(StrJSON, i , 1);
				
				// Skip all string literals.
				If InString Then
					
					// Process current string.
					If Ch <> """" Then
						// Simple char found.
						
					ElsIf Mid(StrJSON, i - 1 , 1) = "\" Then
						// Escaped quote found.
						
					Else
						// Closing quote found.
						InString = False;
					EndIf;
					
				Else
					// Check string.
					If Ch = """" Then
						// Quote found - string begins.
						InString = True;
						
					ElsIf Ch = ChOp Then
						// Go one level down.
						ItLevel = ItLevel + 1;
						
					ElsIf Ch = ChCl Then
						// Go one level up.
						If ItLevel > 1 Then
							ItLevel = ItLevel - 1;
						Else
							// Closing bracket found.
							StrJSON = Mid(StrJSON, i + 1);
							Break;
						EndIf;
					EndIf;
				EndIf;
				
				// Next iteration.
				StrVal = StrVal + Ch;
				i = i + 1;
			EndDo;
			
			// Set proper value collection.
			If ChOp = "{" Then
				Value = New Structure;
			Else
				Value = New Array;
			EndIf;
			
			// Add value to parent structure.
			If TypeOf(Parent) = Type("Structure") Then
				Parent.Insert(StrID, Value);
			ElsIf TypeOf(Parent) = Type("Array") Then
				Parent.Add(Value);
			ElsIf Parent = Undefined Then
				Parent = Value;
			Else // Unknown parent found.
				Return;
			EndIf;
			
			// Decode descedant structure.
			DecodeJSONStructure(TrimAll(StrVal), Value, TimeShift);
			
		ElsIf Ch = """" Then   // String value found.
			
			// Only one-char left: char already processed.
			If StrLen(StrJSON) = 1 Then StrJSON = ""; EndIf;
			
			// Cut string value.
			StrVal = ""; i = 2;
			While i <= StrLen(StrJSON) Do
				
				// Get current char.
				Ch = Mid(StrJSON, i , 1);
				If Ch <> """" Then
					// Simple char found.
					StrVal = StrVal + Ch;
					
				ElsIf Mid(StrJSON, i - 1 , 1) = "\" Then
					// Escaped quote found.
					StrVal = StrVal + Ch;
					
				Else
					// Closing quote found.
					StrJSON = Mid(StrJSON, i + 1);
					Break;
				EndIf;
				
				// Next iteration.
				i = i + 1;
			EndDo;
			
			// Additional processing of string contents.
			If ConvertValueToPrimitiveType(StrVal, Type("Date"), -TimeShift) Then
				// Succesfully converted.
			ElsIf ConvertValueToPrimitiveType(StrVal, Type("UUID")) Then
				// Succesfully converted.
			Else
				// Convert JSON string to native 1C string.
				StrVal = JSONStrToStr(StrVal);
			EndIf;
			
			// Add value to parent structure.
			If TypeOf(Parent) = Type("Structure") Then
				Parent.Insert(StrID, StrVal);
			ElsIf TypeOf(Parent) = Type("Array") Then
				Parent.Add(StrVal);
			ElsIf Parent = Undefined Then
				Parent = StrVal;
			Else // Unknown parent found.
				Return;
			EndIf;
			
		Else                   // Other type found.
			
			// Cut value.
			StrVal = Ch; i = 2;
			Value = Undefined;
			While i <= StrLen(StrJSON) Do
				
				// Get current char.
				Ch = Mid(StrJSON, i , 1);
				If Find(CharsID+"+-.", Ch) > 0 Then
					// Simple char found.
					StrVal = StrVal + Ch;
					
				Else
					// Other char found. Stop further processing.
					Break;
				EndIf;
				
				// Next iteration.
				i = i + 1;
			EndDo;
			
			// Decode cutted value.
			Value = StrVal;
			If Not ConvertValueToPrimitiveType(Value,, -TimeShift) Then
				// Failed to convert value to any primitive type.
				Return;
			EndIf;
			
			// Adjust value type.
			If Value = Undefined Or Value = Null Then  // Is Empty.
				// Use undefined as empty value.
				Value = Undefined;
				
			ElsIf TypeOf(Value) = Type("Boolean") Then // Is Boolean.
				// OK, skip check.
				
			ElsIf TypeOf(Value) = Type("Number") Then  // Is Number.
				// OK, skip check.
				
			ElsIf TypeOf(Value) = Type("Date") Then    // Is Date/Time.
				// OK, skip check.
				
			ElsIf TypeOf(Value) = Type("UUID") Then    // Is UUID.
				// OK, skip check.
				
			// String type is not allowed without quotes.
			Else                                       // Unknown.
				// Wrong defined type or some unknown value.
				Return;
			EndIf;
			
			// Cut rest of StrJSON.
			StrJSON = Mid(StrJSON, i);
			
			// Add value to parent structure.
			If TypeOf(Parent) = Type("Structure") Then
				Parent.Insert(StrID, Value);
			ElsIf TypeOf(Parent) = Type("Array") Then
				Parent.Add(Value);
			ElsIf Parent = Undefined Then
				Parent = Value;
			Else // Unknown parent found.
				Return;
			EndIf;
		EndIf;
		
		// 4. Get value pair delimiter.
		Pos = Find(StrJSON, ",");
		If Pos = 0 Then
			// Delimiter not found
			Return;
		ElsIf Not IsBlankString(Left(StrJSON, Pos-1)) Then
			// Some garbage found?
			Return;
		Else
			// Cut string to next value pair.
			StrJSON = TrimL(Mid(StrJSON, Pos+1));
		EndIf;
	EndDo;
	
	// Full StrJSON parsed.
	
EndProcedure

// Decodes JSON-compatible string to UTF-16 string according to RFC 4627.
//
// JSON string definition:
// string = quotation-mark *char quotation-mark
// char = unescaped /
//		  escape (
//			%x62 /          ; b    backspace       U+0008
//			%x74 /          ; t    tab             U+0009
//			%x6E /          ; n    line feed       U+000A
//			%x66 /          ; f    form feed       U+000C
//			%x72 /          ; r    carriage return U+000D
//			%x22 /          ; "    quotation mark  U+0022
//			%x2F /          ; /    solidus         U+002F
//			%x5C /          ; \    reverse solidus U+005C
//			%x75 4HEXDIG )  ; uXXXX                U+XXXX
// escape = %x5C            ; \
// quotation-mark = %x22    ; "
// unescaped = %x20-21 / %x23-5B / %x5D-10FFFF
//
// Parameters:
//  Str    - String - JSON-compatible string.
//
// Returns:
//  String - Unicode string.
//
Function JSONStrToStr(Str)
	
	// Define default result.
	Result = String(Str);
	
	// Define escaped characters and their replaces.
	EscChars    = Char(8) + Chars.Tab + Chars.LF + Chars.FF + Chars.CR + """" + "/" + "\";
	EscReplaces = "btnfr""/\";
	HexChar     = "0123456789ABCDEF";
	
	//--------------------------------------------------------------------------
	// 1. Replace JSON defined symbols.
	
	// Encode escaped characters.
	For i = 1 To StrLen(EscChars) Do
		// Get cuurent escaped char.
		EscChar = Mid(EscChars,    i, 1);
		EscRepl = Mid(EscReplaces, i, 1);
		
		// Replace escaped char in current string (the JSON string does not contain the surrogate pairs).
		Result = StrReplace(Result, "\" + EscRepl, EscChar); // Uppercase is not allowed by RFC 4627.
	EndDo;
	
	//--------------------------------------------------------------------------
	// 2. Replace control characters.
	
	// Replace control characters.
	i = 0;  MWCS = New Array();
	While i < StrLen(Result) Do
		// Get current char.
		Char = Mid(Result, i + 1, 1);
		
		// Check backslash character.
		If Char = "\" And Mid(Result, i + 2, 1) = "u" Then // \u char sequence found.
			
			// Agregate unicode string.
			j = 0; MWCS.Clear();
			While i + j < StrLen(Result) Do
				
				// Analize character mask "\uHHHH[\uHHHH[...]]"
				ResChar = Mid(Result, i + j + 1, 1);
				HexCode = Find(HexChar, Upper(ResChar));   // Uppercase of hex digit is allowed by RFC 4627.
				MJ      = j % 6;
				
				// Check out char according to mask index.
				If    MJ = 0 And ResChar = "\" Then                 // "\" char expected.
					// Is control character.
					
				ElsIf MJ = 1 And ResChar = "u" Then                 // "u" char expected
					// Is UTF-16 code.                              // Uppercase is not allowed by RFC 4627.
					
				ElsIf MJ = 2 And ResChar <> "" And HexCode > 0 Then // "H" hex digit expected.
					// Convert high half-byte in high byte.
					CharCode =            4096 * (HexCode - 1);
					
				ElsIf MJ = 3 And ResChar <> "" And HexCode > 0 Then // "H" hex digit expected.
					// Convert low half-byte in high byte.
					CharCode = CharCode +  256 * (HexCode - 1);
					
				ElsIf MJ = 4 And ResChar <> "" And HexCode > 0 Then // "H" hex digit expected.
					// Convert low half-byte in high byte.
					CharCode = CharCode +   16 * (HexCode - 1);
					
				ElsIf MJ = 5 And ResChar <> "" And HexCode > 0 Then // "H" hex digit expected.
					// Convert low half-byte in high byte.
					CharCode = CharCode +    1 * (HexCode - 1);
					
					// Add word to MWCS.
					MWCS.Add(CharCode);
					
				Else // Got some char that we didn't expected.
					Break;
				EndIf;
				
				// Next iteration.
				j = j + 1;
			EndDo;
			
			// Replace found encoded symbols with chars.
			If MWCS.Count() > 0 Then // The UTF-16 sequence found.
				
				// Add UTF-16 character directly to the string,
				// because 1C string is UTF-16BE native string.
				MWCSStr = "";
				For j = 0 To MWCS.UBound() Do
					MWCSStr = MWCSStr + Char(MWCS[j]);
				EndDo;
				MWCSLen = MWCS.Count() * 6; // 6 char per MWC.
				Result  = Left(Result, i) + MWCSStr + Mid(Result, i + MWCSLen + 1);
				
				// Incremet pointer to converted chars length.
				i = i + StrLen(MWCSStr);
				
				// Skip the standard iterator.
				Continue;
				
			EndIf;
		EndIf;
		
		// Next iteration.
		i = i + 1;
	EndDo;
	
	// Return JSON-compatible string.
	Return Result;
	
EndFunction

//------------------------------------------------------------------------------
// Encoding JSON functions

// Encode parameters of primitives and structures into standard JSON string.
// Types encoding:
// - Structures, maps, and value lists are recoded to JSON objects.
// - Arrays are recoded to JSON arrays.
// - Numeric values are encoded using international standard without thousands
//    separators, decimal separator represented by ".", using unar minus as prefix.
// - Date types are encoded in UNIX-time (numeric) or according to ISO 8601 (string).
// - Boolean values as "true" and "false" values.
// - Undefined and Null as "null" value.
// - All other values are encoded as stirngs using their presentation.
//
// Parameters:
//  StructJSON       - ValueList, Structure, Map, Array - Collection of parameters
//                               and typed values or structures.
//  StrJSON          - String  - Resulting filling JSON (also used in recursion).
//  Level            - Number  - Current ident level.
//  UseWideRecord    - Boolean - Use human-readable representation,
//                               otherwise compact internet format will be used.
//  UseISODate       - Boolean - Use ISO 8601 string for encoding the datetime values,
//                               otherwise UNIX-time numeric will be used.
//  UseShortISODate  - Boolean - If date converted to ISO 8601
//                               has only data part without time used,
//                               then it will be saved only as data in short format,
//                               otherwise classic notation for date&time will be used.
//  TimeShift        - Number  - Local time zone correction in seconds for use with UNIX dates
//                               and ISO 8601 dates without time zone specified.
//
// Returns:
//  StrJSON - String - Encoded JSON.
//
Procedure EncodeJSONStructure(StructJSON, StrJSON, Level = 0,
	// Define default encoding parameters.
	UseWideRecord = True, UseISODate = True, UseShortISODate = True, TimeShift = 0);
	
	//--------------------------------------------------------------------------
	// 0. Define parameters.
	
	// Define valid id symbols.
	CharsID = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789";
	CharsDg = "0123456789";
	
	// Define spaces and idents.
	If UseWideRecord Then
		// Use standard spaces and idents.
		CharsIn = "  ";
		CharsSp = " ";
		CharsLf = Chars.LF;
	Else
		// Use compact style minimizing internet traffic.
		CharsIn = "";
		CharsSp = "";
		CharsLf = "";
	EndIf;
	
	//--------------------------------------------------------------------------
	// 1. Open new collection element.
	
	// Define inline objects presence flag.
	ContainsObjects = False;
	
	// Open collection element.
	If TypeOf(StructJSON) = Type("Array") Then        // JSON Array type
		
		// Check inline data types.
		For Each Element In StructJSON Do
			If TypeOf(Element) = Type("Array")
			Or TypeOf(Element) = Type("Map")
			Or TypeOf(Element) = Type("Structure")
			Or TypeOf(Element) = Type("ValueList") Then
				// Substructure found.
				ContainsObjects = True;
				Break;
			EndIf;
		EndDo;
		
		// Insert open bracket in current line.
		StrJSON  = StrJSON + "[";
		
		// For object-type elements add ident for all items.
		If ContainsObjects Then
			StrJSON = StrJSON + CharsLf;
		EndIf;
		
	ElsIf TypeOf(StructJSON) = Type("Map")
	   Or TypeOf(StructJSON) = Type("Structure")
	   Or TypeOf(StructJSON) = Type("ValueList") Then // JSON object type
		
		// Insert open bracket in current line.
		StrJSON  = StrJSON + "{" + CharsLf;
		
	Else
		// Unknown object or collection.
		Return;
	EndIf;
	
	//--------------------------------------------------------------------------
	// 2. Declare element items.
	
	// Increase indent level.
	If CharsIn <> "" Then
		Level  = Level + 1;
		Indent = StringFunctionsClientServer.GenerateCharacterString(CharsIn, Level);
	Else
		Indent = "";
	EndIf;
	
	// Go thru paramters collection and add keys and values to JSON string.
	BeginningElement = True;
	For Each Element In StructJSON Do
		
		// Define current key and value in collection.
		If TypeOf(StructJSON) = Type("Array") Then
			// Use array elements.
			KeyStr = ""; // Key is not defined
			Value  = Element;
			
		ElsIf TypeOf(StructJSON) = Type("Map")
		   Or TypeOf(StructJSON) = Type("Structure") Then
			// Use key and value fields.
			KeyStr = Element.Key;
			Value  = Element.Value;
			
		ElsIf TypeOf(StructJSON) = Type("ValueList") Then
			// Use presentation and value fields.
			KeyStr = Element.Presentation;
			Value  = Element.Value;
		EndIf;
		
		// Generate object name (for objects structures).
		If KeyStr <> "" Then
			
			// Convert key to JSON name.
			KeyStr = StrReplace(TrimAll(KeyStr), " ", "_");
			Name   = "";
			For i = 1 To StrLen(KeyStr) Do
				Ch = Mid(KeyStr, i, 1);
				If Find(CharsID, Ch) > 0 Then
					Name = Name + Ch;
				EndIf;
			EndDo;
			
			// Check ID conformation.
			If Name = ""                        // No valid characters found
			Or Find(CharsDg, Left(Name, 1)) > 0 // ID begins from a digit
			Then
			    // Skip current key.
				Continue;
			EndIf;
			
			// Add elements delimiter for all elements except beginning one.
			If Not BeginningElement Then
				StrJSON = StrJSON + "," + CharsLf;
			EndIf;
			
			// Add ident, current name, name delimiter, and value ident.
			StrJSON = StrJSON + Indent + """" + Name + """" + ":" + CharsSp;
			
		Else // Generate current ident for array elements.
			
			// For object-type elements add ident for all items.
			If ContainsObjects Then
				
				// Add elements delimiter for all elements except beginning one.
				If Not BeginningElement Then
					StrJSON = StrJSON + "," + CharsLf;
				EndIf;
				
				// Add current element ident.
				StrJSON = StrJSON + Indent;
				
			// For primitive-type elements - add ident for beginning item only.
			Else
				// Add elements delimiter for all elements except beginning one.
				If Not BeginningElement Then
					StrJSON = StrJSON + "," + CharsSp;
				EndIf;
			EndIf;
		EndIf;
		
		// Clear beginning flag.
		If BeginningElement Then
			BeginningElement = False;
		EndIf;
		
		// Add formatted value.
		If Value = Undefined or Value = Null Then
			StrJSON = StrJSON + "null";
			
		ElsIf TypeOf(Value) = Type("Array")
		   Or TypeOf(Value) = Type("Map")
		   Or TypeOf(Value) = Type("Structure")
		   Or TypeOf(Value) = Type("ValueList")
		   Then
			// Run the procedure recursively for all child elements.
			EncodeJSONStructure(Value, StrJSON, Level,
				UseWideRecord, UseISODate, UseShortISODate, TimeShift);
			
		ElsIf TypeOf(Value) = Type("Boolean") Then
			StrJSON = StrJSON + Format(Value, "BF=false; BT=true");
			
		ElsIf TypeOf(Value) = Type("Number") Then
			StrJSON = StrJSON + Format(Value, "NDS=.; NZ=0; NG=");
			
		ElsIf TypeOf(Value) = Type("Date") Then
			If UseISODate Then
				// Use ISO 8601 string for encoding the date.
				If UseShortISODate And (BegOfDay(Value) = Value) Then
					// Use short date format.
					StrJSON = StrJSON + """" + Format(Value, "DF=yyyy-MM-dd") + """";
					
				Else // Use full date & time format.
					
					// Calculate time zone difference in seconds.
					CurrentDate   = CurrentDate();
					LocalTimeZone = CurrentDate - ToUniversalTime(CurrentDate);
					
					// Define time zone presentation.
					TimeZoneHrs = Int( ?(LocalTimeZone < 0, -1, 1) * LocalTimeZone / 3600);                     // Time zone hours.
					TimeZoneMin = Int((?(LocalTimeZone < 0, -1, 1) * LocalTimeZone - TimeZoneHrs * 3600) / 60); // Time zone minutes.
					TimeZoneStr = ?(LocalTimeZone = 0, "Z",
					              ?(LocalTimeZone > 0, "+", "-") + Format(TimeZoneHrs, "ND=2; NFD=0; NLZ=") +
					                      ?(TimeZoneMin > 0, ":" + Format(TimeZoneMin, "ND=2; NFD=0; NLZ="), ""));
					
					// Use ISO 8601 string for encoding the date.
					StrJSON = StrJSON + """" + Format(Value, "DF=yyyy-MM-ddTHH:mm:ss") + TimeZoneStr + """";
				EndIf;
				
			Else
				// Use UNIX-time numeric for encoding the date.
				StrJSON = StrJSON + Format(Value - Date("19700101") + TimeShift, "NFD=0; NZ=0; NG=");
			EndIf;
			
		Else // As string.
			If TypeOf(Value) = Type("Array") Or TypeOf(Value) = Type("String") Then
				StrJSON = StrJSON + """" + StrToJSONStr(Value) + """"; 
			Else
				StrJSON = StrJSON + """" + StrToJSONStr(String(Value)) + """"; 
			EndIf;
		EndIf;
	EndDo;
	
	//--------------------------------------------------------------------------
	// 3. Close current collection.
	
	// Decrease indent level.
	If CharsIn <> "" Then
		// Restore previous level
		Level  = Level - 1;
		Indent = StringFunctionsClientServer.GenerateCharacterString(CharsIn, Level);
	EndIf;
	
	// Open collection element.
	If TypeOf(StructJSON) = Type("Array") Then        // JSON Array type
		
		// For object-type elements add ident for all items.
		If ContainsObjects Then
			// Close current line.
			StrJSON = StrJSON + CharsLf;
			
			// Add new line indent.
			StrJSON = StrJSON + Indent;
		EndIf;
		
		// Insert close bracket in current line.
		StrJSON  = StrJSON + "]";
		
	ElsIf TypeOf(StructJSON) = Type("Map")
	   Or TypeOf(StructJSON) = Type("Structure")
	   Or TypeOf(StructJSON) = Type("ValueList") Then // JSON object type
		
		// Close current line.
		StrJSON = StrJSON + CharsLf;
		
		// Insert indent, and close bracket in current line.
		StrJSON  = StrJSON + Indent + "}";
		
	Else
		// Unknown object or collection.
		Return;
	EndIf;
	
	// Finished encoding JSON string.
	// StrJSON is returning value.
	
EndProcedure

// Encodes UTF-16 string to JSON-compatible string according to RFC 4627.
//
// JSON string definition:
// string = quotation-mark *char quotation-mark
// char = unescaped /
//		  escape (
//			%x62 /          ; b    backspace       U+0008
//			%x74 /          ; t    tab             U+0009
//			%x6E /          ; n    line feed       U+000A
//			%x66 /          ; f    form feed       U+000C
//			%x72 /          ; r    carriage return U+000D
//			%x22 /          ; "    quotation mark  U+0022
//			%x2F /          ; /    solidus         U+002F
//			%x5C /          ; \    reverse solidus U+005C
//			%x75 4HEXDIG )  ; uXXXX                U+XXXX
// escape = %x5C            ; \
// quotation-mark = %x22    ; "
// unescaped = %x20-21 / %x23-5B / %x5D-10FFFF
//
// Parameters:
//  Str    - String - Native 1C string.
//
// Returns:
//  String - JSON-compatible string.
//
Function StrToJSONStr(Str)
	
	// Define default result.
	UnicodeStr = UTF16ToUnicode(Str, True);
	
	// Define escaped characters and their replaces.
	EscChars    = Char(8) + Chars.Tab + Chars.LF + Chars.FF + Chars.CR + """" + "/" + "\";
	EscReplaces = "btnfr""/\";
	EscCharsLen = StrLen(EscChars);
	HexChar     = "0123456789ABCDEF";
	
	//--------------------------------------------------------------------------
	// 1. Replace escaped symbols.
	
	// Encode escaped characters.
	For i = 0 To EscCharsLen - 1 Do
		// Get cuurent escaped char.
		EscChar = Mid(EscChars,    EscCharsLen - i, 1);
		EscRepl = Mid(EscReplaces, EscCharsLen - i, 1);
		
		// Replace escaped char in current string.
		j = UnicodeStr.UBound();
		While j >= 0 Do
			
			// Check char escaped.
			If UnicodeStr[j] = CharCode(EscChar) Then
				// Replace escaped character.
				UnicodeStr[j] =        CharCode("\");      //  ESC character
				UnicodeStr.Insert(j+1, CharCode(EscRepl)); // Replace character
			EndIf;
			
			// Next iteration.
			j = j - 1;
		EndDo;
	EndDo;
	
	//--------------------------------------------------------------------------
	// 2. Replace control and high-unicode characters.
	
	// Replace control and high unicode characters.
	i = UnicodeStr.UBound(); MWC = New Array(1);
	While i >= 0 Do
		// Get current character code.
		Code = UnicodeStr[i];
		
		// Check control character.
		If Code < 32 Then         // 0000.0000 .. 0000.001F
			// Define escaped character presentation.
			UChar = "\u00" + Mid(HexChar, Int(Code / 16) + 1, 1) + Mid(HexChar, (Code % 16) + 1, 1);
			
			// Replace escaped character.
			UnicodeStr[i] =            CharCode("\");                 // ESC character
			For j = 2 To StrLen(UChar) Do
				UnicodeStr.Insert(i+j-1, CharCode(Mid(UChar, j, 1))); // Replace character
			EndDo;
			
		ElsIf Code < 65536 Then   // 0000.0020 .. 0000.FFFF
			// The code is in the basic multilingual plane (BMP).
			
		ElsIf Code < 1114112 Then // 0001.0000 .. 0010.FFFF
			// SMP, SIP, TIP, SSP or private area code.
			MWC[0] = Code;
			
			// Encode symbol to UTF-16.
			UTF16  = UnicodeToUTF16(MWC, True, True);
			
			// Encode UTF-16 string to control string representation.
			UChar = "";
			For j = 0 To UTF16.Ubound() Do
				HByte = Int(UTF16[j] / 256);
				LByte =    (UTF16[j] % 256);
				UChar = UChar + "\u" + Mid(HexChar, Int(HByte / 16) + 1, 1) + Mid(HexChar, (HByte % 16) + 1, 1)
				                     + Mid(HexChar, Int(LByte / 16) + 1, 1) + Mid(HexChar, (LByte % 16) + 1, 1);
			EndDo;
			
			// Replace escaped character.
			UnicodeStr[i] =            CharCode("\");                 // ESC character
			For j = 2 To StrLen(UChar) Do
				UnicodeStr.Insert(i+j-1, CharCode(Mid(UChar, j, 1))); // Replace character
			EndDo;
			
		Else
			// Not a valid unicode char - cut symbol.
			UnicodeStr.Delete(i);
		EndIf;
		
		// Next iteration.
		i = i - 1;
	EndDo;
	
	// Return JSON-compatible string.
	Return UnicodeToUTF16(UnicodeStr);
	
EndFunction

//------------------------------------------------------------------------------
// Universal conversation functions

// Fills the date format variables and calculates local time adjustment in seconds.
//
// Parameters:
//  DateEncodingFormat       - Structure - describing encoding format of passed dates.
//                             URL settings - structure with the following fields:
//   UseISODate              - Boolean - Use ISO 8601 string for encoding the datetime values,
//                             otherwise UNIX-time numeric will be used.
//   UseShortISODate         - Boolean - If date converted to ISO 8601
//                             has only data part without time used,
//                             then it will be saved only as data in short format,
//                             otherwise classic notation for date&time will be used.
//   UseLocalDate            - Boolean - If true then local date will be used without changes,
//                             otherwise date will be adjusted to UTC time zone.
//                             Number - -12 .. 0 .. 12 - Destination time zone in hours,
//                             the date should be encoded to - the difference between the time
//                             zone of local date and time zone of remote host will be adjusted.
//                             This setting does not affect fully encoded ISO 8601 dates.
//
// Returns:
//  UseISODate               - Boolean - Use ISO 8601 string for encoding the datetime values,
//                             otherwise UNIX-time numeric will be used.
//  UseShortISODate          - Boolean - If date converted to ISO 8601
//                             has only data part without time used,
//                             then it will be saved only as data in short format,
//                             otherwise classic notation for date&time will be used.
//  TimeShift       - Number - Local time zone correction in seconds for use with UNIX dates
//                             and ISO 8601 dates without time zone specified.
//
Procedure DecodeDateParameters(DateEncodingFormat,
	UseISODate = Undefined, UseShortISODate = Undefined, TimeShift = Undefined)
	
	// Define local date format variables.
	Var ISODate, ShortISODate, LocalDate;
	
	// Define date format constants values.
	UseISODate      = True; // The following default date format will be used:
	UseShortISODate = True; // YYYY-MM-DD
	UseLocalDate    = True; // The local date will be used (no time zone adjustment applied).
	
	// Update date format with passed parameters
	If TypeOf(DateEncodingFormat) = Type("Structure") Then
		If DateEncodingFormat.Property("UseISODate",      ISODate)      And (ISODate      <> Undefined) Then UseISODate      = ISODate;      EndIf;
		If DateEncodingFormat.Property("UseShortISODate", ShortISODate) And (ShortISODate <> Undefined) Then UseShortISODate = ShortISODate; EndIf;
		If DateEncodingFormat.Property("UseLocalDate",    LocalDate)    And (LocalDate    <> Undefined) Then UseLocalDate    = LocalDate;    EndIf;
	EndIf;
	
	// Calculate time zone difference.
	CurrentDate   = CurrentDate();
	LocalTimeZone = CurrentDate - ToUniversalTime(CurrentDate);
	
	// UNIX date adjustment & ISO date without time zone specification.
	If    UseLocalDate = True Then                   // Local time zone: no time zone adjustment required.
		TimeShift = 0; 
	ElsIf UseLocalDate = False Then                  // UTC time zone: use local time zone as adjustment value.
		TimeShift = 0 - LocalTimeZone;
	ElsIf TypeOf(UseLocalDate) = Type("Number") Then // Convert local time to the specified time zone.
		TimeShift = UseLocalDate * 3600 - LocalTimeZone;
	EndIf;
	
EndProcedure

// Converts passed value to desired primitive type.
// Supports automatic value conversion (if Type is not specified).
// If conversion fails, then value remains unchanged.
//
// Parameters:
//  Value     - Arbitrary - Value to be converted to primitive type.
//  Type      - Type      - Primitive type for value to be converted to.
//  TimeShift - Number    - Time shift for adjusting the dates,
//                          used if time zone was not specified.
//
// Returns:
//  Boolean   - Conversation succession flag.
//  Value     - Arbitrary - Converted (succeded) or unchanged (failed) value.
//
Function ConvertValueToPrimitiveType(Value, Type = Undefined, TimeShift = 0)
	
	// Try to convert passed value to desired type.
	Try
		// Auto conversion.
		If Type = Undefined Then
			
			// Check existing type
			If Value = Null
			Or Value = Undefined
			Or TypeOf(Value) = Type("Boolean")
			Or TypeOf(Value) = Type("UUID")
			Or TypeOf(Value) = Type("Date")
			Or TypeOf(Value) = Type("Number")
			// Except of String.
			Then
				// Value already has a primitive type.
				// No additional conversation needed.
				Return True;
			EndIf;
			
			// Try step-by-step convert string to primitive types.
			If Upper(TrimAll(Value)) = "NULL" Then
				// Passed null value.
				Value = Null;
				Return True;
				
			ElsIf Upper(TrimAll(Value)) = "UNDEFINED" Then
				// Passed undefined value.
				Value = Undefined;
				Return True;
				
			ElsIf ConvertValueToPrimitiveType(Value, Type("Boolean")) Then
				// Succesfully converted.
			ElsIf ConvertValueToPrimitiveType(Value, Type("UUID")) Then
				// Succesfully converted.
			ElsIf ConvertValueToPrimitiveType(Value, Type("Date"), TimeShift) Then
				// Succesfully converted.
			ElsIf ConvertValueToPrimitiveType(Value, Type("Number"), TimeShift) Then
				// Succesfully converted.
			ElsIf ConvertValueToPrimitiveType(Value, Type("String")) Then
				// Succesfully converted.
			Else
				// Failed to convert to any primitive type.
				Return False;
			EndIf;
			
		ElsIf Type = Type("Boolean") Then
			Value = Boolean(Value);
			
		ElsIf Type = Type("Number") Then
			
			// Define native numeric format.
			If TypeOf(Value) = Type("Number") Then
				// No additional conversion required.
				
			// Define conversion from string format.
			ElsIf TypeOf(Value) = Type("String") Then
				// Define numeric characters.
				Numeric = "0123456789eE+-.";
				SNumber = ""; // Numeric part.
				SExpont = ""; // Exponent part.
				SOption = 1;  // Numeric or Exponent option: 1 or 2.
				
				// Check string contains only digits.
				For i = 1 To StrLen(Value) Do
					// Define current char.
					Ch = Mid(Value, i, 1);
					
					// Check char passes numeric chars.
					If Find(Numeric, Ch) = 0 Then
						Raise(NStr("en = 'Invalid char found in numeric string.'"));
						
					ElsIf (SOption = 1) And (Ch = "e" Or Ch = "E") Then
						// Switch to exponent part.
						SOption = 2;
					
					ElsIf (SOption = 2) And (Ch = "e" Or Ch = "E") Then
						Raise(NStr("en = 'Exponent part doubled in the number.'"));
						
					ElsIf (SOption = 1) And (Ch = "+" Or Ch = "-") And (i > 1) Then
						Raise(NStr("en = 'Sign can not be defined in the middle of numeric part.'"));
						
					ElsIf (SOption = 2) And (Ch = "+" Or Ch = "-") And (Not IsBlankString(SExpont)) Then
						Raise(NStr("en = 'Sign can not be defined in the middle of exponent part.'"));
						
					ElsIf (SOption = 1) Then
						// Assign char to numeric part.
						SNumber = SNumber + Ch;
						
					ElsIf (SOption = 2) Then
						// Assign char to exponent part.
						SExpont = SExpont + Ch;
					EndIf;
				EndDo;
				
				// Convert number string to number.
				Value = Number(SNumber);
				
				// Convert exponent string to number.
				If Not IsBlankString(SExpont) Then // Exponent defined.
					Exponent = Number(SExpont);
					
					// Update number value.
					Value = Value * Pow(10, Exponent);
				EndIf;
				
				// Custom conversion for UNIX date.
				If  Value > 31500000       // > 31.12.1970 14:00:00
				And Find(SNumber, ".") = 0 // Is integer.
				And IsBlankString(SExpont) // No exponent part defined.
				Then
					// Suggest it is a UNIX time format.
					Value = Date("19700101") + Value + TimeShift;
				EndIf;
				
			// Define conversion from any other (boolean) format.
			Else
				Value = Number(Value);
			EndIf;
			
		ElsIf Type = Type("UUID") Then
			Value = New UUID(Value);
			
		ElsIf Type = Type("Date") Then
			
			// Define native date format.
			If TypeOf(Value) = Type("Date") Then
				// No additional conversion required.
				
			// Define Number to Date conversion.
			ElsIf TypeOf(Value) = Type("Number") Then
				// Convert from UNIX date to 1C date.
				Value = Date("19700101") + Value + TimeShift;
				
			// Define String to Date conversion.
			ElsIf TypeOf(Value) = Type("String") Then
				// Try to convert value from internet format ISO 8601 (converting time zone difference).
				// 1) YYYYMMDD[[T]hhmmss[ss[s]][Z|±HH[mm]]]
				// 2) YYYY[-|/]MM[-|/]DD[Thh:mm:ss[.ss[s]][Z|±HH[:mm]]]
				
				// Skip overlong strings.
				If StrLen(Value) > 29 Then
					Raise(NStr("en = 'Size of date value exeeds maximum available length.'"));
				EndIf;
				
				// Define digits characters.
				Digits = "0123456789";
				
				// Check/process passed value.
				SDate = "";  // Date in string native format.
				SZone = "";  // Time zone in string format.
				SOption = 0; // Datetime format option 1 or 2.
				
				// Define first steps.
				Step1 = 4;         // 4
				Step2 = Step1 + 1; // 5
				For i = 1 To StrLen(Value) Do
					// Define current char.
					Ch = Mid(Value, i, 1);
					
					// Step 1.
					If i <= Step1 Then
						// YYYY in [0123456789]
						If Find(Digits, Ch) > 0 Then
							SDate = SDate + Ch;
						Else
							Raise(NStr("en = 'Wrong date format.'"));
						EndIf;
						
					// Step 2.
					ElsIf i = Step2 Then
						// Check date option.
						If Ch = "-" Or Ch = "/" Then
							// YYYY[-|/], skip char.
							SOption = 2;
							// Define next step constants.
							Step3 = Step2 + 2; // 7
							Step4 = Step3 + 1; // 8
							
						ElsIf Find(Digits, Ch) > 0 Then
							// M in [0123456789]
							SDate = SDate + Ch;
							// YYYYM
							SOption = 1;
							// Define next step constants.
							Step3 = Step2 + 1; // 6
							Step4 = Step3 + 1; // 7
							
						Else
							Raise(NStr("en = 'Wrong date format.'"));
						EndIf;
						
					// Step 3.
					ElsIf i <= Step3 Then
						// MM in [0123456789]
						If Find(Digits, Ch) > 0 Then
							SDate = SDate + Ch;
						Else
							Raise(NStr("en = 'Wrong date format.'"));
						EndIf;
						
					// Step 4.
					ElsIf i = Step4 Then
						If SOption = 2 Then
							If Ch = "-" Or Ch = "/" Then
								// YYYY[-|/]MM[-|/], skip char.
								// Define next step constants.
								Step5 = Step4 + 2; // 10
								Step6 = Step5 + 1; // 11
							Else
								Raise(NStr("en = 'Wrong date format.'"));
							EndIf;
							
						Else // SOption = 1.
							If Find(Digits, Ch) > 0 Then
								// D in [0123456789]
								SDate = SDate + Ch;
								// YYYYMMD
								// Define next step constants.
								Step5 = Step4 + 1; // 8
								Step6 = Step5 + 1; // 9
							Else
								Raise(NStr("en = 'Wrong date format.'"));
							EndIf;
						EndIf;
						
					// Step 5.
					ElsIf i <= Step5 Then
						// MM in [0123456789]
						If Find(Digits, Ch) > 0 Then
							SDate = SDate + Ch;
						Else
							Raise(NStr("en = 'Wrong date format.'"));
						EndIf;
						
					// Step 6.
					ElsIf i = Step6 Then
						If Ch = "T" Or Ch = " " Then
							If SOption = 2 Then
								// 2) YYYY[-|/]MM[-|/]DDT
								// Define next step constants.
								Step7 = Step6 + 2; // 13
								Step8 = Step7 + 1; // 14
								
							ElsIf SOption = 1 Then
								// 1) YYYYMMDD[T]
								// Define next step constants.
								Step7 = Step6 + 2; // 11
								Step8 = Step7 + 1; // 12
							EndIf;
							
						ElsIf Find(Digits, Ch) > 0 Then
							If SOption = 1 Then
								// 1) YYYYMMDDh
								SDate = SDate + Ch;
								// Define next step constants.
								Step7 = Step6 + 1; // 10
								Step8 = Step7 + 1; // 11
							Else
								Raise(NStr("en = 'Wrong date format.'"));
							EndIf;
						EndIf;
					
					// Step 7.
					ElsIf i <= Step7 Then
						// hh in [0123456789]
						If Find(Digits, Ch) > 0 Then
							SDate = SDate + Ch;
						Else
							Raise(NStr("en = 'Wrong time format.'"));
						EndIf;
						
					// Step 8.
					ElsIf i = Step8 Then
						If SOption = 2 Then
							If Ch = ":" Then
								// YYYY[-|/]MM[-|/]DDThh:, skip char.
								// Define next step constants.
								Step9 = Step8 + 2; // 16
								StepA = Step9 + 1; // 17
							Else
								Raise(NStr("en = 'Wrong time format.'"));
							EndIf;
							
						Else // SOption = 1.
							If Find(Digits, Ch) > 0 Then
								// m in [0123456789]
								SDate = SDate + Ch;
								// YYYYMMDD[T]hhm
								// Define next step constants.
								Step9 = Step8 + 1; // 12/13
								StepA = Step9 + 1; // 13/14
							Else
								Raise(NStr("en = 'Wrong time format.'"));
							EndIf;
						EndIf;
						
					// Step 9.
					ElsIf i <= Step9 Then
						// mm in [0123456789]
						If Find(Digits, Ch) > 0 Then
							SDate = SDate + Ch;
						Else
							Raise(NStr("en = 'Wrong time format.'"));
						EndIf;
						
					// Step 10.
					ElsIf i = StepA Then
						If SOption = 2 Then
							If Ch = ":" Then
								// YYYY[-|/]MM[-|/]DDThh:mm:, skip char.
								// Define next step constants.
								StepB = StepA + 2; // 19
								StepC = StepB + 1; // 20
							Else
								Raise(NStr("en = 'Wrong time format.'"));
							EndIf;
							
						Else // SOption = 1.
							If Find(Digits, Ch) > 0 Then
								// s in [0123456789]
								SDate = SDate + Ch;
								// YYYYMMDD[T]hhmms
								// Define next step constants.
								StepB = StepA + 1; // 14/15
								StepC = StepB + 1; // 15/16
							Else
								Raise(NStr("en = 'Wrong time format.'"));
							EndIf;
						EndIf;
						
					// Step 11.
					ElsIf i <= StepB Then
						// ss in [0123456789]
						If Find(Digits, Ch) > 0 Then
							SDate = SDate + Ch;
						Else
							Raise(NStr("en = 'Wrong time format.'"));
						EndIf;
						
					// Step 12.
					ElsIf i = StepC Then
						If SOption = 2 Then
							If Ch = "." Then
								// YYYY[-|/]MM[-|/]DDThh:mm:ss., skip char.
								// Define next step constants.
								StepD = StepC + 2; // 22
								StepE = StepD + 1; // 23
								// Next steps not yet defined.
							ElsIf Ch = "+" Or Ch = "-" Then
								// YYYY[-|/]MM[-|/]DDThh:mm:ss[+|-]
								StepD = StepC;     // Skip step
								StepE = StepD;     // Skip step
								StepF = StepE;     // Skip step
								StepG = StepF + 2; // 22
								StepH = StepG + 1; // 23
								// Next steps not yet defined.
								// [+|-]
								SZone = SZone + Ch;
							ElsIf Ch = "Z" Then
								// YYYY[-|/]MM[-|/]DDThh:mm:ssZ, skip char.
								StepD = StepC;     // Skip step
								StepE = StepD;     // Skip step
								StepF = StepE;     // Skip step
								StepG = StepF;     // Skip step
								StepH = StepG;     // Skip step
								StepI = StepH;     // Skip step
								StepJ = StepI + 1; // 21
							Else
								Raise(NStr("en = 'Wrong time format.'"));
							EndIf;
							
						Else // SOption = 1.
							If Find(Digits, Ch) > 0 Then
								// s in [0123456789], skip char.
								// YYYYMMDD[T]hhmmsss
								// Define next step constants.
								StepD = StepC + 1; // 16/17
								StepE = StepD + 1; // 17/18
								// Next steps not yet defined.
							ElsIf Ch = "+" Or Ch = "-" Then
								// YYYYMMDD[T]hhmmss[+|-]
								StepD = StepC;     // Skip step
								StepE = StepD;     // Skip step
								StepF = StepE;     // Skip step
								StepG = StepF + 2; // 17/18
								StepH = StepG + 1; // 18/19
								// Next steps not yet defined.
								// [+|-]
								SZone = SZone + Ch;
							ElsIf Ch = "Z" Then
								// YYYYMMDD[T]hhmmssZ, skip char.
								StepD = StepC;     // Skip step
								StepE = StepD;     // Skip step
								StepF = StepE;     // Skip step
								StepG = StepF;     // Skip step
								StepH = StepG;     // Skip step
								StepI = StepH;     // Skip step
								StepJ = StepI + 1; // 16/17
							Else
								Raise(NStr("en = 'Wrong time format.'"));
							EndIf;
						EndIf;
						
					// Step 13.
					ElsIf i <= StepD Then
						If SOption = 2 Then
							// YYYY[-|/]MM[-|/]DDThh:mm:ss.ss, skip char.
						Else // SOption = 1.
							// YYYYMMDD[T]hhmmssss, skip char.
						EndIf;
					
					// Step 14.
					ElsIf i = StepE Then
						If Find(Digits, Ch) > 0 Then
							// YYYY[-|/]MM[-|/]DDThh:mm:ss.sss, skip char.
							// YYYYMMDD[T]hhmmsssss, skip char.
							// Define next step constants.
							StepF = StepE + 1; // 1) 24 2) 18/19
							// Next steps not yet defined.
						ElsIf Ch = "+" Or Ch = "-" Then
							// YYYY[-|/]MM[-|/]DDThh:mm:ss.ss[+|-]
							// YYYYMMDD[T]hhmmssss[+|-]
							StepF = StepE;     // Skip step
							StepG = StepF + 2; // 1) 25 2) 19/20
							StepH = StepG + 1; // 1) 26 3) 20/21
							// Next steps not yet defined.
							// [+|-]
							SZone = SZone + Ch;
						ElsIf Ch = "Z" Then
							// YYYY[-|/]MM[-|/]DDThh:mm:ss.ssZ, skip char.
							// YYYYMMDD[T]hhmmssssZ, skip char.
							StepF = StepE;     // Skip step
							StepG = StepF;     // Skip step
							StepH = StepG;     // Skip step
							StepI = StepH;     // Skip step
							StepJ = StepI + 1; // 1) 24 2) 18/19
						Else
							Raise(NStr("en = 'Wrong time format.'"));
						EndIf;
					
					// Step 15.
					ElsIf i = StepF Then
						If Ch = "+" Or Ch = "-" Then
							// YYYY[-|/]MM[-|/]DDThh:mm:ss.sss[+|-]
							// YYYYMMDD[T]hhmmsssss[+|-]
							StepG = StepF + 2; // 1) 26 2) 20/21
							StepH = StepG + 1; // 1) 27 2) 21/22
							// [+|-]
							SZone = SZone + Ch;
						ElsIf Ch = "Z" Then
							// YYYY[-|/]MM[-|/]DDThh:mm:ss.sssZ, skip char.
							// YYYYMMDD[T]hhmmsssssZ, skip char.
							StepG = StepF;     // Skip step
							StepH = StepG;     // Skip step
							StepI = StepH;     // Skip step
							StepJ = StepI + 1; // 1) 25 2) 19/20
						Else
							Raise(NStr("en = 'Wrong time zone format.'"));
						EndIf;
						
					// Step 16.
					ElsIf i <= StepG Then
						// hh in [0123456789]
						If Find(Digits, Ch) > 0 Then
							SZone = SZone + Ch;
						Else
							Raise(NStr("en = 'Wrong time zone format.'"));
						EndIf;
						
					// Step 17.
					ElsIf i = StepH Then
						If SOption = 2 Then
							If Ch = ":" Then
								// YYYY[-|/]MM[-|/]DDThh:mm:ss[.ss[s]][+|-]hh:, skip char.
								// Define next step constants.
								StepI = StepH + 2; // 29
								StepJ = StepI + 1; // 30
							Else
								Raise(NStr("en = 'Wrong time zone format.'"));
							EndIf;
							
						Else // SOption = 1.
							If Find(Digits, Ch) > 0 Then
								// m in [0123456789]
								SZone = SZone + Ch;
								// YYYYMMDD[T]hhmmss[ss[s]][+|-]hhm
								// Define next step constants.
								StepI = StepH + 1; // 22/23
								StepJ = StepI + 1; // 23/24
							Else
								Raise(NStr("en = 'Wrong time zone format.'"));
							EndIf;
						EndIf;
						
					// Step 18.
					ElsIf i <= StepI Then
						// mm in [0123456789]
						If Find(Digits, Ch) > 0 Then
							SZone = SZone + Ch;
						Else
							Raise(NStr("en = 'Wrong time zone format.'"));
						EndIf;
						
					// Step 19.
					ElsIf i = StepJ Then
						// YYYY[-|/]MM[-|/]DDThh:mm:ss[.ss[s]][Z|[+|-]hh:[mm]]?
						// YYYYMMDD[T]hhmmss[ss[s]][Z|[+|-]hh[mm]]?
						Raise(NStr("en = 'Wrong date format.'"));
						
					// Step unknown.
					Else
						Raise(NStr("en = 'Wrong date format.'"));
					EndIf;
				EndDo;
				
				// Convert simplified datetime string to primitive date.
				SourceDate = Date(SDate); // "YYYYMMDDhhmmss"
				
				// Adjust date from source to universal UTC time [+|-]hh[:mm] (if specified)
				If (Not IsBlankString(SZone)) Or (Find(Value, "Z") > 0) Then // UTC date specified
					TimeZoneCorrection = Number(Left(SZone, 1)+"1") * (Number("0"+Mid(SZone, 2, 2))*3600 + Number("0"+Mid(SZone, 4, 2))*60);
					
					// Convert local date & UTC offset to universal date (UTC = 0).
					UTCDate = SourceDate - TimeZoneCorrection;
					
					// Convert UTC date to local date with current server/client UTC correction.
					Value = ToLocalTime(UTCDate);
				Else
					// Check whether it is a date-only or date-time.
					If StrLen(SDate) = 8 Then // "YYYYMMDD"
						// Use short date format.
						Value = SourceDate;
					Else
						// Use full datetime format and apply the time shift.
						Value = SourceDate + TimeShift;
					EndIf;
				EndIf;
				
			// Define conversion from any other format.
			Else
				Value = Date(Value);
			EndIf;
			
		ElsIf Type = Type("String") Then
			Value = String(Value);
			
		Else // Uknown type.
			Return False;
		EndIf;
		
		// Conversion succeeded.
		Return True;
	Except
		// Conversion failed.
		Return False;
	EndTry;
	
EndFunction

// Decodes UTF-16 string to native unicode string.
//
// Parameters:
//  UTF16     - String    - String of UTF-16 characters codes.
//            - Array     - Array of UTF-16 characters words.
//  AsArray   - Boolean   - Function must return unicode characters as an array
//                          (otherwise returns string of char-dwords).
//  ByteOrder - Boolean   - True  = Big endian UTF-16BE (High byte, Low byte).
//                        - False = Low endian UTF-16LE (Low byte, high byte).
//            - Undefined - UTF-16: Use byte order autodetection
//                          (prefferably UTF-16BE).
// Returns:
//  String - Decoded unicode string.
//  Array  - Decoded unicode characters.
//
Function UTF16ToUnicode(UTF16, AsArray = False, ByteOrder = Undefined)
	
	// Define empty result.
	If AsArray Then
		Result = New Array;
	Else
		Result = "";
	EndIf;
	
	// Define default exception description.
	ErrorDescription = NStr("en = 'UTF-16 string format error occured'");
	
	// Define source string parameters.
	If TypeOf(UTF16) = Type("Array") Then
		
		// Use passed multy-words characters array directly.
		MWCS = UTF16;
		
	ElsIf TypeOf(UTF16) = Type("String") Then
		
		// Create multy-words characters array.
		If StrLen(UTF16) > 0 Then
			MWCS = New Array(StrLen(UTF16));
			For i = 1 To StrLen(UTF16) Do
				MWCS[i-1] = CharCode(UTF16, i);
			EndDo;
		Else
			// Return empty result.
			Return Result;
		EndIf;
		
	Else
		// Unknown passed type.
		Return Result;
	EndIf;
	
	// Step by step convertion of UTF-16 MWCS.
	Try
		i = 0; MWC = New Array;
		While i < MWCS.Count() Do
			
			// Get first word according to the byte order.
			If (ByteOrder = Undefined) Or (ByteOrder) Then
				// High-endian (plain) byte order.
				Word = MWCS[i];
				
			Else // ByteOrder = False
				// Low-endian (reverse) byte order.
				LB = Int(MWCS[i] / 256);
				HB = MWCS[i] % 256;
				Word = HB * 256 + LB;
			EndIf;
			
			// Define char size.
			If Word < 0 Then
				// Error: Character code can't be signed int.
				If AsArray Then
					Return New Array;
				Else
					Return "";
				EndIf;
				
			ElsIf Word < 55296   Then    // 0000 .. D7FF
				// Decode basic multilingual plane char = 16 bits.
				// xxxx -> xxxx.xxxx xxxx.xxxx -> xxxx
				
				// Add word.
				If AsArray Then
					Result.Add(Word);    // Basic code.
				Else
					Result = Result + Char(Word); // Basic char.
				EndIf;
				i = i + 1;
				
			ElsIf Word < 56320   Then    // D800 .. DBFF
				// High surrogate pair.
				
				// Check MWC length.
				If i + 1 > MWCS.Count() Then
					// This is not valid MCW length,
					// read beyond the end of MCBS array.
					If AsArray Then
						Return New Array;
					Else
						Return "";
					EndIf;
				EndIf;
				
				// Get second word according to the byte order.
				If (ByteOrder = Undefined) Or (ByteOrder) Then
					// High-endian (plain) byte order.
					Wrd2 = MWCS[i + 1];
					
				Else // ByteOrder = False
					// Low-endian (reverse) byte order.
					LB = Int(MWCS[i + 1] / 256);
					HB = MWCS[i + 1] % 256;
					Wrd2 = HB * 256 + LB;
				EndIf;
				
				// Check low surrogate pair.
				If Wrd2 < 56320    Then  // 0000 .. DBFF
					// Error: LSP expected, but signed int, BMP char or HSP found.
					Raise ErrorDescription;
					
				ElsIf Wrd2 < 57344 Then  // DC00 .. DFFF
					// OK: Low surrogate pair found.
					
				Else                     // E000 .. FFFF (+)
					// Error: LSP expected, but BMP char found or code exeeds word limit.
					Raise ErrorDescription;
				EndIf;
				
				// Calculate char code.
				HW = Word % 1024;        // AND $3FF
				LW = Wrd2 % 1024;        // AND $3FF
				Word = HW * 1024 + LW;   // SHL(High word, 10) OR (Low word)
				
				// Shift chars range to 10000 (add 0001.0000)
				// 0000.0000 .. 000F.FFFF > 0001.0000 .. 0010.FFFF
				Word = Word + 65536;     // ADD(Word, $0001.0000)
				
				// Add word.
				If AsArray Then
					Result.Add(Word);    // SMP, SIP, TIP, SSP or private area code.
				Else
					Result = Result + Char(Word); // SMP, SIP, TIP, SSP or private area char.
				EndIf;
				i = i + 2;
				
			ElsIf Word < 57344   Then    // DC00 .. DFFF
				// Low surrogate pair.
				// Error: LSP can't be used without HSP.
				Raise ErrorDescription;
				
			ElsIf Word = 65279           // FEFF
			  And    i = 0       Then
				// 1st word - BOM detected: UTF-16BE
				ByteOrder = True;
				i = i + 1;
				
			ElsIf Word = 65534           // FFFE
			  And    i = 0       Then
				// 1st word - BOM detected: UTF-16LE
				ByteOrder = False;
				i = i + 1;
				
			ElsIf Word < 65536   Then    // E000 .. FFFF; excl. FEFF, FFFE
				// Decode basic multilingual plane char = 16 bits.
				// xxxx -> xxxx.xxxx xxxx.xxxx -> xxxx
				
				// Add word.
				If AsArray Then
					Result.Add(Word);    // Basic code.
				Else
					Result = Result + Char(Word); // Basic char.
				EndIf;
				i = i + 1;
				
			Else // Char code exeeds word limit:    FFFF (+)
				Raise ErrorDescription;
			EndIf;
		EndDo;
		
	Except
		// Check exception cause.
		Info = ErrorInfo();
		If Info.Description = ErrorDescription Then // Self-produced error.
			
			// Check bytes order (wrong order?)
			If ByteOrder = Undefined Then // Autoswitch bytes order.
				// Repeat call with low endian byte order.
				Return UTF16ToUnicode(UTF16, AsArray, False);
			Else
				// The byte order is defined. Wrong data input.
				If AsArray Then
					Return New Array;
				Else
					Return "";
				EndIf;
			EndIf;
		Else
			// Other errors should be handled by default.
			Raise;
		EndIf;
	EndTry;
	
	// Return resulting string or array.
	Return Result;
	
EndFunction

// Decodes UTF-8 string to native unicode string.
//
// Parameters:
//  UTF8     - String  - String of UTF-8 characters codes.
//           - Array   - Array of UTF-8 characters bytes.
//  AsArray  - Boolean - Function must return unicode characters as an array
//                       (otherwise returns string of char-dwords).
//
// Returns:
//  String - Decoded unicode string.
//  Array  - Decoded unicode characters.
//
Function UTF8ToUnicode(UTF8, AsArray = False)
	
	// Define unicode BOM signature.
	BOM = 65279; // FEFF
	
	// Define empty result.
	If AsArray Then
		Result = New Array;
	Else
		Result = "";
	EndIf;
	
	// Define source string parameters.
	If TypeOf(UTF8) = Type("Array") Then
		
		// Use passed multy-byte characters array directly.
		MBCS = UTF8;
		
	ElsIf TypeOf(UTF8) = Type("String") Then
		
		// Create multy-byte characters array.
		If StrLen(UTF8) > 0 Then
			MBCS = New Array(StrLen(UTF8));
			For i = 1 To StrLen(UTF8) Do
				MBCS[i-1] = CharCode(UTF8, i);
			EndDo;
		Else
			// Return empty result.
			Return Result;
		EndIf;
		
	Else
		// Unknown passed type.
		Return Result;
	EndIf;
	
	// Step by step convertion of UTF-8 MBCS.
	i = 0; MBC = New Array;
	While i < MBCS.Count() Do
		
		// Get first byte.
		Byte = MBCS[i];
		
		// Get bytes count per MBC.
		Base = 128; Count = 0;
		While Byte > 0 Do
			
			// Check 0-subset.
			If Int(Byte/Base) = 0 Then
				Break;
			EndIf;
			
			// Add 1 to count of bytes in set.
			Count = Count + 1;
			
			// Get next iteration.
			Byte = Byte % Base;
			Base = Int(Base / 2);
		EndDo;
		
		// Convert char using specified quantity of symbols.
		If Count = 0 Then
			
			// ASCII Char (0..7F)
			If AsArray Then
				Result.Add(Byte);
			Else
				Result = Result + Char(Byte);
			EndIf;
			i = i + 1;
			
		ElsIf Count = 1 Then
			
			// This is not valid UTF-8 character,
			// control bits are reserved.
			If AsArray Then
				Return New Array;
			Else
				Return "";
			EndIf;
			
		ElsIf Count > 4 Then
		
			// This is not valid UTF-8 character,
			// 5 and 6 byte symbols are restricted according to RFC 3629.
			If AsArray Then
				Return New Array;
			Else
				Return "";
			EndIf;
			
		Else // This is 2-4 bytes set.
			
			// Check MBC length.
			If i + Count > MBCS.Count() Then
				// This is not valid MCB length,
				// read beyond the end of MCBS array.
				If AsArray Then
					Return New Array;
				Else
					Return "";
				EndIf;
			EndIf;
			
			// Add rest bits from first character.
			MBC.Add(Byte);
			
			// Check other characters.
			For j = 1 To Count-1 Do
				B  = MBCS[i+j];    // Current byte.
				B1 = Int(B / 128); // Highest bit
				B  = B % 128;      // AND $7F
				B2 = Int(B / 64);  // 2-nd bit
				B  = B % 64;       // AND $3F
				
				// Check control bits
				If B1 = 1 And B2 = 0 Then
					MBC.Add(B);
				Else
					// This is not valid UTF-8 character,
					// control bits are not found.
					If AsArray Then
						Return New Array;
					Else
						Return "";
					EndIf;
				EndIf;
			EndDo;
			
			// Last value of MBC can be used without rebuilding.
			Code = MBC[Count-1]; Base = 64;
			
			// Get bits from MBC and calculate the unicode code points.
			For j = 2 To Count Do
				Code = Code + Base * MBC[Count-j];
				Base = Base * 64;
			EndDo;
			
			// Check BOM signature.
			If i = 0 And Code = BOM Then // BOM signature found in first MBC.
				// Skip BOM.
			Else
				// Add unicode char to result.
				If AsArray Then
					Result.Add(Code);
				Else
					Result = Result + Char(Code);
				EndIf;
			EndIf;
			
			// Prepare for next iteration.
			i = i + Count;
			MBC.Clear();
		EndIf;
	EndDo;
	
	// Return resulting string or array.
	Return Result;
	
EndFunction

// Decodes ANSI string (provided by some browsers) to native unicode string.
// Warning: Only Windows SBCS are supported, Windows DBCS are not supported:
// There is no support for eastern languages: Thai, Japanese, Korean, Chinese.
//
// Parameters:
//  ANSI     - String - String of ANSI characters codes,
//           - Array  - Array of ANSI characters bytes.
//
//  CodePage - String - Windows-ANSI character table:
//             "windows-1250" – Central and East European Latin
//             "windows-1251" – Cyrillic
//             "windows-1252" – West European Latin
//             "windows-1253" – Greek
//             "windows-1254" – Turkish
//             "windows-1255" – Hebrew
//             "windows-1256" – Arabic
//             "windows-1257" – Baltic
//             "windows-1258" – Vietnamese
//           - Undefined - Autodetection of ANSI code page
//             basing on current session localization code.
// Returns:
//  String   - Decoded unicode string (UTF-16 compilant).
//
Function ANSIToUnicode(ANSI, CodePage = Undefined)
	
	// Define empty result.
	Result = "";
	
	// Define source string parameters.
	If TypeOf(ANSI) = Type("Array") Then
		
		// Use passed single-byte characters array directly.
		SBCS = ANSI;
		
	ElsIf TypeOf(ANSI) = Type("String") Then
		
		// Create single-byte characters array.
		If StrLen(ANSI) > 0 Then
			SBCS = New Array(StrLen(ANSI));
			For i = 1 To StrLen(ANSI) Do
				SBCS[i-1] = CharCode(Mid(ANSI, i, 1));
			EndDo;
		Else
			// Return empty result.
			Return Result;
		EndIf;
		
	Else
		// Unknown passed type.
		Return Result;
	EndIf;
	
	// Define actual codepage to be used in conversion.
	If  (StrLen(CodePage) = 12)
	And (Left(CodePage, 11) = "windows-125")
	And (Find("012345678", Mid(CodePage, 12, 1)) > 0) Then
	
		// Assign passed code page.
		CP = "CP125"+Mid(CodePage, 12, 1);
		
	Else // Process automatic search of codepage using session data.
	
		// Define code page constants.
		CP125X = New Array(9);
		// CP1250 (Latin, Central European languages)
		CP125X[0] = "az, az_AZ, az_Latn, az_Latn_AZ, " +  // Azerbaijani (latin)
		            "hy, hy_AM, hy_AM_REVISED, " +        // Armenian
		            "ka, ka_GE, " +                       // Georgian
		            "uz, uz_Latn, uz_Latn_UZ, uz_UZ, " +  // Uzbek (latin)
		            "cs, cs_CZ, " +                       // Czech
		            "hr, hr_HR, " +                       // Croatian
		            "hu, hu_HU, " +                       // Hungarian
		            "pl, pl_PL, " +                       // Polish
		            "ro, ro_RO, " +                       // Romanian
		            "sk, sk_SK, " +                       // Slovak
		            "sl, sl_SI, " +                       // Slovenian
		            "sr_Latn, " +                         // Serbian (Latin)
		            "sr_BA, sr_Latn_BA, " +               // Serbian (Bosnia and Herzegovina)
		            "sr_Latn_RS, sr_Latn_ME, sr_Latn_CS"; // Serbian (Latin, Serbia and Montenegro)
		// CP1251 (Cyrillic)
		CP125X[1] = "ru, ru_RU, ru_UA, " +                // Russian
		            "be, be_BY, " +                       // Belarusian
		            "uk, uk_UA, " +                       // Ukrainian
		            "kk, kk_KZ, " +                       // Kazakh
		            "az_Cyrl, az_Cyrl_AZ, " +             // Azerbaijani (Cyrillic)
		            "uz_Cyrl, uz_Cyrl_UZ, " +             // Uzbek (Cyrillic)
		            "bg, bg_BG, " +                       // Bulgarian
		            "mk, mk_MK, " +                       // Macedonian
		            "sr, sr_CS, sr_RS, sr_ME, " +         // Serbian (Serbia and Montenegro)
		            "sr_Cyrl, " +                         // Serbian (Cyrillic)
		            "sr_Cyrl_BA, " +                      // Serbian (Cyrillic, Bosnia and Herzegovina)
		            "sr_Cyrl_CS, sr_Cyrl_RS, sr_Cyrl_ME"; // Serbian (Cyrillic, Serbia and Montenegro)
		// CP1252 (Latin, Western European languages, Default)
		CP125X[2] = "";                                   // Default codepage
		// CP1253 (Greek)
		CP125X[3] = "el, el_CY, el_GR";                   // Greek
		// CP1254 (Turkish)
		CP125X[4] = "tr, tr_TR";                          // Turkish
		// CP1255 (Hebrew)
		CP125X[5] = "he, he_IL";                          // Hebrew
		// CP1256 (Arabic)
		CP125X[6] = "ar, ar_AE, ar_BH, ar_DZ, ar_EG, " +  // Arabic
		            "ar_IQ, ar_JO, ar_KW, ar_LB, ar_LY, " +
		            "ar_MA, ar_OM, ar_QA, ar_SA, ar_SD, " +
		            "ar_SY, ar_TN, ar_YE";
		// CP1257 (Latin, Baltic languages)
		CP125X[7] = "et, et_EE, " +                       // Estonian
		            "lt, lt_LT, " +                       // Lithuanian
		            "lv, lv_LV";                          // Latvian
		// CP1258 (Vietnamese)
		CP125X[8] = "vi, vi_VN";                          // Vietnamese
		
		// Actually we don't know exactly, which ANSI page was used,
		// because it defined by regional & language settings.
		// We'll use the current session language code as much close possible value to regional settings.
		#If ThinClient Or WebClient Then
			LocaleCode = CurrentLanguage();
		#Else
			LocaleCode = CurrentLocaleCode();
		#EndIf
		CP = "";
		For i = 0 To 8 Do
			If Find(", " + CP125X[i] + "," , ", " + LocaleCode + ",") > 0 Then
				CP = "CP125"+i;
				Break;
			EndIf;
		EndDo;
		If IsBlankString(CP) Then
			CP = "CP1252"; // Use default code page.
		EndIf;
	EndIf;
	
	// Define charset character table.
	If CP = "CP1250" Then
		// CP1250 (Latin, Central European languages)
		// 00 .. 7F -> 0000 ..007F (ASCII)
		Bt80 = "20AC,    ,201A,    ,201E,2026,2020,2021,    ,2030,0160,2039,015A,0164,017D,0179,"+ // 80 .. 8F
		       "    ,2018,2019,201C,201D,2022,2013,2014,    ,2122,0161,203A,015B,0165,017E,017A,"+ // 90 .. 9F
		       "00A0,02C7,02D8,0141,00A4,0104,00A6,00A7,00A8,00A9,015E,00AB,00AC,00AD,00AE,017B,"+ // A0 .. AF
		       "00B0,00B1,02DB,0142,00B4,00B5,00B6,00B7,00B8,0105,015F,00BB,013D,02DD,013E,017C,"+ // B0 .. BF
		       "0154,00C1,00C2,0102,00C4,0139,0106,00C7,010C,00C9,0118,00CB,011A,00CD,00CE,010E,"+ // C0 .. CF
		       "0110,0143,0147,00D3,00D4,0150,00D6,00D7,0158,016E,00DA,0170,00DC,00DD,0162,00DF,"+ // D0 .. DF
		       "0155,00E1,00E2,0103,00E4,013A,0107,00E7,010D,00E9,0119,00EB,011B,00ED,00EE,010F,"+ // E0 .. EF
		       "0111,0144,0148,00F3,00F4,0151,00F6,00F7,0159,016F,00FA,0171,00FC,00FD,0163,02D9";  // F0 .. FF
		
	ElsIf CP = "CP1251" Then
		// CP1251 (Cyrillic)
		// 00 .. 7F -> 0000 ..007F (ASCII)
		Bt80 = "0402,0403,201A,0453,201E,2026,2020,2021,20AC,2030,0409,2039,040A,040C,040B,040F,"+ // 80 .. 8F
		       "0452,2018,2019,201C,201D,2022,2013,2014,    ,2122,0459,203A,045A,045C,045B,045F,"+ // 90 .. 9F
		       "00A0,040E,045E,0408,00A4,0490,00A6,00A7,0401,00A9,0404,00AB,00AC,00AD,00AE,0407,"+ // A0 .. AF
		       "00B0,00B1,0406,0456,0491,00B5,00B6,00B7,0451,2116,0454,00BB,0458,0405,0455,0457,"+ // B0 .. BF
		       "0410,0411,0412,0413,0414,0415,0416,0417,0418,0419,041A,041B,041C,041D,041E,041F,"+ // C0 .. CF
		       "0420,0421,0422,0423,0424,0425,0426,0427,0428,0429,042A,042B,042C,042D,042E,042F,"+ // D0 .. DF
		       "0430,0431,0432,0433,0434,0435,0436,0437,0438,0439,043A,043B,043C,043D,043E,043F,"+ // E0 .. EF
		       "0440,0441,0442,0443,0444,0445,0446,0447,0448,0449,044A,044B,044C,044D,044E,044F";  // F0 .. FF
		
	ElsIf CP = "CP1252" Then
		// CP1252 (Latin, Western European languages, Default)
		// 00 .. 7F -> 0000 ..007F (ASCII)
		Bt80 = "20AC,    ,201A,0192,201E,2026,2020,2021,02C6,2030,0160,2039,0152,    ,017D,    ,"+ // 80 .. 8F
		       "    ,2018,2019,201C,201D,2022,2013,2014,02DC,2122,0161,203A,0153,    ,017E,0178,"+ // 90 .. 9F
		       "00A0,00A1,00A2,00A3,00A4,00A5,00A6,00A7,00A8,00A9,00AA,00AB,00AC,00AD,00AE,00AF,"+ // A0 .. AF
		       "00B0,00B1,00B2,00B3,00B4,00B5,00B6,00B7,00B8,00B9,00BA,00BB,00BC,00BD,00BE,00BF,"+ // B0 .. BF
		       "00C0,00C1,00C2,00C3,00C4,00C5,00C6,00C7,00C8,00C9,00CA,00CB,00CC,00CD,00CE,00CF,"+ // C0 .. CF
		       "00D0,00D1,00D2,00D3,00D4,00D5,00D6,00D7,00D8,00D9,00DA,00DB,00DC,00DD,00DE,00DF,"+ // D0 .. DF
		       "00E0,00E1,00E2,00E3,00E4,00E5,00E6,00E7,00E8,00E9,00EA,00EB,00EC,00ED,00EE,00EF,"+ // E0 .. EF
		       "00F0,00F1,00F2,00F3,00F4,00F5,00F6,00F7,00F8,00F9,00FA,00FB,00FC,00FD,00FE,00FF";  // F0 .. FF
		
	ElsIf CP = "CP1253" Then
		// CP1253 (Greek)
		// 00 .. 7F -> 0000 ..007F (ASCII)
		Bt80 = "20AC,    ,201A,0192,201E,2026,2020,2021,    ,2030,    ,2039,    ,    ,    ,    ,"+ // 80 .. 8F
		       "    ,2018,2019,201C,201D,2022,2013,2014,    ,2122,    ,203A,    ,    ,    ,    ,"+ // 90 .. 9F
		       "00A0,0385,0386,00A3,00A4,00A5,00A6,00A7,00A8,00A9,    ,00AB,00AC,00AD,00AE,2015,"+ // A0 .. AF
		       "00B0,00B1,00B2,00B3,0384,00B5,00B6,00B7,0388,0389,038A,00BB,038C,00BD,038E,038F,"+ // B0 .. BF
		       "0390,0391,0392,0393,0394,0395,0396,0397,0398,0399,039A,039B,039C,039D,039E,039F,"+ // C0 .. CF
		       "03A0,03A1,    ,03A3,03A4,03A5,03A6,03A7,03A8,03A9,03AA,03AB,03AC,03AD,03AE,03AF,"+ // D0 .. DF
		       "03B0,03B1,03B2,03B3,03B4,03B5,03B6,03B7,03B8,03B9,03BA,03BB,03BC,03BD,03BE,03BF,"+ // E0 .. EF
		       "03C0,03C1,03C2,03C3,03C4,03C5,03C6,03C7,03C8,03C9,03CA,03CB,03CC,03CD,03CE,    ";  // F0 .. FF
		
	ElsIf CP = "CP1254" Then
		// CP1254 (Turkish)
		Bt80 = "20AC,    ,201A,0192,201E,2026,2020,2021,02C6,2030,0160,2039,0152,    ,    ,    ,"+ // 80 .. 8F
		       "    ,2018,2019,201C,201D,2022,2013,2014,02DC,2122,0161,203A,0153,    ,    ,0178,"+ // 90 .. 9F
		       "00A0,00A1,00A2,00A3,00A4,00A5,00A6,00A7,00A8,00A9,00AA,00AB,00AC,00AD,00AE,00AF,"+ // A0 .. AF
		       "00B0,00B1,00B2,00B3,00B4,00B5,00B6,00B7,00B8,00B9,00BA,00BB,00BC,00BD,00BE,00BF,"+ // B0 .. BF
		       "00C0,00C1,00C2,00C3,00C4,00C5,00C6,00C7,00C8,00C9,00CA,00CB,00CC,00CD,00CE,00CF,"+ // C0 .. CF
		       "011E,00D1,00D2,00D3,00D4,00D5,00D6,00D7,00D8,00D9,00DA,00DB,00DC,0130,015E,00DF,"+ // D0 .. DF
		       "00E0,00E1,00E2,00E3,00E4,00E5,00E6,00E7,00E8,00E9,00EA,00EB,00EC,00ED,00EE,00EF,"+ // E0 .. EF
		       "011F,00F1,00F2,00F3,00F4,00F5,00F6,00F7,00F8,00F9,00FA,00FB,00FC,0131,015F,00FF";  // F0 .. FF
		
	ElsIf CP = "CP1255" Then
		// CP1255 (Hebrew)
		Bt80 = "20AC,    ,201A,0192,201E,2026,2020,2021,02C6,2030,    ,2039,    ,    ,    ,    ,"+ // 80 .. 8F
		       "    ,2018,2019,201C,201D,2022,2013,2014,02DC,2122,    ,203A,    ,    ,    ,    ,"+ // 90 .. 9F
		       "00A0,00A1,00A2,00A3,20AA,00A5,00A6,00A7,00A8,00A9,00D7,00AB,00AC,00AD,00AE,00AF,"+ // A0 .. AF
		       "00B0,00B1,00B2,00B3,00B4,00B5,00B6,00B7,00B8,00B9,00F7,00BB,00BC,00BD,00BE,00BF,"+ // B0 .. BF
		       "05B0,05B1,05B2,05B3,05B4,05B5,05B6,05B7,05B8,05B9,    ,05BB,05BC,05BD,05BE,05BF,"+ // C0 .. CF
		       "05C0,05C1,05C2,05C3,05F0,05F1,05F2,05F3,05F4,    ,    ,    ,    ,    ,    ,    ,"+ // D0 .. DF
		       "05D0,05D1,05D2,05D3,05D4,05D5,05D6,05D7,05D8,05D9,05DA,05DB,05DC,05DD,05DE,05DF,"+ // E0 .. EF
		       "05E0,05E1,05E2,05E3,05E4,05E5,05E6,05E7,05E8,05E9,05EA,    ,    ,200E,200F,    ";  // F0 .. FF
		
	ElsIf CP = "CP1256" Then
		// CP1256 (Arabic)
		Bt80 = "20AC,067E,201A,0192,201E,2026,2020,2021,02C6,2030,0679,2039,0152,0686,0698,0688,"+ // 80 .. 8F
		       "06AF,2018,2019,201C,201D,2022,2013,2014,06A9,2122,0691,203A,0153,200C,200D,06BA,"+ // 90 .. 9F
		       "00A0,060C,00A2,00A3,00A4,00A5,00A6,00A7,00A8,00A9,06BE,00AB,00AC,00AD,00AE,00AF,"+ // A0 .. AF
		       "00B0,00B1,00B2,00B3,00B4,00B5,00B6,00B7,00B8,00B9,061B,00BB,00BC,00BD,00BE,061F,"+ // B0 .. BF
		       "06C1,0621,0622,0623,0624,0625,0626,0627,0628,0629,062A,062B,062C,062D,062E,062F,"+ // C0 .. CF
		       "0630,0631,0632,0633,0634,0635,0636,00D7,0637,0638,0639,063A,0640,0641,0642,0643,"+ // D0 .. DF
		       "00E0,0644,00E2,0645,0646,0647,0648,00E7,00E8,00E9,00EA,00EB,0649,064A,00EE,00EF,"+ // E0 .. EF
		       "064B,064C,064D,064E,00F4,064F,0650,00F7,0651,00F9,0652,00FB,00FC,200E,200F,06D2";  // F0 .. FF
		
	ElsIf CP = "CP1257" Then
		// CP1257 (Latin, Baltic languages)
		Bt80 = "20AC,    ,201A,    ,201E,2026,2020,2021,    ,2030,    ,2039,    ,00A8,02C7,00B8,"+ // 80 .. 8F
		       "    ,2018,2019,201C,201D,2022,2013,2014,    ,2122,    ,203A,    ,00AF,02DB,    ,"+ // 90 .. 9F
		       "00A0,    ,00A2,00A3,00A4,    ,00A6,00A7,00D8,00A9,0156,00AB,00AC,00AD,00AE,00C6,"+ // A0 .. AF
		       "00B0,00B1,00B2,00B3,00B4,00B5,00B6,00B7,00F8,00B9,0157,00BB,00BC,00BD,00BE,00E6,"+ // B0 .. BF
		       "0104,012E,0100,0106,00C4,00C5,0118,0112,010C,00C9,0179,0116,0122,0136,012A,013B,"+ // C0 .. CF
		       "0160,0143,0145,00D3,014C,00D5,00D6,00D7,0172,0141,015A,016A,00DC,017B,017D,00DF,"+ // D0 .. DF
		       "0105,012F,0101,0107,00E4,00E5,0119,0113,010D,00E9,017A,0117,0123,0137,012B,013C,"+ // E0 .. EF
		       "0161,0144,0146,00F3,014D,00F5,00F6,00F7,0173,0142,015B,016B,00FC,017C,017E,02D9";  // F0 .. FF
		
	ElsIf CP = "CP1258" Then
		// CP1258 (Vietnamese)
		Bt80 = "20AC,    ,201A,0192,201E,2026,2020,2021,02C6,2030,    ,2039,0152,    ,    ,    ,"+ // 80 .. 8F
		       "    ,2018,2019,201C,201D,2022,2013,2014,02DC,2122,    ,203A,0153,    ,    ,0178,"+ // 90 .. 9F
		       "00A0,00A1,00A2,00A3,00A4,00A5,00A6,00A7,00A8,00A9,00AA,00AB,00AC,00AD,00AE,00AF,"+ // A0 .. AF
		       "00B0,00B1,00B2,00B3,00B4,00B5,00B6,00B7,00B8,00B9,00BA,00BB,00BC,00BD,00BE,00BF,"+ // B0 .. BF
		       "00C0,00C1,00C2,0102,00C4,00C5,00C6,00C7,00C8,00C9,00CA,00CB,0300,00CD,00CE,00CF,"+ // C0 .. CF
		       "0110,00D1,0309,00D3,00D4,01A0,00D6,00D7,00D8,00D9,00DA,00DB,00DC,01AF,0303,00DF,"+ // D0 .. DF
		       "00E0,00E1,00E2,0103,00E4,00E5,00E6,00E7,00E8,00E9,00EA,00EB,0301,00ED,00EE,00EF,"+ // E0 .. EF
		       "0111,00F1,0323,00F3,00F4,01A1,00F6,00F7,00F8,00F9,00FA,00FB,00FC,01B0,20AB,00FF";  // F0 .. FF
	Else
		Bt80 = "";
	EndIf;
	
	// Define hex codes string.
	HexStr = "0123456789ABCDEF";
	
	// Step by step convertion of ANSI Characters to Unicode.
	For i = 0 To SBCS.Count() - 1 Do
		
		// Get current byte.
		Byte = SBCS[i];
		If Byte < 128 Then
			// ASCII Char (00 .. 7F)
			Result = Result + Char(Byte);
			
		ElsIf Byte < 256 Then
			// National Code Page Char (80 .. FF)
			UnicodeCharHex  = Mid(Bt80, (Byte-128) * 5 + 1, 4);
			If Not IsBlankString(UnicodeCharHex) Then
				UnicodeCharCode = 0; Base = 1;
				For j = 0 To 3 Do
					UnicodeCharCode = UnicodeCharCode + Base * (Find(HexStr, Mid(UnicodeCharHex, 4 - j, 1)) - 1);
					Base = Base * 16;
				EndDo;
				Result = Result + Char(UnicodeCharCode);
			Else
				// Undefined symbol or wrong character table.
				Result = Result + "?";
			EndIf;
		Else
			// Undefined symbol or wrong character table.
			Result = Result + "?";
		EndIf;
	EndDo;
	
	// Return resulting string.
	Return Result;
	
EndFunction

// Encodes native unicode string to UTF-16 string.
//
// Parameters:
//  Str       - String    - Unicode string,
//            - Array     - Unicode characters codes.
//  AsArray   - Boolean   - Return UTF-16 MWCS as an array
//                          (otherwise returns string of char-words).
//  ByteOrder - Boolean   - True  = Big endian UTF-16BE (High byte, Low byte).
//                        - False = Low endian UTF-16LE (Low byte, high byte).
//            - Undefined - UTF-16: Use default byte order: UTF-16BE.
//  UseBOM    - Boolean   - Flag of include byte order mark (BOM) in the resulting string.
//
// Returns:
//  String - encoded UTF-16 characters codes,
//  Array  - encoded UTF-16 characters words.
//
Function UnicodeToUTF16(Str, AsArray = False, ByteOrder = Undefined, UseBOM = False)
	
	// Define UTF-16 words array.
	MWCS = New Array;
	
	// Define source string parameters.
	If TypeOf(Str) = Type("Array") Then
		
		// Use passed unicode characters array directly.
		UCS = Str;
		
	ElsIf TypeOf(Str) = Type("String") Then
		
		// Create unicode characters array.
		If StrLen(Str) > 0 Then
			UCS = New Array(StrLen(Str));
			For i = 1 To StrLen(Str) Do
				UCS[i-1] = CharCode(Str, i);
			EndDo;
		Else
			UCS = New Array;
		EndIf;
		
	Else
		// Unknown passed type.
		UCS = New Array;
	EndIf;
	
	// Add BOM signature (if required).
	If UseBOM Then
		
		// Insert BOM code into result.
		If (ByteOrder = Undefined) Or (ByteOrder) Then
			
			// Add UTF-16BE (plain) BOM.
			BOM = 65279;             // FEFF
		Else
			
			// Add UTF-16LE (reverse) BOM.
			BOM = 65534;             // FFFE
		EndIf;
		
		// Insert BOM into resulting array.
		MWCS.Add(BOM);
		
	EndIf;
	
	// Go thru string and encode chars.
	For i = 0 To UCS.Count()-1 Do
		
		// Get current char.
		Code = UCS[i];
		
		// Define char size.
		If Code < 0 Then
			// Skip symbol.
			
		ElsIf Code < 55296   Then    // 0000.0000 .. 0000.D7FF
			// Encode basic multilingual plane char = 16 bits.
			// xxxx -> xxxx.xxxx xxxx.xxxx -> xxxx
			
			// Add word.
			If (ByteOrder = Undefined) Or (ByteOrder) Then
				// Add UTF-16BE (plain) code.
				MWCS.Add(Code);      // Basic code.
			Else
				// Add UTF-16LE (reverse) code.
				LB = Int(Code / 256);// Basic code.
				HB = Code % 256;
				MWCS.Add(HB * 256 + LB);
			EndIf;
			
		ElsIf Code < 57344   Then    // 0000.D800 .. 0000.DFFF
			// Surrogate pairs - ignored during encoding to UTF-16.
			
			// Skip symbol.
			
		ElsIf Code < 65536   Then    // 0000.E000 .. 0000.FFFF
			// Encode basic multilingual plane char = 16 bits.
			// xxxx -> xxxx.xxxx xxxx.xxxx -> xxxx
			
			// Add word.
			If (ByteOrder = Undefined) Or (ByteOrder) Then
				// Add UTF-16BE (plain) code.
				MWCS.Add(Code);      // Basic code.
			Else
				// Add UTF-16LE (reverse) code.
				LB = Int(Code / 256);// Basic code.
				HB = Code % 256;
				MWCS.Add(HB * 256 + LB);
			EndIf;
			
		ElsIf Code < 1114112 Then    // 0001.0000 .. 0010.FFFF
			// 2-words encoding = 20 bits.
			// xxxx -> 1101.10xx xxxx.xxxx 1101.11xx xxxx.xxxx -> Dxxx Dxxx
			
			// Shift chars range to 0 (subtract 0001.0000)
			// 0001.0000 .. 0010.FFFF > 0000.0000 .. 000F.FFFF
			Code = Code - 65536;     // SUB(Code, $0001.0000)
			
			// Define high and low parts.
			HW = Int(Code / 1024);   // High word: SHR(Code, 10);
			LW = Code % 1024;        // Low word:  Code AND $0000.03FF;
			
			// Add surrogate mask.
			HW = 55296 + HW;         // $D800 OR HW
			LW = 56320 + LW;         // $DC00 OR LW
			
			// Add words to an array.
			If (ByteOrder = Undefined) Or (ByteOrder) Then
				// Add UTF-16BE (plain) code.
				MWCS.Add(HW);        // High word.
				MWCS.Add(LW);        // Low word.
			Else
				// Add UTF-16LE (reverse) code.
				LB = Int(HW / 256);  // High word / Low byte
				HB = HW % 256;       // High word / High byte
				MWCS.Add(HB * 256 + LB);
				
				LB = Int(LW / 256);  // Low word / Low byte
				HB = LW % 256;       // Low word / High byte
				MWCS.Add(HB * 256 + LB);
			EndIf;
			
		Else // Greater codes are restricted according to RFC 2781.
			
			// Skip symbol.
		EndIf;
	EndDo;
	
	// Format final result.
	If AsArray Then
		
		// Return ref to original array.
		Result = MWCS;
		
	Else
		// Encode array to a character string.
		Result = "";
		For i = 0 To MWCS.Count()-1 Do
			Result = Result + Char(MWCS[i]);
		EndDo;
	EndIf;
	
	// Return formatted value.
	Return Result;
	
EndFunction

// Encodes native unicode string to UTF-8 string.
//
// Parameters:
//  Str      - String  - Unicode string,
//           - Array   - Unicode characters bytes.
//  AsArray  - Boolean - Return UTF-8 MBCS as an array
//                       (otherwise returns string of char-bytes).
//  UseBOM   - Boolean - Flag of include byte order mark (BOM) in the resulting string.
//
// Returns:
//  String - encoded UTF-8 characters codes,
//  Array  - encoded UTF-8 characters bytes.
//
Function UnicodeToUTF8(Str, AsArray = False, UseBOM = False)
	
	// Define UTF-8 bytes array.
	MBCS = New Array;
	
	// Define source string parameters.
	If TypeOf(Str) = Type("Array") Then
		
		// Use passed unicode characters array directly.
		UCS = Str;
		
	ElsIf TypeOf(Str) = Type("String") Then
		
		// Create unicode characters array.
		If StrLen(Str) > 0 Then
			UCS = New Array(StrLen(Str));
			For i = 1 To StrLen(Str) Do
				UCS[i-1] = CharCode(Str, i);
			EndDo;
		Else
			UCS = New Array;
		EndIf;
		
	Else
		// Unknown passed type.
		UCS = New Array;
	EndIf;
	
	// Add BOM signature (if required).
	If UseBOM Then
		
		// Add BOM signature bytes to an array.
		MBCS.Add(239); // $EF
		MBCS.Add(187); // $BB;
		MBCS.Add(191); // $BF;
		
	EndIf;
	
	// Go thru string and encode chars.
	For i = 0 To UCS.Count()-1 Do
		
		// Get current char.
		Code = UCS[i];
		
		// Define char size.
		If Code < 0 Then
			// Skip symbol.
			
		ElsIf Code = 0 Then          // 0000.0000
			// Encode NUL char in overlong form (000) = 11 bits,
			// preventing mixing it with end-string character (00).
			// 000 -> 1100.0000 1000.0000 -> C080
			
			// Add high and low part.
			MBCS.Add(192);           // $C0
			MBCS.Add(128);           // $80
			
		ElsIf Code < 128     Then    // 0000.0001 .. 0000.007F
			// Encode ASCII char = 7 bits.
			// xx -> 0xxx.xxxx -> xx
			
			// Add byte.
			MBCS.Add(Code);          // ASCII code.
			
		ElsIf Code < 2048    Then    // 0000.0080 .. 0000.07FF
			// 2-bytes encoding = 11 bits.
			// 0xxx -> 110x.xxxx 10xx.xxxx -> Cx8x
			
			// Define high and low parts.
			HB = Int(Code / 64);     // High byte: SHR(Code, 6);
			LB = Code % 64;          // Low byte:  Code AND $0000.003F;
			
			// Add bytes to an array.
			MBCS.Add(192 + HB);      // $C0 OR HB
			MBCS.Add(128 + LB);      // $80 OR LB;
			
		ElsIf Code < 65536   Then    // 0000.0800 .. 0000.FFFF
			// 3-bytes encoding = 16 bits.
			// xxxx -> 1110.xxxx 10xx.xxxx 10xx.xxxx -> Ex8x8x
			
			// Define high, mid and low parts.
			HB = Int(Code / 4096);   // High byte: SHR(Code, 12);
			LW = Code % 4096;        // Low word:  Code AND $0000.0FFF;
			MB = Int(LW / 64);       // Mid byte:  SHR(Code, 6);
			LB = LW % 64;            // Low byte:  LW   AND $0000.003F;
			
			// Add bytes to an array.
			MBCS.Add(224 + HB);      // $E0 OR HB
			MBCS.Add(128 + MB);      // $80 OR MB;
			MBCS.Add(128 + LB);      // $80 OR LB;
			
		ElsIf Code < 1114112 Then    // 0001.0000 .. 0010.FFFF
			// 4-bytes encoding = 20½ bits.
			// 001x.xxxx -> 1111.0xxx 10xx.xxxx 10xx.xxxx 10xx.xxxx -> Fx8x8x8x
			
			// Define high, upper, mid and low parts.
			HB = Int(Code / 262144); // High byte: SHR(Code, 18);
			LP = Code % 262144;      // Low part:  Code AND $0003.FFFF;
			UB = Int(LP / 4096);     // Uppr byte: SHR(Code, 12);
			LW = LP % 4096;          // Low word:  LP   AND $0000.0FFF;
			MB = Int(LW / 64);       // Mid byte:  SHR(Coce, 6);
			LB = LW % 64;            // Low byte:  LW   AND $0000.003F;
			
			// Add bytes to an array.
			MBCS.Add(240 + HB);      // $F0 OR HB
			MBCS.Add(128 + UB);      // $80 OR UB;
			MBCS.Add(128 + MB);      // $80 OR MB;
			MBCS.Add(128 + LB);      // $80 OR LB;
			
		Else // Greater codes are restricted according to RFC 3629.
			
			// Skip symbol.
		EndIf;
	EndDo;
	
	// Format final result.
	If AsArray Then
		
		// Return ref to original array.
		Result = MBCS;
		
	Else
		// Encode array to a character string.
		Result = "";
		For i = 0 To MBCS.Count()-1 Do
			Result = Result + Char(MBCS[i]);
		EndDo;
	EndIf;
	
	// Return formatted value.
	Return Result;
	
EndFunction

// Encodes native 1C string to UTF-8 string.
//
// Parameters:
//  Str      - String  - Native 1C string.
//  AsArray  - Boolean - Return UTF-8 MBCS as an array
//                       (otherwise returns string of char-bytes).
//  UseBOM   - Boolean - Flag of include byte order mark (BOM) in the resulting string.
//
// Returns:
//  String - encoded UTF-8 characters codes,
//  Array  - encoded UTF-8 characters bytes.
//
Function StrToUTF8(Str, AsArray = False, UseBOM = False)
	
	// Convert native 1C UTF-16BE string to unicode characters array first.
	UnicodeStr = UTF16ToUnicode(Str, True);
	
	// Convert unicode string to UTF-8 string / chars array.
	Return UnicodeToUTF8(UnicodeStr, AsArray, UseBOM);
	
EndFunction

// Decodes UTF-8 string to native 1C string.
//
// Parameters:
//  UTF8     - String  - String of UTF-8 characters codes.
//           - Array   - Array of UTF-8 characters bytes.
//
// Returns:
//  String - Decoded 1C string.
//
Function UTF8ToStr(UTF8)
	
	// Convert UTF-8 to unicode characters array first.
	UnicodeStr = UTF8ToUnicode(UTF8, True);
	
	// Convert unicode string to native 1C UTF-16BE string.
	Return UnicodeToUTF16(UnicodeStr);
	
EndFunction

//------------------------------------------------------------------------------
// Service functions

// Performs deletion of passed file without the exception if delete fails.
//
// Parameters:
//  FileName - String - File name to be deleted.
//
// Returns:
//  Boolean  - Succession flag.
//
Function SafeDeleteFile(FileName)
	
	// Delete passed file name ignore possible exception.
	Try
		DeleteFiles(FileName);
	Except
		// File deletion failed.
		Return False;
	EndTry;
	
	// File successfully deleted.
	Return True;
EndFunction

// Returns the structure with passed parameters.
//
// Parameters:
//  Result             - Arbitrary - Returned function value.
//  Description        - String    - Success string or error description.
//  AdditionalData     - Arbitrary - Additional returning parameters.
//
// Returns:
//  Structure with the passed parameters:
//   Result            - Arbitrary.
//   Description       - String.
//   AdditionalData    - Arbitrary.
//
Function ResultDescription(Result, Description = "", AdditionalData = Undefined)
	
	// Return parameters converted to the structure
	Return New Structure("Result, Description, AdditionalData",
	                      Result, Description, AdditionalData);
	
EndFunction

#EndRegion