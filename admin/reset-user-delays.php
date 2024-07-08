<?php

include '../utils/db.php';
include '../utils/redirect.php';

session_start();

$cf = $_SESSION['cf'] ?? '';

if ($cf == '') redirect_error('input');
unset($_SESSION['cf']);

$sql = "UPDATE lettore SET ritardi = 0 WHERE cf = $1";

$db = open_pg_connection();
$res = pg_prepare($db, "reset-user-$cf-delays", $sql);
$res = pg_execute($db, "reset-user-$cf-delays", array($cf));

if (!$res) redirect_error('credentials');

redirect("./lettore.php?cf=$cf");
