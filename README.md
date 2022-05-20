Navegando na Play Store encontrei um aplicativo chamado Termux, que simula um terminal Linux no Android.

`'Termux combina emulação de terminal poderosa com uma coleção extensa de pacotes Linux.'`

Achei interessante, você pode baixar vários pacotes Linux, executar comandos shell para interagir com a API Termux, que lhe fornece dados do celular, envio de SMS, notificações, colher status da bateria...

E para experimentar o terminal, codifiquei um script shell para ler um arquivo de configurações com empresas da bolsa de valores de São Paulo eugostaria de receber uma notificação se o preço da empresa estiver dentro de um intervalo de preço.

# Termux 
Eu tinha baixado o Termux diretamente da Play Store. Mas o aplicativo já não é mais atualizado na plataforma: 
![image](https://user-images.githubusercontent.com/1113381/158214301-bb35eeed-9e57-41c8-af14-9733c19c4ac0.png)

Portanto fiz o download do aplicativo através da plataforma F-Droid (https://f-droid.org/), ele é um catálogo de aplicativos opensource para Android:
- https://f-droid.org/pt_BR/packages/com.termux/ (Aplicativo Terminal Termux);
- https://f-droid.org/pt_BR/packages/com.termux.api/ (Aplicativo que faz interface entre o terminal e o aparelho para fazer uso de envio de SMS, noifications, consultar status da bateria através da linha de comando).

## Pacotes que foram necessários serem instalados durante o desenvolvimento do script
Basta abrir o termux e executar os seguintes comandos para instalar as bibliotecas necessárias para execução do script criado:
- `pkg install termux-api` [Biblioteca que disponibiliza comandos para interagir com a câmera do celular, SMS, notification...](https://wiki.termux.com/wiki/Termux:API)
- `pkg install termux-service` [Biblioteca que contém scripts para gerênciar serviços tais como o cron, banco de dados, servidor web...](https://wiki.termux.com/wiki/Termux-services)
- `pkg install git`
- `pkg install jq` [Biblioteca de processamento de arquivo JSON](https://stedolan.github.io/jq/) através da linha de comando. Utilizada para ler o arquivo de configuração, ela ajuda a buscar itens específicos no JSON.
- `pkg install bc` Biblioteca matemática que facilita montar condições de comparação de números no shell.
- `pkg install cronie` Instalação do serviço cron, com ele iremos programar a execução do script shell para verificar a cada hora se as ações estão dentro do intervalo configurado

# Executando o script

## API Alpha Vantage
Para obter o preço atual das ações o script consulta a API Alpha Vantage. Ela é uma API gratuita, basta você acessar a página de solicitação de chave para iniciar o consumo dela: https://www.alphavantage.co/support/#api-key

## Clone o projeto
Clone o projeto na home do Termux: `git clone https://github.com/thiagosilr/bovespa-buy-alert.git`

## Arquivo de configuração config.json
Acesso o diretório do repositório clonado e crie um aquivo com o nome config.json com a seguinte estrutura:

```json
{
    "apiKey": "CHAVE_DA_API_ALPHA_VANTAGE_OBTIDA_ATRAVES_DA_URL_CITADA_ACIMA"
	"companys": ["ITSA4.SAO"],
	"ITSA4.SAO": {
		"priceMin": 8.00,
		"priceMax": 9.50
	}
}
```

- companys: Array contendo as empresas a qual gostaria de monitorar. A identificação da empresa segue o seguinte padrão na API Alpha Vantage, CodigoEmpresaBovespa.SAO. Ex.: Itaúsa (ITSA4) = ITSA4.SAO

Para cada empresa listada no atributo companys é necessário gerar um chave com os campos princeMin e priceMax.

## script.sh 
```sh
#!/data/data/com.termux/files/usr/bin/bash
config=$(cat ~/bovespa-buy-alert/companies-monitor.conf)
apiKey=$(echo $config | jq 'apiKey')

companyTotal=$(echo $config | jq '.companys | length')
for i in $(seq 0 $(($companyTotal-1)));
do
	company=$(echo $config | jq -r '.companys['$i']')
	priceMin=$(echo $config | jq '."'$company'".priceMin')
	priceMax=$(echo $config | jq '."'$company'".priceMax')
	price=$(curl "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=$company&apikey=$apiKey" | jq -r '."Global Quote"."05. price"')
	notification="$company se encontra entre os valores $priceMin - $priceMax"

	if (( $(echo "$price >= $priceMin" | bc -l) )); then
		if (( $(echo "$price <= $priceMax" | bc -l) )); then
			termux-notification -c "$notification"
        fi
    fi
done
```

Basicamente o script lê o arquivo de configuração e realiza um requisição a API para obter o valor das ações listadas no arquivo. Após obter o valor o script verifica se o preço atual da ação está dentro do intervalo de preço min ou max configurados. Se o preço estiver dentro do intervalo é gerado um notificação no aparelho informando:

## Agendando o script para que ele execute a cada hora
Execute o seguinte comando para incluir um agendamento para executar o nosso script automaticamente:
- `crontab -e`

Será aberto um arquivo, nele configure um novo agendamento da seguinte forma:
- `0 10-18 * * 1-5 ~/bovespa-buy-alert/script.sh 2> ~/bovespa-buy-alert/log.txt`
Obs.: Como a Bovespa opera somente durante a semana de 10 as 18 horas. Montei uma agendamento que execute o nosso script a cada hora de segunda a sexta-feira das 10 as 18. Note que a execução é enviada para um arquivo de log. Assim você consegue realizar verificação em caso de falha.

Para salvar o arquivo basta precionar:
- `ctrl + x` 

Habilite o serviço de cron, pois ele vem desligado assim que é instaldo:
- `sv-enable crond`

