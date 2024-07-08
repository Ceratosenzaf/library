<?php

include '../utils/db.php';
include '../utils/redirect.php';

session_start();

$libro = $_POST['libro'] ?? '';
$sede = $_POST['sede'] ?? '';

if ($libro == '' || $sede == '') redirect_error('input');

$sql = "INSERT INTO copia (libro, sede) VALUES ($1, $2)";

$db = open_pg_connection();
$res = pg_prepare($db, 'new-copy', $sql);
$res = pg_execute($db, 'new-copy', array($libro, $sede));

if (!$res) redirect_error('credentials');

redirect('./copie.php');
