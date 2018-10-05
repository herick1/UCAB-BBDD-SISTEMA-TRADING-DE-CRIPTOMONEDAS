# UCAB-BBDDII-SISTEMA TRADING DE CRIPTOMONEDAS 

 En el repo aparece 3 archivos ".sql" un archivo ".xml" , este proyecto esta desarrollado con Oracle 11g , en sql developer
 
## 1 Instalacion (Oracle):

   
* Instalacion de sql developer en windows : para la instalacion vale la pena ver este link [sql developer](http://www.tiflocordoba.org/manual-de-instalacion-de-sql-developer-en-windows-y-con-accesibilidad/ "sql developer").

## 2 Ambiente de Trabajo:

* crear un tablespace nuevo
	* Primero crear una carpeta en c:/ , yo la llame BBDDII
	* Entrar en sql plus y poner:
 		* create tablespace herick100 datafile  'C:\BBDDII\herick100.dbf' size 10240 m;
	        * create user herick identified by 123 default tablespace herick100  temporary tablespace temp;
	        * grant DBA to marcos ;

   	        * nota:= al crear el tablespace puede tardar un poco bastante debido al tamaño que le estamos asignando 
     		* borremos el usuario con el estabamos haciendo antes el sql developer  (debemos desconectarnos y conectarnos con herick)
                * Drop user proy cascade;
		* nota:= cambiar "proy" por el nombre de tu usuario 

* Ahora dentro de sql developer debemos "crear una nueva conexion" con el usuario y la clave que pusimos en el paso anterior

* Una vez hecho todo esto ya tendras tu instancia de pl/sql creada , ahora en las opciones de sql developer debemos buscar la opcion de importar BD , y alli cargaremos los dos archivos que estan aqui :

	* CREATE.sql
	* Procedimientos-funciones-trigger.sql

	* nota:= tambien hay un archivo llamado DROP.sql que sirve a la hora de borrar la BBDD , sin imbargo despues de ejecutar este .sql recuerda purgar la papelera desde el usuario system



## 3 Ejecuciòn:

* En una nueva hoja de trabajo poner:
  
   * set serveroutput on;   --Esto es para poder ver las salidas de los procedimientos/funciones

   * execute H02_INSERCIONES_BASICAS;
   * execute H03_CREAR_USUARIOS_ALEATORIO(500); -- Este procedimiento crea 500 usuarios aleatorios
   * execute H04_CREAR_MONEDERO_ALEATORIO;
   * execute H07_RELLENO_FALTANTE(100); -- Este procedimiento crea 100 depositos y retiros
   * execute H08_CREAR_HISTO_MONE_MERCA(50);--se crean 50 dias anteriores a la fecha actual en el historias

   * execute  H05_SIMULA_5_MILLON_TRADING(200,1,1); --La simulaciòn principal , en ella se hace el trading de 200 operaciones aleatorias del mercado uno y de la moneda numero uno

   * execute H0_FUNCION_USUARIO_LOGIN('MATIAS_0','0'); --Esto sirve para probar el login de los usuarios da 1 cuando es correcto 0 cuando no 
   * update vista_usuario set contrasena_Actual = 'herick' where id=1;  --actualizar la vista del usuario
   * update vista_monedero set cantidad_Actual = 21.2 where id=2;       --vista del monedero de dicho usuario
   * execute H10_simulacion_montecarlo(5.1,1,1);  --primer elemento capital a simular, segundo elemento la moneda del capital , y el tercero el mercado
   * execute H11_simulacion_regresiones(sysdate,1,1); --primer elemento dia a simular precio, segundo elemento la moneda del  capital , y el tercero el mercado

           * nota:= 
		  * te da simulacion lineal
                    * te da simulacion cuadratica
                    * te da simulacion exponencial

   * execute h12_optimizacion_venta(3.5,1);  --primer elemento es el capital que se va a optimizar y el segundo es el tipo moneda que se esta utilizando
   * execute H13_ganancia_mercado_dia(1); --elemento corresponde al id del monedero que se va ver la ganacia historica
   * execute H14_correcion_de_mercado(1); --elemento corresponde a la id del mercado donde se vaya a ver si hay en su historico una correcion de mercado 

   * execute C1_CAPITALIZACION_BURSATIL(1,1); --elemento 1 corresponde a la id del mercado y el segundo elemento correpsonde al id de la moneda

* En la parte xml es necesario ver este tutorial para entender como ponerlo [graficas en sql developer ](http://www.v-espino.com/~chema/daw1/tutoriales/oracle/sqldeveloper.htm "graficas en sql developer").
