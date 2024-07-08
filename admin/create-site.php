<?php

include '../utils/db.php';
include '../utils/redirect.php';

session_start();

$indirizzo = $_POST['indirizzo'] ?? '';
$citta = $_POST['città'] ?? '';

if ($indirizzo == '' || $citta == '') redirect_error('input');

$sql = "INSERT INTO sede (indirizzo, citta) VALUES ($1, $2)";

$db = open_pg_connection();
$res = pg_prepare($db, 'new-city', $sql);
$res = pg_execute($db, 'new-city', array($indirizzo, $citta));

if (!$res) redirect_error('credentials');

redirect('./sedi.php');
