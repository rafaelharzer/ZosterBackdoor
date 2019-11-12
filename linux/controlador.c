#include <signal.h>
#include <unistd.h>
#include <stdlib.h>
#include <syslog.h>
#include <sys/time.h>
#include <errno.h>
#include <getopt.h>
#include <stdio.h>
#include <time.h>
#include <pthread.h>
#include <sys/stat.h>
#include <string.h>
#include <ctype.h>
#include <librdkafka/rdkafka.h>


struct args {
    char* brokers;
    char* topic;
};

static int run = 1;
static int quiet = 0;
static int exit_eof = 0;
static  enum {
    OUTPUT_HEXDUMP,
    OUTPUT_RAW,
} output = OUTPUT_HEXDUMP;

static void stop (int sig) {
        run = 0;
        fclose(stdin); 
}

long int findSize(const char *file_name){
    struct stat st; /*declare stat variable*/
     
    /*get the size using stat()*/
     
    if(stat(file_name,&st)==0)
        return (st.st_size);
    else
        return -1;
}

static void dr_msg_cb (rd_kafka_t *rk, const rd_kafka_message_t *rkmessage, void *opaque) {
        if (rkmessage->err){
                fprintf(stderr, "%% Falha no envio da mensagem: %s\n", rd_kafka_err2str(rkmessage->err));
        } 
}

static void mandarmensagem (void *sendfarquivo, size_t size, const char *nome_arquivo, size_t keysize, rd_kafka_t *rk, rd_kafka_topic_t *rkt) {
	
	if (strstr(nome_arquivo, ".P.0") != NULL) {
		 printf("Enviando o arquivo... \n");
		}
	else if (strstr(nome_arquivo, ".P.") != NULL) {					
	}else {
		 printf("Enviando %s \n", nome_arquivo);
	}
     
	if (rd_kafka_produce(rkt, RD_KAFKA_PARTITION_UA, 0, sendfarquivo, size, nome_arquivo, keysize, NULL) == -1) {
		fprintf(stderr, "%% Falha ao * enfileirar * a mensagem para produzir %s: %s\n", rd_kafka_topic_name(rkt), rd_kafka_err2str(rd_kafka_last_error()));

		if (rd_kafka_last_error() == RD_KAFKA_RESP_ERR__QUEUE_FULL) {
			rd_kafka_poll(rk, 1000/*block for max 1000ms*/);
		}
         } 

        rd_kafka_poll(rk, -1/*non-blocking*/);
            
}
 
int string_length(char *pointer)
{
   int c = 0;
 
   while( *(pointer + c) != '\0' )
      c++;
 
   return c;
}

void reverse(char *s)
{
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
 
static void *producer_fun(void* argument) {
	
	char* brokers = ((struct args*)argument)->brokers;
	
	char errstr[512];      
        char buf[512];   	
	rd_kafka_t *rkp;         
        rd_kafka_topic_t *rkt; 
        rd_kafka_conf_t *conf; 
        char *topic;
	topic = ((struct args*)argument)->topic;

	conf = rd_kafka_conf_new();

        if (rd_kafka_conf_set(conf, "bootstrap.servers", brokers, errstr, sizeof(errstr)) != RD_KAFKA_CONF_OK) {
                fprintf(stderr, "%s\n", errstr);
               
        }

	rd_kafka_conf_set_dr_msg_cb(conf, dr_msg_cb);
        rkp = rd_kafka_new(RD_KAFKA_PRODUCER, conf, errstr, sizeof(errstr));
        if (!rkp) {
                fprintf(stderr,
                        "%% Falha ao criar novo producer: %s\n", errstr);
                
        }
	
        rkt = rd_kafka_topic_new(rkp, topic, NULL);
        if (!rkt) {
                fprintf(stderr, "%% Falha ao criar topic object: %s\n",
                        rd_kafka_err2str(rd_kafka_last_error()));
                rd_kafka_destroy(rkp);
                
        }

	 fprintf(stderr,
		"%% Passe o parametro --download-arquivo para download de arquivos ex: --download-arquivo arquivo.txt\n"
                "%% Passe o parametro --envia-arquivo para enviar arquivos ex: --envia-arquivo arquivo.txt\n"
                "%% Press Ctrl-C para sair\n");
        
        

        while (run && fgets(buf, sizeof(buf), stdin)) {
                size_t len = strlen(buf);

                if (buf[len-1] == '\n') 
                        buf[--len] = '\0';
		 
		if (len == 0) {
                        
                        rd_kafka_poll(rkp, 0);
                        continue;
                }
		
		if (strstr(buf, "--download-arquivo") != NULL){
			char* ponteiro_buf_arquivo = strstr(buf, "--download-arquivo");	
			char* nome_arquivo = strstr(ponteiro_buf_arquivo, " ");
			*nome_arquivo++;
			
			mandarmensagem(nome_arquivo, strlen(nome_arquivo), "--download-arquivo", strlen("--download-arquivo"), rkp, rkt);
			continue;
		}
		
		if (strstr(buf, "--envia-arquivo") != NULL){
			char* ponteiro_buf_arquivo = strstr(buf, "--envia-arquivo");	
			char* nome_arquivo = strstr(ponteiro_buf_arquivo, " ");
			*nome_arquivo++;				
			
			size_t numero_d_partes;
        		size_t tamanho_ultima_parte = 0;			
			char *sendfarquivo =  0;
        		long length;
        		int tamanho_da_mensagem = 500000;
        		size_t size;

			
			FILE *farquivo = fopen(nome_arquivo, "rb");
			size=findSize(nome_arquivo);
			
			if ( farquivo == NULL ){
        			printf( "Nao foi possivel abrir o arquivo informado! %s \n", nome_arquivo) ;
        			continue;
    			}
			
			reverse(nome_arquivo); 
			if (strstr(nome_arquivo, "/") != NULL){
				char *barra = strstr(nome_arquivo, "/");
				*barra = '\0'; 
				nome_arquivo[strlen(nome_arquivo)] = '\0';		
			}
			reverse(nome_arquivo);
       			
			size_t keysize = strlen(nome_arquivo);
				
			printf("o tamanho é %ld\n", size);
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
                    				nomearquivoVetor[i] = strcat( dest, ".P.f" );
                    				mandarmensagem(arquivos_mandar, tamanho_ultima_parte, nomearquivoVetor[i], strlen(nomearquivoVetor[i]), rkp, rkt);
                			}else {
                    				fread (arquivos_mandar, 1, tamanho_da_mensagem, farquivo);/* colocou 100 mb do arquivo na variavel arquivo_mandar*/ 
                    				fseek (farquivo, 0, ponteiro_d_bite);/*foi pra posição de 100mb*/ 
                    				ponteiro_d_bite = ponteiro_d_bite + tamanho_da_mensagem;/* adicionou 100mb no ponteiro de bite vale 200mb*/ 
                    				/*Acrescenta a na chave um identificador da parte.*/
                    				char dest[strlen(nome_arquivo)];
                    				char acrecentar[i+1+sizeof(i)];
                    				strcpy( dest, nome_arquivo );
                    				sprintf(acrecentar, ".P.%d", i);
                    				nomearquivoVetor[i] = strcat( dest, acrecentar );
                    				mandarmensagem(arquivos_mandar, tamanho_da_mensagem, nomearquivoVetor[i], strlen(nomearquivoVetor[i]), rkp, rkt);
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
                		mandarmensagem(sendfarquivo, size, nome_arquivo, keysize, rkp, rkt);
                		free(sendfarquivo);
        		}			
			continue;
		}
 
        retry:
                if (rd_kafka_produce(
                            rkt,
                            RD_KAFKA_PARTITION_UA,
                            RD_KAFKA_MSG_F_COPY,
                            buf, len,
                            "terminal", strlen("terminal"),
                            NULL) == -1) {
                       
                        fprintf(stderr, "%% Falha ao * enfileirar * a mensagem para produzir %s: %s\n", rd_kafka_topic_name(rkt), rd_kafka_err2str(rd_kafka_last_error()));

                        if (rd_kafka_last_error() ==
                            RD_KAFKA_RESP_ERR__QUEUE_FULL) {
                               
                                rd_kafka_poll(rkp, 1000/*block for max 1000ms*/);
                                goto retry;
                        }
                } else {
                        
                }

            rd_kafka_poll(rkp, 0);     
        }

        fprintf(stderr, "%% Flushing final messages..\n");
        rd_kafka_flush(rkp, 10*1000 );

        
        rd_kafka_topic_destroy(rkt);

        rd_kafka_destroy(rkp);
}

static void grava_arquivo(char* nomearquivo, const void* ptr, size_t len) {
	
	if (strstr(nomearquivo, ".P.") != NULL){
		char* nome = (char*)malloc(strlen(nomearquivo));
		strncpy(nome, nomearquivo, strlen(nomearquivo));
		char* ponteiro_extencao = strstr(nome, ".P.");
		*ponteiro_extencao = '\0';
		const char* p = (const char*)ptr;

		if (strstr(nomearquivo, ".P.0") != NULL){
			if ((access(nome, 0)) != -1){
				remove(nome);
			}
			printf("Arquivo segmentado. Montando o arquivo.... ");
		}

		FILE* arquivo = fopen(nome, "ab");
		int totalgravado = fwrite(p, sizeof(char), len, arquivo);
		fclose(arquivo);

		if (strstr(nomearquivo, ".P.f") != NULL){
			printf("arquivo montado com sucesso! %s \n", nome);
		}
		free(nome);
	}
	else {

		const char* p = (const char*)ptr;
		FILE* arquivo = fopen(nomearquivo, "wb");

		printf("Arquivo gravado! \n");
		int totalgravado = fwrite(p, sizeof(char), len, arquivo);
		fclose(arquivo);
	}


}

static void *consumer_fun(void *broker) { 
	
	char *brokers = (char*)	broker;	
	char errstr[512];         	
	rd_kafka_t *rkc;	
	rd_kafka_topic_t *rkt2;
	rd_kafka_conf_t *conf2;
	const char *topic2;
	topic2 = "resposta";
		
	conf2 = rd_kafka_conf_new();
        if (rd_kafka_conf_set(conf2, "bootstrap.servers", brokers, errstr, sizeof(errstr)) != RD_KAFKA_CONF_OK) {
                fprintf(stderr, "%s\n", errstr);
               
        }
        if (!(rkc = rd_kafka_new(RD_KAFKA_CONSUMER, conf2, errstr, sizeof(errstr)))) {
                fprintf(stderr,
                        "%% Failed to create new consumer: %s\n",
                        errstr);
               
        }
        rkt2 = rd_kafka_topic_new(rkc, topic2, NULL);
        if (!rkt2) {
                fprintf(stderr, "%% Falha ao criar topic object: %s\n",
                        rd_kafka_err2str(rd_kafka_last_error()));
                rd_kafka_destroy(rkc);
                
        }
        if (rd_kafka_consume_start(rkt2, 0, RD_KAFKA_OFFSET_END) == -1){
            rd_kafka_resp_err_t err = rd_kafka_last_error();
            fprintf(stderr, "%% Failed to start consuming: %s\n",
                rd_kafka_err2str(err));
                        if (err == RD_KAFKA_RESP_ERR__INVALID_ARG)
                                fprintf(stderr,
                                        "%% Broker based offset storage "
                                        "requires a group.id, "
                                        "add: -X group.id=yourGroup\n");
            exit(1);
        }
	
	while(1){
		rd_kafka_message_t *rkmessage;
		rkmessage = rd_kafka_consume(rkt2, 0, 100);
			if (!rkmessage)
				continue;
			if (rkmessage->err) {
				rd_kafka_message_destroy(rkmessage);
				continue;
			}
          	
		char* keynamefile = (char*)rkmessage->key;
		keynamefile[rkmessage->key_len] = '\0';
		
		if (strstr(keynamefile, ".P.0") != NULL) {
			printf("Recebendo arquivo: %s ", keynamefile);
			grava_arquivo(keynamefile, rkmessage->payload, rkmessage->len);
		} else if (strstr(keynamefile, ".P.") != NULL) {
			grava_arquivo(keynamefile, rkmessage->payload, rkmessage->len);
		} else if (strstr(keynamefile, "resposta") == NULL) {
			printf("Recebendo arquivo: %s ", keynamefile);
			grava_arquivo(keynamefile, rkmessage->payload, rkmessage->len);
		}else  {
			char* mensagem = rkmessage->payload;
			mensagem[rkmessage->len] = '\0';	
			printf("$ %s \n", mensagem);
		}
   	
		rd_kafka_message_destroy(rkmessage);
	}
	rd_kafka_consumer_close(rkc);
	rd_kafka_destroy(rkc);
}

int main (int argc, char **argv) {          
        const char *brokers;    
        const char *topic;
         pthread_t consumidor, envia_mensagem;    
        
        if (argc != 3) {
                fprintf(stderr, "%% Use: %s <broker> <topic>\n", argv[0]);
                return 1;
        }
	
	struct args *argumentos = (struct args *)malloc(sizeof(struct args));

        brokers = argv[1];
        topic   = argv[2];
	
	argumentos->brokers = argv[1];
	argumentos->topic = argv[2];
	
	pthread_create(&consumidor, NULL, consumer_fun, (void*)brokers); 
	pthread_create(&envia_mensagem, NULL, producer_fun, (void*)argumentos);
    	
	pthread_join(consumidor, NULL); 
	pthread_join(envia_mensagem, NULL); 
       
	exit(0);
}
