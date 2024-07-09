<?php

include '../utils/db.php';
include '../utils/redirect.php';

session_start();

$isbn = $_SESSION['libro'] ?? '';
$titolo = $_POST['titolo'] ?? '';
$pubblicazione = $_POST['pubblicazione'] ?? null;
$pagine = (int)($_POST['pagine'] ?? 0);
$editore = $_POST['editore'] ?? '';
$trama = $_POST['trama'] ?? '';

$autoriNew = array();
foreach ($_POST['autori'] as $autore) {
  array_push($autoriNew, $autore);
}

if ($isbn == '' || $titolo == '' || $pagine <= 0 || $editore == '' || count($autoriNew) == 0 || $trama == '')
  redirect_error('input');
unset($_SESSION['libro']);

$sql = "UPDATE libro SET titolo = $2, trama = $3, editore = $4, pagine = $5, pubblicazione = $6 WHERE ISBN = $1";

$db = open_pg_connection();
start_pg_transaction($db);
$res = pg_prepare($db, "edit-book-$isbn", $sql);
$res = pg_execute($db, "edit-book-$isbn", array($isbn, $titolo, $trama, $editore, $pagine, value_or_null($pubblicazione)));

if (!$res) {
  rollback_pg_transaction($db);
  redirect_error('input');
} 

// fetch current data
$sql = "SELECT s.autore FROM scrittura s WHERE s.libro = $1";
$res = pg_prepare($db, "book-$isbn-authors", $sql);
$res = pg_execute($db, "book-$isbn-authors", array($isbn));

if (!$res){
  rollback_pg_transaction($db);
  redirect_error('input');
} 

$autoriOld = array();
while ($row = pg_fetch_assoc($res))
  array_push($autoriOld, $row['autore']);

// delete useless data
$sql = "DELETE FROM scrittura WHERE libro = $1 AND autore = $2";
$res = pg_prepare($db, 'old-book-authors', $sql);
foreach ($autoriOld as $autore) {
  if (!in_array($autore, $autoriNew)) {
    $res = pg_execute($db, 'old-book-authors', array($isbn, $autore));
    if (!$res){
      rollback_pg_transaction($db);
      redirect_error('input');
    } 
  }
}

// insert new data
$sql = "INSERT INTO scrittura (libro, autore) VALUES ($1, $2)";
$res = pg_prepare($db, 'new-book-authors', $sql);
foreach ($autoriNew as $autore) {
  if (!in_array($autore, $autoriOld)) {
    $res = pg_execute($db, 'new-book-authors', array($isbn, $autore));
    if (!$res){
      rollback_pg_transaction($db);
      redirect_error('input');
    } 
  }
}

commit_pg_transaction($db);

redirect('./libri.php');
