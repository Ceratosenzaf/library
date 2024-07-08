<?php

include '../utils/db.php';
include '../utils/redirect.php';

session_start();

$id = $_SESSION['copia'] ?? '';
$archiviato = isset($_POST['archiviato']) ? 'TRUE': 'FALSE';

if ($id == '') redirect_error('input');
unset($_SESSION['copia']);

$sql = "UPDATE copia SET archiviato = $2 WHERE id = $1";

$db = open_pg_connection();
$res = pg_prepare($db, "edit-copy-$id", $sql);
$res = pg_execute($db, "edit-copy-$id", array($id, $archiviato));

if (!$res) redirect_error('credentials');

redirect('./copie.php');
