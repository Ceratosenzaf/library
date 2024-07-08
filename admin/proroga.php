<?php

include '../utils/db.php';
include '../utils/redirect.php';

session_start();

$id = $_SESSION['prestito'] ?? '';
$data = $_POST['data'] ?? '';

if ($id == '' || $data == '') redirect_error('input');
unset($_SESSION['città']);

$sql = "
UPDATE prestito SET scadenza = $2 
WHERE id = $1 AND riconsegna IS NULL
";

$db = open_pg_connection();
$res = pg_prepare($db, "proroga-$id", $sql);
$res = pg_execute($db, "proroga-$id", array($id, $data));

if (!$res) redirect_error('input');

redirect('./prestiti.php');
