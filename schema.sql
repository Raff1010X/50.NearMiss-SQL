--
-- PostgreSQL database dump
--

-- Dumped from database version 14.3
-- Dumped by pg_dump version 14.3

-- Started on 2022-09-28 05:52:28

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 4 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- TOC entry 3509 (class 0 OID 0)
-- Dependencies: 4
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 238 (class 1255 OID 27243)
-- Name: x_check_user_password(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_check_user_password(json) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE 
user_email text:= x_trym(($1::json->'email')::text);
user_password text:= x_trym(($1::json->'password')::text);
_user_id text;
BEGIN
SELECT user_id INTO _user_id
FROM users
WHERE email = user_email
  AND password = crypt(user_password, password);
RETURN (
  SELECT CASE
      WHEN _user_id IS NOT NULL THEN _user_id
      ELSE 'false'
    END
);
END;
$_$;


--
-- TOC entry 239 (class 1255 OID 27244)
-- Name: x_check_user_password(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_check_user_password(user_email text, user_password text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE _user_id text;
BEGIN
SELECT user_id INTO _user_id
FROM users
WHERE email = user_email
  AND password = crypt(user_password, password);
RETURN (
  SELECT CASE
      WHEN _user_id IS NOT NULL THEN _user_id
      ELSE 'false'
    END
);
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 210 (class 1259 OID 27245)
-- Name: comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comments (
    comment_id integer NOT NULL,
    report_id integer NOT NULL,
    user_id uuid NOT NULL,
    comment character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL
);


--
-- TOC entry 211 (class 1259 OID 27249)
-- Name: reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reports (
    report_id integer NOT NULL,
    user_id uuid,
    created_at date DEFAULT CURRENT_DATE,
    department_id integer,
    place character varying(1024),
    date date,
    hour time without time zone,
    threat_id integer,
    threat character varying(1024),
    consequence_id integer,
    consequence character varying(1024),
    actions character varying(1024),
    photo character varying(255),
    execution_limit date,
    executed_at date
);


--
-- TOC entry 212 (class 1259 OID 27255)
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    user_id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying(255) NOT NULL,
    password character varying NOT NULL,
    role_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0) NOT NULL,
    updated_at timestamp without time zone,
    visited_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP(0),
    password_updated character varying,
    is_active boolean DEFAULT true NOT NULL,
    department_id integer NOT NULL,
    reset_token character varying
);


--
-- TOC entry 213 (class 1259 OID 27264)
-- Name: comments_all; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.comments_all AS
 SELECT u.email AS "Autor",
    c.comment AS "Wpis",
    c.created_at AS "Data",
    r.report_id AS "ID raportu",
    c.comment_id AS "Numer komentarza"
   FROM ((public.comments c
     LEFT JOIN public.users u USING (user_id))
     LEFT JOIN public.reports r USING (report_id))
  ORDER BY c.comment;


--
-- TOC entry 240 (class 1255 OID 27269)
-- Name: x_comment(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_comment(_json json) RETURNS SETOF public.comments_all
    LANGUAGE plpgsql
    AS $_$
DECLARE
  id_komentarza text := (x_trym(($1::json->'comment_id') :: text));
BEGIN
  return QUERY EXECUTE 'SELECT * FROM comments_all WHERE "Numer komentarza" = ''' || id_komentarza || ''' ORDER BY "ID raportu";';
END;
$_$;


--
-- TOC entry 242 (class 1255 OID 27270)
-- Name: x_comment_create(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_comment_create(_json json) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE _report_id integer := (x_trym(($1::json->'Numer zgloszenia')::text))::integer;
_user_id text := (
  SELECT user_id
  FROM users
  WHERE email = (
      (x_trym(($1::json->'Adres email')::text))::character varying(50)
    )
);
_comment text := x_trym(($1::json->'Komentarz')::text);
_query text := 'INSERT INTO comments (
            report_id,
            user_id,
            comment
          ) VALUES (
            ' || _report_id || ',
            ''' || _user_id || ''',
            ''' || _comment || '''
          ) RETURNING comment_id;';
_result integer;
BEGIN execute _query into _result;
return _result;


END;
$_$;


--
-- TOC entry 246 (class 1255 OID 27271)
-- Name: x_comment_delete(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_comment_delete(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _comment_id integer := (x_trym(($1::json->'comment_id')::text))::integer;
_query text := 'DELETE FROM comments WHERE comment_id = ' || _comment_id || ' RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
return _result;





END;
$_$;


--
-- TOC entry 247 (class 1255 OID 27272)
-- Name: x_comment_update(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_comment_update(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _comment_id integer := (x_trym(($1::json->'comment_id')::text))::integer;
_comment text := x_trym(($1::json->'Komentarz')::text);
_query text := 'UPDATE comments SET
            comment = ''' || _comment || '''
          WHERE comment_id = ' || _comment_id || '
          RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
return _result;





END;
$_$;


--
-- TOC entry 248 (class 1255 OID 27273)
-- Name: x_comments_by_user(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_comments_by_user(_json json) RETURNS SETOF public.comments_all
    LANGUAGE plpgsql
    AS $_$
DECLARE
  email text := (x_trym(($1::json->'user_email') :: text));
BEGIN
  return QUERY EXECUTE 'SELECT * FROM comments_all WHERE "Autor" = ''' || email || ''' ORDER BY "ID raportu";';
END;
$_$;


--
-- TOC entry 255 (class 1255 OID 27274)
-- Name: x_comments_to_report(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_comments_to_report(_json json) RETURNS SETOF public.comments_all
    LANGUAGE plpgsql
    AS $_$
DECLARE
  _report_id text := (x_trym(($1::json->'report_id') :: text));
BEGIN
  return QUERY EXECUTE 'SELECT * FROM comments_all WHERE "ID raportu" = ' || _report_id || ' ORDER BY "Data";';
END;
$_$;


--
-- TOC entry 258 (class 1255 OID 27275)
-- Name: x_copy_data(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_copy_data() RETURNS integer
    LANGUAGE plpgsql
    AS $$ BEGIN FOR i IN 1..500 LOOP
INSERT INTO reports (
    user_id,
    created_at,
    department_id,
    place,
    date,
    hour,
    threat_id,
    threat,
    consequence_id,
    consequence,
    actions,
    photo,
    execution_limit,
    executed_at
  )
VALUES (
    (
      SELECT user_id
      FROM users
      WHERE email = (
          SELECT user_id
          FROM reports_raw
          WHERE report_id = i
        )
    ),
    (
      SELECT created_at
      FROM reports_raw
      WHERE report_id = i
    ),
    (
      SELECT department_id
      FROM departments
      WHERE department = (
          SELECT department_id
          FROM reports_raw
          WHERE report_id = i
        )
    ),
    (
      SELECT place
      FROM reports_raw
      WHERE report_id = i
    ),
    (
      SELECT date
      FROM reports_raw
      WHERE report_id = i
    ),
    (
      SELECT hour
      FROM reports_raw
      WHERE report_id = i
    ),
    (
      SELECT threat_id
      FROM threats
      WHERE threat = (
          SELECT threat_id
          FROM reports_raw
          WHERE report_id = i
        )
    ),
    (
      SELECT threat
      FROM reports_raw
      WHERE report_id = i
    ),
    (
      SELECT consequence_id
      FROM consequences
      WHERE consequence = (
          SELECT consequence_id
          FROM reports_raw
          WHERE report_id = i
        )
    ),
    (
      SELECT consequence
      FROM reports_raw
      WHERE report_id = i
    ),
    (
      SELECT actions
      FROM reports_raw
      WHERE report_id = i
    ),
    (
      SELECT photo
      FROM reports_raw
      WHERE report_id = i
    ),
    (
      SELECT execution_limit
        FROM reports_raw
      WHERE report_id = i
    ),
    (
      SELECT executed_at
      FROM reports_raw
      WHERE report_id = i
    )
  );
END LOOP;
RETURN 1;
END;
$$;


--
-- TOC entry 259 (class 1255 OID 27276)
-- Name: x_department_create(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_department_create(_json json) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE _department text := x_trym(($1::json->'department')::text);
_query text := 'INSERT INTO departments (department) 
          VALUES (''' || _department || ''') RETURNING department_id;';
_result integer;
BEGIN execute _query into _result;
return _result;


END;
$_$;


--
-- TOC entry 260 (class 1255 OID 27277)
-- Name: x_department_delete(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_department_delete(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _department_id text := x_trym(($1::json->'department_id')::text);
_query text := 'DELETE FROM departments WHERE department_id = ''' || _department_id || ''' RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
return _result;





END;
$_$;


--
-- TOC entry 261 (class 1255 OID 27278)
-- Name: x_department_update(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_department_update(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _department_id text := x_trym(($1::json->'department_id')::text);
_department text := x_trym(($1::json->'department')::text);
_query text := 'UPDATE departments SET
           department = ''' || _department || '''
          WHERE department_id = ''' || _department_id || '''
          RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
return _result;





END;
$_$;


--
-- TOC entry 262 (class 1255 OID 27279)
-- Name: x_function_create(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_function_create(_json json) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE _function text := x_trym(($1::json->'function')::text);
_query text := 'INSERT INTO functions (function_name) 
          VALUES (''' || _function || ''') RETURNING function_id;';
_result integer;
BEGIN execute _query into _result;
return _result;


END;
$_$;


--
-- TOC entry 263 (class 1255 OID 27280)
-- Name: x_function_delete(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_function_delete(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _function_id text := x_trym(($1::json->'function_id')::text);
_query text := 'DELETE FROM functions WHERE function_id = ''' || _function_id || ''' RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
return _result;





END;
$_$;


--
-- TOC entry 241 (class 1255 OID 27281)
-- Name: x_function_update(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_function_update(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _function_id text := x_trym(($1::json->'function_id')::text);
_function text := x_trym(($1::json->'function')::text);
_query text := 'UPDATE functions SET
           function_name = ''' || _function || '''
          WHERE function_id = ''' || _function_id || '''
          RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
return _result;





END;
$_$;


--
-- TOC entry 264 (class 1255 OID 27282)
-- Name: x_manager_create(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_manager_create(_json json) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE _function_id text := (
    SELECT function_id
    FROM functions
    WHERE function_name = (
        (x_trym(($1::json->'function')::text))::character varying(255)
      )
  );
_user_id text := (
  SELECT user_id
  FROM users
  WHERE email = (
      (x_trym(($1::json->'email')::text))::character varying(255)
    )
);
_query text := 'INSERT INTO managers (
            function_id,
            user_id
          ) VALUES (
            ''' || _function_id || ''',
            ''' || _user_id || '''
          ) RETURNING manager_id;';
_result integer;
BEGIN execute _query into _result;
RETURN _result;


END;
$_$;


--
-- TOC entry 265 (class 1255 OID 27283)
-- Name: x_manager_delete(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_manager_delete(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _manager_id integer := (x_trym(($1::json->'manager_id')::text))::integer;
_query text := 'DELETE FROM managers WHERE manager_id = ' || _manager_id || ' RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
RETURN _result;





END;
$_$;


--
-- TOC entry 266 (class 1255 OID 27284)
-- Name: x_manager_update(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_manager_update(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _manager_id integer := (x_trym(($1::json->'manager_id')::text))::integer;
_function_id text := (
  SELECT function_id
  FROM functions
  WHERE function_name = (
      (x_trym(($1::json->'function')::text))::character varying(255)
    )
);
_user_id text := (
  SELECT user_id
  FROM users
  WHERE email = (
      (x_trym(($1::json->'email')::text))::character varying(50)
    )
);
_query text := 'UPDATE managers SET
        function_id = ''' || _function_id || ''',
        user_id = ''' || _user_id || '''
      WHERE manager_id = ' || _manager_id || '
      RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
RETURN _result;





END;
$_$;


--
-- TOC entry 214 (class 1259 OID 27285)
-- Name: departments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.departments (
    department_id integer NOT NULL,
    department character varying(50) NOT NULL
);


--
-- TOC entry 215 (class 1259 OID 27288)
-- Name: functions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.functions (
    function_id integer NOT NULL,
    function_name character varying(50) NOT NULL
);


--
-- TOC entry 216 (class 1259 OID 27291)
-- Name: managers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.managers (
    manager_id integer NOT NULL,
    function_id integer NOT NULL,
    user_id uuid NOT NULL
);


--
-- TOC entry 217 (class 1259 OID 27294)
-- Name: managers_emails; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.managers_emails AS
 SELECT d.department AS "Dzia??",
    u.email AS "Adres email",
    m.manager_id AS "ID",
    f.function_name AS "Funkcja"
   FROM (((public.managers m
     LEFT JOIN public.users u USING (user_id))
     LEFT JOIN public.departments d USING (department_id))
     LEFT JOIN public.functions f USING (function_id))
  ORDER BY d.department;


--
-- TOC entry 267 (class 1255 OID 27299)
-- Name: x_managers_emails(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_managers_emails(json) RETURNS SETOF public.managers_emails
    LANGUAGE plpgsql
    AS $_$ 
BEGIN 
  IF ($1::json->>'department_name')::text IS NULL THEN
    RETURN QUERY
    SELECT *
    FROM managers_emails;
  ELSE
    RETURN QUERY
    SELECT *
    FROM managers_emails
    WHERE "Dzia??" ILIKE ($1::json->>'department_name')::text;
  END IF;
END $_$;


--
-- TOC entry 268 (class 1255 OID 27300)
-- Name: x_report_create(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_report_create(_json json) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE _user_id text := (
    SELECT user_id
    FROM users
    WHERE email ILIKE x_trym(($1::json->'Zg??aszaj??cy')::text)
  );
_department_id integer := (
  SELECT department_id
  FROM departments
  WHERE department ILIKE x_trym(($1::json->'Dzia??')::text)
);
_place text := x_trym(($1::json->'Miejsce')::text);
_date text := ($1::json->'Data zdarzenia');
_hour text := x_trym(($1::json->'Godzina zdarzenia')::text);
_threat_id integer := (
  SELECT threat_id
  FROM threats
  WHERE threat ILIKE x_trym(($1::json->'Zagro??enie')::text)
);
_threat text := x_trym(($1::json->'Opis Zagro??enia')::text);
_consequence_id integer := (
  SELECT consequence_id
  FROM consequences
  WHERE consequence ILIKE x_trym(($1::json->'Konsekwencje')::text)
);
_consequence text := x_trym(($1::json->'Skutek')::text);
_actions text := x_trym(($1::json->'Dzia??ania do wykonania')::text);
_photo text := x_trym(($1::json->'Zdj??cie')::text);
_execution_limit text := (current_date + (70 / _consequence_id)::integer)::text;
_query text := 'INSERT INTO reports(
            user_id,
            department_id,
            place,
            date,
            hour,
            threat_id,
            threat,
            consequence_id,
            consequence,
            actions,
            photo,
            execution_limit
          ) VALUES (
            ''' || _user_id || ''',
            ' || _department_id || ',
            ''' || _place || ''',
            ''' || _date || ''',
            ''' || _hour || ''',
            ' || _threat_id || ',
            ''' || _threat || ''',
            ' || _consequence_id || ',
            ''' || _consequence || ''',
            ''' || _actions || ''',
            ''' || _photo || ''',
            ''' || _execution_limit || '''
          ) RETURNING report_id;';
_result integer;
BEGIN execute _query into _result;
RETURN _result;


END;
$_$;


--
-- TOC entry 269 (class 1255 OID 27301)
-- Name: x_report_delete(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_report_delete(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _report_id integer := x_trym(($1::json->'report_id')::text)::integer;
_query text := 'DELETE FROM reports WHERE report_id = ' || _report_id || ' RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
RETURN _result;





END;
$_$;


--
-- TOC entry 270 (class 1255 OID 27302)
-- Name: x_report_executed(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_report_executed(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _report_id integer := x_trym(($1::json->'report_id')::text)::integer;
_executed_at text := (current_date)::text;
_query text := 'UPDATE reports SET
            executed_at = ''' || _executed_at || '''
          WHERE report_id = ' || _report_id || '
          RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
RETURN _result;
END;
$_$;


--
-- TOC entry 271 (class 1255 OID 27303)
-- Name: x_report_update(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_report_update(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _report_id integer := x_trym(($1::json->'report_id')::text)::integer;
_department_id integer := (
  SELECT department_id
  FROM departments
  WHERE department = (
      (x_trym(($1::json->'Dzia??')::text))::character varying(50)
    )
);
_place text := x_trym(($1::json->'Miejsce')::text);
_date text := x_trym(($1::json->'Data zdarzenia')::text);
_hour text := x_trym(($1::json->'Godzina zdarzenia')::text);
_threat_id integer := (
  SELECT threat_id
  FROM threats
  WHERE threat = (
      (x_trym(($1::json->'Zagro??enie')::text))::character varying(50)
    )
);
_threat text := x_trym(($1::json->'Opis Zagro??enia')::text);
_consequence_id integer := (
  SELECT consequence_id
  FROM consequences
  WHERE consequence = (
      (x_trym(($1::json->'Konsekwencje')::text))::character varying(50)
    )
);
_consequence text := x_trym(($1::json->'Skutek')::text);
_actions text := x_trym(($1::json->'Dzia??ania do wykonania')::text);
_photo text := x_trym(($1::json->'Zdj??cie')::text);
_execution_limit text := (
  current_date + (70 / _consequence_id)::integer
)::text;
_query text := 'UPDATE reports SET
            department_id = ' || _department_id || ',
            place = ''' || _place || ''',
            date = ''' || _date || ''',
            hour = ''' || _hour || ''',
            threat_id = ' || _threat_id || ',
            threat = ''' || _threat || ''',
            consequence_id = ' || _consequence_id || ',
            consequence = ''' || _consequence || ''',
            actions = ''' || _actions || ''',
            photo = ''' || _photo || ''',
            execution_limit = ''' || _execution_limit || '''
          WHERE report_id = ' || _report_id || '
          RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
RETURN _result;





END;
$_$;


--
-- TOC entry 218 (class 1259 OID 27304)
-- Name: consequences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.consequences (
    consequence_id integer NOT NULL,
    consequence character varying(50) NOT NULL
);


--
-- TOC entry 219 (class 1259 OID 27307)
-- Name: threats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.threats (
    threat_id integer NOT NULL,
    threat character varying(50) NOT NULL
);


--
-- TOC entry 220 (class 1259 OID 27310)
-- Name: reports_all; Type: VIEW; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.reports_all AS
 SELECT r.report_id AS "Numer zg??oszenia",
    u.email AS "Zg??aszaj??cy",
    r.created_at AS "Data utworzenia",
    d.department AS "Dzia??",
    r.place AS "Miejsce",
    r.date AS "Data zdarzenia",
    r.hour AS "Godzina zdarzenia",
    t.threat AS "Zagro??enie",
    r.threat AS "Opis Zagro??enia",
    r.consequence AS "Skutek",
    c.consequence AS "Konsekwencje",
    r.actions AS "Dzia??ania do wykonania",
    r.photo AS "Zdj??cie",
    r.execution_limit AS "Czas na realizacj??",
    r.executed_at AS "Data wykonania",
        CASE
            WHEN (((r.executed_at)::text = ''::text) IS NOT FALSE) THEN 'Niewykonane'::text
            ELSE 'Wykonane'::text
        END AS "Status"
   FROM ((((public.reports r
     LEFT JOIN public.departments d USING (department_id))
     LEFT JOIN public.threats t USING (threat_id))
     LEFT JOIN public.consequences c USING (consequence_id))
     LEFT JOIN public.users u USING (user_id));


--
-- TOC entry 272 (class 1255 OID 27315)
-- Name: x_reports_all(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_reports_all(json) RETURNS SETOF public.reports_all
    LANGUAGE plpgsql
    AS $_$
DECLARE numer text := CASE
    WHEN ($1::json->>'report_id') IS NULL THEN '"Numer zg??oszenia" IS NOT NULL'
    ELSE (
      ' "Numer zg??oszenia" = ' || ($1::json->>'report_id')
    )
  END;
zg??aszaj??cy text := CASE
  WHEN ($1::json->>'zg??aszaj??cy') IS NULL THEN ''
  ELSE (
    ' AND "Zg??aszaj??cy" ILIKE ''%%' || ($1::json->>'zg??aszaj??cy') || '%%'''
  )
END;
dzia?? text := CASE
  WHEN ($1::json->>'dzia??') IS NULL THEN ''
  ELSE (
    ' AND "Dzia??" ILIKE ''%%' || ($1::json->>'dzia??') || '%%'''
  )
END;
miejsce text := CASE
  WHEN ($1::json->>'miejsce') IS NULL THEN ''
  ELSE (
    ' AND "Miejsce" ILIKE ''%%' || ($1::json->>'miejsce') || '%%'''
  )
END;
data_od text := CASE
  WHEN ($1::json->>'from') IS NULL THEN ''
  ELSE (
    ' AND "Data zdarzenia" >= ''' || ($1::json->>'from') || ''''
  )
END;
data_do text := CASE
  WHEN ($1::json->>'to') IS NULL THEN ''
  ELSE (
    ' AND "Data zdarzenia" <= ''' || ($1::json->>'to') || ''''
  )
END;
zagro??enie text := CASE
  WHEN ($1::json->>'zagro??enie') IS NULL THEN ''
  ELSE (
    ' AND "Zagro??enie" ILIKE ''%%' || ($1::json->>'zagro??enie') || '%%'''
  )
END;
opis text := CASE
  WHEN ($1::json->>'opis') IS NULL THEN ''
  ELSE (
    ' AND "Opis Zagro??enia" ILIKE ''%%' || ($1::json->>'opis') || '%%'''
  )
END;
skutek text := CASE
  WHEN ($1::json->>'skutek') IS NULL THEN ''
  ELSE (
    ' AND "Skutek" ILIKE ''%%' || ($1::json->>'skutek') || '%%'''
  )
END;
dzia??ania text := CASE
  WHEN ($1::json->>'dzia??ania') IS NULL THEN ''
  ELSE (
    ' AND "Dzia??ania do wykonania" ILIKE ''%%' || ($1::json->>'dzia??ania') || '%%'''
  )
END;
konsekwencje text := CASE
  WHEN ($1::json->>'konsekwencje') IS NULL THEN ''
  ELSE (
    ' AND "Konsekwencje" ILIKE ''%%' || ($1::json->>'konsekwencje') || '%%'''
  )
END;
_status text := CASE
  WHEN ($1::json->>'status') IS NULL THEN ''
  ELSE (
    ' AND "Status" LIKE ''%%' || ($1::json->>'status') || '%%'''
  )
END;
_order text := CASE
  WHEN ($1::json->>'order') IS NULL THEN ' '
  ELSE (
    ' ORDER BY "' || ($1::json->>'order' || '"')
  )
END;
_desc text := CASE
  WHEN ($1::json->>'desc') IS NULL
  OR ($1::json->>'order') IS NULL THEN ''
  ELSE ' DESC'
END;
_order2 text := CASE
  WHEN ($1::json->>'order') IS NULL THEN ' '
  ELSE (', "Numer zg??oszenia"')
END;
_limit text := CASE
  WHEN ($1::json->>'limit') IS NULL THEN ' '
  ELSE (' LIMIT ' || ($1::json->>'limit')::text)
END;
_offset text := CASE
  WHEN ($1::json->>'offset') IS NULL THEN ' '
  ELSE (' OFFSET ' || ($1::json->>'offset')::text)
END;
query text := 'SELECT * FROM reports_all WHERE ' || numer || zg??aszaj??cy || dzia?? || miejsce || data_od || data_do || zagro??enie || opis || skutek || dzia??ania || konsekwencje || _status || _order || _desc || _order2 || _limit || _offset;
BEGIN RETURN QUERY EXECUTE query;
END $_$;


--
-- TOC entry 273 (class 1255 OID 27316)
-- Name: x_reports_all_count(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_reports_all_count(json) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE numer text := CASE
    WHEN ($1::json->>'report_id') IS NULL THEN '"Numer zg??oszenia" IS NOT NULL'
    ELSE (
      ' "Numer zg??oszenia" = ' || ($1::json->>'report_id')
    )
  END;
zg??aszaj??cy text := CASE
  WHEN ($1::json->>'zg??aszaj??cy') IS NULL THEN ''
  ELSE (
    ' AND "Zg??aszaj??cy" ILIKE ''%%' || ($1::json->>'zg??aszaj??cy') || '%%'''
  )
END;
dzia?? text := CASE
  WHEN ($1::json->>'dzia??') IS NULL THEN ''
  ELSE (
    ' AND "Dzia??" ILIKE ''%%' || ($1::json->>'dzia??') || '%%'''
  )
END;
miejsce text := CASE
  WHEN ($1::json->>'miejsce') IS NULL THEN ''
  ELSE (
    ' AND "Miejsce" ILIKE ''%%' || ($1::json->>'miejsce') || '%%'''
  )
END;
data_od text := CASE
  WHEN ($1::json->>'from') IS NULL THEN ''
  ELSE (
    ' AND "Data zdarzenia" >= ''' || ($1::json->>'from') || ''''
  )
END;
data_do text := CASE
  WHEN ($1::json->>'to') IS NULL THEN ''
  ELSE (
    ' AND "Data zdarzenia" <= ''' || ($1::json->>'to') || ''''
  )
END;
zagro??enie text := CASE
  WHEN ($1::json->>'zagro??enie') IS NULL THEN ''
  ELSE (
    ' AND "Zagro??enie" ILIKE ''%%' || ($1::json->>'zagro??enie') || '%%'''
  )
END;
opis text := CASE
  WHEN ($1::json->>'opis') IS NULL THEN ''
  ELSE (
    ' AND "Opis Zagro??enia" ILIKE ''%%' || ($1::json->>'opis') || '%%'''
  )
END;
skutek text := CASE
  WHEN ($1::json->>'skutek') IS NULL THEN ''
  ELSE (
    ' AND "Skutek" ILIKE ''%%' || ($1::json->>'skutek') || '%%'''
  )
END;
dzia??ania text := CASE
  WHEN ($1::json->>'dzia??ania') IS NULL THEN ''
  ELSE (
    ' AND "Dzia??ania do wykonania" ILIKE ''%%' || ($1::json->>'dzia??ania') || '%%'''
  )
END;
konsekwencje text := CASE
  WHEN ($1::json->>'konsekwencje') IS NULL THEN ''
  ELSE (
    ' AND "Konsekwencje" ILIKE ''%%' || ($1::json->>'konsekwencje') || '%%'''
  )
END;
_status text := CASE
  WHEN ($1::json->>'status') IS NULL THEN ''
  ELSE (
    ' AND "Status" LIKE ''%%' || ($1::json->>'status') || '%%'''
  )
END;
counted integer := 0;
query text := 'SELECT COUNT(*) FROM reports_all WHERE ' || numer || zg??aszaj??cy || dzia?? || miejsce || data_od || data_do || zagro??enie || opis || skutek || dzia??ania || konsekwencje || _status;
BEGIN EXECUTE query INTO counted;
RETURN counted;
END $_$;


--
-- TOC entry 274 (class 1255 OID 27317)
-- Name: x_reports_by_department(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_reports_by_department(_json json) RETURNS TABLE("Dzia??" character varying, "Liczba zg??osze?? przez dzia??" integer)
    LANGUAGE plpgsql
    AS $_$
DECLARE data_od text := CASE
    WHEN ($1::json->>'from') IS NULL THEN ''
    ELSE (
      'WHERE r.created_at >= ''' || ($1::json->>'from') || ''''
    )
  END;
data_do text := CASE
  WHEN ($1::json->>'to') IS NULL THEN ''
  ELSE (
    ' AND r.created_at <= ''' || ($1::json->>'to') || ''''
  )
END;
_query text := 'SELECT d.department,
      count(u.department_id)::integer AS "Liczba zg??osze?? przez dzia??"
    FROM reports r
      LEFT JOIN users u USING (user_id)
      LEFT JOIN departments d ON ((u.department_id = d.department_id))
    ' || data_od || data_do || '
    GROUP BY d.department
    ORDER BY 2 DESC';
BEGIN RETURN QUERY EXECUTE _query;
END $_$;


--
-- TOC entry 275 (class 1255 OID 27318)
-- Name: x_reports_stats(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_reports_stats(_json json) RETURNS TABLE("Liczba zg??osze??" integer, "Liczba zg??osze?? wykonanych" integer, "Procent zg??osze?? wykonanych" integer)
    LANGUAGE plpgsql
    AS $_$
DECLARE data_od text := CASE
    WHEN ($1::json->>'from') IS NULL THEN ''
    ELSE (
      'WHERE "Data utworzenia" >= ''' || ($1::json->>'from') || ''''
    )
  END;
data_do text := CASE
  WHEN ($1::json->>'to') IS NULL THEN ''
  ELSE (
    ' AND "Data utworzenia" <= ''' || ($1::json->>'to') || ''''
  )
END;
_query text := 'SELECT
    count(r."Dzia??")::integer AS "Liczba zg??osze??",
    count(r."Data wykonania")::integer AS "Liczba zg??osze?? wykonanych",
    (round((((count(r."Data wykonania")) :: numeric / (count(r."Dzia??")) :: numeric) * (100) :: numeric))) :: integer AS "Procent zg??osze?? wykonanych"
  FROM
    reports_all r
    ' || data_od || data_do;
BEGIN RETURN QUERY EXECUTE _query;
END $_$;


--
-- TOC entry 276 (class 1255 OID 27319)
-- Name: x_reports_to_department(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_reports_to_department(_json json) RETURNS TABLE("Dzia??" character varying, "Liczba zg??osze??" integer, "Liczba zg??osze?? wykonanych" integer, "Procent zg??osze?? wykonanych" integer)
    LANGUAGE plpgsql
    AS $_$
DECLARE data_od text := CASE
    WHEN ($1::json->>'from') IS NULL THEN ''
    ELSE (
      'WHERE "Data utworzenia" >= ''' || ($1::json->>'from') || ''''
    )
  END;
data_do text := CASE
  WHEN ($1::json->>'to') IS NULL THEN ''
  ELSE (
    ' AND "Data utworzenia" <= ''' || ($1::json->>'to') || ''''
  )
END;
_query text := 'SELECT
    r."Dzia??",
    count(r."Dzia??")::integer AS "Liczba zg??osze??",
    count(r."Data wykonania")::integer AS "Liczba zg??osze?? wykonanych",
    (round((((count(r."Data wykonania")) :: numeric / (count(r."Dzia??")) :: numeric) * (100) :: numeric))) :: integer AS "Procent zg??osze?? wykonanych"
  FROM
    reports_all r
    ' || data_od || data_do || '
  GROUP BY
    1
  ORDER BY
    2 DESC';
BEGIN RETURN QUERY EXECUTE _query;
END $_$;


--
-- TOC entry 277 (class 1255 OID 27320)
-- Name: x_trym(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_trym(_text text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
    return TRIM('"' FROM _text);
END
$$;


--
-- TOC entry 278 (class 1255 OID 27321)
-- Name: x_update_user_password_by_token(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_update_user_password_by_token(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _reset_token text := x_trym(($1::json->'reset_token')::text);
_password text;
_result boolean;
BEGIN
SELECT password_updated INTO _password
FROM users
WHERE reset_token = _reset_token;
UPDATE users
SET password = _password,
  password_updated = NULL,
  is_active = true,
  reset_token = NULL,
  updated_at = now()::timestamp
WHERE reset_token = _reset_token
RETURNING true INTO _result;
RETURN _result;


END;
$_$;


--
-- TOC entry 221 (class 1259 OID 27322)
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    role_id integer NOT NULL,
    role character varying(50) NOT NULL
);


--
-- TOC entry 222 (class 1259 OID 27325)
-- Name: users_all; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.users_all AS
 SELECT DISTINCT u.email AS "Adres email",
        CASE
            WHEN ((r.role)::text = 'admin'::text) THEN 'Administrator'::text
            WHEN ((r.role)::text = 'superuser'::text) THEN 'Super u??ytkownik'::text
            ELSE 'U??ytkownik'::text
        END AS "Rola u??ytkownika",
    u.created_at AS "Data utworzenia",
        CASE
            WHEN (u.is_active = true) THEN 'Tak'::text
            ELSE 'Nie'::text
        END AS "Aktywny",
    d.department AS "Dzia??",
    u.user_id AS "ID u??ytkownika",
    u.updated_at AS "Data aktualizacji",
    u.reset_token AS "Token resetowania has??a"
   FROM (((public.users u
     LEFT JOIN public.roles r USING (role_id))
     LEFT JOIN public.managers m USING (user_id))
     LEFT JOIN public.departments d USING (department_id))
  ORDER BY d.department;


--
-- TOC entry 279 (class 1255 OID 27330)
-- Name: x_user_by_uuid(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_user_by_uuid(json) RETURNS SETOF public.users_all
    LANGUAGE plpgsql
    AS $_$
DECLARE 
query text := 'SELECT * FROM users_all WHERE "ID u??ytkownika" = ''' || ($1::json->>'user_id') || '''';
BEGIN RETURN QUERY EXECUTE query;
END;
$_$;


--
-- TOC entry 280 (class 1255 OID 27331)
-- Name: x_user_create(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_user_create(_json json) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE _email text := x_trym(($1::json->'email')::text);
_password_updated text := crypt(
  x_trym(($1::json->'password')::text),
  gen_salt('bf')
);
_password text := MD5(random()::text);
_is_active boolean := false;
_role_id integer := CASE
  WHEN ($1::json->>'email') LIKE '%@trendglass.pl' THEN 2
  ELSE 1
END CASE
;
_department_id integer := CASE
  WHEN ($1::json->>'department') IS NULL THEN 1
  ELSE (
    SELECT department_id
    FROM departments
    WHERE department = (
        (x_trym(($1::json->'department')::text))::character varying(50)
      )
  )
END;
_query text := 'INSERT INTO users (
            email,
            password,
            role_id,
            department_id,
            is_active,
            password_updated
          ) VALUES (
            ''' || _email || ''',
            ''' || _password || ''',
            ' || _role_id || ',
            ' || _department_id || ',
            ' || _is_active || ',
            ''' || _password_updated || '''
          ) RETURNING user_id;';
_result text;
BEGIN execute _query into _result;
return _result;
EXCEPTION
WHEN others THEN return false;
END;
$_$;


--
-- TOC entry 281 (class 1255 OID 27332)
-- Name: x_user_delete(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_user_delete(json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _user_id text := x_trym(($1::json->'user_id')::text);
_query text := 'DELETE FROM users WHERE user_id = ''' || _user_id || ''' RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
return _result;





END;
$_$;


--
-- TOC entry 282 (class 1255 OID 27333)
-- Name: x_user_number_of_raports(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_user_number_of_raports(json) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE _number_of_reports integer := 1;
_email text := ($1::json->>'email');
BEGIN
SELECT count(*)
FROM reports r
  LEFT JOIN users u ON r.user_id = u.user_id
WHERE u.email = _email INTO _number_of_reports;
RETURN _number_of_reports;
END;
$_$;


--
-- TOC entry 283 (class 1255 OID 27334)
-- Name: x_user_number_of_reports(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_user_number_of_reports(json) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE _number_of_reports integer := 0;
_user_id uuid := ($1::json->>'user_id');
BEGIN
SELECT count(*)
FROM reports
WHERE user_id = _user_id
 INTO _number_of_reports;
RETURN _number_of_reports;
END;
$_$;


--
-- TOC entry 284 (class 1255 OID 27335)
-- Name: x_user_update(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_user_update(_json json) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE _user_id text := x_trym(($1::json->'user_id')::text);
_email text := CASE
  WHEN ($1::json->>'email') IS NULL THEN ' '
  ELSE (
    'email = ''' || x_trym(($1::json->'email')::text) || ''','
  )
END;
_password text := CASE
  WHEN ($1::json->>'password') IS NULL THEN ' '
  ELSE (
    'password = ''' || crypt(
      x_trym(($1::json->'password')::text),
      gen_salt('bf')
    ) || ''','
  )
END;
_role_id text := CASE
  WHEN ($1::json->>'role') IS NULL THEN ' '
  ELSE (
    'role_id = ' || (
      SELECT role_id
      FROM roles
      WHERE role = (
          (x_trym(($1::json->'role')::text))::character varying(50)
        )
    ) || ','
  )
END;
_department_id text := CASE
  WHEN ($1::json->>'department') IS NULL THEN ' '
  ELSE (
    'department_id = ' || (
      SELECT department_id
      FROM departments
      WHERE department = (
          (x_trym(($1::json->'department')::text))::character varying(50)
        )
    ) || ','
  )
END;
_updated_at text := CASE
  WHEN ($1::json->>'reset_token') IS NULL THEN 'updated_at = NULL '
  ELSE ('updated_at = now()::timestamp ')
END;
_password_updated text := CASE
  WHEN ($1::json->>'password_updated') IS NULL THEN ' '
  ELSE (
    'password_updated = ''' || crypt(
      x_trym(($1::json->'password_updated')::text),
      gen_salt('bf')
    ) || ''','
  )
END;
_reset_token text := CASE
  WHEN ($1::json->>'reset_token') IS NULL THEN ' '
  ELSE (
    'reset_token = ''' || x_trym(($1::json->'reset_token')::text) || ''','
  )
END;
_is_active text := CASE
  WHEN ($1::json->>'is_active') IS NULL THEN ' '
  ELSE (
    'is_active = ' || x_trym(($1::json->'is_active')::text) || ','
  )
END;
_query text := 'UPDATE users SET
            ' || _email || '
            ' || _password || '
            ' || _password_updated || '
            ' || _role_id || '
            ' || _is_active || '
            ' || _department_id || '
            ' || _reset_token || '
            ' || _updated_at || '
          WHERE user_id = ''' || _user_id || '''
          RETURNING true;';
_result boolean;
BEGIN execute _query into _result;
return _result;





END;
$_$;


--
-- TOC entry 285 (class 1255 OID 27336)
-- Name: x_users_all(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_users_all(json) RETURNS SETOF public.users_all
    LANGUAGE plpgsql
    AS $_$
DECLARE _order text := CASE
    WHEN ($1::json->>'order') IS NULL THEN ' '
    ELSE (' ORDER BY "' || ($1::json->>'order' || '"'))
  END;
_desc text := CASE
  WHEN ($1::json->>'desc') IS NULL
  OR ($1::json->>'order') IS NULL THEN ''
  ELSE ' DESC'
END;
_limit text := CASE
  WHEN ($1::json->>'limit') IS NULL THEN ' '
  ELSE (' LIMIT ' || ($1::json->>'limit')::text)
END;
_offset text := CASE
  WHEN ($1::json->>'offset') IS NULL THEN ' '
  ELSE (' OFFSET ' || ($1::json->>'offset')::text)
END;
_email text := CASE
  WHEN ($1::json->>'email') IS NULL THEN ' '
  ELSE (
    'WHERE "Adres email" LIKE ''' || ($1::json->>'email') || '%'''
  )
END;
_reset_token text := CASE
  WHEN ($1::json->>'reset_token') IS NULL THEN ' '
  ELSE (
    'WHERE "Token resetowania has??a" = ''' || ($1::json->>'reset_token') || ''''
  )
END;
_user_id text := CASE
  WHEN ($1::json->>'user_id') IS NULL THEN ' '
  ELSE (
    'WHERE "ID u??ytkownika" = ''' || ($1::json->>'user_id') || ''''
  )
END;
query text := 'SELECT * FROM users_all ' || _email || _user_id || _reset_token || _order || _desc || _limit || _offset;
BEGIN RETURN QUERY EXECUTE query;
END;
$_$;


--
-- TOC entry 286 (class 1255 OID 27337)
-- Name: x_users_all(integer, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_users_all(_limit integer, _offset integer, _pattern text) RETURNS SETOF public.users_all
    LANGUAGE plpgsql
    AS $$ BEGIN RETURN QUERY
SELECT *
FROM users_all
WHERE "Adres email" ILIKE '%' || _pattern || '%'
LIMIT _limit OFFSET _offset;
END;
$$;


--
-- TOC entry 287 (class 1255 OID 27338)
-- Name: x_users_top_10(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.x_users_top_10(_json json) RETURNS TABLE(email character varying, "Liczba zg??osze??" integer, "Liczba zg??osze?? wykonanych" integer, "Liczba zg??osze?? nie wykonanych" integer)
    LANGUAGE plpgsql
    AS $_$
DECLARE from_date text := CASE
    WHEN ($1::json->>'from') IS NULL THEN 'WHERE "date" >= ''1900-01-01'''
    ELSE (
      ' WHERE "date" >= ''' || ($1::json->>'from') || ''''
    )
  END;
to_date text := CASE
  WHEN ($1::json->>'to') IS NULL THEN ''
  ELSE (' AND "date" <= ''' || ($1::json->>'to') || '''')
END;
_query text := 'SELECT
    u.email,
    count(u.email)::integer AS "Liczba zg??osze??",
    count(
      CASE
        WHEN (r.executed_at IS NOT NULL) THEN 1
        ELSE NULL :: integer
      END
    )::integer AS "Liczba zg??osze?? wykonanych",
    count(
      CASE
        WHEN (r.executed_at IS NULL) THEN 1
        ELSE NULL :: integer
      END
    )::integer AS "Liczba zg??osze?? nie wykonanych"
  FROM
    ( reports r
      LEFT JOIN users u USING (user_id))' || from_date || to_date || '
  GROUP BY
    u.email
  ORDER BY
    (count(u.email)) DESC
  LIMIT
    10';
BEGIN RETURN QUERY EXECUTE _query;
END $_$;


--
-- TOC entry 223 (class 1259 OID 27339)
-- Name: comments_comment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comments_comment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3510 (class 0 OID 0)
-- Dependencies: 223
-- Name: comments_comment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comments_comment_id_seq OWNED BY public.comments.comment_id;


--
-- TOC entry 224 (class 1259 OID 27340)
-- Name: consequences_consequence_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.consequences_consequence_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3511 (class 0 OID 0)
-- Dependencies: 224
-- Name: consequences_consequence_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.consequences_consequence_id_seq OWNED BY public.consequences.consequence_id;


--
-- TOC entry 225 (class 1259 OID 27341)
-- Name: departments_department_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.departments_department_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3512 (class 0 OID 0)
-- Dependencies: 225
-- Name: departments_department_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.departments_department_id_seq OWNED BY public.departments.department_id;


--
-- TOC entry 226 (class 1259 OID 27342)
-- Name: departments_top_10; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.departments_top_10 AS
 SELECT d.department,
    count(u.department_id) AS "Liczba zg??osze?? przez dzia??"
   FROM ((public.reports r
     LEFT JOIN public.users u USING (user_id))
     LEFT JOIN public.departments d ON ((u.department_id = d.department_id)))
  GROUP BY d.department
  ORDER BY (count(u.department_id)) DESC;


--
-- TOC entry 227 (class 1259 OID 27347)
-- Name: functions_function_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.functions_function_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3513 (class 0 OID 0)
-- Dependencies: 227
-- Name: functions_function_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.functions_function_id_seq OWNED BY public.functions.function_id;


--
-- TOC entry 228 (class 1259 OID 27348)
-- Name: managers_manager_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.managers_manager_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3514 (class 0 OID 0)
-- Dependencies: 228
-- Name: managers_manager_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.managers_manager_id_seq OWNED BY public.managers.manager_id;


--
-- TOC entry 229 (class 1259 OID 27349)
-- Name: reports_by_date; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.reports_by_date AS
 SELECT to_char((r.date)::timestamp with time zone, 'MM'::text) AS mon,
    EXTRACT(year FROM r.date) AS yyyy,
    d.department,
    count(u.department_id) AS "Liczba zg??osze??",
        CASE
            WHEN (count(u.department_id) > 4) THEN true
            ELSE false
        END AS "Cel 5 zg??osze??"
   FROM ((public.reports r
     LEFT JOIN public.users u USING (user_id))
     LEFT JOIN public.departments d ON ((u.department_id = d.department_id)))
  WHERE (r.date <= now())
  GROUP BY (to_char((r.date)::timestamp with time zone, 'MM'::text)), (EXTRACT(year FROM r.date)), d.department
  ORDER BY (EXTRACT(year FROM r.date)) DESC, (to_char((r.date)::timestamp with time zone, 'MM'::text)) DESC, (count(u.department_id)) DESC, d.department;


--
-- TOC entry 230 (class 1259 OID 27354)
-- Name: reports_by_date_done; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.reports_by_date_done AS
 SELECT to_char((r.date)::timestamp with time zone, 'MM'::text) AS mon,
    EXTRACT(year FROM r.date) AS yyyy,
    (count(1))::integer AS "Liczba zg??osze?? wykonanych"
   FROM ((public.reports r
     LEFT JOIN public.users u USING (user_id))
     LEFT JOIN public.departments d ON ((u.department_id = d.department_id)))
  WHERE ((r.executed_at IS NOT NULL) AND (r.date <= now()))
  GROUP BY (to_char((r.date)::timestamp with time zone, 'MM'::text)), (EXTRACT(year FROM r.date))
  ORDER BY (EXTRACT(year FROM r.date)) DESC, (to_char((r.date)::timestamp with time zone, 'MM'::text)) DESC;


--
-- TOC entry 231 (class 1259 OID 27359)
-- Name: reports_by_date_post; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.reports_by_date_post AS
 SELECT to_char((r.date)::timestamp with time zone, 'MM'::text) AS mon,
    EXTRACT(year FROM r.date) AS yyyy,
    (count(1))::integer AS "Liczba zg??osze??"
   FROM ((public.reports r
     LEFT JOIN public.users u USING (user_id))
     LEFT JOIN public.departments d ON ((u.department_id = d.department_id)))
  WHERE (r.date <= now())
  GROUP BY (to_char((r.date)::timestamp with time zone, 'MM'::text)), (EXTRACT(year FROM r.date))
  ORDER BY (EXTRACT(year FROM r.date)) DESC, (to_char((r.date)::timestamp with time zone, 'MM'::text)) DESC;


--
-- TOC entry 232 (class 1259 OID 27364)
-- Name: reports_by_department; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.reports_by_department AS
 SELECT d.department,
    count(u.department_id) AS "Liczba zg??osze?? przez dzia??"
   FROM ((public.reports r
     LEFT JOIN public.users u USING (user_id))
     LEFT JOIN public.departments d ON ((u.department_id = d.department_id)))
  WHERE (d.department IS NOT NULL)
  GROUP BY d.department
  ORDER BY (count(u.department_id)) DESC;


--
-- TOC entry 233 (class 1259 OID 27375)
-- Name: reports_report_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reports_report_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3515 (class 0 OID 0)
-- Dependencies: 233
-- Name: reports_report_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reports_report_id_seq OWNED BY public.reports.report_id;


--
-- TOC entry 234 (class 1259 OID 27376)
-- Name: reports_to_department; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.reports_to_department AS
 SELECT r."Dzia??",
    (count(r."Dzia??"))::integer AS "Liczba zg??osze??",
    (count(r."Data wykonania"))::integer AS "Liczba zg??osze?? wykonanych",
    (round((((count(r."Data wykonania"))::numeric / (count(r."Dzia??"))::numeric) * (100)::numeric)))::integer AS "Procent zg??osze?? wykonanych"
   FROM public.reports_all r
  WHERE (r."Dzia??" IS NOT NULL)
  GROUP BY r."Dzia??"
  ORDER BY ((count(r."Dzia??"))::integer) DESC;


--
-- TOC entry 235 (class 1259 OID 27380)
-- Name: roles_role_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3516 (class 0 OID 0)
-- Dependencies: 235
-- Name: roles_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_role_id_seq OWNED BY public.roles.role_id;


--
-- TOC entry 236 (class 1259 OID 27381)
-- Name: threats_threat_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.threats_threat_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3517 (class 0 OID 0)
-- Dependencies: 236
-- Name: threats_threat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.threats_threat_id_seq OWNED BY public.threats.threat_id;


--
-- TOC entry 237 (class 1259 OID 27382)
-- Name: users_top_10; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.users_top_10 AS
 SELECT u.email,
    (count(u.email))::integer AS "Liczba zg??osze??",
    (count(
        CASE
            WHEN (r.executed_at IS NOT NULL) THEN 1
            ELSE NULL::integer
        END))::integer AS "Liczba zg??osze?? wykonanych",
    (count(
        CASE
            WHEN (r.executed_at IS NULL) THEN 1
            ELSE NULL::integer
        END))::integer AS "Liczba zg??osze?? nie wykonanych"
   FROM (public.reports r
     LEFT JOIN public.users u USING (user_id))
  GROUP BY u.email
  ORDER BY (count(u.email)) DESC
 LIMIT 10;


--
-- TOC entry 3288 (class 2604 OID 27387)
-- Name: comments comment_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments ALTER COLUMN comment_id SET DEFAULT nextval('public.comments_comment_id_seq'::regclass);


--
-- TOC entry 3298 (class 2604 OID 27388)
-- Name: consequences consequence_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consequences ALTER COLUMN consequence_id SET DEFAULT nextval('public.consequences_consequence_id_seq'::regclass);


--
-- TOC entry 3295 (class 2604 OID 27389)
-- Name: departments department_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments ALTER COLUMN department_id SET DEFAULT nextval('public.departments_department_id_seq'::regclass);


--
-- TOC entry 3296 (class 2604 OID 27390)
-- Name: functions function_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.functions ALTER COLUMN function_id SET DEFAULT nextval('public.functions_function_id_seq'::regclass);


--
-- TOC entry 3297 (class 2604 OID 27391)
-- Name: managers manager_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.managers ALTER COLUMN manager_id SET DEFAULT nextval('public.managers_manager_id_seq'::regclass);


--
-- TOC entry 3290 (class 2604 OID 27392)
-- Name: reports report_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports ALTER COLUMN report_id SET DEFAULT nextval('public.reports_report_id_seq'::regclass);


--
-- TOC entry 3300 (class 2604 OID 27394)
-- Name: roles role_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN role_id SET DEFAULT nextval('public.roles_role_id_seq'::regclass);


--
-- TOC entry 3299 (class 2604 OID 27395)
-- Name: threats threat_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.threats ALTER COLUMN threat_id SET DEFAULT nextval('public.threats_threat_id_seq'::regclass);


--
-- TOC entry 3487 (class 0 OID 27245)
-- Dependencies: 210
-- Data for Name: comments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.comments (comment_id, report_id, user_id, comment, created_at) FROM stdin;
1	5	ddda0f68-9f25-4e69-b62f-95b4b5b1ba6a	Komentarz nowy 2	2022-07-09 14:28:01
2	5	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz nowy 2	2022-07-09 14:30:23
3	5	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz nowy 3333	2022-07-09 14:39:57
4	5	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz	2022-07-09 14:46:11
5	5	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz nowy 3333	2022-07-09 20:46:55
37	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:22:03
38	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:22:39
39	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:22:59
40	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:23:35
41	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:23:47
42	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:23:53
43	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:24:04
44	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:25:29
45	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:26:00
46	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:27:42
47	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:27:54
48	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:28:43
49	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:29:21
50	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:32:58
52	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:43:05
53	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:43:43
54	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 18:44:20
56	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:11:58
57	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:15:31
58	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:16:24
59	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:18:00
60	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:21:17
61	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:22:06
62	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:26:09
63	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:28:30
64	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:28:47
65	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:32:12
66	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:32:29
67	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:32:41
68	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:35:08
69	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:56:56
70	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:57:20
71	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 19:57:59
72	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 20:01:07
73	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 20:01:18
74	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 20:03:04
75	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 20:03:48
76	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 20:04:27
77	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 20:09:44
78	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 20:10:54
79	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 20:12:22
80	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz poprawiony	2022-07-16 20:13:35
6	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz nowy 2	2022-07-11 20:33:34
51	6	05e455a5-257b-4339-a4fd-9166edbae5b5	Komentarz nowy 2222	2022-07-16 18:40:31
\.


--
-- TOC entry 3493 (class 0 OID 27304)
-- Dependencies: 218
-- Data for Name: consequences; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.consequences (consequence_id, consequence) FROM stdin;
1	Bardzo ma??e
2	Ma??e
3	??rednie
4	Du??e
5	Bardzo du??e
\.


--
-- TOC entry 3490 (class 0 OID 27285)
-- Dependencies: 214
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.departments (department_id, department) FROM stdin;
1	Biuro
2	Dekoratornia
3	Formowanie
4	Inny
5	Jako????, BHP i O??
6	Konfekcja
7	Magazyn A30
8	Magazyn A31
9	Magazyn butli, cz??sci, palet, odpady niebezpieczne
10	Magazyn opakowa??
11	Magazyn wyrob??w
12	Sortownia
13	Technika
14	Utrzymanie ruchu
15	Warsztat
16	Wzory
17	Zestawiarnia
\.


--
-- TOC entry 3491 (class 0 OID 27288)
-- Dependencies: 215
-- Data for Name: functions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.functions (function_id, function_name) FROM stdin;
1	Kierownik administracji
2	Kierowink magazynu butli, cz????ci, palet...
3	Kierownik magazynu opakowa??
4	Kierownik magazynu A30
5	Kierownik magazynu A31
6	Kierownik dzia??u konfekcjonowania
7	Kierownik dzia??u formowania
8	Kierownik dzia??u zestawiarni i topienia
9	Kierownik sortowania
10	Kierownik dekoratorni
11	Kierownik warsztatu
12	Kierownik jako??ci, BHP i O??
13	Kierowink dzia??u wzory
14	Kierownik techniki
15	Kierownik utrzymania ruchu
\.


--
-- TOC entry 3492 (class 0 OID 27291)
-- Dependencies: 216
-- Data for Name: managers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.managers (manager_id, function_id, user_id) FROM stdin;
1	1	eab85052-fedd-4360-8a8c-d2ff48f0f378
2	2	f1fdc277-8503-41b8-aaea-e809a84b298b
3	3	6559d7cb-5868-4911-b0e4-baf0c393cdc3
4	3	ddda0f68-9f25-4e69-b62f-95b4b5b1ba6a
5	4	07774e50-66a1-4f17-95f6-9be17f7a023f
6	4	ddda0f68-9f25-4e69-b62f-95b4b5b1ba6a
7	5	02ee2179-6408-46c9-a003-eefbd9d60a37
8	5	ddda0f68-9f25-4e69-b62f-95b4b5b1ba6a
9	6	758cdd42-c7db-4aa8-b7cc-dbd66f2c9487
10	7	8d5a9bed-f25b-4209-bae6-564b5affcf3c
11	7	9be931ff-ff6d-4e74-a13e-4f44ade6d3ac
12	7	d8090826-dfed-4cce-a67e-aff1682e7e31
13	8	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6
14	8	8d5a9bed-f25b-4209-bae6-564b5affcf3c
15	9	da14c0c1-09a5-42c1-8604-44ff5c8cd747
16	9	95b29d34-ec2f-4ed7-8bc1-1e4fbc4cb0c7
17	10	3025f3ea-78c5-41fb-ba3e-cf7a79a57c0c
18	10	5bc3e952-bef5-4be3-bd25-adbe3dae5164
19	10	568a4817-69a1-4647-a74e-150242618dbe
20	10	800f4ae5-d6e5-45bf-9df7-ac9a8dcab858
21	11	5b869265-65e3-4cdf-a298-a1256d660409
22	12	813c24c3-fc3d-4afe-a8c3-cad54bb8b015
23	13	cd4e0c92-24a5-4921-a22e-41da8c81adf6
24	14	4bae726c-d69c-4667-b489-9897c64257e4
25	15	0eaf92dd-1e90-4134-bd30-47f84907abcb
\.


--
-- TOC entry 3488 (class 0 OID 27249)
-- Dependencies: 211
-- Data for Name: reports; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.reports (report_id, user_id, created_at, department_id, place, date, hour, threat_id, threat, consequence_id, consequence, actions, photo, execution_limit, executed_at) FROM stdin;
111	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-02-15	11	Alejka obok maszyny Kammann przy budowanych na pi??trze szatniach na starym magazynie wyrob??w gotowych.	2021-02-15	14:00:00	23	zabezpieczaj??ca osob?? wypadek tej por??wna?? bok por??wna?? bok spadek stanie wod?? sztuki schod??w spadaj??cej zniszczenia obra??enia Potkni??cieprzewr??cenieskaleczenie	3	Wygi??ty spe??nia pozostawiony omin???? widocznym A3 widocznym A3 konstrukcja nieoznakowane naprawiali nam Wyci??ganie kra??cowym Nieprzymocowane otwartym sortowi po??owie	odstaj??c?? roboczy d??u??szego potencjalnie R10 Niezw??oczne R10 Niezw??oczne oleju karty przykr??cenie poprzecznej przez stanu po??wi??cenie PLEKSY hydrantu ??rub??	\N	2021-03-15	2021-12-15
115	e89c35ee-ad74-4fa9-a781-14e8b06c9340	2021-02-18	4	Magazyn palet - palety wystawione do pobrania na sortowni??	2021-02-18	10:00:00	23	Nara??enie pod??og?? zwichni??cie po??arem zbiornika w??zki zbiornika w??zki spi??trowanych widzia??em rozdzielni "podwieszonej" paletach ci????ki r??kawiczka zagro??enie Przer??cone	5	moga tlenie aluminiowego potknie frontu wyeliminuje frontu wyeliminuje z????czniu d??ugie stabilnej wyst??puj?? le???? rynience nast??pnie oznakowanie doprowadzi??o kraw??dzi	proces poprzecznej paletach kasetony przepis??w ratunkowym przepis??w ratunkowym operatora stosowanie ??adowania przyczepy regularnego nieprzestrzeganie natrysku listew czysto???? ociec	12341.jpg	2021-02-25	\N
7	0fb6b96b-96a8-4a39-a0e2-459511d1c563	2019-08-07	17	Konstrukcja starej zestawiarni przy piecu W1	2019-08-07	16:00:00	0	drabiny uaszkodzenie jednego pracownikami obs??ugi najprawdopodobnie obs??ugi najprawdopodobnie nadstawki nast??pnie ??rodk??w ko??czyny wyj??cie gor??cym wieczornych uczestni??cymi Uswiadomienie	\N	oczywi??cie but??w Zakryty sprz??t pozosta??o???? powstawanie pozosta??o???? powstawanie sto??u Operacyjnego najechanie r??czny ??yletka doj??cia w??asn?? fasad?? najni??szej Trendu	podestu przdstawicielami kanaliki spr????arka otynkowanie ca??y otynkowanie ca??y temperatur?? szatniach Obudowa?? magazynie spotkanie bie????ce charakterystyki Obecna piecu przeciwpo??arowego	pozar.jpg	\N	\N
13	ffcf648d-83c7-473e-9355-361e6ec7bcee	2019-09-20	12	R10	2019-09-20	11:00:00	0	sa oprzyrz??dowania ko??czyn udzia??em zagro??enie Zanieczyszczenie zagro??enie Zanieczyszczenie pod du??e stronie co katastrofa kt??ra CI??G??O??CI ostrzegawczy Lu??no	\N	by??a wstawia w????czeniu Wa?? pietrze wyskakiwanie pietrze wyskakiwanie panuje rozchodzi minutach wypad??a skrzyd??o strop Zbli??enie szk??a tekturowymi z????	ukryty mog?? ociekowej monta?? dzwon oznakowanym dzwon oznakowanym Przestawienie Przyspawa?? odbojniki swoich metry kluczowych element odstawianie niezgodny jasnych	DSC_3256_resize_90.jpg	\N	\N
59	0fb6b96b-96a8-4a39-a0e2-459511d1c563	2020-10-12	17	Podest przy piecu W1 - przej??cie od lewej strony kieszeni zasypowej przy palisadzie w stron?? drugiego wziernika. Strefa za zlewni??	2020-10-12	09:00:00	0	uszczerbkiem po??lizgu r????nych ??wietle regeneracyjnego maszynki regeneracyjnego maszynki wody kostki obecnym gasz??cych Wyciek uchwyt??w ??miertelny R1 produkcji	\N	demonta??em rutynowych mate drzwi odprowadzaj??cej folii odprowadzaj??cej folii b??d?? pakowaniu obsuni??ta doprowadzaj??ce wychodz??cy kt??rym urz??dzeniu opu??ci??a rega??u niedozwolonych	regularnie oznakowane niedozwolonych problem czynno??ci?? stabilnym czynno??ci?? stabilnym kt??ra jezdniowego ostrzegawczej FINANS??W USZODZONEGO kamizelk?? piwnicy ograniczenie uraz bezpo??redniego	Inked1602571790549_LI.jpg	\N	\N
88	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-01-12	11	Rampa 0 przy biurze koordynator??w transportu	2021-01-12	14:00:00	21	uszkodzone operatora prawej - samych kubek samych kubek sprz??t co niebezpiecze??stwo wpychaniu stanie osob?? Zwr??cenie podwieszona ma	4	umo??liwiaj??cych odstaje nadmiern?? ba??k?? pulpitem komunikacyjnym pulpitem komunikacyjnym zapalenia podjazdu prawie poruszania ??ciankach pod??o??a NIEU??YTE woda konstrukcji znajduj??cej	by??o ustawienie rur?? stopni powietrza ruchomych powietrza ruchomych bortnic nachylenia oznaczenie kuchennych w Staranne Naprawi?? twarz?? Skrzynia Prosze	R6podest2.jpg	2021-01-28	2021-12-15
95	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-01-28	11	Paletyzator R7	2021-01-28	07:00:00	26	wp??ywem co powoduj??c?? oosby przekraczaj??cy spadaj??ce przekraczaj??cy spadaj??ce zdemontowane uchwyt??w zatrzymania przechodz??c?? sufitem wysoko??ci : j?? niebezpiecze??stwo	3	66 prasa powoduje luzem oznakowanego przepe??nione oznakowanego przepe??nione wchodz??c?? podno??nika drugiej osobowy nieoznakowanym Przechodzenie pradem pracownika karton??w rozbicia	opakowa??! bokiem to maszynach s??siedzcwta g??rnej s??siedzcwta g??rnej swobodny element??w odpowiedniej Codzienne ostro??no???? st??ze?? przerwy ponad rozlew??w elektrycznych	IMG_20210118_134735_resized_20210118_014948921.jpg	2021-02-25	2021-12-15
18	05e455a5-257b-4339-a4fd-9166edbae5b5	2019-10-08	15	Pomieszczenie magazynu form	2019-10-08	09:00:00	0	pot??uczenie itp uszkodzon?? mie?? podczas prawdopodobie??stwo podczas prawdopodobie??stwo opakowania naci??gni??cie mog??o Zdezelowana pochwycenia udzia??em uderzeniaprzygniecenia nadstawek karton??w	\N	rzuca??o DZIA??ANIE ostrych kt??ry niebezpieczne postaci niebezpieczne postaci wchodz??c?? Magazynier nocnej zalane opi??ek przechyla?? "mocowaniu" otw??r stoi Nier??wna	??cian?? oczy??ci?? noszenia Uniesienie przed??u??ki ka??dej przed??u??ki ka??dej chwytak Pomalowa?? drogach odbieraj??c?? ubranie ??adowa?? Poprowadzenie mi??dzy poinformowanie pracowniakmi	IMG_20191008_094743.jpg	\N	\N
20	e8f02c5a-1ece-4fa6-ae4e-27b9eda20340	2019-10-15	4	Piwnica pod hal?? produkcyjn??	2019-10-15	11:00:00	0	jako wysokosci mog?? a stopy lub stopy lub szk??em doprowadzi?? robi?? uszkodzeniu skr??ceniez??amanie skaleczenia b??d??cych d??oni- bram??	\N	stron?? wytarte zwijania zaw??r warsztacie znajduj??cego warsztacie znajduj??cego konieczna stabilno??ci sygnalizacji polegaj??c?? obci????e?? laboratorium wp??ywaj??c gor??cego przechylona oleje	kszta??t ta??my sk??adowanym teren r??wnej streczowane r??wnej streczowane pust?? stawia?? ostrzegawczej pojemnika dostosowuj??c rozmawia?? pracprzeszkoli?? Opisanie niebezpiecznych postoju	CAM00538.jpg	\N	\N
28	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2019-11-23	3	prasa R9	2019-11-23	10:00:00	0	Poparzenie Mo??lio???? wyrob??w instalacjipora??enie wstrz??su Uswiadomienie wstrz??su Uswiadomienie pracuj??ce widoczno??ci instalacja przep??ukiwania spodowa?? efekcie stanowisko widoczno??ci skr??cona	\N	dyscypliny ona stwierdzona ruchomych przebywaj??cych spr????one przebywaj??cych spr????one odpr????arki blachy kamerami gor??cego sytuacji widocznym skaleczenia boli uderzy?? wy????cznik	natrysk naprawy obci????one ci??gi oczomyjk?? rozpi??trowa?? oczomyjk?? rozpi??trowa?? przepis??w przechylenie lewo stopni praktyki opuszczanie ciep??o obarierkowany szatni p??l	\N	\N	\N
9	07774e50-66a1-4f17-95f6-9be17f7a023f	2019-08-08	7	Magazyn wyrob??w gotowych 2 	2019-08-08	11:00:00	0	urz??dze?? magazynowana wid??owego brak Najechanie plus Najechanie plus pracownicy kontrolowanego kostki Utrudniony pod??ogi gwo??dzie elektrod zdemontowane pobli??u	\N	powtarzaj?? ale nog?? przesun???? zza kaw?? zza kaw?? zuzyciu prze??o??onego 5m Niepoprawne r??wnowagi elektryczne Drobinki przyczyna w????czeniu budynku	przewody cieczy sk??adanie oznakowanym przed??u??ki stawia?? przed??u??ki stawia?? narz??dzi spawanie Instalacja ruchom?? ??rub?? swobodne rozsypa?? przechodzenie pocz??tku doj??cia	\N	\N	\N
29	6ccdb3ad-4df4-4996-b669-792355142621	2019-11-29	1	Biuro dzia??u logistyki wysy??ek	2019-11-29	08:00:00	0	widoczny polerce temu oosby routera uszkodzeniu routera uszkodzeniu reagowania zerwania kt??ry najprawdopodobnie wpadni??cia wystaj??cego nogi d??wi??kowej lampy	\N	??rutu wietrze poziom ztandardowej wykona?? przewr??ci??y wykona?? przewr??ci??y istnieje utrudniaj??cy Zastawiona Je??eli sytuacji ponownie przemywania jest Niepawid??owo wymieniona	rusztu operatora oczyszczony Kontakt bezpiecznie ruchom?? bezpiecznie ruchom?? niesprawnego mo??liwych olej Natychmiast itp dostep??m spi??trowanych sukcesywne niestwarzaj??cy Przywierdzenie	\N	\N	\N
42	57b84c80-a067-43b7-98a0-ee22a5411c0e	2020-02-25	3	Produkcja, polerka R1.	2020-02-25	09:00:00	0	sk??adowanie godzinach spi??trowanej elementem znajduj??cej poprzepalane znajduj??cej poprzepalane oparzenie pozycji innego rz??dka ludzi w????czeniu awaryjnego stanowiska wyroby	\N	Topiarz obszary Zastosowanie bok paletyzatora Wdychanie paletyzatora Wdychanie samozamykacz 5 rynience osobowy podest??w minutach pojemniki nawet wybuchowej jako	rozpinan?? oznaczone min urz??dzeniu ko??czyn" liniami/tabliczkami ko??czyn" liniami/tabliczkami ka??dej elekytrycznych przechowywa?? siatka skrajne obecno???? naprowadzaj??ca pozosta??ych identyfikacji obs??udze	Zrzutekranu2020-02-26o09.23.15.jpg	\N	\N
138	80f879ea-0957-49e9-b618-eaad78f7fa01	2021-03-04	2	magazyn wyrob??w gotowych-??rodkowy	2021-03-04	12:00:00	6	ugasi?? wybuchupo??aru cia??a gazu istnieje tego istnieje tego obecnym pod??og?? d??oni- ostrym znajduj??cych r??kawiczka je??d????ce wypadekkaseta wybuch	4	zamocowane korzystania tu??owia Dekoracja straty "mocowaniu" straty "mocowaniu" mechaniczne Pobrane zabezpieczony chroni??cych upad??y sadz?? powoduje spe??nia Jednakowy kuchni	przeszkolenie Np metry stanu PLEKSY stwarzaj??cym PLEKSY stwarzaj??cym powietrza utrzymaniem t??uszcz ruroci??gu magazynowania upadkiem Skrzynia stolik klatk?? obok	IMG_20210302_134523.jpg	2021-03-18	\N
44	f87198bc-db75-43dc-ac92-732752df2bba	2020-03-07	3	R-9	2020-03-07	15:00:00	0	obok zerwanie budynkami przejazd budynkami kostce budynkami kostce informacji dopuszczalne posadzki dachu po??lizgu widoczno??ci paletszk??a obudowa mog??aby	\N	szczeg??lnie wyra??a?? ??wiat??o przekazywane Przycsik rzuca??o Przycsik rzuca??o podj??te opar??w w???? zaworze Router produkcyjne wyrobu papierosa zabezpieczone but??w	Sk??adowa?? bezbieczne mniejsz?? bezpiecze??stwa pracownikami d??wignica pracownikami d??wignica szafki przykr??ci?? Obecna opakowa??! dzwon ostrzegawczy ??cianki s?? ustawienia oleju	\N	\N	2020-12-29
162	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	3	??uraw (pomi??dzy R8, R7)	2021-03-15	13:00:00	18	zabezpieczenia podwieszona zap??onu tej urz??dze?? paletyzatora urz??dze?? paletyzatora pot??uczenie trwa??y przeci??cie rz??dka przewody urata g??ow?? monitora Wyciek	2	Piec szybka szyb?? podstawy s??upku termokurczliw?? s??upku termokurczliw?? nieutwardzonej pieszego aby nier??wno??ci OSB naprawiali przechyli??y nowych Rozwini??ty odpowiednich	u??wiadamiaj??ce dochodz??ce metody przynajmniej ma??a uszkodzony ma??a uszkodzony przygotowa?? Odsun???? DOSTARCZANIE naprowadzaj??ca wema ??adunki tego ruroci??gu stron ostre	20210315_131457.jpg	2021-05-10	2021-03-15
176	de217041-d6c7-49a5-8367-6c422fa42283	2021-03-22	3	Automat R10	2021-03-22	23:00:00	9	Potencjalne zdrmontowanego nadstawek dost??p ziemi osob?? ziemi osob?? Przeno??nik skutki: wylanie popa??enia obr??bie doprowadzi?? Ci????kie tej stop??	5	zagi??te biurkiem doprowadzi??o ma??a czego unosz??cy czego unosz??cy misy osobowe klimatyzacji Wystaj??ca odsuni??ty p??ytki TIRa inne przewr??ci?? silnika	poprowadzenia schody warunk??w uchwytu postoju indywidualnej postoju indywidualnej mo??liwego pr??g pozycji rozwa??ne umorzliwi??yby przegl??danie NAPRAWA/ umy?? SPODNIACH transportem	12345678.jpg	2021-03-31	2021-03-29
179	5b869265-65e3-4cdf-a298-a1256d660409	2021-03-29	15	Warsztat CNC	2021-03-29	14:00:00	9	urata zniszczenia drodze dojazd doznania Prowizorycznie doznania Prowizorycznie Miejsce ko??a ??cie??k?? je??d????ce palety Uraz jednego skr??ceniez??amanie le????cy	4	Tydzie?? kroplochwyt??wa nast??pi??o spodu ta??mie rynience ta??mie rynience samochodu godzinie Przeprowadzanie wylecia?? kt??r?? ruchem temperatury przesunie drogami Zbyt	identyfikacji odgrodzenia maszynki nawet Urzyma?? praktyki Urzyma?? praktyki przemieszczenie przeznaczone pisemnej doj??cia jezdniowego st??uczk?? otworu warsztacie sposobu pracy	klucz2.jpg	2021-04-12	\N
46	07774e50-66a1-4f17-95f6-9be17f7a023f	2020-06-18	7	Trend Glass Radom ul M.Fo??tyn 11 magazyn wyrob??w gotowych strefa roz??adunk??w przy  dokach za??adunkowych na magazynie budowlanym.	2020-06-18	13:00:00	0	uruchomienia mog??aby spr????onego transportu swobodnie oczu swobodnie oczu niezbednych regeneracyjne wysokosci pojazdu Przer??cone transportowanych uzupe??niania g??ow?? tych	\N	wyciek zacz????y powoduje os??on?? b??d?? poniewa?? b??d?? poniewa?? usytuowana Oberwane mycia Ma??y rury wylecia?? remontowych posiadaj?? magazyniera Nieprawid??owe	kolor sko??czonej steruj??cego to elektryczny Cz??ste elektryczny Cz??ste niew??a??ciwy jeden gazowej skrajne substancje pocz??tku magazynie przestrzegania opuszczania naprawienie	\N	\N	\N
56	8d5a9bed-f25b-4209-bae6-564b5affcf3c	2020-10-05	3	Produkcja R8	2020-10-05	11:00:00	0	por??wna?? ma elementu operatora zbiorowy ka??d?? zbiorowy ka??d?? ludzkiego itp pojazdem pojemnika uwagi uk??ad rozdzielni przedmioty elektryczna	\N	wyrobu we uprz??tni??ta ODPRYSK st??uczk?? ??ruba st??uczk?? ??ruba asortymentu dzwoni??c przeskokiem spowodowa??y odpr????ark?? obs??uguj??cych ???brak doj???? Potencjalny w??skie	roboczy opuszczanej okolicy da otwiera mocowanie otwiera mocowanie lekcji elementy ga??nicy odk??adczego telefon??w dnia gdy mo??liwo??ci inne upadku	IMG_20201005_112122.jpg	\N	2021-08-20
58	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2020-10-08	12	R8- prawa strona ci??gowni od strony ZK 	2020-10-08	15:00:00	0	Pora??enie p??ytek zwarcia magazynie mi??dzy odpowiedniego mi??dzy odpowiedniego si??owego tj wpychania barierka Powa??ny spowodowane osoby pobieraj??cej konstrykcji	\N	gazu pradem mia??am sypie n??z p????wyrobem n??z p????wyrobem czujk?? nieprzystosowany wype??niona mo??liwo??ci boli automatyczne p??omieni powodu r??kawicami utrudnia??o	pust?? sko??czonej dodatkowe ni?? okoliczno??ci pi??trowaniu okoliczno??ci pi??trowaniu miedzy nara??aj??ca kryteria klamry pracprzeszkoli?? dot??p m stawia?? towaru sprawno??ci	\N	\N	\N
381	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-10-26	3	Natrysk ratunkowy przy linii produkcyjnej R8	2021-10-26	10:00:00	6	odpryskiem przejazd wid??owe nt wp??ywem starych wp??ywem starych zgrzeb??owy dotycz??cego skutki hydrantu automatu nast??pnie poprzez wypadni??cia mie??	4	automatycznego bariery w Dekoracja niekontrolowany stop?? niekontrolowany stop?? ostrzegaj??ce wypi??cie komunikat Podest odsuni??ty naci??ni??cia CNC os??aniaj??cy drodze perosilem	sie trybie rozwa??ne starych zamontowana wannie zamontowana wannie transporterze dodatkowe Systematyczne klatk?? Przetransportowanie kluczowych skutkach plomb podczas Uzupe??nienie	20211026_092215.jpg	2021-11-09	2021-12-08
67	3ee5fc99-b50b-4b71-8f18-7a7af63c07ef	2020-10-21	2	NA WYSOKO??CI MI??DZY TR 12 I SPEEDEM W CI??GU KOMUNIKACYJNYM.	2020-10-21	00:00:00	0	jednego Ustawiona r??wnie?? oraz tj si?? tj si?? doprowadzi?? hala go potr??cenie nadstawki magazynowana ograniczony s??amanie widzia??em	\N	korzystania "niefortunnie" foli?? ??arzy?? VNA swobodnego VNA swobodnego zako??czenia mieszad??a Dopracowa?? nast??pnie odcinaj??cy ekspresu wej??ciem bez codziennie naro??nika	szklanej dzia??u siatk?? n????k?? ostro??no???? ??cian?? ostro??no???? ??cian?? poinformowanie dobranych Naprawi?? kotwi??cymi czynno??ci listew spod przeszkolenie obecnie pojemniki	IMG_20201022_142301.jpg	\N	\N
68	05e455a5-257b-4339-a4fd-9166edbae5b5	2020-10-23	17	Przy pojemnikach na tektur??	2020-10-23	11:00:00	0	spi??trowanych pot??uczenie u??ytkowana stopy uderzenia zapalenie uderzenia zapalenie Uswiadomienie schodach uszkodzone nara??aj??cy Wej??cie Stary ha??as mokro element	\N	??a??cuch??w zg??osi?? kana??em drzwiami Rura Zastawiona Rura Zastawiona drewniana kroplochwytu ci??nienia kiera ponad Duda WID??OWYM odci??gowej Rana niegro??ne	blokuj??cej Om??wienie SZKLA napraw spotkanie niepotrzebn?? spotkanie niepotrzebn?? oznaczony przechodzenia Peszle praca podest??w odpowiada?? bortnicy przeno??nikeim grudnia Umie??ci??	\N	\N	2020-12-10
71	80f879ea-0957-49e9-b618-eaad78f7fa01	2020-11-03	4	Obszar przed warsztatem i magazynem opakowa??	2020-11-03	12:00:00	0	z??ego awaria tych oraz pr??by z??amanie pr??by z??amanie Zanieczyszczenie uaszkodzenie znajdujacej ostra zdrowiu Cie??kie sortowanie zalania Wyciek	\N	naczynia mo??e Ma??y r????nice powsta?? ??cie??ce powsta?? ??cie??ce pod??odze zu??yt?? ??cian?? zosta?? ??liska rami?? klucz zdmuchiwanego ognia g??rze	hydrant??w Korekta bezpo??redniego rozbryzgiem stanowisko Kompleksowy stanowisko Kompleksowy matami podestowej os??b kamizelki gro???? dost??pem produkcji Dodatkowo prawid??owych jezdniowego	IMG_20201023_111315.jpg	\N	\N
80	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2020-12-14	17	Zestaiwrnia	2020-12-14	09:00:00	0	s?? spowodowanie mog??y nadpalony brak pieca brak pieca zadzia??a kostce pracownicy nawet kartony braku potkni??cia mog?? zdarzenia	\N	powietrza dwa zaobserwowania przestrzega?? zaworze wykorzystane zaworze wykorzystane barierki szklanych zas??ania innego przesun???? chroni??cych pasach Sortowni codziennie komu??	chemiczych ograniczniki usytuowanie uraz ca??ej organizacji ca??ej organizacji problem szyba odk??adczego opasowanego rur?? ka??dych przetransportowa?? pochylnia otwieraniem obowi??zku	\N	\N	\N
93	9be931ff-ff6d-4e74-a13e-4f44ade6d3ac	2021-01-15	4	Sto????wka pracownicza.	2021-01-15	13:00:00	2	kotwy powr??ci?? szk??a pr??g by??a odrzutu by??a odrzutu sprz??tu ha??as si?? mienie zapalenie ta??moci??gu Paleta z uszczerbek	5	wrz??tkiem powoduj??ce zapewnienia przeno??nika warsztacie ewakuacujne warsztacie ewakuacujne Jednakowy ugaszenia b????d wypalania poinformowa??a j??zyku obejmuj??cych odoby t??ust?? zdarzaj??	gro???? nowej stosach rodzaj butelk?? podesty butelk?? podesty przerobi?? praktyk ograniczonym dostep??m Staranne H=175cm czasei Usuni??cie pojedy??czego bokiem	WhatsAppImage2021-01-15at08.10.30.jpg	2021-01-22	2021-01-18
105	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-02-09	12	Podest R2	2021-02-09	09:00:00	16	cz??owieka zapewniaj??cego ??eby uderzy?? przewr??cenia mog??a przewr??cenia mog??a szatni dachu ??le drzwiowym klosza "podwieszonej" stanowisko lampy po??arem	3	lewa wolne rozmowy swobodne przewr??ci?? ugaszenia przewr??ci?? ugaszenia silnego Samoch??d zamocowane nadzoru Sytuacja bortnicy przedmiot??w os??b wystaj??cego kt??rej	jakim odbojniki przynajmniej spr????ynowej pomi??dzy do??wietlenie pomi??dzy do??wietlenie bezpiecze??stwa Przestrzeganie po??arowo bezpieczny odpowiedni?? przej???? bezpo??rednio u??ywana paletyzator temperatury	20210209_082421.jpg	2021-03-09	2022-02-08
112	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-02-17	3	Krtaka wema na pode??cie przy zasilaczu R4 wygi??ta w liter?? "U"	2021-02-17	14:00:00	16	r????nych wci??gni??cia regeneracyjne dojazd zaczadzeniespalenie odprowadzj??cej zaczadzeniespalenie odprowadzj??cej gwo??dzie wiedzieli sk??ry wystaj?? polerce prowadz??ce wy????cznika po??lizgni??cie z??amania	5	nolce st??uczka du??o odkryte ??ciany Rozproszenie ??ciany Rozproszenie obydwu w??zku zasilnia wieszaka problem kaloryferze p??ytek sytuacje palnych wieszaka	odpowiedniej wentylatora transportowego Obudowa?? stawania prawid??owo stawania prawid??owo kanaliki posadzki przeprowadzi?? Przesuni??cie identyfikacji stanu uniemo??liwiaj??cych b??dzie skrzynce koszyki	\N	2021-02-24	2021-12-10
123	4dce33fe-8070-4d04-99e3-a39dbaca1f82	2021-02-24	3	Za schodami przy linii R6	2021-02-24	12:00:00	26	odprysk wymaga?? gwa??townie pracownikami wci??gni??cia awaryjnego wci??gni??cia awaryjnego uruchomienia informacji ta??moci??gu przest??j szafy uaszkodzenie ??miertelnym urz??dzenia drzwiami	2	cia??a leje wyci??gania przej??cia wychodzenia k????ko wychodzenia k????ko oberwania przeciwolejow?? podniesion?? wzorami schody barierka opuszczonej zabezpieczone Demonta?? zaolejona	usuwanie swobodn?? klamry ??cianki Przestrzeganie punktowy Przestrzeganie punktowy utrzymaniem DzU2019010 Ministra szczelno??ci regularnego GOTOWYCH odpowiednie pr??g" listew towarem	paleta.jpg	2021-04-21	2021-12-10
127	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-02-24	12	Przedsionek z opakowania przy bramie obok R1	2021-02-24	18:00:00	26	chemicznej uderzeniaprzygniecenia koszyk drzwi uderzenia oraz uderzenia oraz opakowa?? piec itp zabezpieczaj??ca pot??uczenie amputacja Poparzenie rozszczelnie mo??liwo??ci	2	a?? przymocowana kraw??dzie nawet papierosa ca??y papierosa ca??y 8 osobowe kt??ra drzwiami Zastosowanie zawleczka wyt??oczniki intensywnych mog?? si??owy	niskich prowadzenia wanienki przetransportowa?? stanowisku ustawienia stanowisku ustawienia hydrant??w os??on?? jesli wcze??niej otynkowanie przyk??adanie Uprzatniuecie p??ynem likwidacja kodowanie	Przewroeconapaleta.jpg	2021-04-23	2021-12-07
128	80f879ea-0957-49e9-b618-eaad78f7fa01	2021-02-26	10	Wej??cie przy wiacie na palety	2021-02-26	11:00:00	26	urata skr??cona czego rodzaju konsekwencji rany konsekwencji rany zawarto??ci skutek automatu powr??ci?? Gdyby osuni??cia uszkodzone oparzenie pr??dem	4	rynience stron?? towarem p????ce weryfikacji w??asn?? weryfikacji w??asn?? Worki w ga??nicy prawa Nieprzymocowane oberwania Przechodzenie pory schodach zbiornika	jednoznacznej szkolenie pod chc??c przechodzenie os??aniaj??ce przechodzenie os??aniaj??ce umy?? przegl??du poza nieco uczulenie poprawienie foto myj??cego Uzupe??ni?? osoby/oznaczy??	IMG_20210226_105600.jpg	2021-03-12	2021-12-07
140	a6e35ba8-06de-4a85-8b4f-961bd7ff09d0	2021-03-06	4	Magazyn szk??a naprzeciw Sleeva ko??o karuzeli giga	2021-03-06	11:00:00	26	Wyniku Wej??cie Zanieczyszczenie barierka pracuj??ce bramie pracuj??ce bramie prawdopodobie??stwo osun????a po??arowe szybkiej gor??cym wid??owe Cie??kie schod??w jako	2	zewn??trzne miejsca uszkodzony poluzowa??a wysuni??ty wyrzucane wysuni??ty wyrzucane szafie antypo??lizgowa Przecisk rami?? rolkowego "NITRO" stanie nim awaryjny maszyny	pi??trowane Przet??umaczy?? Niezw??oczne okolicy nieodpowiedzialne lekko nieodpowiedzialne lekko g????wnym naprowadzaj??ca podwykonawc??w powinien wanienk?? osuszy?? razy dopuszczalnym Przekazanie mycia	IMG_20210306_113117.jpg	2021-05-01	\N
436	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2022-02-07	12	Pakowanie przy sortowni R8	2022-02-07	11:00:00	18	85dB dotycz??cej wi??cej hala pracownice powietrze pracownice powietrze 85dB os??b przeciskaj??cego co przyczepiony zabezpieczaj??ca za urata przemieszczaniu	4	jest otuliny przetopieniu ogie?? pompki szybka pompki szybka jazdy cia??a przyczyna prac?? biura ci??g zuzyciu pozadzka wymian?? przechylenie	Ministra szaf?? zamocowany natrysk naprawic/uszczelni?? ociekow?? naprawic/uszczelni?? ociekow?? piwnicy narz??dzi dna nawet Zdj??cie SPODNIACH uzywa?? n????k?? Kompleksowy sko??czonej	Naprawapalety.jpg	2022-02-21	\N
149	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-03-12	4	Szatnia m??ska -malarnia	2021-03-12	07:00:00	6	pracy- Pomocnik b??d?? r??ki por??wna?? stopy por??wna?? stopy ??mier?? bok oka mog??aby zosta??a Z??amaniest??uczenieupadek urazy cz?????? spos??b	3	standard niegro??ne instalacje dziale automat przechyli??y automat przechyli??y ci????ka przesuwaj??cy wypi??cie pod??odze sekundowe wod?? potencjalnych stosowanie Magazynier samozamykacz	dzia????w kotwi??cymi ??cianki mechanicznych+mycie przetransportowa?? wann?? przetransportowa?? wann?? ??rodk??w rozwa??ne istniej??cych muzyki kartonami rozsypa?? maszynach piecu wieszak niedopuszczenie	IMG_20210305_081447_1.jpg	2021-04-09	\N
150	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-03-12	4	Szatnia damska-malarnia	2021-03-12	07:00:00	6	stanowiska razie oosby si??owego Balustrada przy Balustrada przy instalacja obszaru r10 Tydzie?? oparta substancj?? wpychania wody gotowych	3	skutek w??skie najechanie osobne pomimo Poruszanie pomimo Poruszanie szklarskiego trafia pulpitem odblaskowych pr??dem panuje podestowymi stanie podest??w zamkni??cia	osoby/oznaczy?? dzia??ania uniemo??liwiaj??cych st???? bokiem metalowych bokiem metalowych korb?? Poprawny Przyspawanie/wymiana kluczyk Naprawi?? innych nale??a??oby temperatur?? folii naprawienie	IMG_20210305_084024.jpg	2021-04-09	\N
151	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2021-03-12	17	Piec W2	2021-03-12	07:00:00	7	wylanie przy ewentualny by sk??adowana elementem sk??adowana elementem zgrzewania jednego dotyczy polerki zablokowane osob?? przewr??cenie barierka w????czeniu	5	balustrad inna dosuni??te pi??trowanie odzie??y szybie odzie??y szybie Drobne RYZYKO narz??dzi godz ch??odzenie ta koszyka Stare b??l rejonu	oleju sprawnego komunikacj?? u??wiadamiaj??ce odstawianie ostrych odstawianie ostrych cementow?? palet?? postoju powierzchni wodnego pracownik??w przechowywania r??wno r??wnej uniemo??liwiaj??cych	Screenshot_20210312-071805_WhatsApp.jpg	2021-03-19	\N
168	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	3	R2	2021-03-15	13:00:00	24	osuni??cia urz??dzenia instalacjipora??enie czyszczeniu k????ko razie k????ko razie Towar rega????w Przygniecenie zabezpieczonego Okaleczenie pracuj??ce zagro??enie kt??ry sterowania	3	wej??ciu drog?? wyrzucane stra??y przetopieniu zawleczka przetopieniu zawleczka gazowe wytyczon?? cze??ci stwierdzi?? st???? wej??ciu zmieni?? paj??ka jednej spad??a	PRZYJMOWANIE Staranne komunikacj?? por??cze s??siedzcwta kart s??siedzcwta kart planu Kontrola istniejacym dystrybutor pracy sprawno??ci serwis??w Mycie spi??trowanej pracuje	20210315_131506.jpg	2021-04-12	2021-03-15
171	2168af82-27fd-498d-a090-4a63429d8dd1	2021-03-15	3	R-1	2021-03-15	16:00:00	5	krzes??a elementu Problemy maszynie zdemontowane ponowne zdemontowane ponowne ludzkie naci??gni??cie oraz Uderzenie sufitem b??d??cych ci????kim Zwisaj??cy karku	4	drugi skruty Urwany PREWENCYJNE ruchem wentylacyjn?? ruchem wentylacyjn?? Urwany szcz????cie uzupe??nia by?? antypo??lizgowa transportu odpowiednich rutynowych py??ek cieczy	sekcji kontenera przedosta??y jakiej tego dobr?? tego dobr?? itp blokuj??c?? otwierania pracownikom bezpo??rednio G????doko???? przed??u??ek Odsun???? gumowe otworami/	IMG_20210315_160036.jpg	2021-03-29	2021-04-08
184	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-04-06	3	Hala nr 1	2021-04-06	14:00:00	2	zbiorowy zmia??d??enie schodach bia??a i malarni i malarni mokro Uszkodzona w??zkiem paletszk??a zanieczyszczona do??u znajduj??cego dla sk??adowanych	5	poinformuje podno??nika Wannie wentylacyjnych osobowy przemycia osobowy przemycia zmiany Firma uda??o papierosa widocznych pode??cie wentylacyjnym w du??ym sprzyjaj??cej	stanowiskami szyba mocuje NOGAWNI gniazda ropownicami gniazda ropownicami pod??o??u Wezwanie odpowiednich instalacji celem poziomu Ka??dorazowo ta??my formie wentylacyjnego	IMG_20210402_064840.jpg	2021-04-13	2021-12-29
186	c307fdbd-ea37-43c7-b782-7b39fa731f90	2021-04-08	2	Przej??cie z magazynu do malarni	2021-04-08	08:00:00	5	kolizja pieszego technicznym przejazd posadowiony prawej posadowiony prawej regeneracyjnego dla w ??cie??k?? sprawdzaj??ce ustawione Ludzie i pod	3	sprawdzenie zasilnia potencjalnie klej??cej USZKODZENIE drewniany USZKODZENIE drewniany spiro koszu roz??adowa?? przewr??ci?? pomocy etapie stosownych "boczniakiem" oznakowania ??ruby	informacji dzia??u patrz odk??adcze Pisemne pr??downic Pisemne pr??downic Nale??y w??zk??w uwag?? wprowadza formy wpi??cie pokonanie mocowanie wieszak mocuje	DSC_2176.JPG	2021-05-06	\N
194	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-04-19	12	R9	2021-04-19	14:00:00	9	automatycznego przest??j progu skutkiem 85dB infrastruktury 85dB infrastruktury rozprzestrzenienie wp??yw zahaczenie uchwyt skutki: WZROKU bia??a urz??dze?? por??wna??	3	urz??dzenie u??yciu wymianie zosta??wymieniony paltea Sytuacja paltea Sytuacja przyczyn?? przemyciu furtce nara??ony doj??cia 0,00347222222222222 kostk?? nieoznakowany nadzorem nara??ony	nakaz jak uszkodzonego krzes??a ci??ciu pojemnika ci??ciu pojemnika Wyci??cie warunk??w stosowanych os??b przypadku rowerzyst??w schodka uszkodzonej niepotrzebn?? Ragularnie	20210419_134551.jpg	2021-05-17	2021-12-29
10	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2019-08-13	10	Przy rampie z biurkiem	2019-08-13	09:00:00	0	gasz??cych r??wnie?? piwnicy rozdzielni delikatnie spa???? delikatnie spa???? nask??rka ognia efekcie potencjalnie sk??adowania u??ytkowana przewr??cenie budynkami nara??aj??cy	\N	istnieje zdjeciu sekundowe spowodowa??o pracowik??w przedzielaj??cej pracowik??w przedzielaj??cej zawadzi?? zosta??wymieniony sytuacji Trendu schody tak drugiego b????d schodzenia wy????czonych	przelanie korytem Poprawa klosz ponad ok ponad ok przepakowania Konieczno???? jaki rozmie??ci?? swoich butle premy??le?? ostro??ne odpowiedni?? drewnianych	magazynop.jpg	\N	\N
55	8d5a9bed-f25b-4209-bae6-564b5affcf3c	2020-10-01	12	Linia R9	2020-10-01	08:00:00	0	konsekwencji zrani?? odgradzaj??cej kogo?? sanitariatu sufitem sanitariatu sufitem niebezpiecze??stwo obs??ugi zmia??d??enie t??ust?? substancjami ka??dorazowo d??oni- blachy trzymaj??	\N	Trendu ko??cz??c kostrukcyjnie wyt??ocznikami Widz??c tekturowymi Widz??c tekturowymi rami?? posadzki pochwycenia transportowego ??adowania Gasnica Przymarz??o dogrzewu schodzenia Wok????	przew??d Ustawianie odpowiedni?? ociekow?? natrysku mniejsz?? natrysku mniejsz?? obszarze gaz??w metry niedozwolonych szk??em szklanej Naprawi?? silnikowym placu karton??w	Screenshot_20201001_102507_com.whatsapp.jpg	\N	2021-09-20
75	2168af82-27fd-498d-a090-4a63429d8dd1	2020-12-02	12	p??ytki zej??ciowe odpr????arki R1	2020-12-02	09:00:00	0	spowodowanie kontrolowanego swobodnego elektrycznych w???? skokowego w???? skokowego Mo??lio???? osob?? zabezpieczaj??ca i szybkiej rozprzestrzenienie drzwiami ko??czyny potencjalnie	\N	ucz??szczaj?? krzywo pokryw rutynowych stref?? podtrzymywa?? stref?? podtrzymywa?? lec?? palnik??w pomoc?? Dodatkowo rowerze odprowadzaj??cej ??liska kierunku pierwszej zawadzenia	niezgodny Poprwaienie drogach przedmiotu d??wignica indywidualnej d??wignica indywidualnej uruchamianym szafy foto DOTOWE poziom stopniem Dospawa?? Poinstruowa?? przemywania substancje	woezekzkluczykim,.jpg	\N	2022-02-08
155	3fc5fdcb-e0ad-4e26-aa74-63ec3f99f72f	2021-03-12	15	Dzia?? czyszczenia form/ maszynki	2021-03-12	10:00:00	24	zdrowia uszkodzenie zbiornika po??ar przypadku wybuchupo??aru przypadku wybuchupo??aru pozostawiona lampy zap??onu ostrzegawczy Towar R1 by kontrolowany bardzo	3	os??b akumulator??w w??zek ograniczy??em WID??OWYM paletowych WID??OWYM paletowych zgina?? w/w uk??adzie ma??ym ograniczaj?? niedopa??ka po??arowo zawarto???? Stwierdzono po??lizg	stoj??cej Obudowa?? g??rnej pilne papieros??w serwis papieros??w serwis mo??e kraw??dzi oceniaj??ce Regularne ograniczenie naprawic/uszczelni?? ??cian?? otworzeniu szklanych fotela	krzesla.jpg	2021-04-12	\N
180	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-03-25	15	Wej??cie na warsztat / magazyn form  - zas??ona odgradzaj??ca ci??g komunikacyjny od stanowisk regeneracji	2021-03-25	14:00:00	23	b??dzie w drzwi komputer??w zawias??w ludzie- zawias??w ludzie- wskazania sk??adaj??c?? kabel kontrolowanego innych du??e gazu ograniczenia sortowni	3	ostre Wannie elementem wewn??trzyny s??siedniej tak s??siedniej tak zaprojektowany je przedmiot??w ??aduje przed wewn??trznych rejonu 406 stoi work??w	elektryczny dopuszczalna Uporz??dkowa?? upomina?? przeno??nikeim wje??d??anie przeno??nikeim wje??d??anie przednich rozmie??ci?? k??ta nowa informowaniu skrzyd??a elektryczne myciu niedozwolonych ma??a	oslona.jpg	2021-04-28	2021-03-31
201	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-04-19	10	Magazyn opakowa??	2021-04-19	14:00:00	26	sterowania krzes??a poprzepalane wizerunkowe pojazdu produkcyjnej pojazdu produkcyjnej oraz 2m spr????onego skr??cenie Zwarcie przejazd sk??ry wysokosci substancj??	4	Wannie zabezpieczy?? ga??nic?? podesty doprowadzi??o Po??ar doprowadzi??o Po??ar w/w czyszczenia przymocowanie inna pracach palcy kra??cowym stara Osoby zacz????o	obydwu razy skladowanie kompleksow?? paletowego r??cznego paletowego r??cznego licuj??cej kamizelki mog?? skutkach osoby s??siedzcwta cz??sci wiatraka podwykonawc??w Odkr??ci??	20210419_125938.jpg	2021-05-03	2021-12-07
225	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2021-04-27	3	Prasa R1 Przeno??nik zgrzeb??owy	2021-04-27	22:00:00	5	kanale urz??dzenia niecki prac wid??owego obs??ugi wid??owego obs??ugi mocowania pras brak pomieszcze?? ??rodka kostki palecie nim hala	3	substancjami Pleksa doja??cia niebezpiecze??stwo kontener OCHRONNEJ kontener OCHRONNEJ kierowca Duda zamocowanie ??atwopalnymi do brama konieczna elektryczny elemencie pochwycenia	Dosuni??cie serwisanta ryzyko na wi??cej Dosuni??cie wi??cej Dosuni??cie kontenera kra??c??wki pod??o??a ruch przeciwpo??arowego piktogramami Ka??dy poruszaj??cych ??rodka blachy	20210429_093426.jpg	2021-05-28	2021-10-12
242	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-05-13	2	Na przeciwko karuzeli nr 2	2021-05-13	12:00:00	25	nt istnieje : paleciaka upa???? zasilaczu upa???? zasilaczu pieca powoduj??cych stop?? odpowiedniego osob?? zabezpieczonego niestabilny zrani?? po	3	zacz????o wydostaj?? w??ywem jecha?? wchodz??c?? Topiarz wchodz??c?? Topiarz przechylona zza Wystaj??ca godz wiaty po??o??ona uderzy?? zako??czenie ha??asu w??a??ciwie	nowy r????nicy ci??gi przestrze?? formy instrukcji formy instrukcji rozwi??zana opisane st??uczki przewody wyja??ni?? foto niebezpiecznych kt??ry dzia??u osprz??tu	IMG_20210513_112111.jpg	2021-06-10	2021-06-21
322	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-07-26	11	Magazyn TGP1 rampa nr 5.	2021-07-26	14:00:00	5	klosza hala wyj??cie co oprzyrz??dowania stopie?? oprzyrz??dowania stopie?? roznie???? Op????niona bariery skutki zdarzeniu R1 opakowa?? powstania butli	3	ponownie zatrzyma?? Usuni??cie wchodzi?? spi??trowana zosta?? spi??trowana zosta?? b??d??c mo???? ko??ca wykonane sta??o doja??cia spa???? stosuj?? go??ci mia??am	GOTOWYCH stwarzaj??cy palet??? ??rodk??w ??ancucha odk??adczego ??ancucha odk??adczego stwierdzona montaz SZKLA k???? niestwarzaj??cy poszycie uprz??tn??c organizacji r??kawiczek wyt??ocznik??w	Zrzutekranu2021-07-27113425.jpg	2021-08-24	2021-12-15
370	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-10-18	2	Przej??cie z malarni sitodruk easymat do ????cznika z magazynem A30.	2021-10-18	14:00:00	18	uszkodzeniem gor??cej spr????onego otwarcia strefa drzwiowym strefa drzwiowym opad??w Uszkodzona przygotowania dostepu pod????czenia ucierpia?? nawet znajduj??cych robi??	4	cofaj??c pod??o??a odgradza ??niegowe przechylony samozamykacz przechylony samozamykacz dni opisu Towar Mo??liwo???? pod??ogi Wyci??ganie pi??trowane Elementy Poszkodowana pojemnik??w	wpychaczy DOSTARCZANIE przyczyn NOGAWNI ppo?? stronie ppo?? stronie pracprzeszkoli?? Poimformowa?? uwag?? kotwi??cymi posypanie przek??adane czynno??ci?? swobodne potrzeba status	EASYMATproeg.jpg	2021-11-01	2021-10-18
401	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-11-29	12	Linia R10	2021-11-29	09:00:00	19	dekoratorni zako??czona uszkodzenia nieporz??dek substancjami urwana substancjami urwana nadawa?? momencie ustawione ZASTAWIONA TKANEK powietrze czysto??ci g??ownie znajduj??ce	3	dosy?? przej??ciu ochrony r??cznie pust?? miejsce pust?? miejsce przewr??ci?? stron ceramicznego ??ruby paleciaku krzes??em wi??kszo???? upad??a ??le Zakryty	nt Palety ga??niczy kart kra??cowego rozmawia?? kra??cowego rozmawia?? Naprawi?? zapewniaj??c odblaskow?? oczekuj??cego ok min zakazie ruroci??gu nap??dem stabilne	IMG_20211126_092648.jpg	2021-12-28	2022-02-07
83	57b84c80-a067-43b7-98a0-ee22a5411c0e	2020-12-21	2	Na przeciw stanowisk szlifowania.	2020-12-21	11:00:00	0	pochylni - paletyzatora pobieraj??cej przeje??d??aj??cy sk??ry przeje??d??aj??cy sk??ry Wyd??u??ony automatu k??tem przep??ukiwania zako??czenie p??ytek grozi znajduj??cych zosta??a	\N	metr??w brak??w wchodz??cych 8 za??lepia??a kt??re za??lepia??a kt??re minutach ale kraw????nika pojemnikach ??aduj??c pierwszej Tydzie?? wycieki zabezpieczony magazynu	ubranie ??wietl??wek okre??lonych transportowanie GOTOWYCH lod??wki GOTOWYCH lod??wki charakterystyk mo??liwo??ci piec jako maszyn?? Ustawi?? podest szybka przynakmniej R4	uszkodzonafutryna.jpg	\N	2020-12-21
89	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-01-14	9	Magazyn cz????ci	2021-01-14	12:00:00	26	samym kratce zosta??o Nikt Uswiadomienie towaru Uswiadomienie towaru uszkodzenia sprz??tu wydajno???? koszyk pracownikowi zniszczony podno??nik awaryjnej Zwr??cenie	3	niezabezpieczonym rozpada zniszczony urz??dzenie ude??enia awaryjnego ude??enia awaryjnego niezabezpieczonym czyszczenia produkcyjne wn??trzu DZIA??ANIE chwilowy samozamykacz przemieszcza sta??o zaginanie	stwarzaj??cym okresie oczekuj??cego przygotowa?? ????dowania Umieszczenie ????dowania Umieszczenie Usuni??cie ??okcia p??ynu stawiania piecu Dosuni??cie kratke j??zyku bezpiecznym poj??kiem	Sytuacjapotencjalnieniebezpieczna-MWG21.12.JPG	2021-02-11	2021-12-07
92	9be931ff-ff6d-4e74-a13e-4f44ade6d3ac	2021-01-15	3	R3	2021-01-15	13:00:00	18	gaszenia maszynki sytuacji przeje??d??aj??c Uszkodzony od??o??y?? Uszkodzony od??o??y?? gaszenia zerwania jako spadaj??cej praktycznie kotwy przechodz??ce zagro??enie zagro??enie	5	twarzy tym w????czy?? frontowego szcz????cie pode??cie szcz????cie pode??cie Zabrudzenia wej???? RYZYKO wiatru nara??eni kaloryferze termokurczliw?? sortownia opadaj??c pierwszy	ropownicami Odnie???? robocze uniemo??liwiaj??ce regularnie dopuszczalna regularnie dopuszczalna pozosta??ego dokumentow scie??k?? Rozporz??dzenie pustych po??wi??cenie otwartych oznakowanie metalowy DOSTARCZANIE	Niebezpieczneprzechylenieslupkapalet.JPG	2021-01-22	2021-10-12
96	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-02-02	3	Chwiej??ca si?? kratka na pode??cie przy zasilaczu R4	2021-02-02	11:00:00	1	kabel siatka automatu r??ki wp??ywem spi??trowanej wp??ywem spi??trowanej pionowej przypadkuzagro??enia wi??kszych instalacjipora??enie wpadni??cia spa???? popa??enia substancjami posadzce	4	Magazyny stosuj?? otworzeniu Ma??y metalu puszki metalu puszki ponownie ledwo opu??ci??a Ryzykoskaleczenie/potkni??cia/przewr??cenia automatu sk??adowany mnie transportowa?? ??a??cuch??w j??zyku	grawitacji os??aniaj??cej okalaj??cego Mycie stabiln?? Np stabiln?? Np ODBIERA?? celem robocze rozdzielni kabin poprzecznej okre??lonym oznakowane kluczowych powierzchni??	prawiewypadek.jpg	2021-02-16	2021-12-10
160	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	12	R9, miejsce zgrzewania palet 	2021-03-15	12:00:00	25	lub wp??ywem oderwania zerwanie hydrantu du??e hydrantu du??e ??eby uszlachetniaj??cego uszkodzone wi??kszych sa ci????ki sto??u nadawa?? zdarzenia	3	odmra??aniu pod??o??na nolce okolicach czerpnia kontenera czerpnia kontenera uszkodzon?? Sortierka zosta??a kostk?? ch??odziwo drzwi jazdy frontowy linii wystaje	premy??le?? pr??downic potrzeby regularnej doj??cia polerk??/ doj??cia polerk??/ do??wietlenie wewn??trz niebezpiecze??stwo teren niepozwalaj??cej scie??k?? linie Przytwierdzi?? transporterze okolicach	IMG-20210315-WA0031.jpg	2021-04-12	2021-12-29
304	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-07-12	12	R7	2021-07-12	10:00:00	16	innego Lu??no ta??m?? spadku Gdy nim Gdy nim oparzenia zdarzenia : brak nadawa?? w??zek drzwiowym awaryjnej po??ar	3	wentylacyjny maszyn Otwarte BHP dziura samym dziura samym opu??ci??a wy????cznik chwiejne kosza ??adunek ga??nicze: opisanego prawie pomiedzy dzia??u	ostro??no???? min sobie Stadaryzacja os??ony odpowiedzialny os??ony odpowiedzialny gi??tkich transportowania Rekomenduj??: klamry drodze lod??wki odblaskow?? drzwi wewn??trz realizacj??	IMG_20210907_162428.jpg	2021-08-09	\N
248	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-05-14	3	Wyj??cie z hali produkcyjnej w kierunku warsztatu mechanicznego.	2021-05-14	16:00:00	18	dobrowadzi??o przykrycia kostki instalacji smier?? bram?? smier?? bram?? zniszczeniauszkodzenia: k????ko oderwania zsuni??cia uderzeniaprzygniecenia materialne dopuszczalne nara??aj??cy uderzeniem	4	ziemi plastykow?? zaciera uwagi nim g??rnej nim g??rnej doj???? py?? blaszan?? przytwierdzona pusta ztandardowej szafy cz????ciowo Niestabilne pusta	przypominanie rega??ach skladowa?? Dodatkowo niekt??re Przypomnienie niekt??re Przypomnienie Regularne powierzchni?? szatniach rowerze razy swobodnego wema ograniczaj??cego przemieszczenie swobodnego	20210513_130732.jpg	2021-05-28	2021-12-08
356	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-09-20	2	Wej??cie do/ wyj??cie z nowej malarni od strony ul. M. Fo??tyn.	2021-09-20	16:00:00	18	strony budynk??w mokro zako??czenie osobowej oprzyrz??dowania osobowej oprzyrz??dowania sprz??taj??ce uczestni??cymi innymi przycisk tych kotwy ods??oni??ty uszkodzenia nadstawek	3	ruch s??u????cy luzem uszczerbek wysok?? wej??ciowymi wysok?? wej??ciowymi pile Pojemno???? oczywi??cie kraw??d?? dla o??witlenie przewr??ci??a biegn??ce o wchodzenia	wy????czania butelk?? Uniesienie oczka Zabepieczy?? oznaczony Zabepieczy?? oznaczony Pomalowa?? widoczno???? owini??cie przesun???? wibracyjnych przegrzewania pojemnik??w szczotki materia??u pr??dko??ci	Malarnia2(1).jpg	2021-10-18	\N
362	2168af82-27fd-498d-a090-4a63429d8dd1	2021-09-30	3	R8 podest	2021-09-30	03:00:00	16	lod??wki kierunku uruchomienie upadku przep??ukiwania element??w przep??ukiwania element??w pora??enia Gdyby znajduj??cych tych st??uczk?? smier?? ka??d?? cz????ci?? szybkiej	4	palcy po??aru u??ywaj?? metalowym/ odb??j ga??nica odb??j ga??nica wietrze strat zaginanie 7 myjki ci????ko transportu etapie Zastosowanie komunikacji	pomiar??w serwisanta drug?? jako kartk?? warianty kartk?? warianty dokumentow sol?? Wg bortnice szlamu wn??trza jakim sprawnego sta??ego by??a	R8barierkaXXX.jpg	2021-10-14	2021-12-08
365	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-09-30	9	A21	2021-09-30	08:00:00	2	niezgodnie uszkodzeniu je??d????ce ska??enie studni widzia??em studni widzia??em Ukrainy spadku r????nicy ??atwopalnych nim oznaczenia sieciowej ??rodowiskowym- odstaj??ca	5	szklanych mnie wentylacyjnym zabiezpoeczaj??ca jedn?? sztu??c??w jedn?? sztu??c??w sekcji ochronnych bariera kilka spadku os??oni??te dozna??a Wisz??cy oderwanej przej??ciu	dymnych wpychcza Uszczelnienie wysokich stawiania dopuszczalne stawiania dopuszczalne pro??b?? my?? elektryczne lustro Uszkodzone wyja??ni?? Rekomenduj??: szyba Kompleksowy dostep??m	Blacha.jpg	2021-10-07	2021-11-17
418	9c64da01-6d57-4778-a1e3-d25f3df07145	2021-12-31	12	Obok maszyny inspekcyjnej R10	2021-12-31	10:00:00	5	schodach pod Np wp??ywu podesty przechodz??cej podesty przechodz??cej utrzymania budynkami d??wi??kowej Pochwycenie barierka sprz??t pracuj??ce z??ego sprz??taj??cych	3	olej nieczynnego ruchomy przechodz??cego wid??owych asortymentu wid??owych asortymentu Opady wybuchowej wydostaj??ce Wchodzenie tzw r0 wci??gni??cia rejonu skladowane wchodzenia	odprysk??w kabla ogranicenie w??a??ciwie pod????czenia miejscach pod????czenia miejscach przeznaczeniem Odnie???? swobodne ga??niczych oceny bokiem drabin sprawno??ci powietrza zaworu	image-31-12-21-10-41.jpg	2022-01-28	2022-05-31
61	57b84c80-a067-43b7-98a0-ee22a5411c0e	2020-10-16	3	Droga mi??dzy R5 i R6	2020-10-16	10:00:00	0	uszkodzenie palety umieli sk??adowane kabel sto??u kabel sto??u mog??o opakowa?? dost??pu g??ow?? pokonuj??cej dnem Mo??liwy pracownicy by	\N	palety szczyt uraz zamocowana pada przechodz??c?? pada przechodz??c?? nogi kostrukcj?? przemieszcza dystrybutor za??amania niedozwolonych WID??OWYM odleg??o??ci organy Zatrzyma??y	charakterystyk dokonaci ??rodka r??kawiczek prawid??owe kolejno??ci prawid??owe kolejno??ci ??cie??ce prowadz??cych dachu ustawienie otworzeniu niwelacja dodatkowe obudowy elektrycznych ca??o??ci	20201016_101954.jpg	\N	2021-09-20
333	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-08-09	10	????cznik pomi??dzy starym magazynem a nowym - obok TRS	2021-08-09	07:00:00	26	wskazania delikatnie pora??enia gor??c?? spr????onego obydwu spr????onego obydwu opakowa?? prac pozostawiona Zdezelowana uaszkodzenie rozszczelnie podczas St??uczenia cia??a:	3	pozostawione podesty ruch gro????ce takich wspomagan?? takich wspomagan?? odsuni??ciu wyrwaniem hydrantu mia?? awaria palety lewa ucz??szczaj?? ga??niczy: ??rodku	os??yn prowadzenia regularnie Odblokowanie G????doko???? oznaczone G????doko???? oznaczone odpre??ark?? nap??dem kanaliki DOSTARCZANIE wypatku czujnik??w korb?? bezpieczne wypadku porozmawia??	IMG20210729180351.jpg	2021-09-06	2021-12-07
103	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-02-09	2	Miejsce po zdemontowanych schodach, naprzeciwko R3. 	2021-02-09	09:00:00	18	Zdezelowana w??zkiem Tydzie?? transportowa amputacja grup amputacja grup obszaru zagro??enie Gdy u??ycia rowerzysty obydwu drogi zapali??a mog??	3	umo??liwiaj??cych tych Drogi Wannie z??ej powtarzaj?? z??ej powtarzaj?? Ca??o???? zabezpieczony jeden transportowany palnych gazu przewr??cenia podjazdu wychodz??cy odpowiedniej	naklei?? karton??w substancji przdstawicielami ??cian posadzce ??cian posadzce cm transportowych mia?? le??a??y charakterystyki programist??w pokonanie malarni koryguj??ce umorzliwi??yby	20210209_081507.jpg	2021-03-09	2021-02-24
110	e72de64c-9ad8-4271-ace5-40619f0a5c0e	2021-02-12	12	brama miedzy malarni?? a produkcj?? na przeciwko prasy R3	2021-02-12	13:00:00	18	produkcji ludzkiego samych ci????kich g??ow?? bram?? g??ow?? bram?? ??rodowiskowe dekoratorni opa??enie stoi d??oni- poprzepalane mokro ci????ki poziom??w	4	za??amania miejsce prawdopodobnie r??kawicami WYT??OCZNIK spadnie WYT??OCZNIK spadnie potrzebuj??cy si??owy dwie ??e spowodowa?? stoi si??poza wylecia?? ograniczaj?? transpornie	bhp przeznaczy?? nieodpowiedzialne kompleksow?? lod??wki Poinstruowanie lod??wki Poinstruowanie rozwi??zana klapy miejscamiejsce stosu osoby/oznaczy?? brama/ przednich pr??t rozlew??w ga??nice	20210209_141055.jpg	2021-02-26	2021-12-29
121	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-02-24	2	Kammann	2021-02-24	10:00:00	20	wyj??cie procesu technicznym stanie tekturowych ciala tekturowych ciala warsztat spadaj??cej wid??owe wyroby okolo przypadkuzagro??enia bia??a doprowadzi?? kartony	3	podtrzymanie tryb funkcj?? kostki/stawu utrudnia??o jedn?? utrudnia??o jedn?? zabezpieczaj??cego przekazywane lejku wzros??a przemyciu sitodruku nogi skutkiem ewakuacyjnej wieczorem	t??ok Skrzynia dodatkowe prowadnic pionowo przestrzegania pionowo przestrzegania gaz okresie j??zyku blache technologiczny maszyn?? do przepis??w wibracyjnych stabilnego	IMG-20210224-WA0005.jpg	2021-03-24	2021-02-24
152	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2021-03-12	11	Obszar przy automatyzacji linii R7	2021-03-12	07:00:00	26	przewod??w Opr????nienie poziom??w awaryjnej stoi poparzenia stoi poparzenia ma??o ilo??ci piecem Mo??lio???? ludziach siatk?? drzwi uszczerbkiem r10	3	zwracania sto??u czyszczenia pi??trze uda??o drugiej uda??o drugiej surowc??w d??ugie pokryw oczko segement s??uchawki tamt??dy CNC przesuwaj??cy zosta??y	przenie?? wi??cej szk??a miejsca palet technologiczny palet technologiczny hali wodzie szlifowania Poinstruowa?? przeznaczone dobr?? poziomych kiery podobne dobr??	20210312_072252.jpg	2021-04-09	2021-12-15
199	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-04-19	10	??adowanie akumulator??w, wyj??cie wakuacyjne.	2021-04-19	14:00:00	25	prasa ruchu p??ytek drzwiowym czyszczeniu z??amania czyszczeniu z??amania zaczadzeniespalenie powoduj??c?? pobieraj??cej Przewracaj??ce tych Wyniku itd jako nadstawek	3	szuflad?? i???? podest??w ugasi?? gema krzywo gema krzywo tak cieknie w wskazuje ??eby prowadz??ce potkn????a systemu uchwyty on	rozmie??ci?? bezpo??rednio pionowo czasu podwykonawc??w Weryfikacja podwykonawc??w Weryfikacja u??ytkiem przerobi?? scie??k?? pojemnik por??cze jezdniowe magazynowaia ewentualnie odp??ywowej posprz??ta??	20210419_131123.jpg	2021-05-17	2021-12-07
323	8aed61ca-62f5-445f-993b-26bbcf0c7419	2021-07-27	2	Wyjazd z malarni na magazyn	2021-07-27	23:00:00	18	informacji wy????cznika robi?? sztuki Spadaj??cy powoduj??c?? Spadaj??cy powoduj??c?? wpychania opakowa?? pora??anie Pozostalo???? sa automatu gdzie przechodz?? zdj??ciu	2	oczko ma ewakuacyjnej zewn??trzna podjazdu zwarcie podjazdu zwarcie okazji przemyciu dzia??u naci??ni??cia Przeno??nik Zakryty transportowa?? alejce 800??C pompki	r??kawiczki przej??cia dopuszczalne butelk?? operator??w furtki operator??w furtki pobierania przegl??du rozlew??w Dodatkowo konstrukcji/stabilno??ci przeznaczeniem rzeczy elektrycznych oznakowane przegl??d	IMG20210727093455.jpg	2021-09-21	\N
430	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-01-31	4	Przed pomieszczeniem laboratorium	2022-01-31	12:00:00	19	pras w??zki przechodz??c?? laptop Pomocnik zgniecenia Pomocnik zgniecenia no??yc r??ce niekontrolowane oka zwichni??cia dost??pu Np zalanie wstrz??su	3	kartonami naprawy tym powtarzaj?? wspornik??w wid??owego wspornik??w wid??owego reszt?? reakcji si??poza rozmowy innego DOSTA?? stanowisku zasypniku s??u????cy ceramicznego	powleczone cieczy przenie???? produkcji ochronnej Kontakt ochronnej Kontakt stanowisko Uzupe??nienie szk??em firm?? studzienki zasilaczu dokonaniu zanieczyszcze?? takich pojemnikach	20220131_091445.jpg	2022-02-28	\N
403	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-11-29	3	Linia R2 / R5?	2021-11-29	09:00:00	3	mienie odstaj??ca Zwarcie gor??ca przetarcie podkni??cia przetarcie podkni??cia dystrybutor operatora r??wnie?? jednego upadek powodu rozmowa form mog?? wydajno??ci	4	s??owne wypadni??cia prowadz??ce mo??liwo??ci?? ekranami czego ekranami czego u??ywana pracy odsuni??ciu tekturowymi boksu sortuj??ce ??wietliku za??adukow?? alumniniowej Potencjalny	Poprawny wypadni??cie korytem wyposa??enia stosach klapy stosach klapy remont r??wnej pomi??dzy podobne odblokowa?? prawid??owych tam Trwa??e stwarza??y rozmieszcza	IMG_20211126_093559.jpg	2021-12-14	2021-12-08
169	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	12	Droga ruchu pieszych przy stanowisku Kierownika Sortowni	2021-03-15	13:00:00	18	odbieraj??cy ??rodowiskowe w??zka ??le ilo??ci plus ilo??ci plus sk??ry kostce sprz??taj??ce przewod??w Tydzie?? g??owy pozosta???? widocznej ciala	3	wentlatora oznakowania usterk?? wspomagan?? gniazko pieszy gniazko pieszy Mokre wyniki obsuni??ta proszkow?? Nieodpowiednio przechylenie r??czny spada sto??u trzymaj??cej	chemicznej defekt??w mo??e w??zk??w w???? stwierdzona w???? stwierdzona transportowane rozmawia?? odboju porz??dku b??bnach sk??adowanie pust?? pulpitem wewn??trznych karton??w	20210315_131207.jpg	2021-04-12	2022-02-08
135	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-03-02	2	Sort - malarnia	2021-03-02	14:00:00	26	produkcji a pracownicy ci????kich polegaj??cy form?? polegaj??cy form?? niebezpiecze??stwo delikatnie elementy zahaczy?? poziom??w wylanie Ci????kie rozdzielni ka??d??	3	opu??ci??a mozliwo???? "mocowaniu" rutynowych straty g??ow?? straty g??ow?? przemieszczajacych jest rzuca??o r??ku rega??ami zdarzeniu gazu 7 upad?? pod??og??	uchwyty Staranne operatorowi Ustawianie silnikowym sprz??tu silnikowym sprz??tu ca??ej kraw????nika naprowadzaj??ca procownik??w przeznaczone stawania uszkodzon?? paleciak??w istniej??cym napraw	IMG_20210302_131648.jpg	2021-03-30	2021-03-17
139	a6e35ba8-06de-4a85-8b4f-961bd7ff09d0	2021-03-06	2	Malarnia - szlifiernia	2021-03-06	11:00:00	26	spr????onego sufitem dla wid??owym szatni kt??ra szatni kt??ra Wypadki Stary za ewakuacyjnym karku ostrzegawczy pracuj??cego stoi zahaczy??	2	uderzy?? schodzenia dzieckiem piecem potykanie wychodz??cych potykanie wychodz??cych wod??gaz kondygnacja wchodz??c?? us??an?? worek boli ko??cowym zamocowane ??ilny kawa??ek	SZKLA s??upkach terenu form ??rub?? pierwszej ??rub?? pierwszej substancj?? d??wignica napraw Foli?? kask Niedopuszczalne ????dowania do??wietlenie H=175cm teren	IMG_20210306_102831.jpg	2021-05-01	\N
142	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-03-08	2	sciana obok Carmet 2	2021-03-08	08:00:00	26	sk??adowanych nog?? g??owy jednego przykrycia amputacja przykrycia amputacja skutki: przeciwpo??arowego spi??trowanej spowodowa?? przeciwpo??arowej 2m gwa??townie odbieraj??cy lampy	2	przechowywania frontowego odp??ywu drugi przechylenie biurkiem przechylenie biurkiem godz oznakowanie wystaje mocno oznakowanie powoduj??ce d??ugo??ci pracuj??ca Nieprawid??owe podejrzenie	ruchomych pracownika nachylenia stabilnie biurowego przestrzegania biurowego przestrzegania demonta??u pewno Dodatkowo umieszcza?? kart?? rega??ach firmy montaz obci????one owini??cie	IMG_20210308_083440.jpg	2021-05-03	2021-03-17
145	2168af82-27fd-498d-a090-4a63429d8dd1	2021-03-09	3	polerka R1 od strony odpr????arki.	2021-03-09	10:00:00	6	Zatrucie pochylni monitora Bez kabel detali kabel detali karton??w prowadz??ce procesu stoi szk??a - zbiorowy wypadek ostrym	5	Wy??adowanie kawe??ek otwieraniem termokurczliw?? taki uszkodzeniu taki uszkodzeniu natrysku linii "nie windzie/podno??niku ga??niczy: stoj??ce by?? bezpo??rednio oznakowanie pok??j	??cian?? dobranych Rega?? warunki uprz??tn???? niedostosowania uprz??tn???? niedostosowania Palety podno??nikiem istniej??cym st??uczki utrzymaniem istniej??cych utraty podestem ??okcia przygotowa??	IMG-20210309-WA0000.jpg	2021-03-16	2021-10-12
161	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	2	Przej??cie przy starym miejscu windy 	2021-03-15	12:00:00	25	wysoki wod?? jednoznacznego chemicznej w pojazd??w w pojazd??w zdarzeniu w??zka po??lizgni??cie prowizorycznego palecie Uszkodzona szklan?? uaszkodzenie do??u	3	pozosta??o??ci SUW pozadzka odpr????ark?? Staff upadku Staff upadku pierwszy biura nieu??ywany Obok pompki wirniku przestrzegania odrzutu odcinku wstawia	likwidacja poprzecznej Weryfikacja natrysk Je??eli telefon??w Je??eli telefon??w miedzy Umieszczenie t??ok odstawianie tylko ograniczonym dzwon nieuszkodzon?? odp??ywowej to	IMG-20210315-WA0036.jpg	2021-04-12	\N
170	2168af82-27fd-498d-a090-4a63429d8dd1	2021-03-15	3	w??zki do form	2021-03-15	16:00:00	24	okolo okolo gwa??townie wybuchupo??aru obra??enia skrzyd??o obra??enia skrzyd??o instalacjipora??enie ponowne routera wp??ywem po??ar zap??onu mocowania lampy dolnej	3	docelowe samodzielnie pompach pode??cie uzupe??niania zamkni??ciu uzupe??niania zamkni??ciu telefoniczne skrzynka wpadaj?? badania tam by??o poruszania dystrybutorze Deski miesi??cu	pr??g Foli?? scie??k?? stolik rur?? Wieksz?? rur?? Wieksz?? informacyjnej ruchom?? nt oleju konserwacyjnych napawania metalowych przysparwa?? UR trybie	20210315_131832.jpg	2021-04-12	2021-03-30
172	800f4ae5-d6e5-45bf-9df7-ac9a8dcab858	2021-03-15	2	Kammann K15	2021-03-15	08:00:00	26	przewod??w ??miertelnym acetylenem urazu ka??d?? ponowne ka??d?? ponowne pojazdu Nara??enie wy????cznika ci????kich wci??gni??cia ilo??ci wydajno??ci wci??gni??cia w??zka	5	naro??nika widoczno???? by?? pracuj??ce pora??enie oczu pora??enie oczu technologiczny liniach wyznaczonym kt??r?? stosownych ??ci??gaj??cy st??umienia gro????c nawet szczeg??lnie	pode??cie pozostawiania obs??ugi s?? istniejacym oznaczone istniejacym oznaczone Pomalowa?? obci????enie gaz??w ppo?? mia?? stawania podj??ciem samoczynnego WORK??W listwach	IMG_20210315_155622.jpg	2021-03-23	2021-03-18
185	5bc3e952-bef5-4be3-bd25-adbe3dae5164	2021-04-07	12	brama malarnia-sortownia	2021-04-07	07:00:00	5	posadzce obudowa blachy pieca magazynu niecki magazynu niecki karton sortowanie tj pod??og?? zmia??d??enie wp??yw zbiornika zosta??a zapewniaj??cego	2	pracowince pozosta??o??ci uszkodzeniu ogrodzenia skutkowa?? siatk?? skutkowa?? siatk?? stopa nad osadzonej widlowym pode??cie w??ywem ??mieci zamocowanie gema przyczyn??	butle osuszenia nowe Prosze biurowych uruchamianym biurowych uruchamianym okoliczno??ci kasku maty przej??ciowym Przyspawanie/wymiana Paleta wanienek oceniaj??ce Pomalowa?? swobodne	IMG_20210406_065707.jpg	2021-06-03	2021-12-30
195	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-04-19	3	R9	2021-04-19	14:00:00	25	sterowania Bez prowizorycznego amputacja stopie?? drukarka stopie?? drukarka szk??d stanowisko spowodowane poprawno???? kart?? przypadku Zwisaj??cy sa urwana	3	narz??dzi roztopach balustrad zosta?? mo??na kostrukcj?? mo??na kostrukcj?? przewidzianych izolacj?? "NITRO" poniewa?? oderwie b??d??c opanowana nalano podjazdowych pod??og??	posegregowa?? odstawianie fotela przeznaczy?? wentylacja niew??a??ciwy wentylacja niew??a??ciwy biurowych operacji konstrukcj?? O??wietli?? nie dopuszczalne NOGAWNI niezb??dne r przechodzenia	20210419_131931.jpg	2021-05-17	2021-12-08
196	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-04-19	3	R9	2021-04-19	14:00:00	25	sprz??taj??ce kraw??dzie Przegrzanie mog?? Zwisaj??cy nawet Zwisaj??cy nawet przypadkuzagro??enia innymi bramie urz??dzenia oparzenie dostepu spadaj??ce w zatrucia	2	CZ????CIOWE/Jena wentylacyjn?? niewystarczaj??ca komunikacyjnych Pleksa mia?? Pleksa mia?? sto??em podlegaj??cy konstrukcji technicznego substancjami kraw??dzie Rozwini??ty zasilaczy przeno??nika wej??cie	co ca??owicie przechodzenie roboczej umy?? odpowiedniego umy?? odpowiedniego kurtyn strefy wa?? sprz??tu mieszad??a paletowego Przygi???? sk??adowanie metra d??oni	20210419_131753.jpg	2021-06-14	2021-12-08
202	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-04-20	1	Biuro Specjalist??w KJ	2021-04-20	08:00:00	6	kostce urwania dotycz??cej poprzepalane ograniczenia pracuj??cego ograniczenia pracuj??cego 1 zniszczony sk??adowane straty palet pojemnika bia??a uszkodzon?? ????cznikiem	3	CIEKN??CY stara pracownikiem przej??ciu Mo??liwe ca??ej Mo??liwe ca??ej posiada??a postaci zamocowanie "nie cieczy fragment wystawa??y robi??ca wszed?? niewystarczaj??ce	blisko niekontrolowanym kamizelk?? pionowo opakowania oczekuj??cego opakowania oczekuj??cego ko??a PRZYTWIERDZENIE dziennego lub pracownice rury chwytak odstawi?? no??ycami parkowania	20210419_125800.jpg	2021-05-18	2021-06-09
227	2168af82-27fd-498d-a090-4a63429d8dd1	2021-05-02	3	koliba przeznaczona na szk??o z R4 i 10	2021-05-02	18:00:00	5	kart?? wysoko??ci odboju paletyzatora bezpiecznej wydajno???? bezpiecznej wydajno???? St??uczenia innymi Ipadek wpychaniu firm?? pracuj??ce dekoracj?? w????a stopy	4	zawiadomi??em stosach jej wyrwane Operacyjnego drzwowe Operacyjnego drzwowe doprowadzi?? drug?? uderzono poprzez Deski wcze??niej przyczyn?? zsyp??w nieprzeznaczonym mycia	Przytwierdzi?? przepisami wanienek wymalowa?? przycisku mieszad??a przycisku mieszad??a stosowania Poprawne Rozpi??trowywanie przeszkolenie przdstawicielami r poziome gniazdko pracuje kt??rzy	IMG_20210501_183852.jpg	2021-05-16	2021-05-03
187	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-04-09	4	Brak pokryw na studzienki, studnie	2021-04-09	09:00:00	2	ilo??ci wybuch si?? powoduj??c?? spr????onego Pracownik spr????onego Pracownik Cie??kie powoduj??c?? zaczadzeniespalenie wid??owym drogi znajduj??ce pionie w???? zalenie	5	pada wyt??ocznikami socjalnego wydostaj??ce klimatyzacji odbywa klimatyzacji odbywa miejscach butl?? wietrze przechodzenia butem dla naderwana puszki dystansowego spi??trowanej	informacje utrzymywania odp??ywu wchodzenia sto??u szklanego sto??u szklanego uprz??tn??c Cz??ste godz swoich uszkodzonego blacyy oraz drba?? informacji spi??trowanej	noez.jpg	2021-04-16	2021-11-17
204	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-04-21	4	Tereny zewn??trzne, obok rampy nr 2	2021-04-21	08:00:00	26	Gdyby informacji ci????ki od??amkiem istnieje posadzce istnieje posadzce b??d??cych Wyciek rz??dka uaszkodzenie w??zki przerwy przedmiot ??rodowiskowe komu??	2	opakowa?? kiedy d???? niebezpieczne obszar zamkni??cia obszar zamkni??cia powiewa dost??pu work??w Poinformowano szeroko???? ??ciankach poinformowa??a strumieniem nocnej wchodzi	szczelno??ci kask dosz??o Docelowo pod????czenia rozdzielni pod????czenia rozdzielni porz??dek liniach stabilnego miejsc dymnych uniemo??liwiaj??cy os??oni?? napis wentylacja umytym	image-20-04-21-08-49.jpg	2021-06-16	2021-11-17
237	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-05-10	12	R1 / R2	2021-05-10	09:00:00	25	bramy dotycz??cego ??rodowiskowym- wci??gni??cia Ryzyko zdarzenia Ryzyko zdarzenia lampy podczas studni szklan?? zgniecenia zdrowiu wieczornych korb?? wraz	3	lusterku wyje??d??a stopie?? zdmuchiwanego potencjalnie P??omienie potencjalnie P??omienie osob?? poszdzk?? wytarte transpotru nale??y unosz??cy zauwa??y?? wyrobami kaw?? Gniazdko	ochronne odpady przechodni??w przewody wykonywa?? dochodz??ce wykonywa?? dochodz??ce mog??y obs??uguj??cego konserwacyjnych w??zkowych Przestawienie wspomagania system szczotki odk??adcze schodkach	20210510_085911_compress80.jpg	2021-06-07	2022-02-08
239	9c64da01-6d57-4778-a1e3-d25f3df07145	2021-05-10	2	Malarnia obok SPEED	2021-05-10	12:00:00	26	magazynu starego reagowania Moz??iwo???? pracuj??ce pora??enia pracuj??ce pora??enia ????czenie st??uczk?? ??????te dnem obs??ugi przeje??d??aj??c cia?? zahaczy?? ??mier??	2	okapcania folii termowizyjnymi zdjeciu stronach UR stronach UR kiedy grozi oczywi??cie naruszona gipskartonowych prasie Mokre wymiany Nieodpowiednio wyp??ywa??o	spawark?? stanowisk rozbryzgiem stwarzaj??cym w??a??ciwych u??ytkowaniem w??a??ciwych u??ytkowaniem osuszy?? furtki nieodpowiedzialne ochronnej Utrzyma?? dziennego Karcherem stosy rozwi??zania ograniczaj??cej	Zdjecie1.jpg	2021-07-05	2021-06-21
243	800f4ae5-d6e5-45bf-9df7-ac9a8dcab858	2021-05-13	2	Przy maszynie speed 50	2021-05-13	14:00:00	26	Z??amaniest??uczenieupadek Elektrktryk??wDzia??u palecie nogi Uszkodzona cm Uszkodzona cm rany widzia??em maszynie budynkami rozdzielni automatycznego w materialne- nadpalony	2	wid??owych pro??b?? wyznaczon?? samodzielnie prac?? zwisaj??cy prac?? zwisaj??cy omijania palnych wytyczon?? kask??w barierka niestabilnej pokryte ??arzy?? u??ywaj?? rozmiaru	dachem przypomniec tendencji owini??cie magazynowanie ????cz??cych magazynowanie ????cz??cych wprowadza wykonywanie niestwarzaj??cy Dospawa?? niebezpiecznego ko??ysta?? opisem Naprawi?? skrzyni piec	IMG20210513122828.jpg	2021-07-08	2021-06-21
249	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-05-17	4	Szatnia damska nowa	2021-05-17	11:00:00	25	olejem upuszczenia wid??owe maszyny ze polerki ze polerki Potencjalne ma??o spr????onego charakterystyki pusta dostep sk??adowana trwa??y nale??y	3	widok nowej resztek karton zamkni??te Stare zamkni??te Stare balustad umiejscowion?? kostki/stawu wyd??u??ony sztuki wyskakiwanie kt??rej r????nice ci??g maszyny	porz??dku poziom??w naklei?? budynki towarem sk????dowania towarem sk????dowania plomb przeznaczonym okresie dalszy malarni p??j???? wolnej jednocze??nie kable O??wietli??	20210517_110217.jpg	2021-06-14	\N
251	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-05-17	12	Apteczka R3	2021-05-17	11:00:00	15	butli chemicznych hydrantu magazyn w Potkni??cie w Potkni??cie os??ona d??wi??kowej Nara??enie niekontrolowany zmia??d??enie ludzkiego Sytuacja obudowa towaru	2	zdjeciu rur?? skutkiem otwartych w??skiej Zdeformowana w??skiej Zdeformowana bokami zniszczenie j??zyku drodze Balustrady butem wystaj??c?? opu??ci?? rozwni??ty szklane	miejscami usytuowanie szklanej W????CZNIKA ratunkowego ??atwe ratunkowego ??atwe wymianie przedosta??y by g??ry naklei?? r????nicy mechaniczna po??o??enie konstrukcj?? kumulowania	20210517_105605.jpg	2021-07-12	2021-12-30
261	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-05-21	12	Sortownia, obok strefy obkurczania folii 	2021-05-21	11:00:00	25	upa???? plus dla pobli??u ostreczowanej zdarzeniu ostreczowanej zdarzeniu siatk?? uderze przypadku skrzyd??o pusta zanieczyszczona g??ow??ramieniem ca???? wod??	4	worka wpad??o jednym dachu uzupe??nianie wp??ywaj??c uzupe??nianie wp??ywaj??c komputerowym zaciera pierwszej on ga??nicze: zagro??enie wyznaczon?? blacha z??ej foli??	k???? podestu powiesi?? klej??ca przez kratke przez kratke patrz??c drzwi grudnia W????CZNIKA drewnianymi podesty niebezpieczne otuliny Rozporz??dzenie specjalnych	IMG_20210521_113025.jpg	2021-06-04	2021-12-30
262	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-05-21	15	Stanowiska do czyszczenia form	2021-05-21	13:00:00	26	g??ownie pojazdu s??uchu odk??adane sk??adowanych zablokowane sk??adowanych zablokowane g????wnego za Zwarciepora??enie ??rodowiskowe Mo??liwy upadaj??c piec pr??g osob??	3	zahaczenia ochronnik??w konstrukcji odeskortowa?? ni??ej Czynno???? ni??ej Czynno???? przek??adkami jak mog??o oznakowania dystrybutorze wysoko???? zamkni??te k??adce przyci??ni??ty trafia	szafy kt??rzy po??wi??cenie przeno??nik??w ostrzegawczymi kra??cowego ostrzegawczymi kra??cowego ??rub?? Konieczny nakaz nachylenia miesi??cznego wyja??ni?? wej??ciu technicznych oprzyrz??dowania szlifierni	IMG_20210521_113432.jpg	2021-06-18	\N
284	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-06-30	4	Rozdzielnia elektryczna przed magazynem palet	2021-06-30	10:00:00	25	zawroty od??amkiem delikatnie ca???? stopypalc??w palet stopypalc??w palet budynkami charakterystyki widocznej kotwy wyrob??w zaworem koszyk ka??dorazowo przeje??d??aj??c	4	kondygnacja ????cz??cej tam opr????ni?? temperatura wypchni??ta temperatura wypchni??ta przw??d we wyrwane oczka gdy?? ??rodku siebie zestawiarni Niezabezpieczona ona	Uporz??dkowa?? sterowniczej obecnie pol szklanymi dolnej szklanymi dolnej scie??k?? transportera Wprowadzenie przebywania Odnie???? lokalizacj?? Mycie u??ytkowania mi??dzy praktyki	20210625_085532.jpg	2021-07-14	2021-12-07
197	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-04-19	3	Zej??cie do piwnicy	2021-04-19	14:00:00	18	nara??one polerce polerce pot??uczona polerce odprysk polerce odprysk roboczej linie pot??uczenie Pozostalo???? zdarzeniu pracownice ta??moci??gu ostrzegawczy sterowania	3	przynios?? zasilaczach szaf?? transportu wrz??tkiem transportowego wrz??tkiem transportowego wchodz??cych zawleczka deszcz nieoznakowanym dni odsuni??ciu podestach dymu linii zaczynaj??ca	Inny Prosz?? odbywa??by sterowniczej metalowy magazynowaia metalowy magazynowaia niemo??liwe terenie Poprawne towarem wannie przysparwa?? rekawicy poprowadzi?? przyczyny czyszczenia	20210419_131309.jpg	2021-05-17	2021-04-26
276	5bc3e952-bef5-4be3-bd25-adbe3dae5164	2021-06-22	11	nowa lokalizacja automatycznej streczarki 	2021-06-22	14:00:00	5	pracy obr??bie gwa??townie praktycznie kierunku prawdopodobie??stwem kierunku prawdopodobie??stwem Balustrada skr??cona oczu t??ust?? kabla magazynu Zwr??cenie silnika ??rodka	4	b??d??c dosz??o przekazywane gor??cego zapewnienia drugiej zapewnienia drugiej barierki chroni??cych stoja kamizelek kuchni osuwa?? kartony opu??ci??a gazem Zastawienie	operacji innych Mechaniczne stanu boku warianty boku warianty opisane mocuje FINANS??W nieco usuwa?? wchodz??cych koc swobodnego kontener??w konsekwentne	IMG_20210621_135915.jpg	2021-07-06	2021-12-15
286	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-06-30	3	Linia R3	2021-06-30	10:00:00	17	nawet du??e doznania przechodz??cej sko??czy?? urwana sko??czy?? urwana ????cznikiem otwarcia Pozosta??o???? drukarka ci????ki wycieraniu pracownika odbieraj??cy uszczerbkiem	3	przyci??ni??ty transportow?? przepakowuje/sortuje powierzchni totalny sztuki totalny sztuki wyrwaniem poniewa?? szatniach a?? UCUE stanowi?? paj??ku bliskim u??o??one paletowego	odci??cie testu oznakowane transport nieprzestrzeganie wieszak nieprzestrzeganie wieszak przykryta worki piecyka stabilny wymiany ostrzegawczy ST??UCZK?? paletach lamp parkowania	20210630_102359_compress89.jpg	2021-07-28	2021-06-30
291	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-06-30	15	????cznik mi??dzy Warsztatem/Magazynem Form, a Warsztatem CNC	2021-06-30	12:00:00	6	zerwania liniach spodowa?? poprzez pojazd zgrzewania pojazd zgrzewania ko??a zabezpieczenia do poruszaj?? w????a zako??czenie r10 pistoletu drukarka	4	wyj??cie wanienki komputerowym Mo??liwe kasku ??cian?? kasku ??cian?? auto ??aduj??c drewnian?? piecu wykorzystane ??aduje oczekuj??ce o kraw????nika Wchodzenie	remont wyznaczonymi eleemnt??w wielko??ci plomb przynakmniej plomb przynakmniej pobierania st??uczki boku czujnik??w wyciek os??aniaj??ce wcze??niej wanienki pokry?? obs??ugi	20210625_083145.jpg	2021-07-14	2021-12-17
295	0c2f62a9-c091-47ab-ac4c-fae64bfcfd70	2021-07-05	4	Laboratorium	2021-07-05	08:00:00	9	74-512 zdemontowane jednoznacznego wizerunkowe wpadnieciem operatora wpadnieciem operatora od??o??y?? Lu??no kt??ra du??e gdzie korb?? uderzeniaprzygniecenia Du??a wypadekkaseta	1	u??ytkownika zg??oszenia za??amania obs??ugi Zjecha??y przekrzywiona Zjecha??y przekrzywiona auto ca??y filtr??w u??o??one otworze rozbieranych spi??trowanej porusza jka metalu	nieprzestrzeganie dok??adne ko??cowej oleju wymianie+ naprowadzaj??ca wymianie+ naprowadzaj??ca rozmie??ci?? uruchamianym przyczepy matami odpowiedniego praktyki pojedy??czego ubranie wy????cznika Obecna	IMG_20210702_134649.jpg	2021-08-30	\N
308	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-07-13	10	Hala	2021-07-13	12:00:00	26	oznaczenia Pora??enie studni ewakuacji zerwania wystaj??cym zerwania wystaj??cym po??lizg d??oni- tej r??wnie?? naci??gni??cie starego mokrej budynk??w Uswiadomienie	4	u??ama??a gro????ce j?? sto??u zdmuchiwanego doj???? zdmuchiwanego doj???? hal?? komunikacyjnych oberwania pojemnika Zwisaj??ca przechylenie u??ywana ??adowania szczeg??lnie schodzenia	kabla technicznego wyznaczy?? oslony kratek Uporz??dkowa?? kratek Uporz??dkowa?? os??on?? utw??r/ wystawa?? wydostawaniem dwie wid??ach czujki pozosta??ego napraw biurowca	20210713_110229.jpg	2021-07-27	2021-12-07
309	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-07-13	10	Hala	2021-07-13	12:00:00	26	potencjalnie urz??dzenia m??g?? magazynu bezpieczne innego bezpieczne innego istnieje Dzi?? mo??liwo??ci w???? st??uczenie palecie przeciwpo??arowej skr??cona siatka	4	odpr????arki technicznych chodz?? przemieszczajacych Przeprowadzanie zwarcie Przeprowadzanie zwarcie olej tablicy st??uczka niemal??e frontu nadci??te nadstawek kana??em ude??enia audytu	Dosuni??cie plomb Ka??dy tzw teren hydrant??w teren hydrant??w gdzie kt??rzy foli?? Wymiana/usini??cie dymnych upadek jak bie????ce przypadku etykiety	20210713_110246.jpg	2021-07-27	2021-12-07
316	3ee5fc99-b50b-4b71-8f18-7a7af63c07ef	2021-07-19	11	HYDRANY OBOK RAMPY ZA??ADUNKOWEJ NA PIERWSZYM MAGAZYNIE	2021-07-19	23:00:00	25	delikatnie wypadekkaseta si?? porysowane kolizja brak kolizja brak sk??adaj??c?? kart?? piec sprz??t skrajnie- TKANEK widoczno??ci razie Przer??cone	4	czasie z????czniu zamocowanie le????cy ograniczy??em pada ograniczy??em pada Niepoprawne przewr??ci?? dystrybutorze oczomyjki sobie id??cy zaolejone zdemontowana biegn??ce przewr??cona	Dzia?? instrukcji pilnowa?? Pisemne kszta??t mo??liwie kszta??t mo??liwie bierz??co kontener??w Wdro??enie zabezpiecznia pustych sprawdzania nadzorowa?? ustalaj??ce serwis ??atwe	R-8.jpg	2021-08-03	2021-12-15
319	a6e35ba8-06de-4a85-8b4f-961bd7ff09d0	2021-07-22	2	Przy TR12 naprzeciw mix??w .	2021-07-22	21:00:00	26	wod?? wyj??ciowych przechodz??cej Przeno??nik poruszaj?? zawadzenie poruszaj?? zawadzenie potni??cia Ponadto wypadekkaseta zbiornika zawroty mienie paletach obszaru wybuchu	3	odpr????arki Profibus zsuwania W????CZNIK Samoczynne wystepuje Samoczynne wystepuje Magazynier drugiego kt??rej przyczyn?? zas??ania wystawa??y instalacje momencie upomnienie polerk??	szafy zadaszenie por??cze Wezwanie od??amki piktogramami od??amki piktogramami metra uniemo??liwiaj??cych obs??uguj??cego szyba metalowy rozbryzgiem wyznaczy?? obydwu przechowywania otuliny	IMG_20210720_125314.jpg	2021-08-19	\N
350	2168af82-27fd-498d-a090-4a63429d8dd1	2021-09-07	3	podest R-8	2021-09-07	17:00:00	16	ugasi?? niekontrolowane spr????one uchwyt??w utrzymania pod??og?? utrzymania pod??og?? zawadzenia ??atwopalnych ??miertelny oparzenia pojazdu nog?? kratce Przeno??nik osoby	4	skrzynke nale??y Urwane kamizelka zmia??d??ony otworach zmia??d??ony otworach si???? zmroku upadku odeskortowa?? indywidualnej wentylatorem doprowadzi??o papierowymi drzwi po??piechu	klej??ca uszkodzonych wentylacyjnego montaz pr??g" wentylacja pr??g" wentylacja r??kawiczek dba?? drogi okre??lonym uchwytu H=175cm w??zek cz????ci wentylacyjnego wann??	20210907_144008.jpg	2021-09-21	2021-12-08
331	80f879ea-0957-49e9-b618-eaad78f7fa01	2021-08-06	11	przy sterowniku od automatycznego magazynu	2021-08-06	11:00:00	23	odboju sygnalizacja kt??ra futryny zdrowiu rany zdrowiu rany spi??trowanych korekcyjnych urwania zimno cz?????? przeciwpo??arowego szklan?? wid??owy Lu??no	3	go??ci przej??ciu oleje przymocowanie os??on?? patrz os??on?? patrz zahaczenia transporterach zjecha??em powiadomi??em nadci??te zatrzymanie wydostaj??ce wyposa??one przeciwolejow?? budyku	odp??ywowe Treba transportem czarn?? k??ta stref?? k??ta stref?? podnoszenia Zaczyszczenie monitoring wywieszenie przegrzewania linii jaskraw?? jakiej w??zka bezpo??redniego	7F1E1F2A.jpg	2021-09-03	2021-12-15
328	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-07-30	4	Nowa wiata dla pal??cych - niedaleko sk??adu palet	2021-07-30	14:00:00	18	kontroli wiruj??cy trzymaj?? Zdemontowany transportowej ??rodowiskowym- transportowej ??rodowiskowym- pochylni odci??cie pr??g rozszczelnienie Moz??iwo???? zawadzenia konstrykcji obs??ugiwa?? sygnalizacji	3	obci????e?? mocuj??cy mijaj??cym chwiejne wcze??niej formami wcze??niej formami olejem W??ski bezpo??rednio godz minutach zagi??te kaskow unosi?? ustawi?? schodzi??am	pracownik??w pod??ogi w??zkowych bortnice cienka po cienka po odbieraj??c?? ociekow?? s??u??bowo magazynowania ludzi ilo???? czujnik??w gdzie Niezw??oczne szafie	A9C7451A.jpg	2021-08-27	\N
336	2168af82-27fd-498d-a090-4a63429d8dd1	2021-08-23	12	na pro??b?? Pa?? - podest R1	2021-08-23	15:00:00	5	i znajduj??cych zerwanie zg??oszenia spowodowanie powstania spowodowanie powstania niebezpiecze??stwo Utrata innego przygotowania magazynie obecnym odstaj??ca tys praktycznie	5	sprzyjaj??cej dopilnowanie stanowisk sk??adowana przyczyni??o pracuj??ce przyczyni??o pracuj??ce Poszkodowany kabli pojemniki now?? s??u??b potknie nieu??ywany wanienek mo???? wysoko	scie??k?? sk????dowa??/pi??trowa?? oleju innej usupe??ni?? przedosta??y usupe??ni?? przedosta??y wytycznych wystarczaj??c?? podczas ch??odziwa Usuni??cie umocowan?? wyznaczonym ga??nice Wyprostowanie ruchu	IMG_20210809_065122.jpg	2021-08-30	\N
342	c9f77484-7d39-44d1-aa7c-7c1ac09a24ce	2021-08-24	4	Czytniki wyj??cia/wej??cia malarnia	2021-08-24	13:00:00	5	zawarto??ci gwo??dzie efekcie Otarcie bardzo pora??anie bardzo pora??anie opakowania praktycznie Elektrktryk??wDzia??u po??aru gor??ca smier?? okolo Pora??enie towaru	4	przejazd miejsca Taras" d??ugie innych ga??nicze: innych ga??nicze: S??abe wi??ry dzia??aj??cy prawie drug?? przechodz??c "boczniakiem" wstawia wod?? reakcja	powierzchni wewn??trz wy????czania kt??rzy mocowania Umie??ci?? mocowania Umie??ci?? nadz??r hydrant??w Wi??ksza Sk??adowa?? zadaszenia jasnych prawid??owo ga??nicy Rega?? ubranie	R9.jpg	2021-09-07	2021-08-27
343	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-08-25	11	Droga na zewn??trz magazynu.	2021-08-25	10:00:00	17	Przer??cone Np kraw??dzie Niepoprawne szczelin?? b??dzie szczelin?? b??dzie przewr??cenie komu?? niekontrolowane zewn??trzn?? gazu spr????one znajduj??cego przeje??d??aj??c urz??dze??	4	ustawi?? konieczna Gasnica podni??s?? obci????eniem Zapewni?? obci????eniem Zapewni?? stoj??cego niew??a??ciwie resztek usytuowany transportow?? dziura ognia reakcja pozostawiono nadzoru	od??amki skrzynki uczulenie poj??kiem ciecz muzyki ciecz muzyki t??uszcz Zabudowanie tego robocz?? odp??ywu bokiem worka Poprawa USZODZONEGO mo??liwych	20210824_095151.jpg	2021-09-13	2021-12-15
361	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-09-29	12	Podesty linii R9	2021-09-29	09:00:00	16	prasy organizm ca??ego urz??dzenia fabryki drogi fabryki drogi detali ca???? drogi miejscu paleciaka z??amanie by przemieszczeie Wypadki	3	zepsuty dost??pu Zablokowana USZKODZENIE wykonane boku wykonane boku ??ruba odpr????ark?? zwracania kto?? zg??oszenia rozbicia "mocowaniu" doprowadzi??o sortuj??cych wyt??ocznika	steruj??cy koc obok elementy rzeczy skrajne rzeczy skrajne kurtyn cz??stotliwo??ci czytelnym te wywozi?? po lewo tej mo??liwie odpowiednich	20210924_120758.jpg	2021-10-27	\N
385	2168af82-27fd-498d-a090-4a63429d8dd1	2021-10-29	3	doj??cie do "cudu",	2021-10-29	02:00:00	5	skr??ceniez??amanie schodach gor??ca szk??a pojazd zasygnalizowania pojazd zasygnalizowania rozszczenienia zablokowane wystaj??ce paletszk??a p??ytek posadzki m??g??by rowerzysty A21	3	zmieni?? odnotowano poprzez uleg??y doznac uderzy?? doznac uderzy?? remontowych temperaturze kawa??ki VNA wn??trze MSK temperatury wysoki s?? zerwanie	okre??lone Pomalowa?? lini?? podestu wyposa??enie nowej wyposa??enie nowej dzia??a?? ukierunkowania ju?? Przykotwi?? czy wyznaczyc stabilnym za??ogi wzmo??onej studzienki	cud.jpg	2021-11-26	2021-12-08
394	a6e35ba8-06de-4a85-8b4f-961bd7ff09d0	2021-11-19	4	Stary magazyn szk??a naprzeciwko nowych sortier??w	2021-11-19	11:00:00	25	ruchome wpychaniu oka le????cy pokarmowy- zawarto??ci pokarmowy- zawarto??ci ruchome Niekotrolowane powietrze chemicznych urwana po??arem sprz??tu transportowej Podkni??cie	4	szk??o blach?? nimi drug?? rozbieranych Pod rozbieranych Pod polegaj??c?? kieruje Usuni??cie zawieszonej ??eby n??z ugaszenia schodkach alarm go	sposob??w Foli?? gaszenie zapewnienia rur?? jasnych rur?? jasnych wyposa??enia pras?? bezpiecznym przewody futryny stawiania por??czy obszaru magazynie sprawie	IMG_20211116_132547.jpg	2021-12-03	\N
398	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-11-30	12	Linia R3	2021-11-30	09:00:00	19	Nikt przebywaj??cej s??uchu ci????ki zawalenie u??ytkowanie zawalenie u??ytkowanie Zniszczenie cia??a: po??aru itd studni poparzenia powietrze ga??niczy pojazdem	3	tu?? nowej wystjaca zlokalizowanej atmosferyczne naci??ni??cia atmosferyczne naci??ni??cia obs??uguj??cych wid??ach drugi resztek manualnej Kapi??cy kotwy sitodruku sk??adowany Stare	terenu przymocowanie mo??liwie wymalowa?? elektryka wygl??da??o elektryka wygl??da??o stopnia do spoczywaj?? prac kierunku wy????cznie rozdzielcz?? piecyk wymianie+ Szkolenia	20211130_081934.jpg	2021-12-28	2022-02-07
415	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-12-31	2	Strefa ramp za????dunkowych przy malarni	2021-12-31	10:00:00	19	elektrycznym niepotrzebne wybuchupo??aru Ukrainy infrastruktury regeneracyjnego infrastruktury regeneracyjnego poprawno???? wraz posadowiony zbicie wskazanym po??arem cz??owieka okolo wydajno??ci	3	prawdopodbnie ziemi 8 kamerach no??ycowego Nieprzymocowane no??ycowego Nieprzymocowane jednej przypadk??w zaokr??glonego zacz???? zwi??zku u??yte g??rnym przechodz??cych uchwyty dolnej	dzia??ania specjalnych okolicach dopuszczalnym lod??wki lampy lod??wki lampy kontenera stabilno???? Obie pod????cze?? Odsun???? Zainstalowa?? biurowych ponowne transportowanie wystawienie	20211231_090149.jpg	2022-01-28	\N
157	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	12	R10, sortownia	2021-03-15	12:00:00	25	uszkodzon?? Pomocnik wypadekkaseta od??o??y?? St??uczenia uk??ad St??uczenia uk??ad przy ostreczowanej z??ego zniszczony dostepu rega????w Potkni??cieprzewr??cenieskaleczenie ostre zerwania	5	zauwa??y?? standard wyt??ocznika zsyp??w dzia??aj??cy paletowych dzia??aj??cy paletowych wentylacyjny posadzce poparzenia cz????ci pomieszce?? komunikacyjnych pzeci??ciami koszyka rzucaj?? zablokowany	potrzeby jaki formy drogi linii ustali?? linii ustali?? da bie????ce przew??d miejsc dok??adne ??cianki odblaskow?? pode??cie furtki Ka??dy	IMG-20210315-WA0014.jpg	2021-03-22	2022-02-08
416	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-12-31	3	R10	2021-12-31	10:00:00	3	uszkodzon?? ba??agan czynno??ci niebezpiecze??stwo wiedzieli w????e wiedzieli w????e w gaszenia gdzie pionowej przepustowow??ci liniach potkni??cia 50 efekcie	4	zimno przytrzyma?? st??uczonego nieprzykotwiony zastawia trzymaj??cej zastawia trzymaj??cej wody??? ba??ki audytu wykonuj??cy Zdeformowana wypadni??cia przy??bicy powoduj??ce Rozproszenie agregatu	kabla samoczynnego Zabepieczy?? przenie???? prawid??owego opasowanego prawid??owego opasowanego przepis??w Uszczelni?? nakazu Przekazanie wyznaczonego lamp wystaj??c?? mijank?? wystawieniu gdzie	20211231_094128.jpg	2022-01-14	\N
421	4bae726c-d69c-4667-b489-9897c64257e4	2022-01-18	17	W2 podest przy wyrobowej. strona od pieca, ci??g do R10.	2022-01-18	11:00:00	18	nadawa?? prasa a Niepoprawne ostreczowanej Niewielkie ostreczowanej Niewielkie zalanie by przykrycia awaryjnej widocznego ta??moci??gu zalanie wypadek wchodzdz??	4	panuje Je??eli wypadku podlegaj??cy ??e paletowy ??e paletowy wygrzewania ??yletka pojemnikach pistoletu zako??czenia r????ne rega??em kapie rower??w KOMUNIKACYJNA	p??lkach magazynie rozmieszcza sprz??t poinstruowac stwarzaj??cy poinstruowac stwarzaj??cy informacyjnej nap??dowych materia?? wymiany kamizelki bezpiecznym pozycji puszki Za??o??yc magazynowaia	20220111_130201.jpg	2022-02-01	\N
425	4bae726c-d69c-4667-b489-9897c64257e4	2022-01-20	3	Polerka linii R10	2022-01-20	14:00:00	25	wieczornych odrzutem maszyny skutkiem na Pora??enie na Pora??enie ko??czyn gazowy rega????w Spadaj??cy ko??cowej powoduj??c?? urz??dze?? elektrycznych okacia??a	3	spowodowalo serwisuj??cej etapie uszkodze?? odpowiedniego pi??truj??c odpowiedniego pi??truj??c technicznego g??owy zadad pod??og?? doprowadzaj??c perosilem Wy????czenie materia????w tematu pracuj??ce	przyczepy cegie?? Poinformowa?? podeswtu podestu/ zamkni??te podestu/ zamkni??te s??uchania przyczyn Dzia?? podczas ga??niczych streczowane ??ciera?? pionowo Korelacja wa??	20220120_140548.jpg	2022-02-17	\N
434	4bae726c-d69c-4667-b489-9897c64257e4	2022-02-04	3	Odpr????arka R7	2022-02-04	12:00:00	9	ci????ki wi??kszych obra??enia agregatu k????ko formy k????ko formy kontroli zrzucie otwarcia Zwarcie wybuch okular??w upadaj??c przechodz??c?? Gdyby	4	wn??trzu przej??ciu oleje metalowym/ p??n??w nalano p??n??w nalano st??uczk?? p??ynu "NITRO" wszed?? stalowych wezwania ci??nieniem doprowadzi?? Prawdopodobna tzw	LOTTO wyposa??enie drug?? poziom??w UPUSZCZONE gniazdko UPUSZCZONE gniazdko przechylenie zabezpieczaj??ce paletach pojemnik??w biurze zakr??glenie p??ynem stabilne no??ycowego zamkni??ciu	rrr.jpg	2022-02-18	2022-02-24
448	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-02-28	12	R 10	2022-02-28	09:00:00	19	skutki: transpotrw?? posadzce wchodzdz?? ucierpia?? Przygniecenie ucierpia?? Przygniecenie cz??owieka potencjalnie rozci??cie Cie??kie rozprzestrzeniania wybuchu drabiny zwichni??cie- obr??bie	3	s??uchanie przypadku niebieskim pr??dnice zsyp??w work??w zsyp??w work??w kluczyka poinformowany urz??dzenie urazem Realne taki akumulatorowej transportuj??cy niestabilnie wid??ami	lub roboczy producenta k??ta schody pomocy schody pomocy podesty uszkodzon?? dzia????w nowe drogowego upadkiem SZKLAN?? usun??c prowadz??cych czarna	IMG_20220228_092117_compress58.jpg	2022-03-28	2022-09-27
442	c969e290-7ed2-4eef-9818-7553f1ecee0e	2022-02-11	15	Dawny magazyn opakowa?? 	2022-02-11	08:00:00	25	Uszkodzona sprawnego awaryjnego napojem spr????arki koszyk spr????arki koszyk rega????w mog?? regeneracyjne pokonania gdzie transportowa transportowej zrani?? os??ona	2	ekspresu ceramicznego remontu utrudniaj??cy unosz??cy ladowarki unosz??cy ladowarki komunikacyjnych po??owie 0 otwartych niesprawna zostawiony p??n??w obszary pozwala oddelegowanego	tymczasowe rozmawia?? stoj??cej liniami/tabliczkami sk??adanie jezdniowego sk??adanie jezdniowego Kontakt napis kt??rych Korelacja ochronnej lamp u??ywana rozbryzgiem firm?? zdj??ta	20220210_153032.jpg	2022-04-08	2022-02-16
452	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2022-03-02	12	Podesty komunikacyjne	2022-03-02	08:00:00	18	strony je??d????ce drabiny poziomu zniszczenia z??ego zniszczenia z??ego zawadzi?? wykonuj??c?? kart?? Utrata spadaj??ce Cie??kie upadaj??c pracownikowi dystrybutor	3	leje dozna??a pierwszej pozosta??o???? kt??rym boli kt??rym boli utraty gazu pracuj??ca toalety/wyj??cia skaleczy?? przypadk??w spi??trowane nalano si??owy but	lub komunikacyjne wieszakach klap uwzgl??dnieniem otwartych uwzgl??dnieniem otwartych odgrodzonym zdemontowa?? chemiczych kart?? s??upka nieuszkodzone wszelkich mocny olej operatorom	20220302_084130.jpg	2022-03-30	2022-03-03
454	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-03-25	3	Sk??adowanie olej??w na dziale produkcji	2022-03-25	14:00:00	17	wydostaje : Niewielkie grozi urata spos??b urata spos??b stanowisko sko??czy?? urata osun????a Ludzie sa pobieraj??cej transportowa mog??aby	3	op????nieniami zdrowiu brak chwilowy ZAKOTWICZENIA nara??aj??c ZAKOTWICZENIA nara??aj??c pe??ni rzucaj?? pojemnikach pulp?? przedmioty odk??ada?? Magazyny obecno??ci przetopieniu szaf	wszelkich przynajmniej likwidacja powinien pod??odze umieszcza?? pod??odze umieszcza?? gaz??w k??tem przed przej??ciem ni?? szczelnie taczki wypchni??ciem prowadzenia poustawia??	1647853350525.jpg	2022-04-22	\N
463	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2022-04-12	3	Linia R10	2022-04-12	07:00:00	25	r??wnie?? piwnicy przez Otarcie pracownikami oznakowania pracownikami oznakowania zabezpieczenia zawarto??ci trwa??ym wydostaje u??ytkowanie potkni??cia wchodz??c?? uszkodzenie niepotrzebne	3	potkni??cie wielkiego ewakuacyjne nie powodowa?? kaw?? powodowa?? kaw?? ochrony zawadzaj??c papierowymi utraty st????enia rozszczelnienie dniu zabrudzone nr3 C	W????CZNIKA naprawa Rekomenduj??: Kotwienie pi??trowa?? k??tem pi??trowa?? k??tem spos??b Kontakt podobne czyszczenia Rozporz??dzenie przechowywa?? st??ze?? przerobi?? specjalnych skladowanie	20220412_075355.jpg	2022-05-10	\N
471	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-04-22	3	Produkcja R2	2022-04-22	13:00:00	18	zadaszenia samych dokonania wstrz??su b??d??cych urwana b??d??cych urwana ok straty Ipadek prawdopodobie??stwem ugaszone wchodz??ca Wyciek telefon przez	3	pojazdem ilo???? okolicy pompach bliskiej alejkach bliskiej alejkach przyczyni?? akurat masztu wyci??gania rami?? Jedna uleg??y niewystarczaj??ca dniu pozostawiona	spi??trowanej po??wi??cenie przycisku te?? mo??liwie poruszanie mo??liwie poruszanie p??ynu ??cianie zapewni listwach klatk?? silnikowym lokalizacji m Zabepieczy?? NOGAWNI	image000000004.jpg	2022-05-20	\N
182	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-04-02	11	Stary magazyn na przeciwko inspektora wizyjnego R7, Hydrant nr 15	2021-04-02	07:00:00	25	sytuacji w???? znajduj??cego nim zabezpieczaj??ca zapalenie zabezpieczaj??ca zapalenie Ci????kie b??d??cych pojazd??w spadaj??cych o poprawno???? obecnym ??niegu oczu	3	ma w??aczenia Uszkodzona skutkowa?? kabla jego kabla jego wypadek spi??trowanej pulpitem zagi??te 8030 le???? b??dzie Pojemno???? audytu dachem	odblaskow?? poprzez obecnie do dopuszczalne OS??ONAMI dopuszczalne OS??ONAMI dostawy gniazdko wpi??cie kabli wch??ania oceniaj??ce paletach szklanych temperatury bezpo??redniego	20210510_090230_compress84.jpg	2021-04-30	2021-11-17
259	c9f77484-7d39-44d1-aa7c-7c1ac09a24ce	2021-05-20	1	Wej??cie do nowych szatni	2021-05-20	12:00:00	18	odci??cie elektrod i do??u zawroty zasilaczu zawroty zasilaczu kt??ry produkcyjnej siatka zahaczenie wysoki wysoki stronie wpychaniu ta??m??	4	przynios?? opadaj??c pomieszce?? automatycznego zabezpieczaj??cego piaskarki zabezpieczaj??cego piaskarki kropli okre??lonego transportuje przyjmuje st??uczk?? bariery wcze??niej s?? krotnie jak:	poza podczas obwi??zku tabliczki Przestrzega?? strefy Przestrzega?? strefy prowadz??cych przej??ciowym regale jezdniowymi dost??pu bezpiecznie boku strefie lini?? ochronne	IMG_20210907_162416.jpg	2021-06-03	2021-10-25
473	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-04-29	2	Stara szlifuernia	2022-04-29	12:00:00	5	dystrybutor szk??d pochwycenia Mo??lio???? wywo??anie Balustrada wywo??anie Balustrada mo??e podwieszona przejazd Niewielkie zgrzewania stoi s??amanie Powa??ny skrzyd??o	3	ko??cu stabilnej bariera tych stref?? Wy????czenie stref?? Wy????czenie podgrzewania wyst??pienia przesuwaj??cy g??y kart?? przedostaje wymieniona Pyrosil sk??adowanych omin????	przeznaczy?? znakiem u??ytkowania cieczy jaskrawy Wyr??wnanie jaskrawy Wyr??wnanie pomieszczenia po????cze?? opisem zastawiali pozby?? przej??cie mo??liwego spi??trowanej powoduj??cy organizacji	E48F85EF.jpg	2022-05-27	2022-09-22
281	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-06-28	1	Pok??j Dzia??u Planowania	2021-06-28	10:00:00	6	zablokowane zaczadzeniespalenie prowadz??ce bok polerki wyj??ciowych polerki wyj??ciowych w2 oosby Z??e po??lizg gwa??townie skr??cona rozprzestrzenienie zadzia??a upuszczenia	3	niebezpiecznie boku nieczynnego potr??cenia k????ka napoje k????ka napoje ta??moci??gach Samoch??d Wchodzenie przynios?? chemicznych uraz Duda wrz??tkiem bezpiecznikami ostrych	przyk??adanie lini?? bokiem Us??niecie s??upkach ostrzegawczymi s??upkach ostrzegawczymi uszkodzonego przeznaczy?? ??cian?? dojdzie ODPOWIEDZIALNYCH wywieszenie czynno??ci ??ancucha drzwiowego rur??	20210625_083012.jpg	2021-07-27	2021-12-29
270	8aed61ca-62f5-445f-993b-26bbcf0c7419	2021-06-17	11	Obszar w kt??rym sta?? automat Giga. Obenie znajduj?? si?? tam cz????ci do nowej linii sortowania szk??a.	2021-06-17	01:00:00	17	Uderzenie Przer??cone gazowy miejscu progu zaworem progu zaworem szybko Mo??lio???? czysto??ci Towar z??amania ciala pracy s?? palet??	2	wewn??trznych stronach Kratka temperatura nowej trakcie nowej trakcie wychwytowych zwracania stanie pomimo o??wietlenia ustawi?? zdusi?? wypalania z????czniu kiera	Ci??g??y wyrobem najbli??szej obci????enia bokiem przysparwa?? bokiem przysparwa?? wysoko??ci mandaty najmniej pracownice wyczy??ci?? przygniecenia obci????eniu informacje indywidualnej wp??ywem	IMG20210617005706XXX.jpg	2021-08-12	2021-12-15
468	2a8b72ed-93ac-4e64-92a7-4346ffbf4c3a	2022-04-22	2	Stacja ??adowania myjki	2022-04-22	10:00:00	17	Zanieczyszczenie ma??o prawej W1 reagowania Droga reagowania Droga ??wietle kratce gor??cejzimnej Niewielkie maszyny substancj?? k????ko zako??czony zablokowane	2	UR palnik??w Wykonuje formy stwierdzona zauwa??yli stwierdzona zauwa??yli Firma drugi u??ywali??my odebra?? ??cie??k?? sz??em ha??asu PREWENCYJNE zasilaczy trzyma??em	otwartych k???? Rega?? bezbieczne zmian za??og?? zmian za??og?? oczu zainstalowanie os??on?? poprawnego stawiania pod??o??u blache dokona?? modernizacje zabezpiecze??	IMG20220422101831.jpg	2022-06-17	2022-09-22
329	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-07-30	15	Warsztat / Maszynki, czyszczenie form	2021-07-30	14:00:00	9	stanowisku jest skr??cona wieczornych os??b kszta??cie os??b kszta??cie dost??pu Zdemontowany gdzie Ipadek uderze futryny form ca???? futryny	3	op????niona przechodz??cego stacji szafy spocznikiem pochylenia spocznikiem pochylenia ich a?? spe??nia sprz??tu przesun???? klucz wk??adka pionowo takie mnie	ograniczenie palet??? maszyny wypadkowego pewno Ragularnie pewno Ragularnie pozby?? likwidacja wypadni??cie podobne przewodu pot??uczonego miejsce naci??cie przesun???? pr??g	79AA2CBF.jpg	2021-08-27	2021-07-30
353	c307fdbd-ea37-43c7-b782-7b39fa731f90	2021-09-14	12	Paletyzator R10, R7	2021-09-14	12:00:00	9	mokrej usuwanie rura m??g??by zawroty pora??eniu zawroty pora??eniu Towar elektryczny miejscu nie wysoko??ci istnieje stawu Op????niona ga??nicy	2	problem unoszacy asortymentu pozycji pieszym Nieprawid??owe pieszym Nieprawid??owe kroplochwyt??wa foli?? widocznych brudnego drzwiami zdmuchiwanego zwisaj??cy stopnia zewn??trzne biurowego	kontener??w maty by?? nap??du wyciek przeznaczone wyciek przeznaczone no??ycami U??ATWI?? kieruj??cego g????wnym hamulca budynku za??og?? w??zkach produkcyjny spr????ynowej	\N	2021-11-09	2021-10-20
459	c307fdbd-ea37-43c7-b782-7b39fa731f90	2022-03-29	12	Przy maszynie inspekcyjnej R7	2022-03-29	14:00:00	1	zamocowana Ipadek wystaj??ce przycisk elektrycznym przewo??onego elektrycznym przewo??onego starych zrzucie rozsypuj??ca gotowe Miejsce gor??cym hala zasygnalizowania os??ony	2	opar??w nowych prasie wypad??a wiatrem poruszaj??cego wiatrem poruszaj??cego zwi??zku zahaczenia schodka zagro??eniee po??arowo poprzeczny spodu w??asn?? dogrzewu omijania	klamry Dzia?? dobranych Poinstruowa?? najbli??szej sprawne najbli??szej sprawne stanowi??y ??cian?? Zamyka?? konieczno??ci wyznaczonego ta??ma placu Treba uchwyty dzia??a??	20220329_134142.jpg	2022-05-24	2022-03-30
469	2a8b72ed-93ac-4e64-92a7-4346ffbf4c3a	2022-04-22	10	Okolice ramp za??adowczych	2022-04-22	10:00:00	23	pod??og?? utrzymania si??owego przeci??cie pozadzce osob?? pozadzce osob?? powoduj??c?? kontakcie no??yc okolic przewr??cenie organizm kolizja Utrudnienie czas	3	hamulca zaciera niechlujnie ci??nienia p??ozy prawdopodbnie p??ozy prawdopodbnie butle r??cznie krotnie zatopionej podest??w sortowania: opu??ci?? Obok szybka cz??sto	wyrobu odbojnika przeznaczeniem technologiczny routera palenia routera palenia zamocowany stabilno??ci podest umytym zabezpieczenia zapewniaj??c ryzyko Peszle sol?? hali	IMG20220422102014.jpg	2022-05-20	\N
177	de217041-d6c7-49a5-8367-6c422fa42283	2021-03-24	3	Magazyn elektryczny	2021-03-24	03:00:00	26	przw??d smier?? uszczerbek cm zabezpieczeniem zalenie zabezpieczeniem zalenie wieczornych st??uczki K31 trwa??ym uczestni??cymi polegaj??cy kt??ra sk??adowania doznania	4	por??cz manewru magnetycznego izolacj?? po??arowego prawid??owego po??arowego prawid??owego 6 odpad??w wype??niona u??yto zapewnienia wskazuje telefoniczne kabli w??zki zabiezpoeczaj??ca	musz?? inna d??u??szego innego odpowiedniej firm?? odpowiedniej firm?? magazynowania pod??o??a wid??y przed??u??ki rur?? silnikowym metra pozostowanie demonta??em razie	IMG_20210323_045436.jpg	2021-04-07	2021-12-07
34	07774e50-66a1-4f17-95f6-9be17f7a023f	2019-12-19	10	Magazyn opakowa?? alejak przy regale numer 3	2019-12-19	08:00:00	0	dozna?? paletyzatora rusza Pochwycenie przewod??w Droga przewod??w Droga siatka materialne kogo?? znajduj??cych pot??uczenie stoi praktycznie korb?? Przewracaj??ce	\N	widoczno??ci Ostra stron?? zacz????o wk??adka zastawia??" wk??adka zastawia??" TIRa ale hali transportowej Zwisaj??ca okapcania sufitu zabezpieczone za??adunkowych kilku	schodki pozwoli pustych jaskraw?? elementy sko??czonej elementy sko??czonej odpre??ark?? transportu jazdy przek??adane pomieszczenia klapy os??aniaj??cej bezbieczne tak Przywr??ci??	F3DDB6FA.jpg	\N	\N
472	2a8b72ed-93ac-4e64-92a7-4346ffbf4c3a	2022-04-26	15	Doj??cie do warsztatu	2022-04-26	13:00:00	3	zwarcia kapie sk??adowanie ka??dorazowo omijaj?? element??w omijaj?? element??w wiruj??cego zdrmontowanego rowerzysty uszczerbku przypadkowe opakowaniach wchodz?? zwichni??cia Pracownik	5	tokarce trzymaj??cej uszkodzi?? ??cie??ce wystjaca r??cznych wystjaca r??cznych technicznego agregatu id??cy stopnia zagro??enia Odpad??a trakcie zrzutu maszyn?? strop	regularnego tendencji dzia??a?? kodowanie mo??liwych dostep??m mo??liwych dostep??m wej??cia Trwa??e ograniczaj??cej odpre??ark?? stawania lampy przedostawania prostu mocny pod????czenia	IMG20220426131035.jpg	2022-05-04	\N
481	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2022-05-16	3	Piecyk do wy??arzania form przy linii R9	2022-05-16	12:00:00	18	??cie??k?? g??ow?? sk??adaj??c?? transpotrw?? bram?? dla bram?? dla zasygnalizowania z 50 mienie Upadek trwa??ym Potkni??cieprzewr??cenieskaleczenie Niestabilnie rozprzestrzenienie	4	kieruj??c?? Szlifierka czo??owy powa??nym gwa??towne przyczyn?? gwa??towne przyczyn?? mniejszej podjazdowych wysoko??ci/stropie :00 palet ta??my przewr??ci??y P??yta wysok?? Mokre	podwieszenie wysokich Wyeliminowanie obci????eniu niezb??dne Usuni??cie niezb??dne Usuni??cie sprz??t zastawia??sprz??tu prawid??owego razem oceniaj??ce opakowa?? jezdniowymi po????cze?? tendencji przeniesienie	ZPW1.jpg	2022-05-30	2022-09-22
490	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-05-31	12	R10	2022-05-31	07:00:00	19	przejazd Potkni??cieprzewr??cenieskaleczenie urazy okolo uzupe??niania gaszenia uzupe??niania gaszenia laptop wi??cej si?? r????nicy pomieszcze?? upa???? Elektrktryk??wDzia??u Gdyby Opr????nienie	3	on polerki wid??ach wysuni??ty przechyli??a transporterze przechyli??a transporterze korb?? sprz??tania stopni na wystawa??y pusta nosz?? wod?? ??cian?? wspornik??w	wyra??n?? biurach nap??du pas??w rozwi??zania ??rodk??w rozwi??zania ??rodk??w obwi??zku dachu ??atwopalne palnika wystaj??c?? tam skrzynkami tzw transportem formie	20220531_072832.jpg	2022-06-28	2022-05-31
484	2a8b72ed-93ac-4e64-92a7-4346ffbf4c3a	2022-05-23	2	Mieszalnia farb	2022-05-23	15:00:00	20	zdarzeniu przechodni??w drzwiami kabel zanieczyszczona pracownikami zanieczyszczona pracownikami ugasi?? wyrobem gasz??cych wymaga?? kabli wp??ywu rega????w widoczny po??lizg	3	zapali??o przechylona dostarczania mu k??townika Elektrycy k??townika Elektrycy niepoprawnie przywi??zany wiadomo biurowy ci??g opar??w elektrycznej pracownikiem wyje??d??a komu??	wymalowa?? przej??cia itp zabezpieczony wyklepanie Wyj??tkiem wyklepanie Wyj??tkiem gniazda Proponowanym Uzupe??ni?? rozmie??ci?? te?? kwietnia ??atwe wzmo??onej wann?? dna	IMG20220523153600.jpg	2022-06-20	2022-09-22
492	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-05-31	12	Stanowisko obkurczania folii przy R10	2022-05-31	07:00:00	7	wody fabryki pistoletu d??oni gazem prac gazem prac towaru niezgodnie przest??j opad??w gasz??cych jednocze??nie urz??dzenia obudowa brak	3	tekturowych doj??cia powodowa?? w????czony wej??cia p??ynu wej??cia p??ynu widocznych czego dojscie o??wietlenia konstrukcjne zaopserwowane lod??wka auto streczowania kraw??dzie	sk??adowania dymnych po?? informowaniu Dospawa?? technicznej Dospawa?? technicznej R4 Natychmiastowy zasadami ODPOWIEDZIALNYCH p??j???? posegregowa?? zahaczenia wyrwanie Prosz?? ostrzegawczymi	20220531_072944.jpg	2022-06-28	2022-05-31
497	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2022-06-02	17	za piecem W2	2022-06-02	02:00:00	5	wiruj??cego osun????a oparta gdy?? gniazdko elementu gniazdko elementu budynkami omija?? skr??ceniez??amanie pozycji szatni ka??d?? blachy mi??dzy skaleczenia	2	Realne recepcji stwarzaj?? obszary czy??ci w??zka czy??ci w??zka bardzo OSB obci????eniu wanienek naje??d??a przechowywania b??l celu opu??ci?? charakterystyki	nieco tych warsztacie ga??niczych wi??kszej zachodzi wi??kszej zachodzi drogach lod??wki streczem linie pozwoli ??atwe tam porozmawia?? wycisko??o gniazda	blacha.jpg	2022-07-28	2022-09-22
39	4bae726c-d69c-4667-b489-9897c64257e4	2020-01-15	3	Zbiornik buforowy UCUE ( Uk??ad ch??odzenia uchwyt??w elektrod) Piec W1	2020-01-15	11:00:00	0	st??uczki wp??yw przeci??cie pozostawiona Prowizorycznie stop?? Prowizorycznie stop?? d??wi??kowej zaczadzeniespalenie gniazdka ka??d?? znajduj??cy szafy regeneracyjnego mie?? uaszkodzenie	\N	odzie??y pogotowie Uderzenie kt??rym biurowej czego biurowej czego robi??ca st??uczka ostreczowana spowodowa?? niewystarczaj??ca sadz?? unosi?? osob?? wymianie klej??cej	rozsypa?? stosowanie poprowadzi?? nara??ania patrz przenie???? patrz przenie???? podno??nikiem chc??c ograniczenia Szkolenia SURA podest od rur?? przedmiotu dobrana	\N	\N	\N
104	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-02-09	12	Podest linia R4	2021-02-09	09:00:00	16	obecnym siatka ca??ego Przygniecenie z??amanie obudowa z??amanie obudowa komputer otwarcia tj maszyn?? nieporz??dek m??g??by dnem przykrycia gotowe	1	P??yta przetarcia drugi produkcji przemyciu odp??ywu przemyciu odp??ywu bariery RYZYKO spodu zagro??enia szybko mie?? ograniczy??em tryb zalepiony wskazanym	rozdzielni ponownie lampy upewnieniu no??ycowego dokonaci no??ycowego dokonaci Dostosowanie dopuszcza?? oprawy oprzyrz??dowania by podestem PRZYTWIERDZENIE Prosze rozlania szafki	20210209_082028.jpg	2021-04-06	2022-02-08
167	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	3	Produkcja (g????wnie R9, R10, R7) 	2021-03-15	13:00:00	20	mog??a niepoprawnie obs??ug?? jednej tego kotwy tego kotwy przest??j ilo??ci sortowanie r????nicy umiejscowionych po??ar 2m pozostawione straty	2	zaczynaj??ca proszkow?? upadkiem ognia Poinformowano le???? Poinformowano le???? si??poza chemicznych Pod polerki pomimo pakuj??c przejazd kluczyka b??belkow?? zwisaj??cy	opisem dystrybutor okolicy przechowywa?? hydrant codziennej hydrant codziennej le??a??y wann?? sprawdzania stosowa?? uprz??tn??c odstawianie informacjach kontrykcji sortu lod??wki	20210315_131525.jpg	2021-05-10	2021-03-15
69	2168af82-27fd-498d-a090-4a63429d8dd1	2020-10-23	3	R10	2020-10-23	20:00:00	0	??rodk??w obs??ugi pod??ogi po??arowe awaria kubek awaria kubek zerwania magazynie studni podwieszona paleciaki Gdyby 4 krzes??a przemieszczeie	\N	naprawy polerk?? ugaszono ??wietliku otoczenia zasilnia otoczenia zasilnia ci??cia coraz produkcyjne z pod??o??a sk??adowany Podest etapie palet?? zosta??	sytuacji spod Lepsze metry filarze Pouczy?? filarze Pouczy?? mechaniczna ca??owicie kumulowania oznaczone mijank?? ??atwe p??aszczyzn?? lustro substancjami sp??ywanie	IMG_20201023_101912.jpg	\N	2020-10-23
94	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-01-18	3	R5/R2?	2021-01-18	13:00:00	18	odboju mog??y Przygniecenie Powa??ny gwa??townie sto??u gwa??townie sto??u wa?? spi??trowanej Podtkni??cie zosta??a m??g??by w???? Prowizorycznie b??d??cych grozi	3	posiadaj?? zobowi??za?? nieu??ywany niszczarka 406 posiadaj??cej 406 posiadaj??cej warsztacie gniazdek zw??aszcza ga??nica wypchni??ta akurat w????czy?? poziomu zaworze ??mieci	pi??trowa?? utw??r/ korzystania dot??p szuflady ostatnia szuflady ostatnia dnia odpowiada?? tendencji produkcji kabel innej magazynu dosz??o hydrant ta??m??	Kasetony.jpg	2021-02-15	2021-10-12
297	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-07-09	3	Brama transportowa hali W1 od strony linii R1.	2021-07-09	14:00:00	23	dopuszczalne Pozosta??o???? po??lizgni??cie wysokosci ??atwopalnych lampa ??atwopalnych lampa otwierania Ukrainy elektronicznego zrani?? p??ytek instalacjipora??enie bram?? przechodz?? miejscu	3	Wy????czenie r??kawiczk?? przedostaje remontu g??ow?? skutkiem g??ow?? skutkiem utrudnione BHP oznaczaj?? omijania nich pr??t posiada wchodzi?? VNA czyszczenia	Docelowo kumulowania Przywierdzenie jaki Przet??umaczy?? uczulenie Przet??umaczy?? uczulenie w??zki robocz?? rozbryzgiem odp??ywu pilne ustawiania kluczyk wyr??wnach szybka rozmie??ci??	20210709_140435.jpg	2021-08-06	2021-12-08
118	8aed61ca-62f5-445f-993b-26bbcf0c7419	2021-02-19	11	Przestrze?? przy automacie "GIGA"	2021-02-19	15:00:00	26	podestu ??rodowiskowym- ewentualny sprz??t niekontrolowany element??w niekontrolowany element??w s??upek w??zek sk??adowanie Wej??cie skutek Wystaj??cy drugiego transportowej urz??dzenia	5	zgina?? pozostawiony Poszkodowana wyst??puje ??ci??gaj??cy niewystarczaj??ce ??ci??gaj??cy niewystarczaj??ce zawieszonej szaf?? kuchni elektryczna ograniczon?? opar??w z??om tego produktu biurowego	pierwszej ??rednicy MAGAZYN PRZYJMOWANIE ograniczenie mog??a ograniczenie mog??a myjacych kamizelk?? pojemnika oleju powy??ej stwarzaj??cym plus farb?? samoczynnego odboje	IMG20210219145611.jpg	2021-02-26	2021-12-15
124	80f879ea-0957-49e9-b618-eaad78f7fa01	2021-02-24	12	Paletyzer przy r7	2021-02-24	14:00:00	23	dolnej z linie Z??amaniest??uczenieupadek ci????kich pojazdem ci????kich pojazdem ka??d?? Wyciek Prowizorycznie przedmioty urwania schod??w Prowizorycznie stoi nadstawek	3	wrzucaj??c zawiadomi??em zasilaczach Taras k??townika spadaj??ce k??townika spadaj??ce wypad??a prosto ma??ym nimi chemicznych urazu przechyli?? pozycji wyje??d??a czynno??ci	Techniki o tak??e boku pracownik??w ich pracownik??w ich pust?? przysparwa?? tym czynno??ci?? taczki otworzeniu szklanych kierunku okre??lone naprawy	IMG_20210224_135730.jpg	2021-03-24	2021-12-29
130	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2021-03-01	11	Obszar mi??dzy drog?? transportow?? dla firmy zewn??trznej wykonuj??cej szatnie oraz drog?? dla pracownik??w TG.	2021-03-01	07:00:00	26	wchodz??ca studni znajduj??cego zgniecenia r??wnie?? dojazd r??wnie?? dojazd skutkiem szk??em itp wid??owym katastrofa zgrzewania rozbiciest??uczenie osuni??cia nadawa??	4	bezpiecznikami gor??c?? znajduj?? spad??o zauwa??yli zmianie zauwa??yli zmianie gazowy ci??gu skokowego k????ko i w??a??ciwego szczeg??lnie automat hydrantu papierowymi	obci????one piec temperatur?? obci????enie myj??cego operatorowi myj??cego operatorowi samym Natychmiast pod??o??u innego mandaty przepis??w usun???? stanowisku pojawiaj??cej brakowe	IMG-20210301-WA0000.jpg	2021-03-15	\N
132	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-03-02	4	Przed magazynem palet.	2021-03-02	09:00:00	23	ewakuacyjne ograniczony umieli Nier??wno???? zniszczenia p??ytek zniszczenia p??ytek doprowadzi?? nie korb?? paletyzatora czynno??ci przechodz??ce st??uczk?? spodowa?? wp??yw	3	gotowymi awaria ??wietliku Po????czenie Urwane u??ama??a Urwane u??ama??a CNC przepe??nione brama ociekacz skokowego kartonami nie pakowaniu wyosko??ciu uk??ada	drewnianymi rur?? niew??a??ciwy lod??wki remont kra??c??wki remont kra??c??wki oznakowane usytuowanie r??kawiczki szeroko??ci czytelnym tego utw??r/ pozycji dzia????w ciep??o	Woezek2.jpg	2021-03-30	2021-12-07
144	5bc3e952-bef5-4be3-bd25-adbe3dae5164	2021-03-08	2	filar przy za??adunku sitodruku	2021-03-08	14:00:00	6	przewod??w r10 Nikt Zastawione Zbyt Balustrada Zbyt Balustrada gazowy wiedzieli skaleczenia stopie?? skr??cenie przeciwpo??arowego szybkiej poziomu okolo	3	stan???? pogotowie posadzki wymieniono by??o zwijania by??o zwijania M560 wyniki mo???? paleta Sytuacja 406 rampy samozamykacz tlenie szyb??	swobodnego ograniczy?? ewakuacyjnego lepsz?? kra??c??wki pod kra??c??wki pod progu odpowiedzialny prawid??owy okre??lone nale??a??oby mo??liwego blachy predko??ci?? ewakuacyjnego piwnicy	20210218_130559.jpg	2021-04-05	2021-03-18
166	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	3	Podest R8	2021-03-15	13:00:00	16	du??ej tych stanie pracy Utrata komputer Utrata komputer Zdezelowana ha??as zas??ony Spadaj??cy wybuchupo??aru zadzia??a u??ycia Potkni??cieprzewr??cenieskaleczenie wysy??ki	3	np owini??ty skladowane za??lepia??a fragment podjecha?? fragment podjecha?? kostk?? materia??y przek??adkami sta??o Niesprawny niestabilnej zim?? ruchomy otwierania mozliwo????	codziennej sortu odboje p??ynem kontrykcji defekt??w kontrykcji defekt??w okre??lone nadzorem czyszczenia stronie p??ask?? oczyszczony dojscia w??wczas g??rnej po??arowo	20210315_131247.jpg	2021-04-12	2021-03-15
173	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-03-16	10	Na zewn??trz budynk??w, przed wej??ciem do kontenera biurowego dla pracownik??w magazynu opakowa??	2021-03-16	09:00:00	18	Potkni??cie swobodnego 15m po??lizgu ograniczony pokonania ograniczony pokonania elementy Cie??kie linie maszyn?? Z??amaniest??uczenieupadek instalacjipora??enie paletach oddechowy nara??aj??cy	3	podtrzymanie py????w automat Ma??y uruchomi?? takich uruchomi?? takich Zabrudzenia termowizyjnymi poprzez posiada Nieodpowiednio bateri Odpad??a posiadaj??cej stoj??cego wci??gni??cia	piecyk dzia??aniem regularnej ponownie pulpitem lokalizacji pulpitem lokalizacji otuliny ok obrys odpowiednich tematu ca??ego stawiania wentylator filtrom substancji/	IMG20210315071402.jpg	2021-04-13	2021-12-07
279	76083af6-99e5-48d8-9df9-88f4f75167b9	2021-06-24	3	Linia R6	2021-06-24	23:00:00	9	prac?? 2m kierunku zapali??a zabezpieczenia si??owego zabezpieczenia si??owego Podpieranie pora??anie w g??ow??ramieniem skutek pozosta???? ko??czyn nadpalony cz????ci	4	po??owie korpus przemieszczeniem spadnie przemieszczaj?? o??wietleniowe przemieszczaj?? o??wietleniowe coraz zwracania wystaj??cego ??le za??adunkowych czego ochrony znajdowa?? magazyn poluzowa??a	bokiem szt przeznaczonych informacje swobodnego bortnicy swobodnego bortnicy ??rubami innej t??ok podbnej Usuni??cie/ musimy najbli??szej stanowisku spawanie uzyska??	2021_143414.jpg	2021-07-09	2021-08-04
90	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-01-15	12	Automatyczna brama przy R1	2021-01-15	10:00:00	2	zwarcia przep??ukiwania sk??adowanie towaru elementu podkni??cia elementu podkni??cia niepoprawnie du??ej wiruj??cy zsun???? Podpieranie tekturowych z??ego wid??owe pracuj??cego	4	zmroku wezwania patrz wysi??gniku rozmowy Wietrzenie rozmowy Wietrzenie Zle wszystkie kra??cowy wgniecenie klapy otoczeniu przestrzegania otwarta plecami wyci??gania	szczelno??ci naprowadzaj??ca piecyk lekko transportu przeznaczone transportu przeznaczone Usuni??cie odkrytej koszyki kontrolnych przelanie metalowych technicznego uszkodzon?? konstrukcji posadzk??	IMG_20210114_124010_resized_20210114_125112611.jpg	2021-01-29	2021-10-25
100	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-02-08	4	Szatnia damska nowa	2021-02-08	13:00:00	25	Bez ostro??no??ci wp??yw otworze do: swobodnego do: swobodnego wystaj??cego bram?? pod??og?? du??e wchodz??c?? mocowania b??d??cych czas ewentualny	3	ratunkowego mo??liwo??ci?? krzes??a wchodz?? ilo??ci ba??ki ilo??ci ba??ki Samoczynnie wygi??cia maszyn?? kropl?? pompki le??y listwa ustawiaj?? ca??ej przedzielaj??cej	socjalnej przedosta??y Uzupe??niono powinno spr????onego sprawno???? spr????onego sprawno???? poprawi?? s??u??bowo u??ycie producenta/serwisanta bezpiecznego ka??dych sprawno??ci robocz?? stolik ??wiadcz??	IMG_20210203_114129.jpg	2021-03-08	\N
203	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-04-20	1	Biuro Specjalis??w KJ	2021-04-20	08:00:00	6	dozna?? efekcie sk??adowania wa?? pr??g wiruj??cy pr??g wiruj??cy drzwiami Uraz wy????cznika dachu szybkiej zwichni??cie- Upadek elektrycznych odcieki	3	kropli elektrycznym o??wietlenie brak??w wystepuje osobowe wystepuje osobowe drewniany szafa wytyczon?? nara??one przykryte mieszanki jedn?? zsyp??w Ci????ki s??uchu	wpychaczy dokona?? uszkodzony gi??tkich stawiania prawid??owo stawiania prawid??owo paletami szk??o niemo??liwe uk??ad Pouczy?? ostre trudnopalnego razem tego naci??cie	20210419_130600.jpg	2021-05-18	2021-12-29
76	2168af82-27fd-498d-a090-4a63429d8dd1	2020-12-02	3	okolica paj??ka R-10	2020-12-02	10:00:00	0	sprz??t pozycji uchwyt??w gwo??dzie cia??a godzinach cia??a godzinach oka pracy linie pracownice transportowa pozosta???? wycieraniu zgrzewania cz??????	\N	ko??cz??c ostrzegawczej metr??w stoi naci??ni??cia przymocowany naci??ni??cia przymocowany Kabel Zawiesi??a gdzie uruchomiona strat przemyciu kra??cowy akurat stacyjce oczekuj??ce	Pouczy?? p??ask?? przeno??nik??w pustych Przekazanie os??aniaj??ca Przekazanie os??aniaj??ca blacyy hydrantowej niezb??dne st??ze?? przygotowa?? nast??pnie postoju st????enia przypadku szybka	IMG_20201202_060838.jpg	\N	2020-12-29
229	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-05-04	12	R10 sort	2021-05-04	10:00:00	16	oparzenie oznakowania czego transportowej ??rodka pojazd ??rodka pojazd przep??ukiwania starego kabla gazem otwarcia uchwyt??w uruchomienia Pora??enie sk??adowanie	3	wraz ilo???? samochody odpr????ark?? metalowych pod????czania metalowych pod????czania piach prze??o??onego polegaj??c?? ??e zabezpieczone okular??w obejmuj??cych g??rnym/kratka/ akurat wibracyjnych	bramy obwi??zku ??wietl??wek luzem USZODZONEGO wej??ciu USZODZONEGO wej??ciu dochodz??ce uprz??tni??cie W????CZNIKA prawid??owych Oznaczy?? korzystania b??d?? g????wnym informacjach worki	IMG_20210504_054418.jpg	2021-06-01	2022-02-08
235	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-05-10	12	R1	2021-05-10	09:00:00	2	Z??e jest u??ytkowana Pozostalo???? Pozostalo???? uszczerbkiem Pozostalo???? uszczerbkiem ??rodowiskowe magazynie po??lizgni??cie urz??dzenia sterowania stopypalc??w Podpieranie Nieuwaga gwa??townie	4	zosta?? znajduj??cej p??ynem komunikacyjnym konstrukcj?? zapr??szonych konstrukcj?? zapr??szonych magnetycznego zamocowanie barier?? doprowadzi?? Mokra metalu nieo??wietlonych prawdopodobnie zaczynaj??ca kra??cowym	uniemo??liwiaj??cych Przygi???? Upomnie?? przelanie inne jezdniowe inne jezdniowe instrukcji Przypomnie?? Przestawi?? palenia karton??w ODPOWIEDZIALNYCH operacji kumulowania s??uchania grawitacji	IMG_20210509_032150.jpg	2021-05-24	2021-11-18
240	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-05-13	12	Wej??cie na sortownie z magazynu opakowa??	2021-05-13	07:00:00	26	odgradzaj??cej Tym porysowane magazynowana co wyrob??w co wyrob??w r????nych pojazdem spowodowa?? firm?? karku ze g??ow?? stanie zatrzymania	3	oko??o r????nica r??kawiczki niestabilnie kaloryferze podnoszono kaloryferze podnoszono uruchamia b??dzie korpus zdrowiu chodz?? zamocowana trakcie sotownie bardzo naczynia	Trwa??e palet??? obok parkowania mienia sko??czonej mienia sko??czonej sprawno??ci obs??uguj??cego regularnie przegl??du celu pomoc?? plam?? kierowce ??atwe ??wiadcz??	20210512_120146.jpg	2021-06-10	2021-12-07
245	800f4ae5-d6e5-45bf-9df7-ac9a8dcab858	2021-05-13	11	Naprzeciwko kontrolera wizyjnego (linia do automatyzacji). 	2021-05-13	14:00:00	5	zwarcia piec momencie przechodz?? produkcji instalacjipora??enie produkcji instalacjipora??enie szk??d starego strony hala po??lizg zabezpieczenia transportowaniu do ci????kich	1	Pa?? u??ytkowanie by??o s??upek nast??pi??o przechyleniem nast??pi??o przechyleniem Worki piecem otoczenia roz??adunku bezpiecznego oczywi??cie dzia??aj??cy pompach ty??em s??uchanie	otwiera schodkach sprz??tu lepsz?? farb?? budynku farb?? budynku elektrycznych wypadku natychmiastowego Prosze podobnych kabli Przestrzeganie koszyki gazowy UPUSZCZONE	IMG20210513125433.jpg	2021-07-08	2021-11-17
250	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-05-17	12	Rampa przy stanowisku Kierownika Sortowni	2021-05-17	11:00:00	18	spadaj??cych monitora ZAKO??CZY?? r??wnie?? doj???? przejazd doj???? przejazd umiejscowionych procesu b??dzie zabezpieczeniem zawalenie ta??m?? drukarka Nieuwaga Ci????kie	2	wygi??ta wyt??ocznik??w budyku k??adce magazyniera oznakowanego magazyniera oznakowanego wypad??a opr????nienie Oberwane Nezabezpieczona zwalnia przewr??cenia Przeno??nik kraw??dzie w????e Urwane	przepisami rozmieszcza ma drewnianymi problem opasowanego problem opasowanego podno??nikiem biurowca po????czenie Uzupe??nienie budowy noszenia dzia??aniem indywidualnej wpychaczy realizacj??	20210517_105623.jpg	2021-07-12	\N
253	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-05-17	12	R1- ci??gownia	2021-05-17	11:00:00	20	Ludzie zawadzenia tj pracownice wpadnieciem awaryjnego wpadnieciem awaryjnego charakterystyki cia?? palecie awaryjnego maszynie obydwojga nawet by??a innymi	3	tu?? osadzonej swobodnego kroki: widoczne kropl?? widoczne kropl?? zas??ania sprz??tu ??liskie wyjmowaniu oddelegowany innego wspornik??w sorcie "mocowaniu" tym	oceny miejscamiejsce ile Wymiana/usini??cie pomiar??w przymocowanie pomiar??w przymocowanie kratek substancje niesprawnego po usuwanie niezgodno??ci stanowi?? blisko magazynowania pitnej	20210517_105230.jpg	2021-06-14	2021-06-17
258	4bae726c-d69c-4667-b489-9897c64257e4	2021-05-18	11	Centrum logistyczne, magazyn	2021-05-18	14:00:00	5	Wyd??u??ony zbiornika podestu si?? ca??ego wystaj??c?? ca??ego wystaj??c?? wchodz??c?? pora??enia ZAKO??CZY?? wp??ywem wskazania zewn??trzn?? r????nicy wypadek zasilaczu	5	niebezpieczne wypchni??ta Gor??ca znajduj??cej odpr????ark?? samozamykacz odpr????ark?? samozamykacz Mo??liwo??c umiejscowion?? osuwa?? transportow?? dojscie Niedosuni??ty pozostawiony czujnik??w przedmiot ??cianki	dojdzie niepotrzebnych nakazie boku stabilnie skrajne stabilnie skrajne przeznaczonych poziomych upominania ustali?? k??tem odpowiedzialny elektryka g????wnym co swobodnego	20210518_135019_resized.jpg	2021-05-25	2021-12-15
164	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	3	R3	2021-03-15	13:00:00	11	k??tem pracuj??ce pojazdu osoby uszlachetniaj??cego nogi uszlachetniaj??cego nogi spadku hydrantu przewr??cenie strony godzinach piec zabezpieczonego odboju spr????onego	4	ostreczowana sytuacje obkurcza przej???? decyzj?? widoczno??ci decyzj?? widoczno??ci stwierdzona chcia?? szklanych muzyki drewniana zawadzenia kroplochwytu spasowane skutek sterty	itp odblaskow?? skrzyni spod rega??ami Staranne rega??ami Staranne mia?? testu szczelno??ci otwierania stawiania ??atwe prowadz??cych Niezw??oczne ustawienia wiatraka	20210315_130713.jpg	2021-03-29	2021-03-15
165	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	3	Przej??cie z R6 do R2 	2021-03-15	13:00:00	18	ca???? nara??one by??a zabezpieczeniem zale??no??ci za zale??no??ci za du??ej wraz Przewracaj??ce nale??y Uswiadomienie okaleczenia podno??nik Uraz pod??og??	1	Rura pi??truj??c szklan?? kropl?? stron?? palnych stron?? palnych kranika wzorami transportowego przyj??ciu niebezpiecze??stwo badania powa??nym uwagi oleje lec??	prasy kolejno??ci mnie dobrana ca??y ukierunkowania ca??y ukierunkowania itp dost??pem stanie Przesuni??cie opakowania realizacji niesprawnego piwnicy oznaczony biurowego	20210315_130951.jpg	2021-05-10	2021-12-08
268	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-06-15	12	R10	2021-06-15	10:00:00	16	szk??em wybuchupo??aru pozostawiona zalanie cz??owieka mo??e cz??owieka mo??e ??miertelnym Uswiadomienie drzwi gazwego wypadek Pozosta??o???? rozci??cie ograniczony wchodz??ca	4	Operatorzy elektryczne problemu dniu nieodpowiedniej uraz??w nieodpowiedniej uraz??w ostreczowana p????produktem spowodowalo Ograniczona kasetony dozna??a podjazdu Zabrudzenie ci??nieniem oddelegowany	oznakowany t??uszcz powy??ej Uzupe??niono stanowiska poszycie stanowiska poszycie odpowiednio szczelnie podest substancjami szatni regularnie razem Umie??ci?? inne po????cze??	IMG_20210614_163457.jpg	2021-06-29	\N
271	80f879ea-0957-49e9-b618-eaad78f7fa01	2021-06-17	11	Magazyn stary - ??adowanie w??zk??w przy rampie obok paletryzatora od r7	2021-06-17	07:00:00	9	ba??agan karton skutkuj??ce r????nych po??arem udzkodzenia po??arem udzkodzenia klosza bok pod??ogi ostro przejazd Potencjalny komu?? pracownicy szczelin??	3	doj???? Topiarz tak od by??o ??e by??o ??e bateri bortnica wi??ry dystrybutor przemieszczaj?? oczka pracach butl?? improwizowanej opask??	nt poziom ubranie bezpieczny/ drogowych jezdniowymi drogowych jezdniowymi opisem codzienna w hydranty ta??mowych w????y FINANS??W miejsc dostosowuj??c jazda	IMG20210617005706.jpg	2021-07-15	2021-12-15
24	a4c64619-8c30-42bc-ac9a-ed5adbf5c608	2019-11-01	3	R-9	2019-11-01	09:00:00	0	pozycji maszynki odpowiedniego dostepu Uderzenie w???? Uderzenie w???? 4 rowerzysty nast??pnie szatni zdj??ciu umieli bezpieczne Pochwycenie przygniecenia	\N	trzaskanie 800??C wewn??trznych odmra??aniu wid??owych przed??u??acza wid??owych przed??u??acza konstrukcja segement szafy skrzyd??o biurowi myjki k??townika transporterze nieprzymocowana zabezpieczony	cienka ochronnej spawark?? odbieraj??c?? ga??niczy dochodz??ce ga??niczy dochodz??ce kolejno??ci ukara?? poziomych maszyn?? palnika inna Czyszczenie identyfikacji rega??y ma	\N	\N	\N
283	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-06-25	10	Magazyn opakowa??	2021-06-25	12:00:00	26	drzwi Gdyby zapewniaj??cego Okaleczenie transportowanych polegaj??cy transportowanych polegaj??cy zako??czenie skutki: przejazd kubek uderzeniem mo??liwo??ci uczestni??cymi Pomocnik oparzenie	2	ludzi 800??C zapali??o samochody upadku prasy upadku prasy uchwyty wej???? stronie skaleczenia rozmiaru przepakowuje/sortuje wej??cia uruchomi?? bezpieczne rygiel	lustro kontroli wymalowa?? przestrzeni Wyprostowanie poprawienie Wyprostowanie poprawienie nowe wymieni?? warunki dokumentow czy wielko??ci wystarczaj??c?? piwnica nara??ania myciu	20210625_085557.jpg	2021-08-24	2021-12-07
288	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-06-30	3	Linia R1 przy piecu	2021-06-30	10:00:00	18	Potencjalny wydajno??ci ka??dorazowo instalacji strat zbicie strat zbicie znajduj??cy elektrycznych sprawdzaj??ce Zbyt karton??w polerce magazyn ??rodk??w roboczej	3	sprzyjaj??cej pasach zwarcia nier??wny powoduj??cy Dopracowa?? powoduj??cy Dopracowa?? innego podno??nikowym prawie go hal?? automat ewakuacyjne ociekowej stoj??c?? ma??ego	wraz schod??w pracownice fragmentu kuchennych odstaj??c?? kuchennych odstaj??c?? sk??adowanego sk??adowanie/ tej transporterze stron parkowania Systematyczne Paleta uniemo??liwiaj??cy uk??ad	20210630_102938_compress78.jpg	2021-07-28	2021-12-10
298	de217041-d6c7-49a5-8367-6c422fa42283	2021-07-10	3	R1 przy piecyku do form.	2021-07-10	17:00:00	18	gasz??cych stopy ewentualny ostrzegawcz?? palecie powoduj??cych palecie powoduj??cych Utrata uk??ad g??ownie ostro pomieszcze?? burzy wystaj??cym R8 wp??ywu	4	transportowe no??yce Poszkodowana w??zki zestawiarni wygrzewania zestawiarni wygrzewania i???? temperaturze technologoiczny zapewnienia przewr??ci?? rury potkni??cie przykryte deszcz??wka siatk??	linii wide?? dost??pnych rozpi??trowa?? podaczas naprawienie podaczas naprawienie brama/ drzwi poziomych Regularne likwidacja rury routera usun???? kieruj??cego kt??rzy	20210709_140545.jpg	2021-07-24	2021-07-10
317	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-07-21	11	Magazyn ??rodkowy - obok Automatu Giga	2021-07-21	09:00:00	26	nadstawek form?? mog??o Zanieczyszczenie palecie b??dzie palecie b??dzie zawadzenia zadaszenia zamocowana ruchome elektrycznej obs??ugiwa?? s??amanie komputer??w d??wi??kowej	3	potykanie barier?? gdy dopad??a fragment zwalniaj??cy fragment zwalniaj??cy regulacji naci??ni??cia siebie go??ci stara rzucaj?? poruszaj??cych przechodz??cej audytu pode??cie/	Ragularnie stabilny wyj??ciami opakowania wyj??ciowych cykliczneserwis wyj??ciowych cykliczneserwis otwarcie dorobi?? kurtyn wpychaczy kasetony przej??cie burty umo??liwiaj??cych koryguj??cych palet	R-2.jpg	2021-08-18	2021-12-15
332	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-08-09	2	przejazd obok sitodruku z prawej strony id??c od malarni	2021-08-09	07:00:00	26	osoby karku ??atwopalnych dostep si??owego powoduj??c?? si??owego powoduj??c?? dolnej progu rodzaju IKEA ??miertelnym usuwanie transportu jednoznacznego Pora??enie	3	My przemywania elektrycznych zgnieciona zawarto???? si?? zawarto???? si?? wypi??cie zastawia obs??ugi s??uchawki przechyli??a listwie maszynki wychodz??cych Samoczynnie dost??pnem	przew??d stwarzaj??cym pod????cze?? poprawienie wybory ruchomych wybory ruchomych tabliczki pozostawiania podobnych opasowanego podno??nika miejscem przegl??dzie uszkodzonych Treba ??ciany	800C5123.jpg	2021-09-06	2021-08-09
334	80f879ea-0957-49e9-b618-eaad78f7fa01	2021-08-12	2	magazyn budowlany	2021-08-12	10:00:00	13	smier?? roboczej umieli Uszkodzona momencie Problemy momencie Problemy okaleczenia wystaj?? St??uczeniez??amanie ??niegu postaci instaluj??c?? konstrukcji przewody p??ytek	3	posadzka zdmuchiwanego skladowane r????nica poruszaj??c?? u??ywana poruszaj??c?? u??ywana wewn??trznej pod??o??na pr??dem zdrowiu stoi ??a??cuch??w mieszadle Jedzie spuchni??te widoczny	rozdzielni instrukcji wybory ostro??no??ci spi??trowanych cm spi??trowanych cm uprz??tn??c lekcji przedmiotu praktyk ostrego transportera spr????ynowej u??ytkowaniu wykonywania piwnica	IMG_20210805_082547.jpg	2021-09-09	2021-08-23
247	5bc3e952-bef5-4be3-bd25-adbe3dae5164	2021-05-14	11	hydrant przy rampach	2021-05-14	12:00:00	25	du??ym nast??pnie jako pracownik??w Pora??enie kontrolowanego Pora??enie kontrolowanego transportowej pracy- Zwarcie reakcji drodze Niestabilnie mienia nie hala	3	nogi ziemi obieg b??belkow?? kiedy drabin?? kiedy drabin?? wystaje dachem stara aby rozbieranych posiadaj??ce akumulator??w Staff tam przewr??ci??	??cian?? kable wpychcza trzech obci????enia Przestrzeganie obci????enia Przestrzeganie dzia??aniem Przykotwi?? przeno??nikeim kierunku podeswtu Oosby k????ek chemicznej dzia??u schodki	hydrant.jpg	2021-06-11	2021-12-15
347	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-09-07	12	Paletyzator R7	2021-09-07	14:00:00	9	Utrata osun????a okular??w Pozosta??o???? rozszczenienia skutek rozszczenienia skutek W1 ka??d?? w2 rozpi??cie elektrycznych kratce udzia??em Uszkodzona Zadrapanie	3	Jedzie r??czny przej??cia reakcja ruchu tacami ruchu tacami pomieszczenia osob?? klawiszy antypo??lizgowa efekcie s??upie zosta???? pomocy M560 dzwoni??c	skrzynce przedmiotu piec portiernii pracownik??w pokry?? pracownik??w pokry?? ochronnik??w Rozporz??dzenie uniemo??liwiaj??cy wypadkowego Zabezpieczenie le??y powiesi?? niebezpiecze????twem spi??trowanej prostu	20210827_115011.jpg	2021-10-05	2021-09-09
40	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2020-01-17	3		2020-01-17	16:00:00	0	szafy Z??e r10 zalenie jak wy????cznika jak wy????cznika najprawdopodobnie ta??moci??gu uderzeniem ci????kim zmia??d??enie spr????onego mog??o katastrofa niestabilny	\N	piecu 8m pomieszczenia polegaj??c?? zimnego pieca zimnego pieca obci????e?? rega?? spowodowa??y doja??cia wskazanym t??ucze przej??ciu przechyli?? Opr????nia boku	k???? hali lokalizacj?? sama obs??uguj??cego umocowan?? obs??uguj??cego umocowan?? poprawnej po chc??c pracownik??w powietrza szczelno??ci posypanie przewodu stwarzaj??cym regularnego	\N	\N	\N
378	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-10-21	12	Wyj??cie z klatki schodowej z cz????ci socjalnej na sortownie	2021-10-21	10:00:00	18	okaleczenia pracownicy sufitem przechodz??cej odgradzaj??cej amputacja odgradzaj??cej amputacja paleciaka lod??wki Nikt Mo??liwe ta??m?? karton Dzi?? transportowaniu na	4	os??ny chwilowy Przeci??g R7/R8 z????czniu niedozwolonych z????czniu niedozwolonych CZ????CIOWE/Jena Zanim Wisz??cy a potr??cenia "Wyj??cie uszkodzon?? 5 Nezabezpieczona razem	miejscami zadaszenia takiego obowi??zku min ponad min ponad Przygi???? upadkiem zainstalowanie CNC schodkach Przet??umaczy?? najdalej otwieranie natychmiastowym przyczyn	20211021_095521.jpg	2021-11-04	\N
382	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-10-26	3	Przy bramie przy linii produkcyjnej R9	2021-10-26	10:00:00	5	zahaczy?? drzwiami siatka Mo??lio???? przerwy sk??adowanie przerwy sk??adowanie sk??adowana Otarcie rozdzielni piecem transportowaniu sprawdzaj??ce sortowanie pionie warsztat	3	Rana coraz palnik??w wystaje wszystkich ci??gowni?? wszystkich ci??gowni?? Opieranie ch??odzenia kasku zdemontowana wyciek lokalizacji kostki/stawu lec?? Rana wid??owy	Instalacja jaskrawy jesli maj?? wzmocni?? ochronne wzmocni?? ochronne wyznaczy?? zakresie ca??o??ci sekcji wa?? oceniaj??ce usuwa?? miejsca no??ycowego kompleksow??	20211026_090541.jpg	2021-11-23	\N
396	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-11-19	4	Szatnia damska stara	2021-11-19	16:00:00	25	przeje??d??aj??cy pradem kogo?? czysto??ci cm przewod??w cm przewod??w polerce uaszkodzenie Przer??cone szatni kryzysowej nitce 1 ????cznikiem ludzkie	5	st??uczka gazu n??z ciasno rury pomog??a rury pomog??a Gor??ce Dopracowa?? powstania komu?? wspomagan?? r??wnie?? sumie Chcia??abym uzupe??nianie ceg??y	drzwiowego samym szk??a jakiej zasady zadziory zasady zadziory worka s??uchu os??on Wezwanie hydranty charakterystyki wody stosy maszynach przeznaczonym	IMG-20211119-WA0079.jpg	2021-11-26	\N
422	4bae726c-d69c-4667-b489-9897c64257e4	2022-01-18	3	Podest przy wyrobowej W2 od strony pieca w ci??gu do zasilacza R10 	2022-01-18	11:00:00	5	Potkni??cieprzewr??cenieskaleczenie telefon zdrmontowanego ma??o bramy po??aru bramy po??aru po??arowego wizerunkowe desek pracownikowi przemieszczaniu niebezpiecze??stwo wysokosci ??mier?? zabezpieczonego	4	metalu prsy b??dzie warstwy Taras" jej Taras" jej sk??adowania czerpnia interwencja komunikacyjnym r??cznych farbach miejsc alarm wysokie takie	szafy Reorganizacja wielko???? steruj??cy k????ko opuszczanie k????ko opuszczanie konieczne przewod??w spawark?? powierzchni?? pokonanie prowadzenia Demonta?? Po??o??y?? elektryka ??cian??	20220111_130544.jpg	2022-02-01	2022-01-20
433	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-01-31	2	Na zewn??trz pomieszcze?? w drodze do pracy	2022-01-31	12:00:00	23	spi??trowanych temu Po??lizni??cie niezbednych kostki udzia??em kostki udzia??em pusta przebywaj??cej kt??ry os??ona Ryzyko ??ycia procesu pochylni b??d??cych	4	technologiczny Je??eli koszyk??w ch??odziwo przewr??ci?? schodkach przewr??ci?? schodkach chemiczne otuliny mocowania metalowy posiadaj?? skrzyd??o dystrybutor ponad wymieniono Linia	poprawnego Pouczenie oceniaj??ce sama otwierania przej??ciu otwierania przej??ciu przycisku informacyjnej powiesi?? wystaj??c?? u??yciem stosowanie Przekazanie powiadomi?? nowa roboczy	20220131_114955.jpg	2022-02-14	\N
437	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2022-02-07	12	Dystrybutor wody sieciowej obs??uguj??cy sortowni?? na wysoko??ci R7 i R8.	2022-02-07	11:00:00	5	zalanej upadaj??c odprysk wp??ywu instaluj??c?? opakowaniami instaluj??c?? opakowaniami zabezpieczeniem r??k sk??adowana wyrobach zdarzenia otworze ewakuacji uszczerbek cofaj??c	4	odci??gowej wysoko??ci dojscie wzorami cz????ci klawiszy cz????ci klawiszy drewnianych komputerowym urz??dzeniu wymiot??w odrzutu cz??ste wiatrak co spasowane formy	przewod??w Zabezpieczenie Kategoryczny nap??dowych wyeliminowania przyczyny wyeliminowania przyczyny pokonanie gro???? wraz Uprz??tni??cie fragmentu cieczy ??rub?? monitoring transportowane powinny	PWsortR8.jpg	2022-02-21	2022-02-07
440	c307fdbd-ea37-43c7-b782-7b39fa731f90	2022-02-10	15	W??zek poruszaj??cy si?? na zewn??trz sortowni przy R1/ warsztacie	2022-02-10	15:00:00	23	znajduj??cy upadku przeciskaj??cego zerwana MO??liwo??c MO??liwo??c MO??liwo??c MO??liwo??c charakterystyki ostra hala ewentualnym elektrycznych uszlachetniaj??cego szybkiej sortowni prawej	2	w????czony Zastawienie ??????tych olejem S??abe razy S??abe razy drugi wykonywa?? p??omie?? wody ekranami manewr pracuj??cych ??wiatlo powoduj??ce wieszak??w	Uprzatniuecie wymianie+ pod??o??a os??aniaj??cej miejscem proces miejscem proces lini?? foli?? Wproszadzi?? hamulca Pomalowa?? Rekomenduj??: odbojnika w??a??ciwe zaj??cia otworami/	41.jpg	2022-04-07	\N
445	c969e290-7ed2-4eef-9818-7553f1ecee0e	2022-02-17	15	Drzwi wej??ciowe do warsztatu. 	2022-02-17	14:00:00	18	potni??cia kt??ry sprawdzaj??ce kontrolowany 2m ostre 2m ostre zgniecenia brak wystaj??cego ludzkiego stopypalc??w oraz dolnej mo??lwio??c uszkodze??	2	u??ytkowanie zapali?? okolicy op????niona deszcu Hu??taj??ce deszcu Hu??taj??ce u??ywaj??c Taras Kabel formami czyszczenia przechodz??c stwarzaj?? oczka cz????ci sk??adowania	obecno???? pokryw kask siatk?? gazowy zaizolowa?? gazowy zaizolowa?? spr????onego czujnik??w odgrodzi?? ??cian przepakowania polskim po????cze?? jezdniowego najmniej hydrantowej	IMG_20220211_111854.jpg	2022-04-14	2022-02-21
198	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-04-19	10	??adowanie akumulator??w	2021-04-19	14:00:00	25	pionie niebezpiecze??stwo niekontrolowane 15m podno??nik Wyciek podno??nik Wyciek ka??dorazowo magazyn Wyniku spa???? ewakuacyjnym magazynu wp??ywu przerwy spadek	4	lusterku kra??cowym ga??nic?? naruszona zwi??kszaj??cy sadzy zwi??kszaj??cy sadzy odpad??w nad ochronne Przekroczenie przeniesienia zwarcie uleg??a odbiera ci??cie przyj????	koszyki kierownika budowy przenie?? Np spi??trowanych Np spi??trowanych ??rednicy pomoc?? jezdniowe ostro??no??ci stolik go po w??a??ciwie brakuj??cy Poprawne	20210419_131224.jpg	2021-05-03	2021-12-07
205	800f4ae5-d6e5-45bf-9df7-ac9a8dcab858	2021-04-21	2	Przy windzie	2021-04-21	09:00:00	6	oparta 40 Uswiadomienie Poparzenie zasygnalizowania uszlachetniaj??cego zasygnalizowania uszlachetniaj??cego innych zwalniaj??cego przewody kabel brak oraz uszczerbku cm ka??dorazowo	2	przykryte odpady zbiornika kierunku do??wietlenie zapali??a do??wietlenie zapali??a poinformuje osobne ladowarki np wykona?? spi??trowanej nak??adki chroni??cych postaci powstawanie	kierowce blach?? nieodpowiednie ruch drodze przemywania drodze przemywania opuszczania kontroli element??w ilo??ci Prosz?? obs??udze otwarcia podest??w/ jednolitego rega??ami	image-20-04-21-08-49-1.jpg	2021-06-16	\N
210	8aed61ca-62f5-445f-993b-26bbcf0c7419	2021-04-22	11	Magazyn szk??a przy sorcie produkcji za miejscem do grzania folii na paletach	2021-04-22	16:00:00	26	laptop ostrym Najechanie odprysk ??rodk??w regeneracyjne ??rodk??w regeneracyjne wid??owy uszkodzon?? wpychaniu komputer??w skr??ceniez??amanie Uderzenie 2m magazynowana zamocowana	2	pokryte lusterku gaszenia dop??ywu pod??og?? wrzucaj??c pod??og?? wrzucaj??c Przeci??g usytuowany zacz????y przywr??cony interwencja przeno??nika dozna??a Trendu stron cz????ci	dymnych mog??a foto nad pobrania miesi??cznego pobrania miesi??cznego odstaj??c?? stoper obowi??zku filtry streczem ci??ciu powierzchni powiesi?? telefon??w rampy	20210422_144148.jpg	2021-06-17	2021-12-15
213	31ccccef-7f8d-45e5-9e03-7e6e07671f0a	2021-04-26	2	Wejscie na dzia?? dekoratornia	2021-04-26	14:00:00	18	potencjalnie gaszenia dystrybutor monitora Zdezelowana lampa Zdezelowana lampa CI??G??O??CI kraw??dzie zgniecenia potr??cenie bram?? zawarto??ci pozosta???? praktycznie schod??w	5	ca??a Operatorzy le????cy wymiany "mocowaniu" naruszenie "mocowaniu" naruszenie ograniczon?? Przewr??ceniem powy??ej studzienkach elementem DOSTA?? korytarzem utrudnia schodka widoczne	kraty przyczyny dla metalowych ograniczonym kasku ograniczonym kasku jej jazdy przyczyny odstawianie sprawno??ci gdy porz??dkowe blokady przegl??dzie jasne	IMG_20210426_070055.jpg	2021-05-03	2021-10-20
222	d069465b-fd5b-4dab-95c6-42c71d68f69b	2021-04-27	1	Nowe skrzyd??o biurowca	2021-04-27	15:00:00	18	??miertelny Pracownik zwalniaj??cego widoczny kontrolowany nim kontrolowany nim Niestabilnie r??ki Z??amaniest??uczenieupadek Okaleczenie substancjami odboju smier?? po??lizgu czego	3	zabezpieczenie pistolet sortuj??ce dachu sekundowe odpowiednie sekundowe odpowiednie Panel czujnik panuje widoczne rusztowanie koszyk??w polegaj??c?? pracownika rega??ami W??A??CIWE	utrzymaniem postoju stolik Obudowa?? etykiety przechodzenia etykiety przechodzenia wi??cej jezdniowymi powieszni ??okcia stref?? r??cznego Konieczny pust?? w??a??ciwie niedostosowania	20210427_133703.jpg	2021-05-25	2022-01-19
223	8aed61ca-62f5-445f-993b-26bbcf0c7419	2021-04-28	2	Miejsce przy szafie sterowniczej.	2021-04-28	10:00:00	6	k??tem ugasi?? go os??ona ??miertelny uruchomienia ??miertelny uruchomienia uruchomienia roboczej 74-512 Utrata znajduj??cego Elektrktryk??wDzia??u pozosta???? pojazd??w Dzi??	3	rozchodzi czego Kapi??cy widoczno???? pracuj??ce zahaczenia pracuj??ce zahaczenia ??rodku metr??w schod??w uszkodze?? oparami liniach bliskiej przyj???? wysoko??ci poszdzk??	elekytrycznych ca??owicie elektryczne piecyka przeszkolenie identyfikacji przeszkolenie identyfikacji dzia??u ilo???? Poinformowa?? sprawno???? naprawy ??adunki otwierana myjki otwartych u??ytkiem	\N	2021-05-26	\N
232	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-05-07	4	Pomieszczenie na makulatur??	2021-05-07	09:00:00	1	przypadkuzagro??enia niepoprawnie zwalniaj??cego praktycznie polerki zanieczyszczona polerki zanieczyszczona gwo??dzie g??ow??ramieniem ludzkiego piecem Paleta budynk??w w??zka rusza acetylenem	5	??adowarki automat "Duda nieprawid??owo przek??adkami Zastawiona przek??adkami Zastawiona C warsztacie spiro us??an?? klawiszy k??tem ta stoj?? ona Demonta??	ewakuacyjnego stabilne klatk?? bli??ej j??zyku czyszczenia j??zyku czyszczenia Instalacja stanowisk poprawi?? Uporz??dkowa?? ustawienie Poinstruowanie ostrzegawczej Przykotwi?? odpowiednio kamizelki	IMG_6877.jpg	2021-05-14	2022-01-19
451	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-02-28	12	Transporter rolkowy na sortowni, przed ????cznikiem	2022-02-28	09:00:00	9	zgrzeb??owy Niesprawny osob?? usuwanie zwalniaj??cego pracy- zwalniaj??cego pracy- zniszczony ????cznikiem przygniecenia pora??anie wzrokiem Ponadto rura zako??czenie przedmioty	3	materia?? za??adunku transportowej chroni??cy przyj???? stosuj?? przyj???? stosuj?? os??oni??te Deformacja bezpiecznego wzgl??du palety dalszego zweryfikowaniu ??atwo akcji reakcji	orurowanie zabezpiecza FINANS??W sprz??ta?? cienka naklei?? cienka naklei?? umo??liwiaj??cych u??wiadamiaj??ce pr??dko??ci kartonami wypatku wpychcza Naprawi?? nast??pnie stanowi??y trzecia	IMG_20220228_093158_compress27.jpg	2022-03-28	\N
461	4bae726c-d69c-4667-b489-9897c64257e4	2022-03-31	12	Liczne miejsca z ga??nicami kt??re stoj?? swobodnie na skrzynce hydrantu. Ga??nica ze zdj??cia znajduj?? si?? obok MSK. 	2022-03-31	08:00:00	18	okacia??a u??ycia poziom??w magazynu g??owy poruszania g??owy poruszania studni transportowanych ??mier?? sto??u uszczerbkiem Prowizorycznie zawarto??ci szklanym widzia??em	3	Odklejenie bia??a pory podeszw?? DZIA??ANIE uchyt DZIA??ANIE uchyt musi kamizelki butla ustawione przechyli??y Rozproszenie m??g?? blach?? b????d zako??czenia	znajdowa??a opisane Przetransportowanie mia?? przestrze?? drogowego przestrze?? drogowego urz??dzenia przeznaczonych upominania wypadkowego jezdniowe mo??liwie u??ytkowanie zako??czeniu Przewo??enie odpre??ark??	20220330_084831_resized.jpg	2022-04-28	\N
464	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2022-04-12	12	Sortownia przy pomieszczeniu kierownik??w	2022-04-12	11:00:00	16	przypadkowe wystaj??c?? drog?? podestu oka noga oka noga dotycz??cej ca???? wylanie u??ytkowana obs??ugi odprowadzj??cej w???? czas g????wnego	3	materia????w Dystrubutor przytwierdzony d??ugie prawa st??uczk?? prawa st??uczk?? razu wstawia aluminiowego wy????cznika spompowa?? ma??ego blacha przeskokiem spowodowany Niesprawny	wykonywanie w??zki sposob??w ??cianki obszar powinno obszar powinno wyznaczone os??aniaj??cej Obecna Uprz??tni??cie Ustawi?? Techniki koryguj??ce poprawienie razy pionowo	20220412_110031.jpg	2022-05-10	2022-04-21
352	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-09-05	12	Linia r6	2021-09-05	02:00:00	16	pras cz??owieka upuszczenia uchwyt awaryjnej Potkni??cie awaryjnej Potkni??cie zamocowana ba??agan stanowisku ziemi znajdujacej skutek przycisk p??ytek W1	3	stanie przestrzenie nienaturalnie stoja zej??cie pracowince zej??cie pracowince etycznego strat zewn??trzn?? gor??cej prowizoryczny otrzyma?? inne kotwy roz??adowa?? podniesion??	identyfikacji naprowadzaj??ca Poprwaienie stanowisku jej dostosowuj??c jej dostosowuj??c m s??upek upominania piktogramami konstrukcj?? Poinformowa?? sobie mo??liwego spawark?? matami	20210907_144822.jpg	2021-10-08	\N
427	c307fdbd-ea37-43c7-b782-7b39fa731f90	2022-01-31	2	Magazyn A20	2022-01-31	09:00:00	25	oparta naro??nika wiruj??cy uszlachetniaj??cego por??wna?? maszynie por??wna?? maszynie wyznaczaj??cych upadku spi??trowanej Uszkodzona przechodz??c?? szk??auraz oznaczenia ewakuacyjnym u??ycia	2	pozostawione zawadzi?? Niepawid??owo platformowego wgniecenie Usuni??cie wgniecenie Usuni??cie napis dniu sufitu krople filtra Prawdopodobna b??d??c pozosta??o???? kropla ??wiatlo	pomiar w??zkami stawia?? WYWO??ENIE transportowane Rega?? transportowane Rega?? naprawic/uszczelni?? wraz wyciek dost??pem Przewo??enie wysuni??tej wypchni??ciem zastawionej Przeszkolic sterowniczej	IMG_20220228_092608_compress73.jpg	2022-03-28	\N
81	c307fdbd-ea37-43c7-b782-7b39fa731f90	2020-12-16	4	Obszary produkcyjne/ magazyny	2020-12-16	13:00:00	0	ha??as drugiego niepotrzebne Powa??ny maszynie stopie?? maszynie stopie?? przypadkuzagro??enia mog??a wa?? zanieczyszczona Z??amaniest??uczenieupadek malarni gaszenia fabryki stanie	\N	trzyma??em 7 u??ytkowanie g??ow?? w????czeniu Oberwane w????czeniu Oberwane kraty ceramicznego antypo??lizgowa blaszan?? "boczniakiem" zej??cie biurowi pojemniku usytuowany gazowy	powoduj??cy miejscamiejsce patrz??c ci??ciu przyczyny p??ynem przyczyny p??ynem miejsca tokarskiego s??siedzcwta pobli??u u??ytkowaniem mocuj??cych informacj?? spoczywaj?? przycisku k??tem	\N	\N	\N
241	4bae726c-d69c-4667-b489-9897c64257e4	2021-05-13	12	 Wej??cie na sortownie z magazynu opakowa?? przy R1	2021-05-13	07:00:00	26	Uszkodzona Mo??liwo???? drugiej hydrantu st??uczenie wydajno???? st??uczenie wydajno???? k??tem butli wywo??anie palet Nara??enie pot??uczenie kt??ry pojemnika urazy	3	odbi??r szlifierk?? akcji rozchodzi porusza zew??trznej porusza zew??trznej kluczyka wysoki korytarzu rega??ami trzeba poza naprawiali ostro komu?? by??y	pi??trowanie wn??ki odp??ywowej informacje podest??w szuflady podest??w szuflady od pi??trowane stabilny Do??o??y?? wszystkie s??siedzcwta starych umo??liwiaj??cych odpowiednich Karcherem	20210512_120155.jpg	2021-06-10	2021-12-07
244	800f4ae5-d6e5-45bf-9df7-ac9a8dcab858	2021-05-13	11	W alejce naprzeciwko kontrolera wizyjnego (linia do automatyzacji). 	2021-05-13	14:00:00	26	Podkni??cie przygotowania sko??czy?? przemieszczaniu sterowania efekcie sterowania efekcie CI??G??O??CI amputacja ??niegu gwa??townie infrastruktury konsekwencji przeciwpo??arowej przez bok	3	niemal??e Pracownice Natychmiastowa Ciekcie prasa pogotowie prasa pogotowie umiejscowion?? zacz???? kolizji kosza pomieszce?? proszkow?? otworzeniu magazynu wyd??u??ony p????wyrobem	prac owalu lewo bez ??okcia paletyzator ??okcia paletyzator os??aniaj??cej bezpo??rednio powy??ej konstrukcj?? bortnic dymnych wann?? szyb?? umorzliwi??yby Uzupe??nienie	IMG20210513125516.jpg	2021-06-10	2021-12-15
246	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-05-14	11	MWG za pierwszym ????cznikiem	2021-05-14	10:00:00	26	uderzeniem Ludzie kostce poprzepalane ci??te przycisk ci??te przycisk czujnik??w bariery niekontrolowany czas umieli stop?? charakterystyki fabryki wywo??anie	3	szmaty ga??nic?? sprz??tania przemieszczeniem zranienia automat zranienia automat pracami mo??e wytyczon?? szyb?? opanowana warsztatu sortowi piecu TECHMET wyrzucane	pracownik??w palet?? przegl??dzie okre??lonym mniejsz?? przechylenie mniejsz?? przechylenie serwisanta pochylnia okresie ustawiania pozosta??ych Ragularnie stron?? praktyk technologiczny ostreczowana	IMG_20210514_094730.jpg	2021-06-11	2021-12-15
252	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-05-17	10	R1 	2021-05-17	11:00:00	26	polerce automatu zwichni??cia potencjalnie zahaczenie ga??niczego zahaczenie ga??niczego zw??aszcza piecem skr??cenie odpowiedniego spadaj??cych czas uk??ad pusta kraw??dzie	3	skruty zaolejona niestabilny opar??w id??cy pleksy id??cy pleksy zosta?? zamontowane przekrzywiony d???? podno??nika pode??cie/ transporter ci??gowni?? substancjami korpusu	Kompleksowy jazdy Rozpi??trowywanie warunk??w drug?? nowe drug?? nowe kt??rzy pr??downic Kontrola ko??cowej przypomniec jezdniowego pomoc?? dzia????w u??ytkowania si??	20210517_105336.jpg	2021-06-14	2021-12-07
263	2168af82-27fd-498d-a090-4a63429d8dd1	2021-05-28	3	przej??cie ko??o p kierownik??w i W1	2021-05-28	12:00:00	18	zwarcia przez po??arem a dekoracj?? rozszczelnie dekoracj?? rozszczelnie os??ony pokonania szybkiego wystrza?? transportu obra??enia utrzymania cm magazynu	4	elektrycznego os??on?? kabli wypadek PODP??R sadza PODP??R sadza B????dne wysokie wisi osoba przekrzywiony szk????m ZAKOTWICZENIA potknie oczkiem ma	przechylenie wchodzenia Umieszczenie r??cznego p??aszczyzn?? R4 p??aszczyzn?? R4 operatorom niepotrzebnych wn??trza min jasn?? ograniczy?? jak nakazie brama/ w??zk??w	20210521_125419.jpg	2021-06-11	2021-10-12
273	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-06-21	3	Budowa nowego pieca W2	2021-06-21	08:00:00	16	pozostawione w??zkiem ga??niczy pionowej poziom??w mocowania poziom??w mocowania WZROKU pr??g ponowne m??g?? budynkami nara??aj??cy regeneracyjne St??uczenia lampy	5	recepcji otwory pieszych widlowy magazynier??w u??ytkowanie magazynier??w u??ytkowanie ??cianki WYT??OCZNIK systemu papieros??w MSK zabezpieczony posiadaj??ce mate remontowych spada	sprz??t myciu metalowy W????CZNIKA Je??eli wystawieniu Je??eli wystawieniu stolik przebi?? teren ??rodka rozsypa?? sytuacji mo??liwego samodomykacz polerki jeden	20210616_155734.jpg	2021-06-28	2021-08-04
275	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-06-21	2	Malarnia - filtr od speeda	2021-06-21	14:00:00	18	wysoko??ci przebywaj??cej awaria Uderzenie Niepoprawne Pozosta??o???? Niepoprawne Pozosta??o???? Nara??enie elektrycznej w??zkiem przygotowania Uszkodzona okolic pochylni napojem dolnej	3	nieprawid??owo k??towej dwie du???? unosi?? systemu unosi?? systemu prsy zastrze??e?? instalacje tu?? kluczyka zosta?? obszar wyra??a?? robi?? tylko	czynno??ci szlifowania po??o??enie oczu wypatku DOTOWE wypatku DOTOWE no??ycowego umo??liwiaj??ce szklanej ostrych wymiana kiery dachem dalszy ODPOWIEDZIALNYCH podno??nikiem	20210614_181148.jpg	2021-07-19	2021-06-21
278	ea77d327-1540-4c81-b95c-2bb5dc21a32e	2021-06-23	2	g????wne przej??cie obok starej windy	2021-06-23	13:00:00	11	ugasi?? g??ow?? Ci????kie Stary przw??d nawet przw??d nawet oparzenia routera poprawno???? ograniczenia przetarcie automatycznego g??owy prawej gazem	3	ga??nicy W??ski rozwi??zanie wid??owy zako??czenie przedmiot zako??czenie przedmiot Wannie ci??gu os??aniaj??ca poprzeczny zwalnia biurowy pr??bie 0r ude??enia drewniany	podbnej sortu premy??le?? nowa dobr?? wr??t dobr?? wr??t orurowanie butli wszystkich schod??w dotychczasowe technicznego ci??gi gro???? p??lkach kabel	20210622_140935.jpg	2021-07-21	2022-04-11
449	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-02-28	3	Skrzynki elektryczne na zwen??trz pokoju kierownik??	2022-02-28	09:00:00	6	w??zkiem malarni stawu Uderzenie poniewa?? drzwiowym poniewa?? drzwiowym stopypalc??w elementami sypie odprysk palecie pracownik??w stanowisku zabezpieczaj??ca stop??	3	nam komunikacyjnym transportowej szczyt ca??a momencie ca??a momencie po??lizgn????em kraw??dzi no??ycowym palnikiem Zanim wychodzenia innej ch??odz??c?? frezarka buty	r??kawiczek poruszanie zdemontowa?? ostrzegawcz?? otworami/ Pomalowanie otworami/ Pomalowanie pomieszczenia DOTOWE pol zdj??ciu pozosta??ych zbiornika natychmiastowym filtry listew spr????yn??	IMG_20220228_092159_compress21.jpg	2022-03-28	2022-03-02
285	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-06-30	4	Przed magazynem palet.	2021-06-30	10:00:00	26	podczas ??eby automatycznego zagro??enia wystaj??c?? Potencjalne wystaj??c?? Potencjalne uruchomienie sprz??t wydajno??ci go sie paleciaki transportowej przewr??cenia szatni	3	samozamykacz prawdopodobnie spadnie powiewa przed??u??acz filtry przed??u??acz filtry leje naderwana kostrukcj?? Przecisk posadzka technologoiczny gazowe gips lub odzie??	odkrytej tego pitnej s??uchu mijank?? sprz??tu mijank?? sprz??tu dnia przewidzianych drzwi palnika upominania progu stron eleemnt??w stopnia odprysk??w	20210630_102351_compress32.jpg	2021-07-28	2021-12-07
289	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-06-30	12	paletyzator R7	2021-06-30	11:00:00	26	godzinach R8 dolnej otwierania mog?? mi??dzy mog?? mi??dzy rega????w wpadnieciem skr??ceniez??amanie wystaj??cym beczki hali mocowania m??g?? je??d????ce	2	istotne mate spadaj??ce ziemi :00 r??cznych :00 r??cznych sadz?? korytarz koordynator obs??ugiwane szlifierki ba??ki strony skokowego ochronnik??w foli??	gumowe palet??? Przekazanie ograniczy?? wannie kasetony wannie kasetony odzie??y wid??owych jako ustawiania ca??owicie rozsypa?? powinien u??ycia Poprawnie spr????ynowej	IMG_20210628_093529_compress14.jpg	2021-08-25	\N
290	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-06-30	15	Warsztat / Magazyn Form	2021-06-30	12:00:00	23	Podpieranie b??dzie zbiorowy 4 starych wchodz??ca starych wchodz??ca Mo??liwo???? ka??dorazowo blachy obecnym ko??czyn wpadni??cia paleciaka materialne u??ycia	4	pomoc?? Jedzie wolne jazdy tematu maszyny tematu maszyny brakowe dymu przeje??dzaj??c nieodpowiedni rozbicia wentylacyjnych przechodz??cej elektrycznego ugasi?? Utrudniony	wr??t ca??ej ostrzegawczej przeprowadzenie odkrytej predko??ci?? odkrytej predko??ci?? wypchni??ciem kierunku wype??nion?? uniemo??liwiaj??cy ch??odziwa ci??gi otynkowanie wod?? sukcesywne gaz	IMG_20210630_093103.jpg	2021-07-14	2021-12-15
292	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-06-30	15	Warsztat CNC	2021-06-30	12:00:00	2	nt poruszania czas poziom??w prawdopodobie??stwem Dzi?? prawdopodobie??stwem Dzi?? st??uczki piec maszynki linie poprzez oparzenia uderzeniem szybko ta??moci??gu	4	odbi??r ewakuacujne za??o??enia uda??o odeskortowa?? pusta odeskortowa?? pusta pakuj??c zostawiaj?? wyst??pienia Nier??wno???? paj??ku Pan za??o??enie napoje wrz??tkiem palet??	spi??trowanych spoczywaj?? tj blokady pieszych WYWO??ENIE pieszych WYWO??ENIE przechodzenie hydrant pomieszcze?? wymieni?? Odnie???? b??dzie r9 mocuj??ce roku wiele	mf2.jpg	2021-07-14	2021-08-04
293	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-06-30	15	Magazyn Form, przestrze?? na ko??cu pierwszego rega??u.	2021-06-30	15:00:00	17	ograniczenia sortowni sprz??tu zsun???? usuwanie oznakowania usuwanie oznakowania substancji g??owy uchwyt??w Po??lizni??cie os??ona Uderzenie - zapalenie dotycz??cej	3	po zlokalizowane ciasno zbiorniku pozycji gazowych pozycji gazowych rozpuszczalnikiem osobom Odstaj??ca Po????czenie Rana Wyci??ganie po??lizgn????em samochody ostre komunikat	poprowadzi?? palet?? hydranty gdzie wytyczonej skrzynkami wytyczonej skrzynkami powieszni procownik??w jedn?? pomocnika pakunku poruszanie Kontakt kratk?? Wykona?? dost??pem	mf1.jpg	2021-07-28	2021-06-30
302	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-07-12	12	R6	2021-07-12	10:00:00	16	regeneracyjnego mog??a mog??a sk??adowane po trwa??y po trwa??y obecnym rura przekraczaj??cy sytuacji produkcyjnej uzupe??niania Utrata prawdopodobie??stwem substancj??	3	obszar przewidzianego Element najni??szej unosi?? polaniem unosi?? polaniem bok ciecz?? dzia??aj??cej s??upka prasie magazynier??w k????ko on przesunie Przeprowadzanie	pitnej teren si?? ma powinny dopu??ci?? powinny dopu??ci?? otwierana bortnice niekt??re st???? pod??ogi regularnie ??wiadcz?? czynno??ci?? przegrzewania kabin	Barierkamalarnia.jpg	2021-08-09	\N
306	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-07-13	10	Hala	2021-07-13	12:00:00	26	rozszarpanie Uszkodzona r??ce elementem gazowy rozszarpanie gazowy rozszarpanie spos??b s??amanie schod??w czas czynno??ci nadstawek ??rodowiskowe oosby formy	4	transporterze uruchamia systemu pr??dko???? sto????wce zaworu sto????wce zaworu przed nieodpowiednie biurowej prawa zaczynaj??ca wyt??ocznika ko??cz??c magazynem s??u??y niszczarka	wyroby Wproszadzi?? sol?? ograniczy?? ewentualne opakowania ewentualne opakowania st??ze?? szklarskich palet palet??? pomocnika u??ytkiem lewo s??upek oprawy obecno????	R712.07.jpg	2021-07-27	2021-12-07
315	2168af82-27fd-498d-a090-4a63429d8dd1	2021-07-19	3	przej??cie do R2	2021-07-19	21:00:00	5	je??d????ce wa?? zachowania sk??adaj??c?? wid??owym b??d??cych wid??owym b??d??cych dotyczy inspekcyjnej spad??a z??ego uczestni??cymi kostce os??ony bariery paletach	4	funkcj?? elektryczna zim?? Praca telefon zawarto???? telefon zawarto???? ruchu w??zkiem Wchodzenie przewr??ci?? r????ne wybuchowej Uszkodzona panelach wid??ami u??ycie	przykr??cenie powleczone sprz??tu przydzielenie ty??em ko??nierzu ty??em ko??nierzu klatk?? tylko DOSTARCZANIE karty koryguj??ce odbojnicy czarna ewentualnych Upomnie?? filtrom	R-9.jpg	2021-08-02	2021-08-04
318	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-07-21	1	Magazyn TGP1, dach pomieszczenia socjalnego przy po??udniowej  ??cianie.	2021-07-21	13:00:00	26	straty Zdemontowany poprowadzone nieszczelno???? zapewniaj??cego ca???? zapewniaj??cego ca???? znajduj??ce pr??by odpryskiem spadajacy urwania uszkodzeniu ustawione wystaj??ce mokro	4	instalacji czym sk??adowanie wykonane drugi wymaga?? drugi wymaga?? odpad??w wi??ry stali r??kawiczka silnika konstrukcj?? zranienia zasilaj??ce panuje pomimo	oznakowanie boczn?? w????e sk????dowania wema organizacji wema organizacji ewakuacyjnej stawania odgrodzi?? Zachowa?? pracownika rury poziomu kt??rzy powinny filarze	IMG20210719233643.jpg	2021-08-04	\N
325	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-07-30	15	Warsztat / piaskarki / napawywanie;  Palety z kartonami ustawione przy ??cianie s??siaduj??cej ze stanowiskiem napawywania	2021-07-30	09:00:00	26	por??wna?? zrani?? nieszczelno???? go widoczny awaryjnego widoczny awaryjnego Poparzenie powy??ej zniszczenia wyznaczaj??cych przedmioty wody bariery pochylni kart??	3	R7/R8 w??aczenia mia??am mo??liwo??ci nich odpowiednie nich odpowiednie ucz??szczaj?? zabezpieczony zawleczka ??liska bariera dolnej szeroko???? podnoszono Obok 8	niestwarzaj??cy Wymieniono Palety Zabroni?? biurze Ka??dorazowo biurze Ka??dorazowo Poinformowa?? uchwyty ostro??no???? stopnia odk??adcze trzecia piktorgamem przeszkolenie boku dobrana	IMG20210727215206.jpg	2021-08-27	2021-07-30
82	c9f77484-7d39-44d1-aa7c-7c1ac09a24ce	2020-12-17	2	Wej??cie do laboratorium	2020-12-17	13:00:00	0	sygnalizacji pod??og?? potr??cenie rany doj???? nawet doj???? nawet Podpieranie upadku Zastawione Bez spa???? Wyciek spadaj??ce mo??e zabezpieczenia	\N	wykona?? korzystania uruchomiona krotnie szybka z??ej szybka z??ej nieprzystosowany prawid??owo zapali??a etapie ziemi g??rnym/kratka/ wod??gaz Element wy????czonych spowodowa??o	Techniki os??b kwietnia charakterystyk ??cian?? nieumy??lnego ??cian?? nieumy??lnego kontener??w producenta/serwisanta jesli hydrantu podbnej drogowych plam?? biurowca MAGAZYN powinny	\N	\N	2021-04-20
231	c200ca1b-fa97-4946-94a2-626bd32f497c	2021-05-05	1	Pomieszczenie dawneego Biura G????wnej Ksi??gowej	2021-05-05	16:00:00	6	okular??w Ukrainy paletach pora??anie le????cy elementu le????cy elementu le????cy ha??as odgradzaj??cej Przeno??nik przewr??cenie pod????czenia zaczadzeniespalenie mokro wieczornych	5	opakowania potykanie zadanie manewru kostrukcj?? rozmowy kostrukcj?? rozmowy pr??t przedmioty etapie pomi??dzy oderwanej znajduj??cego poruszaj??cych oczkiem stwarza?? poszdzk??	lepsz?? noszenia dopuszczeniem cz??stotliwo??ci miejsca Otw??r miejsca Otw??r dokona?? obok chemiczych niew??a??ciwy innych wej??ciu p??lkach karton??w narz??dzi ko??a	20210505_162150.jpg	2021-05-13	2021-06-09
236	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-05-10	12	Droga transportowa na sortowni	2021-05-10	09:00:00	23	pokarmowy- lampy ostra Ipadek elektryczna rozszczelnienie elektryczna rozszczelnienie Spadaj??cy spodowa?? wi??kszych zatrzymania Bez mieniu r??wnie?? ostrym wyj??ciowych	3	sortownia wyniki substancjami ??nieg czujnik nog?? czujnik nog?? sprz??t Poinformowano standard Przewr??ceniem wolne po?? podgrzewa?? / szklanych przeniesienia	dwustronna spod jego obs??ugi skrzyni?? wielko???? skrzyni?? wielko???? umytym oprzyrz??dowania na stolik u??yciem Wyci???? pod krzes??a Ka??dorazowo Szkolenia	20210510_090250_compress34.jpg	2021-06-07	2021-12-30
257	4bae726c-d69c-4667-b489-9897c64257e4	2021-05-17	1	Korytarz przy gabinecie Pana Prezesa	2021-05-17	13:00:00	6	reagowania zimno substancj?? prawdopodobie??stwo dotycz??cej Lu??no dotycz??cej Lu??no zwalniaj??cego desek cia?? nask??rka zdrowia przy laptop karton form	3	pada Sortierka odleg??o??ci d??oni ociekow?? Magazynier ociekow?? Magazynier pojemniku regulacji rozchodzi ko??cowym strat platformie zostawiaj?? drug?? wskazanym Usuni??cie	umo??liwiaj??cych plus szczeg??lnie kt??rym w???? gi??tkich w???? gi??tkich odbywa??by schodki wn??ki obci????one otwieranie przeprowadzi?? hydranty informacja niebezpiecznych w??zkowych	20210517_121832.jpg	2021-06-14	2021-05-25
260	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-05-21	11	Stary magazyn - miejsce po regale K	2021-05-21	11:00:00	26	??ycia zako??czona przewody obs??uguj??cego potkni??cia sko??czy?? potkni??cia sko??czy?? materialne- tj Gdyby przycisk zewn??trzn?? telefon substancj?? sko??czy?? przygotowania	3	mieszad??a czego stosowanie pracownikiem dwa znajduj?? dwa znajduj?? uniesionych CNC ga??nica ci??gu mechanicznego rur?? obszarze kluczyk Drobinki kaw??	kart pomieszczenia metra mia?? niedostosowania pokry?? niedostosowania pokry?? wraz wej??ciem rynny spotkanie poszycie obszarze ga??nic ropownicami wyda?? Sta??e	IMG_20210520_121908.jpg	2021-06-18	2021-12-07
326	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-07-30	4	nowa szatnia m??ska - prysznice	2021-07-30	10:00:00	5	przeciwpo??arowej zdemontowane obok stanowiska w mo??e w mo??e paleciaka du??ym ruchome sprawdzaj??ce Zdemontowany SKALECZENIE mi????nie sk??adaj??c?? zniszczenia	3	u??ama??a przeno??nika indywidualnej mo??e platformie dodatkowy platformie dodatkowy podnoszono agregatu maszyn omin???? automatyczne sortuj??ce Jedna zdemontowana stopniu dost??pu	chc??c by??a ca??o??ci kamizelk?? Poprawa t??uszcz Poprawa t??uszcz Przestrzega?? realizacj?? wyroby odblaskow?? ma Rekomenduj??: dobranych Wi??ksza ustalaj??ce mo??liwego	IMG20210727215251.jpg	2021-08-27	2021-12-29
330	3ee5fc99-b50b-4b71-8f18-7a7af63c07ef	2021-07-29	11	Magazyn wyrob??w gotowych, obok rampy.	2021-07-29	20:00:00	25	du??e odpryskiem dozna?? kontrolowany reakcji ??mier?? reakcji ??mier?? uraz??w wskazania ma dozna?? przechodz??ce zdarzeniu pojazd??w le????cy czysto??ci	3	wzros??a ognia wyp??ywa??o odebra?? doja??cia odebra?? doja??cia odebra?? odbioru kabla zasad upad??a byc ??adnych zwisaj??cego Poszkodowany przewr??cenia MWG	nadpalonego pojemnik??w wysoko??ci filarze przewidzianych kontenera przewidzianych kontenera Konieczno???? spr????ynowej da metra jaskraw?? Mechaniczne wszystkie otwor??w konstrukcji by	1EC4128D.jpg	2021-08-27	2021-12-15
335	23369f2a-f53f-4064-8ff5-b886102686fd	2021-08-12	8	Magazyn A31 okolice rampy nr9	2021-08-12	20:00:00	23	le????cy ??rodowiskowe lampa butli skutki: itp skutki: itp przeje??d??aj??cy skutkiem zwichni??cia odgradzaj??cej Utrudniony Wej??cie dekoracj?? znajduj??cych doznania	3	pot??uczonej ko??cu pierwszej doprowadzi??o z zawarto???? z zawarto???? W??A??CIWE niewielkie drzwiami trzaskanie piecyka wysoki prowadz??ce wisi spowodowa??y mieszad??a	U??ATWI?? Zabranie lub spawark?? wyznaczy?? malarni wyznaczy?? malarni pust?? skrzyni?? przykryta mo??liwego smarowanie ci??g suchym Okre??lenie kartonami powierzchni	IMG_20210809_064659.jpg	2021-09-09	\N
14	bbe3f140-d74d-4ee0-980a-c007ad061fa0	2019-09-23	12	Zgrzewanie palet r??cznym palnikiem przez pracownik??w sortu. Ryzyko poparze??.	2019-09-23	11:00:00	0	braku uderze mienia si?? wid??owego kolizja wid??owego kolizja podkni??cia ka??d?? cz?????? wyj??ciem wyrob??w gazowy pracuj??cego ci??te pojazdu	\N	Firma instalacja po??o??ona ko??ca kablach wentlatora kablach wentlatora taka dniu magazynu przyj???? g??rze monta??u tej cze??ci temu gro????ce	co bezpiecznie do poruszania mog??a premy??le?? mog??a premy??le?? prawid??owego d??oni biurowym ??ciera?? czyszczenia pojemnik??w st??uczk?? chc??c odbieraj??c?? serwisanta	\N	\N	\N
15	bbe3f140-d74d-4ee0-980a-c007ad061fa0	2019-09-23	12	Zgrzewanie palet - ryzyko zapalenia rekawiczek. 	2019-09-23	11:00:00	0	schodach warsztat do??u spadek potkni??cia pracownikowi potkni??cia pracownikowi paleciaka nadstawki budynkami skutki: zerwanie zalenie przechodz??ce dozna?? b??dzie	\N	olejem powoduj??ce niepoprawnie dozownika obs??ugi rampy obs??ugi rampy oczkiem wyr??b w??zkowy automatyzacji spadku ??wietl??wki przepe??nione sotownie trwania okular??w	ga??nic przyczyny skr??cenie przymocowanie stortoweni suchym stortoweni suchym szuflady Proponowanym blokuj??ce ppo?? stanowi ko??ysta?? prze??o??onych firm parkowania przeno??nik	\N	\N	\N
474	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-04-28	4	Portiernia	2022-04-28	07:00:00	5	??rodowiska 15m pozosta???? g????wnego po??aru wysokosci po??aru wysokosci r??kawiczka zwichni??cia istnieje bramy spr????one szybkiego Wskutek dla u??ytkowanie	2	osadu poruszaj??ca nagromadzenia Niezas??oni??te Zabrudzenie przepe??niony Zabrudzenie przepe??niony by?? koc mokrych transportow?? sadz?? Urwana/uszkodzona prasa niestabilnie zawadzi?? materia??y	podjazd Przypomnie?? otynkowanie kt??re drog?? kontener??w drog?? kontener??w ??ancucha Us??niecie st??ze?? wytycznych maszynki wysokich Zabezpieczenie oczyszczony ok sprz??tu	20220427_070353.jpg	2022-06-24	2022-09-22
16	83b1ad28-951d-4a56-bbd1-0d4f4358d18a	2019-09-25	12	Linia R8	2019-09-25	11:00:00	0	dostepu ca??ego ugasi?? pras tego ok tego ok naci??gni??cie przedmioty je??d????ce sk??adowanie uszlachetniaj??cego przykrycia elektrycznych os??ona gniazdka	\N	g??rnej zaczynaj??ca straty UR robi??ca regulacji robi??ca regulacji nogi przyci??ni??ty rzuca??o stopa stopnia Obecnie linii sumie uszkodze?? wn??trzu	porusza?? miesi??cznego stwierdzona Techniki poprawi?? por??cze poprawi?? por??cze spotkanie przeniesienie Oosby klosz stabilny burty kierownika pomieszczenia niepotrzebnych czynno??ci	\N	\N	\N
346	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-08-31	1	MWG A31	2021-08-31	11:00:00	26	prowizorycznego uszkodzenie pod??odze wybuchu no??yc zwichni??cie- no??yc zwichni??cie- urz??dze?? odpowiedniego ewakuacyjnym Uszkodzony do: stopie?? procesu zasilaczu dokonania	5	znajduj?? B????dne kratki prasie poupadkowych Prawdopodobna poupadkowych Prawdopodobna opad??w umo??liwiaj??cych tryb ustwiono kieruj??cy razy kiera szklane rozchodzi stosuj??	zakup Uprzatniuecie Rozporz??dzenie posadzki R10 zakazaz R10 zakazaz obchody plus no??no???? pozostawionych je??li Skrzynia cm dobranych stale wy????cznik	20210826_074002.jpg	2021-09-07	2021-12-15
19	2b05f424-3dc1-4bea-81b5-6e241f7ed6d8	2019-10-09	4	??cie??ka na zewn??trz budynku od strony biura	2019-10-09	14:00:00	0	schod??w chemicznych Gdyby powodu rega??u rozci??cie rega??u rozci??cie mienia nim powstania ??ycia r??kawiczka barierka uszczerbkiem umieli wyj??ciem	\N	u??ywa?? ztandardowej listwa gazowej w???? uzupe??nianie w???? uzupe??nianie k??tem ze zamkni??ciu rusztowanie Zabrudzenia kostki Drobinki takich koordynator w??aczenia	linii codziennej dysz Przygi???? palnika stolik palnika stolik prawid??owych drogi opakowania poza palet umo??liwiaj??cych naprawa przej??ciu koc Ocena	\N	\N	\N
411	4bae726c-d69c-4667-b489-9897c64257e4	2021-12-30	1	korytarz	2021-12-30	08:00:00	25	delikatnie mieniu skr??ceniez??amanie cz????ci?? usuwanie poziomu usuwanie poziomu przechodz?? ostro??no??ci ??adunku Ponadto gumowe liniach znajduj??ce sk??adowane wy????cznika	3	Zdj??te wy????czonych jak: sta??a robi??ca wodzie robi??ca wodzie nieprawid??owej spowodowa?? ??ruba brak??w luzem speed przepe??niony kable kable prowadzi	warsztacie odboju elekytrycznych przegl??d ??ancucha oczu ??ancucha oczu trzech przelanie razie Zabranie widoczno??ci ppo?? przewidzianych Rozmowy odpowiedniej ??adunku	Screenshot_20211230-081634_WhatsApp.jpg	2022-01-27	\N
4	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2019-06-12	12	R7	2019-06-12	11:00:00	0	wystaj?? uszkodzenie s?? element TKANEK czyszczeniu TKANEK czyszczeniu ziemi uszlachetniaj??cego r??wnie?? widoczno??ci skr??cenie temu wstrz??su pr??by upadku	\N	poszdzk?? Praca kratami ostry przechylona frezarka przechylona frezarka paltea znajduj??cego sk??adowany ochronnych ??wiat??o zepsuty Zestawiacz Uszkodziny swoj?? wewn??trznej	bie????co Poinstruowa?? os??oni?? budynki dok??adne ppo?? dok??adne ppo?? regularnej Poimformowa?? ??atwopalne ilo??ci pojedy??czego nara??aj??ca rozmie??ci?? tej odpowiedniego piwnica	\N	\N	\N
428	c307fdbd-ea37-43c7-b782-7b39fa731f90	2022-01-31	12	R9	2022-01-31	09:00:00	5	st??uczenie energoch??onnej mog??aby kontrolowanego paleciaka przep??ukiwania paleciaka przep??ukiwania instalacji zabezpieczenia drog?? kt??ry odprowadzj??cej zalanej pod??odze Pochwycenie organizacji	2	strat stoj??cego przytwierdzona kraw????nik filtra zwarcie filtra zwarcie wypadni??cia Post??j pode??cie za??lepia??a ??liskie zg??osi?? upadaj?? produkcyjne uwagi niestabilnych	zastosowa?? by?? w????y sta??ych szczeg??lnie bhp szczeg??lnie bhp podestowej tokarskiego oznakowanie nale??a??oby opakowa?? powinny trudnopalnego now?? przydzielenie ga??niczy	20220131_091521.jpg	2022-03-28	\N
6	0fb6b96b-96a8-4a39-a0e2-459511d1c563	2019-07-10	17	Piec W1	2019-07-10	00:00:00	0	dostepu przetarcie rusza ??rodk??w pieszego uaszkodzenie pieszego uaszkodzenie Pracownik Przeno??nik uzupe??niania hydrantu ostreczowanej sk??adowanych bramy z??amanie Bez	\N	sta??o Uszkodziny osadzonej ilo??ci pietrze hydrantu pietrze hydrantu szybie szfy dniu p??k?? pionowym rozdzielcza paltea nieprzystosowany unoszacy regulacji	mijank?? stosowania kotroli problem lampy przedostawania lampy przedostawania opisane dokona?? gro???? napraw Je??eli rozlew??w demonta??u p??aszczyzn?? cieczy ostrzegawczy	\N	\N	\N
12	57b84c80-a067-43b7-98a0-ee22a5411c0e	2019-09-10	4	Laboratorium	2019-09-10	08:00:00	0	znajduj??cy uchwyt??w bezpieczne poprzez sterowania d??oni- sterowania d??oni- linie wody Potencjalny 2m linie zapalenie ok paletszk??a urazy	\N	wystaj??ce nieodpowiedni kogo?? lejku p????produktem b??d?? p????produktem b??d?? produkcj?? mocowania ??wietliku poruszajacej ??wietliku skutkowa?? ustawione podestem r??ku termokurczliw??	przenie???? Inny podestem kt??rych schodkach os??yn schodkach os??yn kt??ry suchym ograniczenie prze??o??enie uniemo??liwiaj??ce stoj??cej podest??w odgrodzi?? Doko??czy?? niestwarzaj??cy	\N	\N	\N
22	0fb6b96b-96a8-4a39-a0e2-459511d1c563	2019-10-25	17	Wanna W1	2019-10-25	13:00:00	0	pracy- sk??adowane spadaj??cej WZROKU Du??a nadstawki Du??a nadstawki palet noga ludzkiego powr??ci?? nadstawki ma??o po??aru zdrowiu nawet	\N	spodu ruchome budna tylko powstania poruszania powstania poruszania oczekuj??ce element??w ca??y niedopa??ka roz??adunku stanowiska g????wnym stop?? Stare go??ymi	jak filtry kraty papieros??w pozycji butle pozycji butle Powiekszenie chemiczych kolejno??ci nachylenia prawid??owy stosowanie Karcherem przewody farb?? steruj??cy	\N	\N	2021-01-08
25	4e8bfd59-71d3-44b0-af9e-268860f19171	2019-11-13	3	R-1	2019-11-13	23:00:00	0	obs??ugiwa?? Przygniecenie przebywaj??cej kogo?? Przeno??nik a Przeno??nik a odk??adane nawet urz??dze?? ka??d?? Uraz po??lizgni??cie rega??u spodowa?? drodze	\N	szk??o Potencjalny po?? mechanicznego sortuj??cych wrzucaj??c sortuj??cych wrzucaj??c tam osuwa?? zabezpieczenie usytuowana rega????w butle roztopach potknie poszed?? wcze??niej	pod??ogi higieny NAPRAWA/ szuflady drabin chwytak drabin chwytak naprawy lub kra??cowego cz????ci przeznaczy?? ??niegu przygotowa?? praktyk Dosuni??cie po??o??enie	\N	\N	\N
26	a4c64619-8c30-42bc-ac9a-ed5adbf5c608	2019-11-16	3	R-1	2019-11-16	11:00:00	0	piwnicy pieszych przechodz?? dokonania wylanie bia??a wylanie bia??a pochwycenia wymaga?? paleciaka Bez odprysk pr??dem awaryjnej mo??e m??g??by	\N	ewakuacyjnej blaszan?? biurowy zasalania ilo??ci zwracania ilo??ci zwracania porze kablach krzywo dzwoni??c wn??trze paltea powierzchni bariera bezpieczne u??ywali??my	pro??b?? os??aniaj??cej nara??ania przykryta muzyki Poprawnie muzyki Poprawnie powierzchni czarna podaczas przechowywa?? rega????w substancjami sterowniczej Dospawa?? ci??ciu kierowce	\N	\N	\N
27	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2019-11-23	3	R-9	2019-11-23	10:00:00	0	zatrucia ka??dorazowo wpychaniu ostreczowanej do zdrowiu do zdrowiu ze Podtkni??cie nog?? p??ytek sufitem maszynie gaszenia budynkami jako	\N	wszed?? terenu sta??o przewr??ci??y ??cieka trzeba ??cieka trzeba unosi?? szmaty usytuowana wgniecenie nawet RYZYKO pozosta??o??ci niej wchodz??c?? gotowych	rewersja Prosz?? naprawic/uszczelni?? poziome tym pr??g tym pr??g szatni odpre??ark?? przeno??nikeim podobnych trzecia premy??le?? oczomyjk?? m Dostosowanie Palety	\N	\N	2020-12-29
30	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2019-12-08	12	R2 podest 	2019-12-08	09:00:00	0	pod??ogi Pora??enie polerki skr??cenie ewakuacyjnym oddechowy ewakuacyjnym oddechowy nie powstania magazynowana oprzyrz??dowania ko??a drzwi szafy wysokosci Wyniku	\N	pracowince koc spompowa?? urazem jazdy oleju jazdy oleju stabilno??ci gdy dop??ywu 800??C materia??y unoszacy postaci przedzielaj??cej pi??trowane u??ama??a	by??a rur?? paletowego umy?? pi??trowania stosach pi??trowania stosach szczotki Codzienne ustali?? tokarskiego kierow folii kryteria dzia??ania H=175cm stanowisk	\N	\N	2021-09-20
37	2168af82-27fd-498d-a090-4a63429d8dd1	2020-01-04	3	R-7	2020-01-04	11:00:00	0	katastrofa widzia??em operatora doj???? substancjami elementem substancjami elementem z dekoratorni ze towaru nogi oraz znajduj??cych element pionie	\N	kartony oka przenoszenia ma??ym przekrzywiony brudn?? przekrzywiony brudn?? ucz??szczaj?? urz??dzenia trzymaj??c maskuj??ca podest??w zapali??o klatki zdjeciu zahaczenie zabezpieczony	os??on?? powiadomi?? przedosta??y bezbieczne co rega????w co rega????w elekytrycznych operatorom usun??c r????nicy rega??ami pojemnik??w malarni Om??wienie oprzyrz??dowania UPUSZCZONE	\N	\N	2020-12-29
45	2168af82-27fd-498d-a090-4a63429d8dd1	2020-03-07	3	automat R9	2020-03-07	12:00:00	0	nim obok porysowane po??ar zale??no??ci ??eby zale??no??ci ??eby dolnej obydwu ko??czyn zdrowiu pozosta???? por??wna?? Potencjalne swobodnego pojemnika	\N	wiatrem kiedy wentlatora zbiornika za??amania widoczne za??amania widoczne pozadzka Pan alumniniowej koc przewidzianych drzwiami bezpiecznikami rami?? obkurcza zamkni??te	pras?? podnoszenia ??cie??k?? pieszo sprz??tu prowadzenia sprz??tu prowadzenia powinien Przypomnienie pierwszej okre??lone usuwa?? okolicach czysto???? Przypomnienie st??uczk?? Uszczelnienie	\N	\N	\N
49	4f623cb2-e127-4e20-bc1a-3bef46e89920	2020-08-05	3	R-9	2020-08-05	19:00:00	0	efekcie trwa??y szybkiej elementu ludzi pr??dem ludzi pr??dem za??og?? ziemi d??oni- obs??uguj??cego Wyd??u??ony w2 poziom??w informacji prawdopodobie??stwo	\N	mo??liwego ??uraw wycieka zbiornika palete totalny palete totalny GA??NICZEGO okolicy g??rnej ci??cie Odpad??a platformowego o??witlenie we palnikiem pompki	rozsypa?? kratek prowadz??cych Maksymalna cz??sci kompleksow?? cz??sci kompleksow?? poziomej owini??cie inna stabilny przenie?? otworu kraw??dzie przeprowadzenie usuwanie mia??	\N	\N	\N
50	4f623cb2-e127-4e20-bc1a-3bef46e89920	2020-08-06	3	R-9	2020-08-06	19:00:00	0	Miejsce ewakuacyjnym oprzyrz??dowania ludziach paletyzatora zapewniaj??cego paletyzatora zapewniaj??cego niekontrolowane opa??enie wysoko??ci zagro??enie pracownik??w nast??pnie bramy Wypadki warsztat	\N	zaprojektowany wzrostu id??c alarm prac oparami prac oparami twarzy ODPRYSK ruchomy cz?????? pistoletu kropl?? alejce u??ama??a zauwa??y?? elektrycznych	spos??b jeden biurowego rozwi??zania kra??cowy mnie kra??cowy mnie stosowanie oprawy przej??ciu odpowiedniej suchym instrukcji sko??czonej prawid??owo celem Ragularnie	\N	\N	\N
53	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2020-09-11	3	R-1	2020-09-11	19:00:00	0	wylanie ca??ego urwana mi??dzy stopypalc??w pracownikami stopypalc??w pracownikami ewakuacyjnym Zanieczyszczenie przemieszczeie skutek zapalenia WZROKU palecie osob?? potr??cenie	\N	Przepi??cie oczekuj??ce 3 wewn??trzny gwa??townie monta??u gwa??townie monta??u produkcyjnych stabilno??ci Worki wej???? Poinformowano elektryka sobie r??wnie?? pomi??dzy mokrych	siatka przechowywania kasku pisemnej to p??ytek to p??ytek okoliczno??ci p??lkach niezgodny montaz bezwzgl??dnym oznakowany przeno??nik??w mocowanie poprawnego hydranty	\N	\N	\N
57	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2020-10-08	12	Podest R6	2020-10-08	15:00:00	0	Np uszkodzenie ze Poparzenie zmia??d??enie przewr??cenie zmia??d??enie przewr??cenie uszkodzenie godzinach pozostawione dnem Wypadki mocowania szybkiej elektryczna prasa	\N	ma wieszak??w PREWENCYJNE widoczny ryzyku odbi??r ryzyku odbi??r zwi??kszaj??cy u??ywana wpa???? zahaczenia Spalone boczniaka czyszczeniem zniszczony o??wietlenie zastrze??e??	??cianki szczotki kryteria gotowym ??cie??k?? pulpitem ??cie??k?? pulpitem magazynie upominania uruchamianym mog?? kolejno??ci opakowania Poprawnie s??u??bowo skr??cenie szt	\N	\N	\N
153	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-03-12	4	Szatnia damska-malarnia	2021-03-12	10:00:00	25	zdarzeniu wysoko??ci spi??trowanych zatrzymana kszta??cie nara??aj??cy kszta??cie nara??aj??cy siatka elektrycznej Zwr??cenie w??zki bramie ??ycia Droga g????wnego dopuszczalne	4	nieoznakowane u??ywania wszystkie zawieszonej tamt??dy metalowym/ tamt??dy metalowym/ odpalony s??uchawki oczywi??cie ude??enia mrugaj??ce gro????cy Magazyny materia??y sk??adowana zas??aniaj??	Ragularnie dot??p bortnicy Dosuni??cie konserwacyjnych stronie konserwacyjnych stronie modernizacje mocuj??cych ustalaj??ce powoduj??cy kieruj??cego usuwanie ograniczonym kompleksow?? przewod??w Przetransportowanie	\N	2021-03-26	\N
60	8d5a9bed-f25b-4209-bae6-564b5affcf3c	2020-10-13	12	Przeno??nik wynosz??cy st??uczk?? poza budynek do big baga z rejonu automatycznego sortu R1	2020-10-13	14:00:00	0	wi??kszych automatu Gdy wody brak ma??o brak ma??o bezpiecznej kt??re du??e zwichni??cia uszkodzenia j?? nadawa?? chemicznej pokonania	\N	zwi??kszaj??cy pomieszczenia odpr????arki wentylacyjn?? odsuni??ty zasilnia odsuni??ty zasilnia ??cinaki no??ycowego b??d??c zako??czenia inne urz??dzenia si??poza kamizelka Stwierdzono przechylenie	??cian poziomej planu form stanu brakuj??cy stanu brakuj??cy budowlanych podczas przemywania piecyk instalacji poziome obci????one pustych stabiln?? Przekazanie	IMG_20201013_122433.jpg	\N	\N
62	800f4ae5-d6e5-45bf-9df7-ac9a8dcab858	2020-10-16	4	Sitodruk- maszyna k31 (pyrosil)	2020-10-16	23:00:00	0	w2 oparami zatrzymana amputacja Ludzie nie Ludzie nie nie sto??u znajduj??ce od stop?? technicznym Utrudnienie bram?? uruchomienie	\N	budna Ca??o???? zawleczka zweryfikowaniu alejce ??atwo alejce ??atwo deszcz??wka moze napoje ??aduj??c bok kamizelek zwarcie ugaszenia ??wiartek konieczna	przyk??adanie spr????onego rowerze SZKLA planu sta??ej planu sta??ej punktowy swoich regularnego stosowa?? lekko miejsca ostrych naprowadzaj??ca miejscamiejsce przydzielenie	\N	\N	\N
66	8d5a9bed-f25b-4209-bae6-564b5affcf3c	2020-10-22	12	Linia R6 prawa strona podestu patrz??c w kierunku CK	2020-10-22	14:00:00	0	bezpiecznej zagro??enie przechodz??c?? rusza m??g?? powr??ci?? m??g?? powr??ci?? sufitem obs??uguj??cego cia?? niezbednych ograniczony po zamocowana pozostawiona Potencjalne	\N	wykonywana czym odcinaj??cy nadci??te pracownik??w rega??u pracownik??w rega??u ma W??ski zaolejone wewn??trzny niezabezpieczonym osobowy powtarzaj?? obecno??ci t??ust?? pod??og??	przymocowany ograniczenie paletami operacji przeniesienie temperatury przeniesienie temperatury ??wiadcz?? punktowy osoby/oznaczy?? k????ek twarz?? przydzielenie cegie?? Naprawi?? nara??aj??ca praktyki	\N	\N	2020-12-10
77	c307fdbd-ea37-43c7-b782-7b39fa731f90	2020-12-07	12	Brama na zewn??trz od strony R1	2020-12-07	16:00:00	0	kratce zosta??a Potkni??cie gaszenia uderzeniem przekraczaj??cy uderzeniem przekraczaj??cy Najechanie mog??y magazyn amputacja spodowa?? u??ytkowana Nara??enie drabiny 85dB	\N	warsztatu palecenie kolizji koordynator bezw??adnie spi??trowana bezw??adnie spi??trowana zbiornik magazynie o??wietlenia automatu zatrzyma?? b??l kondygnacja remontu niepoprawnie pr??dnice	oprzyrz??dowania odkrytej poprowadzi?? kontener??w roboczy pulpitem roboczy pulpitem czyszczenia noszenia stawania fragmentu lampy ca??y Obecna celu utw??r/ uprz??tn??c	\N	\N	2021-09-20
84	de217041-d6c7-49a5-8367-6c422fa42283	2020-12-24	3	Produkcja, automat R3.	2020-12-24	08:00:00	0	74-512 ostre sprz??tu wycieraniu czujnik??w schod??w czujnik??w schod??w zapali??a rozci??cie komputer magazynu paletach w???? Gdy sk??adowanych ??eby	\N	rozbieranych odmra??aniu produkcj?? produkcyjn?? potykanie kt??r?? potykanie kt??r?? ekspresu utraty pozwala os??ona ucz??szczaj?? ??uraw krzes??a pokrywaj??ce remontowych MWG	usun???? sk??adowanym gotowym poszycie pomocy koszyki pomocy koszyki niepotrzebnych przebywania skutkach butle SURA paletami Obecna dysz osuszy?? praktyki	\N	\N	2020-12-24
85	c307fdbd-ea37-43c7-b782-7b39fa731f90	2021-01-04	12	Automatyczna streczarka	2021-01-04	16:00:00	0	Przewracaj??ce odgradzaj??cej Potkni??cie mieniu informacji zalanie informacji zalanie magazynowana ??rodowiskowym- R1 bok Utrudnienie Ci????kie kt??ra pokonania kostki	\N	prze??wietlenie rynien kontenera wynikaj??cy zmia??d??ony podczs zmia??d??ony podczs rur?? buty b??d?? i polaniem odp??ywu Wa?? Router schody odpr????ark??	CNC kask dopuszczalnym Oosby kra??cowego linie kra??cowego linie pomi??dzy os??oni?? pojemnika porozmawia?? dna Najlepiej napawania OSB skr??cenie szczeg??lnie	\N	\N	2021-12-06
86	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2021-01-07	4	Plac, droga przy Frigo R9, W2.	2021-01-07	07:00:00	0	pozosta???? elementem przeci??cie ??le sk??adowania chemicznej sk??adowania chemicznej przeciwpo??arowego wystaj??cym nadstawek j?? wi??cej elektrod Opr????nienie palecie Mo??liwe	\N	szafy krzes??a otworzon?? przymocowany Jedzie po??piechu Jedzie po??piechu u??ywana zacz???? czeka?? osoba upad??a nagminnie przyci??ni??ty le???? zimnego p??omienia	postoju niesprawnego to stwierdzona tym Reklamacja tym Reklamacja pr??downic utrzymywania oznakowany pracowniakmi poprowadzi?? pr??g boczn?? Codzienne jednolitego suchym	20210104_160939_resized.jpg	\N	\N
102	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-02-09	17	Wyj??cie z hali nr 2 na zestawiarni??	2021-02-09	09:00:00	21	uszkodzenia nara??one automatycznego pojazdu zdarzenia ewakuacyjne zdarzenia ewakuacyjne sto??u wody gdzie uzupe??niania wpychaniu Zanieczyszczenie ??wietle korb?? pobli??u	5	Ci????ki awaryjny automatycznie zawadzenia ??uraw straty ??uraw straty zbiorniku dla kamizelek palnych zosta???? sprz??tania po??lizgn????em gaszenie innych korytarzu	razy d??u??szego spr????yn?? pilnowa?? stwarza??y p??lkach stwarza??y p??lkach przegl??danie parkowania instrukcji i niebezpiecze??stwo Konieczny ju?? towarem ??adunek stolik	\N	2021-02-16	2021-10-25
47	57b84c80-a067-43b7-98a0-ee22a5411c0e	2020-08-04	12	Sortownia, stanowisko sortowania przy linii R9	2020-08-04	11:00:00	0	reakcji pozycji Przewracaj??ce jest godzinach po??arowego godzinach po??arowego spadaj??ce kabel zbiornika mog??aby nogi wypadek wchodz??c?? osun????a zwichni??cie	\N	kropla ustawiaj?? sortuj??cych upa???? spa???? mia??am spa???? mia??am np automat gdy?? Niedosuni??ty ryzyku przekrzywiona zabezpiecze?? kropl?? minutach w????czony	k??ta rozwa??ne przynajmniej kierow pobrania kszta??t pobrania kszta??t Natychmiastowy Konieczny le??a??y przyczepach o??wietleniowej sta??ych magazynowania przeniesienie nowa konstrukcj??	IMG_20200804_111131_resized_20200804_111638680.jpg	\N	\N
109	31ccccef-7f8d-45e5-9e03-7e6e07671f0a	2021-02-11	4	Pomieszczenie laboratoryjne	2021-02-11	11:00:00	17	podczas zniszczony uruchomienie obszaru Przegrzanie smier?? Przegrzanie smier?? rozci??cie pionowej pobli??u Ustawiona Zdezelowana pokarmowy- zsuni??cia pr??by wybuch	1	otworzon?? doja??cia Zastosowanie przewr??ci??a lusterku w????czy?? lusterku w????czy?? butelki pierwszy butl?? olejem okolicach doporowadzi?? ??????tych ewakuacujne po??arowego zwi??zku	warunk??w pobierania Poinformowa?? Niezw??oczne celu warsztacie celu warsztacie orurowanie maty dna mechanicznych+mycie umocowan?? obci????enie technicznych nieodpowiednie pionowo ty??em	20210209_110224(002).jpg	2021-04-08	2021-10-20
341	c9f77484-7d39-44d1-aa7c-7c1ac09a24ce	2021-08-24	12	Sortownia zimny koniec R1	2021-08-24	13:00:00	16	instalacji tej regeneracyjne b????du st??uczenie gazowy st??uczenie gazowy nadstawek wa?? Podtkni??cie itp rozszczelnienie roznie???? ma??o samych pracownik??w	4	oznacze?? blisko pi??truj??c oparta wysi??gniku kieruj??c?? wysi??gniku kieruj??c?? kapi??ca nadstawek poruszajacej koszyka pieszego demonta??em Upadaj??ca pr??dnicy oczekuj??ce obrotowej	miejscu Inny wyrwanie zak??ada?? ci????ar linii ci????ar linii magazynie realizacji powoduj??cy odpowiedzialny ??atwe je??li ogranicenie por??cze by?? szuflady	schody.jpg	2021-09-07	2021-08-27
113	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2021-02-17	3	Na przeciwko okna sto????wki na produkcji szafka elektryczna i szafa rozdzielcza.	2021-02-17	18:00:00	6	ostrym gazowy znajduj??ce ostreczowanej poziomu maszynie poziomu maszynie przez zap??onu odk??adane wypadku- pojazdem dotyczy transportowej Nara??enie cz????ci	4	niszczarka skaleczenia przeciwpo??arowy niew??a??ciwie ryzyku mo??liwo??ci?? ryzyku mo??liwo??ci?? dyr strumieniem utrudniaj??cy p??omienia przechowywania uprz??tni??ta zapakowa?? GA??NICZEGO papierosa polegaj??c??	ilo??ci butli remont Kompleksowy mienia prawid??owe mienia prawid??owe szlifowania przegl??du higieny Codzienne warstwie podj??ciem wentylatora swobodny przestrze?? terenu	\N	2021-03-03	2021-11-17
119	de217041-d6c7-49a5-8367-6c422fa42283	2021-02-24	3	Pod sufitem hali W1 mi??dzy piecem do form a pomieszczeniem z piaskarkami.	2021-02-24	09:00:00	6	osob?? obydwu nadawa?? niepotrzebne r??ki zatrucia r??ki zatrucia Tydzie?? niekontrolowany zawroty poparzenia u??ytkowana g????wnego zap??onu nawet Prowizorycznie	4	ugasi?? wypalania sadzy pierwszy Pa?? s??upie Pa?? s??upie odprowadzaj??cej przeskokiem usuwaj?? szk??em szybka wid??owego ??ruby wej??ciu r??ku potrzebuj??cy	nast??pnie przetransportowa?? przymocowany nara??ania naprawienie jednoznacznej naprawienie jednoznacznej Pomalowa?? ci??g Poprowadzenie g??ry Kartony przepis??w os??on poziomej stabilno??ci os??yn	\N	2021-03-10	2021-12-08
133	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-02	1	Nowe biuro, wyj??cie z korytarza (pokoje BHP, Technika, Sortownia, Jako????) 	2021-03-02	11:00:00	4	niekontrolowany spi??trowanej pracownika schod??w spr????onego zap??onu spr????onego zap??onu stref?? pora??enia polerce palet?? odprysk Ponadto przeciwpo??arowej Zanieczyszczenie poparzenia	3	Berakn?? schod??w boli Gor??ca Staff muzyki Staff muzyki materia??y dojscie zezwole?? otoczenia Gor??ca dachowego zdrowiu pomieszczenia trafia u??ywaj??c	naprawic/uszczelni?? gazowy piecu szczotki jaki spr????onego jaki spr????onego skladowa?? skrzyni odgrodzenia kontenera sprawn?? w gazowej Mechaniczne kabli specjalnych	\N	2021-03-30	2021-10-25
360	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-09-28	10	Rega?? o numerze 08	2021-09-28	11:00:00	26	Nara??enie niestabilny ucierpia?? Zanieczyszczenie wysy??ki ludzkie wysy??ki ludzkie w??zka zablokowane operatora Zbyt budynk??w zgniecenia kart?? znajdujacej karku	5	instalacji Szlifierka zewn??trzna wieszak??w ostro godz ostro godz pracowince potkni??cia/upadku "NITRO" wyt??ocznika niestabilnej przez odprowadzaj??cej Nieprzymocowane urz??dzenia wskazany	Utrzymanie rury klamry wyr??b Pisemne pochylnia Pisemne pochylnia papieros??w chemiczych gaszenie DzU2019010 natrysk biurze szatniach przegrzewania zakamarki stabilno????	20210928_103934.jpg	2021-10-06	2021-12-07
373	2168af82-27fd-498d-a090-4a63429d8dd1	2021-10-19	3	R8 podest	2021-10-19	10:00:00	16	R7 budynku telefon fotela pracuj??cego sk??adowane pracuj??cego sk??adowane kryzysowej Potencjalna sytuacji robi?? zapalenia karku elektronicznego poziom??w Nara??enie	3	M560 trzeba stanowi?? czy prac?? Zanim prac?? Zanim nast??puj??ce zatrzymaniu opiera ponownie mia?? stali r??cznego p??n??w ma Zbli??enie	dopuszczeniem sk??adowanym realizacji farb?? warsztatu sztuki warsztatu sztuki szk??em mi??dzy p??ynem drug?? wyst??puj??cych substancjami pr??g ma??a widoczno??ci by??	R8podest3.jpg	2021-11-16	2021-12-08
376	2168af82-27fd-498d-a090-4a63429d8dd1	2021-10-19	3	R8 stopie??	2021-10-19	10:00:00	16	efekcie ga??niczego wylanie st???? Uderzenie zwichni??cie Uderzenie zwichni??cie wychodz?? magazynu stref?? powy??ej Pozostalo???? zn??w du??ej zaleceniami skutek	4	barier?? chwilowy pust?? Plama PODP??R wyt??ocznikami PODP??R wyt??ocznikami Wisz??ce ustawiaj?? paleta transportowe alejce stwierdzi?? wykonywana Berakn?? ale twarzy	pozwoli stref?? wy????czania wykonywanie ??adowania prze??o??enie ??adowania prze??o??enie st??uczk?? przypadku jego najbli??szej elektrycznego ??cian?? patrz??c zaj??cia za??o??y?? ??adunku	R8stopien.jpg	2021-11-02	2021-12-08
467	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2022-04-19	17	Zasypnik w1	2022-04-19	11:00:00	16	zatrzymania jednego grup skutkuj??ce Upadek spryskiwaczy Upadek spryskiwaczy ludziach b??d?? desek w??zki "prawie" skr??ceniez??amanie rozbiciest??uczenie sygnalizacji ostro??no??ci	4	Utrudniony kotwy zapakowa?? Stare pracowniczej pod??o??a pracowniczej pod??o??a nara??aj??c wytyczon?? trzymaj??c Dodatkowo spadnie transportowe trwania Ods??oni??te Klosz pieszym	r??wno u??ywana jazdy Zdj??cie utw??r/ wysoko??ci utw??r/ wysoko??ci mocuj??ce uwag?? oczu Wezwanie klosz warsztacie budowlanych punkt kolejno??ci wyznaczone	20220419_104508.jpg	2022-05-03	\N
52	800f4ae5-d6e5-45bf-9df7-ac9a8dcab858	2020-08-14	2	CI??GOWNIA CARMET  C1 ??? OBSZAR DEKORATORNI	2020-08-14	11:00:00	0	ci????ki wizerunkowe drugiego swobodnego Z??amaniest??uczenieupadek urz??dze?? Z??amaniest??uczenieupadek urz??dze?? wyrob??w zwichni??cia skr??ceniez??amanie pozosta???? Wypadki potkni??cia produkcji znajduj??cych wycieraniu	\N	pozostawiona speed zasypniku zwijania swobodne przepe??niony swobodne przepe??niony schodka misy Zdarzenie prasie do indywidualnej wsporniku ta??m?? stoj?? Zastawiona	dziennego jasnych myciu nt ??cian?? informacji ??cian?? informacji oznakowanie rekawicy przepis??w pod??o??u tak kierow sta?? piktogramami mnie blokuj??ce	\N	\N	\N
78	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2020-12-08	3	Oczomyjka na goracym ko??cu przy linii R7	2020-12-08	14:00:00	0	wypadek palety W1 ruchome z??amania wpychania z??amania wpychania uzupe??niania r????nych wyrob??w Przyczyna Przeno??nik m??g??by przypadku Bez nie	\N	u??wiadamiany dachowego stara CIEKN??CY nieprawid??owej znajduj??cego nieprawid??owej znajduj??cego wchodz??cych budyku foli?? przed wyrobami r??kawiczka ??aduj??c nier??wny awari?? Drobinki	spi??trowanej Uporz??dkowa?? jej licuj??cej drabimny korb?? drabimny korb?? stopni najmniej otwartych stanowisku niestwarzaj??cy przeno??nik??w osprz??tu musi blisko przewodu	\N	\N	2021-12-10
106	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-02-09	3	Linia R4	2021-02-09	11:00:00	6	Wyniku g??ow?? podno??nik uszczerbku jest widzia??em jest widzia??em du??e Zdemontowany komputer??w : ci??te uderzeniem pieszego stopek kotwy	5	kamizelki chwiejn?? otrzyma?? schodzi??am przestrze?? przygaszenia przestrze?? przygaszenia prawej wysokie przy??bicy pu??kach cieknie Pytanie za??lepia??a wysok?? tylne innych	ko??cowej konieczne kwietnia kuchennych Przygi???? odpowiedzialno??ci Przygi???? odpowiedzialno??ci pilnowa?? stosu ogranicenie pustych przypadku odpowiednich porozmawia?? ODPOWIEDZIALNYCH sprawdzi?? operatora	\N	2021-02-16	2021-12-10
1	57b84c80-a067-43b7-98a0-ee22a5411c0e	2019-02-05	2	Komin wentylacji na zewn??trz	2019-02-05	11:00:00	0	drukarka spi??trowanej wa?? paleciaka ??atwopalnych ko??czyn ??atwopalnych ko??czyn pieszych zagro??enie dostepu pieszego szatni r10 szk??d Poparzenie wpychaniu	\N	wskazuje podejrzenie po??lizgn???? ograniczon?? kiera oderwanej kiera oderwanej Zdemontowane pistolet stosuj?? s??uchanie g????boko??ci foli?? wchodz?? zalane spad??y magazynowych	chemiczych ruchom?? spi??trowane narz??dzi prawid??owego brakuj??cy prawid??owego brakuj??cy blachy niego ??rodka stoj??cej nadpalonego owalu nadzorowa?? t??uszcz jaki Sprawdzenie	IMG_20190205_101514.jpg	\N	\N
17	e8f02c5a-1ece-4fa6-ae4e-27b9eda20340	2019-10-01	3	Na zewn??trz budynku od strony zestawiarni wyj??cie od strony R9	2019-10-01	10:00:00	0	ci????kich sk??adowanie wy????cznika g????wnego osun????a k????ko osun????a k????ko tj paleciaka przechodz?? Miejsce tj wa?? znajdujacej zapali??a przetarcie	\N	wyniki tylko uszkodzeniu Automatyczna oderwanej but??w oderwanej but??w ch???? koc usuwania palnikiem sprawdzenia placu wentylacji spadaj??ce r??cznych u??ama??a	swobodnego drug?? celem kontener??w kuchennych sposobu kuchennych sposobu biurach odpowiedzialno??ci jezdniowe ewakuacyjnego ??rodka przyczyn natrysku przelanie pr??g grawitacji	CAM00518.jpg	\N	2019-10-08
131	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-03-01	4	Przed magazynem palet	2021-03-01	11:00:00	23	wysoki je??d????ce umiejscowionych ??rodk??w dostepu powoduj??cych dostepu powoduj??cych nadpalony w??zka g??ow?? obszaru Stary Zbyt cz??owieka doprowadzi?? spr????onego	3	boku podni??s?? podj????em cz??sto zagro??enia sygnalizacji zagro??enia sygnalizacji lewa gro????ce lamp za??o??enie osobowy innych wid??owych drabiny korzystania elektryka	uszkodzon?? stwarzaj??cy ponad kontroli sk??adowanego rynny sk??adowanego rynny hydrant??w produkcyjny jezdniowych innych szafki prze??o??onych foto towaru DzU2019010 stanowisko	Woezek2XXX.jpg	2021-03-30	2021-03-02
163	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	3	Przej??cie z GK na ZK R1	2021-03-15	13:00:00	18	obydwu kubek przechodz??c?? ??eby Z??amaniest??uczenieupadek wysoki Z??amaniest??uczenieupadek wysoki obydwu powietrza skr??ceniez??amanie uaszkodzenie powstania zgrzewania A21 jak g??ow??ramieniem	3	Regularne drabina st??uczk?? Pod polaniem jednego polaniem jednego wysoki otwieraniu ??ilny podjazdu ruchomych drug?? Jedzie Staff pulpitem zewn??trzn??	elementu Systematyczne patrz??c Rozmowy p??l G p??l G niezgodno??ci s??uchu operatora k???? przewod??w klej??ca uprz??tni??cie podbnej szklanej monitoring	Bez??tytuluXXX.jpg	2021-04-12	2021-03-15
188	8f1c2db0-ea39-4354-9aad-ee391b4f8e25	2021-04-14	1	????cznik pomiedzy star?? a now?? cz????ci?? biurowca I pietro 	2021-04-14	13:00:00	5	przedmioty Pracownik zgrzeb??owy Zwarcie u pojazd u pojazd desek kartony obecnym paletyzatora szczelin?? ga??niczego pora??anie wi??kszych nadstawek	2	metr??w zako??czona kocem wypi??cie skaleczenia uruchomi?? skaleczenia uruchomi?? wyniku prawdopodobie??stwo wpadaj?? u??ywa?? powierzchowna polaniem sprz??tania przytwierdzona posadzka stoj??cego	lekcji rozwi??zania kwietnia ograniczaj??cego drzwiowego ci??ciu drzwiowego ci??ciu przykr??ci?? ilo??ci przygotowa?? p??lkach spr????yn?? skrzynce przymocowany u??wiadamiaj??ce w??wczas szlifierni	Bez??tytulu.jpg	2021-06-09	2021-11-17
351	2168af82-27fd-498d-a090-4a63429d8dd1	2021-09-07	3	podest R-8,	2021-09-07	17:00:00	16	wieszak odpowiedniego Mo??liwy Mo??liwo???? zabezpieczonego gniazdko zabezpieczonego gniazdko Dzi?? potkni??cia cz????ci sprz??taj??ce starych olejem spr????one pracy element??w	4	stali kroplochwyt ty?? podjecha?? budowy ok budowy ok u??ama??a fasad?? innego niedozwolonych paletowego poruszaj??c?? elektrycznej lewa paru instalacje	p??l uwagi routera SPODNIACH upomina?? materia??u upomina?? materia??u scie??k?? naprawa dostawy przykr??ci?? owini??cie magazynu w??zek po????cze?? Trwa??e wyj??ciami	20210907_144716.jpg	2021-09-21	2021-12-08
374	2168af82-27fd-498d-a090-4a63429d8dd1	2021-10-19	3	R8 barierka	2021-10-19	10:00:00	16	zawadzenia zwarcia elementem ugasi?? upadaj??c Uszkodzony upadaj??c Uszkodzony nadpalony wylanie rozprzestrzenienie bramie prawej gasz??cych pieca si?? St??uczeniez??amanie	4	prasa przechyli?? przemieszczaj?? g????biej uleg??a odcinku uleg??a odcinku szmaty bortnica przej???? tygodnia k????ko gor??cymi r??kawiczki urz??dze?? ale innego	wyposa??enia przetransportowa?? kontroli trzech Czyszczenie przypadku Czyszczenie przypadku firmy sta??y prawid??owe foto podaczas nieodpowiednie g??ry wi??kszej poprowadzi?? biurowym	R8barierka.jpg	2021-11-02	2021-12-08
375	2168af82-27fd-498d-a090-4a63429d8dd1	2021-10-19	3	R8 barierka	2021-10-19	10:00:00	16	Po??lizni??cie innych wycieraniu okacia??a linie gotowych linie gotowych jednocze??nie substancji blacha obs??ug?? maszyny okular??w si?? robi?? ha??as	4	du??a zaciemnienie opad??w rozgrzewania kontener pory kontener pory szafa ewakuacujne ca??ej Gor??ce wype??niona dyr nier??wny ka??dym zatrzymanie Mo??liwo??c	firm ruchom?? przeszkolenie wype??nion?? kraw??dzi defekt??w kraw??dzi defekt??w U??ywanie OSB olej korb?? schody Odnie???? mo??e pod dopuszczalnym telefon??w	R8barierka2.jpg	2021-11-02	2021-12-08
462	c200ca1b-fa97-4946-94a2-626bd32f497c	2022-04-11	1	Sto????wka (na przeciwko dzia??u sprzeda??y)	2022-04-11	11:00:00	5	wp??ywem powierzchni zgniecenia wskazanym dekoratorni przygotowania dekoratorni przygotowania zabezpieczonego paleciaki Niepoprawne przechodni??w Ci????kie jako ognia w??zka upadaj??c	4	przemieszczeniem co?? zdjeciu kamizelek oddelegowany wi??ry oddelegowany wi??ry kolor od ruchomych pojemnik??w dosz??o lampy wentylacji stopniach "podest" poziomem	folii obci????one otuliny tylko takich zastawiania takich zastawiania szk??a produkcji jakim porz??dku mo??liwe przed g??ry otwierana kratk?? przewidzianych	IMG_20220411_114933kopia.jpg	2022-04-25	2022-04-14
496	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2022-06-02	3	na przeciwko zgrzeb??owego R2 obok wanienki do ch??odzenia form R2	2022-06-02	02:00:00	5	popa??enia b??d??cych po??arowego 74-512 obr??bie karku obr??bie karku poruszaj?? deszczu substancj?? Towar odci??cie szcz??k wychodz?? kt??ry rury	3	przytwierdzony uwagi umyte pu??kach wymaganej przemywania wymaganej przemywania balustad CNC dalszego zobowi??za?? co?? stopnie to uzupe??nianie alejki od	sto??u pol oczka demonta??u otwiera nadzorowa?? otwiera nadzorowa?? worki elektryczny boku r??kawiczek zadaszenia niestabilnych przej??ciowym Ustawi?? Doko??czy?? ryzyko	weze.jpg	2022-06-30	2022-09-22
500	c307fdbd-ea37-43c7-b782-7b39fa731f90	2022-06-02	2	Kontenery biurowe	2022-06-02	14:00:00	16	osobowej st??uczenie stawu Przygniecenie jest mienia jest mienia komu?? Oderwana okolo Niestabilnie zamkni??tej samym Z??amaniest??uczenieupadek w??zkiem nie	3	stanowi??ce manewr paletki kaskow p??k?? zawieraj??c?? p??k?? zawieraj??c?? Obudowa perosilem zdusi?? wyj???? czy??ci butle biurowca elektrycznych niewystarczaj??ce zapewnienia	sprz??tu warstwie si?? usytuowanie niesprawnego dok??adne niesprawnego dok??adne drba?? trzech ??wietl??wek wid??ach pojawiaj??cej Usuni??cie tablicy znajduj??cej zdj??ciu informacji	20220602_133124.jpg	2022-06-30	2022-09-22
91	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-01-15	12	Brama mi??dzy R1 a przedsionkiem z kartonami	2021-01-15	11:00:00	26	maszynki przewr??cenie Powa??ny Wypadki pracownikowi zasygnalizowania pracownikowi zasygnalizowania doj???? 74-512 skutkiem przewody r??kawiczkach Dzi?? rozlanie widocznego ZAKO??CZY??	2	Nieprzymocowane prawa wyrwane doprowadzi?? Dopracowa?? szfy Dopracowa?? szfy dzia??ania ma??a transporter kierunku wid??owy przypadk??w skutkiem Niestabilne wielkiego odstaje	uniemo??liwiaj??cy stanie tego otwarcie strefy ur??adze?? strefy ur??adze?? Poprawny monitoring pracy ??adunek Usuni??cie/ sie oczka Odkr??ci?? co sytuacji	\N	2021-03-12	2022-02-08
97	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-02-02	17	Krata przy piachu - daszek przy piachu	2021-02-02	11:00:00	2	miejscu gaszenia pora??eniu naci??gn????em nie kogo?? nie kogo?? Du??a jednoznacznego przerwy pobieraj??cej wyroby magazyn po??lizgu zak??adu po??ar	4	mo??liwo??ci?? ociekow?? Mo??liwe kogo?? przejazd resztek przejazd resztek pada o??witlenie frontowy potknie koc roztopach kraw????nik prawdopodbnie ga??nic ??ciany	ograniczniki przechowywa?? stan por??cze skrzyd??a napis skrzyd??a napis Infrastruktury Systematycznie jazda poustawia?? obszarze drba?? drogowego rzeczy czyszczenia u??ytkowanie	\N	2021-02-16	\N
355	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-09-20	2	Nowa malarnia, przej??cie przez drog?? dla  w??zk??w wid??owych w kierunku drzwi do toalety i wyj??cia w kierunku ul. M.Fo??tyn	2021-09-20	15:00:00	18	zahaczy?? drugiej bardzo oosby pras bram?? pras bram?? wysokosci si?? oddechowy pracuj??cego kontrolowanego rusza podczas ca???? ??????te	3	Odpad??a skrzyd??o zwarcie schody p??ytek piecu p??ytek piecu wi??c stwierdzona niszczarka zwisaj??cy przygotowanym przewr??cenia p??yne??o p??ytki wygrzewania p??omienia	pod??ogi ile FINANS??W w??zek lub pilnowa?? lub pilnowa?? informacja stanowisk form podest??w/ pode??cie kamizelk?? sugeruje dnia obs??ugi rozpinan??	Malarnia2(2).jpg	2021-10-18	\N
357	9c64da01-6d57-4778-a1e3-d25f3df07145	2021-09-21	12	Obok transportera na R7, dodane zdj??cie	2021-09-21	14:00:00	1	za lampy pusta dolnych si??owego paletyzatora si??owego paletyzatora uszkodzon?? gazwego Miejsce czytelno??ci substancji nara??one wyroby b??d??cych IKEA	2	Topiarz po?? dysze prowadz??cy w????czy?? wewn??trzny w????czy?? wewn??trzny wirniku podesty dopilnowanie transportu rega?? wymiany biegn??ce Regularne przewody R3	przymocowany przypominanie rampy Wyr??wna?? butli przepakowania butli przepakowania obs??ugi dopuszcza?? dost??pnych niepotrzebnych szk??a jedn?? zamka ??adowa?? pod??odze fotela	image-21-09-21-02-42-2(1).jpg	2021-11-16	2021-11-09
358	9c64da01-6d57-4778-a1e3-d25f3df07145	2021-09-21	12	Zabezpieczenie obok maszyny inspekcyjnej R7, dodane zdj??cie	2021-09-21	14:00:00	14	wyj??ciowych si?? uderzeniaprzygniecenia gotowe oparami bezpiecznej oparami bezpiecznej upadku Pomocnik wchodz??c?? rega????w uderzenia rozszarpanie Przer??cone widoczno??ci pochwycenia	2	sk??adowany agregat transportuje poziom poruszaj??c?? pr??bie poruszaj??c?? pr??bie ??ruby obejmuj??cych u??ywa?? izolacj?? zahaczy?? poinformowa??a konieczna chodz?? biurowej sk??adowanych	itp zaizolowa?? odgrodzi?? konieczno??ci Opisanie stanowisko Opisanie stanowisko rega??ami pojedy??czego napraw kryteria uszkodzonej schody oznakowany przez wyst??puj??cych spod	image-21-09-21-02-42-1(1).jpg	2021-11-16	2021-10-22
368	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-10-13	10	Obszar mi??dzy ramp?? 1 i 2 w MWG	2021-10-13	12:00:00	26	automatu skutek Niesprawny ci??gi zosta??a j?? zosta??a j?? wysoko??ci butli bia??a urz??dze?? Stary zewn??trzn?? wysoko??ci wybuch zsuni??cia	2	utrudnia przyczyni??o ??adowarki oleju sprawdzenia deszcz??wka sprawdzenia deszcz??wka opakowa?? za??amania umo??liwiaj??cych p??ynu Taras" w???? korytarzem Przechowywanie py????w ty??em	do??wietlenie identyfikacji CNC odpowiednio Przywierdzenie poprzecznej Przywierdzenie poprzecznej Widoczne piwnicy opisem narz??dzi transportowania sugeruje okoliczno??ci stolik dzia??u CNC	PaletaMWG.JPG	2021-12-08	2021-12-07
369	9c64da01-6d57-4778-a1e3-d25f3df07145	2021-10-15	12	Obok maszyny inspekcyjnej R7 - zabezpieczenie wystaj??cego silnika przed uderzeniem w??zka wid??owego	2021-10-15	11:00:00	1	rozpi??cie na sufitem materialne gumowe gwa??townie gumowe gwa??townie spos??b ??rodk??w oraz doj???? w ewakuacyjne odboju stopypalc??w rega????w	3	musi os??oni??te by sprz??tu spowodowa??o kto?? spowodowa??o kto?? wysi??gniku pomiedzy zabezpiecze?? pi??trze przechyli??a wykorzystane zakotwiczone przyczyni?? foto dzia??u	instalacji towaru bezpiecznym rega??ami ostreczowana bierz??co ostreczowana bierz??co ostatnia takiej zakresu wymienia?? informacj?? kwietnia pozostawianie przeprowadzi?? jazdy regularnie	\N	2021-11-12	2021-10-22
371	2168af82-27fd-498d-a090-4a63429d8dd1	2021-10-19	3	wykonanie podest	2021-10-19	10:00:00	16	b??d?? ucierpia?? ko??czyn towaru formy Niesprawny formy Niesprawny ??eby sk??adowanie wysoko??ci w???? wp??ywem pora??anie zagro??enia ucierpia?? gazu	3	uszkodzony sortuj??ce zauwa??y?? wsporniku py????w ca??y py????w ca??y przekazywane przytrzyma?? skokowego utrudniaj??cy przewrucenie improwizowanej wysoki przechyli?? ??ruby listwie	przechodni??w Karcherem Wyr??wnanie pust?? konsekwencjach oznakowa?? konsekwencjach oznakowa?? kt??ra umieszcza?? dnia w??a??ciwe kraw????nika za przyczyny czytelnym ??rub?? blisko	R8podest.jpg	2021-11-16	2021-12-08
380	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-10-25	3	Posadzka w pobli??u pulpitu sterowniczego dla automatu linii R1.	2021-10-25	12:00:00	18	st???? bariery stron?? usuwanie Mo??liwe PODP??R Mo??liwe PODP??R wypadekkaseta niepotrzebne st??uczki ??wietle powoduj??c?? kolizja porysowane pozostawione produkcyjnej	3	szlifierk?? stopnia Ka??dorazowo zewn??trznej sortownia przechodz??cej sortownia przechodz??cej stopie?? Magazynier Gniazdko zamykaniem stacji po??arowego ostro pomieszczenia swoj?? lusterku	O??wietli?? tendencji samoczynnego luzem modernizacje big modernizacje big opisem koszyki SZKLAN?? obci????one wyj??ciowych my?? te pojemnikach odbojniki Poinstruowanie	R1.jpg	2021-11-22	\N
384	2168af82-27fd-498d-a090-4a63429d8dd1	2021-10-29	17	piwnica	2021-10-29	02:00:00	19	ga??niczy szk??em cm konstrukcji z??amanie skutkiem z??amanie skutkiem 2m Niesprawny kratce i d??oni instalacja zdemontowane monitora przedmiot	4	przeskokiem Automatyczna w????e Profibus form?? kratami form?? kratami kraw????nikiem sekundowe nr3 upadku filtry robi??ca agregatu biurowej mechaniczne plamy	umo??liwiaj??ce lod??wki zabezpieczanie wyposa??enia u??ycie substancje u??ycie substancje dost??pnych przenie???? zakresu lub wej??ciu okre??lonym prace wyznaczy?? g??ry naci??cie	myjka.jpg	2021-11-12	\N
54	f87198bc-db75-43dc-ac92-732752df2bba	2020-09-14	3	R-2	2020-09-14	16:00:00	0	substancj?? ??rodowiskowe wystaj??ce lampy elektryczna prasy elektryczna prasy znajduj??cego trwa??ym czas ludziach paletach uszczerbek znajduj??ce mog??aby w??zka	\N	pojemnik ci??cia zdj??cia swoj?? ??r??cych dolna ??r??cych dolna Nr nich straty wentylacyjnym przymocowana WID??OWYM Osoby ponad u??ywaj?? rur??	Treba dwie przestrze?? konsekwencjach ponad oznakowane ponad oznakowane panelu hali ??wiadcz?? stosowania panelu Nale??y ga??nice kolor rewersja cienka	\N	\N	2020-12-29
120	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-02-24	11	Miejsce ??adowania w??zk??w wid??owych, naprzeciwko automatyzacji R7	2021-02-24	09:00:00	25	zosta??a piec uruchomienia Podkni??cie przedmioty dekoracj?? przedmioty dekoracj?? Wypadki drzwi wypadek spa???? w znajduj??cy mienie stronie sk??ry	5	Element bezw??adnie por??cz okolicach Regularne suficie Regularne suficie metalowych zdemontowana potkn????a ??????tych zap??onu Zdeformowana 700 automat pozosta??o??ci sk??adowanych	Przypomnienie SPODNIACH kra??cowy Umie??ci?? ryzyko Korekta ryzyko Korekta stabilno??ci niezb??dnych poziomej dzia??u substancj?? utrzymania dobr?? obszarze tak??e listwie	IMG-20210224-WA0004.jpg	2021-03-03	\N
387	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2021-11-02	4	Teren zewn??trzny przy warsztacie - wiata dla pracownik??w	2021-11-02	09:00:00	17	elektryczna Wystaj??cy zatrucia g????wnego liniach bok liniach bok czynno??ci wpychania linie prac?? kogo?? d??wi??kowej r??wnie?? siatka kontakcie	2	ko??cu ugina pomiedzy aby czas przechyleniem czas przechyleniem polaniem pzeci??ciami ??ciankach zwalnia p??omieni wid??owych poziomy ??rodkowego zosta?? ociekowej	pitnej szatni kolejno??ci Rozmowy stanowi??y osprz??tu stanowi??y osprz??tu typu naprowadzaj??ca O??wietli?? niebezpiecze??stwo zadaszenia informacji d??wignica Przeszkoli?? gumowe charakterystyki	20211102_080305.jpg	2021-12-28	\N
388	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-11-02	3	Przestrze?? obok pokoju przygotowania produkcji przy piecu W1	2021-11-02	23:00:00	10	Dzi?? le????ce pieszego widocznej zabezpieczenia form?? zabezpieczenia form?? bramy ca??ego ??miertelny MO??liwo??c drzwiami Mo??liwe du??ej uszczerbku przejazd	3	kart?? transportowa?? bariera opisanego wysoko odpr????arki wysoko odpr????arki agregacie 66 czyszczenia powy??ej biurowego niszczarka kolejn?? zgnieciona otwieraniem ty??	ustalaj??ce Czyszczenie Kategoryczny informacyjne wyznaczonego osprz??tu wyznaczonego osprz??tu Przypomnienie lokalizacji skr??cenie otuliny mienia ewakuacyjnej ustawiania stortoweni nap??dowych blokuj??c??	Ciecie.jpg	2021-12-01	2021-12-10
395	a6e35ba8-06de-4a85-8b4f-961bd7ff09d0	2021-11-19	4	Stary magazyn szk??a naprzeciwko nowych sortier??w	2021-11-19	11:00:00	25	od??amkiem dobrowadzi??o inspekcyjnej kracie pr??g pracuj??ce pr??g pracuj??ce elektrycznym przedmioty sk??adowania Towar wyj??ciem czas kanale lampa zagro??enie	4	przemieszczania schodkiem najni??szej wysy??k?? 2021984 elektrycznych 2021984 elektrycznych os??b stacyjka sytuacjach manualnej Nezabezpieczona wirniku wyst??puj?? biurkiem eksploatacyjnych otaczaj??c??	obecno???? butle element obci????enie Poinstruowa?? biurowym Poinstruowa?? biurowym przeno??nik chwytak wymieni?? R10 spr????arka naprawic/uszczelni?? tym Uzupe??ni?? przerobi?? podstaw??	IMG_20211116_132615.jpg	2021-12-03	\N
400	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-11-30	12	Linia R10	2021-11-30	09:00:00	19	ko??czyn Mozliwo???? Ipadek zdrowia St??uczenia o St??uczenia o ??niegu niekontrolowany gdzie Czyszczenie skutki dopuszczalne za??og?? ewentualny szafy	3	uszkodzonego czerwonych farb stanowisk komunikacyjnej biurkiem komunikacyjnej biurkiem lejku pochylenia gwa??townie zaciemnienie polskim Przycsik wykonuj?? zas??ania stalowe Wykonuje	jezdniowego przegl??dzie sk??adowanie/ gi??tkich blokuj??c?? niego blokuj??c?? niego przeznaczonych Zamkni??cie dot??p bez zasad Przytwierdzi?? rusztu Wyznaczenie Poprwaienie oczka	IMG_20211126_092700.jpg	2021-12-28	2022-02-07
402	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-11-30	12	Linia R1	2021-11-30	09:00:00	25	praktycznie transportowaniu spr????onego nog?? oraz mo??liwo??ci?? oraz mo??liwo??ci?? ostro g??ownie przewr??cenie laptop u??ytkowanie obydwu kryzysowej automatu znajdujacej	4	odpowiedniego reakcji chroni??ca firm?? naci??ni??cia My naci??ni??cia My formami opiera u??o??ono uszkodzeniu id??c przypadk??w o??wietlenie Jedna maj?? miejsca	Zabroni?? elektrycznych Odnie???? niekontrolowanym podobnych przewidzianych podobnych przewidzianych miejscach Us??niecie klamry wykonanie niepotrzebn?? wodnego wcze??niej wielko??ci Zaopatrzy?? wiatraka	IMG_20211130_080525.jpg	2021-12-14	2022-02-07
424	4bae726c-d69c-4667-b489-9897c64257e4	2022-01-20	12	Sortownia, ??ciana za paletyzatorem	2022-01-20	14:00:00	25	przechodz??c?? roznie???? element??w wysoki zamocowana karton??w zamocowana karton??w tj mog??o od??o??y?? zw??aszcza konstrykcji sko??czy?? transportow?? uszczerbkiem stronie	3	wpad??a 0,03125 szeroko???? zacz???? prac?? zarz??dzonej prac?? zarz??dzonej widoczno???? a odcinku zwi??kszaj??cy powodowa?? pokryw Topiarz przestrzenie spada zepsuty	rega????w wentylacja transportu za??adunku elektrycznych Przykotwi?? elektrycznych Przykotwi?? Rozpi??trowywanie chemiczych stabilno???? terenu zakrytych u??ytkowaniem KJ mechanicznych+mycie r??wnej producenta	20220120_135837.jpg	2022-02-17	2022-01-31
439	c969e290-7ed2-4eef-9818-7553f1ecee0e	2022-02-10	15	Dawny magazyn opakowa?? 	2022-02-10	10:00:00	25	pieszego karton obra??enia ??le w????a wci??gni??cia w????a wci??gni??cia wybuchowa Zwarcie ok otworze wi??cej swobodnego opakowa?? awaryjnego ognia	2	pracuj??ca powietrze ??ciany zdj??cie os??ona podeszw?? os??ona podeszw?? gor??cego przw??d Pojemno???? podestem przynios?? obs??uguj??cych wiadomo buty odleg??o??ci zatrzymaniu	kratki zakr??glenie pobierania ogarnicznik??w bezpo??redniego wykonywanie bezpo??redniego wykonywanie myjki po????czenie myciu Niedopuszczalne nap??dowych stosowanych Ragularnie nieco pieszo wysokiej	Usterka.jpg	2022-04-07	\N
441	c307fdbd-ea37-43c7-b782-7b39fa731f90	2022-02-10	12	Obok biura kierownik??w Sortowni	2022-02-10	15:00:00	9	cia??a nale??y wybuchupo??aru obs??uguj??cego Moz??iwo???? oparami Moz??iwo???? oparami budynku klosza ci??te zagro??enie Okaleczenie pozycji ci??gi przeje??d??aj??cy przekraczaj??cy	2	st??uczk?? zabezpiecze?? spiro cieczy schodka podtrzymanie schodka podtrzymanie Zdemontowane wody??? oprzyrz??dowania pozycji trzyma??em centymetr??w zatrudnieni przechodz??c?? otaczaj??c?? ??adowarki	niezgodno??ci drogowych wyl??dowa?? maszyn postoju ??adunku postoju ??adunku warstwie wej??cia ile przygotowa?? klej??ca nadzorem bie????co wyciek obci????enie zdarzeniom	20220210_152902.jpg	2022-04-07	2022-02-11
443	4bae726c-d69c-4667-b489-9897c64257e4	2022-02-11	12	Dach odpr????arki R7	2022-02-11	09:00:00	9	WZROKU niezbednych bram?? elementami pracy pobli??u pracy pobli??u PODP??R organizm Niekotrolowane R8 44565 pozostawiona hali konstrykcji wpadni??cia	4	Ga??nice bez Sytuacja napinaczy kosza automat kosza automat widoczna Elektrycy miejscu futryna wystaj??ce barierek paleciakiem w??zka foli?? rozbieranych	noszenia powieszni poziomych zapewnia wyposa??enie specjalnych wyposa??enie specjalnych Sk??adowa?? kotwi??cymi Uzupe??nienie stanowisk suchym wyciek Reklamacja jednocze??nie osuszy?? prowadnic	IMG-2022.jpg	2022-02-25	2022-02-24
446	de217041-d6c7-49a5-8367-6c422fa42283	2022-02-17	3	??ciana odzielaj??ca hale produkcjyjn?? W1 od magazynu piachu. Nad pomieszczeniami Elektryk??w/Dzia??u przygotowania produkcji.	2022-02-17	14:00:00	11	ci??te Gdy r??kawiczka W1 wi??kszymi acetylenem wi??kszymi acetylenem gazwego niekontrolowane samym ucierpia?? dost??p zaczadzeniespalenie ch??odziwo wycieraniu wid??owe	4	dyr rozdzielni aby stacyjce Zanim umo??liwiaj??cych Zanim umo??liwiaj??cych oderwie zewn??trzne swobodnego stoj??cego osadu trzymaj??c wcze??niej boczny ??ruby powietrze	kierownik??w k????ko telefon??w terenu DzU2019010 posegregowa?? DzU2019010 posegregowa?? pochylnia blacyy wi??kszej transportem zasilaczu piecyk uwagi wentylator kra??cowego Udro??enienie	IMG_20220217_135831.jpg	2022-03-03	2022-02-21
450	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-02-28	17	Obszar mi??dzy budynkiem zestawiarni a magazynem st??uczki, przy rozdzielni elektrycznej 	2022-02-28	09:00:00	11	po??ar Niesprawny wyj??ciem do: pozycji automatycznego pozycji automatycznego : kontrolowanego pobieraj??cej bezpiecznej powietrze kabel w Ludzie r??kawiczka	3	czynno??ci przestrzenie gipskartonowych rzucaj?? gazowe zwi??zane gazowe zwi??zane u??o??one pr??bie Wy??adowanie przeciwpo??arowy zdarzenia wraz zdj??cie drodze chwiejne work??w	Ministra szklarskich swobodny Rozporz??dzenie kable Udro??enienie kable Udro??enienie utraty zdrowotnych rodzaj mniejsz?? materia??u stosowaniu wyrobem rur?? szklarskich wej??ciu	IMG_20220228_092708_compress55.jpg	2022-03-28	2022-03-02
453	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2022-03-03	15	Warsztat CNC	2022-03-03	07:00:00	6	w????czeniu oczu potr??ceniem ga??nic i musz?? i musz?? produkcji MO??liwo??c monitora Zniszczenie sprz??taj??ce ta??m?? otwierania pojazdem Mo??liwy	3	przodu p??ynu czasie Wisz??ce dekorowanego wydostaj??ce dekorowanego wydostaj??ce utrudniaj??cy mocowanie przyczyn?? odpowiedniej maszynki telefon u??o??ono wystaj??cy Zatrzyma??y wanienek	okre??lone pracownik??w tymczasowe magazynowanie stwierdzona dna stwierdzona dna ci??cia owalu naklei?? ilo??ci Poprawnie elektrycznej spi??trowanych Poinformowa?? pracowniakmi pi??trowane	20220303_073109.jpg	2022-03-31	2022-04-12
455	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-03-25	3	R6	2022-03-25	14:00:00	18	przewod??w przypadku nie "podwieszonej" nim polerki nim polerki ka??dorazowo zalanej skutek naci??gni??cie cz????ci Uszkodzony wypadekkaseta zatrucia gazwego	3	drabin?? powoduj??cy jazdy brak??w wiaty osobom wiaty osobom kuchni doprowadzaj??c urazy otrzyma?? manewru tu??owia agencji budna klimatyzacji poziomem	spotkanie podestu/ planu posadzk?? okalaj??cego Uzupe??niono okalaj??cego Uzupe??niono by??o stwarzaj??cy podjazd rur?? stale pod??odze zezwala?? informacyjne posypanie hydranty	1647853350530.jpg	2022-04-22	\N
465	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2022-04-12	4	Stara malarnia	2022-04-12	12:00:00	5	otwierania naro??nik sko??czy?? prac szczotki do: szczotki do: Naruszenie ga??niczego zawroty wchodz??ca zamkni??tej opakowaniami materialne Bez zwiazane	4	??e wysoka skaleczenia przesuwaj??cy obszarze takich obszarze takich nieutwardzonej zastawia jego poruszaj??cy zawadzenia metalowych stop?? tekturowymi organy wodzie	??adunki sekcji wywozi?? r??wnej szk??o odbywa??by szk??o odbywa??by biurach niedozwolonych Przeszkoli?? instalacji obudowy patrz??c nap??dem ODBIERA?? obszaru pisemnej	20220412_121520.jpg	2022-04-26	2022-04-20
466	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2022-04-14	2	Kabina 1	2022-04-14	08:00:00	20	drzwi potr??cenie formy Potkni??cieprzewr??cenieskaleczenie trwa??ym jednej trwa??ym jednej kto?? spr????onego nieszczelno???? si?? samych wybuchowa wid??owym od??amkiem Wyniku	3	ciecz?? zg??oszenia termowizyjnymi DZIA??ANIE zastawianie zas??abni??cie zastawianie zas??abni??cie pod??og?? z??e Urwane sprz??t ??cianie Upadaj??ca podnoszono D??wigiem mie?? panelach	Zapoznanie drug?? trudnopalnego powinien niebezpiecznego stosowa?? niebezpiecznego stosowa?? zakr??glenie stopa swobodnego ruroci??gu przesun???? kurtyn przygotowa?? wieszakach uniemo??liwiaj??cych blokuj??ce	IMG-20220414-WA0021.jpg	2022-05-13	\N
476	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-04-29	12	Sortownia jak na zdj??ciu	2022-04-29	13:00:00	19	74-512 szk??a piec maszynie g??ow?? gazu g??ow?? gazu sk??adaj??c?? technicznym b??d??cych ska??enie temu temu pozosta??o??ci u??ytkowana Poparzenie	3	szlifierk?? rury Uszkodzona elektryczna unoszacy poszed?? unoszacy poszed?? rurach gro????ce kroplochwyt progu doprowadzaj??ce Rozproszenie pi??trze ??adnych nowej przemieszczaj??	p??lkach musimy bezpo??redniego z??bate oraz zastawionej oraz zastawionej umytym dojdzie swoich USZODZONEGO jaki stanowisku Powiekszenie budowy szeroko??ci UPUSZCZONE	20220429_112921.jpg	2022-05-27	2022-05-12
480	2a8b72ed-93ac-4e64-92a7-4346ffbf4c3a	2022-05-06	12	R9	2022-05-06	10:00:00	18	ewentualny oparta zale??no??ci R8 pochwycenia towaru pochwycenia towaru kontroli wystaj??cego uchwyt??w gazowy uszkodzeniu bramy skutki stalowa palet	2	substancja pod??og?? okazji zezwole?? r??ku ewakuacyjne r??ku ewakuacyjne przewr??cenia technicznego pionowej elektryczne rega????w cz??ste maksymlnie posiadaj?? produktu obszarze	miejscu sta??ych rozwi??zania Zapewni?? kotroli wszystkie kotroli wszystkie OS??ONAMI licuj??cej prze??o??enie odk??adczego hali przynajmniej kt??re pozosta??ego pracprzeszkoli?? oznaczone	IMG20220506085304.jpg	2022-07-01	2022-05-12
486	9c64da01-6d57-4778-a1e3-d25f3df07145	2022-05-25	12	Barierki os??aniaj??ce maszyny inspekcyjne - R7, R9, R10	2022-05-25	15:00:00	1	Pracownik godzinach kartony przekraczaj??cy bortnica oczu bortnica oczu futryny komu?? zanieczyszczona podkni??cia szczotki transpotrw?? przypadkuzagro??enia przypadkowe gotowe	2	stoj??cego kierowca urz??dzeniu przestrzegania mo??na s??uchawki mo??na s??uchawki ostrzegawczych nale??y Obecnie otwarta droga przechodz??cych przepakowuje/sortuje dzwoni??c sterowniczej pogotowia	wraz na smarowanie grawitacji dokonaci niezb??dnych dokonaci niezb??dnych prawid??owych oznaczony lokalizacji gazowy razem skladowania szyba Zabepieczy?? utrzymania zakup	image-25-05-22-02-59-1.jpg	2022-07-20	2022-05-26
493	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-05-31	12	Przy rampie za??adunkowej	2022-05-31	08:00:00	25	Podtkni??cie Pozosta??o???? omija?? futryny Przeno??nik Wystaj??cy Przeno??nik Wystaj??cy nieprzymocowana zerwanie Tym posadzki rura elektronicznego WZROKU Przygniecienie m??g??	3	zadad pile uzupe??niania otw??r poluzowa??a stopa poluzowa??a stopa 8030 WID??OWYM ci??gu ??adunek tekturowych tygodnia blacha obejmuj??cych ustawiaj?? budynku	ponowne potencjalnie zko??czenie zdarzeniach portiernii ka??dych portiernii ka??dych le??y Przed??u??enie Przestrzega?? steruj??cy Przypomnie?? zamurowa?? Pana piwnica Widoczne wychodzila	20220531_073245.jpg	2022-06-28	2022-05-31
499	c307fdbd-ea37-43c7-b782-7b39fa731f90	2022-06-02	2	Odgrodzenie maszyny Speed	2022-06-02	12:00:00	1	szyb?? Uszkodzona zap??onu prowizorycznego osun????a R7 osun????a R7 du??ym 40 cz?????? blachy uczestni??cymi przechodz??c?? odcieki charakterystyki rozszczelnie	2	posiadaj??ce kierunku niezgodnie resztek pod??o??na boksu pod??o??na boksu Niedosuni??ty spa???? powierzchni gaszenia szeroko???? Czynno???? zewn??trzna ??wiatlo przechodz??cych spi??trowane	realizacj?? rozpinan?? zapewnienia miejsce podest??w/ Zamkni??cie podest??w/ Zamkni??cie noszenia zasadami spi??trowanych pitnej Zabezpieczenie Sta??e wyznaczonym do no??ycami pojemniki	20220602_104122.jpg	2022-07-28	2022-09-22
193	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-04-19	12	R5	2021-04-19	14:00:00	5	tego przest??j uchwyt??w pusta pracownik??w naci??gni??cie pracownik??w naci??gni??cie tej wychodz?? pora??eniu zalania zmia??d??enie czas wp??ywem mokro uzupe??niania	3	funkcj?? produkcyjnych przewr??ci korb?? Ciekcie zasalania Ciekcie zasalania porze nieoznakowany stron Pojemno???? poinformuje g??rnym/kratka/ paru /ZURZYCIE pomieszczenia r????nica	dost??pu przypominanie bezpiecze??stwa ??cie??k?? Przypomnienie maszynki Przypomnienie maszynki bezpieczny hydrantu sprawdzi?? pi??trowaniu szklanymi ograniczonym wcze??niej od??amki ukara?? kierunku	\N	2021-05-17	2022-02-08
392	4bae726c-d69c-4667-b489-9897c64257e4	2021-11-16	3	Miedy ??cian?? zewn??trz?? budynku a odpr????ark?? linii R1	2021-11-16	08:00:00	3	zapakowanej gor??cejzimnej awaryjnej wybuch sortowni wzrokiem sortowni wzrokiem powr??ci?? wydajno???? wysoko??ci uszkodzenie dobrowadzi??o zimno upadek kontroli powodu czyszczenia	4	zniszczony py??ek Opr????nia but NIEU??YTE schodkiem NIEU??YTE schodkiem odpalony przedmiot dopuszczalnym przej???? przej???? skrzyd??o R8 palnych zalepiona Gor??ce	serwis wyeliminowania kraty podestu/ po??o??enie stawia?? po??o??enie stawia?? pr??dko??ci temperatury tematu ostrzegawczej wyst??pienia lampy szklanej stanowi pomoc?? futryny	20211116_092931_resized.jpg	2021-12-01	2021-12-10
310	eb411106-d321-41de-ab83-3f347a439da4	2021-07-16	2	Zej??cie ze schodow socjalu	2021-07-16	12:00:00	18	Uszkodzona odbieraj??cy sprz??taj??ce skutki oczu Niepoprawne oczu Niepoprawne pracownice bezpiecznej ustawione po??arowego reakcji kana??u energoch??onnej wypadek Wypadki	2	B????dne st??uczka oleju potencjalnie powiadomi??em odsuni??ty powiadomi??em odsuni??ty filtr??w pali?? trzeba miesi??cu przewidzianego cofaj??c zdarzaj?? palnych wyj??cie przeno??nika	wej??ciu sprz??tu ??adowania wyznaczyc kontener??w upominania kontener??w upominania powiesi?? hali pomocnika os??ony wypompowania Przeszkolic steruj??cego routera czysto???? punktowy	20210713_110316.jpg	2021-09-10	\N
407	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-11-30	15	obszar po magazynie opakowa??	2021-11-30	13:00:00	26	Spadaj??cy Ponadto j?? podwieszona przewr??cenia innych przewr??cenia innych Zadrapanie si??owego niezgodnie udzia??em upuszczenia upadku materialne- nast??pnie wyj??cie	2	umo??liwienia kamerach chodz?? Trendu sk??adowania brak sk??adowania brak pozwala wpad??o przestrzenie szklarskiego kartony gazowych podestowymi ewakuacyjne Przechodzenie umo??liwienia	os??aniaj??ce kontener??w schodka upadkiem roboczej Ocena roboczej Ocena tokarskiego wodnego materia??u miejscem pionowo wi??cej Odkr??ci?? przeznaczy?? poziom zabezpiecze??	\N	2022-01-25	2022-02-16
460	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2022-03-31	3	szafa elektryczna na przeciwko transformatora W1	2022-03-31	02:00:00	6	skutki mokrej substancji szybko utrzymania okolicy utrzymania okolicy przewr??cenie przypadkowe ??ycia zosta??o monitora nadstawek piwnicy Zanieczyszczenie oparzenia	3	zmierzaj??cego zgina?? g????biej wykonywanych wy????czonych st???? wy????czonych st???? b??d??c kt??ry u??ywany zdejmowania sortownia skrzynki zauwa??yli sadz?? ko??cowym sto??em	maszyny higieny wydostawaniem niebezpiecze????twem po????czenie Odgarni??cie po????czenie Odgarni??cie Zaopatrzy?? sta??ej regale prasy prawid??owych wyklepanie skrzyd??a Konieczny producentem substancje	\N	2022-04-28	2022-04-04
458	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-03-25	12	R8	2022-03-25	14:00:00	5	zgniecenia zawadzenie omijaj?? spadaj??cych ci??te przechodz??c?? ci??te przechodz??c?? ewentualny kszta??cie stalowa obecnym wchodz??c udzielenia wy????cznika gor??cym oznaczenia	3	powodu Stare ca??a ustawiaj?? kra??cowym tego kra??cowym tego wr??ci?? dosz??o przetarcia st??umienia palete listwa odpalony 0r Przeno??nik zauwa??y??	fotela demonta??u ??atwopalne sk????dowania kontrykcji odgrodzi?? kontrykcji odgrodzi?? temperatury wymianie przeszkolenie ich czynno??ci?? utrzymania trybie Rekomenduj??: starych kt??re	1647853350503.jpg	2022-04-22	\N
154	8aed61ca-62f5-445f-993b-26bbcf0c7419	2021-03-15	11	Obszar przy wej??ciu na magazyn wyrob??w.	2021-03-15	08:00:00	26	nt d??oni- ognia ustawione rozbiciest??uczenie posadzce rozbiciest??uczenie posadzce obecnym zdrowiu rega????w b??d?? budynkami Podkni??cie po??lizg procesu 4	3	wy????cznikiem siatk?? Staff napis porusza kieruje porusza kieruje zagi??te wysuni??ty ??atwopalnymi Je??eli wezwania PREWENCYJNE za??adunku ga??niczym po??o??ona swobodnie	wchodz??cych uzywa?? kt??rych bortnice Pokrzywione prze??o??onych Pokrzywione prze??o??onych ewakuacyjnego rur?? jak ukryty prze??o??y?? wiatraka przechowywania drodze odstaj??c?? pojemnik	IMG20210315065328.jpg	2021-04-12	2021-12-15
311	9c64da01-6d57-4778-a1e3-d25f3df07145	2021-07-16	2	Drzwi wej??ciowe z malarni na obszar biurowy	2021-07-16	13:00:00	14	wywo??anie po??arem gniazdko nt spos??b sprz??taj??cych spos??b sprz??taj??cych butli Miejsce okular??w Niepoprawne gazwego uszczerbku ewakuacji Ipadek najprawdopodobnie	4	narz??dzi Zastawienie ochrony wychwytowych Przekroczenie ewakuacji Przekroczenie ewakuacji wentylacyjnym szmaty nieoznakowane dzia??aj??cej pracuje przywr??cony zahaczenia korpusu st??uczki ni??ej	stosu technicznego b??bnach hydrant inna uszkodzony inna uszkodzony s??upkach wysokiej warsztacie dzia??aniem przej??ciowym uczulenie Uruchomi?? otuliny wysokich prawid??owe	20210713_110331.jpg	2021-07-30	\N
498	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2022-06-02	3	obok prasy R1 na przeciwko drzwi wyj??ciowych	2022-06-02	02:00:00	5	grup ko??cowej desek skutki: trwa??ym r??k trwa??ym r??k ka??d?? pozosta???? zalenie 85dB infrastruktury miejscu Problemy wiruj??cy uchybienia	3	u??ywany zza Uszkodzona ko??cu u??ywana producenta u??ywana producenta Wychylanie p??omie?? mocno poruszajacej zdmuchiwanego spryskiwaczy k??townika spad?? element??w wysuni??ty	cz????ci Przytwierdzi?? wymiana zamkni??te Zas??oni??cie Uruchomi?? Zas??oni??cie Uruchomi?? Pomalowanie tak??e przechowywania sekcji wspornik??w lod??wki licuj??cej stosowa?? szczelnie tj	tasma.jpg	2022-06-30	2022-09-22
3	57b84c80-a067-43b7-98a0-ee22a5411c0e	2019-06-06	3	R9	2019-06-06	11:00:00	0	po??aru godzinach Podpieranie bezpiecznej stopypalc??w mi??dzy stopypalc??w mi??dzy znajdujacej zawarto??ci gazowy uzupe??niania Przyczyna brak do obs??ugi wchodz??c??	\N	przemieszczajacych r??koma stosuj?? obci????e?? ??ruba pakowaniu ??ruba pakowaniu posadzk?? przytwierdzona prac Ewakuacyjne" rozwni??ty wentylacji przewr??ci??a p??omienia nieodpowiednie Royal	porz??dku konsekwencjach s??u??bowo porusza?? grawitacji plomb grawitacji plomb odgrodzonym transportowania kierownik??w piecu pracuje ??adowania hydranty ostro??ne Czyszczenie Poprowadzenie	\N	\N	2019-06-30
23	8d5a9bed-f25b-4209-bae6-564b5affcf3c	2019-10-27	3	Linia R1	2019-10-27	10:00:00	0	komputer karton okolic elementem paleciaka zahaczy?? paleciaka zahaczy?? upadaj??c amputacja czyszczeniu ??wietle rusza ponowne regeneracyjnego obecno???? drodze	\N	??eby uda??o p??omienia dopilnowanie przepakowuje/sortuje krzes??a przepakowuje/sortuje krzes??a s??u??y czym nieu??ywany prawie nowej kostrukcyjnie dziurawy Pyrosil si??ga??y ga??niczy:	niszczarki spi??trowane opuszczanej odk??adczego mycia szklanych mycia szklanych kraw??dzie Poinformowa?? Kategoryczny Poprawnie powierzchni stabilnie bortnicy ma??a specjalnych przeszkolenie	\N	\N	\N
31	2168af82-27fd-498d-a090-4a63429d8dd1	2019-12-13	3	R-9	2019-12-13	01:00:00	0	s??upek widoczno??ci Uswiadomienie brak swobodnego szk??d swobodnego szk??d sk??adowana spadaj??cych obra??enia doznania przeci??cie dotyczy wylanie nadstawki podkni??cia	\N	oczkiem os??ony korpusu Ewakuacyjne" puszki magazynier??w puszki magazynier??w elektrycznej zastawiaj?? Niezgodno???? technologiczny zdemontowana piecem spad??y alarm technicznych termokurczliw??	osprz??tu karton??w st???? steruj??cy prze??o??y?? kurtyn prze??o??y?? kurtyn takiego dosz??o napis okre??lonym niekt??re ochronnych przedostawania licuj??cej tak??e odp??ywowej	\N	\N	\N
36	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2019-12-25	3	R-1	2019-12-25	10:00:00	0	ewakuacji je??d????ce pod??odze sko??czy?? m??g?? drukarka m??g?? drukarka urwana skaleczenia kart?? u Uswiadomienie prasy Utrudniony naci??gn????em g??owy	\N	NIEU??YTE alarm wskazany drogami wykorzystano u??ywany wykorzystano u??ywany Przeprowadzanie szyby Ga??nice testu automatyczne jazda palete materia????w Upadaj??ca zacina	Oosby p??ynu kolor Przyspawanie/wymiana kabin opuszczanie kabin opuszczanie gniazdka tak ruchu problem ka??dej Rozmowy Przestrzeganie piwnica k??tem Rozpi??trowywanie	\N	\N	2020-12-29
48	57b84c80-a067-43b7-98a0-ee22a5411c0e	2020-08-04	9	W przej??ciu na magazyn, jak na zdj??ciu.	2020-08-04	12:00:00	0	pieszego Wyciek element??w nask??rka osuni??cia warsztat osuni??cia warsztat W1 rozlanie Wyciek drzwi zamocowana Sytuacja sie u??ytkowana nadstawek	\N	niemal??e przechyli??y wyje??d??a kart?? szafie 800??C szafie 800??C zsyp??w form?? ustawiaj?? pu??kach przesunie siatk?? utrudnia piecem silnego 0,03125	??atwopalne Foli?? patrz??c dost??pem oprawy firm?? oprawy firm?? kontrykcji dokona?? procownik??w pod po??o??enie podestu sol?? odpowiednich luzem ostrzegawczymi	IMG_20200804_115609_resized_20200804_121245323.jpg	\N	\N
70	80f879ea-0957-49e9-b618-eaad78f7fa01	2020-10-26	12	Wyj??cie na zewn??trz budynku w stron?? magazyny opakowa??	2020-10-26	12:00:00	0	wyroby st??uczenie spa???? wy????cznika elektryczna zapalenie elektryczna zapalenie gasz??cych pokonuj??cej A21 magazyn bok zalenie palet dnem pod	\N	klej??cej stoj?? pokryw widoczne podlegaj??cy doznac podlegaj??cy doznac szafy Nezabezpieczona naprawy r??czny Urwany miejsc chwiejn?? strony gro????ce gazem	jednoznacznej kontroli podnoszenia przechodzenia Poprawnie urz??dzenia Poprawnie urz??dzenia prowadzenia ca??ej Przytwierdzi?? dwie przy kasetony powinny powiadomi?? Pouczenie niestwarzaj??cy	\N	\N	2020-11-03
73	8f1c2db0-ea39-4354-9aad-ee391b4f8e25	2020-11-26	1	Biuro I pi??tro schody na recepcj?? 	2020-11-26	14:00:00	0	odbieraj??cy nadstawek wystaj??cego pozostawiona sprawdzaj??ce pozycji sprawdzaj??ce pozycji zdrowiu Tym palecie zniszczony rowerzysty potr??cenie rozmowa powietrza prasy	\N	produktu du??a przewr??ci?? boczny p??yty po??aru p??yty po??aru nieszczelno???? prawid??owego niebezpiecze??stwo oraz nadzorem sortierki pr??dem pory mocowanie Trendu	przej??cie Pomalowanie roboczej uczulenie Odsun???? matami Odsun???? matami uk??ad plomb magazynie tak??e posprz??ta?? niedopuszczenie sprawno???? i mechanicznych+mycie uszkodzon??	\N	\N	2020-12-10
488	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2022-05-27	3	R9	2022-05-27	14:00:00	18	zapali??a bok Pozostalo???? szklan?? bramie fabryki bramie fabryki ga??niczy gor??c?? bram?? udzielenia urata u??ytkowana prowadz??ce g??owy zgrzewania	3	posadzki zweryfikowaniu przechodz??cego obieg Szlifierka wod??gaz Szlifierka wod??gaz manewru Samoczynne zabezpiecznienia Ods??oni??te gniazko W??ski kaloryferze krople mniejszej doj????	stopa obudowy stanowi??y myjki poinstruowac do poinstruowac do za??agodzi?? uszkodzony Poinstruowa?? szk??a wszystkie zamocowanie bezpiecznej magazynowania wyklepanie informowaniu	IMG-20220526-WA0029.jpg	2022-06-24	2022-09-22
107	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-02-11	2	Przejazd obok maszyny do sleeve	2021-02-11	07:00:00	7	zosta??o nieporz??dek innego przewod??w zadzia??a elektrycznych zadzia??a elektrycznych niebezpiecze??stwo szk??em spadaj??ce organizm Wystaj??cy desek warsztat substancj?? Potencjalny	4	pionowo cz????ci zej??cie wyskakiwanie rozpuszczalnikiem r??wnowagi rozpuszczalnikiem r??wnowagi stacyjka polaniem listwie deszcz dyr innych utrzymania Trendu rega??ami efekcie	cykliczneserwis pieszych punktowy miesi??cznego ca??ego osprz??tu ca??ego osprz??tu metry Pana wej??ciem blach?? towarem powleczone DEKORATORNIE miejscamiejsce drodze skrzynki	IMG-20210210-WA0000.jpg	2021-02-25	2021-10-25
114	2168af82-27fd-498d-a090-4a63429d8dd1	2021-02-18	3	polerka R-1	2021-02-18	03:00:00	9	okolic transportowa paletach informacji palet pojazd palet pojazd zadzia??a uszczerbek strony rz??dka podczas lampy powoduj??cych sygnalizacji ewakuacji	4	du??o nasi??kni??ty przesun???? polerk?? Du??e poszdzk?? Du??e poszdzk?? odzie?? kamizelka otwieraniu wentylacyjny zg??oszenia pomog??a zranienia otoczenia je komunikacyjnym	pracy sta??ych konstrukcj?? siatk?? wentylacja pojemnik??w wentylacja pojemnik??w ??ancucha spod palnika rozlania przej??cia przej???? pozby?? liniami/tabliczkami pokryw mog??a	E379D0CE.jpg	2021-03-04	2021-10-12
117	5b869265-65e3-4cdf-a298-a1256d660409	2021-02-18	15	Warsztat CNC	2021-02-18	09:00:00	26	4 oprzyrz??dowania na mienie ludzkiego Zwr??cenie ludzkiego Zwr??cenie spadaj??cych stop?? wiruj??cy oosby tego plus wi??kszych uruchomienie wod??	4	stoj??c?? chwytaka ??wietliku le??y poruszajacej kocem poruszajacej kocem kostrukcyjnie s??uchawki zapali??o mrugaj??ce skrzyd??o ??wiartek trafia sto??u paleciaku bez	podest??w/ opuszczanie dotychczasowe odstaj??c?? czynno??ci kryteria czynno??ci kryteria wann?? nara??ania pod??odze pozycji kszta??cie pracownikom bhp spawanie piwnica otuliny	20210126_143853.jpg	2021-03-05	2021-10-20
324	8aed61ca-62f5-445f-993b-26bbcf0c7419	2021-07-27	2	Magazyn szk??a malarni	2021-07-27	23:00:00	17	uwagi robi?? pod??og?? awarii by??y ograniczenia by??y ograniczenia Ustawiona zachowania ostreczowanej rura po??lizgni??cie pod stanowisko przykrycia automatu	1	niestabilnie mog??ce przebywaj??cych Piec pol drugiej pol drugiej wytarte Zdj??te korpus godz mo???? miejsca stacji zu??yt?? g??rnej niebezpiecznie	pode??cie obs??udze dla rekawicy niego st????enia niego st????enia strony naprowadzaj??ca Obecna oznakowa?? miejscu ostrych zadziory przycisku powleczone ochronnej	Dzieckonamagazynie.jpg	2021-09-21	\N
79	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2020-12-14	12	Sortownia/ palc od linni R9	2020-12-14	09:00:00	0	pod??og?? wid??owym ??mier?? r??kawiczka upadaj??c cia??em upadaj??c cia??em s?? odbieraj??cy wiedzieli dotycz??cej sa instalacjipora??enie ludziach po??arowego Ustawiona	\N	otw??r po??lizg Ograniczona przygotowanym zamkni??cia ??rodka zamkni??cia ??rodka oznaczaj?? odpad??w brukow?? st??uczk?? okular??w zapali??o nalewania przedmiot??w zabezpieczone wysypywane	kt??ra t??uszcz pojemnik musi nieumy??lnego Przykotwi?? nieumy??lnego Przykotwi?? brakuj??cego budowy Poprawne s??upek posprz??ta?? usun???? potrzeby odk??adczego spawanie biurowych	\N	\N	2022-02-08
189	2168af82-27fd-498d-a090-4a63429d8dd1	2021-04-14	3	przej??cie ko??o R2	2021-04-14	20:00:00	18	t??ust?? wci??gni??cia uszczerbek urwana przedmiot : przedmiot : spowodowane si?? gotowych powstania automatu elektrycznych ci????kim spos??b wybuchupo??aru	4	zamkni??te poziomego palet?? kocem kroki: ci??nienia kroki: ci??nienia wody??? os??on?? polegaj??c?? id??c ??cieka zatrudnieni kogo?? przechylenie wykonywa?? wrz??tkiem	budowy Docelowo Lepsze przeszkolenie schod??w kolor schod??w kolor miejscu wieszak musi prawid??owo potrzeby by?? ruchom?? plomb Szkolenia powinien	\N	2021-04-28	2021-10-12
200	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-04-19	4	Mi??dzy budynkami, magazyn palet, produkcja	2021-04-19	14:00:00	25	osuni??cia nim rozszczelnie rega????w innymi dachu innymi dachu komputer r????nicy utrzymania polegaj??cy przez urz??dze?? wybuch braku beczki	4	miejsca bortnicy podtrzymywa?? p??yne??o w????czone dodatkowy w????czone dodatkowy silnika zbiorniku trzymaj??c przestrzega?? ztandardowej opadaj??c przywi??zany Prawdopodobn?? DOSTA?? papieros??w	ostrzegawcz?? klosz jak czujnik??w dolnej spr????onego dolnej spr????onego pod??o??u na pod??o??e formie wewn??trznych oprawy umo??liwiaj??cych Systematyczne informacyjne opuszczania	20210419_125954.jpg	2021-05-03	\N
255	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-05-17	2	Szlifiernia	2021-05-17	11:00:00	25	bezpieczne sprz??tu R1 g??ow??ramieniem spadek infrastruktury spadek infrastruktury zosta??o grozi otwarcia ludzkiego przycisk wp??ywem 2 dostepu Ludzie	4	awaria t??ust?? przechodz??c przewidzianych paletami pietrze paletami pietrze substancji Router mia??am nieoznakowane odnotowano niedozwolonych st??uczk?? szklan?? agregacie s??uchu	lepsz?? przyczepy czyszczenia dok??adne R10 starych R10 starych olej materia?? ci????ar niekontrolowanym wyposa??enie drabin cm czynno??ci?? grawitacji ograniczenie	20210517_104711.jpg	2021-05-31	\N
266	80f879ea-0957-49e9-b618-eaad78f7fa01	2021-06-09	12	Sort r 10	2021-06-09	13:00:00	5	wydajno??ci g??ow?? pr??g zdrowia ??????te Nikt ??????te Nikt Przer??cone rozdarcie wzrokiem pora??eniu bariery kt??ra zabezpieczaj??ca Mo??liwe przewr??cenia	4	otwory podnosi?? sobie wysoko???? zasilaczach Niestabilne zasilaczach Niestabilne przewr??ci?? g????boko??ci poszed?? akumulator??w foto substancjami ugaszono obszar Odpad??a przechodzenia	jazdy H=175cm spr????yn?? ga??nicy ??rub?? nieco ??rub?? nieco Kontakt s?? wystaj??c?? u??ytkowaniem skrzynkami substancje pora??enia sprawdzi?? terenu wentylacja	\N	2021-06-23	2022-02-07
301	de217041-d6c7-49a5-8367-6c422fa42283	2021-07-10	2	Przej??cie z sortu na malarnie na wprost drzwi do szatni.	2021-07-10	18:00:00	1	Zniszczenie Pomocnik Paleta magazynie Przygniecenie klosza Przygniecenie klosza obszaru stopie?? wiruj??cy skutkiem ga??niczy Przeno??nik transportu pieszych przerwy	2	o??wietlenie naro??nika kablach Operacyjnego efekcie opuszczonej efekcie opuszczonej niskich zak??adu usterk?? usuwania rega????w ziemi przepe??nione gazowa Berakn?? akcji	wi??kszej Niezw??oczne przek??adane stwarza??y metalowy patrz metalowy patrz otwierania przymocowanie stawiania tablicy paleciak??w k??tem kontrolnych korb?? Zabepieczy?? wystawieniu	BlachapiecW2.jpg	2021-09-04	\N
349	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-09-07	12	Wyj??cie na klatk?? schodow?? prowadz??ce w kierunku kadr nowego biurowca	2021-09-07	14:00:00	25	r??k gor??cej s??amanie zsuni??cia pokarmowy- u??ytkowanie pokarmowy- u??ytkowanie paleciaka zawalenie komu?? naci??gni??cie roznie???? spowodowanie rusza zadaszenia przygniecenia	4	ha??asu pomieszczenia Spalone urazu zamocowanie przej??ciu zamocowanie przej??ciu niewielka wentylatora drabin?? utrudnia??o poziom??w Prawdopodobna Mo??lio???? zaopserwowana ??wietl??wki technologiczny	substancji posprz??ta?? dost??pnych rozdzielni utrzymaniem s?? utrzymaniem s?? robocz?? strefie blachy wyra??n?? wyznaczy?? by??a Ustawi?? strony jezdniowe schod??w	PaletaMWG3.JPG	2021-09-21	\N
475	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-04-22	4	Na zewn??trz przed biurem	2022-04-22	13:00:00	25	mo??liwa poruszaj??cych jest sanitariatu awaryjnej po??arem awaryjnej po??arem ko??czyn infrastruktury Utrudnienie ba??agan g??ow?? po??lizgu niebezpiecze??stwo stanowisku dotycz??cej	2	Duda bezpieczne ??wiat??a zewn??trzn?? niegro??ne wyposa??one niegro??ne wyposa??one ??wietl??wki Niepoprawne odrzut usuwania wymaganej Jedna po lekkim oznakowanym wieczorem	??adowania cieczy otwieraniem przeznaczonym myjki wn??trza myjki wn??trza Przesuni??cie pomieszczenia przed czytelnym przenie?? warianty jezdniowymi ryzyko odp??ywu DOTOWE	20220422_114931.jpg	2022-06-24	2022-09-22
211	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2021-04-23	3	R10	2021-04-23	14:00:00	9	wyj??ciowych paleciaka magazyn budynk??w ko??czyn skutek ko??czyn skutek Utrudniony cia?? pionowej sprz??taj??ce przemieszczeie sie sk??adowanie ??niegu pozycji	3	CIEKN??CY work??w strat drabiny sk??adowana indywidualnej sk??adowana indywidualnej RYZYKO opu??ci??a centymetr??w nie uszkodzi?? lusterku ??adowarki Oberwane kana??ach Mokre	listwie drzwiami Je??eli podjazd gaszenie listew gaszenie listew USZODZONEGO elekytrycznych koryguj??cych drba?? GOTOWYCH nawet Dodatkowo Poprawne przej???? budynki	zdjecie22.04.jpg	2021-05-22	2021-10-12
228	a6e35ba8-06de-4a85-8b4f-961bd7ff09d0	2021-05-04	11	Stary magazyn szk??a przy ostatniej rampie	2021-05-04	06:00:00	25	substancjami swobodnie zalanie SKALECZENIE kostki mi??dzy kostki mi??dzy zwichni??cie- nie ??cie??k?? obecnym przygniecenia piecem przygniecenia gdzie transportowaniu	5	uleg??a ewakuacji 7 poluzowa??a odeskortowa?? widocznych odeskortowa?? widocznych widoczno???? kropli Rana przechyleniem dziura ??ruby bateri lusterku pojazdu ????cz??cej	si?? u??ywania swobodn?? kra??cowego wielko??ci czarn?? wielko??ci czarn?? miejsca oprawy upomina?? ukara?? nap??du W????CZNIKA schodkach przej??ciowym pomi??dzy kieruj??cego	IMG_20210502_142305.jpg	2021-05-11	2021-12-15
413	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-12-30	11	Rampa za??adunkowa nr 3 na TGP2	2021-12-30	13:00:00	26	??atwopalnych procesu upa???? pracownicy rury smier?? rury smier?? bezpieczne braku trwa??ym potr??cenie skutkuj??ce spadajacy ustawionej zaczadzeniespalenie wi??kszymi	5	op????nionych ??wietliku regale bliskiej zu??yto kasku zu??yto kasku chwiejn?? kosza wyrobem zas??abni??cie obecno??ci tu?? tylne dziurawy "boczniakiem" palet??	G????doko???? za??atanie sk????dowania siatka niekt??re gaz??w niekt??re gaz??w dalszy Zabranie oprzyrz??dowania Wyci???? Systematycznie zastawiali niezb??dnych zawiasie rozmieszcza poprzecznej	Przygnieceniemagazyniera.JPG	2022-01-06	\N
2	07774e50-66a1-4f17-95f6-9be17f7a023f	2019-02-13	10		2019-02-13	11:00:00	0	w??zkiem instalacja ludzkie elektryczna ka??dorazowo ewakuacyjnym ka??dorazowo ewakuacyjnym spr????onego po??arem przeci??cie zawarto??ci zahaczy?? opa??enie substancjami od??o??y?? ??rodowiskowe	\N	komunikacyjny pracami dachu mia??am bariera wid??ach bariera wid??ach wymieniono odpady u??wiadamiany gaszenie CNC stronach poinformuje potkn????a id??c odpady	stanowi?? jesli Pouczy?? przyj??cia big obarierkowany big obarierkowany rozlania skrzyni?? powiesi?? materia?? konsekwencjach otwieraniem p??l DEKORATORNIE uchwytu terenie	\N	\N	\N
267	2aac6936-3ec6-4c2f-8823-1e30d3eb7dfc	2021-06-14	11	Magazyn wyrob??w gotowych, rega?? DVN01 /04 , prz??s??o mi??dzy 4 a 5. 	2021-06-14	15:00:00	26	Cie??kie strat b??d??cych Przyczyna nara??aj??cy oprzyrz??dowania nara??aj??cy oprzyrz??dowania podtrucia z??ego telefon dekoratorni agregatu obtarcie 1 Podpieranie oznakowania	4	Przycsik wentylatora poruszaj??cy posadzk?? mo??na Podczas mo??na Podczas 8m podestach d???? osob?? w??ywem rozbieranych skrzyd??o no??ycowym kostrukcyjnie zaworu	potrzeby otwieraniem niestabilnych kontener??w drodze stosowanych drodze stosowanych system Uniesienie wspornik??w stabilnym os??b operator??w Powiekszenie UPUSZCZONE tokarskiego otwartych	1.jpg	2021-06-28	2021-12-15
348	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-09-07	12	Linia transportuj??ca R10	2021-09-07	14:00:00	23	detali dopuszczalne wyj??ciowych st???? stopni prawdopodobie??stwo stopni prawdopodobie??stwo jednego transportowanych zg??oszenia innymi Cie??kie r??k os??b zaczadzeniespalenie Wyd??u??ony	3	tokarki kiedy podstawy boku medycznych centymetr??w medycznych centymetr??w widlowy d??ugie uszkodzeniu schodkach kawe??ek Wygi??ty w??zka Piec Ograniczona trwania	wp??ywem Wyprostowanie zakr??glenie budynki kraw????nika grawitacji kraw????nika grawitacji jaki stosowa?? Wymieniono bramy przykr??cenie przej??ciem biurowym s??upka posadzce rozdzielcz??	PaletaMWG3XXX.JPG	2021-10-05	\N
379	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-10-15	10	Alejka mi??dzy rega??ami od strony dekoratorni	2021-10-15	11:00:00	26	zablokowane uzupe??niania Towar materialne przebywaj??cych si??owego przebywaj??cych si??owego wiruj??cy Pozosta??o???? przechodni??w wid??owy wystaj??c?? s?? zaparkowany opakowaniami Utrata	5	zdj remontowych zewn??trzna upadkiem wentylacji zu??yt?? wentylacji zu??yt?? wentylacyjn?? stwarza nich nisko bokami rega??em Deski panuje problem puszki	Wymieniono otworu Dodatkowo podestowej Przestawienie ma Przestawienie ma wanienek Wezwanie podstaw?? panelu oceny palenia dopuszczalna listwach kuchennych przednich	\N	2021-10-28	2021-12-07
409	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-12-02	11	Teren przed TGP1	2021-12-02	14:00:00	26	rowerzysty odk??adane zniszczenia ludzie- mog?? cm mog?? cm ga??nicy osuni??cia elementu ludzie- dotyczy zahaczenie poruszaj?? napojem otworze	3	py????w Ustawienie znajduj??ce Zapewni?? ustwiono surowc??w ustwiono surowc??w pomoc?? bliskim znajdowa?? w i z???? serwisuj??cej ????cz??cej butelki je	kt??re przeszkolenie komunikacj?? utraty kratk?? Reorganizacja kratk?? Reorganizacja miejscu odp??ywowej le??a??y maseczek posegregowa?? o??wietleniowej dwustronna ostreczowana system??w skutecznego	TekturaMWG.JPG	2021-12-30	2021-12-15
5	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2019-07-09	2	Sitodruk	2019-07-09	00:00:00	0	jest produkcji uszkodzenia potencjalnie Przeno??nik upadku Przeno??nik upadku uszczerbkiem oderwania informacji by przest??j sygnalizacji r??wnie?? wpychaniu potr??cenie	\N	wychodzenia bezpieczne skaleczy?? magazynier??w wyrzucane z???? wyrzucane z???? gazowy bliskiej no??yce pr??g transportera korytarzu zaciera paletyzatora zabezpieczony skutkowa??	ukierunkowania rusztu lub farb?? ga??nicy miejscami ga??nicy miejscami r9 odblaskow?? pot??uczonego kratek dooko??a przeznaczeniem osoby puszki miejscach pod??o??e	\N	\N	\N
8	07774e50-66a1-4f17-95f6-9be17f7a023f	2019-08-08	7	Magazyn wyrob??w gotowych 2 i 3	2019-08-08	11:00:00	0	okaleczenia innymi wid??owego oprzyrz??dowania spadek koszyk spadek koszyk Podpieranie mog??aby szybkiego spr????onego braku pr??dem pracownice gazowej po??lizgni??cie	\N	sterowania wentylatorem kawe??ek skaleczy?? Rozproszenie potkn????a Rozproszenie potkn????a przewr??ci??y os??b ale przesunie do??wietlenie pomiedzy pr??dko???? akurat Podest temperatury	napis s??upka pode??cie lewo przepis??w operatorom przepis??w operatorom raz kontroli ratunkowym upadku nieodpowiednie pieszo stabilno??ci ga??nice sprz??ta?? przypominanie	\N	\N	\N
35	4f623cb2-e127-4e20-bc1a-3bef46e89920	2019-12-20	3	R-9	2019-12-20	18:00:00	0	przedmioty przewod??w elektrycznych zdarzeniu wstrz??su g??ow?? wstrz??su g??ow?? elektrycznej awaryjnego ca??ego przejazd sufitem zmia??d??enie oczu straty pojemnika	\N	Przechowywanie hali docelowe wod?? spad??o nieoznakowanym spad??o nieoznakowanym zosta??wymieniony droga automatyczne Wdychanie sotownie dw??ch 3 gro????ce ucz??szczaj?? proszkow??	kierow odpowiedzialny bezpieczny/ kotwi??cymi miedzy DOTOWE miedzy DOTOWE drabimny rozlania telefon??w ci????ar konieczne prawid??owo budynki miejscami spawanie prze??o??onych	\N	\N	2020-12-29
38	f87198bc-db75-43dc-ac92-732752df2bba	2020-01-10	3	R-8	2020-01-10	23:00:00	0	pojazdem Wyciek oparami pod??og?? sprz??t prawdopodobie??stwo sprz??t prawdopodobie??stwo ZAKO??CZY?? gor??cym kt??re rozmowa pod??odze wydajno???? W1 bok zalenie	\N	pojazdu wybuchowej blaszan?? mu upad??y przytwierdzona upad??y przytwierdzona serwisuj??cej wyra??a?? zaopserwowane si?? BHP Otwarte stosuj?? ??mieci sta??o Dekoracja	o??wietlenia substancje przeprowadzenie ostro??no??ci firm rega??ach firm rega??ach Poinstruowa?? poprawnej bramy uchwyty nadpalonego nagan?? Natychmiastowy usun??c przerobi?? podestowej	\N	\N	\N
41	4e8bfd59-71d3-44b0-af9e-268860f19171	2020-02-07	3	WannaNr2	2020-02-07	10:00:00	0	form zawroty pot??uczenie zdemontowane odgradzaj??cej pracownicy odgradzaj??cej pracownicy reakcji hali warsztat automatycznego Upadek s?? Pochwycenie wp??ywu St??uczenia	\N	pi??truj??c dozownika Drogi ??ruby pode??cie przej??ciu pode??cie przej??ciu spowodowany u??ama??a windzie/podno??niku aluminiowego Ka??dorazowo wielkiego naci??ni??cia zniszczonej piecyku Czynno????	urz??dzenia rowerzyst??w Usuni??cie/ dojdzie maszynki sekcji maszynki sekcji dwustronna takiej brakuj??cego t??ok sol?? porz??dku Ragularnie Sta??e robocze montaz	\N	\N	\N
43	2168af82-27fd-498d-a090-4a63429d8dd1	2020-03-07	3	R-9	2020-03-07	12:00:00	0	niepotrzebne by??y r??ce szk??d najprawdopodobnie wa?? najprawdopodobnie wa?? plus Du??a spowodowanie Mo??liwe skutkiem umieli wybuchu szk??a wa??	\N	dystrybutorze przewidzianego Dnia przw??d klawiszy gro????ce klawiszy gro????ce lec?? kilku dach odpowiedniej fragment przej???? leje potkni??cia trwania r??cznego	monitoring przeprowadzenie przed istniej??cym kierownika ustawia?? kierownika ustawia?? podwykonawc??w t??ok ustawiona ta??m?? przewod??w podno??nikiem odpowiednie niestabilnych j??zyku przyk??adanie	\N	\N	2020-12-29
51	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2020-08-14	2	C1 Malarnia	2020-08-14	11:00:00	0	godzinach zsun???? zatrucia futryny wyj??ciem Utrudnienie wyj??ciem Utrudnienie p??ytek uchwyt przechodz?? przewr??cenie opa??enie kabli chemicznej automatu oprzyrz??dowania	\N	Uszkodziny s?? obs??ugi swobodnie blacha pod??o??a blacha pod??o??a w??asn?? agregatu ograniczaj?? kubek usuwania Stanowisko naje??d??a maskuj??ca futryna otwartych	higieny mijank?? przesun???? musimy farb?? siatk?? farb?? siatk?? pobierania powieszni futryny kt??rzy niestwarzaj??cy punkt spawark?? premy??le?? nara??aj??ca lod??wki	\N	\N	\N
63	de217041-d6c7-49a5-8367-6c422fa42283	2020-10-16	3	R1 - polerka	2020-10-16	22:00:00	0	WZROKU ga??nic zimno obudowa przechodz??ce zabezpieczeniem przechodz??ce zabezpieczeniem uderzeniaprzygniecenia z??ego Przegrzanie by??y bok gotowe ludzie- ma Stary	\N	dolna gazowy klapy nagminnie wymaga?? ruchem wymaga?? ruchem p??yne??o kraty przek??adkami widocznym Wdychanie wirniku systemu Worki skladowane osobom	transportem okoliczno??ci cz??stotliwo??ci ostro??ne bezpiecznie Uniesienie bezpiecznie Uniesienie jednocze??nie usun??c musz?? uprz??tni??cie d??u??szego rozlania substancje dalszy przestoju st??uczk??	\N	\N	2020-10-19
64	de217041-d6c7-49a5-8367-6c422fa42283	2020-10-20	3	Wystaj??cy z ziemi fragment blachy, teren za piecem w2.	2020-10-20	07:00:00	0	zanieczyszczona pusta Ci????kie pojazdu komputer pracownice komputer pracownice czego Gdyby mi??dzy zdrowia Wyniku po??lizgu wiedzieli mi????nie cia??em	\N	przemieszczajacych ??adowarki Operacyjnego wystaj??cy zak??adu Post??j zak??adu Post??j odsuni??cie dopad??a otrzyma?? kluczyk budyku sta??o Staff klucz Niepawid??owo indywidualnych	pod????czenia ??adunek obszarze LOTTO producenta/serwisanta prz??d producenta/serwisanta prz??d Poprowadzenie sprz??ta?? rekawicy powierzchni?? sk????dowania os??aniaj??ce przed prace niezb??dne lewo	\N	\N	2021-12-10
65	57b84c80-a067-43b7-98a0-ee22a5411c0e	2020-10-22	2	Szlifiernia, na stanowisku szlifowania	2020-10-22	10:00:00	0	czujnik??w ??le sie Niepoprawne zimno uruchomienie zimno uruchomienie je??d????ce podkni??cia fabryki wysoko??ci Lu??no magazynowana hali zapewniaj??cego delikatnie	\N	kroplochwyt opadaj??c si?? kropli czy krzes??a czy krzes??a wielkiego skaleczy?? zaczynaj??ca wid??ami produktu kondygnacja spiro zatrzyma?? zwr??ci?? dolna	przek??adane poruszaj??cych swobodne kumulowania spi??trowanej rodzaj spi??trowanej rodzaj hydrant mo??liwie oznakowa?? palenia kable konserwacyjnych bramy furtki firm Uszczelnienie	\N	\N	\N
72	2168af82-27fd-498d-a090-4a63429d8dd1	2020-11-24	3	przy awarii no??yc C, D zapali?? si?? smar i sadza na fliperach pod oczkiem,	2020-11-24	17:00:00	0	potkni??cia informacji skokowego przewody b??d?? sterowania b??d?? sterowania spadaj??ce po??lizg ewentualny st??uczki ostra cz?????? ewentualny po??lizg czyszczenia	\N	zastawia Uszkodzona przewod??w zabezpieczone DZIA??ANIE oznacze?? DZIA??ANIE oznacze?? sprz??t nieutwardzonej robi??ca szatniach spe??nia osobom py?? elektryczne d??ugo??ci aluminiowego	obudowy Sprawdzenie ODPOWIEDZIALNYCH nadzorem bez demonta??u bez demonta??u ci??ciu sprz??t uszkodzony pr??t przerwy przysparwa?? odrzucaniem dolnej codziennej producentem	praceniebazpieczne.jpg	\N	2020-12-29
125	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-02-25	4	Droga wewn??trzna, odcinek mi??dzy biurowcem a magazynem wyrob??w gotowych	2021-02-25	12:00:00	23	u??ycia produkcji rusza dachu trzymaj?? dostep trzymaj?? dostep kogo?? Pomocnik gwo??dzie wstrz??su stanowisko zawalenie zawalenie g??ow?? karton	4	r??cznych pojemnikach pr??g u??wiadamiany mnie czyszczenia mnie czyszczenia otrzyma?? pozostawiony nich wcze??niej czo??owy usuwaj??ce kaskow gotowymi otworzeniu panelach	poprzednich dopu??ci?? wid??owych uszkodzon?? ukara?? KJ ukara?? KJ sterowniczej ??rodk??w pilne ostrych Proponowanym odrzucaniem pojemnikach ich przykr??cenie brama/	\N	2021-03-11	\N
87	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-01-13	12	Prasa R6	2021-01-13	12:00:00	16	ca???? Potencjalny charakterystyki Zatrucie pionowej maszynie pionowej maszynie trwa??ym zawroty r??wnie?? g????wnego ognia element??w kabel sk??adaj??c?? zahaczenie	3	schodkiem opalani/zgrzewania maj?? ci??gu owini??ty pozosta??o???? owini??ty pozosta??o???? wy????czonych pozostawione miejscu zabiezpoeczaj??ca oczu zestawiarni zamkni??te roztopach powierzchni schodach	ga??niczy ostatnia o posypanie piecyka k??ta piecyka k??ta ostreczowana poruszanie podeswtu no??ycowego kumulowania ryzyko palet pode??cie specjalnych firm??	\N	2021-02-11	2022-02-08
99	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-02-03	11	Nowy Magazyn 	2021-02-03	12:00:00	26	spowodowane Pora??enie wod?? trwa??ym godzinach efekcie godzinach efekcie zagro??enie ??miertelny r??k zrani?? obudowa silnika pot??uczenie konsekwencji Podtkni??cie	3	chodz?? przymocowana otrzyma?? przytrzyma?? Ciekcie Wychylanie Ciekcie Wychylanie zawadzi?? uprz??tni??ta wychodz??cych ale przewr??ci palnika moze po??piechu niewystarczaj??ce opi??ek	o??wietleniowej kabla w pol okolicy foto okolicy foto regularnej por??cze nakazie ??ciera?? przykr??ci?? te podnoszenia temperatur?? Mycie pilne	\N	2021-03-03	2021-12-15
101	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-02-09	17	dach przy sk????dowisku piachu	2021-02-09	07:00:00	15	odcieki polegaj??cy produkcji ko??a posadzki st??uczki posadzki st??uczki wiedzieli Opr????nienie uderzeniaprzygniecenia obszaru Uswiadomienie mog?? ??????te Pracownik mog??a	5	wibracyjnych Linia Uszkodzona 66 hamulca odbiera hamulca odbiera zezwole?? przytwierdzona TIRa widoczny je zsyp??w jedn?? zaciemnienie pode??cie schodka	stabiln?? trudnopalnego dok??adne Uszczelnienie je??li budowlanych je??li budowlanych otwierania odpre??ark?? towarem konstrukcj?? kierowce USZODZONEGO naprawic/uszczelni?? niemo??liwe poruszaj??cych Je??eli	\N	2021-02-16	2021-10-25
108	2168af82-27fd-498d-a090-4a63429d8dd1	2021-02-10	3	R4	2021-02-10	17:00:00	25	ludzie- mog??a Balustrada ZAKO??CZY?? jest powr??ci?? jest powr??ci?? urazy dozna?? bram?? roznie???? ma napojem przypadkuzagro??enia palety znajduj??cego	3	spowodowalo napinaczy stopy spa???? wci??gni??cia nieutwardzonej wci??gni??cia nieutwardzonej czerpnia by brudn?? prowadz??ce obejmuj??cych koszyka inn?? zewn??trzne pokrywa zosta??	maszynki u??wiadomi?? trzech dachem ograniczaj??cego Kartony ograniczaj??cego Kartony si?? nadzorowa?? sprawdzania odpowiedni?? pozby?? pr??g elektrycznych blokady ci????ar pakunku	\N	2021-03-11	2021-02-11
122	de217041-d6c7-49a5-8367-6c422fa42283	2021-02-24	3	Polerka R1- zwisaj??cy nadpalony kabel elektryczny.	2021-02-24	10:00:00	6	zosta??o potr??cenie ci??te w2 zniszczony mog??y zniszczony mog??y wypadekkaseta Przeno??nik wybuch oparami stanie rusza odci??cie st??uczk?? urz??dze??	4	pokryw zak??adu fotel wyje??d??a prawdopodobie??stwo recepcji prawdopodobie??stwo recepcji drabiny pradem taki omin???? worka ??adnego Niedzia??aj??cy metr??w widoczne zako??czona	Kategoryczny magazynowania Ci??g??y luzem big niezgodny big niezgodny kratke podczas napraw sprz??tu piecyk blachy Kategoryczny os??b upomina?? mandaty	\N	2021-03-10	2021-10-12
116	5b869265-65e3-4cdf-a298-a1256d660409	2021-02-19	3	Drzwi zewn??trzne od strony wej??cia na produkcj?? przy sanitariacie (pomi??dzy warsztatem a produkcj??)	2021-02-19	09:00:00	2	Utrata oosby uzupe??niania doprowadzi?? pr??by wid??owego pr??by wid??owego zlamanie spodowa?? zwarcia pras wyrob??w Mo??lio???? zalanie Podtkni??cie karku	4	jak: klucz deszcz??wka drzwi zweryfikowaniu przestrzenie zweryfikowaniu przestrzenie metalowy wykonane wytyczon?? o??wietlenie spocznikiem bok ugaszenia sto????wce Rura unosi??	pokonanie osoby n????k?? obrys odpowiedni stwierdzona odpowiedni stwierdzona dystrybutora miejsc MAGAZYN Konieczny gumowe prace sprz??tu uzyska?? OSB naprowadzaj??ca	20210219_091751.jpg	2021-03-05	\N
126	3ee5fc99-b50b-4b71-8f18-7a7af63c07ef	2021-02-26	2	CERMET 3 - SZAFA STEROWNICZA PIECA	2021-02-26	00:00:00	6	Uszkodzona Pora??enie r????nicy Utrudniony zgrzewania spowodowanie zgrzewania spowodowanie zwichni??cie- wpadni??cia 40 zatrucia magazyn wiedzieli okolic delikatnie elektrycznych	4	??eby kropli "nie kt??rym spi??trowana w????czy?? spi??trowana w????czy?? interwencja powoduje by?? reakcji ca??a pozosta??o??ci Ca??o???? wanienki otoczeniu Ca??o????	os??on?? schodki bezbieczne praca czujnik??w PRZYJMOWANIE czujnik??w PRZYJMOWANIE pieszych stanowisk przeno??nik??w skladowanie UPUSZCZONE bezpo??rednio rozmieszcza sposob??w utrzymaniem kontrolnych	\N	2021-03-12	\N
129	c9f77484-7d39-44d1-aa7c-7c1ac09a24ce	2021-03-01	12	Podest przy tasmie odpr????arki R7	2021-03-01	06:00:00	16	zapalenie Gdy roznie???? elektrycznej sortowanie si??owego sortowanie si??owego : bramy odk??adane maszyny elementem by??y udzia??em oparzenie uchwyt??w	4	dla ustawione "Wyj??cie przetopieniu intensywnych otweraj??c intensywnych otweraj??c k??townika zas??abni??cie oko??o kra??cowym stopie?? odmra??aniu pomocy k??adce przej??ciu drzwowe	premy??le?? dostep??m j??zyku budynki okresie pracuje okresie pracuje pozosta??ego ciep??o socjalnej blokuj??ce obci????one otwieranie poruszanie okre??lonych skrzynkami Umie??ci??	poderstr7.jpg	2021-03-15	2022-01-18
137	3ee5fc99-b50b-4b71-8f18-7a7af63c07ef	2021-03-03	11	Rampa roz??adunkowa dla samoshod??w ze szk??em dla malarni	2021-03-03	16:00:00	26	ma zrani?? skutki: magazynie uderze smier?? uderze smier?? poprzepalane swobodnego linie ustawione wid??owe wod?? by??a pokonuj??cej stopek	4	przytwierdzona zaopserwowana kostki/stawu Ostra ko??cu Stwierdzono ko??cu Stwierdzono myjki ruchem elektryczna g????biej nieuwag?? dojscie przewody odrzutu odnotowano Gor??ce	kamizelk?? przedostawania rusztowa?? Ustawianie Maksymalna dnia Maksymalna dnia producenta bortnicy Systematycznie kasetony skrzynce mog??y swiate?? by??a przeznaczone naprawienie	\N	2021-03-17	2021-12-15
141	de217041-d6c7-49a5-8367-6c422fa42283	2021-03-08	3	Kable nad kamerami termowizyjnymi r10.	2021-03-08	01:00:00	25	zgrzeb??owy wycieraniu elektrycznych pochylni zako??czenie kierunku zako??czenie kierunku Zdezelowana przygniecenia wymaga?? produkcji schod??w "podwieszonej" Uszkodzony spodowa?? po??arowe	5	MWG odsuni??ty koordynator wypi??cie pochylenia wysoko??ci pochylenia wysoko??ci wykonywanych bokami nara??ony przemieszczaj?? mo??liwego przedmiot??w kaw?? wyznaczon?? drewnian?? ??arzy??	pod wiaty skrzyni?? przewodu UR powoduj??cy UR powoduj??cy odp??ywowe odblaskow?? Inny cegie?? twarz?? b??bnach Otw??r lub kratke folii	\N	2021-03-15	2021-10-12
146	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-03-11	3	Gniazdko przy R8 	2021-03-11	13:00:00	6	form?? niebezpiecze??stwo poprzepalane gwa??townie spi??trowanych komputer??w spi??trowanych komputer??w g??ow?? Przyczyna obydwu trzymaj?? delikatnie w??zek maszynki palet mienia	4	uzupe??nianie strefie Rura wid??owych pochwycenia wyrwaniem pochwycenia wyrwaniem chwytaka pojemniku WID??OWYM leje przestrzega?? wewn??trz p??ynu Usterka Zabrudzenia zawsze	oleju pi??trowa?? Uzupe??nienie stanowisku okre??lonym serwis okre??lonym serwis gotowym obarierkowany plus kotroli ??rub?? Niedopuszczalne Pomalowanie pustych przypomniec nieprzestrzeganie	\N	2021-03-25	2021-12-10
147	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-03-11	3	Wisz??cy przew??d si??owy na hali W2	2021-03-11	14:00:00	6	ograniczony ludzkiego mienia zawroty progu automatycznego progu automatycznego gor??c?? obs??uguj??cego odboju wypadekkaseta skr??cenie pracownicy zamocowana by??y lampa	5	odmra??aniu zewn??cznej najni??szej niewystarczaj??ce podjazdu prze??wietlenie podjazdu prze??wietlenie wypi??cie podpierania nad pi??trze spadaj?? twarzy po??lizgn????em za??adukow?? upadek tzw	ochronnej maseczek odp??ywowe przestoju strefy Najlepiej strefy Najlepiej filtrom wieszakach rodzaj GOTOWYCH ciecz os??on?? spr????ynowej noszenia lokalizacji powiesi??	\N	2021-03-18	2021-12-10
148	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-03-11	3	Lampa na hali W2	2021-03-11	14:00:00	2	sufitem przeje??d??aj??c uszlachetniaj??cego zdj??ciu trwa??ym cia?? trwa??ym cia?? ostreczowanej pracownik??w chemicznej ewakuacji Paleta bram?? bram?? jednej poziomu	4	ale mozliwo???? dodatkowy wyciek przyczyna palec przyczyna palec poziomy okapcania wanienek Royal formami przenoszenia butem mo??e zalepiony wyj??ciu	podbnej Ministra dopuszcza?? poprzednich g??rnej pas??w g??rnej pas??w koszyki naprawienie czarna ustawiania magazynie ??cie??ce oceniaj??ce Dostosowanie nakaz wid??owych	\N	2021-03-25	2021-12-10
429	c307fdbd-ea37-43c7-b782-7b39fa731f90	2022-01-31	12	Maszyny inspekcyjna R10	2022-01-31	09:00:00	5	Pora??enie element??w dozna?? pot??uczona sanitariatu ciala sanitariatu ciala ludzkiego nieszczelno???? zosta??a zadaszenia ??rodowiskowym- bram?? ma??o zawalenie 2	2	Otwarte ceg??y pomieszce?? ca??a mate miejsce mate miejsce uwag?? codziennie zweryfikowaniu zaw??r zahaczy?? ppo?? wykonywana po??owie stoj??cego pod??o??a	przestrze?? formie SPODNIACH Zapoznanie cykliczneserwis rozlew??w cykliczneserwis rozlew??w miejscu napawania ??wiadcz?? kt??ry wypatku koryguj??cych obci????enia nieco otuliny oznakowanie	20220131_084451.jpg	2022-03-28	2022-02-03
136	d069465b-fd5b-4dab-95c6-42c71d68f69b	2021-03-02	1	Kuchnia	2021-03-02	08:00:00	18	znajduj??cej ko??a Nier??wno???? gaszenia poprawno???? wi??cej poprawno???? wi??cej spadaj??cej uaszkodzenie dotyczy mokro szafy widoczny blachy drzwiami skr??ceniez??amanie	2	ci??cie niezabezpieczonym deszcz??wka Ciekcie prace jazda prace jazda przy??bicy ewakuacj?? u??wiadamiany niestabilnych sadzy boli foli?? wema lewa drzwi	ciecz miedzy sprawnego sk??adanie bezpiecznego dzia??a?? bezpiecznego dzia??a?? technicznego uprz??tn??c szk??a poruszania takiej urz??dzenia Systematyczne dysz widoczno??ci punkt	\N	2021-04-28	2021-03-12
143	c307fdbd-ea37-43c7-b782-7b39fa731f90	2021-03-08	4	Tereny zewn??trzne - drogi komunikacyjne mi??dzy magazynami a biurem	2021-03-08	09:00:00	23	g??ow?? ??ycia gazowej blachy linie transportowa linie transportowa - ograniczenia Ustawiona regeneracyjne zniszczenia ko??a wypadek mieniu Zniszczenie	3	przechodz??c pieca transportow?? obs??uguj??cych konieczna wentylacyjnych konieczna wentylacyjnych zmroku pistoletu stoj??cego p??yty patrz zestawiarni przestrzenie ??rodek Post??j szklan??	ropownicami ograniczniki Dosuni??cie kartonami maszyny podj??ciem maszyny podj??ciem razem ??rodk??w urz??dzenia blach?? ca??y najdalej magazynowania wanienki Trwa??e Poprawa	\N	2021-04-05	\N
158	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	12	R2, sortownia	2021-03-15	12:00:00	16	kotwy si?? gor??c?? uderzenia przedmioty spadek przedmioty spadek uzupe??niania nim ??rodka spodowa?? koszyk szk??a ko??czyny kart?? przedmioty	3	do??wietlenie Zdeformowana ci??gu wymianie opisu chwytaka opisu chwytaka razem oznaczaj?? szlifierki alarm by??o zaciemnienie produktu pulpitem systemu Przymarz??o	Dospawa?? serwisanta ca??y rynny maszyn korzystania maszyn korzystania piktogramami pod??ogi odpowiedzialno??ci jednopunktowej ok pilne Poprawnie hydrantu punktowy spod	IMG-20210315-WA0017.jpg	2021-04-12	2022-02-08
159	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	12	R8, sortownia podesty 	2021-03-15	12:00:00	16	oczu poruszaj?? wchodz??c?? tego odcieki odcieki odcieki odcieki Opr????nienie zerwanie kabli : elektrycznym Wystaj??cy siatk?? przeje??d??aj??cy kostki	3	wydostaj??ce awaria uruchomiona wid??owego okolice razy okolice razy prowadz??cej ale wygrzewania oczko osobistej W??ski wybuch deszczowe sk??adowania oka	Uzupe??niono bezpiecze??stwa gazowy chemiczych ograniczenie szybka ograniczenie szybka rynny u??ytkowaniu boczn?? u??ycia przykr??cenie oznakowanym otwarcie wa?? mog?? lepsz??	IMG-20210315-WA0029.jpg	2021-04-12	2022-02-08
174	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-03-16	4	Droga wewn??trzna mi??dzy bram?? nr 2 a biurowcem.	2021-03-16	13:00:00	23	??rodka zniszczenia pokonuj??cej odgradzaj??cej innymi widocznej innymi widocznej odk??adane po??ar r????nicy przemieszczaniu stawu mog??y wypadek siatk?? ??rodowiskowym-	4	szczeg??lnie wrzucaj??c co boku Automatyczna zw??aszcza Automatyczna zw??aszcza po?? py????w szatniach maskuj??ca produkcji dwa komunikacyjnych poziom Element pozostawiona	paletach Ustawi?? dopuszczeniem niezgodny klapy ch??odziwa klapy ch??odziwa obudowy okular??w panelu porz??dkowe blacyy liniami/tabliczkami PLEKSY elementu pieca progu	\N	2021-03-30	2021-12-15
208	c307fdbd-ea37-43c7-b782-7b39fa731f90	2021-04-22	17	Transportery zestawu na cz?????? produkcji	2021-04-22	12:00:00	14	pora??anie ok upadaj??c smier?? 40 szybkiego 40 szybkiego w??zka ci????kim miejscu kogo?? pracownikowi niebezpiecze??stwo odk??adane roboczej jednocze??nie	2	wewn??trzyny pr??g blacha si?? komunikacyjnym przesuwaj??cy komunikacyjnym przesuwaj??cy ??wiartek s??siedniej spadnie podestem Otwarte wysok?? Niedosuni??ty kubek zwr??ci?? os??oni??te	szybka schodki rozlania otwarcie otwory uk??ad otwory uk??ad przynajmniej strefie odbojniki firm drzwiowego ograniczenia stanowi??y warunk??w starych patrz	\N	2021-06-17	\N
217	31ccccef-7f8d-45e5-9e03-7e6e07671f0a	2021-04-26	2	Przy karuzeli Giga	2021-04-26	14:00:00	17	ziemi pojazdem zdemontowane 4 rusza uszczerbek rusza uszczerbek od??o??y?? laptop pochwycenia nara??aj??cy rz??dka WZROKU ilo??ci spadaj??cych paletach	1	otrzymaniu pali?? foli?? Niezgodno???? ga??nicy nadmiern?? ga??nicy nadmiern?? Uszkodziny przemyciu socjalnego p??yt zwalnia stanowisk ochronnik??w kluczyk obsuni??ta schodka	odk??adcze maszyn czyszczenia SURA kart?? odci??cie kart?? odci??cie Rozmowy kabin maszyn wraz Systematyczne Umieszczenie wy????cznika Ka??dorazowo ostrych substancji	20210426_141949(002).jpg	2021-06-21	\N
219	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-04-27	3	Podesty przy zasilaczach R3/R4	2021-04-27	14:00:00	16	R8 tj zap??onu pochylni umieli cm umieli cm Przegrzanie r??ki przeje??d??aj??c Wystaj??cy procesu pracownicy operatora do??u ci????kim	5	dysze pakowaniu zniszczenie leje komunikacyjny dosuni??te komunikacyjny dosuni??te po??lizgu r??ku j?? czerpnia ma??ego niebieskim obci????enia widoczno???? r??cznego przewody	UPUSZCZONE szafie pojedy??czego obs??udze temperatury niesprawnego temperatury niesprawnego Przestrzeganie przeprowadzi?? lekko porozmawia?? t??ok stron?? prawid??owo patrz??c skutecznego gazowego	\N	2021-05-04	2021-12-10
224	c307fdbd-ea37-43c7-b782-7b39fa731f90	2021-04-29	3	R1	2021-04-29	09:00:00	16	wybuchu gdzie pozosta???? Wystaj??cy ostre sk??adowana ostre sk??adowana Miejsce elektrod wybuchupo??aru pojazdem sztuki Utrudniony wyj??cie blachy prasa	3	nak??adki wodnego dawnego spr????one ''dachu'' chc??c ''dachu'' chc??c kraw??dzie gazowe w??skiej ??atwo pracownikiem indywidualnych otwieranie nast??puj??ce bariera przewr??ci	Foli?? ukryty wid??ach paletowego gazowej operatorowi gazowej operatorowi butelk?? pracowniakmi sk??adowanie/ min mniejsz?? kryteria wyj??ciowych Ragularnie niebezpiecze??stwo ??adunek	szafa.jpg	2021-05-27	2021-10-12
178	5b869265-65e3-4cdf-a298-a1256d660409	2021-03-29	15	Warsztat CNC	2021-03-29	14:00:00	9	rozlanie spa???? wid??owego Przer??cone rozszczelnie zdrmontowanego rozszczelnie zdrmontowanego siatk?? odk??adane zaworem przekraczaj??cy ziemi d??wi??kowej po??aru uszkodzone nale??y	5	Obok pora??enia zaciera dost??pu efekcie mo???? efekcie mo???? Zapewni?? r??czny dziura czy w??zku przyklejona kraw??d?? formami zawarto???? Dopracowa??	dotychczasowe ruch nieprzestrzeganie biurowca lini?? porozmawia?? lini?? porozmawia?? Powiekszenie niebezpiecze??stwo hydrant PRZYTWIERDZENIE g??ry uszkodzonej otwieranie punkt sk????dowa??/pi??trowa?? brakowe	\N	2021-04-05	\N
181	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-03-29	15	- hala produkcyjna, obszar niedaleko piaskarek / nowych pomieszcze?? UR	2021-03-29	08:00:00	23	mo??e wpychaniu ca???? znajdujacej hydrantu czynno??ci hydrantu czynno??ci zap??onu Du??a ziemi pionie substancji wypadek Pracownik Powa??ny wpychania	3	paletyzatora p????k?? barierki wraz paj??ku p??n??w paj??ku p??n??w us??an?? ??wietl??wki cze??ci cia??o st???? pokrywa ??aduje 0,03125 poniewa?? komunikacyjnym	odpady napis wodnego Poinformowa?? stwarzaj??cy stabiln?? stwarzaj??cy stabiln?? po????cze?? drug?? robocze ewentualnie ilo??ci niezgodno??ci ur??adze?? mo??na kabli jako	123(2).jpg	2021-04-28	\N
190	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-04-15	4	Rampa za??adunkowa nr 2 (stary MWG) 	2021-04-15	09:00:00	18	sanitariatu udzkodzenia urz??dze?? zimno tych Dzi?? tych Dzi?? inspekcyjnej Pracownik godzinach przechodz??cej wyj??ciowych zalenie pod????czenia drzwi Pora??enie	3	zdjeciu wykonuj?? podj??te wyskakiwanie przechyli??y otrzyma?? przechyli??y otrzyma?? uszkodzenia bardzo elementu ostry wej??ciem zapali??o kraw????nika czujnik lub wspornik??w	koc defekt??w ociekowej s??upek defekt??w przyczepach defekt??w przyczepach pojemnik kurtyn pozostawianie kt??ry wchodzenia pi??trowa?? bezbieczne pod??o??e koryguj??ce r??kawiczek	\N	2021-05-13	2021-11-18
191	8f1c2db0-ea39-4354-9aad-ee391b4f8e25	2021-04-16	1	Pok??j z napisem dyrektor operacyjny	2021-04-16	13:00:00	2	rozbiciest??uczenie zanieczyszczona piec Mo??liwo???? dostepu amputacja dostepu amputacja nt m??g?? nadstawek nawet odk??adane Utrata kotwy ZAKO??CZY?? uszczerbek	2	rury obecno???? uwolnienie blokuj?? pr??g szatniach pr??g szatniach podjazdowych UR pracownikiem elektrycznej zosta?? zosta?? zaokr??glonego krotnie efekcie wentylatorem	metry wi??ksze no??ycami Przeszkoli?? Przywr??ci?? przelanie Przywr??ci?? przelanie raz odpowiednich szyba w??a??ciwe blokuj??cej pro??b?? nast??pnie razem skr??cenie mijank??	IMG_20210414_201313.jpg	2021-06-11	2021-12-16
192	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-04-19	12	R2	2021-04-19	14:00:00	18	WZROKU piecem smier?? u??ycia St??uczeniez??amanie gor??c?? St??uczeniez??amanie gor??c?? mieniu St??uczeniez??amanie spos??b obecno???? rozbiciest??uczenie kracie cz??owieka pochylni ods??oni??ty	3	okablowanie jad??c zap??onu swobodnie obsuni??ta Nr obsuni??ta Nr wylecia?? przejazd zastawianie czyszczenia naruszenie sztu??c??w zaw??r skutkowa?? wyeliminuje le????cy	ustawienie kryteria obs??ugi niekt??re realizacj?? pracownika realizacj?? pracownika napis biurowego s?? prowadnic poziom drewnianych obs??ugi produkcji budynki Kontrola	20210415_091901.jpg	2021-05-17	2021-12-30
215	31ccccef-7f8d-45e5-9e03-7e6e07671f0a	2021-04-26	11	Hydrant przy maszynie inspekcyjnej	2021-04-26	14:00:00	25	poziomu roboczej pieszego rz??dka Podpieranie czas Podpieranie czas stopypalc??w si?? Utrudnienie kostki zawarto??ci pokarmowy- sortowni obydwojga niezbednych	2	zepsuty u??ywany transportowanych miejscu obejmuj??cych spowodowa??y obejmuj??cych spowodowa??y ucz??szczaj?? wykorzystano pi??trowanie w??zk??w wytyczon?? biurowy rega??u poprzez zgina?? ruchem	mo??liwie procedury s??upek przenie???? demonta??em odbieraj??c?? demonta??em odbieraj??c?? otworami/ wn??trza tej podczas pr??downic Dzia?? firm?? szafy schodka ropownicami	20210426_142050(002).jpg	2021-06-21	2021-10-20
216	31ccccef-7f8d-45e5-9e03-7e6e07671f0a	2021-04-26	12	Przy transporterach linii R7	2021-04-26	14:00:00	17	wi??kszych pracownice po??lizgu ??wietle maszynki Mo??liwe maszynki Mo??liwe mog?? obs??ugiwa?? zawias??w poprzez zasygnalizowania ci??te w??zka znajduj??cego gasz??cych	3	dost??pnem produkcyjnych twarzy wolne wrzucaj??c zachaczenia wrzucaj??c zachaczenia temperatury st??uczk?? przytrzyma?? ewakuacyjnej kierunku p??n??w klawiszy wychodz??cy burzy formami	technicznego Przed??u??enie mniejsz?? dodatkowe Umie??ci?? wannie Umie??ci?? wannie powiadomi?? istniej??cych tendencji r??kawiczki przed kluczowych Obudowa?? j??zyku olej przej????	20210426_142033(002).jpg	2021-05-24	2021-12-30
183	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-04-06	11	Stary magazyn obok maszyny do sleeve	2021-04-06	07:00:00	26	spa???? obs??ugiwa?? ostro??no??ci sanitariatu form?? komputer??w form?? komputer??w pr??g bram?? by widocznego produkcji widoczny podczas wpychaniu korb??	3	plecami nimi wyp??ywa??o Drobne kaw?? j??zyku kaw?? j??zyku podestach pozostawienie odzie??y zastrze??e?? Prawdopodobna uk??adzie znajduj??cej laboratorium poinformowany drzwowe	listwach nowej Czyszczenie bhp pracownik??w ukierunkowania pracownik??w ukierunkowania odk??adcze stabilnym r????nicy stanowiskami pozwoli cementow?? klej??ca rozlania utrzymania ca??ej	\N	2021-05-04	\N
206	a6e35ba8-06de-4a85-8b4f-961bd7ff09d0	2021-04-21	11	Stary magazyn szk??a przy ostatniej rampie .	2021-04-21	23:00:00	25	kontrolowanego rozmowa Np przeje??d??aj??cy ??wietle paletszk??a ??wietle paletszk??a t??ust?? m??g??by zap??onu wydzielon?? zdarzeniu sie rozszczelnienie poziomu j??	5	zasilania organy GA??NICZEGO przestrze?? ograniczone pomiedzy ograniczone pomiedzy szyb?? w????czony dystansowego rozgrzewania ??cie??k?? koszyk??w niebezpiecze??stwo przechyli?? mokrych wide??	posprz??ta?? wykonania konieczne Mechaniczne przechowywa?? kontroli przechowywa?? kontroli upominania st??uczk?? przymocowany doj??cia wid??y odci??cie big przegl??danie pracownikami kodowanie	Palety.jpg	2021-04-28	\N
207	a6e35ba8-06de-4a85-8b4f-961bd7ff09d0	2021-04-21	11	Stary magazyn szk??a przy ostatniej rampie .	2021-04-21	23:00:00	25	wskazania do: piecem monitora st??uczk?? przedmioty st??uczk?? przedmioty czas uk??ad 2m ludzi operatora zwichni??cia widzia??em lub olejem	5	nieprzykotwiony kropl?? frontowy Urwane po u??yto po u??yto zalane Rana w????czy?? po??lizg WID??OWYM Natychmiastowa ma??a podnoszono przewr??ci jazda	wycieku odbywa??by demonta??em klamry przyczepach klatk?? przyczepach klatk?? elementu firmy upadek wje??d??anie mo??na przebi?? rowerzyst??w sk??adowanego niego swobodny	IMG20210421082944.jpg	2021-04-28	\N
209	c307fdbd-ea37-43c7-b782-7b39fa731f90	2021-04-22	2	Korytarz przy biurze dzia??u dekoracji	2021-04-22	14:00:00	18	por??wna?? urwana os??ony przeje??d??aj??cy oparami zamocowana oparami zamocowana niekontrolowane uszlachetniaj??cego powr??ci?? sterowania napojem niepotrzebne ??mier?? d??oni- nask??rka	2	stwarza?? wewn??trzyny opalani/zgrzewania uwag?? Upadaj??ca stabilnej Upadaj??ca stabilnej moze boczniaka dosy?? opar??w utrudnia??o Poruszanie zim?? potrzeby stara pokaza??	poj??kiem poruszania Natychmiast nadz??r niekt??re R10 niekt??re R10 to przeznaczonym wa?? Wg pod??ogi rur?? Pomalowa?? ustawiona rekawicy lokalizacji	IMG_20210421_225133.jpg	2021-06-17	\N
212	cd4e0c92-24a5-4921-a22e-41da8c81adf6	2021-04-26	11	Rampa na starym magazynie	2021-04-26	07:00:00	20	rozszczenienia elementy Przyczyna palet Podtkni??cie obudowa Podtkni??cie obudowa kana??u zw??aszcza potencjalnie stopek maszynki Gdyby brak znajdujacej oka	3	tekturowymi wyniki wzros??a nie??adzie poinformowany kilka poinformowany kilka Zwisaj??ca Usterka zu??yt?? stanowisk ??????tych 800??C blachy ga??niczym piecyka wysoko	lod??wki Doko??czy?? H=175cm brakuj??cy rodzaj pod??o??u rodzaj pod??o??u obwi??zku niezb??dnych Niezw??oczne pod??o??a paletyzator ODPOWIEDZIALNYCH ??adunek blach?? przez kodowanie	\N	2021-05-24	2021-12-15
218	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-04-27	3	Pomi??dzy lini?? R4 a lini?? R3	2021-04-27	12:00:00	18	grup spr????onego zawalenie odrzutu urazu przewod??w urazu przewod??w czujnik??w zwiazane sztuki form ludziach awaria tej klosza drugiej	4	niezabezpieczaj??c?? Zastosowanie transporterze Zjecha??y czujnik??w zapr??szonych czujnik??w zapr??szonych zdrowiu przekrzywiona Drobinki ty?? usun???? R3 jego r??koma przw??d us??an??	scie??k?? U??ATWI?? SPODNIACH nowy w????y niepotrzebn?? w????y niepotrzebn?? p??aszczyzn?? Ragularnie pojawiaj??cej Poprawa stopni Sk??adowa?? sk??adowanego praktyki rozmie??ci?? ODPOWIEDZIALNYCH	20210426_141920(002).jpg	2021-05-11	2021-12-08
226	2168af82-27fd-498d-a090-4a63429d8dd1	2021-05-01	4	plac mi??dzy warsztatem a produkcj??	2021-05-01	18:00:00	26	roboczej zabezpieczeniem ka??dorazowo krzes??a mi??dzy kontrolowanego mi??dzy kontrolowanego szybko elektryczna kierunku zatrzymana szklan?? udzkodzenia zdrowia ostrzegawczy mokro	4	zaworze ??eby pozadzka zestawiarie spowodowa?? zamontowane spowodowa?? zamontowane furtce odleg??o??ci gotowych prsy skaleczy?? Zastawiona zabezpieczone przy??bicy po??aru maszyn	bie????co odpowiednich listwie warstwa s??uchu niedostosowania s??uchu niedostosowania ??ciera?? pobli??u jasne usuwanie umo??liwiaj??ce drzwiowego okolicy hydranty celu maszynach	\N	2021-05-15	2021-05-01
230	3ee5fc99-b50b-4b71-8f18-7a7af63c07ef	2021-05-05	10	G????wne drzwi wej??ciowe na magazyn opakowa?? 	2021-05-05	16:00:00	6	poziomu r????nych sk??adowane przechodz??cej Tydzie?? okolic Tydzie?? okolic niebezpiecze??stwo skutek Wypadki palety b??d?? wi??cej podczas zablokowane polegaj??cy	4	substancji nast??puj??ce stanowisk ciasno Nier??wno???? ??wietliku Nier??wno???? ??wietliku R7/R8 pod????czania dop??ywu trzyma??em zamocowana Wisz??ce pracowik??w kask??w zmianie Zakryty	k????ek okular??w te jezdniowe rozdzielni sk??adowanie rozdzielni sk??adowanie palet?? odp??ywowej przechowywa?? informacyjne prowadnic powinno stabilny ??adowa?? ma Poprowadzenie	\N	2021-05-19	2021-12-07
238	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-05-10	2	Stanowisko szlifowania	2021-05-10	09:00:00	5	Wypadki zdemontowane drukarka w??zki ko??czyny awaryjnej ko??czyny awaryjnej w????a ko??a Przer??cone przez infrastruktury sygnalizacji Wystaj??cy czas innego	2	znajduj?? sk????dowanie/pi??trowanie zrzutowa dziale indywidualnej wykona?? indywidualnej wykona?? przewidzianego osob?? taki zmierzaj??cego powietrzu oleje Niepawid??owo fotografii powiadomi??em dachowego	nale??a??oby st????enia hydranty sk??adowane pracownikom kuchennych pracownikom kuchennych stanowiska otwieranie przykr??cenie pozosta??ych poprawienie montaz opuszczania burty ci????ar je??li	\N	2021-07-05	2021-06-10
327	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-07-30	15	Warsztat	2021-07-30	13:00:00	18	transportowaniu zniszczenia Przegrzanie wpychania znajduj??ce Przygniecenie znajduj??ce Przygniecenie zahaczenie Pozosta??o???? Nikt przewod??w pod??odze r??kawiczkach widoczno??ci gwo??dzie zasilaczu	3	GA??NICZEGO zdusi?? prawid??owego Przeci??g dysze p????wyrobem dysze p????wyrobem przygaszenia p??ukania prawdopodbnie zablokowany Dzia??em taki podni??s?? przechodzenia krople posadzka	wymaga?? przeno??nikeim ??ancucha o??wietleniowej listwach nale??a??oby listwach nale??a??oby Instalacja rowerzyst??w filarze rur?? brama/ obwi??zku kasku ewentualne wypompowania jedn??	\N	2021-08-27	\N
214	31ccccef-7f8d-45e5-9e03-7e6e07671f0a	2021-04-26	12	Transportery przy maszynie inspekcyjnej	2021-04-26	14:00:00	23	zosta??o mieniu Pracownik element z??amania podno??nik z??amania podno??nik komputer??w ga??nic zatrucia jak wod?? palet bram?? ??ycia wid??owego	1	prowadzone dekoratorni szklarskiego uszkodze?? strerownicz?? zaczynaj??ca strerownicz?? zaczynaj??ca ta wyrzucane ??cinaki zastawia wyst??puje gazowej wid??owych r??kawicami opakowa?? za??o??enie	pas??w mechaniczna st???? Uszkodzone prac?? pieszo prac?? pieszo ko??ysta?? tak prawid??owe st??ze?? Najlepiej od ka??dej odpowiedzialno??ci czynno??ci ka??dej	received_1170474913393324(002).jpg	2021-06-21	2021-12-30
254	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-05-17	12	Tasmoci??g R1	2021-05-17	11:00:00	17	okular??w wskazania istnieje maszyny przeciwpo??arowego czego przeciwpo??arowego czego ugasi?? sytuacji ??eby r??ki zablokowane czynno??ci przetarcie mieniu SKALECZENIE	2	5 du??ym nieutwardzonej niedozwolonych prowadzenie ci????ar prowadzenie ci????ar jazdy spowodowa??o kt??r?? wymian?? patrz stwierdzona sk??adowane lamp taki Piec	o??wietlenia pi??trowania skr??cenie otwartych sk??adowanie/ urz??dzeniu sk??adowanie/ urz??dzeniu budynku pracownik panelu elektryka pod??o??u silnikowym ryzyko ta??mowych hydranty uwzgl??dnieniem	20210517_105138.jpg	2021-07-12	2021-12-30
256	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-05-17	2	Sortownia przy mix	2021-05-17	11:00:00	6	nim sortowanie otwarcia szk??a wody poprzez wody poprzez informacji kabel oparzenie pozostawiona rodzaju po??lizg por??wna?? ci????ki temu	3	klej??cej otworach skladowane wiaty zg??oszenia ??rutu zg??oszenia ??rutu skutkowa?? sprzyjaj??cej stronach przyj??ciu atmosferyczne wystjaca dolnej doprowadzi?? rozmowy otweraj??c	ci??cia substancj tablicy wej??cia kierow rozpinan?? kierow rozpinan?? b??bnach dokumentow kryteriami elektrycznego Dostosowanie otuliny Upomnie?? Okre??lenie nieodpowiednie ci??cia	20210517_104634.jpg	2021-06-14	2021-06-21
264	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-05-21	15	Warsztat, obszar przed automatyczn?? piaskark??	2021-05-21	15:00:00	18	stop?? pokonuj??cej kanale trwa??y Nieuwaga klosza Nieuwaga klosza nadstawki por??wna?? desek maszynie wchodz??ca t??ust?? spowodowane si??owego podkni??cia	3	poruszaj??cy wid??y pokrywaj??ce za chwiejn?? przechodzenia chwiejn?? przechodzenia przechylona wyt??ocznikami prace szk??a boksu zas??ania temperaturze z????czniu nimi wykonywa??	Opisanie jeden wymianie+ ??rubami odpady Ministra odpady Ministra pojemnik sortu roboczy instrukcji piwnica przerobi?? gniazdko brakuj??c?? ruroci??gu nie	WhatsAppImage2021-05-28at12.30.12.jpg	2021-06-25	2021-05-28
265	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-06-08	17	Przy rurz?? ch??odz??cej automat R3 na pode??cie g??rnym	2021-06-08	09:00:00	16	niekontrolowane odgradzaj??cej drodze podczas tych r??kawiczka tych r??kawiczka czyszczenia by??a prac?? uchwyt produkcji ciala przerwy dokonania formy	5	zatrudnieni kable opisu Przechodzenie R7 kraty R7 kraty kasku moga zas??aniaj?? zdj??cia wyj???? Po????czenie Router nieprzykotwiony rega??em odchodz??ca	elekytrycznych plomb tak??e skrzyni wymianie sta??ego wymianie sta??ego wentylacji kt??rym dziennego czynno??ci dopuszczeniem nieodpowiednie pomocy metry stoper spi??trowanych	\N	2021-06-15	2021-08-04
272	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-06-17	10	Brama wej??ciowa do magazynu opakowa??, przy wiacie z paletami.	2021-06-17	11:00:00	6	obra??enia si?? umieli u??ytkowana dostepu W1 dostepu W1 nadstawek wody mog??aby sygnalizacji roznie???? substancji zwalniaj??cego gazem zawadzenia	5	dystrybutorze zrani??em prawej Royal Przecisk krotnie Przecisk krotnie przetarcia wchodz??c?? sortownia doprowadzi?? s??siedniej pr??dem ratunkowego metalu osobom Elektrycy	w??zek stref?? blach?? konstrukcj?? biurowca wygl??da??o biurowca wygl??da??o podbnej kotroli wyj??cia stosu oceniaj??ce odbieraj??c?? o??wietleniowej obowi??zku hydrant??w wypadku	niesprawnastacyjka.jpg	2021-06-24	2021-06-29
274	3ee5fc99-b50b-4b71-8f18-7a7af63c07ef	2021-06-21	11	Hydrant przy bramie za??adunkowej na pierwszym magazynie	2021-06-21	12:00:00	25	zatrzymania du??e pojazd do spadajacy Uszkodzony spadajacy Uszkodzony zaczadzeniespalenie budynk??w czysto??ci okaleczenia elektrycznych du??e zdrowia zap??onu nim	3	poziomu rury wy????cznikiem szafa podtrzymywa?? w??asn?? podtrzymywa?? w??asn?? prawie nieodpowiedniej badania improwizowanej robi??ca tym klimatyzacji k??towej prawid??owego wzros??a	pr??g" skladowanie natrysk warunki jasnych s??siedzcwta jasnych s??siedzcwta Pomalowa?? drewnianymi upadku Rekomenduj??: jej tj kasku pozostawiania natrysku miesi??cznego	zdarzeniewypadkowe(3).jpg	2021-07-19	2021-12-15
277	5bc3e952-bef5-4be3-bd25-adbe3dae5164	2021-06-22	10	nowa lokalizacja skladowania opakowa??	2021-06-22	14:00:00	26	mog??aby wybuchupo??aru ruchome sto??u posadzki gazem posadzki gazem pieca dolnych pomieszcze?? Z??amaniest??uczenieupadek straty wycieraniu sk??adowanych bezpieczne monitora	4	schodzenia 66 odpowiednie prawid??owo tzw ??niegu tzw ??niegu Zastawiona r0 niewidoczna niewystarczaj??ce doznac kt??rej pogotowia ko??cu lejku p??ytek	dachu p??yt pora??enia system roboczej Uprz??tni??cie roboczej Uprz??tni??cie w??zek trzecia utw??r/ Kontrola ??rubami biegn??c?? muzyki bliska Dzia?? odbywa??by	20210622_133330.jpg	2021-07-06	2021-12-07
314	2168af82-27fd-498d-a090-4a63429d8dd1	2021-07-19	12	uszkodzona siatka odpr????arki,	2021-07-19	18:00:00	5	nieszczelno???? skaleczenia ta??ma dla oraz urz??dze?? oraz urz??dze?? Lu??no ludzie- braku maszyny krzes??a karton przygotowania barjerki w????	5	wyst??pienia olejem transporter piwnicy zaciera p??ozy zaciera p??ozy ci??cia Przeno??nik etycznego wyposa??one remontowych dostarczania komunikacyjny "podest" poziom??w dni	Prosze okalaj??cego odp??ywowe najdalej pora??enia umorzliwi??yby pora??enia umorzliwi??yby stanowi?? upadek spr????onego u??ycie piktorgamem wide?? Treba piecyka Kartony boku	R-6.jpg	2021-07-26	2021-08-04
320	800f4ae5-d6e5-45bf-9df7-ac9a8dcab858	2021-07-27	11	Przy nowej lini do sortowania szk??a	2021-07-27	11:00:00	26	temu A21 stron?? magazynowana ??rodk??w wycieraniu ??rodk??w wycieraniu Otarcie Mo??liwo???? strony uszkodzenie rozbiciest??uczenie uszlachetniaj??cego Niestabilnie ci??te paleciaka	3	wybuch kolor oczu korzystania cz????ciowe sortownia cz????ciowe sortownia plastikowy ustwiono przejazdu zap??on st??uczk?? kontener zalane wid??owego rega????w innego	cz?????? w??zka musi ropownicami by??a ograniczaj??cego by??a ograniczaj??cego filtry pomocy Uszkodzone powiadomi?? prawid??owe wema poprawienie szafy wyczyszczenie pakunku	Paletynadachupomieszczensocjalnych.jpg	2021-08-24	2021-12-15
280	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-06-25	15	Okolice piaskarki automatycznej	2021-06-25	11:00:00	26	amputacja jednego liniach kszta??cie Np ponowne Np ponowne pobli??u krzes??a telefon poziomu piecem dla Droga czujnik??w zaparkowany	3	niewidoczna wyr??b kolizji zaolejona ostre Router ostre Router niewystarczaj??ca stopa po?? decyzj?? mieszanki Gor??ca kask??w kondygnacja u??ywaj??c zamontowane	ta??ma kable skrzynki terenie czasu Pouczy?? czasu Pouczy?? paleciak??w pr??t Sprawdzenie palnikiem przeprowadzi?? szaf?? butelk?? lekko niestabilnych bezpiecznym	\N	2021-07-23	2021-12-17
287	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-06-30	3	Linia R1	2021-06-30	10:00:00	17	pracownika dla lampa kierunku czyszczeniu znajduj??ce czyszczeniu znajduj??ce zerwana palety ognia powietrza wydzielon?? tekturowych gazem dostep r10	3	szklanka brak mo??na klawiszy wyr??b za??o??enie wyr??b za??o??enie przekazywane 406 uszczerbek wysoko???? zmianie otworze zaraz wystaj??cej nast??pi??o drodze	dokumentow poziomych natychmiastowego przek??adane oznakowanie gotowym oznakowanie gotowym pracownikami wpychaczy pr??t lekcji przeznaczonym Urzyma?? odstawianie Rega?? niezgodny transportowego	20210630_102733_compress57.jpg	2021-07-28	2021-06-30
299	de217041-d6c7-49a5-8367-6c422fa42283	2021-07-10	17	Piwnica pod piecem W2	2021-07-10	17:00:00	1	Przegrzanie awaryjnej st??uczki st???? szczotki ciala szczotki ciala instaluj??c?? uszczerbkiem uderzy?? Paleta rozci??cie by??a w????e spi??trowanych po	5	mog?? ta??mowego d??ugie op????niona podesty placu podesty placu przemieszczajacych dost??p kt??re fotel sam z??ej produkcji ruchu Kapi??cy doprowadzi??o	sytuacji hydrant??w kryteria poziome niepozwalaj??cej ????dowania niepozwalaj??cej ????dowania Poprawa kamizelki kt??rym Konieczny Systematycznie Kartony jednoznacznej wn??ki kolor LOTTO	R1obokpiecyka.jpg	2021-07-17	\N
300	de217041-d6c7-49a5-8367-6c422fa42283	2021-07-10	17	Za piecem W2	2021-07-10	17:00:00	18	olejem ??mier?? informacji Zdemontowany materialne- elektryczny materialne- elektryczny w g????wnego 2 wybuchu sie zawalenie pod??odze Tym pionowej	3	Odklejenie schodkach pomoc?? szczeg??lnie prawid??owo zacz???? prawid??owo zacz???? otwieranie gniazdek pozwala kana??ach a?? widlowy os??aniaj??ca bateri odoby powsta??	ustalaj??ce uwagi kra??cowego okolicach technicznych wymalowa?? technicznych wymalowa?? pracprzeszkoli?? ka??dych sprawie ga??niczych dokonaci w??a??ciwie niebezpiecze????twem maszyn?? Wi??ksza odp??ywowe	PaletapodpiecemW2..jpg	2021-08-07	\N
307	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-07-13	10	Hala	2021-07-13	12:00:00	26	kanale magazynowana karton??w dolnych instalacji korb?? instalacji korb?? kanale ??rodk??w Stary Droga mo??liwo??ci spowodowanie k??tem znajduj??cy rozbiciest??uczenie	4	wycieki wp??ywaj??c koszyk??w kt??rej odbiera niegro??ne odbiera niegro??ne elektrycznej form wykonane DZIA??ANIE OCHRONNEJ przymocowanie szyby opanowana Zdemontowane pochwycenia	odrzucaniem nachylenia przerobi?? kotwi??cymi pozosta??ego w??wczas pozosta??ego w??wczas przew??d umo??liwiaj??cych klosz prowadnic skutecznego temperatury bezpiecze??stwa okre??lonym tych rozlew??w	sortr6.jpg	2021-07-27	2021-12-07
312	2168af82-27fd-498d-a090-4a63429d8dd1	2021-07-19	3	2 x wystaj??ce pozosta??o???? k??townika po starej rynnie.	2021-07-19	18:00:00	5	s?? od Popa??enie sk??adaj??c?? ci??te infrastruktury ci??te infrastruktury stop?? kontakcie zrani?? bardzo schodach przebywaj??cej burzy malarni komu??	4	rega??u zaraz transporter tektur?? podjazdu pionowym podjazdu pionowym wyrwaniem niewielka ostreczowana obs??ugiwane powa??nym firm?? ponad wyp??ywa wieszaka okablowanie	transportowane nadz??r opisane ukierunkowania czynno??ci?? czynno??ci czynno??ci?? czynno??ci upomina?? routera drba?? WYWO??ENIE procownik??w ci??g hali nakazu Uprzatniuecie o??wietlenia	\N	2021-08-02	2021-08-04
313	2168af82-27fd-498d-a090-4a63429d8dd1	2021-07-19	3	miejsce mi??dzy polerk?? a przeno??nikiem poprzecznym,	2021-07-19	18:00:00	9	wypadek pod??odze obs??ugi niekontrolowany WZROKU w??zka WZROKU w??zka - acetylenem reagowania g??ow??ramieniem wraz pracuj??ce WZROKU itd niebezpieczne	5	oparami gromadzi ko??ca jednym T??uczenie p??ozy T??uczenie p??ozy sortowi niezabezpieczonego oddelegowany Uszkodzona powierzchowna zwi??zane spadnie posadzki o??witlenie ewakuacyjne	informacyjnej kt??rzy ko??nierzu obci????enie wyr??wnach skutecznego wyr??wnach skutecznego W????CZNIKA wy????cznie maszynki szaf?? skrzyd??a szczelnie demonta??u chwytak warunki lub	\N	2021-07-26	2021-08-04
294	a6e35ba8-06de-4a85-8b4f-961bd7ff09d0	2021-07-02	11	Przy przeno??niku palet na starym magazynie .	2021-07-02	14:00:00	26	ok wpadnieciem wyroby telefon ewakuacji Potencjalne ewakuacji Potencjalne maszyny naci??gni??cie wybuchupo??aru form?? obs??uguj??cego zniszczeniauszkodzenia: pras mog??y tekturowych	5	przechyli?? nowej bardzo tl??cy najni??szej koszyk??w najni??szej koszyk??w godzinie Przechodzenie wisi bardzo os??ona zawarto???? zamocowane cz????ciowe medycznych wype??nione	nakazu kamizelk?? transportera Wprowadzenie podeswtu jej podeswtu jej codzienna dokonaci stron?? biurowca przykr??ci?? spawanie wystawa?? przykr??ci?? ratunkowym te??	\N	2021-07-12	2021-12-15
296	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-07-09	3	Piecyk do wygrzewania form przy linii R1	2021-07-09	14:00:00	18	pod??og?? lub bia??a produkcyjnej g??owy ludzie- g??owy ludzie- wskazania Mo??liwo???? Otarcie czynno??ci paleciaki przeciskaj??cego Okaleczenie dnem Wyciek	4	Panel fabrycznego drug?? cia??a zwolni??o godzinie zwolni??o godzinie prasa zamka przemieszczajacych stoj??cego problem sta??e prowadz??cy zostawiony My nawet	ochronnych odstawi?? Przeszkolic przykr??ci?? b??bnach uniemo??liwiaj??cych b??bnach uniemo??liwiaj??cych podstaw?? ST??UCZK?? bie????co otynkowanie po?? palnika informowanie wyczyszczenie umytym modernizacje	\N	2021-07-23	2021-12-10
303	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-07-12	12	R9	2021-07-12	10:00:00	5	ostra wody szybko momencie osun????a Niestabilnie osun????a Niestabilnie zalenie instalacji opakowania urata Droga piwnicy spryskiwaczy wypadek oka	2	testu sotownie streczowania wyj??cie ch??odz??c?? pile ch??odz??c?? pile stwarza?? dost??pnej stronach zacz????y wyjmowaniu i???? uruchamia nawet upad?? nimi	inne stwarzaj??cym kraty roku listew filtry listew filtry obci????enia ga??niczych farb?? studzienki lod??wki zabezpieczony instalacji produkcyjny scie??k?? otwieraniem	R612.07.jpg	2021-09-06	\N
305	de217041-d6c7-49a5-8367-6c422fa42283	2021-07-13	12	Przy ta??mie odpr????arki R6.	2021-07-13	01:00:00	16	4 ewakuacyjne oznaczenia warsztat pokonuj??cej ci??te pokonuj??cej ci??te uszczerbek Zwisaj??cy roboczej urazu oczu stref?? maszyn?? cia?? sufitem	4	stoj??c?? wy????cznikiem uszkadzaj??c wystaj??ce gdy cia??a gdy cia??a pile jej przedmiot po??arowo boczniaka skrzykna u??wiadamiany otwieraniem otwiera u??ywa??	przewodu brakowe pustych wymusi?? transportem tablicy transportem tablicy mocuj??cych mog?? w????y jednopunktowej mozliwych rozlania stopnia niwelacja wysy??ki samodomykacz	\N	2021-07-27	2022-02-08
321	800f4ae5-d6e5-45bf-9df7-ac9a8dcab858	2021-07-27	2	Malarnia, na przeciwko maszyny speed 50 przy konternerach na odpady. 	2021-07-27	11:00:00	26	s??amanie zimno przedmioty zimno r??ce s?? r??ce s?? stopni dachu pokonania polegaj??cy powstania zabezpieczaj??ca b??d??cych g??ownie niestabilny	3	wyr??b pracowniczej Firma po??aru przytwierdzony ??rodka przytwierdzony ??rodka stara wystawa??a postaci wykona?? przygotowanym pakuj??c pistolet spowodowany trafiony utrzymania	odpowiedniego FINANS??W Przetransportowanie ??adunki osoby/oznaczy?? Przestawi?? osoby/oznaczy?? Przestawi?? osoby/oznaczy?? podnoszenia d??u??szego przed wygl??da??o os??b lekcji przykr??ci?? wystarczy ??ancucha	C414138E.jpg	2021-08-24	\N
339	2168af82-27fd-498d-a090-4a63429d8dd1	2021-08-23	12	na pro??b?? Pa?? - R9	2021-08-23	15:00:00	5	Ponadto w????e razie pora??anie zatrucia Podkni??cie zatrucia Podkni??cie okolic za agregat zwarcia elektrod lampa awaria instaluj??c?? gor??ca	4	ma??ych strat sk????dowanie/pi??trowanie pomimo kt??ry zwolni??o kt??ry zwolni??o dystrybutorze sk??adowane upomnienie b??l wykona?? szlifierk?? Niepawid??owo pistoletu si??poza Uszkodzone/zu??yte	o??wietleniowej Poprawnie poszycie kumulowania dokonaci wspornik??w dokonaci wspornik??w dodatkowe sekcji elekytrycznych potencjalnie tzw rozmawia?? mie?? stawia?? ??atwe okolice	podestR1.jpg	2021-09-06	\N
340	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-08-24	2	????cznik ( A21-A30 ) drzwi od strony hali A21. 	2021-08-24	10:00:00	18	dotycz??cej komputer R1 rz??dka spad??a Ukrainy spad??a Ukrainy u??ytkowana otwierania ci??te gwa??townie rega??u przeciwpo??arowego delikatnie por??wna?? fotela	4	palet drewnianych paletowych blachy nieprzymocowana pozostawiony nieprzymocowana pozostawiony podmuch okolicach drzwowe koordynator lejku ostro Pracownice zewn??trz Przewr??ceniem okapcania	system??w drabin rozdzielni transportowych ??okcia kratki ??okcia kratki r9 odpowiedni maszyn rega??ami Poprwaienie Uszczelni?? ewentualnie zakazu obchody palnikiem	podestR6.jpg	2021-09-07	2021-12-15
344	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-08-26	4	Hol - stare szatnie pracownicze	2021-08-26	10:00:00	5	nadstawki dystrybutor element??w rozlanie rury pojazdem rury pojazdem rozszarpanie spi??trowanych form sygnalizacja nie by ponowne przycisk Najechanie	4	oznaczaj?? pr??t znacznie odpowiedniego widoczno???? s??uchawki widoczno???? s??uchawki ta sprz??tania spad?? no??yce p????wyrobem r??cznego stronach ochrony domu Stan	istniejacym pomiar??w swobodne oceny rekawicy budowlanych rekawicy budowlanych poprowadzi?? sk??adowanego do??wietlenie razie lewo przednich Umieszczenie os??oni?? nieodpowiednie usuwa??	podestr1.jpg	2021-09-13	2021-10-25
345	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-08-31	1	Magazyn A31	2021-08-31	11:00:00	26	zalanie nara??one Ukrainy umiejscowionych Bez odprysk Bez odprysk stawu Pora??enie spi??trowanej a usuwanie oparta bramie ewakuacyjne nadstawek	5	obs??ugi droga zosta??a stos demonta??em foto demonta??em foto przekazywane futryna poluzowa??a przyjmuje dodatkowy Po??ar ''dachu'' gema podnoszono wystaj??cego	wann?? Natychmiast plomb ko??a temperatur?? magazynu temperatur?? magazynu kurtyn dna utrzymaniem wyra??nie naklei?? drewnianych mi??dzy wyczyszczenie dochodz??ce blach??	wystajacyelement.jpg	2021-09-07	2021-12-15
456	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-03-25	12	R6	2022-03-25	14:00:00	19	pr??g Poparzenie niepoprawnie swobodnego porz??dku ludzie- porz??dku ludzie- uwagi jednoznacznego element Potkni??cie temu drukarka zahaczenie zniszczenia wylanie	3	rega?? dra??ni??cych cz??ste DOSTA?? ca??ej pr??bie ca??ej pr??bie NIEU??YTE po??arowego upa???? oraz odcinaj??cy but lu??ne pojemniki istotne przewody	takich wykonywanie przestrzegania towar bezpiecze??stwa sprawnej bezpiecze??stwa sprawnej osoby/oznaczy?? rodzaju ??wietl??wek kraw????nika wykonanie bezwzgl??dnym komunikacyjne odblokowa?? sprawdzi?? boczn??	\N	2022-04-22	2022-04-28
337	2168af82-27fd-498d-a090-4a63429d8dd1	2021-08-23	12	na pro??b?? Pa?? - podest R6	2021-08-23	15:00:00	5	stref?? porysowane mog??a przechodz??cej doznania Uswiadomienie doznania Uswiadomienie kostki uszczerbku wysy??ki rozmowa zachowania tych praktycznie zniszczenia zdrowia	5	przewr??ci??y osob?? ustwiono nie zasilaj??ce gazowy zasilaj??ce gazowy po??lizg niebezpiecze??stwo elektryczne gotowych poruszaj??c?? przyjmuje stoj??ce wod?? ??wiartek krzes??a	korb?? oznaczenie substancj klosz DOSTARCZANIE upewnieniu DOSTARCZANIE upewnieniu UR kszta??t warunk??w otworzeniu ewakuacyjnej g??rnej brama/ Kontrola szeroko??ci upadkiem	magbudowlany.jpg	2021-08-30	\N
338	2168af82-27fd-498d-a090-4a63429d8dd1	2021-08-23	12	przej??cie R6 - R7	2021-08-23	15:00:00	5	spadajacy gniazdka Pozostalo???? stron?? ostreczowanej Przegrzanie ostreczowanej Przegrzanie budynk??w wpadni??cia Popa??enie maszynie ok spadku Zatrucie si??owego prawej	5	ni??ej przeniesienia opad??w Zwisaj??ca liniach ostry liniach ostry dach stalowych Kapi??cy rozbicia w????e ugaszony powstania si??owy Niedopa??ki opu??ci??	w??a??ciwych mocuje ustalenie prze??o??y?? kraty ci??ciu kraty ci??ciu operatorowi defekt??w Korekta u??yciem Prosze otynkowanie cz??sci przestrzegania schod??w stanowi??y	\N	2021-08-30	\N
372	2168af82-27fd-498d-a090-4a63429d8dd1	2021-10-19	3	R8 podest	2021-10-19	10:00:00	16	zdj??ciu wypadekkaseta stanie niezbednych cm kierunku cm kierunku ta??ma zwichni??cie- r????nicy ostre wycieraniu 15m nast??pnie WZROKU rury	3	kt??re spodu 80 zimno wystawa??a przetarcia wystawa??a przetarcia tl??cy balustrad proszkow?? stron niekontrolowany ludzi pasach du???? 700 Miedzy	przestrzegania oznakowany zakazu maszyn?? rampy ??rubami rampy ??rubami obydwu sprawdzi?? UR le??a??y regale zabezpieczy?? Rozpi??trowywanie O??wietli?? s??u??bowo obszarze	R8podest2.jpg	2021-11-16	2021-12-08
359	9c64da01-6d57-4778-a1e3-d25f3df07145	2021-09-21	12	R7 obok masyzny inspekcyjnej, dodane zdj??cie	2021-09-21	14:00:00	1	przewod??w karku zanieczyszczona drzwiami beczki pracownice beczki pracownice zap??onu przeje??d??aj??cy prasy ruchome przebywaj??cej g??rnych sieciowej piwnicy operatora	4	powiewa CZ????CIOWE/Jena no??ycowym Przeno??nik Przewr??ceniem ustawiony/przymocowany Przewr??ceniem ustawiony/przymocowany ??cianie ekranami p??ytki ??cie??k?? stoj??c?? foli?? razy zabezpieczone gazowych ??aduj??c	wypadku Kontakt Pouczenie OS??ONAMI tych lokalizacj?? tych lokalizacj?? prze??o??y?? w??zek odpowiedni?? widoczno???? Uzupe??nia?? pod????cze?? zabezpieczony korzystania czujki naprawic/uszczelni??	image-21-09-21-02-42(1).jpg	2021-10-05	2021-10-22
363	2168af82-27fd-498d-a090-4a63429d8dd1	2021-09-30	3	R8 podest	2021-09-30	03:00:00	16	wyrob??w Potencjalna rz??dka jednej zawalenie wysy??ki zawalenie wysy??ki budynku skutki ta??m?? Zwarciepora??enie zadzia??a rura zg??oszenia automatycznego osob??	4	nogi odzie?? produktu zniszczenie p????ce uderzenia p????ce uderzenia substancji jka przechyli?? pol poluzowa??a swobodnie zlewie wychodz??cych kluczyka u??ama??a	odp??ywowe gdzie stabilno??ci Reorganizacja wygrodzenie kontenera wygrodzenie kontenera wywieszenie by?? pojedy??czego schody pod????czenia o??wietleniowej nowy Wyci??cie powiesi?? Zachowa??	R8schodeklubbarierka.jpg	2021-10-14	2021-12-08
364	2168af82-27fd-498d-a090-4a63429d8dd1	2021-09-30	3	R8 podest	2021-09-30	03:00:00	16	po??lizgni??cie stawu os??ona d??oni- uderzy?? zabezpieczaj??ca uderzy?? zabezpieczaj??ca 15m przw??d r????nicy pracy- skutki: zadzia??a cm awaria 74-512	4	rowerze zacina kra??c??wki foli?? kraw????nikiem przepakowuje/sortuje kraw????nikiem przepakowuje/sortuje paletki w??zkiem uleg??a szybko mu zamocowane zwalniaj??cy znajduj??ce po??arniczej interwencja	karton??w na schody Oosby montaz ROZWOJU montaz ROZWOJU filtrom SZKLAN?? Wyprostowanie przedostanie PRZYTWIERDZENIE ociec warstwy roku okolicach instalacji	R8schodek.jpg	2021-10-14	2021-12-08
366	0b150b78-ca98-42d4-b9cf-dbe7872a667e	2021-10-07	12	Okolice automatycznego sortu linia R10	2021-10-07	08:00:00	5	zako??czony ??rodowiskowe Naruszenie du??ej wyj??cie d??wi??kowej wyj??cie d??wi??kowej cz??owieka ewakuacyjnym jednego zadzia??a cz?????? uszczerbku wid??owy wid??owe 2m	4	szklane prasa siatk?? stron wyznaczon?? czystego wyznaczon?? czystego utrudnionego wyd??u??ony ZAKOTWICZENIA upad??a upad??y GA??NICZEGO dzrzwi wypadek dzwoni??c oprzyrz??dowania	rozdzielcz?? stron?? powleczone Reklamacja odkrytej zamkni??ciu odkrytej zamkni??ciu swobodnego transporterze informacji wewn??trz poszycie wystawienie osoby/oznaczy?? wyrobu obszarze ruch	foto7.10.2021.jpg	2021-10-21	2022-02-07
367	9c64da01-6d57-4778-a1e3-d25f3df07145	2021-10-08	12	Banda obok schod??w	2021-10-08	15:00:00	1	ustawione Spadaj??cy pozosta??o??ci na komputer podno??nik komputer podno??nik rozdzielni fabryki obydwojga prawdopodobie??stwem czysto??ci lampa ??wietle prawdopodobie??stwo zahaczenie	2	d???? stref?? trafia spasowane urz??dze?? celu urz??dze?? celu metalowe dopad??a dzia??u g??rnej w????czone sorcie py?? stacji zostawiaj?? prowadz??ce	wykonywania oznaczony wiatraka niebezpieczne podwykonawc??w kraw??dzie podwykonawc??w kraw??dzie czarn?? polskim r??wno upadku pojedy??czego Wyeliminowanie piktorgamem poziomu codzienna firmy	\N	2021-12-03	2021-10-22
377	cf85acd7-7898-440e-970d-310e8ad84d4b	2021-10-19	4	Zapadni??ta kosta przy studzience na wprost butli z gazem 	2021-10-19	11:00:00	5	??cie??k?? szczelin?? ograniczenia Du??a st???? zbiorowy st???? zbiorowy zawadzenie r????nicy lod??wki usuwanie niezabezpieczone skrzyd??o zalanie przedmioty szatni	3	dniu Magazynier przesun???? elektryczn?? kolizj?? surowc??w kolizj?? surowc??w brudnego wcze??niej komunikacyjnej umo??liwiaj??cych dost??p d???? pakowania odprowadzaj??cej osadu telefoniczne	Ustawianie wzmo??onej pomiar??w bezpiecznie Zabudowanie rowerze Zabudowanie rowerze r9 patrz wi??cej system s??uchu podaczas bezpieczny przenie?? rekawicy ??cian??	\N	2021-11-16	\N
389	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-11-05	4	27.09.2021 rampa 10, A31, 12:00-14:00 za??aduek Animal Island	2021-11-05	13:00:00	19	zapalenia wychodz?? ludzi palet?? prasy uszkodzon?? prasy uszkodzon?? pr??dem uk??ad stanowiska szatni najprawdopodobnie znajduj??cy prac automatycznego spadajacy	4	k??towej Przymarz??o przekazywane kroplochwycie odprowadzaj??cej zapakowa?? odprowadzaj??cej zapakowa?? uleg??y produkcyjn?? uderzenia tekturowych zacz????o elektrycznysi??owy podno??nikowym pracuje wystaj??cymi dziurawy	Poprwaienie listew zabezpieczy?? ubranie ty??em szklanego ty??em szklanego dot??p rodzaj Poinstruowa?? stale szk??em wytyczonej uruchamianym wch??ania sposob??w w??wczas	\N	2021-11-19	2021-12-15
390	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-11-10	17	wisz??ce kable elektryczne	2021-11-10	14:00:00	6	W1 stanie uwagi pracy- rozszczenienia le????ca rozszczenienia le????ca porysowane Np ??ycia Uderzenie odboju sytuacji sk??adowana wyj??ciem zgrzewania	5	k????ko Opieranie powa??nych umo??liwienia Stwierdzono wolne Stwierdzono wolne pozadzka Przymarz??o czerpnia odkryte minutach Firma os??aniaj??ca sk????dowanie/pi??trowanie wiadomo pracuj??cych	oleju wyklepanie przydzielenie przechodni??w przeniesienie obecno???? przeniesienie obecno???? u??ytkowaniem przysz??o???? ukara?? umo??liwiaj??cych podest??w opisem os??yn Wg razie tak??e	\N	2021-11-17	2021-11-18
477	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2022-05-03	3	okolice R4 i R3	2022-05-03	01:00:00	17	rozci??cie transportowanych bram?? R4 mo??liwo??ci?? natrysk mo??liwo??ci?? natrysk rozmowa dostep przewody St??uczeniez??amanie noga wchodz?? ostre informacji ??ycia	3	czystego wyst??puj?? strefie dalszego kra??cowy ostrzegaj??ce kra??cowy ostrzegaj??ce ma sprz??tania os??ony podesty jednego r??cznych przej??cie farb porusza Operacyjnego	temperatury gro???? konsekwencjach naci??cie ostrego wiaty ostrego wiaty ko??cowej stan ochrony wyprostowa?? kolejno??ci zasadach ogranicenie prowadzenia najbli??szej konsekwencjach	\N	2022-05-31	2022-09-22
383	2168af82-27fd-498d-a090-4a63429d8dd1	2021-10-29	17	piwnica 	2021-10-29	02:00:00	19	upuszczenia operatora przechodz??ca umiejscowionych wyj??cie polerce wyj??cie polerce uderzenia le????cy nara??aj??cy ruchome awaryjnej pora??eniu umieli mog??y ??wietlno-	5	swobodnego kosza barierka warstwy przeno??nika wodzie przeno??nika wodzie fragment papierosa reszt?? nowe raz rusztowaniu miejscu roz??adowa?? przewo??enia roz??adowa??	uchwyty luzem w??zka Korekta sk??adanie obszaru sk??adanie obszaru przdstawicielami przysz??o???? stawania drzwiami opakowania big kamizelki zaj??cia szt spr????yn??	myjka2.jpg	2021-11-05	\N
386	1fa367b9-3777-4c85-889f-2cd8ffd19e75	2021-11-02	15	Hala	2021-11-02	09:00:00	5	w??zka Otarcie siatk?? kotwy st??uczenie udzia??em st??uczenie udzia??em paleciaki wi??kszych zapalenia prasy b??d?? futryny do Ponadto MO??liwo??c	3	przesuwaj??cy czyszcz??cej wje??d??a?? doja??cia karty strerownicz?? karty strerownicz?? zawsze zawiadomi??em schod??w audytu nagromadzenia ruchome paleciaku okna Tydzie?? ograniczaj??	szlamu ich Je??eli biurach ??atwe oprawy ??atwe oprawy Obecna magazynie biegn??c?? stopniem ??ancucha ci??g stanowi??y terenu przek??adane niedozwolonych	20211102_075842.jpg	2021-11-30	\N
391	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-11-10	15	Pomieszczenie z piaskarkami do czyszczenia form	2021-11-10	15:00:00	10	kartony kracie ka??d?? stanowisku pracownik??w energoch??onnej pracownik??w energoch??onnej gazowy uszczerbku skaleczenia podtrucia ??niegu klosza zniszczenia gotowych ??miertelnym	4	Dekoracja poruszaj??cych zawleczka pusta g??rnym ha??asu g??rnym ha??asu Nagromadzenie umo??liwienia Zawiesi??a zawleczka przejazd posiadaj??cej wszystkie zosta???? rampy r????nice	socjalnej blach?? ostro??no??ci ur??adze?? Poinstruowa?? elementu Poinstruowa?? elementu G miejscem nieuszkodzon?? odstawi?? zabezpiecznia tym za posadzki okolicy wyst??pienia	Palnikpiaskarki.jpg	2021-11-24	\N
393	4bae726c-d69c-4667-b489-9897c64257e4	2021-11-17	3	GK R9 obok polerki	2021-11-17	07:00:00	18	oparzenia strefa wystaj??cego zg??oszenia form sieciowej form sieciowej gor??ca ostreczowanej karton uzupe??niania r??kawiczkach paletach zbiorowy wy????cznika konstrykcji	5	piecyku zaw??r spadaj??ce z???? P??yta ??r??cych P??yta ??r??cych gor??cymi przywr??cony kana??em wi??ry starej stanie u??o??ono pozwala okre??lonego samochodu	obchody karton??w w??zkami osuszy?? wyrobu przepakowania wyrobu przepakowania zakaz licuj??cej maseczek nieprzestrzeganie Systematyczne realizacj?? no??ycowego odpowiednich napraw kt??rym	\N	2021-11-24	2021-12-08
408	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-11-30	15	warsztat cnc	2021-11-30	13:00:00	18	strefa lampa s?? posadzce pradem d??o?? pradem d??o?? czytelno??ci wyst??pi?? wybuch Opr????nienie warsztat powietrze ewakuacji mog?? niekontrolowany	2	pochwycenia powiewa ci????ka ztandardowej schody pro??b?? schody pro??b?? lampie mia??am Klosz wid??owy podjecha?? materia????w Usterka oprzyrz??dowania kostk?? droga	dokona?? Poinformowa?? poprowadzi?? odkrytej Palety identyfikacji Palety identyfikacji nakazie przeprowadzi?? bezwzgl??dnym operatorom dystrybutor elektrycznego odbywa??by miesi??cznego tak??e dojdzie	\N	2022-01-25	\N
410	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-12-17	12	Wyj??cie na zewn??trz hali od strony sortowni R9	2021-12-17	10:00:00	18	uszkodzeniu nadpalony uszkodzenie st???? uchwyt??w obs??ugi uchwyt??w obs??ugi przekraczaj??cy ta??ma agregatu ewakuacji ??rodowiskowe mog?? przyczepiony obtarcie dystrybutor	2	kropli zu??yt?? podj????em osob?? tekturowymi nagromadzenia tekturowymi nagromadzenia dzrzwi py?? wi??c ramp sortowania ba??ki zatrzyma?? odgradza Uszkodziny z??ej	rozlania kabli nakazu jaskraw?? charakterystyk umy?? charakterystyk umy?? zasilania mog??a innym oraz blacyy palet??? wid??owych nieco i ustalaj??ce	DrzwiR9.jpg	2022-02-11	2021-12-29
412	4bae726c-d69c-4667-b489-9897c64257e4	2021-12-30	4	Przej??cie wok???? bramy wjazdowej 	2021-12-30	13:00:00	18	elektryczna oprzyrz??dowania sa utrzymania doznania wiedzieli doznania wiedzieli pod??ogi ??miertelny wyst??pi?? ??rodka okular??w silnika ognia zapewniaj??cego przetarcie	4	rynienki pietrze zakotwiczone p??ynu przechylenie wy????cznik przechylenie wy????cznik ma??ych Zastawienie funkcj?? konstrukcja blokuj?? zako??czenia otwartym opakowaniami kasku wyt??ocznikami	musz?? strony ratunkowym jaskrawy przej??cia poprawienie przej??cia poprawienie Najlepiej zako??czonym wy????cznie postoju tematu Przestrzeganie niemo??liwe Za??o??enie form Rega??	zpw12.jpg	2022-01-13	\N
420	9c64da01-6d57-4778-a1e3-d25f3df07145	2022-01-03	1	Pok??j specjalist??w ds. kontroli jako??ci	2022-01-03	14:00:00	6	ta??ma niekontrolowane przy WZROKU nara??one wybuch nara??one wybuch brak pr??by szatni niecki spadek ma??o regeneracyjne ziemi zalania	3	wide?? stref?? st????enia zmianie we zapewnienia we zapewnienia tryb Odm??wi?? Samoczynne Obecnie stopni p??n??w zranienia barierek s??uchu asortymentu	pojemnik??w obszarze stortoweni kt??ry hydrantowej ??niegu hydrantowej ??niegu ochrony b??d?? umieszcza?? ko??nierzu lini?? now?? Trwa??e Ustawi?? ko??ysta?? zainstalowanie	\N	2022-01-31	2022-01-17
423	da14c0c1-09a5-42c1-8604-44ff5c8cd747	2022-01-20	12	Ciekn??cy dach mi??dzy lini?? R6 a R7, na schody kapie woda	2022-01-20	08:00:00	18	Pozosta??o???? stron?? d??o?? dekoracj?? k????ko drzwiami k????ko drzwiami sieciowej okolo g????wnego komputer??w w powy??ej sortowanie zadzia??a robi??	3	posadzce r??kawiczka furtce ich awaryjnego Nier??wna awaryjnego Nier??wna opr????ni?? posadzce guma szykowania ewakuacji rega??u p??ytek odpowiednie Berakn?? cz??????	odgrodzenia ubranie k????ek koryguj??ce podesty przewody podesty przewody stolik zdania streczem ??cie??ce kolejno??ci por??cze wewn??trz Natychmiastowy pieszych kra??c??wki	\N	2022-02-17	\N
397	c9f77484-7d39-44d1-aa7c-7c1ac09a24ce	2021-11-29	12	Zimny koniec okolice automatycznewgo sortu linia R7	2021-11-29	08:00:00	16	WZROKU widocznego bia??a osob?? pozosta???? palecie pozosta???? palecie niezabezpieczone pracuj??cego korb?? komputer??w wizerunkowe bezpiecznej na godzinach podestu	4	medycznych wystepuje mocno sekundowe zatopionej dzia??ania zatopionej dzia??ania kawa??ki eksploatacyjnych swobodnie z id??cy 66 ha??asu mechanicznie czego kroplochwyt	liniach zakazu prac?? Kompleksowy steruj??cego Konieczno???? steruj??cego Konieczno???? Widoczne Systematyczne zasad Kompleksowy istniej??cym zabezpiecze?? magazynowaia Uzupe??niono rewersja uzyska??	R7zk.jpg	2021-12-13	2022-02-07
404	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-11-22	15	Warsztat	2021-11-22	12:00:00	18	mocowania nask??rka g??ow?? lod??wki Cie??kie Wystaj??cy Cie??kie Wystaj??cy r??kawiczka kolizja pradem ods??oni??ty pod zdarzeniu wraz zagro??enie rozlanie	3	sk??adowany przechodz??c przechyleniem stwarzaj?? przechodz??cych Uszkodzona przechodz??cych Uszkodzona opakowaniami ??rodku otwieranie ochrony kiedy robi??ca najechania ci??nieniem tymi kieruj??cym	owalu tendencji postoju Wi??ksza wodnego napawania wodnego napawania powiesi?? ilo???? miesi??cznego produkcji r??cznego nast??pnie ta??my Oznaczy?? zapewni?? wanienki	20211122_125617.jpg	2021-12-28	2021-12-17
414	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-12-31	10	Droga od strony przeno??nika rolkowego	2021-12-31	10:00:00	23	szafy stopie?? Zatrucie wid??owym Upadek elektryczna Upadek elektryczna do??u dotyczy mocowania poziomu Towar Balustrada przerwy gazu mo??liwo??ci	4	Gor??ce Panel elektryczny znajduj??cego gdy skrzyd??o gdy skrzyd??o pieszych palet SUW zmieni?? zatrzymaniu stali prasy siatki ruchomych w??zku	typu stosowania przyj??cia odpowiedniego nakazie ??rednicy nakazie ??rednicy myjki kszta??cie Uruchomi?? dost??p wyr??wnach jazdy natychmiastowym praktyk kratke jednolitego	\N	2022-01-14	\N
417	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-12-31	12	Sortownia przy rampach	2021-12-31	10:00:00	25	po??arowego ewentualny zawroty zw??aszcza instaluj??c?? d??oni- instaluj??c?? d??oni- czas przep??ukiwania element??w ostrym 4 drabiny paletszk??a wybuchupo??aru d??oni	2	Wychylanie platformie przy wcze??niej produkcji zatopionej produkcji zatopionej Rozwini??ty u??ywaj?? nieoznakowane najechanie spad?? panuje przechodz??c obudowa/szkrzynka rusztowaniu komunikat	informacja otworu okolice zabezpieczony zakup k??tem zakup k??tem stosowaniu tematu pod??o??a hydrantowej stanowiskach paletami nakazie foto przymocowanych OSB	20211231_085444.jpg	2022-02-25	\N
419	9c64da01-6d57-4778-a1e3-d25f3df07145	2022-01-03	1	Pok??j specjalist??w ds. kontroli jako??ci	2022-01-03	13:00:00	6	zako??czona st???? Elektrktryk??wDzia??u maszynie o obydwu o obydwu jak widoczny sortowni pozosta???? urazy prasa Zanieczyszczenie - wypadku-	2	Poszkodowany stalowych sadzy kraw??dzie opr????ni?? po?? opr????ni?? po?? stosie ??liskie trzeba swoj?? po??lizgn????em Worki nog?? ryzyku R7 osobom	silnikowym czarna U??ywanie drogowych Wyci??cie dzia????w Wyci??cie dzia????w temperatury stanowi??y Przytwierdzi?? wyrobem takiego pras?? dost??p ukryty ????cz??cych szlamu	\N	2022-02-28	2022-01-17
438	c969e290-7ed2-4eef-9818-7553f1ecee0e	2022-02-10	15	Dawny magazyn opakowa?? 	2022-02-10	09:00:00	6	wci??gni??cia ponowne du??ym Np przechodni??w St??uczenia przechodni??w St??uczenia kostce magazynowana Uszkodzony z inspekcyjnej Potkni??cie spr????onego zatrucia firm??	2	spuchni??te papierosa skrzyd??o zdarzeniu kilka Stanowisko kilka Stanowisko Panel ca??ego zanieczyszczenie natrysku zatrzymaniu czym siatk?? zapalenia u??wiadomionego ci??gowni	przebywania tym mo??liwie jarzmie wyposa??enia uwzgl??dnieniem wyposa??enia uwzgl??dnieniem zdarzeniu rekawicy utrzymywania ponowne lekcji przemywania operatora pust?? u??ytkowaniu zapewnienia	PWsortR78.jpg	2022-04-07	\N
444	c9f77484-7d39-44d1-aa7c-7c1ac09a24ce	2022-02-11	12	Przej??cie schodami nad przeno??nikiem poprzecznym doprowadzaj??cym szk??o do maszyny inspekcyjnej	2022-02-11	11:00:00	18	przygotowania obok ??cie??k?? Uszkodzona magazynowana wpadni??cia magazynowana wpadni??cia wpychaniu dotycz??cego szklanym zgrzeb??owy fabryki przyczepiony zawadzenie elementem otwierania	4	zbiornik zamocowane wypi??cie ziemi futryna krzes??em futryna krzes??em wzrostu k??towej m??g?? rusztowaniu mate zastawione brakowe zsuwania ??arzy?? paltea	system??w rozpinan?? szk??a por??cze jak sto??u jak sto??u ochronnej Proponowanym kart?? ruchom?? Usuni??cie/ jazdy sk??adanie kt??ra blisko wy????czania	odprezarkar7.jpg	2022-02-25	\N
447	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-02-28	12	Paletyzator	2022-02-28	09:00:00	5	kabli wizerunkowe stref?? mocowania przw??d "podwieszonej" przw??d "podwieszonej" infrastruktury Powa??ny zatrzymana spowodowa?? uszczerbkiem rz??dka odk??adane st???? sk??adowania	3	dwa wiatraki drewniany uwolnienie Zastawiony pali??/tli?? Zastawiony pali??/tli?? sufitu odci??gowej aluminiowego zamka pozostawiony jak: wykonany mocno stref?? ograniczone	usytuowanie innych Ustawianie folii s??upkach jasne s??upkach jasne wyznaczone przemywania wyt??ocznik??w zgodn?? wykonywania Egzekwowanie blokady blisko osuszenia komunikacj??	\N	2022-03-28	2022-03-02
426	497c3ff2-60bf-4a5e-bc73-e2fd6c619637	2022-01-24	12	Przej??cie z sortowni na produkcj?? przy R9.	2022-01-24	07:00:00	18	kratce Mo??lio???? ha??as wyj??ciowych urz??dze?? pod??og?? urz??dze?? pod??og?? mokrej lampa sk??adaj??c?? przemieszczaniu WZROKU przerwy mocowania potencjalnie posadzki	2	rozbicia takie sekcji Duda ??ciankach UCUE ??ciankach UCUE Ustawienie Przekroczenie Uderzenie dwie zamkni??cia proszkow?? stwarza pod??ogi A3 ci??gowni	zastawia??" ubranie poinformowanie drogach co uczulenie co uczulenie Pomalowa?? pol maty zakup szklarskich ma uczulenie transportowania operatora szlamu	IMG_20210804_081746.jpg	2022-03-21	2022-02-07
431	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-01-31	2	Miejsce sk??adowania st??uczki w workach przy rampach	2022-01-31	12:00:00	19	ewakuacja znajduj??cej powietrze uchwyt??w transportu bezpieczne transportu bezpieczne zlamanie posadowiony dobrowadzi??o szatni itd r10 os??ony drukarka studni	3	podnoszono kamizelka Przechowywanie pada przeciwpo??arowego gniazda przeciwpo??arowego gniazda kluczyka pracownik p??omienia zdrowiu stosie Royal szuflad?? powoduje tego przedostaje	oczka worka magazynowanie przeno??nik??w jedn?? zaznaczenia jedn?? zaznaczenia Umieszczenie pomoc?? o jakim kt??ry wypadkowego Udro??enienie zabezpiecza jeden tylko	\N	2022-02-28	\N
11	0fb6b96b-96a8-4a39-a0e2-459511d1c563	2019-09-05	12	Dzwignik przy pode??cie R8	2019-09-05	16:00:00	0	Cie??kie rozci??cie okolic du??ej zalenie Zanieczyszczenie zalenie Zanieczyszczenie wiedzieli rozdzielni roznie???? s??amanie pokarmowy- klosza cia??a bezpieczne s??uchu	\N	przyczyn?? wystaj??cy pracownik??w magazyniera ??ciany transporterze ??ciany transporterze Utrudniony Przekroczenie obkurcza wykonany nak??adki wr??ci?? przypadku sadzy funkcj?? wszystkie	montaz stortoweni przegl??danie pr??g hydranty samoczynnego hydranty samoczynnego niszczarki taczki Szkolenia ilo??ci oczu chemicznej otwierana SZKLA r??kawiczki R10	\N	\N	\N
21	4e8bfd59-71d3-44b0-af9e-268860f19171	2019-10-18	3	R-10	2019-10-18	11:00:00	0	maszyny od??o??y?? kt??re kogo?? pracownikami dostepu pracownikami dostepu Miejsce palety st??uczenie palety towaru stawu Potencjalne mog?? wod??	\N	mieszad??a Odstaj??ca przewr??ci kroplochwycie przepakowuje/sortuje wymieniono przepakowuje/sortuje wymieniono zaciera kogo?? taki otrzyma?? d??oni wid??ach stopy tej osadzonej drugiej	ROZWOJU metalowych odstawianie ci??gi biegn??c?? sprawnego biegn??c?? sprawnego kotwi??cymi spr????ynowej chc??c budowy ubranie przechylenie odgrodzonym spi??trowanych fotela kontener??w	\N	\N	2020-12-29
32	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2019-12-16	3	R-9	2019-12-16	21:00:00	0	wystaj?? ??atwopalnych pracownicy nog?? poprzepalane zdrowiu poprzepalane zdrowiu d??wi??kowej Uszkodzony Przyczyna i paleciaka wypadek tekturowych 85dB pojazdem	\N	odpr????ark?? R Niedopa??ki wy????cznikiem ma??a Royal ma??a Royal MECHANICZNY 6 powodu automatyzacji tnie uchyt id??cy Kratka frontowego 2021984	Odnie???? szklanymi ca??o??ci natychmiastowym rur?? kontrolnych rur?? kontrolnych otynkowanie elementu jej od maszyn?? ka??dych przykryta Uczuli?? pozostowanie ewentualnie	\N	\N	2020-12-29
33	4e8bfd59-71d3-44b0-af9e-268860f19171	2019-12-18	3	R-10	2019-12-18	01:00:00	0	korb?? Uderzenie z??amania ostro??no??ci ostrym Przeno??nik ostrym Przeno??nik zadzia??a gotowe kartony zapali??a Przewracaj??ce urz??dzenia zapali??a ??rodowiskowym- mo??e	\N	przeje??dzaj??c szfy oznakowane wykonywana zgrzeb??owego ha??asu zgrzeb??owego ha??asu intensywnych transportowej Gor??ca Niedzia??aj??cy ruchome uwagi 8 U dni Kapi??cy	informacyjne ty??em filtry stosu ga??nicy razie ga??nicy razie ostre odgrodzi?? Skrzynia Urzyma?? odpowiedniego pas??w sprawie codzienna GOTOWYCH konstrukcj??	\N	\N	\N
74	80f879ea-0957-49e9-b618-eaad78f7fa01	2020-11-27	12	Sortownia obok R10	2020-11-27	11:00:00	0	por??wna?? oderwania ponowne prawdopodobie??stwo stopni R1 stopni R1 Stary godzinach skutkiem zasygnalizowania wy????cznika dokonania uszkodzone zniszczony ruchome	\N	ci??cie przew??d odzie?? krotnie okolicy momencie okolicy momencie lej??ca stosowanie wyst??puje dra??ni??cych momencie podtrzymanie produktu wentylacyjn?? os??oni??te telefoniczne	nadzorowa?? obci????enia produkcji puszki os??on stron?? os??on stron?? mog?? czarna przeznaczeniem matami dopuszczalna opakowaniami pracownikach stanowiskami powiesi?? s??upkach	\N	\N	2022-02-08
98	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-02-02	3	Chwiej??ca si?? kratka na pode??cie przy zasialczu R4	2021-02-02	13:00:00	1	zako??czenie noga pozostawione pobli??u kratce kolizja kratce kolizja s??uchu ga??nic pracownicy niezbednych obydwojga trwa??y zdarzeniu niekontrolowane instalacji	4	wyje??d??a r??kawicami ochrony "nie opar??w ??a??cuch??w opar??w ??a??cuch??w widoczna Mo??liwo???? opr????ni?? prac Towar zosta?? przewr??cenia ale zawieszonej wyst??puje	innych urz??dzeniu dosz??o przed??u??ki jasne plomb jasne plomb sposob??w ROZWOJU Uczuli?? pozosta??ego Dok??adnie jaskraw?? pocz??tku u??yciem sk??adowanie/ niezb??dnych	\N	2021-02-16	2021-12-10
478	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2022-05-04	3	R2	2022-05-04	00:00:00	5	odk??adane prac szatni r??kawiczkach urata wskazanym urata wskazanym sk??adowania gasz??cych si??owego co komu?? rega????w organizm Utrudniony przygotowania	3	tym swobodne stwarza?? stalowe biurowi usuwania biurowi usuwania spodziewa?? prowadz??ce moze opu??ci??a sekcji bliskim nieprzystosowany Kapi??cy zaciera W??A??CIWE	utraty mie?? ci??cia rozbryzgiem zagro??enia kraw????nika zagro??enia kraw????nika i stanowisk wystawienie malarni nara??aj??ca siatk?? etykiety okre??lone m ropownicami	\N	2022-06-01	\N
470	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2022-04-22	3	Prasa R9	2022-04-22	13:00:00	9	wzrokiem pora??anie j?? podczas posadzki zapewniaj??cego posadzki zapewniaj??cego paletach gdy?? podestu polerki ska??enie widocznej konsekwencji kszta??cie Tydzie??	5	zdj klej??cej sobie niestabilnie platformie elektrycznych platformie elektrycznych zagro??eniee magazynowych st??uczk?? magazynowych silnego jakiegokolwiek skrzynka stwarza nowe pracach	progu na Dosuni??cie st??uczk?? ustawiona ostrych ustawiona ostrych zamocowany ochronnik??w bortnice lewo klamry ostrzegawczymi wyznaczonymi sposob??w system ruroci??gu	\N	2022-04-29	\N
354	4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	2021-09-18	3	Prasa R10	2021-09-18	05:00:00	5	producenta Przer??cone to uszczerbkiem sa Gdy sa Gdy kostce jednego Niestabilnie Powa??ny skokowego noga stopie?? ruchu gor??cejzimnej	3	stopnie dost??p transportu rynien wod?? schod??w wod?? schod??w palec bezw??adnie roz????czenia pozwala poszdzk?? p??ynu otwierania Duda ustawione prac	scie??k?? wygrodzenie tak??e potencjalnie malarni Utrzymanie malarni Utrzymanie pozby?? rynny blache przechylenie warunki ci??cia ustali?? stortoweni rodzaj dziennego	\N	2021-10-17	2021-10-28
134	57b84c80-a067-43b7-98a0-ee22a5411c0e	2021-03-02	4	Droga wewn??trzna od portierni do wej??cia na sort przy prasie R1	2021-03-02	13:00:00	18	zwichni??cia ??rodowiskowe chemicznej Ludzie nadpalony stopek nadpalony stopek wysokosci drukarka pochylni za pracownice zosta??o Zwisaj??cy Z??amaniest??uczenieupadek paletach	4	dosuni??te zapr??szonych Poszkodowana jka spos??b hal?? spos??b hal?? wchodz?? ponownie przejazdu magazynier??w otworzeniu roz??adunku opakowaniami wchodzi platformowego podgrzewa??	Stadaryzacja skrzyni Rozmowy owalu serwis??w ca??o??ci serwis??w ca??o??ci portiernii oceny miejscami brakuj??cego miejscu g??ry form przeprowadzenie kontenera towarem	\N	2021-03-16	\N
156	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2021-03-15	12	Sortownia, naprzeciwko R8	2021-03-15	12:00:00	25	polegaj??cy stop?? s??upek obydwu wi??cej gwo??dzie wi??cej gwo??dzie zsun???? niestabilny urwania barierka sa oosby wskazania koszyk spowodowanie	5	??wiat??a bariery otoczeniu podniesiona stoj??c?? natrysku stoj??c?? natrysku wykonany przykryte p??omienia otw??r kask/ kamerami kropli produkcj?? pozwala ga??nic??	??adowania Odgarni??cie odpowiednich przewidzianych oznakowany prze??o??onych oznakowany prze??o??onych kierownik??w czujnik??w stabiln?? Dospawa?? k??ta dost??pem obecno???? Korekta odpowiednie ustawiania	20210315_114857.jpg	2021-03-22	2022-02-08
175	e89c35ee-ad74-4fa9-a781-14e8b06c9340	2021-03-22	4	Na korytarzu, naprzeciwko drzwi wej??ciowych do szatni malarni stoi szafka, kt??a powoduje, ??e po otworzeniu drzwi do szatni jest niewiele miejsca na przej??cie mi??dzy ni?? a otwartymi drzwiami. Generuje to powa??ne ryzyko uderzenia drzwiami osob??, kt??ra w momencie otwierania drzwi chcia??aby omin???? szafk??.	2021-03-22	10:00:00	5	ca???? Najechanie zawalenie uszkodzenia karton charakterystyki karton charakterystyki drzwiowym okolo po??aru mie?? podestu posadzce dost??pu zadzia??a form??	4	CNC produkcji otworu wysuniet?? pracuj??ca u??ywaj?? pracuj??ca u??ywaj?? uda 700 szklan?? zas??aniaj?? sobie przekrzywiony MWG bortnicy powietrzu wpad??a	poprawi?? piwnicy niedopuszczenie p??yt cykliczneserwis hydrant??w cykliczneserwis hydrant??w n????k?? biurowym Wprowadzi?? okular??w na pocz??tku Przestawienie kolor sprawdzania rega????w	\N	2021-03-31	\N
220	fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	2021-04-27	3	Wystaj??ce pr??ty z posadzki przy odpr????arce R1	2021-04-27	14:00:00	2	wystrza?? zdrowiu rodzaju upa???? obs??uguj??cego ba??agan obs??uguj??cego ba??agan studni zsuni??cia Utrudniony zas??ony paletyzatora zaczadzeniespalenie cz?????? malarni pracuj??cego	5	but??w niebezpiecznie ??le wyrobami po??piechu usuwaj?? po??piechu usuwaj?? oddelegowany linii poniewa?? sie o??wietleniowe rynienki i zahaczenie uszkodzon?? pracowik??w	oceniaj??ce czynno??ci jest palet??? praktyki i praktyki i odci??cie sk??adowanym obszaru prawid??owe Pomalowanie podest??w sortu streczem Egzekwowanie pracownika	\N	2021-05-04	2022-01-19
221	05e455a5-257b-4339-a4fd-9166edbae5b5	2021-04-27	4	Droga przed malarni??	2021-04-27	14:00:00	25	innych trzymaj?? ko??czyny dost??pu kart?? hali kart?? hali zale??no??ci wiedzieli telefon gazowy substancji sk??adowane je??d????ce przewr??cenia materialne	3	napoje dziurawy wyst??puj?? kropla odsuni??cie rozmiaru odsuni??cie rozmiaru szafie rozdzielni za??amania strumieniem w??a??ciwego przy??bicy poinformowany trzeba standard taki	drzwiowego kotroli poziome ukara?? nara??ania okre??lonych nara??ania okre??lonych ochrony os??aniaj??ca oslony wymalowanych informacj?? schod??w O??wietli?? blokuj??cej fragmentu taczki	\N	2021-05-25	\N
233	2168af82-27fd-498d-a090-4a63429d8dd1	2021-05-09	3	W 2 i zasilacze,	2021-05-09	03:00:00	14	ca???? znajduj??cego ??rodka stoi drugiego udzkodzenia drugiego udzkodzenia butli awaria skokowego gor??c?? wod?? korb?? utrzymania kolizja wchodz??ca	4	gor??c?? wykonuj?? odzie?? RYZYKO kana??em brakowe kana??em brakowe ??e dziura podczs pomog??a Tydzie?? Zastawienie trzaskanie sterty st??uczk?? uniesionych	ograniczaj??cego nowej boku okular??w odrzucaniem odp??ywowej odrzucaniem odp??ywowej r??wnej posypanie wspornik??w rega??ami kuchennych terenu robocze os??b Kartony otwarcia	\N	2021-05-23	2021-10-12
234	2168af82-27fd-498d-a090-4a63429d8dd1	2021-05-09	3	sanitariaty przy dziale produkcji,	2021-05-09	03:00:00	5	spi??trowanych wid??owe rozmowa za dostepu Gdy dostepu Gdy cm bezpiecznej regeneracyjnego uraz??w "podwieszonej" sko??czy?? uszkodzone por??wna?? przykrycia	2	pokryte zaw??r st??uczka przemieszczajacych pionowym odgradza pionowym odgradza Elektrycy pol k??adce zawadzenia korytarzu ga??nicze: wystaj??ce przemyciu poruszania podjazdowych	obs??uguj??cego drzwiowego Okre??lenie potencjalnie wyja??ni?? transportu wyja??ni?? transportu budowlanych Korelacja wodzie elektrycznymi kratek niekt??re niezgodno??ci poszycie kra??c??wki maszyn??	\N	2021-07-04	2021-10-12
269	8aed61ca-62f5-445f-993b-26bbcf0c7419	2021-06-17	11	Obszar w kt??rym sta??a karuzela Giga. Obecnie stoj?? cz????ci do nowej linii sortowania szk??a.	2021-06-17	01:00:00	17	wydajno??ci uderzeniem Opr????nienie p??ytek ??????te komputer ??????te komputer opakowa?? dolne st??uczki r??k pobli??u zamocowana urazu straty momencie	2	futryna ceg??y niewystarczaj??ca Mo??liwo??c du???? stopni du???? stopni istotne ta??mowego Worki palec starej Wykonuje brakowe zawadzaj??c cofaj??c 406	odboje przej??cie stawiania palet nowa wyczyszczenie nowa wyczyszczenie le??a??y wej??ciu wanienki pi??trowaniu Poprawny wymianie+ skladowanie pieca operatorom pas??w	\N	2021-08-12	2021-12-15
282	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2021-06-25	10	Magazyn Opakowa??, alejka na wprost 1 bramy	2021-06-25	13:00:00	26	j?? form?? uszkodzeniu rozdzielni elektronicznego wysy??kowego elektronicznego wysy??kowego obs??ugiwa?? i SKALECZENIE koszyk ga??niczy prowadz??ce ka??d?? ostreczowanej wraz	3	widoczno???? do??wietlenie wi??kszo???? zlokalizowane ci??cia CIEKN??CY ci??cia CIEKN??CY alejki ograniczy??em ustwiono transporterach Wok???? 800??C jednej 5m jedn?? przepe??niony	pobierania polerki wychwytywania podest??w/ Mycie s??u??bowo Mycie s??u??bowo metalowy przypomniec przenie?? nast??pnie jaskrawy przegrzewania kt??ra nara??aj??ca Systematycznie podno??nika	\N	2021-07-27	2021-12-07
479	0b150b78-ca98-42d4-b9cf-dbe7872a667e	2022-05-06	4	Nowe szatnie	2022-05-06	12:00:00	14	powietrze ci??gi deszczu po??aru pracownik??w St??uczenia pracownik??w St??uczenia kropli u??ytkowana ka??dorazowo spi??trowanych prac?? St??uczeniez??amanie potr??cenie wyrobach podestu	2	pistoletu ch??odz??c?? odrzutu sterowania powierzchni przymocowany powierzchni przymocowany gro????c pietrze si??gaj??ca schod??w ko??cz??c szyby to g??rze filtry le????cy	serwis??w wyra??nie koryguj??cych wszystkich pi??trowa?? Kontrola pi??trowa?? Kontrola Wdro??enie obok spod porz??dek g??ry okresie godz ??cianki os??oni?? brakuj??cy	fotoszatnia.jpg	2022-07-01	2022-09-23
399	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2021-11-30	4	Nowy ci??g pieszych, wydzielony barierami ??elbetowymi, na wysoko??ci zbiornika buforowego ppo??. 	2021-11-30	09:00:00	18	po??lizgu urz??dze?? jak odpowiedniego zasilaczu r??kawiczkach zasilaczu r??kawiczkach przerwy bramy gazwego tj sortowanie szk??em zapalenia wywo??anie zdrmontowanego	3	rejonu by??o odpalony sortowi Nier??wna wygrzewaj??cego Nier??wna wygrzewaj??cego testu zestawiarni poziomu sprawdzenie prowizoryczny rejonu st??uczk?? skaleczenia wystaj??cymi problem	dopuszczalne tak??e przesun???? Poprwaienie rozwi??zana jaki rozwi??zana jaki Dodatkowo ??atwopalne by Zamyka?? wy????cznie g????wnym u??wiadomi?? przykr??cenie stolik wymienia??	\N	2021-12-28	2022-01-18
405	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-11-30	15	Obszar przy piaskarce automatycznej	2021-11-30	12:00:00	18	ustawione Uraz oparzenia Mozliwo???? dojazd po??aru dojazd po??aru polerki 40 nask??rka by??a we kana??u gor??cejzimnej drabiny nara??aj??cy	3	samozamykacz taka dachem powietrza o u??ywaj?? o u??ywaj?? do chcia?? weryfikacji odcinaj??cy zamontowane pieszego wyt??ocznik??w monta??u ??r??cych wej??cie	ca??o??ci skrzynkami k????ek naprowadzaj??ca ustawiania futryny ustawiania futryny przew??d stosowanych nadpalonego nieprzestrzeganie wielko???? Niedopuszczalne poprawnego karty kra??cowy ile	20211130_103618.jpg	2021-12-28	\N
457	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-03-25	12	R6	2022-03-25	14:00:00	16	ko??cowej sieciowej z wyrobach opa??enie zapalenia opa??enie zapalenia obszaru ostro pomieszcze?? grup ????czenie spowodowanie drogim ??cie??k?? "podwieszonej"	3	poruszajacej za??lepia??a schodzi??am dost??p przykryte 406 przykryte 406 mog?? wype??niona sprz??tania konstrukcj?? technologiczny osobowy zak??adu Operator ODPRYSK chroni??ca	w??zkiem skrzynce jednopunktowej Konieczno???? Odgarni??cie noszenia Odgarni??cie noszenia powieszni rur?? poziomych przed??u??ki burty bortnic opakowa?? r??wnej firm?? rozmieszcza	1647853350512.jpg	2022-04-22	2022-09-23
483	2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	2022-05-16	4	Piwnica, trakt mi??dzy spr????atkami a transporterem st??uczki odprowadzaj??cym braki  z sortowni.	2022-05-16	13:00:00	18	Utrudnienie Czyszczenie obudowa wybuchowa poruszania pot??uczona poruszania pot??uczona za uszkodzenie barjerki sko??czy?? itd ziemi efekcie przypadku wci??gni??cia	3	PODP??R platformowego eksploatacyjnych porusza wiadomo przemieszczania wiadomo przemieszczania oznakowane wzgl??du ucz??szczaj?? otwieraniem zimno szmaty stosownych Nier??wno???? ruchoma zbiornik	wypadkowego os??on pewno rozdzielcz?? Utrzymanie Weryfikacja Utrzymanie Weryfikacja uraz os??on?? Zebranie sztywno nara??aj??ca zorganizowa?? tymczasowe skutecznego stanowiskach dopuszcza??	ZPW3.jpg	2022-06-13	2022-05-26
487	9c64da01-6d57-4778-a1e3-d25f3df07145	2022-05-27	2	Nieszczelno???? w dachu	2022-05-27	14:00:00	2	operatora zalania pod????czenia uchybienia cia??a znajduj??cy cia??a znajduj??cy zablokowane nim wraz spadek spi??trowanej by??y odk??adane przewod??w ??rodowiskowym-	3	nale??y zatrzymywania wzros??a sterowni pojemniki zbiornik pojemniki zbiornik odci??gowej ??rodk??w pakowania ma strat wanienki przewr??ci??y gotowymi piecu piecyku	kable niesprawnego ka??dym potencjalnie Czyszczenie s??siedzcwta Czyszczenie s??siedzcwta Uszkodzone zastawianiu zagro??eniach brak routera Peszle telefon??w u??wiadomi?? przeno??nikeim pracuje	received_741508627196645(002).jpg	2022-06-24	2022-09-22
491	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-05-31	12	R3/R4	2022-05-31	07:00:00	19	zamocowana 2 jednej tokarski w??zka pozycji w??zka pozycji razie elementy rozpi??cie tego sygnalizacji Utrudniona Zbyt pieszego wi??cej	3	bariera ochronnik??w uszkadzaj??c obieg wiatru na wiatru na filtra cz??sto r??wnowagi pozostawiona tymczasowej Mokra s??u??y pionowej "niefortunnie" dymu	u??ytkowania obs??uguj??cego schody oleju lepsz?? piec lepsz?? piec powoduj??cy drabimny nap??dem niskich przemieszczenie ??rodk??w gumowe mocny ??cian?? obszar	\N	2022-06-28	2022-05-31
406	47663ef2-8d7b-42f2-b5b0-50656b44603a	2021-11-30	15	warsztat / nowy magazyn oprzyrz??dowania	2021-11-30	12:00:00	6	powr??ci?? b??d??cych stop?? niezgodnie za??og?? hydrantu za??og?? hydrantu zerwana materialne- reagowania Nier??wno???? drabiny zagro??enie dostepu zapalenia sk??ry	4	s??upek do Hu??taj??ce usun???? blokowane powierzchowna blokowane powierzchowna technicznych USZKODZENIE wygi??cia zgrzeb??owego transportu zas??abni??cie wi??c prasy otworu Pozotsawiony	lekcji ODBIERA?? element??w przeznaczonym Po??o??y?? zabezpiecznia Po??o??y?? zabezpiecznia kontenera podno??nikiem wszelkich prawid??owych ko??a stawiania niezb??dnych potrzeby stoper pomiar	\N	2021-12-14	2022-01-18
432	05e455a5-257b-4339-a4fd-9166edbae5b5	2022-01-31	5	Miejsce naprawy palet	2022-01-31	12:00:00	24	itp konstrukcji o Ponadto Np ugaszone Np ugaszone zapalenia inspekcyjnej niezgodnie le????ce barierka k??tem sie ??ycia drugiej	3	doj???? Niezas??oni??te b??d??c opakowaniami j?? st??umienia j?? st??umienia byc transportu Regularne paj??ka utrzymania drugi rozgrzewania zosta?? osobne Samoczynne	ograniczaj??cego kluczowych zdarzeniu biurowym u??ywana transportowych u??ywana transportowych odpowiednich blachy ??atwopalne obszaru butle obszar czarn?? pust?? Zapewni?? przypomniec	sszs.jpg	2022-02-28	\N
435	f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	2022-02-07	2	Rampa nr 5 na dekoratorni	2022-02-07	10:00:00	23	wiruj??cy dolnych zas??ony oznakowania ??wietlno- acetylenem ??wietlno- acetylenem szk??em urazu zaparkowany r????nicy grozi bram?? wzgledem spryskiwaczy poprawno????	4	posadzki Oberwane dystrybutorze poszed?? Praca surowc??w Praca surowc??w pobierania listwie zabrudzone pomimo medycznych uleg??a potr??cenia kieruj??c?? poza sta??a	magazynu wymogami zbli??ania stopnia nadpalonego wewn??trznych nadpalonego wewn??trznych Obie producentem w??a??ciwie zachowania biurowego Karcherem stabilno??ci ????dowania niezb??dne transportowane	20220204_124528.jpg	2022-02-21	\N
485	dadc2557-a5cf-4ba3-bc35-f288dafa55ec	2022-05-25	12	R10	2022-05-25	09:00:00	16	uszczerbkiem kart?? pracownik??w St??uczenia le????ce szybko le????ce szybko sortowni szk??auraz spos??b lampa poziom??w si??owego ruchu elektrycznym uszkodze??	3	tam indywidualnych Uderzenie przechylenie uniesionych wid??ach uniesionych wid??ach Obecnie podgrzewa?? b??belkow?? tlenie doznac sk??adowany przewr??ci??y uszkodzi?? usterk?? s??upie	premy??le?? nap??du scie??k?? zakup gniazda ostatnia gniazda ostatnia zatrzymania Uruchomi?? lod??wki Pokrzywione dystrybutora podeswtu zakazie zgodn?? k????ek Poprawa	IMG-20220525-WA0008.jpg	2022-06-22	2022-05-27
489	c9f77484-7d39-44d1-aa7c-7c1ac09a24ce	2022-05-30	4	Stara malarnia - wyj??cie na stara malarni??	2022-05-30	09:00:00	6	gazu TKANEK kabel Niesprawny oznakowania naro??nik oznakowania naro??nik spadajacy uchwytu Okaleczenie noga zasygnalizowania prac paletszk??a rozdzielni 85dB	4	przestrzeni zatrzymywania MWG szybie pory on pory on stoj??c niestabilnej kamizelka temperatury wrzucaj??c piecu zastawionej b??l utraty powodu	nadzorem ci??cia Zamyka?? pobli??u bli??ej Czyszczenie bli??ej Czyszczenie Wyci???? O??wietli?? ??cianie ??cianki tym cz??stotliwo??ci usytuowanie kratk?? upominania ostrzegawcz??	Kabel.jpg	2022-06-13	2022-09-22
482	2a8b72ed-93ac-4e64-92a7-4346ffbf4c3a	2022-05-16	12	Cz?????? sortowni zajmowana przez system SLEEVE	2022-05-16	12:00:00	18	opad??w Przygniecienie mie?? ??miertelny urwana odpowiedniego urwana odpowiedniego otworze stopek Zatrucie zdrowia transportow?? noga Potencjalne wyj??ciem Zwr??cenie	3	zagi??te za??adukow?? pol ugaszenia momencie przechodz??cego momencie przechodz??cego ratunkowego wibracyjnych zatopionej przygotowanym ??adowarki Samoczynne frontu ca??kowite wyt??ocznika Zabrudzenie	drewnianymi zawiasie zaworu zamykania streczowane odblaskow?? streczowane odblaskow?? pionowo dwustronna sprawno??ci przechodni??w widoczno???? blachy kodowanie kask plomb ilo????	ZPW2.jpg	2022-06-13	2022-09-22
494	c969e290-7ed2-4eef-9818-7553f1ecee0e	2022-05-31	15	Warsztat CNC	2022-05-31	14:00:00	6	du??e niepotrzebne skutkuj??ce Sytuacja przyczepiony rozlanie przyczepiony rozlanie "prawie" przetarcie po??lizgni??cia Niestabilne wyznaczaj??cych wypadek pojazd??w praktycznie zw??aszcza	2	s??upie zabrudzone formy go powoduj??cy kroki: powoduj??cy kroki: klucz piecyka Niezgodno???? indywidualnej przewr??ci?? dyr korpus naruszona nowych kostrukcj??	rozbryzgiem maseczek ta??mowych ??rodk??w napawania w??zkami napawania w??zkami przestrzeni Wprowadzenie g????wnym dopuszczeniem liniach rozdzielcz?? u??yciem rega??y zmiany pomieszczenia	\N	2022-07-26	2022-05-31
495	c9f77484-7d39-44d1-aa7c-7c1ac09a24ce	2022-06-01	4	Hala "starej" malarni	2022-06-01	12:00:00	20	dotycz??cej gwa??townie przypadkowe wypadek przeciwpo??arowego Przeno??nik przeciwpo??arowego Przeno??nik wchodzdz?? nask??rka obudowa potkni??cia mog??a czytelno??ci zerwana potencjalnie odprysk	4	Powyginana niepoprawnie usuwaj?? posiada wyznaczon?? tymi wyznaczon?? tymi jak: platformie zlewie Wisz??ce podno??nikowym Zamkniecie transportowej materia????w kiedy Przeprowadzanie	Pouczy?? zakaz warsztatu odgrodzonym obchody przyczyn obchody przyczyn linii uruchamianym ustawienia przypomniec ??ciany gro???? naprawy dobranych wielko??ci wspomagania	\N	2022-06-15	2022-09-22
\.


--
-- TOC entry 3495 (class 0 OID 27322)
-- Dependencies: 221
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.roles (role_id, role) FROM stdin;
1	user
2	superuser
3	admin
\.


--
-- TOC entry 3494 (class 0 OID 27307)
-- Dependencies: 219
-- Data for Name: threats; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.threats (threat_id, threat) FROM stdin;
1	Balustrady
2	Budynki
3	Butle z gazami technicznymi
4	Drabiny
5	Inne
6	Instalacja elektryczna
7	Instalacje gazowe
8	Magazynowanie
9	Maszyny
10	Narz??dzia
11	Niezabezpieczone otwory technologiczne
12	Ochrona p.po??.
13	Odzie??
14	Oznakowanie
15	Pierwsza pomoc
16	Podesty
17	Porz??dek
18	Przej??cia-doj??cia
19	St??uczka szklana
20	Substancje chemiczne
21	??rodki ochrony indywidualnej
22	??rodki ochrony zbiorowej
23	Transport
24	Wyposa??enie
25	Ochrona p.po??
26	Magazynowanie, sk??adowanie
0	
\.


--
-- TOC entry 3489 (class 0 OID 27255)
-- Dependencies: 212
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (user_id, email, password, role_id, created_at, updated_at, visited_at, password_updated, is_active, department_id, reset_token) FROM stdin;
8f1c2db0-ea39-4354-9aad-ee391b4f8e25	emilia.kowalczyk@acme.pl	$2a$06$n3gmtR2a5DnB1LUc3sa8h.wi0V7FG/d7dJKIUF9NY7jux4IHIcCk2	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
fa2460ab-25b0-46a9-bccb-8b62b7d9c0e6	agnieszka.sobolewski@acme.pl	$2a$06$WBg5R5cF2Xlm7wECaq94yuSVuO/ncyTNuPS2arpw.iE9h77nuRBAa	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	17	\N
47663ef2-8d7b-42f2-b5b0-50656b44603a	aleksander.terlikowski@acme.pl	$2a$06$Hxl2h2mE7U.UNe/pRMD5ueP2gJ1.VXfPSWZsB/S1MG0AqTsfgLpiy	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	15	\N
ea77d327-1540-4c81-b95c-2bb5dc21a32e	aleksandra.wlodarz@acme.pl	$2a$06$F.nEGyvTXkkc5.sEP.gI..e98nDkG9ST1VhjZSgkFkGyMNdxoIOw6	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
f87198bc-db75-43dc-ac92-732752df2bba	andrzej.kowalczyk@acme.pl	$2a$06$Y6mtGu9GO2JWz3dSEDXNWet2cZMSsFPbBE5EI4fNXa1gKIfINSycG	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
eb411106-d321-41de-ab83-3f347a439da4	aneta.nowakowski@acme.pl	$2a$06$KH.lnsMdfXC8mOZNcJXQIupgWODIz4LLhotdP13UFezYkr3IFMpwG	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	12	\N
dadc2557-a5cf-4ba3-bc35-f288dafa55ec	anna.warwas@acme.pl	$2a$06$HRghlJayXyOO.yOVJWuVFu4er3VZWPHiaBZ7Zp3bM8EQSd9cuw0S.	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
57b84c80-a067-43b7-98a0-ee22a5411c0e	anonim.anonim@acme.pl	$2a$06$5keU.RpvoyQGbo4YTndUkuRkhX0jf/u4pnxLBHPurOXIeJ2FOinq6	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	4	\N
2aac6936-3ec6-4c2f-8823-1e30d3eb7dfc	bartosz.kiraga@acme.pl	$2a$06$S2.PWu1S0QHEwRqnDj1GH.xnZN30SYqdiHWzo8bQvFjiFILf0VuNu	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	7	\N
2b05f424-3dc1-4bea-81b5-6e241f7ed6d8	beata.gryz@acme.pl	$2a$06$2VuVpQcburVALQUugMkyx.bTPKNpo8OwYi8j8gFRf2ij3sqyNgA8K	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	12	\N
497c3ff2-60bf-4a5e-bc73-e2fd6c619637	elwira.jamrozy@acme.pl	$2a$06$BZCUE6kTM4zdoI3DkSmJzus2gujM1oll5cOGDsx7BsYvDa9hdyoDq	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
3025f3ea-78c5-41fb-ba3e-cf7a79a57c0c	ewelina.kryza@acme.pl	$2a$06$u7NknE19u/1Ic31QihMqGeyxxiQYFEG5ptC8hpcss/aiiKLV.wo6G	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	2	\N
4f623cb2-e127-4e20-bc1a-3bef46e89920	fedorowicz.anonim@acme.pl	$2a$06$1BYwyMTd1MM0SIu7beS6g.i1CZQ0DGmYZk/dyPYqtJ8YooDFOzkyy	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
5b869265-65e3-4cdf-a298-a1256d660409	grzegorz.paszkowski@acme.pl	$2a$06$J0lNBcyDGPhFRRJjK5SYv.jafy3CnV788kHJ3N32s7ZT2ytuJPNvC	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	15	\N
4dce33fe-8070-4d04-99e3-a39dbaca1f82	habrajski.siewczyk@acme.pl	$2a$06$IqYWLlQ70m4c5Mipc4o2f.iIyl6HumMBzqvGi1Z38KPIu.JY8I1gu	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
2168af82-27fd-498d-a090-4a63429d8dd1	jacek.mucha@acme.pl	$2a$06$st2kcbEojFTJmMBTz7DTM.L6Q.ZM04A9bAjY4OTgIKKMWgCTTSOFC	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
bbe3f140-d74d-4ee0-980a-c007ad061fa0	jaroslaw.dariusz@acme.pl	$2a$06$EzK4j5gXYCywZpIKXpskvuwgsyW0l1rGGpCUhtgPurRk2dUba2neq	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
83b1ad28-951d-4a56-bbd1-0d4f4358d18a	justyna.anonim@acme.pl	$2a$06$XgEmGuZCyOsVCWFZb0YTmePf2MDgqXbuR2yJaaP1IMsfabU5SJqx.	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	12	\N
0eaf92dd-1e90-4134-bd30-47f84907abcb	karol.zbrowska@acme.pl	$2a$06$CGM7apXBi8NMyLXndilwaewnGDqu0U6qhB7f/wNlq88QtSX49zgiO	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	14	\N
cf85acd7-7898-440e-970d-310e8ad84d4b	karol.janczewski@acme.pl	$2a$06$wZlCGKyHv3I16TEdatHNROK27UABs6tuVwjKM1sTJv7S31SBgD0h6	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
23369f2a-f53f-4064-8ff5-b886102686fd	karol.warchol@acme.pl	$2a$06$WrhrbqSuypwzRSPeI0DbZ.uid36mQqNFY9ytJk6dB/B3xeNRQbtCG	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	8	\N
e72de64c-9ad8-4271-ace5-40619f0a5c0e	karolina.kurek@acme.pl	$2a$06$haP1Hd.B2TGy2BHEuRZJwuY/DcElPEAscf9Kol2LsmcJSVJfkYzea	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
da14c0c1-09a5-42c1-8604-44ff5c8cd747	kasper.hernik@acme.pl	$2a$06$onu8528oIVp.zEtFjVgBL.C3k83JFqfa9mpBVJYGBMqKDrFHy/Dn2	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	12	\N
d069465b-fd5b-4dab-95c6-42c71d68f69b	katarzyna.marek@acme.pl	$2a$06$GCYkJxbNN02hJ0UoqHesjeThZ/hBHO4wWyLC3dxGv8KGxnoa4Yj/O	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	1	\N
568a4817-69a1-4647-a74e-150242618dbe	kierownik.winiarski@acme.pl	$2a$06$M7qfsrkg2q8BjdSrgx1Oi.9cAEYiQAo2rByZJK0bUHRM0N1vNZJTu	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	2	\N
c200ca1b-fa97-4946-94a2-626bd32f497c	krzysztof.tuzimek@acme.pl	$2a$06$5flx6J9eWPAmTwKBuD1Yeu3m.cV3oP8etmbFfM97kN2diPtd5WKHy	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	1	\N
9be931ff-ff6d-4e74-a13e-4f44ade6d3ac	krzysztof.wozniak@acme.pl	$2a$06$lMX2uOREgRQerqa.olsjoOjDboswfWEXnvD5/6e2GIIkmEE9CxC9C	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
a4c64619-8c30-42bc-ac9a-ed5adbf5c608	krzysztof.mazurkiewicz@acme.pl	$2a$06$J8nV2uztqqVVzK0P9PYe4eOnv.EKGCzaGNu5XtORCA5MobGoyS11K	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
800f4ae5-d6e5-45bf-9df7-ac9a8dcab858	lukasz.burek@acme.pl	$2a$06$qvCN7zhjFj.hhbHKQuBLGumJV8Bgrud772W3ZMDT0OQd7Fg1QUk1.	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	2	\N
8aed61ca-62f5-445f-993b-26bbcf0c7419	marcin.polit@acme.pl	$2a$06$EsEoM2rV7LHgISAsX.szmemPU5QCuBx.400sZpHoJBFUVuLZV5vvS	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	2	\N
ffcf648d-83c7-473e-9355-361e6ec7bcee	marcin.szymczyk@acme.pl	$2a$06$cDtIUwjGoNIQrYWkF05v0.w.eU7aWE3HtO3hOwc0E5.KF9oPBiE9m	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
4710a3fd-cd7c-47c6-a678-fa8dd6f3609c	mariusz.pawel@acme.pl	$2a$06$3Ixm8MlUw9bpwvgpQo5KpOzh8.ySedkJo7iA6CXg31O8uKSqN1DuW	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
8d5a9bed-f25b-4209-bae6-564b5affcf3c	mateusz.habrajski@acme.pl	$2a$06$RY6DSwmfAOvcpGETjUbWu.wKl.FjZNHYsIy2ZmQcuSUidSsJQYuzC	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
de217041-d6c7-49a5-8367-6c422fa42283	michal.mlodzikowski@acme.pl	$2a$06$DmkIt6/SHY6WDSTzX659N.9Ap/khoFFTdjWX/r2eWNPsML3UsWtkq	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
0fb6b96b-96a8-4a39-a0e2-459511d1c563	michal.wojcik@acme.pl	$2a$06$Zy1s8yeo4SrXdyrw1zRgiu0TwbZrhZD4IuYrjkNDcE/QtW.NnlDTm	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	1	\N
2a8b72ed-93ac-4e64-92a7-4346ffbf4c3a	mikolaj.tarabasz@acme.pl	$2a$06$CHfCJTH7dimTtECDeQ9Tze2DhzDUu6GXJmaeoUkW6iZl83jPt1VIK	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
31ccccef-7f8d-45e5-9e03-7e6e07671f0a	monika.borowski@acme.pl	$2a$06$JYHzIggqiC5eiiPmzcfqpufxankAn6m40ONYibVhqRCasrcOy0CfG	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
813c24c3-fc3d-4afe-a8c3-cad54bb8b015	monika.fedorowicz@acme.pl	$2a$06$SLxlD3BABOr9QvKDFISaU.Os1TrrzBXNvXpki6tFUDe5UIPHsksA2	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
2e5b7509-39fd-4c7a-8a0e-fe6888c0fb76	norbert.kaleta@acme.pl	$2a$06$O4B1hK2ZxPa0cqKYFtljsOKXUC3bgraRC5q9YtzlhEt1/39ChXM9q	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
c307fdbd-ea37-43c7-b782-7b39fa731f90	olga.bojarski@acme.pl	$2a$06$dVfH6SbP0TjLmLUu05JHd.LOjSbDgENQ639sgzXH/0y3f6NqHjOKK	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	4	\N
a6e35ba8-06de-4a85-8b4f-961bd7ff09d0	pawel.zygmanska@acme.pl	$2a$06$qDFXdTJmdVWrFi3Fqh7c2OUT..G/SsxnPtcEKddk.Ws/bNsZ3Fi5e	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	2	\N
1fa367b9-3777-4c85-889f-2cd8ffd19e75	pawel.zygma??ska@acme.pl	$2a$06$Hl7z9kjPS147kw9iBrQH7uaYwPDuzs6xJhFHnVmPY/J5MqpRZr7Ru	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	13	\N
c9f77484-7d39-44d1-aa7c-7c1ac09a24ce	kwatek.anonim@acme.pl	$2a$06$x1ns/5PB1qR3KspVbt9M4uH4su9r0/470wzA4oOnJlGNZTf6wwyjG	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
05e455a5-257b-4339-a4fd-9166edbae5b5	rafal.anonim@acme.pl	$2a$06$Qb7fGWe9fL7zEkvCXPh/1O7JdurSIxMuiOx3pTwGfVEHUinxsibRe	3	2022-02-02 02:02:02	2022-09-27 20:49:36.654504	2022-07-09 11:34:41	\N	t	5	\N
cd4e0c92-24a5-4921-a22e-41da8c81adf6	pawel.gornik@acme.pl	$2a$06$6Pq5tmR/EZo4S8bZ/NbKoes6wodpihM944pu6puH4Gh75BaznWsc.	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	16	\N
80f879ea-0957-49e9-b618-eaad78f7fa01	pawel.janas@acme.pl	$2a$06$xWlVmCjeb8S8IqgZ/8O/y.B9Iucd4zjsDLigL.sG7U54nuTa8yeBy	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	2	\N
3ee5fc99-b50b-4b71-8f18-7a7af63c07ef	pawel.kroczak@acme.pl	$2a$06$ndaJVE58JLF2FYGuucwl4OQoyWoMW20JeIIz12Y/ukWLpSiAQ1WZm	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	2	\N
f1fdc277-8503-41b8-aaea-e809a84b298b	pawel.kwatek@acme.pl	$2a$06$apZ1tWsRggnYyxhcULp6qudu22qB7AdpeMbVKAfEz/IB1fVbznxz6	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	9	\N
76083af6-99e5-48d8-9df9-88f4f75167b9	pawel.wi??niewski@acme.pl	$2a$06$p0nQs1B6o4tnN.TNtjD7i.kuXl4wJdJ77izrjynUxrvB.VGI0NWo.	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
0b150b78-ca98-42d4-b9cf-dbe7872a667e	pawel.gozdziewska@acme.pl	$2a$06$uGlU2kU5iolFzQYSgr22MudBDvlXPp3NXCy4BhZEc0gBkPTPikRXq	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
07774e50-66a1-4f17-95f6-9be17f7a023f	pawel.marcula@acme.pl	$2a$06$oM3N4Ab/8cxXUg3K0y9KoOLs1SLlL3Q1fjp32LoPRgg4rxEA5WS6C	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	7	\N
4bae726c-d69c-4667-b489-9897c64257e4	piotr.pacholczak@acme.pl	$2a$06$Vh.goZRvCyXk4vQEcdpY6ua6zOrUoyCZQh2U5c/FzMTH5TLBzMzd.	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	13	\N
02ee2179-6408-46c9-a003-eefbd9d60a37	piotr.kupczynska@acme.pl	$2a$06$22AmjM0BAhZO1mlH9IjJjeleCJXa/WrwXlAgKYZ1DiPgtGvk.Q/eq	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	8	\N
3fc5fdcb-e0ad-4e26-aa74-63ec3f99f72f	piotr.michcik@acme.pl	$2a$06$Duh5Aw.PU92GGoRetK3ke.rolHuY2OzAggZC5Qo76MkWRzODG8S46	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	15	\N
d8090826-dfed-4cce-a67e-aff1682e7e31	produkcja.paciorek@acme.pl	$2a$06$SHstufvA4esOoEtfU9Z6m.PZbELdNtreCb5GvqEyDaqMGvHV4G91W	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
6559d7cb-5868-4911-b0e4-baf0c393cdc3	przemyslaw.sypek@acme.pl	$2a$06$4Wfh6d9roYV5SzsiyT5ed.11MvD14P8WJ7aBANzGpH4srHfh9tAMe	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	10	\N
758cdd42-c7db-4aa8-b7cc-dbd66f2c9487	rafal.bernat@acme.pl	$2a$06$TqNGsrDSOnb6nl4NGWqjTOy38HXWd6ovMCYt5s5jQVMZ40EtC4p/a	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	6	\N
5bc3e952-bef5-4be3-bd25-adbe3dae5164	rafal.kiraga@acme.pl	$2a$06$k9RlhGv.FUj0u18ekKLJvuBvhzdeF5AwmUiHk4bMtxCXFxk6zBlZO	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	2	\N
ddda0f68-9f25-4e69-b62f-95b4b5b1ba6a	rafal.niemiec@acme.pl	$2a$06$hcb5W0p0hWfsDcf5.KJBDuONOCcODNXq7DxkPJRxUNowoQI2Mss92	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	10	\N
ee1fd76a-d1ab-4215-834c-020f0b379deb	raff.firlej@acme.pl	$2a$06$USZWNI/wk9mOBRNPeGrL/OUfoajoRwc/B/EL.3YqDXqyiyRiF3nFy	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	1	\N
c969e290-7ed2-4eef-9818-7553f1ecee0e	robert.klusek@acme.pl	$2a$06$fbSs9te4T0VKHQEp0Xk0EeW236fKuRh0DG8lrHNJ0Fci9n/WrSyKi	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	15	\N
f89bd6d2-11f2-44f4-be20-f8bf76ec9c8c	robert.gadzikowska@acme.pl	$2a$06$FXDxoNitXpqlAQAtbHrD3uR3T/eL0esyrx5Ue8HGJ1jvKImS0zeta	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	1	\N
9c64da01-6d57-4778-a1e3-d25f3df07145	sebastian.kaczorek@acme.pl	$2a$06$fIJvzvTm7oxQ//lpMyGwOuK3HtQpmuE5VpuC3ZCDSwNgA9u.WqyJC	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
4e8bfd59-71d3-44b0-af9e-268860f19171	sikora.michal@acme.pl	$2a$06$UaVWOQK75Tb5oBAFXnN6MORaHLJA7zsUEze/f.9y4ov/9uxStQtdq	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	3	\N
95b29d34-ec2f-4ed7-8bc1-1e4fbc4cb0c7	sort.dulewicz@acme.pl	$2a$06$yX3cLcbOHn5/A7a3159gWubNAE.Z0CssUgzaCZmO1Rw8gU03V4s.m	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	12	\N
0c2f62a9-c091-47ab-ac4c-fae64bfcfd70	sylwia.lukasz@acme.pl	$2a$06$kLkkCNXJrhk2mPDgxY.be.VlZZxYQ1RbGp92zh3RumWYxy0OgrncC	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
e89c35ee-ad74-4fa9-a781-14e8b06c9340	tomasz.kucper@acme.pl	$2a$06$ebGqf3EU19IxDQk5QCmlpODWsAk7TtiZsHkNsowqMrEaSLoFLIIqK	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	1	\N
eab85052-fedd-4360-8a8c-d2ff48f0f378	urszula.dziadczyk@acme.pl	$2a$06$O3/c.WZ0psT5of23wC0ndOEAu90B4APw0fKTC8/M2MPsTDkPZJ7eC	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	1	\N
e8f02c5a-1ece-4fa6-ae4e-27b9eda20340	wieslaw.olczyk@acme.pl	$2a$06$UZdGCvrLbJ04QTVhVandXeTndo.BSduYLvNF2Rh31m3qgRZLVTrwe	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	5	\N
6ccdb3ad-4df4-4996-b669-792355142621	wioleta.bilski@acme.pl	$2a$06$pAIb/TdonU/Z0kWZIDCZD.5hTmKvSp6BPSBf.s7oOORnkTs4JrHIq	2	2022-02-02 02:02:02	\N	2022-07-09 11:34:41	\N	t	1	\N
\.


--
-- TOC entry 3518 (class 0 OID 0)
-- Dependencies: 223
-- Name: comments_comment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.comments_comment_id_seq', 189, true);


--
-- TOC entry 3519 (class 0 OID 0)
-- Dependencies: 224
-- Name: consequences_consequence_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.consequences_consequence_id_seq', 5, true);


--
-- TOC entry 3520 (class 0 OID 0)
-- Dependencies: 225
-- Name: departments_department_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.departments_department_id_seq', 198, true);


--
-- TOC entry 3521 (class 0 OID 0)
-- Dependencies: 227
-- Name: functions_function_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.functions_function_id_seq', 203, true);


--
-- TOC entry 3522 (class 0 OID 0)
-- Dependencies: 228
-- Name: managers_manager_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.managers_manager_id_seq', 226, true);


--
-- TOC entry 3523 (class 0 OID 0)
-- Dependencies: 233
-- Name: reports_report_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.reports_report_id_seq', 736, true);


--
-- TOC entry 3524 (class 0 OID 0)
-- Dependencies: 235
-- Name: roles_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.roles_role_id_seq', 4, true);


--
-- TOC entry 3525 (class 0 OID 0)
-- Dependencies: 236
-- Name: threats_threat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.threats_threat_id_seq', 26, true);


--
-- TOC entry 3302 (class 2606 OID 27397)
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (comment_id);


--
-- TOC entry 3319 (class 2606 OID 27399)
-- Name: consequences consequences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consequences
    ADD CONSTRAINT consequences_pkey PRIMARY KEY (consequence_id);


--
-- TOC entry 3311 (class 2606 OID 27401)
-- Name: departments departments_department_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_department_key UNIQUE (department);


--
-- TOC entry 3313 (class 2606 OID 27403)
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (department_id);


--
-- TOC entry 3315 (class 2606 OID 27405)
-- Name: functions functions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.functions
    ADD CONSTRAINT functions_pkey PRIMARY KEY (function_id);


--
-- TOC entry 3317 (class 2606 OID 27407)
-- Name: managers managers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.managers
    ADD CONSTRAINT managers_pkey PRIMARY KEY (manager_id);


--
-- TOC entry 3305 (class 2606 OID 27409)
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (report_id);


--
-- TOC entry 3325 (class 2606 OID 27413)
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (role_id);


--
-- TOC entry 3327 (class 2606 OID 27415)
-- Name: roles roles_role_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_role_key UNIQUE (role);


--
-- TOC entry 3321 (class 2606 OID 27417)
-- Name: threats threats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.threats
    ADD CONSTRAINT threats_pkey PRIMARY KEY (threat_id);


--
-- TOC entry 3323 (class 2606 OID 27419)
-- Name: threats threats_threat_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.threats
    ADD CONSTRAINT threats_threat_key UNIQUE (threat);


--
-- TOC entry 3307 (class 2606 OID 27421)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 3309 (class 2606 OID 27423)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 3303 (class 1259 OID 27424)
-- Name: reports_photo_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX reports_photo_key ON public.reports USING btree (photo);


--
-- TOC entry 3328 (class 2606 OID 27425)
-- Name: comments comments_report_id_reports_report_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_report_id_reports_report_id FOREIGN KEY (report_id) REFERENCES public.reports(report_id) ON DELETE CASCADE;


--
-- TOC entry 3329 (class 2606 OID 27430)
-- Name: comments comments_user_id_users_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_user_id_users_user_id FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- TOC entry 3336 (class 2606 OID 27435)
-- Name: managers managers_function_id_functions_function_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.managers
    ADD CONSTRAINT managers_function_id_functions_function_id FOREIGN KEY (function_id) REFERENCES public.functions(function_id);


--
-- TOC entry 3330 (class 2606 OID 27440)
-- Name: reports reports_consequence_id_consequences_consequence_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_consequence_id_consequences_consequence_id FOREIGN KEY (consequence_id) REFERENCES public.consequences(consequence_id);


--
-- TOC entry 3331 (class 2606 OID 27445)
-- Name: reports reports_department_id_departments_department_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_department_id_departments_department_id FOREIGN KEY (department_id) REFERENCES public.departments(department_id);


--
-- TOC entry 3332 (class 2606 OID 27450)
-- Name: reports reports_threat_id_threats_threat_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_threat_id_threats_threat_id FOREIGN KEY (threat_id) REFERENCES public.threats(threat_id);


--
-- TOC entry 3333 (class 2606 OID 27455)
-- Name: reports reports_user_id_users_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_user_id_users_user_id FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- TOC entry 3334 (class 2606 OID 27460)
-- Name: users users_department_id_departments_department_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_department_id_departments_department_id FOREIGN KEY (department_id) REFERENCES public.departments(department_id);


--
-- TOC entry 3335 (class 2606 OID 27465)
-- Name: users users_role_id_roles_role_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_role_id_roles_role_id FOREIGN KEY (role_id) REFERENCES public.roles(role_id);


-- Completed on 2022-09-28 05:52:28

--
-- PostgreSQL database dump complete
--

