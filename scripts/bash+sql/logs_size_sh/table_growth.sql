set newpage 0 verify off feedback off echo off term off trimout on trimspool on timing off;
set lines 150;
col OWNER for a20;
col TABLE_NAME for a30;
SPOOL /tmp/table_growth.tmp
select OWNER,TABLE_NAME,TABLE_SIZE,GROWTH_IN_MB_PER_DAY from system.table_growth where TO_CHAR(time, 'YYYYMMDD') = TO_CHAR(SYSDATE-1, 'YYYYMMDD') ORDER BY owner;
spool off;
