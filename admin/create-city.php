<?php

include '../utils/db.php';
include '../utils/redirect.php';

session_start();

$nome = $_POST['nome'] ?? '';

if ($nome == '' ) redirect_error('input');

$sql = "INSERT INTO citta (nome) VALUES ($1)";

$db = open_pg_connection();
$res = pg_prepare($db, 'new-city', $sql);
$res = pg_execute($db, 'new-city', array($nome));

if (!$res) redirect_error('credentials');

redirect('./cittas.php');
