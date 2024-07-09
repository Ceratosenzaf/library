--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2
-- Dumped by pg_dump version 16.2

-- Started on 2024-07-09 10:18:27

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
-- TOC entry 4968 (class 1262 OID 5)
-- Name: postgres; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE postgres WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1252';


ALTER DATABASE postgres OWNER TO postgres;

\connect postgres

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
-- TOC entry 4969 (class 0 OID 0)
-- Dependencies: 4968
-- Name: DATABASE postgres; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON DATABASE postgres IS 'default administrative connection database';


--
-- TOC entry 5 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- TOC entry 4970 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 898 (class 1247 OID 16563)
-- Name: tipo_log; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.tipo_log AS ENUM (
    'prestito',
    'proroga',
    'riconsegna'
);


ALTER TYPE public.tipo_log OWNER TO postgres;

--
-- TOC entry 254 (class 1255 OID 24809)
-- Name: check_and_insert_prestito(character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_and_insert_prestito(cf character varying, isbn character varying, id_sede integer DEFAULT NULL::integer) RETURNS TABLE(id_copia integer, id_nuova_sede integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    id_copia INTEGER;
   	id_nuova_sede INTEGER;
BEGIN
    IF id_sede IS NOT NULL THEN
        SELECT id, sede
        INTO id_copia, id_nuova_sede
        FROM copia
        WHERE libro = isbn
          AND sede = id_sede
          AND disponibile = true
          AND archiviato = false
        LIMIT 1;
        
        IF FOUND then -- copia trovata presso la sede specificata
            INSERT INTO prestito (lettore, copia, inizio)
            VALUES (cf, id_copia, CURRENT_DATE);
            
            RETURN QUERY SELECT id_copia, id_nuova_sede;
        END IF;
    END IF;
    
    -- sede non specificata o copia non trovata presso quella sede
    SELECT id, sede
    INTO id_copia, id_nuova_sede
    FROM copia
    WHERE libro = isbn
      AND disponibile = true
      AND archiviato = false
    LIMIT 1;
    
    IF FOUND THEN
        RAISE NOTICE 'Il libro non è disponibile nella sede specificata. Considerando copie da altre sedi.';
        
        INSERT INTO prestito (lettore, copia, inizio)
        VALUES (cf, id_copia, CURRENT_DATE);
       
        RETURN QUERY SELECT id_copia, id_nuova_sede;
    ELSE
        RAISE EXCEPTION 'Nessuna copia disponibile per il libro richiesto.';
    END IF;
END;
$$;


ALTER FUNCTION public.check_and_insert_prestito(cf character varying, isbn character varying, id_sede integer) OWNER TO postgres;

--
-- TOC entry 237 (class 1255 OID 16639)
-- Name: check_copia_disponibile(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_copia_disponibile() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (SELECT disponibile FROM copia WHERE id = NEW.copia) IS NOT TRUE THEN
		RAISE EXCEPTION 'La copia è già in prestito';
    ELSIF (SELECT archiviato FROM copia WHERE id = NEW.copia) IS TRUE THEN
		RAISE EXCEPTION 'La copia è stata archiviata';
	ELSE
   		RETURN NEW;
    END IF;
END;
$$;


ALTER FUNCTION public.check_copia_disponibile() OWNER TO postgres;

--
-- TOC entry 236 (class 1255 OID 16635)
-- Name: check_lettore_bloccato(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_lettore_bloccato() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (SELECT bloccato FROM lettore WHERE cf = NEW.lettore) IS NOT TRUE THEN
        RETURN NEW;
    ELSE
        RAISE EXCEPTION 'Il lettore è stato bloccato';
    END IF;
END;
$$;


ALTER FUNCTION public.check_lettore_bloccato() OWNER TO postgres;

--
-- TOC entry 235 (class 1255 OID 16633)
-- Name: check_prestiti_attivi(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_prestiti_attivi() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    massimo INTEGER;
    prestiti_attivi INTEGER;
BEGIN
    SELECT CASE
        WHEN premium THEN 5
        ELSE 3
    END INTO massimo
    FROM lettore
    WHERE cf = NEW.lettore;

    SELECT (COUNT(*) + 1) INTO prestiti_attivi
    FROM prestito
    WHERE lettore = NEW.lettore
    AND riconsegna IS NULL;

    IF prestiti_attivi > massimo THEN
        RAISE EXCEPTION 'Il lettore ha raggiunto il numero massimo di prestiti attivi consentiti dalla sua categoria (%).', massimo;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_prestiti_attivi() OWNER TO postgres;

--
-- TOC entry 242 (class 1255 OID 16652)
-- Name: check_proroga_consentita(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_proroga_consentita() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	if (old.scadenza < now()) then
		raise exception 'Il prestito si trova già in ritardo';
	elsif (new.scadenza < old.scadenza ) then
		raise exception 'Non si può anticipare la scadenza di un prestito';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_proroga_consentita() OWNER TO postgres;

--
-- TOC entry 241 (class 1255 OID 16649)
-- Name: increment_ritardi(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.increment_ritardi() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	if (new.riconsegna > new.scadenza) then
		UPDATE lettore
        SET ritardi = ritardi + 1
        WHERE lettore.cf = NEW.lettore;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.increment_ritardi() OWNER TO postgres;

--
-- TOC entry 239 (class 1255 OID 16644)
-- Name: set_copia_disponibile(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_copia_disponibile() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE copia
    SET disponibile = TRUE
    WHERE id = NEW.copia;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_copia_disponibile() OWNER TO postgres;

--
-- TOC entry 238 (class 1255 OID 16641)
-- Name: set_copia_non_disponibile(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_copia_non_disponibile() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE copia
    SET disponibile = FALSE
    WHERE id = NEW.copia;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_copia_non_disponibile() OWNER TO postgres;

--
-- TOC entry 240 (class 1255 OID 16646)
-- Name: set_lettore_bloccato(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_lettore_bloccato() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	if (new.ritardi >= 5) then
		NEW.bloccato = TRUE;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_lettore_bloccato() OWNER TO postgres;

--
-- TOC entry 234 (class 1255 OID 16588)
-- Name: set_scadenza_default(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_scadenza_default() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.scadenza IS NULL THEN
        NEW.scadenza = NEW.inizio + INTERVAL '30 days';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_scadenza_default() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 217 (class 1259 OID 16431)
-- Name: autore; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.autore (
    id integer NOT NULL,
    nome character varying(255),
    cognome character varying(255),
    pseudonimo character varying(255),
    nascita date,
    morte date,
    biografia text
);


ALTER TABLE public.autore OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 16430)
-- Name: autore_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.autore_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.autore_id_seq OWNER TO postgres;

--
-- TOC entry 4971 (class 0 OID 0)
-- Dependencies: 216
-- Name: autore_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.autore_id_seq OWNED BY public.autore.id;


--
-- TOC entry 229 (class 1259 OID 16536)
-- Name: bibliotecario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bibliotecario (
    cf character(16) NOT NULL,
    nome character varying(255) NOT NULL,
    cognome character varying(255) NOT NULL,
    password character varying(255) NOT NULL
);


ALTER TABLE public.bibliotecario OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16471)
-- Name: casa_editrice; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.casa_editrice (
    id integer NOT NULL,
    nome character varying(255) NOT NULL,
    fondazione date,
    cessazione date,
    citta integer
);


ALTER TABLE public.casa_editrice OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16470)
-- Name: casa_editrice_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.casa_editrice_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.casa_editrice_id_seq OWNER TO postgres;

--
-- TOC entry 4972 (class 0 OID 0)
-- Dependencies: 222
-- Name: casa_editrice_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.casa_editrice_id_seq OWNED BY public.casa_editrice.id;


--
-- TOC entry 219 (class 1259 OID 16440)
-- Name: citta; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.citta (
    id integer NOT NULL,
    nome character varying(255) NOT NULL
);


ALTER TABLE public.citta OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 16439)
-- Name: citta_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.citta_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.citta_id_seq OWNER TO postgres;

--
-- TOC entry 4973 (class 0 OID 0)
-- Dependencies: 218
-- Name: citta_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.citta_id_seq OWNED BY public.citta.id;


--
-- TOC entry 227 (class 1259 OID 16511)
-- Name: copia; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.copia (
    id integer NOT NULL,
    libro character(13) NOT NULL,
    sede integer NOT NULL,
    disponibile boolean DEFAULT true NOT NULL,
    archiviato boolean DEFAULT false NOT NULL
);


ALTER TABLE public.copia OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16510)
-- Name: copia_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.copia_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.copia_id_seq OWNER TO postgres;

--
-- TOC entry 4974 (class 0 OID 0)
-- Dependencies: 226
-- Name: copia_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.copia_id_seq OWNED BY public.copia.id;


--
-- TOC entry 228 (class 1259 OID 16527)
-- Name: lettore; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lettore (
    cf character(16) NOT NULL,
    nome character varying(255) NOT NULL,
    cognome character varying(255) NOT NULL,
    premium boolean DEFAULT false NOT NULL,
    ritardi integer DEFAULT 0 NOT NULL,
    bloccato boolean DEFAULT false NOT NULL,
    password character varying(255) NOT NULL
);


ALTER TABLE public.lettore OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16483)
-- Name: libro; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.libro (
    isbn character(13) NOT NULL,
    titolo character varying(255) NOT NULL,
    trama text NOT NULL,
    editore integer NOT NULL,
    pagine smallint NOT NULL,
    pubblicazione date
);


ALTER TABLE public.libro OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 16570)
-- Name: log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.log (
    id integer NOT NULL,
    tipo public.tipo_log NOT NULL,
    prestito integer NOT NULL,
    bibliotecario character(16) NOT NULL,
    "timestamp" date NOT NULL,
    dati_pre json NOT NULL,
    dati_post json NOT NULL
);


ALTER TABLE public.log OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 16569)
-- Name: log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.log_id_seq OWNER TO postgres;

--
-- TOC entry 4975 (class 0 OID 0)
-- Dependencies: 232
-- Name: log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.log_id_seq OWNED BY public.log.id;


--
-- TOC entry 231 (class 1259 OID 16546)
-- Name: prestito; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prestito (
    id integer NOT NULL,
    lettore character(16) NOT NULL,
    copia integer NOT NULL,
    inizio date NOT NULL,
    scadenza date NOT NULL,
    riconsegna date
);


ALTER TABLE public.prestito OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 16545)
-- Name: prestito_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.prestito_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.prestito_id_seq OWNER TO postgres;

--
-- TOC entry 4976 (class 0 OID 0)
-- Dependencies: 230
-- Name: prestito_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.prestito_id_seq OWNED BY public.prestito.id;


--
-- TOC entry 225 (class 1259 OID 16495)
-- Name: scrittura; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.scrittura (
    libro character(13) NOT NULL,
    autore integer NOT NULL
);


ALTER TABLE public.scrittura OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16447)
-- Name: sede; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sede (
    id integer NOT NULL,
    indirizzo character varying(255) NOT NULL,
    citta integer NOT NULL
);


ALTER TABLE public.sede OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16446)
-- Name: sede_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sede_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sede_id_seq OWNER TO postgres;

--
-- TOC entry 4977 (class 0 OID 0)
-- Dependencies: 220
-- Name: sede_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sede_id_seq OWNED BY public.sede.id;


--
-- TOC entry 4748 (class 2604 OID 16434)
-- Name: autore id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.autore ALTER COLUMN id SET DEFAULT nextval('public.autore_id_seq'::regclass);


--
-- TOC entry 4751 (class 2604 OID 16474)
-- Name: casa_editrice id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.casa_editrice ALTER COLUMN id SET DEFAULT nextval('public.casa_editrice_id_seq'::regclass);


--
-- TOC entry 4749 (class 2604 OID 16443)
-- Name: citta id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.citta ALTER COLUMN id SET DEFAULT nextval('public.citta_id_seq'::regclass);


--
-- TOC entry 4752 (class 2604 OID 16514)
-- Name: copia id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.copia ALTER COLUMN id SET DEFAULT nextval('public.copia_id_seq'::regclass);


--
-- TOC entry 4759 (class 2604 OID 16573)
-- Name: log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log ALTER COLUMN id SET DEFAULT nextval('public.log_id_seq'::regclass);


--
-- TOC entry 4758 (class 2604 OID 16549)
-- Name: prestito id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prestito ALTER COLUMN id SET DEFAULT nextval('public.prestito_id_seq'::regclass);


--
-- TOC entry 4750 (class 2604 OID 16450)
-- Name: sede id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sede ALTER COLUMN id SET DEFAULT nextval('public.sede_id_seq'::regclass);


--
-- TOC entry 4946 (class 0 OID 16431)
-- Dependencies: 217
-- Data for Name: autore; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.autore (id, nome, cognome, pseudonimo, nascita, morte, biografia) FROM stdin;
1	Aron Hector	Schmitz	Italo Svevo	1861-12-19	1928-09-13	Scrittore e drammaturgo italiano.
2	Anne	Frank	\N	1929-06-12	1945-02-01	Giovane ebrea tedesca, divenuta un simbolo della Shoah per il suo diario, scritto nel periodo in cui lei e la sua famiglia si nascondevano dai nazisti, e per la sua tragica morte nel campo di concentramento di Bergen-Belsen.
3	Giuseppe	Ungaretti	\N	1888-02-08	1970-06-01	Poeta, scrittore, traduttore e giornalista italiano. È stato uno dei principali poeti della letteratura italiana del XX secolo.
\.


--
-- TOC entry 4958 (class 0 OID 16536)
-- Dependencies: 229
-- Data for Name: bibliotecario; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.bibliotecario (cf, nome, cognome, password) FROM stdin;
crtdvd02m01l157c	davide	cerato	5f4dcc3b5aa765d61d8327deb882cf99
\.


--
-- TOC entry 4952 (class 0 OID 16471)
-- Dependencies: 223
-- Data for Name: casa_editrice; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.casa_editrice (id, nome, fondazione, cessazione, citta) FROM stdin;
1	laFeltrinelli	1954-01-01	\N	\N
2	Giulio Einaudi Editore	1933-11-15	\N	\N
\.


--
-- TOC entry 4948 (class 0 OID 16440)
-- Dependencies: 219
-- Data for Name: citta; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.citta (id, nome) FROM stdin;
1	Milano
2	Vicenza
\.


--
-- TOC entry 4956 (class 0 OID 16511)
-- Dependencies: 227
-- Data for Name: copia; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.copia (id, libro, sede, disponibile, archiviato) FROM stdin;
2	9788883376542	1	t	f
3	9788807900495	2	t	f
1	9788807900495	1	f	f
\.


--
-- TOC entry 4957 (class 0 OID 16527)
-- Dependencies: 228
-- Data for Name: lettore; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.lettore (cf, nome, cognome, premium, ritardi, bloccato, password) FROM stdin;
GSTSGL69D06H501B	carlo	carli	f	0	f	5f4dcc3b5aa765d61d8327deb882cf99
SLDSFO03C57L157J	Sofia	Soldà	t	0	f	5f4dcc3b5aa765d61d8327deb882cf99
FSFSFS80A01F205G	nome	cognome	f	3	t	5f4dcc3b5aa765d61d8327deb882cf99
crtdvd02m01l157c	Davide	Cerato	f	0	f	5f4dcc3b5aa765d61d8327deb882cf99
\.


--
-- TOC entry 4953 (class 0 OID 16483)
-- Dependencies: 224
-- Data for Name: libro; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.libro (isbn, titolo, trama, editore, pagine, pubblicazione) FROM stdin;
978880455083 	Poesie	Vita di un uomo	2	905	\N
9788807900495	La coscienza di Zeno	Il romanzo è di fatto l'analisi della psiche di Zeno, un individuo che si sente malato e inetto ed è continuamente in cerca di una guarigione dal suo malessere attraverso molteplici tentativi, a volte assurdi o controproducenti.	1	432	1923-01-01
9788883376542	Il diario di Anna Frank	Anne nel "Diario" aveva annotato in francese: «Soit gentil et tiens courage!» «Sii gentile e abbi coraggio!» Quasi un invito che sentiamo di dare al lettore (giovane o meno giovane) per la propria vita e per l'approccio alla lettura di queste pagine. Coraggio nell'affrontare qualsiasi tipo di avversità; comprensione delle persone che ci sono accanto; gentilezza come modo di essere. Un animo sensibile non può che innamorarsi di questa ragazzina e sperimentare la magia umana dell'empatia.	1	213	1947-01-01
\.


--
-- TOC entry 4962 (class 0 OID 16570)
-- Dependencies: 233
-- Data for Name: log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.log (id, tipo, prestito, bibliotecario, "timestamp", dati_pre, dati_post) FROM stdin;
\.


--
-- TOC entry 4960 (class 0 OID 16546)
-- Dependencies: 231
-- Data for Name: prestito; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.prestito (id, lettore, copia, inizio, scadenza, riconsegna) FROM stdin;
4	crtdvd02m01l157c	1	2024-07-04	2024-07-30	2024-08-30
9	crtdvd02m01l157c	2	2024-07-04	2024-07-30	2024-07-09
10	crtdvd02m01l157c	1	2024-06-01	2024-07-01	2024-07-09
12	crtdvd02m01l157c	3	2024-07-08	2024-08-07	2024-07-09
13	crtdvd02m01l157c	2	2024-07-09	2024-08-08	2024-07-09
16	crtdvd02m01l157c	2	2024-07-09	2024-08-08	2024-07-09
17	crtdvd02m01l157c	1	2024-07-09	2024-08-08	2024-07-09
18	crtdvd02m01l157c	3	2024-07-09	2024-08-08	2024-07-09
19	crtdvd02m01l157c	1	2024-07-09	2024-08-08	2024-07-09
21	crtdvd02m01l157c	2	2024-07-09	2024-08-08	2024-07-09
20	crtdvd02m01l157c	3	2024-07-09	2024-08-08	2024-07-09
22	crtdvd02m01l157c	1	2024-07-09	2024-08-08	\N
\.


--
-- TOC entry 4954 (class 0 OID 16495)
-- Dependencies: 225
-- Data for Name: scrittura; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scrittura (libro, autore) FROM stdin;
9788807900495	1
9788883376542	2
978880455083 	3
\.


--
-- TOC entry 4950 (class 0 OID 16447)
-- Dependencies: 221
-- Data for Name: sede; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sede (id, indirizzo, citta) FROM stdin;
1	Via Celoria, 18	1
2	Via Ponte, 26b	2
\.


--
-- TOC entry 4978 (class 0 OID 0)
-- Dependencies: 216
-- Name: autore_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.autore_id_seq', 3, true);


--
-- TOC entry 4979 (class 0 OID 0)
-- Dependencies: 222
-- Name: casa_editrice_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.casa_editrice_id_seq', 2, true);


--
-- TOC entry 4980 (class 0 OID 0)
-- Dependencies: 218
-- Name: citta_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.citta_id_seq', 2, true);


--
-- TOC entry 4981 (class 0 OID 0)
-- Dependencies: 226
-- Name: copia_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.copia_id_seq', 3, true);


--
-- TOC entry 4982 (class 0 OID 0)
-- Dependencies: 232
-- Name: log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.log_id_seq', 1, false);


--
-- TOC entry 4983 (class 0 OID 0)
-- Dependencies: 230
-- Name: prestito_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.prestito_id_seq', 22, true);


--
-- TOC entry 4984 (class 0 OID 0)
-- Dependencies: 220
-- Name: sede_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sede_id_seq', 2, true);


--
-- TOC entry 4761 (class 2606 OID 16438)
-- Name: autore autore_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.autore
    ADD CONSTRAINT autore_pkey PRIMARY KEY (id);


--
-- TOC entry 4777 (class 2606 OID 16542)
-- Name: bibliotecario bibliotecario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bibliotecario
    ADD CONSTRAINT bibliotecario_pkey PRIMARY KEY (cf);


--
-- TOC entry 4767 (class 2606 OID 16476)
-- Name: casa_editrice casa_editrice_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.casa_editrice
    ADD CONSTRAINT casa_editrice_pkey PRIMARY KEY (id);


--
-- TOC entry 4763 (class 2606 OID 16445)
-- Name: citta citta_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.citta
    ADD CONSTRAINT citta_pkey PRIMARY KEY (id);


--
-- TOC entry 4773 (class 2606 OID 16516)
-- Name: copia copia_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.copia
    ADD CONSTRAINT copia_pkey PRIMARY KEY (id);


--
-- TOC entry 4775 (class 2606 OID 16533)
-- Name: lettore lettore_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lettore
    ADD CONSTRAINT lettore_pkey PRIMARY KEY (cf);


--
-- TOC entry 4769 (class 2606 OID 16593)
-- Name: libro libro_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.libro
    ADD CONSTRAINT libro_pkey PRIMARY KEY (isbn);


--
-- TOC entry 4781 (class 2606 OID 16577)
-- Name: log log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log
    ADD CONSTRAINT log_pkey PRIMARY KEY (id);


--
-- TOC entry 4779 (class 2606 OID 16551)
-- Name: prestito prestito_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prestito
    ADD CONSTRAINT prestito_pkey PRIMARY KEY (id);


--
-- TOC entry 4771 (class 2606 OID 16499)
-- Name: scrittura scrittura_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scrittura
    ADD CONSTRAINT scrittura_pkey PRIMARY KEY (libro, autore);


--
-- TOC entry 4765 (class 2606 OID 16452)
-- Name: sede sede_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sede
    ADD CONSTRAINT sede_pkey PRIMARY KEY (id);


--
-- TOC entry 4794 (class 2620 OID 16640)
-- Name: prestito check_copia_disponibile_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER check_copia_disponibile_trigger BEFORE INSERT ON public.prestito FOR EACH ROW EXECUTE FUNCTION public.check_copia_disponibile();


--
-- TOC entry 4795 (class 2620 OID 16636)
-- Name: prestito check_lettore_bloccato_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER check_lettore_bloccato_trigger BEFORE INSERT ON public.prestito FOR EACH ROW EXECUTE FUNCTION public.check_lettore_bloccato();


--
-- TOC entry 4796 (class 2620 OID 16634)
-- Name: prestito check_prestiti_attivi_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER check_prestiti_attivi_trigger BEFORE INSERT ON public.prestito FOR EACH ROW EXECUTE FUNCTION public.check_prestiti_attivi();


--
-- TOC entry 4797 (class 2620 OID 16653)
-- Name: prestito check_proroga_consentita_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER check_proroga_consentita_trigger BEFORE UPDATE OF scadenza ON public.prestito FOR EACH ROW EXECUTE FUNCTION public.check_proroga_consentita();


--
-- TOC entry 4798 (class 2620 OID 16651)
-- Name: prestito increment_ritardi_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER increment_ritardi_trigger AFTER UPDATE OF riconsegna ON public.prestito FOR EACH ROW WHEN (((old.riconsegna IS NULL) AND (new.riconsegna IS NOT NULL))) EXECUTE FUNCTION public.increment_ritardi();


--
-- TOC entry 4799 (class 2620 OID 16645)
-- Name: prestito set_copia_disponibile_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_copia_disponibile_trigger AFTER UPDATE OF riconsegna ON public.prestito FOR EACH ROW WHEN ((new.riconsegna IS NOT NULL)) EXECUTE FUNCTION public.set_copia_disponibile();


--
-- TOC entry 4800 (class 2620 OID 16642)
-- Name: prestito set_copia_non_disponibile_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_copia_non_disponibile_trigger AFTER INSERT ON public.prestito FOR EACH ROW EXECUTE FUNCTION public.set_copia_non_disponibile();


--
-- TOC entry 4793 (class 2620 OID 16648)
-- Name: lettore set_lettore_bloccato_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_lettore_bloccato_trigger BEFORE UPDATE OF ritardi ON public.lettore FOR EACH ROW WHEN ((new.bloccato IS NOT TRUE)) EXECUTE FUNCTION public.set_lettore_bloccato();


--
-- TOC entry 4801 (class 2620 OID 16654)
-- Name: prestito set_scadenza_default_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_scadenza_default_trigger BEFORE INSERT ON public.prestito FOR EACH ROW EXECUTE FUNCTION public.set_scadenza_default();


--
-- TOC entry 4783 (class 2606 OID 16477)
-- Name: casa_editrice casa_editrice_sede_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.casa_editrice
    ADD CONSTRAINT casa_editrice_sede_fkey FOREIGN KEY (citta) REFERENCES public.citta(id);


--
-- TOC entry 4787 (class 2606 OID 16599)
-- Name: copia copia_isbn_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.copia
    ADD CONSTRAINT copia_isbn_fkey FOREIGN KEY (libro) REFERENCES public.libro(isbn);


--
-- TOC entry 4788 (class 2606 OID 16522)
-- Name: copia copia_sede_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.copia
    ADD CONSTRAINT copia_sede_fkey FOREIGN KEY (sede) REFERENCES public.sede(id);


--
-- TOC entry 4784 (class 2606 OID 16490)
-- Name: libro libro_editore_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.libro
    ADD CONSTRAINT libro_editore_fkey FOREIGN KEY (editore) REFERENCES public.casa_editrice(id);


--
-- TOC entry 4791 (class 2606 OID 16583)
-- Name: log log_bibliotecario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log
    ADD CONSTRAINT log_bibliotecario_fkey FOREIGN KEY (bibliotecario) REFERENCES public.bibliotecario(cf);


--
-- TOC entry 4792 (class 2606 OID 16578)
-- Name: log log_prestito_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log
    ADD CONSTRAINT log_prestito_fkey FOREIGN KEY (prestito) REFERENCES public.prestito(id);


--
-- TOC entry 4789 (class 2606 OID 16557)
-- Name: prestito prestito_copia_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prestito
    ADD CONSTRAINT prestito_copia_fkey FOREIGN KEY (copia) REFERENCES public.copia(id);


--
-- TOC entry 4790 (class 2606 OID 16552)
-- Name: prestito prestito_lettore_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prestito
    ADD CONSTRAINT prestito_lettore_fkey FOREIGN KEY (lettore) REFERENCES public.lettore(cf);


--
-- TOC entry 4785 (class 2606 OID 16505)
-- Name: scrittura scrittura_autore_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scrittura
    ADD CONSTRAINT scrittura_autore_fkey FOREIGN KEY (autore) REFERENCES public.autore(id);


--
-- TOC entry 4786 (class 2606 OID 16594)
-- Name: scrittura scrittura_libro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scrittura
    ADD CONSTRAINT scrittura_libro_fkey FOREIGN KEY (libro) REFERENCES public.libro(isbn);


--
-- TOC entry 4782 (class 2606 OID 16453)
-- Name: sede sede_citta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sede
    ADD CONSTRAINT sede_citta_fkey FOREIGN KEY (citta) REFERENCES public.citta(id);


-- Completed on 2024-07-09 10:18:28

--
-- PostgreSQL database dump complete
--

