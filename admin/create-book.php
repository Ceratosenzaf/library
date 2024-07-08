<?php

include '../utils/db.php';
include '../utils/redirect.php';

session_start();

$isbn = $_POST['isbn'] ?? '';
$titolo = $_POST['titolo'] ?? '';
$pubblicazione = $_POST['pubblicazione'] ?? null;
$pagine = (int)($_POST['pagine'] ?? 0);
$editore = $_POST['editore'] ?? '';
$trama = $_POST['trama'] ?? '';

$autori = array();
foreach ($_POST['autori'] as $autore) {
  array_push($autori, $autore);
}


if ($isbn == '' || $titolo == '' || $pagine <= 0 || $editore == '' || count($autori) == 0 || $trama == '')
redirect_error('input');

$sql = "INSERT INTO libro (isbn, titolo, trama, editore, pagine, pubblicazione) VALUES ($1, $2, $3, $4, $5, $6)";

$db = open_pg_connection();
$res = pg_prepare($db, 'new-book', $sql);
$res = pg_execute($db, 'new-book', array($isbn, $titolo, $trama, $editore, $pagine, value_or_null($pubblicazione)));

if (!$res) redirect_error('input');


$sql = "INSERT INTO scrittura (libro, autore) VALUES ($1, $2)";
$res = pg_prepare($db, 'new-book-authors', $sql);

foreach ($autori as $autore) {
  $res = pg_execute($db, 'new-book-authors', array($isbn, $autore));
  if (!$res) redirect_error('input');
}

redirect('./libri.php');
