<?php

include '../utils/db.php';
include '../utils/redirect.php';

session_start();

$cf = $_SESSION['cf'] ?? '';
$nome = $_POST['nome'] ?? '';
$cognome = $_POST['cognome'] ?? '';
$premium = isset($_POST['premium'])? 'TRUE': 'FALSE';
$bloccato = isset($_POST['bloccato'])? 'TRUE': 'FALSE';

if ($cf == '' || $nome == '' || $cognome == '')
  redirect_error('input');

$sql = "UPDATE lettore SET nome = $2, cognome = $3, premium = $4, bloccato = $5 WHERE cf = $1";

$db = open_pg_connection();
$res = pg_prepare($db, "edit-user-$cf", $sql);
$res = pg_execute($db, "edit-user-$cf", array($cf, $nome, $cognome, $premium, $bloccato));

if (!$res) redirect_error('credentials');

redirect('./');
