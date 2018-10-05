  CREATE OR REPLACE TYPE "CONTRASENAS" as varray(8) of VARCHAR2(16);
/
  CREATE OR REPLACE TYPE "DATOS_PERSONALES" as object(
  primer_nombre VARCHAR2(50),
  segundo_nombre VARCHAR2(50),
  primer_apellido VARCHAR2(50),
  segundo_apellido VARCHAR2(50),
  fecha_nacimiento date,
  sexo NUMBER(1),
  member function FUNCIONVALIDO (sexo in NUMBER) return NUMBER
);

/
CREATE OR REPLACE TYPE "H_MONEDERO" as table of monederos_H;
/
CREATE OR REPLACE TYPE "MONEDEROS_H" as object(
  monto number,
  fecha date
);
/
CREATE OR REPLACE TYPE "PREDICCIONES" as object(
  monto_minimo number,
  monto_maximo number,
  fecha_inicio_prediccion date,
  fecha_fin_prediccion date
);
/
  CREATE OR REPLACE TYPE "TABLAPREDIC" as table of Predicciones;
/
  CREATE OR REPLACE TYPE "TELEFONOS" as varray(3) of number(20);

/
  CREATE OR REPLACE TYPE "UBICACIONES" as object(
  pais_nacimiento varchar2(50),
  pais_residencia varchar2(50)
);
/
CREATE TABLE USUARIO (
         id NUMBER PRIMARY KEY,
         datos datos_personales,
         telefono telefonos,
         ubicacion ubicaciones,
         contrasena contrasenas,
         contrasena_actual VARCHAR2(16),
         email VARCHAR2(100) UNIQUE NOT NULL, 
         nombre_usuario VARCHAR2(100) UNIQUE NOT NULL,
         imagen_Pasaporte BLOB,
         fecha_creacion_cuenta DATE,
         ultima_conexion date,
         verificacion number(1), 
         tipo VARCHAR2(50) ,    
         CONSTRAINT Email_Formato_valido check(email LIKE '%@%.com'),
         CONSTRAINT verificacion_valido check( verificacion in(1,0)),
         CONSTRAINT tipo_valido check( tipo in('estandar','administrador','premium'))
);
/

CREATE TABLE MONEDA (
         id NUMBER (20) PRIMARY KEY,
         nombre VARCHAR2(50),
         sobre_nombre VARCHAR2(50),
         valor number(20)         
);
/
CREATE TABLE MERCADO (
         id NUMBER (20) PRIMARY KEY,
         nombre VARCHAR2(50),
         prediccion_mercado tablaPredic,
         valor_promedio number(20),
         CONSTRAINT fk_moneda_mercado FOREIGN KEY(id) REFERENCES MONEDA(id)
)nested table prediccion_mercado store as Prediccion;
/
CREATE TABLE COMPRA_VENTA (
      id NUMBER (20) PRIMARY KEY,     
      monto number, 
      cantidad number(20),
      tipo VARCHAR2(50),
      orden_estado number(1),
      metodo_realizado VARCHAR2(20),
      Valor_mercado NUMBER,
      Precio_limit NUMBER, 
      Precio_stop NUMBER,
      CONSTRAINT orden_estado check( (orden_estado = 1) or (orden_estado = 0) )
);
/
CREATE TABLE DEPOSITO_RETIRO (
      id NUMBER (20) PRIMARY KEY,
      cantidad number,
      tipo VARCHAR2(50),
      concepto VARCHAR2(50),
      observaciones_adicionales VARCHAR2(50)
);
/
CREATE TABLE MONEDERO (
      id Number(20) PRIMARY KEY,
      id_usuario Number(20),
      id_moneda Number(20),
      cantidad_actual NUMBER,
      cantidad_monedero H_monedero, 
      CONSTRAINT fk_usuario_monedero FOREIGN KEY(id_usuario) REFERENCES USUARIO(id),
      CONSTRAINT fk_moneda_monedero FOREIGN KEY(id_moneda) REFERENCES MONEDA(id)
)nested table cantidad_monedero store as monederos_historico;
/

CREATE TABLE HISTORIAL_DEPOSITO_RETIRO (
      fecha_realizado_inicio date,
      fecha_realizado_fin date,
      id_monedero Number(20),
      id_transaccion Number(20),
      CONSTRAINT fk_usuario_depositotio FOREIGN KEY(id_monedero) REFERENCES MONEDERO(id),
      CONSTRAINT fk_transaccion_deposito FOREIGN KEY(id_transaccion) REFERENCES DEPOSITO_RETIRO(id),
      CONSTRAINT pk_depsoito_retiro PRIMARY KEY(id_monedero,id_transaccion)
);
/
CREATE TABLE HISTORIAL_MONEDAS_MERCADO (
      id number(20),
      fecha_dia date,
      monto_ingresado NUMBER,
      monto_egresado NUMBER,
      valor_mercado_dia number,
      id_moneda Number(20),
      id_mercado Number(20),
      CONSTRAINT fk_id_moneda_mercado FOREIGN KEY(id_moneda) REFERENCES MONEDA(id),
      CONSTRAINT fk_id_mercado_monedas FOREIGN KEY(id_mercado) REFERENCES MERCADO(id),
      CONSTRAINT pk_moneda_mercado PRIMARY KEY(id)
);
/
CREATE TABLE HISTORIAL_COMPRA_VENTA (
      fecha_realizada_transaccion date,
      fecha_trasaccion_cerrada date,
      id_monedero_cantidad Number(20),
      id_monedero_monto Number(20),
      id_mercado Number(20),
      id_moneda_cantidad  NUMBER (20),
      id_transaccion_prin Number(20),  
      id_trans_contraria_pri Number(20), 
      CONSTRAINT fk_mone_VENTA FOREIGN KEY(id_monedero_cantidad) REFERENCES MONEDERO(id),
      CONSTRAINT fk_mer_VENTA FOREIGN KEY(id_mercado) REFERENCES MERCADO(id),
      CONSTRAINT fk_id_moneda_cantidad FOREIGN KEY(id_moneda_cantidad) REFERENCES MONEDA(id),
      CONSTRAINT fk_transa_VENTA FOREIGN KEY(id_transaccion_prin) REFERENCES COMPRA_VENTA (id),
      CONSTRAINT fk_contr_VENTA FOREIGN KEY(id_trans_contraria_pri) REFERENCES COMPRA_VENTA (id),
      CONSTRAINT pk_historial_compra_venta PRIMARY KEY(id_transaccion_prin)
);
/
CREATE SEQUENCE secuencia_USUARIO_ID START WITH 1;

CREATE SEQUENCE secuencia_MONEDA_ID START WITH 1;

CREATE SEQUENCE secuencia_MERCADO_ID START WITH 1;

CREATE SEQUENCE secuencia_DEPOSITO_RETIRO_ID START WITH 1;

CREATE SEQUENCE secuencia_COMPRA_VENTA_ID START WITH 1;

CREATE SEQUENCE secuencia_MONEDERO_ID START WITH 1;

CREATE SEQUENCE secuencia_HISTOR_MONE_MER_ID START WITH 1;

create index monedero_cantidad on monedero(id_moneda);
create index monedero_usuario on monedero(id_usuario);

create index compra_venta_tipo on compra_venta(tipo);
create index compra_venta_estado on compra_venta(orden_estado);

create index histo_compra_venta_mercado on HISTORIAL_COMPRA_VENTA(ID_MERCADO);
create index histo_compra_venta_moneda on HISTORIAL_COMPRA_VENTA(ID_MONEDA_CANTIDAD);

create index historial_monedas on historial_monedas_mercado(id_moneda);
create index historial_mercado_m on historial_monedas_mercado(id_mercado);
create index historial_mon_mer_fecha on historial_monedas_mercado(fecha_dia);


/                                        
CREATE OR REPLACE VIEW vista_usuario AS (select u.* 
                                         from usuario u);
/
CREATE OR REPLACE VIEW vista_administrador AS (select m.id id_monedero, m.cantidad_actual monedero_cantidad,cv.*
                                         from monedero m, compra_venta cv , historial_compra_venta hcv);
/
CREATE OR REPLACE VIEW vista_monedero AS (select m.*    from monedero m);
