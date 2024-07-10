<?php

include '../utils/db.php';
include '../utils/redirect.php';

session_start();

$nome = $_POST['nome'] ?? '';
$fondazione = $_POST['fondazione'] ?? '';
$cessazione = $_POST['cessazione'] ?? '';
$citta = $_POST['città'] ?? '';

if ($nome == '') redirect_error('input');

$sql = "INSERT INTO casa_editrice (nome, fondazione, cessazione, citta) VALUES ($1, $2, $3, $4)";

$db = open_pg_connection();
$res = pg_prepare($db, 'new-publisher', $sql);
$res = pg_execute($db, 'new-publisher', array($nome, value_or_null($fondazione), value_or_null($cessazione), value_or_null($citta)));

if (!$res) redirect_error('credentials');

redirect('./editori.php');
