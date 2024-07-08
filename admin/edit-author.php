<?php

include '../utils/db.php';
include '../utils/redirect.php';

session_start();

$id = $_SESSION['autore'] ?? '';
$nome = $_POST['nome'] ?? '';
$cognome = $_POST['cognome'] ?? '';
$pseudonimo = $_POST['pseudonimo'] ?? '';
$nascita = $_POST['nascita'] ?? '';
$morte = $_POST['morte'] ?? '';
$biografia = $_POST['biografia'] ?? '';

if ($id == '') redirect_error('input');
unset($_SESSION['autore']);

$sql = "UPDATE autore SET nome = $2, cognome = $3, pseudonimo = $4, nascita = $5, morte = $6, biografia = $7 WHERE id = $1";

$db = open_pg_connection();
$res = pg_prepare($db, "edit-city-$id", $sql);
$res = pg_execute($db, "edit-city-$id", array($id, value_or_null($nome), value_or_null($cognome), value_or_null($pseudonimo), value_or_null($nascita), value_or_null($morte), value_or_null($biografia)));

if (!$res) redirect_error('credentials');

redirect('./autori.php');
