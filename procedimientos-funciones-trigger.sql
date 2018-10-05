  CREATE OR REPLACE TRIGGER "1.1.COMPRA_VENTA_ID_AUTO" 
  BEFORE INSERT ON COMPRA_VENTA 
  FOR EACH ROW
BEGIN
  SELECT secuencia_COMPRA_VENTA_ID.NEXTVAL
  INTO   :new.id
  FROM   dual;
END;
/
  CREATE OR REPLACE TRIGGER "1.2.DEPOSITO_RETIRO_ID_AUTO" 
  BEFORE INSERT ON DEPOSITO_RETIRO  
  FOR EACH ROW
BEGIN
  SELECT secuencia_DEPOSITO_RETIRO_ID.NEXTVAL
  INTO   :new.id
  FROM   dual;
END;
/
  CREATE OR REPLACE TRIGGER "1.3.HISTOR_MONE_MER_ID_AUTO" 
  BEFORE INSERT ON HISTORIAL_MONEDAS_MERCADO 
  FOR EACH ROW
BEGIN
  SELECT secuencia_HISTOR_MONE_MER_ID.NEXTVAL
  INTO   :new.id
  FROM   dual;
END;
/
create or replace
TRIGGER "1.4.MERCADO_ID_AUTOINCREMENTO" 
  BEFORE INSERT ON MERCADO
  FOR EACH ROW
  BEGIN
  SELECT id
  INTO   :new.id FROM MONEDA
  where NOMBRE= :new.NOMBRE;
END;
/
  CREATE OR REPLACE TRIGGER "1.5.MONEDA_ID_AUTOINCREMENTO" 
  BEFORE INSERT ON MONEDA 
  FOR EACH ROW
  BEGIN
  SELECT secuencia_MONEDA_ID.NEXTVAL
  INTO   :new.id
  FROM   dual;
END;
/
  CREATE OR REPLACE TRIGGER "1.6.MONEDERO_ID_AUTOINCREMENTO" 
  BEFORE INSERT ON MONEDERO
  FOR EACH ROW
BEGIN
  SELECT secuencia_MONEDERO_ID.NEXTVAL
  INTO   :new.id
  FROM   dual;
END;
/
CREATE OR REPLACE TRIGGER "1.7.USUARIO_ID_AUTO"
  BEFORE INSERT ON USUARIO
  FOR EACH ROW
BEGIN
  SELECT secuencia_USUARIO_ID.NEXTVAL
  INTO   :new.id
  FROM   dual;
END;
/
create or replace
TRIGGER "6.TRADING_ACTUALIZA_TRANSAON" 
  before INSERT ON HISTORIAL_COMPRA_VENTA 
  FOR EACH ROW
declare
  	--transaccion_seleccionada compra_venta%ROWTYPE; 
    transaccion_id INTEGER;
    transaccion_monto number;
    transaccion_cantidad number;
    transaccion_metodo_realizado VARCHAR2(200);
    transaccion_tipo VARCHAR2(50);
    
    /*************cursor dinamico**********/
    TYPE EmpCurTyp IS REF CURSOR;
    cursor_tran   EmpCurTyp;
    emp_rec  compra_venta%ROWTYPE;
    v_stmt_str VARCHAR2(200);  
    /*****************************************/
    
    id_mone integer;
    id_mone1 integer;
    salir integer :=0;
    
    
  TYPE matriz_rowid IS TABLE OF compra_venta.id%TYPE;
  TYPE matriz_col1 IS TABLE OF compra_venta.cantidad%TYPE;
  TYPE matriz_col2 IS TABLE OF compra_venta.monto%TYPE;  
  emp_id matriz_rowid;
  emp_cantidad matriz_col1;
  emp_monto matriz_col2;    
    
    
BEGIN

  select id, cantidad, monto,tipo, metodo_realizado
  into transaccion_id,transaccion_cantidad,transaccion_monto,transaccion_tipo,
  transaccion_metodo_realizado
  from compra_venta 
  where :new.id_transaccion_prin = id;
 
  if(transaccion_metodo_realizado='mercado' or transaccion_metodo_realizado='limit')then
     
      v_stmt_str := 'SELECT id,cantidad,monto FROM compra_venta where tipo !='''|| transaccion_tipo 
                    ||''' and id IN (select ID_TRANSACCION_PRIN from HISTORIAL_COMPRA_VENTA where ID_MERCADO='
                    || :new.id_mercado ||' and ID_MONEDA_CANTIDAD ='|| :new.id_moneda_cantidad || ' )'
                    ||' and orden_estado = :j';
     
     OPEN cursor_tran FOR v_stmt_str USING 0;
     LOOP
        FETCH cursor_tran  BULK COLLECT INTO emp_id,emp_cantidad,emp_monto;
        
        for i in 1..emp_id.count loop

               -- procesamiento
              if(transaccion_tipo='venta')  then      
                  if(transaccion_cantidad <= emp_cantidad(i))then
                      if(transaccion_monto <= emp_monto(i))then
                                                              
                          :new.id_trans_contraria_pri := emp_id(i);
                          update HISTORIAL_COMPRA_VENTA set id_trans_contraria_pri = transaccion_id,
                                                            fecha_trasaccion_cerrada=sysdate
                                                        where id_transaccion_prin=emp_id(i);
                          --pasar ambas transaciones a cerrado
                          update COMPRA_VENTA set ORDEN_ESTADO = 1 where id=emp_id(i) or id= transaccion_id;
                    
                                /*******parte de seleccionar y actualizar el monedero **************/
                                select id_monedero_cantidad,id_monedero_monto into id_mone, id_mone1 from historial_compra_venta 
                                where id_transaccion_prin = emp_id(i);
                                
                                update monedero set cantidad_actual =( (cantidad_actual) - (transaccion_cantidad)) 
                                where id = :new.id_monedero_cantidad;
                                
                                update monedero set cantidad_actual =( (cantidad_actual) + (transaccion_monto)) 
                                where id = :new.id_monedero_monto;                          
                                
                                update monedero set cantidad_actual = cantidad_actual + emp_cantidad(i)
                                where id=id_mone;
                                             
                                update monedero set cantidad_actual = cantidad_actual - emp_monto(i)
                                where id=id_mone1;
                                /***********************************fin de la actualizacion monedero*****************/
                                salir:=1;
                      end if;
                  end if;
              ELSIF(transaccion_tipo='compra')   then     
                  
                  if(transaccion_cantidad >= emp_cantidad(i))then
                      if(transaccion_monto >= emp_monto(i))then
      
                          :new.id_trans_contraria_pri := emp_id(i);
                          update HISTORIAL_COMPRA_VENTA set id_trans_contraria_pri = transaccion_id,
                                                                                fecha_trasaccion_cerrada=sysdate
                                                        where id_transaccion_prin=emp_id(i);
                          --pasar ambas transaciones a cerrado
                          update COMPRA_VENTA set ORDEN_ESTADO = 1 where id=emp_id(i) or id= transaccion_id;
                          
                                /*******parte de seleccionar y actualizar el monedero **************/
                                select id_monedero_cantidad,id_monedero_monto into id_mone, id_mone1 from historial_compra_venta 
                                where id_transaccion_prin = emp_id(i);
                                
                                update monedero set cantidad_actual =( (cantidad_actual) + (transaccion_cantidad)) 
                                where id = :new.id_monedero_cantidad;
                                
                                update monedero set cantidad_actual =( (cantidad_actual) - (transaccion_monto)) 
                                where id = :new.id_monedero_monto;                          
                                
                                update monedero set cantidad_actual = cantidad_actual - emp_cantidad(i)
                                where id=id_mone;
                                             
                                update monedero set cantidad_actual = cantidad_actual + emp_monto(i)
                                where id=id_mone1;
                                /***********************************fin de la actualizacion monedero*****************/ 
                                salir:=1;
                      end if;
                  end if;
              end if;           
        end loop;
        EXIT WHEN cursor_tran%NOTFOUND;
        EXIT WHEN salir=1;        
    END LOOP;
    CLOSE cursor_tran;
 end if;
end;
/
--------------------------------------------------------
  CREATE OR REPLACE TRIGGER "2.1VERIFICAR_MAYOR_EDAD" 
  BEFORE INSERT ON USUARIO 
  FOR EACH ROW
declare
edad INTEGER;
VALOR_MENOR EXCEPTION;
begin

SELECT trunc((SYSDATE - to_date(:new.datos.fecha_nacimiento,'DD/MM/rrrr'))/365,0)into edad FROM dual;
	IF edad < 18 THEN
		RAISE VALOR_MENOR;
	END IF;
  
EXCEPTION
  -- Excepcion
  WHEN VALOR_MENOR THEN
	  dbms_output.put_line('la edad no puede ser menor a 18 años');
    --ROLLBACK TRANSACTION;
END;
/
create or replace TRIGGER "2.2CREAR_MONEDERO" 
after INSERT ON USUARIO 
FOR EACH ROW
declare
    CURSOR id_moneda_cursor IS  SELECT id FROM  moneda;     
    i integer :=1;
     TYPE matriz_col1 IS TABLE OF moneda.id%TYPE;
     col1 matriz_col1;
BEGIN 
   OPEN id_moneda_cursor;
   LOOP
   FETCH id_moneda_cursor bulk collect INTO col1 limit 4;    
      
      FORALL i IN 1 ..col1.count
          insert into monedero(id_usuario, id_moneda, cantidad_actual,cantidad_monedero) 
          values(:new.id, col1(i),0,H_MONEDERO(MONEDEROS_H(0,sysdate)));    
          
      EXIT WHEN id_moneda_cursor%NOTFOUND;       
                
      END LOOP;
      close id_moneda_cursor;
end; 
/
create or replace
PROCEDURE "H05_SIMULA_5_MILLON_TRADING" (cantidad_transaccion integer,id_moneda1 integer ,id_mercado integer) 
as
   type tipoArreglo IS VARRAY(2) OF VARCHAR2(50);
   type tipoMetodo_realizado IS VARRAY(3) OF VARCHAR2(50); 
   tipo tipoArreglo;
   tipoMetodo tipoMetodo_realizado; 

   ali_cantidad integer;
   ali_monto integer;
   ali_tipo integer;
   ali_tipo_metodo integer;

   ali_precio_maximo integer;
   ali_precio_stop integer;
   valor_mercado integer;
   contador integer;
   mayor_numero_monedero integer; --el recibira el parametro mas grande que haya en todos los monederos 
   valor_mercado_select integer; --el recibira el parametro con el valor en el mercado     


  monto integer;
  id_transaccion integer;
  CURSOR cur IS SELECT m1.id, m1.cantidad_actual, m2.id, m2.cantidad_actual
          FROM   MONEDERO m1, MONEDERO m2
          where m2.id_usuario = m1.id_usuario and m2.id_moneda =id_mercado and m1.id_moneda=id_moneda1
          ORDER BY DBMS_RANDOM.VALUE;
          
  TYPE matriz_rowid IS TABLE OF monedero.id%TYPE;
  TYPE matriz_col1 IS TABLE OF monedero.cantidad_actual%TYPE;
  
  m_rowid matriz_rowid;
  m_col1 matriz_col1;
  
    TYPE matriz_rowid_1 IS TABLE OF monedero.id%TYPE;
  TYPE matriz_col1_1 IS TABLE OF monedero.cantidad_actual%TYPE;
  
  m_rowid_2 matriz_rowid_1;
  m_col1_2 matriz_col1_1;
  con number:=2000;
  i integer;
 fehca date;
BEGIN 

      tipo:=tipoArreglo('compra','venta');
      tipoMetodo:= tipoMetodo_realizado('mercado','limit','stop_limit');
         
     select max(fecha_dia)
     into fehca
     FROM   historial_monedas_mercado
     where id_mercado= id_mercado and id_moneda= id_moneda1; 
     
     select valor_mercado_dia
     into valor_mercado_select
     FROM   historial_monedas_mercado
     where id_mercado= id_mercado and id_moneda= id_moneda1 and fecha_dia=fehca and rownum = 1; 
         
  contador:=0;
  OPEN cur ;
  LOOP
    FETCH cur BULK COLLECT INTO m_rowid, m_col1,m_rowid_2, m_col1_2 ;

     for i in 1..cantidad_transaccion loop
      /******************************ALEATORIOS*****************/     
      ali_cantidad := dbms_random.value(1,m_col1(i));
      ali_monto := dbms_random.value(1,m_col1_2(i)); --el monto es aleatorio
      ali_tipo := dbms_random.value(1,2);
      ali_tipo_metodo := dbms_random.value(1,3); 
      ali_precio_maximo := dbms_random.value(1,795);

      if (tipo(ali_tipo) = 'compra') then  --cuando compras el precio stop tiene que ser mas alto que el precio que tu fijas
        ali_precio_stop := dbms_random.value(ali_monto,m_col1_2(i));
      end if;
      
      if(tipo(ali_tipo) = 'venta') then   --cuando vendes el precio stop tiene que ser mas bajo que el precio que tu fijas
        ali_precio_stop := dbms_random.value(1,ali_monto);
      end if;
        
     if (tipoMetodo(ali_tipo_metodo) = 'mercado') then
          insert into COMPRA_VENTA(monto,cantidad,tipo,orden_estado,metodo_realizado,Valor_mercado) 
          values(valor_mercado_select,ali_cantidad,tipo(ali_tipo),0, tipoMetodo(ali_tipo_metodo),valor_mercado_select);
     elsif (tipoMetodo(ali_tipo_metodo) = 'limit') then
           insert into COMPRA_VENTA(monto,cantidad,tipo,orden_estado,metodo_realizado,Precio_limit) 
            values(ali_monto,ali_cantidad,tipo(ali_tipo),0,tipoMetodo(ali_tipo_metodo),ali_monto);              
      ELSIF (tipoMetodo(ali_tipo_metodo) = 'stop_limit') then
             insert into COMPRA_VENTA(monto,cantidad,tipo,orden_estado,metodo_realizado,Valor_mercado,Precio_limit,Precio_stop) 
              values(ali_monto,ali_cantidad,tipo(ali_tipo),0,tipoMetodo(ali_tipo_metodo),valor_mercado_select,ali_monto,ali_precio_stop);
      end if; 
              
      /*****para saber la id de esta transaccion que se creara***/
      SELECT max(id) INTO id_transaccion FROM   COMPRA_VENTA;
                /*********************************************************/
                
      insert into historial_compra_venta(fecha_realizada_transaccion, id_monedero_cantidad,
                   id_monedero_monto, id_transaccion_prin, 
                   id_mercado,id_moneda_cantidad)
      values (sysdate,m_rowid(i),m_rowid_2(i),id_transaccion,id_mercado,id_moneda1);
    /********************************FIN LLENADO TRANSACCIONES***************************************/    		
    end loop;
    EXIT WHEN cur%NOTFOUND;
  END LOOP;
  CLOSE cur;
end; 
/
create or replace
PROCEDURE "H07_SIMULA_DEPOSI_RETIRO" (trans integer)
as
  monto integer;
  id_transaccion integer;
  CURSOR cur IS SELECT id
                FROM   MONEDERO
                ORDER BY DBMS_RANDOM.VALUE;
          
  TYPE matriz_rowid IS TABLE OF monedero.id%TYPE;
 
  m_rowid matriz_rowid;
  
  type tipoArreglo IS VARRAY(2) OF VARCHAR2(50);
 tipo tipoArreglo;
 ali_cantidad integer;
 ali_tipo integer;
BEGIN 

  tipo:=tipoArreglo('Deposito','retiro');        
  OPEN cur ;
  LOOP
    FETCH cur BULK COLLECT INTO m_rowid;

     for i in 1..trans loop
      /******************************ALEATORIOS*****************/     
      ali_cantidad := dbms_random.value(1,9999);
      ali_tipo := dbms_random.value(1,2); 
      
          /********************************INSERCION DE DEPOSITOS_RETIROSS*******************/
          if (tipo(ali_tipo) = 'Deposito') or (tipo(ali_tipo) = 'retiro')then   
                  insert into DEPOSITO_RETIRO(cantidad,tipo,concepto) 
                  values(ali_cantidad,tipo(ali_tipo),'pues no se xd');
          end if;   
              
      /*****para saber la id de esta transaccion que se creara***/
      SELECT max(id) INTO id_transaccion FROM   DEPOSITO_RETIRO;
                /*********************************************************/
      insert into Historial_DEPOSITO_RETIRO(id_monedero, id_transaccion, fecha_realizado_inicio)
      values (m_rowid(i), id_transaccion,sysdate);  
                  		
    end loop;
    EXIT WHEN cur%NOTFOUND;
  END LOOP;
  CLOSE cur;
end; 
/
create or replace PROCEDURE "H04_CREAR_MONEDERO_ALEATORIO" 
as
  TYPE matriz_rowid IS TABLE OF monedero.id%TYPE;
  TYPE matriz_col1 IS TABLE OF monedero.cantidad_actual%TYPE;
  
  CURSOR cur IS SELECT id, cantidad_actual FROM monedero;
  m_rowid matriz_rowid;
  m_col1 matriz_col1;
  contador NUMBER := 2000;
BEGIN
  OPEN cur;
  LOOP
    FETCH cur BULK COLLECT INTO m_rowid, m_col1 LIMIT contador;
    FOR i IN 1 .. m_rowid.count
    LOOP
      m_col1(i):= trunc(dbms_random.value(1,999),2);
    END LOOP;
    FORALL i IN 1 .. m_rowid.count
      UPDATE monedero
        SET cantidad_actual = m_col1(i)
        WHERE id = m_rowid(i);
    EXIT WHEN cur%NOTFOUND;
  END LOOP;
  CLOSE cur;
END;
/
create or replace
PROCEDURE "H03_CREAR_USUARIOS_ALEATORIO" (cantidad_Usuario integer) authid current_user
as
   type nombresArreglo IS VARRAY(800) OF VARCHAR2(50);
   type apellidosArreglo IS VARRAY(1600) OF VARCHAR2(50);  
   type paisesArreglo IS VARRAY(200) OF VARCHAR2(50);
   type tipoArreglo IS VARRAY(3) OF VARCHAR2(50);
   nombre nombresArreglo; 
   apellido apellidosArreglo; 
   pais paisesArreglo; 
   tipo tipoArreglo;
 
   ali_nombre integer;
   ali_apellido integer;
   ali_nombre_2 integer;
   ali_apellido_2 integer;
   ali_sexo integer;
   ali_pais integer;
   ali_pais_2 integer;
   pais_diferente integer;
   ali_fecha_nacimiento date;
   ali_fecha_creacion date;
   ali_telefono integer;
   ali_verifiacion integer;
   ali_tipo integer;
   contador integer;

   mi_email varchar2(100);
   mi_usuario varchar2(100);
BEGIN 

   nombre := nombresArreglo('BENJAMÍN0','VICENTE','MARTÍN','MATÍAS','JOAQUÍN','AGUSTÍN','MAXIMILIANO'
,'CRISTÓBAL','SEBASTIÁN','TOMÁS','DIEGO','JOSÉ','NICOLÁS','FELIPE','LUCAS','JUAN','ALONSO'
,'BASTIÁN','GABRIEL','IGNACIO','FRANCISCO','RENATO','MATEO','MÁXIMO','JAVIER','LUIS','DANIEL'
,'GASPAR','CARLOS','ANGEL','FERNANDO','FRANCO','EMILIO','PABLO','SANTIAGO','CRISTIAN'
,'DAVID','ESTEBAN','JORGE','RODRIGO','ALEXANDER','CAMILO','AMARO','LUCIANO','BRUNO','DAMIÁN'
,'ALEXIS','ALEJANDRO','VÍCTOR','MANUEL','PEDRO','FABIÁN','JULIÁN','KEVIN','MIGUEL','SIMÓN'
,'IAN','THOMAS','EDUARDO','CRISTOPHER','ANDRÉS','DYLAN','LEÓN','RAFAEL','GUSTAVO','LEONARDO','JEAN','GONZALO'
,'ÁLVARO','SERGIO','DANTE','RICARDO','LUKAS','MARCELO','ALAN','ELÍAS','OSCAR','MAURICIO'
,'CLAUDIO','CLEMENTE','JESÚS','PATRICIO','SAMUEL','HÉCTOR','ALEX','ARIEL','EMILIANO'
,'AXEL','ROBERTO','CÉSAR','ISAAC','JOHAN','JONATHAN','ANTONIO','GUILLERMO','MARIO','CRISTOFER'
,'IVAN','AARON','CHRISTOPHER','JUSTIN','BRAYAN','BENJAMIN','MARCO','LEANDRO','DILAN','ANGELO'
,'BRANDON','FACUNDO','EZEQUIEL','MATHIAS','ALFONSO','ISAIAS','RAÚL','CHRISTIAN','MOISÉS','JORDÁN'
,'DEMIAN','ENZO','JOSUE','JAIME','JEREMY','VALENTÍN','RAIMUNDO','JULIO','BRYAN','EXEQUIEL'
,'BALTAZAR','ISMAEL','SALVADOR','GIOVANNI','ANÍBAL','GASTÓN','MATIAS','SEBASTIAN'
,'MARCOS','ABRAHAM','ARTURO','WILLIAMS','HANS','MARTIN','DARÍO','JOSEPH','ERICK','MICHAEL'
,'JEREMÍAS','HUGO','JOSHUA','EMANUEL','JOEL','HERNÁN','NELSON','JOHN','THOMÁS','ANTHONY'
,'OCTAVIO','BAYRON','CRISTOBAL','LORENZO','DOMINGO','MAURO','RICHARD','WILLIAM','CRISTIÁN','JOHANS'
,'AMARU','JOSUÉ','LEONE','PIERO','JOAN','ENRIQUE','MILOVAN','OMAR','RUBÉN','JAIRO'
,'GERARDO','GERMÁN','ANDY','MARIANO','AUGUSTO','DANILO','EDGAR','NICOLAS','ALFREDO','JOSE'
,'AARÓN','PAULO','RODOLFO','OLIVER','FÉLIX','IKER','MAX','PAOLO','JHON','STEVEN','ALBERTO','MISAEL'
,'JOAQUIN','ISRAEL','ADOLFO','GERALD','AGUSTIN','BORJA','MAICOL','SAID','EDISON','NAHUEL','TOMAS','ALAIN'
,'ÁNGEL','BRIAN','MAXIMO','BASTIAN','ERIC','OSVALDO','EDWARD','LAUTARO','RENÉ','BERNARDO','ETHAN'
,'THIAGO','WLADIMIR','BORIS','BYRON','JADIEL','PATRICK','AQUILES','BAIRON','EMMANUEL','JUAQUIN'
,'PAUL','ABEL','ADRIÁN','EVAN','RONALD','ALEN','ANDREW','CRISTHIAN','IVÁN','GIOVANNY'
,'JACOB','ROBERT','ROMÁN','WILSON','ALESSANDRO','BRANCO','ERIK','IÑAKI','JOHANN','LIAN','LIONEL'
,'YOHAN','DAMIAN','JORDAN','MAIKOL','MARK','MATTEO','WALTER','YORDAN','ARON','STEFANO'
,'YEREMI','ERNESTO','GAEL','GIULIANO','JIMMY','JASON','ORLANDO','ALDO','EMERSON','EVANS','HENRY'
,'SAMIR','VICTOR','JAIR','ELIAN','FEDERICO','FREDDY','HAROLD','ITALO','JONATAN'
,'ROLANDO','XAVIER','YAIR','ADÁN','ALONZO','AMIR','BRAULIO','DARIEL','RENZO','VALENTINO'
,'DIDIER','EDGARDO','RAMÓN','SANTINO','EIDAN','ERWIN','FABIAN','JOSTIN','NIKOLAS','ROBINSON'
,'VLADIMIR','EYDAN','ISAÍAS','ABDIEL','CRISTHOFER','DARIEN','ELOY','FRANKO','JHONATAN','LUCA'
,'VINCENT','YONATHAN','EFRAÍN','GINO','NATANAEL','NEHEMIAS','YAHIR','YEREMY','AIDAN','ALVARO'
,'JASTIN','JULIAN','YASTIN','ANDERSON','CESAR','LUCIAN','RAMIRO','TIAGO','EDSON','GIORDANO'
,'GUIDO','JULIANO','MAYKOL','MILTON','PASCUA','YADIEL','YOEL','CARLO','DARWIN','FLAVIO'
,'FRANK','IHAN','JHOAN','ROGER','SAÚL','TRISTÁN','YERKO','YOAN','ADIEL','ALLAN'
,'ANTONY','GERSON','INTI','LIAM','REINALDO','ANDRÉ','ANDRES','ANTOINE','CHRISTOFER','DANNY'
,'DEREK','DORIAN','DUSTIN','ELISEO','ELLIOT','GIANFRANCO','HEBER','ELIAS','FABIO','JEISON'
,'JEREMI','JOSIAS','LEONIDAS','MARCIAL','MIRKO','YERAL','ABNER','ALEXSANDER','ARMANDO','AUSTIN'
,'GARY','IÑIGO','JOAO','JONAS','JORDANO','MATHÍAS','NICHOLAS','ULISES','BASTHIAN','BENITO'
,'DERECK','DYLAND','EDGARD','EDWIN','JAN','JESUS','LUCIO','LUCKAS','MICHEL','NATANIEL'
,'RAPHAEL','TOBÍAS','VITTORIO','ANTHUAN','ANTUAN','FREDY','HUMBERTO','JHONNY','MATHEO','NÉSTOR'
,'SIMON','TEO','URIE','ALEXI','ANTU','CALEB','CHRIS','GADIEL','GENARO','GERARD'
,'HERMAN','JEFFERSON','MARLON','MATTHEW','MILAN','YAMIL','YEISON','YOJAN','YULIANO','ADONIS'
,'ADRIANO','ANDRE','APOLO','BRANKO','EDER','EDINSON','EMIR','FABRICIO','GREGORIO','JAMES'
,'JARED','JOAKIN','JOHAO','KURT','MARCE','MAYCOL','NAIM','PHILIPPE','YULIAN','ADAM'
,'ALLEN','ANDER','CRISTOFHER','EDUARD','ESTEFANO','FRANCESCO','GIAN','JACK','KARIM'
,'LUKA','MARTHIN','MASSIMO','MATTIAS','SEGUNDO','YAN','YOJHAN','YOSHUA','YOSTIN','BALTASAR'
,'BAUTISTA','CRISTIANO','DENZEL','EITHAN','FERMÍN','FRANZ','GIANCARLO','JAHIR','JEFERSON'
,'JERSON','LUCCIANO','MAICKOL','MATIA','NOAH','RANDY','SANTOS','VASCO','YAMIR','ADRIEL'
,'ALÉN','ANGELLO','ANYELO','AXL','BRUCE','CHRISTOBAL','DANKO','DASTIN','DIXON','ELVI'
,'EYTHAN','FABIANO','GREGORY','HECTOR','IANN','JEREMMY','JIM','KENNETH','MAIKEL','NICANOR','OSTIN','SILVESTRE'
,'ALBERT','CHRISTIÁN','DAYRON','ELEAZAR','EUGENIO','EVER','FARIDLEO','LUCCA','LYAN','MIGUELANGEL','ROQUE'
,'SANDRO','STEFAN','STIVEN','YOHANS','ALEXANDRE','ARAMIS','BENYAMIN','BLADIMIR','BLAS','DAVOR'
,'DEIVID','FAVIO','FELIX','FIDEL','GEORGE','ÍAN','ISAI','JERÓNIMO','LENIN','NATHAN'
,'NATHANIEL','ROY','TOMMY','WILLIAN','YEIKO','YERSON','ADRIAN','ALI','ANIBAL'
,'BELTRÁN','BILLY','DARIAN','DAVIS','DEIVY','EDUAR','ELIEL','ESTIVEN','FABRIZIO','GEREMY'
,'GIANLUCA','GIOVANI','ITHAN','IVO','JEREMIAS','JHORDAN','JOSÉ-TOMÁS','JOSÍAS'
,'JUANPABLO','LEON','LISANDRO','LOGAN','MOISES','NAHIR','NAIN','NEFTALÍ','NEHEMÍAS'
,'NEIL','NORMAN','PIERRE','RAYMOND','REMIGIO','RENATTO','ROBERTH','ROMAN','RONALDO'
,'RYAN','THEO','VALENTIN','VINCENZO','YHAN','YONATAN','ZAHIR','AIRON','AITOR'
,'AMÉRICO','ANTON','ARMIN','ARTHUR','CRISTHOPER','DAN','DEMIS','DEMYAN','DIOGO','EDWARDS'
,'ELIEZER','FRANKLIN','GEOVANNY','HEYDAN','HORACIO','JEANPIERRE','JEYSON','JHOEL','JOHAQUIN'
,'JUNIOR','KAMILO','KEVYN','KRISTOPHER','MAIQUEL','MARC','MARCK','MARTYN','MIKEL'
,'NICKOLAS','OWEN','RAUL','SAMI','STEPHANO','STEVENS','TAREK','YAEL','YERALD'
,'YOVANI','ADEMIR','AKILES','ARNALDO','BÁSTIAN','BERNABÉ','DASTYN','DOMÉNICO'
,'DONOVAN','DUSAN','DUVAN','EBER','EITAN','ELMER','EXZEQUIEL','GORAN','JANS'
,'JHANS','JHEREMY','JHOSEP','JOHNNY','JOSTYN','JOVANY','JUAN-PABLO','KAI','KRISTOBAL'
,'LENNY','LEOPOLDO','LESTER','LUCCAS','MAGDIEL','MARKO','MATHYAS','MATTHIAS'
,'MAYKEL','MILÁN','NABIH','NAHUM','NAWEL','NOEL','OCIEL','OTONIEL','PASCAL'
,'PAU','PHILIP','PHILLIP','ROMEO','RONAL','SALOMÓN','SEAN','STEPHAN','VIKTOR'
,'WALDO','WILFREDO','WILLIANS','YORDANO','ZAID','ZAMIR','ALEEN','ALEXANDRO','ALIRO'
,'ANAKIN','ARIKI','AXCEL','BALTHAZAR','BASTÍANBENJAMYN','BRAIAN','CRISTHOBAL'
,'CRISTIÀN','DÁMIAN','DAMIR','DEIVI','DEMMIAN','DEYLAN','ELIAM','ELIÁN','ELIO'
,'ELIOT','ELUNEY','FABRIZZIO','GAMALIEL','GASTON','GEAN','GEREMÍAS','GIANCARLOS'
,'GIORGIO','GORKA','HERNAN','ISAAK','JACOBO','JEANS','JHOSTIN','JORDI','JOSEP'
,'JOSTHYN','JOSÚE','JUANJOSE','KELVIN','KENNY','KILIAN','KRISTIAN','LOUIS','MANU'
,'MARKUS','MATTIA','MAXI','MAXIMILIAN','MIJAEL','MIQUEAS','MITCHELL','NAHIM'
,'NAIR','NIBALDO','NIKOLÁS','ROBIN','RUDY','SEBASTÍAN','SILVIO','TIZIANO','VINCEN'
,'YAZID','YEFERSON','YERAY','YOSEF','ABRAHAN','ABRAM','ALANN','ALDAIR','AMADOR','ANCEL'
,'ANDRIU','ANTÜ','ANTWAN','ARÍSTIDES','AUGUSTIN','AYDAN','AYRON','BRYAM','CAIN','CELSO'
,'CHRISS','CHRISTHIAN','CRESCENTE','DARIO','DARKO','DAUD','DÉMIAN','DENNIS','DIAN'
,'DIETER','DOMINIC','DUBAN','DYLANN','EDDIE','ELIOTH','ERVIN','EZEKIEL','GERÓNIMO'
,'GILBERTO','GIUSEPPE','HENRRY','HERIBERTO');
   
      apellido := apellidosArreglo('Abila','Abina','Abitua','Aboites','Abonce','Abrego','Abrica','Abrigo','Abundis','Aburto',
'Acebedo','Acebes','Acencio','Acero','Acevedo','Aceves','Acha','Adan','Adrian','Agirre',
'Agredano','Aguado','Aguallo','Aguas','Aguayo','Agueda','Aguero','Aguila','Aguilar','Aguilera',
'Aguinaga','Aguino','Aguirre','Agundis','Ahuatl','Ahumada','Aiala','Aillon','Alamilla','Alamiya',
'Alamo','Alanis','Alarcon','Alatorre','Alatriste','Alaves','Alba','Albarado','Albarran','Alberto',
'Albino','Albis','Albornos','Alcantar','Alcaras','Alcocer','Alcorta','Aldaco','Aldape','Aldaz',
'lderete','Alejandro','Alejo','Aleman','Alexos','Alfaro','Alferes','Alfonso','Alguera','Allala',
'Allende','Almager','Almaguer','Almanza','Almaras','Almasan','Almeda','Almejo','Almendares',
'Almodovar','Almonte','Almorin','Alonzo','Altamirano','Altra','Altusar','Alva','Alvarado',
'Alvares','Alverto','Alvidres','Alvillar','Alvino','Alviso','Amador','Amalla','Amaral','Amarilla',
'Amaro','Amaya','Ambris','Ambrocio','Americano','Amescua','Amesola','Amesquita','Ana','Analla',
'Anaya','Anda','Anderson','Andrada','Andrade','Andres','Andrews','Angel','Angeles','Angiano',
'Angon','Anguiano','Angulo','Ansures','Antillon','Antonio','Antuna','Antunes','Aparicio',
'Apodaca','Apolinar','Apresa','','Aquallo','Aquilar','Aquirre','Ara','Aragon','Araiza','Arana',
'Aranda','Arango','Aranguti','Araujo','Araus','Arauxo','Arayza','Arbizu','Arce','Arceo','Arcia','Arciniega',
'Arcola','Arebalo','Arechiga','Aredondo','Arellano','Arenas','Arevalo','Areyano','Argote',
'Arguelles','Arguello','Argueta','Arguijo','Arias','Ariola','Arisa','Arisaga','Arismendis',
'Arispe','Ariza','Arizaga','Armadillo','Armendaris','Armengol','Armenta','Armijo','Aro','Aroche',
'Aros','Aroyo','Arpero','Arrasola','','Arrayales','Arreaga','Arredondo','Arreguin','Arreola',
'Arreortua','Arrequin','Arriaga','Arrieta','Arriola','Arroio','Arrollo','Arrona','Arroyo',
'Arsate','Arse','Arsiga','Arsiniega','Arsola','Arteaga','Arujo','Arze','Arzola','Asa','Ascona','Asebes',
'Asencio','Asero','Asevedo','Aseves','Aspitia','Astorga','Astudillo','Asuara','Atilano',
'Atondo','Auguiano','Aumada','Aurioles','Avelino','Avila','Aviles','Avilla','Avitia','Ayon',
'Azebedo','Azero','Azevedo','Baca','Bacasegua','Badillo','Badiola','Baena','Baes','Bahena',
'Baina','Baisa','Baker','Balades','Balbaneda','Balberde','Balbuena','Balderas','Baldes','Baldespino',
'Baldibia','Baldivia','Baldivieso','Baldonado','Baldovinos','Balencia','Balencuela','Balensuela',
'Balentin','Balenzuela','Balero','Balladares','Ballarta','Ballejo','Ballesa','Ballesteros',
'Ballin','Ballinas','Balona','Balseca','Baltierres','Balverde','Balvuena','Banderas','Bandilla','Banegas',
'Banes','Baptista','Baquera','Baragan','Barajas','Baraxas','Barba','Barbero','Barcenas','Barco',
'Barela','Barientos','Barques','Barra','Barragan','Barrales','Barranco','Barraza','Barreda','Barreto',
'Barrentes','Barrientos','Barron','Barros','Barroso','Barsena','Barunda','Barva','Barvosa',
'Barzena','Basgues','Basques','Basulto','Basurto','Bata','Batres','Bautista','Bayejo','Baylon',
'Bazan','Becerra','Becerril','Bedolla','Bedoya','Bega','Begil','Bejarano','Bela','Belarde','Belasco',
'Belasques','Belendes','Belis','Belman','Belmontes','Belmudes','Belos','Beltran','Benabides',
'Benegas','Benites','Benito','Bentura','Bera','Berber','Berdin','Berdusco','Bergara','Bermejo',
'Bermudes','Bernal','Bernales','Bernardino','Berra','Berrio','Berrones','Berruecos','Bertis','Berumen',
'Beserra','Betancourt','Betancur','Bexarano','Bibaldo','Bibas','Bidal','Bidales','Biera',
'Bigueria','Billa','Billagomes','Billalobos','Billalovos','Billalpando','Billanueba','Billanueva',
'Billasenor','Billegas','Biscarra','Blancarte','Blancas','Blanco','Blas','Bobadilla','Bocanegra',
'Bocardo','Bocas','Bojorques','Bolanos','Bona','Bonifacio','Bonilla','Bonito','Borbon','Borda','Borjas','Borrego',
'Bosque','Botello','Bovadilla','Boyd','Bracamontes','Bracho','Brambila','Bravo','Brena','Bribiesca',
'Briones','Brisena','Briseno','Brito','Brocal','Brooks','Brown','Bruno','Brusiaga','Buelna','Buen',
'uenabides','uenavides','Buendia','Bueno','Buenrostro','Buentello','Bugarin','Buitimea','Buitron',
'Burciaga','Burgos','Burnett','Bustamante','Bustos','Butanda','Butierres','Byrd','Caacuaa',
'Caacusi','Caaghu','Caasayu','Caballero','Cabanillas','Cabello','Cabesa','Cabral','Cabrera',
'Cabriales','Cacalotl','Cacillas','Cacimiro','Caco','Cacuaa','Cacuiy','Cacusi','Caghi','Caghu',
'Cague','Caguihui','Cahua','Cahuaco','Cahuidzu','Cahuiyo','Calata','Calbario','Calbo','Caldera','Calderon',
'Calisto','Calistro','Callejas','Calleros','Calles','Calletano','Calsada','Calvario','Calvillo',
'Calzada','Cama','Camacho','Camahu','Camarena','Camargo','Camarillo','Camau','Camberos','Cambray',
'Camino','Campa','','Campillo','Campirano','Campos','Camposano','Campusano','Cana','Canal',
'Canceco','Canchola','Cancino','Candelaria','Candelario','Candia','Canedo','Canela','Canencia',
'Cano','Canoa','Canpos','Canseco','Cansino','Cantero','Cantu','Canuu','Canzeco','Capasete','Capetillo',
'Capitrano','Caquihui','Cara','Carabajal','Caraballo','Carabantes','Carabaxal','Carandia','Carapia',
'Caasco','Caravallo','Caravantes','Cardenas','Cardiel','Cardona','Cardoso','Cariaga','Carillo',
'Carion','Carlin','Carlon','Carlos','Carmel','Carmona','Carnero','Caro','Carpintero','Carpio','Carrales',
'Carranco','Carrasco','arreno','Carrera','Carreto','Carrillo','Carrion','Carrisal','Carrisales','Carriyo','Carrizal','Carro',
'Carvaja','Casa','Casanoba','Casanova','Casares','Casas','Casasola','Casayu','Casco','Caseres','Casian',
'Castillo','Castiyo','Casto.','Castorena','Castrejon','Castrillo','Castro','Catalan','Catano','Catuta','Cavallero','Cavazos',
'Cavello','Cavrera','Cayetano','Cayo','Cazares','Ceballos','Cedeno','Cedillo','Ceja','Celaya',
'Celio','Celis','Cena','Centeno','Cepeda','Cerbantes','Cerda','Cermeno','Cerna','Ceron',
'Cerrano','Cerrato','Cerrillo','Certuche','Cervantes','Cervera','Cervin','Cevallos','Cevilla','
Chaca','Chacon','Chagolla','Chagollan','Chaire','Chantes','Chapa','Chapul','Charles','Charqueno','Chavarria','
Chavarrieta','Chaves','Chaveste','Chavez','Chavira','Chavolla','Chia','Chica','Chico','Chicuate','Chihuagua','
Clark','Claudio','Clemente','Cleto','Colchado','Colima','Colin','Colirio','Collado','Colmenares',
'Colmenero','Colorado','Colunga','Comparan','Compean','Concepcion','Condado','Conde','Conrrique','Constancia','Constante','Constantino',
'Contreras','Conuu','Copado','Coquau','Coquihui','Corales','Corchado','Cordoba','Cordova','Corea',
'Coreno','Coria','Cornejo','Cornelio','Coronado','Corral','Corrales','Correa','Corro','Cortes','Cortez',
'Cos','Cosa','Cosileon','Cosme','Costilla','Cota','Cotzomi','Covarrubias','Covarruvias','Covos','Cox',
'Coyaso','Coyo','Coyote','Coyotl','Coz','Cozatl','Cozileon','Crespin','Crespo','Crisanto','Crisostomo',
'Crispin','Cristan','Crus','Cruz','Cuachitl','Cuacitl','Cuacuil','Cuadros','Cuaetle','Cuatecatl',
'Cuatlat','Cuatlayol','Cuautle','Cuautli','Cuaya','Cuechi','Cuello','Cuenca','Cuesta','Cuevas',
'Cueyar','Cueyo','Cuin','Cumplido','Cura','Cusicuiy','Dabalos','abila','Dado','Damian','Daniel','Dasa',
'Davila','Daza','Delara','Delgadillo','Delgado','Delos','Delossantos','Deras','Diego',
'Dimas','Dionicio','Domingues','Dominguez','Donate','Dongu','Dorado','Dorantes','Duarte','Duenas',
'Duque','Duran','Duron','Echeverria','Eledesma','Elenes','Elias','Elisondo','Elizarraras','Elizondo','Enamorado','Encarnacion',
'Encinas','Enciso','Enriquez','Enrrique','Enrriquez','Ensiso','Eredia','Erera','Ernandes','Errera',
'Escalante','Escamilla','Escandon','Escobar','Escobedo','Escojido','Escovar','Escutia','Espalin','Espana',
'Esparcia','Esparza','Espejo','Espindola','Espinel','Espinola','Espinoza','Espiritu','Espitia','Esqueda',
'Esquibel','Esquibias','Esquivel','Esteban','Estebes','Estevan','Esteves','Estrada','Estrella','Estreya',
'Estudillo','Europa','Evangelista','Evans','Evora','Fabela','Fabian','Facio','Fajardo','Falcon',
'Farfan','Farias','Faustino','Faxardo','Feliciano','Felis','Feliz','Ferel','Fermin','Fernandes',
'Fernandez','Fernando','Ferreira','Ferrel','Fierro','Figueroa','Filoteo','Fiscal','Fletes','Flores',
'Florez','Fonceca','Fonseca','Frade','Fraga','Fragoso','Fraide','Fraile','Franca','Francisco',
'Franco','Frausto','Fregoso','Frias','Frutos','Fuente','Fuentes','Fuerte','Fulgencio','Funes',
'Gabia','Gabino','Gabriel','Gadillo','Gado','Galabis','Galan','Galarza','Galas','Galavis','Galban','Galbes','alego','Galicia',
'Galisia','Gallardo','Gallega','Gallegos','Gallo','Galvan','Galvana','Gama','Gamboa','Gamero',
'Games','Gamez','Gamino','Ganboa','Gandara','Gaona','Garambuyo','Garate','Garavito','Garay','Garcia','Gardea','Gaduno',
'Garfias','Garsa','Garsia','Garza','Garzia','Gasca','Gascon','Gaspar','Gastan','Gatica','Gauna','Gausin',
'Gavia','Gavilan','Gavilanes','Gavino','Gayardo','Gayo','Gaytan','Gazca','Gebara','George',
'Gerardo','Gerero','German','Gil','Gillen','Gimenes','Gimenez','Gines','Gloria','Gobea','Goche',
'Godina','Godines','Gonzalez','Gopar','Gordillo','Gordo','Govea','Gracia','Gradilla','Grageda',
'Grajales','Grajeda','Granado','Grande','Guadalaxara','Guadalupe','Guadarrama','Guanajuato','Guaracha',
'Gurdado','Guardia','Guardiola','Guarneros','Gudino','Guereca','Guerra','Guerrero','Guerta',
'Guete','Guevara','Guia','Guido','Guijarro','Guillen','Guilo','Guimenes','Guines','Guipe','Guisa',
'Guisar','Guiterres','Guiza','Gurrola','Gusman','Gutieres','Gutierrez','Haro','Harris','Haumada','Helguera',
'Henrique','Henriquez','Heredia','Hererra','Hermoso','Hernandes','Hernandez','Herrada','Herrera',
'Herver','Hibarra','Hierro','Higareda','Higuera','Hijar','Hilario','Hinojosa','Hornelas','Horosco',
'Horta','Hortega','Hortis','Huaracha','Huerta','Huisache','Huisar','Huitzil','Huizar','Humada','Hurtado','Hurvina',
'Hydalgo','Ianes','Ianito','Ibarra','Idalgo','Illescas','Infante','Inigues','','Inojos','Inojosa','Isarraras','Ivarra','Jacinto',
'Jaco','Jacoba','Jacobo','Jaen','','Jahuey','Jalpa','amaica','an','Jaques','Jara','Jaramillo','Jaramiyo',
'Jarquin','Jimenes','Jiron','Jonguitud','Huache','Juan','Juares','Jurado','Labra','Labrador','Ladino','Ladron','Lagunas','Lagunillas',
'Lala','Lamas','Lambarena','Landa','Landeros','Landeta','Landin','Langarcia','Langarica','Larios','Laris','Laro','Lasareno','Laso','Laureano','Lazareno','Lazaro',
'Lazo','Leal','Leandro','Leche','Lechuga','Leiba','Lemus','Leon','Leonardo','Leonor','Lepe','Lerma','Lesama','Leso','Letins',
'Levario','Leyba','Liebanos','Liera','Ligas','Lilo','Limon','Linan','nares','Lino','Lira','Lisama','Lisarde','Lisarraga','Lisea','Lisola','Lisondo','Llaguno',
'Llamas','Llanas','Llanes','Llanito','Llepes','Loayza','Lobato','Lobos','Loeza','Lomas','Lomeli','Lomelin','Longoria','Lopez','Loredo','Lorenzana',
'Lorenzano','Lorenzo','Loreto','Loria','Losada','Losano','Lossano','Lovato','Loya','Loza',
'Lozada','Luciano','Lucio','Luengas','Luevano','Lueza','Luga','Lugarda','Luguin','Lujan','Lule','Lumbreras',
'Luna','Lupercio','Lupez','Lupian','Luria','Luz','Macario','Macedo','Machado','Machorro','Macias','Maciel',
'Madaleno','Madera','Madrigal','Madrueno','Mafra','Magallanes','Magallon','Magana','Magdaleno','Maguellal','Maia','Maiorga',
'Malacara','Maldonado','Maleno','Malindo','Malo','Malpica','Mancera','Mancha','Mancilla','Mandujano',
'ani','Manriquez','Mansanales','Mansanares','Mansanero','Mansano','Mansilla','Manso','Mantilla','Manuel','Manzanales',
'Manzanares','Manzo','Maravilla','Marceleno','Marchan','Marcial','Mareno','Mares','Marfil',
'Margues','Maria','Mariano','Marimon','Marin','Marines','Marroquin','Marrufo','Martel','Martin','Martines',
'Martinon','Mascorro','Massias','Mata','Mateo','Mateos','Matheo','Mathias','Matias','Maturan','Maya','Mayor',
'Meave','Meda','Medel','Medellin','Medero','Medez','Medina','Medinilla','Megia','Mejia','Mejicano',
'Mejorada','Melecio','Melendres','Melesio','Melgar','Melgarejo','Melgoza','Mellado','Membrila','Mena',
'Menchaca','Mendes','Mendez','Mendia','Mendiola','Mendosa','Meneces','Meneses','Meras','Mercado','Merced',
'Mereles','Merino','Merlin','Merlo','Merodio','Mesquite','Messa','Mexia','Meza','Michaca','Miguel','Milan',
'Minchaca','Minero','Minguela','Mira','Miramontes','Miranda','Mireles','Mitzi','Moctesuma','Modesto','Mogica',
'Moia','Mojica','Molina','Molla','Molleda','Monares','Moncada','Moncayo','Mondragon','Monjaras','Monreal','Montana','Montanes',
'Montano','Monte','Montecillo','Montecinos','Montejano','Montelongo','Montemar','Montemayor','Monteon',
'Montero','Monterroso','Montesillo','Montesinos','Montesuma','Montez','Montiel','Montion','Montolla',
'Montoya','Montufar','Monzon','Mora','Morado','Moral','Morales','Morantes','Moras','Morelos','Moreno',
'Morentin','Morfin','Morgado','Morillo','Morin','Moriyo','Morones','Morquecho','Morras','Morua',
'Moscoso','Moso','Mosqueda','Mota','Motete','Mototl','Moxarro','Moxica','Moya','Moyeda','Moyotl',
'Muela','Mujica','Mulgado','Mundo','Mungia','Munguia','Munis','Munos','Murgo','Muriyo','Muro',
'Nabarro','Nabor','Nachi','Naco','Nagera','Naghi','Naghu','Nahuidzu','Nahuiyo','Najar','Najera','Nama','Namau',
'Namorado','Nanes','Napoles','Naquihui','Narbaes','Narvaez','Nasayu','Natividad','Natuta','Navarrete',
'aveda','Navia','Nayo','Nazario','Negreros','Negrete','Neira','Neri','Neria','Nesta','Neto',
'Nevares','Niave','Nicolaza','Niebes','Niebla','Nieva','Nieves','Nila','Nino','Noboa','Nocelotl','Noco',
'Nocuaa','Nocuiy','Nocusi','Nogales','Noghi','Nohuaco','Nohuidzu','Nohuiyo','Nolasco','Nollola',
'Noma','Nomau','Nopalera','Noquihui','Norabuena','Noriega','Nosa','Nosayu','Notario','Novoa','Noyo',
'Numau','Nuncio','Nunes','Nungarai','Nuno','Oballe','Obispo','Oblea','Obregon','Ocana','Ocaranza',
'Oceguera','Ochoa','Octavo','Ogalde','Olachia','Olaque','Oldorica','Olea','Olgin','Olguin','Oliba',
'Olibares','Olibas','Olibera','Oliva','Olivas','Olivera','Olivo','Olivos','Olmos','Olveda','Onate','Oporto',
'Oranday','Ordaz','Ordones','Ordorica','Orduno','Oregel','Oria','Oribe','Orihuela','Orisava','Orocio',
'Orona','Oropesa','Orosco','Orsua','Orta','Ortes','Ortigosa','Ortis','Ortuno','Osegueda','Osorio','Ossorio',
'Osuna','Otero','Otuel','Oviedo','Oxeda','Ozegueda','Pablo','Pacho','Paderes','Padia','Padilla',
'Padron','Padua','Paes','Palacios','Palafos','Palasios','Palencia','Pallares','Palma','Palmerin',
'Palo','Paloalto','Paloblanco','Palomar','Palomeque','Palomera','Palomino','Palomo','Palos','Palula',
'Panecatl','Paneda','Paniagua','Pantaleon','Pantoja','Pantoxa','Para','Parada','Paramo','Pardave',
'Pardinas','Pardo','Pareja','Parra','Parrales','Parrilla','Partida','Pasillas','Pasqual',
'Pastrana','Patino');
   
      pais := paisesArreglo('Afganistán','Albania','Alemania','Andorra','Angola','Antigua y Barbuda','Arabia Saudita','Argelia',
'Argentina','Armenia','Australia','Austria','Azerbaiyán','Bahamas','Bangladés','Barbados','Baréin'
,'Bélgica','Belice','Benín','Bielorrusia','Birmania','Bolivia','Bosnia y Herzegovina','Botsuana','Brasil'
,'Brunéi','Bulgaria','Burkina Faso','Burundi','Bután','Cabo Verde','Camboya','Camerún','Canadá','Catar'
,'Chad','Chile','China','Chipre','Ciudad del Vaticano','Colombia','Comoras','Corea del Norte','Corea del Sur'
,'Costa de Marfil','Costa Rica','Croacia','Cuba','Dinamarca','Dominica','Ecuador','Egipto','El Salvador','Emiratos Árabes Unidos'
,'Eritrea','Eslovaquia','Eslovenia','España','Estados Unidos','Estonia','Etiopía','Filipinas','Finlandia'
,'Fiyi','Francia','Gabón','Gambia','Georgia','Ghana','Granada','Grecia','Guatemala','Guyana','Guinea'
,'Guinea ecuatorial','Guinea-Bisáu','Haití','Honduras','Hungría','India','Indonesia','Irak','Irán'
,'Irlanda','Islandia','Islas Marshall','Islas Salomón','Israel','Italia','Jamaica','Japón','Jordania','Kazajistán'
,'Kenia','Kirguistán','Kiribati','Kuwait','Laos','Lesoto','Letonia','Líbano','Liberia','Libia','Liechtenstein'
,'Lituania','Luxemburgo','Madagascar','Malasia','Malaui','Maldivas','Malí','Malta','Marruecos','Mauricio'
,'Mauritania','México','Micronesia','Moldavia','Mónaco','Mongolia','Montenegro','Mozambique'
,'Namibia','Nauru','Nepal','Nicaragua','Níger','Nigeria','Noruega','Nueva Zelanda','Omán','Países Bajos'
,'Pakistán','Palaos','Panamá','Papúa Nueva Guinea','Paraguay','Perú','Polonia','Portugal','Reino Unido'
,'República Centroafricana','República Checa','República de Macedonia','República del Congo','República Democrática del Congo'
,'República Dominicana','República Sudafricana','Ruanda','Rumanía','Rusia','Samoa','San Cristóbal y Nieves','San Marino'
,'San Vicente y las Granadinas','Santa Lucía','Santo Tomé y Príncipe','Senegal','Serbia','Seychelles','Sierra Leona'
,'Singapur','Siria','Somalia','Sri Lanka','Suazilandia','Sudán','Sudán del Sur','Suecia','Suiza','Surinam'
,'Tailandia','Tanzania','Tayikistán','Timor Oriental','Togo','Tonga','Trinidad y Tobago','Túnez'
,'Turkmenistán','Turquía','Tuvalu','Ucrania','Uganda','Uruguay','Uzbekistán','Vanuatu','Venezuela'
,'Vietnam','Yemen','Yibuti','Zambia','Zimbabue');
   
   tipo:=tipoArreglo('administrador','estandar','premium');
       

  --Para el llenado de los usarios
  contador :=0;
	while contador< cantidad_Usuario LOOP
      
      /******************************ALEATORIOS*****************/
      ali_nombre := dbms_random.value(1,795);
      ali_apellido := dbms_random.value(1,1504);
      ali_nombre_2 := dbms_random.value(1,795);
      ali_apellido_2 := dbms_random.value(1,1504);
      ali_sexo:= dbms_random.value(0,1);
      ali_pais:= dbms_random.value(1,194);
      ali_pais_2 := dbms_random.value(1,194);

      --el if lo que determina si el usuario vive en el mismo pais que nacio o no 
      pais_diferente:= dbms_random.value(0,1);
      if ( pais_diferente = 0 ) then 
        ali_pais_2 := ali_pais; 
      end if;
      --fin  del if
      
      ali_telefono:= dbms_random.value(1000000,9999999); --7 digitos para cada telefono   
      ali_verifiacion:= dbms_random.value(0,1);
      ali_tipo := dbms_random.value(1,3);       
         
          /***************Fecha aleatoria para personas de 60 a 18 años****/
         SELECT TO_DATE(TRUNC( DBMS_RANDOM.VALUE(TO_CHAR(DATE '1958-12-31','J')
                          ,TO_CHAR(DATE '2000-06-01','J'))),'J'
                       )into ali_fecha_nacimiento FROM DUAL;    
      
          /***************Fecha aleatoria para creacion de cuentas desde 2017 ****/
         SELECT TO_DATE(TRUNC( DBMS_RANDOM.VALUE(TO_CHAR(DATE '2017-12-31','J')
                          ,TO_CHAR(DATE '2018-06-01','J'))),'J'
                       )into ali_fecha_creacion FROM DUAL;    
                       
      /*****************************************/  
    
      --email y usario que se van a utilizar ya que los mismos tienen que ser unicos
        mi_email:='' || nombre(ali_nombre) || TO_CHAR(contador)  || '@gmail.com' ;
        mi_usuario:= '' || nombre(ali_nombre) || '_' || TO_CHAR(contador) ; 
         
 
     /********************************INSERCION DE USUARIOS*******************/
  EXECUTE IMMEDIATE '
       insert into USUARIO(datos, telefono, ubicacion, contrasena, contrasena_actual, 
                       email, nombre_usuario, imagen_Pasaporte, 
                       fecha_creacion_cuenta, ultima_conexion, 
                      verificacion, tipo)
       values(:x, :y, :j, :a, :b, 
                       :c, :d, empty_blob(), 
                       :f, :g, 
                      :h, :i)' using datos_personales( nombre(ali_nombre), nombre(ali_nombre_2),apellido(ali_apellido),apellido(ali_apellido_2),ali_fecha_nacimiento,1), 
              telefonos(ali_telefono,(ali_telefono+1)), ubicaciones(pais(ali_pais),pais(ali_pais_2)), 
              contrasenas(TO_CHAR(contador),TO_CHAR(contador+1)) ,TO_CHAR(contador),
              mi_email, mi_usuario, 
              ali_fecha_creacion, sysdate, 
              ali_verifiacion, tipo(ali_tipo);
     /***********************************************************************/

		contador:= contador+1;	
	END LOOP;
end;  
/
create or replace
PROCEDURE "H02_INSERCIONES_BASICAS" 
as
begin
Insert into MONEDA(NOMBRE, SOBRE_NOMBRE, VALOR)
	Values('Bitcoin', 'BTC', 988.68);
Insert into MONEDA(NOMBRE, SOBRE_NOMBRE, VALOR)
	Values('Ethereum', 'ETH', 570.76);
Insert into MONEDA(NOMBRE, SOBRE_NOMBRE, VALOR)
	Values('Litecoin', 'LTC', 118.51);
Insert into MONEDA(NOMBRE, SOBRE_NOMBRE, VALOR)
	Values('EOS', 'EOS', 12.03);
Insert into MERCADO(NOMBRE, VALOR_PROMEDIO)
	values('Bitcoin', 7517.28);
Insert into MERCADO(NOMBRE, VALOR_PROMEDIO)
	values('Ethereum', 579.50);
Insert into MERCADO(NOMBRE, VALOR_PROMEDIO)
	values('Litecoin', 1);
dbms_output.put_line('creado');
end;
/
create or replace
PROCEDURE "H08_CREAR_HISTO_MONE_MERCA" (cantidad_dias integer) 
as

   ali_monto_ingresado number;
   ali_monto_egresado number;

  contador_mercado integer;
  contador_moneda integer;
   
   minima_id_moneda integer;
   maxima_id_moneda integer;
   minima_id_mercado integer;
   maxima_id_mercado integer;
   contador integer;
   valor_mercado_dia number;
BEGIN 
   select min(id),max(id) into minima_id_moneda, maxima_id_moneda from moneda;
   select min(id),max(id) into minima_id_mercado, maxima_id_mercado from mercado;
     
       --Para el llenado de los usarios
  contador :=0;
	while contador< cantidad_dias LOOP

     /********************************INSERCION DE USUARIOS*******************/
     contador_moneda := minima_id_moneda;
     while contador_moneda <= maxima_id_moneda loop
           
        contador_mercado := minima_id_mercado;
        while contador_mercado <= maxima_id_mercado loop
             ali_monto_ingresado := dbms_random.value(1,99999);
             ali_monto_egresado := dbms_random.value(1,999999);
             valor_mercado_dia :=  dbms_random.value(1,9);
   
            insert into Historial_monedas_mercado(fecha_dia,monto_ingresado,monto_egresado, valor_mercado_dia, id_moneda, id_mercado )
       values(sysdate-cantidad_dias+ contador, ali_monto_ingresado,ali_monto_egresado,valor_mercado_dia,
             contador_moneda,contador_mercado);
     /***********************************************************************/
      contador_mercado := contador_mercado +1;
    end loop;
   
     /***********************************************************************/
      contador_moneda := contador_moneda+1;
    end loop;

    contador:= contador+1;	
	END LOOP;
end;  
/
create or replace
procedure H10_simulacion_montecarlo (capital number, moneda INTEGER, mercado integer)
as
 mayor_valor number;
 menor_valor number;
 rango number;
 numero_de_clases number;
 intervalo_de_clases number;
 cantidad_elementos integer;
 
 type Hi_aleatorio_a IS VARRAY(510) OF number;        --Frecuencia Relativa Acumulada
 type z_a IS VARRAY(500) OF number; 
  type z_a_dentro IS VARRAY(700) OF number; 



Hi_aleatorio number;
z z_a;
z_adentro z_a_dentro;

u number;
xi number;
 
 ali_Hi integer;
 i integer;
 numero integer;
 
 capital_final number;
 intervalo_mayor number;
 intervalo_menor number;
 k integer;
 intervalo_de_confianza number;
 
 monto_ingresado number;
 monto_egresado number; 
 o_cuadrado number;
 desviacion_estandar number;
 z_n number;
 prome number;
 h integer;
 j integer;
 prome1 number;
 promedio number;

    CURSOR c_cursor 
    IS
    SELECT monto_ingresado, monto_egresado 
    FROM  historial_monedas_mercado
    where id_moneda=moneda and id_mercado = mercado;
 
    monto_i number;
    monto_e number;
    
    TYPE t_f  IS TABLE OF NUMBER  -- Associative array type
      INDEX BY VARCHAR2(64);
   f t_f;
 xifi number;
 media number;
 suma number;
 hi_minuscula number;
    TYPE hi_t  IS TABLE OF NUMBER  -- Associative array type
      INDEX BY VARCHAR2(64);
 Hi hi_t;
begin       
  z := z_a (0.00,0.01,0.02,0.03,0.04,0.05,0.06,0.07,0.08,0.09, 
            0.10,0.11,0.12,0.13,0.14,0.15,0.16,0.17,0.18,0.19,           
            0.20,0.21,0.22,0.23,0.24,0.25,0.26,0.27,0.28,0.29, 
            0.30,0.31,0.32,0.33,0.34,0.35,0.36,0.37,0.38,0.39,
            0.40,0.41,0.42,0.43,0.44,0.45,0.46,0.47,0.48,0.49,
            0.50,0.51,0.52,0.53,0.54,0.55,0.56,0.57,0.58,0.59, 
            0.60,0.61,0.62,0.63,0.64,0.65,0.66,0.67,0.68,0.69,
            0.70 , 0.71,0.72,0.73,0.74,0.75,0.76,0.77,0.78,0.79,
            0.80,0.81,0.82,0.83,0.84,0.85,0.86,0.87,0.88,0.89, 
            0.90,0.91,0.92,0.93,0.94,0.95,0.96,0.97,0.98,0.99, 
            1.00,1.01,1.02,1.03,1.04,1.05,1.06,1.07,1.08,1.09, 
            1.10,1.11,1.12,1.13,1.14,1.15,1.16,1.17,1.18,1.19,           
            1.20,1.21,1.22,1.23,1.24,1.25,1.26,1.27,1.28,1.29, 
            1.30,1.31,1.32,1.33,1.34,1.35,1.36,1.37,1.38,1.39,
            1.40,1.41,1.42,1.43,1.44,1.45,1.46,1.47,1.48,1.49,
            1.50,1.51,1.52,1.53,1.54,1.55,1.56,1.57,1.58,1.59, 
            1.60,1.61,1.62,1.63,1.64,1.65,1.66,1.67,1.68,1.69,
            1.70 , 1.71,1.72,1.73,1.74,1.75,1.76,1.77,1.78,1.79,
            1.80,1.81,1.82,1.83,1.84,1.85,1.86,1.87,1.88,1.89, 
            1.90,1.91,1.92,1.93,1.94,1.95,1.96,1.97,1.98,1.99,
            2.00,2.01,2.02,2.03,2.04,2.05,2.06,2.07,2.08,2.09, 
            2.10,2.11,2.12,2.13,2.14,2.15,2.16,2.17,2.18,2.19,           
            2.20,2.21,2.22,2.23,2.24,2.25,2.26,2.27,2.28,2.29, 
            2.30,2.31,2.32,2.33,2.34,2.35,2.36,2.37,2.38,2.39,
            2.40,2.41,2.42,2.43,2.44,2.45,2.46,2.47,2.48,2.49,
            2.50,2.51,2.52,2.53,2.54,2.55,2.56,2.57,2.58,2.59, 
            2.60,2.61,2.62,2.63,2.64,2.65,2.66,2.67,2.68,2.69,
            2.70 , 2.71,2.72,2.73,2.74,2.75,2.76,2.77,2.78,2.79,
            2.80,2.81,2.82,2.83,2.84,2.85,2.86,2.87,2.88,2.89, 
            2.90,2.91,2.92,2.93,2.94,2.95,2.96,2.97,2.98,2.99,
            3.00,3.01,3.02,3.03,3.04,3.05,3.06,3.07,3.08,3.09, 
            3.10,3.11,3.12,3.13,3.14,3.15,3.16,3.17,3.18,3.19,           
            3.20,3.21,3.22,3.23,3.24,3.25,3.26,3.27,3.28,3.29, 
            3.30,3.31,3.32,3.33,3.34,3.35,3.36,3.37,3.38,3.39,
            3.40,3.41,3.42,3.43,3.44,3.45,3.46,3.47,3.48,3.49,
            3.50,3.51,3.52,3.53,3.54,3.55,3.56,3.57,3.58,3.59, 
            3.60,3.61,3.62,3.63,3.64,3.65,3.66,3.67,3.68,3.69,
            3.70 , 3.71,3.72,3.73,3.74,3.75,3.76,3.77,3.78,3.79,
            3.80,3.81,3.82,3.83,3.84,3.85,3.86,3.87,3.88,3.89, 
            3.90,3.91,3.92,3.93,3.94,3.95,3.96,3.97,3.98,3.99
            );
            
z_adentro:= z_a_dentro(0.0000,0.0040,0.0080,0.0120,0.0160,0.0199,0.0239,0.0279,0.0319,0.0359,
0.0398,0.0438,0.0478,0.0517,0.0557,0.0596,0.0636,0.0675,0.0714,0.0753,
0.0793,0.0832,0.0871,0.0910,0.0948,0.0987,0.1026,0.1064,0.1103,0.1141,
0.1179,0.1217,0.1255,0.1293,0.1331,0.1368,0.1406,0.1443,0.1480,0.1517,
0.1554,0.1591,0.1628,0.1664,0.1700,0.1736,0.1772,0.1808,0.1844,0.1879,
0.1915,0.1950,0.1985,0.2019,0.2054,0.2088,0.2123,0.2157,0.2190,0.2224,
0.2257,0.2291,0.2324,0.2357,0.2389,0.2422,0.2454,0.2486,0.2517,0.2549,
0.2580,0.2611,0.2642,0.2673,0.2704,0.2734,0.2764,0.2794,0.2823,0.2852,
0.2881,0.2910,0.2939,0.2967,0.2995,0.3023,0.3051,0.3078,0.3106,0.3133,
0.3159,0.3186,0.3212,0.3238,0.3264,0.3289,0.3315,0.3340,0.3365,0.3389,
0.3413,0.3438,0.3461,0.3485,0.3508,0.3531,0.3554,0.3577,0.3599,0.3621,
0.3643,0.3665,0.3686,0.3708,0.3729,0.3749,0.3770,0.3790,0.3810,0.3830,
0.3849,0.3869,0.3888,0.3907,0.3925,0.3944,0.3962,0.3980,0.3997,0.4015,
0.4032,0.4049,0.4066,0.4082,0.4099,0.4115,0.4131,0.4147,0.4162,0.4177,
0.4192,0.4207,0.4222,0.4236,0.4251,0.4265,0.4279,0.4292,0.4306,0.4319,
0.4332,0.4345,0.4357,0.4370,0.4382,0.4394,0.4406,0.4418,0.4429,0.4441,
0.4452,0.4463,0.4474,0.4484,0.4495,0.4505,0.4515,0.4525,0.4535,0.4545,
0.4554,0.4564,0.4573,0.4582,0.4591,0.4599,0.4608,0.4616,0.4625,0.4633,
0.4641,0.4649,0.4656,0.4664,0.4671,0.4678,0.4686,0.4693,0.4699,0.4706,
0.4713,0.4719,0.4726,0.4732,0.4738,0.4744,0.4750,0.4756,0.4761,0.4767,
0.4772,0.4778,0.4783,0.4788,0.4793,0.4798,0.4803,0.4808,0.4812,0.4817,
0.4821,0.4826,0.4830,0.4834,0.4838,0.4842,0.4846,0.4850,0.4854,0.4857,
0.4861,0.4864,0.4868,0.4871,0.4875,0.4878,0.4881,0.4884,0.4887,0.4890,
0.4893,0.4896,0.4898,0.4901,0.4904,0.4906,0.4909,0.4911,0.4913,0.4916,
0.4918,0.4920,0.4922,0.4925,0.4927,0.4929,0.4931,0.4932,0.4934,0.4936,
0.4938,0.4940,0.4941,0.4943,0.4945,0.4946,0.4948,0.4949,0.4951,0.4952,
0.4953,0.4955,0.4956,0.4957,0.4959,0.4960,0.4961,0.4962,0.4963,0.4964,
0.4965,0.4966,0.4967,0.4968,0.4969,0.4970,0.4971,0.4972,0.4973,0.4974,
0.4974,0.4975,0.4976,0.4977,0.4977,0.4978,0.4979,0.4979,0.4980,0.4981,
0.4981,0.4982,0.4982,0.4983,0.4984,0.4984,0.4985,0.4985,0.4986,0.4986,
0.4987,0.4987,0.4987,0.4988,0.4988,0.4989,0.4989,0.4989,0.4990,0.4990,
0.4990,0.4991,0.4991,0.4991,0.4992,0.4992,0.4992,0.4992,0.4993,0.4993,
0.4993,0.4993,0.4994,0.4994,0.4994,0.4994,0.4994,0.4995,0.4995,0.4995,
0.4995,0.4995,0.4995,0.4996,0.4996,0.4996,0.4996,0.4996,0.4996,0.4997,
0.4997,0.4997,0.4997,0.4997,0.4997,0.4997,0.4997,0.4997,0.4997,0.4998,
0.4998,0.4998,0.4998,0.4998,0.4998,0.4998,0.4998,0.4998,0.4998,0.4998,
0.4998,0.4998,0.4999,0.4999,0.4999,0.4999,0.4999,0.4999,0.4999,0.4999,
0.4999,0.4999,0.4999,0.4999,0.4999,0.4999,0.4999,0.4999,0.4999,0.4999,
0.4999,0.4999,0.4999,0.4999,0.4999,0.4999,0.4999,0.4999,0.4999,0.4999,
0.5000,0.5000,0.5000,0.5000,0.5000,0.5000,0.5000,0.5000,0.5000,0.5000);


                             --la simlacion de montecarlo necesitas que los datos individuales se tranformen en rangos
                             --con su respectiva cantidad de datos (es decir la frecuencia en que estas estan)
select max(monto_ingresado - monto_egresado) , min (monto_ingresado - monto_egresado), avg(monto_ingresado - monto_egresado)
into mayor_valor, menor_valor, u
from historial_monedas_mercado
where id_mercado=mercado and id_moneda= moneda;


select count(*) 
into cantidad_elementos
from historial_monedas_mercado
where id_mercado=mercado and id_moneda= moneda;


rango := trunc(mayor_valor -menor_valor,3);
numero_de_clases := ceil(sqrt(cantidad_elementos)); --se puede cambiar a la version logaritmica
intervalo_de_clases:= rango/numero_de_clases;

f('1'):=0;
f('2'):=0;
f('3'):=0;
f('4'):=0;
f('5'):=0;
f('6'):=0;
f('7'):=0;
f('8'):=0;
f('9'):=0;
f('10'):=0;
f('11'):=0;
f('12'):=0;
f('13'):=0;
f('14'):=0;
f('15'):=0;
f('16'):=0;
f('17'):=0;
f('18'):=0;
f('19'):=0;
f('20'):=0;
f('21'):=0;

    OPEN c_cursor;
    LOOP
        FETCH c_cursor INTO monto_i,monto_e;
        EXIT WHEN c_cursor%NOTFOUND;
        numero :=menor_valor;

        for i in 1..cantidad_elementos loop
              if (((monto_i - monto_e) >= numero ) and ((monto_i - monto_e)<(numero + intervalo_de_clases)))then
                  f(to_char(i)):=f(to_char(i))+1;
                  exit;
              end if;
              numero := numero+ intervalo_de_clases ;
        end loop;        

    END LOOP; 
    CLOSE c_cursor;

  xifi:=0;
  numero :=menor_valor;
  for i in 1..numero_de_clases loop
      xi:=((numero )+ (numero+intervalo_de_clases))/2;
      xifi:=xifi+trunc(f(to_char(i)) * xi,2);                                   
     numero := numero+ intervalo_de_clases ;
  end loop;        

media:= xifi/cantidad_elementos;
o_cuadrado:=0;
  for i in 1..numero_de_clases loop
      xi:=((numero )+ (numero+intervalo_de_clases))/2;
      o_cuadrado := o_cuadrado + trunc((xi-media) * (xi-media)*f(to_char(i)),2);
      numero := numero+ intervalo_de_clases ;
  end loop;  
              
              
--prome es el valor probabilistico que ocurra valor del capital ingresado

suma :=0;
for i in 1..numero_de_clases loop
  hi_minuscula:= f(to_char(i))/cantidad_elementos;
  suma:=suma+ h;
  HI(to_char(i)):=suma;
end loop;

desviacion_estandar := sqrt(o_cuadrado/numero_de_clases);
z_n:=(capital -u)/desviacion_estandar;

i:=1;
 if (z_n < 0)then 
      z_n:= z_n*(-1);
      prome:= 0.5;
  end if;
       
z_n:=trunc(z_n,3);
while i< 399 loop
     
  if((z(i) >= z_n) and (z_n < z(i+1))) then
        prome:= z_adentro(i);
        exit;
  end if;
  i:=i+1;
end loop;


h:=0;
while h<2000 loop

--funcion aleatoria de cada funcion que se vaya hacer
  i:=0;
  while (i< numero_de_clases)loop
       ali_Hi := dbms_random.value(1,numero_de_clases); --seleccionar un valor aleatorio del arreglo Hi    
       Hi_aleatorio:=Hi(to_char(ali_Hi)) ; --se crea un arreglo aleatorio , con una nueva cuerva con valores iguales a la orginal
       
       z_n:= (Hi_aleatorio -u )/desviacion_estandar;
        j:=1;
          while j< 399 loop
          if((z(j)>=z_n) and z_n < z(j+1)) then
                   prome1 := z_adentro(j);
                     k:=k+1;
                    promedio := promedio+ Hi_aleatorio;
          end if;
          j:=j+1;
        end loop;
       i:=i+1;
        
        end loop;
    h:= h+1;
end loop;
      capital_final:=  promedio/k;
      capital_final:=  trunc(capital_final,-1);

       /*el intervalo de confianza es el del 95% por lo que corresponde a  un número decimal 0,95, 
      réstalo de 1 (1 – 0,095) y divídelo entre 2 para tener 0,025. 
     Luego, revisa la tabla de valores z para encontrar el valor que corresponde a 0,025.
    Verás que el valor más cercano es -1,96 en la intersección de la fila 1,9 y la columna 0,6. esto no cambia para ningun caso*/
       -- formla margen de error usando : -1,96 * ?/?(n) 
      intervalo_de_confianza:= -1.96 * (desviacion_estandar / sqrt(k));    
      intervalo_mayor :=capital_final+ intervalo_de_confianza ;
      intervalo_menor :=capital_final- intervalo_de_confianza ;
      
      dbms_output.put_line('capital final: ' || trunc(capital_final,3));
      dbms_output.put_line('intervalo de confianza : ' || trunc(intervalo_de_confianza,3));
      dbms_output.put_line('intervalo mayor: ' || trunc(intervalo_mayor,3));
      dbms_output.put_line('intervalo menor: ' || trunc(intervalo_menor,3));
end;
/
create or replace
procedure H11_simulacion_regresiones(fecha date, moneda INTEGER, mercado integer)
as
begin
  H111_regreseion_lineal(fecha, moneda, mercado);
  H112_regreseion_cuadratica(fecha, moneda, mercado);
  H113_regreseion_exponencial(fecha, moneda, mercado);
end;
/
create or replace procedure H111_regreseion_lineal(fecha date, moneda INTEGER, mercado integer)
as
 x_cuadrado number;
 x number;
 y number;
 n number;
 A1 number;
 B number;
 xy number;
 y_total number;
 x_fecha number;
begin

   --sacar las variables
   --x:
   --y_total valor que se va a calcular que es objetivo de esta buscqueda
   --recordar que y = ax+b 
   --ecuacion que debemos hayar atraves de una regresion lineal por el metodo de 
   --minimos cuadrados
   --recordar 
   --x: sumatoria de x
   --y: sumatoria de y
   --x_cuadrado: sumatoria de x_cuadrado
   --xy: sumatoria de x por y 
   --n: cantidad de datos;
   select sum(to_number(to_char(fecha_dia, 'j'))),sum(valor_mercado_dia), sum((to_number(to_char(fecha_dia, 'j')))*(to_number(to_char(fecha_dia, 'j')))) , sum((to_number(to_char(fecha_dia, 'j')))*valor_mercado_dia), count(*) 
   into x,y, x_cuadrado, xy, n
   from historial_monedas_mercado
   where id_moneda= moneda  and id_mercado= mercado;
   
   
   select to_number(to_char(fecha, 'j')) into x_fecha from dual;
    
   A1 := ((n * xy) -(x * y))/((n* x_cuadrado)- (x*x));
   B := ((x_cuadrado * y )-(x * xy))/((n * x_cuadrado)-(x*x));
   y_total:= A1 *(x_fecha) + B; 
  dbms_output.put_line('aproximacion de la moneda en ese dia es a traves de regresion lineal: '||trunc(y_total,4));
end;
/
create or replace procedure H112_regreseion_cuadratica(fecha date, moneda INTEGER, mercado integer)
as
  type matriz_A IS VARRAY(10) OF number; 
  fila1 matriz_A; --aparenta la forma de una matriz
  fila2 matriz_A; --aparenta la forma de una matriz
  fila3 matriz_A; --aparenta la forma de una matriz

  matriz0 number;
  matriz1 number;
  matriz2 number;
  matriz3 number;
  matriz4 number;
  matriz5 number;
  matriz6 number;
  matriz7 number;
  matriz8 number;
  matriz9 number;
  matriz10 number;
  matriz11 number;
  
  c_ecuacion  number;
  b_ecuacion number;
  a_ecuacion number;
  temp number;
  y_total number;
  x_fecha integer;
begin
--llenado de la matriz
    
   select sum(to_number(to_char(fecha_dia, 'j'))*to_number(to_char(fecha_dia, 'j'))*to_number(to_char(fecha_dia, 'j'))*to_number(to_char(fecha_dia, 'j'))),
          sum(to_number(to_char(fecha_dia, 'j'))*to_number(to_char(fecha_dia, 'j'))*to_number(to_char(fecha_dia, 'j'))),
          sum(to_number(to_char(fecha_dia, 'j'))*to_number(to_char(fecha_dia, 'j'))), 
          sum(to_number(to_char(fecha_dia, 'j'))*to_number(to_char(fecha_dia, 'j'))*valor_mercado_dia),
          sum(to_number(to_char(fecha_dia, 'j'))*valor_mercado_dia),          
          sum(to_number(to_char(fecha_dia, 'j'))), 
          count(*),
          sum(valor_mercado_dia)
    into matriz0,-- sumatoria de x a la 4
        matriz1,-- sumatoria de x a la 3
        matriz2,-- sumatoria de x a la 2
        matriz3,-- sumatoria de x al cuadrado * y  
        matriz7,-- sumatoria de x * y 
        matriz9,-- sumatoria de x
        matriz10,-- n( numero de participantes)
        matriz11-- sumatoria de y 
   from historial_monedas_mercado
   where id_moneda= moneda  and id_mercado= mercado;

      matriz4:= matriz1; -- sumatoria de x a la 3
      matriz5:=matriz2;-- sumatoria de x a la 2
      matriz6:=matriz9;-- sumatoria de x a la 1
      matriz8:=matriz2;-- sumatoria de x a la 2

fila1:=matriz_A(matriz0, matriz1, matriz2, matriz3);
fila2:=matriz_A(matriz4, matriz5, matriz6, matriz7);
fila3:=matriz_A(matriz8, matriz9, matriz10, matriz11);

--aplicacion de gauss jordan
--gauss jordan 
--´primer pivoteo
fila1:=matriz_A(matriz0/matriz0,  matriz1/matriz0, matriz2/matriz0, matriz3/matriz0);
temp:= matriz4;
fila2:=matriz_A (((-temp)* fila1(1))+matriz4,  ((-temp)* fila1(2))+matriz5, ((-temp)* fila1(3))+matriz6, ((-temp)* fila1(4))+matriz7);
temp:= matriz8;
fila3:=matriz_A (((-temp)* fila1(1))+matriz8,  ((-temp)* fila1(2))+matriz9, ((-temp)* fila1(3))+matriz10, ((-temp)* fila1(4))+matriz11);

--segundo pivoteo
temp:=fila2(2);
fila2:=matriz_A(fila2(1)/temp,  fila2(2)/temp, fila2(3)/temp, fila2(4)/temp);
temp:= fila1(2);
fila1:=matriz_A (((-temp)* fila2(1))+fila1(1),  ((-temp)* fila2(2))+fila1(2), ((-temp)* fila2(3))+fila1(3), ((-temp)* fila2(4))+fila1(4));
temp:= fila3(2);
fila3:=matriz_A (((-temp)* fila2(1))+fila3(1),  ((-temp)* fila2(2))+fila3(2), ((-temp)* fila2(3))+fila3(3), ((-temp)* fila2(4))+fila3(4));

--tercer pivoteo
temp:=fila3(3);
fila3:=matriz_A(fila3(1)/temp,  fila3(2)/temp, fila3(3)/temp, fila3(4)/temp);
temp:= fila1(3);
fila1:=matriz_A (((-temp)* fila3(1))+fila1(1),  ((-temp)* fila3(2))+fila1(2), ((-temp)* fila3(3))+fila1(3), ((-temp)* fila3(4))+fila1(4));
temp:= fila2(3);
fila2:=matriz_A (((-temp)* fila3(1))+fila2(1),  ((-temp)* fila3(2))+fila2(2), ((-temp)* fila3(3))+fila2(3), ((-temp)* fila3(4))+fila2(4));


a_ecuacion:= (fila1(4)-fila1(3)-fila1(3))/fila1(1);

b_ecuacion:= (fila2(4)-fila2(3)-fila2(1))/fila2(2);

c_ecuacion:= (fila3(4)-fila3(2)-fila3(1))/fila3(3);

   select to_number(to_char(fecha, 'j')) into x_fecha from dual;
   
   y_total:= a_ecuacion *(x_fecha)*(x_fecha)+ b_ecuacion *(x_fecha) + c_ecuacion; 
    dbms_output.put_line('aproximacion de la moneda en ese dia es a traves de regresion cuadratica: '||trunc(y_total,4));
end;
/
create or replace
procedure H113_regreseion_exponencial(fecha date, moneda INTEGER, mercado integer)
as

 x_cuadrado number;
 x number;
 y number;
 n number;
 A1 number;
 B number;
 xy number;
 y_total number;
 x_fecha number;
 c1 number;
 fecha_Actual INTEGER;
begin

   --sacar las variables
   --x:
   --y_total valor que se va a calcular que es objetivo de esta buscqueda
   --recordar que y = ax+b 
   --ecuacion que debemos hayar atraves de una regresion lineal por el metodo de 
   --minimos cuadrados
   --recordar 
   --x: sumatoria de x
   --y: sumatoria de y
   --x_cuadrado: sumatoria de x_cuadrado
   --xy: sumatoria de x por y 
   --n: cantidad de datos;
   fecha_Actual:=to_number(to_char(sysdate, 'j'));
   
   select sum(to_number(to_char(fecha_dia, 'j'))-fecha_Actual),sum(LN(valor_mercado_dia)), sum(((to_number(to_char(fecha_dia, 'j')))-fecha_Actual)*(to_number(to_char(fecha_dia, 'j'))-fecha_Actual)), 
          sum((to_number(to_char(fecha_dia, 'j'))-fecha_Actual)*LN(valor_mercado_dia)), count(*) 
   into x,y, x_cuadrado, xy, n
   from historial_monedas_mercado
   where id_moneda= moneda  and id_mercado= mercado;
   
   
   select to_number(to_char(fecha, 'j')-fecha_Actual) into x_fecha from dual;
   
   
   A1 := ((n * xy) -(x * y))/((n* x_cuadrado)- (x*x));
   B:= ((x_cuadrado * y )-(x * xy))/((n * x_cuadrado)-(x*x));
   B:= trunc(B, 4);
   A1:= trunc(A1, 4);
   c1:= POWER(2.7182, B);
   B:= trunc(c1, 5);
   y_total:= c1 * POWER(2.71828, (A1 *(x_fecha)));
  dbms_output.put_line('aproximacion de la moneda en ese dia es a traves de regresion exponencial: '||trunc(y_total,4));
end;
/
create or replace
procedure h12_optimizacion_venta(capital number, moneda integer)
as
m1 number;
m2 number;
m3 number;

costo_m1 number;
costo_m2 number;
costo_m3 number;

costo_total number;
begin
  select avg(valor_mercado_dia)  into costo_m1
  from historial_monedas_mercado 
  where id_mercado=1 and id_moneda= moneda;

  select avg(valor_mercado_dia)  into costo_m2
  from historial_monedas_mercado 
  where id_mercado=2 and id_moneda= moneda; 
  
  select avg(valor_mercado_dia)  into costo_m3
  from historial_monedas_mercado 
  where id_mercado=3 and id_moneda= moneda;

  --en el fondo todo lo siguiente es un simplex de 3 variables con una resticcion 
  --pero para no hacer el algoritmo del simplex con matrices ya que es una sola restriccion
  --se hace por reglas de 3 
  
  costo_total:= costo_m1 +costo_m2 +costo_m3; 
  
  m1:=(((costo_m1*100)/costo_total)/100)*capital ;  --se saca el porcentaje de los costos asociado al mercado 1 
                                                    --y se multiplica por el capital asociado o impuesto
  m2:=(((costo_m2*100)/costo_total)/100)*capital;
  
  m3:=(((costo_m3*100)/costo_total)/100)*capital;
  
   dbms_output.put_line('inversion en el mercado 1 : '||trunc(m1,4));
   dbms_output.put_line('inversion en el mercado 2 : '||trunc(m2,4));
   dbms_output.put_line('inversion en el mercado 3 : '||trunc(m3,4));
end;
/
create or replace procedure H13_ganancia_mercado_dia(id_monedero integer)
as

moneda INTEGER;
cantidad number;
suma number;
valor_mercado number;
fecha date;
m1 number;
m2 number;
m3 number;
begin
begin
    select id_moneda
    into moneda
    from monedero 
    where id= id_monedero;
       
    --para elprimer mercado 
    select count(*), sum(compra_venta.monto)
    into cantidad, suma
    from historial_compra_venta, compra_venta
    where id_moneda_cantidad=moneda and id_monedero_cantidad= id_monedero and 
          id_transaccion_prin=id and id_mercado=1;
    --ganancia en el mercado1  
    
    select max(fecha_dia)
    into fecha 
    from historial_monedas_mercado
    where id_mercado=1 and id_moneda = moneda;
    
    select valor_mercado_dia
    into valor_mercado
    from historial_monedas_mercado
    where id_mercado=1 and id_moneda = moneda and fecha_dia=fecha;
    
    m1:= suma-(cantidad *valor_mercado);
          
          
    --para el segundo mercado 
    select count(*), sum(compra_venta.monto)
    into cantidad, suma
    from historial_compra_venta, compra_venta
    where id_moneda_cantidad=moneda and id_monedero_cantidad= id_monedero and 
          id_transaccion_prin=id and id_mercado=2;
    --ganancia en el mercado2 
    
    select max(fecha_dia)
    into fecha 
    from historial_monedas_mercado
    where id_mercado=2 and id_moneda = moneda;
    
    select valor_mercado_dia
    into valor_mercado
    from historial_monedas_mercado
    where id_mercado=2 and id_moneda = moneda and fecha_dia=fecha;
    
    m2:= suma-(cantidad *valor_mercado);   
    
        --para el tercer mercado 
    select count(*), sum(compra_venta.monto)
    into cantidad, suma
    from historial_compra_venta, compra_venta
    where id_moneda_cantidad=moneda and id_monedero_cantidad= id_monedero and 
          id_transaccion_prin=id and id_mercado=3;
    --ganancia en el mercado3 
    
    select max(fecha_dia)
    into fecha 
    from historial_monedas_mercado
    where id_mercado=3 and id_moneda = moneda;
    
    select valor_mercado_dia
    into valor_mercado
    from historial_monedas_mercado
    where id_mercado=3 and id_moneda = moneda and fecha_dia=fecha;
    
    m3:= suma-(cantidad *valor_mercado);
    
  dbms_output.put_line('inversion en el mercado 1 : '||trunc(m1,4));
  dbms_output.put_line('inversion en el mercado 2 : '||trunc(m2,4));
  dbms_output.put_line('inversion en el mercado 3 : '||trunc(m3,4));    
EXCEPTION 
WHEN NO_DATA_FOUND THEN 
valor_mercado:= 0; 
end; 

--return valor_mercado; 

end; 
/
create or replace
procedure H14_correcion_de_mercado(mercado_id INTEGER)
as
  /*************cursor dinamico**********/
    TYPE EmpCurTyp IS REF CURSOR;
    cursor_tran   EmpCurTyp;
    emp_rec  historial_monedas_mercado%ROWTYPE;
    v_stmt_str VARCHAR2(200);  
    /*****************************************/
    
i integer;
anterior_signo number;
signo_monto number;
signo number;
BEGIN
 
anterior_signo:=1;--empezamos siempre siendo optimista y dandole signo positivo
for i in 1..4 loop --4 monedas
  v_stmt_str := 'SELECT * FROM historial_monedas_mercado where id_mercado='|| mercado_id
                    ||' and id_moneda= :j';
     
  OPEN cursor_tran FOR v_stmt_str USING i;
  LOOP
     FETCH cursor_tran INTO emp_rec;
     EXIT WHEN cursor_tran%NOTFOUND;
    ---codigo
      signo_monto:= emp_rec.monto_egresado + emp_rec.monto_ingresado;
      signo:= anterior_signo* signo_monto;
      
      if(signo <0 ) then
      --correcion de mercado
                if(signo_monto <0 ) then
                    dbms_output.put_line('Hay una correcion de mercado  negativa(bajo) el dia '|| emp_rec.fecha_dia);
                elsif(signo > 0) then
                    dbms_output.put_line('Hay una correcion de mercado  positiva(subio) el dia '|| emp_rec.fecha_dia);
                end if;

      elsif(signo > 0) then
                  if(signo_monto <0 ) then
                    anterior_signo:=-1;
                  elsif(signo > 0) then
                    anterior_signo:=1;
                  end if;
      end if;  
   END LOOP; 
   CLOSE cursor_tran;
end loop;
end;
/
create or replace
PROCEDURE "C1_CAPITALIZACION_BURSATIL"(idmoneda integer, idmercado integer)
As
  capital_bursatil number;
  sum_total number;
  fecha date;
  valor_mercado_1 number;
Begin
begin
  /*Gracias a la capitalización de mercado, los inversores pueden determinar de forma sencilla el tamaño de una empresa. 
  (nuestro caso la monedas de los diferentes mercado)
  Se calcula multiplicando el número total de acciones existente(la suma de todos los monederos de esa moneda)
  por el precio actual de la acción(valor del mercado).*/
  
  select sum(cantidad_actual)
  into sum_total 
  from monedero 
  where id_moneda = idmoneda;
  
  --mercado
  select max(fecha_dia)
  into fecha
  from historial_monedas_mercado
  where id_moneda= idmoneda and id_mercado = idmercado;
  
  select valor_mercado_dia 
  into valor_mercado_1
  from historial_monedas_mercado
  where fecha_dia=fecha and id_moneda= idmoneda and id_mercado = idmercado;
  
  
  capital_bursatil := sum_total * valor_mercado_1;
  dbms_output.put_line('La capitalizacion bursatil enel mercado es ' || trunc(capital_bursatil,2)); 
  
  EXCEPTION 
WHEN NO_DATA_FOUND THEN 
  dbms_output.put_line('no hay datos'); 
end; 
End;
/
create or replace
procedure H0_FUNCION_USUARIO_LOGIN(nombre_us VARCHAR2, contra VARCHAR2) authid current_user
as
  el_mismo_usuario number;
  id_u integer;
  tipo1 varchar2(100);
BEGIN
  SELECT count(*)
    INTO el_mismo_usuario
    FROM USUARIO
   WHERE (nombre_us = nombre_usuario OR nombre_us = email ) AND (contrasena_actual=contra);
if (el_mismo_usuario =1) then 
   SELECT id,tipo 
   INTO id_u, tipo1
   FROM USUARIO
   WHERE (nombre_us = nombre_usuario OR nombre_us = email ) AND (contrasena_actual=contra);
  EXECUTE IMMEDIATE 
    'CREATE OR REPLACE VIEW vista_usuario AS (select u.* 
                                         from usuario u
                                         where u.id='||id_u||')';
  EXECUTE IMMEDIATE 
    'CREATE OR REPLACE VIEW vista_monedero AS (select m.*    from monedero m
                                         where m.id_usuario='||id_u||')';
  EXECUTE IMMEDIATE 
    'CREATE OR REPLACE VIEW vista_ordenes AS (select cv.*
                                         from compra_venta cv , historial_compra_venta hcv
                                         where (hcv.id_monedero_cantidad='||id_u||' or id_monedero_monto='||id_u||') and cv.id= hcv.id_transaccion_prin)';

    if (tipo1='administrador')then
    EXECUTE IMMEDIATE       
      'CREATE OR REPLACE VIEW vista_administrador AS (select m.id id_monedero, m.cantidad_actual monedero_cantidad,cv.*
                                         from monedero m, compra_venta cv , historial_compra_venta hcv
                                         where (id_monedero_cantidad=m.id or id_monedero_monto=m.id) and cv.id= hcv.id_transaccion_prin)';
    end if;
    dbms_output.put_line('se hizo el login y se creo la vista');
else  dbms_output.put_line('no se hizo el login y se creo la vista');
end if;
END; 
/
create or replace
TRIGGER "3.1.actualizar_contrasenas"
instead of UPDATE  
ON vista_usuario 
declare
  i integer;
     exception_iguales EXCEPTION; 
BEGIN
  for i in 1..:new.contrasena.count loop
     IF (:new.contrasena(i) = :new.contrasena_actual) THEN 
      RAISE exception_iguales; 
     END IF; 
  end loop;

  if(:new.contrasena.count=1)then
    UPDATE usuario
    SET CONTRASENA = CONTRASENAS(:new.contrasena(1),:new.contrasena_actual) ,
         contrasena_actual= :new.contrasena_actual
    WHERE id=:new.id;
  elsif (:new.contrasena.count=2)then
    UPDATE usuario
    SET CONTRASENA = CONTRASENAS(:new.contrasena(1),:new.contrasena(2),:new.contrasena_actual),
         contrasena_actual= :new.contrasena_actual
    WHERE id=:new.id;
  elsif (:new.contrasena.count=3)then
    UPDATE usuario
    SET CONTRASENA = CONTRASENAS(:new.contrasena(1),:new.contrasena(2),:new.contrasena(3),:new.contrasena_actual),
         contrasena_actual= :new.contrasena_actual
    WHERE id=:new.id;
  elsif (:new.contrasena.count=4)then
    UPDATE usuario
    SET CONTRASENA = CONTRASENAS(:new.contrasena(1),:new.contrasena(2),:new.contrasena(3),:new.contrasena(4),:new.contrasena_actual),
         contrasena_actual= :new.contrasena_actual
    WHERE id=:new.id;
  elsif (:new.contrasena.count=5)then
    UPDATE usuario
    SET CONTRASENA = CONTRASENAS(:new.contrasena(1),:new.contrasena(2),:new.contrasena(3),:new.contrasena(4),:new.contrasena(5),:new.contrasena_actual),
         contrasena_actual= :new.contrasena_actual
    WHERE id=:new.id;
  elsif  (:new.contrasena.count=6)then
    UPDATE usuario
    SET CONTRASENA = CONTRASENAS(:new.contrasena(1),:new.contrasena(2),:new.contrasena(3),:new.contrasena(4),:new.contrasena(5),:new.contrasena(6),:new.contrasena_actual),
         contrasena_actual= :new.contrasena_actual
    WHERE id=:new.id;
  elsif  (:new.contrasena.count=7)then
    UPDATE usuario
    SET CONTRASENA = CONTRASENAS(:new.contrasena(1),:new.contrasena(2),:new.contrasena(3),:new.contrasena(4),:new.contrasena(5),:new.contrasena(6),:new.contrasena(7),:new.contrasena_actual),
         contrasena_actual= :new.contrasena_actual
    WHERE id=:new.id;
  elsif  (:new.contrasena.count=8)then
    UPDATE usuario
    SET CONTRASENA = CONTRASENAS(:new.contrasena_actual,:new.contrasena(1),:new.contrasena(2),:new.contrasena(3),:new.contrasena(4),:new.contrasena(5),:new.contrasena(6),:new.contrasena(7)),
         contrasena_actual= :new.contrasena_actual
    WHERE id=:new.id;
  end if ;
  
  EXCEPTION 
   WHEN exception_iguales THEN 
    dbms_output.put_line('contraseña repetida');
END;
/
create or replace TRIGGER "3.2.actualizar_monedero" 
instead of UPDATE  
ON vista_monedero
declare
  i integer;
BEGIN
 insert into THE (select cantidad_monedero from monedero where id=:new.id) values
 (monederos_H(:old.cantidad_actual,sysdate));
 update monedero set cantidad_Actual = :new.cantidad_actual  where id=:new.id;
END;
/