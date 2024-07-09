<?php

include '../utils/db.php';
include '../utils/redirect.php';

session_start();

$cf = $_SESSION['cf'] ?? '';
$nome = $_POST['nome'] ?? '';
$cognome = $_POST['cognome'] ?? '';
$premium = isset($_POST['premium']) ? 'TRUE' : 'FALSE';

if ($cf == '' || $nome == '' || $cognome == '') redirect_error('input');
unset($_SESSION['cf']);

$sql = "UPDATE lettore SET nome = $2, cognome = $3, premium = $4 WHERE cf = $1";

$db = open_pg_connection();
$res = pg_prepare($db, "edit-user-$cf", $sql);
$res = pg_execute($db, "edit-user-$cf", array($cf, $nome, $cognome, $premium));

if (!$res) redirect_error('credentials');

redirect('./lettori.php');
