--Таблица для сбора инфы
CREATE TABLE system.table_growth (
id numeric(20) GENERATED ALWAYS AS IDENTITY,
time date NOT NULL,
owner varchar2(20),
table_name varchar2(30),
table_size numeric(20),
growth_in_mb_per_day numeric(20) NULL,
CONSTRAINT table_growth_pk PRIMARY KEY (id)
);

--тригер на timestamp
CREATE OR REPLACE TRIGGER SYSTEM.TABLE_GROWTH_TRG
  BEFORE INSERT ON system.table_growth
  FOR EACH ROW
BEGIN
  :new.time := sysdate;
END;
/
