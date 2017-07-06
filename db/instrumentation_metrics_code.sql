DROP SEQUENCE instrumentation_metrics_seq;

CREATE SEQUENCE instrumentation_metrics_seq START WITH 1
                                            MAXVALUE 999999999999999999999999999
                                            MINVALUE 1
                                            NOCYCLE
                                            NOCACHE
                                            NOORDER;
/

ALTER TABLE instrumentation_metrics
    DROP PRIMARY KEY CASCADE;

DROP TABLE instrumentation_metrics CASCADE CONSTRAINTS;

CREATE TABLE instrumentation_metrics
(
    im_id       NUMBER,
    im_metric   VARCHAR2 (200 BYTE) NOT NULL,
    im_value    NUMBER DEFAULT 0,
    im_type     VARCHAR2 (250 BYTE),
    im_help     VARCHAR2 (350 BYTE)
);

CREATE UNIQUE INDEX instrumentation_metrics_pk
    ON instrumentation_metrics (im_id);

CREATE UNIQUE INDEX instrumentation_metrics_un
    ON instrumentation_metrics (im_metric);

CREATE OR REPLACE TRIGGER instrumentation_metrics_trg
    BEFORE INSERT
    ON instrumentation_metrics
    REFERENCING NEW AS new OLD AS old
    FOR EACH ROW
BEGIN
    :new.im_id := instrumentation_metrics_seq.NEXTVAL;
END instrumentation_metrics_trg;
/


ALTER TABLE instrumentation_metrics ADD (
  CONSTRAINT instrumentation_metrics_pk
  PRIMARY KEY
  (im_id)
  USING INDEX instrumentation_metrics_pk
  ENABLE VALIDATE);
/

CREATE OR REPLACE PACKAGE im_metrics
AS
    /******************************************************************************
       NAME:       im_metrics
       PURPOSE:   περιέχει κώδικα που υλοποιεί τον μηχανισμό των μετρήσεων

       REVISIONS:
       Ver        Date        Author           Description
       ---------  ----------  ---------------  ------------------------------------
       1.0        05/10/2016  Β. Στεργιούλης   1. Created this package.
    ******************************************************************************/

    -- Αύξηση κατά 1 ενός αθροιστή (counter) με metric id
    PROCEDURE incr_metric (p_metric_id NUMBER);

    -- Αύξηση κατά 1 ενός αθροιστή (counter) με metric name
    PROCEDURE incr_metric (p_metric VARCHAR2);

    -- Αύξηση κατά p_value ενός αθροιστή (counter) με metric id
    PROCEDURE incr_metric_by (p_metric_id NUMBER, p_value NUMBER);

    -- Αύξηση κατά p_value ενός αθροιστή (counter) με metric name
    PROCEDURE incr_metric_by (p_metric VARCHAR2, p_value NUMBER);

    -- Ενημέρωση με την τιμή  p_value ενός μετρητή (gauge) με metric id
    PROCEDURE set_metric (p_metric_id NUMBER, p_value NUMBER);

    -- Ενημέρωση με την τιμή  p_value ενός μετρητή (gauge) με metric name
    PROCEDURE set_metric (p_metric VARCHAR2, p_value NUMBER);

    -- Αρχικοποίηση ενός metric
    FUNCTION init_metric_name (p_metric    VARCHAR2,
                               p_type      VARCHAR2,
                               p_help      VARCHAR2)
        RETURN NUMBER;

    -- timer function to calculate diffs in seconds with big precision
    FUNCTION timer (p_start TIMESTAMP, p_end TIMESTAMP)
        RETURN NUMBER;
END;
/

CREATE OR REPLACE PACKAGE BODY im_metrics
AS
    /******************************************************************************
       NAME:       im_metrics
       PURPOSE:   περιέχει κώδικα που υλοποιεί τον μηχανισμό των μετρήσεων

       REVISIONS:
       Ver        Date        Author           Description
       ---------  ----------  ---------------  ------------------------------------
       1.0        05/10/2016  Β. Στεργιούλης   1. Created this package.
    ******************************************************************************/
    /*
    -- example call
    DECLARE
       i   NUMBER;
    BEGIN
       i :=
          im_metrics.init_metric_name (
             p_metric   => 'ep_ws_outbound_requests_total{type="some_service",sub="subtype"}',
             p_type     => 'counter',
             p_help     => 'total number of web service some_service for subtype requests');
       commit;
    end;
    */


    -- timer function to calculate diffs in seconds with big precision
    FUNCTION timer (p_start TIMESTAMP, p_end TIMESTAMP)
        RETURN NUMBER
    IS
        v_ms   NUMBER;
    BEGIN
        SELECT   (  SUM (
                            (  EXTRACT (HOUR FROM p_end)
                             - EXTRACT (HOUR FROM p_start))
                          * 3600
                        +   (  EXTRACT (MINUTE FROM p_end)
                             - EXTRACT (MINUTE FROM p_start))
                          * 60
                        + EXTRACT (SECOND FROM p_end)
                        - EXTRACT (SECOND FROM p_start))
                  * 1000)
               / 1000
          INTO v_ms
          FROM DUAL;

        RETURN v_ms;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN 0;
    END;

    -- ενημερώνει την τιμή ενός μετρητικού στοιχείου αυξάνοντας την κατά την p_value
    -- χρησιμοποιώντας για την εύρεση το κλειδί p_metric. αν δεν την βρει την εισάγει
    PROCEDURE upsert (p_metric    VARCHAR2,
                      p_value     NUMBER DEFAULT 1,
                      p_action    VARCHAR2 DEFAULT 'inc')
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        UPDATE instrumentation_metrics
           SET im_value =
                     CASE
                         WHEN p_action = 'inc' THEN NVL (im_value, 0)
                         ELSE 0
                     END
                   + p_value
         WHERE im_metric = p_metric;

        IF SQL%ROWCOUNT = 0
        THEN
            INSERT INTO instrumentation_metrics (im_metric, im_value)
                 VALUES (p_metric, p_value);
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
    END;

    -- ενημερώνει την τιμή ενός μετρητικού στοιχείου αυξάνοντας την κατά την p_value
    -- χρησιμοποιώντας για την εύρεση το κλειδί p_metric_id. αν δεν την βρει την εισάγει
    -- χρησιμοποιώντας το υποχρεωτικό p_metric το οποίο δεν πρέπει να είναι null
    PROCEDURE upsert (p_metric_id    NUMBER,
                      p_value        NUMBER DEFAULT 1,
                      p_action       VARCHAR2 DEFAULT 'inc',
                      p_metric       VARCHAR2 DEFAULT NULL)
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        UPDATE instrumentation_metrics
           SET im_value =
                     CASE
                         WHEN p_action = 'inc' THEN NVL (im_value, 0)
                         ELSE 0
                     END
                   + p_value
         WHERE im_id = p_metric_id;

        IF SQL%ROWCOUNT = 0
        THEN
            INSERT INTO instrumentation_metrics (im_id, im_metric, im_value)
                 VALUES (p_metric_id, p_metric, p_value);
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
    END;

    -- αύξηση κατά 1 ενός αθροιστή (counter) με metric id
    PROCEDURE incr_metric (p_metric_id NUMBER)
    IS
    BEGIN
        upsert (p_metric_id => p_metric_id, p_value => 1, p_action => 'inc');
    END;

    -- αύξηση κατά 1 ενός αθροιστή (counter) με metric name
    PROCEDURE incr_metric (p_metric VARCHAR2)
    IS
    BEGIN
        upsert (p_metric => p_metric, p_value => 1, p_action => 'inc');
    END;

    -- αύξηση κατά p_value ενός αθροιστή (counter) με metric id
    PROCEDURE incr_metric_by (p_metric_id NUMBER, p_value NUMBER)
    IS
    BEGIN
        upsert (p_metric_id   => p_metric_id,
                p_value       => NVL (p_value, 0),
                p_action      => 'inc');
    END;

    -- αύξηση κατά p_value ενός αθροιστή (counter) με metric name
    PROCEDURE incr_metric_by (p_metric VARCHAR2, p_value NUMBER)
    IS
    BEGIN
        upsert (p_metric   => p_metric,
                p_value    => NVL (p_value, 0),
                p_action   => 'inc');
    END;

    -- ενημέρωση με την τιμή  p_value ενός μετρητή (gauge) με metric id
    PROCEDURE set_metric (p_metric_id NUMBER, p_value NUMBER)
    IS
    BEGIN
        upsert (p_metric_id   => p_metric_id,
                p_value       => NVL (p_value, 0),
                p_action      => 'set');
    END;

    -- ενημέρωση με την τιμή  p_value ενός μετρητή (gauge) με metric name
    PROCEDURE set_metric (p_metric VARCHAR2, p_value NUMBER)
    IS
    BEGIN
        upsert (p_metric   => p_metric,
                p_value    => NVL (p_value, 0),
                p_action   => 'set');
    END;

    -- αρχικοποίηση ενός metric
    FUNCTION init_metric_name (p_metric    VARCHAR2,
                               p_type      VARCHAR2,
                               p_help      VARCHAR2)
        RETURN NUMBER
    IS
        ret   NUMBER;
    BEGIN
        IF p_type IN ('counter', 'gauge', 'summary')
        THEN
            INSERT INTO instrumentation_metrics (im_metric, im_type, im_help)
                     VALUES (
                                p_metric,
                                '# type ' || p_metric || ' ' || p_type,
                                '# help ' || p_metric || ' ' || p_help)
              RETURNING im_id
                   INTO ret;

            RETURN ret;
        ELSE
            raise_application_error (
                -20999,
                'λάθος τύπος μετρητή, αποδεκτοί είναι οι counter, gauge και summary');
        END IF;
    END;
END;
/
