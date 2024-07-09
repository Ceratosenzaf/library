PGDMP      9        	        |           postgres    16.2    16.2 g    x           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            y           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            z           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            {           1262    5    postgres    DATABASE     �   CREATE DATABASE postgres WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1252';
    DROP DATABASE postgres;
                postgres    false            |           0    0    DATABASE postgres    COMMENT     N   COMMENT ON DATABASE postgres IS 'default administrative connection database';
                   postgres    false    4987                        2615    2200    public    SCHEMA        CREATE SCHEMA public;
    DROP SCHEMA public;
                pg_database_owner    false            }           0    0    SCHEMA public    COMMENT     6   COMMENT ON SCHEMA public IS 'standard public schema';
                   pg_database_owner    false    5            �           1247    16563    tipo_log    TYPE     Y   CREATE TYPE public.tipo_log AS ENUM (
    'prestito',
    'proroga',
    'riconsegna'
);
    DROP TYPE public.tipo_log;
       public          postgres    false    5                       1255    24906 H   check_and_insert_prestito(character varying, character varying, integer)    FUNCTION     n  CREATE FUNCTION public.check_and_insert_prestito(cf character varying, isbn character varying, sede_predefinita integer DEFAULT NULL::integer) RETURNS TABLE(id_prestito integer, id_copia integer, id_sede integer)
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
    
    -- sede non specificata o copia non trovata presso quella sede
    SELECT id, sede
    INTO id_copia, id_sede
    FROM copia
    WHERE libro = isbn
      AND disponibile = true
      AND archiviato = false
    LIMIT 1;
    
    IF FOUND THEN
        RAISE NOTICE 'Il libro non è disponibile nella sede specificata. Considerando copie da altre sedi.';
        
        INSERT INTO prestito (lettore, copia, inizio)
        VALUES (cf, id_copia, CURRENT_DATE)
        RETURNING id INTO id_prestito;
       
        RETURN QUERY SELECT id_prestito, id_copia, id_sede;
    ELSE
        RAISE EXCEPTION 'Nessuna copia disponibile per il libro richiesto.';
    END IF;
END;
$$;
 x   DROP FUNCTION public.check_and_insert_prestito(cf character varying, isbn character varying, sede_predefinita integer);
       public          postgres    false    5            �            1255    16639    check_copia_disponibile()    FUNCTION     �  CREATE FUNCTION public.check_copia_disponibile() RETURNS trigger
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
 0   DROP FUNCTION public.check_copia_disponibile();
       public          postgres    false    5            �            1255    24833    check_date_prestito()    FUNCTION       CREATE FUNCTION public.check_date_prestito() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (NEW.inizio > NOW() or NEW.riconsegna > NOW()) THEN
        RAISE EXCEPTION 'Il prestito non può trovarsi nel futuro';
    END IF;

    RETURN NEW;
END;
$$;
 ,   DROP FUNCTION public.check_date_prestito();
       public          postgres    false    5            �            1255    16633    check_prestiti_attivi()    FUNCTION     �  CREATE FUNCTION public.check_prestiti_attivi() RETURNS trigger
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
 .   DROP FUNCTION public.check_prestiti_attivi();
       public          postgres    false    5            �            1255    16652    check_proroga_consentita()    FUNCTION     |  CREATE FUNCTION public.check_proroga_consentita() RETURNS trigger
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
 1   DROP FUNCTION public.check_proroga_consentita();
       public          postgres    false    5            �            1255    24907    check_ritardi()    FUNCTION     7  CREATE FUNCTION public.check_ritardi() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (SELECT ritardi FROM lettore WHERE cf = NEW.lettore) >= 5 THEN
        RAISE EXCEPTION 'Il lettore è stato bloccato perché ha superato il numero massimo di ritardi';
    END IF;
    RETURN NEW;
END;
$$;
 &   DROP FUNCTION public.check_ritardi();
       public          postgres    false    5            �            1255    16649    increment_ritardi()    FUNCTION       CREATE FUNCTION public.increment_ritardi() RETURNS trigger
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
 *   DROP FUNCTION public.increment_ritardi();
       public          postgres    false    5            �            1255    16644    set_copia_disponibile()    FUNCTION     �   CREATE FUNCTION public.set_copia_disponibile() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE copia
    SET disponibile = TRUE
    WHERE id = NEW.copia;
    RETURN NEW;
END;
$$;
 .   DROP FUNCTION public.set_copia_disponibile();
       public          postgres    false    5            �            1255    16641    set_copia_non_disponibile()    FUNCTION     �   CREATE FUNCTION public.set_copia_non_disponibile() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE copia
    SET disponibile = FALSE
    WHERE id = NEW.copia;
    RETURN NEW;
END;
$$;
 2   DROP FUNCTION public.set_copia_non_disponibile();
       public          postgres    false    5            �            1255    16588    set_scadenza_default()    FUNCTION     �   CREATE FUNCTION public.set_scadenza_default() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.scadenza IS NULL THEN
        NEW.scadenza = NEW.inizio + INTERVAL '30 days';
    END IF;
    RETURN NEW;
END;
$$;
 -   DROP FUNCTION public.set_scadenza_default();
       public          postgres    false    5            �            1259    16431    autore    TABLE     #  CREATE TABLE public.autore (
    id integer NOT NULL,
    nome character varying(255),
    cognome character varying(255),
    pseudonimo character varying(255),
    nascita date,
    morte date,
    biografia text,
    CONSTRAINT chk_date CHECK (((morte IS NULL) OR (nascita <= morte)))
);
    DROP TABLE public.autore;
       public         heap    postgres    false    5            �            1259    16430    autore_id_seq    SEQUENCE     �   CREATE SEQUENCE public.autore_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE public.autore_id_seq;
       public          postgres    false    217    5            ~           0    0    autore_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE public.autore_id_seq OWNED BY public.autore.id;
          public          postgres    false    216            �            1259    16536    bibliotecario    TABLE     �   CREATE TABLE public.bibliotecario (
    cf character(16) NOT NULL,
    nome character varying(255) NOT NULL,
    cognome character varying(255) NOT NULL,
    password character varying(255) NOT NULL
);
 !   DROP TABLE public.bibliotecario;
       public         heap    postgres    false    5            �            1259    16471    casa_editrice    TABLE     �   CREATE TABLE public.casa_editrice (
    id integer NOT NULL,
    nome character varying(255) NOT NULL,
    fondazione date,
    cessazione date,
    citta integer,
    CONSTRAINT chk_date CHECK (((cessazione IS NULL) OR (fondazione <= cessazione)))
);
 !   DROP TABLE public.casa_editrice;
       public         heap    postgres    false    5            �            1259    16470    casa_editrice_id_seq    SEQUENCE     �   CREATE SEQUENCE public.casa_editrice_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.casa_editrice_id_seq;
       public          postgres    false    223    5                       0    0    casa_editrice_id_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.casa_editrice_id_seq OWNED BY public.casa_editrice.id;
          public          postgres    false    222            �            1259    16440    citta    TABLE     a   CREATE TABLE public.citta (
    id integer NOT NULL,
    nome character varying(255) NOT NULL
);
    DROP TABLE public.citta;
       public         heap    postgres    false    5            �            1259    16439    citta_id_seq    SEQUENCE     �   CREATE SEQUENCE public.citta_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE public.citta_id_seq;
       public          postgres    false    219    5            �           0    0    citta_id_seq    SEQUENCE OWNED BY     =   ALTER SEQUENCE public.citta_id_seq OWNED BY public.citta.id;
          public          postgres    false    218            �            1259    16511    copia    TABLE     �   CREATE TABLE public.copia (
    id integer NOT NULL,
    libro character(13) NOT NULL,
    sede integer NOT NULL,
    disponibile boolean DEFAULT true NOT NULL,
    archiviato boolean DEFAULT false NOT NULL
);
    DROP TABLE public.copia;
       public         heap    postgres    false    5            �            1259    16510    copia_id_seq    SEQUENCE     �   CREATE SEQUENCE public.copia_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE public.copia_id_seq;
       public          postgres    false    227    5            �           0    0    copia_id_seq    SEQUENCE OWNED BY     =   ALTER SEQUENCE public.copia_id_seq OWNED BY public.copia.id;
          public          postgres    false    226            �            1259    16527    lettore    TABLE       CREATE TABLE public.lettore (
    cf character(16) NOT NULL,
    nome character varying(255) NOT NULL,
    cognome character varying(255) NOT NULL,
    premium boolean DEFAULT false NOT NULL,
    ritardi integer DEFAULT 0 NOT NULL,
    password character varying(255) NOT NULL
);
    DROP TABLE public.lettore;
       public         heap    postgres    false    5            �            1259    16483    libro    TABLE     `  CREATE TABLE public.libro (
    isbn character(13) NOT NULL,
    titolo character varying(255) NOT NULL,
    trama text NOT NULL,
    editore integer NOT NULL,
    pagine smallint NOT NULL,
    pubblicazione date,
    CONSTRAINT chk_date CHECK (((pubblicazione IS NULL) OR (pubblicazione <= now()))),
    CONSTRAINT chk_pagine CHECK ((pagine >= 0))
);
    DROP TABLE public.libro;
       public         heap    postgres    false    5            �            1259    24879    log    TABLE     �  CREATE TABLE public.log (
    id integer NOT NULL,
    tipo public.tipo_log NOT NULL,
    prestito integer NOT NULL,
    bibliotecario character varying(16),
    dati_pre json NOT NULL,
    dati_post json NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_bibliotecario CHECK (((tipo = 'prestito'::public.tipo_log) OR (bibliotecario IS NOT NULL)))
);
    DROP TABLE public.log;
       public         heap    postgres    false    901    5    901            �            1259    24867 
   log_id_seq    SEQUENCE     �   CREATE SEQUENCE public.log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 !   DROP SEQUENCE public.log_id_seq;
       public          postgres    false    5            �            1259    24878    log_id_seq1    SEQUENCE     �   CREATE SEQUENCE public.log_id_seq1
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 "   DROP SEQUENCE public.log_id_seq1;
       public          postgres    false    236    5            �           0    0    log_id_seq1    SEQUENCE OWNED BY     :   ALTER SEQUENCE public.log_id_seq1 OWNED BY public.log.id;
          public          postgres    false    235            �            1259    16546    prestito    TABLE     U  CREATE TABLE public.prestito (
    id integer NOT NULL,
    lettore character(16) NOT NULL,
    copia integer NOT NULL,
    inizio date NOT NULL,
    scadenza date NOT NULL,
    riconsegna date,
    CONSTRAINT chk_riconsegna_dopo_inizio CHECK ((riconsegna >= inizio)),
    CONSTRAINT chk_scadenza_dopo_inizio CHECK ((scadenza >= inizio))
);
    DROP TABLE public.prestito;
       public         heap    postgres    false    5            �            1259    16545    prestito_id_seq    SEQUENCE     �   CREATE SEQUENCE public.prestito_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.prestito_id_seq;
       public          postgres    false    5    231            �           0    0    prestito_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE public.prestito_id_seq OWNED BY public.prestito.id;
          public          postgres    false    230            �            1259    16447    sede    TABLE     �   CREATE TABLE public.sede (
    id integer NOT NULL,
    indirizzo character varying(255) NOT NULL,
    citta integer NOT NULL
);
    DROP TABLE public.sede;
       public         heap    postgres    false    5            �            1259    24818    ritardi_sede    VIEW     s  CREATE VIEW public.ritardi_sede AS
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
    DROP VIEW public.ritardi_sede;
       public          postgres    false    231    231    231    231    227    227    227    221    5            �            1259    16495 	   scrittura    TABLE     a   CREATE TABLE public.scrittura (
    libro character(13) NOT NULL,
    autore integer NOT NULL
);
    DROP TABLE public.scrittura;
       public         heap    postgres    false    5            �            1259    16446    sede_id_seq    SEQUENCE     �   CREATE SEQUENCE public.sede_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 "   DROP SEQUENCE public.sede_id_seq;
       public          postgres    false    221    5            �           0    0    sede_id_seq    SEQUENCE OWNED BY     ;   ALTER SEQUENCE public.sede_id_seq OWNED BY public.sede.id;
          public          postgres    false    220            �            1259    24814    statistiche_sede    VIEW       CREATE VIEW public.statistiche_sede AS
 SELECT s.id,
    count(c.id) AS copie,
    count(DISTINCT c.libro) AS libri,
    count(c.id) FILTER (WHERE (c.disponibile IS FALSE)) AS prestiti_attivi
   FROM (public.sede s
     LEFT JOIN public.copia c ON ((s.id = c.sede)))
  GROUP BY s.id;
 #   DROP VIEW public.statistiche_sede;
       public          postgres    false    227    227    227    221    227    5            �           2604    16434 	   autore id    DEFAULT     f   ALTER TABLE ONLY public.autore ALTER COLUMN id SET DEFAULT nextval('public.autore_id_seq'::regclass);
 8   ALTER TABLE public.autore ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    217    216    217            �           2604    16474    casa_editrice id    DEFAULT     t   ALTER TABLE ONLY public.casa_editrice ALTER COLUMN id SET DEFAULT nextval('public.casa_editrice_id_seq'::regclass);
 ?   ALTER TABLE public.casa_editrice ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    222    223    223            �           2604    16443    citta id    DEFAULT     d   ALTER TABLE ONLY public.citta ALTER COLUMN id SET DEFAULT nextval('public.citta_id_seq'::regclass);
 7   ALTER TABLE public.citta ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    218    219    219            �           2604    16514    copia id    DEFAULT     d   ALTER TABLE ONLY public.copia ALTER COLUMN id SET DEFAULT nextval('public.copia_id_seq'::regclass);
 7   ALTER TABLE public.copia ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    226    227    227            �           2604    24882    log id    DEFAULT     a   ALTER TABLE ONLY public.log ALTER COLUMN id SET DEFAULT nextval('public.log_id_seq1'::regclass);
 5   ALTER TABLE public.log ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    235    236    236            �           2604    16549    prestito id    DEFAULT     j   ALTER TABLE ONLY public.prestito ALTER COLUMN id SET DEFAULT nextval('public.prestito_id_seq'::regclass);
 :   ALTER TABLE public.prestito ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    231    230    231            �           2604    16450    sede id    DEFAULT     b   ALTER TABLE ONLY public.sede ALTER COLUMN id SET DEFAULT nextval('public.sede_id_seq'::regclass);
 6   ALTER TABLE public.sede ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    221    220    221            d          0    16431    autore 
   TABLE DATA           Z   COPY public.autore (id, nome, cognome, pseudonimo, nascita, morte, biografia) FROM stdin;
    public          postgres    false    217   h�       p          0    16536    bibliotecario 
   TABLE DATA           D   COPY public.bibliotecario (cf, nome, cognome, password) FROM stdin;
    public          postgres    false    229   ˑ       j          0    16471    casa_editrice 
   TABLE DATA           P   COPY public.casa_editrice (id, nome, fondazione, cessazione, citta) FROM stdin;
    public          postgres    false    223   (�       f          0    16440    citta 
   TABLE DATA           )   COPY public.citta (id, nome) FROM stdin;
    public          postgres    false    219   m�       n          0    16511    copia 
   TABLE DATA           I   COPY public.copia (id, libro, sede, disponibile, archiviato) FROM stdin;
    public          postgres    false    227   ɓ       o          0    16527    lettore 
   TABLE DATA           P   COPY public.lettore (cf, nome, cognome, premium, ritardi, password) FROM stdin;
    public          postgres    false    228   �       k          0    16483    libro 
   TABLE DATA           T   COPY public.libro (isbn, titolo, trama, editore, pagine, pubblicazione) FROM stdin;
    public          postgres    false    224   ��       u          0    24879    log 
   TABLE DATA           a   COPY public.log (id, tipo, prestito, bibliotecario, dati_pre, dati_post, created_at) FROM stdin;
    public          postgres    false    236   7�       r          0    16546    prestito 
   TABLE DATA           T   COPY public.prestito (id, lettore, copia, inizio, scadenza, riconsegna) FROM stdin;
    public          postgres    false    231   ��       l          0    16495 	   scrittura 
   TABLE DATA           2   COPY public.scrittura (libro, autore) FROM stdin;
    public          postgres    false    225   �       h          0    16447    sede 
   TABLE DATA           4   COPY public.sede (id, indirizzo, citta) FROM stdin;
    public          postgres    false    221   �       �           0    0    autore_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('public.autore_id_seq', 27, true);
          public          postgres    false    216            �           0    0    casa_editrice_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.casa_editrice_id_seq', 15, true);
          public          postgres    false    222            �           0    0    citta_id_seq    SEQUENCE SET     :   SELECT pg_catalog.setval('public.citta_id_seq', 7, true);
          public          postgres    false    218            �           0    0    copia_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('public.copia_id_seq', 94, true);
          public          postgres    false    226            �           0    0 
   log_id_seq    SEQUENCE SET     9   SELECT pg_catalog.setval('public.log_id_seq', 1, false);
          public          postgres    false    234            �           0    0    log_id_seq1    SEQUENCE SET     :   SELECT pg_catalog.setval('public.log_id_seq1', 13, true);
          public          postgres    false    235            �           0    0    prestito_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.prestito_id_seq', 159, true);
          public          postgres    false    230            �           0    0    sede_id_seq    SEQUENCE SET     9   SELECT pg_catalog.setval('public.sede_id_seq', 7, true);
          public          postgres    false    220            �           2606    16438    autore autore_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.autore
    ADD CONSTRAINT autore_pkey PRIMARY KEY (id);
 <   ALTER TABLE ONLY public.autore DROP CONSTRAINT autore_pkey;
       public            postgres    false    217            �           2606    16542     bibliotecario bibliotecario_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.bibliotecario
    ADD CONSTRAINT bibliotecario_pkey PRIMARY KEY (cf);
 J   ALTER TABLE ONLY public.bibliotecario DROP CONSTRAINT bibliotecario_pkey;
       public            postgres    false    229            �           2606    16476     casa_editrice casa_editrice_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.casa_editrice
    ADD CONSTRAINT casa_editrice_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY public.casa_editrice DROP CONSTRAINT casa_editrice_pkey;
       public            postgres    false    223            �           2606    16445    citta citta_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY public.citta
    ADD CONSTRAINT citta_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY public.citta DROP CONSTRAINT citta_pkey;
       public            postgres    false    219            �           2606    16516    copia copia_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY public.copia
    ADD CONSTRAINT copia_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY public.copia DROP CONSTRAINT copia_pkey;
       public            postgres    false    227            �           2606    16533    lettore lettore_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.lettore
    ADD CONSTRAINT lettore_pkey PRIMARY KEY (cf);
 >   ALTER TABLE ONLY public.lettore DROP CONSTRAINT lettore_pkey;
       public            postgres    false    228            �           2606    16593    libro libro_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.libro
    ADD CONSTRAINT libro_pkey PRIMARY KEY (isbn);
 :   ALTER TABLE ONLY public.libro DROP CONSTRAINT libro_pkey;
       public            postgres    false    224            �           2606    24887    log log_pkey 
   CONSTRAINT     J   ALTER TABLE ONLY public.log
    ADD CONSTRAINT log_pkey PRIMARY KEY (id);
 6   ALTER TABLE ONLY public.log DROP CONSTRAINT log_pkey;
       public            postgres    false    236            �           2606    16551    prestito prestito_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.prestito
    ADD CONSTRAINT prestito_pkey PRIMARY KEY (id);
 @   ALTER TABLE ONLY public.prestito DROP CONSTRAINT prestito_pkey;
       public            postgres    false    231            �           2606    16499    scrittura scrittura_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY public.scrittura
    ADD CONSTRAINT scrittura_pkey PRIMARY KEY (libro, autore);
 B   ALTER TABLE ONLY public.scrittura DROP CONSTRAINT scrittura_pkey;
       public            postgres    false    225    225            �           2606    16452    sede sede_pkey 
   CONSTRAINT     L   ALTER TABLE ONLY public.sede
    ADD CONSTRAINT sede_pkey PRIMARY KEY (id);
 8   ALTER TABLE ONLY public.sede DROP CONSTRAINT sede_pkey;
       public            postgres    false    221            �           2620    16640 (   prestito check_copia_disponibile_trigger    TRIGGER     �   CREATE TRIGGER check_copia_disponibile_trigger BEFORE INSERT ON public.prestito FOR EACH ROW EXECUTE FUNCTION public.check_copia_disponibile();
 A   DROP TRIGGER check_copia_disponibile_trigger ON public.prestito;
       public          postgres    false    231    239            �           2620    24834 $   prestito check_date_prestito_trigger    TRIGGER     �   CREATE TRIGGER check_date_prestito_trigger BEFORE INSERT OR UPDATE ON public.prestito FOR EACH ROW EXECUTE FUNCTION public.check_date_prestito();
 =   DROP TRIGGER check_date_prestito_trigger ON public.prestito;
       public          postgres    false    244    231            �           2620    16634 &   prestito check_prestiti_attivi_trigger    TRIGGER     �   CREATE TRIGGER check_prestiti_attivi_trigger BEFORE INSERT ON public.prestito FOR EACH ROW EXECUTE FUNCTION public.check_prestiti_attivi();
 ?   DROP TRIGGER check_prestiti_attivi_trigger ON public.prestito;
       public          postgres    false    231    238            �           2620    16653 )   prestito check_proroga_consentita_trigger    TRIGGER     �   CREATE TRIGGER check_proroga_consentita_trigger BEFORE UPDATE OF scadenza ON public.prestito FOR EACH ROW EXECUTE FUNCTION public.check_proroga_consentita();
 B   DROP TRIGGER check_proroga_consentita_trigger ON public.prestito;
       public          postgres    false    231    242    231            �           2620    24908    prestito check_ritardi_trigger    TRIGGER     |   CREATE TRIGGER check_ritardi_trigger BEFORE INSERT ON public.prestito FOR EACH ROW EXECUTE FUNCTION public.check_ritardi();
 7   DROP TRIGGER check_ritardi_trigger ON public.prestito;
       public          postgres    false    245    231            �           2620    16651 "   prestito increment_ritardi_trigger    TRIGGER     �   CREATE TRIGGER increment_ritardi_trigger AFTER UPDATE OF riconsegna ON public.prestito FOR EACH ROW WHEN (((old.riconsegna IS NULL) AND (new.riconsegna IS NOT NULL))) EXECUTE FUNCTION public.increment_ritardi();
 ;   DROP TRIGGER increment_ritardi_trigger ON public.prestito;
       public          postgres    false    231    243    231    231            �           2620    16645 &   prestito set_copia_disponibile_trigger    TRIGGER     �   CREATE TRIGGER set_copia_disponibile_trigger AFTER UPDATE OF riconsegna ON public.prestito FOR EACH ROW WHEN ((new.riconsegna IS NOT NULL)) EXECUTE FUNCTION public.set_copia_disponibile();
 ?   DROP TRIGGER set_copia_disponibile_trigger ON public.prestito;
       public          postgres    false    231    231    231    241            �           2620    16642 *   prestito set_copia_non_disponibile_trigger    TRIGGER     �   CREATE TRIGGER set_copia_non_disponibile_trigger AFTER INSERT ON public.prestito FOR EACH ROW EXECUTE FUNCTION public.set_copia_non_disponibile();
 C   DROP TRIGGER set_copia_non_disponibile_trigger ON public.prestito;
       public          postgres    false    231    240            �           2620    16654 %   prestito set_scadenza_default_trigger    TRIGGER     �   CREATE TRIGGER set_scadenza_default_trigger BEFORE INSERT ON public.prestito FOR EACH ROW EXECUTE FUNCTION public.set_scadenza_default();
 >   DROP TRIGGER set_scadenza_default_trigger ON public.prestito;
       public          postgres    false    237    231            �           2606    16477 %   casa_editrice casa_editrice_sede_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.casa_editrice
    ADD CONSTRAINT casa_editrice_sede_fkey FOREIGN KEY (citta) REFERENCES public.citta(id);
 O   ALTER TABLE ONLY public.casa_editrice DROP CONSTRAINT casa_editrice_sede_fkey;
       public          postgres    false    219    4779    223            �           2606    16599    copia copia_isbn_fkey    FK CONSTRAINT     t   ALTER TABLE ONLY public.copia
    ADD CONSTRAINT copia_isbn_fkey FOREIGN KEY (libro) REFERENCES public.libro(isbn);
 ?   ALTER TABLE ONLY public.copia DROP CONSTRAINT copia_isbn_fkey;
       public          postgres    false    4785    224    227            �           2606    16522    copia copia_sede_fkey    FK CONSTRAINT     p   ALTER TABLE ONLY public.copia
    ADD CONSTRAINT copia_sede_fkey FOREIGN KEY (sede) REFERENCES public.sede(id);
 ?   ALTER TABLE ONLY public.copia DROP CONSTRAINT copia_sede_fkey;
       public          postgres    false    227    221    4781            �           2606    16490    libro libro_editore_fkey    FK CONSTRAINT        ALTER TABLE ONLY public.libro
    ADD CONSTRAINT libro_editore_fkey FOREIGN KEY (editore) REFERENCES public.casa_editrice(id);
 B   ALTER TABLE ONLY public.libro DROP CONSTRAINT libro_editore_fkey;
       public          postgres    false    4783    224    223            �           2606    24896    log log_bibliotecario_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.log
    ADD CONSTRAINT log_bibliotecario_fkey FOREIGN KEY (bibliotecario) REFERENCES public.bibliotecario(cf);
 D   ALTER TABLE ONLY public.log DROP CONSTRAINT log_bibliotecario_fkey;
       public          postgres    false    229    4793    236            �           2606    24901    log log_prestito_fkey    FK CONSTRAINT     x   ALTER TABLE ONLY public.log
    ADD CONSTRAINT log_prestito_fkey FOREIGN KEY (prestito) REFERENCES public.prestito(id);
 ?   ALTER TABLE ONLY public.log DROP CONSTRAINT log_prestito_fkey;
       public          postgres    false    236    4795    231            �           2606    16557    prestito prestito_copia_fkey    FK CONSTRAINT     y   ALTER TABLE ONLY public.prestito
    ADD CONSTRAINT prestito_copia_fkey FOREIGN KEY (copia) REFERENCES public.copia(id);
 F   ALTER TABLE ONLY public.prestito DROP CONSTRAINT prestito_copia_fkey;
       public          postgres    false    227    4789    231            �           2606    16552    prestito prestito_lettore_fkey    FK CONSTRAINT        ALTER TABLE ONLY public.prestito
    ADD CONSTRAINT prestito_lettore_fkey FOREIGN KEY (lettore) REFERENCES public.lettore(cf);
 H   ALTER TABLE ONLY public.prestito DROP CONSTRAINT prestito_lettore_fkey;
       public          postgres    false    228    231    4791            �           2606    16505    scrittura scrittura_autore_fkey    FK CONSTRAINT     ~   ALTER TABLE ONLY public.scrittura
    ADD CONSTRAINT scrittura_autore_fkey FOREIGN KEY (autore) REFERENCES public.autore(id);
 I   ALTER TABLE ONLY public.scrittura DROP CONSTRAINT scrittura_autore_fkey;
       public          postgres    false    4777    217    225            �           2606    16594    scrittura scrittura_libro_fkey    FK CONSTRAINT     }   ALTER TABLE ONLY public.scrittura
    ADD CONSTRAINT scrittura_libro_fkey FOREIGN KEY (libro) REFERENCES public.libro(isbn);
 H   ALTER TABLE ONLY public.scrittura DROP CONSTRAINT scrittura_libro_fkey;
       public          postgres    false    225    224    4785            �           2606    16453    sede sede_citta_fkey    FK CONSTRAINT     q   ALTER TABLE ONLY public.sede
    ADD CONSTRAINT sede_citta_fkey FOREIGN KEY (citta) REFERENCES public.citta(id);
 >   ALTER TABLE ONLY public.sede DROP CONSTRAINT sede_citta_fkey;
       public          postgres    false    219    221    4779            d   S  x��XM��8=ӿ��%��mX�ݶ���J2IOc���[�4E��F���q���m����UQj;�8�����J��W��I��H�2_�����Bes��V$���p��S�,��a���%X���dU������K��F-���`���sndPY�]m�*u0�r~ ��[[��U�M�6B�F;�i��־���?e���C���^*�Jc��ۀ���h��p<N��8]�d�d��T��Zl B@�^׺��4��������6�W��|����)��u��U�+��&�
8���5�Y��n:L"'��hb�D�I(7j 3m��1=��9 xo�1^z[#�b	���?�;�2�KD�5��aԛ��C�����F���p|6Lg�8�	�9��v�`�T-�S��遺SI��&3��,�>��T`�V3
���;SbE�:F�#��7�E�ɒ��5��s���N�=R]����L;�|�m�p��K�Hk�.b8�2a)}�#ɏh_�������c-�������JsT���P2������ʌ�㐠�\zG<��UpX@�C�]���]RA �@���q�Fʗ��-�G�}W`�~�/tH�꺆/���P�t�[� U�7U�#������jwN��$c��9����^(�9��T�A����x���:6)
��\.!�_�O|����H˔E7��	y"��q��;�〝�|o��� $�A�ܙ��d(�+S�H0��9`L�GQ�צ�d,�N+~R�*�\L8�3e��#I:�뵇�H�T@�����ȁ��LN������R��nX��3����<l���mc��w-�����^���H�E�cTY���`h����K�"��
��q����?sĥ��]�`����d�����]��m�<�=��[��t�m �h�K�.����jSD1��� ��L�j�w�w"����;�oՓ�b���7ʢ�(�0�	u��8����)���e?�i"0x������wV}���cݩP2�S�k����U�?Nb�̎{_$t�V^H����p� u�|3,د��Y���j&.<�e�Sv�B�yj�q��c�d��D�8�MP��\1A��k[�/6�β�4l�N�D�ՓcՈh���
��s�=o��79��,�}F���4��\�����M�p�����պ!�Д�BBf]��"O�����8o+T|S�;��&p���j�ĵPi͓T���e�;����nr ���m��۫�&9��e�J%팲4�!��}��8��8S����1xFߺم������Nn�D5|n�1J��ͳ�v�hǛit���=?j��u00�
kЦ�����R�L.?��w��l�=�ax���P��0�����o�Nv2`� �#����Kw��!M�=�`���2B�}K׉�c�8�������*�6~�s��)��y�((e�A����	{8R@�3R���a����\7
#h7덹1�e�C�N��G>OC�Q������~w<��S�C�zB�Ƈ���0͜��$o|^a����h���>�73�˱/��;�v���*4N����V���з.��vGj���޷��?�����$ہ�>�5\�V
�Y<dB3)�����K��5��j�ݏzT�ߛLk����6*��$p8��0�f�lS�$ޣR�\��Σmb.����iA���/�F$b`Z�[�� �;C�И��`��n�$� t#\q�E�YF�x�T�"܎u�ЀlpcС���[�1wrhU���ɿ_|~ ��!d\�.�PV06ˈ��u����#����v��d��=7�h�g�t"Q�l���J��8�@ O��S�R�k꩘([$�.�H�櫄��T5�n���$�ۨ�EvX�凹�l\.�|s1��Q�����k�v褄Yѭ�K�fW�U�8!]v8�������w�W|�'[/�@/NGFG$��q9�����MԙA� p��ʦn膓��8�@�=�BaGlnv��?�1��6;�J@�e�ʩ���QA��O7J:d7m�6�z_Y�]c8��_�{4�B�L� u/�6��K��8�;Z0�ޗQ���\�<?      p   M   x�s
q	s10�50�145w�LI,�LI�LN-J,��4M3IIN6N2ML473M13L�062OIM��0JN������� ���      j   5  x�M�Mk�0�����i��;M�m��ae���Ƣ8v������[��k�bGpׄN|hg�$�>E`�WMQ��R��;S�f{f[o-�H��	��p�N<��0��@Ȋ��D���젇	��N��b!�������+�4��, ��3P�N������X�H�v&zAﲤ~�Ȓm��S����7�5�&�*T{+��4"(9��y�":�Q���nU�MANj��T�����$-I��.C�e�^�.dZ��!����d2���)��ZN�ڀ�ǌZ���1Z��:.8����k���\�R��Ӄ�V}~�I |�      f   L   x�3����I���2����K)J�2�tJ-��
�r$e�gr�q���D�8�R�"󋲹�9�2�S��b���� ]�      n     x�m�ˑ1Dϣ(������l��� ��N�zB5�A(|U�RcNe�K�����t�P�s��׃��B��r����8��s��ZZ����3ߵ-/�q��V^��vqc������$ǉ���`�1wJ)Y��h� ��NI*�/9���� <"mУԈ�'<�֖����v�Z ���~�T0H}�����ܥ:����
I���;������,d�g��	��jDLw���cxD��E�Gl��8)�-����u��q<"��x�6&�ݸ��]������	�N��H�57�?���N|ՙ�\��I���&�r�pk��G��N<�x��S�k��j���	O���k�(#�f;���&��b��̜�V�]�	�t�z5����sN���7o��Y��wz��L&й�1+h������(��D�w�T3�Y1xD^�6"��h흮q�h n��{DN]�[D	p�(�[#"�3U�#boF��S��v�@��=G&�)�ӓ�8|�ߏ��&U��      o   �  x���ˮ�FD�ï�3=��YJ�%�&��o#��"@� J�ߟ&�g\p�����~��ޏA��R�.~��|&�ݾF��Y<�����)Y���@�ʃB���q��q�m/�B�"z���x��Ϣ
���f�r�$�!6�+�`$��z��,ڸ\�!k$*^��8�S?y�,���h&q,s9�{E`�X�����UNQV���J���ѽӫ����=�����"%N��/
-%�t��z_lsx9v��a��� �t�����z9��		h�uR�$Y2x�������q;t���(�����/�Lߕ(��h4cQV(^!T�|&�.5퉅p��[!�wk6�%X%���e[Z�%X̺j[e-��i���4�\'��RX��6?x���)%�*-��![rr�t�X%[9����aB��`z�r�FWV�+?u�l�?4X8��P)�j��t�fvsƾ�xٻ��i%����8_�Rd*Uը8Vi!H�s��WObl������{�2>r�b�<S��k�ׄx|�9:_\�=��0�\�:��2n��)�g_��e��GFR�`�,VV���0ꜵ�q�Rӎ���N/N�,�bG�ι�������g��)�h����T�0��=�B3vCߵ>̚�{������y^6�+]��xWlҒ*烑�G�yه�ѳ3C���ɭ�Ϭ�`�<W��9��&(�L O�":_u��M�PUs�v�ԣ�hW�'1=J]����me���L��6T>�Hr�����a����+��?[x{k��jּ��w����I�t'�usN�8zs��+/���� г�R��T"o�D�TVV��˱�=D�ɯB~/t)�Y�B��F��L�F�Rt�X�*������؟ڱGyz;�;6tё�
@G� p$���2w�[�D!��elw����g,��3�Sz� 9Y��t�d�D��g��o����u��O����i����	      k   r  x�uXێ��|����I��7�ң�������z7�	��E����n�Iʙ��<��?��ӔF����D�<�:UuzS��t�n�e���W�7j4���L�^�1���Z�`�jnt����;��}���N�
�`�Q�up�^�U��Z�F=j�L�i�S���Z�vf0�����\=�a���K|8טw~j�0��WI���*��eu��wi�lS��e�e�����]�����wc��k&�ũ��ڻ��q�����������>Z�S��y�x5L�jL�Y�	IX�����UG�Q��	�W����ů�fk�Q��j?��u�~�,��@ԛUz�"p�:-����e��º�}�ݣ�����^�{s��䐎�������;;j���űҍ��۠Q=�&��[�ಔ#�+���m��;-��u�̺�Ƈ��D>�&8�HVI��g��KWw�zN`U�6�zͲ����w�qD�	5v�0���5]s�\�n<PP#F�E�F�, �g)�>�/�>|V���p���(�R�a�Q�3
�6�����m���hY�%[$U�W�YfҎU�fS�e��fs4l� �C���C����(9�C÷ s��Վ7�jk[��4�謻��>H�i�p�l�<����@ᢩS@�(}.��iV�,���z�ϛ�` ���u^w�Qo͸W/�sf�o?���ס~����C������;���F�<���75��w1C!;~K��@�7�Ԭ@�wy�̪ڔ�,+W,r���Uǘ��'�5aT�k�3�`��h&Lj�[�v����ֶAʌ�F������O�@8��f�`�`0�N�+̺�٪Z�GDs�aD�Y���M��)�.�w��9�E�|��uo��,oRA�~��c����/�zKвÝa�1{���2�Ĥ��>�\q&v�	�L��5�������3�+����eQ���<��65�b�/�$/n���c�V�Y��n- ��Qx~�Kۏ���\y��;2R�[8˓����|P�L6��fy�#\�5��s�U��+��=`C��}��m&�xyyx-�4��t�:p��)�Mh$t�@^�l?���,8�w���Rbjdo\��*�8&~� < @)�`�ӻl�XU�*�6�čW��L�@��C1����=2�R�q "�f�5��z\;'e�e dG��qS�1E�_J��U�W���JlN��9����MQ.��O�������#��R��v�zA�m��m�<( (��H;�z��;B�%tC���D�R�]/����ڑ���3ai���A�8�yJuڔ������e��(07o��
\2��~�~����e��s2�ؓ<��<[�h�����3^^t�D�{����	��a�Q���<bi�>�*J���?G�,}���ŬDzb<�M`Y^r4ݠ"�P-�<��ϑȭ�`8�ivWmˁ�n�r�-y���v6^��n���sZ�Ͳ�z曙 �e��!v�n��kґR�����~���=,�N�m!����t�(Q�������L+}���߁�&��Vrs�КӒ���'�P���*��k�O@�A���vԗ��88Oa��k�L{b:��w�E���	Y�ya�O��*��Nk笺)R�$M
�Cx��"�Y�����`Ĥ45_�~%�?����쏧��6��@2|��A��ga%����.���%߁�&A3�Ŵ�3��@���y�6ͥe՗��ju�FV���ؤ����x�:��Ղ#��J�e�+�S�{]m�v+�R��!
��yA89��R�oP�)��L9;8K|ʢH/���"��%��������N����5����,�R�AF�7��<W�1������䛖��b��}|�=ŗ�F�J�{Yή�K޺(���7z���&��	$r�u��uvђ����P�PHj��3lsQ� ��`�o�B�,��j����&IJ��ǘy��|� ��h��,�^pg�K_^n�8œ��e�gE�UĎ�%0�sb�e���7�5GT��-�q7BL��za���hn��4Am�s�'C�d�̀!F[;�?��L5�c�L���,K��\l}��,dٺ�VY򒻥,?���5�ھǂ��E��z�W����ʨ#�ryԉ����~���2�d� O��.3����E~�M������pV�N�r@�̪��0o�QaA��m��� ��XxN4Zq:G���8��$�×����-�M��)/g���eե|-S���4�C��I�-�+���0{ϋ�&Vz���@]���>��U�l"cˈ��̯�􂉄9��l����N?uVJ��� [^�����Rm�i�[=ۇo�ω;���o���E-�I�
#���vxP/�z�u�A�������+>>��(c�@>��$!<��,X��:q ���3�s�q�d��2y�Z#rӀ(���Ǝn#Ȕb��
4�����ba1�Z���`S����,����(n��2��x��vR�t������:p9D�f����r����|-eGD�f8�4~� �����ֵ#��/^-����3K��{�*���s�G��P5�N8��Z�Le�Ȥ,�{�nVL��l��~��5O�F�nd%�����;+�GK�J1�`$�e�Wͣx5��`��J<�u2���n��0JUU��?s/!%_Rj�gq��je��M��<v�77.؁GS�{qϙw�����51B�P����A��_l����k��"y�}�~ Wv����%q�r���[�ֈ��ezN���zYg�2�����4@���X���rFi�{�Z���z�ߤi�Qr`B����4�D\%�����d�h%X�#"��H�>m���с���_�y�w<�Qv8�'+T?���L�B����)`,�gj���: U�;Et���+� X�i��0�.�Y���s�|=!���`0��4 "�4zk=��g���]7�v��6VC�BT<����8S�p���*��7�;��f�zKR=&�B��QbN���'&"��qS\�b���ߝ�/D�p�a\�؃�@�-{s���[���
)o�a��x����z�ٝP���o��M���=O�����,zߍ��q�e�B ذ�:vw�@7�F3�Qnx�WЋ�Ō��Ϟ=�?�g�      u   m  x��Mk�@@��_Qr�����^���PJO^�Y�������wJ�F�65�����2���I [թN�"�����}"�Y�h;ζy��!�X��/˦IuI��<
��*2ߙ����h��Hؑ𴻞�����g���T��EE��c���xY�ew���D��Y���t�<� 0��J�К���==y�����S7�mxR�0}��T?O��f&ۥ�����e�'������ZK�q_z��}��I_�*�k���8�U����B�S�jeO�)��ѣC� �V�nb�Șɦ/ٶ�k.�3��Q�������zc`�bھ�Ώ�j�D+�6�;��=X@�SA@��н�r������      r     x��X[��8���2[|?>���S��u(g����ϱ e�	�S�ʅl��1��i��ч����f��R�q�&�)߄F���0[���,_H���a�:~3��|0���7�T����0����M�jJ��z�>����	Q=juno�8Y=jh�]�<+���� %�i+	z��|oV8�(E���)r}��u��73�p����,�,)OC�<҉#dC��Z����9�>��$zH���'p=�D�	�B�M�������5_'p
=L5k}��N7�B�d�$p�5_�"p�z�&I��	�t���L��I�+��a�͔{sp��y����L9�&�i	\�[_t&e�f��q
�E��-�ϳK�y�f�2�Nl����j�_u�/8�����y�yN�T���Y�Ϧ��`�e�����*���)��%9�7�\�w�}	�2�� �ys�����\n�O��� 6�_!Q�\�����#~2����L����r~_�S�N��9�/��U��f� Z�1�k0�u�R���1���qv�Z��Vե��H��q<Nц��ޙ�/�0M�~Zӿ<�'�͙i߷ҴN]՚��y9�N�Og�C��͏��7M����B��VW@9o���2͋�'�+�VO��/�7J!Y�6��q�,�R��K"�p��,|�?t�}����QD���\�ߒ���t-.pW�Wa��.� \�_}�C�W��/A8�(��+���h1`�o&�����f_��}8M���<=��g\!�Ǿ���X��x�x�>�8Ǯ�1����M��f
_x���g��QH%�=?C p򎟶����M���	<Rf��(��+�xM@�i�P@U�ҊKg �����U�	(���Ѣ�]��+�_$]���No��[Tb�T���6��:~Kl<u7�U@����#�5ӥ*r�B������^�r��yz�|�9������9B��t��w��7���o?���T�M��~6��$��jS�,���(�����垘����Սi�7����a�S~� T�l<WQv�F��o\MGS@Sq��l_j�	]�UZ�2�4�m61�q�u��������蝙"�~6��j�e���j�>��ljXj��1��d�*h�Nk��̴&� t��/��p ԰�O}O�9��qҩ+'�MA@Z�v_H�Y�qt�Ju�j���h� 7�9b9���Qu�$�7z���ouC:c����#���&a�Ȭo>�@��, p= �g �v��4�S;m(@`��@��
���)��k��-dD      l   �   x�]Q˱�0;�*��7�?�l�u<;;��<	�YSH�1�����Irb8�BzէۤL@�qd�U�_8M%��)V���Y��£7��R]8����o.�x�U�aB\3���iI����"��j>#��0�J���25�Ƽ�[.-:"|�J�M�ӖA��
��M��OG�A�Z	��U��ش=�̸����yL�ӕ��jK~�c���qj�f�$x��#�H�Mĝo3[H�u�Q����J�h�      h   r   x��A
�0E�3��H1ZH�U���d��@�z��n���9X�i�òrG��?��Y��$GK֑o��l+�|�l5i�i)Y�4�È��u��E�����q{ ��t �     