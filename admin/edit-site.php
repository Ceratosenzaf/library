<?php

include '../utils/db.php';
include '../utils/redirect.php';

session_start();

$id = $_SESSION['sede'] ?? '';
$indirizzo = $_POST['indirizzo'] ?? '';
$citta = $_POST['città'] ?? '';

if ($id == '' || $indirizzo == '' || $citta == '') redirect_error('input');
unset($_SESSION['sede']);

$sql = "UPDATE sede SET indirizzo = $2, citta = $3 WHERE id = $1";

$db = open_pg_connection();
$res = pg_prepare($db, "edit-site-$id", $sql);
$res = pg_execute($db, "edit-site-$id", array($id, $indirizzo, $citta));

if (!$res) redirect_error('credentials');

redirect('./sedi.php');
