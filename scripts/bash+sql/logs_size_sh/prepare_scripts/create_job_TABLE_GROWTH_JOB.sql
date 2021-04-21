BEGIN
  SYS.DBMS_SCHEDULER.CREATE_JOB
    (
       job_name        => 'SYS.TABLE_GROWTH_JOB'
      ,start_date      => TO_TIMESTAMP_TZ('2020/10/02 14:45:00.845336 Europe/Moscow','yyyy/mm/dd hh24:mi:ss.ff tzr')
      ,repeat_interval => 'FREQ=DAILY; byhour=23'
      ,end_date        => NULL
      ,job_class       => 'DEFAULT_JOB_CLASS'
      ,job_type        => 'PLSQL_BLOCK'
      ,job_action      => 'INSERT INTO system.table_growth (owner, table_name, table_size)
SELECT owner as "Schema", segment_name as "Object Name", sum(round(bytes/1024/1024,2)) as "Object Size (Mb)"
from dba_segments
where segment_name in (
''BP_REQUEST_LOG'',
''BP_LOG'',
''BP_LOG1'',
''SWE_EVENT'')
and owner in (''SWE'',''ISWE'')
GROUP BY owner, segment_name
ORDER BY owner;
BEGIN
For i in (select
   t1.TIME,
   t1.OWNER,
   t1.TABLE_NAME,
   t1.TABLE_SIZE  - t2.TABLE_SIZE as GROWTH from
   (select TIME,OWNER,TABLE_NAME,TABLE_SIZE from system.table_growth where TO_CHAR(time, ''YYYYMMDD'') = TO_CHAR(SYSDATE, ''YYYYMMDD'') ORDER BY owner) t1,
   (select TIME,OWNER,TABLE_NAME,TABLE_SIZE from system.table_growth where TO_CHAR(time, ''YYYYMMDD'') = TO_CHAR(SYSDATE-1, ''YYYYMMDD'') ORDER BY owner) t2
where
   t1.TABLE_NAME=t2.TABLE_NAME and t1.OWNER=t2.OWNER)
LOOP
Update system.table_growth set GROWTH_IN_MB_PER_DAY = i.GROWTH where OWNER = i.OWNER and TABLE_NAME = i.TABLE_NAME and TO_CHAR(time, ''YYYYMMDD'') = TO_CHAR(SYSDATE, ''YYYYMMDD'');
END LOOP;
commit;
END;
'
      ,comments        => 'Insert growth info into the table_growth table'
    );
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'SYS.TABLE_GROWTH_JOB'
     ,attribute => 'RESTARTABLE'
     ,value     => FALSE);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'SYS.TABLE_GROWTH_JOB'
     ,attribute => 'LOGGING_LEVEL'
     ,value     => SYS.DBMS_SCHEDULER.LOGGING_OFF);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE_NULL
    ( name      => 'SYS.TABLE_GROWTH_JOB'
     ,attribute => 'MAX_FAILURES');
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE_NULL
    ( name      => 'SYS.TABLE_GROWTH_JOB'
     ,attribute => 'MAX_RUNS');
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'SYS.TABLE_GROWTH_JOB'
     ,attribute => 'STOP_ON_WINDOW_CLOSE'
     ,value     => FALSE);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'SYS.TABLE_GROWTH_JOB'
     ,attribute => 'JOB_PRIORITY'
     ,value     => 3);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE_NULL
    ( name      => 'SYS.TABLE_GROWTH_JOB'
     ,attribute => 'SCHEDULE_LIMIT');
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'SYS.TABLE_GROWTH_JOB'
     ,attribute => 'AUTO_DROP'
     ,value     => TRUE);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'SYS.TABLE_GROWTH_JOB'
     ,attribute => 'RESTART_ON_RECOVERY'
     ,value     => FALSE);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'SYS.TABLE_GROWTH_JOB'
     ,attribute => 'RESTART_ON_FAILURE'
     ,value     => FALSE);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => 'SYS.TABLE_GROWTH_JOB'
     ,attribute => 'STORE_OUTPUT'
     ,value     => TRUE);

  SYS.DBMS_SCHEDULER.ENABLE
    (name                  => 'SYS.TABLE_GROWTH_JOB');
END;
/
