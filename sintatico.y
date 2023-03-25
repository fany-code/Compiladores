/*------------------------------------------------------------
  |                  UNIFAL - Universidade Federal de Alfenas
  |                  BACHARELADO EM CIENCIA DA COMPUTACAO
  |   Trabalho....: Compilador Simples - Funcao
  |   Disciplina..: Teoria de Linguagens e Compiladores
  |   Professor...: Luiz Eduardo da Silva
  |   Aluno.......: Flaviane Moura Oliveira
  |   Data........: 17/02/2023
  +----------------------------------------------------------
*/

%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "lexico.c"
#include "utils.c"
#define MAX_PAR 20

int contaVar = 0;  //conta numero de variaveis
int rotulo = 0; //marca lugares no codigo
int tipo;
char escopo = 'G';
char categoria;
int endereco = 0;
int parametros = 0, qtdParametros = 0;
int lPar[MAX_PAR];
int conta, contaArg = 0;
int tab = 0;  
int rot_local;
int deslocamento = 0;
int pega_rot_pos = 0;
int nvarl;
%}

%token T_PROGRAMA
%token T_INICIO
%token T_FIM
%token T_LEIA
%token T_ESCREVA
%token T_SE
%token T_ENTAO
%token T_SENAO
%token T_FIMSE
%token T_ENQTO
%token T_FACA
%token T_FIMENQTO
%token T_INTEIRO
%token T_LOGICO
%token T_MAIS
%token T_MENOS
%token T_VEZES
%token T_DIV
%token T_ATRIBUI
%token T_MAIOR
%token T_MENOR
%token T_IGUAL
%token T_E
%token T_OU
%token T_NAO
%token T_ABRE
%token T_FECHA
%token T_V
%token T_F
%token T_IDENTIF
%token T_NUMERO

/*adicionar os tokens retorne, func e fimfunc*/
%token T_FUNC
%token T_RETORNE
%token T_FIMFUNC

%start programa
%expect 1

%left T_E T_OU
%left T_IGUAL
%left T_MAIOR T_MENOR
%left T_MAIS T_MENOS
%left T_VEZES T_DIV

%%

programa 
    : cabecalho 
        {
            contaVar = 0;
            fprintf(yyout,"\tINPP\n"); 
        }
      variaveis 
        { 
            escopo = 'G';
            if (contaVar){
                fprintf(yyout,"\tAMEM\t%d\n", contaVar);    //imprime AMEM
            }
            empilha(contaVar, 'n');     //conta variaveis

        }
      rotinas

    T_INICIO lista_comandos T_FIM
        { 
            if (contaVar > 0)
                fprintf(yyout,"\tDMEM\t%d\n", contaVar); 
            fprintf(yyout,"\tFIMP\n");
        }
    ;

cabecalho
    : T_PROGRAMA T_IDENTIF
    ;

variaveis
    : /* vazio */
    | declaracao_variaveis
     /*{
            
            //mostraTabela();
            if (conta){
                fprintf(yyout,"\tAMEM\t%d\n", conta);    //imprime AMEM
            }
            empilha(conta, 'n');     //conta variaveis
        
        }*/
    ;

declaracao_variaveis
    : tipo lista_variaveis declaracao_variaveis
    | tipo lista_variaveis
    ;

tipo
   : T_LOGICO { tipo = LOG; }
   | T_INTEIRO { tipo = INT; }
   ;

lista_variaveis
    : lista_variaveis  T_IDENTIF 
        { 
            strcpy(elemTab.id, atomo);
            if (escopo == 'L'){
                elemTab.end = nvarl;
                nvarl++;
            } else {
                elemTab.end = contaVar;
                contaVar++;
            }
            //elemTab.end = contaVar;
            elemTab.tip = tipo;
            elemTab.cat = 'V';
            elemTab.esc = escopo;
            //elemTab.rot = -1;
            insereSimbolo(elemTab);
            deslocamento++;
        }
    | T_IDENTIF
        { 
            strcpy(elemTab.id, atomo);
            if (escopo == 'L'){
                elemTab.end = nvarl;
                nvarl++;
            } else {
                elemTab.end = contaVar;
                contaVar++;
            }
            elemTab.tip = tipo;
            elemTab.esc = escopo;
            elemTab.cat = 'V';
            insereSimbolo(elemTab);
            //contaVar++;   
            deslocamento++;   
        }
    ;

rotinas
    : /*não tem funcoes*/
    | 
        {
            //fprintf(yyout,"\tDSVS\tL0\n");
            fprintf (yyout,"\tDSVS\tL%d\n", rotulo);
            empilha(rotulo, 'r');
        }
    lista_funcoes
        { 
            //fprintf(yyout,"L0\tNADA\n");
            int r = desempilha('r');
            fprintf(yyout, "L%d\tNADA\n", r);
        }
    ;

/*regras para as funções*/ 
lista_funcoes
    : funcao
    | funcao lista_funcoes
    ;

funcao
    : T_FUNC tipo T_IDENTIF
        { 
            strcpy(elemTab.id, atomo);
            elemTab.tip = tipo;
            elemTab.cat = 'F';
            rot_local = deslocamento;
            elemTab.rot = ++rotulo;
            elemTab.end = deslocamento;
            elemTab.esc = escopo;
            insereSimbolo(elemTab);
            fprintf(yyout, "L%d\tENSP\n", rotulo);
            deslocamento++;
            escopo = 'L';
        }

      T_ABRE parametros T_FECHA
        {
            ajustaDeslocamento(deslocamento, parametros);
        }

      variaveis
        {
            if(nvarl > 0)
                fprintf(yyout, "\tAMEM\t%d\n", nvarl);
        }

      T_INICIO lista_comandos T_FIMFUNC
        {
            //verificarTipoArgumento();
            escopo = 'G';
            nvarl = 0;
            parametros = 0;

            /*int p = desempilha('p');
            int r = desempilha('r');
            fprintf(yyout,"\tDMEM\t%d\n", conta);   // deve gerar dmem 1
            fprintf (yyout,"\tRTSP\t%d\n", parametros);*/
            //tab = removeTabela(conta, parametros);
            

        }
    ;

parametros
    : /*vazio*/
    | parametro parametros
    ;

parametro
    : tipo T_IDENTIF 
        {
            strcpy(elemTab.id, atomo);
            elemTab.tip = tipo;
            elemTab.cat = 'P';
            elemTab.rot = 0;
            elemTab.end = deslocamento;
            elemTab.esc = escopo;
            insereSimbolo(elemTab);
            deslocamento++;
            parametros++;
            //qtdParametros++;
            //mostraTabela();
        }
    ;

lista_comandos
    : /* vazia */
    | comando lista_comandos
    ;

comando
    : entrada_saida
    | repeticao
    | selecao
    | atribuicao
    | retorno
    ;

/*comando retorno só faz sentido dentro da função*/
/* tem que gerar os codigos ARZL (valor de retorno) > DMEN (se tiver variavel local) > RTSP (retorno de sub programa)*/
retorno 
    : T_RETORNE expressao
        {
            //mostraTabela();
            int t = desempilha('t'); 
            if(t != tabSimb[rot_local].tip)
                yyerror("Tipo incompatível!");
            if(escopo != 'L')
                yyerror("Escopo errado!");
            fprintf(yyout, "\tARZL\t%d\n", tabSimb[rot_local].end);
            if(nvarl > 0)
                fprintf(yyout, "\tDMEM\t%d\n", nvarl);
            fprintf(yyout, "\tRTSP\t%d\n", tabSimb[rot_local].npar);
        }
        /*deve gerar depois da trad. da expressao
        
        ARZL n          guarda o endereço do valor de retorno
        DMEM n          se tiver variavel local, onde n é o número de variaveis declaradas dentro da funcao
        RTSP n          onde n é o número de parametros
        */
    ;

entrada_saida
    : leitura
    | escrita
    ;

leitura
    : T_LEIA T_IDENTIF
        { 
            int p = buscaSimbolo(atomo);
            fprintf(yyout,"\tLEIA\n\tARZG\t%d\n", tabSimb[p].end); 
        }
    ;

escrita 
    : T_ESCREVA expressao
         { 
            desempilha('t');
            fprintf(yyout,"\tESCR\n"); 
         }
    ;

repeticao
    : T_ENQTO 
        { 
            fprintf(yyout,"L%d\tNADA\n", ++rotulo); 
            empilha(rotulo, 'r');
        }
      expressao T_FACA 
        {
             int tipo = desempilha('t');
             if(tipo != LOG)
                 yyerror("Incompatilidade de tipo 2");
             fprintf(yyout,"\tDSVF\tL%d\n", ++rotulo);
             empilha(rotulo, 'r');
        }
      lista_comandos 
      T_FIMENQTO
         { 
            int r1 = desempilha('r');
            int r2 = desempilha('r');
            fprintf(yyout,"\tDSVS\tL%d\n",r2);
            fprintf(yyout,"L%d\tNADA\n",r1);
         }
    ;

selecao
    : T_SE expressao T_ENTAO
        {
             int tipo = desempilha('t');
             if(tipo != LOG)
                 yyerror("Incompatilidade de tipo 1!");
             fprintf(yyout,"\tDSVF\tL%d\n", ++rotulo);
             empilha(rotulo, 'r');
        }
      lista_comandos T_SENAO
        { 
            int rot = desempilha('r');
            fprintf(yyout,"\tDSVS\tL%d\n", ++rotulo);
            fprintf(yyout,"L%d\tNADA\n", rot);
            empilha(rotulo, 'r');
        }
      lista_comandos T_FIMSE
        { 
            int rot = desempilha('r');
            fprintf(yyout,"L%d\tNADA\n", rot); 
        }
    ;

atribuicao
    : T_IDENTIF 
        {
            int p = buscaSimbolo(atomo);
            empilha(p, 'p');
        }   
      T_ATRIBUI expressao
        {
            int tipo = desempilha('t');
            int p = desempilha('p');
            if (tabSimb[p].tip != tipo)
               yyerror("Incompatibilidade de tipo!");
            if(tabSimb[p].esc == 'L'){
                fprintf(yyout,"\tARZL\t%d\n", tabSimb[p].end);
            } else if (tabSimb[p].esc == 'G') {
                fprintf(yyout,"\tARZG\t%d\n", tabSimb[p].end);
            }
            //empilha(tabSimb[p].tip, 't');
        }
    ;

expressao
    : expressao T_VEZES expressao
        {
            testaTipo(INT,INT, INT);
            fprintf(yyout,"\tMULT\n"); 
        }
    | expressao T_DIV expressao
        {
            testaTipo(INT,INT, INT);
            fprintf(yyout,"\tDIVI\n"); 
        }
    | expressao T_MAIS expressao
        {
            testaTipo(INT,INT, INT);
            fprintf(yyout,"\tSOMA\n"); 
        }
    | expressao T_MENOS expressao
        {
            testaTipo(INT,INT, INT);
            fprintf(yyout,"\tSUBT\n");
        }
    | expressao T_MAIOR expressao
        {
            testaTipo(INT,INT, LOG);
            fprintf(yyout,"\tCMMA\n"); 
        }
    | expressao T_MENOR expressao
        {
            testaTipo(INT,INT, LOG);
            fprintf(yyout,"\tCMME\n");
        }
    | expressao T_IGUAL expressao
        {
            testaTipo(INT,INT, LOG);
            fprintf(yyout,"\tCMIG\n"); 
        }
    | expressao T_E expressao 
        {
            testaTipo(LOG, LOG, LOG);
            fprintf(yyout,"\tCONJ\n"); 
        }
    | expressao T_OU expressao
        {
            testaTipo(LOG, LOG, LOG);
            fprintf(yyout,"\tDISJ\n"); 
        }
    | termo
    ;

/* a chamada da função vai acontecer como termo em uma expressao*/
chamada
    : /*sem parenteses é uma variavel 
        desempilha a posicao e trata como variavel*/
        {
            int p = desempilha('p');
            if(tabSimb[p].esc == 'L'){
                fprintf(yyout,"\tCRVL\t%d\n", tabSimb[p].end);
            } else if (tabSimb[p].esc == 'G') {
                fprintf(yyout,"\tCRVG\t%d\n", tabSimb[p].end);
            }
            empilha(tabSimb[p].tip, 't');
        }
    | T_ABRE 
        {
            int p = desempilha('p');
            if (p == -1){
                yyerror("Erro! A função não foi declarada!");
            }
            pega_rot_pos = tabSimb[p].rot;
            //armazena nesta variavel o rótulo desta variável para conseguir chamar em lista_argumentos
            parametros = tabSimb[p].npar;

            empilha(tabSimb[p].tip, 't');
            fprintf(yyout,"\tAMEM\t%d\n", tabSimb[p].rot);
        } /* AMEM */
    lista_argumentos /* trata em termo */T_FECHA 
        { /* {SVCP e DSVS} */
            if(contaArg != parametros)
                yyerror("Erro! A quantidade de argumentos não equivale a quantidade de parametros!");
            mostraTabela();
            fprintf(yyout,"\tSVCP\n");
            fprintf(yyout,"\tDSVS\tL%d\n", pega_rot_pos); // tem que desviar para L1
            //fprintf(yyout,"\tDSVS\tL1\n");
        }
    ;

identificador
    : T_IDENTIF
        {
            int p = buscaSimbolo(atomo); 
             if(p == -1){
                yyerror("Erro! A variavel não foi declarada!");
             }
            empilha(p, 'p'); 
        }
    ;

lista_argumentos
    : /*vazio*/ 
    | argumento 
    ;

argumento
    : argumento arg
    | arg
    ;
arg
    : expressao
        {
            contaArg++;
            int t1 = desempilha('t');
        }
    ;

termo
    : identificador chamada
    | T_NUMERO
        {
            fprintf(yyout,"\tCRCT\t%s\n", atomo);
            empilha(INT, 't');
        }
    | T_V
        {
            fprintf(yyout,"\tCRCT\t1\n"); 
            empilha(LOG, 't');
        }
    | T_F
        {
            fprintf(yyout,"\tCRCT\t0\n"); 
            empilha(LOG, 't');
        }
    | T_NAO termo
        {
            int t = desempilha('t');
            if (t != LOG)
                yyerror ("Incompatibilidade de tipo!");
            fprintf(yyout,"\tNEGA\n"); 
            empilha(LOG, 't');
        }
    | T_ABRE expressao T_FECHA
    ;
%%

int main(int argc, char *argv[]){
    char *p, nameIn[100], nameOut[100];
    argv++;
    if(argc < 2){
        puts("\nCompilador Simples\n");
        puts("\n\tUso: ./simples <NOME>[.simples]/n/n");
        exit(10);
    }
    p = strstr(argv[0], ".simples");
    if(p) *p = 0;
    strcpy(nameIn, argv[0]);
    strcat(nameIn, ".simples");
    strcpy(nameOut, argv[0]);
    strcat(nameOut, ".mvs");
    yyin = fopen(nameIn, "rt");
    if(!yyin){
        puts("Programa fonte não encontrado!");
        exit(20);
    }
    yyout = fopen(nameOut,"wt");
    yyparse(); /*LR melhorado*/
    puts("Programa ok!");
}