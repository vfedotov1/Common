/* Formatted on 21/04/2021 11:02:43 (QP5 v5.345) */
SET NEWPAGE 0 VERIFY OFF FEEDBACK OFF ECHO OFF TERM OFF TRIMOUT ON TRIMSPOOL ON TIMING OFF;
SPOOL /tmp/check_CLIENT_INFO/check_CLIENT_INFO.csv
SET SERVEROUTPUT ON
DEFINE machine_like = 'tomcat8-app-server' -- set name of machine that raised the connection
BEGIN
    FOR i IN 1 .. 3650
    LOOP
        DBMS_OUTPUT.PUT_LINE (TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
        DBMS_OUTPUT.put_line ('CLIENT_INFO_COUNT' || ';' || 'CLIENT_INFO' || ';' || 'USERNAME');
        FOR v_rec
            IN (  SELECT COUNT (*) AS CLIENT_INFO_COUNT, CLIENT_INFO, USERNAME
                    FROM gv$session
                   WHERE machine LIKE '%&machine_like%'
                GROUP BY CLIENT_INFO, USERNAME)
        LOOP
            DBMS_OUTPUT.put_line (
                   v_rec.CLIENT_INFO_COUNT
                || ';'
                || v_rec.CLIENT_INFO
                || ';'
                || v_rec.USERNAME);
        END LOOP;
        sys.DBMS_SESSION.sleep (1);
    END LOOP;
END;
/
EXIT;
