<?php

include '../utils/db.php';
include '../utils/redirect.php';

session_start();

$nome = $_POST['nome'] ?? '';
$cognome = $_POST['cognome'] ?? '';
$pseudonimo = $_POST['pseudonimo'] ?? '';
$nascita = $_POST['nascita'] ?? '';
$morte = $_POST['morte'] ?? '';
$biografia = $_POST['biografia'] ?? '';

$sql = "INSERT INTO autore (nome, cognome, pseudonimo, nascita, morte, biografia) VALUES ($1, $2, $3, $4, $5, $6)";

$db = open_pg_connection();
$res = pg_prepare($db, 'new-author', $sql);
$res = pg_execute($db, 'new-author', array(value_or_null($nome), value_or_null($cognome), value_or_null($pseudonimo), value_or_null($nascita), value_or_null($morte), value_or_null($biografia)));

if (!$res) redirect_error('credentials');

redirect('./autori.php');
