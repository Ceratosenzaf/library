<?php

include '../utils/db.php';
include '../utils/redirect.php';

session_start();

$id = $_SESSION['città'] ?? '';
$nome = $_POST['nome'] ?? '';

if ($id == '' || $nome == '') redirect_error('input');
unset($_SESSION['città']);

$sql = "UPDATE citta SET nome = $2 WHERE id = $1";

$db = open_pg_connection();
$res = pg_prepare($db, "edit-city-$id", $sql);
$res = pg_execute($db, "edit-city-$id", array($id, $nome));

if (!$res) redirect_error('credentials');

redirect('./cittas.php');
