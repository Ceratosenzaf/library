<?php

include '../utils/db.php';
include '../utils/redirect.php';

session_start();

$id = $_SESSION['copia'] ?? '';
$sede = $_POST['sede'] ?? '';
$archiviato = isset($_POST['archiviato']) ? 'TRUE' : 'FALSE';

if ($id == '' || $sede == '') redirect_error('input');
unset($_SESSION['copia']);

$sql = "UPDATE copia SET archiviato = $2, sede = $3 WHERE id = $1";

$db = open_pg_connection();
$res = pg_prepare($db, "edit-copy-$id", $sql);
$res = pg_execute($db, "edit-copy-$id", array($id, $archiviato, $sede));

if (!$res) redirect_error('credentials');

redirect('./copie.php');
