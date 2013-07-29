
////////////////////////////////////////////////////////////////////////////////
// Internet connection: Server Call
//------------------------------------------------------------------------------
// Available on:
// - Server
// - Server call from client
//

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

//------------------------------------------------------------------------------
// Establish and execute internet connection (web-client redirection)

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
//                             The module must implement ConnectionCreate method:
//                             ConnectionCreate(InternetConnectionType,
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
Function ConnectionCreate(Val URL, ConnectionSettings = Undefined,
	SecureConnection = Undefined, ProxySettings = Undefined,
	ExternalHandler = Undefined, ExternalParameters = Undefined) Export
	
	// Redirect to server module implementation.
	Return InternetConnectionClientServer.ConnectionCreate(URL, ConnectionSettings,
	       SecureConnection, ProxySettings, ExternalHandler, ExternalParameters);
	
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
//  Headings                 - Map - map with defined pairs of request headings.
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
//                             If it is not specified, it will be generated automatically.
//
//  ExternalHandler          - CommonModule - object for override connection creation.
//                             If client connection creation will be supported,
//                             then common module should set Client Call flag.
//                             The module must implement connection execution method:
//                             HTTPConnectionExecute(Connection, Method, Request)
//                             and/or FTPConnectionExecute(Connection, Method,
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
Function ConnectionOpen(Connection, Method, ConnectionSettings = Undefined,
	HeadingsData = Undefined, InputData = Undefined, OutputData = Undefined,
	ExternalHandler = Undefined, ExternalParameters = Undefined) Export
	
	// Redirect to server module implementation.
	Return InternetConnectionClientServer.ConnectionOpen(Connection, Method, ConnectionSettings,
	       HeadingsData, InputData, OutputData, ExternalHandler, ExternalParameters);
	
EndFunction

//------------------------------------------------------------------------------
// Service functions

// Returns current session locale code from server (client interface)
//
// Returns:
//  String - current session locale code, defined at server.
//
Function CurrentLocaleCodeAtServer() Export
	
	// Returns current session locale code.
	Return CurrentLocaleCode();
	
EndFunction

#EndRegion