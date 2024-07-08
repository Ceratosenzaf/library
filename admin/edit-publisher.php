<?php

include '../utils/db.php';
include '../utils/redirect.php';

session_start();

$id = $_SESSION['autore'] ?? '';
$nome = $_POST['nome'] ?? '';
$fondazione = $_POST['fondazione'] ?? '';
$cessazione = $_POST['cessazione'] ?? '';
$citta = $_POST['citta'] ?? '';

if ($id == '' || $nome == '') redirect_error('input');
unset($_SESSION['editore']);

$sql = "UPDATE casa_editrice SET nome = $2, fondazione = $3, cessazione = $4, citta = $5 WHERE id = $1";

$db = open_pg_connection();
$res = pg_prepare($db, "edit-publisher-$id", $sql);
$res = pg_execute($db, "edit-publisher-$id", array($id, $nome, value_or_null($fondazione), value_or_null($cessazione), value_or_null($citta)));

if (!$res) redirect_error('credentials');

redirect('./editori.php');
