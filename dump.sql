--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2
-- Dumped by pg_dump version 16.2

-- Started on 2024-07-10 16:49:01

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
-- TOC entry 5 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- TOC entry 4987 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 901 (class 1247 OID 16563)
-- Name: tipo_log; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.tipo_log AS ENUM (
    'prestito',
    'proroga',
    'riconsegna'
);


ALTER TYPE public.tipo_log OWNER TO postgres;

--
-- TOC entry 257 (class 1255 OID 24906)
-- Name: check_and_insert_prestito(character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_and_insert_prestito(cf character varying, isbn character varying, sede_predefinita integer DEFAULT NULL::integer) RETURNS TABLE(id_prestito integer, id_copia integer, id_sede integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    id_prestito INTEGER;
    id_copia INTEGER;
    id_sede INTEGER;
BEGIN
    IF sede_predefinita IS NOT NULL THEN
        SELECT id, sede
        INTO id_copia, id_sede
        FROM copia
        WHERE libro = isbn
          AND sede = sede_predefinita
          AND disponibile = true
          AND archiviato = false
        LIMIT 1;
        
        IF FOUND THEN -- copia trovata presso la sede specificata
            INSERT INTO prestito (lettore, copia, inizio)
            VALUES (cf, id_copia, CURRENT_DATE)
            RETURNING id INTO id_prestito;
            
            RETURN QUERY SELECT id_prestito, id_copia, id_sede;
        END IF;
    END IF;
    
    IF NOT FOUND THEN -- sede non specificata o copia non trovata presso quella sede
	   	SELECT id, sede
	    INTO id_copia, id_sede
	    FROM copia
	    WHERE libro = isbn
	      AND disponibile = true
	      AND archiviato = false
	    LIMIT 1;
	    
	    IF FOUND then
	    	IF sede_predefinita IS NOT NULL THEN
	        	RAISE NOTICE 'Il libro non è disponibile nella sede specificata. Considerando copie da altre sedi.';
	    	END IF;
	       
	        INSERT INTO prestito (lettore, copia, inizio)
	        VALUES (cf, id_copia, CURRENT_DATE)
	        RETURNING id INTO id_prestito;
	       
	        RETURN QUERY SELECT id_prestito, id_copia, id_sede;
	    ELSE
	        RAISE EXCEPTION 'Nessuna copia disponibile per il libro richiesto.';
	    END IF;
    END IF;
END;
$$;


ALTER FUNCTION public.check_and_insert_prestito(cf character varying, isbn character varying, sede_predefinita integer) OWNER TO postgres;

--
-- TOC entry 239 (class 1255 OID 16639)
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
-- TOC entry 244 (class 1255 OID 24833)
-- Name: check_date_prestito(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_date_prestito() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (NEW.inizio > NOW() or NEW.riconsegna > NOW()) THEN
        RAISE EXCEPTION 'Il prestito non può trovarsi nel futuro';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_date_prestito() OWNER TO postgres;

--
-- TOC entry 238 (class 1255 OID 16633)
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
	if (old.scadenza < now() and old.riconsegna is null) then
		raise exception 'Il prestito si trova già in ritardo';
	elsif (new.scadenza < old.scadenza ) then
		raise exception 'Non si può anticipare la scadenza di un prestito';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_proroga_consentita() OWNER TO postgres;

--
-- TOC entry 245 (class 1255 OID 24907)
-- Name: check_ritardi(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_ritardi() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (SELECT ritardi FROM lettore WHERE cf = NEW.lettore) >= 5 THEN
        RAISE EXCEPTION 'Il lettore è stato bloccato perché ha superato il numero massimo di ritardi';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_ritardi() OWNER TO postgres;

--
-- TOC entry 243 (class 1255 OID 16649)
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
-- TOC entry 241 (class 1255 OID 16644)
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
-- TOC entry 240 (class 1255 OID 16641)
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
-- TOC entry 237 (class 1255 OID 16588)
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
    biografia text,
    CONSTRAINT chk_date CHECK (((morte IS NULL) OR (nascita IS NULL) OR (nascita <= morte)))
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
-- TOC entry 4988 (class 0 OID 0)
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
    citta integer,
    CONSTRAINT chk_date CHECK (((cessazione IS NULL) OR (fondazione IS NULL) OR (fondazione <= cessazione)))
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
-- TOC entry 4989 (class 0 OID 0)
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
-- TOC entry 4990 (class 0 OID 0)
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
-- TOC entry 4991 (class 0 OID 0)
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
    pubblicazione date,
    CONSTRAINT chk_date CHECK (((pubblicazione IS NULL) OR (pubblicazione <= now()))),
    CONSTRAINT chk_pagine CHECK ((pagine >= 0))
);


ALTER TABLE public.libro OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 24879)
-- Name: log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.log (
    id integer NOT NULL,
    tipo public.tipo_log NOT NULL,
    prestito integer NOT NULL,
    bibliotecario character varying(16),
    dati_pre json NOT NULL,
    dati_post json NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_bibliotecario CHECK (((tipo = 'prestito'::public.tipo_log) OR (bibliotecario IS NOT NULL)))
);


ALTER TABLE public.log OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 24867)
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
-- TOC entry 235 (class 1259 OID 24878)
-- Name: log_id_seq1; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.log_id_seq1
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.log_id_seq1 OWNER TO postgres;

--
-- TOC entry 4992 (class 0 OID 0)
-- Dependencies: 235
-- Name: log_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.log_id_seq1 OWNED BY public.log.id;


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
    riconsegna date,
    CONSTRAINT chk_riconsegna_dopo_inizio CHECK ((riconsegna >= inizio)),
    CONSTRAINT chk_scadenza_dopo_inizio CHECK ((scadenza >= inizio))
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
-- TOC entry 4993 (class 0 OID 0)
-- Dependencies: 230
-- Name: prestito_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.prestito_id_seq OWNED BY public.prestito.id;


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
-- TOC entry 233 (class 1259 OID 24818)
-- Name: ritardi_sede; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.ritardi_sede AS
 SELECT s.id,
    p.copia,
    c.libro,
    p.lettore,
    (CURRENT_DATE - p.scadenza) AS giorni_ritardo
   FROM ((public.sede s
     JOIN public.copia c ON ((s.id = c.sede)))
     JOIN public.prestito p ON ((c.id = p.copia)))
  WHERE ((p.riconsegna IS NULL) AND (p.scadenza < now()))
  ORDER BY s.id, (CURRENT_DATE - p.scadenza) DESC;


ALTER VIEW public.ritardi_sede OWNER TO postgres;

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
-- TOC entry 4994 (class 0 OID 0)
-- Dependencies: 220
-- Name: sede_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sede_id_seq OWNED BY public.sede.id;


--
-- TOC entry 232 (class 1259 OID 24814)
-- Name: statistiche_sede; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.statistiche_sede AS
 SELECT s.id,
    count(c.id) AS copie,
    count(DISTINCT c.libro) AS libri,
    count(c.id) FILTER (WHERE (c.disponibile IS FALSE)) AS prestiti_attivi
   FROM (public.sede s
     LEFT JOIN public.copia c ON ((s.id = c.sede)))
  GROUP BY s.id;


ALTER VIEW public.statistiche_sede OWNER TO postgres;

--
-- TOC entry 4757 (class 2604 OID 16434)
-- Name: autore id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.autore ALTER COLUMN id SET DEFAULT nextval('public.autore_id_seq'::regclass);


--
-- TOC entry 4760 (class 2604 OID 16474)
-- Name: casa_editrice id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.casa_editrice ALTER COLUMN id SET DEFAULT nextval('public.casa_editrice_id_seq'::regclass);


--
-- TOC entry 4758 (class 2604 OID 16443)
-- Name: citta id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.citta ALTER COLUMN id SET DEFAULT nextval('public.citta_id_seq'::regclass);


--
-- TOC entry 4761 (class 2604 OID 16514)
-- Name: copia id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.copia ALTER COLUMN id SET DEFAULT nextval('public.copia_id_seq'::regclass);


--
-- TOC entry 4767 (class 2604 OID 24882)
-- Name: log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log ALTER COLUMN id SET DEFAULT nextval('public.log_id_seq1'::regclass);


--
-- TOC entry 4766 (class 2604 OID 16549)
-- Name: prestito id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prestito ALTER COLUMN id SET DEFAULT nextval('public.prestito_id_seq'::regclass);


--
-- TOC entry 4759 (class 2604 OID 16450)
-- Name: sede id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sede ALTER COLUMN id SET DEFAULT nextval('public.sede_id_seq'::regclass);


--
-- TOC entry 4964 (class 0 OID 16431)
-- Dependencies: 217
-- Data for Name: autore; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.autore (id, nome, cognome, pseudonimo, nascita, morte, biografia) FROM stdin;
1	F. Scott	Fitzgerald	\N	1896-09-24	1940-12-21	F. Scott Fitzgerald è stato un romanziere e scrittore di racconti americano, noto per i suoi romanzi ambientati nell'età del jazz.
2	Emily	Brontë	\N	1818-07-30	1848-12-19	Emily Brontë è stata una scrittrice e poetessa inglese, autrice del famoso romanzo "Cime tempestose".
3	Harper	Lee	\N	1926-04-28	2016-02-19	Harper Lee è stata una scrittrice americana, celebre per il suo romanzo "Il buio oltre la siepe", vincitore del Premio Pulitzer.
4	George	Orwell	\N	1903-06-25	1950-01-21	George Orwell è stato uno scrittore e giornalista inglese, noto per i suoi romanzi distopici "1984" e "La fattoria degli animali".
5	J.D.	Salinger	\N	1919-01-01	2010-01-27	J.D. Salinger è stato uno scrittore americano, famoso per il suo romanzo "Il giovane Holden".
6	Dan	Brown	\N	1964-06-22	\N	Dan Brown è un autore di romanzi thriller americani, noto per i suoi bestseller tra cui "Il codice da Vinci" e "Angeli e demoni".
7	Ernest	Hemingway	\N	1899-07-21	1961-07-02	Ernest Hemingway è stato uno scrittore e giornalista americano, vincitore del Premio Nobel per la letteratura nel 1954.
8	Jane	Austen	\N	1775-12-16	1817-07-18	Jane Austen è stata una scrittrice inglese, nota per i suoi romanzi tra cui "Orgoglio e pregiudizio" e "Ragione e sentimento".
9	J.R.R.	Tolkien	\N	1892-01-03	1973-09-02	J.R.R. Tolkien è stato uno scrittore, poeta, filologo e accademico inglese, noto per "Il Signore degli Anelli" e "Lo Hobbit".
10	Franz	Kafka	\N	1883-07-03	1924-06-03	Franz Kafka è stato uno scrittore boemo di lingua tedesca, considerato uno dei maggiori autori del XX secolo.
11	Mikhail	Bulgakov	\N	1891-05-15	1940-03-10	Mikhail Bulgakov è stato uno scrittore e drammaturgo russo, noto per il suo romanzo "Il maestro e Margherita".
12	Fëdor	Dostoevskij	\N	1821-11-11	1881-02-09	Fëdor Dostoevskij è stato uno scrittore e filosofo russo, autore di romanzi come "Delitto e castigo" e "I fratelli Karamazov".
13	Marie-Henri	Bayle	Stendhal	1783-01-23	1842-03-23	Stendhal è stato uno scrittore francese, noto per i suoi romanzi "Il rosso e il nero" e "La Certosa di Parma".
14	Umberto	Eco	\N	1932-01-05	2016-02-19	Umberto Eco è stato uno scrittore, filosofo e semiologo italiano, noto per il romanzo "Il nome della rosa".
15	Cormac	McCarthy	\N	1933-07-20	\N	Cormac McCarthy è uno scrittore americano, autore di romanzi come "La strada" e "Non è un paese per vecchi".
16	Paolo	Giordano	\N	1982-12-19	\N	Paolo Giordano è un fisico e scrittore italiano, noto per il suo romanzo "La solitudine dei numeri primi".
17	Antonio	Tabucchi	\N	1943-09-23	2012-03-25	Antonio Tabucchi è stato uno scrittore e accademico italiano, noto per il romanzo "Sostiene Pereira".
18	Elena	Ferrante	\N	\N	\N	Elena Ferrante è lo pseudonimo di una scrittrice italiana, autrice della serie "L'amica geniale".
19	Niccolò	Ammaniti	\N	1966-09-25	\N	Niccolò Ammaniti è uno scrittore italiano, noto per il romanzo "Io non ho paura".
20	Paolo	Cognetti	\N	1978-01-27	\N	Paolo Cognetti è uno scrittore italiano, noto per il romanzo "Le otto montagne".
21	Terence David John	Pratchett	Terry Pratchett	1948-04-28	2015-03-12	Terry Pratchett è stato uno scrittore britannico, noto per la sua serie di libri "Discworld". Le sue opere sono celebri per il loro umorismo, il mondo immaginario ricco di dettagli e la critica sociale.\n
22	Neil	Gaiman	\N	1960-11-10	\N	Neil Gaiman è uno scrittore britannico di romanzi, fumetti e racconti brevi, noto per le sue opere fantasy e horror, tra cui "American Gods", "Coraline" e "The Sandman".
23	Stephen Edwin	King	\N	1947-09-21	\N	Stephen King è uno degli autori più noti di thriller e horror.
26	Peter	Straub	\N	1943-03-02	\N	Peter Straub è uno scrittore americano di horror e suspense, noto per i suoi romanzi come "Ghost Story" e "Shadowland".
27	Aron Hector	Schmitz	Italo Svevo	1861-12-19	1928-09-13	Impiegato di banca, attività a cui fu costretto per motivi economici, iniziò a cimentarsi con la scrittura in articoli e racconti. Nel 1892 scrisse il suo primo romanzo, Una vita, a cui seguirono Senilità (1898) e la sua opera più celebre La coscienza di Zeno nel 1923 che lo pose all'attenzione della critica. Formatosi sugli scrittori realisti francesi, sulla filosofia di Schopenhauer e gli scritti di Sigmund Freud, Svevo introdusse nella letteratura italiana una visione analitica del reale, sottoposta a una continua interiorizzazione, sempre attenta ai moti della coscienza. L'indagine sull'inconscio, spesso mutuata dall'ironia e dal grottesco, diventa protagonista delle sue opere che presentano sempre un eroe negativo, preso da una "malattia" che altro non è che la condizione di crisi esistenziale di una società priva di valori.
\.


--
-- TOC entry 4976 (class 0 OID 16536)
-- Dependencies: 229
-- Data for Name: bibliotecario; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.bibliotecario (cf, nome, cognome, password) FROM stdin;
CRTDVD02M01L157C	davide	cerato	5f4dcc3b5aa765d61d8327deb882cf99
\.


--
-- TOC entry 4970 (class 0 OID 16471)
-- Dependencies: 223
-- Data for Name: casa_editrice; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.casa_editrice (id, nome, fondazione, cessazione, citta) FROM stdin;
3	Penguin Random House	1925-07-01	\N	2
4	HarperCollins	1989-01-01	\N	2
5	Simon & Schuster	1924-01-02	\N	2
6	Macmillan Publishers	1843-01-01	\N	3
7	Hachette Livre	1826-01-01	\N	5
9	Pearson Education	1844-01-01	\N	3
10	Bloomsbury Publishing	1986-02-26	\N	3
11	Springer Science+Business Media	1842-05-10	\N	4
12	Mondadori	1907-11-08	\N	1
13	Feltrinelli	1954-01-01	\N	1
14	Einaudi	1933-11-15	\N	6
15	Adelphi	1962-01-01	\N	1
8	Scholastic Corporation	1920-10-22	1999-09-09	2
\.


--
-- TOC entry 4966 (class 0 OID 16440)
-- Dependencies: 219
-- Data for Name: citta; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.citta (id, nome) FROM stdin;
1	Milano
3	Londra
4	Berlino
5	Parigi
6	Torino
2	New York
7	Vicenza
\.


--
-- TOC entry 4974 (class 0 OID 16511)
-- Dependencies: 227
-- Data for Name: copia; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.copia (id, libro, sede, disponibile, archiviato) FROM stdin;
32	9780452284234	3	t	t
55	9780452284258	1	t	f
86	978880790049 	7	t	f
90	9788842087105	3	t	f
92	9788838934534	2	t	f
94	9780743273541	3	t	f
18	9780316769488	3	t	f
19	9780316769488	4	t	f
22	9780393040029	2	t	f
23	9780393040029	4	t	f
25	9780143039433	2	t	f
26	9780143039433	3	t	f
27	9780143039433	4	t	f
28	9780679451146	1	t	f
29	9780679451146	2	t	f
31	9780452284234	2	t	f
21	9780743273565	3	t	f
33	9780452284234	4	t	f
88	9780452284258	1	t	f
16	9780316769488	1	t	f
15	9780312428421	2	t	f
24	9780143039433	1	t	t
20	9780743273565	1	t	t
34	9788804625376	1	t	f
30	9780679451146	3	f	f
57	9780140186390	1	f	f
7	9780143128540	3	t	f
17	9780316769488	2	t	f
72	9780062315006	2	t	f
53	9780679728019	3	t	f
54	9780679728019	4	t	f
56	9780452284258	3	t	f
58	9780140186390	2	t	f
59	9780140186390	3	t	f
60	9780743273558	1	t	f
61	9780743273558	2	t	f
62	9780743273558	3	t	f
63	9780743273558	4	t	f
66	9780553213117	1	t	f
67	9780553213117	4	t	f
73	9780062315006	4	t	f
74	9780451529250	2	t	f
75	9780451529250	3	t	f
76	9780451529250	4	t	f
77	9780743273541	1	t	f
78	9780743273541	3	t	f
79	9780062316096	1	t	f
80	9780062316096	2	t	f
81	9780060853983	1	t	f
82	9780060853983	3	t	f
83	9780452284774	2	t	f
84	9780452284774	3	t	f
85	9780452284774	4	t	f
51	9780451529236	2	t	f
52	9780679728019	2	t	f
50	9780451529236	1	t	f
71	9780062315006	1	t	f
70	9780141187761	3	t	t
65	9780060834820	3	t	t
35	9788804625376	2	t	f
69	9780141187761	2	t	f
68	9780141187761	1	t	f
64	9780060834820	2	t	f
8	9780060935467	1	t	f
91	9780060935467	4	t	f
13	9781501126372	4	f	f
14	9780312428421	1	f	f
11	9781501126372	2	f	f
87	978880790049 	7	t	f
89	9788804625376	3	t	f
93	9788842087105	2	t	f
5	9780143128540	1	t	f
6	9780143128540	2	t	f
9	9780060935467	2	t	f
10	9780060935467	4	t	f
12	9781501126372	3	t	f
36	9788807030447	3	t	f
37	9788807030447	4	t	f
38	9788867870197	1	t	f
40	9788867870197	3	t	f
41	9788867870197	4	t	f
42	9788838934534	1	t	f
43	9788838934534	2	t	f
44	9788838934534	4	t	f
45	9788842087105	2	t	f
46	9788842087105	3	t	f
47	9780345391803	1	t	f
48	9780345391803	2	t	f
49	9780345391803	3	t	f
39	9788867870197	2	t	t
\.


--
-- TOC entry 4975 (class 0 OID 16527)
-- Dependencies: 228
-- Data for Name: lettore; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.lettore (cf, nome, cognome, premium, ritardi, password) FROM stdin;
LNMRSB88R90H501X	Ilaria	Lombardi	t	0	2c103f2c4ed1e59c0b4e2e01821770fa
RSSMRA85M01H501Z	Mario	Rossi	f	1	2c103f2c4ed1e59c0b4e2e01821770fa
RSSLAR80A01H501Y	Anna	Rossi	f	1	402fd6af80d80e346b96c89d37aae805
PRCSMS85C22H501F	Sara	Pereira	f	1	47b7bfb65fa83ac9a71dcb0f6296bb6e
FNNLCR76E30H501G	Francesca	Neri	f	1	6bac796099b08e175ac2b823b83f88e5
GVPLMN82F35H501J	Paolo	Giuliani	f	1	97274d5652cb9522ec0ed285b845b55f
FRRBNL77J50H501P	Simona	Ferrari	f	1	12bce374e7be15142e8172f668da00d8
CTLMNR90L60H501R	Giulia	Marini	t	1	a753066d5fc7517e957d3f35f0fec821
BPLTRM87N70H501T	Elena	Bortolotti	f	1	b6f057c9964a5edc69a3e2bf9ac5f1e5
CDMNGS71D28H501M	Giovanni	De Luca	t	1	dc647eb65e6711e155375218212b3964
GNRMLA80M65H501S	Marco	Gentili	f	1	0cef1fb10f60529028a71f58e54ed07b
BTNSMR68H45H501K	Roberta	Bernardi	f	1	9ec847db68e6c23d82a26f6793deac93
FNRBMD79S95H501Y	Gianluca	Ferrari	f	0	494b0e50f2fff6c97b3dd35286646a00
CRTDVD02M01L157C	Davide	Cerato	t	0	5f4dcc3b5aa765d61d8327deb882cf99
RLNMLC89G40H501H	Alessandro	Romano	t	5	2637a5c30af69a7bad877fdb65fbd78b
BNCDNL70B15H501T	Luca	Bianchi	f	0	0d491297649a8a4f7768f3e5784c52f1
TSDRSM74K55H501Q	Stefano	Russo	f	0	eb9a9a9720c4971d359fe2ec40a62fd4
MRTGNS76O75H501U	Francesco	Marini	f	0	59ffd3a837bb86cf28d060165e6be033
PNTMRR84P80H501V	Laura	Patti	f	0	ffb901326772e7284aeb4c1f220ce120
ZPLFRR73Q85H501W	Valerio	Zanetti	f	0	ab14bd419ee3dabf862ae92946c8b01a
PMTCRM70T01H501Z	Diana	Pace	f	0	76ad47269a28c26ccd94b2a85a0aa9c5
VRCDLR69U15H501A	Giovanni	Ricci	f	0	26b5c3f86027614d7c3bbec4238a97f8
FSFSFS80A01F205G	Davide	Cerato	t	0	5f4dcc3b5aa765d61d8327deb882cf99
\.


--
-- TOC entry 4971 (class 0 OID 16483)
-- Dependencies: 224
-- Data for Name: libro; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.libro (isbn, titolo, trama, editore, pagine, pubblicazione) FROM stdin;
9780060935467	Cime tempestose	La tragica storia d'amore tra Heathcliff e Catherine Earnshaw, ambientata nella brughiera inglese, esplora la passione, la vendetta e la distruzione.	4	416	1847-12-01
9781501126372	Il buio oltre la siepe	Un racconto di razzismo e ingiustizia nel profondo sud degli Stati Uniti, visto attraverso gli occhi della giovane Scout Finch.	5	336	1960-07-11
9780312428421	1984	Un romanzo distopico che esplora una società totalitaria governata dal Grande Fratello, dove la sorveglianza e la manipolazione sono all'ordine del giorno.	6	328	1949-06-08
9780316769488	Il giovane Holden	La storia di Holden Caulfield, un adolescente ribelle che si trova a New York City, alle prese con la depressione e la ricerca di un significato nella vita.	7	277	1951-07-16
9780393040029	Il vecchio e il mare	La lotta epica tra un vecchio pescatore cubano e un gigantesco marlin, che rappresenta una battaglia tra l'uomo e la natura.	8	127	1952-09-01
9780143039433	Orgoglio e pregiudizio	La storia di Elizabeth Bennet e Mr. Darcy, una satira sociale dell'Inghilterra del XIX secolo e una romantica storia d'amore.	3	279	1813-01-28
9780679451146	Il codice da Vinci	Robert Langdon e Sophie Neveu indagano sull'omicidio del curatore del Louvre e scoprono segreti nascosti tra i capolavori dell'arte.	13	489	2003-03-18
9780452284234	Moby Dick	La caccia ossessiva del capitano Ahab alla balena bianca Moby Dick, un racconto di avventura e riflessione sulla natura umana.	3	720	1851-11-14
9788804625376	Io non ho paura	Il racconto di un ragazzo che scopre un terribile segreto in un piccolo villaggio del sud Italia durante un'estate caldissima.	12	220	2001-01-01
9788807030447	L'amica geniale	La storia di due amiche, Elena e Lila, che crescono in un quartiere povero di Napoli, esplorando le complessità della loro amicizia e delle loro vite.	14	400	2011-10-19
9788867870197	La solitudine dei numeri primi	Due bambini, entrambi segnati da traumi, crescono e le loro vite si intrecciano in modi inaspettati, esplorando la solitudine e la connessione umana.	12	271	2008-01-01
9788838934534	Sostiene Pereira	Nella Lisbona del 1938, un giornalista apolitico si trova coinvolto in eventi che cambiano radicalmente la sua vita e il suo modo di pensare.	13	208	1994-01-01
9788842087105	Le otto montagne	La storia dell'amicizia tra Pietro e Bruno, due ragazzi che si incontrano tra le montagne delle Alpi e condividono esperienze di vita.	14	200	2016-11-08
9780345391803	Il Signore degli Anelli	L'epica avventura di Frodo Baggins e dei suoi amici nella Terra di Mezzo per distruggere l'Unico Anello e sconfiggere Sauron.	9	1216	1954-07-29
9780451529236	Il processo	Il racconto dell'angosciosa esperienza di Josef K., un uomo innocente arrestato e processato da un sistema giudiziario opprimente e incomprensibile.	3	256	1925-01-01
9780679728019	Il maestro e Margherita	Un romanzo che intreccia una storia d'amore con elementi fantastici e satirici, ambientato nella Mosca degli anni '30.	10	384	1967-01-01
9780452284258	Delitto e castigo	La storia di Raskolnikov, un giovane studente che commette un omicidio e deve confrontarsi con le conseguenze morali e psicologiche delle sue azioni.	3	576	1866-01-01
9780140186390	Il rosso e il nero	La storia di Julien Sorel, un giovane ambizioso nella Francia del XIX secolo, che cerca di scalare la società con la sua astuzia e il suo fascino.	3	576	1830-01-01
9780743273558	Inferno	Robert Langdon si sveglia in un ospedale di Firenze senza memoria e deve decifrare un enigma legato all'Inferno di Dante.	5	480	2013-05-14
9780060834820	Fahrenheit 451	In un futuro distopico, i libri sono vietati e i pompieri bruciano qualsiasi libro trovino. La storia di Guy Montag, un pompiere che inizia a dubitare del suo lavoro.	4	249	1953-10-19
9780553213117	Il nome della rosa	In un monastero medievale, il frate Guglielmo da Baskerville indaga su una serie di omicidi misteriosi, svelando segreti nascosti tra i manoscritti antichi.	11	512	1980-01-01
9780141187761	Brave New World	Un romanzo distopico che immagina un futuro in cui la società è altamente controllata attraverso la manipolazione genetica e il condizionamento psicologico.	3	268	1932-01-01
9780062315006	Il signore delle mosche	Un gruppo di ragazzi rimane bloccato su un'isola deserta e la loro organizzazione iniziale degenera in caos e violenza.	4	224	1954-09-17
9780451529250	La metamorfosi	La storia di Gregor Samsa, che si sveglia una mattina trasformato in un gigantesco insetto e deve affrontare le reazioni della sua famiglia e della società.	3	201	1915-01-01
9780143128540	Il grande Gatsby	La storia dell'ambizioso Jay Gatsby e del suo amore per la bella Daisy Buchanan, narrata da Nick Carraway, in un ritratto vivido e avvincente degli anni ruggenti.	3	180	1925-04-10
9780743273565	Angeli e demoni	Il professore di simbologia Robert Langdon viene chiamato a Roma per risolvere un mistero che coinvolge un antico ordine segreto e la minaccia alla Chiesa cattolica.	5	572	2000-05-01
9780743273541	Il simbolo perduto	Robert Langdon viene chiamato a Washington D.C. per decifrare un misterioso simbolo massonico e prevenire una catastrofe imminente.	5	509	2009-09-15
9780062316096	La strada	In un mondo postapocalittico, un padre e il suo giovane figlio viaggiano attraverso un paesaggio devastato, cercando di sopravvivere.	4	287	2006-09-26
9780452284774	Il Talismano	Un romanzo fantasy che segue il viaggio di un ragazzo di 12 anni in un regno parallelo per trovare un talismano che salverà sua madre e il suo mondo.	15	576	1984-01-01
9780060853983	Good Omens	Un romanzo comico che racconta la storia di un angelo e di un demone che collaborano per prevenire l'Armageddon, che si avvicina inaspettatamente.	13	288	1990-01-01
978880790049 	La coscienza di Zeno	Nella prefazione del libro il sedicente psicoanalista "Dottor S." (si pensa che fosse ispirato a Sigmund Freud o più verosimilmente a Edoardo Weiss) dichiara di voler pubblicare "per vendetta" alcune memorie, redatte in forma autobiografica da un suo ex paziente, Zeno Cosini, che si è sottratto alla cura che gli era stata prescritta. Gli appunti dell'ex paziente costituiscono il contenuto del libro.\r\nIl romanzo è di fatto l'analisi della psiche di Zeno, un individuo che si sente malato e inetto ed è continuamente in cerca di una guarigione dal suo malessere attraverso molteplici tentativi, a volte assurdi o controproducenti.	13	432	1923-01-01
\.


--
-- TOC entry 4981 (class 0 OID 24879)
-- Dependencies: 236
-- Data for Name: log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.log (id, tipo, prestito, bibliotecario, dati_pre, dati_post, created_at) FROM stdin;
1	proroga	148	CRTDVD02M01L157C	{"id":"148","lettore":"CRTDVD02M01L157C","copia":"68","inizio":"2024-07-09","scadenza":"2024-08-09","riconsegna":null}	{"id":"148","lettore":"CRTDVD02M01L157C","copia":"68","inizio":"2024-07-09","scadenza":"2024-08-10","riconsegna":null}	2024-07-09 18:59:32.818702
2	proroga	148	CRTDVD02M01L157C	{"id":"148","lettore":"CRTDVD02M01L157C","copia":"68","inizio":"2024-07-09","scadenza":"2024-08-10","riconsegna":null}	{"id":"148","lettore":"CRTDVD02M01L157C","copia":"68","inizio":"2024-07-09","scadenza":"2024-08-10","riconsegna":null}	2024-07-09 19:02:13.452055
3	proroga	148	CRTDVD02M01L157C	{"id":"148","lettore":"CRTDVD02M01L157C","copia":"68","inizio":"2024-07-09","scadenza":"2024-08-10","riconsegna":null}	{"id":"148","lettore":"CRTDVD02M01L157C","copia":"68","inizio":"2024-07-09","scadenza":"2024-08-11","riconsegna":null}	2024-07-09 19:02:19.497134
4	proroga	148	CRTDVD02M01L157C	{"id":"148","lettore":"CRTDVD02M01L157C","copia":"68","inizio":"2024-07-09","scadenza":"2024-08-11","riconsegna":null}	{"id":"148","lettore":"CRTDVD02M01L157C","copia":"68","inizio":"2024-07-09","scadenza":"2024-08-11","riconsegna":null}	2024-07-09 19:04:26.021021
5	proroga	148	CRTDVD02M01L157C	{"id":"148","lettore":"CRTDVD02M01L157C","copia":"68","inizio":"2024-07-09","scadenza":"2024-08-11","riconsegna":null}	{"id":"148","lettore":"CRTDVD02M01L157C","copia":"68","inizio":"2024-07-09","scadenza":"2024-08-14","riconsegna":null}	2024-07-09 19:04:31.717805
6	riconsegna	148	CRTDVD02M01L157C	{"id":"148","lettore":"CRTDVD02M01L157C","copia":"68","inizio":"2024-07-09","scadenza":"2024-08-14","riconsegna":null}	{"id":"148","lettore":"CRTDVD02M01L157C","copia":"68","inizio":"2024-07-09","scadenza":"2024-08-14","riconsegna":"2024-07-09"}	2024-07-09 19:04:36.192463
7	proroga	151	CRTDVD02M01L157C	{"id":"151","lettore":"CRTDVD02M01L157C","copia":"69","inizio":"2024-07-09","scadenza":"2024-08-08","riconsegna":null}	{"id":"151","lettore":"CRTDVD02M01L157C","copia":"69","inizio":"2024-07-09","scadenza":"2024-08-10","riconsegna":null}	2024-07-09 19:17:28.169717
8	riconsegna	151	CRTDVD02M01L157C	{"id":"151","lettore":"CRTDVD02M01L157C","copia":"69","inizio":"2024-07-09","scadenza":"2024-08-10","riconsegna":null}	{"id":"151","lettore":"CRTDVD02M01L157C","copia":"69","inizio":"2024-07-09","scadenza":"2024-08-10","riconsegna":"2024-07-09"}	2024-07-09 19:17:31.928239
11	prestito	156	\N	{}	{"id":"156","lettore":"CRTDVD02M01L157C","copia":"68","inizio":"2024-07-09","scadenza":"2024-08-08","riconsegna":null}	2024-07-09 19:34:29.87967
12	prestito	157	\N	{}	{"id":"157","lettore":"CRTDVD02M01L157C","copia":"91","inizio":"2024-07-09","scadenza":"2024-08-08","riconsegna":null}	2024-07-09 19:35:25.87273
13	prestito	158	\N	{}	{"id":"158","lettore":"CRTDVD02M01L157C","copia":"15","inizio":"2024-07-09","scadenza":"2024-08-08","riconsegna":null}	2024-07-09 19:41:22.069281
14	prestito	161	\N	{}	{"id":"161","lettore":"CRTDVD02M01L157C","copia":"88","inizio":"2024-07-10","scadenza":"2024-08-09","riconsegna":null}	2024-07-10 13:23:17.981068
15	riconsegna	158	CRTDVD02M01L157C	{"id":"158","lettore":"CRTDVD02M01L157C","copia":"15","inizio":"2024-07-09","scadenza":"2024-08-08","riconsegna":null}	{"id":"158","lettore":"CRTDVD02M01L157C","copia":"15","inizio":"2024-07-09","scadenza":"2024-08-08","riconsegna":"2024-07-10"}	2024-07-10 14:31:59.377814
16	proroga	157	CRTDVD02M01L157C	{"id":"157","lettore":"CRTDVD02M01L157C","copia":"91","inizio":"2024-07-09","scadenza":"2024-08-08","riconsegna":null}	{"id":"157","lettore":"CRTDVD02M01L157C","copia":"91","inizio":"2024-07-09","scadenza":"2024-08-08","riconsegna":null}	2024-07-10 14:32:01.966401
17	riconsegna	156	CRTDVD02M01L157C	{"id":"156","lettore":"CRTDVD02M01L157C","copia":"68","inizio":"2024-07-09","scadenza":"2024-08-08","riconsegna":null}	{"id":"156","lettore":"CRTDVD02M01L157C","copia":"68","inizio":"2024-07-09","scadenza":"2024-08-08","riconsegna":"2024-07-10"}	2024-07-10 14:32:04.750782
18	riconsegna	152	CRTDVD02M01L157C	{"id":"152","lettore":"CRTDVD02M01L157C","copia":"64","inizio":"2024-07-09","scadenza":"2024-08-08","riconsegna":null}	{"id":"152","lettore":"CRTDVD02M01L157C","copia":"64","inizio":"2024-07-09","scadenza":"2024-08-08","riconsegna":"2024-07-10"}	2024-07-10 14:32:07.381055
19	riconsegna	157	CRTDVD02M01L157C	{"id":"157","lettore":"CRTDVD02M01L157C","copia":"91","inizio":"2024-07-09","scadenza":"2024-08-08","riconsegna":null}	{"id":"157","lettore":"CRTDVD02M01L157C","copia":"91","inizio":"2024-07-09","scadenza":"2024-08-08","riconsegna":"2024-07-10"}	2024-07-10 14:32:10.00267
20	riconsegna	161	CRTDVD02M01L157C	{"id":"161","lettore":"CRTDVD02M01L157C","copia":"88","inizio":"2024-07-10","scadenza":"2024-08-09","riconsegna":null}	{"id":"161","lettore":"CRTDVD02M01L157C","copia":"88","inizio":"2024-07-10","scadenza":"2024-08-09","riconsegna":"2024-07-10"}	2024-07-10 14:32:12.437601
21	prestito	164	\N	{}	{"id":"164","lettore":"CRTDVD02M01L157C","copia":"8","inizio":"2024-07-10","scadenza":"2024-08-09","riconsegna":null}	2024-07-10 14:37:00.003722
22	prestito	176	\N	{}	{"id":"176","lettore":"CRTDVD02M01L157C","copia":"21","inizio":"2024-07-10","scadenza":"2024-08-09","riconsegna":null}	2024-07-10 14:51:58.96534
23	prestito	177	\N	{}	{"id":"177","lettore":"CRTDVD02M01L157C","copia":"88","inizio":"2024-07-10","scadenza":"2024-08-09","riconsegna":null}	2024-07-10 14:54:45.902823
24	prestito	178	\N	{}	{"id":"178","lettore":"CRTDVD02M01L157C","copia":"15","inizio":"2024-07-10","scadenza":"2024-08-09","riconsegna":null}	2024-07-10 14:54:50.948723
25	prestito	179	\N	{}	{"id":"179","lettore":"CRTDVD02M01L157C","copia":"55","inizio":"2024-07-10","scadenza":"2024-08-09","riconsegna":null}	2024-07-10 14:54:55.113917
26	riconsegna	176	CRTDVD02M01L157C	{"id":"176","lettore":"CRTDVD02M01L157C","copia":"21","inizio":"2024-07-10","scadenza":"2024-08-09","riconsegna":null}	{"id":"176","lettore":"CRTDVD02M01L157C","copia":"21","inizio":"2024-07-10","scadenza":"2024-08-09","riconsegna":"2024-07-10"}	2024-07-10 15:24:58.705851
27	proroga	178	CRTDVD02M01L157C	{"id":"178","lettore":"CRTDVD02M01L157C","copia":"15","inizio":"2024-07-10","scadenza":"2024-08-09","riconsegna":null}	{"id":"178","lettore":"CRTDVD02M01L157C","copia":"15","inizio":"2024-07-10","scadenza":"2024-09-20","riconsegna":null}	2024-07-10 15:28:01.118387
28	riconsegna	179	CRTDVD02M01L157C	{"id":"179","lettore":"CRTDVD02M01L157C","copia":"55","inizio":"2024-07-10","scadenza":"2024-08-09","riconsegna":null}	{"id":"179","lettore":"CRTDVD02M01L157C","copia":"55","inizio":"2024-07-10","scadenza":"2024-08-09","riconsegna":"2024-07-10"}	2024-07-10 15:28:17.179023
\.


--
-- TOC entry 4978 (class 0 OID 16546)
-- Dependencies: 231
-- Data for Name: prestito; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.prestito (id, lettore, copia, inizio, scadenza, riconsegna) FROM stdin;
54	RLNMLC89G40H501H	5	2023-01-15	2023-02-14	2023-02-15
55	RLNMLC89G40H501H	6	2023-02-01	2023-02-25	2023-03-01
56	RLNMLC89G40H501H	8	2023-03-10	2023-04-09	2023-04-10
57	RLNMLC89G40H501H	9	2023-04-05	2023-04-30	2023-05-05
58	RLNMLC89G40H501H	10	2023-05-20	2023-06-19	2023-06-20
59	LNMRSB88R90H501X	11	2023-06-01	2023-07-01	2023-07-01
60	LNMRSB88R90H501X	12	2023-07-10	2023-07-25	2023-08-10
62	LNMRSB88R90H501X	14	2023-09-15	2023-10-15	2023-10-15
63	LNMRSB88R90H501X	15	2023-10-01	2023-10-31	2023-11-01
64	RSSMRA85M01H501Z	16	2023-01-05	2023-02-04	2023-02-05
65	RSSMRA85M01H501Z	18	2023-02-10	2023-03-12	2023-03-10
66	RSSMRA85M01H501Z	19	2023-03-15	2023-03-30	2023-04-15
67	RSSMRA85M01H501Z	20	2023-04-20	2023-05-20	2023-05-20
68	RSSMRA85M01H501Z	21	2023-05-25	2023-06-24	2023-06-25
69	RSSLAR80A01H501Y	22	2023-06-01	2023-07-01	2023-07-01
70	RSSLAR80A01H501Y	23	2023-07-05	2023-07-30	2023-08-05
71	RSSLAR80A01H501Y	24	2023-08-10	2023-09-09	2023-09-10
72	RSSLAR80A01H501Y	25	2023-09-15	2023-10-15	2023-10-15
73	RSSLAR80A01H501Y	26	2023-10-20	2023-11-19	2023-11-20
74	BNCDNL70B15H501T	27	2023-11-01	2023-12-01	2023-12-01
75	BNCDNL70B15H501T	28	2023-12-05	2024-01-04	2024-01-05
76	BNCDNL70B15H501T	29	2024-01-10	2024-02-09	2024-02-10
78	PRCSMS85C22H501F	31	2024-03-01	2024-03-31	2024-04-01
79	PRCSMS85C22H501F	32	2024-04-05	2024-04-25	2024-05-05
80	PRCSMS85C22H501F	33	2024-05-10	2024-06-09	2024-06-10
81	FNNLCR76E30H501G	34	2024-06-01	2024-07-01	2024-07-01
83	FNNLCR76E30H501G	36	2023-08-15	2024-09-05	2024-07-09
130	MRTGNS76O75H501U	35	2023-03-05	2023-04-05	2023-03-10
133	PNTMRR84P80H501V	38	2023-02-25	2023-03-25	2023-03-01
134	ZPLFRR73Q85H501W	39	2023-03-10	2023-04-10	2023-03-15
136	FNRBMD79S95H501Y	41	2023-01-30	2023-02-28	2023-02-01
138	PMTCRM70T01H501Z	43	2023-02-10	2023-03-10	2023-02-15
141	VRCDLR69U15H501A	46	2023-02-10	2023-03-10	2023-02-20
143	FSFSFS80A01F205G	48	2023-04-05	2023-05-05	2023-04-10
144	CDMNGS71D28H501M	49	2023-01-10	2023-02-10	2023-01-15
84	FNNLCR76E30H501G	37	2023-09-20	2024-10-20	2024-07-09
85	GVPLMN82F35H501J	38	2023-10-01	2024-10-31	2024-07-09
86	GVPLMN82F35H501J	39	2023-11-05	2024-12-05	2024-07-09
87	GVPLMN82F35H501J	40	2023-12-10	2025-01-09	2024-07-09
88	BTNSMR68H45H501K	41	2024-01-01	2025-01-31	2024-07-09
89	BTNSMR68H45H501K	42	2024-02-05	2025-03-07	2024-07-09
90	BTNSMR68H45H501K	43	2024-03-10	2025-04-09	2024-07-09
91	BTNSMR68H45H501K	44	2024-04-15	2025-05-15	2024-07-09
92	BTNSMR68H45H501K	45	2024-05-20	2025-06-19	2024-07-09
93	FRRBNL77J50H501P	46	2024-06-01	2025-07-01	2024-07-09
94	FRRBNL77J50H501P	47	2024-07-05	2025-08-04	2024-07-09
95	FRRBNL77J50H501P	48	2023-08-10	2025-09-09	2024-07-09
96	FRRBNL77J50H501P	49	2023-09-15	2025-10-15	2024-07-09
97	TSDRSM74K55H501Q	50	2023-10-01	2025-10-31	2024-07-09
98	TSDRSM74K55H501Q	51	2023-11-05	2025-12-05	2024-07-09
99	TSDRSM74K55H501Q	52	2023-12-10	2026-01-09	2024-07-09
102	RLNMLC89G40H501H	5	2023-01-15	2023-02-15	2023-01-20
104	LNMRSB88R90H501X	8	2023-03-10	2023-04-10	2023-03-12
106	RSSMRA85M01H501Z	10	2023-01-05	2023-02-05	2023-01-25
109	RSSLAR80A01H501Y	13	2023-04-20	2023-05-20	2023-04-25
111	BNCDNL70B15H501T	15	2023-03-10	2023-04-10	2023-03-15
112	PRCSMS85C22H501F	16	2023-01-20	2023-02-20	2023-01-22
115	FNNLCR76E30H501G	20	2023-04-10	2023-05-10	2023-04-15
116	GVPLMN82F35H501J	21	2023-01-10	2023-02-10	2023-01-15
118	BTNSMR68H45H501K	23	2023-03-05	2023-04-05	2023-03-10
120	FRRBNL77J50H501P	25	2023-01-30	2023-02-28	2023-01-31
122	TSDRSM74K55H501Q	27	2023-02-20	2023-03-20	2023-03-01
124	CTLMNR90L60H501R	29	2023-01-10	2023-02-10	2023-01-15
126	GNRMLA80M65H501S	31	2023-03-10	2023-04-10	2023-03-15
128	BPLTRM87N70H501T	33	2023-01-15	2023-02-15	2023-01-20
103	RLNMLC89G40H501H	6	2023-02-01	2023-03-01	2023-03-01
105	LNMRSB88R90H501X	9	2023-04-01	2023-05-01	2023-04-29
107	RSSMRA85M01H501Z	11	2023-02-10	2023-03-10	2023-04-10
108	RSSLAR80A01H501Y	12	2023-03-15	2023-04-15	2023-04-16
110	BNCDNL70B15H501T	14	2023-02-05	2023-03-05	2023-02-08
113	PRCSMS85C22H501F	18	2023-02-25	2023-03-25	2023-06-25
114	FNNLCR76E30H501G	19	2023-03-01	2023-04-01	2023-04-11
117	GVPLMN82F35H501J	22	2023-02-15	2023-03-15	2023-03-19
119	BTNSMR68H45H501K	24	2023-04-10	2023-05-10	2023-07-10
121	FRRBNL77J50H501P	26	2023-03-01	2023-04-01	2024-07-09
123	TSDRSM74K55H501Q	28	2023-03-25	2023-04-25	2023-04-20
125	CTLMNR90L60H501R	30	2023-02-15	2023-03-15	2024-03-12
131	MRTGNS76O75H501U	36	2023-04-10	2023-05-10	2023-05-10
132	PNTMRR84P80H501V	37	2023-01-20	2023-02-20	2023-02-19
135	ZPLFRR73Q85H501W	40	2023-04-15	2023-05-15	2023-05-04
137	FNRBMD79S95H501Y	42	2023-03-01	2023-04-01	2023-04-01
139	PMTCRM70T01H501Z	44	2023-03-15	2023-04-15	2023-04-15
140	VRCDLR69U15H501A	45	2023-01-05	2023-02-05	2023-02-05
142	FSFSFS80A01F205G	47	2023-03-01	2023-04-01	2023-04-01
129	BPLTRM87N70H501T	34	2023-02-20	2023-03-20	2024-07-09
145	CDMNGS71D28H501M	50	2023-02-15	2023-03-15	2024-07-09
127	GNRMLA80M65H501S	32	2023-04-15	2023-05-15	2024-07-09
82	FNNLCR76E30H501G	35	2024-07-10	2024-08-09	2024-07-19
158	CRTDVD02M01L157C	15	2024-07-09	2024-08-08	2024-07-10
148	CRTDVD02M01L157C	68	2024-07-09	2024-08-14	2024-07-09
151	CRTDVD02M01L157C	69	2024-07-09	2024-08-10	2024-07-09
156	CRTDVD02M01L157C	68	2024-07-09	2024-08-08	2024-07-10
152	CRTDVD02M01L157C	64	2024-07-09	2024-08-08	2024-07-10
157	CRTDVD02M01L157C	91	2024-07-09	2024-08-08	2024-07-10
161	CRTDVD02M01L157C	88	2024-07-10	2024-08-09	2024-07-10
164	CRTDVD02M01L157C	8	2024-07-10	2024-08-09	2024-07-10
165	CRTDVD02M01L157C	91	2024-07-10	2024-08-09	2024-07-10
173	CRTDVD02M01L157C	21	2024-07-10	2024-08-09	2024-07-10
175	CRTDVD02M01L157C	21	2024-07-10	2024-08-09	2024-07-10
176	CRTDVD02M01L157C	21	2024-07-10	2024-08-09	2024-07-10
206	CRTDVD02M01L157C	14	2024-06-05	2024-07-05	\N
179	CRTDVD02M01L157C	55	2024-07-10	2024-08-09	2024-07-10
61	LNMRSB88R90H501X	13	2023-08-05	2023-09-04	\N
77	BNCDNL70B15H501T	30	2024-02-15	2024-03-16	\N
170	CRTDVD02M01L157C	21	2024-07-10	2024-08-09	2024-07-10
177	CRTDVD02M01L157C	88	2024-07-10	2024-08-09	2024-07-10
178	CRTDVD02M01L157C	15	2024-07-10	2024-09-20	2024-07-10
207	CDMNGS71D28H501M	57	2024-07-03	2024-08-02	\N
208	BTNSMR68H45H501K	11	2024-06-25	2024-07-25	\N
\.


--
-- TOC entry 4972 (class 0 OID 16495)
-- Dependencies: 225
-- Data for Name: scrittura; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scrittura (libro, autore) FROM stdin;
9780143128540	1
9780060935467	2
9781501126372	3
9780312428421	4
9780316769488	5
9780743273565	6
9780393040029	7
9780143039433	8
9780679451146	6
9780452284234	8
9788804625376	19
9788807030447	18
9788867870197	16
9788838934534	17
9788842087105	20
9780345391803	9
9780451529236	10
9780679728019	11
9780452284258	12
9780140186390	13
9780743273558	6
9780060834820	4
9780553213117	14
9780141187761	4
9780062315006	15
9780451529250	10
9780743273541	6
9780062316096	15
9780060853983	21
9780060853983	22
9780452284774	23
9780452284774	26
978880790049 	27
9780743273565	15
\.


--
-- TOC entry 4968 (class 0 OID 16447)
-- Dependencies: 221
-- Data for Name: sede; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sede (id, indirizzo, citta) FROM stdin;
1	Via Celoria, 18	1
2	Via Festa del Perdono, 7	1
3	Broadway, 1	2
4	Downing Street, 10	3
7	Piazza dei Signori, 1	7
8	Via Gogli, 27	1
\.


--
-- TOC entry 4995 (class 0 OID 0)
-- Dependencies: 216
-- Name: autore_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.autore_id_seq', 28, true);


--
-- TOC entry 4996 (class 0 OID 0)
-- Dependencies: 222
-- Name: casa_editrice_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.casa_editrice_id_seq', 15, true);


--
-- TOC entry 4997 (class 0 OID 0)
-- Dependencies: 218
-- Name: citta_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.citta_id_seq', 7, true);


--
-- TOC entry 4998 (class 0 OID 0)
-- Dependencies: 226
-- Name: copia_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.copia_id_seq', 94, true);


--
-- TOC entry 4999 (class 0 OID 0)
-- Dependencies: 234
-- Name: log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.log_id_seq', 1, false);


--
-- TOC entry 5000 (class 0 OID 0)
-- Dependencies: 235
-- Name: log_id_seq1; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.log_id_seq1', 28, true);


--
-- TOC entry 5001 (class 0 OID 0)
-- Dependencies: 230
-- Name: prestito_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.prestito_id_seq', 208, true);


--
-- TOC entry 5002 (class 0 OID 0)
-- Dependencies: 220
-- Name: sede_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sede_id_seq', 8, true);


--
-- TOC entry 4777 (class 2606 OID 16438)
-- Name: autore autore_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.autore
    ADD CONSTRAINT autore_pkey PRIMARY KEY (id);


--
-- TOC entry 4793 (class 2606 OID 16542)
-- Name: bibliotecario bibliotecario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bibliotecario
    ADD CONSTRAINT bibliotecario_pkey PRIMARY KEY (cf);


--
-- TOC entry 4783 (class 2606 OID 16476)
-- Name: casa_editrice casa_editrice_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.casa_editrice
    ADD CONSTRAINT casa_editrice_pkey PRIMARY KEY (id);


--
-- TOC entry 4779 (class 2606 OID 16445)
-- Name: citta citta_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.citta
    ADD CONSTRAINT citta_pkey PRIMARY KEY (id);


--
-- TOC entry 4789 (class 2606 OID 16516)
-- Name: copia copia_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.copia
    ADD CONSTRAINT copia_pkey PRIMARY KEY (id);


--
-- TOC entry 4791 (class 2606 OID 16533)
-- Name: lettore lettore_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lettore
    ADD CONSTRAINT lettore_pkey PRIMARY KEY (cf);


--
-- TOC entry 4785 (class 2606 OID 16593)
-- Name: libro libro_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.libro
    ADD CONSTRAINT libro_pkey PRIMARY KEY (isbn);


--
-- TOC entry 4797 (class 2606 OID 24887)
-- Name: log log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log
    ADD CONSTRAINT log_pkey PRIMARY KEY (id);


--
-- TOC entry 4795 (class 2606 OID 16551)
-- Name: prestito prestito_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prestito
    ADD CONSTRAINT prestito_pkey PRIMARY KEY (id);


--
-- TOC entry 4787 (class 2606 OID 16499)
-- Name: scrittura scrittura_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scrittura
    ADD CONSTRAINT scrittura_pkey PRIMARY KEY (libro, autore);


--
-- TOC entry 4781 (class 2606 OID 16452)
-- Name: sede sede_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sede
    ADD CONSTRAINT sede_pkey PRIMARY KEY (id);


--
-- TOC entry 4809 (class 2620 OID 16640)
-- Name: prestito check_copia_disponibile_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER check_copia_disponibile_trigger BEFORE INSERT ON public.prestito FOR EACH ROW EXECUTE FUNCTION public.check_copia_disponibile();


--
-- TOC entry 4810 (class 2620 OID 24834)
-- Name: prestito check_date_prestito_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER check_date_prestito_trigger BEFORE INSERT OR UPDATE ON public.prestito FOR EACH ROW EXECUTE FUNCTION public.check_date_prestito();


--
-- TOC entry 4811 (class 2620 OID 16634)
-- Name: prestito check_prestiti_attivi_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER check_prestiti_attivi_trigger BEFORE INSERT ON public.prestito FOR EACH ROW EXECUTE FUNCTION public.check_prestiti_attivi();


--
-- TOC entry 4812 (class 2620 OID 16653)
-- Name: prestito check_proroga_consentita_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER check_proroga_consentita_trigger BEFORE UPDATE OF scadenza ON public.prestito FOR EACH ROW EXECUTE FUNCTION public.check_proroga_consentita();


--
-- TOC entry 4813 (class 2620 OID 24908)
-- Name: prestito check_ritardi_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER check_ritardi_trigger BEFORE INSERT ON public.prestito FOR EACH ROW EXECUTE FUNCTION public.check_ritardi();


--
-- TOC entry 4814 (class 2620 OID 16651)
-- Name: prestito increment_ritardi_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER increment_ritardi_trigger AFTER UPDATE OF riconsegna ON public.prestito FOR EACH ROW WHEN (((old.riconsegna IS NULL) AND (new.riconsegna IS NOT NULL))) EXECUTE FUNCTION public.increment_ritardi();


--
-- TOC entry 4815 (class 2620 OID 16645)
-- Name: prestito set_copia_disponibile_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_copia_disponibile_trigger AFTER UPDATE OF riconsegna ON public.prestito FOR EACH ROW WHEN ((new.riconsegna IS NOT NULL)) EXECUTE FUNCTION public.set_copia_disponibile();


--
-- TOC entry 4816 (class 2620 OID 16642)
-- Name: prestito set_copia_non_disponibile_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_copia_non_disponibile_trigger AFTER INSERT ON public.prestito FOR EACH ROW EXECUTE FUNCTION public.set_copia_non_disponibile();


--
-- TOC entry 4817 (class 2620 OID 16654)
-- Name: prestito set_scadenza_default_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_scadenza_default_trigger BEFORE INSERT ON public.prestito FOR EACH ROW EXECUTE FUNCTION public.set_scadenza_default();


--
-- TOC entry 4799 (class 2606 OID 16477)
-- Name: casa_editrice casa_editrice_sede_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.casa_editrice
    ADD CONSTRAINT casa_editrice_sede_fkey FOREIGN KEY (citta) REFERENCES public.citta(id);


--
-- TOC entry 4803 (class 2606 OID 16599)
-- Name: copia copia_isbn_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.copia
    ADD CONSTRAINT copia_isbn_fkey FOREIGN KEY (libro) REFERENCES public.libro(isbn);


--
-- TOC entry 4804 (class 2606 OID 16522)
-- Name: copia copia_sede_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.copia
    ADD CONSTRAINT copia_sede_fkey FOREIGN KEY (sede) REFERENCES public.sede(id);


--
-- TOC entry 4800 (class 2606 OID 16490)
-- Name: libro libro_editore_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.libro
    ADD CONSTRAINT libro_editore_fkey FOREIGN KEY (editore) REFERENCES public.casa_editrice(id);


--
-- TOC entry 4807 (class 2606 OID 24896)
-- Name: log log_bibliotecario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log
    ADD CONSTRAINT log_bibliotecario_fkey FOREIGN KEY (bibliotecario) REFERENCES public.bibliotecario(cf);


--
-- TOC entry 4808 (class 2606 OID 24901)
-- Name: log log_prestito_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log
    ADD CONSTRAINT log_prestito_fkey FOREIGN KEY (prestito) REFERENCES public.prestito(id);


--
-- TOC entry 4805 (class 2606 OID 16557)
-- Name: prestito prestito_copia_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prestito
    ADD CONSTRAINT prestito_copia_fkey FOREIGN KEY (copia) REFERENCES public.copia(id);


--
-- TOC entry 4806 (class 2606 OID 16552)
-- Name: prestito prestito_lettore_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prestito
    ADD CONSTRAINT prestito_lettore_fkey FOREIGN KEY (lettore) REFERENCES public.lettore(cf);


--
-- TOC entry 4801 (class 2606 OID 16505)
-- Name: scrittura scrittura_autore_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scrittura
    ADD CONSTRAINT scrittura_autore_fkey FOREIGN KEY (autore) REFERENCES public.autore(id);


--
-- TOC entry 4802 (class 2606 OID 16594)
-- Name: scrittura scrittura_libro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scrittura
    ADD CONSTRAINT scrittura_libro_fkey FOREIGN KEY (libro) REFERENCES public.libro(isbn);


--
-- TOC entry 4798 (class 2606 OID 16453)
-- Name: sede sede_citta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sede
    ADD CONSTRAINT sede_citta_fkey FOREIGN KEY (citta) REFERENCES public.citta(id);


-- Completed on 2024-07-10 16:49:02

--
-- PostgreSQL database dump complete
--

